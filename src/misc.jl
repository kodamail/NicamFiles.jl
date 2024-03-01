# constants
#CNST_UNDEF4 = -9.9999f30                # undefined value (REAL4)
#CNST_UNDEF8 = -9.9999e30                # undefined value (REAL8)
CNST_UNDEF4 = -9.99f34                # undefined value (REAL4), old NICAM
CNST_UNDEF8 = -9.99e34                # undefined value (REAL8), old NICAM


"""
    uint2char( ui )
Convert data from UInt to Char with null fulfilled if necessary.
"""
function uint2char( ui )
    if ui == 0
        return ""
    else
        return Char(ui)
    end
end
