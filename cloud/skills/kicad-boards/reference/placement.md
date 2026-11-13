# Placement

## Contents

- Why parts go where they go
- The order
- By kind of part
- Where it goes wrong
- Keep every pad reachable
- Check, look, fix
- When pins cross: change the schematic

Placement decides most of what routing can do. A part in the wrong place makes a track long, a current loop large or a pad unreachable, and no routing repairs that. Compute positions from pad coordinates (`part` gives them; KiCad's Python measures), not from a picture: an estimate by eye is often off by more than a small part is long. Parts are placed by the board's script (`b.place(…)`, reference/format.md), so a placement is numbers you can change and run again.

## Why parts go where they go

Work from these reasons; the rules follow from them, and when a rule and a reason disagree on a board, follow the reason.

- **Current flows in loops.** It goes out on one conductor and comes back on another, usually ground. The loop's area sets what it radiates and picks up, its length its inductance. A decoupling capacitor helps only if the loop from its pads to the chip's supply and ground pins is small. A switching regulator has one loop whose current switches in nanoseconds (in a buck: the input capacitor, the switches and their ground return): the datasheet's layout section names it, and it comes first.
- **Some connections tolerate distance and some do not.** A slow GPIO can cross the board. A decoupler, a switch node, a crystal, an RF node, a feedback divider or a filter on a sensitive input cannot. Rank the connections before placing anything and give the space next to the pins to those that tolerate least.
- **Noisy and sensitive circuits need distance.** Switch nodes, clocks and digital buses are noisy; crystals, analog inputs, references, feedback nodes and radio are sensitive. Keep the one's copper away from the other's.
- **Some things are fixed before you start.** Connectors, buttons, LEDs, mounting holes, an antenna and its keep-out, the outline, what an enclosure dictates.
- **A placed part must stay reachable.** Every pad needs a way for a track to reach it, every ground pad a place for a via, every row of fine pins room in front of it for its tracks to leave.
- **The board's size is chosen, not found.** Where the person gave none, take the smallest outline the parts, their heat and their copper allow, and write it into `DESIGN.md`. A board that routes because it is large and sparse costs more, carries longer loops and fits nothing: once it routes clean, try it smaller.
- **The board must be built.** Courtyards do not overlap; parts on one side cost less to assemble; polarised parts facing one way are easier to inspect; hot parts want copper and air.

## The order

1. **Fixed parts**, from the mechanical needs: connectors at the edges with their openings facing out (a connector that takes its plug from the side sits at the edge, also after the outline changed), mounting holes, what the person touches or sees on the side they face.
2. **The large chips**: turn each so that its pins face what they go to, at the distance its nearest chain needs. `print(b.pins("U1"))` in the board's script says which side each pin is on as the chip sits: read it at all four angles and take the one where pins to a connector face it, pins that leave the area face where they go, and pins with local parts (supplies, a regulator, a clock) face room for those parts. The schematic's sheet says nothing about this. The distance to a fixed part is what goes between: a connector's protection parts, a radio pin's matching chain. When the chain does not fit, the chip moves; the chain is not stretched.
3. **What tolerates no distance**: a regulator's power loop, radio matching, then every decoupling and filter capacitor at its own pin, then crystals with their load capacitors.
4. **What serves those**: bulk capacitors behind the small ones, series resistors, ferrites, pull-ups, protection parts beside their connector.
5. **Everything that tolerates distance.**

When a large part and a small capacitor compete for the place at a pin, the large part moves. Follow the signal's or the power's way across the board (in at one edge, through, out at another), so tracks run the way the current does and blocks do not cross each other.

## By kind of part

| Part                                             | Where                                                                                                                                                                                                                                                |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Decoupling capacitor                             | at its supply pin, its supply pad towards the pin, its ground pad with a via beside it; the smallest value closest                                                                                                                                   |
| Bulk capacitor                                   | where the rail comes in, and behind the small capacitors it backs                                                                                                                                                                                    |
| Switching regulator                              | the loop the datasheet names as small as possible; the switch node short and away from everything sensitive; the inductor's output pad at the output capacitor; the feedback divider at the feedback pin, away from the switch node and the inductor |
| Linear regulator                                 | its capacitors at its pins; copper for its heat                                                                                                                                                                                                      |
| Crystal                                          | both pads close to their two pins, at nearly equal distance, its load capacitors beside it, nothing routed underneath or between                                                                                                                     |
| Radio module or antenna                          | at the edge or a corner, its antenna over no copper on any layer (the keep-out its datasheet draws), away from tall metal parts                                                                                                                      |
| Connector's protection (ESD diode, fuse, filter) | between the connector and the rest, close to the connector, the line running through the protection part's pad on its way in, a ground via at the part                                                                                               |
| Termination                                      | a series resistor at the driving pin, a parallel one at the far end                                                                                                                                                                                  |
| Pull-up                                          | anywhere on a slow net; a boot or strap pin's beside the chip (it must be right at reset)                                                                                                                                                            |
| Current-sense resistor                           | in the current's path, its two sense tracks from its pads' inner edges, together                                                                                                                                                                     |
| Test points                                      | where a probe can reach, on every rail and on what you would debug                                                                                                                                                                                   |

Use the parts the design has; do not add a ferrite or a capacitor the schematic and the datasheet do not have to make a placement work.

Where one supply reaches several pins of a chip and there are capacitors enough, each pin gets one, on whichever side of the package it is. With fewer capacitors than pins, neighbouring pins share one, grouped the way the datasheet's layout shows.

## Where it goes wrong

- **Two parts at neighbouring pins.** Side by side, each in line with its pin, they fit only when their two courtyards together are no wider than twice the pin pitch: two 0402s at a 0.5 mm pitch do not. Plan the pair together: one further out by its own length, or shifted sideways, or the two pins' parts swapped.
- **A row of capacitors in front of pins that must leave.** A track from further out needs a way through the row: leave the gap when the capacitors go down, not after.
- **A switching regulator whose switch pin and output pin are neighbours** (common where the converter is inside a larger chip). The inductor joins both, and the output capacitor belongs at the output pin. An inductor laid along the row of pins keeps both its pads at their pins; one turned across the row carries its output pad, and the output capacitor behind it, away. Try both and keep the one whose output capacitor reaches its pin.
- **A part across two pins** (a crystal, a flying capacitor). Its two tracks should be nearly as long as each other: each adds stray capacitance to its side, and a short one with a long one unbalances the load. Turning it half round, sliding it along the chip's side, or (a four-pad crystal has its two signal pads on opposite corners) each of the four angles gives other lengths: measure them, do not judge by eye. Prefer the balanced place when it costs little length; do not buy balance with much length.
- **A matching network at a radio pin** (a pi or a T). The series parts go on one straight line from the pin to the antenna or the connector, in the schematic's order. Each part to ground joins that line with its pad **on** the line, in a gap left between the two series parts, turned across the line with its ground pad away: the track then runs straight through its pad. A part beside the line needs a short branch to reach it, and at 2.4 GHz a branch is an inductance and a capacitance the values did not allow for. The gaps make the chain longer than its parts end to end: count them before the chip's distance from the antenna is set. Where the maker's layout ties a ground to one pin or one layer, that comes first and the branch is accepted and said. This is geometry; the match itself is the maker's tuning or a measurement.
- **A part that must be close cannot reach its pin.** Something that tolerates distance holds the place (a bulk capacitor, a series resistor, a pull-up, a test point): that one moves. Before a decoupling capacitor, a filter capacitor, a crystal or a radio part is moved away from its pin, try two other ways (another angle, the other side of its neighbour, the two neighbours swapped) and keep the one with the shortest worst distance that still routes. When a side of a chip cannot hold its parts, the chip turns or moves. What could not be met is said, with why.

## Keep every pad reachable

- Leave a channel wherever a signal must pass between parts: one track plus two clearances, from the board's rules.
- Keep the area in front of a row of fine pins free until its tracks can turn (about 2 mm at 0.5 mm pitch).
- Place a two-pad part in line with the pin it serves rather than across the row, so the neighbouring pins' tracks can leave straight.
- A ground pad that returns to a plane (a decoupling capacitor's, a crystal capacitor's) has room for its via right beside it: the via's pad plus the clearance to the neighbouring copper. Where the maker ties that pad to a particular pin instead, follow the maker and add no via.
- At least 1 mm between parts' courtyards where tracks or vias must pass, 0.2 mm where none must; at least 1 mm from the board's edge, more beside a V-score or a breakaway tab.
- A board that will not route on two layers at this size wants more room or four layers (two planes inside: reference/analysis.md), not thinner tracks.

## Check, look, fix

After each group of parts:

- **Measure**: `print(b.near(s))` in the board's script lists every two-pin part with its distance from the pin it serves, the farthest first, and calls a supply's capacitor far beyond 4 mm. Read the whole list: a crystal's capacitor, a strap's pull-up or a feedback divider that is far is yours to notice. A regulator's loop and a crystal's two tracks you measure from the pads' places (`b.where()`, or `part`'s pads).
- **Look**: `look` at the whole board, then `look { around: "U1" }` at each chip: a chain out of order, a part in front of pins it does not serve, a connector facing inwards, labels over pads.
- **Route** as the test of the placement: what `route` cannot connect, or connects by a long way round, shows where parts are in each other's way. Move the part that tolerates distance, never the one that does not.

When a short critical connection and a signal leaving the area compete for the same space, the critical part stays: the signal can bend, change layer or leave another way; a decoupler, a crystal or a switch node cannot.

Keep it tidy where it costs nothing: parts of a kind in rows on one grid and turned one way (polarised parts especially) are quicker to assemble and to inspect. Parts go on one side unless the person asked for two or the board cannot be made otherwise: say so before using the back, it changes the price of assembly.

## When pins cross: change the schematic

A placement that leaves a bundle of connections crossing each other is often a choice made in the schematic, not a routing problem. Where the parts allow it, change the choice: the processor's pin for a signal that any pin of that kind can carry, the order of a connector's pins when nothing outside fixes it, which gate or which resistor of an array carries which signal, a bus's bit order where the program can reverse it. Do it in the description (`scripts/design.py`), draw the schematic again, run the board's script, and `check`. Never for a pin whose function is fixed (a strap pin, a boot pin, an ADC channel, a peripheral's own pin where the chip has no remapping, a pair's two halves), and say what was swapped in `DESIGN.md`: the program is written against it.
