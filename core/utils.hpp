/*
 * @brief utilities, like log line
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#ifndef INCLUDE_UTILS_HPP
#define INCLUDE_UTILS_HPP


namespace Core {

void log(const char* fmt, ...);

void print_bits(unsigned x, unsigned start_bit, unsigned end_bit);

} // namespace Core

#endif
