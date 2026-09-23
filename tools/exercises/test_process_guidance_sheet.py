"""Behavior tests for the guidance image pipeline (bundled Python + Pillow)."""
import importlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw


class SheetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.assertTrue(Path(__file__).with_name("process_guidance_sheet.py").exists(),
                        "process_guidance_sheet.py is missing")
        self.processor = importlib.import_module("tools.exercises.process_guidance_sheet")

    def sheet(self, boxes, colors):
        path = self.root / "sheet.png"
        image = Image.new("RGB", (1536, 1024))
        draw = ImageDraw.Draw(image)
        for box, color in zip(boxes, colors):
            draw.rectangle(box, fill=color)
        image.save(path)
        return path

    def check_frames(self, paths, size, colors):
        self.assertEqual([p.name for p in paths], [
            f"ex_leg_squat_female_{i:02}.webp" for i in range(1, len(colors) + 1)])
        for path, color in zip(paths, colors):
            with Image.open(path) as image:
                self.assertEqual(image.format, "WEBP")
                self.assertEqual(image.mode, "RGB")
                self.assertEqual(image.size, size)
                self.assertFalse(image.getexif())
                pixel = image.getpixel((size[0] // 2, size[1] // 2))
                self.assertTrue(all(abs(a - b) <= 5 for a, b in zip(pixel, color)), pixel)

    def test_horizontal_2_splits_equal_columns(self):
        colors = [(255, 0, 0), (0, 0, 255)]
        source = self.sheet([(0, 0, 767, 1023), (768, 0, 1535, 1023)], colors)
        paths = self.processor.process_sheet(source, "leg_squat", "female", "horizontal-2", self.root)
        self.check_frames(paths, (768, 1024), colors)

    def test_horizontal_3_splits_equal_columns(self):
        colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
        source = self.sheet([(0, 0, 511, 1023), (512, 0, 1023, 1023), (1024, 0, 1535, 1023)], colors)
        paths = self.processor.process_sheet(source, "leg_squat", "female", "horizontal-3", self.root)
        self.check_frames(paths, (512, 1024), colors)

    def test_grid_4_splits_quadrants_in_reading_order(self):
        colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]
        source = self.sheet([(0, 0, 767, 511), (768, 0, 1535, 511),
                             (0, 512, 767, 1023), (768, 512, 1535, 1023)], colors)
        paths = self.processor.process_sheet(source, "leg_squat", "female", "grid-4", self.root)
        self.check_frames(paths, (768, 512), colors)

    def test_contact_sheet_keeps_frame_order_at_320_px(self):
        source = self.sheet([(0, 0, 767, 1023), (768, 0, 1535, 1023)], [(255, 0, 0), (0, 0, 255)])
        paths = self.processor.process_sheet(source, "leg_squat", "female", "horizontal-2", self.root)
        before = [path.read_bytes() for path in paths]
        preview = self.processor.build_contact_sheet(paths, self.root / "preview.png")
        with Image.open(preview) as image:
            self.assertEqual(image.size, (640, 427))
            self.assertGreater(image.getpixel((160, 200))[0], 245)
            self.assertGreater(image.getpixel((480, 200))[2], 245)
        self.assertEqual(before, [path.read_bytes() for path in paths])

    def test_rejects_unsplittable_dimensions_and_unknown_layout(self):
        for width, height, layout in [(1535, 1024, "horizontal-2"), (1537, 1024, "horizontal-3"),
                                      (1536, 1023, "grid-4"), (1535, 1024, "grid-4"),
                                      (1536, 1024, "diagonal"), (0, 1024, "horizontal-2")]:
            with self.subTest(layout=layout, size=(width, height)), self.assertRaises(ValueError):
                self.processor.frame_boxes(width, height, layout)

    def test_webp_is_repeatable_rgb_and_strips_source_exif(self):
        source = self.root / "with-exif.png"
        image = Image.new("RGBA", (1536, 1024), (255, 0, 0, 255))
        exif = Image.Exif()
        exif[270] = "source metadata"
        image.save(source, exif=exif)
        paths = self.processor.process_sheet(source, "leg_squat", "female", "horizontal-2", self.root)
        self.check_frames(paths, (768, 1024), [(255, 0, 0), (255, 0, 0)])
        first = [path.read_bytes() for path in paths]
        paths = self.processor.process_sheet(source, "leg_squat", "female", "horizontal-2", self.root)
        self.assertEqual(first, [path.read_bytes() for path in paths])


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = Path(__file__).resolve().parents[2]
        self.media = self.root / "media"
        self.media.mkdir()
        self.entry = {"id": "leg_squat", "partKey": "leg", "frameCount": 2,
                      "layout": "horizontal-2", "captions": ["开始", "结束"],
                      "cardFrameIndex": 1, "view": "side", "equipmentNotes": "barbell",
                      "muscleNotes": "quadriceps", "status": "planned"}
        self.manifest = self.root / "guidance.json"
        self.write_manifest([self.entry])

    def write_manifest(self, entries):
        self.manifest.write_text(json.dumps({"exercises": entries}, ensure_ascii=False), encoding="utf-8")

    def run_tool(self, filename, *args, success=True):
        path = self.repo / "tools" / "exercises" / filename
        self.assertTrue(path.exists(), f"{filename} is missing")
        result = subprocess.run([sys.executable if filename.endswith(".py") else "node", str(path), *map(str, args)],
                                cwd=self.repo, env={**os.environ, "PYTHONIOENCODING": "utf-8"},
                                capture_output=True, text=True, encoding="utf-8")
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def make_frames(self, size=(384, 384), fmt="WEBP"):
        for gender in ("female", "male"):
            for index in (1, 2):
                Image.new("RGB", size, "red").save(self.media / f"ex_leg_squat_{gender}_{index:02}.webp", format=fmt)

    def test_processor_cli_filters_literal_part_and_builds_previews(self):
        other = {**self.entry, "id": "core_bird_dog", "partKey": "core"}
        self.write_manifest([self.entry, other])
        sheet_dir = self.root / "sheets" / "leg_squat"
        sheet_dir.mkdir(parents=True)
        for gender in ("female", "male"):
            image = Image.new("RGB", (1536, 1024), "red")
            ImageDraw.Draw(image).rectangle((768, 0, 1535, 1023), fill="blue")
            image.save(sheet_dir / f"{gender}-sheet.png")
        Image.new("RGB", (10, 10)).save(sheet_dir / "unrelated.png")
        self.run_tool("process_guidance_sheet.py", "--manifest", self.manifest, "--sheet-root", sheet_dir.parent,
                      "--out-dir", self.media, "--part", "leg", "--contact-sheet", self.root / "previews")
        self.assertEqual(sorted(p.name for p in self.media.iterdir()), [
            "ex_leg_squat_female_01.webp", "ex_leg_squat_female_02.webp",
            "ex_leg_squat_male_01.webp", "ex_leg_squat_male_02.webp"])
        for gender in ("female", "male"):
            with Image.open(self.root / "previews" / f"ex_leg_squat_{gender}_contact.png") as preview:
                self.assertEqual(preview.size, (640, 427))
                self.assertGreater(preview.getpixel((160, 200))[0], 245)
                self.assertGreater(preview.getpixel((480, 200))[2], 245)
        self.run_tool("process_guidance_sheet.py", "--manifest", self.manifest, "--sheet-root", sheet_dir.parent,
                      "--out-dir", self.media, success=False)

    def test_verifier_rejects_invalid_manifests(self):
        mutations = [{"layout": "diagonal"}, {"frameCount": 3}, {"captions": ["one"]},
                     {"cardFrameIndex": -1}, {"cardFrameIndex": 2}, {"status": "done"},
                     {"id": "../escape"}, {"partKey": ""}]
        for change in mutations:
            with self.subTest(change=change):
                self.write_manifest([{**self.entry, **change}])
                self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)
                self.run_tool("generate_guidance_mapping.mjs", "--manifest", self.manifest, "--media", self.media,
                              "--out", self.root / "invalid.ets", success=False)
        self.write_manifest([self.entry, self.entry])
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)

    def test_verifier_requires_both_genders_for_approved_or_require_all(self):
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media)
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, "--require-all", success=False)
        self.write_manifest([{**self.entry, "status": "approved"}])
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)
        self.make_frames()
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media)
        (self.media / "ex_leg_squat_male_02.webp").unlink()
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, "--part", "core")

    def test_verifier_rejects_small_wrong_format_and_undecodable_files(self):
        self.write_manifest([{**self.entry, "status": "approved"}])
        for size, fmt in [((383, 384), "WEBP"), ((384, 383), "WEBP"), ((384, 384), "PNG")]:
            with self.subTest(size=size, fmt=fmt):
                self.make_frames(size, fmt)
                self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)
        self.make_frames()
        (self.media / "ex_leg_squat_female_01.webp").write_bytes(b"not an image")
        self.run_tool("verify_guidance_assets.py", "--manifest", self.manifest, "--media", self.media, success=False)

    def load_mapping(self, path):
        # Execute the generated module after removing ArkTS type syntax, as project logic checks do.
        script = """import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import {runInNewContext} from 'node:vm';
const context = {$r: name => name};
const source = stripTypeScriptTypes(readFileSync(process.argv[1], 'utf8')).replace(/export /g, '');
runInNewContext(source + '\\nglobalThis.result = GENERATED_GUIDANCE_ARTWORK;', context);
console.log(JSON.stringify(context.result));"""
        result = subprocess.run(["node", "--input-type=module", "-e", script, str(path)],
                                capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_mapping_executes_empty_then_only_approved_with_ordered_resources(self):
        output = self.root / "generated.ets"
        self.run_tool("generate_guidance_mapping.mjs", "--manifest", self.manifest, "--media", self.media, "--out", output)
        self.assertEqual(self.load_mapping(output), [])
        approved = {**self.entry, "status": "approved"}
        self.write_manifest([approved, {**self.entry, "id": "core_bird_dog", "partKey": "core"}])
        self.run_tool("generate_guidance_mapping.mjs", "--manifest", self.manifest, "--media", self.media, "--out", output, success=False)
        self.make_frames()
        self.run_tool("generate_guidance_mapping.mjs", "--manifest", self.manifest, "--media", self.media, "--out", output)
        self.assertEqual(self.load_mapping(output), [{"id": "leg_squat",
            "femaleFrames": ["app.media.ex_leg_squat_female_01", "app.media.ex_leg_squat_female_02"],
            "maleFrames": ["app.media.ex_leg_squat_male_01", "app.media.ex_leg_squat_male_02"],
            "frameCaptions": ["开始", "结束"], "cardFrameIndex": 1}])

    def test_prompts_join_catalog_and_filter_planned_jobs(self):
        result = self.run_tool("guidance_prompt.mjs", "--check")
        self.assertIn("PASS", result.stdout)
        result = self.run_tool("guidance_prompt.mjs", "leg_squat", "female")
        job = json.loads(result.stdout)
        self.assertEqual((job["id"], job["gender"], job["sheetPath"]),
                         ("leg_squat", "female", ".work/exercise-guidance/leg_squat/female-sheet.png"))
        for term in ["no text", "no watermark", "female", "horizontal-3", "站立起始", "控制下蹲", "底部换向",
                     "Barbell Back Squat", "scientific-educational", "full-body", "neutral background"]:
            self.assertIn(term, job["prompt"])
        self.write_manifest([self.entry,
                             {**self.entry, "id": "chest_bb_bench", "partKey": "chest"}])
        jobs = [json.loads(line) for line in self.run_tool("guidance_prompt.mjs", "--manifest", self.manifest,
                                                          "--jobs", "--part", "chest").stdout.splitlines()]
        self.assertEqual([(job["id"], job["gender"]) for job in jobs],
                         [("chest_bb_bench", "female"), ("chest_bb_bench", "male")])
        self.run_tool("guidance_prompt.mjs", "leg_squat", "other", success=False)
        self.run_tool("guidance_prompt.mjs", "unknown", "female", success=False)
        self.write_manifest([{**self.entry, "status": "approved"},
                             {**self.entry, "id": "core_bird_dog", "partKey": "core"}])
        jobs = [json.loads(line) for line in self.run_tool("guidance_prompt.mjs", "--manifest", self.manifest,
                                                          "--jobs").stdout.splitlines()]
        self.assertEqual([(job["id"], job["gender"]) for job in jobs],
                         [("core_bird_dog", "female"), ("core_bird_dog", "male")])

    def test_prompt_rejects_non_string_layouts(self):
        for layout in (["horizontal-2"], {"name": "grid-4"}, None):
            with self.subTest(layout=layout):
                self.write_manifest([{**self.entry, "layout": layout}])
                result = self.run_tool("guidance_prompt.mjs", "--manifest", self.manifest,
                                       "--jobs", success=False)
                self.assertIn("invalid layout", result.stderr)

    def test_arnold_prompt_uses_manifest_start_without_conflicting_catalog_start(self):
        job = json.loads(self.run_tool("guidance_prompt.mjs", "shoulder_arnold", "female").stdout)
        self.assertIn("掌心相对起始", job["prompt"])
        self.assertIn("旋转推起", job["prompt"])
        self.assertIn("头顶结束", job["prompt"])
        self.assertNotIn("掌心朝向自己", job["prompt"])

    def test_prompt_prefers_manifest_movement_reference_over_catalog_variants(self):
        selected = "Start from a high-bar squat with both heels planted."
        self.write_manifest([{**self.entry, "movementReference": selected}])
        job = json.loads(self.run_tool("guidance_prompt.mjs", "--manifest", self.manifest,
                                       "--jobs").stdout.splitlines()[0])
        self.assertIn(selected, job["prompt"])
        self.assertNotIn("杠铃置于上背", job["prompt"])
        self.assertIn("selected variation is authoritative", job["prompt"])

    def test_selected_catalog_variants_are_unambiguous_in_generated_prompts(self):
        cases = [
            ("arm_overhead_extension", "right hand holds one dumbbell overhead", "坐姿或站姿"),
            ("shoulder_db_press", "standing bilateral dumbbell press", "站立或坐姿"),
            ("shoulder_cable_front", "both hands grasp one straight-bar attachment", "背对或侧向"),
            ("back_one_arm_cable_row", "half-kneeling facing the high pulley", "侧向或面对"),
        ]
        for exercise_id, chosen, rejected in cases:
            with self.subTest(exercise_id=exercise_id):
                prompt = json.loads(self.run_tool("guidance_prompt.mjs", exercise_id, "female").stdout)["prompt"]
                self.assertIn(chosen, prompt)
                self.assertNotIn(rejected, prompt)

    def test_incline_dumbbell_press_starts_over_chest_and_straight_arm_anatomy_is_valid(self):
        incline = json.loads(self.run_tool("guidance_prompt.mjs", "chest_incline_db_press", "female").stdout)["prompt"]
        self.assertIn("extend both arms with dumbbells directly above upper chest", incline)
        self.assertIn("upper arms are approximately parallel to the floor", incline)
        self.assertNotIn("哑铃位于上胸两侧", incline)
        straight_arm = json.loads(self.run_tool("guidance_prompt.mjs", "back_straight_arm_pulldown", "female").stdout)["prompt"]
        self.assertNotIn("胸大肌（长头）", straight_arm)
        self.assertIn("肱三头肌长头", straight_arm)


if __name__ == "__main__":
    unittest.main()
