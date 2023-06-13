# The Antarctic ice melt emulator
Eveline van der Linden, 2023

## NEMO files (compile nemo after these changes)
path: sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/MY_SRC/
- sbc_oce.F90
- sbccpl.F90
- sbcfwf.F90
- sbcmod.F90
- sbcrnf.F90

## EC-Earth scripts
path: runtimes/classic/

- ece-esm.sh.tmpl
- config-run.xml
- wrapper-hpc2020.sh
- fwfwrapper.sh                 - calls python scripts from ece-esm.sh.tmpl             -
- /ctrl/namelist.nemo-ORCA1L75-coupled.cfg.sh 

### Python scripts
path: fwf/interactive/scripts

- InitialiseFreshwaterForcing.py - run before starting interactive simulation to create initial conditions from config.py
- ThetaoDrivenFreshwaterForcing.py - main script called by fwfwrapper.sh, calls functions from other scripts
- ThetaoSectors.py
- BasalMelt.py
- FreshWaterForcing.py
- DataVariablesParameters.py
- constants.py
- config.py - configuration file

### Input files
path: fwf/interactive/input

- areacello_Ofx_EC-Earth3_historical_r1i1p1f1_gn.nc
- basal_melt_mask_ORCA1_ocean.nc
- calving_mask_ORCA1_ocean.nc
- basal_melt_depth1.nc - created by InitialiseFreshwaterForcing.py
- basal_melt_depth2.nc - created by InitialiseFreshwaterForcing.py
- FWF_LRF_y1850.nc - created by InitialiseFreshwaterForcing.py
- OceanSectorThetao_piControl.csv - mean ocean temperatures at depth of ice shelf base for piControl period

path: fwf/
- runoff_maps_fwf_AIS.nc    - new file for runoff-mapper, excludes Antarctica

### Monitoring/output files
path: fwf/interactive/forcing_files

- FWF_LRF_y????.nc - annual file to be read in by nemo
- OceanSectorThetao_{exp}_{year_min}_{year_max}.csv
- OceanSectorThetao_30yRM_{exp}_{year_min}_{year_max}.csv - 30 yr running mean
- BasalMeltAnomaly_{exp}_{year_min}_{year_max}.csv
- CumulativeFreshwaterForcingAnomaly_{exp}_{year_min}_{year_max}.csv
- TotalFreshwaterForcing_{exp}_{year_min}_{year_max}.csv - sum of anomalies + baseline


