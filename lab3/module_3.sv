`timescale 1ns/1ps

// Модуль 3. Управление приводом турникета и счетчиком проходов.
// По команде gate_open привод за p_drive_ticks тактов поворачивается на открытие
// (motor.fwd) или на закрытие (motor.rev); если команда меняется на ходу,
// привод сразу начинает движение в обратную сторону.
// Счетчик pass_count считает людей, прошедших через открытый турникет.
// Сброс синхронный, активный уровень - 0.
module module_3
import lab3_pkg::*;
#(
    parameter int p_drive_ticks = DRIVE_TICKS   // время поворота привода в тактах
)
(
    input                clk,
    input                rst_n,
    input  logic         gate_open,     // команда автомата: турникет открыт
    input  state_t       fsm_state,     // состояние автомата турникета
    input  event_t       ev,            // событие (нужен признак прохода человека)
    output drive_state_t drive_state,   // состояние привода
    output motor_t       motor,         // команды двигателю
    output count_t       pass_count     // число проходов
);

drive_state_t next_state;
timer_t       timer;        // счетчик тактов в текущем состоянии привода
logic         passed;       // человек прошел через открытый турникет

assign passed = (fsm_state == ST_OPEN) && ev.person && ev.valid;

// регистр состояния привода
always_ff @ (posedge clk)
    if (!rst_n)
    begin
        drive_state <= DRV_CLOSED;
    end
    else
    begin
        drive_state <= next_state;
    end

// логика переходов привода
always_comb
begin
    next_state = drive_state;
    case (drive_state)
        DRV_CLOSED:
        begin
            if (gate_open)
            begin
                next_state = DRV_OPENING;
            end
        end
        DRV_OPENING:
        begin
            if (!gate_open)
            begin
                next_state = DRV_CLOSING;   // команду сняли на ходу
            end
            else if (timer == p_drive_ticks - 1)
            begin
                next_state = DRV_OPENED;
            end
        end
        DRV_OPENED:
        begin
            if (!gate_open)
            begin
                next_state = DRV_CLOSING;
            end
        end
        DRV_CLOSING:
        begin
            if (gate_open)
            begin
                next_state = DRV_OPENING;   // новая команда на открытие
            end
            else if (timer == p_drive_ticks - 1)
            begin
                next_state = DRV_CLOSED;
            end
        end
        default:
        begin
            next_state = DRV_CLOSED;
        end
    endcase
end

// счетчик тактов привода и счетчик проходов
always_ff @ (posedge clk)
    if (!rst_n)
    begin
        timer      <= '0;
        pass_count <= '0;
    end
    else
    begin
        if (drive_state != next_state)
        begin
            timer <= '0;
        end
        else
        begin
            timer <= timer + 1'b1;
        end

        if (passed)
        begin
            pass_count <= pass_count + 1'b1;
        end
    end

// команды двигателю
always_comb
begin
    motor.fwd = (drive_state == DRV_OPENING);
    motor.rev = (drive_state == DRV_CLOSING);
end

endmodule: module_3
