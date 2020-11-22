
add_executable (intc intc.cpp)
target_link_libraries(intc prussdrv core)

run_pasm(pru_intc pru_intc.p) 

