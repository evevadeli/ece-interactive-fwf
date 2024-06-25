# Initialise freshwater forcing experiment by creating initial freshwater forcing file and depth distribution files
# 2023-06: Eveline van der Linden (KNMI) linden@knmi.nl

## Import modules
import os
import xarray as xr
import pandas as pd
import numpy as np
import sys

import ThetaoSectors as TS
import DataVariablesParameters as dvp
from config import running_mean_period

print('Number of arguments:', len(sys.argv), 'arguments.')
print('Argument List:', str(sys.argv))

## Year of run + total experiment
year = int(sys.argv[3])
year_min = int(sys.argv[1])
year_max = int(sys.argv[2])
leg_number = str(sys.argv[4]).zfill(3) # add leading zeros
exp_name = str(sys.argv[5])
ini_data_dir = str(sys.argv[6])
run_dir = str(sys.argv[7])

########################## File definition #########################
## Paths
path_input = f'{ini_data_dir}/nemo/fwf/interactive/input/'
path_output = f'{run_dir}/fwf/interactive/forcing_files/' #Create other path (scratch)

## Input data
file_area = f'{path_input}/areacello_Ofx_EC-Earth3_historical_r1i1p1f1_gn.nc'
file_larmip_ocean_mask = f'{ini_data_dir}/masks/LARMIP_ocean_regions_ORCA1.nc'
file_basal_melt_mask = f'{path_input}/basal_melt_mask_ORCA1_ocean.nc'
file_calving_mask = f'{path_input}/calving_mask_ORCA1_ocean.nc'

file_thetao = f'{run_dir}/output/nemo/{leg_number}/{exp_name}_1m_{year}0101_{year}1231_grid_T.nc'
if not os.path.exists(file_thetao):
    file_thetao = f'{run_dir}/output/nemo/{leg_number}/{exp_name}_1m_{year}0101_{year}1231_opa_grid_T_3D.nc' #other output format

file_baseline_thetao = f'{path_output}/OceanSectorThetao_piControl.csv'

## Output data
## FWF for EC-Earth (freshwater forcing computed from year yyyy is applied in year yyyy+1)
#notused file_forcing = f'{path_output}/FWF_LRF_y{year_min}.nc'

# Constants
spy               = 3600*24*365   # [s yr^-1]
kg_per_Gt         = 1e12         # [kg] to [Gt]

## Intermediate output files
output_thetao =f'{path_output}/OceanSectorThetao_{exp_name}.csv'
output_thetao_RM = f'{path_output}/OceanSectorThetao_{running_mean_period}yRM_{exp_name}.csv'

##################### Sector mean thetao computation (part of analysis) ############################

## Open thetao dataset + rename dimensions (to be consistent with areacello file)
ds = xr.open_dataset(file_thetao,use_cftime=True)
ds = ds.rename({'y':'j','x':'i','nav_lon':'longitude','nav_lat':'latitude','olevel':'lev'})

## Compute time mean value over annual file 
ds_thetao_year = ds['thetao'].mean('time_counter')

# Read lev bnds
ds_lev_bnds = ds['olevel_bounds']

## Open areacello dataset
ds_area = xr.open_dataset(file_area)

## Sector names, consistent with linear response functions
sectors = ['eais','wedd','amun','ross','apen']

# Dictionary for relating larmip regions to numbers in netcdf file
sector_dict = {'eais': 1,
               'ross': 2,
               'amun': 3,
               'wedd': 4,
               'apen': 5}

## Create dataframe for mean ocean temperatures per sector
df_thetao_year = pd.DataFrame(columns=sectors, index=[year])
df_thetao_year.index.name = 'year'

# Open Larmip mask
ds_larmip_mask = xr.open_dataset(file_larmip_ocean_mask)
ds_larmip_mask = ds_larmip_mask.rename({'y':'j','x':'i','lon':'longitude','lat':'latitude'})

## Loop over oceanic sectors
for sector in sectors:
    # Select mask for specific ocean sector
    #mask_sector = dvp.sel_mask(ds_area,sector)
    mask_sector = (ds_larmip_mask.regions==sector_dict[sector]) #Based on nc file

    # Compute area weighted mean temperature
    print('Computing area weighted mean of thetao for ', sector, 'sector')           
    thetao_area_weighted_mean = TS.area_weighted_mean(ds_thetao_year,ds_area,mask_sector)

    depth_bnds_sector = dvp.sel_depth_bnds(sector) 

    # Compute layer weighted mean of area weighted mean --> volume weighted mean
    thetao_volume_weighted_mean = TS.lev_weighted_mean(thetao_area_weighted_mean,ds_lev_bnds,depth_bnds_sector)

    # Create dataframe from dataarray
    print('Fill dataframe for sector ', sector)
    df_thetao_year[sector] = [thetao_volume_weighted_mean.values]

## Export data 
print(f'##### Exporting data of year {year} to csv file ##############')
print(output_thetao)

if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_thetao):    
        os.remove(output_thetao)    

    df_thetao_year.to_csv(output_thetao)
elif year>year_min:
    # Append to existing file (if file exists)
    df_thetao_year.to_csv(output_thetao, mode='a', header=not os.path.exists(output_thetao))

ds_area.close()

## Read data from csv file 
df_thetao_all = pd.read_csv(output_thetao)
## Read baseline thetao
df_thetao_baseline = pd.read_csv(file_baseline_thetao,index_col=0)

# Compute thetao running mean
df_thetao_running_mean = TS.running_mean_backward(df_thetao_all, df_thetao_baseline, year, year_min, running_mean_period)

# Write output to file
if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_thetao_RM):    
        os.remove(output_thetao_RM)    

    df_thetao_running_mean.to_csv(output_thetao_RM)
elif year>year_min:
    df_thetao_running_mean.to_csv(output_thetao_RM, mode='a', header=not os.path.exists(output_thetao_RM))

