import numpy as np
import pandas as pd

def freshwater_flux_anomaly_df(t, length, BM, RF, file_future_fwf):
    '''
    Compute freshwater flux from basal melt anomaly using linear response functions for the next 200 years.

    Args:
        t: current timestep (relative to start) [in years]
        length: total length of experiment (year_max+1 - year_min) [in years]
        BM: basal melt anomaly dataframe for X regions
        RF: linear response function dataframe for X regions
        file_future_fwf: path of fwf file storing fwf for future years
    Returns:
        Freshwater flux from basal melt anomaly for next time step (t+1)   
    '''

    if t==0:
        # Initialise dfFWF
        print('Initialise empty dataframe dfFWF')
        dfFWF = pd.DataFrame(0,index=range(length),columns=BM.columns) # creaty empty dataframe
    elif t > 0:
        dfFWF = pd.read_csv(file_future_fwf, index_col=0)
    # Contribution of basal melt in year to freshwater flux in future 200 years [year+1:year+201]
    #dFWFyear = RF.mul(BM.iloc[t])
    dFWFyear = RF.multiply(np.array(BM), axis='columns')
    # length of RF is 200 years (0:199) - only need years up to year_max
    lenRF = len(RF)
    # If there are less then 200 years left:
    if (length - t) < lenRF:
        #1902:2100
        dfFWF.iloc[t:length] = dfFWF.iloc[t:length].values + dFWFyear.iloc[:(length-t)].values
    #If there are more than 200 years left:
    elif (length - t) >= lenRF:
        #1850:1901
        dfFWF.iloc[t:t+lenRF] = dfFWF.iloc[t:t+lenRF].values + dFWFyear.iloc[:].values
    # Write dfFWF to file (updated each year) !! the years from year_min to year should have been processed before
    dfFWF.to_csv(file_future_fwf)
    print(f'Saved future forcing to {file_future_fwf}')
    # Compute differences: annual forcing
    dfFWF_diff = dfFWF.diff()
    return (pd.DataFrame(dfFWF_diff.iloc[t]).T)