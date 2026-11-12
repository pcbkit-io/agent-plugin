# The board as a running device: programs, runs, checks

Read this when the board has a processor and the work includes its program: firmware for a
microcontroller, or a script on a board that runs Linux. PCBKit runs the board as the device it
is: each processor executes the image its program builds (the file that is flashed onto the made
board, unchanged), wired to the board's parts as its nets wire them. You test the program before
anything is ordered, and the person watches the device work beside the board.

## The order

1. **The pins first.** The device's wiring is the board: its netlist while it has no copper, and
   its copper once it is routed (see "The board is the wiring" below). Each pad needs its pin's name
   (`pinfunction`), which KiCad writes when a board is made from its schematic, and which you
   write into a board you write as text (`(pad "17" … (net "LED") (pinfunction "PB5"))`). A
   processor is recognised by its value or part number (`ATmega328P-A`, `RP2040`,
   `ESP32-S3-WROOM-1`, `STM32F103C8T6`, a `Raspberry_Pi_2_3` header); a part by its value
   (`SSD1306`, `BME280`, `ILI9341`, `WS2812B`) and its pins' names (`SDA`, `SCL`, `MOSI`, `SCK`,
   `CS`, `DC`, `RESET`); an LED, a button, a switch and a potentiometer by their reference
   letters and what their other side is on.
2. **`device` with `plan`** says what it recognised: each processor's model, each part's model
   and which pin or bus it is on, and what it left out and why. Read it before writing the
   program: it is the pin table your program must agree with. A part on pins that cannot carry
   its bus (an I²C display on pins with no I²C function) is a finding about the board.
3. **What the board cannot say** goes into `.pcbkit/device.yaml`:

   ```yaml
   processors:
     U1: { model: esp32, firmware: fw/main } # a module under another name; a program elsewhere
   parts:
     J3: { model: servo, ports: { signal: 1 } } # a header that is a servo: its port's pad
     DS1: { model: ssd1306-i2c, parameters: { address: 61 } }
     U7: { model: none } # leave it out
   environment: { celsius: 23, humidity: 45, co2_ppm: 600, lux: 300 }
   keys: { KeyW: SW1, Space: SW2 } # the person's keyboard works these controls
   ```

   `pcbkit device parts` lists every model with its ports and parameters, and what each does and
   does not do. A file the program is built with and the project does not hold (a game's levels)
   is declared by where it is published and its SHA-256; it is fetched once, checked, and linked
   in under its name (PCBKit keeps a copy, so a build does not depend on that address staying up):

   ```yaml
   processors:
     U1:
       firmware: doom
       data:
         DOOM1.WAD: { url: "https://…/doom1.wad", sha256: "1d7d43be…", bytes: 4196020 }
   parts:
     U3: { firmware: guest } # a flash memory that holds a program for the machine the MCU emulates
   ```

4. **The program** is the folder `firmware` (`firmware/<reference>` when the board has several
   processors), a project of its own build system: PlatformIO (`platformio.ini`), an Arduino
   sketch (`.ino`), ESP-IDF, CMake with the Pico SDK, Zephyr, Cargo, a `Makefile`, or plain `.c`
   files: for an AVR compiled with avr-gcc as they are, for a chip with a kit (RP2040, RP2350,
   ESP32-C3/C6, CH32V003, STM32F103/F401/F411/G030/G431, SAM D21, nRF52, i.MX RT1062) compiled
   with clang against the kit: start-up, link layout, `<pcbkit/<chip>.h>` (pins, time, SPI, the
   console as stdio) and a C library, with nothing else to set up (`pcbkit device kit <model>`
   prints the kit's headers). Use the board's real pins from the plan.
   For a board that runs Linux (a Raspberry Pi), the folder is the program itself: `main.py` or
   `run.sh`, started at boot, with Python, libgpiod (`/dev/gpiochip0`), I²C and serial tools on
   the board's system.
5. **`device` with `build` and `steps`** builds and runs it, and checks what the device is for.

## Steps

A run goes on the device's own clock: as fast as the computer allows, and the same every time
(a Linux board goes at one second per second). Steps work the device and check it, in order:

```json
[
  { "until": { "console": "ready", "within": 2 } },
  { "expect": { "D1": "off" } },
  { "press": "SW1" },
  { "until": { "D1": "on", "within": 0.5 } },
  { "set": { "RV1": 0.8 } },
  { "wait": 0.3 },
  { "expect": { "J1": { "degrees": [140, 150] } } },
  { "type": "status\n" },
  { "until": { "console": "T=23", "within": 1 } },
  { "shot": "screen.png" }
]
```

- `wait`: seconds of the device's time.
- `set`: a control's value (a button or switch 1 or 0, a knob 0…1, a sensor's quantity by the
  part's reference). `press`: a button held for a tenth of a second (`{ "SW1": 0.5 }`: as long).
- `type`: text into the console (the first processor's; `{ "U2-console": "…" }` names another).
- `expect`: what holds now. `until`: the same, waited for (`within` seconds, 5 unless said).
  `console` is what was printed so far; a part is `on`, `off`, a number, or readings by name
  (`brightness`, `degrees`, `red`/`green`/`blue`, `value`; a screen has `lit`, the share of its
  pixels that are lit). A range is `[low, high]`.
- `shot`: the screens' pictures as files; the run's answer carries the first screen's picture.

An expectation that fails is a finding with what was seen instead; the run goes on. Write steps
that prove what the device is for (the reading appears, the button changes the mode, the motor's
pulse is the angle asked for), not that it started.

## The board is the wiring

A run follows the board as it is made, and a running device follows the board as it changes:

- **Copper.** Once the board has tracks or filled zones, two pads are connected when copper joins
  them, not when they share a net's name: an unrouted or cut connection is open (the plan lists
  the nets the copper leaves in pieces), a part behind it gets nothing, an input behind it floats.
  Before any copper is drawn the netlist is the wiring. `wiring: nets` in the device file keeps
  the netlist for a board whose routing is half done.
- **Power.** A part whose supply pin reaches no source through the copper is off: a display
  dark, a sensor silent. A processor without power does not run, and the device says it is off
  and why. The sources are what the board shows (a connector, a battery, a regulator's output).
- **Pulls and straps.** A resistor to a rail on a pin is the level the pin reads when nothing
  drives it; an input nothing drives and nothing pulls floats, and the plan says so.
- **Changes while it runs.** Save the board and the running device is wired anew, in place: the
  program and the parts keep their state; what lost its connection stops answering, what got it
  back answers again. A change of the processors themselves, or of the program's image, starts
  the device again.

## The device that runs live

A run with steps is yours: it starts, does what the steps say, and ends, the same every time.
The device a person watches on the page (they pressed Run) is another thing: it goes on at one
second per second, and it runs beside you, on the same computer. You can look at it and put a
hand on it:

- `device` with `live: []` (`pcbkit device live` in a shell) says its time, what its parts show,
  what its consoles printed last, and each screen as a picture file to look at.
- `["press","SW1","0.3"]`, `["set","RV1","0.8"]`, `["type","status\n"]`, `["key","ArrowUp"]`,
  `["wait","2"]`: what a person's hand would do, then what the device says a moment later.
- `["build"]` builds the program again and starts the device from its start; `["reset"]` only
  starts it again. A board file you save reaches the running device by itself.
- `["start"]` starts one when none runs (nobody pressed Run), `["stop"]` ends it. One you started
  ends by itself after ten minutes without a command.

Use the live device to see what the person sees ("the screen stays black after I press fire":
press fire, look at the picture, read the console) and to try things by hand. Prove the fix with
steps: they are the test that stays in the project.

## What a run is and is not

- Lines are ideal wires. What the copper does to a signal (rise times, voltage drop, crosstalk)
  is `analyze`'s reading, not this run's.
- Each model says what it does (`pcbkit device parts`): a chip's peripheral the model lacks stops
  the run with the reason or is listed. A radio (Wi-Fi, Bluetooth) is not simulated on the
  microcontroller models: a program that needs the network runs up to that call.
- A Raspberry Pi runs its real Linux; today its GPIO outputs reach the board's parts (read
  every 10 ms), not yet its inputs, I²C, SPI or PWM.
- The image the run used is the file that is flashed. A build puts each processor's in
  `.pcbkit/firmware/<its reference>.<elf, hex, uf2 or bin>` (`.pcbkit/firmware/U1.uf2`), one
  place whatever built it: say where it is when the work is done. A build's own folders
  (`.build`, `.pio`, `build`) stay on the computer that built.

## In a shell

`pcbkit device plan`, `pcbkit device build`, `pcbkit device run --steps tests/boot.yaml`
(`--seconds 5` without steps), `pcbkit device live [press SW1 | type … | start | stop]`,
`pcbkit device parts`, `pcbkit device kit <chip>`. Keep the steps that prove the device in the
project (`tests/*.yaml`): they are its test, run again after every change.
