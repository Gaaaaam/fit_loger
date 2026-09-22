"""Map anatomical structure names to training pick nodes or occluders."""

def region_for(name):
    if 'pectoralis major' in name:
        return 'chest'
    if 'deltoid' in name:
        return 'front_delt' if 'clavicular' in name else 'rear_delt' if 'spinal' in name else 'side_delt'
    if 'trapezius' in name:
        return 'traps' if 'descending' in name else 'upper_back'
    if any(s in name for s in ('infraspinatus', 'teres major', 'teres minor', 'rhomboid')):
        return 'upper_back'
    if 'latissimus dorsi' in name:
        return 'lats'
    if any(s in name for s in ('iliocostalis', 'longissimus thoracis', 'spinalis thoracis', 'thoracolumbar fascia')):
        return 'erector_spinae'
    if 'biceps brachii' in name or 'brachialis' in name:
        return 'biceps'
    if 'triceps brachii' in name or 'anconeus' in name:
        return 'triceps'
    if any(s in name for s in (
        'carpi', 'brachioradialis', 'pronator', 'supinator', 'palmaris longus',
        'flexor digitorum superficialis', 'flexor digitorum profundus', 'extensor digiti minimi',
        'extensor indicis', 'pollicis longus', 'extensor pollicis brevis'
    )):
        return 'forearm'
    if name.endswith('extensor digitorum'):
        return 'forearm'
    if 'rectus abdominis' in name:
        return 'rectus_abdominis'
    if 'external oblique' in name or 'serratus anterior' in name:
        return 'obliques'
    if 'gluteus maximus' in name:
        return 'glute_max'
    if 'gluteus medius' in name:
        return 'glute_med'
    if 'vastus' in name or 'rectus femoris' in name:
        return 'quads'
    if any(s in name for s in ('biceps femoris', 'semitendinosus', 'semimembranosus')):
        return 'hamstrings'
    if 'gastrocnemius' in name or 'soleus' in name:
        return 'calves'
    return None


def overlay_region(name):
    if 'hallucis' in name:
        return None
    if 'intercostal' in name:
        return 'chest'
    if any(s in name for s in ('sartorius', 'adductor longus', 'adductor magnus', 'gracilis', 'iliotibial')):
        return 'quads'
    if any(s in name for s in ('tibialis anterior', 'fibularis longus', 'fibularis brevis')):
        return 'calves'
    return None


def occluder_surface(name):
    return any(s in name for s in (
        'sternocleidomastoid', 'platysma', 'splenius capitis', 'sternohyoid',
        'hand', 'foot', 'hallucis', 'retinaculum'
    ))


def side_suffix(name):
    return '_L' if 'left' in name else '_R'


def assign_group(name):
    if occluder_surface(name):
        return 'base_connective'
    key = region_for(name)
    if key and 'tendon' not in name:
        return 'pick_' + key + side_suffix(name)
    overlay = overlay_region(name)
    if overlay:
        return 'pick_' + overlay + side_suffix(name)
    return None
