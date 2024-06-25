# The Antarctic ice melt emulator
Eveline van der Linden, 2023
* = changed in new simulation

## NEMO files (compile nemo after these changes)
path: sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/MY_SRC/
- sbc_oce.F90
- sbccpl.F90
- sbcfwf.F90*
- sbcmod.F90*
- sbcrnf.F90

## EC-Earth scripts
path: runtime/classic/

- ece-esm.sh.tmpl*               - l.1093-1136
- config-run.xml*                - set FWF to 4, set RUN_NUM_LEGS to 10
- wrapper-hpc2020.sh
- fwfwrapper.sh                  - calls python scripts from ece-esm.sh.tmpl             -
- /ctrl/namelist.nemo-ORCA1L75-coupled.cfg.sh* - add namelists for basal melt depths 

### Python scripts
path: fwf/interactive/scripts

- InitialiseFreshwaterForcing.py - run before starting interactive simulation to create initial conditions from config.py
- ThetaoDrivenFreshwaterForcing.py* - main script called by fwfwrapper.sh, calls functions from other scripts
- ThetaoSectors.py
- BasalMelt.py
- FreshWaterForcing.py
- DataVariablesParameters.py
- constants.py
- config.py* - configuration file

### Input files
path: fwf/interactive/input

- areacello_Ofx_EC-Earth3_historical_r1i1p1f1_gn.nc
- basal_melt_mask_ORCA1_ocean.nc*
- calving_mask_ORCA1_ocean.nc*
- OceanSectorThetao_piControl.csv - mean ocean temperatures at depth of ice shelf base for piControl period, create for new piControl
- basal_melt_depth1.nc* - created by InitialiseFreshwaterForcing.py
- basal_melt_depth2.nc* - created by InitialiseFreshwaterForcing.py
- FWF_LRF_y1850.nc* - created by InitialiseFreshwaterForcing.py, create for new piControl

Note: you need to copy the last 3 files from the input directory to the directory fwf/interactive/forcing_files/{exp}
OR run InitialiseFreshwaterForcing.py to create the input files in the forcing directory

path: fwf/
- runoff_maps_fwf_AIS.nc    - new file for runoff-mapper, excludes Antarctica

### Monitoring/output files
path: fwf/interactive/forcing_files

Output
- FWF_LRF_y????.nc - annual freshwater forcing file (basal melt + calving) to be read in by nemo

Monitoring
- OceanSectorThetao_{exp}_{year_min}_{year_max}.csv
- OceanSectorThetao_30yRM_{exp}_{year_min}_{year_max}.csv - 30 yr running mean
- BasalMeltAnomaly_{exp}_{year_min}_{year_max}.csv
- TotalFreshwaterForcing_{exp}_{year_min}_{year_max}.csv - sum of anomalies + baseline

Restarts
- CumulativeFreshwaterForcingAnomaly_{exp}_{year_min}_{year_max}.csv
- Create new OceanSectorThetao_piControl if new picontrol experiment
- Create new FWF_LRF_y1850.nc for new piControl experiment (new P-E averaged over AIS)


### Controlling output files
- file_def_nemo-lim3.xml
- file_def_nemo-opa.xml
- file_def_nemo-pisces.xml
- ppt0000000000
- pptdddddd0600


