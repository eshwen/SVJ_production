#!/bin/bash

work_space=$1

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481

if [ -r $work_space/CMSSW_7_1_28/src ] ; then
  echo release CMSSW_7_1_28 already exists
else
  cd $work_space
  scram p CMSSW_7_1_28
  cd -
fi

cd $work_space/CMSSW_7_1_28/src
eval `scram runtime -sh`

echo Finished initialising CMSSW_7_1_28

exit