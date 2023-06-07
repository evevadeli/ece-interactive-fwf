# Initialise freshwater forcing experiment by creating initial freshwater forcing file and depth distribution files
# 2023-06: Eveline van der Linden (KNMI) linden@knmi.nl

## Import modules
import os
import xarray as xr
import pandas as pd
import numpy as np
import sys

import ThetaoSectors as TS
from config import bm_dep1, bm_dep2, FWF_total_yearmin
from constants import spy, kg_per_Gt


print('Number of arguments:', len(sys.argv), 'arguments.')
print('Argument List:', str(sys.argv))

## Year of run + total experiment
year_min = int(sys.argv[1])
exp_name = str(sys.argv[2])
start_dir = str(sys.argv[3])


########################## File definition #########################
## Paths
path_input = f'{start_dir}/fwf/interactive/input/'
path_forcing_file = f'{start_dir}/fwf/interactive/forcing_files/{exp_name}/' #Create other path (scratch)

## Input data
file_area = f'{path_input}/areacello_Ofx_EC-Earth3_historical_r1i1p1f1_gn.nc'
file_basal_melt_mask = f'{path_input}/basal_melt_mask_ORCA1_ocean.nc'
file_calving_mask = f'{path_input}/calving_mask_ORCA1_ocean.nc'

# For lev_bnds & time_counter (12 months, to be replaced):
run_dir = '/scratch/nk0j/ecearth3-cmip6'
leg_number ='001'
exp_name = '5icu'
year = '1850'
file_thetao = f'{run_dir}/{exp_name}/output/nemo/{leg_number}/{exp_name}_1m_{year}0101_{year}1231_opa_grid_T_3D.nc' #other output format

## Output data
## FWF for EC-Earth (freshwater forcing computed from year yyyy is applied in year yyyy+1)
file_forcing = f'{path_forcing_file}/FWF_LRF_y{year_min}.nc'
file_bm_depth1 = f'{path_forcing_file}/basal_melt_depth1.nc' #shallowest depth
file_bm_depth2 =f'{path_forcing_file}/basal_melt_depth2.nc' # deepest depth

# Constants
spy               = 3600*24*365   # [s yr^-1]
kg_per_Gt         = 1e12         # [kg] to [Gt]

############################# Create FWF_LRF_y1850.nc (first year freshwater forcing) #################

# Baseline FWF freshwater forcing piControl mean
FWF_total_Gt = FWF_total_piControl # 3300 Gt/yr
print('Total freshwater forcing: ', FWF_total_Gt, ' Gt per yr')

# Open masks for calving and basal melt
basal_melt_mask = xr.open_dataset(file_basal_melt_mask)
calving_mask = xr.open_dataset(file_calving_mask)

## Open areacello dataarray and compute area corresponding with  distribution mask
ds_area = xr.open_dataset(file_area)

basal_melt_area = ds_area.areacello.where(basal_melt_mask.basal_melt_mask).sum('j').sum('i').values
calving_area = ds_area.areacello.where(calving_mask.calving_mask).sum('j').sum('i').values

print('Basal melt area: ', basal_melt_area*1.e-12, '10^6 km^2')
print('Calving area: ', calving_area*1.e-12, '10^6 km^2')

#The distribution of this total meltwater flux between basal melt and calving is fixed using the observed mass loss by Rignot et al. 2013 
FWF_calving_Gt = 0.45 * FWF_total_Gt
FWF_basal_melt_Gt = 0.55 * FWF_total_Gt

print('Calving piControl: ', FWF_calving_Gt, ' Gt')
print('Basal melt piControl: ', FWF_basal_melt_Gt, ' Gt')
        
# Convert Gt yr-1 to kg m-2 s-1
basal_melt_flux = FWF_basal_melt_Gt*kg_per_Gt/spy/float(basal_melt_area)
calving_flux = FWF_calving_Gt*kg_per_Gt/spy/float(calving_area)

# Apply flux to masked region
basal_melt_distribution = basal_melt_flux*basal_melt_mask
calving_distribution = calving_flux*calving_mask

# Rename variables for nemo
FWF_basal_melt = basal_melt_distribution.rename({'basal_melt_mask':'sorunoff_f'})
FWF_calving = calving_distribution.rename({'calving_mask':'socalving_f'})

## (Re)open thetao dataset to obtain time
ds = xr.open_dataset(file_thetao)
t = ds.time_counter

# Add time dimension to dataarrays (12 months); flux is equal throughout the year
FWF_basal_melt = FWF_basal_melt.sorunoff_f.expand_dims({'time_counter': t.values})
FWF_basal_melt.attrs = {'long_name':'basal melt flux', 'units':'kg/m^2/s'}
FWF_basal_melt = FWF_basal_melt.fillna(0) #set nans to zeros

FWF_calving = FWF_calving.socalving_f.expand_dims({'time_counter': t.values})
FWF_calving.attrs = {'long_name':'calving flux', 'units':'kg/m^2/s'}
FWF_calving = FWF_calving.fillna(0) #set nans to zeros

# Merge dataarrays in one dataset
ds_FWF = xr.merge([FWF_basal_melt, FWF_calving])
ds_FWF = ds_FWF.assign_coords({'time_counter': t.values})
ds_FWF.attrs = {'long_name': 'freshwater fluxes', 'units':'kg/m^2/s'}

# Write to file  (to be read in by EC-Earth in the next year)
print(file_forcing)

if os.path.isfile(file_forcing):    
    os.remove(file_forcing)    

ds_FWF.to_netcdf(file_forcing, unlimited_dims=['time_counter'])

############################# Vertical distribution of basal melt ###################################
# Create zshelf files based on horizontal basal melt distribution for basal melt distribution over depth
# Read lev bnds from file_thetao
ds_lev_bnds = ds['olevel_bounds']

d = 0
for depth in [bm_dep1, bm_dep2]:
    # Find oceanic layers that sit fully within the depth bounds
    if d == 0:
        lev_ind = TS.nearest_above(ds_lev_bnds[:,0],depth) #above = deeper than
        depth_nemo = ds_lev_bnds[lev_ind,0].values
        print('Upper bound of ocean layer used for basal melt distribution: ' , depth_nemo, ' m')
    elif d == 1:
        lev_ind= TS.nearest_below(ds_lev_bnds[:,1],depth) #below = shallower than
        depth_nemo = ds_lev_bnds[lev_ind,1].values
        print('Lower bound of ocean layer used for basal melt distribution: ' , depth_nemo, ' m')

    print('Creating zshelf ncfile')
    ds_bm_mask = xr.open_dataarray(file_basal_melt_mask)

    ds_zshelf = ds_bm_mask.where(ds_bm_mask > 0)
    ds_zshelf.name = 'bmdepth'
    ds_zshelf = ds_zshelf.fillna(0)
    df_zshelf = ds_zshelf.values
    df_zshelf[df_zshelf>0] = depth_nemo
    ds_zshelf.attrs = {'long_name':'basal melt depth', 'units':'m'}
    ds_zshelf = ds_zshelf.expand_dims({'time_counter': 1})

    file_bm=[file_bm_depth1, file_bm_depth2]
    print('for depth = '+ str(depth) +' m:')
    print(file_bm[d])
    ds_zshelf.to_netcdf(file_bm[d], unlimited_dims=['time_counter'])
    d += 1