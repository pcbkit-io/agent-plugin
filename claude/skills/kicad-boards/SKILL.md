---
name: kicad-boards
description: Designs and changes KiCad projects as text (.kicad_sch schematics, .kicad_pcb boards, .kicad_pro settings, symbol and footprint libraries) and takes a device from an idea to a checked schematic and a routed, checked board ready for a factory's review, with what a beginner would not know to ask for. Use before editing any KiCad file, designing or reviewing a schematic or a board, choosing its parts or its layers, placing, routing or analysing it, advising on what a device needs, or preparing its files for manufacturing.
---

# KiCad boards

A board that works is made by checking, not by being sure. What goes wrong is rarely the file's syntax: it is a pin on the wrong net, a part without what its datasheet demands, a capacitor far from its pin, a board called ready that nobody checked, or a device that does what was asked and still cannot be lived with, because nobody thought about how its battery level is read. So the work goes through gates, in order, and a tool decides each one, not your confidence. Each gate is cheap next to the one after it: a wrong pin costs a line now and a board later.

The person watches the whole way. They see the schematic, then the board in 2D as it is placed and routed, then the finished thing in 3D, each when it is ready, with a sentence on what they are looking at (reference/view.md, "Show the work as it goes"). Many of them have never made a board: say things by what they will notice when they hold the device, and bring up what they did not know to ask for.

## The gates

Copy this list into your notes and tick it as you go. Do not start a step while the one before it fails.

```
- [ ] 1. DESIGN.md says what is being built: goal, who builds it and how, supplies, blocks
- [ ] 2. What it also needs that nobody asked for is decided: in, asked, or left out (reference/completeness.md)
- [ ] 3. Every part with more than two pins has its pin table from its datasheet (reference/parts.md)
- [ ] 4. The schematic is written from one description, and `check` (KiCad's electrical rules) is clean; the person has seen it (reference/schematic.md)
- [ ] 5. Layers are decided and set up: how many, what each carries, the widths and clearances as rules (reference/layers.md)
- [ ] 6. The board file holds the outline and the footprints with their nets; `check` says the board and the schematic connect the same pads
- [ ] 7. Placement: fixed parts first, then by how little distance each connection tolerates (reference/placement.md); `look` at it; the person sees it in 2D
- [ ] 8. `route` connects everything; what it could not is fixed by moving parts, not by forcing tracks
- [ ] 9. `check`: KiCad's design rules, nothing unconnected, still the schematic's connections
- [ ] 10. `analyze`: what it finds is fixed in the board (reference/analysis.md)
- [ ] 11. The review lists, read against the board, and "what it also needs" once more (reference/review.md)
- [ ] 12. The person is shown the finished board in 3D with a tour, and told what was verified, assumed and not checked
- [ ] 13. For a factory: its limits as rules, the files made and looked at (reference/manufacturing.md)
```

A small change to a board that exists (move a part, change a value) needs only the gates it touches: the schematic first when a connection or a part changes, the write's check, `route` if copper moved, `check`.

## 1. Write down what is being built: `DESIGN.md`

Before any part is chosen, write `DESIGN.md` in the project and keep it current. It is what the board is checked against, what the person reads to see whether you understood them, and what the next conversation (yours, or another agent's working beside you) reads first. Short and plain:

```markdown
# Goal

A 555 blinker on USB-C: one LED at about 2 Hz. 30 × 22 mm. Soldered by hand by a beginner.

# Supplies

| Rail | Volts | From | Load |
| +5V | 5.0 | J1 (USB-C, 5.1 kΩ on CC1 and CC2) | 5 mA |

# Blocks

Power in (J1, R1, R2) → timer (U1, R3, R4, C1, C2) → LED (D1, R5)

# What it also needs

- In: 0805 parts and an SOIC timer, because it is soldered by hand. A test pad on +5V and on ground.
- Asked: a second LED that shows power is there (default: yes).
- Left out: protection against a wrong supply: USB-C cannot be plugged in backwards.

# Layers

Two: parts and tracks on the front, ground on the back. Nothing here is fast.

# Decisions and what they rest on

- U1 is TLC555 (CMOS): 2 V–15 V, 170 µA (datasheet p.5), so R3 and R4 can be large.
- Assumed, not given: the LED runs at 3 mA.

# Not verified

- The blink rate on a real part (±20 % with these tolerances).
```

The nets themselves live in `scripts/design.py` (gate 4), once, not copied here: `DESIGN.md` says what and why, the script says what is joined to what.

`# Goal` is the person's, in their words: what they are building, the constraints they gave, the choices they made. When a message says something new about any of these, change it there first, then the design. It never holds your progress, a plan or a list of what is left: those are the conversation's.

Two things to settle at the start, by asking when the request does not say: **who builds it** (soldered by hand, or assembled by a factory: it decides the parts' sizes and packages) and **what it is powered from**. Everything else gets a default you name.

Where the goal is a number (efficiency, battery life, price, size), write it as a budget under its own heading before the parts are final, every term of the goal as the person stated it with its figure: for a power stage the watts lost in each part at the real current (from its datasheet), summed to the efficiency you expect; for a battery device the average current and the life it gives; where the goal names cost or size, the parts' price and the board's area in the same table. A term left without a number is a term dropped, and the design over-builds on the ones that were counted.

Design a large board block by block (power, the processor, each interface), each with its own nets, and join them through named nets. For each net, know who drives it and at what voltage: most wrong connections are a part given a role it does not have (a transistor's collector called a gate, an output joined to an output).

## 2. What it also needs

Read **reference/completeness.md** and walk the device's day before choosing parts: how it is powered and switched off, how the program gets in, what the person sees and presses, what the program must be able to read (a battery's level, whether it is charging, a fault), how it is measured when it does not work, who solders it. Each item is put in (and said in a line), asked (all questions at once, at most five, each with a default), or left out with what the person then cannot do. Write the three lists into `DESIGN.md`, and beside them the table of what the program must be able to read and do, each line with its pin. This is where a board that only does what was said becomes a device someone can use; it is also the easiest step to skip.

## 3. Parts and their datasheets

Read **reference/parts.md** before choosing parts. In short: find parts with `find_parts` and read them with `part` (the real footprint and pins); get each datasheet and copy the pin table from it before a pin is used; give every part what its datasheet makes mandatory. A design that rests on memory of a pinout is a guess.

## 4. The schematic

Read **reference/schematic.md**. Describe the parts and the net of each pin once, in `scripts/design.py` (written with `pcbkit.schematic`, which every PCBKit has), and draw it with the `schematic` tool: blocks in frames, two-pin parts wired to what they serve, a name on each chip pin. Its answer has what KiCad's electrical rules found (the input nothing drives, the two outputs on one net, the net name spelt two ways) and the sheet's picture: read every block of it (`look { view: "schematic", around: "U1" }` zooms in), change the description and draw again until it reads the way you would explain it. Then show it to the person (`view: schematic`) with a line on each block and the questions from gate 2: a misunderstanding caught here costs nothing.

## 5. Layers

Read **reference/layers.md**. Two layers or four, what each carries, and the widths, clearances and holes as rules in the project, decided now and written into `DESIGN.md` with the reason. The board's size and outline are chosen here too.

## 6. The board file, and the connections read back

Read **reference/format.md**. The board is made by its script, `scripts/board.py`, written with `pcbkit.pcb` and run with `pcbkit python scripts/board.py`: the outline, then `b.update(s)`, which puts the description's parts and nets on the board, then `b.place(…)`, the planes and `b.save()`. The script is run again at every change and keeps what is placed and routed: never build a board from nothing twice.

Then `check`: it compares the board with the schematic pad by pad and names every difference. A rule check cannot know that a pin is on the wrong net; this comparison can. `nets { part: "U1" }` reads one part's pins back when you want to see them against the datasheet's table.

Show the board once there is one (`show`, where the tool exists), so the person watches the rest.

## 7. Placement

Read **reference/placement.md**. Placement decides most of what routing can do: no track repairs a capacitor that is far from its pin. Then `look` at it: parts overlapping, off the board, crowded or far from what they serve are easier to see than to compute. `look { around: "U1" }` zooms in on a part; `look { view: "3d" }` is the board as an object. These pictures are yours alone; the person gets the 2D view with what you placed lit, and why it sits there.

## 8–10. Route, check, analyse

`route` draws the tracks and vias; never write `segment`s and `via`s by hand. Net classes, planes, pairs and what the analyses compute and are told are in **reference/analysis.md**. What `route` leaves open is a placement problem: move parts apart or turn them, and route again (`all: true` starts over).

`check` runs the syntax check and KiCad's own checks where it can. `analyze` computes what the routed board means physically. What they find is yours to fix, not to list: change the design, route, and run them again, as many rounds as it takes. Boards are made by ripping up and trying again.

**A fix that failed twice is the wrong fix.** Stop repeating it and change something larger: move the part, turn it, give the board more room or two more layers, choose another part. If two tools disagree about the same thing (one says clean, one says not), find out which rule each applies before changing the board.

A finding that is not a fault (a rule tripped by something intended, such as two grounds joined on purpose) is answered with its reason, in `DESIGN.md` and to the person, never by loosening a rule quietly.

## 11. Review

Read **reference/review.md** and go through it against the board: the things no checker sees. A finding needs evidence (the pin, the datasheet's page, the measured distance); a suspicion without evidence is a question to look into, not a finding. Then `# What it also needs` in `DESIGN.md` once more: each thing you said is in, is on the board and reaches a pin that can do it.

## 12. What you show and tell the person

Show the finished board in 3D and walk them round it with a `tour` (reference/view.md): where power comes in, what each block does, what they will plug in and press.

Then say what you made, and three short lists: **verified** (which check, what it found, not what you expect), **assumed** (and on what), **not verified** (what needs a bench, a measurement or the factory's own check). Add what you would do next if it were yours: the one or two things that would make the device better or the first build safer, each with what it costs. Leave the first power-up for this board in `DESIGN.md`, step by step (reference/circuits.md): the person who receives the boards reads it with a meter in hand. Never call a board ready to manufacture on your own word: say which gates it passed. A board that passes every check here is a candidate for a person's review and a first build, not a product.

## 13. For a factory

Read **reference/manufacturing.md** before any file for a factory is made.

## Advising the person

You are the one in the conversation who has built boards before. That means saying things the person did not ask about, at the moment they are cheap:

- **By what they will notice**, not by the part: "you could not see the battery's level" rather than "no divider on VBAT".
- **With the cost**: a part, a few square millimetres, a pin, a dollar. A recommendation without its cost is a sermon.
- **Sorted**: what you put in because it is nearly free and nearly always wanted; what you ask about; what you left out. Never a wall of warnings.
- **Once.** Ask your questions together, take the defaults when the person says "just build it", and do not ask again what `DESIGN.md` already answers.
- **Honest about what you do not know**: a figure from a datasheet has its page; a guess is called a guess.

## Other references

- **reference/circuits.md**: the circuits that recur, with their numbers: a chip maker's hardware design guide and what it holds, a lithium cell from the port to the program, USB-C, I²C pull-ups, crystals, addressable LEDs, track widths for current, and the first power-up written for the person. Read it when the design has one of these.
- **reference/device.md**: the board as a running device: its program (the folder `firmware`, built by its own build system), the `device` tool's plan, runs and steps that prove what the device is for, the device file (`.pcbkit/device.yaml`). Read it when the board has a processor and the work includes its program.
- **reference/enclosure.md**: the device's enclosure: printed parts (a case, button caps, a stand), bought hardware (screws, inserts, nuts) and the assembly, written as a build123d program in `enclosure/enclosure.py` and built and checked by the `enclosure` tool. Read it when the person wants a case for the board or a device they can hold, before writing any of it.
- **reference/view.md**: the person's view as a file (`.pcbkit/view.yaml`): what to show them at each step, a back view, a tour of the board.
- **reference/kicad-tools.md**: `kicad-cli`, KiCad's Python and where it trips, KiCad's libraries, pictures of a schematic, simulation, what PCBKit's own shell has.

## After each write

PCBKit checks the KiCad files you wrote and reports syntax problems with line and column: fix them before anything else. The person sees every write at once, so work in steps that leave the files valid. Every file in the project's folder is the project's: the person sees it, and a second board or project file there stands in the tools' way. Try things in `/tmp` (a copy of the board, a symbol you are testing), and keep what you fetched to read (datasheets, a reference design) under `refs/`. Other agents and the person may be changing the same project: read a file again before you change it. What the person has selected is in the view file (`select`): when what you are about to change is what they are at and they did not ask for it, say so in a line and do something else first.
