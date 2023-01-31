#!/bin/bash
clear
# My cool banner splash. I love doing these.
echo ""
echo "============================================="
echo "|                                           |"
echo "|    ___      WISE-BITS JUMPBOX     ___     |"
echo "|   (o o)                          (o o)    |"
echo "|  (  V  )      Deploy Script     (  V  )   |"
echo "|  --m-m----------------------------m-m--   |"
echo "|                                           |"
echo "|              By: B̤̿it̺̕B͓̚urneȑ🔥               |"
echo "|                                           |"
echo "============================================="
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
sudo git clone https://github.com/0xmoot/s3sec
echo "✅ Done installing s3sec"
echo ""
bash interact.sh
