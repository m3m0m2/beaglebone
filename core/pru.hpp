/*
 * @brief classes around prussdrv
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#ifndef INCLUDE_PRU_HPP
#define INCLUDE_PRU_HPP

#define TOTAL_PRUS_NUM  2

#include "prussdrv.h"
#include <cstdint>

namespace Core {

class PrussDrv;

///
// Pru is non-copyable and retrieved using PrussDrv
//
class Pru
{
    int _pru_num;
    uint32_t *_pru_mem, *_ext_mem;
    uint32_t _ext_mem_size;

    Pru(int pru_num);
    friend PrussDrv;

    void map_pru_mem();

public:
    int get_pru_num() const {return _pru_num;}
    uint32_t* get_pru_mem() {return _pru_mem;}
    uint32_t* get_ext_mem() {return _ext_mem;}
    uint32_t get_ext_mem_size() {return _ext_mem_size;}

    ~Pru();

    void map_ext_mem();
    void exec_program_file(const char* file);

    void reset();
    void enable();
    void disable();

    // other functions are available in prussdrv like
    // prussdrv_pru_write_memory


    // prevent copies of Pru
    Pru(Pru const&)            = delete;
    void operator=(Pru const&) = delete;
};


///
// PrussDrv is a singleton class 
//
class PrussDrv
{
private:
    PrussDrv();

public:
    // call before the first get_instance if needed, otherwise default setup
    static void setup_intc(tpruss_intc_initdata prussintc_init_data);

    static PrussDrv& get_instance();
    ~PrussDrv();

    // prevent copies of this
    PrussDrv(PrussDrv const&)       = delete;
    void operator=(PrussDrv const&) = delete;

    Pru& get_pru(int pru_num);

    // needed to later wait on event from PRU
    // sysevt e.g. PRU0_ARM_INTERRUPT
    void pru_send_event(unsigned sysevt);
    void wait_event_and_clear(unsigned sysevt);
    // host_uio is usually PRU_EVTOUT0 or PRU_EVTOUT1
    // this needs to be called before get_pru
    void open_host_uio(unsigned host_uio);

private:
    static Pru* _prus[TOTAL_PRUS_NUM];
    static tpruss_intc_initdata _prussintc_init_data;
    static bool _init_done;
};

/* default interrupts 
 *
 * sysevts: PRU0_PRU1_INTERRUPT=17, PRU1_PRU0_INTERRUPT, PRU0_ARM_INTERRUPT, 
 *          PRU1_ARM_INTERRUPT, ARM_PRU0_INTERRUPT, ARM_PRU1_INTERRUPT
 * channels:
 * 0 = dst PRU0 (PRU1_PRU0_INTERRUPT, ARM_PRU0_INTERRUPT)
 * 1 = dst PRU1 (PRU0_PRU1_INTERRUPT, ARM_PRU1_INTERRUPT)
 * 2 = PRU0_ARM_INTERRUPT available as PRU_EVTOUT0
 * 3 = PRU1_ARM_INTERRUPT available as PRU_EVTOUT1
 *
 * terminology the final mapped values are called host_uio:
 * PRU_EVTOUT0, PRU_EVTOUT1, ...
 */

} // namespace Core

#endif
