#!/bin/bash

LOG_DIR=/var/log/roboshop
SCRIPT_FILE=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOG_DIR/$SCRIPT_FILE.log"
SCRIPT_DIR=$(pwd)
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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE_STATUS "nginx disable "
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE_STATUS "enable nginx "
dnf install nginx -y &>>$LOG_FILE
VALIDATE_STATUS "install nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE_STATUS "system nginx enable, start "

rm -rf /usr/share/nginx/html/* 
VALIDATE_STATUS "removed all html files "

cd /usr/share/nginx/html 
wget https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
unzip frontend-v3.zip
VALIDATE_STATUS "unzip frontend "

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE_STATUS "replaced nginx.conf "

systemctl restart nginx
VALIDATE_STATUS "nginx restart "



