# What the person sees: the view file

`.pcbkit/view.yaml` is the person's view of the board, as a file. Read it to learn what they look at; write it to show them something (their view glides there). Every field is optional:

```yaml
view: 3d # 2d, 3d or schematic
select: [U1, C3, "net:GND"] # lit and framed: references, pads (U1/3), net:<name>, layer:<name>, item uuids
layers: { "B.Cu": false, "F.SilkS": true } # KiCad layer names shown or hidden
components: false # the bare board, without parts
explode: true # the copper layers apart
stage: 3 # a device with a built enclosure, in 3D: its assembly taken apart to this stage (0: together; the last: every part laid flat)
look: { mask: Black } # a mask colour to try in 3D (Green, Black, Blue, Red, White, Purple, Yellow, "#RRGGBB"); the design keeps its own
camera:
  2d: { center: [110, 105], width: 40 } # mm
  3d: { target: [110, 105, 0], yaw: 30, pitch: 40, distance: 120 }
tour: # takes the person round the board in 3D, stop by stop, with your words under it
  - show: [J1, R2, R3] # what the stop frames and marks (ids as in select)
    title: Power comes in # optional
    say: The USB-C socket takes 5 V. R2 and R3 tell the charger a device is here.
  - show: [U1, C1, C2]
    say: The regulator turns 5 V into 3.3 V. C1 and C2 keep it steady.
```

Angles of `camera.3d`: `yaw` 0 looks from the front (the board's bottom edge, as it reads), 90 from its right edge, 180 from the back edge, -90 from the left; `pitch` is degrees above the board (85 is from over it), negative from under it: the back of the board is `pitch: -50`. Leave `distance` out and the board is framed. `look { view: "3d", yaw, pitch }` gives you the same picture, to check what you are about to show.

"Show me the back", "zoom in on the regulator", "what does it look like in black" are changes of this file, not of the design.

"Walk me through it", "explain this board", "how does the power get to the chip" are a `tour`: a few stops in the order the story goes (the signal's or the power's way, not the references' order), each with a sentence or two a person can read in the time the camera turns round it: what the parts are there for, not their part numbers again. It plays as soon as the file has it; the person can pause it, step through it and close it (which takes it out of the file). The board's real colours and finish are in the `.kicad_pcb` (`setup` → `stackup`: the mask and silkscreen layers' `color`, `copper_finish`).
