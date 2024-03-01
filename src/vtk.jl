using WriteVTK

#TODO: construct same structure as hgrid

mutable struct NicamVTKFile   # per file
    vtk_points :: Array{Float32,2}
    vtk_cells  :: Array{MeshCell{VTKCellType,Array{Int64,1}},1}

    function NicamVTKFile(
        nioh :: NicamHgridFile
    )
        self = new()
        ij2p(T)      = T[1] + (T[2]-1) * (2^nioh_all.gmr)
        p2ij(p)      = (p-1) % (2^nioh.gmr) + 1, (p-1) ÷ (2^nioh.gmr) + 1
        ij2p_halo(T) = (T[1]+1) + T[2] * (2^nioh.gmr+2)
        p2ij_halo(p) = (p-1) % (2^nioh.gmr+2), (p-1) ÷ (2^nioh.gmr+2)

        ijm(T)   = T[1]  , T[2]-1
        imj(T)   = T[1]-1, T[2]
        imjm(T)  = T[1]-1, T[2]-1
        
        self.vtk_points = Float32.(
	    [ nioh.data["hix"]' nioh.data["hjx"]' ;
              nioh.data["hiy"]' nioh.data["hjy"]' ;
	      nioh.data["hiz"]' nioh.data["hjz"]' ])
        self.vtk_cells = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, nioh.gall_in )  # TODO: add halo cell if necessary
  
	joffset = nioh.gall

	for p=1 : nioh.gall_in  # p: no halo  px: with halo
            p1 = ij2p_halo(p2ij(p)) + joffset
	    p2 = ij2p_halo(p2ij(p))
	    p3 = ij2p_halo(ijm(p2ij(p))) + joffset
	    p4 = ij2p_halo(imjm(p2ij(p)))
	    p5 = ij2p_halo(imjm(p2ij(p))) + joffset
	    p6 = ij2p_halo(imj(p2ij(p)))
            self.vtk_cells[p] = MeshCell(VTKCellTypes.VTK_POLYGON, [ p1,p2,p3,p4,p5,p6 ])
        end

        return self
    end
end

mutable struct NicamVTKAllFiles
    niov          :: Array{NicamVTKFile,1}  # array of vtk files
    vtk_points_np :: Array{Float32,2}
    vtk_points_sp :: Array{Float32,2}
    vtk_cells_np  :: Array{MeshCell{VTKCellType,Array{Int64,1}},1}
    vtk_cells_sp  :: Array{MeshCell{VTKCellType,Array{Int64,1}},1}
    vtk_points_pl :: Array{Float32,2}
    vtk_cells_pl  :: Array{MeshCell{VTKCellType,Array{Int64,1}},1}

    function NicamVTKAllFiles(
        nioh_all::NicamHgridAllFiles
    )
        self = new()

        self.niov = Array{NicamVTKFile}( undef, nioh_all.num_pe )
        for pe=0:nioh_all.num_pe-1
	    self.niov[pe+1] = NicamVTKFile( nioh_all.nioh[pe+1] )
	end

        self.vtk_points_np = Float32.(
	    [ nioh_all.data_np[1]["cellx"] nioh_all.data_np[2]["cellx"] nioh_all.data_np[3]["cellx"] nioh_all.data_np[4]["cellx"] nioh_all.data_np[5]["cellx"] ;
              nioh_all.data_np[1]["celly"] nioh_all.data_np[2]["celly"] nioh_all.data_np[3]["celly"] nioh_all.data_np[4]["celly"] nioh_all.data_np[5]["celly"] ;
              nioh_all.data_np[1]["cellz"] nioh_all.data_np[2]["cellz"] nioh_all.data_np[3]["cellz"] nioh_all.data_np[4]["cellz"] nioh_all.data_np[5]["cellz"] ])
        self.vtk_cells_np = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, 1 )
        self.vtk_cells_np[1] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 1, 2, 3, 4, 5 ])
        #
        self.vtk_points_sp = Float32.(
	    [ nioh_all.data_sp[1]["cellx"] nioh_all.data_sp[2]["cellx"] nioh_all.data_sp[3]["cellx"] nioh_all.data_sp[4]["cellx"] nioh_all.data_sp[5]["cellx"] ;
              nioh_all.data_sp[1]["celly"] nioh_all.data_sp[2]["celly"] nioh_all.data_sp[3]["celly"] nioh_all.data_sp[4]["celly"] nioh_all.data_sp[5]["celly"] ;
              nioh_all.data_sp[1]["cellz"] nioh_all.data_sp[2]["cellz"] nioh_all.data_sp[3]["cellz"] nioh_all.data_sp[4]["cellz"] nioh_all.data_sp[5]["cellz"] ])
        self.vtk_cells_sp = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, 1 )
        self.vtk_cells_sp[1] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 1, 2, 3, 4, 5 ])


        self.vtk_points_pl = Float32.(
	    [ nioh_all.data_np[1]["cellx"] nioh_all.data_np[2]["cellx"] nioh_all.data_np[3]["cellx"] nioh_all.data_np[4]["cellx"] nioh_all.data_np[5]["cellx"] nioh_all.data_sp[1]["cellx"] nioh_all.data_sp[2]["cellx"] nioh_all.data_sp[3]["cellx"] nioh_all.data_sp[4]["cellx"] nioh_all.data_sp[5]["cellx"] ;
              nioh_all.data_np[1]["celly"] nioh_all.data_np[2]["celly"] nioh_all.data_np[3]["celly"] nioh_all.data_np[4]["celly"] nioh_all.data_np[5]["celly"] nioh_all.data_sp[1]["celly"] nioh_all.data_sp[2]["celly"] nioh_all.data_sp[3]["celly"] nioh_all.data_sp[4]["celly"] nioh_all.data_sp[5]["celly"] ;
              nioh_all.data_np[1]["cellz"] nioh_all.data_np[2]["cellz"] nioh_all.data_np[3]["cellz"] nioh_all.data_np[4]["cellz"] nioh_all.data_np[5]["cellz"] nioh_all.data_sp[1]["cellz"] nioh_all.data_sp[2]["cellz"] nioh_all.data_sp[3]["cellz"] nioh_all.data_sp[4]["cellz"] nioh_all.data_sp[5]["cellz"] ])
        self.vtk_cells_pl = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, 2 )
        self.vtk_cells_pl[1] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 1, 2, 3, 4, 5 ])
        self.vtk_cells_pl[2] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 6, 7, 8, 9, 10 ])

	return self
    end
end


function nicam_vtk_grid(
    f        :: Function,
    fhead    :: String,
    digit    :: Integer,
    ext      :: String,
    niov_all :: NicamVTKAllFiles )
    
    nicam_vtk = Dict()

    try
        f( nicam_vtk )
	
    finally
        for pe=0: length(niov_all.niov)-1
	    pe0 = pe
	    if digit == 6
	        pe0 = @sprintf("%06i", pe )
	    elseif digit == 5
                pe0 = @sprintf("%05i", pe )
	    end
	    
            vtk_grid( fhead * pe0 * ext, niov_all.niov[pe+1].vtk_points, niov_all.niov[pe+1].vtk_cells ) do vtk
                for ( key, value ) in nicam_vtk
	            vtk[key] = value[pe+1,:]
	        end
            end
        end
    end
end

# merge all the VTK files
# poles are ignored
function nicam_vtk_grid(
    f        :: Function,
    fname    :: String,
    niov_all :: NicamVTKAllFiles )
    
    nicam_vtk = Dict()

    try
        f( nicam_vtk )
	
    finally
        size_points = size(niov_all.niov[1].vtk_points)
	num_cells  = length(niov_all.niov[1].vtk_cells)
        vtk_points = Array{Float32}( undef, size_points[1], size_points[2]*length(niov_all.niov) )
        vtk_cells  = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, length(niov_all.niov)*num_cells )

        for pe=0: length(niov_all.niov)-1
	    vtk_points[:,pe*size_points[2]+1:(pe+1)*size_points[2]] .= niov_all.niov[pe+1].vtk_points[:,:]
	    vtk_cells[pe*num_cells+1:(pe+1)*num_cells]              .= niov_all.niov[pe+1].vtk_cells[:]

            # shift indeces
	    for c=pe*num_cells+1: (pe+1)*num_cells
	        vtk_cells[c].connectivity .+= pe * size_points[2]
	    end
	end
	    
        vtk_grid( fname, vtk_points, vtk_cells ) do vtk
            for ( key, value ) in nicam_vtk
                vtk[key] = reshape(value',:)
	    end
        end
	
    end
end


function nicam_vtk_grid_pl(
    f        :: Function,
    fname    :: String,
    niov_all :: NicamVTKAllFiles
)
    nicam_vtk = Dict()

    try
        f( nicam_vtk )
	
    finally
        vtk_grid( fname, niov_all.vtk_points_pl, niov_all.vtk_cells_pl ) do vtk
            for ( key, value ) in nicam_vtk
                vtk[key] = value
            end
        end
    end
end
