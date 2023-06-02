import xarray as xr
import pandas as pd
import numpy as np
from constants import rho_sw, c_po, rho_i, L_i, T_f

def basal_melt_sensitivity(gamma):
    '''
    Compute quadratic basal melt anomalies for parameter gamma (array or single value)

    Args:
        gamma: calibration parameter

    Returns:
        Basal melt sensitivity
   '''
    # Compute coefficient for basal melt computation
    c_lin = (rho_sw*c_po)/(rho_i*L_i)
    c_quad = (c_lin)**2

    # Compute basal melt sensitivity for gamma value
    ms = gamma * 10**5 * c_quad

    return ms

def quadratic_basal_melt(thetao, gamma):
    '''
    Compute basal melt based on quadratic parameterization with 
    chosen gamma, ocean temperatures and freezing point temperatures
    
    Args:
        thetao: ocean temperatures
        gamma: calibration parameter

    Returns:   
        Basal melt
    '''
    melt_sensitivity = basal_melt_sensitivity(gamma)
    print(f'Using basal melt sensitivity: {melt_sensitivity} m yr-1 K-2')

    # Compute basal melt timeseries
    BasalMelt = (thetao - T_f) * (abs(thetao - T_f)) * melt_sensitivity  

    return BasalMelt

def basal_melt_anomalies(thetao_ref,thetao, gamma):
    ''' 
    Compute basal melt anomalies for ocean temperature thetao compared to baseline period
    
    Args:
        thetao_ref: ocean temperature used as baseline for anomaly computation
        thetao: ocean temperature
        gamma: calibration parameter

    
    Returns:
        Basal melt anomalies compared to baseline period
    '''

    # Quadratic melt baseline (negative if To < Tf)
    BasalMelt_base = quadratic_basal_melt(thetao_ref, gamma)

    # Compute basal melt for thetao
    BasalMelt = quadratic_basal_melt(thetao, gamma)
    
    # Compute basal melt anomalies
    deltaBasalMelt = BasalMelt - BasalMelt_base
    
    # Convert to dataframe
    df_deltaBasalMelt = deltaBasalMelt.to_frame().transpose()

    # return: basal melt anomalies compared to historical reference period
    return(df_deltaBasalMelt)