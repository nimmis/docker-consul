#!/bin/sh
#
# loop thru all versions
#
# (c) 2017 nimmis <kjell.havenskold@gmail.com>
#

RUN_CON_NAME="nimmis/consul"
SUCCESS_RUN=""
FAIL_RUN=""

BASEDIR=$(dirname "$0")

TAGS=$(ls -1l $BASEDIR | grep ^d | grep '[0-9]\.' | awk '{print $NF}')

for TAG in $TAGS; do
  $BASEDIR/run.sh $RUN_CON_NAME $TAG
  if [ "$?" = "0" ]; then
     SUCCESS_RUN="$SUCCESS_RUN$TAG "
  else
     FAIL_RUN="$FAIL_RUN$TAG "
  fi 
done

echo "----- RESULT -----"
echo "SUCCESSFUL TAGS: $SUCCESS_RUN"
echo "FAIL TAGS      : $FAIL_RUN"

