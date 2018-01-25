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
if [ ! -d $work_space ]; then
    mkdir $work_space
fi

# Set up CMSSW environments
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481
if [ -r $work_space/CMSSW_7_1_28/src ]; then
    echo release CMSSW_7_1_28 already exists
else
    cd $work_space
    scram p CMSSW_7_1_28
fi

export SCRAM_ARCH=slc6_amd64_gcc530
if [ -r $work_space/CMSSW_8_0_21/src ]; then
    echo release CMSSW_8_0_21 already exists
else
    cd $work_space
    scram p CMSSW_8_0_21
fi

cd $work_space/../

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
			request_disk = 10000000
			request_memory = 2000
                        +MaxRuntime = 7200
			# Number of instances of job to run
			queue 1
			" > $work_space/run_scripts/condor_submission_${seed}.job

			condor_submit $work_space/run_scripts/condor_submission_${seed}.job
			
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
	       
echo "
#!/bin/bash
# Hadd component miniAODs, then delete
cd $work_space/CMSSW_8_0_21/src
cmsenv
cd $work_space/output/alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}
hadd alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_MINIAOD_final.root *MINIAOD.root
rm *MINIAOD.root
cd $work_space/../
rm hadd_miniAODs.sh
" > ./hadd_miniAODs.sh

chmod +x hadd_miniAODs.sh
   
exit
