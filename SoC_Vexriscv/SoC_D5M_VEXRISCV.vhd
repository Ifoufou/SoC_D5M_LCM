library ieee;
use ieee.std_logic_1164.all;

entity SoC_D5M_Vexriscv is
    port(
        -- CLOCK
        CLOCK_50           : in    std_logic;

        -- SDRAM
        DRAM_ADDR          : out   std_logic_vector(12 downto 0);
        DRAM_BA            : out   std_logic_vector(1 downto 0);
        DRAM_CAS_N         : out   std_logic;
        DRAM_CKE           : out   std_logic;
        DRAM_CLK           : out   std_logic;
        DRAM_CS_N          : out   std_logic;
        DRAM_DQ            : inout std_logic_vector(15 downto 0);
        DRAM_LDQM          : out   std_logic;
        DRAM_RAS_N         : out   std_logic;
        DRAM_UDQM          : out   std_logic;
        DRAM_WE_N          : out   std_logic;

        -- GPIO_0
        GPIO_0_D5M_D       : in    std_logic_vector(11 downto 0);
        GPIO_0_D5M_FVAL    : in    std_logic;
        GPIO_0_D5M_LVAL    : in    std_logic;
        GPIO_0_D5M_PIXCLK  : in    std_logic;
        GPIO_0_D5M_RESET_N : out   std_logic;
        GPIO_0_D5M_SCLK    : inout std_logic;
        GPIO_0_D5M_SDATA   : inout std_logic;
        GPIO_0_D5M_STROBE  : in    std_logic;
        GPIO_0_D5M_TRIGGER : out   std_logic;
        GPIO_0_D5M_XCLKIN  : out   std_logic;

        ---- GPIO_1
        GPIO_1_LCM_DATA  : out std_logic_vector(7 downto 0); -- LCM Data 8 Bits
        GPIO_1_LCM_GRST  : out   std_logic; -- LCM Global Reset
        GPIO_1_LCM_SHDB  : out   std_logic; -- LCM Sleep Mode
        GPIO_1_LCM_DCLK  : out   std_logic; -- LCM Clock
        GPIO_1_LCM_HSYNC : out   std_logic; -- LCM Horizontal Sync pulse
        GPIO_1_LCM_VSYNC : out   std_logic; -- LCM Vertical Sync pulse
        GPIO_1_LCM_SCLK  : out   std_logic; -- LCM I2C Clock
        GPIO_1_LCM_SDAT  : inout std_logic; -- LCM I2C Data
        GPIO_1_LCM_SCEN  : out   std_logic  -- LCM I2C Enable
    );
end entity SoC_D5M_Vexriscv;

architecture rtl of SoC_D5M_Vexriscv is

    component soc_d5m_vexriscv_sys is
        port(
            clk_clk                          : in    std_logic                     := 'X';
            reset_reset_n                    : in    std_logic                     := 'X';
            sdram_clk_clk                    : out   std_logic;
            sdram_controller_addr            : out   std_logic_vector(12 downto 0);
            sdram_controller_ba              : out   std_logic_vector(1 downto 0);
            sdram_controller_cas_n           : out   std_logic;
            sdram_controller_cke             : out   std_logic;
            sdram_controller_cs_n            : out   std_logic;
            sdram_controller_dq              : inout std_logic_vector(15 downto 0) := (others => 'X');
            sdram_controller_dqm             : out   std_logic_vector(1 downto 0);
            sdram_controller_ras_n           : out   std_logic;
            sdram_controller_we_n            : out   std_logic;
            trdb_d5m_cmos_sensor_frame_valid : in    std_logic                     := 'X';
            trdb_d5m_cmos_sensor_line_valid  : in    std_logic                     := 'X';
            trdb_d5m_cmos_sensor_data        : in    std_logic_vector(7 downto 0)  := (others => 'X');
            trdb_d5m_i2c_scl                 : inout std_logic                     := 'X';
            trdb_d5m_i2c_sda                 : inout std_logic                     := 'X';
            trdb_d5m_pixclk_clk              : in    std_logic                     := 'X';
            trdb_d5m_xclkin_clk              : out   std_logic;
            trdb_lcm_out_signals_lcm_data    : out   std_logic_vector(7 downto 0);
            trdb_lcm_out_signals_lcm_dclk    : out   std_logic;
            trdb_lcm_out_signals_lcm_grst    : out   std_logic;
            trdb_lcm_out_signals_lcm_hsync   : out   std_logic;
            trdb_lcm_out_signals_lcm_shdb    : out   std_logic;
            trdb_lcm_out_signals_lcm_vsync   : out   std_logic
        );
    end component soc_d5m_vexriscv_sys;
    
    component I2S_LCM_Config is
        port (
            -- Host Side
            iCLK : in std_logic;
            iRST_N : in std_logic;
            -- I2C Side
            I2S_SCLK : out   std_logic;
            I2S_SDAT : inout std_logic;
            I2S_SCEN : out   std_logic
        );
    end component I2S_LCM_Config;

begin
    GPIO_0_D5M_RESET_N <= '1';
    GPIO_0_D5M_TRIGGER <= '0';

    sys : component soc_d5m_vexriscv_sys
        port map (
            clk_clk                          => CLOCK_50,
            reset_reset_n                    => '1',
            sdram_clk_clk                    => DRAM_CLK,
            sdram_controller_addr            => DRAM_ADDR,
            sdram_controller_ba              => DRAM_BA,
            sdram_controller_cas_n           => DRAM_CAS_N,
            sdram_controller_cke             => DRAM_CKE,
            sdram_controller_cs_n            => DRAM_CS_N,
            sdram_controller_dq              => DRAM_DQ,
            sdram_controller_dqm(1)          => DRAM_UDQM,
            sdram_controller_dqm(0)          => DRAM_LDQM,
            sdram_controller_ras_n           => DRAM_RAS_N,
            sdram_controller_we_n            => DRAM_WE_N,
            trdb_d5m_xclkin_clk              => GPIO_0_D5M_XCLKIN,
            trdb_d5m_cmos_sensor_frame_valid => GPIO_0_D5M_FVAL,
            trdb_d5m_cmos_sensor_line_valid  => GPIO_0_D5M_LVAL,
				-- select only the upper bits from the sensor
            trdb_d5m_cmos_sensor_data        => GPIO_0_D5M_D(11 downto 4),
            trdb_d5m_i2c_scl                 => GPIO_0_D5M_SCLK,
            trdb_d5m_i2c_sda                 => GPIO_0_D5M_SDATA,
            trdb_d5m_pixclk_clk              => GPIO_0_D5M_PIXCLK,
            trdb_lcm_out_signals_lcm_data    => GPIO_1_LCM_DATA,
            trdb_lcm_out_signals_lcm_dclk    => GPIO_1_LCM_DCLK,
            trdb_lcm_out_signals_lcm_grst    => GPIO_1_LCM_GRST,
            trdb_lcm_out_signals_lcm_hsync   => GPIO_1_LCM_HSYNC,
            trdb_lcm_out_signals_lcm_shdb    => GPIO_1_LCM_SHDB,
            trdb_lcm_out_signals_lcm_vsync   => GPIO_1_LCM_VSYNC
        );

    lcm_i2c_config : component I2S_LCM_Config
        port map(
            iCLK => CLOCK_50,
            iRST_N => '1',
            I2S_SCLK => GPIO_1_LCM_SCLK,
            I2S_SDAT => GPIO_1_LCM_SDAT,
            I2S_SCEN => GPIO_1_LCM_SCEN
        );
end;
