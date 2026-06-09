#ifndef FPGA_INTERFACE_HPP
#define FPGA_INTERFACE_HPP

#include <cstddef>

namespace FPGAInterface
{
    int spiOpen(unsigned spiChan, unsigned spiBaud, unsigned spiFlags);
    int spiRead(int fd, unsigned speed, char *buf, unsigned count);
    int spiWrite(int fd, unsigned speed, char *buf, unsigned count);
    int spiXfer(int fd, unsigned speed, char *txBuf, char *rxBuf, unsigned count);
}

#endif // FPGA_INTERFACE_HPP