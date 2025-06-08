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

mkdir -p $LOG_DIR
VALIDATE_STATUS "Directory creation"
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE_STATUS "nodejs disable"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE_STATUS "nodejs enable"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE_STATUS "Install nodejs"

mkdir -p /app
VALIDATE_STATUS "creating app directory"

useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop
VALIDATE_STATUS "creating system user"

cd /app
rm -fr *
wget https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE_STATUS "Downloading catalog source zip"
unzip catalogue-v3.zip &>>$LOG_FILE
VALIDATE_STATUS "Unzip catalog source zip"
npm install &>>$LOG_FILE
VALIDATE_STATUS "Install npm "

cp catalog.service /etc/systemd/system/catalog.service
VALIDATE_STATUS "copy catalog service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalog &>>$LOG_FILE
systemctl start catalog &>>$LOG_FILE
VALIDATE_STATUS "catalog start" 

cp mongodb.repo /etc/yum.repos.d/mongodb.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE_STATUS "install mongo shell" 
mongosh --host mongodb.hkdevops.site </app/db/master-data.js
VALIDATE_STATUS "mongo shell master data loaded" 
