

add_executable (sum sum.cc)
target_link_libraries(sum prussdrv)

run_pasm(sum sum.p) 


