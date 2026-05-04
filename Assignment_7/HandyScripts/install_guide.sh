###
echo "[WARNING] DELIVERED AS IS, the TA's are not required to help you with running this script"
###

## update your packages
sudo apt update

## make project folder (from git)
sudo apt install -y git
git clone https://git.ram.eemcs.utwente.nl/repository-esl/laboratory-files.git
cd laboratory-files

## installing the packages
sudo apt install -y yosys 
sudo apt install -y nextpnr-ice40-qt 
sudo apt install -y libboost-all-dev 
sudo apt install -y libeigen3-dev 
sudo apt install -y qtcreator 
sudo apt install -y qtbase5-dev 
sudo apt install -y qt5-qmake 
sudo apt install -y fpga-icestorm 
sudo apt install -y g++ 
sudo apt install -y raspi-config
sudo apt install -y git 
sudo apt install -y libgpiod-dev 
sudo apt install -y gpiod

# get the additional tooling (icoprog to upgrade / make the fpga on board work)
git clone https://git.ram.eemcs.utwente.nl/repository-esl/icoprog.git
cd icoprog
## Create the icoprog executable
g++ src/icoprog.cpp src/gpio_interface.cpp -o icoprog -lgpiodcxx

# BEFORE YOU DO ANYTHING THE .PCF file is still missing! This is located in the Assignments
