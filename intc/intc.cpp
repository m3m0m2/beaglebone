/*
 * @brief experiments with intc
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#include "config.h"
#include "pru.hpp"
#include "config_pins.hpp"
#include "utils.hpp"
#include <prussdrv.h> 
#include <pruss_intc_mapping.h>

using namespace std;
using Core::log;
using Core::print_bits;



struct PruRegisters {
    uint32_t r31;
    uint32_t SECR0;
    uint32_t SECR1;
};

// wrappers for comunication PRU -> ARM
struct PruResult {
    uint32_t size;
    PruRegisters reg[0];
} __attribute__((packed));


void init_pru_mem(Core::Pru& pru)
{
    int idx = 0;
    uint32_t* pru_mem = pru.get_pru_mem();

    auto& result = * reinterpret_cast<PruResult*>(pru_mem);

    result.size = 0;
}


void return_result(Core::Pru& pru)
{
    uint32_t* pru_mem = pru.get_pru_mem();

    PruResult& result = * reinterpret_cast<PruResult*>(pru_mem);

    log("result has %u records:\n", result.size);
    for(int i=0; i<result.size; i++)
    {
        log("[%i].r31: ", i);
        print_bits(result.reg[i].r31, 30, 31);

        log("\n[%u].SECR0: ", i);
        print_bits(result.reg[i].SECR0, 0, 31);

        log("\n[%u].SECR1: ", i);
        print_bits(result.reg[i].SECR1, 0, 31);

        log("\n");
    }
}



int main(int argc, char** argv)
{
    auto& drv = Core::PrussDrv::get_instance();

    // to receive signals from pru
    drv.open_host_uio(PRU_EVTOUT_0 + PRU_NUM);
    // if two prus were used I would add
    drv.open_host_uio(PRU_EVTOUT_0 + PRU_OTHER_NUM);

    auto& pru = drv.get_pru(PRU_NUM);

    init_pru_mem(pru);

    pru.exec_program_file("pru_intc.bin");

    drv.wait_event_and_clear(PRU0_ARM_INTERRUPT + pru.get_pru_num());
    // imagining PRU completed the first task
    // after some processing here
    // tell PRU to do a second task
    drv.pru_send_event(ARM_PRU0_INTERRUPT);

    // wait for pru completion
    drv.wait_event_and_clear(PRU0_ARM_INTERRUPT + pru.get_pru_num());

    return_result(pru);

    return 0;
}

