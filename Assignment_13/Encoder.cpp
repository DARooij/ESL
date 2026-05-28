
#include "Encoder.hpp"

class Encoder {
    uint32_t getPosition() 
    {
        // Open SPI channel 0 with a baud rate of 1 MHz and mode 0
        int fd = FPGAInterface::spiOpen(0, 1000000, 0);
        if (fd < 0) {
            std::cerr << "Failed to open SPI channel" << std::endl;
            return -1;
        }

        // Read 4 bytes from the encoder
        char buf[4];
        if (FPGAInterface::spiRead(fd, 1000000, buf, sizeof(buf)) < 0) {
            std::cerr << "Failed to read from SPI" << std::endl;
            close(fd);
            return -1;
        }

        // Close the SPI channel
        close(fd);

        // Convert the received bytes to a uint32_t position value
        uint32_t position = (static_cast<uint32_t>(buf[0]) << 24) |
                            (static_cast<uint32_t>(buf[1]) << 16) |
                            (static_cast<uint32_t>(buf[2]) << 8) |
                            static_cast<uint32_t>(buf[3]);

        return position;
    }
