#!/bin/bash
#----------------------------------------------------------------------------------------------------
# Name:         Iterative tcpdump Script for RHELv7/CentOSv7      
# Purpose:      Streamline the setup of an iterative tcpdump scheme where disks are not overflowed
# Author:       hyraxai@gmail.com
# Created:      November 2016
#----------------------------------------------------------------------------------------------------

#Start / Information
#----------------------------------------------------------------------------------------------------
clear
printf "[i] This program will guide the setup of a packet capturing machine and\n    aid the setup of dependancies and security.\n"
printf "\nBefore continuing, be sure to configure and mount a secure storage device.\n"
printf "\nAlso, at somepoint, make sure sshd is configured securely.\n\n"

#Presteps
#----------------------------------------------------------------------------------------------------
#date install check
if ! hash date &>/dev/null;
then
read -p "[ ] Dependency: date is not currently installed. Type Y or y to install. " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
  yum install -y date
  clear
  fi
else
  printf "[*] Dependency check: date is already installed.\n"
fi

#tcpdump install check
if ! hash tcpdump &>/dev/null;
then
read -p "[ ] Dependency: tcpdump is not currently installed. Type Y or y to install. " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
  yum install -y tcpdump
  clear
  fi
else
  printf "[*] Dependency check: tcpdump is already installed.\n"
fi

#optionally update the system
read -p "[~] Optional: Do you want to run updates? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  yum update -y
  yum upgrade -y
  clear
fi

#optionally disable firewalld, install and enable iptables
read -p "[~] Optional: Do you want to disable firewalld and setup a highly restrictive iptables ruleset? " -n 1 -r
echo   # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "[!] WARNING: Enter the IP or network you intend to connect from, otherwise you will be locked out!"
  echo "IP or CIDR Network: "
  read usersIP
  systemctl stop firewalld
  systemctl disable firewalld
  yum install iptables-services
  systemctl enable iptables
  systemctl start iptables

  #create iptables rules
  iptables -F
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -s $usersIP -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
  iptables -L -n
  service iptables save
  systemctl restart iptables
  systemctl status iptables
  clear
fi

read -p "[~] Optional: Do you need to create a new directory to store packet capture files? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
read madeDirectory
mkdir $madeDirectory
fi

#Setup TCPDUMP guide
#----------------------------------------------------------------------------------------------------
read -p "[!] The setup process will now begin. Enter Y or y to proceed: " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  printf "\n[i] Available Interfaces:\n\n"
  tcpdump -D

  printf "\n[-] Please enter your preferred capture interface from the list above: "
  read interface

    if [[ $madeDirectory != ''  ]]
      then
      read -p "[?] Do you want to use the directory you created earlier? " -n 1 -r
      echo    # (optional) move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]
        then
          directory=$madeDirectory
        fi
      else
          printf "\n[-]Enter an existing destination directory for pcaps, DO NOT include trailing '/' (e.g ~/Desktop): "
          read directory
    fi

  printf "\n[-] Enter the base file name (e.g. HR_Network): "
  read fileName

  printf "\n[i] Available space:\n"
  df -h

  printf "\n[-] Set max filesize (e.g. 10 = 10MB, 100 = 100MB, 1000 = 1GB ): "
  read fileSize

  printf "\n[-] Set rollover integer (e.g. 2000): "
  read rolloverInt
else
  exit
fi

printf "\n[!] The directory $directory and it's contents can be modified to be owend by root, the group wheel, and chmoded to 770.\n"
read -p "[?] Do you want to make the permissions changes? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  chown -R root $directory
  chgrp -R wheel $directory
  chmod -R 770 $directory
fi

totalSpaceInMB=$((($fileSize*$rolloverInt)))
totalSpaceInGB=$((($fileSize*$rolloverInt)/1000))
printf "\n[i] Summary:\n "
echo "--------------------"
printf "    Interface: $interface\n    Destination directory: $directory\n    Filename: $fileName\n    Filesize: $fileSize MB\n    Rollover Count: $rolloverInt"
printf "\n    Total space to be used: $totalSpaceInMB MB ($totalSpaceInGB GB)\n"
echo "--------------------"

read -p "[?] Initialize? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  date +'%Y-%m-%d_%H:%M:%S' | xargs -I {} bash -c "sudo tcpdump -q -i $interface -w $directory/{}$fileName.cap -C $fileSize -W $rolloverInt -Z root"
  #sudo tcpdump -q -i $interface -w $directory/$fileName.cap -C $fileSize -W $rolloverInt -Z root
fi
