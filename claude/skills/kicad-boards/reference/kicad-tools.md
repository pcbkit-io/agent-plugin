# KiCad's own tools, and what PCBKit's shell has

## Contents

- KiCad's libraries, boards by script, checks, files for a factory
- KiCad 10's Python, where it trips
- Pictures: a schematic, a datasheet's page, a plot
- Simulation
- What PCBKit's own shell has

`kicad-cli` and Python's `pcbnew` are there in PCBKit's own shell, and on the person's computer when they have KiCad (`kicad-cli version`; on macOS it is in `/Applications/KiCad/KiCad.app/Contents/MacOS`). On a person's computer, `pcbkit python script.py` runs a script in the Python that has KiCad's `pcbnew` and PCBKit's own package. When they are, use them for what text editing does badly:

- **KiCad's libraries**: footprints in `/usr/share/kicad/footprints/<Library>.pretty/<Name>.kicad_mod`, symbols in `/usr/share/kicad/symbols/<Library>.kicad_sym` (macOS: `/Applications/KiCad/KiCad.app/Contents/SharedSupport/`). `ls` and `grep` them; a `.kicad_mod` file is the footprint's text, ready to paste into a board with its reference, position and nets.
- **A board by script**: `pcbkit.pcb` first (reference/format.md: the outline, the description's parts and nets, places, planes, keep-outs, run again and again); `pcbnew` itself for the rest, on `b.board`: `pcbnew.LoadBoard(path)`, `pcbnew.FootprintLoad(library_dir, name)`, `footprint.SetPosition(pcbnew.VECTOR2I_MM(x, y))`, `pad.SetNet(net)`, `board.Add(footprint)`, `board.Save(path)`. Good for many parts at once, for arrays and circles of parts, and for measuring (`board.GetBoardEdgesBoundingBox()`, `footprint.GetBoundingBox()`).
- **KiCad 10's Python, where it trips:** copy a footprint with `pcbnew.FOOTPRINT(fp)` (`fp.Duplicate()` wants an argument and gives a bare `BOARD_ITEM`); a footprint's own fields are `fp.SetField("MPN", "…")`, not fitted is `fp.SetDNP(True)`; save a footprint into a library with `pcbnew.PCB_IO_MGR.FindPlugin(pcbnew.PCB_IO_MGR.KICAD_SEXP).FootprintSave(dir, fp)` (`pcbnew.FootprintSave` fails); an arc is `shape.SetShape(pcbnew.SHAPE_T_ARC); shape.SetArcGeometry(start, mid, end)`; fill the zones before saving (`pcbnew.ZONE_FILLER(board).Fill(board.Zones())`) whenever anything under them moved; in a board's `layers` table the copper layers are listed front to back and numbered F.Cu 0, In1.Cu 4, In2.Cu 6, …, B.Cu 2.
- **A factory's limits are rules:** before the files for a factory are made, fetch its capability page and write what it says into `<name>.kicad_dru` (the smallest track, gap, hole, annular ring and solder-mask web; the distance of copper from the edge): `check` then holds the board to them, and a finding there is fixed in the board, not waved through.
- **Checks**: `check` already runs KiCad's own where it can: the schematic's electrical rules, the board's design rules, and whether the two connect the same pads. `kicad-cli sch export netlist` writes a schematic's netlist when a script wants it.
- **Files for a factory**: `kicad-cli pcb export gerbers`, `… drill`, `… pos` (placement), `kicad-cli sch export bom`, `kicad-cli pcb export step` (the 3D model), `… pdf`, `… svg`; `zip` the Gerbers and drill files together.
- **Simulation**: `ngspice -b circuit.cir` in PCBKit's shell, for a filter, a divider or a regulator's loop before it goes on the board.

## Pictures: a schematic, a datasheet's page, a plot

What can be drawn can be looked at, and looking finds what reading does not. `look` draws the board, and with `view: "schematic"` the schematic's sheet (all of it, or round a part). For the rest, make a PNG and read it as an image:

- **A schematic on paper** (a PDF for the person, a page of a review): `kicad-cli sch export pdf -o <name>.pdf <name>.kicad_sch`. A schematic a person can read has its blocks apart, power at the top and ground at the bottom, and nothing overlapping.
- **A datasheet's page** (a pinout drawing, a layout example, a graph): `pdftoppm -r 120 -f 7 -l 7 -png refs/<part>.pdf /tmp/page`. A scanned datasheet without text: `tesseract /tmp/page-07.png -` reads it.
- **A plot or a layer**: `kicad-cli pcb export svg --layers F.Cu,Edge.Cuts …` and `rsvg-convert`; a Gerber with Python's `pygerber`.

## What PCBKit's own shell has

A Linux of the project's own, with the internet through a proxy that is already set (public https and http: `curl`, `git clone` and `pip install` work as usual). Besides KiCad 10: Python 3 with numpy, scipy, shapely, sympy, networkx, matplotlib, pandas, pillow, `sexpdata`, `kiutils`, `pdfplumber`, `pypdf` and `pygerber`; `pip` and `uv` for more (a C compiler is there for packages that need one); `ngspice`; `pdftotext`, `pdftoppm`, `mutool`, `tesseract`; `rsvg-convert`, ImageMagick, Graphviz; `node`; `git`, `jq`, `rg`, `sqlite3`, `zip`, `unzip`, `7z`, `xz`. PCBKit's own commands are there too (`pcbkit schematic`, `pcbkit check`, `pcbkit route`, `pcbkit analyze`), for scripts, and its Python package (`pcbkit`) in every Python there. On a person's own computer, use what is installed and say what is missing.
