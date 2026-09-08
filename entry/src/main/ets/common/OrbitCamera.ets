import { Node, Quaternion, Vec3 } from '@kit.ArkGraphics3D';
import { clampPitch, wrapYaw } from './MuscleLogic';

export const CAMERA_FOV: number = 0.65;

export class OrbitState {
  yaw: number = 0;
  pitch: number = 0;
  distance: number = 3.2;
  fitDistance: number = 3.2;
  viewportHeight: number = 450;
  targetX: number = 0;
  targetY: number = 0.9;
  targetZ: number = 0;
  panRight: number = 0;
  panUp: number = 0;
}

export function resetOrbit(state: OrbitState, width: number = 360, height: number = 450): void {
  state.yaw = 0;
  state.pitch = 0;
  state.viewportHeight = Math.max(height, 1);
  state.fitDistance = fitDistance(width, height);
  state.distance = state.fitDistance;
  state.targetX = 0;
  state.targetY = 0.9;
  state.targetZ = 0;
  state.panRight = 0;
  state.panUp = 0;
}

export function frontOrbit(state: OrbitState): void {
  state.yaw = 0;
  state.pitch = 0;
  state.panRight = 0;
  state.panUp = 0;
}

export function backOrbit(state: OrbitState): void {
  state.yaw = Math.PI;
  state.pitch = 0;
  state.panRight = 0;
  state.panUp = 0;
}

export function applyRotate(state: OrbitState, dx: number, dy: number): void {
  state.yaw = wrapYaw(state.yaw - dx * 0.01);
  state.pitch = clampPitch(state.pitch + dy * 0.008);
}

export function applyZoom(state: OrbitState, scale: number): void {
  const next: number = state.distance / Math.max(scale, 0.05);
  state.distance = Math.max(0.65, Math.min(state.fitDistance, next));
  if (state.distance >= state.fitDistance - 0.04) {
    state.panRight = 0;
    state.panUp = 0;
  }
}

export function applyPan(state: OrbitState, dx: number, dy: number): void {
  if (state.distance >= state.fitDistance - 0.04) {
    return;
  }
  const factor: number = 2 * state.distance * Math.tan(CAMERA_FOV / 2) / state.viewportHeight;
  state.panRight = Math.max(-0.55, Math.min(0.55, state.panRight - dx * factor));
  state.panUp = Math.max(-0.8, Math.min(0.8, state.panUp + dy * factor));
}

// Body asset is centred at x/z 0, y 0..1.8. Include depth and breathing room.
function fitDistance(width: number, height: number): number {
  const aspect: number = Math.max(0.2, width / Math.max(height, 1));
  const tangent: number = Math.tan(CAMERA_FOV / 2);
  return Math.max(0.96 / tangent, 0.53 / (tangent * aspect)) + 0.24;
}

export function resizeOrbit(state: OrbitState, width: number, height: number): void {
  const zoomRatio: number = state.distance / state.fitDistance;
  state.fitDistance = fitDistance(width, height);
  state.distance = Math.max(0.65, state.fitDistance * zoomRatio);
  state.viewportHeight = Math.max(height, 1);
}

export function lookAt(node: Node, eye: Vec3, center: Vec3, up: Vec3): void {
  const f: Vec3 = normalize(sub(center, eye));
  const m0: Vec3 = normalize(cross(f, up));
  const m1: Vec3 = cross(m0, f);
  const m2: Vec3 = { x: -f.x, y: -f.y, z: -f.z };
  let t: number = 0;
  let q: Quaternion = { x: 0, y: 0, z: 0, w: 1 };
  if (m2.z < 0) {
    if (m0.x > m1.y) {
      t = 1.0 + m0.x - m1.y - m2.z;
      q = { x: t, y: m0.y + m1.x, z: m2.x + m0.z, w: m1.z - m2.y };
    } else {
      t = 1.0 - m0.x + m1.y - m2.z;
      q = { x: m0.y + m1.x, y: t, z: m1.z + m2.y, w: m2.x - m0.z };
    }
  } else {
    if (m0.x < -m1.y) {
      t = 1.0 - m0.x - m1.y + m2.z;
      q = { x: m2.x + m0.z, y: m1.z + m2.y, z: t, w: m0.y - m1.x };
    } else {
      t = 1.0 + m0.x + m1.y + m2.z;
      q = { x: m1.z - m2.y, y: m2.x - m0.z, z: m0.y - m1.x, w: t };
    }
  }
  const scale: number = 0.5 / Math.sqrt(t);
  node.position = eye;
  node.rotation = { x: q.x * scale, y: q.y * scale, z: q.z * scale, w: q.w * scale };
}

export function applyOrbitToCamera(camera: Node, state: OrbitState): void {
  const cosPitch: number = Math.cos(state.pitch);
  const forward: Vec3 = {
    x: Math.sin(state.yaw) * cosPitch,
    y: Math.sin(state.pitch),
    z: Math.cos(state.yaw) * cosPitch
  };
  const worldUp: Vec3 = { x: 0, y: 1, z: 0 };
  const right: Vec3 = normalize(cross(worldUp, forward));
  const up: Vec3 = normalize(cross(forward, right));
  const target: Vec3 = {
    x: state.targetX + right.x * state.panRight + up.x * state.panUp,
    y: state.targetY + right.y * state.panRight + up.y * state.panUp,
    z: state.targetZ + right.z * state.panRight + up.z * state.panUp
  };
  const eye: Vec3 = {
    x: target.x + forward.x * state.distance,
    y: target.y + forward.y * state.distance,
    z: target.z + forward.z * state.distance
  };
  lookAt(camera, eye, target, worldUp);
}

function sub(l: Vec3, r: Vec3): Vec3 {
  return { x: l.x - r.x, y: l.y - r.y, z: l.z - r.z };
}

function dot(l: Vec3, r: Vec3): number {
  return l.x * r.x + l.y * r.y + l.z * r.z;
}

function normalize(v: Vec3): Vec3 {
  const d: number = Math.sqrt(dot(v, v));
  if (d < 0.000001) {
    return { x: 0, y: 1, z: 0 };
  }
  return { x: v.x / d, y: v.y / d, z: v.z / d };
}

function cross(l: Vec3, r: Vec3): Vec3 {
  return {
    x: l.y * r.z - l.z * r.y,
    y: l.z * r.x - l.x * r.z,
    z: l.x * r.y - l.y * r.x
  };
}
