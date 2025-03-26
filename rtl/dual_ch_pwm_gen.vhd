LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY dual_ch_pwm_gen IS
    GENERIC (
        WIDTH_ACC_PERIOD : INTEGER := 64;
        WIDTH_ACC_DUTY : INTEGER := 64
    );
    PORT (
        i_rstn : IN STD_LOGIC;
        i_clk_100MHz : IN STD_LOGIC;
        i_clk_33MHz : IN STD_LOGIC;
        i_ch0_duty_wen : IN STD_LOGIC;
        i_ch0_duty : IN STD_LOGIC_VECTOR(WIDTH_ACC_DUTY - 1 DOWNTO 0);
        i_ch1_duty_wen : IN STD_LOGIC;
        i_ch1_duty : IN STD_LOGIC_VECTOR(WIDTH_ACC_DUTY - 1 DOWNTO 0);
        i_ch0_period_wen : IN STD_LOGIC;
        i_ch0_period : IN STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD - 1 DOWNTO 0);
        i_ch1_period_wen : IN STD_LOGIC;
        i_ch1_period : IN STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD - 1 DOWNTO 0);
        o_ch0_pwm : OUT STD_LOGIC;
        o_ch1_pwm : OUT STD_LOGIC
    );
END dual_ch_pwm_gen;

ARCHITECTURE Behavioral OF dual_ch_pwm_gen IS

    COMPONENT pulse_sync IS
        PORT (
            i_rstn : IN STD_LOGIC;
            i_clk_a : IN STD_LOGIC;
            i_clk_b : IN STD_LOGIC;
            i_pulse_a : IN STD_LOGIC;
            o_pulse_b : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT pwm IS
        GENERIC (
            WIDTH_ACC_PERIOD : INTEGER := 64;
            WIDTH_ACC_DUTY : INTEGER := 64
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rstn : IN STD_LOGIC;
            i_srst_duty : STD_LOGIC;
            i_srst_period : STD_LOGIC;
            i_duty : IN STD_LOGIC_VECTOR(WIDTH_ACC_DUTY - 1 DOWNTO 0);
            i_period : IN STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD - 1 DOWNTO 0);
            o_period_end : OUT STD_LOGIC;
            o_pwm : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL ch0_set_duty : STD_LOGIC;
    SIGNAL ch0_set_period : STD_LOGIC;
    SIGNAL ch1_set_duty : STD_LOGIC;
    SIGNAL ch1_set_period : STD_LOGIC;
    SIGNAL ch0_duty_wen_sync : STD_LOGIC;
    SIGNAL ch0_duty_sync : STD_LOGIC_VECTOR(WIDTH_ACC_DUTY-1 DOWNTO 0);
    SIGNAL wait_ch0_duty_wr : STD_LOGIC;
    SIGNAL ch1_duty_wen_sync : STD_LOGIC;
    SIGNAL ch1_duty_sync : STD_LOGIC_VECTOR(WIDTH_ACC_DUTY-1 DOWNTO 0);
    SIGNAL wait_ch1_duty_wr : STD_LOGIC;
    SIGNAL ch0_period_wen_sync : STD_LOGIC;
    SIGNAL ch0_period_sync : STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD-1 DOWNTO 0);
    SIGNAL wait_ch0_period_wr : STD_LOGIC;
    SIGNAL ch1_period_wen_sync : STD_LOGIC;
    SIGNAL ch1_period_sync : STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD-1 DOWNTO 0);
    SIGNAL wait_ch1_period_wr : STD_LOGIC;
    SIGNAL ch0_duty : STD_LOGIC_VECTOR(WIDTH_ACC_DUTY-1 DOWNTO 0);
    SIGNAL ch1_duty : STD_LOGIC_VECTOR(WIDTH_ACC_DUTY-1 DOWNTO 0);
    SIGNAL ch0_period : STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD-1 DOWNTO 0);
    SIGNAL ch1_period : STD_LOGIC_VECTOR(WIDTH_ACC_PERIOD-1 DOWNTO 0);
    SIGNAL ch0_period_end : STD_LOGIC;
    SIGNAL ch1_period_end : STD_LOGIC;
BEGIN

    u_pulse_sync_ch0_duty_wen : pulse_sync
    PORT MAP(
        i_rstn => i_rstn,
        i_clk_a => i_clk_33MHz,
        i_clk_b => i_clk_100MHz,
        i_pulse_a => i_ch0_duty_wen,
        o_pulse_b => ch0_duty_wen_sync
    );

    u_pulse_sync_ch1_duty_wen : pulse_sync
    PORT MAP(
        i_rstn => i_rstn,
        i_clk_a => i_clk_33MHz,
        i_clk_b => i_clk_100MHz,
        i_pulse_a => i_ch1_duty_wen,
        o_pulse_b => ch1_duty_wen_sync
    );

    u_pulse_sync_ch0_period_wen : pulse_sync
    PORT MAP(
        i_rstn => i_rstn,
        i_clk_a => i_clk_33MHz,
        i_clk_b => i_clk_100MHz,
        i_pulse_a => i_ch0_period_wen,
        o_pulse_b => ch0_period_wen_sync
    );

    u_pulse_sync_ch1_period_wen : pulse_sync
    PORT MAP(
        i_rstn => i_rstn,
        i_clk_a => i_clk_33MHz,
        i_clk_b => i_clk_100MHz,
        i_pulse_a => i_ch1_period_wen,
        o_pulse_b => ch1_period_wen_sync
    );

    ch0_set_duty <= wait_ch0_duty_wr AND ch0_period_end;
    ch0_set_period <= wait_ch0_period_wr AND ch0_period_end;
    ch1_set_duty <= wait_ch1_duty_wr AND ch1_period_end;
    ch1_set_period <= wait_ch1_period_wr AND ch1_period_end;

    PROCESS (i_clk_100MHz, i_rstn)
    BEGIN
        IF i_rstn = '0' THEN
            ch0_duty_sync <= (OTHERS => '0');
            ch1_duty_sync <= (OTHERS => '0');
            ch0_period_sync <= (OTHERS => '0');
            ch1_period_sync <= (OTHERS => '0');
            ch0_duty <= (OTHERS => '0');
            ch1_duty <= (OTHERS => '0');
            ch0_period <= (OTHERS => '1');
            ch1_period <= (OTHERS => '1');
            wait_ch0_duty_wr <= '0';
            wait_ch1_duty_wr <= '0';
            wait_ch0_period_wr <= '0';
            wait_ch1_period_wr <= '0';
        ELSIF rising_edge(i_clk_100MHz) THEN
            IF ch0_duty_wen_sync = '1' THEN
                ch0_duty_sync <= i_ch0_duty;
                wait_ch0_duty_wr <= '1';
            ELSIF ch0_set_duty = '1' THEN
                wait_ch0_duty_wr <= '0';
                ch0_duty <= ch0_duty_sync;
            END IF;
            IF ch0_period_wen_sync = '1' THEN
                ch0_period_sync <= i_ch0_period;
                wait_ch0_period_wr <= '1';
            ELSIF ch0_set_period = '1' THEN
                wait_ch0_period_wr <= '0';
                ch0_period <= ch0_period_sync;
            END IF;

            IF ch1_duty_wen_sync = '1' THEN
                ch1_duty_sync <= i_ch1_duty;
                wait_ch1_duty_wr <= '1';
            ELSIF ch1_set_duty = '1' THEN
                wait_ch1_duty_wr <= '0';
                ch1_duty <= ch1_duty_sync;
            END IF;
            IF ch1_period_wen_sync = '1' THEN
                ch1_period_sync <= i_ch1_period;
                wait_ch1_period_wr <= '1';
            ELSIF ch1_set_period = '1' THEN
                wait_ch1_period_wr <= '0';
                ch1_period <= ch1_period_sync;
            END IF;
        END IF;
    END PROCESS;

    u_ch0_pwm_gen : pwm
    generic map (
        WIDTH_ACC_PERIOD => WIDTH_ACC_PERIOD,
        WIDTH_ACC_DUTY => WIDTH_ACC_DUTY
    )
    PORT MAP(
        i_clk => i_clk_100MHz,
        i_rstn => i_rstn,
        i_srst_duty => ch0_set_duty,
        i_srst_period => ch0_set_period,
        i_duty => ch0_duty,
        i_period => ch0_period,
        o_period_end => ch0_period_end,
        o_pwm => o_ch0_pwm
    );

    u_ch1_pwm_gen : pwm
    generic map (
        WIDTH_ACC_PERIOD => WIDTH_ACC_PERIOD,
        WIDTH_ACC_DUTY => WIDTH_ACC_DUTY
    )
    PORT MAP(
        i_clk => i_clk_100MHz,
        i_rstn => i_rstn,
        i_srst_duty => ch1_set_duty,
        i_srst_period => ch1_set_period,
        i_duty => ch1_duty,
        i_period => ch1_period,
        o_period_end => ch1_period_end,
        o_pwm => o_ch1_pwm
    );
END Behavioral;