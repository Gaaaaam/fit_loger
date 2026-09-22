import { Vec3 } from '@kit.ArkGraphics3D';
import { muscleFromNodeChain } from './MuscleLogic';
import { MuscleKey } from '../model/muscleTypes';

export interface SceneHit {
  names: string[];
  position: Vec3;
  visible: boolean;
  boxCenter: Vec3 | null;
}

// Overlapping muscle boxes: a larger neighbour can stick a couple of centimetres
// past the shoulder, so the nearest box face is the arm or the chest. Keep hits
// this close to that face and choose the box whose centre the ray actually
// passes. 0.12 reaches the deltoid behind the chest box without reaching the
// back muscles behind the torso.
const ENTRY_BAND: number = 0.12;

export function nearestSceneMuscle(hits: SceneHit[], eye: Vec3): MuscleKey | null {
  let nearestEntry: number = Number.MAX_VALUE;
  let blockerDistance: number = Number.MAX_VALUE;
  for (const hit of hits) {
    if (!hit.visible) {
      continue;
    }
    const entry: number = entryDistance(hit.position, eye);
    const key: MuscleKey | null = muscleFromNodeChain(hit.names);
    if (key !== null) {
      if (entry < nearestEntry) {
        nearestEntry = entry;
      }
    } else if (isHeadShell(hit.names) && entry < blockerDistance) {
      blockerDistance = entry;
    }
  }
  let muscle: MuscleKey | null = null;
  let bestAim: number = Number.MAX_VALUE;
  let bestEntry: number = Number.MAX_VALUE;
  for (const hit of hits) {
    if (!hit.visible) {
      continue;
    }
    const key: MuscleKey | null = muscleFromNodeChain(hit.names);
    if (key === null) {
      continue;
    }
    const entry: number = entryDistance(hit.position, eye);
    if (entry > nearestEntry + ENTRY_BAND) {
      continue;
    }
    const aim: number = aimOffset(hit, eye);
    if (muscle === null || aim < bestAim || (aim === bestAim && entry < bestEntry)) {
      muscle = key;
      bestAim = aim;
      bestEntry = entry;
    }
  }
  // The head shell is a real outer surface. Skeleton and connective boxes are
  // not: their bounds wrap muscles that are already the visible surface.
  if (muscle === null || blockerDistance < bestEntry) {
    return null;
  }
  return muscle;
}

function entryDistance(point: Vec3, eye: Vec3): number {
  const dx: number = point.x - eye.x;
  const dy: number = point.y - eye.y;
  const dz: number = point.z - eye.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function aimOffset(hit: SceneHit, eye: Vec3): number {
  const center: Vec3 | null = hit.boxCenter;
  if (center === null || center === undefined) {
    return Number.MAX_VALUE;
  }
  const rx: number = hit.position.x - eye.x;
  const ry: number = hit.position.y - eye.y;
  const rz: number = hit.position.z - eye.z;
  const span: number = rx * rx + ry * ry + rz * rz;
  if (span < 0.000001) {
    return Number.MAX_VALUE;
  }
  const t: number = ((center.x - eye.x) * rx + (center.y - eye.y) * ry + (center.z - eye.z) * rz) / span;
  const px: number = eye.x + t * rx;
  const py: number = eye.y + t * ry;
  const pz: number = eye.z + t * rz;
  const dx: number = center.x - px;
  const dy: number = center.y - py;
  const dz: number = center.z - pz;
  return dx * dx + dy * dy + dz * dz;
}

function isHeadShell(names: string[]): boolean {
  return names.length > 0 && names[0] === 'base_head';
}

export interface ScenePointer {
  id: number;
  x: number;
  y: number;
}

export class SceneGestureResult {
  kind: string = 'none';
  dx: number = 0;
  dy: number = 0;
  scale: number = 1;
  x: number = 0;
  y: number = 0;
}

// One touch stream owns the interaction. Pinch and midpoint translation are
// calculated together, so two exclusive recognizers cannot steal each other.
export class SceneGesture {
  private active: boolean = false;
  private moved: boolean = false;
  private multi: boolean = false;
  private startX: number = 0;
  private startY: number = 0;
  private previous: ScenePointer[] = [];

  down(points: ScenePointer[]): void {
    if (!this.active && points.length > 0) {
      this.active = true;
      this.moved = false;
      this.multi = false;
      this.startX = points[0].x;
      this.startY = points[0].y;
    }
    if (points.length > 1) {
      this.multi = true;
    }
    this.previous = points;
  }

  move(points: ScenePointer[]): SceneGestureResult {
    const result: SceneGestureResult = new SceneGestureResult();
    if (!this.active) {
      return result;
    }
    if (points.length === 2 && this.previous.length === 2) {
      this.multi = true;
      result.kind = 'transform';
      result.dx = (points[0].x + points[1].x - this.previous[0].x - this.previous[1].x) / 2;
      result.dy = (points[0].y + points[1].y - this.previous[0].y - this.previous[1].y) / 2;
      const oldDistance: number = separation(this.previous);
      result.scale = oldDistance > 1 ? separation(points) / oldDistance : 1;
    } else if (points.length === 1 && this.previous.length === 1 && !this.multi) {
      const dx: number = points[0].x - this.startX;
      const dy: number = points[0].y - this.startY;
      if (this.moved || dx * dx + dy * dy > 64) {
        result.kind = 'rotate';
        result.dx = this.moved ? points[0].x - this.previous[0].x : dx;
        result.dy = this.moved ? points[0].y - this.previous[0].y : dy;
        this.moved = true;
      }
    }
    this.previous = points;
    return result;
  }

  up(remaining: ScenePointer[], lifted: ScenePointer): SceneGestureResult {
    const result: SceneGestureResult = new SceneGestureResult();
    const dx: number = lifted.x - this.startX;
    const dy: number = lifted.y - this.startY;
    if (remaining.length === 0) {
      if (this.active && !this.moved && !this.multi && dx * dx + dy * dy <= 64) {
        result.kind = 'pick';
        result.x = lifted.x;
        result.y = lifted.y;
      }
      this.cancel();
    } else {
      this.previous = remaining;
    }
    return result;
  }

  cancel(): void {
    this.active = false;
    this.moved = false;
    this.multi = false;
    this.previous = [];
  }
}

function separation(points: ScenePointer[]): number {
  const dx: number = points[1].x - points[0].x;
  const dy: number = points[1].y - points[0].y;
  return Math.sqrt(dx * dx + dy * dy);
}
