# Compute Antarctic freshwater forcing anomalies from ocean subsurface temperature in 5 regions
# 2023-03: Eveline van der Linden (KNMI) linden@knmi.nl

## Import modules
import os
import xarray as xr
import pandas as pd
import numpy as np
import sys

import ThetaoSectors as TS
import BasalMelt as BM
import FreshWaterForcing as FWF
from config import gamma, ism, bm, running_mean_period, FWF_total_yearmin


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

# optional, set FWF_total_yearmin manually
if len(sys.argv) == 9:
    print('Reset FWF_total_yearmin from',FWF_total_yearmin,'==>',int(sys.argv[8]))
    FWF_total_yearmin = int(sys.argv[8])
else:
    # default: use value from config.py
    print('Use FWF_total_yearmin: ',FWF_total_yearmin)


# Constants
spy               = 3600*24*365   # [s yr^-1]
kg_per_Gt         = 1e12         # [kg] to [Gt]

########################## File definition #########################
## Paths
path_input = f'{ini_data_dir}/nemo/fwf/interactive/input/'
path_output = f'{run_dir}/fwf/interactive/forcing_files/'
#if year == year_min:
#    os.mkdir(path_output)
path_forcing_file = f'{run_dir}/fwf/interactive/forcing_files/' #Create other path (scratch)
path_lrfs = f'{ini_data_dir}/nemo/fwf/interactive/RFunctions/'

## Input data
## Output file from nemo: input file for freshwater forcing
file_thetao = f'{run_dir}/output/nemo/{leg_number}/{exp_name}_1m_{year}0101_{year}1231_grid_T.nc'
if not os.path.exists(file_thetao):
    file_thetao = f'{run_dir}/output/nemo/{leg_number}/{exp_name}_1m_{year}0101_{year}1231_opa_grid_T_3D.nc' #other output format

file_area = f'{path_input}/areacello_Ofx_EC-Earth3_historical_r1i1p1f1_gn.nc'

# check if theta_baselinefile exists in run_dir/fwf...
file_baseline_thetao = f'{path_output}/OceanSectorThetao_piControl.csv'
if not os.path.isfile(file_baseline_thetao):
    file_baseline_thetao = f'{path_input}/OceanSectorThetao_piControl.csv'
print('Use baseline_thetao from '+file_baseline_thetao)

file_basal_melt_mask = f'{path_input}/basal_melt_mask_ORCA1_ocean.nc'
file_calving_mask = f'{path_input}/calving_mask_ORCA1_ocean.nc'

## Output data
## FWF for EC-Earth (freshwater forcing computed from year yyyy is applied in year yyyy+1)
file_forcing = f'{path_forcing_file}/FWF_LRF_y{year+1}.nc'
file_bm_depth1 = f'{run_dir}/basal_melt_depth1.nc' #shallowest depth
file_bm_depth2 =f'{run_dir}/basal_melt_depth2.nc' # deepest depth

## Basal melt in year yyyy affects freshwater forcing for the next 200 yrs (length of linear response functions)
file_future_forcing = f'{path_output}/CumulativeFreshwaterForcingAnomaly_{exp_name}_Future.csv'

## Intermediate output files
output_thetao =f'{path_output}/OceanSectorThetao_{exp_name}.csv'
output_BM =f'{path_output}/BasalMeltAnomaly_{exp_name}.csv'
output_dFWF =f'{path_output}/FreshwaterForcingAnomaly_{exp_name}.csv'
output_FWF =f'{path_output}/TotalFreshwaterForcing_{exp_name}.csv'
output_thetao_RM = f'{path_output}/OceanSectorThetao_{running_mean_period}yRM_{exp_name}.csv'

##################### Sector mean thetao computation ############################

## Open thetao dataset + rename dimensions (to be consistent with areacello file)
ds = xr.open_dataset(file_thetao, use_cftime=True)
ds = ds.rename({'y':'j','x':'i','nav_lon':'longitude','nav_lat':'latitude','olevel':'lev'})

## Compute time mean value over annual file 
ds_thetao_year = ds['thetao'].mean('time_counter')

# Read lev bnds
ds_lev_bnds = ds['olevel_bounds']

## Open areacello dataset
ds_area = xr.open_dataset(file_area)

## Sector names, consistent with linear response functions
sectors = ['eais','wedd','amun','ross','apen']

## Create dataframe for mean ocean temperatures per sector
df_thetao_year = pd.DataFrame(columns=sectors, index=[year])
df_thetao_year.index.name = 'year'

## Loop over oceanic sectors
for sector in sectors:

    # Compute area weighted mean temperature
    print('Computing area weighted mean of thetao for ', sector, 'sector')           
    thetao_area_weighted_mean = TS.area_weighted_mean(ds_thetao_year,ds_area,sector)

    # Compute layer weighted mean of area weighted mean --> volume weighted mean
    thetao_volume_weighted_mean = TS.lev_weighted_mean(thetao_area_weighted_mean,ds_lev_bnds,sector)

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

## Read last running mean if file exists, otherwise use baseline
try:
    df_thetao_lastrm = pd.read_csv(f'{path_output}/OceanSectorThetao_lastRM.csv')
    print('Use lastRM from OceanSectorThetao_lastRM')
except FileNotFoundError:
    df_thetao_lastrm = df_thetao_baseline
    print('Use lastRM from OceanSectorThetao_piControl')

# Compute thetao running mean
df_thetao_running_mean = TS.running_mean_backward(df_thetao_all, df_thetao_lastrm, year, year_min, running_mean_period)

# Write output to file
if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_thetao_RM):    
        os.remove(output_thetao_RM)    

    df_thetao_running_mean.to_csv(output_thetao_RM)
elif year>year_min:
    df_thetao_running_mean.to_csv(output_thetao_RM, mode='a', header=not os.path.exists(output_thetao_RM))

#################### Basal Melt Computation ############################

print('Computing basal melt anomalies')
## Compute basal melt anomalies from thetao and gamma
baseyear=df_thetao_baseline.index[0]
df_dBM = BM.basal_melt_anomalies(df_thetao_baseline.loc[baseyear],df_thetao_running_mean.loc[year], gamma)
# Add index 'year' to dataframe
df_dBM.index=[year]
df_dBM.index.name = 'year'

print(f'##### Exporting data of year {year} to csv file ##############')
print(output_BM)

if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_BM):    
        os.remove(output_BM)    

    df_dBM.to_csv(output_BM)
elif year>year_min:
    # Append to existing file if it exists, otherwise create file
    df_dBM.to_csv(output_BM, mode='a', header=not os.path.exists(output_BM))


###################### Anomalous Freshwater Forcing Computation ####################

## Dictionary for finding response functions related to the ocean sectors
LRF_sector = {'eais': 'R1',
              'ross': 'R2',
              'amun': 'R3',
              'wedd': 'R4',
              'apen': 'R5'}

## Forward computation: compute total sea level contribution over full period
length = year_max+1-year_min #length of total experiment in years
length += 200 # add length of response in case you ever want continue the exp
t = year - year_min # time step (counting in years from the start of the experiment)

# Create empty dataframe for storing linear response functions
dfRF=pd.DataFrame(columns=[sectors],index=np.arange(200))

# Read linear response function
for sector in sectors:
    region =  LRF_sector[sector]
    # Read response function: unit Gt/m [(Gt yr-1)/(m -yr-1)]
    RF_TotalFW_file = f'{path_lrfs}/TotalFW/RF_{ism}_BM{bm}_{region}.dat'
    with open(RF_TotalFW_file) as f:
        RF_TotalFW = np.array([float(row) for row in f])
    dfRF[sector] =  RF_TotalFW

## Compute total freshwater forcing for the next year (dataframe with 5 values in Gt)
# Note: file_future_forcing will store the freshwater forcing for up to 200 years in the future
df_dFWF = FWF.freshwater_flux_anomaly_df(t,length,df_dBM,dfRF,file_future_forcing)
# Add index 'year' to dataframe
df_dFWF.index=[year]
df_dFWF.index.name = 'year'

print(f'##### Exporting freshwater forcing anomaly of year {year} to csv file ##############')
print(output_dFWF)

if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_dFWF):    
        os.remove(output_dFWF)   
    df_dFWF.to_csv(output_dFWF)
elif year>year_min:
    # Append to existing file if it exists, otherwise create file
    df_dFWF.to_csv(output_dFWF, mode='a', header=not os.path.exists(output_dFWF))


######################### Total freshwater forcing ##########################
# Read baseline freshwater forcing (computed from precipitation, evaporation and runoff) from file
#with open(file_baseline_fwf ) as f:
#    FWF_AIS_baseline_Gt = f.read()

# Total change in freshwater forcing: sum over 5 regions
sum_dFWF_Gt = df_dFWF.sum(axis=1)

# Add baseline FWF to sum of anomalies
df_total_FWF_Gt = sum_dFWF_Gt + FWF_total_yearmin
# Add index 'year' to dataframe
df_total_FWF_Gt.index=[year]
df_total_FWF_Gt.index.name = 'year'
print('Total freshwater forcing: ', df_total_FWF_Gt)

# Write total FWF to file
print(f'##### Exporting freshwater forcing of year {year} to csv file ##############')
print(output_FWF)

if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_FWF):    
        os.remove(output_FWF)    

    df_total_FWF_Gt.to_csv(output_FWF)
elif year>year_min:
    # Append to existing file if it exists
    df_total_FWF_Gt.to_csv(output_FWF, mode='a', header=not os.path.exists(output_FWF))


##################### Distribution over ocean grid ######################

##
# Read distribution mask from file
#with open(file_distribution_area) as f:
#    distribution_area = f.read()
#distribution_mask = xr.open_dataset(file_distribution_mask)
basal_melt_mask = xr.open_dataset(file_basal_melt_mask)
calving_mask = xr.open_dataset(file_calving_mask)


## Open areacello dataarray and compute area corresponding with  distribution mask
ds_area = xr.open_dataset(file_area)
#distribution_area = ds_area.areacello.where(distribution_mask.friver).sum('j').sum('i').values
#print('Freshwater distribution area: ', distribution_area, 'm^2')

basal_melt_area = ds_area.areacello.where(basal_melt_mask.basal_melt_mask).sum('j').sum('i').values
calving_area = ds_area.areacello.where(calving_mask.calving_mask).sum('j').sum('i').values
print('Basal melt area: ', basal_melt_area, 'm^2')
print('Calving area: ', calving_area, 'm^2')

ds_depth=xr.open_dataset(file_bm_depth2)-xr.open_dataset(file_bm_depth1)
basal_melt_volume = np.nansum(ds_area.areacello.where(basal_melt_mask.basal_melt_mask).values*ds_depth.bmdepth.values)
print('Basal melt volume: ', basal_melt_volume, 'm^3')

#The distribution of this total meltwater flux between basal melt and calving is fixed using the observed mass loss by Rignot et al. 2013 
df_FWF_calving = 0.45 * df_total_FWF_Gt
df_FWF_basal_melt = 0.55 * df_total_FWF_Gt

# Convert Gt yr-1 to kg m-2 s-1
#FWF_flux = df_total_FWF_Gt.values*kg_per_Gt/spy/float(distribution_area)
basal_melt_flux = df_FWF_basal_melt.values*kg_per_Gt/spy/float(basal_melt_area)
calving_flux = df_FWF_calving.values*kg_per_Gt/spy/float(calving_area)

# Apply flux to masked region
#FWF_distribution = FWF_flux*distribution_mask
#FWF_distribution = FWF_distribution.rename({'friver':'freshwater_flux'})
basal_melt_distribution = basal_melt_flux*basal_melt_mask
calving_distribution = calving_flux*calving_mask

# BM per volume (in kg m-3 s-1)
# multiply with depth for each gridpoint, overwrite basal_melt_distribution
basal_melt_flux_per_volume = df_FWF_basal_melt.values*kg_per_Gt/spy/float(basal_melt_volume)
basal_melt_distribution = basal_melt_flux_per_volume*ds_depth.bmdepth.values*basal_melt_mask

#The distribution of this total meltwater flux between basal melt and calving is fixed using the observed mass loss by Rignot et al. 2013 
#FWF_calving = 0.45 * FWF_distribution
#FWF_basal_melt = 0.55 * FWF_distribution

##################### Create forcing file for NEMO ######################

# Rename variables for nemo
#FWF_calving = FWF_calving.rename({'freshwater_flux':'socalving_f'})
#FWF_basal_melt = FWF_basal_melt.rename({'freshwater_flux':'sorunoff_f'})

FWF_basal_melt = basal_melt_distribution.rename({'basal_melt_mask':'sorunoff_f'})
FWF_calving = calving_distribution.rename({'calving_mask':'socalving_f'})

t_new = xr.cftime_range(str(year+1),periods=12,freq='MS')

# Add time dimension to dataarrays (12 months for the next year); flux is equal throughout the year
FWF_basal_melt = FWF_basal_melt.sorunoff_f.expand_dims({'time_counter': t_new.values})
FWF_basal_melt.attrs = {'long_name':'runoff flux', 'units':'kg/m^2/s'}
FWF_basal_melt = FWF_basal_melt.fillna(0) #set nans to zeros

FWF_calving = FWF_calving.socalving_f.expand_dims({'time_counter': t_new.values})
FWF_calving.attrs = {'long_name':'calving flux', 'units':'kg/m^2/s'}
FWF_calving = FWF_calving.fillna(0) #set nans to zeros

# Merge dataarrays in one dataset
ds_FWF = xr.merge([FWF_basal_melt, FWF_calving])
ds_FWF = ds_FWF.assign_coords({'time_counter': t_new.values})
#ds_FWF = ds_FWF.rename({'y':'j','x':'i','nav_lon':'longitude','nav_lat':'latitude'})

# Write to file  (to be read in by EC-Earth in the next year)
if os.path.isfile(file_forcing):    
    os.remove(file_forcing)    

ds_FWF.to_netcdf(file_forcing, unlimited_dims=['time_counter'])

# Create zshelf files based on horizontal basal melt distribution for basal melt distribution over depth
#if year==year_min:
#    d = 0
#    for depth in [bm_dep1, bm_dep2]:
#        # Find oceanic layers that sit fully within the depth bounds
#        if d == 0:
#            lev_ind = TS.nearest_above(ds_lev_bnds[:,0],depth) #above = deeper than
#            depth_nemo = ds_lev_bnds[lev_ind,0].values
#            print('Upper bound of ocean layer used for basal melt distribution: ' , depth_nemo, ' m')
#        elif d == 1:
#            lev_ind= TS.nearest_below(ds_lev_bnds[:,1],depth) #below = shallower than
#            depth_nemo = ds_lev_bnds[lev_ind,1].values
#            print('Lower bound of ocean layer used for basal melt distribution: ' , depth_nemo, ' m')
#
#        print('Creating zshelf ncfile')
#        ds_bm_mask = xr.open_dataarray(file_basal_melt_mask)

#        ds_zshelf = ds_bm_mask.where(ds_bm_mask > 0)
#        ds_zshelf.name = 'bmdepth'
#        ds_zshelf = ds_zshelf.fillna(0)
#        df_zshelf = ds_zshelf.values
#        df_zshelf[df_zshelf>0] = depth_nemo
#        ds_zshelf.attrs = {'long_name':'basal melt depth', 'units':'m'}
#        ds_zshelf = ds_zshelf.expand_dims({'time_counter': 1})

#        file_bm=[file_bm_depth1, file_bm_depth2]
#        print('for depth = '+ str(depth) +' m:')
#        print(file_bm[d])
#        ds_zshelf.to_netcdf(file_bm[d], unlimited_dims=['time_counter'])
#        d += 1

print("##### FINISHED FRESHWATER FORCING COMPUTATION")

