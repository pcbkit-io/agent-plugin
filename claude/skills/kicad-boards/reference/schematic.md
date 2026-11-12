# The schematic

## Contents

- Why the schematic comes before the board
- One description, two files
- Writing it: `scripts/schematic.py`
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

Write the parts and the net of each pin **once**, in a script of the project (`scripts/design.py`), and make both files from it: the schematic through `schematic.py`, the board's nets from the same object. Two files typed by hand from memory drift apart; two files made from one list cannot, and `check` proves it.

## Writing it: `scripts/schematic.py`

This skill has `scripts/schematic.py` (in PCBKit's shell: `/pcbkit/skills/kicad-boards/scripts/schematic.py`; in a plugin: `scripts/schematic.py` in this skill's folder). Copy it into the project's `scripts/`, so the project builds anywhere. It needs Python 3 and KiCad's symbol libraries, nothing else.

```python
# scripts/design.py: the design, once. Run it from the project's folder: python3 scripts/design.py
import sys; sys.path.insert(0, "scripts")
from schematic import Schematic

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
s.flag("+5V", "GND")                      # power comes in from outside the sheet here
s.note("Power in", "5 V from USB-C; R1 and R2 ask the charger for it.")

if __name__ == "__main__":
    print(s.write("board.kicad_sch"))     # the paper it took
```

It draws each part's symbol, the parts of a block side by side under the block's name, a short wire and a global label on every connected pin, and a no-connect mark on every pin given no net. A wrong pin stops it with the symbol's real pins listed: read that list against the datasheet's table rather than trying names until one passes.

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

Make its picture and read it (reference/kicad-tools.md: `kicad-cli sch export svg`, `rsvg-convert`): a label that is not what you meant, a block that grew unreadable, a part in the wrong block. Then put it in front of the person: `view: schematic` in `.pcbkit/view.yaml` (reference/view.md), with a sentence on what each block does. A person who looks at the schematic before the board exists catches a misunderstanding when it costs nothing.

## The board from the same description

The board's footprints carry the same references, and its pads get their nets from `s.nets()`:

```python
# scripts/board.py (part of it): the pads' nets from the design
import sys; sys.path.insert(0, "scripts")
import pcbnew
from design import s

board = pcbnew.LoadBoard("board.kicad_pcb")
for name, pins in s.nets().items():
    net = board.FindNet(name)
    if net is None:
        net = pcbnew.NETINFO_ITEM(board, name)
        board.Add(net)
    for ref, number in pins:
        for pad in board.FindFootprintByReference(ref).Pads():
            if pad.GetNumber() == number:
                pad.SetNet(net)
board.Save("board.kicad_pcb")
```

Then `check`: it says whether the board and the schematic connect the same pads, and names each pad that differs. A part on one and not on the other, or a pad on another net, is fixed before anything is placed.

## Changing a schematic a person drew

A project that came with its own schematic (drawn in KiCad, with wires) is not regenerated: its drawing is the person's. Change it as text, in its own style: a new symbol with its `lib_symbols` entry, its pins joined by labels of the nets' names, a new uuid on every item; then look at its picture and run `check`. The same for the board: keep both in step, by reference.
