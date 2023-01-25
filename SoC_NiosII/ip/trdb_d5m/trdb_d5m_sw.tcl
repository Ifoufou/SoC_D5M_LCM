#
# trdb_d5m_sw.tcl
#

# Create a new driver
create_driver trdb_d5m

# Associate it with the "cmos_sensor_input" qsys module
# NOTE: there is no instance of the trdb_d5m in the generated set of modules 
#       as Qsys "inlines" the trdb_d5m by its sub-modules.
#       The list of "active" modules can be seen using the nios2-bsp-editor.
set_sw_property hw_class_name cmos_sensor_input

# The version of this driver
set_sw_property version 20.1
#set_sw_property min_compatible_hw_version 1.1

# Initialize the driver in alt_sys_init()
# NOTE: we will make a manual initialization instead
set_sw_property auto_initialize false

# Location in generated BSP that above sources will be copied into
set_sw_property bsp_subdirectory drivers

#
# Source file listings...
#

# Files for trdb_d5m
# C/C++ source files:
add_sw_property c_source HAL/src/trdb_d5m.c
# Include files:
add_sw_property include_directory HAL/inc/
add_sw_property include_source    HAL/inc/trdb_d5m.h
add_sw_property include_directory inc/
add_sw_property include_source    inc/trdb_d5m_regs.h

# Files for ip/cmos_sensor_acquisition
# C/C++ source files:
add_sw_property c_source ip/cmos_sensor_acquisition/HAL/src/cmos_sensor_acquisition.c
# Include files:
add_sw_property include_directory ip/cmos_sensor_acquisition/HAL/inc/
add_sw_property include_source    ip/cmos_sensor_acquisition/HAL/inc/cmos_sensor_acquisition.h

# Files for ip/cmos_sensor_input
# C/C++ source files:
add_sw_property c_source ip/cmos_sensor_input/HAL/src/cmos_sensor_input.c
# Include files:
add_sw_property include_directory ip/cmos_sensor_input/HAL/inc/
add_sw_property include_source    ip/cmos_sensor_input/HAL/inc/cmos_sensor_input.h
add_sw_property include_directory ip/cmos_sensor_input/inc/
add_sw_property include_source    ip/cmos_sensor_input/inc/cmos_sensor_input_io.h
add_sw_property include_source    ip/cmos_sensor_input/inc/cmos_sensor_input_regs.h

# Files for ip/i2c
# C/C++ source files:
add_sw_property c_source ip/i2c/HAL/src/i2c.c
# Include files:
add_sw_property include_directory ip/i2c/HAL/inc/
add_sw_property include_source    ip/i2c/HAL/inc/i2c.h
add_sw_property include_directory ip/i2c/inc/
add_sw_property include_source    ip/i2c/inc/i2c_io.h
add_sw_property include_source    ip/i2c/inc/i2c_regs.h

# Files for ip/msgdma
# NOTE: it seems that Intel modified the C interface of the msgdma in version 20.1
# Thus, we include "manually" an old interface as the system was designed with this one.
# C/C++ source files:
add_sw_property c_source ip/msgdma/HAL/src/msgdma.c
# Include files:
add_sw_property include_directory ip/msgdma/HAL/inc/
add_sw_property include_source    ip/msgdma/HAL/inc/msgdma.h
add_sw_property include_directory ip/msgdma/inc/
add_sw_property include_source    ip/msgdma/inc/msgdma_csr_regs.h
add_sw_property include_source    ip/msgdma/inc/msgdma_descriptor_regs.h
add_sw_property include_source    ip/msgdma/inc/msgdma_io.h
add_sw_property include_source    ip/msgdma/inc/msgdma_response_regs.h

# This driver supports HAL & UCOSII BSP (OS) types
add_sw_property supported_bsp_type hal
add_sw_property supported_bsp_type ERIKA
add_sw_property supported_bsp_type CONTIKI

# End of file