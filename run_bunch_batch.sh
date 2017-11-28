#!/bin/bash

if [ -z $1 ]; then
  echo "-----------------------------------------------------------------------------------------------------------------------------------------------
Usage: ./run_bunch_batch WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS NUMBER_OF_THREADS(to not execute cmsRun leave empty)  MAIL_ADDRESS
-----------------------------------------------------------------------------------------------------------------------------------------------"
  exit
fi

init_ind=4
num_ind=1
n_of_events=$2
n_of_threads=$4
n_of_seeds=$3
MAIL=$5

work_space=$(readlink -m $1)

for alpha_D in 01; do
    for m_Z in 3000; do
	for r_inv in 03; do

	    for seed in  $(seq 1 1 $n_of_seeds); do
		seed=$(echo 3000+$seed | bc)

		$PWD/set_batch.sh $work_space $n_of_events $alpha_D $m_Z $r_inv $seed $n_of_threads
		mkdir logs
		if [ ! -d logs ]; then
		    mkdir logs
		fi
		if [ ! -z $n_of_threads ]; then
		    if [ -z $MAIL ]; then
			qsub -N job_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed} -o logs/ -e logs/ -q long.q -cwd $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
		    else
			qsub -N job_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed} -o logs/ -e logs/ -q long.q -cwd -m ae -M $MAIL $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
		    fi
		fi
	    done
	done
    done
done
	       
   
exit
