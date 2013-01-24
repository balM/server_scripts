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

##############################################################################
#                 Checking availability of dialog and pv                     #
##############################################################################

which dialog &> /dev/null

[ $? -ne 0 ]  && echo "Dialog utility is not available, Install it" && exit 1

which pv &> /dev/null

[ $? -ne 0 ]  && echo "pv (pv utility is not available, Install it." && exit 1

#define global PATH - make sure that the ones that won't change are read-only
# IMPORTANT !!!
#change this on the DEV SERVER with the correct one
declare -r BACKTITLE="TAG: Deploy new project. Part of the automation process."
declare LOG_FILE="/var/log/deployment.log"
declare TMP_FILE="$(mktemp /tmp/deployi.XXXXX)"  # always use `mktemp`
declare TMP_PROJECT_NAME="$(mktemp /tmp/project_name.XXXXX)"
declare -r README="/home/andy/cores/readme"
declare DRUPAL_CORE="/home/andy/cores/drupal/"
declare -r DRUPAL_ASSETS_DIR="assets"
declare -r DRUPAL_WWW_DIR="www"
declare CI_CORE="/home/andy/cores/igniter/"
declare REPO_PATH="/home/andy/repos/projects/"
declare WEB_PATH="/var/www/vhost/devel_sites/"
declare -r prefix_drupal="genesis_"
declare -r prefix_ci="firestarter_"
declare -r appendweb="_web"

# pipe a command to a tailbox dialog
# here we can specify the parameters the function expects
# perhaps there are smarter ways that may integrate better
# $1 - tailbox dialog height
# $2 - title
# $3 - command
##############################################################################
#                      Define Functions Here                                 #
##############################################################################

##############################################################################
show_readme() {
dialog --backtitle "$BACKTITLE" --textbox $README 15 80
}
##############################################################################
clone_drupal() {

#		we need a project name first; otherwise we will end up with something like __
#		display a inputbox where the user will specify the project name

dialog --title "Drupal Project" \
--backtitle "$BACKTITLE" \
--inputbox "Enter project name:" 8 50 2> $TMP_PROJECT_NAME

return_drupal_name=$?
drupal_name=`cat $TMP_PROJECT_NAME`
case $return_drupal_name in
        0)
        projectname="$drupal_name";
        rm -f $TMP_PROJECT_NAME ;;
        1)
        echo "Cancel pressed.";
        rm -f $TMP_PROJECT_NAME ;;
esac

sufix=$projectname
DEV_ENVIROMENT=$prefix_drupal$sufix
DEV_ENVIROMENT_WEB=$DEV_ENVIROMENT$appendweb

echo "########################################################################
########################################################################" >> $LOG_FILE
echo Initialize log >> $LOG_FILE
date >> $LOG_FILE
echo "" >> $LOG_FILE
echo "Moving to WEB location...." >> $LOG_FILE
echo "" >> $LOG_FILE

cd $WEB_PATH
mkdir "$DEV_ENVIROMENT_WEB"
cd $DEV_ENVIROMENT_WEB

	git init >> $LOG_FILE
	git add . >> $LOG_FILE
	git commit >> $LOG_FILE

echo "" >> $LOG_FILE
echo "Moving to REPO location...." >> $LOG_FILE
echo "" >> $LOG_FILE

cd $REPO_PATH
mkdir $prefix_drupal$projectname

cd $prefix_drupal$projectname
	git --bare init >> $LOG_FILE

#		go back to web location... go inside project folder and finnish with git
echo "" >> $LOG_FILE
echo "Moving to WEB location...." >> $LOG_FILE
echo "" >> $LOG_FILE

cd $WEB_PATH
cd $DEV_ENVIROMENT_WEB

	git --bare init >> $LOG_FILE
	git add . >> $LOG_FILE
	git commit -m "Initial commit" >> $LOG_FILE
	git push $REPO_PATH$DEV_ENVIROMENT master >> $LOG_FILE

#       Setup hooks for syncronisation
#       We need to make sure that the .hub. repository is configured as a remote for the live repository.

(echo '[remote "hub"]
        url ='$REPO_PATH$DEV_ENV'
        fetch = +refs/heads/*:refs/remotes/hub/*' >> .git/config) >> $LOG_FILE

#       Next we need to set up a couple of hooks.
#       The first one will make sure that any time anything is pushed to the hub repository it will be pulled into the live repo.
#       This hook can also contain anything that needs to happen to deploy the new version

cd $REPO_PATH
cd $DEV_ENV
touch hooks/post-update
#       start to write
cat > hooks/post-update <<EOF
#!/bin/sh

echo
echo "**** Pulling changes into Live [Hub's post-update hook]"
echo

cd $WEB_PATH$DEV_ENV_WEB || exit
unset GIT_DIR
git pull hub master

exec git-update-server-info

EOF
#       make it executable
chmod +x hooks/post-update

#       start the core relocation
cd $DRUPAL_CORE
cp .gitignore $WEB_PATH$DEV_ENV_WEB >> $LOG_FILE #      small file , no need for a gauge

#       find out the size of each folder that we need to relocate. Start with "assets"
#       display gauge during the copy
#       it may be so fast that it does nor actually manage to display the gauge :)
(cp -R $DRUPAL_ASSETS_DIR $WEB_PATH$DEV_ENV_WEB | pv -n -s -f 'du -sb . | awk'{print $1}'') 2>&1 | dialog --gauge 'Importing assets...' 7 70
(cp -R $DRUPAL_WWW_DIR $WEB_PATH$DEV_ENV_WEB | pv -n -s -f 'du -sb . | awk'{print $1}'') 2>&1 | dialog --gauge 'Importing core...' 7 70


#       now we have the www folder for the Drupal core in place.
#       define the roor folder for web
        WEB_ROOT_DRUPAL="www"
        #go to the right location
        cd $WEB_ROOT_DRUPAL
        #the default .htaccess file
        cp sample.htaccess .htaccess

#       PUSH
        cd $WEB_PATH$DEV_ENV_WEB
        git add . >> $LOG_FILE
        git commit -m "Core and assets" >> $LOG_FILE
        git push hub master >> $LOG_FILE

##      all done!
echo "#########################################################################
###  New project created.
###  Please check the WIKI page for the URL
#########################################################################" >> $LOG_FILE

dialog --title "Progress log..." \
       --tailbox $LOG_FILE 50 100

#setup hooks for syncronisation
#We need to make sure that the .hub. repository is configured as a remote for the live repository.
# we are in the correct location?
#

}
##############################################################################


##############################################################################
#Call me crazy, but without my main() function I ain't going anywhere.
#Now we can start writing some bash.
#Once you have your main() it means you're going to write code ONLY inside functions.
#I don't care it's a scripting language. Let's be strict.

main() {
while :
do
        dialog --clear --backtitle "$BACKTITLE" --title "Main Menu" \
--menu "Use [UP/DOWN] key to move.Please choose an option:" 15 55 10 \
1 "Create a DRUPAL based project" \
2 "Create a CODE IGNITER based project" \
3 "README" \
4 "Exit" 2> $TMP_FILE

    returned_opt=$?
    choice=`cat $TMP_FILE`

    case $returned_opt in
           0) case $choice in
                  1)  clone_drupal ;;
                  2)  clone_igniter ;;
                  3)  show_readme  ;;
                  4)  clear; rm -f $TMP_FILE; exit 0;;
              esac ;;
          *)clear ; rm -f $TMP_FILE; exit ;;
    esac
done
}
main "$@"

