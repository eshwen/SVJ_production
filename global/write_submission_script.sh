#!/bin/bash

# Write the HTCondor submission script for sample generation

work_space=$1
alpha_D=$2
m_Z=$3
r_inv=$4
seed=$5

echo "# HTCondor submission script
Universe = vanilla
executable = $work_space/run_scripts/run_batch_alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_${seed}.sh
Log        = $work_space/logs/condor_job_${seed}.log
Output     = $work_space/logs/condor_job_${seed}.out
Error      = $work_space/logs/condor_job_${seed}.error
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT_OR_EVICT
" > $work_space/run_scripts/condor_submission_${seed}.job

if [[ "$HOSTNAME" == "soolin"* ]]; then                                                                             
    echo "use_x509userproxy = true" >> $work_space/run_scripts/condor_submission_${seed}.job
fi

echo "# Resource requests (disk storage in kB, memory in MB)
request_cpus = 1
request_disk = 1000000
request_memory = 2500
+MaxRuntime = 7200
# Number of instances of job to run
queue 1
" >> $work_space/run_scripts/condor_submission_${seed}.job