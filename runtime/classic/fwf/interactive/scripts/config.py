"""configuration constants"""
gamma = 0.08 #Basal melt calibration parameter based on sea level response function: Amundsen Sea calibration - EC-Earth3 IMAU
bm = '08' #basal melt forcing
bm_dep1 = 200 #depths between which basal melt is distributed [in m]
bm_dep2 = 700
## Linear response functions
ism = 'IMAU_VUB' #ice sheet model
running_mean_period = 30 #interval over which running mean ocean temperatures are computed in years