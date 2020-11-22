/*
 * @brief experiments using intc
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

.origin 0
.entrypoint start

#include "config.h"
#include "pru.hp"


.struct Result
    .u32 size
.ends

.struct Sample
    .u32 reg_r31
    .u32 reg_SECR0
    .u32 reg_SECR1
.ends

.struct Local
    .u32 reg_zero
    .u32 store_addr
    .u32 tmp1
    .u32 tmp2
.ends


///
// macros
//

.macro delay
.mparam val, local
    mov  local.tmp1, val
    qbeq delay_end, local.tmp1, 0
delay_loop:
    sub  local.tmp1, local.tmp1, 1
    qbne delay_loop, local.tmp1, 0
delay_end:
.endm


.macro load_sample
.mparam sample, local
    mov  sample.reg_r31, r31
    mov  local.tmp1, INTC_SECR0
    lbco sample.reg_SECR0, C0, local.tmp1, 8
.endm

.macro store_sample
.mparam sample, local, result
    sbbo sample, local.store_addr, 0, SIZE(sample)
    add  local.store_addr, local.store_addr, SIZE(sample)
    add  result.size, result.size, 1
.endm

// this clears all the interrupts, but should only clear 
// intc for this core
.macro clear_intc
.mparam local
    mov local.tmp1, INTC_SECR0

    // write 1 to clear bits
    lbco local.tmp2, C0, local.tmp1, 4
    sbco local.tmp2, C0, local.tmp1, 4

    // secr1 offset+=4
    add local.tmp1, local.tmp1, 4
    lbco local.tmp2, C0, local.tmp1, 4
    sbco local.tmp2, C0, local.tmp1, 4
.endm


// this is more refined than clear_intc
// it only clears intc for the given pru
.macro clear_intc_for_pru
.mparam core, local
    mov  local.tmp1, core
    qbne pru1, local.tmp1, 0
pru0:
    // just loading the meaningful byte
    mov  local.tmp1, INTC_SECR0+2
    lbco local.tmp2, C0, local.tmp1, 1
    and  local.tmp2, local.tmp2, 0b100100

    // write 1 to clear bits
    sbco local.tmp2, C0, local.tmp1, 1
    jmp  end
pru1:
    mov  local.tmp1, INTC_SECR0+2
    lbco local.tmp2, C0, local.tmp1, 1
    and  local.tmp2, local.tmp2, 0b1000010

    // write 1 to clear bits
    sbco local.tmp2, C0, local.tmp1, 1
end:
.endm

// other way of clearing interrupts is writing intc into SICR


///
// entry point
//

start:

    // enable OCP by clearing bit 4 STANDBY_INIT of SYSCFG reg
    lbco r0, PRU_ICSS_CFG, CFG_SYSCFG, 4
    clr  r0, r0, 4
    sbco r0, PRU_ICSS_CFG, CFG_SYSCFG, 4


.enter main_scope
    .assign Sample, r17, *, sample
    .assign Local, r20, *, local

    mov local.reg_zero, 0
    mov local.store_addr, 4

    .assign Result, r16, *, result 
    mov result.size, 0

    // if needed load init data from ARM like:
    // LBCO result, local.reg_zero, 0, 4

    // initial state = 0
    load_sample sample, local
    store_sample sample, local, result

    // trigger int pru1->pru0
    mov  r31.b0, PRU1_PRU0_INTERRUPT+16
    // it takes ~5 cycles for intc to propagate back to r31
    // delay 2, local
    // PRU1_PRU0_INTERRUPT=18 sets bit 30 of r31 (with default mapping)
    // also sets bit 18 of SECR0 that needs clearing
    // indented as PRU0 wait for interrupt
    wbs r31, 30

    load_sample sample, local
    store_sample sample, local, result
    clear_intc_for_pru 0, local
    // clear_intc local (sledge hammer)
    wbc  r31, 30

    // trigger int pru0->pru1
    mov R31.b0, PRU0_PRU1_INTERRUPT+16
    // PRU0_PRU1_INTERRUPT=17 sets bit 31 of r31 (with default mapping)
    // also sets bit 17 of SECR0 that needs clearing
    // indented as PRU1 wait for interrupt
    wbs r31, 31

    load_sample sample, local
    store_sample sample, local, result
    clear_intc_for_pru 1, local
    wbc  r31, 31

    // Send notification to Host and try to spy on it
    mov  r31.b0, PRU0_ARM_INTERRUPT+PRU_NUM+16
    delay 2, local
    load_sample sample, local
    store_sample sample, local, result

    // wait for int from host
    wbs  r31, 30
    load_sample sample, local
    store_sample sample, local, result
    clear_intc_for_pru 0, local
    // wait for r31:30 to clear
    wbc  r31, 30

    // end
    load_sample sample, local
    store_sample sample, local, result

    sbbo result.size, local.reg_zero, 0, 4


.leave main_scope

    // Send notification to Host for program completion
    mov R31.b0, PRU0_ARM_INTERRUPT+PRU_NUM+16
    halt
