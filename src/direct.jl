struct NicamDirectFile <: NicamNativeFile
    fin       :: IOStream
    fname     :: String
    glevel    :: Integer
    rlevel    :: Integer
    precision :: Integer   # 4 or 8
end

function NicamDirectFile(
    fname     :: String,
    glevel    :: Integer,
    rlevel    :: Integer,
    precision :: Integer
)
    fin = open( fname, "r" )
    
    return NicamDirectFile( fin, fname, glevel, rlevel, precision )
end

function Base.read(
    ni        :: NicamDirectFile;
    step      :: Integer = 1,
    flag_halo :: Bool    = false,
    undef2nan :: Bool    = false
)

    vret = Array{Any}( undef, 0 )

    idef = 2^( ni.glevel - ni.rlevel ) + 2
    jdef = idef

    fin = ni.fin

    if ni.precision == 4     # REAL4
        tmpbuf = Array{Float32}( undef, idef, jdef )
    elseif ni.precision == 8     # REAL8
        tmpbuf = Array{Float64}( undef, idef, jdef )
    end

    seek( fin, (step-1)*idef*jdef )

    read!( fin, tmpbuf )
    tmpbuf .= ntoh.( tmpbuf )
	
    imin = 1 ; imax = idef
    jmin = 1 ; jmax = jdef
    if ! flag_halo
        # halo will be trimmed
        imin = 2 ; imax = idef-1
        jmin = 2 ; jmax = jdef-1
    end
    kmin = 1
    kmax = 1
    rmin = 1
    rmax = 1

    if undef2nan == true
        if ni.precision == 4     # REAL4
            tmpbuf[tmpbuf.==CNST_UNDEF4] .= NaN32

        elseif ni.precision == 8 # REAL8
            tmpbuf[tmpbuf.==CNST_UNDEF8] .= NaN64
        end
    end
    append!( vret, tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax] )

    return vret
end  # Base.read

mutable struct NicamAllDirectFiles <: NicamAllNativeFiles
    nio       :: Array{NicamDirectFile,1}
    fhead     :: String
    glevel    :: Integer
    rlevel    :: Integer
    precision :: Integer
    num_rgn   :: Integer

    function NicamAllDirectFiles(
        fhead     :: String,
        glevel    :: Integer,
        rlevel    :: Integer,
        precision :: Integer
    )
        self           = new()
        self.fhead     = fhead
        self.glevel    = glevel
        self.rlevel    = rlevel
        self.precision = precision
	self.num_rgn   = 10*4^self.rlevel

        # allocate array for all the files
        self.nio = Array{NicamDirectFile}( undef, self.num_rgn )

        for rgn=0:self.num_rgn-1
            rgn5 = @sprintf(".rgn%05i", rgn )
            fname = fhead * rgn5
            self.nio[rgn+1] = NicamDirectFile( fname, self.glevel, self.rlevel, self.precision )
        end

        return self
    end
end


# read by rgn
# for NicamAllNativeFiles (direct/sequential)
function Base.read(
#    nio_all   :: NicamAllDirectFiles;
    nio_all   :: NicamAllNativeFiles;
    rgnid     :: Integer = -1,
    step      :: Integer = 1,
    flag_halo :: Bool    = false,
    undef2nan :: Bool    = false
)
    if rgnid >= 0
        return read( nio_all.nio[rgnid+1],
                     step=step, 
	             flag_halo=flag_halo, undef2nan=undef2nan )
		     
    else
        # read all the regions
        tmp = read( nio_all.nio[1],
                    step=step, 
	            flag_halo=flag_halo, undef2nan=undef2nan )
	vret = Array{Any,2}( undef, nio_all.num_rgn, length(tmp) )

        for rgn=0:nio_all.num_rgn-1
            tmp = read( nio_all.nio[rgn+1], 
                        step=step, 
	                flag_halo=flag_halo, undef2nan=undef2nan )
            vret[rgn+1,:] = copy( tmp )
            
	end
        return vret
    end
    
    return nothing
end


# for NicamAllNativeFiles (direct/sequential)
function read_pl(
#    nio_all   :: NicamAllDirectFiles,
    nio_all   :: NicamAllNativeFiles,
    rgnid_np  :: Integer = -1,
    rgnid_sp  :: Integer = -1;
    step      :: Integer = 1,
    undef2nan :: Bool    = false
)
    tmpbuf = read(
        nio_all,
        rgnid=rgnid_np,
        step=step,
        flag_halo=true,
        undef2nan=undef2nan )
    idef = 2^( nio_all.glevel - nio_all.rlevel ) + 2
    jdef = idef
    odef = Int( length(tmpbuf) / ( idef * jdef ) )  # k, t

    vret_np = reshape( tmpbuf, idef, jdef, odef )

    tmpbuf = read(
        nio_all,
        rgnid=rgnid_sp,
        step=step,
        flag_halo=true,
        undef2nan=undef2nan )

    vret_sp = reshape( tmpbuf, idef, jdef, odef )

    return [ vret_np[2,jdef,:] ; vret_sp[idef,2,:] ]
end
