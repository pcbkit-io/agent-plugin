# Parts and their datasheets

## Contents

- Finding parts
- The datasheet is the truth
- The pin table
- What a part needs around it
- Choosing values and ratings
- Reference designs
- When the library has no symbol or no footprint

## Finding parts

Find each part with `find_parts` and read it with `part`: it gives the pins by number, the footprint in a line (its pads, their extent and pitch; its KiCad text with `footprint: true`), stock and the datasheet's link. `save_part` puts its footprint and symbol into the project. Do not invent pad geometry or pin numbers for a part the library has. Passives, headers and common connectors are in KiCad's own libraries too, where KiCad is installed (reference/kicad-tools.md).

Prefer parts that are in stock in quantity and that a second maker also makes; say when a part is the only one of its kind. Every part gets its maker's number (`MPN`) and maker in its fields: a value like "10k" is not a part. The number is the whole orderable one: the package, the temperature grade and the output voltage are in its suffix, and a number cut short ("AP2112K") names several parts. A part is chosen in the size whoever builds the board can solder (0603 and larger by hand, as `DESIGN.md` says who builds it), in the size the schematic gave it.

## The datasheet is the truth

`part` answers with what the library has read from the part's datasheet (its supply range and absolute maximum, its currents, the parts to put around it), each with its page: start there, and say so when you build on it. For what it does not say, and always for the pin table of the package you chose, read the datasheet itself.

Get the datasheet of every part with more than two pins and keep it in the project as `refs/<part>.pdf` (`part` gives its link). `pdftotext -layout refs/<part>.pdf -` reads it; a table that comes out scrambled is read as a picture: `pdftoppm -r 120 -f 5 -l 5 -png refs/<part>.pdf /tmp/p` and look at the page. What you remember of a part is where to look, not what to build from: packages of one part number have different pinouts, and a second source's "compatible" part often differs in one pin.

Read, at least: the pin table for **the package you chose**, the absolute maximum ratings, the recommended operating conditions, the typical application circuit, and the layout section when there is one. For a processor or a radio, also get its maker's **hardware design guide** (reference/circuits.md): the reset circuit, the boot pins, the crystal's extra parts and the antenna's clearances are there, not in the pin table. And read a major chip's errata sheet. Note the page next to what you take from it (`DESIGN.md`: "FB divider per eq. 3, p.14").

## The pin table

Before a part's pins go on nets, write its pin table from the datasheet (in `DESIGN.md`, or `refs/<part>.pins.md` for a large part): number, name, what it is (supply, ground, input, output, open drain, analog, no connect), and what you connect it to. Then:

- **Every pin has a decision.** Connected, or left open because the datasheet says it may be. Several supply and ground pins all get connected; an exposed pad goes where the datasheet says (usually ground, sometimes a rail, sometimes nothing).
- **One function per pin.** A pin that can be UART or SPI is one of them on this board. List each pin's chosen function; two functions on one pin is a short or a dead interface.
- **A function goes on a pin that has it.** A processor's table of alternate functions says which pins can be which UART, which ADC channel, which timer's output; which pins wake it from sleep; which the radio or the flash takes; which are read at reset (strap pins) and must not be pulled the wrong way by what you connect. Choose each signal's pin from that table, and write the choice beside it.
- **Directions meet.** An output drives inputs; two outputs on one net fight unless both are open drain (then the net needs its pull-up). TX goes to RX. A pair's P and N do not swap unless the datasheet allows it.
- **Levels meet.** Each input sees a voltage inside its limits from what drives it (a 3.3 V pin from a 5 V output needs a level shifter or a divider, or a pin the datasheet calls 5 V tolerant).
- **Pin 1 and the view.** Tables are drawn from the top; a footprint mirrored or a connector drawn from the mating side reverses the order. Check a connector's pin order against what plugs into it.

The pins go into `scripts/design.py` by number from this table (reference/schematic.md). When the board file is written, read a chip's pins back against it (`nets { part: "U1" }`), and give each pad its `(pinfunction …)` and `(pintype …)` from it: the analyses read them.

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

- **A ceramic capacitor's dielectric** is part of its value. X7R or X5R for decoupling and bulk; C0G (NP0) wherever the value itself matters or the signal passes through it: a crystal's load capacitors, a timing capacitor, a filter's, an antenna's matching network, an audio path (the other dielectrics change with voltage and temperature, and sing or pick up vibration in audio). Never Y5V or Z5U on a new board. Check the dielectric's temperature range against where the device lives.
- **The capacitance a regulator's output may carry** has a lower limit for stability and often an upper one (its datasheet's range; a load switch or a soft-start limits the inrush into a large one). Add up what hangs on the rail, the decoupling of every chip on it included, at its real value under bias.
- **A resistor** for precision or low noise (a divider that sets a voltage, a sense resistor, an analog gain) is thin film, 1 % or 0.1 % as the error budget asks; thick film elsewhere.
- **An inductor** is chosen by its saturation current (above the peak, not the average), its resistance (it is a loss and heat) and its shielding (a shielded one beside anything sensitive); one in an antenna's matching network is a high-Q part. Inductors' footprints are their makers' own: take the footprint of this very part.
- A ceramic capacitor is chosen by what is left of it at its working voltage (the maker's DC-bias curve: small packages lose most), with a rating of at least twice that voltage as the rule of thumb; 1.25× for electrolytics; a resistor's power is at least twice what it dissipates (I²R: compute it for every resistor in a power path or a current sense); a connector and an inductor carry the current with margin.
- A part works inside its **recommended** conditions, not just under its absolute maximum: check each rail against each part on it, at the highest input the board may see.
- Compute what can be computed and write the numbers down: a divider's output, a filter's corner, an LED's current, a regulator's dissipation ((Vin − Vout) × I for a linear one) and its temperature rise from its package's thermal resistance. `ngspice` checks a filter, a divider or a loop before it goes on the board (reference/kicad-tools.md).

## Reference designs

A module, a connector or a chip with a reference design (a compute module, a radio module, a switching regulator's evaluation board) has its maker's schematic and often KiCad or mechanical files: get them into `refs/` and build from them, keeping the values and the layout notes. A carrier for a module starts from the module maker's carrier. Say in `DESIGN.md` what you took from where and what you changed. Put the maker's schematic beside yours as pictures and go through it block by block: a part theirs has and yours has not is a question to answer, not a difference to ignore.

## When the library has no symbol or no footprint

Look first: `find_parts` under the part's other numbers, and KiCad's own libraries by the package (`Package_SO`, `Package_DFN_QFN`, `Package_TO_SOT_SMD`: a part in a standard package wants the standard footprint of that package, checked against its drawing, not a new one). Make one only when neither has it, into the project's own `parts.kicad_sym` and `parts.pretty`, and say that it is yours and not the library's.

**A symbol** is the datasheet's pin table for this package, every pin of it:

- its number and its name as the table has them (an overbar is `~{RESET}`), and its electrical kind right: a supply pin `power_in`, a regulator's output `power_out`, an output, an input, open drain, bidirectional, passive, not connected. KiCad's electrical rules judge the schematic by these kinds: a symbol with every pin passive passes everything.
- inputs on the left, outputs on the right, supplies on top, grounds at the bottom, pins of one function together; pins 2.54 mm apart with their ends on the 1.27 mm grid.
- a pin with several functions carries the name of the one this board uses first; pins that are one net inside the part (several grounds) each stay a pin with its own number.
- then compare, by a few lines of script and not by eye: the symbol's numbers and names against the table, one for one, none missing and none twice. Draw the schematic and look at it.

**A footprint** is the datasheet's recommended land pattern (not the package's outline drawing: the pads are larger than the leads):

- write it down in numbers before drawing it: each pad's size, the pitch, the distance between rows, the exposed pad and its paste (often split into windows), which pad is 1 and from which side the drawing is seen;
- pads numbered as the symbol's pins, pad 1 marked on the silkscreen and the fabrication layer, a courtyard round everything, the origin at the part's centre;
- then `look` at it on a board (`look { around: … }`) and measure it back against the drawing: the pitch, the span over the rows, the pad count. A footprint that is one pin off in pitch or mirrored is found here or at the first assembly.

Change nothing in a library footprint for one board: copy it under a new name in the project and change the copy.
