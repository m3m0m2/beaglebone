/*
 * @brief PRU assembly to use McSpi perhiperal
 * @author Mauro Meneghin <m3m0m2@gmail.com>
 */

.origin 0
.entrypoint start

#include "config.h"
#include "pru.hp"

#define PRU_NUM PRU_SPI_NUM



.struct WorkData
    .u32    reg_zero
    .u32    data_out
    .u32    value
    .u32    addr
    .u32    tmp1
    .u32    tmp2
.ends

///
// macros
//

.macro mcspi_read_sysconfig
.mparam work_data
    mov     work_data.addr, MCSPI_SYSCONFIG
    lbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_write_sysconfig
.mparam work_data
    mov     work_data.addr, MCSPI_SYSCONFIG
    sbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_read_sysstatus
.mparam work_data
    mov     work_data.addr, MCSPI_SYSSTATUS
    lbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_write_sysstatus
.mparam work_data
    mov     work_data.addr, MCSPI_SYSSTATUS
    sbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_read_irqstatus
.mparam work_data
    //lbco    data, CONST_MCSPI0, MCSPI_IRQSTATUS , 4
    mov     work_data.addr, MCSPI_IRQSTATUS
    lbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_write_irqstatus
.mparam work_data
    //sbco    data, CONST_MCSPI0, MCSPI_IRQSTATUS, 4
    mov     work_data.addr, MCSPI_IRQSTATUS
    sbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_read_modulctrl
.mparam work_data
    //lbco    data, CONST_MCSPI0, MCSPI_MODULCTRL, 4
    mov     work_data.addr, MCSPI_MODULCTRL
    lbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_write_modulctrl
.mparam work_data
    //sbco    data, CONST_MCSPI0, MCSPI_MODULCTRL, 2
    mov     work_data.addr, MCSPI_MODULCTRL
    sbbo    work_data.value, work_data.addr, 0, 2
.endm


.macro mcspi_read_conf_ch0
.mparam work_data
    //lbco    data, CONST_MCSPI0, MCSPI_CH0CONF, 4
    mov     work_data.addr, MCSPI_CH0CONF
    lbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_write_conf_ch0
.mparam work_data
    //sbco    data, CONST_MCSPI0, MCSPI_CH0CONF, 4
    mov     work_data.addr, MCSPI_CH0CONF
    sbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_read_stats_ch0
.mparam work_data
    mov     work_data.addr, MCSPI_CH0STAT 
    lbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_activate_ch0
.mparam work_data
    //lbco    tmp1, CONST_MCSPI0, MCSPI_CH0CTRL, 4
    mov     work_data.addr, MCSPI_CH0CTRL
    lbbo    work_data.value, work_data.addr, 0, 4
    set     work_data.value, 0
    //sbco    tmp1, CONST_MCSPI0, MCSPI_CH0CTRL, 4
    sbbo    work_data.value, work_data.addr, 0, 4
.endm

.macro mcspi_deactivate_ch0
.mparam work_data
    //lbco    tmp1, CONST_MCSPI0, MCSPI_CH0CTRL, 4
    mov     work_data.addr, MCSPI_CH0CTRL
    lbbo    work_data.value, work_data.addr, 0, 4
    clr     work_data.value, 0
    //sbco    tmp1, CONST_MCSPI0, MCSPI_CH0CTRL, 4
    sbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_write_ctrl_ch0
.mparam work_data
    //sbco    data, CONST_MCSPI0, MCSPI_CH0CTRL, 2
    mov     work_data.addr, MCSPI_CH0CTRL
    sbbo    work_data.value, work_data.addr, 0, 2
.endm




.macro mcspi_write_data_ch0
.mparam work_data
    //sbco    data, CONST_MCSPI0, MCSPI_TX0, 4
    mov     work_data.addr, MCSPI_TX0
    sbbo    work_data.value, work_data.addr, 0, 4
.endm


.macro mcspi_read_data_ch0
.mparam work_data
    //lbco    data, CONST_MCSPI0, MCSPI_RX0, 4
    mov     work_data.addr, MCSPI_RX0
    lbbo    work_data.value, work_data.addr, 0, 4
.endm


// TODO: maybe set MCSPI_XFERLEVEL[WCNT] = 1 so fifo sends only 1 word att


///
// entry point
//

start:

    // enable OCP by clearing bit 4 STANDBY_INIT of SYSCFG reg
    lbco r0, CONST_PRUSSCFG, CFG_SYSCFG, 4
    clr  r0, r0, 4
    sbco r0, CONST_PRUSSCFG, CFG_SYSCFG, 4


.enter main_scope
    MOV     r0, 0

    // setup work variables
    .assign WorkData, r16, *, work_data 
    lbbo    work_data, r0, 0, SIZE(work_data)
    mov     work_data.reg_zero, 0
    mov     work_data.data_out, 4

    mcspi_read_sysconfig work_data
    // set bit SYSCONFIG:SOFTRESET to trigger software reset
    // default seems to be: 0x15
    // 9-8 CLOCKACTIVITY  3h = OCP and Functional clocks are maintained.
    // 7-5 RESERVED
    // 4-3 SIDLEMODE 1h = If an idle request is detected, the request is ignored
    // 2 RESERVED
    // 1 SOFTRESET
    // 0 AUTOIDLE 0h = OCP clock is free-running.
    //                   09876543210
    //mov work_data.value,0b1100001010 
    //set     work_data.value, 1
    mov work_data.value,0x17
    mcspi_write_sysconfig work_data

//debug
    sbbo work_data.value, work_data.data_out, 0, 4
    add  work_data.data_out, work_data.data_out, 4

wait_for_reset:
    mcspi_read_sysstatus    work_data
    // wait until bit 0 is set
    qbbc    wait_for_reset, work_data.value, 0


    // reg MCSPI_MODULCTRL
    // bit val name/description
    //  8   0 FDAA: no DMA (FIFO data managed by MCSPI_TX(i) and MCSPI_RX(i))
    //  7   0 MOA: no multiple words in fifo
    //  6-4 0 INITDLY: no Initial SPI delay for first transfer
    //  3   0 SYSTEM_TEST: no test mode
    //  2   0 MS: master mode
    //  1   0 PIN34: use SPIEN as chip select (CS)
    //  0   1 Single: 0=multiple channels used, 1=single channel
    mov     work_data.value, 0b000000001
    mcspi_write_modulctrl   work_data

    mov  work_data.addr, MCSPI_REVISION
    lbbo work_data.value, work_data.addr, 0, 4
    sbbo work_data.value, work_data.data_out, 0, 4
    add  work_data.data_out, work_data.data_out, 4


    // reg MCSPI_CH0CONF
    // bit  val description
    // 29 1 CLKG: clock divider, 0h = Clock granularity of power of 2
    // 28 1 FFER: 1h = fifo buffer is used to receive data.
    // 27 1 FFEW: 1h = fifo buffer is used to transmit data.
    // 26-25 0 TCS: time between cs change and spi edge, 1h = 1.5 clock cycles
    // 24 1 SBPOL: 1h = Start bit polarity is held to 1 during SPI transfer.
    // 23 0 SBE R/W: 0h = Default SPI transfer length as specified by WL bit field.
    // 22-21 0 SPIENSLV: slave/ignore
    // 20 0? FORCE R/W: 
    // 19 0 TURBO: 0h = Turbo is deactivated (recommended for single SPI word
    // 18 0 IS: 0h = Data line 0 (SPIDAT[0]) selected for reception.
    // 17 0 DPE1: 0h = Data line 1 (SPIDAT[1]) selected for transmission
    // 16 1 DPE0: 1h = No transmission on data line 0 (SPIDAT[0])
    // 15 0 DMAR: 0h = DMA read request is disabled.
    // 14 0 DMAW: 0h = DMA write request is disabled.
    // 13-12 0 TRM: 0h = Transmit and receive mode
    // 11-7 9 WL: The SPI word is 10-bits long
    // 6  1 EPOL: 1h = SPIEN is held low during the active state.
    // ##5-2  Fh CLKD: with CLKG=1 clock=1+EXTCLK+15, see EXTCLK below to give 1MHz
    // 5-2  0 CLKD: with CLKG=1 clock=1+EXTCLK+15, see EXTCLK below to give 1MHz
    // 1  0 POL: polarity 0h = SPICLK is held high during the active state
    // 0  0 PHA: phase 0h = Data are latched on odd numbered edges of SPICLK (rising edge)
    //                         987654321098765432109876543210
    //mov     work_data.value, 0b111001000000010000010011000000
    mov     work_data.value, 0b111001000100010000010011000000
    mcspi_write_conf_ch0    work_data


    // reg MCSPI_CH0CTRL
    // bit  val description
    // 15-8 2 EXTCLK: clock divider with 1 granularity
    //      if CLKG=1 divisor = 1 + EXTCLK*16 + CLKD = 1+2*16+15=48, so CLKSPIREF=48MHz/48=1MHz
    //      48 = 1 + 2*16 + 15
    // 0    1 EN: enable channel 0
    //                98765432109876543210
    mov     work_data.value, 0b01000000001
    mcspi_write_ctrl_ch0    work_data

nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
//debug
    mcspi_read_stats_ch0 work_data
    sbbo work_data.value, work_data.data_out, 0, 4
    add  work_data.data_out, work_data.data_out, 4
    // TODO: wait for TXS empty


    // spi tx word
    // 1: start bit
    // 1: single 
    // 000: ch0
    // wait, tx 11000 
    mov     work_data.value, 0b11000
    mcspi_write_data_ch0 work_data

nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
//debug
    mcspi_read_stats_ch0 work_data
    sbbo work_data.value, work_data.data_out, 0, 4
    add  work_data.data_out, work_data.data_out, 4

wait_response:
    // bit
    // 6    RXFFF   FIFO receive buffer full
    // 5    RXFFE   FIFO receive buffer empty
    // 4    TXFFF   FIFO transmit buffer full
    // 3    TXFFE   FIFO transmit buffer empty
    // 2    EOT     end-of-transfer
    // 1    TXS     1 = transmitter register is empty
    // 0    RXS     1 = receiver register is full
    mcspi_read_stats_ch0 work_data
    //qbbc    wait_response, work_data.value, 0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0
nop0    r0,r0,r0

    // alternative
    // bit  
    // 0    RX0_OVERFLOW
    // 1    RX0_FULL
    // 2    TX0_UNDERFLOW
    // 3    TX0_EMPTY
    //mcspi_read_irqstatus


    // read received spi word
    mcspi_read_data_ch0 work_data

    // write read value to mem[1]
    sbbo work_data.value, work_data.data_out, 0, 4

    // write # of wors written to mem[0]
    lsr work_data.data_out, work_data.data_out, 2
    sbbo work_data.data_out, work_data.reg_zero, 0, 4

    mcspi_deactivate_ch0    work_data


.leave main_scope

    // Send notification to Host for program completion
    mov r31.b0, PRU0_ARM_INTERRUPT+PRU_NUM+16

    halt
