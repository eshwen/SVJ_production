#!/bin/bash

if [ -z $1 ]; then
  echo "-----------------------------------------------------------------------------------------------------------------------------
Usage: ./set_config.sh  WORKING_DIRECTORY  NUMBER_OF_EVENTS ALPHA_D M_Z R_INV SEED NUMBER_OF_THREADS(to not execute cmsRun leave empty)
-----------------------------------------------------------------------------------------------------------------------------"
  exit
fi

work_space=$(readlink -m $1)

alpha_D=$3
m_Z=$4
r_inv=$5

seed=$6

alpha_D_mod="${alpha_D:0:1}.${alpha_D:2}"
r_inv_mod="${r_inv:0:1}.${r_inv:2}"
gridpack_name=alphaD${alpha_D}_mZ${m_Z}_rinv${r_inv}

if [ ! -d $work_space/output ]; then
    mkdir $work_space/output
fi

if [ ! -d $work_space/output/$gridpack_name ]; then
  mkdir $work_space/output/$gridpack_name
fi

if [ ! -d $work_space/output/$gridpack_name/cfg_py ]; then
  mkdir $work_space/output/$gridpack_name/cfg_py/
fi

n_of_events=$2
nThreads=$7

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481
cd $work_space/CMSSW_7_1_28/src
eval `scram runtime -sh`

if [ ! -d $work_space/CMSSW_7_1_28/src/Configuration ]; then
  mkdir $work_space/CMSSW_7_1_28/src/Configuration $work_space/CMSSW_7_1_28/src/Configuration/GenProduction $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python
fi

if [ ! -d $work_space/CMSSW_7_1_28/src/Configuration/GenProduction ]; then
  mkdir $work_space/CMSSW_7_1_28/src/Configuration/GenProduction $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python
fi

if [ ! -d $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python ]; then
  mkdir $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python
fi

cmssw_path1=$CMSSW_BASE

#if [[ ! -a $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python/${gridpack_name}_GS-fragment.py ]]; then

echo "import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.Pythia8CUEP8M1Settings_cfi import *

generator = cms.EDFilter(\"Pythia8GeneratorFilter\",
    pythiaPylistVerbosity = cms.untracked.int32(1),
    # put here the efficiency of your filter (1. if no filter)
    filterEfficiency = cms.untracked.double(1.0),
    pythiaHepMCVerbosity = cms.untracked.bool(False),
    # put here the cross section of your process (in pb)
    crossSection = cms.untracked.double(0.8),
    comEnergy = cms.double(13000.0),
    maxEventsToPrint = cms.untracked.int32(3),
    PythiaParameters = cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CUEP8M1SettingsBlock,
        processParameters = cms.vstring(
            
            'HiddenValley:ffbar2Zv = on', #it works only in the case of narrow width approx
            
            '4900023:m0 = {:g}'.format($m_Z), #mZprime 
            '4900023:mMax = {:g}'.format($m_Z+1),
            '4900023:mMin = {:g}'.format($m_Z-1),
            '4900023:mWidth=1',

            ##set parameters and masses for HV particles
            '4900211:m0 = {:g}'.format(9.9),
            '4900213:m0 = {:g}'.format(9.9),
            '4900101:m0 = {:g}'.format(10),

            '4900111:m0 = {:g}'.format(20), #mDark 
            '4900113:m0 = {:g}'.format(20), #mDark 

            #'HiddenValley:Run = on', # turn on coupling running 
            'HiddenValley:fragment = on', # enable hidden valley fragmentation 
            #'HiddenValley:NBFlavRun = 0', # number of bosonic flavor for running 
            #'HiddenValley:NFFlavRun = 2', # number of fermionic flavor for running 
            'HiddenValley:alphaOrder = 1',
            'HiddenValley:Lambda = {:g}'.format($alpha_D_mod), #alpha, confinement scale   
            'HiddenValley:nFlav = 1', # this dictates what kind of hadrons come out of the shower, if nFlav = 2, for example, there will be many different flavor of hadrons 
            'HiddenValley:probVector = 0.75', # ratio of number of vector mesons over scalar meson, 3:1 is from naive degrees of freedom counting 
            'HiddenValley:pTminFSR = {:g}'.format(10), # cutoff for the showering, should be roughly confinement scale 
            
            '4900111:oneChannel = 1 {:g} 0 4900211 -4900211'.format($r_inv_mod),
            '4900111:addChannel = 1 {:g} 91 1 -1'.format(1.0-$r_inv_mod),
            '4900113:oneChannel = 1 {:g} 0 4900213 -4900213'.format($r_inv_mod),
            '4900113:addChannel = 1 {:g} 91 1 -1'.format(1.0-$r_inv_mod),
            ),
        parameterSets = cms.vstring(
            'pythia8CommonSettings',
            'pythia8CUEP8M1Settings',
            'processParameters',
        )
    )
)" >& $work_space/CMSSW_7_1_28/src/Configuration/GenProduction/python/${gridpack_name}_GS-fragment.py

#else
#  echo "Fragment ${gridpack_name}_GS-fragment.py exists!"
#fi

scram b
cd -

if [ -z $n_of_events ]; then exit; fi

echo $DBS_CLIENT_CONFIG

cd $work_space/CMSSW_7_1_28/src

cmsDriver.py Configuration/GenProduction/python/${gridpack_name}_GS-fragment.py --fileout $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_GS.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions MCRUN2_71_V3::All --beamspot Realistic50ns13TeVCollision --step GEN,SIM -n $n_of_events --python_filename $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg.py --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1 --magField 38T_PostLS1 --no_exec

head -n -8 $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg.py >  $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg_tmp.py

echo "
# reset all random numbers to ensure statistically distinct but reproducible jobs
from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper
randHelper = RandomNumberServiceHelper(process.RandomNumberGeneratorService)
randHelper.resetSeeds($seed)

# genjet/met settings - treat HV mesons as invisible
_particles = [\"genParticlesForJetsNoMuNoNu\",\"genParticlesForJetsNoNu\",\"genCandidatesForMET\",\"genParticlesForMETAllVisible\"]
for _prod in _particles:
    if hasattr(process,_prod):
            hv = [4900211, 4900213]
            getattr(process,_prod).ignoreParticleIDs.extend(hv)
if hasattr(process,'recoGenJets') and hasattr(process,'recoAllGenJetsNoNu'):
    process.recoGenJets += process.recoAllGenJetsNoNu
if hasattr(process,'genJetParticles') and hasattr(process,'genParticlesForJetsNoNu'):
    process.genJetParticles += process.genParticlesForJetsNoNu
    getattr(process,\"RAWSIMoutput\").outputCommands.extend([
        'keep *_genParticlesForJets_*_*',
        'keep *_genParticlesForJetsNoNu_*_*',
    ])

# miniAOD settings
_pruned = [\"prunedGenParticles\"]
for _prod in _pruned:
    if hasattr(process,_prod):
        # keep HV particles
        getattr(process,_prod).select.append(\"keep (4900001 <= abs(pdgId) <= 4900991 )\")
">> $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg_tmp.py

tail -n -8 $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg.py >>  $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg_tmp.py
mv $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg_tmp.py $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg.py

if [ ! -z $nThreads ]; then
  cmsRun $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_GS_cfg.py -n $nThreads
  echo ls -l 
  echo 'STARTING GS PRODUCTION'
fi

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc530
cd $work_space/CMSSW_8_0_21/src
eval `scram runtime -sh`
scram b
cd -

cmsDriver.py step1 --filein $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_GS.root --fileout $work_space/output/$gridpack_name/${gridpack_name}_${seed}_DR_step1.root --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:@frozen2016 -n $n_of_events --python_filename $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_DR_step1_cfg.py --era Run2_2016 --datamix PreMix --no_exec --pileup_input filelist:${work_space}/../global/pileup_filelist.txt

if [ ! -z $nThreads ]; then
  cmsRun $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_DR_step1_cfg.py -n $nThreads
fi

rm $work_space/output/$gridpack_name/${gridpack_name}_${seed}_GS.root

cmsDriver.py step2 --filein $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_DR_step1.root --fileout $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_DR.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step RAW2DIGI,RECO,EI -n $n_of_events --python_filename $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_DR_cfg.py --era Run2_2016 --no_exec

if [ ! -z $nThreads ]; then
  cmsRun $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_DR_cfg.py -n $nThreads
fi

cmsDriver.py step1 --filein $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_DR.root --fileout $work_space/output/$gridpack_name/file:${gridpack_name}_${seed}_MINIAOD.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --step PAT -n $n_of_events --python_filename $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py --era Run2_2016 --no_exec

head -n -8 $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py >  $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg_tmp.py

echo "
# miniAOD settings
_pruned = [\"prunedGenParticles\"]
for _prod in _pruned:
    if hasattr(process,_prod):
        # keep HV particles
        getattr(process,_prod).select.append(\"keep (4900001 <= abs(pdgId) <= 4900991 )\")
">> $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg_tmp.py

tail -n -8 $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py >> $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg_tmp.py
rm $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py
mv $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg_tmp.py $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py

if [ ! -z $nThreads ]; then
  cmsRun $work_space/output/$gridpack_name/cfg_py/${gridpack_name}_${seed}_MINIAOD_cfg.py -n $nThreads
fi

rm $work_space/output/$gridpack_name/${gridpack_name}_${seed}_DR*.root

exit
