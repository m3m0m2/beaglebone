/*
 * @brief ConfigPins class to setup PINs
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 *
 * Refer to config-pin for more details, under the hood
 * a pin can be set by writing to a special file e.g.
 * /sys/bus/platform/drivers/bone-pinmux-helper/ocp:P8_42_pinmux/state
 */

#ifndef INCLUDE_CONFIG_PINS_HPP
#define INCLUDE_CONFIG_PINS_HPP

#include <string>
#include <iostream>
#include <fstream>

namespace Core {

class ConfigPins
{
    const std::string _file_template;

    // the requested pin will be substituted in _file_template 
    const std::string _pin_placeholder = "{pin}";

public:
    ConfigPins(std::string file_template="/sys/bus/platform/drivers/bone-pinmux-helper/ocp:{pin}_pinmux/state");

    std::string get_pin_file(std::string pin_name);

    std::string get_pin(std::string pin_name);

    void set_pin(std::string pin_name, std::string value);


    /* set all pins needed at once, use with a 2d string array null terminated like:
     
const char* pin_settings[][2] =
{
    { "P9_1", "pruin" },
    { "P9_2", "pruout" },
    nullptr
};  */
    void set_pins(const char* array[][2]);
};

} // namespace Core

#endif
