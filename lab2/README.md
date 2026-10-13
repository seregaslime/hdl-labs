# Лабораторная работа № 2. Конечные автоматы

**Вариант 7:** контроллер турникета (состояния: ожидание, проверка оплаты, проход разрешён, блокировка).

## Файлы

- `turnstile_pkg.sv` — типы данных: состояния `state_t` и тип события `event_type_t` (`typedef enum`), событие `event_t` (`typedef struct`: тип, признак достоверности, данные)
- `turnstile.sv` — модуль автомата (синхронный сброс `rstN`, активный 0; выходы `gate_open`, `alarm`, `outp_state`)
- `turnstile_tb.sv` — тестбенч: такт 10 нс, пять сценариев, проходящих все состояния и переходы, вывод состояния и запись диаграммы в `turnstile.vcd`
- `Отчет_ЛР2_ЯОА_вариант07_Ильин.docx` — отчёт

## Запуск

Нужен [Icarus Verilog](https://github.com/steveicarus/iverilog) (`brew install icarus-verilog`).

```bash
iverilog -g2012 -o turnstile_sim turnstile_pkg.sv turnstile.sv turnstile_tb.sv
vvp turnstile_sim
```

Временную диаграмму `turnstile.vcd` можно открыть в GTKWave, [Surfer](https://app.surfer-project.org) или расширении VS Code (WaveTrace / VaporView).
