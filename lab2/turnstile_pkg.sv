`timescale 1ns/1ps

// Общие типы данных контроллера турникета.
package turnstile_pkg;

// тип события на входе турникета
typedef enum logic [1:0]
{
    EV_NONE = 2'd0,     // события нет
    EV_PAY  = 2'd1,     // оплата
    EV_PASS = 2'd2      // сработал датчик прохода человека
} event_type_t;

// сведения о событии
typedef struct packed
{
    event_type_t ev_type;   // тип события
    logic        valid;     // признак достоверности события
    logic [7:0]  data;      // дополнительные данные (для оплаты - внесенная сумма)
} event_t;

// состояния конечного автомата
typedef enum logic [1:0]
{
    ST_IDLE   = 2'd0,   // ожидание
    ST_CHECK  = 2'd1,   // проверка оплаты
    ST_OPEN   = 2'd2,   // проход разрешен
    ST_LOCKED = 2'd3    // блокировка
} state_t;

endpackage: turnstile_pkg
