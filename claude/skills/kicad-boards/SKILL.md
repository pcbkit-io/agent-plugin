---
name: kicad-boards
description: Read, write and change KiCad projects as text (.kicad_pcb boards, .kicad_sch schematics, .kicad_pro settings, symbol and footprint libraries), and take a board from an idea to routed and checked. Use before editing any KiCad file or designing a board.
---

# KiCad boards as text

KiCad files are S-expressions: one item per list, `(footprint …)`, `(segment …)`, `(via …)`, `(zone …)`, `(symbol …)`, each with its own `(uuid "…")`. Coordinates are millimetres, y grows downwards; `(at x y angle)` places an item. A project is `<name>.kicad_pro` (settings, net classes), `<name>.kicad_pcb` (the board) and `<name>.kicad_sch` (the schematic), named alike.

## A new board, in this order

1. **Parts.** Find each with `find_parts` and read it with `part`: it gives the real footprint (pads, sizes) as KiCad text and the pins by number. Do not invent pad geometry or pin numbers for a part the library has. Passives, headers and common connectors are in KiCad's own libraries too, where KiCad is installed (below).
2. **Connections, written down first:** every net with the pins on it (`GND: U1.4, C1.2, J1.2`). This list is what you check the board against later.
3. **Outline.** One closed shape on `Edge.Cuts` (a `gr_rect`, a `gr_circle`, or `gr_line`s and `gr_arc`s that meet end to end).
4. **Footprints with their nets.** Each pad names its net; pads of one net get connected by the router. Place parts inside the outline, at least 1 mm from the edge and from each other: connectors at the edges, a decoupling capacitor beside the pin it serves, parts that talk to each other close together, room between them for tracks.
5. **Show it** (`show`, once), so the person watches the rest.
6. **Compare** what `nets` reads from the file with your list, pin by pin (`nets { part: "U1" }` gives one part's pins). A design rule check cannot know that a pin is on the wrong net; this step can.
7. **Look** at it (`look`): parts overlapping, off the board, crowded, or far from what they serve are easier to see than to compute. `look { around: "U1" }` zooms in on a part (labels over pads, tracks squeezed between pins); `look { view: "3d" }` is the board as an object. These pictures are yours alone: the person sees only what the view file shows them (below).
8. **Route it** with `route`. Never write `segment`s and `via`s by hand. If it leaves connections unmade, move parts apart or turn them, then route again (`all: true` starts over).
9. **Analyze it** with `analyze`: the voltage each supply loses on the way to each load and back through ground, the copper's resistance to it, the current through each via and the densest copper. Its findings name the place (mm), the pads and the nets: widen that copper, add a pour or vias, or move the load, then route and analyze again. What the copper is (a resistance) is exact; volts follow currents, and where the board does not say them they are assumed and listed: write the real ones into `.pcbkit/analysis.yaml` (below) when the person or a datasheet gives them.
10. **Check it** with `check`: syntax, and KiCad's own design rule check where it can run. Fix what it lists. Then say what you made, what the check found (not what you expect), and what you did not verify.

For more than a few items, write the files with a short script (Python) instead of by hand: generate uuids, compute positions, print the S-expressions.

Before you call a board ready, the things no checker sees: every supply pin has its decoupling capacitor; reset, enable and open-drain lines (I2C) have their pull-ups; a crystal has its load capacitors; LEDs and polarised capacitors face the right way; a connector's pin order matches what plugs into it; a connector that takes its plug from the side (USB, a barrel jack, a card slot) sits at the board's edge with its opening facing out, also after the outline changed; nothing the part's datasheet calls mandatory is left floating.

## The smallest valid board

A resistor and an LED on one net, ready to route. Keep this shape: the layers table, the nets declared once and used by number and name in pads, a uuid on every item.

```
(kicad_pcb
	(version 20241229)
	(generator "pcbkit")
	(generator_version "1.0")
	(general (thickness 1.6))
	(paper "A4")
	(layers
		(0 "F.Cu" signal)
		(2 "B.Cu" signal)
		(5 "F.SilkS" user "F.Silkscreen")
		(1 "F.Mask" user)
		(13 "F.Paste" user)
		(25 "Edge.Cuts" user)
		(31 "F.CrtYd" user "F.Courtyard")
		(35 "F.Fab" user)
	)
	(net 0 "")
	(net 1 "VIN")
	(net 2 "LED_A")
	(net 3 "GND")
	(footprint "Resistor_SMD:R_0805_2012Metric"
		(layer "F.Cu")
		(uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0a01")
		(at 110 105)
		(property "Reference" "R1" (at 0 -1.65 0) (layer "F.SilkS") (uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0a02")
			(effects (font (size 1 1) (thickness 0.15)))
		)
		(property "Value" "330" (at 0 1.65 0) (layer "F.Fab") (uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0a03")
			(effects (font (size 1 1) (thickness 0.15)))
		)
		(attr smd)
		(pad "1" smd roundrect (at -0.9125 0) (size 1.025 1.4) (layers "F.Cu" "F.Mask" "F.Paste") (roundrect_rratio 0.243902)
			(net 1 "VIN") (uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0a04")
		)
		(pad "2" smd roundrect (at 0.9125 0) (size 1.025 1.4) (layers "F.Cu" "F.Mask" "F.Paste") (roundrect_rratio 0.243902)
			(net 2 "LED_A") (uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0a05")
		)
	)
	(gr_rect (start 100 100) (end 125 110)
		(stroke (width 0.1) (type default)) (fill no) (layer "Edge.Cuts") (uuid "6f0c2f0e-3b1c-4a53-9a51-2f1d8f1f0c01")
	)
)
```

- A pad's `(at …)` is relative to its footprint; a footprint turned by `(at x y 90)` turns its pads with it.
- A through-hole pad is `(pad "1" thru_hole circle (at 0 0) (size 1.7 1.7) (drill 1.0) (layers "*.Cu" "*.Mask") (net 3 "GND") (uuid "…"))`; pin 1 is usually `rect`.
- A part on the back has `(layer "B.Cu")` and its pads `"B.Cu" "B.Mask" "B.Paste"`.
- Wider power tracks and clearances are net classes in the `.kicad_pro` (`net_settings.classes`, with `netclass_patterns` naming the nets); the router follows them.

## Changing a board that exists

- Boards can be large (tens of megabytes). Find what you need with `grep -n` and read around it with `sed -n 'a,bp'` or the read tool's offset and limit; never read a whole board.
- A footprint is found by its reference: `grep -n '"Reference" "U3"'`, then read up to its `(footprint` line and its closing parenthesis.
- Make small, exact replacements of unique text (an item's uuid makes it unique). For many similar changes, use `sed` or a script over the file.
- Keep the file's own format: its `version`, tabs, how it names nets in pads (`(net 5 "GND")`, or `(net "GND")` in the newest files).
- Every new item gets a new random uuid (`uuidgen` or any v4 uuid). Never reuse one.
- Moving a footprint: change its `(at x y angle)`; its pads move with it. Tracks connected to it don't: route again.
- Keep the schematic and the board in step: a part added to one belongs in the other, with the same reference and footprint.
- If the person has the board open in KiCad, KiCad does not see your changes and will overwrite them when it saves: tell them to reload it there (File → Revert) first.

## What the person sees: the view file

`.pcbkit/view.yaml` is the person's view of the board, as a file. Read it to learn what they look at; write it to show them something (their view glides there). Every field is optional:

```yaml
view: 3d # 2d, 3d or schematic
select: [U1, C3, "net:GND"] # lit and framed: references, pads (U1/3), net:<name>, layer:<name>, item uuids
layers: { "B.Cu": false, "F.SilkS": true } # KiCad layer names shown or hidden
components: false # the bare board, without parts
explode: true # the copper layers apart
look: { mask: Black } # a mask colour to try in 3D (Green, Black, Blue, Red, White, Purple, Yellow, "#RRGGBB"); the design keeps its own
camera:
  2d: { center: [110, 105], width: 40 } # mm
  3d: { target: [110, 105, 0], yaw: 30, pitch: 40, distance: 120 }
tour: # takes the person round the board in 3D, stop by stop, with your words under it
  - show: [J1, R2, R3] # what the stop frames and marks (ids as in select)
    title: Power comes in # optional
    say: The USB-C socket takes 5 V. R2 and R3 tell the charger a device is here.
  - show: [U1, C1, C2]
    say: The regulator turns 5 V into 3.3 V. C1 and C2 keep it steady.
```

Angles of `camera.3d`: `yaw` 0 looks from the front (the board's bottom edge, as it reads), 90 from its right edge, 180 from the back edge, -90 from the left; `pitch` is degrees above the board (85 is from over it), negative from under it: the back of the board is `pitch: -50`. Leave `distance` out and the board is framed. `look { view: "3d", yaw, pitch }` gives you the same picture, to check what you are about to show.

"Show me the back", "zoom in on the regulator", "what does it look like in black" are changes of this file, not of the design.

"Walk me through it", "explain this board", "how does the power get to the chip" are a `tour`: a few stops in the order the story goes (the signal's or the power's way, not the references' order), each with a sentence or two a person can read in the time the camera turns round it: what the parts are there for, not their part numbers again. It plays as soon as the file has it; the person can pause it, step through it and close it (which takes it out of the file). The board's real colours and finish are in the `.kicad_pcb` (`setup` → `stackup`: the mask and silkscreen layers' `color`, `copper_finish`).

## Where KiCad is installed

`kicad-cli` and Python's `pcbnew` are there in PCBKit's own shell, and on the person's computer when they have KiCad (`kicad-cli version`; on macOS it is in `/Applications/KiCad/KiCad.app/Contents/MacOS`). When they are, use them for what text editing does badly:

- **KiCad's libraries**: footprints in `/usr/share/kicad/footprints/<Library>.pretty/<Name>.kicad_mod`, symbols in `/usr/share/kicad/symbols/<Library>.kicad_sym` (macOS: `/Applications/KiCad/KiCad.app/Contents/SharedSupport/`). `ls` and `grep` them; a `.kicad_mod` file is the footprint's text, ready to paste into a board with its reference, position and nets.
- **A board by script**: `pcbnew.LoadBoard(path)`, `pcbnew.FootprintLoad(library_dir, name)`, `footprint.SetPosition(pcbnew.VECTOR2I_MM(x, y))`, `pad.SetNet(net)`, `board.Add(footprint)`, `board.Save(path)`. Good for many parts at once, for arrays and circles of parts, and for measuring (`board.GetBoardEdgesBoundingBox()`, `footprint.GetBoundingBox()`).
- **Checks**: `check` already runs KiCad's design rule check where it can; `kicad-cli sch erc <file>` checks a schematic.
- **Files for a factory**: `kicad-cli pcb export gerbers`, `… drill`, `… pos` (placement), `kicad-cli sch export bom`, `kicad-cli pcb export step` (the 3D model), `… pdf`, `… svg`; `zip` the Gerbers and drill files together.
- **Simulation**: `ngspice -b circuit.cir` in PCBKit's shell, for a filter, a divider or a regulator's loop before it goes on the board.

## What the analyses are told: `.pcbkit/analysis.yaml`

Everything in it is optional; what it does not say is read from the board (names like `+3V3` and `GND`, a part's value, what joins two supplies) and listed in the answer under "Rests on".

```yaml
ambient: 25 # °C
rails:
  "+3V3":
    voltage: 3.3
    sources: [U2.5] # pins (U2.5) or whole parts (J1) the rail comes in by
    loads: { U1: 0.15, U3.4: 0.02 } # amperes, by part or by pin
    current: 0.4 # or the rail's whole load, shared among its loads
    tolerance: 0.03 # the share of the voltage it may lose
parts:
  U2: { power: 0.4 } # watts it sheds
```

## After each write

PCBKit checks the KiCad files you wrote and reports syntax problems with line and column: fix them before anything else. The person sees every write at once, so work in steps that leave the files valid.
