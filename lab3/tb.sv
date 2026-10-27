`timescale 1ns/1ps

// Тестбенч контроллера турникета.
// Воздействия подаются только на входы top, результат проверяется только по выходам top.
module tb;

import lab3_pkg::*;

logic         clk;
logic         rst_n;

// сигналы DUT
logic         person_sensor;
pay_in_t      pay_in;
logic         pay_error;
logic         alarm;
state_t       fsm_state;
drive_state_t drive_state;
motor_t       motor;
count_t       pass_count;

top dut
(
    .clk(clk),
    .rst_n(rst_n),
    .person_sensor(person_sensor),
    .pay_in(pay_in),
    .pay_error(pay_error),
    .alarm(alarm),
    .fsm_state(fsm_state),
    .drive_state(drive_state),
    .motor(motor),
    .pass_count(pass_count)
);

int     checks_ok   = 0;    // успешные проверки
int     checks_fail = 0;    // неуспешные проверки
int     tests_ok    = 0;    // успешные тесты
int     tests_fail  = 0;    // неуспешные тесты
int     test_num    = 0;
int     fail_at_start;      // число ошибок к началу текущего теста
string  test_name;
count_t exp_count;          // ожидаемое значение счетчика проходов
logic   half_way;           // привод развернулся, не открывшись полностью
int     seed;               // начальное значение генератора (+seed=N)
int     rnd_passed  = 0;    // случайные попытки: успешные проходы
int     rnd_denied  = 0;    // случайные попытки: отказы

// генерация такта с периодом 10 нс
initial clk = 1'b0;
always #5 clk = ~clk;

// двигатель не должен вращаться в обе стороны одновременно
always @ (negedge clk)
    if (rst_n && motor.fwd && motor.rev)
    begin
        checks_fail++;
        $error("t=%0d: двигатель включен на открытие и закрытие одновременно", $time);
    end

// ---------------- проверка результата ----------------
task automatic check(input logic ok, input string what);
    state_t       fs;   // копии выходов для вывода имен состояний
    drive_state_t ds;
    fs = fsm_state;
    ds = drive_state;
    if (ok)
    begin
        checks_ok++;
    end
    else
    begin
        checks_fail++;
        $error("t=%0d: %s (fsm=%s, drive=%s, motor=%b, pass_count=%0d, ожидалось %0d, alarm=%b, pay_error=%b)",
               $time, what, fs.name(), ds.name(), motor, pass_count, exp_count, alarm, pay_error);
    end
endtask

task automatic begin_test(input string name);
    test_num++;
    test_name     = name;
    fail_at_start = checks_fail;
endtask

task automatic end_test();
    if (checks_fail == fail_at_start)
    begin
        tests_ok++;
        $display("t=%4d ns  ПРОЙДЕН     тест %0d: %s (pass_count = %0d)", $time, test_num, test_name, pass_count);
    end
    else
    begin
        tests_fail++;
        $display("t=%4d ns  НЕ ПРОЙДЕН  тест %0d: %s", $time, test_num, test_name);
    end
endtask

// исходное состояние выходов после сброса
task automatic check_reset_state();
    check(fsm_state   == ST_IDLE,    "автомат не в ST_IDLE");
    check(drive_state == DRV_CLOSED, "привод не закрыт");
    check(motor       == '0,         "двигатель включен");
    check(pass_count  == '0,         "счетчик проходов не обнулен");
    check(!alarm && !pay_error,      "активны сигналы тревоги или ошибки");
endtask

// ---------------- формирование воздействий ----------------
// сброс на заданное число тактов
task automatic apply_reset(input int cycles);
    @ (negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @ (negedge clk);
    rst_n     = 1'b1;
    exp_count = '0;
endtask

// посылка терминала оплаты длительностью в один такт
task automatic send_payment(input amount_t amount, input logic bad_parity);
    @ (negedge clk);
    pay_in.strobe = 1'b1;
    pay_in.amount = amount;
    pay_in.parity = parity(amount) ^ bad_parity;
    @ (negedge clk);
    pay_in = '0;
endtask

// человек проходит через датчик (датчик активен 3 такта)
task automatic person_walk();
    person_sensor = 1'b1;
    repeat (3) @ (negedge clk);
    person_sensor = 1'b0;
endtask

// ожидание состояния привода с ограничением по времени
task automatic wait_drive(input drive_state_t s, input int max_cycles, input string what);
    for (int i = 0; i < max_cycles && drive_state != s; i++)
        @ (negedge clk);
    check(drive_state == s, what);
endtask

// ожидание состояния автомата с ограничением по времени
task automatic wait_fsm(input state_t s, input int max_cycles, input string what);
    for (int i = 0; i < max_cycles && fsm_state != s; i++)
        @ (negedge clk);
    check(fsm_state == s, what);
endtask

// турникет должен оставаться закрытым заданное число тактов
task automatic expect_closed(input int cycles, input string what);
    logic ok;
    ok = 1'b1;
    repeat (cycles)
    begin
        @ (negedge clk);
        if (fsm_state == ST_OPEN || drive_state != DRV_CLOSED || motor != '0)
            ok = 1'b0;
    end
    check(ok, what);
endtask

// типовая транзакция: оплата, открытие, проход человека, учет прохода
task automatic pass_transaction(input amount_t amount);
    send_payment(amount, 1'b0);
    wait_fsm(ST_OPEN, 5, "оплата принята, но автомат не перешел в ST_OPEN");
    wait_drive(DRV_OPENED, DRIVE_TICKS + 3, "привод не открылся");
    check(motor == '0, "двигатель не остановлен в открытом положении");
    check(!pay_error && !alarm, "лишний сигнал ошибки при правильной оплате");
    person_walk();
    exp_count++;
    check(pass_count == exp_count, "неверное значение счетчика проходов");
    check(fsm_state == ST_IDLE, "после прохода автомат не вернулся в ST_IDLE");
endtask

// оплата, которая не должна открыть турникет
task automatic rejected_payment(input amount_t amount, input logic bad_parity);
    send_payment(amount, bad_parity);
    expect_closed(6, "турникет открылся при неправильной оплате");
    check(pass_count == exp_count, "изменился счетчик проходов");
endtask

// попытка прохода со случайной оплатой из диапазона 40..150:
// при оплате не меньше цены человек проходит, иначе турникет блокируется
task automatic pass_attempt(input int n);
    amount_t amount;
    amount = $urandom_range(40, 150);
    if (amount >= PRICE)
    begin
        pass_transaction(amount);
        wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
        rnd_passed++;
        $display("            попытка %2d: оплата %3d -> проход               (pass_count = %0d)",
                 n, amount, pass_count);
    end
    else
    begin
        rejected_payment(amount, 1'b0);
        person_walk();                  // человек все равно пытается пройти
        wait_fsm(ST_LOCKED, 3, "проход с недостаточной оплатой не заблокирован");
        check(alarm, "нет сигнала тревоги");
        wait_fsm(ST_IDLE, LOCK_TICKS + 2, "блокировка не закончилась");
        check(pass_count == exp_count, "проход с недостаточной оплатой учтен счетчиком");
        rnd_denied++;
        $display("            попытка %2d: оплата %3d -> отказ, блокировка    (pass_count = %0d)",
                 n, amount, pass_count);
    end
endtask

// ---------------- сценарии ----------------
initial
begin
    $dumpfile("lab3.vcd");
    $dumpvars(0, tb);

    // начальное значение генератора можно задать при запуске: vvp lab3_sim +seed=N
    if ($value$plusargs("seed=%d", seed))
    begin
        $display("seed = %0d", seed);
        void'($urandom(seed));
    end

    rst_n         = 1'b0;
    person_sensor = 1'b0;
    pay_in        = '0;
    exp_count     = '0;
    apply_reset(2);

    begin_test("исходное состояние после сброса");
    check_reset_state();
    end_test();

    begin_test("штатный проход, оплата 70");
    pass_transaction(8'd70);
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("второй штатный проход, оплата 120");
    pass_transaction(8'd120);
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("граничные суммы: 49, 50, 255");
    rejected_payment(PRICE - 1'b1, 1'b0);
    check(!pay_error, "сумма меньше цены не является ошибкой терминала");
    pass_transaction(PRICE);
    pass_transaction(8'd255);
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("ошибка четности и нулевая сумма");
    rejected_payment(8'd70, 1'b1);
    check(pay_error, "нет сигнала ошибки при неверной четности");
    rejected_payment(8'd0, 1'b0);
    check(pay_error, "нет сигнала ошибки при нулевой сумме");
    pass_transaction(8'd60);    // правильная оплата снимает ошибку
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("проход без оплаты: блокировка");
    @ (negedge clk);
    person_walk();
    wait_fsm(ST_LOCKED, 3, "автомат не перешел в блокировку");
    check(alarm, "нет сигнала тревоги");
    expect_closed(2, "турникет открылся при проходе без оплаты");
    wait_fsm(ST_IDLE, LOCK_TICKS + 2, "блокировка не закончилась");
    check(!alarm, "сигнал тревоги не снят");
    check(pass_count == exp_count, "проход без оплаты учтен счетчиком");
    end_test();

    begin_test("оплата без прохода: закрытие по тайм-ауту");
    send_payment(8'd80, 1'b0);
    wait_drive(DRV_OPENED, 8, "привод не открылся");
    wait_drive(DRV_CLOSING, OPEN_TICKS + 2, "турникет не закрылся по тайм-ауту");
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся");
    check(pass_count == exp_count, "изменился счетчик проходов");
    end_test();

    begin_test("повторная операция сразу после предыдущей");
    pass_transaction(8'd50);
    pass_transaction(8'd90);    // новая оплата без паузы
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("проход до полного открытия привода");
    send_payment(8'd100, 1'b0);
    wait_fsm(ST_OPEN, 5, "оплата принята, но автомат не перешел в ST_OPEN");
    person_sensor = 1'b1;           // человек входит сразу, привод еще в пути
    half_way = 1'b1;
    repeat (3)
    begin
        @ (negedge clk);
        if (drive_state == DRV_OPENED)
            half_way = 1'b0;
    end
    person_sensor = 1'b0;
    exp_count++;
    check(half_way, "привод успел полностью открыться");
    check(drive_state == DRV_CLOSING, "привод не перешел на закрытие с полпути");
    check(pass_count == exp_count, "неверное значение счетчика проходов");
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся");
    end_test();

    begin_test("сброс во время открытия турникета");
    send_payment(8'd70, 1'b0);
    wait_drive(DRV_OPENING, 6, "привод не начал открываться");
    apply_reset(2);
    check_reset_state();
    expect_closed(4, "после сброса турникет открылся по старой оплате");
    end_test();

    begin_test("восстановление работы после сброса");
    pass_transaction(8'd70);
    wait_drive(DRV_CLOSED, DRIVE_TICKS + 3, "привод не закрылся после прохода");
    end_test();

    begin_test("20 попыток прохода со случайной оплатой 40..150");
    begin
        count_t count_before;
        count_before = pass_count;
        for (int n = 1; n <= 20; n++)
            pass_attempt(n);
        check(pass_count == count_before + rnd_passed, "счетчик не совпадает с числом проходов");
        $display("            проходов: %0d, отказов: %0d", rnd_passed, rnd_denied);
    end
    end_test();

    $display("------------------------------------------------------------");
    $display("Итого тестов: %0d, успешных: %0d, неуспешных: %0d", test_num, tests_ok, tests_fail);
    $display("Проверок: успешных %0d, неуспешных %0d", checks_ok, checks_fail);
    $finish;
end

endmodule: tb
