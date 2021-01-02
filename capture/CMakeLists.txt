

add_executable (capture capture.cpp)
target_link_libraries(capture prussdrv core)

run_pasm(pru_capture pru_capture.p) 

run_pasm(pru_spi pru_spi.p) 

