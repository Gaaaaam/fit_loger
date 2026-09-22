"""Assignment of anatomical names to pick / occluder / omitted layers."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools' / 'anatomy'))
from surface_map import assign_group

assert assign_group('abdominal part of left pectoralis major') == 'pick_chest_L'
assert assign_group('external intercostal muscle') == 'pick_chest_R'
assert assign_group('left intercostal muscle') == 'pick_chest_L'
assert assign_group('left sartorius') == 'pick_quads_L'
assert assign_group('right adductor longus') == 'pick_quads_R'
assert assign_group('left adductor magnus') == 'pick_quads_L'
assert assign_group('right gracilis') == 'pick_quads_R'
assert assign_group('left tibialis anterior') == 'pick_calves_L'
assert assign_group('right fibularis longus') == 'pick_calves_R'
assert assign_group('left fibularis brevis') == 'pick_calves_L'
assert assign_group('left iliotibial tract') == 'pick_quads_L'
assert assign_group('oblique head of left adductor hallucis') == 'base_connective'
assert assign_group('abductor digiti minimi of left hand') == 'base_connective'
assert assign_group('abductor digiti minimi of right foot') == 'base_connective'
assert assign_group('left sternocleidomastoid') == 'base_connective'
assert assign_group('pectoralis major tendon') is None
print('Anatomy surface assignment mapping passed')
