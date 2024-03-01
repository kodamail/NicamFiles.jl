# Reference: https://qiita.com/RhT/items/a0dcd6a8065027226097

# Treat single NICAM file
abstract type NicamFile end
abstract type NicamNativeFile <: NicamFile end

# Treat NICAM files for all the regions
abstract type NicamAllFiles end
abstract type NicamAllNativeFiles <: NicamAllFiles end

function NicamFile(
    fname     :: String;
    access    :: String  = "panda",
    glevel    :: Integer = -1,     # for direct or sequential
    rlevel    :: Integer = -1,     # for direct or sequential
    precision :: Integer = -1,     # for direct
    showinfo  :: Bool    = false
)
    
    if access == "panda"
        return NicamPandaFile( fname, showinfo=showinfo )

    elseif access == "direct"
        return NicamDirectFile( fname, glevel, rlevel, precision )

    elseif access == "sequential"
        return NicamSequentialFile( fname, glevel, rlevel )

    end
    
    return nothing
end

function NicamAllFiles(
    fhead          :: String;
    access         :: String  = "panda",
    glevel         :: Integer = -1,     # for direct or sequential
    rlevel         :: Integer = -1,     # for direct or sequential
    precision      :: Integer = -1,     # for direct or sequential
    num_pe         :: Integer = -1,
    num_rgn_per_pe :: Integer = 1,
    showinfo       :: Bool    = false
)
    if access == "panda"
        return NicamAllPandaFiles(
	    fhead, 
	    num_pe=num_pe, num_rgn_per_pe=num_rgn_per_pe )

    elseif access == "direct"
        return NicamAllDirectFiles(
            fhead, glevel, rlevel, precision )

    elseif access == "sequential"
        return NicamAllSequentialFiles(
            fhead, glevel, rlevel )

    end
    
    return nothing
end


function Base.close( ni::NicamFile )
    close( ni.fin )
end
