cmake_minimum_required(VERSION 3.10)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# cross compiling
# version 6 has to match gcc -v on beaglebone
set(GCC arm-linux-gnueabihf-gcc-6)
set(GPP arm-linux-gnueabihf-g++-6)

set(CMAKE_C_COMPILER ${GCC})
set(CMAKE_CXX_COMPILER ${GPP})


# build prussdrv library from am335x_pru_package app_loader 
#
set(PRU_PKG_DIR ${CMAKE_SOURCE_DIR}/am335x_pru_package/pru_sw/)
set(PRUSSDRV_SOURCES ${PRU_PKG_DIR}app_loader/interface/prussdrv.c)

# maybe consider using target_include_directories() for each target
include_directories(${PRU_PKG_DIR}app_loader/include core/)

add_library(prussdrv STATIC ${PRUSSDRV_SOURCES})


# build pasm
#
set(PASM_DIR ${PRU_PKG_DIR}utils/pasm_source/)
set(PASM_PATH ${PASM_DIR}../pasm)

add_custom_command(OUTPUT ${PASM_PATH}
    COMMAND ./linuxbuild
    COMMAND cp ${PASM_PATH} ${CMAKE_BINARY_DIR}/pasm
    WORKING_DIRECTORY ${PASM_DIR}
    COMMENT "Building pasm"
    VERBATIM
)

add_custom_target(
    pasm_build ALL
    DEPENDS ${PASM_PATH}
)


# function for subprojects to build using psam
#
function(run_pasm pasm_out pasm_source)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${pasm_out}.bin
       DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${pasm_source}" "${PASM_PATH}"
       COMMAND "${PASM_PATH}" -V3 -b "${CMAKE_CURRENT_SOURCE_DIR}/${pasm_source}" "${CMAKE_CURRENT_BINARY_DIR}/${pasm_out}"
       COMMENT "Running pasm"
    )
    add_custom_target("${pasm_out}_build" ALL
       DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${pasm_out}.bin"
       #COMMENT "target ${pasm_out}_build"
       #VERBATIM
    )

endfunction()



project(BeagleBone VERSION 0.1)

add_subdirectory(sum)

