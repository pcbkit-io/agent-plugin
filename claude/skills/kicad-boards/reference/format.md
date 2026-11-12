# KiCad files as text

## Contents

- The smallest valid board
- Layers, pads, parts on the back, net classes
- Four layers: planes
- Changing a board that exists

KiCad files are S-expressions: one item per list, `(footprint …)`, `(segment …)`, `(via …)`, `(zone …)`, `(symbol …)`, each with its own `(uuid "…")`. Coordinates are millimetres, y grows downwards; `(at x y angle)` places an item. A project is `<name>.kicad_pro` (settings, net classes), `<name>.kicad_pcb` (the board) and `<name>.kicad_sch` (the schematic), named alike.

For more than a few items, write the files with a short script (Python) instead of by hand: generate uuids, compute positions, print the S-expressions. Keep the script in the project (`scripts/`): the next change runs it again.

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

- **Four layers:** the inner two are planes, not routing layers: ground under the signals (`In1.Cu`), power or a second ground (`In2.Cu`). Give each a `zone` of its net over the whole board, and one rule area over the board on both inner layers that keeps tracks out and lets vias and pours in (in KiCad's Python: `z.SetIsRuleArea(True); z.SetDoNotAllowTracks(True)`, the other `SetDoNotAllow…` false). `route` then draws on the outer layers and reaches the planes by vias; a fast pair keeps an unbroken plane under it. Without the rule area the router uses the inner layers as it uses any other.
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
- Keep the schematic and the board in step: a part added to one belongs in the other, with the same reference and footprint; where the project has `scripts/design.py`, change the design there and write both from it (reference/schematic.md). `check` names every pad where they differ.
- If the person has the board open in KiCad, KiCad does not see your changes and will overwrite them when it saves: tell them to reload it there (File → Revert) first.
