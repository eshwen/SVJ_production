#!/bin/bash

if [ -z $1 ]; then
  echo "-------------------------------------------------------------------------------------------------------------------------------------
Usage: ./set_batch.sh  WORKING_DIRECTORY NUMBER_OF_EVENTS  ALPHA_D M_Z R_INV SEED NUMBER_OF_THREADS(to not execute cmsRun leave empty) SUBMISSION_DIR
-------------------------------------------------------------------------------------------------------------------------------------"
  exit
fi

workdir=$1
if [ ! -d $workdir ]; then mkdir $workdir; fi

workdir=$(readlink -m $workdir)
n_of_events=$2
alpha_D=$3
m_Z=$4
r_inv=$5
seed=$6
n_of_threads=$7
submission_dir=$8

name_of_dir=alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}

if [ ! -d $workdir/run_scripts ]; then mkdir $workdir/run_scripts; fi

echo "#!/bin/bash

$submission_dir/set_config.sh $workdir $n_of_events $alpha_D $m_Z $r_inv $seed $n_of_threads $submission_dir

exit" >& $workdir/run_scripts/run_batch_$(basename $name_of_dir)_${seed}.sh

chmod +x $workdir/run_scripts/run_batch_$(basename $name_of_dir)_${seed}.sh

echo "$workdir/run_scripts/run_batch_$(basename $name_of_dir)_${seed}.sh was created!"

exit
