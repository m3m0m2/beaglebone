.origin start
.entrypoint start

#include "config.h"
#include "digcapture.hp"


.struct MemBuffer
    .u32    start_addr
    .u32    end_addr
.ends


start:

    // Configure the block index register for PRU0 by setting c24_blk_index[7:0] and
    // c25_blk_index[7:0] field to 0x00 and 0x00, respectively.  This will make C24 point
    // to 0x00000000 (PRU0 DRAM) and C25 point to 0x00002000 (PRU1 DRAM).
    MOV     r0, 0x00000000
    MOV     r1, CTBIR_0
    SBBO    r0, r1, 0, 4

    // load PRU_ICSS_CFG.SYSCFG register
    LBCO r0, PRU_ICSS_CFG, SYSCFG, 4
    // enable OCP by clearing bit 4 STANDBY_INIT
    CLR r0, r0, 4
    // store updated value in PRU_ICSS_CFG.SYSCFG register
    SBCO r0, PRU_ICSS_CFG, SYSCFG, 4


.enter init_scope
    .assign MemBuffer, r5, r6, ext_mem


    // read MemBuffer data passed by ARM
    MOV     r1, 0
    LBBO    ext_mem, r1, 0, SIZE(ext_mem)

    // read next data passed into r0
    LBBO    r0, r1, 8, 4

    // increment r0
    ADD     r1, r0, #1

    //Load address of PRU data memory in r2
    MOV       r2, 0x000C

    // write start_addr to ARM just for debug
    SBBO    ext_mem.start_addr, r2, 0, 4
    // write to ext_mem
    //SBBO    r1, r2, 0, 4
// maybe crash if OCP not enabled
    SBBO    r1, ext_mem.start_addr, 0, 4

.leave init_scope

    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+PRU_NUM+16

    HALT
