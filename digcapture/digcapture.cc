#include "config.h"
#include "config_pins.hpp"
#include <pruss_intc_mapping.h>
#include <prussdrv.h>
#include <stdio.h>
#include <stdarg.h>


// using PRUSS0_PRU1_DATARAM;
static constexpr int pru_num = PRU_NUM;
static constexpr int pru_event_out = PRU_EVTOUT_0 + pru_num;
static constexpr int pru_arm_interrupt = PRU0_ARM_INTERRUPT + pru_num;

static unsigned* pru_mem_int = nullptr;
static unsigned* pru_ext_mem_int = nullptr;
static unsigned  pru_ext_mem_size = 0;


void log(const char* fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

void init_pru_mem()
{
    int idx = 0;
    unsigned phy_ext_mem_addr = prussdrv_get_phys_addr(pru_ext_mem_int);

    // pass ext mem: start_addr, end_addr
    *(pru_mem_int + idx++) = (unsigned)phy_ext_mem_addr;
    *(pru_mem_int + idx++) = (unsigned)phy_ext_mem_addr + pru_ext_mem_size;

    // some data
    *(pru_mem_int + idx++) = 10;
    *(pru_mem_int + idx++) = 0;
}

void return_result()
{
    log("got: %X\n", pru_mem_int[3]);
    log("got ext_mem: %X\n", pru_ext_mem_int[0]);
}

// pru_num: either of:
//   PRUSS0_PRU0_DATARAM
//   PRUSS0_PRU1_DATARAM
void map_pru_mem(int pru_num)
{
    void* pru_mem_void = nullptr;

    prussdrv_map_prumem (pru_num, &pru_mem_void);

    pru_mem_int = (unsigned*)pru_mem_void;
}

void map_pru_ext_mem()
{
    void* pru_ext_mem_void;

    prussdrv_map_extmem(&pru_ext_mem_void);
    pru_ext_mem_int = (unsigned*)pru_ext_mem_void;
    pru_ext_mem_size = prussdrv_extmem_size();
}


int main(int argc, char** argv)
{
    int ret;
    char fw_file[100];
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

    log("Starting %s\n", argv[0]);

    ConfigPins config_pins;

    prussdrv_init();

    // Open event for interrupt
    ret = prussdrv_open(pru_event_out);
    if (ret)
    {
        log("Error: prussdrv_open failed\n");
        return ret;
    }

    prussdrv_pruintc_init(&pruss_intc_initdata);

    // prep
    map_pru_mem(pru_num);
    map_pru_ext_mem();
    init_pru_mem();

    log("pru_mem addr:%X\n", pru_mem_int);
    log("pru_ext_mem addr:%X\n", pru_ext_mem_int);
    log("pru_ext_mem size:%u\n", pru_ext_mem_size);

    sprintf(fw_file, "pru%d.bin", pru_num);
    log("Running %s on PRU%d\n", fw_file, pru_num);
    if(prussdrv_exec_program (pru_num, fw_file))
    {
        log("Error: Could not open %s\n", fw_file);
        return 1;
    }

    log("Waiting for interrupt from PRU%d\n", pru_num);
    prussdrv_pru_wait_event(pru_event_out);
    prussdrv_pru_clear_event(pru_event_out, pru_arm_interrupt);


    log("PRU returned:\n");
    return_result();
    

    prussdrv_pru_disable(pru_num);
    prussdrv_exit();
    return 0;
}
