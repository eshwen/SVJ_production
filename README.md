# SVJ_production

Sample generation can be run on a batch system (currently Zurich and Imperial College London are supported).

At Zurich, run

```bash
./run_bunch_batch.sh WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS NUMBER_OF_THREADS(to not execute cmsRun leave empty)  MAIL_ADDRESS
```

At Imperial, run

```bash
./run_bunch_imperial_batch.sh WORKING_DIRECTORY  NUMBER_OF_EVENTS  NUMBER_OF_SEEDS NUMBER_OF_THREADS(to not execute cmsRun leave empty)
```

The default values for the important parameters (alpha\_D, r\_inv and m\_Z') are specified in run\_bunch\_batch.sh with underscores replacing decimals (i.e., 0\_1 = 0.1).
