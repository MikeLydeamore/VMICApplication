#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=18G
#SBATCH --cpus-per-task=1
module load gcc/10.2.0

./covid_multistrain/covid_ms --ttiq-type=${TTIQ_TYPE} -a${AGE_DIST_FILE} -s${STRAIN_PARAMS} -v${VACCINE_PARAMS} -e${EXPOSURE_PARAMS} -i${IMMUNITY_PARAMS} -c${CONTACT_FILE} -r${SCENARIO_FILE} -o${OUTPUT_DIR} -n$SLURM_ARRAY_TASK_ID -t${T_END}

#./covid_ms ${STRAIN_PARAMS} ${T_END} ${VACCINE_PARAMS} ${EXPOSURE_PARAMS} ${IMMUNITY_PARAMS} ${CONTACT_FILE} ${SCENARIO_FILE} ${TTIQ_TYPE} ${OUTPUT_DIR} ${NUM_SIMS} ${DT}