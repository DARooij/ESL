# ESL

## Assignment 4

Important parameters include:
- Pulses per rotation

Statuses we need to measure:
- Speed 
- Direction of rotation
- Possibly the position of the motor

## Assignment 8

The min position of the pitch encoder is 65061 (leftmost) and the maximum is 207 (rightmost), the difference between that is 681 increments

For yaw, maximum is 2450 and minimum is 65535, that is a difference of 2450

## Assignment 12

We're going to use the Raspberry Pi with the FPGA HAT. We will use polling for getting the data of the encoder and for receiving PWM commands on the FPGA. We are going to use 32 bits as word size for our SPI bus. Polling has a higher overhead than interrupts, but are easier to work with and easier to debug. 

Interesting points of measurement:

- Speed of the bus: We would like to waste as little time as possible on communication, especially if we we're using polling.
- Word size efficiency: We would like to use up as little packets as possible, making each packet efficient.
- 

Raspberry PI vs DE10;
- Raspberry PI is easier in use case, the avalon bus of the DE10 is quite finicky to work with and can be hard to debug
- Raspberry Pi is more common in use, more people have experience with this, which makes it easier to use for people not super familiar with the project
