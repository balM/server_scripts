import sys
import os
import time
import datetime
from fabric.api import *
from fabric.colors import *

#############################################################################################
#       Define some functions
#       This are NOT tasks that are to be executed
#       but we will use them to get usefull data like directory names that will be transfered
#############################################################################################

def get_folder_input():
        global filename
        global remote_path
        global remote_landing
        global remote_host

        print ""
        print "What files need to be copied?"
        print ""

        filename = raw_input("(CTRL+C -> exit) Copy LOCAL FILES from this location:                                     ")
        print ""
        remote_path = raw_input("(CTRL+C -> exit) Transfer files to REMOTE on this location:                            ")
        print ""
        remote_landing = raw_input("(CTRL+C -> exit) Update REMOTE on the following path:                                       ")
        print ""
        remote_host = raw_input("(CTRL+C -> exit)Enter the IP ADDRESS of the REMOTE HOST:                               ")
        print ""

def clear():
    """Clear screen, return cursor to top left"""
    sys.stdout.write('\033[2J')
    sys.stdout.write('\033[H')
    sys.stdout.flush()


#############################################################################################
#       Servers
#############################################################################################
#def dev_server():
#       env.user = 'username'
#       env.hosts = ['development.server']

#def staging_server():
#       env.user = 'username'
#       env.hosts = ['staging.server']
#
#def production_server():
#       env.user = 'username'
#       env.hosts = ['live-server-1', 'live-server-2' ]

#############################################################################################
#       TASKS
#############################################################################################
def host_info():
        print 'Checking lsb_release of host: ',  env.host
        run('lsb_release -a')
def uptime():
        run('uptime')
def last_logins():
        print 'Last 20 logins on the server: ', env.host
        run('last -20')

#       implement scp using fabric.
def copy_to_remote():
        # run with: fab dev_server copy_to_remote:/home/andy/test_deployment/fabric-test
        # make sure the directory is there!
        # create a directory
        now = datetime.datetime.now()
        remote_dir = now.strftime("%Y-%m-%d---%H:%M")
        env.hosts = remote_host

        # temporary change permissions
        local('sudo chown -R %s %s' % (env.user,filename))

        print 'Changing to remote folder... %s' % remote_path
        with cd(remote_path):
                run('mkdir -p %s' % remote_dir)

                # temporary change permissions
                local('sudo chown -R %s %s' % (env.user,filename))

                put(filename, remote_dir)
                with cd(remote_dir):
                        print ""
                        print (yellow("Changing to remote directory...",bold=True))
                        print ""
                        # we need to get the last part from $filename
                        # eg: if filename = /home/andy/test-files/all/themes
                        # we need just "themes". This folder will be copied to the WEB PATH

                        folder_to_copy = filename.rpartition('/')

                        # now folder_to_copy[0] = /home/andy/test-files/all
                        # we need folder_to_copy[2] = themes
                with cd(remote_landing):
                        print ""
                        print (green("Changing to WEB location...Removing previous folder/files...",bold=True))
                        print ""
                        sudo('rm -rf %s' % folder_to_copy[2])
                        sudo('cd %s' % remote_path)
                        #sudo('cd %s' % remote_dir)
                with cd(remote_dir):
                        print ""
                        print (green("Changing to remote location...Starting to copy new folder/files...",bold=True))
                        print ""
                        remote_landing_append_filename = "%s/%s" % (remote_landing,folder_to_copy[2])
                        sudo('cp -R %s %s' % (folder_to_copy[2],remote_landing_append_filename))
                with cd(remote_landing):
                        print ""
                        print (green("Fixing permisions for WEB PATH....",bold=True))
                        print ""
                        sudo('chown -R www-data:www-data %s' % remote_landing)

                # rollback the permissions for the local machine
                local('sudo chown -R www-data %s' % filename)

                print ""
                print (green("Completed!",bold=True))
                print ""

#############################################################################################
#       Display the main menu
#       Show this after each task is performed
#############################################################################################
keepProgramRunning = True


clear()

while keepProgramRunning:
        print ""
        print (cyan("********************************************************",bold=True))
        print (cyan("***** Fabric - a easy way to deploy!     ***************",bold=True))
        print (cyan("********************************************************",bold=True))
        print (green("Please select one of the following options:",bold=False))
        print ""
        print "         1: Deploy to REMOTE WEB SERVER"
        print "         2: Update MEDIA files (for Drupal builds)"
        print "         3: Display last 20 logins on specific server"
        print "         4: Display informations about a specific server"
        print "OR"
        print "         q: Exit"
        print ""

        #Capture the menu choice.
        choice = raw_input("Selection: ")
        if choice == "1":
                get_folder_input()
                copy_to_remote()
        elif choice == "2":
                clear()
                print "Not implemented."
                print (red("",bold=True))
                print ""
        elif choice == "3":
                last_logins()
        elif choice == "4":
                host_info()
                uptime()
        elif choice == "q":
                clear()
                print ""
                print (green("Exit. BYE!",bold=True))
                print ""
                sys.exit()
        else:
                clear()
                print ""
                print (red("Please choose a valid option.",bold=True))
                print ""

