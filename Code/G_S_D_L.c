#include <stdint.h>

#define PORT_S    (*(volatile uint32_t *)0x00000120u)
#define PORT_E    (*(volatile uint32_t *)0x00000140u)
#define VECT_POS  (*(volatile uint32_t *)0x00000100u)
#define NIVEAU    (*(volatile uint8_t  *)0x00000110u)
#define BASE_DUTY (*(volatile uint32_t *)0x00000130u)

#define FIN_SL    (PORT_E & 1u)
#define FIN_ROT   (PORT_E & 2u)
#define LINE_SEEN (VECT_POS & 0x7Fu)

static void delay_1s(void)
{
	volatile uint32_t i;
	for (i = 0; i < 500000; i++) {}
}

int main(void)
{
	NIVEAU    = 0x6C;
	BASE_DUTY = 0x75f;
	PORT_S    = 0;

	uint8_t dir = 0;

	typedef enum { WAIT, FOLLOW, PAUSE, ROTATE } state_t;
	state_t state = WAIT;

	for (;;) {
		switch (state) {

			case WAIT:
			if (LINE_SEEN) {
				PORT_S = 1;
				state  = FOLLOW;
			}
			break;

			case FOLLOW:
			if (FIN_SL) {
				PORT_S = 0;
				state  = PAUSE;
			}
			break;

			case PAUSE:
			delay_1s();
			dir   ^= 1;
			PORT_S = 2 | (dir << 2);
			state  = ROTATE;
			break;

			case ROTATE:
			if (FIN_ROT) {
				PORT_S = 0;
				delay_1s();
				PORT_S = 1;
				state  = FOLLOW;
			}
			break;
		}
	}
}