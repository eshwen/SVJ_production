#!/usr/bin/env python
import argparse
import os
import stat
import sys
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("-w", "--workingDir", default = os.path.join("Working_Dir"), help = "Top level of working directory to store the output")
parser.add_argument("-n", "--nEvents", default = 100000, type = int, help = "Number of events to generate")
parser.add_argument("--alphaD", default = 0.1, type = float, help = "Running dark coupling strength")
parser.add_argument("--mZ", default = 3000, type = int, help = "Mass of the Z'")
parser.add_argument("--rInv", default = 0.3, type = float, help = "Fraction of dark matter particles")
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
    gridpack_name = "alphaD" + str(alpha_D) + "_mZ" + str(m_Z) + "_rinv" + str(r_inv)
    nested_output = "Output/" + gridpack_name + "/cfg_py"

    if not os.path.exists( os.path.join(work_space, nested_output) ):
        print "Output directory in work space doesn't exist. Creating now..."
        os.makedirs( os.path.join(work_space, nested_output ) )
    
    nEvents = args.nEvents
    nThreads = args.nThreads

    os.chmod("./initialise_cmssw.sh", 0775)
    subprocess.Popen(["./initialise_cmssw.sh", work_space])

    cmssw_output_path = "CMSSW_7_1_28/src/Configuration/GenProduction/python"

    if not os.path.exists( os.path.join(work_space, cmssw_output_path)):
        print "CMSSW output path doesn't exist. Creating now..."
        os.makedirs ( os.path.join(work_space, cmssw_output_path) )

    writePyConfig(gridpack_name, work_space, cmssw_output_path, m_Z, alpha_D, r_inv)

    
    # CONTINUE FROM L138 OF set_config.sh


def writePyConfig(gridpack_name, work_space, cmssw_output_path, m_Z, alpha_D, r_inv):
    """
    Write the Python config file for sample production with Pythia
    """
    
    configPath = work_space + "/" + cmssw_output_path + "/" + gridpack_name + "_GS-fragment.py"
    configFile = open(configPath, "w")

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
            '4900023:mWidth=1',

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
            '4900113:oneChannel = 1 {6} 0 4900213 -4900213',
            '4900113:addChannel = 1 {7} 91 1 -1',
            ),
        parameterSets = cms.vstring(
            'pythia8CommonSettings',
            'pythia8CUEP8M1Settings',
            'processParameters',
        )
    )
)
    """.format(m_Z, m_Z+1, m_Z-1, alpha_D, r_inv, 1.0-r_inv, r_inv, 1.0-r_inv )
    )

    configFile.close()


if __name__ == '__main__':
    main()
    sys.exit("Completed")