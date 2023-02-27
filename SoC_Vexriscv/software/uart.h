#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stdbool.h>

/* Status register */
#define UART_PE   0x0001
#define UART_FE   0x0002
#define UART_BRK  0x0004
#define UART_ROE  0x0008
#define UART_TOE  0x0010
#define UART_TMT  0x0020
#define UART_TRDY 0x0040
#define UART_RRDY 0x0080
#define UART_E    0x0100
#define UART_BIT9 0x0200
#define UART_DCTS 0x0400
#define UART_CTS  0x0800
#define UART_EOP  0x1000

void jtag_uart_tx_char(const char c);
void jtag_uart_tx_str(const char *str);
int  jtag_uart_rx_get_char(uint8_t *c);

#endif // Uart_H
