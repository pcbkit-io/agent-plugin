---
name: kicad-boards
description: Designs and changes KiCad projects as text (.kicad_pcb boards, .kicad_sch schematics, .kicad_pro settings, symbol and footprint libraries) and takes a board from an idea to routed, checked and ready for a factory's review. Use before editing any KiCad file, designing or reviewing a board, choosing its parts, placing, routing or analysing it, or preparing its files for manufacturing.
---

# KiCad boards

A board that works is made by checking, not by being sure. What goes wrong is rarely the file's syntax: it is a pin on the wrong net, a part without what its datasheet demands, a capacitor far from its pin, a board called ready that nobody checked. So the work goes through gates, in order, and a tool decides each one, not your confidence. Each gate is cheap next to the one after it: a wrong pin costs a line now and a board later.

## The gates

Copy this list into your notes and tick it as you go. Do not start a step while the one before it fails.

```
- [ ] 1. DESIGN.md says what is being built: goal, supplies, blocks, every net with its pins
- [ ] 2. Every part with more than two pins has its pin table from its datasheet (reference/parts.md)
- [ ] 3. The board file holds the outline and the footprints with their nets; PCBKit's check of the write is clean
- [ ] 4. `nets` agrees with DESIGN.md pin by pin (and with the schematic's netlist, when there is a schematic)
- [ ] 5. Placement: fixed parts first, then by how little distance each connection tolerates (reference/placement.md); `look` at it
- [ ] 6. `route` connects everything; what it could not is fixed by moving parts, not by forcing tracks
- [ ] 7. `check`: KiCad's design rules, nothing unconnected
- [ ] 8. `analyze`: what it finds is fixed in the board (reference/analysis.md)
- [ ] 9. The review lists, read against the board (reference/review.md)
- [ ] 10. For a factory: its limits as rules, the files made and looked at (reference/manufacturing.md)
```

A small change to a board that exists (move a part, change a value) needs only the gates it touches: the write's check, `nets` for what was rewired, `route` if copper moved, `check`.

## 1. Write down what is being built: `DESIGN.md`

Before any part is chosen, write `DESIGN.md` in the project and keep it current. It is what the board is checked against, what the person reads to see whether you understood them, and what the next conversation (yours, or another agent's working beside you) reads first. Short and plain:

```markdown
# Goal

A 555 blinker on USB-C: one LED at about 2 Hz. 30 × 22 mm, two layers.

# Supplies

| Rail | Volts | From | Load |
| +5V | 5.0 | J1 (USB-C, 5.1 kΩ on CC1 and CC2) | 5 mA |

# Blocks

Power in (J1, R1, R2) → timer (U1, R3, R4, C1, C2) → LED (D1, R5)

# Nets

GND: J1.A1, J1.B1, J1.A12, J1.B12, U1.1, C1.2, C2.2, D1.K, R1.2, R2.2
+5V: J1.A4, J1.B4, J1.A9, J1.B9, U1.8, U1.4, R3.1, C3.1
…

# Decisions and what they rest on

- U1 is TLC555 (CMOS): 2 V–15 V, 170 µA (datasheet p.5), so R3 and R4 can be large.
- Assumed, not given: the LED runs at 3 mA.

# Not verified

- The blink rate on a real part (±20 % with these tolerances).
```

Where the goal is a number (efficiency, battery life, price, size), write it as a budget under its own heading before the parts are final, every term of the goal as the person stated it with its figure: for a power stage the watts lost in each part at the real current (from its datasheet), summed to the efficiency you expect; where the goal names cost or size, the parts' price and the board's area in the same table. A term left without a number is a term dropped, and the design over-builds on the ones that were counted.

For each net, say who drives it and at what voltage when it is not obvious: most wrong connections are a part given a role it does not have (a transistor's collector called a gate, an output joined to an output). Design a large board block by block (power, the processor, each interface), each with its own nets, and join them through named nets.

## 2. Parts and their datasheets

Read **reference/parts.md** before choosing parts. In short: find parts with `find_parts` and read them with `part` (the real footprint and pins); get each datasheet and copy the pin table from it before a pin is used; give every part what its datasheet makes mandatory. A design that rests on memory of a pinout is a guess.

## 3–4. The board file, and the connections read back

The files' format, the smallest valid board and how to change a board that exists are in **reference/format.md**. Write the outline (one closed shape on `Edge.Cuts`) and the footprints, each pad naming its net.

Then compare what `nets` reads from the file with `DESIGN.md`, pin by pin (`nets { part: "U1" }` gives one part's pins). A rule check cannot know that a pin is on the wrong net; this comparison can, because the two were written at different moments. Where there is a schematic, a third reading must agree: `kicad-cli sch export netlist`. Keep the schematic and the board in step: a part added to one belongs in the other, with the same reference and footprint.

Show the board once there is one (`show`, where the tool exists), so the person watches the rest.

## 5. Placement

Read **reference/placement.md**. Placement decides most of what routing can do: no track repairs a capacitor that is far from its pin. Then `look` at it: parts overlapping, off the board, crowded or far from what they serve are easier to see than to compute. `look { around: "U1" }` zooms in on a part; `look { view: "3d" }` is the board as an object. These pictures are yours alone.

## 6–8. Route, check, analyse

`route` draws the tracks and vias; never write `segment`s and `via`s by hand. Net classes, planes, pairs and what the analyses compute and are told are in **reference/analysis.md**. What `route` leaves open is a placement problem: move parts apart or turn them, and route again (`all: true` starts over).

`check` runs the syntax check and KiCad's design rule check where it can. `analyze` computes what the routed board means physically. What they find is yours to fix, not to list: change the design, route, and run them again, as many rounds as it takes. Boards are made by ripping up and trying again.

**A fix that failed twice is the wrong fix.** Stop repeating it and change something larger: move the part, turn it, give the board more room or two more layers, choose another part. If two tools disagree about the same thing (one says clean, one says not), find out which rule each applies before changing the board.

A finding that is not a fault (a rule tripped by something intended, such as two grounds joined on purpose) is answered with its reason, in `DESIGN.md` and to the person, never by loosening a rule quietly.

## 9. Review

Read **reference/review.md** and go through it against the board: the things no checker sees. A finding needs evidence (the pin, the datasheet's page, the measured distance); a suspicion without evidence is a question to look into, not a finding.

## 10. For a factory

Read **reference/manufacturing.md** before any file for a factory is made.

## What you tell the person

Say what you made, then three short lists: **verified** (which check, what it found, not what you expect), **assumed** (and on what), **not verified** (what needs a bench, a measurement or the factory's own check). Never call a board ready to manufacture on your own word: say which gates it passed. A board that passes every check here is a candidate for a person's review and a first build, not a product.

## Other references

- **reference/device.md**: the board as a running device: its program (the folder `firmware`, built by its own build system), the `device` tool's plan, runs and steps that prove what the device is for, the device file (`.pcbkit/device.yaml`). Read it when the board has a processor and the work includes its program.
- **reference/enclosure.md**: the device's enclosure: printed parts (a case, button caps, a stand), bought hardware (screws, inserts, nuts) and the assembly, written as a build123d program in `enclosure/enclosure.py` and built and checked by the `enclosure` tool. Read it when the person wants a case for the board or a device they can hold, before writing any of it.
- **reference/view.md**: the person's view as a file (`.pcbkit/view.yaml`): show them something, a back view, a tour of the board.
- **reference/kicad-tools.md**: `kicad-cli`, KiCad's Python and where it trips, KiCad's libraries, pictures of a schematic, simulation, what PCBKit's own shell has.

## After each write

PCBKit checks the KiCad files you wrote and reports syntax problems with line and column: fix them before anything else. The person sees every write at once, so work in steps that leave the files valid. Other agents and the person may be changing the same project: read a file again before you change it.
