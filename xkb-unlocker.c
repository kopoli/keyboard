
#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/XKBlib.h>

void usage(char const *prog)
{
    fprintf(stderr, "usage: %s\n\nUntoggles the caps lock\n", prog);
}

int main(int argc, char *argv[])
{
    Display *disp;

    if (argc > 1)
    {
        usage(argv[0]);
        return 1;
    }

    disp = XOpenDisplay(NULL);
    if (!disp)
    {
        fprintf(stderr, "Could not connect to X server.\n");
        return 1;
    }

    if (!XkbLockModifiers(disp, XkbUseCoreKbd, LockMask, 0))
    {
        fprintf(stderr, "Unlocking Caps Lock failed.\n");
    }

    XCloseDisplay(disp);
    return 0;
}
