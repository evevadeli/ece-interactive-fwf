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
from config import gamma, ism, bm, fwf_distribution, running_mean_period, FWF_total_yearmin


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

file_basal_melt_mask = f'{path_input}/basal_melt_mask_LARMIP_ORCA1.nc'
file_calving_mask = f'{path_input}/calving_mask_LARMIP_ORCA1.nc'

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

##################### Basal melt and calving distribution##################################
## Sector names, consistent with linear response functions
sectors = ['eais','wedd','amun','ross','apen']

# Basal melt sensitivities for each sector - LADDIE-derived
dict_melt_sensitivity_laddie = {'eais': 1.01,
                                'wedd': 1.07,
                                'amun': 0.51,
                                'ross': 0.32,
                                'apen': 0.21}

# Basal melt and calving contribution per sector (Rignot 2013)
bm_calv_distribution = pd.DataFrame(columns=['calv','bm', 'sum'],index=sectors)
bm_calv_distribution.loc['eais'] = [15.5, 15.5, 31]
bm_calv_distribution.loc['ross'] = [6, 3, 9]
bm_calv_distribution.loc['amun'] = [9, 23, 32]
bm_calv_distribution.loc['wedd'] = [12, 7, 19] 
bm_calv_distribution.loc['apen'] = [2.5, 6.5, 9]
bm_calv_distribution.loc['sum'] = [45, 55, 100]

# Calving distribution from source (row) to sink (column) per sector (Rignot 2013)
source_sink_calv_distribution = pd.DataFrame(0,columns=sectors,index=sectors)
# Source amun
#df.loc[row_indexer, "col"] = values
source_sink_calv_distribution.loc['amun','amun'] = 30
source_sink_calv_distribution.loc['amun','ross'] = 30
source_sink_calv_distribution.loc['amun','eais'] = 20
source_sink_calv_distribution.loc['amun','wedd'] = 20


#Source ross
source_sink_calv_distribution.loc['ross','ross'] = 30
source_sink_calv_distribution.loc['ross','eais'] = 20
source_sink_calv_distribution.loc['ross','wedd'] = 50

#Source eais
source_sink_calv_distribution.loc['eais','eais'] = 40
source_sink_calv_distribution.loc['eais','wedd'] = 60

#Source wedd
source_sink_calv_distribution.loc['wedd','wedd'] = 100

#Source apen
source_sink_calv_distribution.loc['apen','apen'] = 100



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
#Create dataframe with basal melt sensitivities
df_melt_sensitivity=pd.DataFrame(data=dict_melt_sensitivity_laddie,index=[year])

baseyear=df_thetao_baseline.index[0]
df_dBM = BM.basal_melt_anomalies(df_thetao_baseline.loc[baseyear],df_thetao_running_mean.loc[year], df_melt_sensitivity)
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
print(dfRF)

## Compute total freshwater forcing for the next year (dataframe with 5 values in Gt)
# Note: file_future_forcing will store the freshwater forcing for up to 200 years in the future
df_dFWF = FWF.freshwater_flux_anomaly_df(t,length,df_dBM,dfRF,file_future_forcing)
# Add sum to dataframe
df_dFWF['sum'] = df_dFWF.sum(axis=1)

# Add index 'year' to dataframe
df_dFWF.index=[year]
df_dFWF.index.name = 'year'
print(df_dFWF)

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
#Distribute baseline according to observations df_FWF_baseline !!!! Change to picontrol PminE per region
df_FWF_baseline =  pd.DataFrame(columns=sectors,index=['picontrol'])
df_FWF_baseline['sum'] = [FWF_total_yearmin]
print('Baseline freshwater forcing: ', df_FWF_baseline['sum'])

for sector in sectors:
    df_FWF_baseline[sector] = bm_calv_distribution.loc[sector]['sum']/100*df_FWF_baseline['sum']
print(df_FWF_baseline)
# Total change in freshwater forcing: sum over 5 regions
#df_FWF_baseline['sum'] = df_dFWF.sum(axis=1)

# Add baseline FWF to sum of anomalies
# Compute total FWF per region
df_FWF_total = pd.DataFrame(columns=sectors+['sum'])
df_FWF_total.loc[year] = df_dFWF.loc[year]+df_FWF_baseline.loc['picontrol']
df_FWF_total.index.name = 'year'
print('Total freshwater forcing: ', df_FWF_total['sum'])

# Write total FWF to file
print(f'##### Exporting freshwater forcing of year {year} to csv file ##############')
print(output_FWF)

if year==year_min:
    # Create output file for the first year
    if os.path.isfile(output_FWF):    
        os.remove(output_FWF)    

    df_FWF_total.to_csv(output_FWF)
elif year>year_min:
    # Append to existing file if it exists
    df_FWF_total.to_csv(output_FWF, mode='a', header=not os.path.exists(output_FWF))


##################### Distribution over ocean grid ######################

# Dictionary for relating larmip regions to numbers in netcdf file
sector_dict = {'eais': 1,
          'wedd': 2,
          'amun': 3,
          'ross': 4,
          'apen': 5}
##
# Read distribution mask from file
#with open(file_distribution_area) as f:
#    distribution_area = f.read()
#distribution_mask = xr.open_dataset(file_distribution_mask)
basal_melt_mask = xr.open_dataset(file_basal_melt_mask)
calving_mask = xr.open_dataset(file_calving_mask)

calving_mask = calving_mask.rename({'lon':'longitude','lat':'latitude','y':'j','x':'i'})
basal_melt_mask = basal_melt_mask.rename({'lon':'longitude','lat':'latitude','y':'j','x':'i'})


## Open areacello and depth dataarray and compute area and volume corresponding with distribution masks
ds_area = xr.open_dataset(file_area)
ds_depth=xr.open_dataset(file_bm_depth2)-xr.open_dataset(file_bm_depth1)

# Compute area for calving flux and volume for basal melt flux
df_fwf_geom = pd.DataFrame(index=sectors+['sum'],columns=['calving area','basal melt area','basal melt volume'])

for sector in sectors:
    df_fwf_geom.loc[sector,'calving area'] = ds_area.areacello.where(calving_mask.calving_mask==sector_dict[sector]).sum('j').sum('i').values
    df_fwf_geom.loc[sector,'basal melt area'] = ds_area.areacello.where(basal_melt_mask.basal_melt_mask==sector_dict[sector]).sum('j').sum('i').values
    df_fwf_geom.loc[sector,'basal melt volume'] = np.nansum(ds_area.areacello.where(basal_melt_mask.basal_melt_mask==sector_dict[sector]).values*ds_depth.bmdepth.values)

df_fwf_geom.loc['sum','calving area'] = ds_area.areacello.where(calving_mask.calving_mask>0).sum('j').sum('i').values
df_fwf_geom.loc['sum','basal melt area'] = ds_area.areacello.where(basal_melt_mask.basal_melt_mask>0).sum('j').sum('i').values
## volume: multiply with depth for each gridpoint
df_fwf_geom.loc['sum','basal melt volume'] = np.nansum(ds_area.areacello.where(basal_melt_mask.basal_melt_mask>0).values*ds_depth.bmdepth.values) 
print('df_fwf_geom', df_fwf_geom)

#The distribution of this total meltwater flux between basal melt and calving is fixed using the observed mass loss by Rignot et al. 2013
df_FWF_calving_source = pd.DataFrame(columns=sectors,index=[year]) #source!
df_FWF_calving = pd.DataFrame(columns=sectors,index=[year]) #sink!
df_FWF_basal_melt = pd.DataFrame(columns=sectors,index=[year]) #source==sink

for sector in (sectors+['sum']):
    df_FWF_calving_source[sector] = bm_calv_distribution.loc[sector,'calv']/bm_calv_distribution.loc[sector,'sum']*df_FWF_total.loc[year,sector]
    df_FWF_basal_melt[sector] = bm_calv_distribution.loc[sector,'bm']/bm_calv_distribution.loc[sector,'sum']*df_FWF_total.loc[year,sector]

for sector in sectors:
    df_FWF_calving[sector]=(source_sink_calv_distribution[sector]/100*df_FWF_calving_source[sectors]).sum(axis=1)
df_FWF_calving['sum']=df_FWF_calving_source['sum']

# Compute fwf fluxes
# Calving flux per area: convert Gt yr-1 to kg m-2 s-1 
df_calving_flux = df_FWF_calving*kg_per_Gt/spy/df_fwf_geom['calving area']
# BM per volume (in kg m-3 s-1)
df_basal_melt_flux_per_volume = df_FWF_basal_melt*kg_per_Gt/spy/df_fwf_geom['basal melt volume']

# Apply flux to masked region
# Distribution options
if fwf_distribution=='uniform':
    da_basal_melt_distribution = float(df_basal_melt_flux_per_volume.loc[year,'sum'])*ds_depth.bmdepth.values*(basal_melt_mask.basal_melt_mask>0)
    da_calving_distribution = float(df_calving_flux.loc[year,'sum'])*(calving_mask.calving_mask>0)
    #Convert dataarray to dataset
    ds_basal_melt_distribution  = da_basal_melt_distribution.to_dataset()
    ds_calving_distribution = da_calving_distribution.to_dataset()
    # Rename variables for nemo
    FWF_basal_melt = ds_basal_melt_distribution.rename({'basal_melt_mask':'sorunoff_f'})
    FWF_calving = ds_calving_distribution.rename({'calving_mask':'socalving_f'})
elif fwf_distribution=='larmip':
    ds_basal_melt_distribution = xr.full_like(basal_melt_mask,np.nan)
    ds_calving_distribution = xr.full_like(calving_mask,np.nan)
    # Create dataset with calving distribution for each region
    for sector in sectors:
        ds_calving_distribution[sector] = float(df_calving_flux.loc[year,sector])*calving_mask.calving_mask.where(calving_mask.calving_mask==sector_dict[sector])
        ds_basal_melt_distribution[sector] = float(df_basal_melt_flux_per_volume.loc[year,sector])*ds_depth.bmdepth.values*basal_melt_mask.basal_melt_mask.where(basal_melt_mask.basal_melt_mask==sector_dict[sector])
    ds_calving_distribution = ds_calving_distribution.drop_vars('calving_mask')
    ds_basal_melt_distribution = ds_basal_melt_distribution.drop_vars('basal_melt_mask')
    # Replace Nans with zeros before taking the sum of all regions
    ds_basal_melt_distribution = ds_basal_melt_distribution.where(ds_basal_melt_distribution>0,0)
    ds_calving_distribution = ds_calving_distribution.where(ds_calving_distribution>0,0)
    # Add all sectors (sum)
    ds_basal_melt_distribution['sum'] = ds_basal_melt_distribution[sectors].to_array().sum("variable")
    ds_calving_distribution['sum'] = ds_calving_distribution[sectors].to_array().sum("variable")
    # Rename variables for nemo   
    FWF_basal_melt = ds_basal_melt_distribution.drop_vars(sectors).rename({'sum':'sorunoff_f'})
    FWF_calving = ds_calving_distribution.drop_vars(sectors).rename({'sum':'socalving_f'})

##################### Create forcing file for NEMO ######################

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

# Write to file  (to be read in by EC-Earth in the next year)
if os.path.isfile(file_forcing):    
    os.remove(file_forcing)    

ds_FWF.to_netcdf(file_forcing, unlimited_dims=['time_counter'])



print("##### FINISHED FRESHWATER FORCING COMPUTATION")

