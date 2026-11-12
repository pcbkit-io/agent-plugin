# The device's enclosure: printed parts, hardware, assembly

Read this when the work is a case for the board, button caps, a stand, a bracket, anything printed
or bought that goes round it. An enclosure is a program you write, `enclosure/enclosure.py` beside
the board, in **build123d** (Python over an exact solid kernel) with PCBKit's `pcbkit` package.
The `enclosure` tool runs it: it checks the enclosure against the board and writes the files to
print. The person watches the device in its enclosure on the board's page, with a slider through
its assembly.

An enclosure that fits is made by checking, like a board. What goes wrong is rarely the shape: it
is an opening a plug's body does not pass, a cap that holds its button down, a screw that ends
before its insert, a part that cannot be put in once another is. The checks find these; you fix
the program.

## The order

```
- [ ] 1. DESIGN.md says what the enclosure is: how the device is held and stood, what must reach outside,
        how it is made (printer, material), how it is held together, how it is put together
- [ ] 2. Every board part's height is known; what sits on the board outside its file is added
- [ ] 3. The parts, drawn from the board's own places (never a coordinate typed from memory)
- [ ] 4. Hardware from `pcbkit.hardware`, with the room it takes cut by its own cutters
- [ ] 5. Everything that must reach outside is declared (plug, light, pin, picture, your own)
- [ ] 6. The steps of assembly, in order
- [ ] 7. `enclosure`: every line ok
- [ ] 8. Tell the person what to measure on the real board before printing, and how to print
```

### 1. Decide before drawing, and ask what you cannot know

Write under `# Enclosure` in DESIGN.md:

- **What reaches outside**, part by part: each connector (and from which side its plug comes), each
  button (a cap, or a pin hole for reset and boot), switches, LEDs (a hole, a light tube), a display's
  picture, speakers and microphones (slots), antennas (no metal near, plastic may cover), cells (how
  they are changed), sensors that need air or light.
- **How it is made.** Ask the person what printer they have or where they order, if they have not
  said: it decides the walls, the fits and the largest part. `fdm()` is a home filament printer
  (0.4 mm nozzle, 256 mm bed, PETG), `mjf()` nylon from a print service (JLC3DP, any orientation, no
  supports), `sla()` resin.
- **How it is held together**: screws into heat-set inserts (strong, opens many times), screws that
  cut their thread in the plastic (no inserts to buy, a few openings), snaps (no hardware, hard to
  get right in a first print). Default: M3 or M2.5 screws through the board's own mounting holes
  into inserts; the board is clamped between posts of the two shells.
- **How it is put together**: which part lies on the table first, what goes in after what.

Dimensions the board cannot say (a taped display's height, a cell's top in its holder, how far a
lever stands out) come from datasheets: write each with its source as a named number at the top
of the program, and list them for the person to measure before they print.

### 2. The board as a mechanical object

```python
from build123d import *
from pcbkit import Board, Enclosure, fdm, hardware, locate
from pcbkit.shapes import box, cyl, prism, rbox

board = Board.load()          # the project's .kicad_pcb (one board: no name needed)
p = fdm()                     # the printer's numbers: p.wall, p.gap, p.fit, p.snug, p.bed
enc = Enclosure(board, p)
W, H, T = board.width, board.height, board.thickness
```

**The device's frame**, millimetres: x to the right and y up as the person sees the board's
front, z out of the front. The front surface is z = 0, the back is z = −T, the lower left corner
of the outline's box is (0, 0). Everything you draw is in this frame.

- `board["J3"]`: a part: `.x`, `.y`, `.rot`, `.back`, `.height`, `.kind` (`"usb-c"`, `"button"`,
  `"slide"`, `"led"`, `"holder"`, `"speaker"`, `"module"`, `"hole"`, `"part"`), `.box()` (its
  courtyard: x0, y0, x1, y1), `.level(h)` (the z of a point `h` above its own side of the board),
  `.top` and `.travel` of a button.
- `board.of_kind("button")`, `board.holes()` (mounting holes: `.x`, `.y`, `.diameter`).
- `board.sketch(grow)`: the outline as a face, grown by `grow`: `prism(board.sketch(p.gap + p.wall), z0, z1)`
  is a slab the shape of the board with a wall's room round it.
- `board.set_height("L1", 3.0)`: a part's height from its datasheet, where the footprint's name does
  not give it. The build fails until every part has one (0 for a part that is flat).
- `board.button("SW1", top=4.3, travel=0.25)`: a button's actuator, where its value does not say.
- `board.add("panel", solid)`: what sits on the board without being in its file (a taped display,
  cells in their holders, a daughter board): an obstacle that moves with the board.

See what the board is before drawing: the `enclosure` tool with `tell: "board"` (in a shell:
`pcbkit enclosure board`) lists every part with its side, kind, place, height and courtyard, the
mounting holes, and what stands at the board's edges. `tell: "api"` lists the package's classes and
functions with their arguments. Your own shell's Python does not have `pcbkit` or build123d: the
tool runs the program. Where the shell has `pcbkit` (PCBKit's own shell does),
`pcbkit enclosure python script.py` runs a script of yours in that Python, to try a shape or
measure one.

### 3. Parts

Plain build123d, algebra mode: solids added, cut and placed with operators.

```python
M = p.gap + p.wall                                        # board edge to the outside
body = prism(board.sketch(M), -T - 6, 8)                  # a slab round the board
body -= prism(board.sketch(p.gap), -T - 6 + p.wall, 9)    # hollowed: a tray, open to the front
enc.part("tray", body, up=(0, 0, 1))                      # prints open side up
```

- `prism(sketch, z0, z1)`, `box(x0, x1, y0, y1, z0, z1)`, `cyl(x, y, r, z0, z1)`, `rbox(…, r, Axis.Y)`
  (a box rounded round an axis: an opening through a wall), `locate((x, y, z), axis)` (a placement
  with +z along `axis`).
- `enc.part(name, solid, up=…)`: a printed part drawn where it sits. `up` is the direction that
  faces up on the printer's bed: `(0, 0, -1)` for a shell that prints face down. `supports=True`
  when it is meant to print on supports.
- `enc.part("cap", cap, at={s.ref: (s.x, s.y) for s in buttons})`: one shape drawn at its own
  origin, standing at each place. `colour="#c8452c"` to tell parts apart.
- build123d, not CadQuery: no `Workplane`, no chains. `Box`, `Cylinder` are centred on the origin;
  move with `Pos(x, y, z) * shape`, turn with `Rot(rx, ry, rz) * shape`. Fillet and chamfer take
  edges: `fillet(part.edges().filter_by(Axis.Z), 3)`, `chamfer(part.edges().group_by(Axis.Z)[-1], 1)`
  (`group_by(Axis.Z)[-1]`: the edges at the greatest z).
- Draw from the board: `usb = board["J3"]`, then `usb.x`. A number typed where the board has it is
  wrong after the next move of that part.

What prints well (FDM; `p` holds the numbers):

|                                              |                                                                                     |
| -------------------------------------------- | ----------------------------------------------------------------------------------- |
| walls and faces                              | `p.wall` (2.4); nothing under `p.min_wall` (0.8)                                    |
| board edge to wall, a part to a wall         | `p.gap` (0.5)                                                                       |
| a moving fit (a cap in its hole)             | `p.fit` a side (0.3)                                                                |
| a fit that only goes together (a lap, a lid) | `p.snug` a side (0.15)                                                              |
| the face on the bed                          | chamfer its edge, never fillet it; holes in it get a 0.4 chamfer                    |
| overhangs                                    | up to 45° without support; a 45° hood instead of a flat roof                        |
| features that meet                           | overlap them or part them by 0.4; two that only touch along a line break the slicer |
| posts round a screw                          | 1.6 mm of plastic round an insert's hole                                            |

A post or a rib must not stand in a part's courtyard: cut it back where one reaches into it.

### 4. Hardware

```python
screw = hardware.screw("M3x10")            # socket head, ISO 4762; head="button", "countersunk"
insert = hardware.insert("M3")             # heat-set, 5.7 long, in a 4.0 hole
# hardware.screw("3x8", head="pan", thread="plastic"), hardware.nut("M3", shape="square"),
# hardware.washer("M3"), hardware.magnet(6, 2)
```

The `enclosure` tool with `tell: "hardware m3"` lists what there is. Each has its numbers
(`screw.head_d`, `screw.clearance`, `insert.hole`, `insert.length`) and cutters for the room it
takes, drawn in its own frame and put in place with `locate`:

```python
for h in board.holes():
    front -= locate((h.x, h.y, 0.0)) * insert.pocket()        # the insert's hole, from the post's end
    back -= locate((h.x, h.y, SEAT)) * screw.well()           # clearance along the screw, a well for its head
enc.use(insert, at={h.ref: (h.x, h.y, 0.0) for h in holes}, into="front", name="insert")
enc.use(screw, at={h.ref: (h.x, h.y, SEAT) for h in holes}, into="insert", name="screw")
```

A screw's origin is under its head and it points along `axis` (default +z); an insert's origin is
at its hole's mouth and it goes in along `axis`. `into` names what it holds in: the insert, or the
part whose plastic it threads (`screw.thread()` cuts that hole). Choose the seat so the thread in
an insert is at least the screw's diameter (M3: 3 mm; 4 is comfortable) and the tip stops short of
the hole's end.

### 5. What must reach outside

```python
enc.plug("J3")                       # the largest USB-C plug's body reaches the socket
enc.light("D1")                      # a straight way out for an LED's light
enc.press("SW12")                    # a pin reaches a button that has no cap
enc.view("the display", x0, y0, x1, y1, z)   # nothing covers a display's picture (its active area at z)
enc.clear("SD card", solid, "a card goes in and comes out")   # any room of your own that must stay empty
enc.cap("cap")                       # the instances of "cap" are caps over the buttons they were placed on
```

An opening for a plug is the size of the plug's body (USB-C: 12.35 × 6.5 mm, so 13.4 × 7.5), not
of the socket's mouth. A cap is a stem through the face with a flange under it wider than its
hole, resting on the button's actuator, with about 0.5 mm of free way under the face.

### 6. The steps

```python
enc.step("Lay the front shell face down.", "front")
enc.step("Press the four inserts into the posts with a soldering iron, flush with their ends.", "insert")
enc.step("Drop the caps into their holes, stems down.", "cap")
enc.step("Lower the board onto the posts, display down.", "board")
enc.step("Lower the back shell on.", "back")
enc.step("Four screws from the back.", "screw")
enc.build()                          # last line of the program
```

Each step is what the person does, and the parts it adds (`"board"` is the board with everything
on it). The build checks that each goes in straight past what is already there, and the page's
slider is these steps read backwards, ending with every part laid flat. An opening for something
that sticks out of the board's edge (a lever, a socket) must be open towards the side the board
comes from, or the board cannot be lowered in.

### 7. Build, read, fix

Call `enclosure` (or `pcbkit enclosure` in a shell). Each line is one fact:

```
ok    front: one closed solid, 187.8 x 92.1 x 11.5 mm as it prints, 34.9 cm3
FAIL  back cuts into cell in BT1: 1113.640 mm3
FAIL  the largest USB-C plug body (12.35 x 6.5 mm) reaches J3 from the +y side: blocked by front (28.94 mm3)
FAIL  screw H1: has 0.5 mm of thread in its insert (at least 3.0)
FAIL  step 4, board: cannot be put in straight from any side; towards the back it is stopped by front (at SW11 lever, 1.11 mm3)
```

Then look at it: `look` with `view: "3d"` draws the device in its enclosure, and `stage` takes it apart step
by step (a low `pitch` looks at an edge, a negative one at the back). The checks find what does not
fit; a picture shows what merely looks wrong (a window off its display, an opening on the wrong
side, a post in the middle of nothing).

Fix the cause in the program (a level, a size, an opening), never the check. A line about a
board part you did not expect means the part is taller or nearer than you drew: read its place
again. Build after each change; a build takes seconds. When every line is ok the files are in
`enclosure/out/`: each printed part as `.step` (an exact solid, for a print service) and
`print/<part>.stl` turned the way it prints, `print/plate-1.3mf` (the parts arranged on the bed),
and the page shows the device.

### 8. What you tell the person

- What you made: the parts, the hardware to buy (the build's list), the size.
- To show them a step of the assembly, or every part laid out, write `stage: n` into the view file
  (`.pcbkit/view.yaml`, with `view: 3d`): their view glides there.
- **To measure before printing**: every number that came from a datasheet and not from the board
  file, by its name in the program and what to measure.
- How to print each part: which face on the bed, whether on supports. Suggest printing the smallest
  part that tests the fits first (one cap, the shell that carries the openings).
- What the checks do not cover: the printer's own accuracy (the fits assume `p.fit`), strength,
  how it feels in the hand.

Never call an enclosure ready on your own word: say which checks passed.
