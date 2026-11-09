---
name: kicad-boards
description: Read and change KiCad projects as text (.kicad_pcb boards, .kicad_sch schematics, .kicad_pro settings, symbol and footprint libraries). Use before editing any KiCad file.
---

# KiCad boards as text

KiCad files are S-expressions: one item per list, `(footprint …)`, `(segment …)`, `(via …)`, `(zone …)`, `(symbol …)`, each with its own `(uuid "…")`. Coordinates are millimetres; `(at x y angle)` places an item.

## Read before you write

- Boards can be large (tens of megabytes). Find what you need with `grep -n` and read around it with `sed -n 'a,bp'` or the read tool's offset and limit; never read a whole board.
- A footprint is found by its reference: `grep -n '"Reference" "U3"'`, then read up to its `(footprint` line and its closing parenthesis.
- Nets are named in pads (`(net 5 "GND")`) and, in older files, declared at the top of the board.

## Change it

- Make small, exact replacements of unique text (an item's uuid makes it unique). For many similar changes, use `sed` or `awk` over the file.
- Keep KiCad's formatting: tabs, one item's lists on their own lines as KiCad writes them.
- Every new item gets a new random uuid (`uuidgen` or any v4 uuid). Never reuse one.
- Moving a footprint: change its `(at x y angle)`; its pads move with it. Tracks connected to it don't: move their ends too, or route again.
- Keep the schematic and the board in step: a part added to one belongs in the other, with the same reference and footprint.

## After each write

PCBKit checks the KiCad files you wrote and reports syntax problems in the tool's result, with line and column: fix them before anything else. The person sees every write at once, so work in small steps that leave the files valid.
