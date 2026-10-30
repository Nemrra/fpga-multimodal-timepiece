# FPGA Multimodal Timepiece

A watch, stopwatch and countdown timer written in SystemVerilog, running on an Intel Cyclone V FPGA (Terasic DE1-SoC). It runs off the board's 50 MHz clock, reads the four push buttons and ten switches, and drives all six seven-segment displays.

## What it does

Switches SW1 and SW0 pick the app. All three run at the same time, so the watch keeps time while you use the stopwatch or timer.

| SW1 SW0 | App |
| :-- | :-- |
| 00 or 10 | Watch |
| 01 | Stopwatch |
| 11 | Timer |

**Watch.** Shows hours, minutes and seconds. Hold KEY3 for a second to set the time. The selected field flashes, KEY1 and KEY0 move it up and down, and holding either one repeats at 10 Hz. Each press of KEY3 moves on from seconds to minutes to hours and then back to normal running. The seconds tick restarts when you leave set mode, so the time you set is exactly the time you get.

**Stopwatch.** Counts minutes, seconds and hundredths. KEY0 starts and stops it. While it's running, KEY1 freezes the display for a lap and keeps counting underneath. Once it's stopped, KEY1 resets it.

**Timer.** Set it the same way as the watch, then start and pause it with KEY0. It stops by itself at zero, and it won't go into set mode while it's running.

**Brightness.** SW9 and SW8 dim every app in four steps, from 12.5% up to full, by pulsing the display blanking at 1 kHz. The steps are Gray-coded, so each change in brightness only needs one switch flipped.

## How it's built

Everything is made from small parameterised blocks: counters, rate generators, edge detectors, and button hold and auto-repeat logic. Each block was tested on its own before going into anything bigger, so building the apps was mostly wiring together parts that already worked.

New features sit on top of old ones instead of rewriting them. The stopwatch's lap freeze sits after its counter, and brightness control is a wrapper between the apps and the displays that neither side knows about. Each app's inputs and outputs travel as one packed struct, so switching apps is a single multiplexer.

Worst-case drift is about 4.3 seconds a day, set by the tolerance of the board's oscillator.

## Testing

- 55 cocotb simulation tests covering every block and all three apps, all passing
- Verilator and Icarus Verilog lint on every source file
- SymbiYosys formal checks on the counters, the lap snapshot, the stopwatch and timer control, and the brightness wrapper

## Running it

Open the repo in VS Code and reopen it in the dev container, which has the full toolchain (Icarus Verilog, Verilator, cocotb, Yosys and SymbiYosys).

```bash
pytest -m "not formal"   # simulation tests and lint
pytest -m formal         # formal checks
```

To put it on the board, build in Quartus with `top_de1_soc` as the top level, and swap its `user_top` instance for `user_top_brightness_timepiece`.

## Layout

```
rtl/            the design
tests/          cocotb tests
sby/            formal properties
tb/             waveform testbenches
.devcontainer/  toolchain
```

The dev container, test harness, formal properties and board wrapper template come from Jonathan Manton's Digital Systems starter repository. The rest of `rtl/` is my design.
