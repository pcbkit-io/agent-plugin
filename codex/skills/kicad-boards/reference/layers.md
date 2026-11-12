# Layers: how many, and what each is for

## Contents

- Decide before a part is placed
- Two layers or four
- What each layer is for
- Return paths: the rule under all of it
- Widths, clearances and holes as rules
- What to tell the person

## Decide before a part is placed

The number of layers and what each carries is decided after the schematic and before placement, because it changes where parts can go, how wide a controlled track is and what the board costs. Changing it after routing means routing again. Write it into `DESIGN.md` (`# Layers`), with the reason, and set it up in the files (reference/format.md) before the first footprint is placed.

## Two layers or four

Start from what the board carries, not from habit.

**Two layers are right** when the board is slow and simple: a timer, LEDs, relays, an 8-bit microcontroller, sensors on I²C or SPI at a few megahertz, a radio or processor that is a finished module with its own antenna, USB at full speed over a short track. The back is a ground pour kept as whole as the routing allows, and the tracks stay on the front except for short hops.

**Four layers are right** when any of these is true:

- there is high-speed USB, Ethernet, an SD card at speed, a camera or display on a fast bus, memory, or any pair whose impedance matters (on a 1.6 mm two-layer board a 50 Ω track would be about 3 mm wide: it cannot be made);
- there is a radio whose antenna feed you route (not a module with its antenna on it);
- a switching regulator of more than about an ampere shares the board with analog inputs or a radio;
- a chip's pins are so fine or many (a QFN with 0.4 mm pitch, any BGA) that two layers cannot bring its supplies and grounds out;
- on two layers the ground pour ends up cut into islands by the tracks, or `route` leaves connections open at a sensible size;
- the device is a product that must pass emissions testing, not a one-off.

A chip maker's guide often says it outright (Espressif recommends four layers for its radio chips, the second one solid ground): follow it. Small four-layer prototypes cost little more than two-layer ones; on larger boards they cost a few times as much, and still usually less than the second spin of a two-layer board that did not work: when in doubt on a board with a processor and anything fast, take four and say why. A **thinner two-layer board** is the middle way for one controlled pair on an otherwise simple board: at 1.0 mm a 90 Ω USB pair is 0.8 mm tracks 0.15 mm apart (the RP2040's reference board does this). Six or more layers are for large BGAs and memory buses: say so and stop to ask before designing one.

## What each layer is for

A four-layer board, front to back:

| Layer    | Carries                                                                       | Why                                                                            |
| -------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `F.Cu`   | the parts, and the signals that matter most (pairs, clocks, the antenna feed) | they run right over the ground plane, 0.1–0.2 mm away                          |
| `In1.Cu` | ground, whole, nothing routed in it                                           | it is the return path of everything on the front                               |
| `In2.Cu` | the supplies (as pours for the rails with many loads), or a second ground     | wide, low-resistance power; a second ground when the back carries fast signals |
| `B.Cu`   | the remaining signals, short hops, and parts only when the front is full      | —                                                                              |

The planes are planes: a track through `In1.Cu` cuts the return path of everything that crosses it. Keep tracks out of both inner layers with a rule area (reference/format.md), so `route` uses the outer layers and reaches the planes by vias.

A two-layer board: the front has the parts and the tracks, the back is ground. Where a track must go to the back, keep the hop short and do not let it run alongside a slot it made in the pour.

## Return paths: the rule under all of it

Every current comes back, and above a few hundred kilohertz it comes back in the plane directly under its track. So:

- every fast or sensitive track has unbroken ground under its whole length (`analyze signal` reports tracks with no plane under them);
- when a signal changes layers, its return needs a way to follow: a ground via beside the signal's via;
- ground is one net. Do not split it into "analog" and "digital" planes joined at a point: keep it whole and keep the noisy parts and the sensitive parts in different places (reference/placement.md). A split with a track across it is worse than no split;
- ground vias stitch the front and back pours to the plane, around the board's edge and beside every decoupling capacitor's ground pad.

## Widths, clearances and holes as rules

Before routing, the numbers go into the project (`net_settings.classes` in the `.kicad_pro`, reference/analysis.md), so `route` follows them and `check` holds the board to them:

- **The factory's limits**, from its capability page (reference/manufacturing.md), with margin: do not design at the limit where there is room.
- **Power**: a width for the current (0.3 mm for 1 A, 0.8 mm for 2 A, 1.4 mm for 3 A on outer 1 oz copper; an inner layer needs about 2.6 times that and often has thinner copper: reference/circuits.md has the table), about one via per 200 mA between layers.
- **Controlled tracks**: the width (and gap, for a pair) that gives the impedance on **this** stackup: 90 Ω differential for USB, 100 Ω for Ethernet, 50 Ω for an antenna feed. It depends on the distance to the plane, which the factory's stackup page gives; set a width, then let `analyze signal` compute what the copper really is and adjust until it agrees. Write the stackup you assumed into `DESIGN.md` and into the notes for the factory.
- **High voltage**: clearance for the voltage, as a net class.

## What to tell the person

One or two sentences when you decide, in their words: "Four layers: the USB pair and the radio need solid ground right under them, and two layers cannot give that. It adds a few dollars to a small batch." Then show them (reference/view.md): the layers apart in 3D (`explode: true`) once the planes exist, so they see what the inner layers are.
