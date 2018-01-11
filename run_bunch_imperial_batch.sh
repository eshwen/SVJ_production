#!/bin/bash

if [ -z $1 ]; then
  echo "-----------------------------------------------------------------------------------------------------------------------------------------------
Usage: ./run_bunch_imperial_batch WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS NUMBER_OF_THREADS(to not execute cmsRun leave empty)
-----------------------------------------------------------------------------------------------------------------------------------------------"
  exit
fi

init_ind=4
num_ind=1
n_of_events=$2
n_of_threads=$4
n_of_seeds=$3

work_space=$(readlink -m $1)

for alpha_D in 0_1; do # In set_config.sh, alpha_D and r_inv are split by 2nd character. So 0_1 = 0.1
    for m_Z in 3000; do
	for r_inv in 0_3; do

	    for seed in  $(seq 1 1 $n_of_seeds); do
		seed=$(echo 3000+$seed | bc)

		$PWD/set_batch.sh $work_space $n_of_events $alpha_D $m_Z $r_inv $seed $n_of_threads
		if [ ! -d logs ]; then
		    mkdir logs
		fi
		if [ ! -z $n_of_threads ]; then
			qsub -N job_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed} -o logs/ -e logs/ -q hep.q -cwd -m ae $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
		fi
	    done
	done
    done
done
	       
   
exit
