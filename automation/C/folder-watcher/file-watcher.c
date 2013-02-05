#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/inotify.h>

#define EVENT_SIZE  ( sizeof (struct inotify_event) )
#define BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )

/*
        The application creates an inotify instance with fd = inotify_init(); and adds one watch to monitor modifications, new files, and destroyed files in /home/andy/watch_this,
        as specified by wd = inotify_add_watch(...). The read() method blocks until one or more alerts arrive.
        The specifics of the alert(s).each file, each event.are sent as a stream of bytes; hence, the loop in the application casts the stream of bytes into a series of event structures.
*/
int main( int argc, char **argv )
{
/*      Run as daemon   */

/*      daemon(0,0);    */

  int length, i = 0;
  int fd;
  int wd;
  char buffer[BUF_LEN];
  FILE *activity;
  time_t current;       /*      basic time manipulation         */
  current = time(NULL);

/*       I hope that we have inotify installed */
  fd = inotify_init();
  activity = fopen("activity.log", "a");
        if (activity == NULL) {
                printf("Cannot open log file.\n");
                exit(0);
        }

  if ( fd < 0 ) {
    perror( "inotify_init" );
  }

  wd = inotify_add_watch( fd, "/home/andy/watch_this",
                         IN_MODIFY | IN_CREATE | IN_DELETE );
  length = read( fd, buffer, BUF_LEN );

  if ( length < 0 ) {
    perror( "read" );
  }
/* Use killall to kill me.
        Need to improve this!   */

  while ( i < length ) {
    struct inotify_event *event = ( struct inotify_event * ) &buffer[ i ];
    if ( event->len ) {
      if ( event->mask & IN_CREATE ) {
        if ( event->mask & IN_ISDIR ) {
			fprintf(activity, "The directory %s was created at %s\n", event->name, ctime(&current) );
        }
        else {
         fprintf(activity, "The file %s was created at %s\n", event->name, ctime(&current));
        }
      }
      else if ( event->mask & IN_DELETE ) {
        if ( event->mask & IN_ISDIR ) {
          printf( "The directory %s was deleted.\n", event->name );
        }
        else {
          fprintf(activity, "The file %s was deleted at %s\n", event->name, ctime(&current) );
        }
      }
      else if ( event->mask & IN_MODIFY ) {
        if ( event->mask & IN_ISDIR ) {
          printf( "The directory %s was modified.\n", event->name );
        }
        else {
          fprintf(activity, "The file %s was modified.\n", event->name );
        }
      }
    }
    i += EVENT_SIZE + event->len;
  }


  ( void ) inotify_rm_watch( fd, wd );
  ( void ) close( fd );

  exit( 0 );
}
