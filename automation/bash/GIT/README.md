The script will create GIT repositories based on user input.
The options are presented via a TUI menu.

There are 6 major VARIABLES that the user needs to change according to his specific environment:
- GIT_USER
- GIT_SHELL
- GIT_HOST - this will be updated into the VHOST file
- GIT_REPO_DIR - this is the location where the GIT repositories will be created;
- WEB_DEPLOY_DIR - needed for VHOST configuration;
- APACHE_VHOST_DIR - usually /etc/apache2/sites-available

All the settings can be changed in the "config.cfg" file

The script will also check if the values from "config.cfg" are correct.
If the values do not exist, we will give the user option to create the structure on-the-fly.

Initially we check if GIT is running under the correct SHELL. If not, we display a security warning.

The user can choose for what ENVIRONMENT the repository will be created : development or staging.
As well, the user can pick if the project will have a VHOST associated. If the VHOST option is picked up, the the script will create the VHOST file and enable it.

The "AllowOverride" option in VHOST is set to "All" - otherwise the webserver will gracefully ignore anything we put in .htaccess file


NOTE: the script will work on DEBIAN based distros. I have tested the functionality in the latest DEBIAN stable and Ubuntu Server 12.04 LTS.
