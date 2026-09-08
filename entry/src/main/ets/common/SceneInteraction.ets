import { Vec3 } from '@kit.ArkGraphics3D';
import { muscleFromNodeChain } from './MuscleLogic';
import { MuscleKey } from '../model/muscleTypes';

export interface SceneHit {
  names: string[];
  position: Vec3;
  visible: boolean;
}

export function nearestSceneMuscle(hits: SceneHit[], eye: Vec3): MuscleKey | null {
  let nearest: SceneHit | undefined = undefined;
  let best: number = Number.MAX_VALUE;
  for (const hit of hits) {
    if (!hit.visible) {
      continue;
    }
    const dx: number = hit.position.x - eye.x;
    const dy: number = hit.position.y - eye.y;
    const dz: number = hit.position.z - eye.z;
    const distance: number = dx * dx + dy * dy + dz * dz;
    if (distance < best) {
      best = distance;
      nearest = hit;
    }
  }
  // An unselectable foreground surface blocks muscles behind it.
  return nearest === undefined ? null : muscleFromNodeChain(nearest.names);
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
