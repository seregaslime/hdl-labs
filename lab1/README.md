# Лабораторная работа № 1. Работа с симулятором

**Вариант 7:** двоично-десятичный (BCD) счётчик в диапазоне 0..99.

## Файлы

- `bcd_counter.sv` — модуль счётчика (единицы и десятки по 4 бита, синхронный сброс `rstN`, активный 0)
- `bcd_counter_tb.sv` — тестбенч: такт 10 нс, сброс, ~105 тактов счёта, вывод значений и запись диаграммы в `bcd_counter.vcd`
- `Отчет_ЛР1_ЯОА_вариант07_Ильин.docx` — отчёт

## Запуск

Нужен [Icarus Verilog](https://github.com/steveicarus/iverilog) (`brew install icarus-verilog`).

```bash
iverilog -g2012 -o bcd_sim bcd_counter.sv bcd_counter_tb.sv
vvp bcd_sim
```

Временную диаграмму `bcd_counter.vcd` можно открыть в GTKWave, [Surfer](https://app.surfer-project.org) или расширении VS Code (WaveTrace / VaporView).
