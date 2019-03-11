#!/bin/bash

#VARIABLES#
Cobol_Source="/home/oframe/YSW/DB2_Access_Script/Source/"
Cobol_Source_Cut="/home/oframe/YSW/DB2_Access_Script/INSERTS/"
Regexp="INSERT[\s\d\t\n\v]*INTO[\s]*\w*"
Audit_Log="/home/oframe/YSW/DB2_Access_Script/Audit.log"
Audit_Log_Sorted="${Audit_Log}.sorted"
has_Ins=""
has_Upd=""
has_Sel=""
has_Del=""


#FUNCTIONS#
find_Insert(){
echo "Finding Insert Statements..."
cd $Cobol_Source_Cut
for item in `ls $Cobol_Source_Cut`
do
        Table_List=`cat $item | grep -A40 "INSERT" | grep "INTO " | sed -n -e 's/^.*INTO //p' | awk '{print $1}' | head -1`
        #echo $Table_List

        if [ ! -z $Table_List ]
        then
                has_Ins="X"
                print_audit $item $Table_List
                has_Ins=""
        fi
done
echo "Found all Insert Statements..."
}

find_Select(){
echo "...Finding all Select Statements"
cd $Cobol_Source_Cut
#For all the files in the Cobol_Source_Cut directory
for item in `ls`
do
        #And if the File is not empty...
        if [ -s $item ]
        then
                Table_List=`cat $item | grep -A60 "SELECT" | grep -A20 "FROM " | sed -n -e 's/^.*FROM //p' | awk '{print $1}'`

                for Table in $Table_List
                do
                        if [ "$Table" != "(" ] && ! [[ "$Table" =~ ^[0-9]*$ ]]
                        then

                        has_Sel="X"
                        print_audit $item $Table
                        has_Sel=""

                        fi
                done
                #Great for Debugging, Uncomment below 4 lines
                #echo $item
                #echo $Table_List
                #echo ""
                #echo ""
        fi
done
echo "Found all Select statements..."
}

find_Delete(){
echo "...Finding all Delete Statements"
cd $Cobol_Source_Cut
#For all the files in the Cobol_Source_Cut directory
for item in `ls`
do
        #And if the File is not empty...
        if [ -s $item ]
        then
                Table_List=`cat $item | grep -A60 "DELETE" | grep -A20 "FROM " | sed -n -e 's/^.*FROM //p' | awk '{print $1}'`

                for Table in $Table_List
                do
                        if [ "$Table" != "(" ] && ! [[ "$Table" =~ ^[0-9]*$ ]]
                        then

                        has_Del="X"
                        print_audit $item $Table
                        has_Del=""

                        fi
                done
                #Great for Debugging, Uncomment below 4 lines
                #echo $item
                #echo $Table_List
                #echo ""
                #echo ""
        fi
done
echo "Found all Delete Statements..."
}

find_Update(){
echo "...Finding all Update Statements"
cd $Cobol_Source_Cut
#For all the files in the Cobol_Source_Cut directory
for item in `ls`
do
        #And if the File is not empty...
        if [ -s $item ]
        then
                Table_List=`cat $item | grep -A2 "UPDATE " | sed -n -e 's/^.*UPDATE //p' | awk '{print $1}'`
                for Table in $Table_List
                do
                        if [ "$Table" != "(" ] && ! [[ "$Table" =~ ^[0-9]*$ ]]
                        then

                        has_Upd="X"
                        print_audit $item $Table
                        has_Upd=""

                        fi
                done
                #Great for Debugging, Uncomment below 4 lines
                #echo $item
                #echo $Table_List
                #echo ""
                #echo ""
        fi
done
echo "Found all Update Statements..."
}

get_DB2_Statements(){
echo "...Copying Source"
cd $Cobol_Source
cp * ${Cobol_Source_Cut}
echo "Source Copied..."
get_between_exec
remove_beg_line_nums


}
get_between_exec(){
echo "...Removing all Except Exec Statements"
cd $Cobol_Source_Cut
        for item in `ls`; do sed -n '/EXEC SQL/,/END-EXEC./p' $item > tmp && mv tmp ${item}; done
echo "Removed all Except Exec Statements..."
remove_beg_line_nums
}

remove_beg_line_nums(){
echo "...Removing all leading line numbers"
cd $Cobol_Source_Cut
        for item in `ls`; do sed -i 's/^......//p' $item ; done
echo "Removed all leading line numbers..."
}


init_audit_file(){
echo "...Removing Audit Log"
rm ${Audit_Log}.sorted
echo "Audit Log Removed..."
echo "Creating new Audit Log..."
touch ${Audit_Log}
echo "Program:Table/View:SELECT:INSERT:UPDATE:DELETE" > ${Audit_Log}
echo "... New Audit Log Created"
}

print_audit(){

#$1 is the Program Name
#$2 is the Table/View Name
echo "${1}:${2}:${has_Sel}:${has_Ins}:${has_Upd}:${has_Del}" >> ${Audit_Log}
}

remove_duplicates(){
(head -n 2 ${Audit_Log} && tail -n +3 ${Audit_Log} | sort -u) > $Audit_Log_Sorted
rm ${Audit_Log}
}

#MAIN#
main(){
get_DB2_Statements
init_audit_file
find_Insert
find_Select
find_Delete
find_Update
remove_duplicates
}

main
