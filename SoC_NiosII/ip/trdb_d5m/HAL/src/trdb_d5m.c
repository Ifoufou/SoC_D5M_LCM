#include "trdb_d5m.h"
#include "trdb_d5m_regs.h"

#include "system.h"

trdb_d5m_dev trdb_d5m_inst(void     *cmos_sensor_acquisition_cmos_sensor_input_base,
                           uint8_t  cmos_sensor_acquisition_cmos_sensor_input_pix_depth,
                           uint32_t cmos_sensor_acquisition_cmos_sensor_input_max_width,
                           uint32_t cmos_sensor_acquisition_cmos_sensor_Input_max_height,
                           uint32_t cmos_sensor_acquisition_cmos_sensor_input_output_width,
                           uint32_t cmos_sensor_acquisition_cmos_sensor_input_fifo_depth,
                           bool     cmos_sensor_acquisition_cmos_sensor_input_debayer_enable,
                           bool     cmos_sensor_acquisition_cmos_sensor_input_pack_enable,
                           void     *cmos_sensor_acquisiton_sgdma_csr_base,
                           void     *cmos_sensor_acquisiton_sgdma_descriptor_base,
                           uint32_t cmos_sensor_acquisition_msgdma_descriptor_fifo_depth,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_burst_enable,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_burst_wrapping_support,
                           uint32_t cmos_sensor_acquisition_msgdma_csr_data_fifo_depth,
                           uint32_t cmos_sensor_acquisition_msgdma_csr_data_width,
                           uint32_t cmos_sensor_acquisition_msgdma_csr_max_burst_count,
                           uint32_t cmos_sensor_acquisition_msgdma_csr_max_byte,
                           uint64_t cmos_sensor_acquisition_msgdma_csr_max_stride,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_programmable_burst_enable,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_stride_enable,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_enhanced_features,
                           uint8_t  cmos_sensor_acquisition_msgdma_csr_response_port,
                           void     *i2c_base) {

    trdb_d5m_dev dev;

    dev.cmos_sensor_acquisition = cmos_sensor_acquisition_inst(cmos_sensor_acquisition_cmos_sensor_input_base,
                                                               cmos_sensor_acquisition_cmos_sensor_input_pix_depth,
                                                               cmos_sensor_acquisition_cmos_sensor_input_max_width,
                                                               cmos_sensor_acquisition_cmos_sensor_Input_max_height,
                                                               cmos_sensor_acquisition_cmos_sensor_input_output_width,
                                                               cmos_sensor_acquisition_cmos_sensor_input_fifo_depth,
                                                               cmos_sensor_acquisition_cmos_sensor_input_debayer_enable,
                                                               cmos_sensor_acquisition_cmos_sensor_input_pack_enable,
                                                               cmos_sensor_acquisiton_sgdma_csr_base,
                                                               cmos_sensor_acquisiton_sgdma_descriptor_base,
                                                               cmos_sensor_acquisition_msgdma_descriptor_fifo_depth,
                                                               cmos_sensor_acquisition_msgdma_csr_burst_enable,
                                                               cmos_sensor_acquisition_msgdma_csr_burst_wrapping_support,
                                                               cmos_sensor_acquisition_msgdma_csr_data_fifo_depth,
                                                               cmos_sensor_acquisition_msgdma_csr_data_width,
                                                               cmos_sensor_acquisition_msgdma_csr_max_burst_count,
                                                               cmos_sensor_acquisition_msgdma_csr_max_byte,
                                                               cmos_sensor_acquisition_msgdma_csr_max_stride,
                                                               cmos_sensor_acquisition_msgdma_csr_programmable_burst_enable,
                                                               cmos_sensor_acquisition_msgdma_csr_stride_enable,
                                                               cmos_sensor_acquisition_msgdma_csr_enhanced_features,
                                                               cmos_sensor_acquisition_msgdma_csr_response_port);
    dev.i2c = i2c_inst(i2c_base);

    return dev;
}

bool trdb_d5m_configure(trdb_d5m_dev *dev,
                        uint16_t column_size, uint16_t row_size,
                        uint16_t row_bin, uint16_t row_skip,
                        uint16_t column_bin, uint16_t column_skip,
                        bool     continuous) {
    uint16_t buffer = 0;
    uint16_t write_data = 0;
    bool success = true;

    /* TRDB_D5M_COLUMN_SIZE_REG */
    write_data = TRDB_D5M_COLUMN_SIZE_REG_WRITE(buffer, column_size);
    success &= trdb_d5m_write(dev, TRDB_D5M_COLUMN_SIZE_REG, write_data);

    /* TRDB_D5M_ROW_SIZE_REG */
    write_data = TRDB_D5M_ROW_SIZE_REG_WRITE(buffer, row_size);
    success &= trdb_d5m_write(dev, TRDB_D5M_ROW_SIZE_REG, write_data);

    /* TRDB_D5M_ROW_ADDRESS_MODE_REG */
    success &= trdb_d5m_read(dev, TRDB_D5M_ROW_ADDRESS_MODE_REG, &buffer);
    write_data = TRDB_D5M_ROW_ADDRESS_MODE_REG_ROW_BIN_WRITE(buffer, row_bin) | TRDB_D5M_ROW_ADDRESS_MODE_REG_ROW_SKIP_WRITE(buffer, row_skip);
    success &= trdb_d5m_write(dev, TRDB_D5M_ROW_ADDRESS_MODE_REG, write_data);

    /* TRDB_D5M_COLUMN_ADDRESS_MODE_REG */
    success &= trdb_d5m_read(dev, TRDB_D5M_COLUMN_ADDRESS_MODE_REG, &buffer);
    write_data = TRDB_D5M_COLUMN_ADDRESS_MODE_REG_COLUMN_BIN_WRITE(buffer, column_bin) | TRDB_D5M_COLUMN_ADDRESS_MODE_REG_COLUMN_SKIP_WRITE(buffer, column_skip);
    success &= trdb_d5m_write(dev, TRDB_D5M_COLUMN_ADDRESS_MODE_REG, write_data);

    /* TRDB_D5M_READ_MODE_1_REG */
    success &= trdb_d5m_read(dev, TRDB_D5M_READ_MODE_1_REG, &buffer);
    write_data = TRDB_D5M_READ_MODE_1_REG_SNAPSHOT_WRITE(buffer, continuous ? 0 : 1);
    success &= trdb_d5m_write(dev, TRDB_D5M_READ_MODE_1_REG, write_data);
    
    /* TRDB_D5M_SHUTTER_WIDTH_LOWER_REG */
    // max 478 for 77.4 fps at PIXCLK=96 Mhz
    // 0x797 default value
    write_data = TRDB_D5M_SHUTTER_WIDTH_LOWER_REG_WRITE(buffer, 0x797);
    success &= trdb_d5m_write(dev, TRDB_D5M_SHUTTER_WIDTH_LOWER_REG, write_data);

    // enter standby mode
    //success &= trdb_d5m_read(dev, TRDB_D5M_OUTPUT_CONTROL_REG_DEFAULT, &buffer);
    //write_data = TRDB_D5M_OUTPUT_CONTROL_REG_CHIP_ENABLE_WRITE(buffer, 0);
    //success &= trdb_d5m_write(dev, TRDB_D5M_OUTPUT_CONTROL_REG_DEFAULT, write_data);
    
    usleep(1);
    
    /*
     *  Internal D5M PLL Configuration
     *  Goal: obtain PIXCLK=96Mhz from XCLKIN=24Mhz
     *  PIXCLK = 24 x 72 / (6 x 3) = 96 Mhz
     */ 
    // retrieve the already setted default content (0x0050)
    success &= trdb_d5m_read(dev, TRDB_D5M_PLL_CONTROL_REG, &buffer);
    
    // power-up pll but don't use it now
    write_data = TRDB_D5M_PLL_CONTROL_REG_POWER_PLL_WRITE(buffer, 1) | TRDB_D5M_PLL_CONTROL_REG_USE_PLL_WRITE(buffer, 0);
    //success &= trdb_d5m_write(dev, TRDB_D5M_PLL_CONTROL_REG, 0x0051);
    // set factor (0x48=72) and first divider (0x5 => 6, PLL_n_divider+1)
    success &= trdb_d5m_read(dev, TRDB_D5M_PLL_CONFIG_1_REG, &buffer);
    write_data = TRDB_D5M_PLL_CONFIG_1_REG_PLL_M_FACTOR_WRITE(buffer, 0x48) | TRDB_D5M_PLL_CONFIG_1_REG_PLL_N_DIVIDER_WRITE(buffer, 0x05);
    //success &= trdb_d5m_write(dev, TRDB_D5M_PLL_CONFIG_1_REG, 0x4805);
    // set second divider (0x2 => 3, PLL_p1_divider+1)
    success &= trdb_d5m_read(dev, TRDB_D5M_PLL_CONFIG_2_REG, &buffer);
    write_data = TRDB_D5M_PLL_CONFIG_2_REG_PLL_P1_DIVIDER_WRITE(buffer, 0x02);
    //success &= trdb_d5m_write(dev, TRDB_D5M_PLL_CONFIG_2_REG, 0x0002);
    // wait 1ms for VCO to lock (see doc)
    usleep(1);
    // maintain the power-up and trigger the usage now
    success &= trdb_d5m_read(dev, TRDB_D5M_PLL_CONTROL_REG, &buffer);
    write_data = TRDB_D5M_PLL_CONTROL_REG_POWER_PLL_WRITE(buffer, 1) | TRDB_D5M_PLL_CONTROL_REG_USE_PLL_WRITE(buffer, 1);
    //success &= trdb_d5m_write(dev, TRDB_D5M_PLL_CONTROL_REG, 0x0053);
    usleep(1);
    
    // leave standbye
    //success &= trdb_d5m_read(dev, TRDB_D5M_OUTPUT_CONTROL_REG_DEFAULT, &buffer);
    //write_data = TRDB_D5M_OUTPUT_CONTROL_REG_CHIP_ENABLE_WRITE(buffer, 0);
    //success &= trdb_d5m_write(dev, TRDB_D5M_OUTPUT_CONTROL_REG_DEFAULT, write_data);
    
    usleep(1);

    cmos_sensor_acquisition_configure(&dev->cmos_sensor_acquisition);

    return success;
}

void trdb_d5m_init(trdb_d5m_dev *dev, uint32_t i2c_freq) {
    cmos_sensor_acquisition_init(&dev->cmos_sensor_acquisition);
    i2c_init(&dev->i2c, i2c_freq);
}

bool trdb_d5m_write(trdb_d5m_dev *dev, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(&dev->i2c, TRDB_D5M_I2C_WRITE_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

bool trdb_d5m_read(trdb_d5m_dev *dev, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(&dev->i2c, TRDB_D5M_I2C_READ_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}

/*
 * trdb_d5m_snapshot
 *
 * Performs a blocking snapshot operation.
 *
 * Returns true if the frame was successfully saved, and false otherwise.
 */
bool trdb_d5m_snapshot(trdb_d5m_dev *dev, void *frame, size_t frame_size) {
    return cmos_sensor_acquisition_snapshot(&dev->cmos_sensor_acquisition, frame, frame_size);
}

void trdb_d5m_cam_loop(trdb_d5m_dev *dev, void *frame, size_t frame_size) {
    return cmos_sensor_acquisition_loop(&dev->cmos_sensor_acquisition, frame, frame_size);
}

/*
 * trdb_d5m_frame_size
 *
 * Returns the total size of a frame in bytes outputted by the camera unit in
 * its current configuration.
 */
size_t trdb_d5m_frame_size(trdb_d5m_dev *dev) {
    return cmos_sensor_acquisition_frame_size(&dev->cmos_sensor_acquisition);
}

/*
 * trdb_d5m_frame_width
 *
 * Returns the width of a frame in pixels.
 */
uint32_t trdb_d5m_frame_width(trdb_d5m_dev *dev) {
    return cmos_sensor_acquisition_frame_width(&dev->cmos_sensor_acquisition);
}

/*
 * trdb_d5m_frame_height
 *
 * Returns the height of a frame in pixels.
 */
uint32_t trdb_d5m_frame_height(trdb_d5m_dev *dev) {
    return cmos_sensor_acquisition_frame_height(&dev->cmos_sensor_acquisition);
}
