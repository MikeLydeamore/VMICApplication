for year in {2076..2100} 
do
  STRAIN_PARAMS="covid_multistrain/params/strain_parameters.json"
  VACCINE_PARAMS="covid_multistrain/params/vaccine_params.json"
  EXPOSURE_PARAMS="covid_multistrain/params/exposure_params.json"
  IMMUNITY_PARAMS="covid_multistrain/params/immunity_model_params.json"
  CONTACT_FILE="transpose_matrix_Samoa.csv"
  SCENARIO_FILE="abm_inputs/vmic_vaccination_rollout_"${year}".csv"
  TTIQ_TYPE="partial"
  AGE_DIST_FILE="covid_multistrain/params/dim_age_band.csv"
  OUTPUT_DIR="/scratch/cm37/VIMC/vaccination_year_"${year}
  NUM_SIMS="30"
  T_END="365.0"
  DT="1"
  JOB_NAME=${SCENARIO_FILE}
  
  echo "${JOB_NAME} will be run with 1-${NUM_SIMS} repeats in parallel."
  echo "There will be ${NUM_SIMS} repeats."

  jid1=$(sbatch --parsable --array=1-${NUM_SIMS} --job-name=${JOB_NAME} --export=AGE_DIST_FILE=${AGE_DIST_FILE},STRAIN_PARAMS=${STRAIN_PARAMS},VACCINE_PARAMS=${VACCINE_PARAMS},EXPOSURE_PARAMS=${EXPOSURE_PARAMS},IMMUNITY_PARAMS=${IMMUNITY_PARAMS},CONTACT_FILE=${CONTACT_FILE},SCENARIO_FILE=${SCENARIO_FILE},TTIQ_TYPE=${TTIQ_TYPE},OUTPUT_DIR=${OUTPUT_DIR},NUM_SIMS=${NUM_SIMS},T_END=${T_END},DT=${DT} submit_function.script)

  jidc=$(sbatch --parsable --dependency=afterany:$jid1 --job-name=Compress_${SCENARIO_FILE} --export=FolderName=${year} compress_function.script)
done