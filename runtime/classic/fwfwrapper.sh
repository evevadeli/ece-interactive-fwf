# Compute freshwater forcing for next year
module load python3

run_start_date=$1
run_end_date=$2
leg_start_date_yyyy=$3
leg_number=$4
exp_name=$5
start_dir=$6
run_dir=$7

echo $run_start_date
echo $run_end_date
echo $leg_start_date_yyyy
echo $leg_number
echo $exp_name
echo $start_dir
echo $run_dir

python3 ${start_dir}/fwf/interactive/scripts/ThetaoDrivenFreshwaterForcing.py ${run_start_date} ${run_end_date} ${leg_start_date_yyyy} ${leg_number} ${exp_name} ${start_dir} ${run_dir}


echo "Computed freshwater forcing for year $((${leg_start_date_yyyy}+1))"