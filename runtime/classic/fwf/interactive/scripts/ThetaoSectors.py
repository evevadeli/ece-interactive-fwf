import numpy as np
import pandas as pd
import xarray as xr

import DataVariablesParameters as dvp

###############################################################################

def area_weighted_mean(ds_var,ds_area,sector):
    '''
    Compute area weighted mean oceanic temperature over specific oceanic sector
    
    Args:
        ds_var: dataarray with variable
        ds_area: dataarray with areacello
        sector: ocean sector name

    Returns:
        Area weighted mean oceanic temperature over specific oceanic sector
    '''

    # Select mask for specific ocean sector
    mask_sector = dvp.sel_mask(ds_area,sector)

    # Create area_weights     
    area_weights = ds_area.areacello

    # DataArrayWeighted with weights along dimensions: j, i
    area_weighted = ds_var.where(mask_sector).weighted(area_weights.fillna(0))
    
    lat = 'j' 
    lon = 'i' 
        
    # Compute area weighted mean
    area_weighted_mean = area_weighted.mean((lat,lon))
    return area_weighted_mean #2D field: time,levs

def lat_weighted_mean(ds_var,ds_lev_bnds,sector):
    '''
    Compute latitude weighted mean oceanic temperature over specific oceanic sector
    (For a rectangular grid the cosine of the latitude is proportional to the grid cell area.)
    
    Args:
        ds_var: dataarray with variable (area-weighted mean)
        ds_lev_bnds: dataarray with lev_bnds
        sector: ocean sectorn name
    
    Returns: 
        Latitude weighted mean oceanic temperature over specific oceanic sector
    
    '''
    # Select mask for specific ocean sector
    mask_sector = dvp.sel_mask(ds_var,sector)
 
    # Loop over dimensions to find latitude and longitude names
    for i in np.arange(len(ds_var.dims)):
        dim = ds_var.dims[i]
        
        if ((dim=='y') or (dim=='j') or (dim=='lat') or (dim=='latitude')):
            lat_name = ds_var.dims[i]
        elif ((dim=='x') or (dim=='i') or (dim=='lon') or (dim =='longitude')):
            lon_name = ds_var.dims[i]
        else:
            continue
    
    print('Latitude and longitude coordinates determined as', lat_name, ' and ', lon_name, 'respectively')
    
    latitudes = ds_lev_bnds[lat_name]
    lat_weights = np.cos(np.deg2rad(latitudes))
    lat_weighted = ds_var.where(mask_sector).weighted(lat_weights.fillna(0))
    
    #print('Computing latitude weighted mean')
    lat_weighted_mean = lat_weighted.mean((lat_name,lon_name))
    return lat_weighted_mean #2D field: time,levs  

def nearest_above(my_array, target):
    '''
    Find nearest value in array that is greater than target value and return corresponding index
    
    Args:
        my_array: dataarray with (depth) values
        target: target depth

    Returns:
        index of nearest value in array that is greater than target value 
    '''
    diff = my_array - target
    mask = np.ma.less_equal(diff, 0)
    # We need to mask the negative differences and zero
    # since we are looking for values above
    if np.all(mask):
        return None # returns None if target is greater than any value
    masked_diff = np.ma.masked_array(diff, mask)
    # Returns the index of the minimum value
    return masked_diff.argmin() 

def nearest_below(my_array, target):
    '''
    Find nearest value in array that is smaller than target value and return corresponding index
    
    Args:
        my_array: dataarray with (depth) values
        target: target depth

    Returns:
        index of nearest value in array that is smaller than target value 
    '''

    diff = target - my_array
    mask = np.ma.less_equal(diff, 0)
    # We need to mask the positive differences and zero
    # since we are looking for values below
    if np.all(mask):
        return None # returns None if target is smaller than any value
    masked_diff = np.ma.masked_array(diff, mask)
    # Returns the index of the minimum value
    return masked_diff.argmin()

def lev_weighted_mean(ds_var,ds_lev_bnds,sector):
    '''
    Compute volume weighted mean oceanic temperature over specific oceanic
    sector and specific depth layers (centered around ice shelf depth)
    
    Args:
        ds_var: dataarray with variable (optional: area-weighted mean)
        ds_lev_bnds: dataarray with lev_bnds
        sector: ocean sector name
    
    Returns: 
       Depth weighted mean oceanic temperature for specific sector
       If input is area-weighted, output is volume-weighted

    '''
   
    # Select depth bounds of sector
    depth_bnds_sector = dvp.sel_depth_bnds(sector)     
    depth_top = depth_bnds_sector[0]
    depth_bottom = depth_bnds_sector[1]
    #print(depth_bnds_sector)
    
    # Find oceanic layers covering the depth bounds and take a slice of these
    # layers
    lev_ind_bottom= nearest_above(ds_lev_bnds[:,1],depth_bottom)
    lev_ind_top = nearest_below(ds_lev_bnds[:,0],depth_top)
    levs_slice = ds_var.isel(lev=slice(lev_ind_top,lev_ind_bottom+1))
    
    # Create weights for each oceanic layer, correcting for layers that fall only partly within specified depth range 
    lev_bnds_sel = ds_lev_bnds.values[lev_ind_top:lev_ind_bottom+1]
    lev_bnds_sel[lev_bnds_sel > depth_bottom] = depth_bottom
    lev_bnds_sel[lev_bnds_sel < depth_top] = depth_top
    # Weight equals thickness of each layer
    levs_weights = lev_bnds_sel[:,1]-lev_bnds_sel[:,0] 
    # DataArray required to apply .weighted on DataArray
    levs_weights_DA = xr.DataArray(levs_weights,coords={'lev': levs_slice.lev},
             dims=['lev'])
    
    # Compute depth weighted mean of ocean slice
    levs_slice_weighted = levs_slice.weighted(levs_weights_DA)
    levs_weighted_mean = levs_slice_weighted.mean(("lev"))
    
    # Return layer-weighted ocean temperature
    return levs_weighted_mean

def running_mean_backward(df_thetao,df_thetao_baseline, year, year_min, period):
    '''
    Computing mean values over period, backward averaging. If length of ongoing 
    experiment is shorter than averaging period, baseline values will be used for
    averaging. Note that this function is required since the ocean temperature variability in the Ross
    sector is so high that is gives high freshwater perturbations to the model.

    Args:
        df_thetao: dataframe with mean temperatures for the ocean sectors in the current model year
        df_thetao_baseline: dataframe with mean temperatures for the ocean sectors in the baseline climate
        year: current year
        year_min: start year of experiment
        period: length of period (in years) over which running mean is computed

    Returns
        Mean value of variable averaged over period (backward averaging)
    '''
    # Compute number of years that experiment is running
    no_yrs = year+1-year_min
    if (no_yrs) >= period:
        print(f'Period longer or equal to {period} years')
        df_thetao_selection = df_thetao.loc[(df_thetao['year'] <= year) & (df_thetao['year'] > year-period)] 
        df_thetao_mean= pd.DataFrame(columns=df_thetao.columns).set_index('year')
        df_thetao_mean.loc[year] = df_thetao_selection.mean()
    elif (no_yrs) < period:
        print(f'Period shorter than {period} years')
        df_thetao_piControl = df_thetao_baseline
        df_thetao_piControl = df_thetao_piControl.loc[df_thetao_piControl.index.repeat(period-no_yrs)].reset_index(drop=True)        
        print(f'Substituting {period}-{no_yrs} years with piControl mean value')
        df_thetao_exp = df_thetao.loc[(df_thetao['year'] <= year) & (df_thetao['year'] > year-no_yrs)]
        # Combine experiment with piControl mean values
        df_thetao_combined = pd.concat([df_thetao_piControl,df_thetao_exp])#.reset_index(drop=True)
        #Create empty dataframe to store running mean values
        df_thetao_mean= pd.DataFrame(columns=df_thetao_exp.columns).set_index('year')
        # Add running mean to dataframe
        df_thetao_mean.loc[year]=df_thetao_combined.mean()   
    return df_thetao_mean
