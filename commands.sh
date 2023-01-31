#!/bin/bash
clear
# My cool banner splash. I love doing these.
echo ""
echo "🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉"
echo "🏴‍☠️                                          🏴‍☠️"
echo "🏴‍☠️    ___      WISE-BITS JUMPBOX     ___    🏴‍☠️"
echo "🏴‍☠️   (o o)                          (o o)   🏴‍☠️"
echo "🏴‍☠️  (  V  )      Deploy Script     (  V  )  🏴‍☠️"
echo "🏴‍☠️  --m-m----------------------------m-m--  🏴‍☠️"
echo "🏴‍☠️                                          🏴‍☠️"
echo "🏴‍☠️              By: B̤̿it̺̕B͓̚urneȑ🔥             🏴‍☠️"
echo "🏴‍☠️                                          🏴‍☠️"
echo "🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉🏴‍☠️🦉"
echo ""
# update and install metapackages
echo "⚡ Updating and installing meta packages headless and webtools"
#DEBIAN_FRONTEND=readline sudo apt update && sudo apt install -y kali-tools-web
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo apt-get update && sudo apt-get install -y -q kali-tools-web
echo "✅ Done updating and installing metapackages"

# install pip
echo "⚡ Installing PIP"
sudo apt install -y pip
echo "✅ Done installing PIP"

# install awscli for later if tools need it.
echo "⚡ Installing AWS CLI"
pip install awscli
echo "✅ Done installing AWS CLI"

echo "⚡ Installing prower via pip"
# Installing prower via pip
pip install prowler-cloud
echo "✅ Done installing Prower via pip"

echo ""
# making a tools directory
echo "⚡ Making a tools and data directory"
sudo mkdir /home/kali/tools/
sudo mkdir /home/kali/tools/data
cd /home/kali/tools
echo "✅ Done making tools and data directory"

echo ""
# installing s3sec from github
echo "⚡ Installing tool s3sec to test AWS S3 buckets for read/write/delete access"
git clone https://github.com/0xmoot/s3sec
echo "✅ Done installing s3sec"
echo ""

# Start to ask the user what to do now
#read -p "❔ What is the URL of the target box you are testing?: " target
#echo ""
#echo "🎯 Storing variable 'target' = $target for later use..."
#echo ""
target="$1"

if [ -z "$target" ]; then
  echo "What is the URL of the target box you are testing?"
  read target
fi

echo "Storing variable target = $target for later use..."
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

#!/bin/bash

option="$1"

case $option in
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
