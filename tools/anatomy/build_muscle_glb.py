"""Build real anatomical training surfaces. See ATTRIBUTION.md for sources.
Requires numpy and scipy. Run python tools/anatomy/build_muscle_glb.py.
"""
import argparse, hashlib, json, struct
from collections import defaultdict
from pathlib import Path
import numpy as np
from scipy.spatial import ConvexHull
ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'entry/src/main/resources/rawfile/models/body_muscles.glb'
COPYRIGHT = 'BodyParts3D (c) The Database Center for Life Science, CC BY-SA 2.1 Japan; Z-Anatomy by Gauthier Kervyn, CC BY-SA 4.0. Mesh preparation: Johan Bellander / BodyExplorer. FitLoger adaptation: CC BY-SA 4.0.'

def load_glb(path):
    raw = path.read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20+size])
    binary = raw[28+size:]
    def accessor(index):
        a = doc['accessors'][index]; view = doc['bufferViews'][a['bufferView']]
        dtype = {5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]
        components = {'VEC3':3,'SCALAR':1}[a['type']]
        offset = view.get('byteOffset',0)+a.get('byteOffset',0)
        return np.frombuffer(binary,dtype=dtype,count=a['count']*components,offset=offset).reshape(-1,components).copy()
    meshes = []
    for node in doc['nodes']:
        if 'mesh' not in node: continue
        for p in doc['meshes'][node['mesh']]['primitives']:
            meshes.append((node['name'],accessor(p['attributes']['POSITION']),accessor(p['attributes']['NORMAL']),accessor(p['indices']).reshape(-1,3)))
    return meshes, hashlib.sha256(raw).hexdigest()

def region_for(name):
    if 'pectoralis major' in name: return 'chest'
    if 'deltoid' in name: return 'front_delt' if 'clavicular' in name else 'rear_delt' if 'spinal' in name else 'side_delt'
    if 'trapezius' in name: return 'traps' if 'descending' in name else 'upper_back'
    if any(s in name for s in ('infraspinatus','teres major','teres minor','rhomboid')): return 'upper_back'
    if 'latissimus dorsi' in name: return 'lats'
    if any(s in name for s in ('iliocostalis','longissimus thoracis','spinalis thoracis','thoracolumbar fascia')): return 'erector_spinae'
    if 'biceps brachii' in name or 'brachialis' in name: return 'biceps'
    if 'triceps brachii' in name or 'anconeus' in name: return 'triceps'
    if any(s in name for s in ('carpi','brachioradialis','pronator','supinator','palmaris longus','flexor digitorum superficialis','flexor digitorum profundus','extensor digiti minimi','extensor indicis','pollicis longus','extensor pollicis brevis')): return 'forearm'
    if name.endswith('extensor digitorum'): return 'forearm'
    if 'rectus abdominis' in name: return 'rectus_abdominis'
    if 'external oblique' in name or 'serratus anterior' in name: return 'obliques'
    if 'gluteus maximus' in name: return 'glute_max'
    if 'gluteus medius' in name: return 'glute_med'
    if 'vastus' in name or 'rectus femoris' in name: return 'quads'
    if any(s in name for s in ('biceps femoris','semitendinosus','semimembranosus')): return 'hamstrings'
    if 'gastrocnemius' in name or 'soleus' in name: return 'calves'
    return None

def context_surface(name):
    return any(s in name for s in ('sternocleidomastoid','platysma','splenius capitis','sternohyoid','sartorius','adductor longus','adductor magnus','gracilis','tibialis anterior','fibularis longus','fibularis brevis','iliotibial','tendon','retinaculum','hand','foot','hallucis','intercostal'))

def normals_for(v,f):
    tri = v[f]; fn = np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]); normal = np.zeros_like(v)
    for i in range(3): np.add.at(normal,f[:,i],fn)
    return normal/np.maximum(np.linalg.norm(normal,axis=1)[:,None],1e-12)

def head_shell(points):
    # Source-derived cranium silhouette: quiet featureless head, no exposed skull.
    hull = ConvexHull(points); f = hull.simplices.copy(); tri = points[f]
    normals = np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])
    wrong = np.einsum('ij,ij->i',normals,hull.equations[:,:3]) < 0
    f[wrong] = f[wrong][:,[0,2,1]]
    used,inverse = np.unique(f,return_inverse=True); v = points[used]; f = inverse.reshape(-1,3)
    return v,normals_for(v,f),f

def build(source_dir,output):
    muscles,muscle_hash = load_glb(source_dir/'anatomy.glb'); bones,bone_hash = load_glb(source_dir/'skeleton.glb')
    positions = np.concatenate([m[1] for m in muscles+bones]); lo,hi = positions.min(axis=0),positions.max(axis=0)
    scale = 1.8/(hi[2]-lo[2]); center_x,center_y = (hi[:2]+lo[:2])/2
    def transform(v,n):
        return np.column_stack(((v[:,0]-center_x)*scale,(v[:,2]-lo[2])*scale,-(v[:,1]-center_y)*scale)).astype('<f4'),np.column_stack((n[:,0],n[:,2],-n[:,1])).astype('<f4')
    groups = defaultdict(list); manifest = []
    for name,v,n,f in muscles:
        key = region_for(name)
        if key and 'tendon' not in name: group = 'pick_'+key+('_L' if 'left' in name else '_R')
        elif context_surface(name): group = 'base_connective'
        else: continue
        v,n = transform(v,n); groups[group].append((name,v,n,f)); manifest.append({'structure':name,'node':group})
    head=[]
    for name,v,n,f in bones:
        v,n = transform(v,n)
        if v[:,1].max()>1.58: head.append(v)
        else: groups['base_skeleton'].append((name,v,n,f))
    v,n,f = head_shell(np.concatenate(head)); groups['base_head'].append(('Source cranium silhouette (convex shell)',v,n,f))
    doc={'asset':{'version':'2.0','generator':'FitLoger anatomical atlas builder','copyright':COPYRIGHT,'extras':{'sourceSha256':{'anatomy.glb':muscle_hash,'skeleton.glb':bone_hash}}},'scene':0,'scenes':[{'name':'FitLoger muscle map','nodes':[0]}],'nodes':[{'name':'BodyRoot','children':[]}],'meshes':[],'materials':[],'accessors':[],'bufferViews':[],'buffers':[]}
    binary=bytearray()
    def add_accessor(array,kind,target):
        while len(binary)%4: binary.append(0)
        offset=len(binary); binary.extend(array.tobytes()); doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(binary)-offset,'target':target})
        a={'bufferView':len(doc['bufferViews'])-1,'componentType':5126 if kind=='VEC3' else 5125,'count':len(array) if kind=='VEC3' else array.size,'type':kind}
        if kind=='VEC3': a.update(min=array.min(axis=0).tolist(),max=array.max(axis=0).tolist())
        doc['accessors'].append(a); return len(doc['accessors'])-1
    for group,chunks in sorted(groups.items()):
        vertices=[]; normals=[]; indices=[]; names=[]; offset=0
        for name,v,n,f in chunks:
            vertices.append(v); normals.append(n); indices.append(f+offset); names.append(name); offset+=len(v)
        v=np.concatenate(vertices).astype('<f4'); n=np.concatenate(normals).astype('<f4'); f=np.concatenate(indices).astype('<u4')
        shade=[.52,.57,.55,1] if group.startswith('pick_') else [.46,.50,.49,1]
        if group=='base_head': shade=[.58,.62,.60,1]
        doc['materials'].append({'name':group,'doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':shade,'metallicFactor':0,'roughnessFactor':.82}})
        primitive={'attributes':{'POSITION':add_accessor(v,'VEC3',34962),'NORMAL':add_accessor(n,'VEC3',34962)},'indices':add_accessor(f,'SCALAR',34963),'material':len(doc['materials'])-1}
        doc['meshes'].append({'name':group,'primitives':[primitive]}); doc['nodes'][0]['children'].append(len(doc['nodes']))
        doc['nodes'].append({'name':group,'mesh':len(doc['meshes'])-1,'extras':{'anatomicalStructures':names}})
    doc['buffers']=[{'byteLength':len(binary)}]; j=json.dumps(doc,separators=(',',':')).encode(); j+=b' '*(-len(j)%4); binary.extend(b'\0'*(-len(binary)%4))
    output.parent.mkdir(parents=True,exist_ok=True); output.write_bytes(struct.pack('<III',0x46546C67,2,28+len(j)+len(binary))+struct.pack('<II',len(j),0x4E4F534A)+j+struct.pack('<II',len(binary),0x004E4942)+binary)
    output.with_name('muscle_manifest.json').write_text(json.dumps({'source':'JohanBellander/BodyExplorer (BodyParts3D and Z-Anatomy)','sourceSha256':doc['asset']['extras']['sourceSha256'],'structures':manifest},ensure_ascii=False,indent=2),encoding='utf-8')
    bounds=np.concatenate([np.concatenate([c[1] for c in chunks]) for chunks in groups.values()])
    print(f'{len(groups)} draw groups, {sum(len(c[3]) for cs in groups.values() for c in cs):,} triangles, {output.stat().st_size/1024/1024:.1f} MiB'); print('Bounds:',bounds.min(axis=0),bounds.max(axis=0))

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--source-dir',type=Path,default=ROOT/'.work/anatomy'); parser.add_argument('--output',type=Path,default=OUTPUT); args=parser.parse_args(); build(args.source_dir,args.output)
