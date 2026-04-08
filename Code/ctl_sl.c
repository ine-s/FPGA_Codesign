#include <stdint.h>
#include <stdio.h>

/* fixed by you */
#define NIVEAU    (*(volatile uint8_t  *)0x00000110u)

/* TODO: replace these with your real Qsys addresses */
#define START_SL  (*(volatile uint32_t *)0x00000120u)
#define BASE_DUTY (*(volatile uint32_t *)0x00000130u)

static void drain_line(void)
{
	int c;
	while ((c = getchar()) != '\n' && c != '\r' && c != EOF) { }
}

int main(void)
{
	/* Auto init */
	NIVEAU    = 0x6C;          // 108
	BASE_DUTY = 0x0800;        // duty only (1900 decimal)
	START_SL  = 0;             // stopped by default

	printf("Init: NIVEAU=0x6C, BASE_DUTY=0x76C\n");
	printf("Commands: g=start, s=stop, b <0..4095>=base duty, n <0..255>=niveau\n");

	while (1)
	{
		int c = getchar();
		if (c == EOF) continue;

		if (c == 'g') {
			START_SL = 1;
			printf("GO (start_SL=1)\n");
		}
		else if (c == 's') {
			START_SL = 0;
			printf("STOP (start_SL=0)\n");
		}
		else if (c == 'b') {
			int v;
			if (scanf("%d", &v) == 1) {
				if (v < 0) v = 0;
				if (v > 4095) v = 4095;
				BASE_DUTY = (uint32_t)(v & 0x0FFFu);
				printf("BASE_DUTY=%d\n", v);
			}
			drain_line();
		}
		else if (c == 'n') {
			int v;
			if (scanf("%d", &v) == 1) {
				if (v < 0) v = 0;
				if (v > 255) v = 255;
				NIVEAU = (uint8_t)v;
				printf("NIVEAU=%d (0x%02X)\n", v, (unsigned)v);
			}
			drain_line();
		}
	}
}