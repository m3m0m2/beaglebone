#include "config_pins.hpp"
#include "pru.hpp"
#include "string"
#include "iostream"


using namespace Core;

const char* pin_settings[][2] = 
{
    { "P9_ONE", "up" },
    { "P9_TWO", "down" },
    nullptr
};

void test_config_pins()
{
    ConfigPins configPins("./test_{pin}");

    auto f=configPins.get_pin_file("P8_42");

    std::cout<<"got: "<<f<<std::endl;

    configPins.set_pins(pin_settings);
}


void test_pru()
{
    std::cout<<"testing PrussDrv.instance start"<<std::endl;
    {
        auto& instance1 = PrussDrv::get_instance();

        {
            auto& instance2 = PrussDrv::get_instance();

        }
        std::cout<<"closed inner block"<<std::endl;
    }
    std::cout<<"testing PrussDrv.instance done"<<std::endl;


    auto& instance3 = PrussDrv::get_instance();
    auto& pru0 = instance3.get_pru(0);
}

int main()
{
    //test_config_pins();
    test_pru();

    return 0;
}
