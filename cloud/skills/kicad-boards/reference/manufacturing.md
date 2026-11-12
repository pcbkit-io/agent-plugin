# For a factory

A board is made by the factory's rules, not KiCad's defaults, and the factory builds what the files say, not what the design meant. Its own check is the last word: when the checks here say clean and the factory's says no, the factory is right.

## Contents

- The factory's limits as rules
- Parts that can be bought
- The files
- Look at what was made
- What you say

## The factory's limits as rules

Before any file for a factory is made, get its capability page (`curl` it into `refs/`) and write what it says into `<name>.kicad_dru` and the board's design rules: the smallest track and gap for this layer count and copper weight, the smallest hole and its ring, the distance of copper and of holes from the edge, the smallest solder-mask web between pads, the smallest silkscreen line and text. `check` then holds the board to them, and a finding there is fixed in the board, not waved through.

Typical limits when the factory's page cannot be read (say that you used these): tracks and gaps 0.127 mm (0.1 mm costs nothing extra at most factories, less than that does); a via with a 0.3 mm hole in a 0.6 mm pad; a plated hole's ring 0.15 mm; copper 0.3 mm from the edge; mask web 0.1 mm; silkscreen lines 0.15 mm and text 1 mm high. Stay away from the limits where there is room: a board at the limit everywhere yields worse.

Say in the notes for the factory what the files cannot: the board's thickness and copper weight, the stackup for a controlled impedance (which nets, which impedance, which layers), the finish, the mask's colour.

## Parts that can be bought

- Every line of the BOM has its maker's part number and, for the factory that assembles, the factory's own number; `find_parts` and `part` say the stock. A part out of stock is replaced now, with its footprint checked again, not at the order.
- Prefer the factory's stocked (basic) parts for passives: they cost no loading fee.
- Parts not to be fitted are marked DNP in the board and the schematic, not left out of the BOM by hand.
- The BOM is generated from the files (`export` makes it from the schematic), never edited by hand: a part number that must change is changed in the schematic.

## The files

After zones are filled and the last `check` is clean, call **`export`** (on a computer, `pcbkit export`): KiCad's own exporter makes one zip that JLCPCB and PCBWay take as it is:

- Gerbers for every copper layer, both masks, pastes and silkscreens, and the outline; the drill files (plated and non-plated apart, slots as slots).
- `<board>-BOM.csv` and `<board>-CPL.csv` in JLCPCB's columns (`Comment, Designator, Footprint, JLCPCB Part #` and `Designator, Mid X, Mid Y, Rotation, Layer`): the part numbers come from a symbol field such as `LCSC` or `JLCPCB Part #`, parts marked DNP are left out, rotations are turned for JLCPCB's footprints of common packages (a field `JLCPCB Rotation Offset` gives a part its own; the factory's preview of the parts must still be checked).

Its answer says where the zip is (on a computer `fab/<board>-fab.zip` in the project; on the site a link: give it to the person) and reads the files back: copper layers, size, whether the outline is closed, holes by size, parts on each side, BOM lines, and what to fix before ordering. Fix what it lists in the board or the schematic, never in the zip.

When the person asks to order, **`order`** puts the board on the factory's own order page (PCBWay, OSH Park, AISLER, NextPCB) and answers with its link; for JLCPCB it says what JLCPCB's own review read and its price, and the person uploads the zip on JLCPCB's quote page. Nothing is ordered or paid by the tool.

For the person, besides: the schematic and the board as PDF, the board's STEP for whoever makes the enclosure (`kicad-cli`, reference/kicad-tools.md).

## Look at what was made

`export`'s answer is the reading of the files themselves; still look at them before saying they are right:

- As many copper layers as the board has, each with copper; an outline that is closed.
- The holes by size as the board has them; the BOM's references exactly the board's fitted parts: none missing, none extra.
- Render or plot the board and look at it (`look`; `kicad-cli pcb export svg`, `rsvg-convert` for a PNG): a missing layer or a mirrored one is seen at once.

## What you say

Which factory's limits the board was checked against (and where they came from), what the checks found, which parts are short in stock, and what the factory's own review and a first build still have to show: nothing here measured a real board. Ordering is the person's act.
