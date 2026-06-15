#include <error.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdbool.h>

// This includes the file you just provided
#include "soc_system.h" 

int main(int argc, char** argv) {
    int fd = 0;
    
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("Couldn't open /dev/mem\n");
        return -1;
    }
    
    uint8_t* fpga_avalon_map = NULL;
    
    // CHANGED HERE: Using the correct macros from soc_system.h
    fpga_avalon_map = (uint8_t*)mmap(NULL, HPS_0_ARM_A9_0_TOPENTITY_0_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, HPS_0_ARM_A9_0_TOPENTITY_0_BASE);
                                     
    if (fpga_avalon_map == MAP_FAILED) {
        perror("Couldn't map Avalon bus bridge.");
        close(fd);
        return -1;
    }

    printf("Successfully mapped FPGA memory. Reading Pitch and Yaw...\n");

    while(1) {
        // Read the 32-bit word from the base address
        uint32_t hw_data = *((volatile uint32_t *)fpga_avalon_map);
        
        // Extract lower 16 bits for Yaw
        uint16_t yaw_val = hw_data & 0xFFFF;
        
        // Extract upper 16 bits for Pitch
        uint16_t pitch_val = (hw_data >> 16) & 0xFFFF;

        printf("Pitch: 0x%04X (%5u) | Yaw: 0x%04X (%5u)\n", 
               pitch_val, pitch_val, yaw_val, yaw_val);
               
        usleep(100000); // 100 ms delay
    }
    
    munmap(fpga_avalon_map, HPS_0_ARM_A9_0_TOPENTITY_0_SPAN);
    close(fd);
    return 0;
}