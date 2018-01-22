#!/bin/bash

if [ -z $1 ]; then
  echo "----------------------------------------------------------------------------------------------------------------------------------------------------
Usage: ./run_bunch_batch.sh WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS  NUMBER_OF_THREADS(to not execute cmsRun leave empty)  EMAIL_ADDRESS
----------------------------------------------------------------------------------------------------------------------------------------------------"
  exit
fi

init_ind=4
num_ind=1
n_of_events=$2 # number of events per job
n_of_threads=$4
n_of_seeds=$3 # = number of jobs
MAIL=$5

if [[ "$HOSTNAME" == *"ic.ac.uk" ]]; then
    queue=hep.q
elif [[ "$HOSTNAME" == *"uzh"* ]]; then
    queue=long.q
elif [[ "$HOSTNAME" = "soolin"* ]] || [[ "$HOSTNAME" = "lxplus"* ]]; then
    echo Running on $HOSTNAME.
else
    echo Sorry, the remote server at $HOSTNAME is not supported at this time.
    exit
fi

work_space=$(readlink -m $1)

for alpha_D in 0_1; do # In set_config.sh, alpha_D and r_inv are split by 2nd character. So 0_1 = 0.1
    for m_Z in 3000; do
	for r_inv in 0_3; do

	    for seed in  $(seq 1 1 $n_of_seeds); do
		seed=$(echo 3000+$seed | bc)

		$PWD/set_batch.sh $work_space $n_of_events $alpha_D $m_Z $r_inv $seed $n_of_threads
		if [ ! -d $work_space/logs ]; then
		    mkdir $work_space/logs
		fi

		if [ ! -z $n_of_threads ]; then

		    if [[ "$HOSTNAME" == "soolin"* ]] || [[ "$HOSTNAME" == "lxplus"* ]]; then
			echo "
			# HTCondor submission script
			Universe = vanilla
			cmd = $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
			#use_x509userproxy = true
			Log        = $work_space/logs/condor_job_${seed}.log
			Output     = $work_space/logs/condor_job_${seed}.out
			Error      = $work_space/logs/condor_job_${seed}.error
			should_transfer_files   = YES
			when_to_transfer_output = ON_EXIT_OR_EVICT
			# Resource requests (disk storage in kB, memory in MB)
			request_cpus = 1
			request_disk = 5000000
			request_memory = 1000
                        +MaxRuntime = 7200
			# Number of instances of job to run
			queue 1
			" > $work_space/run_scripts/condor_submission.job

			condor_submit $work_space/run_scripts/condor_submission.job
			
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
