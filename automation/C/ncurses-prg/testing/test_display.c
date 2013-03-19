#include <stdlib.h>
#include <ncurses.h>
#include <panel.h>
#include <time.h>

#define ENTER 10
#define ESCAPE 27
#define QUIT 113                                // key q


static WINDOW *main_window;
static WINDOW *screen;
static WINDOW *top_w, *center_w, *top_right_w, *bottom_right_w;
static PANEL *top_p, *center_p, *top_right_p, *bottom_right_p;
//WINDOW *window;

int current_sec, current_min, current_hour, current_day, current_week_day, current_month, current_year;
int current_getch;
int dooloop = 1;
time_t now;

struct tm *now_tm;

void screen_init(void) {
        main_window = initscr();                // initialize the curses library
        noecho();                               // don't echo input
        cbreak();                               // take input chars one at a time, no wait for \n
        keypad(stdscr, TRUE);                   // enable keyboard mapping
        nonl();                                 // tell curses not to do NL->CR/NL on output
        nodelay(main_window, TRUE);
        refresh();
        wrefresh(main_window);

        screen = newwin(6,174,1,1);
        top_right_w = newwin(15,30,1,175);
        bottom_right_w = newwin(40,30,16,175);
        center_w = newwin(5,173,7,1);

        box(screen, ACS_VLINE, ACS_HLINE);
        box(top_right_w, ACS_VLINE, ACS_HLINE);
        box(bottom_right_w, ACS_VLINE, ACS_HLINE);

        center_p = new_panel(center_w);
        box(center_w, 45, 45);

}

static void update_display(void) {
        curs_set(0);
        wattron(screen,COLOR_PAIR(2));
        mvwprintw(screen,1,3,"NCURSES TEST");
        wattroff(screen,COLOR_PAIR(2));

        mvwprintw(screen,2,6,"Hour: %d:%d:%d", current_hour, current_min, current_sec);
        mvwprintw(screen,3,6,"DATE: %d-%d-%d", current_day, current_month, current_year);

        wattron(screen,COLOR_PAIR(1));
        mvwprintw(screen,4,3,"--- q to quit ---");
        wattroff(screen,COLOR_PAIR(1));

        mvwprintw(top_right_w,3,6,"top right");
        mvwprintw(bottom_right_w,3,6,"bottom right");

        wrefresh(screen);
        wrefresh(top_right_w);
        wrefresh(bottom_right_w);
        refresh();

        update_panels();
        doupdate();

}

void screen_end(void) {
        endwin();
}

void maketime(void) {
        now = time (NULL);
        now_tm = localtime (&now);
        current_sec = now_tm->tm_sec;
        current_min = now_tm->tm_min;
        current_hour = now_tm->tm_hour;
        current_day = now_tm->tm_mday;
        current_week_day = now_tm->tm_wday;
        current_month = now_tm->tm_mon + 1;
        current_year = now_tm->tm_year + 1900;
}

int main(void) {
        screen_init();

        if(has_colors() == FALSE){
                endwin();
                printf("You terminal does not support color\n");
                exit(1);
                }
        start_color();                                  // Start color
        init_pair(1, COLOR_RED, COLOR_BLACK);
        init_pair(2, COLOR_BLACK, COLOR_GREEN);

        while (dooloop) {
                current_getch = getch();
                if (current_getch == QUIT){
                        dooloop = 0;
                }
                maketime();
                update_display();
                sleep(1);
        }
        screen_end();
        printf("Completed\n");

        return 0;
}
  