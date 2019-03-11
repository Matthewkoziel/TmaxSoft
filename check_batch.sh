#!/bin/bash

#uncomment for debugging
# set -x
####################################################################
#Author: Matthew Koziel & Manoj Aerroju & David Regan              #
#Date: 9/18/2018                                                   #
#                                                                  #
####################################################################

####################################################################
#Variables Section                                                 #
                                                                   #
Default_Script_Directory=${OPENFRAME_HOME}/scripts                 #
Default_OpenFrame_User="oframe"                                    #
Default_Tibero_User="oftibr"                                       #
Whoami=`whoami`                                                    #
Script_Directory=$Default_Script_Directory                         #
Log_Directory=${Script_Directory}/logs                             #
OpenFrame_License_Dir=${OPENFRAME_HOME}/license                    #
Date=`date +%Y%m%d`                                                #
Time=`date +%H%M%S`                                                #
Output_File=$Log_Directory/check_batch.out.$Date                   #
                                                                   #
#These Variables may have to be                                    #
#changed on a project to project basis                             #
                                                                   #
                                                                   #
Core_Config_File=${OPENFRAME_HOME}/core/config/oframe.m            #

####################################################################


check_return_code(){
   RC_=$1
   String_=$2

   if [ "$RC_" == 0 ];
   then
      echo "$String_ : SUCCESSFUL" >> $Output_File
   else
      echo "$String_ : FAILED" >> $Output_File
      exit 10
   fi

}



remove_old_Output_File(){
   cd $Log_Directory
   check_return_code $? "cd $Log_Directory"
   if [ -f $Output_File ];then
      rm $Output_File
      check_return_code $? "rm $Output_File"
   fi
}


#Checking that the correct authorized user is running the script
check_user(){
if [[ "$Whoami" != "$Default_OpenFrame_User" && "$Whoami" != "$Default_Tibero_User" ]];then
   echo "Only $Default_OpenFrame_User or $Default_Tibero_User can use this script"
   exit 1
fi
}

check_tjes(){

   tjesmgr -v
   tjes_RC=`echo $?`
   if [ "$tjes_RC" != 0 ]; then
     echo "tjesmgr status     ...    [PROBLEM]" >> $Output_File
   else
     echo "tjesmgr status     ...    [OK]" >> $Output_File
   fi
}
check_lic(){
   cd $OpenFrame_License_Dir
   tjesmgr license $1
   Return_Code=`echo $?`
   if [ "$Return_Code" != 0 ];then
      echo "$1 status  ...  [PROBLEM]" >> $Output_File
   else
      echo "$1 status  ...  [OK]" >> $Output_File
   fi
}
check_tjes_licenses(){
   check_lic lictjes.dat
   check_lic licbase.dat
   check_lic lichidb.dat
   check_lic lictacf.dat
   check_lic licosi.dat
}
check_svr_processes(){
tmadmin << EOF
si
EOF
}
cat_output(){
   cat $Output_File
}


main(){
remove_old_Output_File
check_user
check_tjes
check_tjes_licenses
check_svr_processes
cat_output
}
main
