/*
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
