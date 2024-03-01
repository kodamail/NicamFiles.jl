using Printf
using FortranFiles
using WriteVTK

# per file (panda:per pe, sequential: per region)
# (pe=region if sequential format)
mutable struct NicamHgridFile
    fname   :: String
    access  :: String
    glevel  :: Integer
    rlevel  :: Integer
    gmr     :: Integer
    gall    :: Integer   # Number of grids per region including halo
    gall_in :: Integer   # Number of grids per region without halo
    data    :: Dict{String,Any}
    lat     :: Array{Real,1}
    lon     :: Array{Real,1}
    
    function NicamHgridFile(
        fname  :: String;
	access :: String  = "panda",
	glevel :: Integer = -1,  # for direct or sequential
	rlevel :: Integer = -1 ) # for direct or sequential
	
	self         = new()
	self.fname   = fname
        self.access  = access

        self.data = Dict(
            "hx"  => [], "hy"  => [], "hz"  => [],
            "hix" => [], "hiy" => [], "hiz" => [],
            "hjx" => [], "hjy" => [], "hjz" => [] )

        # read hgrid in region(s) of a process
        if access == "sequential"  # must be 1rgn/prc
	    nio = NicamFile( fname, access="sequential", glevel=glevel, rlevel=rlevel )
            self.glevel  = glevel
            self.rlevel  = rlevel

            #read( nio )  # skip
            read( nio.fin )  # skip (faster than simply using nio)
	    
            idef = 2^( glevel - rlevel ) + 2
            jdef = idef
            tmpbuf = Array{Float64}( undef, idef, jdef, 1, 1 )
            read( nio, tmpbuf )
            self.data["hx"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
            read( nio, tmpbuf )
            self.data["hy"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
            read( nio, tmpbuf )
            self.data["hz"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
            tmpbuf = Array{Float64}( undef, idef, jdef, 2, 1 )
            read( nio, tmpbuf )
            self.data["hix"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
            self.data["hjx"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)
            read( nio, tmpbuf )
            self.data["hiy"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
            self.data["hjy"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)
            read( nio, tmpbuf )
            self.data["hiz"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
            self.data["hjz"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)

            close( nio )
	    
 	elseif access == "panda"  # rgn/prc may be more than 1
            nio = NicamFile( fname, access="panda" )
            self.glevel = nio.glevel
            self.rlevel = nio.rlevel

            self.data["hx"] = read( nio, "grd_x_x" )  # TODO: unify halo treatment with hix, ...
            self.data["hy"] = read( nio, "grd_x_y" )
            self.data["hz"] = read( nio, "grd_x_z" )
            #
            self.data["hix"] = read( nio, "grd_xt_ix", flag_halo=true )
            self.data["hiy"] = read( nio, "grd_xt_iy", flag_halo=true )
            self.data["hiz"] = read( nio, "grd_xt_iz", flag_halo=true )
            self.data["hjx"] = read( nio, "grd_xt_jx", flag_halo=true )
            self.data["hjy"] = read( nio, "grd_xt_jy", flag_halo=true )
            self.data["hjz"] = read( nio, "grd_xt_jz", flag_halo=true )

	    close( nio )

        end
	
	self.gmr     = self.glevel - self.rlevel
        self.gall    = (2^self.gmr+2)^2
        self.gall_in = (2^self.gmr  )^2

        latlon = xyz2latlon.( self.data["hx"], self.data["hy"], self.data["hz"] )
        self.lat = first.(latlon)
        self.lon = last.(latlon)

	return self
    end
end

# all the regions including pole
mutable struct NicamHgridAllFiles
    nioh    :: Array{NicamHgridFile,1}  # array of regional file
    num_pe  :: Integer  # =num_rgn if sequential format
    num_rgn :: Integer
    glevel  :: Integer
    rlevel  :: Integer
    gmr     :: Integer
    gall    :: Integer   # Number of grids per region including halo
    gall_in :: Integer   # Number of grids per region without halo
    data_np :: Array{Dict{String,Any},1}
    data_sp :: Array{Dict{String,Any},1}
    rgn_np  :: Integer  # region number (>=0)
    rgn_sp  :: Integer  # region number (>=0)
    rgnid_pole::Array{Integer,1}

    function NicamHgridAllFiles(
        fhead          :: String;
	access         :: String  = "panda",
	glevel         :: Integer = -1,
	rlevel         :: Integer = -1,
	num_pe         :: Integer = -1,
	num_rgn_per_pe :: Integer = 1 )   # Be careful! >1 is not well tested

	self         = new()

        if access == "sequential"
            self.glevel  = glevel
            self.rlevel  = rlevel
	    
 	elseif access == "panda"
	    pe = 0
            pe6 = @sprintf(".pe%06i", pe )
            fname = fhead * pe6
            nioh_ref = NicamHgridFile( fname, access="panda" )
            self.glevel  = nioh_ref.glevel
            self.rlevel  = nioh_ref.rlevel
	end

	self.num_rgn = 10*4^self.rlevel
	self.gmr     = self.glevel - self.rlevel
        self.gall    = (2^self.gmr+2)^2
        self.gall_in = (2^self.gmr  )^2

        # set num_pe
        if num_pe < 0
            num_pe = Int( self.num_rgn / num_rgn_per_pe )
	end
	if num_pe * num_rgn_per_pe != self.num_rgn
	    println( "error!!!" )
	end
        self.num_pe = num_pe

        # allocate array for all the hgrid files
        self.nioh = Array{NicamHgridFile}( undef, self.num_pe )
	
        if access == "sequential"
            for pe=0:num_pe-1
                re5 = @sprintf(".rgn%05i", pe )
                fname = fhead * re5
                self.nioh[pe+1] = NicamHgridFile( fname, access="sequential", glevel=self.glevel, rlevel=self.rlevel )
            end
 	elseif access == "panda"
            for pe=0:num_pe-1
                pe6 = @sprintf(".pe%06i", pe )
	        fname = fhead * pe6
                self.nioh[pe+1] = NicamHgridFile( fname, access="panda" )
            end
        end

        # Searching regions that include north or south pole
        hz_max = Array{Any}( undef, self.num_rgn )  # for searching pole
        for pe=0:num_pe-1
            for r=0:num_rgn_per_pe-1
	        rgn = pe * num_rgn_per_pe + r  # rgn >= 0
		s1 =  r    * self.gall_in + 1
		s2 = (r+1) * self.gall_in 
                hz_max[rgn+1] = maximum( self.nioh[pe+1].data["hz"][s1:s2] )
	    end
        end

        rgn_np = sortperm(hz_max,rev=true )[1:5] .- 1  # regions for NP
        rgn_sp = sortperm(hz_max,rev=false)[1:5] .- 1  # regions for SP
	self.rgn_np = rgn_np[1]
	self.rgn_sp = rgn_sp[1]
	self.rgnid_pole = Array{Integer}( undef, 2 )
	self.rgnid_pole[1] = rgn_np[1]
	self.rgnid_pole[2] = rgn_sp[1]
        lon_np = Array{Any}( undef, 5 )
        lon_sp = Array{Any}( undef, 5 )
        for i=1:5
            lon_np[i] = self.nioh[rgn_np[i]+1].lon[(2^self.gmr)*(2^self.gmr-1)+1]  # next to NP grid
            lon_sp[i] = self.nioh[rgn_sp[i]+1].lon[2^self.gmr]                     # next to SP grid
        end
        pei2_np = sortperm(lon_np,rev=false)[1:5]
        pei2_sp = sortperm(lon_sp,rev=false)[1:5]

        self.data_np = Array{Dict{String,Any}}( undef, 5 )
        self.data_sp = Array{Dict{String,Any}}( undef, 5 )

        for i=1:5
            self.data_np[i] = Dict()
            self.data_sp[i] = Dict()
            self.data_np[i]["cellx"] = self.nioh[rgn_np[pei2_np[i]]+1].data["hjx"][(2^self.gmr+2)*(2^self.gmr)+2]
            self.data_np[i]["celly"] = self.nioh[rgn_np[pei2_np[i]]+1].data["hjy"][(2^self.gmr+2)*(2^self.gmr)+2]
            self.data_np[i]["cellz"] = self.nioh[rgn_np[pei2_np[i]]+1].data["hjz"][(2^self.gmr+2)*(2^self.gmr)+2]
            self.data_sp[i]["cellx"] = self.nioh[rgn_sp[pei2_sp[i]]+1].data["hix"][(2^self.gmr+2)*2-1]
            self.data_sp[i]["celly"] = self.nioh[rgn_sp[pei2_sp[i]]+1].data["hiy"][(2^self.gmr+2)*2-1]
            self.data_sp[i]["cellz"] = self.nioh[rgn_sp[pei2_sp[i]]+1].data["hiz"][(2^self.gmr+2)*2-1]
        end

        return self
    end
    
end


# From NICAM/share/mod_vector.f90
function xyz2latlon( x, y, z )
    length = sqrt( x*x + y*y + z*z )
    EPS = 1.e-16
    lat = 0.0
    lon = 0.0

    if length < EPS
       lat = 0.0
       lon = 0.0
       return lat, lon

    elseif z / length >= 1.0  # vector is parallele to z axis.
       lat = asin( 1.0 )
       lon = 0.0
       return lat, lon
       
    elseif z / length <= -1.0  # vector is parallele to z axis.
       lat = asin( -1.0 )
       lon = 0.0
       return lat, lon
       
    else
       lat = asin( z / length )
       
    end

    length_h = sqrt( x*x + y*y )

    if length_h < EPS
       lon = 0.0
       return lat, lon

    elseif x / length_h >= 1.0
       lon = acos( 1.0 )
       
    elseif x / length_h <= -1.0
       lon = acos( -1.0 )
       
    else
       lon = acos( x / length_h )
       
    end

    if y < 0.0
        lon = -lon
    end

    return lat, lon
end
