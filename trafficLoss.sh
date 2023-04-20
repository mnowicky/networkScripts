#!/bin/bash

#--------------------------------------------------------------#
# FILENAME:      trafficLoss.sh                                #
# DESCRIPTION:   Test traffic loss                             #
# LOG:           test_trafficloss.log                          #
#--------------------------------------------------------------#

if [ $# -ne 2 ]; then
  echo ""
  echo "Usage:"
  echo "  ./trafficLoss.sh [target_ip] [number_of_loops]"
  echo ""
  echo "Description:"
  echo "  If traffic loss is in the last hop, not an issue with the connection to target."
  echo "  If traffic loss is in the middle, possibly due to ICMP rate limiting; not an issue."
  echo "  If traffic loss is in the middle to the end, likely losing some traffic."
  echo ""
  echo "Example:"
  echo "  ./trafficLoss.sh"
  echo "  ./trafficLoss.sh 192.168.1.31 10"
  echo "  nohup ./trafficLoss.sh 192.168.1.31 10 &"
  echo ""
  exit 0
fi

#--------------------------------------------------------------#
# Parameters                                                   |
#--------------------------------------------------------------#
V_TARGETIP=${1}
V_LOOP=${2}

#--------------------------------------------------------------#
# Loop                                                         #
#--------------------------------------------------------------#
i=1
while [ ${i} -le ${V_LOOP} ]; do
  V_TIMESTAMP=`date +'%Y-%m-%d %H:%M:%S.%N'`
  i=`expr ${i} + 1`

  #--------------------------------------------------------------#
  # Traffic loss                                                 |
  #--------------------------------------------------------------#
  if command -v mtr &> /dev/null; then
    mtr --report ${V_TARGETIP} >> test_trafficloss.log
  fi

done

exit 1
