#!/bin/sh
#############################################################################
#
# Purpose: This script will install QWC2
#
#############################################################################
# Copyright (c) 2009-2019 The Open Source Geospatial Foundation and others.
# Licensed under the GNU LGPL version >= 2.1.
# 
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LICENSE.LGPL.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".
#############################################################################

#
# Requires:
#
# Uninstall:
# ============
# 
sudo rm -rf /usr/local/share/qwc2-demo-app
sudo rm -rf /usr/local/share/qwc2

./diskspace_probe.sh "`basename $0`" begin
BUILD_DIR=`pwd`
####


# live disc's username is "user"
if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"


INSTALL_FOLDER="/usr/local/share"
QWC2_HOME="$INSTALL_FOLDER/qwc2-demo-app"
QWC2_PORT="8081"

TMP_DIR="/tmp/build_qwc2"
INSTALLURL="https://github.com/qgis/qwc2-demo-app.git"

mkdir -p "$TMP_DIR"

# Install mapbender dependencies.
echo "Installing qwc2 dependencies"


# download and unzip sources...

cd $QWC2_HOME

git clone --recursive $INSTALLURL $QWC2_HOME
chown -R user:www-data $QWC2_HOME

# Installation node.js 
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# Installation yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
#
sudo apt-get update
sudo apt-get install yarn

cd  $QWC2_HOME

yarn install

###------------------------------------------
### Configure Application ###
## Add a script that will launch the browser after starting QWC2
cat << EOF > "$QWC2_HOME/qwc2_start_admin.sh"
#!/bin/sh

cd $QWC2_HOME

#Start yarn
yarn start

DELAY=10

(
for TIME in \`seq \$DELAY\` ; do
  sleep 1
  echo "\$TIME \$DELAY" | awk '{print int(0.5+100*\$1/\$2)}'
done
) | zenity --progress --auto-close --text "QWC2 starting"

# how to set 5 sec timeout?
zenity --info --text "Starting web browser ..."
firefox "http://localhost:$QWC2_PORT/"
EOF


## Add a script that will stop QWC2 and notify the user graphically
cat << EOF > "$QWC2_HOME/qwc2_stop_admin.sh"
cd $QWC2_HOME/shutdown.sh
sudo killall node
zenity --info --text "QWC2 stopped"
EOF


###------------------------------------------
### install desktop icons ##
echo "Installing QWC2 icons"
cp -f "$USER_HOME/gisvm/app-conf/geoserver/geoserver_48x48.logo.png" \
       /usr/share/icons/

## start icon
cat << EOF > /usr/share/applications/qwc2-start.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Start QWC2
Comment=QWC2 
Categories=Application;Geography;Geoscience;Education;
Exec=$QWC2_HOME/qwc2_start_admin.sh
Icon=/usr/share/icons/gnome/48x48/apps/xscreensaver.png
Terminal=false
EOF

cp -a /usr/share/applications/qwc2-start.desktop "$USER_HOME/Desktop/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/qwc2-start.desktop"

## stop icon
cat << EOF > /usr/share/applications/qwc2-stop.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Stop QWC2
Comment=QWC2
Categories=Application;Geography;Geoscience;Education;
Exec=$QWC2_HOME/qwc2_stop_admin.sh
Icon=/usr/share/icons/gnome/48x48/apps/xscreensaver.png
Terminal=false
EOF

cp -a /usr/share/applications/qwc2-stop.desktop "$USER_HOME/Desktop/"
chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/Desktop/qwc2-stop.desktop"


chown -R user:www-data $QWC2_HOME

## Make the scripts executable
chmod u+x $QWC2_HOME/qwc2_start_admin.sh
chmod u+x $QWC2_HOME/qwc2_stop_admin.sh


####
"$BUILD_DIR"/diskspace_probe.sh "`basename $0`" end

