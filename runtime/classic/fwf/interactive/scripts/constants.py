""" physical constants (SI units) """
# Parameters to compute basal ice shelf melt (Favier 2019)
rho_i             = 917.          # [kg m-3]         ice density
rho_sw            = 1028.         # [kg m-3]         sea water density
c_po              = 3974.         # [ J kg-1 K-1]    specific heat capacity of ocean mixed layer
L_i               = 3.34*10**5    # [J kg^-1]        latent heat of fusion of ice
T_f               = -1.6          # [deg C]          freezing-melting point temperature # !could also be computed from salinity and temperature

""" unit conversions """
spy               = 3600*24*365   # [s yr^-1]
kg_per_Gt         = 1e12         # [kg] to [Gt]
kgps_to_Gtpy      = 1/kg_per_Gt/spy # [kg/s] to [Gt/yr]