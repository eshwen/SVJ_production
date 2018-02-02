#!/bin/bash

# Write hadding script

work_space=$1
alpha_D=$2
m_Z=$3
r_inv=$4

echo "#!/bin/bash
# Hadd component miniAODs, then delete
source /cvmfs/cms.cern.ch/cmsset_default.sh
cd $work_space/CMSSW_8_0_21/src
eval \`scramv1 runtime -sh\`
cd $work_space/output/alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}
hadd -k alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_MINIAOD_final.root *MINIAOD.root
rm *MINIAOD.root
cd $work_space/../
rm hadd_miniAODs.sh
" > $work_space/hadd_miniAODs.sh

chmod +x $work_space/hadd_miniAODs.sh