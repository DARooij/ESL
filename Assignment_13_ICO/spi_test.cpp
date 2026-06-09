#include <stdio.h>
#include <cstdint>
#include <string.h>

#include "FPGA_Interface.hpp"

#define SPI_CHANNEL 1
#define SPI_SPEED 1000000
#define SPI_FLAGS 0

int main() {
	char RXBuf[8]; 
	int spi = FPGAInterface::spiOpen(SPI_CHANNEL, SPI_SPEED, SPI_FLAGS);

    while(1)
    {

		FPGAInterface::spiRead(spi, SPI_SPEED, RXBuf, 8);


		uint32_t panEncoderValue;
		uint32_t tiltEncoderValue;
		memcpy(&panEncoderValue, &RXBuf[0], sizeof(uint32_t));
		memcpy(&tiltEncoderValue, &RXBuf[4], sizeof(uint32_t));
        printf("Pan Encoder Value: %u, Tilt Encoder Value: %u\n", panEncoderValue, tiltEncoderValue);

    }
}