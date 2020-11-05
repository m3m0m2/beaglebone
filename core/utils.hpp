/*
 * @brief utilities, like log line
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#ifndef INCLUDE_UTILS_HPP
#define INCLUDE_UTILS_HPP

#include <iostream>
#include <utility>

namespace Core {


void log(){ std::cout<<std::endl; }

template<typename First, typename ...Rest>
void log(First && first, Rest && ...rest)
{
    std::cout << std::forward<First>(first);
    log(std::forward<Rest>(rest)...);
}


} // namespace Core

#endif
