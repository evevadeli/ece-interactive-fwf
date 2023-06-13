"""configuration constants"""

## -------- Basal melt information -------------------------
gamma = 0.08*0.65        #Basal melt calibration parameter based on sea level response function: 
                         #Ice-sheet model specific
                         #Amundsen Sea calibration - EC-Earth3 IMAU (Van der Linden et al, 2023, The Cryosphere); 
                         #reduced by 35% to account for freshwater feedback (Lambert et al., manuscript)

# Depths between which basal melt is distributed [in m] 
bm_dep1 = 200            #shallowest depth, ice front draft (code searches closest depth level bound below this depth)
bm_dep2 = 700            #deepest depth, grounding line or seabed below ice front (code searches closest depth level bound above this depth)

## --------- Linear response functions information ----------
bm = '08'                #basal melt forcing to create linear response functions
ism = 'IMAU_VUB'         #ice sheet model
running_mean_period = 30 #interval over which running mean ocean temperatures are computed in years

## --------- Initial conditions -----------------------------
## Total basal melt + calving (P-E) in piControl simulation
FWF_total_yearmin = 3726 #Gt/yr #Apply average value from (new) piControl: 3315 Gt/yr (3314.661115188267)