#############################################################
# File Name:run.sh
# Author: Yue
# Created TimeSat 25 Apr 2015 01:31:33 PM CDT
#############################################################
#!/bin/bash

if [ $# != 2 ]; then
	echo "Usage: run.sh <input_file> <output_file>"
	exit -1
fi
echo "Deleting " $2
rm -f $2
echo "Compiling ..."
java -jar $(dirname $0)/Compiler.jar $1 $2~
echo "Result store in " $2~
echo "Translating ..."
java -jar $(dirname $0)/asmbl.jar $2~ > $2
echo "Finish"
