# Circuits that recur, with their numbers

## Contents

- The chip maker's hardware design guide
- A lithium cell, from the port to the program
- USB
- I²C, crystals, LEDs, ADC inputs
- Addressable LEDs
- Tracks, vias and clearances by the numbers
- The first power-up, written for the person

Numbers here are where to start and what to check against; the datasheet and the maker's guide of the part on **this** board decide. Where a value is computed, write the computation into `DESIGN.md`.

## The chip maker's hardware design guide

For a processor or a radio, the datasheet is not enough: its maker publishes a hardware design guide (or a "minimal design", or a "getting started with hardware" note) with the parts no pin table shows. Get it into `refs/` with the datasheet and build from its schematic and its layout notes. What such guides hold, by example (read the current guide of your chip; these change):

- **ESP32-S3** (Espressif's hardware design guidelines): the enable pin never floats and rises after the supply (10 kΩ up, 1 µF to ground); strapping pins GPIO0, 3, 45, 46, with a pull-up and **no large capacitor** on GPIO0 (it would enter download mode); analog inputs on ADC1 (GPIO1–10), not ADC2, with 0.1 µF at the pin, and accurate only to about 1.6 V at mid attenuation (a battery divider to one third fits); USB on GPIO19/20 with room for small series resistors; a supply that gives 500 mA; four layers recommended, the second one solid ground; a module's antenna at the board's edge with about 15 mm clear of anything, also inside the case.
- **RP2040** (Raspberry Pi's "Hardware design with RP2040"): 1 µF on each side of its core regulator; a crystal with 1 kΩ in series on XOUT; 27 Ω in series on each USB line; BOOTSEL is the flash's chip-select pulled to ground **through 1 kΩ** by a button; its two-layer reference board is **1.0 mm** thick so that the USB pair can be 90 Ω (0.8 mm tracks, 0.15 mm apart).
- **STM32** (ST's "getting started with hardware development" note for the family): 100 nF at every supply pin and one bulk capacitor; the analog supply filtered; BOOT0 pulled down and reachable; 100 nF on NRST; SWD (SWDIO, SWCLK, NRST, ground, the target's voltage) on a header; the errata sheet read.
- **A Raspberry Pi HAT**: the two ID pins go only to the ID memory; a HAT that powers the Pi feeds 5 V through an ideal diode, never the 3.3 V pins.

## A lithium cell, from the port to the program

```
USB 5 V ─► charger (and power path) ─► system rail ─► regulator ─► loads
              │   ▲ thermistor            │
              ▼                           ├─► divider or fuel gauge ─► the program (ADC or I²C)
       cell + protection                  └─► status and "USB present" ─► GPIOs, an LED
```

- **Charger**: a linear one up to about an ampere (its heat is (5 V − cell) × current). The charge current is set by a resistor for the cell (no more than the cell's sheet allows; half its capacity per hour when it says nothing), and the charge voltage is the cell's (4.20 V unless it says otherwise). A charger with a power path, or a load-sharing FET and diode, lets the device run while charging without confusing the end of charge. Not every charger has a thermistor input: check when the cell has one.
- **Protection** (over-charge, over-discharge at about 2.4 V, short) is the last line, not the working cut-off: a cell should stop near 3.0–3.3 V. So the program, a supervisor chip or the regulator's own under-voltage lockout must stop the device earlier, and the program can only do it if it can measure the cell.
- **Measuring it**: a fuel-gauge chip on I²C for a real percentage; or a divider into an ADC-capable pin, either switched on only while measuring (a P-channel FET at the top driven through a small N-channel one) or made of large resistors (a megohm or more in total, which costs a few microamperes for ever) with 0.1–1 µF at the pin and a pause before the sample. Scale it into the range where the ADC is accurate.
- **What the program is told**: the charger's status pin (often open drain: it needs a pull-up) on a GPIO and an LED; the port's 5 V through a divider on a GPIO.
- **The regulator** must hold its output down to the voltage at which the device stops, under the peak current: a cell sags by its internal resistance times the current, so a radio's burst at 3.4 V can drop below a 3.3 V linear regulator's dropout.
- **Mechanics**: a keyed connector rated for the peak current, polarity in silkscreen, the cell held, nothing sharp or hot against it.

## USB

- **USB-C taking power**: 5.1 kΩ from **each** CC pin to ground, one resistor per pin (a shared one fails with some cables). On a 16- or 24-pin receptacle join the two D+ pins and the two D− pins, so the plug works both ways up.
- The pair is 90 Ω differential; ESD protection at the connector, the pair routed **through** the protection part's pads on its way in; small series resistors at the chip where its guide asks.
- A device that draws more than the default asks properly (the CC pins' advertisement, or a controller chip for more than 5 V); 100 mA is safe on an old port, 500 mA is usual.

## I²C, crystals, LEDs, ADC inputs

- **I²C pull-ups**, one pair per bus: no smaller than (V − 0.4 V) / 3 mA (about 1 kΩ at 3.3 V), no larger than t_r / (0.85 × C_bus), with t_r 1000 ns at 100 kHz and 300 ns at 400 kHz: 4.7 kΩ suits a short 100 kHz bus, 2.2 kΩ a 400 kHz one. Every device's address differs; a bus that leaves the board gets protection.
- **A crystal's capacitors**: C1 = C2 = 2 × (C_load − C_stray), with C_stray about 3–5 pF; the chip's guide may add a series resistor.
- **An LED's resistor**: R = (V − V_forward) / I. A modern indicator LED is bright at 1–3 mA; check the resistor's power where the current is not small.
- **A divider into an ADC**: its two resistors in parallel must be below what the ADC's input tolerates, or it needs a capacitor at the pin and time to settle; the signal's highest value must be inside the ADC's range (a sensor that tops out the reference reads wrong only when it is warm).
- **A ceramic capacitor** loses much of its value at its working voltage, more in small packages: choose by the maker's DC-bias curve for the voltage it sits at, not by its printed value; twice the working voltage is a rule of thumb, not the check.

## Addressable LEDs

A capacitor of several hundred microfarads across the strip's supply at its start; 300–500 Ω in the data line at the first LED; a 5 V strip driven from a 3.3 V pin needs a level shifter (a 74AHCT-family buffer); the strip powered no later than what drives it; budget up to 60 mA for each LED at full white and feed long strips at more than one point.

## Tracks, vias and clearances by the numbers

**Width for current** is not a straight line. Outer layer, 1 oz copper, 10 °C rise (the usual chart's formula):

| Current | 0.5 A   | 1 A     | 2 A     | 3 A     | 5 A     |
| ------- | ------- | ------- | ------- | ------- | ------- |
| Width   | 0.12 mm | 0.30 mm | 0.78 mm | 1.37 mm | 2.77 mm |

An inner layer needs about 2.6 times the width for the same current, and many four-layer boards have thinner inner copper (0.5 oz), which doubles it again: carry power on the outside or in a pour. About one ordinary via (0.3 mm hole) per 200 mA between layers. `analyze dc` computes what the copper on the board really loses: the table is where to start.

**Clearance for voltage** (the layout standard's functional table, not a safety standard): outer layers under 30 V, the factory's minimum is enough; 31–150 V 0.64 mm; 151–300 V 1.25 mm. Mains is governed by a safety standard with larger distances: not from this table.

**Controlled impedance** depends on the stackup: on a common four-layer board with 0.2 mm to the plane, 50 Ω is about 0.35 mm wide and a 90 Ω pair about 0.25 mm with a 0.13 mm gap; on a two-layer 1.6 mm board 50 Ω would be about 2.9 mm, which is why controlled lines want four layers or a thinner board. These are starting widths: `analyze signal` computes the real copper, and the factory's stackup is what you tell it.

## The first power-up, written for the person

Hand this over with the board, in `DESIGN.md` under `# First power-up`, filled in for this board (which pads, which voltages):

1. Look: polarised parts the right way, no bridges on fine pins.
2. Unpowered: a meter between each rail and ground; a short is found now, not with power.
3. Power from a supply limited to a little above what the board should draw (50–100 mA when unknown); stop if it hits the limit.
4. Each rail's voltage at its test pad, in the order they come up (closing the links one by one where the board has them).
5. Then the program: a blink first, then each interface, then the application.
