#!/usr/bin/bash
#!bin/bash

cd /home/sadc/sadc_cft-1.4.1/
echo $PATH
source python3/bin/activate
mpirun -bind-to hwthread -n 75 python3 cft_mpi.py settings.json > tmp

# to run script sending message verification task
cd /home/sadc/
tail sadc_cft-1.4.1/tmp > coco
cc=$(cat coco)

# to run message slack
python /home/sadc/text_me.py -m "$cc"
rm coco
##################################################
# to run this, need to improve for chrontab task
#nohup bash run_CFT_frcst.sh &
# mamon anle cft bobak b
#killall mpirun
##################################################
