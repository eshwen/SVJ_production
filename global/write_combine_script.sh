#!/bin/bash
# Write ROOT macro to combine component miniAODs

work_space=$1
alpha_D=$2
m_Z=$3
r_inv=$4

source /cvmfs/cms.cern.ch/cmsset_default.sh
cd $work_space/CMSSW_8_0_21/src
eval \`scramv1 runtime -sh\`
cd $work_space/output/alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}

mkdir Components
mv *MINIAOD.root Components/

echo "#include \"TMath.h\"
#include \"TFile.h\"
#include \"TTree.h\"
#include <iostream>
#include <fstream>

void chainComponents() {
    TChain * chain = new TChain(\"Events\");
    chain->Add(\"Components/*MINIAOD.root\");
    chain->SaveAs(\"alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}_MINIAOD_final.root\");
    cout << \"Here's a test. The number of events in the chain is \" << chain->GetEntries() << endl;
}
" > chainComponents.cxx

# Currently only writes the "Events" tree from each miniAOD. Can add support if we need the other trees as well

chmod +x chainComponents.cxx
root -l -b -q chainComponents.cxx
rm chainComponents.cxx
