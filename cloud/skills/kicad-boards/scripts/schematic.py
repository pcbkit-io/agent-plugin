"""A KiCad schematic written from a list of parts and the net of each pin.

Copy this file into the project (`scripts/schematic.py`) and describe the design once, in a script of
the project's own (`scripts/design.py`), which writes the schematic and from which the board's
script takes the same nets:

    from schematic import Schematic

    s = Schematic("board", title="USB-C blinker", rev="A")
    s.part("J1", "Connector:USB_C_Receptacle_USB2.0_16P", "USB-C", block="Power in",
           footprint="Connector_USB:USB_C_Receptacle_HRO_TYPE-C-31-M-12",
           fields={"MPN": "TYPE-C-31-M-12", "LCSC": "C165948"},
           pins={"A4": "+5V", "B4": "+5V", "A9": "+5V", "B9": "+5V", "A5": "CC1", "B5": "CC2",
                 "A1": "GND", "B1": "GND", "A12": "GND", "B12": "GND", "S1": "GND"})
    s.part("R1", "Device:R", "5.1k", block="Power in", pins={"1": "CC1", "2": "GND"}, ...)
    s.flag("+5V", "GND")          # where power comes in from outside the sheet (KiCad's PWR_FLAG)
    s.note("Power in", "5 V from USB-C; R1 and R2 ask the charger for it.")
    s.write("board.kicad_sch")    # then: check (KiCad's electrical rules), and look at its picture
    nets = s.nets()               # {"GND": [("J1", "A1"), ...]}: what the board's pads are given

What it draws: each part's symbol from KiCad's libraries (or the project's own `.kicad_sym`: a
`lib_id` such as `parts:TLC555`), the parts of a block side by side under the block's name, every
connected pin with a short wire and a global label naming its net (so a net's name on the board is
its name here), a no-connect mark on every pin given no net. Pins are named by number or by name
(a name several pins share needs their numbers). It needs Python 3 and KiCad's symbol libraries,
nothing else.
"""

from __future__ import annotations

import glob
import os
import uuid

GRID = 1.27
STUB = 2.54
CHAR = 1.0  # a label's width a character, at the default text size
LIBRARIES = [
    os.environ.get("KICAD_SYMBOL_DIR", ""),
    os.environ.get("KICAD10_SYMBOL_DIR", ""),
    os.environ.get("KICAD9_SYMBOL_DIR", ""),
    "/usr/share/kicad/symbols",
    "/Applications/KiCad/KiCad.app/Contents/SharedSupport/symbols",
    "C:/Program Files/KiCad/10.0/share/kicad/symbols",
    "C:/Program Files/KiCad/9.0/share/kicad/symbols",
]
PAPERS = [("A4", 297, 210), ("A3", 420, 297), ("A2", 594, 420), ("A1", 841, 594), ("A0", 1189, 841)]


class Q(str):
    """A quoted string of the file (a bare `str` is written as a token)."""


def parse(text: str) -> list:
    """KiCad's S-expressions as nested lists: tokens as `str`, quoted strings as `Q`."""
    stack: list[list] = [[]]
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "(":
            stack.append([])
        elif c == ")":
            done = stack.pop()
            stack[-1].append(done)
        elif c == '"':
            out = []
            i += 1
            while text[i] != '"':
                if text[i] == "\\":
                    i += 1
                    out.append({"n": "\n", "t": "\t"}.get(text[i], text[i]))
                else:
                    out.append(text[i])
                i += 1
            stack[-1].append(Q("".join(out)))
        elif not c.isspace():
            j = i
            while j < n and not text[j].isspace() and text[j] not in '()"':
                j += 1
            stack[-1].append(text[i:j])
            i = j - 1
        i += 1
    return stack[0][0]


def dump(node, depth: int = 0) -> str:
    if isinstance(node, Q):
        return '"' + node.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(node, float):
        return f"{node:.4f}".rstrip("0").rstrip(".")
    if not isinstance(node, list):
        return str(node)
    flat = "(" + " ".join(dump(x) for x in node) + ")"
    if len(flat) < 100 and not any(isinstance(x, list) and any(isinstance(y, list) for y in x) for x in node):
        return flat
    pad = "\t" * (depth + 1)
    head = [dump(x) for x in node if not isinstance(x, list)]
    body = [pad + dump(x, depth + 1) for x in node if isinstance(x, list)]
    return "(" + " ".join(head) + "\n" + "\n".join(body) + "\n" + "\t" * depth + ")"


def kids(node: list, name: str) -> list[list]:
    return [x for x in node if isinstance(x, list) and x and x[0] == name]


def kid(node: list, name: str):
    found = kids(node, name)
    return found[0] if found else None


def uid() -> Q:
    return Q(str(uuid.uuid4()))


def snap(v: float) -> float:
    return round(round(v / GRID) * GRID, 4)


def font(hide: bool = False, justify: str | None = None, size: float = 1.27) -> list:
    out: list = ["effects", ["font", ["size", size, size]]]
    if justify:
        out.append(["justify", justify])
    if hide:
        out.append(["hide", "yes"])
    return out


class Symbol:
    """A symbol of a library, flattened (a symbol that extends another has its drawing)."""

    def __init__(self, lib_id: str, project_dir: str):
        self.lib_id = lib_id
        lib, name = lib_id.split(":", 1)
        path = self._file(lib, project_dir)
        table = {str(s[1]): s for s in kids(parse(open(path, encoding="utf-8").read()), "symbol")}
        if name not in table:
            raise KeyError(f"{path} has no symbol {name}: `grep '(symbol \"' {path}` lists them")
        own = table[name]
        base, parent = own, kid(own, "extends")
        while parent is not None:
            base = table[str(parent[1])]
            parent = kid(base, "extends")
        units = []
        for unit in kids(base, "symbol"):
            unit = list(unit)
            unit[1] = Q(name + str(unit[1])[len(str(base[1])) :])
            units.append(unit)
        keep = [x for x in own if not (isinstance(x, list) and x[0] in ("symbol", "extends"))]
        if own is not base:  # the drawing's own settings (pin names, power) come with the drawing
            have = {x[0] for x in keep if isinstance(x, list)}
            keep += [x for x in base if isinstance(x, list) and x[0] not in have and x[0] not in ("symbol", "property")]
        self.node = [keep[0], Q(lib_id), *keep[2:], *units]
        self.props = {str(p[1]): str(p[2]) for p in kids(own, "property")}
        # pins by unit: (number, name, x, y, angle); unit 0 belongs to every unit
        self.pins: dict[int, list[tuple[str, str, float, float, int]]] = {}
        self.box: dict[int, list[float]] = {}
        for unit in units:
            u, style = (int(v) for v in str(unit[1]).rsplit("_", 2)[1:])
            if style > 1:
                continue
            for pin in kids(unit, "pin"):
                at = kid(pin, "at")
                self.pins.setdefault(u, []).append(
                    (str(kid(pin, "number")[1]), str(kid(pin, "name")[1]), float(at[1]), float(at[2]), int(float(at[3])) if len(at) > 3 else 0)
                )
            for x, y in self._points(unit):
                b = self.box.setdefault(u, [x, y, x, y])
                b[0], b[1], b[2], b[3] = min(b[0], x), min(b[1], y), max(b[2], x), max(b[3], y)
        self.units = sorted(u for u in set(self.pins) | set(self.box) if u > 0) or [1]

    @staticmethod
    def _file(lib: str, project_dir: str) -> str:
        for folder in [project_dir, *LIBRARIES]:
            path = os.path.join(folder, lib + ".kicad_sym") if folder else ""
            if path and os.path.exists(path):
                return path
        raise FileNotFoundError(
            f"No symbol library {lib}.kicad_sym in the project or in KiCad's libraries "
            f"({', '.join(sorted({os.path.basename(p)[:-10] for d in LIBRARIES if d for p in glob.glob(d + '/*.kicad_sym')})[:12])}, …)"
        )

    @staticmethod
    def _points(unit: list):
        for shape in unit[2:]:
            if not isinstance(shape, list):
                continue
            for key in ("start", "end", "mid", "center"):
                p = kid(shape, key)
                if p is not None:
                    yield float(p[1]), float(p[2])
            pts = kid(shape, "pts")
            for p in kids(pts, "xy") if pts else []:
                yield float(p[1]), float(p[2])
            if shape[0] == "pin":
                at = kid(shape, "at")
                yield float(at[1]), float(at[2])

    def of(self, unit: int):
        """The unit's pins (with those every unit shares when the part has one unit) and its drawing's box."""
        pins = self.pins.get(unit, []) + (self.pins.get(0, []) if len(self.units) == 1 else [])
        boxes = [b for u, b in self.box.items() if u in (0, unit)] or [[-2.54, -2.54, 2.54, 2.54]]
        box = [min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)]
        return pins, box


class Schematic:
    def __init__(self, name: str, title: str = "", rev: str = "", company: str = "", project_dir: str = "."):
        self.name, self.title, self.rev, self.company = name, title or name, rev, company
        self.project_dir = project_dir
        self.root = str(uuid.uuid4())
        self.parts: list[dict] = []
        self.blocks: list[str] = []
        self.notes: dict[str, str] = {}
        self.flags: list[str] = []
        self.symbols: dict[str, Symbol] = {}

    def symbol(self, lib_id: str) -> Symbol:
        if lib_id not in self.symbols:
            self.symbols[lib_id] = Symbol(lib_id, self.project_dir)
        return self.symbols[lib_id]

    def part(self, ref: str, lib_id: str, value: str, pins: dict[str, str | None], block: str = "",
             footprint: str = "", fields: dict[str, str] | None = None, dnp: bool = False) -> None:
        """A part: its symbol, and the net of each pin by number or by name (None, or left out: not connected)."""
        symbol = self.symbol(lib_id)
        every = [p for unit in symbol.pins.values() for p in unit]
        numbers = {p[0] for p in every}
        names: dict[str, list[str]] = {}
        for p in every:
            names.setdefault(p[1], []).append(p[0])
        nets: dict[str, str] = {}
        for key, net in pins.items():
            if net is None:
                continue
            if key in numbers:
                nets[key] = net
            elif key in names and len(names[key]) == 1:
                nets[names[key][0]] = net
            elif key in names:
                raise KeyError(f"{ref}: pins {', '.join(names[key])} are all named {key}: give their numbers")
            else:
                listed = ", ".join(f"{p[0]} {p[1]}" for p in sorted(every))
                raise KeyError(f"{ref} ({lib_id}) has no pin {key}. Its pins: {listed}")
        if any(p["ref"] == ref for p in self.parts):
            raise KeyError(f"{ref} is there already")
        if block not in self.blocks:
            self.blocks.append(block)
        self.parts.append(dict(ref=ref, symbol=symbol, value=value, nets=nets, block=block,
                               footprint=footprint, fields=fields or {}, dnp=dnp))

    def flag(self, *nets: str) -> None:
        """Nets that power comes in by from outside the sheet (a connector, a battery): KiCad's PWR_FLAG."""
        self.flags += [n for n in nets if n not in self.flags]

    def note(self, block: str, text: str) -> None:
        """A sentence under a block's name: what the block is for."""
        self.notes[block] = text

    def nets(self) -> dict[str, list[tuple[str, str]]]:
        """Every net with its pins: what the board's pads are given, so both files say the same."""
        out: dict[str, list[tuple[str, str]]] = {}
        for p in self.parts:
            for number, net in sorted(p["nets"].items()):
                out.setdefault(net, []).append((p["ref"], number))
        return out

    # ---- drawing

    def _cell(self, part: dict, unit: int):
        """A unit's room: how far its labels reach on each side of its origin (left, up, right, down)."""
        pins, box = part["symbol"].of(unit)
        left, up, right, down = -box[0], box[3], box[2], -box[1]
        for number, _name, x, y, angle in pins:
            reach = STUB + CHAR * (len(part["nets"].get(number, "")) + 3)
            if angle == 0:
                left = max(left, -x + reach)
            elif angle == 180:
                right = max(right, x + reach)
            elif angle == 90:
                down = max(down, -y + reach)
            else:
                up = max(up, y + reach)
        # (Over everything, labels too: the reference and the value, two lines.)
        return max(left, 3.81), up + 6.35, max(right, 3.81 + CHAR * max(len(part["ref"]), len(part["value"]))), down + 2.54

    def _instance(self, part: dict, unit: int, x: float, y: float, out: list) -> None:
        symbol: Symbol = part["symbol"]
        pins, box = symbol.of(unit)
        flag = part["ref"].startswith("#")
        sideways = any(angle in (0, 180) for *_rest, angle in pins)
        if sideways:  # pins left and right: the reference and the value over the drawing and its labels
            top = y - (self._cell(part, unit)[1] - 6.35)
            ref_at, value_at, justify = [x + box[0], top - 3.81, 0], [x + box[0], top - 1.27, 0], "left"
        else:  # pins up and down: both beside the drawing
            ref_at, value_at, justify = [x + box[2] + 1.27, y - 1.27, 0], [x + box[2] + 1.27, y + 1.27, 0], "left"
        props = [
            ["property", Q("Reference"), Q(part["ref"]), ["at", *ref_at], font(justify=justify, hide=flag)],
            ["property", Q("Value"), Q(part["value"]), ["at", *value_at], font(justify=justify, hide=flag)],
            ["property", Q("Footprint"), Q(part["footprint"]), ["at", x, y, 0], font(hide=True)],
            ["property", Q("Datasheet"), Q(part["fields"].get("Datasheet", symbol.props.get("Datasheet", ""))), ["at", x, y, 0], font(hide=True)],
        ]
        props += [["property", Q(k), Q(v), ["at", x, y, 0], font(hide=True)] for k, v in part["fields"].items() if k != "Datasheet"]
        out.append([
            "symbol", ["lib_id", Q(symbol.lib_id)], ["at", x, y, 0], ["unit", unit],
            ["exclude_from_sim", "no"], ["in_bom", "yes"], ["on_board", "yes"], ["dnp", "yes" if part["dnp"] else "no"],
            ["uuid", uid()], *props,
            *[["pin", Q(number), ["uuid", uid()]] for number, *_ in pins],
            ["instances", ["project", Q(self.name), ["path", Q("/" + self.root), ["reference", Q(part["ref"])], ["unit", unit]]]],
        ])
        for number, _name, px, py, angle in pins:
            ax, ay = snap(x + px), snap(y - py)
            net = part["nets"].get(number)
            if net is None:
                out.append(["no_connect", ["at", ax, ay], ["uuid", uid()]])
                continue
            dx, dy, turn, justify = {0: (-1, 0, 180, "right"), 180: (1, 0, 0, "left"), 90: (0, 1, 270, "right"), 270: (0, -1, 90, "left")}[angle % 360]
            bx, by = snap(ax + dx * STUB), snap(ay + dy * STUB)
            out.append(["wire", ["pts", ["xy", ax, ay], ["xy", bx, by]], ["stroke", ["width", 0], ["type", "default"]], ["uuid", uid()]])
            out.append(self._label(net, bx, by, turn, justify))

    @staticmethod
    def _label(net: str, x: float, y: float, turn: int, justify: str) -> list:
        return ["global_label", Q(net), ["shape", "passive"], ["at", x, y, turn], font(justify=justify), ["uuid", uid()],
                ["property", Q("Intersheetrefs"), Q("${INTERSHEET_REFS}"), ["at", 0, 0, 0], font(hide=True)]]

    def _block(self, parts: list[dict], block: str, row_width: float):
        """A block's parts in rows no wider than `row_width`: where each goes from the block's corner, and its size."""
        gap = 5.08
        cells = [(p, u, self._cell(p, u)) for p in parts if p["block"] == block for u in p["symbol"].units]
        rows: list[list] = [[]]
        x = 0.0
        for part, unit, (left, up, right, down) in cells:
            if rows[-1] and x + left + right > row_width:
                rows.append([])
                x = 0.0
            rows[-1].append((part, unit, x + left, up, down))
            x += left + right + gap
        placed, y, width = [], 10.16, CHAR * 2 * len(block) + 5.08  # (under the block's name and its sentence)
        for row in rows:
            up = max((c[3] for c in row), default=0.0)
            placed += [(part, unit, cx, y + up) for part, unit, cx, _up, _down in row]
            y += up + max((c[4] for c in row), default=0.0) + gap
            width = max(width, max((c[2] + self._cell(c[0], c[1])[2] for c in row), default=0.0))
        return placed, width, y

    def _draw(self, parts: list[dict], blocks: list[str], paper_width: float) -> tuple[list, float, float]:
        """The blocks side by side, a new row of blocks when the paper's width is used: the items and their room."""
        items: list = []
        margin, gap = 20.0, 12.7
        x, y, shelf, widest = margin, margin, 0.0, 0.0
        for block in blocks:
            placed, width, height = self._block(parts, block, min(paper_width - 2 * margin, 150.0))
            if x > margin and x + width > paper_width - margin:
                x, y, shelf = margin, y + shelf + gap, 0.0
            items.append(["text", Q(block or "Parts"), ["exclude_from_sim", "no"], ["at", snap(x), snap(y + 3.81), 0],
                          font(justify="left bottom", size=2.54), ["uuid", uid()]])
            if block in self.notes:
                items.append(["text", Q(self.notes[block]), ["exclude_from_sim", "no"], ["at", snap(x), snap(y + 7.62), 0],
                              font(justify="left bottom"), ["uuid", uid()]])
            for part, unit, px, py in placed:
                self._instance(part, unit, snap(x + px), snap(y + py), items)
            x += width + gap
            shelf = max(shelf, height)
            widest = max(widest, x - gap)
        return items, widest + margin, y + shelf + margin

    def write(self, path: str) -> str:
        """Writes the schematic; answers the paper it took (the smallest the parts fit on)."""
        parts = list(self.parts)
        for i, net in enumerate(self.flags):  # where power comes in: a flag on the net
            parts.append(dict(ref=f"#FLG{i + 1:02d}", symbol=self.symbol("power:PWR_FLAG"), value="PWR_FLAG",
                              nets={"1": net}, block="Power flags", footprint="", fields={}, dnp=False))
        blocks = self.blocks + (["Power flags"] if self.flags else [])
        for paper, w, h in PAPERS:
            items, width, height = self._draw(parts, blocks, w)
            if width <= w and height <= h - 35.0:  # (the title block's room at the bottom)
                break
        used = {p["symbol"].lib_id: p["symbol"] for p in parts}
        doc = [
            "kicad_sch", ["version", 20250114], ["generator", Q("pcbkit")], ["generator_version", Q("9.0")],
            ["uuid", Q(self.root)], ["paper", Q(paper)],
            ["title_block", ["title", Q(self.title)], ["rev", Q(self.rev)], ["company", Q(self.company)]],
            ["lib_symbols", *[s.node for s in used.values()]],
            *items,
            ["sheet_instances", ["path", Q("/"), ["page", Q("1")]]],
            ["embedded_fonts", "no"],
        ]
        with open(path, "w", encoding="utf-8") as f:
            f.write(dump(doc) + "\n")
        return paper
