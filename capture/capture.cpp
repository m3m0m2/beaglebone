/*
 * @brief get some samples from the PRU using external memory
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#include "config.h"
#include "pru.hpp"
#include "config_pins.hpp"
#include "utils.hpp"
#include <prussdrv.h> 
#include <pruss_intc_mapping.h>

using namespace std;
using namespace Core;


void init_pru_mem(Pru& pru)
{
    int idx = 0;
    uint32_t* pru_mem = pru.get_pru_mem();
    uint32_t phy_ext_mem_addr = prussdrv_get_phys_addr(pru.get_ext_mem());

    // pass ext mem: start_addr, end_addr
    pru_mem[idx++] = phy_ext_mem_addr;
    pru_mem[idx++] = phy_ext_mem_addr + pru.get_ext_mem_size();

    // some data
    pru_mem[idx++] = 10;
    pru_mem[idx++] = 0;
}

void return_result(Pru& pru)
{
    uint32_t* pru_mem = pru.get_pru_mem();
    uint32_t* ext_mem = pru.get_ext_mem();

    log("got: ", std::hex, pru_mem[3], std::dec);
    log("got ext_mem: ", ext_mem[0]);
}

const char* pins_used[][2] =
{
    { "P8_45", "pruin" },   // PRU 1, bit 0
    { "P8_46", "pruin" },   // PRU 1, bit 1
    { "P8_43", "pruin" },   // PRU 1, bit 2
    { "P8_44", "pruin" },   // PRU 1, bit 3
    nullptr
};


int main(int argc, char** argv)
{
    ConfigPins config_pins;

    config_pins.set_pins(pins_used);

    auto& drv = PrussDrv::get_instance();

    // to receive signals from pru
    constexpr int pru_arm_sysevt = PRU0_ARM_INTERRUPT + PRU_NUM;
    constexpr int arm_uio = PRU_EVTOUT_0 + PRU_NUM; 

    drv.open_host_uio(arm_uio);

    auto& pru = drv.get_pru(PRU_NUM);
    pru.map_ext_mem();

    init_pru_mem(pru);

    pru.exec_program_file("pru.bin");
    drv.wait_event_and_clear(pru_arm_sysevt);

    return_result(pru);

    return 0;
}

