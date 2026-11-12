# Placement

## Contents

- Why parts go where they go
- The order
- By kind of part
- Keep every pad reachable
- Check, look, fix

Placement decides most of what routing can do. A part in the wrong place makes a track long, a current loop large or a pad unreachable, and no routing repairs that. Compute positions from pad coordinates (`part` gives them; KiCad's Python measures), not from a picture: an estimate by eye is often off by more than a small part is long.

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
2. **The large chips**: turn each so that its pins face what they go to (try all four rotations: pins to a connector face it, pins with local parts face room for those parts), at the distance its nearest chain needs.
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

## Keep every pad reachable

- Leave a channel wherever a signal must pass between parts: one track plus two clearances, from the board's rules.
- Keep the area in front of a row of fine pins free until its tracks can turn (about 2 mm at 0.5 mm pitch).
- Place a two-pad part in line with the pin it serves rather than across the row, so the neighbouring pins' tracks can leave straight.
- At least 1 mm between parts' courtyards where tracks or vias must pass, 0.2 mm where none must; at least 1 mm from the board's edge, more beside a V-score or a breakaway tab.
- A board that will not route on two layers at this size wants more room or four layers (two planes inside: reference/analysis.md), not thinner tracks.

## Check, look, fix

After each group of parts:

- **Measure** what matters with a few lines of KiCad's Python or from `part`'s pads: each supply pin to its capacitor's supply pad (more than about two of the capacitor's body lengths is too far), a crystal's two tracks, a regulator's loop.
- **Look**: `look` at the whole board, then `look { around: "U1" }` at each chip: a chain out of order, a part in front of pins it does not serve, a connector facing inwards, labels over pads.
- **Route** as the test of the placement: what `route` cannot connect, or connects by a long way round, shows where parts are in each other's way. Move the part that tolerates distance, never the one that does not.

When a short critical connection and a signal leaving the area compete for the same space, the critical part stays: the signal can bend, change layer or leave another way; a decoupler, a crystal or a switch node cannot.
