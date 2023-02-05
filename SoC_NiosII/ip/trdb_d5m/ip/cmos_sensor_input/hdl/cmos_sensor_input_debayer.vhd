library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cmos_sensor_input_constants.all;

-- This entity performs a "naïve" Bayer pattern to RGB conversion, also known as Debayering.
-- Each RGB pixel produced has been generated from 4 input pixels, thus the resolution of the
-- generated image has been divided by 4.
entity cmos_sensor_input_debayer is
    generic(
        PIX_DEPTH_RAW : positive;
        PIX_DEPTH_RGB : positive;
        INPUT_WIDTH   : positive;
        INPUT_HEIGHT  : positive
    );
    port(
        clk                : in  std_logic;
        reset              : in  std_logic;

        -- avalon_mm_slave
        stop_and_reset     : in  std_logic;
        debayer_pattern    : in  std_logic_vector(CMOS_SENSOR_INPUT_CONFIG_DEBAYER_PATTERN_WIDTH - 1 downto 0);

        -- sampler
        valid_in           : in  std_logic;
        data_in            : in  std_logic_vector(PIX_DEPTH_RAW - 1 downto 0);
        start_of_frame_in  : in  std_logic;
        end_of_frame_in    : in  std_logic;

        -- packer / fifo
        valid_out          : out std_logic;
        data_out           : out std_logic_vector(PIX_DEPTH_RGB - 1 downto 0);
        start_of_frame_out : out std_logic;
        end_of_frame_out   : out std_logic
    );
end entity cmos_sensor_input_debayer;

architecture rtl of cmos_sensor_input_debayer is

    -- (RAM-based) Shift register with 2 "taps", space
    component line_buffer is
        generic(
            PIX_DEPTH   : positive;
            IMAGE_WIDTH : positive
        );
        port(
            aclr     : in  std_logic;
            clken    : in  std_logic;
            clock    : in  std_logic;
            shiftin  : in  std_logic_vector(PIX_DEPTH - 1 downto 0);
            shiftout : out std_logic_vector(PIX_DEPTH - 1 downto 0);
            taps0x   : out std_logic_vector(PIX_DEPTH - 1 downto 0);
            taps1x   : out std_logic_vector(PIX_DEPTH - 1 downto 0)
        );
    end component line_buffer;
    
    -- Raw value in Bayer pattern 
    signal mDATA_up   : std_logic_vector(PIX_DEPTH_RAW - 1 downto 0);
    signal mDATA_down : std_logic_vector(PIX_DEPTH_RAW - 1 downto 0);
    -- One cycle delayed version of the upper signals
    signal mDATAd_up   : std_logic_vector(PIX_DEPTH_RAW - 1 downto 0);
    signal mDATAd_down : std_logic_vector(PIX_DEPTH_RAW - 1 downto 0);
   
begin
    line_buffer_component : line_buffer
    generic map(
        PIX_DEPTH   => PIX_DEPTH_RAW,
        IMAGE_WIDTH => INPUT_WIDTH
    )
    port map(
        aclr     => (reset or stop_and_reset),
        clken    => valid_in,
        clock    => clk,
        shiftin  => data_in,
        -- data_in, WIDTH-1 cycles away 
        taps0x   => mDATA_down,
        -- data_in, 2*WIDTH-1 cycles away
        taps1x   => mDATA_up
    );

    process (clk, reset)
        -- temporary variables, representing the value of each independant RGB channel
        variable mCCD_R : std_logic_vector(PIX_DEPTH_RGB/3 - 1 downto 0);
        variable mCCD_G : std_logic_vector(PIX_DEPTH_RGB/3 - 1 downto 0);
        variable mCCD_B : std_logic_vector(PIX_DEPTH_RGB/3 - 1 downto 0);
        
        -- Frame Coordinnate counters
        variable lineCounter : unsigned(integer(ceil(log2(real(INPUT_HEIGHT)))) - 1 downto 0);
        variable columnCounter : unsigned(integer(ceil(log2(real(INPUT_WIDTH)))) - 1 downto 0);
        -- counter of the emitted number of pixels
        variable pixelCounter : unsigned(integer(ceil(log2(real(INPUT_HEIGHT*INPUT_WIDTH/4)))) - 1 downto 0);
        -- sending state
        variable sending_state : std_logic;
        
        variable i : unsigned(integer(ceil(log2(real(2*INPUT_WIDTH+1)))) - 1 downto 0);
    begin
        if reset = '1' then
            mCCD_R    := (others => '0');
            mCCD_G    := (others => '0');
            mCCD_B    := (others => '0');
            mDATAd_up   <= (others => '0');
            mDATAd_down <= (others => '0');
            valid_out <= '0';
            data_out  <= (others => '0');
            lineCounter   := to_unsigned(0, lineCounter'length);
            columnCounter := to_unsigned(0, columnCounter'length);
            pixelCounter  := to_unsigned(0, pixelCounter'length);
            start_of_frame_out <= '0';
            end_of_frame_out   <= '0';
            sending_state := '0';
            i := to_unsigned(0, i'length);
        elsif rising_edge(clk) then
            if stop_and_reset = '1' then
                mCCD_R    := (others => '0');
                mCCD_G    := (others => '0');
                mCCD_B    := (others => '0');
                mDATAd_up   <= (others => '0');
                mDATAd_down <= (others => '0');
                valid_out <= '0';
                data_out  <= (others => '0');
                lineCounter   := to_unsigned(0, lineCounter'length);
                columnCounter := to_unsigned(0, columnCounter'length);
                pixelCounter  := to_unsigned(0, pixelCounter'length);
                start_of_frame_out <= '0';
                end_of_frame_out   <= '0';
                sending_state := '0';
                i := to_unsigned(0, i'length);
            else
                valid_out <= '0';
                data_out  <= (others => '0');
                start_of_frame_out <= '0';
                end_of_frame_out   <= '0';
                    
                if valid_in = '1' then
                    mDATAd_up   <= mDATA_up;
                    mDATAd_down <= mDATA_down;
                    
                    if start_of_frame_in = '1' then
                        -- at this cycle, valid_out is going to be high
                        start_of_frame_out <= '1';
                        sending_state := '1';
                        lineCounter   := to_unsigned(0, lineCounter'length);
                        columnCounter := to_unsigned(0, columnCounter'length);
                        pixelCounter  := to_unsigned(0, pixelCounter'length);
                    end if;
                
                    if sending_state = '1' and lineCounter(0) = '1' and columnCounter(0) = '1' then
                        --            <-- X (Column)
                        --  ---------      --------------------------
                        --    R | G1         mDATA_up   | mDATAd_up
                        --  ---------  =>  --------------------------
                        --   G2 | B          mDATA_down | mDATAd_down
                        --  ---------      --------------------------
                        --
                        mCCD_R := mDATA_up(11 downto 0) & "0000";
                        -- clamp the addition to a 12-bit value but increase its dynamic  
                        mCCD_G := std_logic_vector(unsigned(mDATA_down)+unsigned(mDATAd_up))(12 downto 1) & "0000";
                        mCCD_B := mDATAd_down(11 downto 0) & "0000";
                        valid_out <= '1';
                        -- little endian ?
                        data_out <= (mCCD_B & mCCD_G & mCCD_R);
                        if pixelCounter < to_unsigned((INPUT_HEIGHT * INPUT_WIDTH)/4 - 1, pixelCounter'length) then
                            pixelCounter := pixelCounter + 1;
                        else
                            sending_state := '0';
                            end_of_frame_out <= '1';
                        end if;
                    end if;
                    
                    if columnCounter >= to_unsigned(INPUT_WIDTH - 1, columnCounter'length) then
                        columnCounter := to_unsigned(0, columnCounter'length);
                        if lineCounter < to_unsigned(INPUT_HEIGHT - 1, lineCounter'length) then
                            lineCounter := lineCounter + 1;
                        end if;
                    else
                        columnCounter := columnCounter + 1;
                    end if;
                    
                    -- should not happened, issue a bad frame
                    if sending_state = '1' and end_of_frame_in = '1' then
                        sending_state := '0';
                        end_of_frame_out <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
