The script will create GIT repositories based on user input.
The options are presented via a TUI menu.

There are 4 VARIABLES that the user needs to change according to his specific environment:
- GIT_HOST - this will be updated into the VHOST file
- GIT_REPO_DIR - this is the location where the GIT repositories will be created;
- WEB_DEPLOY_DIR - needed for VHOST configuration;
- APACHE_VHOST_DIR - usually /etc/apache2/sites-available

NOTE: the script will work on DEBIAN based distros. I have tested the functionality in the latest DEBIAN stable and Ubuntu Server 12.04 LTS.