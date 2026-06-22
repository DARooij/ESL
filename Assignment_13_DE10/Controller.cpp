/* Written by Diego Rooijackers and Damian Gaethofs
 * This file implements the controller and interfaces with hardware.
 */

#include <stdio.h>
#include <cstdint>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

/* 20-sim submodel class include file */
#include "FullController/FullController.h"
#include "soc_system.h"

#define DIRECTION_BIT_OFFSET 8

#define TIME_STEP_MICROS 10000
#define MAX_PWM_VALUE 20
#define TILT_PWM_VALUE_OFFSET 9

#define TILTCONST 3.14 / 9856
#define PANCONST 3.14 / 10852 

#define RAWSLACK 100

// Function prototypes
uint16_t ConvertControlSignal(XXDouble value);
void PerformHomeSequence();
 
uint8_t *esl_demo_map = NULL;
uint32_t encoderValues = 0;

uint16_t panMinValue = 0;
uint16_t panMaxValue = 0;
uint16_t tiltMinValue = 0;
uint16_t tiltMaxValue = 0;


/* the main function */
int main()
{
	int fd = 0;

	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if (fd < 0)
	{
		perror("Couldn't open /dev/mem\n");
		return -1;
	}
	esl_demo_map = (uint8_t *)mmap(NULL, HPS_0_ARM_A9_0_TOPENTITY_0_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, HPS_0_ARM_A9_0_TOPENTITY_0_BASE);
	if (esl_demo_map == MAP_FAILED)
	{
		perror("Couldn't map bridge.");
		close(fd);
		return -1;
	}

	XXDouble u[4 + 1];
	XXDouble y[2 + 1];

	uint16_t panEncoderValue = 0;
	uint16_t tiltEncoderValue = 0;
	XXDouble panPosition = 0.0;
	XXDouble tiltPosition = 0.0;

	PerformHomeSequence();

	panPosition = (panEncoderValue + RAWSLACK - panMinValue) * PANCONST;
	tiltPosition = (tiltEncoderValue + RAWSLACK - tiltMinValue) * TILTCONST;
	
	XXDouble panRef = (((panMaxValue - panMinValue)/2) * PANCONST);
	XXDouble tiltRef = (((tiltMaxValue - tiltMinValue)/2) * TILTCONST);

	/* initialize the inputs and outputs with correct initial values */
	u[0] = panPosition;	 /* PosPan */
	u[1] = tiltPosition; /* PosTilt */
	u[2] = panRef;	 /* RefPan */
	u[3] = tiltRef; /* RefTilt */

	y[0] = 0.0; /* OutPan */
	y[1] = 0.0; /* OutTilt */

	FullController my20simSubmodel;

	/* initialize the submodel itself and calculate the outputs for t=0.0 */
	my20simSubmodel.Initialize(u, y, 0.0);
	my20simSubmodel.SetFinishTime(0.0); /* set the finish time to infinite, so the model will run until we stop it */
	
	printf("Time: %f\n", my20simSubmodel.GetTime());

	int nextTime = clock() + TIME_STEP_MICROS;

	uint16_t tiltControlSignal = 0;
	uint16_t panControlSignal = 0;

	/* simple loop, the time is incremented by the integration method */
	while (my20simSubmodel.state != FullController::finished)
	{
		// Read encoder values
		encoderValues = *((uint32_t *)esl_demo_map);
		panEncoderValue = *((uint16_t *)esl_demo_map);
		tiltEncoderValue = (uint16_t)(encoderValues >> 16);

		panPosition = (panEncoderValue + RAWSLACK - panMinValue) * PANCONST;
		tiltPosition = (tiltEncoderValue + RAWSLACK - tiltMinValue) * TILTCONST;

		if (clock() >= nextTime)
		{
			nextTime = clock() + TIME_STEP_MICROS;
			// printf("Clock and nextTime: %ld, %ld\n", clock(), nextTime);
			printf("Encoder values: pan = %d, tilt = %d\n", panEncoderValue, tiltEncoderValue);
			printf("Encoder max values: pan = %d, tilt = %d\n", panMaxValue, tiltMaxValue);
			printf("Encoder min values: pan = %d, tilt = %d\n", panMinValue, tiltMinValue);
			printf("Positions: pan = %f, tilt = %f\n", panPosition, tiltPosition);
			printf("Reference position: pan = %f, tilt = %f\n", panRef, tiltRef);

			/* call the submodel to calculate the output */
			u[0] = panPosition;  // panPosition is the position value from the pan encoder
			u[1] = tiltPosition; // tiltPosition is the position value from the tilt encoder
			my20simSubmodel.Calculate(u, y);

			panControlSignal = ConvertControlSignal(y[0]);

			tiltControlSignal = ConvertControlSignal(y[1]);

			printf("Control signals: pan = %d, tilt = %d\n", panControlSignal, tiltControlSignal);


			printf("Time: %f\n", my20simSubmodel.GetTime());
		}

		*((uint32_t *)esl_demo_map) = (tiltControlSignal << TILT_PWM_VALUE_OFFSET) | panControlSignal;
	}

	/* perform the final calculations */
	my20simSubmodel.Terminate(u, y);

	*((uint32_t *)esl_demo_map) = 0;

	munmap(esl_demo_map, HPS_0_ARM_A9_0_TOPENTITY_0_SPAN);
	close(fd);

	/* and we are done */
	return 0;
}

uint16_t ConvertControlSignal(XXDouble value)
{
	if (value > 0)
	{
		return 1 << DIRECTION_BIT_OFFSET | ((uint8_t)(value * MAX_PWM_VALUE));
	}
	else if (value < 0)
	{
		return 0 << DIRECTION_BIT_OFFSET | ((uint8_t)((-value) * MAX_PWM_VALUE));
	}
	else
	{
		return 0;
	}
}

void PerformHomeSequence() 
{
	// Homing procedure, move at 25% speed in one direction
	*((uint32_t *)esl_demo_map) = (((0 << DIRECTION_BIT_OFFSET) | 10) << TILT_PWM_VALUE_OFFSET) | ((0 << DIRECTION_BIT_OFFSET) | 10);
	sleep(3);
	*((uint32_t *)esl_demo_map) = 0;
	usleep(30);

	encoderValues = *((uint32_t *)esl_demo_map);
	panMinValue = *((uint16_t *)esl_demo_map) - RAWSLACK;
	tiltMinValue = (uint16_t)(encoderValues >> 16) - RAWSLACK;

	*((uint32_t *)esl_demo_map) = (((1 << DIRECTION_BIT_OFFSET) | 10) << TILT_PWM_VALUE_OFFSET) | ((1 << DIRECTION_BIT_OFFSET) | 10);
	sleep(3);
	*((uint32_t *)esl_demo_map) = 0;
	usleep(30);

	encoderValues = *((uint32_t *)esl_demo_map);
	panMaxValue = *((uint16_t *)esl_demo_map) + RAWSLACK;
	tiltMaxValue = (uint16_t)(encoderValues >> 16) + RAWSLACK;
}