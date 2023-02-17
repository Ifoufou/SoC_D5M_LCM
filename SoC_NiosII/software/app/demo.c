#include <stdbool.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

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


uint16_t max_pixel_value(uint16_t *frame, uint32_t width, uint32_t height) {
    uint16_t max = 0;

    for (uint32_t row = 0; row < height; row++) {
        for (uint32_t col = 0; col < width; col++) {
            uint16_t current = frame[row * width + col];
            if (current > max) {
                max = current;
            }
        }
    }

    return max;
}

bool write_ppm(uint16_t *frame, uint32_t width, uint32_t height, const char *filename) {
    FILE *foutput = fopen(filename, "w");
    if (!foutput) {
        printf("Error: could not open \"%s\" for writing\n", filename);
        return false;
    }

    fprintf(foutput, "P3\n"); /* PPM magic number */
    fprintf(foutput, "%" PRIu32 " %" PRIu32 "\n", width, height); /* frame dimensions */
    fprintf(foutput, "%" PRIu16 "\n", max_pixel_value(frame, width, height)); /* max value */
    
    for (uint32_t row = 0; row < height; row++) {
        for (uint32_t col = 0; col < width; col++) {
            if (row % 2 == 0 && col % 2 == 0) {
                /* even row, even col = G1 */
                fprintf(foutput, "%05" PRIu16 " ", 0);                        /* R */
                fprintf(foutput, "%05" PRIu16 " ", frame[row * width + col]); /* G */
                fprintf(foutput, "%05" PRIu16    , 0);                        /* B */
            } else if (row % 2 == 0 && col % 2 == 1) {
                /* even row, odd col = R */
                fprintf(foutput, "%05" PRIu16 " ", frame[row * width + col]); /* R */
                fprintf(foutput, "%05" PRIu16 " ", 0);                        /* G */
                fprintf(foutput, "%05" PRIu16    , 0);                        /* B */
            } else if (row % 2 == 1 && col % 2 == 0) {
                /* odd row, even col = B */
                fprintf(foutput, "%05" PRIu16 " ", 0);                        /* R */
                fprintf(foutput, "%05" PRIu16 " ", 0);                        /* G */
                fprintf(foutput, "%05" PRIu16    , frame[row * width + col]); /* B */
            } else if (row % 2 == 1 && col % 2 == 1) {
                /* odd row, odd col = G2 */
                fprintf(foutput, "%05" PRIu16 " ", 0);                        /* R */
                fprintf(foutput, "%05" PRIu16 " ", frame[row * width + col]); /* G */
                fprintf(foutput, "%05" PRIu16    , 0);                        /* B */
            }
            if (col != (width - 1)) {
                fprintf(foutput, " ");
            }
        }
        if (row != (height - 1)) {
            fprintf(foutput, "\n");
        }
    }

    if (fclose(foutput)) {
        printf("Error: could not close \"%s\"\n", filename);
        return false;
    }

    return true;
}

uint8_t max_pixel_value_rgb(uint8_t *frame, uint32_t width, uint32_t height) {
    uint8_t max = 0;
    
    uint32_t height_rgb = height;
    uint32_t width_rgb  = width *4;
    
    for (uint32_t row_rgb = 0; row_rgb < height_rgb; row_rgb++) {
        for (uint32_t col_rgb = 0; col_rgb < width_rgb; col_rgb++) {
            // Skip the fourth value, as it is just padding inserted
            // for the frame transmission.
            if (col_rgb % 4 == 3)
                continue;
            uint8_t current = frame[row_rgb * width_rgb + col_rgb];
            if (current > max)
                max = current;
        }
    }

    return max;
}

bool write_ppm_rgb(uint8_t *frame, uint32_t width, uint32_t height, const char *filename) {
    FILE *foutput = fopen(filename, "w");
    if (!foutput) {
        printf("Error: could not open \"%s\" for writing\n", filename);
        return false;
    }

    fprintf(foutput, "P3\n"); /* PPM magic number */
    fprintf(foutput, "%" PRIu32 " %" PRIu32 "\n", width, height); /* frame dimensions */
    fprintf(foutput, "%" PRIu8 "\n", max_pixel_value_rgb(frame, width, height)); /* max value */
    
    uint32_t height_rgb = height;
    uint32_t width_rgb  = width *4;

    for (uint32_t row_rgb = 0; row_rgb < height_rgb; row_rgb+=1)
    {
        for (uint32_t col_rgb = 0; col_rgb < width_rgb; col_rgb+=4)
        {
            fprintf(foutput, "%" PRIu8 " ", frame[row_rgb * width_rgb + col_rgb + 2]); /* R */
            fprintf(foutput, "%" PRIu8 " ", frame[row_rgb * width_rgb + col_rgb + 1]); /* G */
            fprintf(foutput, "%" PRIu8 " ", frame[row_rgb * width_rgb + col_rgb]);     /* B */

            if (col_rgb < (width_rgb - 4)) {
                fprintf(foutput, " ");
            }
        }

        if (row_rgb != (height_rgb - 1)) {
            fprintf(foutput, "\n");
        }
    }

    if (fclose(foutput)) {
        printf("Error: could not close \"%s\"\n", filename);
        return false;
    }

    return true;
}

int main(void) {
    printf("test\n");

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
        printf("Error: could not configure trdb_d5m\n");
        return EXIT_FAILURE;
    }

    /*
     * allocate frame memory
     */
    size_t frame_size = trdb_d5m_frame_size(&trdb_d5m);
    printf("size of the frame: %u\n", frame_size);
    
    void *frame = calloc(frame_size, 1);
    if (!frame) {
        printf("Error: could not allocate memory for frame\n");
        return EXIT_FAILURE;
    }

    /*
     * take snapshot
     */
    if (!trdb_d5m_snapshot(&trdb_d5m, frame, frame_size)) {
        printf("Error: could not take snapshot\n");
        return EXIT_FAILURE;
    }

    /*
     * write image to host
     * NOTE: require altera_hostfs to be settled and the usage of gdb-server
     */
    puts("writing image to host");
    /*
    if (!write_ppm_rgb((uint8_t *) frame,
                       trdb_d5m_frame_width(&trdb_d5m), trdb_d5m_frame_height(&trdb_d5m),
                       "/mnt/host/image.ppm")) {
        printf("Error: could not write image to file\n");
        return EXIT_FAILURE;
    }
    
    printf("image normally written!\n");
    */

    alt_up_pixel_buffer_dma_dev * pixel_buf_dma_dev;
    pixel_buf_dma_dev = alt_up_pixel_buffer_dma_open_dev(TRDB_LCM_0_VIDEO_PIXEL_BUFFER_DMA_0_NAME);

    if (pixel_buf_dma_dev == NULL)
        printf("Error: could not open pixel buffer device\n");
    else
        printf("Opened pixel buffer device\n");

    /*
     * change the primary buffer address to the frame address
     *
     */
    // first change the back buffer address
    alt_up_pixel_buffer_dma_change_back_buffer_address(pixel_buf_dma_dev, frame);
    // then swap the buffers (primary <-> back buffer)
    alt_up_pixel_buffer_dma_swap_buffers(pixel_buf_dma_dev);

    while (1) {
        trdb_d5m_snapshot(&trdb_d5m, frame, frame_size);
        puts("frame out");
    }
    return EXIT_SUCCESS;
}
