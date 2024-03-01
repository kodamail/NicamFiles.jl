using Printf
#using DelimitedFiles

# ulimit -n 10240
# ulimit -n 11000


#using WriteVTK   # not necessary in the end

#using NICAMIO
using NicamFiles

sample = 1
#sample = 2
#sample = 3
#sample = 4
#sample = 5

#
# read data for all the regions at once for glevel-5, rlevel-0
#
if sample == 1
    #----- hgrid
    # sequential
    nioh_all = NicamHgridAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/hgrid/gl05/rl00/grid",
                                   access="sequential", glevel=5, rlevel=0 )
    # panda
#    nioh_all = NicamHgridAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78",
#                                   access="panda" )

    #----- hgrid -> VTK
    niov_all = NicamVTKAllFiles( nioh_all )

    #----- variables
    # panda
    ni_all2 = NicamAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78",
                             access="panda" )
    landfrc_all = Float32.( read( ni_all2, "landfrc", undef2nan=true ) )
    landfrc_pl  = Float32.( read_pl( ni_all2, "landfrc", nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )
    # direct
#    ni_all2 = NicamAllFiles( "/home/kodama/data/project/202311_NICOCO/river/landfrc/gl05/rl00/landfrc", 
#                             access="direct", glevel=5, rlevel=0, precision=8 )
#    landfrc_all = Float32.( read(    ni_all2, undef2nan=true ) )
#    landfrc_pl  = Float32.( read_pl( ni_all2, nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    ni_all3 = NicamAllFiles( "/home/kodama/data/project/202311_NICOCO/river/ico_panda/gl05/rl00/pe10/runoff_clim1958-2019",
                             access="panda" )
    runoff_liq_all = Float32.( read( ni_all3, "runoff_liq", step=1, undef2nan=true ) )
    runoff_ice_all = Float32.( read( ni_all3, "runoff_ice", step=1, undef2nan=true ) )
    runoff_liq_pl  = Float32.( read_pl( ni_all3, "runoff_liq", nioh_all.rgn_np, nioh_all.rgn_sp, step=1, undef2nan=true ) )
    runoff_ice_pl  = Float32.( read_pl( ni_all3, "runoff_ice", nioh_all.rgn_np, nioh_all.rgn_sp, step=1, undef2nan=true ) )

    # sequential
    ni_all4 = NicamAllFiles( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl05/rl00/A/topog/topog",
                             access="sequential", glevel=5, rlevel=0 )
    topog_all = Float32.( read( ni_all4, undef2nan=true ) )
    topog_pl  = Float32.( read_pl( ni_all4, nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    #----- write VTK
    nicam_vtk_grid( "sample1/sample.pe", 6, ".vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]    = landfrc_all
        nicam_vtk["runoff_liq"] = runoff_liq_all
        nicam_vtk["runoff_ice"] = runoff_ice_all
        nicam_vtk["topog"]      = topog_all
    end
    # merged file for all the regions except for poles
    nicam_vtk_grid( "sample1/sample.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]    = landfrc_all
        nicam_vtk["runoff_liq"] = runoff_liq_all
        nicam_vtk["runoff_ice"] = runoff_ice_all
        nicam_vtk["topog"]      = topog_all
    end
    nicam_vtk_grid_pl( "sample1/sample.pl.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]    = landfrc_pl
        nicam_vtk["runoff_liq"] = runoff_liq_pl
        nicam_vtk["runoff_ice"] = runoff_ice_pl
        nicam_vtk["topog"]      = topog_pl
    end

#
# read data pe by pe (do not consider pole) for glevel-5, rlevel-0
# 
elseif sample == 2
    pe_max = 10
    for pe=0:pe_max-1
        println( "pe=", pe )
        pe6 = @sprintf("%06i", pe )
        pe5 = @sprintf("%05i", pe )
	
        #----- hgrid
	# sequential
        nioh = NicamHgridFile( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/hgrid/gl05/rl00/grid.rgn"*pe5,
                               access="sequential", glevel=5, rlevel=0 ) # assume 1rgn/prc
        # panda
#        nioh = NicamHgridFile( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78.pe"*pe6,
#	                       access="panda" )

        #----- hgrid -> VTK
        niov = NicamVTKFile( nioh )
    
        #----- variables
	# panda
        ni2 = NicamFile( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78.pe"*pe6,
	                 access="panda" )
        landfrc    = Float32.( read( ni2, "landfrc",            undef2nan=true ) )
        lakefrc    = Float32.( read( ni2, "lakefrc",            undef2nan=true ) )
	# direct
#        ni2 = NicamFile( "/home/kodama/data/project/202311_NICOCO/river/landfrc/gl05/rl00/landfrc.rgn"*pe5,
#	                 access="direct", glevel=5, rlevel=0, precision=8 )
#        landfrc    = Float32.( read( ni2, undef2nan=true ) )
	
        ni3 = NicamFile( "/home/kodama/data/project/202311_NICOCO/river/ico_panda/gl05/rl00/pe10/runoff_clim1958-2019.pe"*pe6,
	                 access="panda" )
        runoff_liq = Float32.( read( ni3, "runoff_liq", step=1, undef2nan=true ) )
        runoff_ice = Float32.( read( ni3, "runoff_ice", step=1, undef2nan=true ) )

        # sequential
        ni4 = NicamFile( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl05/rl00/A/topog/topog.rgn"*pe5, 
                         access="sequential", glevel=5, rlevel=0 )
        topog = Float32.( read( ni4, undef2nan=true ) )

        #----- write VTK
        vtk_grid("sample2/sample.pe"*pe6*".vtu", niov.vtk_points, niov.vtk_cells ) do vtk
            vtk["landfrc"]    = landfrc
            vtk["runoff_liq"] = runoff_liq
            vtk["runoff_ice"] = runoff_ice
            vtk["topog"]      = topog
        end

    end

#
# read data for all the regions at once for glevel-5, rlevel-2
#
elseif sample == 3
    #----- hgrid
    # panda
    nioh_all = NicamHgridAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78",
                                   access="panda" )

    #----- hgrid -> VTK
    niov_all = NicamVTKAllFiles( nioh_all )

    #----- variables
    # panda
    ni_all2 = NicamAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78",
                             access="panda" )
    landfrc_all = Float32.( read(    ni_all2, "landfrc", undef2nan=true ) )
    landfrc_pl  = Float32.( read_pl( ni_all2, "landfrc", nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )
    lakefrc_all = Float32.( read(    ni_all2, "lakefrc", undef2nan=true ) )
    lakefrc_pl  = Float32.( read_pl( ni_all2, "lakefrc", nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    ni_all3 = NicamAllFiles( "/home/kodama/data/project/202311_NICOCO/river/ico_panda/gl05/rl02/pe160/runoff_clim1958-2019",
                             access="panda" )
    runoff_liq_all = Float32.( read( ni_all3, "runoff_liq", step=1, undef2nan=true ) )
    runoff_ice_all = Float32.( read( ni_all3, "runoff_ice", step=1, undef2nan=true ) )
    runoff_liq_pl  = Float32.( read_pl( ni_all3, "runoff_liq", nioh_all.rgn_np, nioh_all.rgn_sp, step=1, undef2nan=true ) )
    runoff_ice_pl  = Float32.( read_pl( ni_all3, "runoff_ice", nioh_all.rgn_np, nioh_all.rgn_sp, step=1, undef2nan=true ) )

    #----- write VTK
    # file per pe
#    nicam_vtk_grid( "sample3/sample.pe", 6, ".vtu", niov_all ) do nicam_vtk
#        nicam_vtk["landfrc"]    = landfrc_all
#        nicam_vtk["lakefrc"]    = lakefrc_all
#        nicam_vtk["runoff_liq"] = runoff_liq_all
#        nicam_vtk["runoff_ice"] = runoff_ice_all
#    end
    # merged file for all the regions except for poles
    nicam_vtk_grid( "sample3/sample.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]    = landfrc_all
        nicam_vtk["lakefrc"]    = lakefrc_all
        nicam_vtk["runoff_liq"] = runoff_liq_all
        nicam_vtk["runoff_ice"] = runoff_ice_all
    end
    # pole
    nicam_vtk_grid_pl( "sample3/sample.pl.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]    = landfrc_pl
        nicam_vtk["lakefrc"]    = lakefrc_pl
        nicam_vtk["runoff_liq"] = runoff_liq_pl
        nicam_vtk["runoff_ice"] = runoff_ice_pl
    end


#
# read data pe by pe (do not consider pole) for glevel-11, rlevel-5
# 
elseif sample == 4
    pe_min = 0
#    pe_max = 10240
    pe_max = 64
    for pe=pe_min:pe_max-1
        println( "pe=", pe )
        pe6 = @sprintf("%06i", pe )
        pe5 = @sprintf("%05i", pe )

        #----- hgrid
	# sequential
        nioh = NicamHgridFile( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/hgrid/gl11/rl05/grid.rgn"*pe5,
                               access="sequential", glevel=11, rlevel=5 ) # assume 1rgn/prc

        #----- hgrid -> VTK
        niov = NicamVTKFile( nioh )
    
        #----- variables
	# direct
        ni2 = NicamFile( "/home/kodama/data/project/202311_NICOCO/river/landfrc/gl11/rl05/c01/landmask_mod.rgn"*pe5,
	                 access="direct", glevel=11, rlevel=5, precision=8 )
        landfrc    = Float32.( read( ni2, undef2nan=true ) )

        ni3 = NicamFile( "/home/kodama/data/project/202311_NICOCO/river/ico_panda/gl11/rl05/c01/pe10240/runoff_clim1958-2019.pe"*pe6,
	                 access="panda" )
        runoff_liq = Float32.( read( ni3, "runoff_liq", step=1, undef2nan=true ) )
        runoff_ice = Float32.( read( ni3, "runoff_ice", step=1, undef2nan=true ) )

        #----- write VTK
        vtk_grid("sample4/sample.pe"*pe6*".vtu", niov.vtk_points, niov.vtk_cells ) do vtk
            vtk["landfrc"] = landfrc
            vtk["runoff_liq"] = runoff_liq
            vtk["runoff_ice"] = runoff_ice
        end

    end



elseif sample == 5
    #----- hgrid
    # sequential
    nioh_all = NicamHgridAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/hgrid/gl11/rl05/grid",
                                   access="sequential", glevel=11, rlevel=5 )  # assume 1rgn/prc
#    nioh_all = NicamHgridAllFiles( "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/hgrid/gl09/rl03/grid",
#                                   access="sequential", glevel=9, rlevel=3 )  # assume 1rgn/prc

    #----- hgrid -> VTK
    niov_all = NicamVTKAllFiles( nioh_all )

    #----- variables
    # direct
    ni_all2 = NicamAllFiles( "/home/kodama/data/project/202311_NICOCO/river/landfrc/gl11/rl05/c01/landmask_mod", 
                             access="direct", glevel=11, rlevel=5, precision=8 )
#    ni_all2 = NicamAllFiles( "/home/kodama/data/project/202311_NICOCO/river/landfrc/gl09/rl03/c01/landmask_mod", 
#                             access="direct", glevel=9, rlevel=3, precision=8 )
    landfrc_all = Float32.( read(    ni_all2, undef2nan=true ) )
    landfrc_pl  = Float32.( read_pl( ni_all2, nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    ni_all3 = NicamAllFiles( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl11/rl05/A/slidx/slidx", 
                             access="direct", glevel=11, rlevel=5, precision=8 )
#    ni_all3 = NicamAllFiles( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl09/rl03/A/slidx/slidx", 
#                             access="direct", glevel=9, rlevel=3, precision=8 )
    slidx_all = Float32.( read(    ni_all3, undef2nan=true ) )
    slidx_pl  = Float32.( read_pl( ni_all3, nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    ni_all4 = NicamAllFiles( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl11/rl05/A/topog/topog", 
                             access="sequential", glevel=11, rlevel=5 )
#    ni_all4 = NicamAllFiles( "/home/kodama/data/NICAM_DATABASE_CMIP6/sfcdata.v2/gl11/rl05/A/topog/topog", 
#                             access="sequential", glevel=9, rlevel=3 )
    topog_all = Float32.( read(    ni_all4, undef2nan=true ) )
    topog_pl  = Float32.( read_pl( ni_all4, nioh_all.rgn_np, nioh_all.rgn_sp, undef2nan=true ) )

    #----- write VTK
    # merged file for all the regions except for poles
    nicam_vtk_grid( "sample5_gl11/sample.vtu", niov_all ) do nicam_vtk
#    nicam_vtk_grid( "sample5_gl09/sample.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]  = landfrc_all
        nicam_vtk["slidx"]    = slidx_all
        nicam_vtk["topog"]    = topog_all
    end
    nicam_vtk_grid_pl( "sample5_gl11/sample.pl.vtu", niov_all ) do nicam_vtk
#    nicam_vtk_grid_pl( "sample5_gl09/sample.pl.vtu", niov_all ) do nicam_vtk
        nicam_vtk["landfrc"]  = landfrc_pl
        nicam_vtk["slidx"]    = slidx_pl
        nicam_vtk["topog"]    = topog_pl
    end

end
