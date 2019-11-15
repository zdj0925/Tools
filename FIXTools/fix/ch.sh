#!/usr/bin/ksh
for LINE in `ls *.fix`
do
        cat $LINE |sed 's/	/        /g' |sed 's/ = / = /g'|sed 's/    /  /g' >$LINE.tmp
        mv $LINE.tmp $LINE
done
