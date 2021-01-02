/*
 * @brief PRU assembly
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

.origin 0
.entrypoint start

#include "config.h"
#include "pru.hp"

#define PRU_NUM PRU_CAPTURE_NUM



// MemBuffer
.struct ExtMemSetup
    .u32    start_addr
    .u32    end_addr
.ends

.struct SamplingReq
    // trigger sampling on condition, if 0 ARM starts immediately
    // 0 = start immediately (no trigger)
    // 1 = trigger on (sample&trigger_mask) == (trigger_val)
    // 2 = trigger on (sample&trigger_mask) != (trigger_val)
    // 3 = start on receving intc
    .u32 trigger_mode

    // use depending on above mode
    .u32 trigger_mask

    // trigger mask expected value
    .u32 trigger_val

    // number of samples before stopping or
    // 0 for continuous until interrupt
    // atm should not make mem full
    .u32 samples

    // time between samples
    .u32 dt
.ends

.struct WorkData
    .u32 current_sample
    .u32 dst_ptr
    .u32 current_dt
    .u32 reg_zero
    .u32 tmp1
    .u32 tmp2
.ends


///
// macros
//

// after receving an interrupt, call this
// to only clears intc for the given pru
.macro clear_intc_for_pru
.mparam core, local
    mov  local.tmp1, core
    qbne pru1, local.tmp1, 0
pru0:
    // just loading the meaningful byte
    mov  local.tmp1, INTC_SECR0+2
    lbco local.tmp2, CONST_PRUSSINTC, local.tmp1, 1
    and  local.tmp2, local.tmp2, 0b100100

    // write 1 to clear bits
    sbco local.tmp2, CONST_PRUSSINTC, local.tmp1, 1
    jmp  end
pru1:
    mov  local.tmp1, INTC_SECR0+2
    lbco local.tmp2, CONST_PRUSSINTC, local.tmp1, 1
    and  local.tmp2, local.tmp2, 0b1000010

    // write 1 to clear bits
    sbco local.tmp2, CONST_PRUSSINTC, local.tmp1, 1
end:
.endm


///
// entry point
//

start:

    // enable OCP by clearing bit 4 STANDBY_INIT of SYSCFG reg
    lbco r0, CONST_PRUSSCFG, CFG_SYSCFG, 4
    clr  r0, r0, 4
    sbco r0, CONST_PRUSSCFG, CFG_SYSCFG, 4


.enter main_scope

    // setup work variables
    .assign WorkData, r23, r28, work_data
    mov     work_data.current_sample, 0
    mov     work_data.reg_zero, 0

    // read ExtMemSetup data passed by ARM
    .assign ExtMemSetup, r16, r17, ext_mem
    lbbo    ext_mem, work_data.reg_zero, 0, SIZE(ext_mem)
    add     work_data.dst_ptr, ext_mem.start_addr, #4

handle_sampling_req:
    // read SamplingReq data passed by ARM
    .assign SamplingReq, r18, r22, sampling_req 
    lbbo    sampling_req, work_data.reg_zero, SIZE(ext_mem), SIZE(sampling_req)


    // dt must be greater then 4, as min cycle time is about 45ns ~ 22MHz
    qblt    min_dt_guaranteed, sampling_req.dt, #4
    mov     sampling_req.dt, #5
min_dt_guaranteed:
    // this is a bit hacky, basically ignore 45ns processing time
    // really 4*10 could be improved by using cycles, dec by 2 and ensure
    // initial val is even
    sub     sampling_req.dt, sampling_req.dt, 4

check_trigger:

    // trigger_modes:
    // 0 = start immediately (no trigger)
    qbeq    do_sampling, sampling_req.trigger_mode, #0

    // 1 = trigger on (sample&trigger_mask) == (trigger_val)
    qbeq    loop_sample_eq, sampling_req.trigger_mode, #1

    // 2 = trigger on (sample&trigger_mask) != (trigger_val)
    qbeq    loop_sample_ne, sampling_req.trigger_mode, #2

    // 3 = start on receving intc
    jmp     loop_on_intc


loop_sample_eq:
    and     work_data.tmp1, r31, sampling_req.trigger_mask
    qbne    loop_sample_eq, work_data.tmp1, sampling_req.trigger_val
    jmp do_sampling

loop_sample_ne:
    and     work_data.tmp1, r31, sampling_req.trigger_mask
    qbeq    loop_sample_ne, work_data.tmp1, sampling_req.trigger_val
    jmp do_sampling

loop_on_intc:
    // note: intc takes 5 cycles to propagate to r31
    // and more to clear
    wbs     r31, 30+PRU_NUM
    clear_intc_for_pru PRU_NUM, work_data
    // should take 5 cycles for r31 to clear
    // but probably no need to wait now for faster start
    // wbc     r31, 30+PRU_NUM


do_sampling:
    qbeq    end_sampling, work_data.current_sample, sampling_req.samples

    // store r31 0-15 bits with pin inputs to ext mem
    sbbo    r31.w0, work_data.dst_ptr, 0, 2

    // increment ext mem pointer
    add     work_data.dst_ptr, work_data.dst_ptr, #2

    // increment num of samples
    add     work_data.current_sample, work_data.current_sample, #1

    // delay
    mov     work_data.current_dt, sampling_req.dt
delay_loop:
    sub     work_data.current_dt, work_data.current_dt, 1
    qbne    delay_loop, work_data.current_dt, 0

    // exit if intc received
    qbbs    intc_exit, r31, 30+PRU_NUM
    jmp do_sampling

intc_exit:
    clear_intc_for_pru PRU_NUM, work_data
    

end_sampling:

    // store samples in ext mem
    sbbo     work_data.current_sample, ext_mem.start_addr, 0, 4

.leave main_scope

    // Send notification to Host for program completion
    mov r31.b0, PRU0_ARM_INTERRUPT+PRU_NUM+16

    halt
