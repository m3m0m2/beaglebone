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
using Core::log;


// structs for comunication ARM -> PRU
struct PruMemSetup {
    uint32_t ext_mem_start;
    uint32_t ext_mem_end;
} __attribute__((packed));

struct PruSamplingReq {
    // trigger sampling on condition, if 0 ARM starts immediately
    // 0 = start immediately (no trigger)
    // 1 = trigger on (sample&trigger_mask) == (trigger_val)
    // 2 = trigger on (sample&trigger_mask) != (trigger_val)
    // 3 = start on receving intc
    uint32_t trigger_mode;
    
    // use depending on above mode
    uint32_t trigger_mask;

    // trigger mask expected value
    uint32_t trigger_val;

    // number of samples before stopping or
    // must be lower than memory size allows
    // TODO: consider 0 for continuous until interrupt
    uint32_t samples;

    // time between samples in 10ns units
    // minimum value is 5
    uint32_t dt;

} __attribute__((packed));

struct PruRequest {
    PruMemSetup mem_setup;
    PruSamplingReq sampling;
} __attribute__((packed));;


// wrappers for comunication PRU -> ARM
struct PruResult {
    uint32_t samples;
    uint16_t sample[0];
} __attribute__((packed));


void init_pru_mem(Core::Pru& pru)
{
    int idx = 0;
    uint32_t* pru_mem = pru.get_pru_mem();
    uint32_t phy_ext_mem_addr = prussdrv_get_phys_addr(pru.get_ext_mem());

    PruRequest& pru_request = * reinterpret_cast<PruRequest*>(pru_mem);
    // pass ext mem: start_addr, end_addr
    pru_request.mem_setup.ext_mem_start = phy_ext_mem_addr;
    pru_request.mem_setup.ext_mem_end = phy_ext_mem_addr + pru.get_ext_mem_size();
    // some data
    pru_request.sampling.trigger_mode = 0;
    pru_request.sampling.trigger_mask = 0;
    pru_request.sampling.trigger_val = 0;
    pru_request.sampling.samples = 1000;
    // must ensure dt > 4
    pru_request.sampling.dt = 50;   // 2MHz

    // init result to 0
    uint32_t* ext_mem = pru.get_ext_mem();
    PruResult& result = * reinterpret_cast<PruResult*>(ext_mem);
    result.samples = 0;
}

void print_sample(int i, uint16_t sample)
{
    log("%d,%u,%u,%u,%u", i,
            (sample>>11)&1, // PIN 30, bit 11
            (sample>>10)&1, // PIN 28, bit 10
            (sample>> 9)&1, // PIN 29, bit 9
            (sample>> 8)&1  // PIN 27, bit 8
          );
}

void print_capture_result(Core::Pru& pru)
{
    uint32_t* pru_mem = pru.get_pru_mem();
    uint32_t* ext_mem = pru.get_ext_mem();

    PruResult& result = * reinterpret_cast<PruResult*>(ext_mem);

    //log("got: %x\n", pru_mem[3]);
    //log("got ext_mem: ", (int)result.result0);
    log("got %d samples:\n", result.samples);

    log("sample,P8_30,P8_28,P8_29,P8_27");
    for(int i=0; i<result.samples; i++)
        print_sample(i, result.sample[i]);
        //log("sample[%d]: %x\n", i, result.sample[i]);
}

void print_spi_result(Core::Pru& pru)
{
    uint32_t* pru_mem = pru.get_pru_mem();
    uint32_t n = pru_mem[0];

    log("spi pru got %u samples", n);
    for(int i=0; i<n; i++)
        log("spi[%d] = 0x%x", i, pru_mem[1+i]);
}


const char* pins_used[][2] =
{
    // inputs to capture data on PRU 1
    { "P8_30", "pruin" },   // PRU 1, bit 11 , default low
    { "P8_28", "pruin" },   // PRU 1, bit 10 , default low
    { "P8_29", "pruin" },   // PRU 1, bit 9 , default low
    { "P8_27", "pruin" },   // PRU 1, bit 8 , default low
    // some of the following pins are critical at boot
    // better to avoid:
    //{ "P8_40", "pruin" },   // PRU 1, bit 7 , default low
    //{ "P8_39", "pruin" },   // PRU 1, bit 6 , default low
    //{ "P8_42", "pruin" },   // PRU 1, bit 5 , default high
    //{ "P8_41", "pruin" },   // PRU 1, bit 4 , default high
    //{ "P8_44", "pruin" },   // PRU 1, bit 3 , default high
    //{ "P8_43", "pruin" },   // PRU 1, bit 2 , default high
    //{ "P8_46", "pruin" },   // PRU 1, bit 1 , default low
    //{ "P8_45", "pruin" },   // PRU 1, bit 0 , default low
    
    // used for hardware spi0 
    { "P9_17", "spi_cs" },
    { "P9_18", "spi" },
    { "P9_21", "spi" },
    { "P9_22", "spi_sclk" },

    nullptr
};


int main(int argc, char** argv)
{
    Core::ConfigPins config_pins;

    config_pins.set_pins(pins_used);

    auto& drv = Core::PrussDrv::get_instance();

    log("opening uio");
    // to receive signals from pru
    drv.open_host_uio(PRU_EVTOUT_0 + PRU_CAPTURE_NUM);
    drv.open_host_uio(PRU_EVTOUT_0 + PRU_SPI_NUM);

    auto& pru_capture = drv.get_pru(PRU_CAPTURE_NUM);
    auto& pru_spi = drv.get_pru(PRU_SPI_NUM);

    pru_capture.map_ext_mem();
    init_pru_mem(pru_capture);

    log("exec on pru");
    pru_capture.exec_program_file("pru_capture.bin");
    pru_spi.exec_program_file("pru_spi.bin");

    log("wait for pru completion");
    drv.wait_event_and_clear(PRU0_ARM_INTERRUPT + pru_capture.get_pru_num());
    log("pru_capture has completed");
    drv.wait_event_and_clear(PRU0_ARM_INTERRUPT + pru_spi.get_pru_num());
    log("pru_spi has completed");

    print_capture_result(pru_capture);
    print_spi_result(pru_spi);

    return 0;
}

