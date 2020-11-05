/*
 * @brief classes around prussdrv
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

#include "pru.hpp"
#include "pruss_intc_mapping.h"

#include <iostream>
#include <assert.h>


namespace Core {

static void assert_valid_pru_num(int pru_num)
{
    assert(pru_num>=0 and pru_num<TOTAL_PRUS_NUM);
}


///
// Pru
//

Pru::Pru(int pru_num): _pru_num(pru_num), _pru_mem(nullptr),
                _ext_mem(nullptr), _ext_mem_size(0)
{
    assert_valid_pru_num(_pru_num);

    map_pru_mem();
}

Pru::~Pru()
{
    prussdrv_pru_disable(_pru_num);
}

void Pru::map_pru_mem()
{
    if(_pru_mem!=nullptr)
        return;
    void* pru_mem_void = nullptr;

    prussdrv_map_prumem (_pru_num, &pru_mem_void);

    _pru_mem = (uint32_t*)pru_mem_void;
}

void Pru::map_ext_mem()
{
    if(_ext_mem!=nullptr)
        return;
    void* ext_mem_void;

    prussdrv_map_extmem(&ext_mem_void);
    _ext_mem = (uint32_t*)ext_mem_void;
    _ext_mem_size = prussdrv_extmem_size();
}

void Pru::exec_program_file(const char* file)
{
    assert(prussdrv_exec_program(_pru_num, file) >= 0);
}

void Pru::reset()
{
    prussdrv_pru_reset(_pru_num);
}

void Pru::enable()
{
    prussdrv_pru_enable(_pru_num);
}

void Pru::disable()
{
    prussdrv_pru_disable(_pru_num);
}




///
// PrussDrv
//

PrussDrv::PrussDrv()
{
    for(int num=0; num<TOTAL_PRUS_NUM; num++)
        _prus[num] = nullptr;

    prussdrv_init();
}

PrussDrv::~PrussDrv()
{
    for(int num=0; num<TOTAL_PRUS_NUM; num++)
        if(_prus[num] != nullptr)
            delete _prus[num];

    prussdrv_exit();
}

void PrussDrv::setup_intc(tpruss_intc_initdata prussintc_init_data)
{
    assert(!_init_done);
    _prussintc_init_data = prussintc_init_data;
}

Pru& PrussDrv::get_pru(int num)
{
    assert_valid_pru_num(num);

    if(!_init_done) {
        prussdrv_pruintc_init(&_prussintc_init_data);
        _init_done = true;
    }

    if(_prus[num] == nullptr)
        _prus[num] = new Pru(num);

    return *_prus[num];
}

void PrussDrv::open_host_uio(unsigned host_uio)
{
    // this method is called before prussdrv_pruintc_init so I cannot mapping
    //int host = prussdrv_get_event_to_host_map(sysevt);
    //assert(host>=0);
    int ret = prussdrv_open(host_uio);
    assert(ret>=0);
}

void PrussDrv::pru_send_event(unsigned sysevt)
{
    prussdrv_pru_send_event(sysevt);
}

void PrussDrv::wait_event_and_clear(unsigned sysevt)
{
    int host = prussdrv_get_event_to_host_map(sysevt);
    assert(host>=0);
    prussdrv_pru_wait_event(host);
    prussdrv_pru_clear_event(host, sysevt);
}

PrussDrv& PrussDrv::get_instance()
{
    static PrussDrv instance;
    return instance;
}



Pru* PrussDrv::_prus[TOTAL_PRUS_NUM] = { nullptr, nullptr };
tpruss_intc_initdata PrussDrv::_prussintc_init_data = PRUSS_INTC_INITDATA;
bool PrussDrv::_init_done = false;

} // namespace Core
