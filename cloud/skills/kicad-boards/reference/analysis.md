# Routing and the analyses

## Contents

- What the router is told
- Planes and four layers
- Critical nets
- What `analyze` computes
- Fixing what it finds
- What the analyses are told: `.pcbkit/analysis.yaml`

## What the router is told

`route` draws every connection that is not made, on the layers the board has, by the rules the project gives it. It knows widths, clearances and where tracks may not go; it does not know that two tracks are a pair or that a net is sensitive. So say it in the files before routing:

- **Net classes** in the `.kicad_pro` (`net_settings.classes`, with `netclass_patterns` naming the nets): a power net its width for its current (about 0.3 mm per ampere on outer 1 oz copper for a 10 °C rise, wider when in doubt), a controlled net the width that gives its impedance on this stackup, high-voltage nets their clearance.
- **Rule areas** where tracks must not go: under an antenna, under a crystal, across a gap in a plane, between a switch node and a feedback divider.
- **Pours** for ground and for supplies with many loads: a `zone` of the net; the router connects pads into it.

Route, read what it could not connect and why, and change the placement rather than the rules. `all: true` routes everything again after parts moved.

## Planes and four layers

A fast signal's return current flows in the plane right under it. A board with a processor, a radio, USB or anything faster wants four layers: the inner two are planes, not routing layers (ground under the signals on `In1.Cu`, power or a second ground on `In2.Cu`). How to set that up, with the rule area that keeps tracks out of the planes, is in reference/format.md. A two-layer board gets a ground pour on the back, kept as whole as the routing allows; a track that crosses a slot in the pour under it has no return path there.

## Critical nets

The nets that tolerate least are placed first (reference/placement.md) and checked first after routing:

- **Differential pairs** (USB, Ethernet, HDMI, LVDS, CAN): named `_P`/`_N` (or `+`/`-`) so the analyses see them; both tracks side by side over an unbroken plane, the same length (`analyze` reports the skew), no stubs, the same number of vias. The router draws them as two tracks: look at the result (`look { around }`) and move parts until the pair runs together.
- **Switch nodes and their loops**: short and wide, nothing sensitive beside or under them.
- **Feedback and sense tracks**: from the point they measure (the output capacitor, the sense resistor's pads), away from the inductor and the switch node.
- **Crystals and clocks**: short, with ground around, nothing crossing under.
- **Antenna feeds**: the width that gives 50 Ω on this stackup, straight, with the matching parts on the line.

## What `analyze` computes

All of it, or the `kinds` named:

- `dc`, the voltage each supply loses on the way to each load and back through ground, the copper's resistance, via currents, and each part's supply against what its datasheet lets it be (a rail over a part's maximum or under its minimum, a regulator asked for more than it gives, also when a radio transmits, or left without its dropout)
- `signal`, each track's impedance from a field solve of the copper it runs over, against its target (a net class like `50R`, a pair named `_P`/`_N`, an interface's name), pairs' skew, tracks with no plane under them, crosstalk
- `heat`, the board's temperature under each part
- `pdn`, each supply's impedance over frequency at its load, capacitors that are missing or too far
- `emc`, each net's loop with its return
- `channel`, a fast net end to end with its eye
- `wave`, a pulse followed through the copper in time (when it reaches each pad, what comes back
- the person sees it as a film)
- `magnetic`, the field of the supply currents over the board and over each part.

Its findings name the place (mm), the parts, pads and nets: change that copper or move that part, route and analyze again. The analysis reads what each pin is from the pads' `(pinfunction "VIN") (pintype "power_in")` (KiCad writes them from the schematic's symbols) and skips parts with `(attr … dnp)`: keep both when you write or change footprints, and give a part you add its pins' types, or supplies, regulators and drivers are guessed from names. What the copper is (a resistance, an impedance) is exact; volts and degrees follow currents and powers, and where the board does not say them they are assumed, listed, and said as what would be: write the real ones into `.pcbkit/analysis.yaml` (below) when the person or a datasheet gives them.

## Fixing what it finds

A finding names the place, the parts and the nets: change that copper or move that part, then route and analyze again. What it usually wants:

| Finding                                | Usual fix                                                                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| A rail loses too much on the way       | a wider track or a pour, more vias in parallel, the regulator nearer its load                                                       |
| A regulator or a part runs hot         | more copper on its pads, thermal vias under it to a plane, a more efficient part (a switcher for a linear regulator dropping volts) |
| A pair or a line is off its impedance  | another width or gap for this stackup (compute it), a net class for it                                                              |
| A track has no plane under it          | move it, or close the gap in the plane                                                                                              |
| A supply's impedance is high at a load | a capacitor nearer the pin, a second smaller one, its via beside its pad                                                            |
| Skew in a pair                         | parts moved so the pair runs straight; length added to the short track near the mismatch                                            |
| Crosstalk                              | distance between the two tracks (three track widths), or a layer between them                                                       |

Leave a finding open only when it needs what you cannot get (a measurement, a part nobody stocks), and say which. A part over its temperature is never left as a note: it gets copper, a heatsink that is in the design (a part with its footprint, its K/W and its mounting), or another part that sheds less.

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
  GND:
    sources: [J2] # ground: where the return current leaves the board (the supply's return terminal)
parts:
  U2: { power: 0.4 } # watts it sheds
signals:
  "/USB_D+": { impedance: 90, rise: 0.5e-9 } # Ω (a pair's differential one), edge in seconds
```
