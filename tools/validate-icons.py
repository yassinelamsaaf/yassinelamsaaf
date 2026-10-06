"""Checks the generated cards in assets/logos/ before they are committed.

Every card is an SVG of a fixed height containing [optional mark][label]. This
verifies the card is valid XML, that the geometry in the file is internally
consistent (declared width vs viewBox, label position vs mark extent, label
extent vs card width), and that a text-only card is exactly as wide as its
label needs. Geometry is re-derived from the same metrics the build script uses,
so a regression in either script shows up here.

The mark's own viewBox travels in the group's data-vb attribute, written by the
build script, which is what lets the mark extent be recomputed instead of
guessed. (Guessing it from the path data does not work: SVG path numbers are not
uniformly x,y pairs, so arc flags and radii get read as coordinates.)

    python tools/validate-icons.py

Exits non-zero on any fault.
"""

import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

SVG = "{http://www.w3.org/2000/svg}"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "assets", "logos")

EXPECT_H = 20.0        # card height
FONT = 10.0
PAD = 6.0
GAP = 4.0
MARK = 13.0
MAXW = 42.0           # width cap on the mark
RADIUS = 0.0          # square corners
INK = "#1f2328"       # label colour, and the only colour a matte mark may use
SLACK = 1.5            # tolerated shortfall before a label counts as clipped

# group -> (card fill, card edge). One fill per group.
GROUPS = {
    "contact": ("#f6f8fa", "#d0d7de"),
    "lang": ("#dbeafe", "#93c5fd"),
    "front": ("#cffafe", "#67e8f9"),
    "back": ("#dcfce7", "#86efac"),
    "data": ("#ffedd5", "#fdba74"),
    "ops": ("#ede9fe", "#c4b5fd"),
}
MATTE_GROUP = "contact"

# Helvetica advance widths per 1000 em.
W = {
    " ": 278, "!": 278, '"': 355, "#": 556, "$": 556, "%": 889, "&": 667,
    "'": 191, "(": 333, ")": 333, "*": 389, "+": 584, ",": 278, "-": 333,
    ".": 278, "/": 278, ":": 278, ";": 278, "?": 556, "@": 1015, "|": 260,
    **{str(d): 556 for d in range(10)},
    "A": 667, "B": 667, "C": 722, "D": 722, "E": 667, "F": 611, "G": 778,
    "H": 722, "I": 278, "J": 500, "K": 667, "L": 556, "M": 833, "N": 722,
    "O": 778, "P": 667, "Q": 778, "R": 722, "S": 667, "T": 611, "U": 722,
    "V": 667, "W": 944, "X": 667, "Y": 667, "Z": 611,
    "a": 556, "b": 556, "c": 500, "d": 556, "e": 556, "f": 278, "g": 556,
    "h": 556, "i": 222, "j": 222, "k": 500, "l": 222, "m": 833, "n": 556,
    "o": 556, "p": 556, "q": 556, "r": 333, "s": 500, "t": 278, "u": 556,
    "v": 500, "w": 722, "x": 500, "y": 500, "z": 500,
}


def text_width(s):
    return sum(W.get(c, 556) for c in s) / 1000.0 * FONT


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "*.svg")))
    if not files:
        print("no cards found")
        return 1

    problems = []
    rows = []

    for f in files:
        name = os.path.basename(f)[:-4]
        raw = open(f, encoding="utf-8").read()

        try:
            root = ET.fromstring(raw)
        except ET.ParseError as e:
            problems.append(f"{name}: XML parse error -> {e}")
            continue

        vb = (root.get("viewBox") or "").split()
        if len(vb) != 4:
            problems.append(f"{name}: bad viewBox {root.get('viewBox')!r}")
            continue

        try:
            w, h = float(root.get("width")), float(root.get("height"))
        except (TypeError, ValueError):
            problems.append(f"{name}: missing or non-numeric width/height")
            continue

        if abs(h - EXPECT_H) > 0.01:
            problems.append(f"{name}: height {h} != {EXPECT_H}")
        if abs(float(vb[2]) - w) > 0.01 or abs(float(vb[3]) - h) > 0.01:
            problems.append(
                f"{name}: viewBox {vb[2]}x{vb[3]} disagrees with width/height {w}x{h}"
            )

        group = root.get("data-group")
        if group not in GROUPS:
            problems.append(f"{name}: unknown or missing data-group {group!r}")
            want_bg = want_edge = None
        else:
            want_bg, want_edge = GROUPS[group]

        rect = root.find(f"{SVG}rect")
        if rect is None:
            problems.append(f"{name}: no card background rect")
        else:
            rx = float(rect.get("rx", 0))
            if abs(rx - RADIUS) > 0.01:
                problems.append(f"{name}: corner radius {rx}, expected {RADIUS}")
            if want_bg:
                if (rect.get("fill") or "").lower() != want_bg:
                    problems.append(
                        f"{name}: fill {rect.get('fill')!r}, expected {want_bg} for {group}"
                    )
                if (rect.get("stroke") or "").lower() != want_edge:
                    problems.append(
                        f"{name}: stroke {rect.get('stroke')!r}, expected {want_edge} for {group}"
                    )

        text = root.find(f"{SVG}text")
        if text is None or not (text.text or "").strip():
            problems.append(f"{name}: no label")
            continue
        label = text.text.strip()

        if abs(float(text.get("font-size", 0)) - FONT) > 0.01:
            problems.append(f"{name}: font-size {text.get('font-size')} != {FONT}")

        base_y = float(text.get("y", 0))
        want_base = (EXPECT_H + FONT * 0.72) / 2
        if abs(base_y - want_base) > 0.15:
            problems.append(
                f"{name}: label baseline y={base_y}, expected ~{want_base:.2f} "
                f"to centre it in {EXPECT_H}"
            )

        # Recompute the mark extent from the viewBox the build script recorded.
        g = root.find(f"{SVG}g")
        mark_w = 0.0
        if g is not None:
            src = (g.get("data-vb") or "").split()
            tr = g.get("transform", "")
            ms = re.search(r"scale\(\s*([\d.eE+-]+)\s*\)", tr)
            mt = re.search(r"translate\(\s*([\d.eE+-]+)\s*,\s*([\d.eE+-]+)\s*\)", tr)
            if len(src) != 4 or not ms or not mt:
                problems.append(f"{name}: mark group missing data-vb or transform")
            else:
                if not len(list(g.iter())):
                    problems.append(f"{name}: mark group is empty")
                scale = float(ms.group(1))
                want_scale = min(MARK / float(src[3]), MAXW / float(src[2]))
                if abs(scale - want_scale) > 1e-6:
                    problems.append(
                        f"{name}: mark scale {scale:g}, expected {want_scale:g} "
                        f"(height {MARK}, width cap {MAXW})"
                    )
                if float(src[2]) * scale > MAXW + 0.05:
                    problems.append(
                        f"{name}: mark is {float(src[2]) * scale:.2f}px wide, "
                        f"over the {MAXW} cap"
                    )
                want_ty = (EXPECT_H - MARK) / 2
                if abs(float(mt.group(2)) - want_ty) > 0.05:
                    problems.append(
                        f"{name}: mark y={mt.group(2)}, expected {want_ty} to centre it"
                    )
                mark_w = float(src[2]) * scale

                # A matte mark must resolve to exactly one colour. Anything left
                # in currentColor would follow whatever the renderer picks, and
                # any surviving hex paint means the mark is not actually flat.
                if group == MATTE_GROUP:
                    if (g.get("fill") or "").lower() != INK:
                        problems.append(
                            f"{name}: matte mark has fill {g.get('fill')!r}, "
                            f"expected {INK}"
                        )
                    stray = set()
                    for el in g.iter():
                        for attr in ("fill", "stop-color", "stroke"):
                            v = (el.get(attr) or "").lower()
                            if v and not v.startswith("url(#") and v != INK:
                                stray.add(v)
                    if "currentcolor" in stray:
                        stray.discard("currentcolor")
                        problems.append(
                            f"{name}: matte mark still uses currentColor"
                        )
                    if stray:
                        problems.append(
                            f"{name}: matte mark has non-ink paint {sorted(stray)}"
                        )

        tx = float(text.get("x", 0))
        want_tx = PAD + mark_w + (GAP if mark_w else 0.0)
        if abs(tx - want_tx) > 0.05:
            problems.append(
                f"{name}: label x={tx}, expected {want_tx:.2f} "
                f"(mark is {mark_w:.2f}px wide)"
            )

        needed = tx + text_width(label) + PAD
        if w + SLACK < needed:
            problems.append(
                f"{name}: card is {w}px but contents need {needed:.2f}px "
                f"(label {label!r} would clip)"
            )

        rows.append((name, label, group, w, round(mark_w, 1)))

    print(f"{'slug':<16}{'label':<18}{'group':<9}{'card w':>8}{'mark w':>8}")
    print("-" * 59)
    for n, lab, grp, w, mw in rows:
        print(f"{n:<16}{lab:<18}{grp:<9}{w:>8}{mw:>8}")

    print()
    print(f"cards: {len(rows)}   problems: {len(problems)}")
    for p in problems:
        print("  x", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())