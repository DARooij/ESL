#include <stdio.h>
#include <cstdint>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include "FullController/FullController.h"
#include "soc_system.h"

#define DIRECTION_BIT_OFFSET 8

#define TIME_STEP_MICROS 10000
#define MAX_PWM_VALUE 20
#define TILT_PWM_VALUE_OFFSET 9

#define TILTCONST 3.14 / 9856
#define PANCONST 3.14 / 10852 

#define RAWSLACK 100

class Controller{ 
    private:

        uint8_t *esl_demo_map = NULL;
		uint32_t encoderValues = 0;
		uint16_t panMinValue = 0;
		uint16_t panMaxValue = 0;
		uint16_t tiltMinValue = 0;
		uint16_t tiltMaxValue = 0;
		uint16_t panRef = 0;
		uint16_t tiltRef = 0;
		uint16_t errorGain = 1;

		XXDouble panPosition = 0.0;
		XXDouble tiltPosition = 0.0;

        void PerformHomeSequence();

        uint16_t ConvertControlSignal(XXDouble value);

    public:
        void setReference(uint16_t _panRef, uint16_t _tiltRef);

        void setGain(uint16_t _errorGain);

        double getpanPosition();

        double gettiltPosition();

        int run();
};