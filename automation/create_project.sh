#!/bin/bash

#    Copyright (C) 2013 Alexandru Iacob
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Start a new project.
# The script will create teh required folders for DEV, STAGGING and LIVE under /opt/repos/projects
# Initiate git repository in DEV with the core code.
# Create coresponding folders for DEV, STAGGING and LIVE under /var/www/vhost/devel_sites
# Create git repos in /var/www for each DEV, STAGGING and LIVE (maybe?)
# setup hooks for updates

 txtrst=$(tput sgr0) # Text reset
 txtred=$(tput setaf 1) # Red
 echo
 echo "${txtred}"
 echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
 echo "!!!                                      WARNING!                                                    !!!"
 echo "!!!         The script is still under heavy development.                                      !!!"
 echo "!!!        WHAT TO EXPECT:                                                                            !!!"
 echo "!!!        - the script WILL create a new project                                                     !!!"
 echo "!!!        - the script WILL use the core specified by the user                                       !!!"
 echo "!!!        - the script WILL clone the core and prepare the WEB environment                           !!!"
 echo "!!!                                                                                                   !!!"
 echo "!!!      PLEASE READ THE INSTRUCTION DISPLAYED AFTER THE SCRIPT IS RUN.                               !!!"
 echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
 echo ""
 echo "${txtrst}"

echo ""
echo "Continue?"
echo ""

#wait for user decision
proceed() {
echo "*******************************************************************************"
echo "1)yes"
echo "2)no"
echo "*******************************************************************************"
}
while [ 1 ]
do
        proceed
        read decision
        case "$decision" in
        "1")
                echo "OK"
                echo
                break
                ;;
        "2")
                echo "Script terminated."
                echo
                exit
                ;;
        esac
done

CORE_SELECTED=""
DRUPAL_CORE="/home/andy/cores/drupal/"
CODEIGNITER_CORE="/home/andy/cores/codeigniter/"

echo
echo "<<<<<     Please input a NAME for new project....     >>>>>"
echo
# read user input
read projectname

# project core
echo
echo "${txtred}Please select project core.${txtrst}"
echo "Project CORE: Drupal/Codeigniter"
core_select() {
echo "*******************************************************************************"
echo "1)Drupal"
echo "2)Code-Igniter"
echo "3)EXIT"
echo "*******************************************************************************"

#display infos about the CORE; version, last commiter, etc.
#we keep all this informations in the "release" file inside teh core folder

 txtrst=$(tput sgr0) # Text reset
 txtcyn=$(tput setaf 6) # Cyan

 echo
 echo "${txtcyn}============================================================================================"
 echo "Additional information about the DRUPAL CORE used:                                         "
 echo "============================================================================================${txtrst}"
 echo

cd $DRUPAL_CORE
while read line
      do
           echo -e "$line \n"
      done < release

}

while [ 1 ]
do
        core_select
        read CORE
        case "$CORE" in
        "1")
                echo "DRUPAL core selected."
                echo
                CORE_SELECTED="drupal"
                break
                ;;
        "2")
                echo "CODE-IGNITER core selected."
                echo
                CORE_SELECTED="codeigniter"
                break
                ;;
        "3")
                echo
                echo "EXIT"
                echo
                exit
                ;;

        esac
done

#tput setaf 7

#define working dirs ---- change this path once the script is tested!
#live
#/etc/init.d/apache2 reload
REPO_PATH="/home/andy/repos/projects/"
prefix="genesis_"
sufix=$projectname
appendweb="_web"

DEV_ENVIROMENT=$prefix$sufix
DEV_ENVIROMENT_WEB=$DEV_ENVIROMENT$appendweb
WEB_PATH="/var/www/vhost/devel_sites/"

###########################################################
#
#       Select project core : drupal/codeigniter
#
############################################################
#
#
#selected_from_codebase=()

#Just some basic text decoration.
txtrst=$(tput sgr0) # Text reset
        txtcyn=$(tput setaf 6) # Cyan
        echo "Fixing path and bringing the ${txtcyn}CORE${txtrst} into the new project..."
txtrst=$(tput sgr0) # Text reset


echo "Creating new project: $projectname"
echo "Changing to repo location....."
echo "Creating DEV folder for project..."
#
#mkdir "$DEV_ENVIROMENT"
#
#build-up the DEV enviroment for WEBSITE
cd $WEB_PATH
echo "Creating DEV folder for web..."
mkdir "$DEV_ENVIROMENT_WEB"
cd $DEV_ENVIROMENT_WEB
#
git init
git add .

git commit

#####
#
# Bring the files in .... !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#####
# build-up the repo in DEV

#cd $REPO_PATH
cd $REPO_PATH
mkdir $prefix$projectname

cd $prefix$projectname
git --bare init

# go back to web location... go inside project folder and finnish with git
cd $WEB_PATH
cd $DEV_ENVIROMENT_WEB
#
git --bare init
git add .
git commit -m "Initial Commit."
git push $REPO_PATH$DEV_ENVIROMENT master
#
#setup hooks for syncronisation
#We need to make sure that the .hub. repository is configured as a remote for the live repository.
# we are in the correct location?
#
echo
echo "Starting to configure hooks...."
echo
#
# append to .git/config
#
echo '[remote "hub"]
        url ='$REPO_PATH$prefix$sufix'
        fetch = +refs/heads/*:refs/remotes/hub/*' >> .git/config


#Next we need to set up a couple of hooks. The first of these will make sure that any time anything is pushed to the hub repository it will be pulled into the live repo. This hook can also contain anything that needs to happen to deploy the new version
#
# change to repo directory
#
cd $REPO_PATH
cd $DEV_ENVIROMENT
#
touch hooks/post-update
#
# start to write
cat > hooks/post-update <<EOF
#!/bin/sh

echo
echo "**** Pulling changes into Live [Hub's post-update hook]"
echo

cd $WEB_PATH$DEV_ENVIROMENT_WEB || exit
unset GIT_DIR
git pull hub master

exec git-update-server-info

EOF
#
chmod +x hooks/post-update

#######################################################################################################################
#######################################################################################################################
#                               Move this so we wont have any problems once we start git
#######################################################################################################################
#######################################################################################################################
#######################################################################################################################
#
#       perform some maintenace.
#       If is a DRUPAL project we need to rename teh .htaccess file from www
#       Also, set read/write permissions fo www/sites/default
############################################################################################

#####################################################################
#
# Bring the core
#
#####################################################################


if [ "$CORE_SELECTED"="drupal" ]
then
        #start the core relocation
        cd $DRUPAL_CORE
        cp .gitignore $WEB_PATH$DEV_ENVIROMENT_WEB
        cp -R -v assets $WEB_PATH$DEV_ENVIROMENT_WEB
        cp -R -v www $WEB_PATH$DEV_ENVIROMENT_WEB

        #now we have the www folder for the Drupal core in place.
        # define the roor folder for web
        WEB_ROOT_DRUPAL="www"
        #go to the right location
        cd $WEB_ROOT_DRUPAL
        #the default .htaccess file
        txtgreen=$(tput setaf 2) # Green
                echo
                echo "${txtgreen}Updating .htaccess file.Changing RewriteRule to default...${txtrst}"
                echo
        cp sample.htaccess .htaccess

#       PUSH
        cd $WEB_PATH$DEV_ENVIROMENT_WEB
         txtgreen=$(tput setaf 2) # Green
                echo
                echo "${txtgreen}Updating the ORIGIN ... This may take some time :)${txtrst}"
                echo
        git add .
        git commit -m "Core and assets"
        git push hub master

# CHECK if the folder are already in the core !!!
#ok, go to sites/ and set permissions
#       cd sites/default
#       mkdir files
#       mkdir private
#       chmod 777 -R files/
#       chmod 777 -R private

else
        break
fi



##############################################################################################
#
#       permissions ???
#
##############################################################################################
 txtgreen=$(tput setaf 2) # Green
                echo
                echo "${txtgreen}Initial deploy complete. Setting the permissions...This will be quick...${txtrst}"
                echo

chown -R git $WEB_PATH$DEV_ENVIROMENT_WEB
chown -R git $REPO_PATH$DEV_ENVIROMENT
##############################################################################################
# prepare Apache vhost setup
# use local folder for testing purpose
#
#echo "Setting up Apache vhost for the new project....."
#
# start with a blank vhost file ...the file will be named as
# projectname_vhost
#
#echo "Using default vhost configuration file...."
#
# do stuff here
#echo "#############################################################################"
#echo "Writing changes................................................................"
#echo "#############################################################################"
#
 txtrst=$(tput sgr0) # Text reset
 txtcyn=$(tput setaf 6) # Cyan
 echo
 echo "${txtcyn}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<      DONE !      >>>>>>>>>>>>>>>>>>>>>>>>>>>${txtrst}"
 echo "${txtcyn}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Project created. BYE!>>>>>>>>>>>>>>>>>>>>>>>${txtrst}"
 echo
 txtred=$(tput setaf 1) # Red
 echo "${txtred}"
 echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
 echo "!!!                                      PLEASE NOTE                                                   !!!"
 echo "!!!      That you will have to edit .htacces file for the new created project                          !!!"
 echo "!!!      and the copy sites/default/default.setting.php to settings.php                                !!!"
 echo "!!!      and setup teh database details. Also check for the files/ and private/ folder                 !!!"
 echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
 echo "${txtrst}"

#exit script
