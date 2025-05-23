#!/bin/bash

#
# Set environment
#

function simu_killall()
{
  sleep 1 ; killall -SIGINT rviz2
  sleep 1 ; killall -SIGINT sick_generic_caller
  sleep 1 ; killall -SIGINT sick_scan_emulator
  sleep 1 ; killall -9 rviz2
  sleep 1 ; killall -9 sick_generic_caller
  sleep 1 ; killall -9 sick_scan_emulator 
  sleep 1
}

# Wait for max 30 seconds, or until 'q' or 'Q' pressed, or until rviz is closed
function waitUntilRvizClosed()
{
  duration_sec=$1
  sleep 1
  for ((cnt=1;cnt<=$duration_sec;cnt++)) ; do  
    echo -e "sick_scan_xd running. Close rviz or press 'q' to exit..." ; read -t 1.0 -n1 -s key
    if [[ $key = "q" ]] || [[ $key = "Q" ]]; then break ; fi
    rviz_running=`(ps -elf | grep rviz2 | grep -v grep | wc -l)`
    if [ $rviz_running -lt 1 ] ; then break ; fi
  done
}

function run_mrs1xxx_simu()
{
  # Start sick_scan_xd emulator
  pcapng_json_file=$1
  duration_sec=$2
  cp -f $pcapng_json_file /tmp/lmd_scandata.pcapng.json
  ros2 run sick_scan_xd sick_scan_emulator ./src/sick_scan_xd/test/emulator/launch/emulator_mrs1xxx_imu.launch &
  sleep 1
  
  # Start sick_scan_xd driver for mrs1104
  echo -e "Launching sick_scan_xd sick_mrs_1xxx.launch\n"
  ros2 launch sick_scan_xd sick_mrs_1xxx.launch.py hostname:=127.0.0.1 port:=2111 sw_pll_only_publish:=False &
  sleep 1
  
  # Start rviz
  ros2 run rviz2 rviz2 -d ./src/sick_scan_xd/test/emulator/config/rviz_emulator_cfg_ros2_mrs1104.rviz &
  sleep 1
  
  # Wait for 'q' or 'Q' to exit or until rviz is closed
  ros2 topic echo --csv /sick_mrs_1xxx/imu &
  waitUntilRvizClosed $duration_sec
  
  # Shutdown
  simu_killall
}

simu_killall
printf "\033c"
pushd ../../../..
if   [ -f /opt/ros/jazzy/setup.bash    ] ; then source /opt/ros/jazzy/setup.bash ; export QT_QPA_PLATFORM=xcb
elif [ -f /opt/ros/humble/setup.bash   ] ; then source /opt/ros/humble/setup.bash
elif [ -f /opt/ros/foxy/setup.bash     ] ; then source /opt/ros/foxy/setup.bash
elif [ -f /opt/ros/eloquent/setup.bash ] ; then source /opt/ros/eloquent/setup.bash
fi
source ./install/setup.bash

# Run sick_scan_xd with MRS1xxx emulator
pcapng_folder=`(pwd)`/src/sick_scan_xd/test/emulator/scandata
run_mrs1xxx_simu $pcapng_folder/20240304-MRS1xxx-default-settings-rssiflag-3.pcapng.json 10
run_mrs1xxx_simu $pcapng_folder/20240307-MRS1xxx-default-settings-rssiflag3-angres0.2500-scanfreq50.0.pcapng.json 10
run_mrs1xxx_simu $pcapng_folder/20240307-MRS1xxx-default-settings-rssiflag3-angres0.1250-scanfreq25.0.pcapng.json 10
run_mrs1xxx_simu $pcapng_folder/20240307-MRS1xxx-default-settings-rssiflag3-angres0.0625-scanfreq12.5.pcapng.json 10
run_mrs1xxx_simu $pcapng_folder/20240304-MRS1xxx-default-settings-rssiflag-1.pcapng.json 10

popd

