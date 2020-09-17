
add_executable (timer timer.c)
target_link_libraries(timer prussdrv)

run_pasm(timer timer.p) 

