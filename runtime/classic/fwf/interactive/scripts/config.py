"""configuration constants"""

## -------- Basal melt information -------------------------
#gamma = 0.15 * 0.65      #Basal melt calibration parameter based on sea level response function: 
                         #Ice-sheet model specific
                         #Amundsen Sea calibration - EC-Earth3 IMAU (Van der Linden et al, 2023, The Cryosphere); 
                         #reduced by 35% to account for freshwater feedback (Lambert et al., manuscript)

# Depths between which basal melt is distributed [in m] 
#bm_dep1 = 200            #shallowest depth, ice front draft (code searches closest depth level bound below this depth)
#bm_dep2 = 700            #deepest depth, grounding line or seabed below ice front (code searches closest depth level bound above this depth)

# Areas over which basal melt and calving are distributed
fwf_distribution = 'larmip' #options: uniform (over all regions > 0) or 'larmip' (associated with LARMIP regions)

## --------- Linear response functions information ----------
bm = '08'                #basal melt forcing to create linear response functions
ism = 'IMAU_VUB'         #ice sheet model
running_mean_period = 5 #interval over which running mean ocean temperatures are computed in years

## --------- Initial conditions -----------------------------
## Total basal melt + calving (P-E) in piControl simulation
FWF_total_yearmin = 3315 #3438 Gt/yr for 1971-2000 #Apply average value from (new) piControl: 3315 Gt/yr