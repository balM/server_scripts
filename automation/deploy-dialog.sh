#!/bin/bash

##############################################################################
#                 Checking availability of dialog utility                    #
##############################################################################

# dialog is a utility installed by default on all major Linux distributions.
# But it is good to check availability of dialog utility on your Linux box.

which dialog &> /dev/null

[ $? -ne 0 ]  && echo "Dialog utility is not available, Install it" && exit 1

##############################################################################
#define global PATH
#change this ion the DEV SERVER with the correct one

BACKTITLE="TAG: Deploy new project. Part of the automation process."
DRUPAL_CORE="/home/andy/cores/drupal/"
IGNITER_CORE="/home/andy/cores/code_igniter/"
REPO_PATH="/home/andy/repos/projects/"
prefix_drupal="genesis_"
prefix_igniter="firestarter_"
sufix=$projectname


##############################################################################
#                      Define Functions Here                                 #
##############################################################################
show_readme() {
README="/home/andy/cores/readme"
dialog --backtitle "$BACKTITLE" --textbox $README 15 80
}
##############################################################################
clone_drupal() {
#we need a project name first; otherwise we will end up with something like __
#display a inputbox where the user will specify the project name
dialog --title "Drupal Project" \
--backtitle "$BACKTITLE" \
--inputbox "Enter project name:i" 8 50 2> tempdrupalname.$$

return_drupal_name=$?
drupal_name=`cat tempdrupalname.$$`
case $return_drupal_name in
        0)
        projectname="$drupal_name";;
        1)
        echo "Cancel pressed.";;
esac
rm -f tempdrupalname.$$

}
##############################################################################

while :
do
        dialog --clear --backtitle "$BACKTITLE" --title "Main Menu" \
--menu "Use [UP/DOWN] key to move.Please choose an option:" 15 55 10 \
1 "Create a DRUPAL based project" \
2 "Create a CODE IGNITER based project" \
3 "README" \
4 "Exit" 2> menuchoices.$$

    returned_opt=$?
    choice=`cat menuchoices.$$`

    case $returned_opt in
           0) case $choice in
                  1)  clone_drupal ;;
                  2)  clone_igniter ;;
                  3)  show_readme  ;;
                  4)  clear; rm -f menuchoices.$$; exit 0;;
              esac ;;
          *)clear ; rm -f menuchoices.$$; exit ;;
    esac
done
