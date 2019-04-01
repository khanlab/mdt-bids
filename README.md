# mdt-bids
bids app wrapper for microstructure diffusion toolbox

 Please see http://github.com/cbclab/mdt for more details

```
Usage: ./run.sh <bids_dir> <output_dir> participant <optional arguments>

 Required arguments:
          [--in_prepdwi_dir PREPDWI_DIR]
          [--model MODEL  (e.g. NODDI)]

 Optional arguments:
          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]
          [--model_fit_opts "[options for mdt-model-fit]"
          [--create_protocol_opts "[options for mdt-create-protocol]"
```


For HCP WU-Minn data (e.g. HCP 1200 3T), use:
```
--create_protocol_opts \"--Delta 21.8e-3 --delta 12.9e-3 --TR 8800e-3 --TE 57e-3\"
```

TO DO: 
 - read in json files to get TR and TE
 - set default --maxG as 0.08 (80 mT/m for our 3T and 7T) 
