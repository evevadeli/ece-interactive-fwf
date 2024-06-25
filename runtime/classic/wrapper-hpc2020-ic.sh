#!/usr/bin/env bash

set -e

#################################################################################
# This wrapper simplifies run submission on AA at ECMWF. It:                    #
#    - reads the config-run.xml                                                 #
#    - create a submit script with the correct directives                       #
#    - submit it                                                                #
#                                                                               #
# HOW-TO :                                                                      #
#    0) copy this file in your rundir/classic                                   #
#    1) set here your account                                                   #
#    2) set here the models configuration with the MYCONFIG variable,           #
#    3) configure your run with the config-run.xml,                             #
#    4) run this script                                                         #
#                                                                               #
# Log of submit script is in "./out" dir (created if needed)                    #
#                                                                               #
# REQUIREMENTS: ec-conf3 is in your $PATH. It is available in the ec-earth      #
#               source code, in sources/util/ec-conf dir.                       #
#################################################################################

#ACCOUNT=spnltune
#ACCOUNT=spnldrij
#MYCONFIG="ifs amip tm5:chem,o3,ch4,aero oasis"
MYCONFIG="ifs nemo:start_from_restart lim3 rnfmapper xios:detached oasis save_ic:end_leg"

# -- Possible configurations -- (everything possible except nemo standalone)
#
#  MYCONFIG="ifs amip "
#  MYCONFIG="ifs amip lpjg:fdbck"                                              
#  MYCONFIG="ifs amip tm5:chem,o3,ch4,aero"                                    
#  MYCONFIG="ifs amip tm5:co2"                                                 
#  MYCONFIG="ifs amip lpjg:fdbck tm5:co2"
#
#  MYCONFIG="ifs nemo lim3 rnfmapper xios:detached oasis"                                 # AOGCM
#  MYCONFIG="ifs nemo lim3 rnfmapper xios:detached oasis lpjg:fdbck"                      # EC-Earth3-Veg
#  MYCONFIG="ifs nemo pisces lim3 rnfmapper xios:detached oasis lpjg:fdbck"               # EC-Earth3-CC c-driven
#  MYCONFIG="ifs nemo pisces lim3 rnfmapper xios:detached oasis lpjg:fdbck tm5:co2,co2fb" # EC-Earth3-CC e-driven
#  MYCONFIG="ifs nemo lim3 rnfmapper xios:detached oasis tm5:chem,o3fb,ch4fb,aerfb"       # EC-Earth3-AerChem

cnfgxml=config-run.xml
platform=ecmwf-hpc2020-intel-openmpi

# Add ec-conf directory to PATH (temporarily)
export "PATH=/perm/nk0j/ecearth3-cmip6/sources/util/ec-conf:$PATH"

#Choose freshwater forcing option to link nemo restart files
fwf=4

#######################################################################
#          YOU SHOULD NOT HAVE TO CHANGE ANYTHING HEREAFTER           #
#######################################################################

source ./librunscript.sh
config=$MYCONFIG
mkdir -p out | true

# ----- parse and get info from xml
ec-conf3 -p ${platform} ${cnfgxml}

expn=$(ec-conf3 -p ${platform} -r "MODEL:GENERAL:EXP_NAME" ${cnfgxml} )
nifs=$(ec-conf3 -p ${platform} -r "MODEL:IFS:NUMPROC"      ${cnfgxml} )     
nnem=$(ec-conf3 -p ${platform} -r "MODEL:NEM:NUMPROC"      ${cnfgxml} )     
nxio=$(ec-conf3 -p ${platform} -r "MODEL:XIO:NUMPROC"      ${cnfgxml} )     
ntmx=$(ec-conf3 -p ${platform} -r "MODEL:TM5:NUMPROC_X"    ${cnfgxml} )   
ntmy=$(ec-conf3 -p ${platform} -r "MODEL:TM5:NUMPROC_Y"    ${cnfgxml} )   
nlpj=$(ec-conf3 -p ${platform} -r "MODEL:LPJG:NUMPROC"     ${cnfgxml} )    
ntm5=$(( ntmx*ntmy ))
adate=$(ec-conf3 -p ${platform} -r "MODEL:GENERAL:RUN_START_DATE" ${cnfgxml} )
edate=$(ec-conf3 -p ${platform} -r "MODEL:GENERAL:RUN_END_DATE"   ${cnfgxml} )
run_start_date=${adate}

srcdir=$(ec-conf3 -p ${platform} -r "PLT:ACTIVE:ECEARTH_SRC_DIR" ${cnfgxml} )

use_machinefile=$(ec-conf3 -p ${platform} -r "PLT:ACTIVE:USE_MACHINEFILE" ${cnfgxml} )
ppn=$(ec-conf3 -p ${platform} -r "PLT:ACTIVE:PROC_PER_NODE" ${cnfgxml} )

if has_config nemo:elpin
then
    ldlibpath=$(ec-conf3 -p ${platform} -r "PLT:ACTIVE:ADD_TO_LD_LIBRARY_PATH" ${cnfgxml} )
    if [ -n $ldlibpath ]
    then
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}$ldlibpath
    fi

    nem_grid=$(ec-conf3 -p ${platform} -r "MODEL:NEM:GRID" ${cnfgxml})
    ini_data_dir=$(ec-conf3 -p ${platform} -r "PLT:ACTIVE:INI_DATA_DIR" ${cnfgxml} )

    bathyfile=${ini_data_dir}/nemo/initial/${nem_grid}/bathy_meter.nc
    elpin=$(eval echo ${srcdir}/util/ELPiN/ELPiNv2.cmd)
    nem_res_hor=$(echo ${nem_grid} | sed 's:ORCA\([0-9]\+\)L[0-9]\+:\1:')
    jpns=($(${elpin} ${bathyfile} ${nnem}))
    onnem=$nnem
    nnem=${jpns[0]}
    echo; echo " Using ELPiN: switched from $onnem to $nnem processes for NEMO"
fi

ntot=0
mess="\nSubmit:"
has_config ifs      && mess=$mess" ifs(${nifs})"     && ntot=$(( ntot + nifs )) 
has_config nemo     && mess=$mess" + nemo(${nnem})"  && ntot=$(( ntot + nnem ))
has_config xios     && mess=$mess" + xios(${nxio})"  && ntot=$(( ntot + nxio ))
has_config ifs nemo && mess=$mess" + rnfmapper(1)"   && ntot=$(( ntot + 1    ))
has_config tm5      && mess=$mess" + tm5(${ntm5})"   && ntot=$(( ntot + ntm5 ))
has_config lpjg     && mess=$mess" + lpjg(${nlpj})"  && ntot=$(( ntot + nlpj ))
has_config amip     && mess=$mess" + amip(1)"        && ntot=$(( ntot + 1    ))
printf "$mess, exp=${expn} [model: ${srcdir}]\n"
printf "  from ${run_start_date} to $(eval echo ${edate})\n\n"

# ----- SLURM directives
ntasks=${ntot}

if $use_machinefile             # !!! DOES NO ACCOUNT FOR MINPPN YET
then
    echo "using a hostfile:"
    source ./ecconf.cfg
    machinefile_config
    nnodes=0
    nothers=0

    nrnf=1
    namip=1
    nlpjg=nlpj

    threes="nemo rnfmapper xios"
    for fcomp in ifs amip lpjg tm5 nemo rnfmapper xios
    do
        if has_config $fcomp
        then
            [[ $threes =~ $fcomp ]] && comp=${fcomp:0:3} || comp=$fcomp
            exclu="${comp}_exc"
            maxppn="${comp}_maxppn"
            effppn=${!maxppn:-$ppn}
            ncomp=n$comp
            if ${!exclu:-false} ; then
                nn=$((ncomp/effppn)) ; ((ncomp%effppn)) && ((nn+=1))
                ((nnodes+=nn))
                xcomp+=" $fcomp"
            else
                ((nothers+=ncomp))
                scomp+=" $fcomp"
            fi
        fi
    done

    if (( nothers ))
    then
        nn=$((nothers/ppn)) ; ((nothers%ppn)) && ((nn+=1))
    else
        nn=0
    fi

    echo "  nb exclusive nodes: $nnodes (comp:$xcomp)"
    echo "  nb of shared nodes: $nn (comp:$scomp)"
    (( nnodes+=nn ))
    echo "  total nb of nodes: $nnodes"; echo
fi

if (( ntasks > 64 )) ; then qos=np; else qos=nf; fi

# ----- Write submit and run scripts

sed "s|^config=.*|config=\"${MYCONFIG}\"|" <ece-esm.sh >ece-${expn}.sh
chmod 744 ./ece-${expn}.sh

# ----- Specify links to restart files (member-01 cmip6 ensemble) ---------
if  [[ $fwf -eq 4 || $fwf -eq 5 ]] ; then
    echo "changing IFS climatology files"
    #rst_ic_dir="/ec/res4/hpcperm/nm6/ece3data/prev_exp/t264/member-01"
    rst_ic_dir="/ec/res4/hpcperm/nk0j/restarts-ecearth3/fwf/fwf1/101"

    echo "changing links to IFS IC files"
    icma="\${ini_data_dir}/ifs/\${ifs_grid}/\${leg_start_date_yyyymmdd}/ICMGGECE3INIUA"
    icms="\${ini_data_dir}/ifs/\${ifs_grid}/\${leg_start_date_yyyymmdd}/ICMSHECE3INIT"
    icmt="\${ini_data_dir}/ifs/\${ifs_grid}/\${leg_start_date_yyyymmdd}/ICMGGECE3INIT"
    sed -i "s|${icma}|${rst_ic_dir}/ICMGG????INIUA|" ece-${expn}.sh
    sed -i "s|${icms}|${rst_ic_dir}/ICMSH????INIT|"  ece-${expn}.sh
    sed -i "s|${icmt}|${rst_ic_dir}/ICMGG????INIT|"  ece-${expn}.sh

    echo "added code fix the dates for the IC files"
    line="add[[:space:]]bare_soil_albedo"
    fixdates="\\
        # change IC file date to 1850-01-01\n\
        # (this is added in wrapper-hpc2020-fwf.sh)\n\
        echo 'setting grib date for IFS IC files'\n\
        mv ICMGG\${exp_name}INIUA ICMGG\${exp_name}INIUA_\n\
        mv ICMSH\${exp_name}INIT  ICMSH\${exp_name}INIT_ \n\
        mv ICMGG\${exp_name}INIT  ICMGG\${exp_name}INIT_ \n\
        \${grib_set} -s dataDate=18500101 ICMGG\${exp_name}INIUA_ ICMGG\${exp_name}INIUA\n\
        \${grib_set} -s dataDate=18500101 ICMSH\${exp_name}INIT_  ICMSH\${exp_name}INIT \n\
        \${grib_set} -s dataDate=18500101 ICMGG\${exp_name}INIT_  ICMGG\${exp_name}INIT \n"
    sed -i "/${line}/i ${fixdates}" ece-${expn}.sh

    echo "changing links to NEMO, LIM restart files"
    nrst="\${nem_restart_file_path}/restart"
    sed -i "s|${nrst}|${rst_ic_dir}/restart|" ece-${expn}.sh

    echo "changing links to OASIS restart files"
    orst="\${oas_grid_dir}/rst/\$f"
    sed -i "s|${orst}|${rst_ic_dir}/\$f|" ece-${expn}.sh
else
    echo "not changing IFS climatology files"
fi

tgt_script=ece-${expn}.jb

if $use_machinefile; then

    cat <<EOF > $tgt_script
#!/bin/bash

#SBATCH --nodes=${nnodes}
#SBATCH --qos=np
#SBATCH --output=out/${expn}.%j.out
#SBATCH --hint=nomultithread
##SBATCH --time=01:15:00

env | grep -i slurm

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
./ece-${expn}.sh

EOF
else
    cat <<EOF > $tgt_script
#!/bin/bash

#SBATCH --ntasks=${ntasks}
#SBATCH --qos=$qos
#SBATCH --output=out/${expn}.%j.out
#SBATCH --hint=nomultithread
##SBATCH --time=01:15:00

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
./ece-${expn}.sh

EOF
fi

[[ -n ${ACCOUNT=} ]] && \
    cmd="sbatch --account=$ACCOUNT" || cmd=sbatch

(( $# )) && $cmd -d afterok:$1 $tgt_script || $cmd $tgt_script


# -- DOs and DONTs

# Add memory for nf queue 
#SBATCH --mem=120G

#SBATCH --job-name=${expn}  # DO NOT USE TO BE ABLE TO RESUBMIT
#SBATCH --nodes=${nnodes}   # DO NOT USE IF USING nf QUEUE!!
