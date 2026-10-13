`timescale 1ns/1ps

// Тестбенч для контроллера турникета.
module turnstile_tb();

import turnstile_pkg::*;

logic   clk;
logic   rstN;
event_t ev;
logic   gate_open;
logic   alarm;
state_t state;

turnstile DUT
(
    .clk(clk),
    .rstN(rstN),
    .ev(ev),
    .gate_open(gate_open),
    .alarm(alarm),
    .outp_state(state)
);

// генерация такта с периодом 10 нс
always #5 clk = ~clk;

// вывод текущего состояния автомата на каждом такте
always @ (posedge clk)
    $display("t=%0d ns  state = %-9s  gate_open = %b  alarm = %b",
             $time, DUT.state.name(), gate_open, alarm);

// подача одного события длительностью в один такт
task send_event(input event_type_t ev_type, input logic valid, input logic [7:0] data);
begin
    @ (negedge clk);
    ev.ev_type = ev_type;
    ev.valid   = valid;
    ev.data    = data;
    $display("t=%0d ns  событие: %s, valid = %b, data = %0d", $time, ev_type.name(), valid, data);
    @ (negedge clk);
    ev = '0;
end
endtask

initial
begin
    $dumpfile("turnstile.vcd");
    $dumpvars(0, turnstile_tb);

    clk  = 1'b0;
    rstN = 1'b0;    // сброс
    ev   = '0;
    #20;
    rstN = 1'b1;

    // 1. оплата и проход: IDLE -> CHECK -> OPEN -> IDLE
    send_event(EV_PAY, 1'b1, 8'd50);
    #20;
    send_event(EV_PASS, 1'b1, 8'd0);
    #20;

    // 2. недостаточная оплата: IDLE -> CHECK -> IDLE
    send_event(EV_PAY, 1'b1, 8'd20);
    #20;

    // 3. недостоверное событие игнорируется: остаемся в IDLE
    send_event(EV_PAY, 1'b0, 8'd50);
    #20;

    // 4. проход без оплаты: IDLE -> LOCKED -> (тайм-аут) -> IDLE
    send_event(EV_PASS, 1'b1, 8'd0);
    #60;

    // 5. оплата без прохода: IDLE -> CHECK -> OPEN -> (тайм-аут) -> IDLE
    send_event(EV_PAY, 1'b1, 8'd100);
    #110;

    $finish;
end

endmodule: turnstile_tb
