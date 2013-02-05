/*
        TASK: watch over a folder and log all teh events inside the folder.
        Usefull when a FTP client is making some changes or uploading new files.

        Update thii as there is no looging mechanism involved yet.
        We need a way to log the activities
        a struct like FILE *activity will do :)
        TO-DO
*/
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/inotify.h>

//The fixed size of the event buffer:
#define EVENT_SIZE  ( sizeof (struct inotify_event) )

//The size of the read buffer: estimate 1024 events with 16 bytes per name over and above the fixed size above
#define EVENT_BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )

//helper function prototypes
const char * target_type(struct inotify_event *event) ;
const char * target_name(struct inotify_event *event);
const char * event_name(struct inotify_event *event);
void fail(const char *message) ;

int main(int argc, char *argv[]) {
        int length, read_ptr, read_offset; //management of variable length events
        int i, watched;
        int fd, wd;                                     // descriptors returned from inotify subsystem
        char buffer[EVENT_BUF_LEN];     //the buffer to use for reading the events

        if( argc < 2 )
                fail("Must specify path(s) to watch");

        /*creating the INOTIFY instance*/
        fd = inotify_init();
        if (fd < 0)
                fail("inotify_init");

        watched = 0;
        i = 1;
        while( argv[i] != NULL ) {
                /*adding a watch for element argv[i]*/
                wd = inotify_add_watch(fd, argv[i], IN_ALL_EVENTS);
                if( wd == -1 ) {
                        printf("failed to add watch %s\n", argv[i]);
                } else {
                        printf("Watching %s as %i\n", argv[i], wd);
                        watched++;
                }
                i++;
        }

        if( watched == 0 )
                fail("Nothing to watch!");
        read_offset = 0; //remaining number of bytes from previous read
        while (1) {
                /* read next series of events */
                length = read(fd, buffer + read_offset, sizeof(buffer) - read_offset);
                if (length < 0)
                        fail("read");
                length += read_offset; // if there was an offset, add it to the number of bytes to process
                read_ptr = 0;

                // process each event
                // make sure at least the fixed part of the event in included in the buffer
                while (read_ptr + EVENT_SIZE <= length ) {
                        //point event to beginning of fixed part of next inotify_event structure
                        struct inotify_event *event = (struct inotify_event *) &buffer[ read_ptr ];

                        // if however the dynamic part exceeds the buffer,
                        // that means that we cannot fully read all event data and we need to
                        // deffer processing until next read completes
                        if( read_ptr + EVENT_SIZE + event->len > length )
                                break;
                        //event is fully received, process
                        printf("WD:%i %s %s %s COOKIE=%u\n",
                                event->wd, event_name(event),
                                target_type(event), target_name(event), event->cookie);
                        //advance read_ptr to the beginning of the next event
                        read_ptr += EVENT_SIZE + event->len;
                }
                //check to see if a partial event remains at the end
                if( read_ptr < length ) {
                        //copy the remaining bytes from the end of the buffer to the beginning of it
                        memcpy(buffer, buffer + read_ptr, length - read_ptr);
                        //and signal the next read to begin immediatelly after them
                        read_offset = length - read_ptr;
                } else
                        read_offset = 0;

        }
        // typically, for each wd, need to: inotify_rm_watch(fd, wd);

        close(fd);
}

void fail(const char *message) {
        perror(message);
        exit(1);
}
const char * target_type(struct inotify_event *event) {
        if( event->len == 0 )
                return "";
        else
                return event->mask & IN_ISDIR ? "directory" : "file";
}
const char * target_name(struct inotify_event *event) {
        return event->len > 0 ? event->name : NULL;
}

const char * event_name(struct inotify_event *event) {
        if (event->mask & IN_ACCESS)
                return "access";
        else if (event->mask & IN_ATTRIB)
                return "attrib";
        else if (event->mask & IN_CLOSE_WRITE)
                return "close write";
        else if (event->mask & IN_CLOSE_NOWRITE)
                return "close nowrite";
        else if (event->mask & IN_CREATE)
                return "create";
        else if (event->mask & IN_DELETE)
                return "delete";
        else if (event->mask & IN_DELETE_SELF)
                return "watch target deleted";
        else if (event->mask & IN_MODIFY)
                return "modify";
        else if (event->mask & IN_MOVE_SELF)
                return "watch target moved";
        else if (event->mask & IN_MOVED_FROM)
                return "moved out";
        else if (event->mask & IN_MOVED_TO)
                return "moved into";
        else if (event->mask & IN_OPEN)
                return "open";
        else
                return "unknown event";
}
