#!/bin/bash
###############################################################################
#DESCRIPTION: This script will parse through an output text file and print   ##
#             The variables.                                                 ##
#AUTHOR: MATTHEW KOZIEL                                                      ##
#DATE: 2019/03/04                                                            ##
#USAGE: sh vsam_parse.sh {INPUT_FILE}                                        ##
###############################################################################

###############################################################################
##                          ENVIRONMENT SETUP                                ##
##DESCRIPTION: Setting up Environment variables for the script               ##
###############################################################################
log_dir="$OPENFRAME_HOME/log/scripts"
basename=$(basename $0)
default_volser="DEFVOL"
DATE_=$(date +%Y%m%d)
TEMP_DIR="/home/oframe/common/temp"
input_file="$1"

###############################################################################
## FUNCTION: check_return_code                                               ##
#DESCRIPTION: This function will check the return code of the previous run   ##
#             command, it will abort with RC=100 if there is a problem and   ##
#             output the message into the .err log file                      ##
###############################################################################
check_return_code(){
  rc=$1
  string_=$2

  if [ "$rc" == 0 ];
  then
    echo "$string_ : SUCCESSFUL" >> ${log_dir}/${basename}.${DATE_}.out
  else
    echo "$string_ : FAILED" >> ${log_dir}/${basename}.${DATE_}.err
    exit 100
  fi
}


###############################################################################
## FUNCTION: sed_between                                                     ##
#DESCRIPTION: This function will grab the data between the two ranges passed ##
###############################################################################
sed_between(){

  sed_output=$(sed -n -e '/${1}/,/${2}/p' ${cut_input_file})
  echo "sed_output: ${sed_output}"
}


###############################################################################
## FUNCTION: cut_first_byte                                                  ##
#DESCRIPTION: This function will remove the first column from the input file ##
#             As it is not needed                                            ##
###############################################################################
cut_first_byte(){

  sed 's/^.//g' ${input_file} > ${input_file}.cut
  cut_input_file=${input_file}.cut

}


################################################################################
#FUNCTION:                      remove_temps                                  ##
#DESCRIPTION: When parsing the input file, this function will check for temp  ##
#             datasets by searching for anything starting with && and does    ##
#             not add them to the output_file                                 ##
################################################################################
create_temp_dir(){
  mydir=$(mktemp -dp $TEMP_DIR "$(basename $0).XXXXXXXXXXXX")
  check_return_code $? "mktemp -dp $mydir"
}



################################################################################
#FUNCTION:                         remove_temp_dir                            ##
#DESCRIPTION: This function removes the temporary directory created by the    ##
#             create_temp_dir function                                        ##
################################################################################
remove_temp_dir(){
  rm -r $mydir
  check_return_code $? "rm $mydir"
}

################################################################################
#FUNCTION:                         check_input_file                           ##
#DESCRIPTION: This function will make sure that the file exists and isn't     ##
#             empty.                                                          ##
################################################################################
check_input_file(){
  if [ ! -s "${input_file}" ]
  then
    echo "input_file does not exist or is not in current working directory"
    echo "input_file does not exist or is not in"\
"current working directory" >> ${log_dir}/${basename}.${DATE_}.err
    exit 100
  fi
}

################################################################################
#FUNCTION: get_clean_rc                                                       ##
#DESCRIPTION: This function checks the input file for the return code of the  ##
#             CLEAN step.                                                     ##
################################################################################
get_clean_rc(){

#  clean_rc=$(cat ${cut_input_file} | grep "\-CLEAN" | head -1 | cut -d" " -f20)
  clean_rc=$(cat ${cut_input_file} | grep "\-CLEAN" | head -1 | awk -v RS=$"\t" '/CLEAN/{getline; print $4}')
  echo "clean_rc: ${clean_rc}"
}

################################################################################
#FUNCTION: check_passed_rc                                                    ##
#DESCRIPTION: This function checks the the return code passed in against 00   ##
################################################################################
check_passed_rc(){
  if [ "$1" -ne "00" ]
  then
#    echo "$1 RC NOT 0"
    echo "$1 RC NOT 0" >> ${log_dir}/${basename}.${DATE_}.err
    echo "STOPPING SCRIPT"
    exit 100
  else
#    echo "$1 RC == 00"
    echo "$1 RC == 00" >> ${log_dir}/${basename}.${DATE_}.out
  fi
}
################################################################################
#FUNCTION: get_repro_rc                                                       ##
#DESCRIPTION: This function checks the input file for the return code of the  ##
#             REPRO step.                                                     ##
################################################################################
get_repro_rc(){

  repro_rc=$(cat ${cut_input_file} | grep "\-REPRO" | head -1 | awk -v RS=$"\t" '/REPRO/{getline; print $4}')
  echo "repro_rc: ${repro_rc}"

}

################################################################################
#FUNCTION: get_listcat_entry                                                  ##
#DESCRIPTION: This function checks the input file for LISTCAT ENTRIES. Then   ##
#             it records the name of the dataset inside the parenthesis       ##
################################################################################
get_listcat_entry(){
  listcat_entry=$(grep "LISTCAT ENTRIES(" ${input_file} | head -1 | cut -d"(" -f2 | cut -d")" -f1)
  echo "LISTCAT ENTRY: $listcat_entry"
}

################################################################################
#FUNCTION: get_data_attributes                                                ##
#DESCRIPTION: This function will use the listcat_entry variable to find the   ##
#             Data entry for this dataset                                     ##
################################################################################
get_data_attributes(){
  echo ${listcat_entry}.DATA ATTRIBUTES:
  data_keylen=$(grep -A 16 "DATA ------- ${listcat_entry}.DATA" ${input_file} | grep KEYLEN | cut -d \t -f2 )
  echo $data_keylen
}

################################################################################
#FUNCTION: get_index_attributes                                               ##
#DESCRIPTION: This function will use the listcat_entry variable to find the   ##
#             INDEX entry for this dataset                                    ##
################################################################################
get_index_attributes(){
  echo ${listcat_entry}.INDEX ATTRIBUTES:
  index_keylen=$(grep -A 16 "INDEX ------ ${listcat_entry}.INDEX" ${input_file} | grep KEYLEN | cut -d \t -f2)
  echo $index_keylen
}

################################################################################
#FUNCTION: get_keylen_value                                                   ##
#DESCRIPTION: This function uses the get_data_attributes to further process   ##
#             The the values                                                  ##
################################################################################
get_keylen_value(){
  data_keylen_value=$(echo "${data_keylen}" | cut -d \t -f2 | cut -d"A" -f1 | cut -d"N" -f2 | sed 's/-*//g' | cut -d" " -f1)
  echo "DATA KEYLEN: ${data_keylen_value}"
}


################################################################################
#FUNCTION: get_data_avglrecl_value                                            ##
#DESCRIPTION: This function uses the get_data_attributes to further process   ##
#             The the value for avglrecl                                      ##
################################################################################
get_data_avglrecl_value(){
  data_avglrecl_value=$(echo "${data_keylen}" | cut -d \t -f2 | cut -d"B" -f1 | cut -d"L" -f4 | sed 's/-*//g' | cut -d" " -f1)
  echo "DATA AVGLRECL: ${data_avglrecl_value}"
}

################################################################################
#FUNCTION: get_index_keylen_value                                             ##
#DESCRIPTION: This function uses the get_data_attributes to further process   ##
#             The the value for avglrecl                                      ##
################################################################################
get_index_keylen_value(){
  index_keylen_value=$(echo "${data_keylen}" | cut -d \t -f2 | cut -d"B" -f1 | cut -d"L" -f4 | sed 's/-*//g' | cut -d" " -f1)
  echo "INDEX KEYLEN: ${index_keylen_value}"
}


################################################################################
#FUNCTION: MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN   ##
################################################################################
main(){
  check_input_file
  create_temp_dir
  cp ${input_file} ${mydir}
  cd $mydir
  cut_first_byte

  get_clean_rc
  check_passed_rc ${clean_rc}

  get_repro_rc
  check_passed_rc ${repro_rc}

  get_listcat_entry

  get_data_attributes
  get_index_attributes

  get_keylen_value
  get_data_avglrecl_value

  #sed_between "CLUSTER -------" "CLUSTER--"

  remove_temp_dir
}
main
