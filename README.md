# SVJ_production

Sample generation can be run on a batch system (currently Zurich and Imperial College London are supported).

Run

```bash
./run_bunch_batch.sh WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS NUMBER_OF_THREADS(to not execute cmsRun leave empty)  SITE  EMAIL_ADDRESS
```

The argument SITE should be 'zurich' or 'imperial', as the submission commands are slightly different for each batch system.
The argument EMAIL_ADDRESS is optional.

The default values for the important parameters (alpha\_D, r\_inv and m\_Z') are specified in run\_bunch\_batch.sh with underscores replacing decimals (i.e., 0\_1 = 0.1).
