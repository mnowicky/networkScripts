#!/bin/bash

#--------------------------------------------------------------#
# FILENAME:      test_network.sh                               #
# DESCRIPTION:   Various port, packet, segment checks          #
# LOGS:          test_network_checkport.log                    #
#                test_network_packets.log                      #
#                test_network_segments.log                     #
#--------------------------------------------------------------#

#--------------------------------------------------------------#
# Help                                                         |
#--------------------------------------------------------------#
if [ $# -ne 5 ]; then
  echo ""
  echo "Usage:"
  echo "  ./test_network.sh [target_ip] [target_port] [number_of_loops] [delay_in_secs] [interface]"
  echo ""
  echo "Logs:"
  echo ""
  echo "  test_network_checkport.log"
  echo "    # Port availability, no packets transmitted"
  echo "    # TIMESTAMP | SOURCE HOSTNAME | TARGET IP | TARGET PORT | RESPONSE TIME (SECS)"
  echo "    2021-12-17 21:14:14.731991069|soadev|192.168.1.31|5901|0.01"
  echo "    2021-12-17 21:14:15.284783737|soadev|192.168.1.31|5901|0.01"
  echo "    2021-12-17 21:14:15.837768193|soadev|192.168.1.31|5901|0.01"
  echo ""
  echo "  test_network_packets.log"
  echo "    # Packet transmission and receive packet errors and drops"
  echo "    # TIMESTAMP | SOURCE  HOSTNAME | TARGET IP | TRANSMISSION PACKETS ERRORS | TRANSMISSION PACKETS DROPS | RECEIVE PACKET ERRORS | RECEIVE ERROR DROPS"
  echo "    2021-12-17 21:14:13.626336229|soadev|0|0|0|0"
  echo "    2021-12-17 21:14:14.179361714|soadev|0|0|0|0"
  echo "    2021-12-17 21:14:14.731991069|soadev|0|0|0|0"
  echo ""
  echo "  test_network_segments.log"
  echo "    # Bad and retransmitted segments"
  echo "    # TIMESTAMP | SOURCE HOSTNAME | TARGET IP | BAD SEGMENTS | RETRANSMITTED SEGMENTS | RETRANSMITTED SEGMENTS %"
  echo "    2021-12-17 21:14:13.626336229|soadev|297|30846213|6.25439"
  echo "    2021-12-17 21:14:14.179361714|soadev|297|30846213|6.25439"
  echo "    2021-12-17 21:14:14.731991069|soadev|297|30846213|6.25439"
  echo ""
  echo "Example:"
  echo "  ./test_network.sh"
  echo "  ./test_network.sh 192.168.1.31 443 8 1 eth0"
  echo "  nohup ./test_network.sh 192.168.1.31 443 345600 0.5 eth0 &"
  echo ""
  exit 0
fi

#--------------------------------------------------------------#
# Parameters                                                   |
#--------------------------------------------------------------#
V_TARGETIP=${1}
V_TARGETPORT=${2}
V_LOOP=${3}
V_DELAY=${4}
V_INTERFACE=${5}

#--------------------------------------------------------------#
# Loop                                                         #
#--------------------------------------------------------------#
i=1
while [ ${i} -le ${V_LOOP} ]; do
  V_TIMESTAMP=`date +'%Y-%m-%d %H:%M:%S.%N'`
  i=`expr ${i} + 1`
  sleep ${V_DELAY}

  #--------------------------------------------------------------#
  # Check port                                                   |
  #--------------------------------------------------------------#
  # Log: number of seconds for positive response
  if command -v nc &> /dev/null; then
    nc -vz ${V_TARGETIP} ${V_TARGETPORT} > test_network.tmp 2>&1
    echo "${V_TIMESTAMP}|`hostname`|${V_TARGETIP}|${V_TARGETPORT}|`cat test_network.tmp | tail -1 | awk '{print $9}'`" >> test_network_checkport.log
    rm -f test_network.tmp
  fi

  #--------------------------------------------------------------#
  # Packet errors                                                #
  #--------------------------------------------------------------#
  # Log: Transmitted Packet Errors | Transmitted Packet Drops | Received Packet Errors | Received Packet Drops
  if command -v ip &> /dev/null; then
    V_TX_PACKETERRORS=`cat /proc/net/dev | grep ${V_INTERFACE} | awk {'print $12'}`
    V_TX_PACKETDROPS=`cat /proc/net/dev | grep ${V_INTERFACE} | awk {'print $13'}`
    V_RX_PACKETERRORS=`cat /proc/net/dev | grep ${V_INTERFACE} | awk {'print $4'}`
    V_RX_PACKETDROPS=`cat /proc/net/dev | grep ${V_INTERFACE} | awk {'print $5'}`
    echo "${V_TIMESTAMP}|`hostname`|${V_TX_PACKETERRORS}|${V_TX_PACKETDROPS}|${V_RX_PACKETERRORS}|${V_RX_PACKETDROPS}" >> test_network_packets.log
  fi

  #--------------------------------------------------------------#
  # Segment retransmissions & bad                                #
  #--------------------------------------------------------------#
  # Log: Segments Bad Count | Segments Retransmitted Count | Segments Retransmitted %
  if command -v netstat &> /dev/null; then
    V_SEGS_RETRANSMIT=`netstat -s | grep retransmited | awk {'print $1'}`
    V_SEGS_BAD=`netstat -s | grep bad | grep segments | awk {'print $1'}`
    V_SEGS_RETRANSMITPER=`gawk 'BEGIN {OFS=" "} $1 ~ /Tcp:/ && $2 !~ /RtoAlgorithm/ {print ($13/$12*100)}' /proc/net/snmp`
    echo "${V_TIMESTAMP}|`hostname`|${V_SEGS_BAD}|${V_SEGS_RETRANSMIT}|${V_SEGS_RETRANSMITPER}" >> test_network_segments.log
  fi

done

exit 1
