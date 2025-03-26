`timescale 1ns / 1ps

module tb_dual_ch_pwm_gen ();

  localparam W_DUTY = 20;
  localparam W_PERIOD = 64;
  localparam NCO_F = 100000000.0;  //Hz
  localparam FREQ_ERROR = 0.8;  //Hz
  localparam DUTY_ERROR = 0.1;  //%

  logic                clk_100MHz;
  logic                clk_33MHz;
  logic                rstn;
  logic                ch0_duty_wen;
  logic [  W_DUTY-1:0] ch0_duty;
  logic                ch1_duty_wen;
  logic [  W_DUTY-1:0] ch1_duty;
  logic                ch0_period_wen;
  logic [W_PERIOD-1:0] ch0_period;
  logic                ch1_period_wen;
  logic [W_PERIOD-1:0] ch1_period;
  logic                ch0_pwm;
  logic                ch1_pwm;
  real                 rez_test;
  real                 rez_test2;
  logic [        63:0] test;
  logic [        63:0] test2;
  logic [        63:0] test3;

  event                test_event;

  initial begin
    clk_100MHz = 1'b0;
    clk_33MHz = 1'b0;
    rstn = 1'b0;
    ch0_duty_wen = 'h0;
    ch0_duty = 'h0;
    ch1_duty_wen = 'h0;
    ch1_duty = 'h0;
    ch0_period_wen = 'h0;
    ch0_period = 'h0;
    ch1_period_wen = 'h0;
    ch1_period = 'h0;

    $timeformat(-9, 6, "", 8);
    repeat (10) @(posedge clk_100MHz);
    rstn <= 1'b1;
    repeat (10) @(posedge clk_100MHz);

    $display("MANUAL TEST");
    manual_test(.ch0_freq(300001), .ch0_duty(10), .ch1_freq(999999), .ch1_duty(33));
    $display("RANDOM TEST");
    rand_test(.repetition(10));

    $display("ALL TESTS PASS");

    $stop();
  end

  always #5ns clk_100MHz = ~clk_100MHz;
  always #15.151ns clk_33MHz = ~clk_33MHz;






  dual_ch_pwm_gen #(
      .WIDTH_ACC_PERIOD(W_PERIOD),
      .WIDTH_ACC_DUTY  (W_DUTY)
  ) DUT_dual_ch_pwm_gen (
      .i_rstn(rstn),
      .i_clk_100MHz(clk_100MHz),
      .i_clk_33MHz(clk_33MHz),
      .i_ch0_duty_wen(ch0_duty_wen),
      .i_ch0_duty(ch0_duty),
      .i_ch1_duty_wen(ch1_duty_wen),
      .i_ch1_duty(ch1_duty),
      .i_ch0_period_wen(ch0_period_wen),
      .i_ch0_period(ch0_period),
      .i_ch1_period_wen(ch1_period_wen),
      .i_ch1_period(ch1_period),
      .o_ch0_pwm(ch0_pwm),
      .o_ch1_pwm(ch1_pwm)
  );


  task automatic wr_duty_reg(input [W_DUTY-1:0] duty, input ch_sel);
    begin
      if (ch_sel == 0) begin
        @(posedge clk_33MHz);
        ch0_duty <= duty;
        ch0_duty_wen <= 1'b1;
        @(posedge clk_33MHz);
        ch0_duty_wen <= 1'b0;
      end else begin
        @(posedge clk_33MHz);
        ch1_duty <= duty;
        ch1_duty_wen <= 1'b1;
        @(posedge clk_33MHz);
        ch1_duty_wen <= 1'b0;
      end
    end
  endtask

  task automatic wr_period_reg(input [W_PERIOD-1:0] period, input ch_sel);
    begin
      if (ch_sel == 0) begin
        @(posedge clk_33MHz);
        ch0_period <= period;
        ch0_period_wen <= 1'b1;
        @(posedge clk_33MHz);
        ch0_period_wen <= 1'b0;
      end else begin
        @(posedge clk_33MHz);
        ch1_period <= period;
        ch1_period_wen <= 1'b1;
        @(posedge clk_33MHz);
        ch1_period_wen <= 1'b0;
      end
    end
  endtask

  function automatic [W_DUTY-1:0] calc_duty(input int freq, input int duty);
    real rez;
    rez = ((freq / (duty / 100.0)) / NCO_F) * (2.0 ** W_DUTY);
    return rez;
  endfunction

  function automatic [W_PERIOD-1:0] calc_period(input int freq);
    real rez;
    rez = (freq / NCO_F) * (2.0 ** W_PERIOD);
    return rez;
  endfunction

  function automatic real abs(input real x);
    return (x < 0.0) ? -x : x;
  endfunction

  task automatic check_duty_period(input int freq, input int duty, input ch_sel);
    int      avg_window;
    real     period_compare;
    realtime time_start;
    real     duty_cal;
    real     period_cal;
    real     period_acc;
    real     duty_acc;
    real     avgT;
    real     avgD;
    real     avg_freq;
    real     percent_duty;
    begin

      if (freq > 100) begin
        avg_window = freq / 100 + 1000;
      end else begin
        avg_window = freq + 3;
      end
      period_compare = (1.0 / freq);
      period_acc = 0.0;
      duty_acc = 0.0;
      if (ch_sel == 0) begin
        @(posedge ch0_pwm);
        time_start = $realtime;
        repeat (avg_window) begin
          @(negedge ch0_pwm);
          duty_cal = $realtime - time_start;
          duty_acc += duty_cal;
          @(posedge ch0_pwm);
          period_cal = $realtime - time_start;
          period_acc += period_cal;
          time_start = $realtime;
        end
      end else begin
        @(posedge ch1_pwm);
        time_start = $realtime;
        repeat (avg_window) begin
          @(negedge ch1_pwm);
          duty_cal = $realtime - time_start;
          duty_acc += duty_cal;
          @(posedge ch1_pwm);
          period_cal = $realtime - time_start;
          period_acc += period_cal;
          time_start = $realtime;
        end
      end

      avgT = period_acc / avg_window;
      avg_freq = 1.0 / (avgT * (10.0 ** -9));
      avgD = duty_acc / avg_window;
      percent_duty = (avgD * 10.0 ** -7) / period_compare;
      $display("CHANNEL %1d avg_window = %d", ch_sel, avg_window);
      $display("CHANNEL %1d f = %6dHz f_gen = %0.3fHz", ch_sel, freq, avg_freq);
      $display("CHANNEL %1d freq diff %0.6fHz", ch_sel, freq - avg_freq);
      $display("CHANNEL %1d duty = %f%% duty_gen = %f%%", ch_sel, duty, percent_duty);
      $display("CHANNEL %1d duty diff = %f%%", ch_sel, duty - percent_duty);

      if (abs(freq - avg_freq) > FREQ_ERROR) begin
        $display("CHANNEL %1d FREQUENCY TEST FAIL", ch_sel);
        $stop();
      end else begin
        $display("CHANNEL %1d FREQUENCY TEST PASS", ch_sel);
      end

      if (abs(duty - percent_duty) > DUTY_ERROR) begin
        $display("CHANNEL %1d DUTY TEST FAIL", ch_sel);
        $stop();
      end else begin
        $display("CHANNEL %1d DUTY TEST PASS", ch_sel);
      end

    end
  endtask

  task automatic manual_test(input int ch0_freq, input int ch0_duty, input int ch1_freq,
                             input int ch1_duty);
    begin
      wr_period_reg(calc_period(ch0_freq), 0);
      wr_duty_reg(calc_duty(ch0_freq, ch0_duty), 0);
      wr_period_reg(calc_period(ch1_freq), 1);
      wr_duty_reg(calc_duty(ch1_freq, ch1_duty), 1);
      fork
        check_duty_period(.freq(ch0_freq), .duty(ch0_duty), .ch_sel(0));
        check_duty_period(.freq(ch1_freq), .duty(ch1_duty), .ch_sel(1));
      join
    end
  endtask

  task automatic rand_test(input int repetition);
    int ch0_rnd_freq;
    int ch0_rnd_duty;
    int ch1_rnd_freq;
    int ch1_rnd_duty;
    int i;
    begin
      for (i = 0; i < repetition; i++) begin
        $display("RANDOM TEST INTERARION %d", i);
        ch0_rnd_freq = $urandom_range(1, 1000000);
        ch0_rnd_duty = $urandom_range(1, 99);
        ch1_rnd_freq = $urandom_range(1, 1000000);
        ch1_rnd_duty = $urandom_range(1, 99);
        manual_test(.ch0_freq(ch0_rnd_freq), .ch0_duty(ch0_rnd_duty), .ch1_freq(ch1_rnd_freq),
                    .ch1_duty(ch1_rnd_duty));
      end
    end
  endtask

endmodule
