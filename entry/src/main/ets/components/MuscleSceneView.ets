import {
  Camera,
  Geometry,
  Light,
  LightType,
  Material,
  MaterialType,
  MetallicRoughnessMaterial,
  Node,
  NodeType,
  RaycastParameters,
  RaycastResult,
  Scene,
  SceneNodeParameters,
  SceneResourceFactory,
  Vec2,
  Vec3,
  Vec4
} from '@kit.ArkGraphics3D';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  DRAG_THRESHOLD,
  HitNode,
  isDragGesture,
  muscleFromNodeName,
  pickVisibleMuscle
} from '../common/MuscleLogic';
import { MuscleKey } from '../model/muscleTypes';
import {
  applyOrbitToCamera,
  applyPan,
  applyRotate,
  applyZoom,
  backOrbit,
  frontOrbit,
  lookAt,
  OrbitState,
  resetOrbit
} from '../common/OrbitCamera';

@Component
export struct MuscleSceneView {
  @Prop @Watch('onSelectedKey') selectedKey: string = '';
  @Prop @Watch('onActionNonce') actionNonce: number = 0;
  @Prop actionName: string = '';
  @Prop isDark: boolean = false;
  onPicked: (key: string) => void = (_key: string) => {
  };
  onStatus: (ok: boolean) => void = (_ok: boolean) => {
  };
  @State ready: boolean = false;
  private alive: boolean = true;
  private failed: boolean = false;
  private scene: Scene | undefined = undefined;
  private camera: Camera | undefined = undefined;
  private muscleNodes: Node[] = [];
  private orbit: OrbitState = new OrbitState();
  private viewW: number = 1;
  private viewH: number = 1;
  private moved: boolean = false;
  private lastPanX: number = 0;
  private lastPanY: number = 0;
  private pinchStartDistance: number = 2.55;
  private twoFingerLastX: number = 0;
  private twoFingerLastY: number = 0;
  private loadToken: number = 0;
  private loadTimer: number = -1;

  aboutToAppear(): void {
    this.alive = true;
    this.loadScene();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.ready = false;
    this.clearLoadTimer();
    this.releaseScene();
  }

  onSelectedKey(): void {
    this.applyHighlight();
  }

  onActionNonce(): void {
    if (this.actionName === 'retry') {
      this.loadScene();
      return;
    }
    if (this.camera === undefined) {
      return;
    }
    if (this.actionName === 'front') {
      frontOrbit(this.orbit);
    } else if (this.actionName === 'back') {
      backOrbit(this.orbit);
    } else if (this.actionName === 'reset') {
      resetOrbit(this.orbit);
    }
    applyOrbitToCamera(this.camera, this.orbit);
  }

  private releaseScene(): void {
    this.muscleNodes = [];
    this.camera = undefined;
    if (this.scene !== undefined) {
      this.scene.destroy();
      this.scene = undefined;
    }
  }

  private clearLoadTimer(): void {
    if (this.loadTimer >= 0) {
      clearTimeout(this.loadTimer);
      this.loadTimer = -1;
    }
  }

  private onLoadTimeout(token: number): void {
    this.loadTimer = -1;
    if (!this.alive || token !== this.loadToken) {
      return;
    }
    this.loadToken++;
    this.failed = true;
    this.ready = false;
    this.onStatus(false);
    hilog.error(0xF170, 'MuscleSceneView', 'scene load timeout');
  }

  private async loadScene(): Promise<void> {
    this.loadToken++;
    const token: number = this.loadToken;
    this.ready = false;
    this.failed = false;
    this.clearLoadTimer();
    this.releaseScene();
    this.loadTimer = setTimeout(() => {
      this.onLoadTimeout(token);
    }, 10000);
    try {
      const loaded: Scene = await Scene.load($rawfile('models/body_muscles.glb'));
      if (!this.alive || token !== this.loadToken) {
        loaded.destroy();
        return;
      }
      this.scene = loaded;
      await this.setupScene(loaded);
      if (!this.alive || token !== this.loadToken) {
        this.releaseScene();
        return;
      }
      this.clearLoadTimer();
      this.ready = true;
      this.failed = false;
      this.onStatus(true);
    } catch (err) {
      hilog.error(0xF170, 'MuscleSceneView', 'scene load failed');
      this.clearLoadTimer();
      if (!this.alive || token !== this.loadToken) {
        return;
      }
      this.ready = false;
      this.failed = true;
      this.onStatus(false);
    }
  }

  private async setupScene(scene: Scene): Promise<void> {
    const root: Node | null = scene.root;
    if (root === null) {
      throw new Error('empty scene');
    }
    this.disableCameras(root);
    this.muscleNodes = [];
    this.collectMuscleNodes(root);
    const factory: SceneResourceFactory = scene.getResourceFactory();
    const camParams: SceneNodeParameters = { name: 'picker_camera' };
    const camera: Camera = await factory.createCamera(camParams);
    camera.enabled = true;
    camera.fov = 0.7;
    camera.nearPlane = 0.08;
    camera.farPlane = 20;
    if (this.isDark) {
      camera.clearColor = { r: 0.07, g: 0.07, b: 0.07, a: 1 };
    } else {
      camera.clearColor = { r: 0.957, g: 0.965, b: 0.973, a: 1 };
    }
    this.camera = camera;
    resetOrbit(this.orbit);
    applyOrbitToCamera(camera, this.orbit);
    await this.addLight(factory, 'key_light', { x: 1.8, y: 3.2, z: 2.2 }, 8);
    await this.addLight(factory, 'fill_light', { x: -2.0, y: 1.6, z: 1.4 }, 3);
    await this.addLight(factory, 'rim_light', { x: 0.2, y: 2.4, z: -2.0 }, 2);
    this.applyHighlight();
  }

  private async addLight(factory: SceneResourceFactory, name: string, eye: Vec3, intensity: number): Promise<void> {
    const params: SceneNodeParameters = { name: name };
    const light: Light = await factory.createLight(params, LightType.DIRECTIONAL);
    light.position = eye;
    light.color = { r: 1, g: 1, b: 1, a: 1 };
    light.intensity = intensity;
    light.enabled = true;
    light.shadowEnabled = false;
    lookAt(light, eye, { x: 0, y: 0.95, z: 0 }, { x: 0, y: 1, z: 0 });
  }

  private disableCameras(node: Node): void {
    if (node.nodeType === NodeType.CAMERA) {
      const existing: Camera = node as Camera;
      existing.enabled = false;
    }
    const count: number = node.children.count();
    for (let i = 0; i < count; i++) {
      const child: Node | null = node.children.get(i);
      if (child !== null) {
        this.disableCameras(child);
      }
    }
  }

  private collectMuscleNodes(node: Node): void {
    if (muscleFromNodeName(node.name) !== null) {
      this.muscleNodes.push(node);
    }
    const count: number = node.children.count();
    for (let i = 0; i < count; i++) {
      const child: Node | null = node.children.get(i);
      if (child !== null) {
        this.collectMuscleNodes(child);
      }
    }
  }

  private applyHighlight(): void {
    for (let i = 0; i < this.muscleNodes.length; i++) {
      const node: Node = this.muscleNodes[i];
      const key: MuscleKey | null = muscleFromNodeName(node.name);
      const selected: boolean = key !== null && key === this.selectedKey;
      tintGeometry(node, selected ? this.accentColor() : this.defaultColor());
    }
  }

  private defaultColor(): Vec4 {
    if (this.isDark) {
      return { x: 0.55, y: 0.57, z: 0.59, w: 1 };
    }
    return { x: 0.73, y: 0.75, z: 0.77, w: 1 };
  }

  private accentColor(): Vec4 {
    if (this.isDark) {
      return { x: 0.169, y: 0.639, z: 0.518, w: 1 };
    }
    return { x: 0.122, y: 0.541, z: 0.439, w: 1 };
  }

  private async handlePick(localX: number, localY: number): Promise<void> {
    if (this.moved || this.camera === undefined) {
      return;
    }
    const width: number = this.viewW <= 0 ? 1 : this.viewW;
    const height: number = this.viewH <= 0 ? 1 : this.viewH;
    let nx: number = localX / width;
    let ny: number = localY / height;
    if (nx < 0) {
      nx = 0;
    }
    if (nx > 1) {
      nx = 1;
    }
    if (ny < 0) {
      ny = 0;
    }
    if (ny > 1) {
      ny = 1;
    }
    const viewPos: Vec2 = { x: nx, y: ny };
    const params: RaycastParameters = {};
    try {
      const hits: RaycastResult[] = await this.camera.raycast(viewPos, params);
      if (!this.alive) {
        return;
      }
      const mapped: HitNode[] = [];
      for (let i = 0; i < hits.length; i++) {
        const item: HitNode = new HitNode();
        item.name = hits[i].node.name;
        item.distance = hits[i].centerDistance;
        item.parentNames = parentNames(hits[i].node);
        mapped.push(item);
      }
      const picked: MuscleKey | null = pickVisibleMuscle(mapped);
      if (picked !== null) {
        this.onPicked(picked);
      }
    } catch (err) {
      hilog.error(0xF170, 'MuscleSceneView', 'raycast failed');
    }
  }

  build() {
    Stack() {
      if (this.ready && this.scene !== undefined) {
        Component3D({ scene: this.scene })
          .width('100%')
          .height('100%')
          .hitTestBehavior(HitTestMode.Transparent)
      }
      if (!this.ready) {
        Text('正在加载人体模型…')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      Column()
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Default)
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            PanGesture({ fingers: 1, distance: 2 })
              .onActionStart(() => {
                this.moved = false;
                this.lastPanX = 0;
                this.lastPanY = 0;
              })
              .onActionUpdate((event: GestureEvent) => {
                const dx: number = event.offsetX - this.lastPanX;
                const dy: number = event.offsetY - this.lastPanY;
                this.lastPanX = event.offsetX;
                this.lastPanY = event.offsetY;
                if (isDragGesture(event.offsetX, event.offsetY, DRAG_THRESHOLD)) {
                  this.moved = true;
                }
                if (this.camera !== undefined) {
                  applyRotate(this.orbit, dx, dy);
                  applyOrbitToCamera(this.camera, this.orbit);
                }
              }),
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                this.moved = true;
                this.pinchStartDistance = this.orbit.distance;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (this.camera === undefined) {
                  return;
                }
                this.orbit.distance = this.pinchStartDistance;
                applyZoom(this.orbit, event.scale);
                applyOrbitToCamera(this.camera, this.orbit);
              }),
            PanGesture({ fingers: 2, distance: 2 })
              .onActionStart(() => {
                this.moved = true;
                this.twoFingerLastX = 0;
                this.twoFingerLastY = 0;
              })
              .onActionUpdate((event: GestureEvent) => {
                const dx: number = event.offsetX - this.twoFingerLastX;
                const dy: number = event.offsetY - this.twoFingerLastY;
                this.twoFingerLastX = event.offsetX;
                this.twoFingerLastY = event.offsetY;
                if (this.camera !== undefined) {
                  applyPan(this.orbit, dx, dy);
                  applyOrbitToCamera(this.camera, this.orbit);
                }
              })
          )
        )
        .onClick((event: ClickEvent) => {
          this.handlePick(event.x, event.y);
        })
        .onAreaChange((_oldArea: Area, newArea: Area) => {
          this.viewW = newArea.width as number;
          this.viewH = newArea.height as number;
        })
    }
    .width('100%')
    .height('100%')
  }
}

function parentNames(node: Node): string[] {
  const names: string[] = [];
  let current: Node | null = node.parent;
  while (current !== null) {
    names.push(current.name);
    current = current.parent;
  }
  return names;
}

function tintGeometry(node: Node, color: Vec4): void {
  if (node.nodeType !== NodeType.GEOMETRY) {
    return;
  }
  const geo: Geometry = node as Geometry;
  if (geo.mesh.materialOverride !== undefined && geo.mesh.materialOverride !== null) {
    tintMaterial(geo.mesh.materialOverride, color);
  }
  const subs = geo.mesh.subMeshes;
  for (let i = 0; i < subs.length; i++) {
    tintMaterial(subs[i].material, color);
  }
}

function tintMaterial(mat: Material, color: Vec4): void {
  if (mat.materialType === MaterialType.METALLIC_ROUGHNESS) {
    const mr: MetallicRoughnessMaterial = mat as MetallicRoughnessMaterial;
    mr.baseColor.factor = color;
  }
}

