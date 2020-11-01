#include "config_pins.hpp"
#include "string"
#include "iostream"


const char* pin_settings[][2] = 
{
    { "P9_ONE", "up" },
    { "P9_TWO", "down" },
    nullptr
};

int main()
{

    ConfigPins configPins("./test_{pin}");

    auto f=configPins.get_pin_file("P8_42");

    std::cout<<"got: "<<f<<std::endl;

    configPins.set_pins(pin_settings);

    return 0;
}
