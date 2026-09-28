`timescale 1ns/1ps

// Тестбенч для BCD-счетчика 0..99.
module bcd_counter_tb();

logic       clk;
logic       rstN;
logic [3:0] ones;
logic [3:0] tens;

bcd_counter DUT
(
    .clk(clk),
    .rstN(rstN),
    .outp_ones(ones),
    .outp_tens(tens)
);

// генерация такта с периодом 10 нс
always #5 clk = ~clk;

// вывод значения счетчика на каждом такте
always @ (posedge clk)
    $display("t=%0d ns  BCD = %4b_%4b  -> %0d%0d", $time, tens, ones, tens, ones);

initial
begin
    $dumpfile("bcd_counter.vcd");
    $dumpvars(0, bcd_counter_tb);

    clk  = 1'b0;
    rstN = 1'b0;    // сброс
    #20;
    rstN = 1'b1;    // запуск счета
    #1050;          // чуть больше 100 тактов, чтобы увидеть переход 99 -> 00
    $finish;
end

endmodule: bcd_counter_tb
