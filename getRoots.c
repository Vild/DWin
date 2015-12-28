#include <stdio.h>

#include <xcb/xcb.h>

int main() {
	xcb_connection_t		 *c;
	xcb_screen_t				 *screen;
	int									 screen_nbr;
	xcb_screen_iterator_t iter;

	/* Open the connection to the X server. Use the DISPLAY environment variable */
	c = xcb_connect(NULL, &screen_nbr);

	printf("length: %d\n\n", xcb_setup_roots_length(xcb_get_setup(c)));

	/* Get the screen #screen_nbr */
	iter = xcb_setup_roots_iterator (xcb_get_setup (c));
	for (; iter.rem; --screen_nbr, xcb_screen_next (&iter)) {
		screen = iter.data;

		printf ("\n");
		printf ("Informations of screen %ld, number %d (%d):\n", screen->root, screen_nbr, iter.rem);
		printf ("\twidth.........: %d\n", screen->width_in_pixels);
		printf ("\theight........: %d\n", screen->height_in_pixels);
		printf ("\twhite pixel...: %ld\n", screen->white_pixel);
		printf ("\tblack pixel...: %ld\n", screen->black_pixel);
		printf ("\n");
	}

	return 0;
}
