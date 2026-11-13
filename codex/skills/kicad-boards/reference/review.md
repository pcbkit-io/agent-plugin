# Review: what no checker sees

Go through this against the board before you say it is done. Read as a reviewer who did not design it: for each line, find the evidence in the files (the pin, the value, the distance, the datasheet's page), not in your memory of having done it. Report by severity: **critical** (it will not work or will be damaged), **warning** (it may not work in some condition, or is hard to build), **note**. What the board is for sets the level: a missing ESD part is a warning on a hobby board and critical on a product. No evidence, no finding.

## Contents

- What it also needs
- Schematic and connections
- Power
- Signals
- What leaves the board
- Layout
- Mechanical and assembly
- Bring-up

## What it also needs

- [ ] Every line under `# What it also needs` in `DESIGN.md` that says "in" is on the board: the part is there, and it reaches a pin that can do the job (the battery's divider on an ADC-capable pin the radio does not take, the wake button on a pin that wakes, the charger's status on a GPIO).
- [ ] Walk the device's day once more against the finished board (reference/completeness.md): nothing the program or the person will want to know is left without a path.
- [ ] What was left out is written down with what the person then cannot do, and they were told.

## Schematic and connections

- [ ] Every part's pins match its datasheet's table for this package (number, function), and its footprint is that package (pin 1, pad count, pitch, the span over the rows, the exposed pad). For each part of more than two pins, the review names the datasheet's page for the pin table and the page for the land pattern, and says how sure it is (read from the page; read from a picture of the page; could not be read). "Checked" without a page is not checked: say so instead.
- [ ] `check` is clean: the schematic's electrical rules (or each message has its reason in `DESIGN.md`), and the board and the schematic connect the same pads.
- [ ] No input floats: every unused input, enable, reset and strap pin is tied where the datasheet says.
- [ ] No two outputs share a net (unless open drain, with its pull-up).
- [ ] Polarised parts face the right way: diodes, LEDs, electrolytic and tantalum capacitors, connectors' pin 1.
- [ ] Every programmable part can be programmed and debugged on this board (its connector or pads, its boot pins).

## Power

- [ ] Each rail's voltage is inside the recommended range of every part on it, at the lowest and the highest input.
- [ ] Each regulator's load is under its rating with margin; its dissipation and temperature rise are computed; its input and output capacitors are what its datasheet asks (value at the working voltage, ESR).
- [ ] Every supply pin has its decoupling; bulk capacitance where power comes in.
- [ ] Power-up order and enables are what the parts need (a core rail before I/O where the datasheet says).
- [ ] The input is protected against what a person can do: reversed polarity, a short on an output, a hot plug's surge.
- [ ] Ratings: capacitors at twice their working voltage, resistors at twice their dissipation, connectors and inductors above their current.

## Signals

- [ ] Logic levels match on every net between parts on different rails.
- [ ] Open-drain buses have pull-ups (once), to the right rail, of a value for the bus's speed and capacitance.
- [ ] TX meets RX; a pair's polarity is right; chip selects, enables and resets have the polarity the parts expect.
- [ ] Crystals have their load capacitors, computed; clocks go to pins that take a clock.
- [ ] Fast lines have their termination and coupling capacitors; analog inputs their filter for the sample rate.

## What leaves the board

- [ ] ESD protection on data lines at each connector that a person touches; current limit or fuse on power outputs.
- [ ] Each connector's pin order matches what plugs into it (straight or mirrored cable, the standard's pinout).
- [ ] USB-C: 5.1 kΩ on CC1 and another on CC2 (a device), the two D+ pins joined and the two D− pins joined on a receptacle, the pair routed through its ESD part, shield and ground as intended.
- [ ] Each connector's pins carry their current (a small battery connector is about an ampere a pin); a plug that can go in turned or shifted puts no supply on a signal.

## Layout

- [ ] DRC clean against the rules in force; nothing unconnected.
- [ ] Each decoupling capacitor is at its pin with a short loop; each regulator's loop is small; the feedback track is away from the switch node.
- [ ] Pairs run together over an unbroken plane, matched; no fast track crosses a gap in its plane.
- [ ] Power tracks and vias are wide and many enough for their current (`analyze dc`).
- [ ] Sensitive analog, crystals and radio are away from switchers and fast digital; the antenna's keep-out is clear on every layer.
- [ ] Hot parts have copper and thermal vias (`analyze heat`).
- [ ] Silkscreen: references readable, not on pads; pin 1 and polarity marked; the board's name and revision.

## Mechanical and assembly

- [ ] Connectors at the edges facing out, with room for their plugs; buttons, LEDs and displays on the side the person faces.
- [ ] Mounting holes where the enclosure has them, with room for screw heads, connected or isolated on purpose.
- [ ] No courtyards overlap; tall parts do not collide with each other or the enclosure (`look { view: "3d" }`).
- [ ] Parts on one side where possible; small two-pad parts have equal copper on both pads (so they do not stand up in the oven).
- [ ] Fiducials and the fab's keep-outs when a machine assembles it.

## Bring-up

- [ ] A test point on every rail and on what you would debug; a ground point for a probe.
- [ ] A way to power the board in parts (a 0 Ω link or a jumper between a regulator and its loads) on a first design, which is also where current is measured.
- [ ] The serial console's pads, the debug connector and a light the program controls are reachable, in the enclosure too.
- [ ] `DESIGN.md` has the first power-up for this board, step by step, for the person (reference/circuits.md).
