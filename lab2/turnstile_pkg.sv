`timescale 1ns/1ps

// Общие типы данных контроллера турникета.
package turnstile_pkg;

// вид события: сочетание двух независимых признаков {есть человек, есть оплата}
typedef enum logic [1:0]
{
    EV_NONE            = 2'b00,     // человека нет, оплаты нет
    EV_PAY_ONLY        = 2'b01,     // оплата есть, человека в проходе нет
    EV_PERSON_NOT_PAID = 2'b10,     // есть человек, и он не платил
    EV_PERSON_PAID     = 2'b11      // есть человек, и он платил
} event_type_t;

// сведения о событии
typedef struct packed
{
    logic        person;    // датчик прохода: есть человек
    logic        pay;       // признак оплаты
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
