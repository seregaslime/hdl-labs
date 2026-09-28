`timescale 1ns/1ps

// Двоично-десятичный (BCD) счетчик в диапазоне 0..99.
// Каждая десятичная цифра хранится в отдельной 4-битной тетраде.
// Сброс синхронный, активный уровень - 0.
module bcd_counter
#(
    parameter p_max_digit = 4'd9    // максимальное значение одной десятичной цифры
)
(
    input              clk,
    input              rstN,
    output logic [3:0] outp_ones,   // единицы
    output logic [3:0] outp_tens    // десятки
);

logic [3:0] ones;
logic [3:0] tens;

assign outp_ones = ones;
assign outp_tens = tens;

always_ff @ (posedge clk)
    if (!rstN)
    begin
        ones <= '0;
        tens <= '0;
    end
    else
    begin
        if (ones == p_max_digit)
        begin
            ones <= '0;
            if (tens == p_max_digit)
            begin
                tens <= '0;         // 99 -> 00
            end
            else
            begin
                tens <= tens + 1'b1; // перенос в десятки
            end
        end
        else
        begin
            ones <= ones + 1'b1;
        end
    end

endmodule: bcd_counter
