#include <stdbool.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "altera_up_avalon_video_pixel_buffer_dma.h"

#include "trdb_d5m.h"
#include "system.h"

#define I2C_FREQ (50000000) /* 50 MHz */

#define TRDB_D5M_COLUMN_SIZE_REG_DATA (2559)
#define TRDB_D5M_ROW_SIZE_REG_DATA    (1919)
#define TRDB_D5M_ROW_BIN_REG_DATA     (3)
#define TRDB_D5M_ROW_SKIP_REG_DATA    (3)
#define TRDB_D5M_COLUMN_BIN_REG_DATA  (3)
#define TRDB_D5M_COLUMN_SKIP_REG_DATA (3)

int main(void) 
{
    alt_sys_init();
    
    // Greetings
	jtag_uart_tx_str("\n\n* * * VexRiscv Demo  -  ");
	jtag_uart_tx_str(DBUILD_VERSION);
	jtag_uart_tx_str("  - ");
	jtag_uart_tx_str(DBUILD_DATE);
	jtag_uart_tx_str("  * * *\n");

    /*
     * instantiate camera control structure
     */
    trdb_d5m_dev trdb_d5m = TRDB_D5M_INST(TRDB_D5M_0_CMOS_SENSOR_ACQUISITION_0_CMOS_SENSOR_INPUT_0,
                                          TRDB_D5M_0_CMOS_SENSOR_ACQUISITION_0_MSGDMA_0,
                                          TRDB_D5M_0_I2C_0);

    /*
     * initialize camera
     */
    trdb_d5m_init(&trdb_d5m, I2C_FREQ);

    /*
     * configure camera
     */
    if (!trdb_d5m_configure(&trdb_d5m,
                            TRDB_D5M_COLUMN_SIZE_REG_DATA, TRDB_D5M_ROW_SIZE_REG_DATA,
                            TRDB_D5M_ROW_BIN_REG_DATA, TRDB_D5M_ROW_SKIP_REG_DATA,
                            TRDB_D5M_COLUMN_BIN_REG_DATA, TRDB_D5M_COLUMN_SKIP_REG_DATA,
                            true)) {
        jtag_uart_tx_str("Error: could not configure trdb_d5m\n");
        return EXIT_FAILURE;
    }

    /*
     * allocate frame memory
     */
    size_t frame_size = trdb_d5m_frame_size(&trdb_d5m);
    
    void *frame = calloc(frame_size, 1);
    if (!frame) {
        jtag_uart_tx_str("Error: could not allocate memory for frame\n");
        return EXIT_FAILURE;
    }

    /*
     * take snapshot
     */
    if (!trdb_d5m_snapshot(&trdb_d5m, frame, frame_size)) {
        jtag_uart_tx_str("Error: could not take snapshot\n");
        return EXIT_FAILURE;
    }
    
    alt_up_pixel_buffer_dma_dev * pixel_buf_dma_dev;
    pixel_buf_dma_dev = alt_up_pixel_buffer_dma_open_dev(TRDB_LCM_0_VIDEO_PIXEL_BUFFER_DMA_0_NAME);

    if (pixel_buf_dma_dev == NULL)
        jtag_uart_tx_str("Error: could not open pixel buffer device\n");
    else
        jtag_uart_tx_str("Opened pixel buffer device\n");

    /*
     * change the primary buffer address to the frame address
     *
     */
    // first change the back buffer address
    alt_up_pixel_buffer_dma_change_back_buffer_address(pixel_buf_dma_dev, frame);
    // then swap the buffers (primary <-> back buffer)
    alt_up_pixel_buffer_dma_swap_buffers(pixel_buf_dma_dev);

    trdb_d5m_cam_loop(&trdb_d5m, frame, frame_size);

    return EXIT_SUCCESS;
}
