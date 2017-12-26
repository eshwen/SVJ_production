#!/usr/bin/env python
import argparse
import os
import stat
import sys
from subprocess import call
from string import replace
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("-w", "--workingDir", default = os.path.join("Working_Dir"), help = "Top level of working directory to store the output")
parser.add_argument("-n", "--nEvents", default = 100000, type = int, help = "Number of events to generate")
parser.add_argument("--alphaD", default = 0.2, type = float, help = "Running dark coupling strength at 1 TeV")
parser.add_argument("--mZ", default = 3000, type = int, help = "Mass of the Z' (GeV)")
parser.add_argument("--rInv", default = 0.3, type = float, help = "Fraction of stable hadrons")
parser.add_argument("-s", "--seed", default = 0, type = int, help = "Random number generator seed")
parser.add_argument("--nThreads", default = 1, type = int, help = "Number of threads to execute with")

args = parser.parse_args()


def main():
    
    if not os.path.exists( os.path.abspath(args.workingDir) ):
        print "The directory you have specified: %s, does not exist. Creating now..." % (os.path.abspath(args.workingDir))
        os.mkdir( os.path.abspath(args.workingDir) )

    work_space = os.path.abspath(args.workingDir)

    alpha_D = args.alphaD
    m_Z = args.mZ
    r_inv = args.rInv
    seed = args.seed

    # Define and create output directories if not already done so
    gridpack_name = "alphaD-" + str(alpha_D) + "_mZ-" + str(m_Z) + "_rinv-" + str(r_inv)
    gridpack_name = gridpack_name.replace('.','_')
    nested_output = "Output/" + gridpack_name + "/cfg_py"

    if not os.path.exists( os.path.join(work_space, nested_output) ):
        print "Output directory in work space doesn't exist. Creating now..."
        os.makedirs( os.path.join(work_space, nested_output ) )
    
    nEvents = args.nEvents
    nThreads = args.nThreads

    initialiseCMSSW(cmsswVersion = "7_1_28", arch = "gcc481", work_space = work_space)

    cmssw7_output_path = "CMSSW_7_1_28/src/Configuration/GenProduction/python"

    if not os.path.exists( os.path.join(work_space, cmssw7_output_path)):
        print "CMSSW output path doesn't exist. Creating now..."
        os.makedirs( os.path.join(work_space, cmssw7_output_path) )

    writeGenSimConfig(gridpack_name, work_space, cmssw7_output_path, m_Z, alpha_D, r_inv)

    call("echo $DBS_CLIENT_CONFIG", shell=True)

    call("cmsDriver.py Configuration/GenProduction/python/{0}_GS-fragment.py \
        --fileout {1}/Output/{0}/file:{0}_{2}_GS.root --mc --eventcontent RAWSIM \
        --datatier GEN-SIM --conditions MCRUN2_71_V3::All --beamspot Realistic50ns13TeVCollision \
        --step GEN,SIM -n {3} --python_filename {1}/{4}/{0}_{2}_GS_cfg.py \
        --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1 \
        --magField 38T_PostLS1 --no_exec".format(gridpack_name, work_space, seed, nEvents, nested_output), shell=True)
        # ^^^ Doesn't work and script fails if "cmsenv" / "eval `scram runtime -sh`" doesn't work

    commonStrConfig = "{0}/{1}/{2}_{3}_GS_cfg".format(work_space, nested_output, gridpack_name, seed)
    # Copy the first 8 lines of the first file and write to the second file
    call("head -n8 {0}.py > {0}_tmp.py".format(commonStrConfig), shell=True)
    
    writeCmsRunConfig(work_space, nested_output, gridpack_name, seed)

    # Copy the last 8 lines of the first file and append to the second file
    call("tail -n8 {0}.py >> {0}_tmp.py".format(commonStrConfig), shell=True)
    
    os.remove( "{0}.py".format(commonStrConfig) )
    os.rename(commonStrConfig+"_tmp.py", commonStrConfig+".py")
    
    call ("cmsRun {0}.py -n {1}".format(commonStrConfig, args.nThreads), shell=True)
    print "Starting GEN-SIM production"

    initialiseCMSSW(cmsswVersion = "8_0_21", arch = "gcc530", work_space = work_space)

    call("cmsDriver.py step1 --filein {0}/Output/{1}/file:{1}_{2}_GS.root --fileout {0}/Output/{1}/file:{1}_{2}_DR_step1.root \
    --mc --eventcontent PREMIXRAW --datatier GEN-SIM-RAW --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 \
    --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:@frozen2016 -n {3} \
    --python_filename {0}/{4}/{1}_{2}_DR_step1_cfg.py --datamix PreMix --no_exec \
    #--pileup_input filelist:/mnt/t3nfs01/data01/shome/grauco/pileup_filelist.txt --era Run2_2016".format(work_space, gridpack_name, seed, nEvents, nested_output), shell=True)

    # CONTINUE FROM L209 OF set_config.sh. SEE IF I CAN TIDY UP THE head/tail COMMANDS AND DO THEM IN PYTHON INSTEAD


def writeGenSimConfig(gridpack_name, work_space, cmssw7_output_path, m_Z, alpha_D, r_inv):
    """
    Write the Python config file for sample production with Pythia
    """
    
    configPath = work_space + "/" + cmssw7_output_path + "/" + gridpack_name + "_GS-fragment.py"
    configFile = open(configPath, "w+")

    configFile.write("""
import FWCore.ParameterSet.Config as cms
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

            '4900023:m0 = {0}', #mZprime 
            '4900023:mMax = {1}',
            '4900023:mMin = {2}',
            '4900023:mWidth = 1',

            ##set parameters and masses for HV particles
            '4900211:m0 = 9.9',
            '4900213:m0 = 9.9',
            '4900101:m0 = 10',

            '4900111:m0 = 20', #mDark 
            '4900113:m0 = 20', #mDark 

            #'HiddenValley:Run = on', # turn on coupling running 
            'HiddenValley:fragment = on', # enable hidden valley fragmentation 
            #'HiddenValley:NBFlavRun = 0', # number of bosonic flavor for running 
            #'HiddenValley:NFFlavRun = 2', # number of fermionic flavor for running 
            'HiddenValley:alphaOrder = 1',
            'HiddenValley:Lambda = {3}', #alpha, confinement scale   
            'HiddenValley:nFlav = 1', # this dictates what kind of hadrons come out of the shower, if nFlav = 2, for example, there will be many different flavor of hadrons 
            'HiddenValley:probVector = 0.75', # ratio of number of vector mesons over scalar meson, 3:1 is from naive degrees of freedom counting 
            'HiddenValley:pTminFSR = 10', # cutoff for the showering, should be roughly confinement scale 

            '4900111:oneChannel = 1 {4} 0 4900211 -4900211',
            '4900111:addChannel = 1 {5} 91 1 -1',
            '4900113:oneChannel = 1 {4} 0 4900213 -4900213',
            '4900113:addChannel = 1 {5} 91 1 -1',
            ),
        parameterSets = cms.vstring(
            'pythia8CommonSettings',
            'pythia8CUEP8M1Settings',
            'processParameters',
        )
    )
)
    """.format(m_Z, m_Z+1, m_Z-1, alpha_D, r_inv, 1.0-r_inv)
    )
    configFile.close()

    print "GEN-SIM fragment config written"


def writeCmsRunConfig(work_space, nested_output, gridpack_name, seed):
    """
    """
    configPath = work_space + "/" + nested_output + "/" + "{0}_{1}_GS_cfg_tmp.py".format(gridpack_name, seed)
    configFile = open(configPath, "a")

    configFile.write("""
# reset all random numbers to ensure statistically distinct but reproducible jobs
from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper
randHelper = RandomNumberServiceHelper(process.RandomNumberGeneratorService)
randHelper.resetSeeds({0})

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
        getattr(process,_prod).select.append(\"keep (4900001 <= abs(pdgId) <= 4900991 )\"))
    """.format(seed)
    )
    configFile.close()

    print "cmsRun config file appended"


def initialiseCMSSW(cmsswVersion, arch, work_space):
    """
    Initialise a CMSSW release
    """

    call("source /cvmfs/cms.cern.ch/cmsset_default.sh", shell=True)
    call("export SCRAM_ARCH=slc6_amd64_{0}".format(arch), shell=True)
    if os.path.exists( os.path.join( work_space, "CMSSW_{0}/src".format(cmsswVersion) ) ):
        print "Release CMSSW_{0} already exists".format(cmsswVersion)
    else:
        os.chdir(work_space)
        call("scram p CMSSW_{0}".format(cmsswVersion), shell=True)
        os.chdir("..")

    os.chdir( work_space + "/CMSSW_{0}/src".format(cmsswVersion) )
    call("eval `scram runtime -sh`", shell=True)
    print "Set up CMSSW_{0} environment".format(cmsswVersion) 

    # Compile and re-initialise environment
    os.chdir( os.path.join( work_space, "CMSSW_{0}/src".format(cmsswVersion) ) )
    call("scram b", shell=True)
    call("eval `scramv1 runtime -sh`", shell=True)  


if __name__ == '__main__':
    main()
    sys.exit("Completed")
