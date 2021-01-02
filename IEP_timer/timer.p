.origin 0
.entrypoint start

//#include "timer.hp"
#define CONST_IEP            C26
#define PRU0_ARM_INTERRUPT      19

// offset of GLOBAL_CFG register in IEP
#define GLOBAL_CFG      0x00
#define GLOBAL_STATUS   0x04
#define COMPEN          0x08
#define COUNT           0x0c
#define CMP_CFG         0x40
#define CMP_STATUS      0x44
#define CMP0            0x48
#define CMP1            0x4c

.macro enable_timer
.mparam DEFAULT_INC=5, CNT_ENABLE=1, CMP_INC=0
    // CMP_INC = compensation increment
    // DEFAULT_INC 5ns/cycle, so mesures time in ns
    mov  r1.w0, (CMP_INC<<8 | DEFAULT_INC<<4 | CNT_ENABLE)
    sbco r1, CONST_IEP, GLOBAL_CFG, 2
.endm

.macro disable_timer
    // CNT_ENABLE = 0
    mov  r1.w0, 0x0000
    sbco r1, CONST_IEP, GLOBAL_CFG, 2
.endm


.macro has_counter_overflow
    // read overflow bit 0
    lbco r1.b0, CONST_IEP, GLOBAL_STATUS, 1
    and r1, r1, 1
.endm

.macro reset_counter_overflow
    mov  r1.b0, 0x01
    // write 1 to clear overflow bit 0
    sbco r1, CONST_IEP, GLOBAL_STATUS, 1
.endm


.macro disable_compensation
    mov  r1, 0x0
    // clear COMPEN_CNT (3 bytes)
    sbco r1, CONST_IEP, COMPEN, 3
.endm


.macro get_count
    // return count in r1
    lbco r1, CONST_IEP, COUNT, 4
.endm
    

.macro reset_count
    //mov  r1, 0xffffffff
    // despite the doc mentinos W1toCl, does not seem the case
    mov  r1, 0x0
    // write 1 to clear bit
    sbco r1, CONST_IEP, COUNT, 4
.endm


.macro set_CMP_EN
.mparam word
    // pag 262
    // bit 0: auto reset counter on CMP0 event
    // bit 1..8: CMP_EN[i] enable comparison for CMP[i]
    sbco word, CONST_IEP, CMP_CFG, 2
.endm


.macro get_CMP_STATUS
.mparam reg_out
    lbco reg_out, CONST_IEP, CMP_STATUS, 1
.endm
    
.macro set_CMP_STATUS
.mparam byte
    sbco byte, CONST_IEP, CMP_STATUS, 1
.endm

clear_CMP_STATUS_bit:
    lbco r1.b0, CONST_IEP, CMP_STATUS, 1
    // write 1 on bit to clear
    // TODO improve this:
    or r1, r1, r0
    sbco r1.b0, CONST_IEP, CMP_STATUS, 1
    

.macro get_CMP0
    lbco r1, CONST_IEP, CMP0, 4
.endm


.macro set_CMP0
    sbco r1, CONST_IEP, CMP0, 4
.endm

    
.macro get_CMP1
    lbco r1, CONST_IEP, CMP1, 4
.endm

.macro set_CMP1
    sbco r1, CONST_IEP, CMP1, 4
.endm



start:
    // just in case the timer was running
    disable_timer
    disable_compensation
    reset_counter_overflow
    reset_count
    //set_CMP_EN 0x0000

    // enable CMP0 (bit 1) and set CMP_REST_CNT_EN (bit 0)
    mov r1, 3
    set_CMP_EN r1.w0

    // clear CMP_STATUS, just in case
    set_CMP_STATUS #0
    // set 1000 as CMP0 max with rollover
    mov r1, 100000
    set_CMP0

    enable_timer


    mov r2, 0
loop1:
    get_count

    get_CMP_STATUS r3.b0
    // if bit 0 is set, then CMP0 event happend
    qbbc no_store_flag, r3, 0
    set_CMP_STATUS #0
    // set a constant just to recognise this
    mov r1, 10000
no_store_flag:

    // store r1 in memory
    SBBO    r1, r2, #0x04, 4
    add     r2, r2, 4
    qbge loop1, r2, 4*20    // if 40 < r2 end

end:
    mov     r1, 0
    // r4 = r2/4 (shift right twice)
    lsr     r4, r2, 2
    // subtract 1 to r2
    sub     r4, r4, 1
    SBBO    r4, r1, 0, 4

    // hacky, last time, store time
    get_count
    // store r1 in memory
    mov r2, 19*4
    SBBO    r1, r2, 0, 4


    disable_timer
    mov r31.b0, PRU0_ARM_INTERRUPT+16
    halt


