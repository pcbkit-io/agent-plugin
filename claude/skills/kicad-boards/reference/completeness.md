# What the device needs that nobody asked for

## Contents

- Why this list exists
- The method: a day with the device
- What you do with each item: in, asked, or left out
- Power coming in
- A battery
- The processor: starting, programming, debugging
- What the person sees, hears and presses
- Sensing and analog
- Motors, LEDs and other loads
- Radio
- Connectors and the world outside
- Who builds it
- The first power-up, and when it does not work
- By kind of device

## Why this list exists

A person says what the device should do. They rarely say what it takes to live with it: how they will know the battery is low, how the program gets in the second time, what happens when the plug goes in backwards. Someone who has built such a thing before adds these without being asked, or asks. Someone who has not finds out when the boards arrive: a handheld that works but cannot show its battery level, because nothing on the board measures it.

The rule behind every line below: **whatever the program or the person will want to know needs a path by which it can be known, and whatever they will want to do needs a part that does it.** A battery's level is a pin that reads it. "Is it charging" is the charger's status pin on a GPIO. "Turn it off" is a switch. A wish the board gives no path to cannot be added in software later.

## The method: a day with the device

Before the parts are chosen, walk through the device's life and write down what each moment needs. This finds what no list has.

1. **It arrives.** Which way up? What plugs in where? (labels, polarity marks, a power light)
2. **First power.** From what, through which connector, and what if it is the wrong supply or backwards?
3. **The program goes in**, and goes in again next week after a bad one. (a port, a way into the bootloader that needs no working program)
4. **It is used.** What does the person look at, press, hear? What must the program read to decide what to show? List every quantity: battery level, charging or not, power plugged in, each button, temperature, a motor's current, a fault. Each needs a pin that can read it.
5. **It misbehaves.** What can be measured, and where does the probe go? Can the program print? Can a part of the board be powered alone?
6. **The battery runs low**, it is charged, it sits in a drawer for a month. (a cut-off, a charger, a real off)
7. **It is built again**, by this person with an iron or by a factory. (part sizes, parts that can be bought)
8. **It goes into a case.** (holes, heights, which edge the connectors are on)

## What you do with each item: in, asked, or left out

Every item that applies gets one of three answers, written into `DESIGN.md` under a heading of its own (`# What it also needs`):

- **In.** Cheap and almost always wanted (a charger's status LED, a test pad on each rail, protection where a person can plug power in wrong, a way to read the battery): put it in and say so in one line with its reason: "R7/R8 let the program read the battery's voltage, so it can show its level."
- **Asked.** It changes the cost, the size or how the device is used (a fuel-gauge chip against a plain divider, an on/off switch, a second button, a display's backlight control): ask, with what each choice gives and costs, and a default you will take. All such questions together, once, at most five; a person who asked for the whole design gets the defaults and the list of what you chose.
- **Left out.** Not worth it here: write what the person will not be able to do ("No fuel gauge: the level is an estimate from voltage, coarse under load").

Say it to the person in their words, by what they will notice, not by the part: "without this you cannot show a battery icon", not "no ADC divider on VBAT". Do not lecture: three useful lines beat a page. And do not add what the device has no use for: every item below has its "not when".

What the board is for sets how hard to push: on a one-off or a hobby board a missing ESD part is a note, on something sold it is a must. Ask once whether this is a prototype, a hobby build or a product, and keep to the answer.

Then the program's side, as a table in `DESIGN.md`, one line for each thing the program must be able to read or do, with the pin that does it or the plain statement that the board does not:

```markdown
# What the program must know and control

| Question | How the board answers | Pin |
| Battery level | R7/R8 divider (1/3), switched by Q2 | GPIO4 (ADC1) |
| Charging or charged | U4 STAT, open drain, 10 kΩ pull-up | GPIO12 |
| USB plugged in | 5 V through 100 kΩ/100 kΩ | GPIO13 |
| Switch itself off | holds U5's enable | GPIO14 |
| Temperature | not on this board (the person agreed) | — |
```

A line with no pin is a thing the device will never be able to do: that is the moment to ask.

At the review (reference/review.md) go through both lists again against the finished board: each "in" is really there and really reaches a pin that can do it. The circuits behind many of the answers, with their numbers, are in reference/circuits.md.

## Power coming in

| Ask                                                         | Usual answer                                                                                                                                                                          | Not when                                                      |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Can power be plugged in backwards or from the wrong supply? | a P-channel FET or an ideal-diode chip in the input (a series Schottky where 0.3 V does not matter); a TVS diode where the cable is long or the supply is a car or a motor's          | USB-C only: the plug cannot be reversed                       |
| What limits the current when something shorts?              | a fuse or a resettable one on a battery and on power that leaves the board; a current-limited switch on a USB port that feeds others                                                  | a board fed only from a current-limited port, feeding nothing |
| USB-C as the source                                         | 5.1 kΩ from CC1 to ground and another from CC2 (never one shared): without them a C-to-C cable gives nothing. More than 5 V, or more than the default current: a sink controller chip | —                                                             |
| Two sources (USB and a battery, USB and a barrel jack)      | a power-path chip or two ideal diodes: decide what feeds the board when both are there, and that neither feeds the other                                                              | one source                                                    |
| Is there a way to turn it off?                              | a slide switch in the battery's path, or a soft latch a button and the program hold                                                                                                   | mains-style gadgets that are unplugged                        |
| A supply much higher than the rail (12 V or 24 V to 3.3 V)  | a switching regulator: a linear one turns the difference into heat ((Vin − Vout) × I)                                                                                                 | a few milliamperes                                            |
| Mains voltage on the board                                  | not on a first board: a certified supply module or an external adapter, and say so plainly                                                                                            | —                                                             |

## A battery

| Ask                                                                     | Usual answer                                                                                                                                                                                                                            | Not when                                 |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| How is it charged?                                                      | a charger chip for its chemistry (lithium: constant current then constant voltage), its current set for the cell (about half its capacity per hour unless the cell's sheet says more), from the same USB port that programs it          | primary cells                            |
| What protects the cell?                                                 | a protection chip with its two FETs (over-discharge, over-current, short), or a cell sold with its protection board: say which you rely on                                                                                              | —                                        |
| **Can the program read its level?**                                     | at least a divider from the battery to an ADC-capable pin (large resistors and a small capacitor, or switched by a FET so it draws nothing asleep); a fuel-gauge chip on I²C where a true percentage matters                            | the device has no way to show or send it |
| Can the program tell charging from charged from running on the battery? | the charger's status pin(s) on a GPIO and on an LED; the USB supply through a divider on a GPIO                                                                                                                                         | —                                        |
| Does the rail hold over the cell's whole range?                         | a lithium cell runs from 4.2 V down to about 3.0 V: a 3.3 V linear regulator needs its dropout below what is left near empty, or use a buck-boost; state at which cell voltage the device stops                                         | —                                        |
| What does it draw when "off" or asleep?                                 | add it up: the regulator's own current, dividers, pull-ups, LEDs, every chip's sleep current; switch a hungry part's rail with a load switch; no always-on power LED. Write the estimate and the battery life it gives into `DESIGN.md` | mains or USB powered                     |
| A coin cell feeding a radio                                             | a capacitor of tens to hundreds of microfarads beside it: the cell cannot give the transmit pulse                                                                                                                                       | —                                        |
| Which way round does the connector go?                                  | small battery connectors have no agreed polarity: mark + and − in silkscreen beside it, and say it to the person                                                                                                                        | soldered cells with marked pads          |

## The processor: starting, programming, debugging

| Ask                                                            | Usual answer                                                                                                                                                                                                                                        | Not when                                               |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| How does the program get in, the first and the hundredth time? | USB (the chip's own, or a USB-to-serial chip) or a debug header (SWD, JTAG, ISP); a bootloader that is entered without a working program: a BOOT button with a RESET button, or the auto-reset pair of transistors a serial bridge drives           | a module flashed in a fixture, and you added its pads  |
| Do the boot pins sit right at power-up?                        | each strapping pin pulled as its datasheet says, and nothing else on those pins that pulls the other way (a button, an LED, a peripheral's output)                                                                                                  | —                                                      |
| Can each pin do what it is given?                              | check the chip's pin table for every use: analog inputs on ADC-capable pins (and ones the radio does not take away), wake-up on pins that can wake, pins that are input-only, pins the module's flash uses, the fixed pins of USB, timers and buses | —                                                      |
| Is there a reset?                                              | a button on the reset or enable pin with the resistor and capacitor the datasheet shows                                                                                                                                                             | a device with a real off switch and no debugging ahead |
| Can it talk when USB does not work?                            | two pads or a header for the serial console's TX and RX, with ground                                                                                                                                                                                | the smallest boards                                    |
| Does it need a crystal?                                        | where USB, a radio or timekeeping needs the accuracy: read the datasheet's clock section; a 32.768 kHz one for a clock that keeps time asleep                                                                                                       | the internal oscillator is enough                      |
| Is anything left for later?                                    | unused pins on a small header or pads; an I²C connector in a common format (Qwiic, STEMMA QT) costs four pads and saves the next board                                                                                                              | a product with no room                                 |
| Which revision is this board?                                  | its name, revision and date in silkscreen; a resistor strap on a spare pin where the program must tell revisions apart                                                                                                                              | —                                                      |

## What the person sees, hears and presses

- **A light the program controls** is the cheapest debugger and the first sign of life: one LED on a GPIO. A separate power LED tells "no power" from "no program" (on a battery, make it one the program can switch off).
- **Buttons**: each on a pin with a pull-up (the chip's or a resistor), the one that wakes the device on a pin that can wake it, protection where a finger reaches the contact. A reset button the person can reach without opening the case, or none on purpose.
- **A display**: its backlight on a pin (through a transistor, dimmable) or it is always on; its reset pin; its connector's pitch, contact side and pin order checked against the display's own sheet (a mirrored flat cable is the classic mistake).
- **Sound**: the amplifier's shutdown pin on a GPIO (it hisses and drains otherwise).
- **Long waits get feedback**: charging, connecting, updating: a light, or a line on the display.

## Sensing and analog

- The signal fits the ADC: a divider or attenuation to bring it inside the range, a capacitor at the pin, the source's impedance low enough for the sample time; a reference where the supply is not steady enough.
- A sensor sits where it can sense: a temperature sensor away from the regulator and the processor; a motion sensor near the board's centre and fixed; a microphone's port and a light sensor's window clear, and facing out of the case.
- Every I²C device's address is checked against the others on the bus (two parts with one fixed address need two buses or a multiplexer); address pins tied, pull-ups once.
- Parts on different rails get a level shifter, or a pin the datasheet calls tolerant.

## Motors, LEDs and other loads

- **Off while the processor starts.** A load's driver has a pull-down (or pull-up) so it stays off until the program says otherwise: pins float during reset.
- **A coil gets its diode**: a relay, a solenoid, a motor driven by a single transistor. A driver chip is chosen for the stall current, not the running current, with its bulk capacitor beside it.
- **The motor does not reset the processor**: its supply separate from the logic's, or a diode and a large capacitor between them; ground returns that do not share a thin track.
- **The program can know what the load does** where it matters: a current-sense resistor to an ADC, the driver's fault pin on a GPIO, an encoder's or an end switch's connector.
- **A logic-level FET** is one fully on at the pin's voltage (its on-resistance stated at 2.5 V or 3.3 V, not only at 10 V), with a gate resistor.
- **Addressable LEDs**: the current budget first (up to 60 mA each at full white), power fed in at more than one point on a long strip, a bulk capacitor at the first LED, a level shifter where a 3.3 V pin drives a 5 V strip, a fuse.

## Radio

- A module with its own certified antenna for anything that is not a radio project; the antenna at the board's edge, over no copper on any layer, away from the battery, the display and metal.
- The supply holds through a transmit burst (several hundred milliamperes for Wi-Fi): a regulator rated for it and bulk capacitance at the module.

## Connectors and the world outside

- The connector fits the cable the person owns, the pin order matches what plugs into it (TX to RX, a flat cable's mirror), and it cannot go in wrong, or the right way is marked.
- Whatever a hand or a long cable reaches has ESD protection and, where it carries power out, a limit.
- Every connector's pins are named in silkscreen, with voltages and polarity; the board says which way is up.
- Mounting holes, and connectors on the edges an enclosure can open to; the tallest part known.

## Who builds it

Ask once, early: **will you solder it yourself, or should a factory assemble it?**

- **By hand**: parts with visible leads and 0603 or larger passives, no pads hidden under a part unless the person has hot air, one side, room between parts for an iron's tip.
- **By a factory**: parts it stocks (and its cheap "basic" passives), all on one side, fiducials, part numbers in the schematic's fields; connectors that go through the board are often cheaper soldered by hand afterwards.
- Either way: every part buyable today in the quantity needed, with a second choice for the ones that are one of a kind.

## The first power-up, and when it does not work

A first board is a test fixture for itself. Cheap, and almost always "in":

- a test pad on every rail and a ground point a probe can clip to;
- a way to feed or cut a section alone on a new design (a 0 Ω link or a solder jumper after each regulator), which is also where the battery's current is measured;
- the serial console's pads, the debug connector, the status LED;
- in `DESIGN.md`, the order of the first power-up: resistance between each rail and ground, power from a limited supply, each rail's voltage, then the program.

## By kind of device

What is most often missing, by what the device is. Use it as a second pass after the day with the device.

- **Battery handheld or wearable**: reading the battery's level; charge status on a pin and a light; a real off; the rail at low battery; sleep current; a wake button on a wake pin; the display's backlight control; a programming path that works with the case closed.
- **USB-powered gadget**: the two CC resistors; ESD on the data pair; the current asked from the port inside what it gives; a way into the bootloader; a status LED.
- **Sensor node on a coin cell or a small lithium cell**: the average current and the life it gives, written down; rails that switch off; the transmit pulse's capacitor; the sensor away from heat; a level reading; a console pad.
- **Motor or robot board**: loads off at reset; stall current; the motor's supply apart from the logic's; reverse-polarity and a fuse at the battery; current sense or fault to the program; connectors that carry the current; test pads.
- **LED lighting**: the current budget and the supply's connector for it; power injection; level shifting; heat in a linear driver; a fuse.
- **Audio**: the amplifier's shutdown; quiet supply for the analog part; a volume path; pops at power-on.
- **A HAT, shield or module carrier**: the standard's outline, holes and header position from its mechanical drawing; which of the host's pins are taken; the identification memory where the standard has one; no back-feeding the host's supply.
- **A dev board or breakout**: every pin labelled; pull-ups and an address choice by solder jumper; a connector in a common format; mounting holes.
- **A keyboard or other input device**: a diode per switch in a matrix; the bootloader's way in with the case closed; ESD at the port; the switch footprints the person's switches fit.
- **Anything with mains**: a certified module or an external supply, and nothing else until the person says they know why.
