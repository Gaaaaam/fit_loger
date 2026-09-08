export interface Point3 { x: number; y: number; z: number; }
export interface Rotation4 { x: number; y: number; z: number; w: number; }
export interface CameraPose { position: Point3; target: Point3; rotation: Rotation4; }
export class MuscleHit {
  name: string;
  hitPosition: Point3;

  constructor(name: string, hitPosition: Point3) {
    this.name = name;
    this.hitPosition = hitPosition;
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function orbitRotation(yaw: number, pitch: number): Rotation4 {
  // The native camera looks along local -Z. Compose yaw with negative pitch.
  return { x: -Math.sin(pitch / 2) * Math.cos(yaw / 2),
    y: Math.cos(pitch / 2) * Math.sin(yaw / 2),
    z: Math.sin(pitch / 2) * Math.sin(yaw / 2),
    w: Math.cos(pitch / 2) * Math.cos(yaw / 2) };
}

export class OrbitCamera {
  yaw: number = 0;
  pitch: number = 0;
  zoom: number = 1;
  panX: number = 0;
  panY: number = 0;
  width: number = 360;
  height: number = 520;
  readonly fov: number = Math.PI / 5;

  resize(width: number, height: number): void {
    this.width = Math.max(1, width);
    this.height = Math.max(1, height);
  }

  reset(back: boolean = false): void {
    this.yaw = back ? Math.PI : 0;
    this.pitch = 0;
    this.zoom = 1;
    this.panX = 0;
    this.panY = 0;
  }

  orbit(dx: number, dy: number): void {
    this.yaw = ((this.yaw - dx * 0.009) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
    this.pitch = clamp(this.pitch + dy * 0.007, -0.65, 0.65);
  }

  setZoom(zoom: number): void {
    this.zoom = clamp(zoom, 1, 3);
    this.limitPan();
  }

  pan(dx: number, dy: number): void {
    const scale = 2 * this.fitDistance() / this.zoom * Math.tan(this.fov / 2) / this.height;
    this.panX -= dx * scale;
    this.panY += dy * scale;
    this.limitPan();
  }

  private limitPan(): void {
    const freedom = (this.zoom - 1) / 2;
    if (freedom === 0) {
      this.panX = 0;
      this.panY = 0;
      return;
    }
    this.panX = clamp(this.panX, -0.45 * freedom, 0.45 * freedom);
    this.panY = clamp(this.panY, -0.7 * freedom, 0.7 * freedom);
  }

  fitDistance(): number {
    const horizontal = Math.tan(this.fov / 2) * this.width / this.height;
    const vertical = Math.tan(this.fov / 2);
    let distance = 0;
    // Fit all eight corners in camera space, including depth, at any orbit angle.
    for (let ix = -1; ix <= 1; ix += 2) {
      for (let iy = -1; iy <= 1; iy += 2) {
        for (let iz = -1; iz <= 1; iz += 2) {
          const x = ix * 0.35;
          const y = iy * 0.9;
          const z = iz * 0.14;
          const side = x * Math.cos(this.yaw) - z * Math.sin(this.yaw);
          const up = -x * Math.sin(this.yaw) * Math.sin(this.pitch) + y * Math.cos(this.pitch) -
            z * Math.cos(this.yaw) * Math.sin(this.pitch);
          const depth = x * Math.sin(this.yaw) * Math.cos(this.pitch) + y * Math.sin(this.pitch) +
            z * Math.cos(this.yaw) * Math.cos(this.pitch);
          distance = Math.max(distance, Math.abs(side) / horizontal + depth, Math.abs(up) / vertical + depth);
        }
      }
    }
    return distance * 1.12;
  }

  pose(): CameraPose {
    const sy = Math.sin(this.yaw);
    const cy = Math.cos(this.yaw);
    const sp = Math.sin(this.pitch);
    const cp = Math.cos(this.pitch);
    const target: Point3 = { x: cy * this.panX - sy * sp * this.panY,
      y: 0.9 + cp * this.panY, z: -sy * this.panX - cy * sp * this.panY };
    const distance = this.fitDistance() / this.zoom;
    return { position: { x: target.x + sy * cp * distance, y: target.y + sp * distance,
      z: target.z + cy * cp * distance }, target: target, rotation: orbitRotation(this.yaw, this.pitch) };
  }
}

export class TapTracker {
  private x: number = 0;
  private y: number = 0;
  private started: number = 0;
  private eligible: boolean = false;

  begin(x: number, y: number, time: number): void {
    this.x = x;
    this.y = y;
    this.started = time;
    this.eligible = true;
  }
  move(x: number, y: number): void {
    if (Math.hypot(x - this.x, y - this.y) > 8) this.eligible = false;
  }
  multitouch(): void { this.eligible = false; }
  end(x: number, y: number, time: number): boolean {
    this.move(x, y);
    const picked = this.eligible && time - this.started < 450;
    this.eligible = false;
    return picked;
  }
}

export function muscleNodeKey(name: string): string {
  const match = /^pick_(chest|front_delt|side_delt|rear_delt|traps|upper_back|lats|erector_spinae|biceps|triceps|forearm|rectus_abdominis|obliques|glute_max|glute_med|quads|hamstrings|calves)_[LR]$/.exec(name);
  return match ? match[1] : '';
}

export function nearestMuscle(hits: MuscleHit[], camera: Point3): string {
  let nearest = Number.POSITIVE_INFINITY;
  let key = '';
  for (let i = 0; i < hits.length; i++) {
    const p = hits[i].hitPosition;
    const distance = (p.x - camera.x) ** 2 + (p.y - camera.y) ** 2 + (p.z - camera.z) ** 2;
    if (Number.isFinite(distance) && distance < nearest) {
      nearest = distance;
      // Neutral geometry must occlude selectable geometry behind it.
      key = muscleNodeKey(hits[i].name);
    }
  }
  return key;
}

export class SceneEpoch {
  private generation: number = 0;
  private active: boolean = false;
  view: number = 0;
  begin(): number { this.active = true; this.invalidateView(); return ++this.generation; }
  current(token: number): boolean { return this.active && token === this.generation; }
  invalidateView(): void { this.view++; }
  stop(): void { this.active = false; this.generation++; this.invalidateView(); }
}
