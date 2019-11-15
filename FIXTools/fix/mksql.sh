#!/usr/bin/ksh
echo "" >1.sql
cat 1.log |while read LINE
do
    OPEN_BRANCH=`echo $LINE |cut -d ' ' -f1`
    BANK_ACC=`echo $LINE |cut -d ' ' -f2`
    echo "update tbbankacc set open_branch ='$OPEN_BRANCH' where secu_no ='3210' and bank_acc ='$BANK_ACC';">> 1.sql
                          
done
echo "commit;" >>1.sql

