/*
 * @brief utilities, like log line
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#include "utils.hpp"


namespace Core {

/*
#include <iostream>
#include <utility>

void log(){ std::cout<<std::endl; }

template<typename First, typename ...Rest>
void log(First && first, Rest && ...rest)
{
    std::cout << std::forward<First>(first);
    log(std::forward<Rest>(rest)...);
}
*/


#include <stdio.h>
#include <stdarg.h>

// old style printf is better than cout for formatting

void log(const char* fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    printf("\n");
}

void print_bits(unsigned x, unsigned start_bit, unsigned end_bit)
{
    unsigned i, bit;

    for(i=end_bit; ; i--)
    {
        bit = (x >> i) & 1;
        printf("%c", '0' + bit);

        if(i==start_bit)
            break;
    }
}


} // namespace Core

