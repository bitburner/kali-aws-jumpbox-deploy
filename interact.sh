#!/bin/bash

# Start to ask the user what to do now
read -p "❔ What is the URL of the target box you are testing?: " target
echo ""
echo "🎯 Storing variable 'target' = $target for later use..."
echo ""

# setup any awscli stuff on the kali box
aws_cli_setup="aws configure --profile kali"

# this is so you can close the WAF if needed or if your IP changes or need to bypass firewalls etc
ngrok="ngrok http 80"

# the good ol standard nmap scan
nmap="nmap -sS -p- -A -oN $target nmap.txt"

# a good comprehensive single level directory scan should be fine
dirbuster="dirbuster -u $target -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"

# I need to look a the options for this one again but it checks permissions on S3 buckets etc
s3sec="s3sec check --region us-west-2"

# do a hail mary - all the full scans back to back
hailmary="nmap -sS -p- -A -oN nmap.txt && dirbuster -u $target -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt && s3sec check --bucket my-bucket --region us-west-1"

# this should gather all created data and make a zip then open a new window with an SSH command it creates to download the zip
collect_data="tar -czf data.tar.gz /data && ssh user@example.com 'mkdir -p data && scp data.tar.gz data'"

# start a GUI if needed and RDP through SSH
gui_access="rdesktop -u user -p password example.com"

PS3="Please select an option: "
options=("AWS CLI setup on Jumpbox" "Install and configure Ngrok" "Run NMAP and choose a scan type" "Run dirbuster and choose a scan type" "Run s3sec and choose a scan type" "Do a hail mary - full scans all data" "Collect the data and download via ssh" "Setup Gui Access" "Exit this script and use Kali manually")
select opt in "${options[@]}"; do
  case $opt in
    "AWS CLI setup on Jumpbox")
      # aws
      $aws_cli_setup
      ;;
    "Install and configure Ngrok")
      # ngrok
      $ngrok
      ;;
    "Run NMAP and choose a scan type")
      # nmap
      $nmap
      ;;
    "Run dirbuster and choose a scan type")
      # dirbuster
      $dirbuster
      ;;
    "Run s3sec and choose a scan type")
      # s3sec
      $s3sec
      ;;
    "Do a hail mary - full scans all data")
      # hailmary
      $hailmary
      ;;
    "Collect the data and download via ssh")
      # collect data
      $collect_data
      ;;          
    "Setup Gui Access")
      # gui setup
      $gui_access
      ;;          
    "Exit this script and use Kali manually")
      exit 0
      ;;
    *) 
      echo "Invalid option"
      ;;
  esac
done
