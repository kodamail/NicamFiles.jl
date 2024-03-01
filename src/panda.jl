# treat file-by-file (i.e. pe-by-pe)
struct NicamPandaFile <: NicamFile
    fin    :: IOStream
    fname  :: String
    glevel :: Integer
    rlevel :: Integer
    info   :: Dict{String,Any}
end

function NicamPandaFile(
    fname    :: String;
    showinfo :: Bool = false
    )

    # temporary buffer
    tmpHSHORT= Array{UInt8}(undef, 16)
    tmpHMID  = Array{UInt8}(undef, 64)
    tmpHLONG = Array{UInt8}(undef,256)

    glevel = -1
    rlevel = -1
    info = Dict()

    fin = open( fname, "r" )
    
    #
    # Package header
    #
    readbytes!( fin, tmpHMID )
    info["desc"] = join( uint2char.(tmpHMID) )

    readbytes!( fin, tmpHLONG )
    info["note"] = join( uint2char.(tmpHLONG) )

    info["fmode"]         = ntoh( read( fin, Int32 ) )
    info["endiantype"]    = ntoh( read( fin, Int32 ) )
    info["grid_topology"] = ntoh( read( fin, Int32 ) )
    glevel                = ntoh( read( fin, Int32 ) )
    rlevel                = ntoh( read( fin, Int32 ) )
    info["num_of_rgn"]    = ntoh( read( fin, Int32 ) )

    info["rgnid"] = Array{Int32}( undef, info["num_of_rgn"] )
    for i=1 : info["num_of_rgn"]
        info["rgnid"][i] = ntoh( read( fin, Int32 ) )
    end

    info["num_of_data"]    = ntoh( read( fin, Int32 ) )

    if showinfo
        println( fname * " header information:" )
        display( info )
        println( "rgnid:" )
        display( info["rgnid"][:] )
    end

    info["dinfo"] = Array{Dict}( undef, info["num_of_data"] )

    #
    # Data Header
    #
    for i=1 : info["num_of_data"]
#	    println(i)
        info["dinfo"][i] = Dict()
	    
        readbytes!( fin, tmpHSHORT )
        info["dinfo"][i]["varname"] = join( uint2char.(tmpHSHORT) )

        readbytes!( fin, tmpHMID )
        info["dinfo"][i]["description"] = join( uint2char.(tmpHMID) )

        readbytes!( fin, tmpHSHORT )
        info["dinfo"][i]["unit"] = join( uint2char.(tmpHSHORT) )

        readbytes!( fin, tmpHSHORT )
        info["dinfo"][i]["layername"] = join( uint2char.(tmpHSHORT) )

        readbytes!( fin, tmpHLONG )
        info["dinfo"][i]["note"] = join( uint2char.(tmpHLONG) )

        info["dinfo"][i]["datasize"]     = ntoh( read( fin, Int64 ) )  # sum of all the regions
        info["dinfo"][i]["datatype"]     = ntoh( read( fin, Int32 ) )
        info["dinfo"][i]["num_of_layer"] = ntoh( read( fin, Int32 ) )
        info["dinfo"][i]["step"]         = ntoh( read( fin, Int32 ) )
        info["dinfo"][i]["time_start"]   = ntoh( read( fin, Int64 ) )
        info["dinfo"][i]["time_end"]     = ntoh( read( fin, Int64 ) )

        if showinfo && i == 1
            println( "data-", i, " header information:" )
            display( info["dinfo"][i] )
        end

        info["dinfo"][i]["data_pos"] = position( fin )  # keep start position of each data content
        skip( fin, info["dinfo"][i]["datasize"] )

    end

    return NicamPandaFile( fin, fname, glevel, rlevel, info )
end


function Base.read(
    ni        :: NicamPandaFile,
    varname   :: String;
    step      :: Integer = -1,
    rgnid     :: Integer = -1, # region id (-1:all or >=0)
    k         :: Integer = -1,
    flag_halo :: Bool    = false,
    undef2nan :: Bool    = false,
    showinfo  :: Bool    = false
    )
    vret = Array{Any}( undef, 0 )

    idef = 2^( ni.glevel - ni.rlevel ) + 2
    jdef = idef
    rdef = ni.info["num_of_rgn"]

    fin = ni.fin

    # Data
    for i=1 : ni.info["num_of_data"]
        varname != ni.info["dinfo"][i]["varname"] && continue
        step != ni.info["dinfo"][i]["step"] && step != -1 && continue

        kdef = ni.info["dinfo"][i]["num_of_layer"]

        imin = 1 ; imax = idef
        jmin = 1 ; jmax = jdef
        if ! flag_halo
            # halo will be trimmed
            imin = 2 ; imax = idef-1
            jmin = 2 ; jmax = jdef-1
        end
        kmin = 1 ; kmax = kdef
        if k > 0
            kmin = k ; kmax = k
        end
        rmin = 1 ; rmax = rdef
        if rgnid >= 0
	    # search for info["rgnid"][:] == rgnid
	    rmin = findfirst( isequal(rgnid), ni.info["rgnid"] )
	    rmax = rmin
	    #println( "rmin:", rmin )
        end

        seek( fin, ni.info["dinfo"][i]["data_pos"] )

        if ni.info["dinfo"][i]["datatype"] == 0     # REAL4
            tmpbuf = Array{Float32}( undef, idef, jdef, kdef, rdef )
        elseif ni.info["dinfo"][i]["datatype"] == 1 # REAL8
            tmpbuf = Array{Float64}( undef, idef, jdef, kdef, rdef )
        else
            return nothing
        end
	    
        read!( fin, tmpbuf )
        tmpbuf .= ntoh.( tmpbuf )

        if undef2nan == true
            if ni.info["dinfo"][i]["datatype"] == 0     # REAL4
                tmpbuf[tmpbuf.==CNST_UNDEF4] .= NaN32

            elseif ni.info["dinfo"][i]["datatype"] == 1 # REAL8
                tmpbuf[tmpbuf.==CNST_UNDEF8] .= NaN64
            end
        end
        append!( vret, tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax] )
    end

    return vret
end  # nio_read_panda


# Treat pe/rgn in a seamless manner
mutable struct NicamAllPandaFiles
    nio    :: Array{NicamPandaFile,1}
    fhead  :: String
    glevel :: Integer
    rlevel :: Integer
    num_pe :: Integer

    function NicamAllPandaFiles(
        fhead          :: String;
	num_pe         :: Integer = -1,
	num_rgn_per_pe :: Integer = 1
    )
        self         = new()
        self.fhead   = fhead
        pe = 0
        pe6 = @sprintf(".pe%06i", pe )
        fname = fhead * pe6
        nio_ref = NicamPandaFile( fname )
        self.glevel = nio_ref.glevel
        self.rlevel = nio_ref.rlevel

        if num_pe < 0
            num_pe = Int( 10*4^self.rlevel / num_rgn_per_pe )
	end
	if num_pe * num_rgn_per_pe != 10*4^self.rlevel
	    println( "error!!!" )
	end
        self.num_pe = num_pe
	
        # allocate array for all the panda files
        self.nio = Array{NicamPandaFile}( undef, self.num_pe )

        for pe=0:num_pe-1
            pe6 = @sprintf(".pe%06i", pe )
            fname = fhead * pe6
            self.nio[pe+1] = NicamPandaFile( fname )
        end

        return self
    end
end
	
# read by pe or rgn
function Base.read(
    nio_all   :: NicamAllPandaFiles,
    varname   :: String;
    rgnid     :: Integer = -1,
    pe        :: Integer = -1,
    step      :: Integer = -1,
    k         :: Integer = -1,
    flag_halo :: Bool    = false,
    undef2nan :: Bool    = false,
    showinfo  :: Bool    = false )
    
    if pe >= 0
        return read( nio_all.nio[pe+1], varname,
                     step=step, k=k,
	             flag_halo=flag_halo, undef2nan=undef2nan,
	             showinfo=showinfo )
    elseif rgnid >= 0
        for pe=0:nio_all.num_pe-1
            if findfirst( isequal(rgnid), nio_all.nio[pe+1].info["rgnid"] ) != nothing
                return read( nio_all.nio[pe+1], varname,
	                     step=step, rgnid=rgnid, k=k,
		             flag_halo=flag_halo, undef2nan=undef2nan,
		             showinfo=showinfo )
            end
        end
    else
        # read all the regions
        tmp = read( nio_all.nio[1], varname,
                    step=step, k=k,
	            flag_halo=flag_halo, undef2nan=undef2nan,
                    showinfo=showinfo )
	vret = Array{Any,2}( undef, nio_all.num_pe, length(tmp) )

        for pe=0:nio_all.num_pe-1
            tmp = read( nio_all.nio[pe+1], varname,
                        step=step, k=k,
	                flag_halo=flag_halo, undef2nan=undef2nan,
                        showinfo=showinfo )
            vret[pe+1,:] = copy( tmp )
            
	end
        return vret
    end
end


function read_pl(
    nio_all   :: NicamAllPandaFiles,
    varname   :: String,
    rgnid_np  :: Integer = -1,
    rgnid_sp  :: Integer = -1;
    step      :: Integer = -1,
    k         :: Integer = -1,
    undef2nan :: Bool    = false,
    showinfo  :: Bool    = false
    )

    tmpbuf = read(
        nio_all,
        varname,
        rgnid=rgnid_np,
        step=step,
        k=k,
        flag_halo=true,
        undef2nan=undef2nan,
        showinfo=showinfo
    )
    idef = 2^( nio_all.glevel - nio_all.rlevel ) + 2
    jdef = idef
    odef = Int( length(tmpbuf) / ( idef * jdef ) )  # k, t

    vret_np = reshape( tmpbuf, idef, jdef, odef )

    tmpbuf = read(
        nio_all,
        varname,
        rgnid=rgnid_sp,
        step=step,
        k=k,
        flag_halo=true,
        undef2nan=undef2nan,
        showinfo=showinfo
    )

    vret_sp = reshape( tmpbuf, idef, jdef, odef )

    return [ vret_np[2,jdef,:] ; vret_sp[idef,2,:] ]

end
