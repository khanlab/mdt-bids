#!/bin/bash

# run mdt on prepdwi pre-proc data, as a bids app

# <in bids> <out folder>  participant 

# required args:
#  --in_prepdwi_dir <path>
#  --model <modelname>
#  --model_fit_opts <options>


function die {
 echo $1 >&2
 exit 1
}

function fixsubj {
#add on sub- if not exists
subj=$1
 if [ ! "${subj:0:4}" = "sub-" ]
 then
  subj="sub-$subj"
 fi
 echo $subj
}

function fixsess {
#add on ses- if not exists
sess=$1
 if [ ! "${sess:0:4}" = "ses-" ]
 then
  sess="sub-$sess"
 fi
 echo $sess
}


participant_label=

if [ "$#" -lt 3 ]
then
 echo "Usage: $0 <bids_dir> <output_dir> participant <optional arguments>"
 echo ""
 echo " Required arguments:"
 echo "          [--in_prepdwi_dir PREPDWI_DIR]" 
 echo "          [--model MODEL  (e.g. NODDI)]"
 echo ""
 echo " Optional arguments:"
 echo "          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]"
 echo "          [--model_fit_opts \"[options for mdt-model-fit]\""
 echo "          [--create_protocol_opts \"[options for mdt-create-protocol]\""
 echo ""
 exit 1
fi


in_bids=$1
out_folder=$2
analysis_level=$3

in_prepdwi_dir=
model=
model_fit_opts=
create_protocol_opts=

shift 3

######################################################################################
# parameter initialization
######################################################################################
while :; do
      case $1 in
     -h|-\?|--help)
	     usage
            exit
              ;;
      --participant_label )       # takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                  participant_label=$2
                    shift
         	  else
                die 'error: "--participant" requires a non-empty option argument.'
              fi
                ;;
       --participant_label=?*)
            participant_label=${1#*=} # delete everything up to "=" and assign the remainder.
              ;;
            --participant_label=)         # handle the case of an empty --participant=
          die 'error: "--participant_label" requires a non-empty option argument.'
            ;;

           --in_prepdwi_dir )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                in_prepdwi_dir=$2
                  shift
	      else
              die 'error: "--in_prepdwi_dir" requires a non-empty option argument.'
            fi
              ;;
     --in_prepdwi_dir=?*)
          in_prepdwi_dir=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --in_prepdwi_dir=)         # handle the case of an empty --participant=
         die 'error: "--in_prepdwi_dir" requires a non-empty option argument.'
          ;;


           --model )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                model=$2
                  shift
	      else
              die 'error: "--model" requires a non-empty option argument.'
            fi
              ;;
     --model=?*)
          model=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --model=)         # handle the case of an empty --participant=
         die 'error: "--model" requires a non-empty option argument.'
          ;;


           --model_fit_opts )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                model_fit_opts=$2
                  shift
	      else
              die 'error: "--model_fit_opts" requires a non-empty option argument.'
            fi
              ;;

     --model_fit_opts=?*)
          model_fit_opts=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --model_fit_opts=)         # handle the case of an empty --participant=
         die 'error: "--model_fit_opts" requires a non-empty option argument.'
          ;;


           --create_protocol_opts )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                create_protocol_opts=$2
                  shift
	      else
              die 'error: "--create_protocol_opts" requires a non-empty option argument.'
            fi
              ;;

     --create_protocol_opts=?*)
          create_protocol_opts=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --create_protocol_opts=)         # handle the case of an empty --participant=
         die 'error: "--create_protocol_opts" requires a non-empty option argument.'
          ;;


      -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
              ;;
     *)               # Default case: No more options, so break out of the loop.
          break
    esac

 shift
  done


shift $((OPTIND-1))


echo participant_label=$participant_label

if [ -e $in_bids ]
then
	in_bids=`realpath $in_bids`
else
	echo "ERROR: bids_dir $in_bids does not exist!"
	exit 1
fi


if [ "$analysis_level" = "participant" ]
then
 echo " running participant level analysis"
 else
  echo "only participant level analysis is enabled"
  exit 0
fi


participants=$in_bids/participants.tsv

work_folder=$out_folder/work


if [ ! -n "$model" ]
then
	echo "$model not specified, please use the -m option to select a model"
	exit 1
fi

if [ ! -n "$in_prepdwi_dir" ] # if not specified
then

    #if not specified, use stored value:
    if [ -e $work_folder/etc/in_prepdwi_dir ]
    then
        in_prepdwi_dir=`cat $work_folder/etc/in_prepdwi_dir`
        echo "Using previously defined --in_prepdwi_dir $in_prepdwi_dir"
    else
        echo "ERROR: --in_prepdwi_dir must be specified!"
        exit 1
    fi

fi


if [ ! -e $in_prepdwi_dir ]
then
    echo "ERROR: in_prepdwi_dir $in_prepdwi_dir does not exist!"
	exit 1
fi

in_prepdwi_dir=`realpath $in_prepdwi_dir`


echo mkdir -p $work_folder
mkdir -p $work_folder 
work_folder=`realpath $work_folder`

#in_prepdwi_dir defined:
#save it to file
mkdir -p $work_folder/etc
echo "$in_prepdwi_dir" > $work_folder/etc/in_prepdwi_dir


if [ ! -e $participants ]
then
    #participants tsv not required by bids, so if it doesn't exist, create one for temporary use
    participants=$work_folder/participants.tsv
    echo participant_id > $participants
    pushd $in_bids
    ls -d sub-* >> $participants
    popd 
fi


echo $participants

if [ -n "$participant_label" ]
then
subjlist=`echo $participant_label | sed  's/,/\ /g'` 
else
subjlist=`tail -n +2 $participants | awk '{print $1}'`
fi



 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

   #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix


	#get _preproc.nii.gz from prepdwi
	dwi=`ls $in_prepdwi_dir/prepdwi/${subj_sess_dir}/dwi/${subj_sess_prefix}*dwi*preproc.nii.gz | head -n 1`
	bvec=${dwi%%.nii.gz}.bvec
	bval=${dwi%%.nii.gz}.bval
	grad_dev=${dwi%%.nii.gz}.grad_dev.nii.gz

	echo "dwi: $dwi, bvec: $bvec, bval: $bval"

	dwi_prefix=${dwi##*/}
	dwi_prefix=${dwi_prefix%.nii.gz}

	mask=${dwi%%preproc.*}brainmask.nii.gz


	out_subj=$out_folder/${subj_sess_dir}
	mkdir -p $out_subj

	protocol=$out_subj/$dwi_prefix.prtcl

	#use gradient deviations if they exist..
	if [ -e $grad_dev ]
	then
		model_fit_opts="$model_fit_opts --gradient-deviations $grad_dev "
	fi

	#make protocol
	echo mdt-create-protocol $bvec $bval -o $protocol $create_protocol_opts
	mdt-create-protocol $bvec $bval -o $protocol $create_protocol_opts

	#mdt-model-fit
	echo mdt-model-fit $model $dwi $protocol $mask -o $out_subj $model_fit_opts
	mdt-model-fit $model $dwi $protocol $mask -o $out_subj $model_fit_opts
	
	done #subjfolder
done #subj
