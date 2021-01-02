
set(CORE_CPP_SOURCES config_pins.cpp pru.cpp utils.cpp)
set(CORE_HPP_INCLUDE config_pins.hpp pru.hpp utils.hpp)

add_library(core STATIC ${CORE_CPP_SOURCES})
target_link_libraries(core prussdrv)


add_executable (test_core test_core.cpp)
target_link_libraries(test_core core prussdrv)

