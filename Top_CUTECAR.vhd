library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Top_CUTECAR is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(0 downto 0);
    SW       : in  std_logic_vector(7 downto 0);
    LED      : out std_logic_vector(7 downto 0);

    DRAM_CLK, DRAM_CKE : out std_logic;
    DRAM_ADDR          : out std_logic_vector(12 downto 0);
    DRAM_BA            : out std_logic_vector(1 downto 0);
    DRAM_CS_N          : out std_logic;
    DRAM_CAS_N         : out std_logic;
    DRAM_RAS_N         : out std_logic;
    DRAM_WE_N          : out std_logic;
    DRAM_DQ            : inout std_logic_vector(15 downto 0);
    DRAM_DQM           : out std_logic_vector(1 downto 0);

    MTRR_P : out std_logic;
    MTRR_N : out std_logic;
    MTRL_P : out std_logic;
    MTRL_N : out std_logic;

    LTC_ADC_CONVST : out std_logic;
    LTC_ADC_SCK    : out std_logic;
    LTC_ADC_SDI    : out std_logic;
    LTC_ADC_SDO    : in  std_logic;

    VCC3P3_PWRON_n : out std_logic
  );
end entity;

architecture Structure of Top_CUTECAR is

  component pll_2freqs is
    port (
      areset : in  std_logic := '0';
      inclk0 : in  std_logic := '0';
      c0     : out std_logic;
      c1     : out std_logic
    );
  end component;

  component Nios_CUTECAR is
    port (
      clk_clk                               : in    std_logic                     := 'X';
      switches_export                       : in    std_logic_vector(7 downto 0)  := (others => 'X');
      leds_export                           : out   std_logic_vector(7 downto 0);

      sdram_wire_addr                       : out   std_logic_vector(12 downto 0);
      sdram_wire_ba                         : out   std_logic_vector(1 downto 0);
      sdram_wire_cas_n                      : out   std_logic;
      sdram_wire_cke                        : out   std_logic;
      sdram_wire_cs_n                       : out   std_logic;
      sdram_wire_dq                         : inout std_logic_vector(15 downto 0) := (others => 'X');
      sdram_wire_dqm                        : out   std_logic_vector(1 downto 0);
      sdram_wire_ras_n                      : out   std_logic;
      sdram_wire_we_n                       : out   std_logic;

      reset_reset_n                         : in    std_logic                     := 'X';
      clocks_sdram_clk_clk                  : out   std_logic;

      writedatal_external_connection_export : out   std_logic_vector(13 downto 0);
      writedatar_external_connection_export : out   std_logic_vector(13 downto 0);

      pos_data0r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data1r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data2r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data3r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data4r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data5r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data6r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');

      vect_pos_external_connection_export    : in    std_logic_vector(6 downto 0)  := (others => 'X');
      niveau_external_connection_export      : out   std_logic_vector(7 downto 0)  := (others => '0');

      base_duty_external_connection_export   : out   std_logic_vector(13 downto 0);
      port_s_external_connection_export      : out   std_logic_vector(2 downto 0);
      port_e_external_connection_export      : in    std_logic_vector(1 downto 0)  := (others => 'X');
  end component;


  -- Internal signals (seulement ceux nécessaires à l'examen)
  signal rst_n    : std_logic;
  signal clk40   : std_logic;
  signal clk2k   : std_logic;
  signal led_nios : std_logic_vector(7 downto 0);
  signal pos_data0r_s, pos_data1r_s : std_logic_vector(7 downto 0);
  signal calc_result : std_logic_vector(8 downto 0);
  signal calc_valid  : std_logic;
  signal pio_op_sel_export   : std_logic_vector(1 downto 0);
  signal pio_result_export   : std_logic_vector(8 downto 0);

begin

  rst_n <= KEY(0);

  VCC3P3_PWRON_n <= '0';

  u_pll : pll_2freqs
    port map (
      areset => not rst_n,
      inclk0 => CLOCK_50,
      c0     => clk40,
      c1     => clk2k
    );

  u_caps : capteurs_sol_seuil
    port map (
      clk          => clk40,
      reset_n      => rst_n,
      data_capture => clk2k,
      data_readyr  => data_ready_s,

      data0r => pos_data0r_s,
      data1r => pos_data1r_s,
      data2r => pos_data2r_s,
      data3r => pos_data3r_s,
      data4r => pos_data4r_s,
      data5r => pos_data5r_s,
      data6r => pos_data6r_s,

      NIVEAU    => niveau_s,
      vect_capt => vect_capt_s,

      ADC_CONVSTr => LTC_ADC_CONVST,
      ADC_SCK     => LTC_ADC_SCK,
      ADC_SDIr    => LTC_ADC_SDI,
      ADC_SDO     => LTC_ADC_SDO
    );

  -- Nios -> FPGA commands
  start_sl_s  <= port_s(0);
  start_rot_s <= port_s(1);
  dir_rot_s   <= port_s(2);

  -- FPGA -> Nios status
  port_e(0) <= fin_sl_s;
  port_e(1) <= fin_rot_s;


  -- Liaison du résultat du calculateur à la PIO pour lecture Nios
  pio_result_export <= calc_result;
  -- Debug LEDs : affiche le résultat du calculateur sur LED(7 downto 0)
  LED <= calc_result(7 downto 0);
  -- Instanciation du calculateur câblé
  u_calc : calculateur_cable
    port map (
      clk     => clk40,
      reset_n => rst_n,
      data_a  => pos_data0r_s, -- capteur 0
      data_b  => pos_data1r_s, -- capteur 1
      op_sel  => pio_op_sel_export, -- piloté par le Nios via PIO
      result  => calc_result,
      valid   => calc_valid
    );

  -- Line following controller
  u_ctl_sl : CTL_SL
    port map (
      clk       => CLOCK_50,
      reset_n   => rst_n,
      start_SL  => start_sl_s,
      posi      => vect_capt_s,
      base_duty => base_duty_s,
		data_ready => data_ready_s,
      cmdL_SL   => cmdL_sl_s,
      cmdR_SL   => cmdR_sl_s,
      fin_SL    => fin_sl_s
    );

  -- Rotation controller (simple): rotate until center pattern detected
  u_ctl_rot : CTL_Rot
    port map(
      clk       => CLOCK_50,
      reset_n   => rst_n,
      start_Rot => start_rot_s,
      dir_Rot   => dir_rot_s,
      posi      => vect_capt_s,
		data_ready => data_ready_s,
      cmdL_rot  => cmdL_rot_s,
      cmdR_rot  => cmdR_rot_s,
      fin_rot   => fin_rot_s
    );

  -- Motor command MUX: Rotation > Line follow > Direct Nios
  cmdL_pwm_s <= cmdL_rot_s when start_rot_s = '1' else
                cmdL_sl_s  when start_sl_s  = '1' else
                writedataL_s;

  cmdR_pwm_s <= cmdR_rot_s when start_rot_s = '1' else
                cmdR_sl_s  when start_sl_s  = '1' else
                writedataR_s;

  PWM0 : PWM_generation
    port map (
      clk          => CLOCK_50,
      reset_n      => rst_n,
      s_writedataR => cmdR_pwm_s,
      s_writedataL => cmdL_pwm_s,
      dc_motor_p_R => MTRR_P,
      dc_motor_n_R => MTRR_N,
      dc_motor_p_L => MTRL_P,
      dc_motor_n_L => MTRL_N
    );

  component Nios_CUTECAR is
    port (
      clk_clk                               : in    std_logic                     := 'X';
      switches_export                       : in    std_logic_vector(7 downto 0)  := (others => 'X');
      leds_export                           : out   std_logic_vector(7 downto 0);

      sdram_wire_addr                       : out   std_logic_vector(12 downto 0);
      sdram_wire_ba                         : out   std_logic_vector(1 downto 0);
      sdram_wire_cas_n                      : out   std_logic;
      sdram_wire_cke                        : out   std_logic;
      sdram_wire_cs_n                       : out   std_logic;
      sdram_wire_dq                         : inout std_logic_vector(15 downto 0) := (others => 'X');
      sdram_wire_dqm                        : out   std_logic_vector(1 downto 0);
      sdram_wire_ras_n                      : out   std_logic;
      sdram_wire_we_n                       : out   std_logic;

      reset_reset_n                         : in    std_logic                     := 'X';
      clocks_sdram_clk_clk                  : out   std_logic;

      writedatal_external_connection_export : out   std_logic_vector(13 downto 0);
      writedatar_external_connection_export : out   std_logic_vector(13 downto 0);

      pos_data0r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data1r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data2r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data3r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data4r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data5r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');
      pos_data6r_external_connection_export  : in    std_logic_vector(7 downto 0)  := (others => 'X');

      vect_pos_external_connection_export    : in    std_logic_vector(6 downto 0)  := (others => 'X');
      niveau_external_connection_export      : out   std_logic_vector(7 downto 0)  := (others => '0');

      base_duty_external_connection_export   : out   std_logic_vector(13 downto 0);
      port_s_external_connection_export      : out   std_logic_vector(2 downto 0);
      port_e_external_connection_export      : in    std_logic_vector(1 downto 0)  := (others => 'X');
    );
  end component;
      pio_op_sel_external_connection_export => pio_op_sel_export,
      pio_result_external_connection_export => pio_result_export
    );

end architecture;