`timescale 1ns/1ps

// Модуль верхнего уровня: контроллер турникета.
// module_1 - обработка сигнала оплаты,
// module_2 - автомат турникета из ЛР2,
// module_3 - управление приводом и счетчиком проходов.
module top
import lab3_pkg::*;
(
    input                clk,
    input                rst_n,
    input  logic         person_sensor, // датчик прохода
    input  pay_in_t      pay_in,        // посылка терминала оплаты
    output logic         pay_error,     // ошибка оплаты
    output logic         alarm,         // тревога: прошел без оплаты
    output state_t       fsm_state,     // состояние автомата турникета
    output drive_state_t drive_state,   // состояние привода
    output motor_t       motor,         // команды двигателю привода
    output count_t       pass_count     // число проходов
);

event_t ev;         // событие: module_1 -> module_2, module_3
logic   gate_open;  // команда открытия: module_2 -> module_3

module_1 u_pay
(
    .clk(clk),
    .rst_n(rst_n),
    .person_sensor(person_sensor),
    .pay_in(pay_in),
    .ev(ev),
    .pay_error(pay_error)
);

module_2 u_fsm
(
    .clk(clk),
    .rst_n(rst_n),
    .ev(ev),
    .gate_open(gate_open),
    .alarm(alarm),
    .outp_state(fsm_state)
);

module_3 u_drive
(
    .clk(clk),
    .rst_n(rst_n),
    .gate_open(gate_open),
    .fsm_state(fsm_state),
    .ev(ev),
    .drive_state(drive_state),
    .motor(motor),
    .pass_count(pass_count)
);

endmodule: top
