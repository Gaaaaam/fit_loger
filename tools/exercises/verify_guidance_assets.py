"""Validate guidance metadata and decoded production WebP frames."""
import argparse
import json
from pathlib import Path
import re

from PIL import Image


LAYOUT_COUNTS = {"horizontal-2": 2, "horizontal-3": 3, "grid-4": 4}


def load_manifest(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("exercises"), list):
        raise ValueError("manifest must contain an exercises array")
    seen = set()
    for entry in data["exercises"]:
        if not isinstance(entry, dict):
            raise ValueError("exercise must be an object")
        exercise_id = entry.get("id")
        if not isinstance(exercise_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", exercise_id):
            raise ValueError(f"invalid exercise ID: {exercise_id}")
        if exercise_id in seen:
            raise ValueError(f"duplicate ID: {exercise_id}")
        seen.add(exercise_id)
        layout = entry.get("layout")
        if not isinstance(layout, str) or layout not in LAYOUT_COUNTS:
            raise ValueError(f"{exercise_id}: invalid layout")
        count = entry.get("frameCount")
        if type(count) is not int or count != LAYOUT_COUNTS[layout]:
            raise ValueError(f"{exercise_id}: frameCount does not match layout")
        captions = entry.get("captions")
        if (not isinstance(captions, list) or len(captions) != count
                or any(not isinstance(caption, str) or not caption.strip() for caption in captions)):
            raise ValueError(f"{exercise_id}: caption-count mismatch or empty caption")
        index = entry.get("cardFrameIndex")
        if type(index) is not int or not 0 <= index < count:
            raise ValueError(f"{exercise_id}: cardFrameIndex out of range")
        if entry.get("status") not in ("planned", "approved"):
            raise ValueError(f"{exercise_id}: invalid status")
        for field in ("partKey", "view", "equipmentNotes", "muscleNotes"):
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                raise ValueError(f"{exercise_id}: missing {field}")
    return data["exercises"]


def verify_assets(manifest: Path, media: Path, require_all: bool = False,
                  part: str | None = None) -> tuple[int, int, int]:
    entries = [entry for entry in load_manifest(manifest) if part is None or entry["partKey"] == part]
    checked = 0
    for entry in entries:
        for gender in ("female", "male"):
            for index in range(1, entry["frameCount"] + 1):
                path = media / f"ex_{entry['id']}_{gender}_{index:02}.webp"
                if not path.is_file():
                    if require_all or entry["status"] == "approved":
                        raise ValueError(f"missing frame: {path}")
                    continue
                with Image.open(path) as image:
                    image.load()
                    if image.format != "WEBP":
                        raise ValueError(f"not WebP: {path}")
                    if image.width < 384 or image.height < 384:
                        raise ValueError(f"frame below 384x384: {path} ({image.width}x{image.height})")
                checked += 1
    approved = sum(entry["status"] == "approved" for entry in entries)
    return approved, len(entries) - approved, checked


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--media", type=Path, required=True)
    parser.add_argument("--require-all", action="store_true")
    parser.add_argument("--part")
    args = parser.parse_args()
    try:
        approved, planned, checked = verify_assets(args.manifest, args.media, args.require_all, args.part)
    except (ValueError, OSError) as error:
        parser.exit(1, f"Guidance validation failed: {error}\n")
    print(f"PASS: approved={approved}, planned={planned}, frames={checked}")


if __name__ == "__main__":
    main()
