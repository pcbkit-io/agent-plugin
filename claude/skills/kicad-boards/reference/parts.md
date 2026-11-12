# Parts and their datasheets

## Contents

- Finding parts
- The datasheet is the truth
- The pin table
- What a part needs around it
- Choosing values and ratings
- Reference designs

## Finding parts

Find each part with `find_parts` and read it with `part`: it gives the real footprint (pads, sizes) as KiCad text, the pins by number, stock and the datasheet's link. `save_part` puts its footprint and symbol into the project. Do not invent pad geometry or pin numbers for a part the library has. Passives, headers and common connectors are in KiCad's own libraries too, where KiCad is installed (reference/kicad-tools.md).

Prefer parts that are in stock in quantity and that a second maker also makes; say when a part is the only one of its kind. Every part gets its maker's number (`MPN`) and maker in its fields: a value like "10k" is not a part.

## The datasheet is the truth

`part` answers with what the library has read from the part's datasheet (its supply range and absolute maximum, its currents, the parts to put around it), each with its page: start there, and say so when you build on it. For what it does not say, and always for the pin table of the package you chose, read the datasheet itself.

Get the datasheet of every part with more than two pins and keep it in the project (`curl -L -o refs/<part>.pdf <link>`; `pdftotext -layout refs/<part>.pdf -` reads it; a table that comes out scrambled is read as a picture: `pdftoppm -r 120 -f 5 -l 5 -png refs/<part>.pdf /tmp/p` and look at the page). What you remember of a part is where to look, not what to build from: packages of one part number have different pinouts, and a second source's "compatible" part often differs in one pin.

Read, at least: the pin table for **the package you chose**, the absolute maximum ratings, the recommended operating conditions, the typical application circuit, and the layout section when there is one. Note the page next to what you take from it (`DESIGN.md`: "FB divider per eq. 3, p.14").

## The pin table

Before a part's pins go on nets, write its pin table from the datasheet (in `DESIGN.md`, or `refs/<part>.pins.md` for a large part): number, name, what it is (supply, ground, input, output, open drain, analog, no connect), and what you connect it to. Then:

- **Every pin has a decision.** Connected, or left open because the datasheet says it may be. Several supply and ground pins all get connected; an exposed pad goes where the datasheet says (usually ground, sometimes a rail, sometimes nothing).
- **One function per pin.** A pin that can be UART or SPI is one of them on this board. List each pin's chosen function; two functions on one pin is a short or a dead interface.
- **Directions meet.** An output drives inputs; two outputs on one net fight unless both are open drain (then the net needs its pull-up). TX goes to RX. A pair's P and N do not swap unless the datasheet allows it.
- **Levels meet.** Each input sees a voltage inside its limits from what drives it (a 3.3 V pin from a 5 V output needs a level shifter or a divider, or a pin the datasheet calls 5 V tolerant).
- **Pin 1 and the view.** Tables are drawn from the top; a footprint mirrored or a connector drawn from the mating side reverses the order. Check a connector's pin order against what plugs into it.

When the board file is written, compare its pins with this table (`nets { part: "U1" }`), and give each pad its `(pinfunction …)` and `(pintype …)` from it: the analyses read them.

## What a part needs around it

What the datasheet's application circuit shows is part of the part:

- **Every supply pin its decoupling capacitor**, of the value the datasheet names, and bulk capacitance where a rail comes in.
- **A regulator** its input and output capacitors (with the ESR and the effective value it asks for: a ceramic loses much of its capacitance at its working voltage), its feedback divider computed from its reference voltage, its inductor rated above the peak current, its enable and soft-start pins decided, its compensation as shown.
- **A crystal** its load capacitors, computed from the crystal's load capacitance and the stray capacitance; only where the chip has the oscillator for it.
- **Reset, enable, boot and strap pins** their pull-ups or pull-downs, to the right rail, so the part starts in the mode you mean. A programming or debug connector for every part that is programmed.
- **Open-drain lines** (I²C, interrupts, power-good) their pull-ups, once per bus.
- **What leaves the board** its protection: a fuse or a current limit on power going out, ESD protection on data lines to a connector, reverse-polarity protection where a person can plug power in backwards. USB-C needs 5.1 kΩ on each CC pin to be given power.
- **Fast lines** their termination and their coupling capacitors where the interface asks.

## Choosing values and ratings

- A capacitor's voltage rating is at least twice its working voltage for ceramics (they lose capacitance with voltage), 1.25× for electrolytics; a resistor's power is at least twice what it dissipates (I²R: compute it for every resistor in a power path or a current sense); a connector and an inductor carry the current with margin.
- A part works inside its **recommended** conditions, not just under its absolute maximum: check each rail against each part on it, at the highest input the board may see.
- Compute what can be computed and write the numbers down: a divider's output, a filter's corner, an LED's current, a regulator's dissipation ((Vin − Vout) × I for a linear one) and its temperature rise from its package's thermal resistance. `ngspice` checks a filter, a divider or a loop before it goes on the board (reference/kicad-tools.md).

## Reference designs

A module, a connector or a chip with a reference design (a compute module, a radio module, a switching regulator's evaluation board) has its maker's schematic and often KiCad or mechanical files: get them (`git clone`, `curl`) into `refs/` and build from them, keeping the values and the layout notes. A carrier for a module starts from the module maker's carrier. Say in `DESIGN.md` what you took from where and what you changed.
