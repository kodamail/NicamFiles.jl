using FortranFiles

# sequential file must have halo data in file

struct NicamSequentialFile <: NicamNativeFile
    fin    :: FortranFile
    fname  :: String
    glevel :: Integer
    rlevel :: Integer
end

function NicamSequentialFile(
    fname  :: String,
    glevel :: Integer,
    rlevel :: Integer
)
    fin = FortranFile( fname, convert="big-endian" )

    return NicamSequentialFile( fin, fname, glevel, rlevel )
end


# special case used in hgrid.jl
function Base.read(
    ni   :: NicamSequentialFile,
    spec :: Any;
    step :: Integer = -1
)
    fin = ni.fin
    
    if step > 0
        rewind( fin )
        for i=1:step-1
            read( fin )  # skip
	end
    end

    return read( fin, spec )
end

function Base.read(
    ni        :: NicamSequentialFile;
    step      :: Integer = -1,
    flag_halo :: Bool    = false,
    undef2nan :: Bool    = false
)
    fin = ni.fin

    vret = Array{Any}( undef, 0 )
    idef = 2^( ni.glevel - ni.rlevel ) + 2
    jdef = idef
    tmpbuf = Array{Float64}( undef, idef, jdef )  # REAL8

    if step > 0
        rewind( fin )
        for i=1 : step-1
            read( fin )  # skip
	end
    end

    read( fin, tmpbuf )
    
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

    return tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax]
end

#=
function Base.read( ni::NicamSequentialFile )
    return read( ni.fin )  # skip
end
=#


mutable struct NicamAllSequentialFiles <: NicamAllNativeFiles
    nio     :: Array{NicamSequentialFile,1}
    fhead   :: String
    glevel  :: Integer
    rlevel  :: Integer
    num_rgn :: Integer

    function NicamAllSequentialFiles(
        fhead  :: String,
        glevel :: Integer,
        rlevel :: Integer
    )
        self         = new()
        self.fhead   = fhead
        self.glevel  = glevel
        self.rlevel  = rlevel
	self.num_rgn = 10*4^self.rlevel

        # allocate array for all the files
        self.nio = Array{NicamSequentialFile}( undef, self.num_rgn )

        for rgn=0:self.num_rgn-1
            rgn5 = @sprintf(".rgn%05i", rgn )
            fname = fhead * rgn5
            self.nio[rgn+1] = NicamSequentialFile( fname, self.glevel, self.rlevel )
        end

        return self
    end
end

# read by rgn
# -> see direct.jl

# pl
# -> see direct.jl
