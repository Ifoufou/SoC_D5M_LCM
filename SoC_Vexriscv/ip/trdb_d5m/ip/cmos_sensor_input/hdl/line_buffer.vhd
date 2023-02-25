--Copyright (C) 2020  Intel Corporation. All rights reserved.
--Your use of Intel Corporation's design tools, logic functions 
--and other software and tools, and any partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Intel Program License 
--Subscription Agreement, the Intel Quartus Prime License Agreement,
--the Intel FPGA IP License Agreement, or other applicable license
--agreement, including, without limitation, that your use is for
--the sole purpose of programming logic devices manufactured by
--Intel and sold by Intel or its authorized distributors.  Please
--refer to the applicable agreement for further details, at
--https://fpgasoftware.intel.com/eula.


library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

entity line_buffer is
    generic(
        PIX_DEPTH   : positive;
        IMAGE_WIDTH : positive
    );
    port(
        aclr     : in  std_logic := '1';
        clken    : in  std_logic := '1';
        clock    : in  std_logic;
        shiftin  : in  std_logic_vector(PIX_DEPTH - 1 downto 0);
        shiftout : out std_logic_vector(PIX_DEPTH - 1 downto 0);
        taps0x   : out std_logic_vector(PIX_DEPTH - 1 downto 0);
        taps1x   : out std_logic_vector(PIX_DEPTH - 1 downto 0)
    );
end line_buffer;


architecture Syn of line_buffer is

    signal sub_wire0 : std_logic_vector(   PIX_DEPTH - 1 downto         0);
    signal sub_wire1 : std_logic_vector((2*PIX_DEPTH)- 1 downto         0);
    signal sub_wire2 : std_logic_vector(   PIX_DEPTH - 1 downto         0);
    signal sub_wire3 : std_logic_vector((2*PIX_DEPTH)- 1 downto PIX_DEPTH);

    component altshift_taps
    generic(
        intended_device_family : string;
        lpm_hint               : string;
        lpm_type               : string;
        number_of_taps         : natural;
        tap_distance           : natural;
        width                  : natural
    );
    port(
        aclr     : in  std_logic;
        clken    : in  std_logic;
        clock    : in  std_logic;
        shiftin  : in  std_logic_vector(   PIX_DEPTH - 1 downto 0);
        shiftout : out std_logic_vector(   PIX_DEPTH - 1 downto 0);
        taps     : out std_logic_vector((2*PIX_DEPTH)- 1 downto 0)
    );
    end component;

begin
    shiftout  <= sub_wire0(   PIX_DEPTH - 1 DOWNTO         0);
    sub_wire3 <= sub_wire1((2*PIX_DEPTH)- 1 DOWNTO PIX_DEPTH);
    sub_wire2 <= sub_wire1(   PIX_DEPTH - 1 DOWNTO         0);
    taps0x    <= sub_wire2(   PIX_DEPTH - 1 DOWNTO         0);
    taps1x    <= sub_wire3((2*PIX_DEPTH)- 1 DOWNTO PIX_DEPTH);

    ALTSHIFT_TAPS_component : ALTSHIFT_TAPS
    generic map(
        intended_device_family => "Cyclone V",
        lpm_hint => "RAM_BLOCK_TYPE=M10K",
        lpm_type => "altshift_taps",
        -- combine 2 lines of pixels
        number_of_taps => 2,
        tap_distance   => IMAGE_WIDTH,
        width          => PIX_DEPTH
    )
    port map(
        aclr => aclr,
        clken => clken,
        clock => clock,
        shiftin => shiftin,
        shiftout => sub_wire0,
        taps => sub_wire1
    );
end Syn;
