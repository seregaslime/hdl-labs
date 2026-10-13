`timescale 1ns/1ps

// Контроллер турникета (конечный автомат Мура).
// Состояния: ожидание, проверка оплаты, проход разрешен, блокировка.
// Сброс синхронный, активный уровень - 0.
module turnstile
import turnstile_pkg::*;
#(
    parameter p_price      = 8'd50, // стоимость прохода
    parameter p_open_ticks = 4'd8,  // сколько тактов турникет ждет прохода
    parameter p_lock_ticks = 4'd4   // длительность блокировки в тактах
)
(
    input          clk,
    input          rstN,
    input  event_t ev,          // событие: оплата или датчик прохода
    output logic   gate_open,   // турникет открыт
    output logic   alarm,       // сигнал тревоги (блокировка)
    output state_t outp_state   // текущее состояние автомата
);

state_t     state;
state_t     next_state;
logic [7:0] paid;       // внесенная сумма
logic [3:0] timer;      // счетчик тактов в текущем состоянии

logic       pay_ev;     // достоверное событие "оплата"
logic       pass_ev;    // достоверное событие "проход"

assign outp_state = state;
assign pay_ev     = ev.valid && (ev.ev_type == EV_PAY);
assign pass_ev    = ev.valid && (ev.ev_type == EV_PASS);

// регистр состояния
always_ff @ (posedge clk)
    if (!rstN)
    begin
        state <= ST_IDLE;
    end
    else
    begin
        state <= next_state;
    end

// логика переходов
always_comb
begin
    next_state = state;
    case (state)
        ST_IDLE:
        begin
            if (pay_ev)
            begin
                next_state = ST_CHECK;      // пришла оплата
            end
            else if (pass_ev)
            begin
                next_state = ST_LOCKED;     // попытка пройти без оплаты
            end
        end
        ST_CHECK:
        begin
            if (paid >= p_price)
            begin
                next_state = ST_OPEN;       // оплаты достаточно
            end
            else
            begin
                next_state = ST_IDLE;       // оплаты недостаточно
            end
        end
        ST_OPEN:
        begin
            if (pass_ev)
            begin
                next_state = ST_IDLE;       // человек прошел
            end
            else if (timer == p_open_ticks - 1'b1)
            begin
                next_state = ST_IDLE;       // никто не прошел, время вышло
            end
        end
        ST_LOCKED:
        begin
            if (timer == p_lock_ticks - 1'b1)
            begin
                next_state = ST_IDLE;       // блокировка закончилась
            end
        end
        default:
        begin
            next_state = ST_IDLE;
        end
    endcase
end

// внесенная сумма и счетчик тактов
always_ff @ (posedge clk)
    if (!rstN)
    begin
        paid  <= '0;
        timer <= '0;
    end
    else
    begin
        if (state == ST_IDLE && pay_ev)
        begin
            paid <= ev.data;
        end

        if (state != next_state)
        begin
            timer <= '0;
        end
        else
        begin
            timer <= timer + 1'b1;
        end
    end

// выходные сигналы
always_comb
begin
    gate_open = 1'b0;
    alarm     = 1'b0;
    case (state)
        ST_OPEN:   gate_open = 1'b1;
        ST_LOCKED: alarm     = 1'b1;
        default:   ;
    endcase
end

endmodule: turnstile
