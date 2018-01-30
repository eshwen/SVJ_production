# Write hadding script

work_space=$1
alpha_D=$2
m_Z=$3
r_inv=$4

echo "#!/bin/bash
# Hadd component miniAODs, then delete
cd $work_space/CMSSW_8_0_21/src
cmsenv
cd $work_space/output/alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}
hadd -k alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_MINIAOD_final.root *MINIAOD.root
rm *MINIAOD.root
cd $work_space/../
rm hadd_miniAODs.sh
" > ../hadd_miniAODs.sh

chmod +x ../hadd_miniAODs.sh