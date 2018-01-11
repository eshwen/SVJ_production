#!/bin/bash

if [ -z $1 ]; then
  echo "----------------------------------------------------------------------------------------------------------------------------------------------------
Usage: ./run_bunch_batch.sh WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS  NUMBER_OF_THREADS(to not execute cmsRun leave empty)  EMAIL_ADDRESS
----------------------------------------------------------------------------------------------------------------------------------------------------"
  exit
fi

init_ind=4
num_ind=1
n_of_events=$2
n_of_threads=$4
n_of_seeds=$3
MAIL=$5

if [[ "$HOSTNAME" == *"ic.ac.uk" ]]; then
	queue=hep.q
elif [[ "$HOSTNAME" == *"uzh"* ]]; then
	queue=long.q
elif [[ "$HOSTNAME" == *"soolin"* ]]; then
	echo Running at Bristol.
else
	echo Sorry, only Zurich, Imperial College London and Bristol are supported at this time.
	exit
fi

work_space=$(readlink -m $1)

for alpha_D in 0_1; do # In set_config.sh, alpha_D and r_inv are split by 2nd character. So 0_1 = 0.1
    for m_Z in 3000; do
	for r_inv in 0_3; do

	    for seed in  $(seq 1 1 $n_of_seeds); do
		seed=$(echo 3000+$seed | bc)

		$PWD/set_batch.sh $work_space $n_of_events $alpha_D $m_Z $r_inv $seed $n_of_threads
		mkdir logs
		if [ ! -d logs ]; then
		    mkdir logs
		fi
		if [ ! -z $n_of_threads ]; then

			if [[ "$HOSTNAME" == *"soolin"* ]]; then
				# HTCondor submission script
				Universe = vanilla
				cmd = $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh # Command to run
				use_x509userproxy = true
				Log        = condor_job_\$(Process).log
				Output     = condor_job_\$(Process).out
				Error      = condor_job_\$(Process).error
				should_transfer_files   = YES
				when_to_transfer_output = ON_EXIT_OR_EVICT
				# Resource requests
				request_cpus = 1
				request_disk = 100000 # kB
				request_memory = 900 # MB
				# Number of instances of job to run
				queue 1
				
			else
		    	if [ -z $MAIL ]; then
				qsub -N job_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed} -o logs/ -e logs/ -q $queue -cwd $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
		    	else
				qsub -N job_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed} -o logs/ -e logs/ -q $queue -cwd -m ae -M $MAIL $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
		    	fi
			fi

		fi
	    done
	done
    done
done
	       
   
exit
