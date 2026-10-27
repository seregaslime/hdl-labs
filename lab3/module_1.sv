`timescale 1ns/1ps

// Модуль 1. Обработка сигнала оплаты.
// Проверяет посылку терминала оплаты (строб, ненулевая сумма, четность),
// выделяет фронт сигнала датчика прохода и формирует событие ev для автомата.
// Выход pay_error держится до следующей правильной оплаты или сброса.
// Сброс синхронный, активный уровень - 0.
module module_1
import lab3_pkg::*;
(
    input           clk,
    input           rst_n,
    input  logic    person_sensor,  // датчик прохода (уровень)
    input  pay_in_t pay_in,         // посылка терминала оплаты
    output event_t  ev,             // событие для автомата турникета
    output logic    pay_error       // ошибка оплаты
);

logic person_d;     // значение датчика на предыдущем такте
logic person_rise;  // фронт датчика: человек вошел в проход
logic pay_good;     // правильная оплата
logic pay_bad;      // строб есть, но оплата неправильная

assign person_rise = person_sensor & ~person_d;
assign pay_good    = pay_ok(pay_in);
assign pay_bad     = pay_in.strobe & ~pay_good;

always_ff @ (posedge clk)
    if (!rst_n)
    begin
        person_d  <= 1'b0;
        ev        <= '0;
        pay_error <= 1'b0;
    end
    else
    begin
        person_d <= person_sensor;

        ev.person <= person_rise;
        ev.pay    <= pay_good;
        ev.valid  <= person_rise | pay_good;
        ev.data   <= pay_good ? pay_in.amount : '0;

        if (pay_bad)
        begin
            pay_error <= 1'b1;
        end
        else if (pay_good)
        begin
            pay_error <= 1'b0;
        end
    end

endmodule: module_1
