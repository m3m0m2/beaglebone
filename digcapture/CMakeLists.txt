

add_executable (digcapture digcapture.cc)
target_link_libraries(digcapture prussdrv core)

#run_pasm(pru1 digcapture.p) 
run_pasm(pru0 digcapture.p) 


