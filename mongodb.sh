#!/bin/bash

LOG_DIR=/var/log/roboshop
SCRIPT_FILE=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOG_DIR/$SCRIPT_FILE.log"

#colors
R="\e[31m"
G="\e[32m"
B="\e[34m"
N="\e[0m"

#checking rootuser
IS_ROOT_USER(){
    if [ $(id -u) == 0 ]; then
        echo -e "$G Running as root user $N"
    else
        echo -e "$R Permission denied, Not a Root user $N"
        exit 1
    fi
}

#validate status
VALIDATE_STATUS(){
    if [ $? == 0 ] ; then
        echo -e "$G $1 successful $N" | tee -a $LOG_FILE
    else 
        echo -e "$R $1 failed $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE_AND_INSTALL_MONGODB(){
    dnf search mongodb-org
    VALIDATE_STATUS "mongodb"
    dnf install mongodb-org -y  &>>$LOG_FILE
    VALIDATE_STATUS "mongodb Install"
    systemctl enable mongod | tee -a $LOG_FILE
    systemctl start mongod | tee -a $LOG_FILE
    VALIDATE_STATUS "mongodb enabled and started"
}

CONFIGURE_MONGODB_AND_RESTART(){
    local configFile="/etc/mongod.conf"
    sed -i 's/127.0.0.1/0.0.0.0/g' $configFile
    VALIDATE_STATUS " Mongodb configure "
    systemctl restart mongod | tee -a $LOG_FILE
    VALIDATE_STATUS " Mongodb Restart "
}

IS_ROOT_USER
mkdir -p $LOG_DIR
# mongodb repo file is created explicitly and copying to /etc/yum.repos.d/mongodb.repo
cp mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE_AND_INSTALL_MONGODB
CONFIGURE_MONGODB_AND_RESTART






