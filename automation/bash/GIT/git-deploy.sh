#!/usr/bin/env bash

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
######################################################################################################
#tput civis			# hide cursor
set -o nounset
set -o pipefail		# if you fail on this line, get a newer version of BASH.
shopt -s dotglob
shopt -s nullglob
shopt -s globstar
######################################################################################################
# IMPORTANT !!!
# check if we are the only running instance
#
SCRIPT_NAME="${0##*/}"
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT_SOURCE[0]}" )" && pwd )"
LOCK_FILE=`basename $0`.lock

if [ -f "${LOCK_FILE}" ]; then
	# The file exists so read the PID
	# to see if it is still running
	MYPID=`head -n 1 "${LOCK_FILE}"`
 
	TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`
 
	if [ -z "${TEST_RUNNING}" ]; then
		# The process is not running
		# Echo current PID into lock file
		# echo "Not running"
		echo $$ > "${LOCK_FILE}"
	else
		echo "`basename $0` is already running [${MYPID}]"
    exit 0
	fi
else
	echo $$ > "${LOCK_FILE}"
fi
# make sure the LOCK_FILE is removed when we exit
trap "rm -f ${LOCK_FILE}" INT TERM EXIT

######################################################################################################
# 					Text color variables and keyboard
bold=$(tput bold)             	# Bold
red=${bold}$(tput setaf 1) 		# Red
blue=${bold}$(tput setaf 4) 	# Blue
green=${bold}$(tput setaf 2) 	# Green
txtreset=$(tput sgr0)          	# Reset

color_normal="`echo -e '\r\e[0;1m'`"
color_reverse="`echo -e '\r\e[1;7m'`"

######################################################################################################
#                 Checking availability of GIT                  
which git &> /dev/null
[ $? -ne 0 ]  && \
echo "" && \
echo "${red}GIT is not available ... Install it${txtreset}" &&  \
echo "" && \
echo "${red}Script terminated.${txtreset}" && \
exit 1
#                 Checking availability of pv - Pipe Viewer                  
which pv &> /dev/null
[ $? -ne 0 ]  && \
echo "" && \
echo "${red}pv is not available ... Install it${txtreset}" &&  \
echo "" && \
echo "${red}Script terminated.${txtreset}" && \
exit 1
######################################################################################################
#	GLOBALS

OS_NAME=$(lsb_release -si)
OS_ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
OS_VERSION=$(lsb_release -sr)

# CONFIG FILE
declare -r CONFIG_FILE="$SCRIPT_DIR/config.cfg"

#	the following VARS will be parsed from config.cfg
#	GIT_HOST, GIT_REPO_DIR, WEB_DEPLOY_DIR, APACHE_VHOST_DIR

_now=$(date +"%Y-%m-%d_%T")

VHOST=false
declare ENVIRONMENT=""
declare PROJECT_NAME=""
declare PROJECT_DESC=""

declare -r LOG_DIR="/var/log/git-deploy"
declare -r LOG_FILE="$LOG_DIR/GIT_deploy_$_now"

# GIT related PATHS & VARS
declare -r GIT_CONFIG_FOLDER=".git"
declare -r GIT_SCRIPT_FOLDER="hooks"
declare -r GIT_POST_UPDATE_INIT="post-update.sample"
declare -r GIT_POST_UPDATE="post-update"

declare -r WEB_DEPLOY_VHOST_DIR="www"
declare -r VHOST_INDEX="index.html"
declare -r APPEND_WEB="_web"

GIT_INIT="git init"
GIT_BARE="git --bare init"
GIT_STAGE="git add ."
GIT_COMMIT="git commit -m"
GIT_PUSH="git push"
GIT_INIT_COMMIT_MSG=" -- Innitial commit. Create .gitignore file."
GIT_VHOST_COMMIT_MSG=" -- Add default folder for VHOST. Create index file"

declare -r APACHE_VHOST_FILE="vhost_"
declare -r APACHE_LOG_DIR="APACHE_LOG_DIR"

declare -a DIRS
declare -i REPLY=0

#	messsages
declare -r HTACCESS_MSG="
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 !!!                                      PLEASE NOTE                                      !!!
 !!!      That you will have to edit .htacces file for the new created project             !!!
 !!!      and restrict the access to the VHOST for the internal IP only	(for DEVELOPMENT)  !!!
 !!!      For STAGING, please add password protection to VHOST                             !!!
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

######################################################################################################
#       We require root privileges
ROOT_UID=0             # Root has $UID 0.
E_NOTROOT=101          # Not root user error. 

#	is root running the script?
function check_if_root (){       
                      
  if [ "$UID" -ne "$ROOT_UID" ]
  then
	echo ""
    echo "$color_reverse$(tput bold)${red}Ooops! Must be root to run this script.${txtreset}"
    echo ""
    exit $E_NOTROOT
  fi
} 
######################################################################################################
#       Check git privileges
#	GIT should ALWAYS use a restricted SHELL
#	usually /usr/bin/git-shell according to https://www.kernel.org/pub/software/scm/git/docs/git-shell.html
#	if for any reasons GIT is running under a different shell
#	the script will display a security warning
function check_git_shell (){
		       
	ENVIRONMENT="GIT"
	cfg.section.$ENVIRONMENT
	
	#	get current shell
	CURRENT_GIT_SHELL=`cat /etc/passwd | grep -Ew ^$GIT_USER | cut -d":" -f7`                    
	
	#	check if we are running the correct one
	if [ "$CURRENT_GIT_SHELL" != "$GIT_SHELL" ]; then
		echo ""
		echo "$color_reverse$(tput bold)${red}                                ${txtreset}"
		echo "$color_reverse$(tput bold)${red}!!!     SECURITY WARNING     !!!${txtreset}"
		echo "$color_reverse$(tput bold)${red}                                ${txtreset}"
		echo ""
		echo "$color_reverse$(tput bold)${red}Please change the SHELL under which GIT user is running to: $GIT_SHELL${txtreset}"
		echo "$color_reverse$(tput bold)${blue}Current SHELL: $CURRENT_GIT_SHELL${txtreset}"
		echo ""
		echo "$color_reverse$(tput bold)${red}Continue at your own risk!${txtreset}"
		echo ""
	fi
} 
######################################################################################################
#       Prepare LOG ENV
function make_log_env(){
	echo ""
	echo "Checking for LOG ENVIRONMENT in $(tput bold)${green}$LOG_DIR${txtreset}"
		if [ ! -d "$LOG_DIR" ]; then
			echo "$(tput bold)${red}LOG environment not present...${txtreset}" && \
			echo "${green}Creating log environment..."
			if [ `mkdir -p $LOG_DIR` ]; then
				echo "ERROR: $* (status $?)" 1>&2
				exit 1
			else
				#	success
				echo "$(tput bold)${green}Success.${txtreset} Log environment created in ${green}$LOG_DIR${txtreset}"
				echo ""
				echo "Moving on...."
				echo ""
			fi
		else
			#	success
			echo "$color_reverse$(tput bold)${green}OK.${txtreset} Log environment present in $(tput bold)${green}$LOG_DIR${txtreset}"
			echo ""
			echo "Moving on...."
			echo ""
		fi
}
######################################################################################################
function select_repo_folder () {
        DIRS=( $(find $GIT_REPO_DIR -maxdepth 1 -type d -exec ls -ld "{}" \; | egrep '^d' | awk '{print $9}') )
        
        echo "$(tput bold)${green}Select destination folder. Hit ENTER to access a location.${txtreset}"
        echo ""

	select opt in "${DIRS[@]}" "Back" ; do
	if (( REPLY == 1 + ${#DIRS[@]} )) ; then
		#	return to base :)
		cd $SCRIPT_DIR
		main
	elif (( REPLY > 0 && REPLY <= ${#DIRS[@]} )) ; then
		echo "Selected"
        echo "$color_reverse${DIRS[$REPLY - 1]}"
        create_git_repo
        break
	else
		echo "Invalid option. Try another one."
    fi
done
}
######################################################################################################
#       Create GIT repo
function create_git_repo(){
#	check VHOST status
if ! $VHOST ; then
	###################
	#	no VHOST
	###################
	echo ""
	echo "$color_reverse$(tput bold)${green}Type the PROJECT NAME, followed by [ENTER]:${txtreset}"
	
	read PROJECT_NAME
	echo ""
	echo "$color_reverse$(tput bold)${blue}<<< Starting GIT repository in ${DIRS[$REPLY - 1]}/$PROJECT_NAME >>>${txtreset}"
	cd ${DIRS[$REPLY - 1]}
	mkdir $PROJECT_NAME 2> /dev/null
	if [ "$?" = "0" ]; then
		echo "$color_reverse$(tput bold)${green}OK.${txtreset}"
		echo
	else
		echo
		echo "$color_reverse$(tput bold)${red}Project NAME already exist! ${txtreset}" 1>&2
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo
	exit 1
	fi
	
	cd ${DIRS[$REPLY - 1]}/$PROJECT_NAME
	echo `$GIT_BARE` >> $LOG_FILE
	
	# describe the new project
	echo "$color_reverse$(tput bold)${green}PROJECT description, followed by [ENTER]:${txtreset}"
	read PROJECT_DESC
	touch description
	echo $PROJECT_DESC > description
	echo "$color_reverse$(tput bold)${blue}<<< Project description updated >>>${txtreset}"
	
	if [ "$?" = "0" ]; then
		echo ""
	else
		echo "$color_reverse$(tput bold)${red}Cannot initialise GIT repository in ${DIRS[$REPLY - 1]}!${txtreset}" 1>&2
	exit 1
	fi
		echo "$color_reverse$(tput bold)${green}Please clone the GIT repository from the following URL:${txtreset}   ssh://git@$GIT_HOST${DIRS[$REPLY - 1]}/$PROJECT_NAME"
		echo "$HTACCESS_MSG"
		#	change permissions
		chown -R $GIT_USER ${DIRS[$REPLY - 1]}/$PROJECT_NAME
		echo "$color_reverse$(tput bold)${green}Bye.${txtreset}"
		echo
		
else
		###################
		#	require VHOST
		###################
	echo ""
	echo "$color_reverse$(tput bold)${green}Type the PROJECT NAME, followed by [ENTER]:${txtreset}"
	
	read PROJECT_NAME
	echo ""
	echo "$color_reverse$(tput bold)${blue}<<< Starting GIT repository in ${DIRS[$REPLY - 1]}/$PROJECT_NAME >>>${txtreset}"
	#	Workflow:
	#	create BARE repo in main location
	#	create REPO in VHOST location
	#	config repo in VHOST (add BARE as remote)
	#	make the innitial PUSH from VHOST to BARE
	#	create post-update hook in BARE
	#	modify permissions for hook (+x)
	#	create WWW folder in VHOST location for Apache
	#	create VHOST file
	#	enable VHOST
	#	reload APACHE
	#	return clone URL
	cd ${DIRS[$REPLY - 1]}
	mkdir $PROJECT_NAME 2> /dev/null
	if [ "$?" = "0" ]; then
		echo "$color_reverse$(tput bold)${green}OK.${txtreset}"
		echo
	else
		echo
		echo "$color_reverse$(tput bold)${red}Project NAME already exist! ${txtreset}" 1>&2
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo
	exit 1
	fi
	
	cd ${DIRS[$REPLY - 1]}/$PROJECT_NAME
	echo `$GIT_BARE` >> $LOG_FILE
	
	echo "$color_reverse$(tput bold)${green}PROJECT description, followed by [ENTER]:${txtreset}"
	read PROJECT_DESC
	touch description
	echo $PROJECT_DESC > description
	echo "$color_reverse$(tput bold)${blue}<<< Project description updated >>>${txtreset}"
	
	cd $WEB_DEPLOY_DIR
	mkdir $PROJECT_NAME$APPEND_WEB
	if [ "$?" = "0" ]; then
		echo "$color_reverse$(tput bold)${green}OK.${txtreset}"
		echo
	else
		echo
		echo "$color_reverse$(tput bold)${red}Project NAME already exist! ${txtreset}" 1>&2
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo
	exit 1
	fi
	
	cd $PROJECT_NAME$APPEND_WEB
	echo `$GIT_INIT` >> $LOG_FILE
	echo `$GIT_STAGE`
	echo "`$GIT_COMMIT\"$PROJECT_NAME${GIT_INIT_COMMIT_MSG}\"`" >> $LOG_FILE
	
	echo `$GIT_BARE` >> $LOG_FILE
	#	add DEFAULT .gitignore file (this will be a really basic one)
	touch .gitignore
	#	start to write
cat > .gitignore <<EOF
# NOTE! Please use 'git ls-files -i --exclude-standard'
# command after changing this file, to see if there are
# any tracked files which get ignored after the change.
#
# Ignore the following
# .project is an Aptana specific file.
# This is generated by default once a project is open.
.project

# Do NOT remove the next 2 lines!
.htaccess
.htpasswd

# Project specific paths
www/.htaccess
www/.htpasswd

# tmp files and other stuff
*.patch
*.diff
*.orig
*.rej
interdiff*.txt
# emacs artifacts.
*~
\#*\#
# Hidden files.
.DS*
# Windows links.
*.lnk
# Temporary files.
tmp*

EOF

	#	innitial commit - we will need a master brach
	echo `$GIT_STAGE`
	echo "`$GIT_COMMIT\"$PROJECT_NAME${GIT_INIT_COMMIT_MSG}\"`" >> $LOG_FILE
	cd $GIT_CONFIG_FOLDER

(echo '[remote "hub"]
        url ='${DIRS[$REPLY - 1]}/$PROJECT_NAME'
        fetch = +refs/heads/*:refs/remotes/hub/*' >> $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB/$GIT_CONFIG_FOLDER/config) >> $LOG_FILE
    #	innitial PUSH to remote hub
	echo `git push ${DIRS[$REPLY - 1]}/$PROJECT_NAME master`
	
	#	create post-update hook in BARE
	cd ${DIRS[$REPLY - 1]}/$PROJECT_NAME/$GIT_SCRIPT_FOLDER
	cp $GIT_POST_UPDATE_INIT $GIT_POST_UPDATE
	
	#	create post-update hook in BARE
	cat > $GIT_POST_UPDATE <<EOF
#!/bin/sh

echo
echo "**** Updating VHOST... [post-update hook]"
echo "**** Please report ANY errors."
echo "**** Working..."
echo

cd $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB || exit
unset GIT_DIR
git pull hub master

exec git-update-server-info
EOF
	#	make it executable
	chmod +x $GIT_POST_UPDATE
	
	#	create WWW folder in VHOST location for Apache
	cd $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB
	mkdir $WEB_DEPLOY_VHOST_DIR
	cd $WEB_DEPLOY_VHOST_DIR
	
	#	create a dummy index file
	#	in case that Apache prevents directory browsing, we will get 403 if the index.html file is not here
	cat > $VHOST_INDEX <<EOF
<html>
<center>
	<h2>This is the default page created.</h2><br />
	<h2>Please change me!</h2><br />
</center>
<h3>Please be aware of the following:</h3>
<ul>
	<li>If you need to edit the <b>.gitignore</b> file, <b>DON'T REMOVE current lines.</b>. Add your lines at the end of file;</li>
	<br />
	<li>All files for the project will go <b>INSIDE www</b> folder. This is required for the VHOST on the server side.</li>
</ul>
</html>
EOF
	
	#	prepare the second PUSH
	cd $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB
	echo `$GIT_STAGE`
	#	commit
	echo "`$GIT_COMMIT\"$PROJECT_NAME${GIT_VHOST_COMMIT_MSG}\"`" >> $LOG_FILE
	#	second PUSH to remote hub
	echo `git push ${DIRS[$REPLY - 1]}/$PROJECT_NAME master`
		
	#	create VHOST file
	cd $APACHE_VHOST_DIR
	
	cat > $APACHE_VHOST_FILE$PROJECT_NAME << EOF
<VirtualHost *:80>

        ServerName $PROJECT_NAME.$GIT_HOST
        ServerAlias www.$PROJECT_NAME.$GIT_HOST

        DocumentRoot $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB/$WEB_DEPLOY_VHOST_DIR
        <Directory $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB/$WEB_DEPLOY_VHOST_DIR>
                Options -Indexes FollowSymLinks MultiViews
                AllowOverride All
        </Directory>

        ErrorLog \${$APACHE_LOG_DIR}/$PROJECT_NAME-error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog \${$APACHE_LOG_DIR}/$PROJECT_NAME-access.log forwarded

</VirtualHost>	
EOF

	#	enable VHOST
	a2ensite $APACHE_VHOST_FILE$PROJECT_NAME
	#	reload APACHE
	apache2ctl graceful
	
	#	return clone URL
	echo
	echo "$color_reverse$(tput bold)${green}Please clone the GIT repository from the following URL:${txtreset}   ssh://git@$GIT_HOST${DIRS[$REPLY - 1]}/$PROJECT_NAME"
	echo "$HTACCESS_MSG"
	#	change permissions
	chown -R $GIT_USER $WEB_DEPLOY_DIR/$PROJECT_NAME$APPEND_WEB
	chown -R $GIT_USER ${DIRS[$REPLY - 1]}/$PROJECT_NAME
	
	echo "$color_reverse$(tput bold)${green}Bye.${txtreset}"
	echo
	
fi
}
######################################################################################################
#       Create GIT repo
function create_drupal_deploy(){
	echo "$color_reverse$(tput bold)${red}Ooops! Not yet implemented.${txtreset}"
	echo "$(tput bold)${red}Script terminated.${txtreset}"
	echo ""
	exit
}
######################################################################################################
#       Create GIT repo
function create_ci_deploy(){
	echo "$color_reverse$(tput bold)${red}Ooops! Not yet implemented.${txtreset}"
	echo "$(tput bold)${red}Script terminated.${txtreset}"
	echo ""
	exit
}
######################################################################################################
#       View CONFIG
function view_config(){
	echo
    cfg.section.$ENVIRONMENT
	
	echo "$color_reverse *** Current running CONFIG: $ENVIRONMENT ***$color_normal"
	echo
	echo "GIT_HOST=$GIT_HOST"
	echo "GIT_REPO_DIR=$GIT_REPO_DIR"
	echo "WEB_DEPLOY_DIR=$WEB_DEPLOY_DIR"
	echo "APACHE_VHOST_DIR=$APACHE_VHOST_DIR"
	echo
	echo "*** To change the settings, please edit the $(tput bold)${green}$CONFIG_FILE${txtreset} file ***"
	echo
}
######################################################################################################
#       Check CONFIG
function check_config(){
	#	make sure that config file contains something
	
	if [ -z "$GIT_HOST" ]; then
		echo "$color_reverse$(tput bold)${red}ERROR!${txtreset} GIT_HOST is empty"
		echo "*** Please edit the $(tput bold)${green}$CONFIG_FILE${txtreset} file and assign a value to $(tput bold)${green}GIT_HOST${txtreset} ***"
		echo
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo ""
		exit 1
	else
		echo
		echo "$color_reverse$(tput bold)${green}Found${txtreset} GIT_HOST $GIT_HOST"
	fi
	
	if [ -z "$GIT_REPO_DIR" ]; then
		echo "$color_reverse$(tput bold)${red}ERROR!${txtreset} GIT_REPO_DIR is empty"
		echo "*** Please edit the $(tput bold)${green}$CONFIG_FILE${txtreset} file and assign a value to $(tput bold)${green}GIT_REPO_DIR${txtreset} ***"
		echo
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo ""
		exit 1
	else
		echo
		echo "$color_reverse$(tput bold)${green}Found${txtreset} GIT_REPO_DIR $GIT_REPO_DIR"
		check_folder_exist "$GIT_REPO_DIR"
	fi
	
	if [ -z "$WEB_DEPLOY_DIR" ]; then
		echo "$color_reverse$(tput bold)${red}ERROR!${txtreset} WEB_DEPLOY_DIR is empty"
		echo "*** Please edit the $(tput bold)${green}$CONFIG_FILE${txtreset} file and assign a value to $(tput bold)${green}WEB_DEPLOY_DIR${txtreset} ***"
		echo
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo ""
		exit 1
	else
		echo
		echo "$color_reverse$(tput bold)${green}Found${txtreset} WEB_DEPLOY_DIR $WEB_DEPLOY_DIR"
		check_folder_exist "$WEB_DEPLOY_DIR"
	fi
	
	if [ -z "$APACHE_VHOST_DIR" ]; then
		echo "$color_reverse$(tput bold)${red}ERROR!${txtreset} APACHE_VHOST_DIR is empty"
		echo "*** Please edit the $(tput bold)${green}$CONFIG_FILE${txtreset} file and assign a value to $(tput bold)${green}APACHE_VHOST_DIR${txtreset} ***"
		echo
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo ""
		exit 1
	else
		echo
		echo "$color_reverse$(tput bold)${green}Found${txtreset} APACHE_VHOST_DIR $APACHE_VHOST_DIR"
		check_folder_exist "$APACHE_VHOST_DIR"
	fi
}
######################################################################################################
function check_folder_exist () {
	cd $1 2> /dev/null
	if [ "$?" = "0" ]; then
		echo "Checking if $(tput bold)${green}$1${txtreset} exists...$(tput bold)${green}OK.${txtreset}"
	else
		echo
		echo "$color_reverse$(tput bold)${red}$1 not found! ${txtreset}"
		ask_permission "$1"
		echo
	fi
	#echo "Checking if $(tput bold)${green}$1${txtreset} exists..."
}
######################################################################################################
function ask_permission () {
	
	local yn
	read -p "Do you wish to create the $(tput bold)${green}$1${txtreset} folder? [y/n]" yn
    case $yn in
        [Yy]* ) create_cfg_folder "$1"  ;;
        [Nn]* ) echo "Received NO. $(tput bold)${red}Script terminated.${txtreset}"; echo ; exit  ;;
        * ) main ;;
    esac
}
######################################################################################################
function create_cfg_folder () {
	
	echo "Creating $1 ..."
	mkdir -p $1 2> /dev/null
	if [ "$?" = "0" ]; then
		echo "$color_reverse$(tput bold)${green}OK${txtreset} folder $1 created successfully"
	else
		#	we should never get here :)
		echo
		echo "$color_reverse$(tput bold)${red}Folder $1 already exist! ${txtreset}" 1>&2
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		
	fi
}
######################################################################################################
function showMenu () {
	echo "$color_reverse$(tput bold)${blue}<<< Please select from available options: >>>${txtreset}"
	echo ""
	echo "1) Create NEW git deployment - no VHOST"
	echo "2) Create NEW git deployment - with VHOST"	
	echo "3) $(tput bold)${red}Create NEW DRUPAL deployment${txtreset}"
	echo "4) $(tput bold)${red}Create NEW CODEIGNITER deployment${txtreset}"
	echo "5) $(tput bold)${blue}View settings${txtreset}"
	echo "q) Quit"
}
######################################################################################################
function select_env () {
	echo "$color_reverse$(tput bold)${blue}<<< Please select ENVIRONMENT: >>>${txtreset}"
	echo ""
	echo "1) Development"
	echo "2) Staging"
	echo "q) Quit"
}
######################################################################################################
#	Config parser
function config_parser(){
    ini="$(<$1)"                # read the file
    ini="${ini//[/\[}"          # escape [
    ini="${ini//]/\]}"          # escape ]
    IFS=$'\n' && ini=( ${ini} ) # convert to line-array
    ini=( ${ini[*]//;*/} )      # remove comments with ;
    ini=( ${ini[*]/\    =/=} )  # remove tabs before =
    ini=( ${ini[*]/=\   /=} )   # remove tabs be =
    ini=( ${ini[*]/\ =\ /=} )   # remove anything with a space around =
    ini=( ${ini[*]/#\\[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%\\]/ \(} )    # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )    # convert item to array
    ini=( ${ini[*]/%/ \)} )     # close array parenthesis
    ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
    ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} ) # remove extra parenthesis
    ini[0]="" # remove first element
    ini[${#ini[*]} + 1]='}'    # add the last brace
    eval "$(echo "${ini[*]}")" # eval the result
}
######################################################################################################
#       Clean-up. Unset variables
function unset_vars(){
		unset IFS	#	important!
		unset DIRS
		unset REPLY
		unset GIT_HOST
		unset GIT_REPO_DIR
		unset WEB_DEPLOY_DIR
		unset APACHE_VHOST_DIR
		unset ENVIRONMENT
		unset GIT_INIT
		unset GIT_BARE
		unset GIT_STAGE
		unset GIT_COMMIT
		unset GIT_PUSH
		unset GIT_INIT_COMMIT_MSG
		unset GIT_VHOST_COMMIT_MSG
}
######################################################################################################
main() {
	#	clear screen
	clear
	echo
	echo "$color_reverse$(tput bold)${blue}<<< GIT DEPLOY >>>  Running on $OS_NAME $OS_VERSION - $OS_ARCH-bit${txtreset}"
		
	check_if_root
	config_parser 'config.cfg'
	check_git_shell
	
	#	read CONFIG FILE
	echo
	select_env
	echo
	read -p "Please select environment: " ENV_CHOICE
			case "$ENV_CHOICE" in
                "1")
						echo
                        echo "$(tput bold)${green}DEVELOPMENT${txtreset} environment."
                        ENVIRONMENT="DEVELOPMENT"
                        cfg.section.$ENVIRONMENT
                        echo ;;                   
                "2")
						echo ""
                        echo "$(tput bold)${green}STAGING${txtreset} environment."
                        ENVIRONMENT="STAGING"
                        cfg.section.$ENVIRONMENT
                        echo ;;             
                "q")
						echo
                        echo "$(tput bold)${red}Script terminated.${txtreset}"
                        echo
                        exit
                        ;;
			esac
			
	#	check if config.cfg file exists
		
	if [ -f "$CONFIG_FILE" ]; then
		echo "$color_reverse Reading $ENVIRONMENT config....${txtreset} $(tput bold)${green}OK.${txtreset}"
		check_config
	else
		echo "$color_reverse$(tput bold)${red}Cannot read CONFIGURATION FILE! ${txtreset}"
		echo "*** Please make sure that the file $(tput bold)${green}$SCRIPT_DIR/config.cfg${txtreset} exists.. ***"
		echo "$(tput bold)${red}Script terminated.${txtreset}"
		echo ""
	exit 1
	fi
	
	#	prepare LOG ENVIRONMENT
	make_log_env
	
	#	enter loop
	while [ 1 ]
		do
			showMenu
			echo
			read -p "Please select an option: " CHOICE
			case "$CHOICE" in
                "1")
						echo ""
                        echo "$(tput bold)${green}Create NEW git deployment - no VHOST${txtreset}"
                        unset IFS	#	important!
                        VHOST=false
                        select_repo_folder ;;
                "2")
						echo ""
                        echo "$(tput bold)${green}Create NEW git deployment - with VHOST${txtreset}"
                        unset IFS	#	important!
                        VHOST=true 
                        select_repo_folder ;;
                "3")
						echo
						unset IFS	#	important!
                        VHOST=true
                        create_drupal_deploy ;;
                "4")
						echo
						unset IFS	#	important!
                        VHOST=true
                        create_ci_deploy ;;
                "5")
						view_config ;;             
                "q")
						echo ""
                        echo "$(tput bold)${red}Script terminated.${txtreset}"
                        echo ""
                        exit
                        ;;
			esac
	done

	#	remove lock
	rm -f ${LOCK_FILE}
	#	unhide cursor
	tput cnorm
	#	Clean up
	unset_vars
	exit 0
}
main "$@"
