"""Check the distributable anatomy asset, including real source provenance."""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
raw = (ROOT / 'entry/src/main/resources/rawfile/models/body_muscles.glb').read_bytes()
assert raw[:4] == b'glTF'
length = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20 + length])
assert 'BodyParts3D' in doc['asset'].get('copyright', ''), 'Use actual anatomical source meshes, not a placeholder figure'
assert doc['asset'].get('extras', {}).get('sourceSha256'), 'Record exact source checksums'
regions = {n['name'][5:-2] for n in doc['nodes'] if n.get('name', '').startswith('pick_')}
assert len(regions) == 18, f'Expected 18 selectable muscle regions; got {regions}'
for node in doc['nodes']:
    if 'mesh' not in node:
        continue
    assert node.get('extras', {}).get('anatomicalStructures'), f'Missing source structure names: {node["name"]}'
    for prim in doc['meshes'][node['mesh']]['primitives']:
        pos = doc['accessors'][prim['attributes']['POSITION']]
        assert all(-1 < v < 2 for v in pos['min'] + pos['max']), 'Model must be normalized to metres'
        assert pos['count'] > 0
assert len(raw) < 24 * 1024 * 1024, 'Mobile model should stay below 24 MiB'
print(f'Anatomy provenance, 18 regions, normalized bounds and asset size passed ({len(raw)/1024/1024:.1f} MiB)')
