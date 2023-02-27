#include <stdint.h>
#include <math.h>
#include "uart.h"

#define REG_WR(reg_name, wr_data)                   (*((volatile uint32_t *)(reg_name##_ADDR)) = (wr_data))
#define REG_RD(reg_name)                            (*((volatile uint32_t *)(reg_name##_ADDR)))

#define FIELD_MASK(reg_name, field_name)            ( ((1<<(reg_name##_##field_name##_FIELD_LENGTH))-1) << (reg_name##_##field_name##_FIELD_START))

#define REG_WR_FIELD(reg_name, field_name, wr_data) (*((volatile uint32_t *)(reg_name##_ADDR)) = \
                                                                ((REG_RD(reg_name) \
                                                                & ~FIELD_MASK(reg_name, field_name)) \
                                                                | (((wr_data)<<(reg_name##_##field_name##_FIELD_START)) & FIELD_MASK(reg_name, field_name))))

#define REG_RD_FIELD(reg_name, field_name)          ((REG_RD(reg_name) & FIELD_MASK(reg_name, field_name)) >> (reg_name##_##field_name##_FIELD_START))

#define MEM_WR(mem_name, wr_addr, wr_data)          (*( (volatile uint32_t *)(mem_name##_ADDR) + (wr_addr)) = (wr_data))

#define MEM_RD(mem_name, rd_addr)                   (*((volatile uint32_t *)((mem_name##_ADDR) + ((rd_addr) << 2))))

#define JTAG_UART_DATA_ADDR         0x00010200

#define JTAG_UART_DATA_DATA_FIELD_START                         0
#define JTAG_UART_DATA_DATA_FIELD_LENGTH                        8

#define JTAG_UART_DATA_RVALID_FIELD_START                       15
#define JTAG_UART_DATA_RVALID_FIELD_LENGTH                      1

#define JTAG_UART_DATA_RAVAIL_FIELD_START                       16
#define JTAG_UART_DATA_RAVAIL_FIELD_LENGTH                      16

#define JTAG_UART_CONTROL_ADDR      0x00010204

#define JTAG_UART_CONTROL_RE_FIELD_START                        0
#define JTAG_UART_CONTROL_RE_FIELD_LENGTH                       1

#define JTAG_UART_CONTROL_WE_FIELD_START                        1
#define JTAG_UART_CONTROL_WE_FIELD_LENGTH                       1

#define JTAG_UART_CONTROL_RI_FIELD_START                        8
#define JTAG_UART_CONTROL_WI_FIELD_LENGTH                       1

#define JTAG_UART_CONTROL_AC_FIELD_START                        9
#define JTAG_UART_CONTROL_AC_FIELD_LENGTH                       1

#define JTAG_UART_CONTROL_WSPACE_FIELD_START                    16
#define JTAG_UART_CONTROL_WSPACE_FIELD_LENGTH                   16

// Check if that JTAG UART is supported by the design.
static inline int has_jtag_uart()
{
    return 1;
}

// Transmit 1 character
void jtag_uart_tx_char(const char c)
{
    uint32_t val;

    if (!has_jtag_uart())
        return;

    // Stall until there's space in the write FIFO
    while((val = REG_RD_FIELD(JTAG_UART_CONTROL, WSPACE)) == 0);
    REG_WR(JTAG_UART_DATA, c);
}

// Transmit a zero-terminated string
void jtag_uart_tx_str(const char *str)
{
    while(*str != 0){
        jtag_uart_tx_char(*str);
        ++str;
    }
}

// Receive 1 character, if there is one
int jtag_uart_rx_get_char(uint8_t *c)
{
    if (!has_jtag_uart())
        return 0;

    int data = REG_RD(JTAG_UART_DATA);

    if ( ((data >> JTAG_UART_DATA_RVALID_FIELD_START)&1) ){
        *c = data & 255;
        return 1UL;
    }
    else{
        return 0UL;
    }
}
