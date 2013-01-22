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


##################################################################################
# 					The main menu and main loop
##################################################################################
# a lot of work to be done here :)
##################################################################################

##################################################################################
# We need to define our functions first. The main manu will need access to them
# in order to work
##################################################################################


# Start a new project.
# The script will create teh required folders for DEV, STAGGING and LIVE under /opt/repos/projects
# Initiate git repository in DEV with the core code.
# Create coresponding folders for DEV, STAGGING and LIVE under /var/www/vhost/devel_sites
# Create git repos in /var/www for each DEV, STAGGING and LIVE (maybe?)
# setup hooks for updates

# function to clone the drupal core
clone_drupal() {

DRUPAL_CORE="/home/andy/cores/drupal/"
REPO_PATH="/home/andy/repos/projects/"
prefix="genesis_"

# will get the projectname from an input box, once the DRUPAL CORE is selected
sufix=$projectname
appendweb="_web"
DEV_ENVIROMENT=$prefix$sufix
DEV_ENVIROMENT_WEB=$DEV_ENVIROMENT$appendweb
WEB_PATH="/var/www/vhost/devel_sites/"
cd $WEB_PATH
mkdir "$DEV_ENVIROMENT_WEB"
cd $DEV_ENVIROMENT_WEB

git init
git add .

git commit

##################################################################################
#
# Bring the files in .... !!!
#
##################################################################################

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
        cp sample.htaccess .htaccess

#       PUSH
        cd $WEB_PATH$DEV_ENVIROMENT_WEB
        git add .
        git commit -m "Core and assets"
        git push hub master

}



TITLE='CREATE NEW PROJECT -  MENU'
BACKTITLE='part of the automation process...'
RESULT='not quit'
until [ "$RESULT" = 'quit' ]
do
  RESULT=$(whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --nocancel --menu "Please select the CORE..." 20 50 11 \
    Drupal       'Select a DRUPAL Core' \
    Code_Igniter 'Select a CODE IGNITER Core' \
    Readme       'What to expect from this script' \
    quit         'EXIT' \
    2>&1 >/dev/tty )

# respond to the user selection from the main menu
TITLE="\"$RESULT\" selected..."
  case $RESULT in
    'Drupal')
      whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "Create the new project using a DRUPAL Core?"  12 40
        exitstatus=$?
        if [ $exitstatus = 0 ]; then

        #we need an input box where the user can enter the project name
        #the name will be passed to clone_drupal()
        #otherwise we will end up with an empty name __

        projectname=$(whiptail --inputbox "What is the project name?" 8 78 --title "STEP 1" 3>&1 1>&2 2>&3)
        exitstatus=$?
                if [ $exitstatus = 0 ]; then
                projectname=$projectname
                clone_drupal
                else
                echo "No project name provided."
                fi
        else
        whiptail --title "Abort" --msgbox "
                The project will NOT be created.\n
                Return to main menu\n" 12 78
        fi
        ;;

    'Code_Igniter')
      whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --msgbox "\n\n\nNot implemented ... yet\n"  12 40
        ;;
    'Readme')
     whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --msgbox "\n
        !!!                               WARNING!                              !!!\n
        !!! The script is still under heavy development.                        !!!\n
        !!! WHAT TO EXPECT:                                                     !!!\n
        !!!   - the script WILL create a new project                            !!!\n
        !!!   - the script WILL use the core specified by the user              !!!\n
        !!!   - the script WILL clone the core and prepare the WEB environment  !!!\n
        !!!                                                                     !!!\n
        !!!      PLEASE READ THE INSTRUCTION DISPLAYED AFTER THE SCRIPT IS RUN. !!!\n
        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n
        \n" 30 90
        ;;

    'quit')
      printf "Script terminated...\n";
      exit 0;
      ;;
    *)
  esac
done




 txtrst=$(tput sgr0) # Text reset
 txtred=$(tput setaf 1) # Red
 txtcyn=$(tput setaf 6) # Cyan
 
# clear the screen
 tput clear

################################# VERSION - TODO: display this infos inside a msgbox
cd $DRUPAL_CORE
while read line
      do
           echo -e "$line \n"
      done < release

}


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
