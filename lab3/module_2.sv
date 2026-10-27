`timescale 1ns/1ps

// Модуль 2. Контроллер турникета из ЛР2 (конечный автомат Мура).
// Состояния: ожидание, проверка оплаты, проход разрешен, блокировка.
// Типы и параметры по умолчанию берутся из пакета lab3_pkg.
// Сброс синхронный, активный уровень - 0.
module module_2
import lab3_pkg::*;
#(
    parameter amount_t p_price      = PRICE,        // стоимость прохода
    parameter int      p_open_ticks = OPEN_TICKS,   // сколько тактов турникет ждет прохода
    parameter int      p_lock_ticks = LOCK_TICKS    // длительность блокировки в тактах
)
(
    input          clk,
    input          rst_n,
    input  event_t ev,          // событие: датчик прохода и признак оплаты
    output logic   gate_open,   // турникет открыт
    output logic   alarm,       // сигнал тревоги (блокировка)
    output state_t outp_state   // текущее состояние автомата
);

state_t  state;
state_t  next_state;
amount_t paid;          // внесенная сумма
timer_t  timer;         // счетчик тактов в текущем состоянии

event_type_t ev_kind;   // вид события (у недостоверного события - EV_NONE)

assign outp_state = state;
assign ev_kind    = event_type_t'({ev.person & ev.valid, ev.pay & ev.valid});

// регистр состояния
always_ff @ (posedge clk)
    if (!rst_n)
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
            case (ev_kind)
                EV_PERSON_PAID:     next_state = ST_CHECK;  // есть человек, и он платил
                EV_PAY_ONLY:        next_state = ST_CHECK;  // оплата есть, человек еще не подошел
                EV_PERSON_NOT_PAID: next_state = ST_LOCKED; // есть человек, и он не платил
                default:            next_state = ST_IDLE;
            endcase
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
            if (ev_kind == EV_PERSON_PAID || ev_kind == EV_PERSON_NOT_PAID)
            begin
                next_state = ST_IDLE;       // человек прошел
            end
            else if (timer == p_open_ticks - 1)
            begin
                next_state = ST_IDLE;       // никто не прошел, время вышло
            end
        end
        ST_LOCKED:
        begin
            if (timer == p_lock_ticks - 1)
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
    if (!rst_n)
    begin
        paid  <= '0;
        timer <= '0;
    end
    else
    begin
        if (state == ST_IDLE && (ev_kind == EV_PERSON_PAID || ev_kind == EV_PAY_ONLY))
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

endmodule: module_2
