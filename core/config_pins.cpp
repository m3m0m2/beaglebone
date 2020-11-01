/*
 * @brief ConfigPins class to setup PINs
 * @author Mauro Meneghin (m3m0m2@gmail.com)
 */

#include "config_pins.hpp"


ConfigPins::ConfigPins(std::string file_template):
    _file_template(file_template)
{}

std::string ConfigPins::get_pin_file(std::string pin_name)
{
    std::string ret = _file_template;
    const std::string pin_placeholder = "{pin}";

    auto pin_it = ret.find(pin_placeholder);
    if(pin_it == std::string::npos)
        throw std::runtime_error("file template is missing placeholder: " + pin_placeholder);

    ret.replace(pin_it, pin_placeholder.length(), pin_name);

    return ret;
}

std::string ConfigPins::get_pin(std::string pin_name)
{
    std::string value;
    std::string filename = get_pin_file(pin_name);
    std::ifstream file;

    file.open(filename);
    file >> value;
    file.close();

    return value;
}

void ConfigPins::set_pin(std::string pin_name, std::string value)
{
    std::string filename = get_pin_file(pin_name);
    std::ofstream file;

    file.open(filename);
    file << value;
    file.close();
}

void ConfigPins::set_pins(const char* array[][2])
{
    for(int idx=0; ; idx++)
    {
        const char* key = array[idx][0];

        if(key==nullptr) break;

        const char* value = array[idx][1];

        if(value==nullptr) break;

        set_pin(key, value);
    }
}

