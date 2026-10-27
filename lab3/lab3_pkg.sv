`timescale 1ns/1ps

// Общие параметры, типы данных и функции проекта "Контроллер турникета".
package lab3_pkg;

// ---------------- общие параметры ----------------
parameter int DATA_WIDTH  = 8;      // разрядность суммы оплаты
parameter int CNT_WIDTH   = 8;      // разрядность счетчика проходов
parameter int TIMER_WIDTH = 4;      // разрядность счетчиков тактов

parameter logic [DATA_WIDTH-1:0] PRICE = 8'd50; // стоимость прохода
parameter int OPEN_TICKS  = 8;      // сколько тактов турникет ждет прохода
parameter int LOCK_TICKS  = 4;      // длительность блокировки в тактах
parameter int DRIVE_TICKS = 2;      // время поворота привода (открытие/закрытие)

// ---------------- пользовательские типы ----------------
typedef logic [DATA_WIDTH-1:0]  amount_t;   // сумма оплаты
typedef logic [CNT_WIDTH-1:0]   count_t;    // значение счетчика проходов
typedef logic [TIMER_WIDTH-1:0] timer_t;    // счетчик тактов в состоянии

// ---------------- перечисления ----------------
// вид события: сочетание двух независимых признаков {есть человек, есть оплата}
typedef enum logic [1:0]
{
    EV_NONE            = 2'b00,     // человека нет, оплаты нет
    EV_PAY_ONLY        = 2'b01,     // оплата есть, человека в проходе нет
    EV_PERSON_NOT_PAID = 2'b10,     // есть человек, и он не платил
    EV_PERSON_PAID     = 2'b11      // есть человек, и он платил
} event_type_t;

// состояния автомата турникета (модуль 2)
typedef enum logic [1:0]
{
    ST_IDLE   = 2'd0,   // ожидание
    ST_CHECK  = 2'd1,   // проверка оплаты
    ST_OPEN   = 2'd2,   // проход разрешен
    ST_LOCKED = 2'd3    // блокировка
} state_t;

// состояния привода турникета (модуль 3)
typedef enum logic [1:0]
{
    DRV_CLOSED  = 2'd0, // закрыт, двигатель выключен
    DRV_OPENING = 2'd1, // открывается
    DRV_OPENED  = 2'd2, // открыт
    DRV_CLOSING = 2'd3  // закрывается
} drive_state_t;

// ---------------- структуры ----------------
// сигнал от терминала оплаты (вход устройства)
typedef struct packed
{
    logic    strobe;    // строб: терминал выдал сумму
    amount_t amount;    // внесенная сумма
    logic    parity;    // бит четности суммы
} pay_in_t;

// сведения о событии (выход модуля 1, вход модуля 2)
typedef struct packed
{
    logic    person;    // датчик прохода: есть человек
    logic    pay;       // признак оплаты
    logic    valid;     // признак достоверности события
    amount_t data;      // дополнительные данные (для оплаты - внесенная сумма)
} event_t;

// команды двигателя привода
typedef struct packed
{
    logic fwd;          // вращение на открытие
    logic rev;          // вращение на закрытие
} motor_t;

// ---------------- функции ----------------
// бит четности: дополняет число единиц до четного
function automatic logic parity(input amount_t data);
    return ^data;
endfunction

// корректность оплаты: есть строб, сумма не нулевая, четность совпадает
function automatic logic pay_ok(input pay_in_t p);
    return p.strobe && (p.amount != '0) && (parity(p.amount) == p.parity);
endfunction

endpackage: lab3_pkg
