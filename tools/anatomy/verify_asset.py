"""Validate the shipped model rather than a procedural placeholder."""
import json
import struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
path = ROOT / 'entry/src/main/resources/rawfile/models/body_muscles.glb'
assert path.exists(), 'The real anatomical model must ship with the application'
raw = path.read_bytes()
assert raw[:4] == b'glTF'
size = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20+size])
assert 'BodyParts3D' in doc['asset'].get('copyright', ''), 'Anatomical source provenance missing'
assert doc['asset'].get('extras', {}).get('sourceSha256'), 'Exact source checksums missing'
regions = {n['name'][5:-2] for n in doc['nodes'] if n.get('name', '').startswith('pick_')}
assert len(regions) == 18, regions
triangles = 0
for node in doc['nodes']:
    if 'mesh' not in node: continue
    assert node.get('extras', {}).get('anatomicalStructures'), node['name']
    for prim in doc['meshes'][node['mesh']]['primitives']:
        p = doc['accessors'][prim['attributes']['POSITION']]
        assert all(-1 < v < 2 for v in p['min'] + p['max']), 'Expected metre-scale normalized coordinates'
        triangles += doc['accessors'][prim['indices']]['count'] // 3
assert triangles < 350000, f'Mobile geometry budget exceeded: {triangles}'
assert len(raw) < 12 * 1024 * 1024, 'Mobile asset size budget exceeded'
print(f'Anatomical provenance, 18 regions, bounds, {triangles:,} triangles, {len(raw)/1024/1024:.1f} MiB passed')
