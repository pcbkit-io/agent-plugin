# The schematic

## Contents

- Why the schematic comes before the board
- One description, two files
- Writing it: `scripts/design.py` and the `schematic` tool
- What it draws, and how to make it read well
- Symbols, pins, nets
- Blocks a person can read
- What KiCad's electrical rules say
- Look at it, and show it
- The board from the same description
- Changing a schematic a person drew

## Why the schematic comes before the board

The schematic is the design a person can read: which part does what, what is joined to what, block by block. They review it, the next person repairs the board with it, and it is checked twice by tools that a board alone never meets: KiCad's electrical rules (an input nothing drives, two outputs on a net, a supply nobody feeds, a net name spelt two ways), and `check`'s comparison of the board with it, pad by pad. A board without a schematic has only your memory of what you meant.

So the order is: `DESIGN.md` (what and why, in words), the schematic (what is joined to what, checked), then the board. A small change to a board that has a schematic changes the schematic too, first.

## One description, two files

Write the parts and the net of each pin **once**, in a script of the project (`scripts/design.py`), and make both files from it: PCBKit draws the schematic from it, and the board's pads take their nets from the same object. Two files typed by hand from memory drift apart; two files made from one list cannot, and `check` proves it.

## Writing it: `scripts/design.py` and the `schematic` tool

The description is Python, written with `pcbkit.schematic` (PCBKit's own: nothing to copy or install, it comes with every PCBKit). **Draw it with the `schematic` tool** (`pcbkit schematic` in a shell): it runs the script, writes the `.kicad_sch`, runs KiCad's electrical rules on it and answers with their findings and a picture of the sheet.

```python
# scripts/design.py: the design, once.
from pcbkit.schematic import Schematic

s = Schematic("board", title="USB-C blinker", rev="A")
s.part("J1", "Connector:USB_C_Receptacle_USB2.0_16P", "USB-C", block="Power in",
       footprint="Connector_USB:USB_C_Receptacle_HRO_TYPE-C-31-M-12",
       fields={"MPN": "TYPE-C-31-M-12", "LCSC": "C165948"},
       pins={"A4": "+5V", "B4": "+5V", "A9": "+5V", "B9": "+5V", "A5": "CC1", "B5": "CC2",
             "A1": "GND", "B1": "GND", "A12": "GND", "B12": "GND", "SH": "GND"})
s.part("R1", "Device:R", "5.1k", block="Power in", pins={"1": "CC1", "2": "GND"},
       footprint="Resistor_SMD:R_0603_1608Metric", fields={"MPN": "RC0603FR-075K1L"})
s.part("U1", "Timer:TLC555xD", "TLC555", block="Timer",
       pins={"8": "+5V", "1": "GND", "4": "+5V", "2": "TRIG", "6": "TRIG", "7": "DIS", "3": "OUT", "5": "CV"},
       footprint="Package_SO:SOIC-8_3.9x4.9mm_P1.27mm")
s.part("C1", "Device:C", "100nF", block="Timer", pins={"1": "+5V", "2": "GND"}, footprint="Capacitor_SMD:C_0603_1608Metric")
s.flag("+5V", "GND")                      # power comes in from outside the sheet here
s.note("Power in", "5 V from USB-C; R1 and R2 ask the charger for it.")

if __name__ == "__main__":
    s.write("board.kicad_sch")
```

A wrong pin stops it with the symbol's real pins listed, a wrong symbol name with the names near it: read that list against the datasheet's table rather than trying names until one passes. Every time it is drawn, the file is read back through KiCad and held to the description pin for pin, so what you described is what the file connects. A schematic PCBKit did not draw (a person's own) is never drawn over.

## What it draws, and how to make it read well

It draws the way a person draws a schematic to be read, from what the nets say:

- **A chip** (any part with more than two pins) stands with a name on each connected pin; neighbouring pins of one net are joined and named once; a pin given no net gets a no-connect mark.
- **Two-pin parts are wired**, not named. A supply's capacitors stand side by side between the supply's symbol and ground's. What hangs on a signal is drawn on that signal's wire under one name: a pull-up over it, a capacitor or a resistor to ground under it, a part in series and what follows it (an LED, then its resistor, then ground).
- **Supplies and grounds** are KiCad's power symbols where a part stands between them (`+3V3`, `+5V`, `VBUS`, `GND`: names KiCad has a symbol for), a name elsewhere.
- **Each block** is a frame with its name and its sentence; the paper is the smallest the blocks fit on.

What you choose decides how well it reads:

- **Blocks by what they do**, a few parts each (a chip and what serves it), in the order power and signals flow. One block of forty parts reads as a parts list.
- **In a block, the chip first, then what serves it** in the order of its pins: pieces are drawn in the order you describe them.
- **Net names a person can follow**: a signal by what it carries (`I2C_SDA`, `~{RESET}`, `LED_STATUS`), a supply by KiCad's own spelling (`+3V3`, not `3V3` or `VCC_3V3`), so it gets its symbol. A net between two parts of one chain (an LED and its resistor) still needs a name: say what it is (`LED_STATUS_K`).
- **Values with their unit**: `100nF`, `4.7uF`, `10uH`, `10k`, `4.7R` (an R, not an omega sign), and for a part that is not a passive its part number.
- **A test point or a jumper in the block of the net it is on**, after the parts that make that net, not in a block of leftovers.
- **One net, one job**: a net that is a supply is drawn as one everywhere. Do not name a signal like a supply (`VBAT_SENSE` is fine; a signal called `+VSENSE` is drawn as a supply).

## Symbols, pins, nets

- **Symbols** come from KiCad's libraries (`ls /usr/share/kicad/symbols`, `grep -o '(symbol "[^"]*' <Library>.kicad_sym` lists a library's; reference/kicad-tools.md has the paths elsewhere) as `Library:Name`, or from the project's own library: `save_part` writes a library part's symbol into `parts.kicad_sym`, used as `parts:<name>`. A generic symbol of the right kind (`Device:R`, `Connector_Generic:Conn_01x06`) is right for a passive or a header; a chip gets its own symbol, with its real pin numbers.
- **Pins by number**, from the pin table you copied from the datasheet for **this package** (reference/parts.md). A pin's name in a symbol is a convenience; the number is what the footprint's pad carries.
- **Every pin has a decision**: a net, or nothing because the datasheet says it may float. The script marks what you left out as not connected, and KiCad then says nothing about it, so leaving a pin out is a statement that you checked.
- **Net names** are the board's net names: rails as `+3V3`, `+5V`, `VBAT`, `GND`; signals by what they carry (`SPI_SCK`, `LED_A`, `~{RESET}` for active low); a pair as `USB_D_P` and `USB_D_N`. One spelling: `3V3` and `+3V3` are two nets.
- **`s.flag(net)`** where power enters the sheet from something that is not a power output in the schematic (a connector, a battery, a test pad). Without it KiCad reports the supply as driven by nobody. A regulator's output is already a power output: do not flag it.
- **Fields** carry what a factory needs: `MPN`, the maker, `LCSC` or another supplier's number. `dnp=True` for a part that has its place but is not fitted.

## Blocks a person can read

`block="…"` groups parts under a name; blocks are drawn in the order you first name them. Name them by what they do and order them the way power and signals flow: power in, protection, each supply, the processor, each interface, what the person sees and touches. Give each a sentence (`s.note`) that says what it is for in plain words: that sentence is what a beginner reads. Within a block, put the chip first and what serves it after (its decoupling, its pull-ups), in the order of its pins.

## What KiCad's electrical rules say

`check` runs them on the schematic and reports each with the pins involved. What the common ones mean:

| Finding                                          | What it usually is                                                                                                                             |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `isolated_pin_label` (label on one pin only)     | a net name spelt two ways, or a pin whose other end you forgot                                                                                 |
| `pin_not_driven`, `power_pin_not_driven`         | an input, or a supply pin, on a net with no output or power source: a missing part, a missing `flag`, or a regulator's output on the wrong net |
| `pin_to_pin` (output to output, power to output) | two things driving one net: a wrong pin, or two regulators joined                                                                              |
| `pin_not_connected`                              | a pin with neither a net nor a no-connect mark (a symbol with pins the script did not see: say which)                                          |
| `no_connect_connected`                           | a pin marked unconnected that is on a net                                                                                                      |
| `multiple_net_names`                             | two names on one net: decide which, and why they met                                                                                           |
| `lib_symbol_…`, `footprint_link_issues`          | KiCad's own libraries are not configured where the check ran: not about your design                                                            |

An error is fixed in `scripts/design.py`, not waved through; a warning is fixed or answered with its reason in `DESIGN.md`.

## Look at it, and show it

The `schematic` tool answers with the sheet's picture: **read it, every block**, before going on. `look { view: "schematic", around: "U1" }` zooms in on a part (texts on a whole A3 are small), `center` and `across` on a place. What to look for, and what to change in the description when you see it:

- a chip pin whose name is not what the datasheet's table says for that number: the pin, not the drawing, is wrong;
- a part drawn alone between two names when it belongs to a chain: one of its nets is spelt differently from its neighbour's;
- a capacitor or a pull-up in another block than the chip it serves: move it to that chip's block, after the chip;
- a block that grew past what one look takes in: split it by function;
- a pin marked not connected that the datasheet says must be tied.
- a block that differs from the maker's reference circuit for its chip (reference/parts.md): put the two pictures side by side.

Change the description, draw again, look again: two or three rounds is usual. Then put it in front of the person: `view: schematic` in `.pcbkit/view.yaml` (reference/view.md), with a sentence on what each block does. A person who looks at the schematic before the board exists catches a misunderstanding when it costs nothing.

## The board from the same description

The board's script (`scripts/board.py`, written with `pcbkit.pcb`: reference/format.md) imports the same object, and `b.update(s)` puts its parts and nets on the board: footprints with the schematic's references, every pad on the net its pin has here.

Then `check`: it says whether the board and the schematic connect the same pads, and names each pad that differs. A part on one and not on the other, or a pad on another net, is fixed in the description and drawn and updated again, before anything is placed.

## Changing a schematic a person drew

A project that came with its own schematic (drawn in KiCad, with wires) is not regenerated: its drawing is the person's. Change it as text, in its own style: a new symbol with its `lib_symbols` entry, its pins joined by labels of the nets' names, a new uuid on every item; then look at its picture and run `check`. The same for the board: keep both in step, by reference.
