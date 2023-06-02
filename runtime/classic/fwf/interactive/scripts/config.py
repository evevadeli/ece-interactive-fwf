"""configuration constants"""
gamma = 0.08 #Basal melt calibration parameter based on sea level response function: Amundsen Sea calibration - EC-Earth3 IMAU
## Linear response functions
ism = 'IMAU_VUB' #ice sheet model
bm = '08' #basal melt forcing
running_mean_period = 30 #interval over which running mean ocean temperatures are computed in years