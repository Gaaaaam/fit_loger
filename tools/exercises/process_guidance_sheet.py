"""Slice manifest-selected mother sheets into deterministic RGB WebP frames."""
import argparse
from pathlib import Path
import re

from PIL import Image

if __package__:
    from .verify_guidance_assets import load_manifest
else:
    from verify_guidance_assets import load_manifest


def frame_boxes(width: int, height: int, layout: str) -> list[tuple[int, int, int, int]]:
    divisions = {"horizontal-2": (2, 1), "horizontal-3": (3, 1), "grid-4": (2, 2)}
    if layout not in divisions:
        raise ValueError(f"unsupported layout: {layout}")
    columns, rows = divisions[layout]
    if width <= 0 or height <= 0 or width % columns or height % rows:
        raise ValueError(f"dimensions {width}x{height} cannot split cleanly for {layout}")
    cell_w, cell_h = width // columns, height // rows
    return [(column * cell_w, row * cell_h, (column + 1) * cell_w, (row + 1) * cell_h)
            for row in range(rows) for column in range(columns)]


def process_sheet(sheet: Path, exercise_id: str, gender: str, layout: str, out_dir: Path) -> list[Path]:
    if not re.fullmatch(r"[a-z][a-z0-9_]*", exercise_id) or gender not in ("female", "male"):
        raise ValueError("invalid exercise ID or gender")
    outputs = []
    with Image.open(sheet) as source:
        source.load()
        boxes = frame_boxes(source.width, source.height, layout)
        rgb = source.convert("RGB")
        out_dir.mkdir(parents=True, exist_ok=True)
        for index, box in enumerate(boxes, 1):
            frame = rgb.crop(box)
            frame.info.clear()
            output = out_dir / f"ex_{exercise_id}_{gender}_{index:02}.webp"
            frame.save(output, format="WEBP", quality=82, method=6, exif=b"")
            outputs.append(output)
    return outputs


def process_manifest(manifest_path: Path, sheet_root: Path, out_dir: Path,
                     part: str | None = None) -> list[Path]:
    outputs = []
    for entry in load_manifest(manifest_path):
        if part is not None and entry["partKey"] != part:
            continue
        for gender in ("female", "male"):
            sheet = sheet_root / entry["id"] / f"{gender}-sheet.png"
            outputs.extend(process_sheet(sheet, entry["id"], gender, entry["layout"], out_dir))
    return outputs


def build_contact_sheet(frames: list[Path], output: Path) -> Path:
    """Write a PNG preview in supplied frame order, with each panel 320 px wide."""
    if not frames:
        raise ValueError("contact sheet needs at least one frame")
    panels = []
    for path in frames:
        with Image.open(path) as image:
            panels.append(image.convert("RGB").resize(
                (320, round(image.height * 320 / image.width)), Image.Resampling.LANCZOS))
    preview = Image.new("RGB", (320 * len(panels), max(panel.height for panel in panels)), "white")
    for index, panel in enumerate(panels):
        preview.paste(panel, (index * 320, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    preview.save(output, format="PNG")
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--sheet-root", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--part")
    parser.add_argument("--contact-sheet", type=Path)
    args = parser.parse_args()
    try:
        outputs = process_manifest(args.manifest, args.sheet_root, args.out_dir, args.part)
        if args.contact_sheet is not None:
            groups = {}
            for path in outputs:
                groups.setdefault(path.stem.rsplit("_", 1)[0], []).append(path)
            for name, frames in groups.items():
                build_contact_sheet(frames, args.contact_sheet / f"{name}_contact.png")
    except (ValueError, OSError) as error:
        parser.exit(1, f"Guidance processing failed: {error}\n")
    print(f"Processed {len(outputs)} WebP frames")


if __name__ == "__main__":
    main()
