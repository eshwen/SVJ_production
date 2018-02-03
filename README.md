# SVJ_production

This repository contains code for generating samples containing semi-visible jets. The generation is currently done in Pythia, and will likely be ported to MadGraph in the future.

Sample generation can be run on a batch system (currently Zurich, Imperial College London, Bristol and lxplus are supported). To submit sample generation to batch, run

```bash
./run_bunch_batch.sh  WORKING_DIRECTORY(relative or absolute)  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS  NUMBER_OF_THREADS(to not execute cmsRun leave empty)  EMAIL_ADDRESS
```

The default values for the important parameters (alpha\_D, r\_inv and m\_Z') are specified in run\_bunch\_batch.sh with underscores replacing decimals (i.e., 0\_1 = 0.1). Once the jobs have finished, run

```bash
./hadd_miniAODs.sh
```

to `hadd` all the component miniAOD files together and clean them up.

A Python version of the sample generation is currently under development. For now, users should only use the bash scripts.


## Batch specifics

The batch submission commands are slightly different for Zurich and IC, and very different for Bristol and lxplus. The script should be able to determine which site you're at. If an error message occurs, try `echo $HOSTNAME` and compare with the statements in the script.

A valid grid certificate may be required to run on your site's cluster. If so, initialise a proxy with

```bash
voms-proxy-init --voms cms --valid 168:00
```

which is valid for one week.

At Imperial and Zurich, you can check on your jobs with `qstat`. At Bristol and lxplus, use `condor_q <user>`.

Keep in mind the memory and disk requests when submitting the Condor jobs. They are designed to run lots of small jobs, rather than few large jobs. Try to keep the number of events per job < 10.


## Miscellaneous

Further reading to understand the theoretical motiviations of this search can be found at [![arXiv](https://img.shields.io/badge/arXiv-1707.05326%20-green.svg)](https://arxiv.org/abs/1503.00009) and [![arXiv](https://img.shields.io/badge/arXiv-1707.05326%20-green.svg)](https://arxiv.org/abs/1707.05326).


## Features to add/bugs to fix

- Fix batch submission at Bristol. Need to store software on /software/, but submit jobs from /storage/.
- Fix Python environment issues. Need to be able to `cmsenv`, and run `cmsDriver.py` and `cmsRun`.
- Finish writing Python version of scripts and tidy up.
- Sometimes there are issues when hadding the component miniAODs. Write code to make a TChain instead.
- Port hard scatter/matrix element calculations to MadGraph, and then shower with Pythia.
- Think about adding CRAB support. Would be able to submit easily from different machines, and can monitor/resubmit jobs easily.
- Once issues are fixed and MadGraph support has been added, can request central production.