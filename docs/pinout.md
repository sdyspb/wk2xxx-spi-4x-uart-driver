# WK2124 Pinout Connection Table

| WK2124 Pin | Signal | RK3568 Pin | GPIO | Notes |
|---|---|---|---|---|
| 1 | VCC | 3.3V | — | |
| 2 | GND | GND | — | |
| 3 | SPI_CLK | SPI1_CLK_M1 | — | |
| 4 | SPI_MOSI | SPI1_MOSI_M1 | — | |
| 5 | SPI_MISO | SPI1_MISO_M1 | — | |
| 6 | SPI_CS | SPI1_CS0_M1 | GPIO3_A1 | |
| 7 | IRQ | GPIO0_A6 | GPIO0_A6 | Active low, edge falling |
| 8 | RESET | PCA9555 P9 | — | Active low |
| 9 | XTAL_IN | 11.0592 MHz | — | |
| 10 | XTAL_OUT | — | — | |
| ... | UART0_TX | — | — | |
| ... | UART0_RX | — | — | |
| ... | UART1_TX | — | — | |
| ... | UART1_RX | — | — | |
| ... | UART2_TX | — | — | |
| ... | UART2_RX | — | — | |
| ... | UART3_TX | — | — | |
| ... | UART3_RX | — | — | |

## Notes

- Reference clock: 11.0592 MHz (standard for UART baud rate accuracy)
- SPI mode: 0 (CPOL=0, CPHA=0)
- SPI max frequency: 10 MHz
- All UART channels: 3.3V TTL (not RS-232)
