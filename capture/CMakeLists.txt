

add_executable (capture capture.cpp)
target_link_libraries(capture prussdrv core)

run_pasm(pru pru.p) 


