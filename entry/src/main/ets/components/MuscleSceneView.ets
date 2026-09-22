import { Camera, Environment, EnvironmentBackgroundType, Geometry, Light, LightType,
  Material, MaterialType, MetallicRoughnessMaterial, Node, NodeType, RaycastParameters,
  RaycastResult, Scene, SceneNodeParameters, SceneResourceFactory, SceneResourceParameters,
  Vec2, Vec3, Vec4 } from '@kit.ArkGraphics3D';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { muscleFromNodeChain } from '../common/MuscleLogic';
import { MuscleKey } from '../model/muscleTypes';
import { CAMERA_FOV, OrbitState, resetOrbit, resizeOrbit, frontOrbit, backOrbit,
  applyRotate, applyZoom, applyPan, applyOrbitToCamera, lookAt } from '../common/OrbitCamera';
import { SceneGesture, SceneGestureResult, ScenePointer, SceneHit, nearestSceneMuscle } from '../common/SceneInteraction';

interface SceneBundle {
  scene: Scene;
  camera: Camera;
  materials: Map<string, Material[]>;
}

@Component
export struct MuscleSceneView {
  @Prop @Watch('onSelectedKey') selectedKey: string = '';
  @Prop @Watch('onActionNonce') actionNonce: number = 0;
  @Prop actionName: string = '';
  @Prop @Watch('updateTheme') isDark: boolean = false;
  onPicked: (key: string) => void = (_key: string) => {};
  onMissed: () => void = () => {};
  onStatus: (ok: boolean) => void = (_ok: boolean) => {};
  @State ready: boolean = false;
  @State failed: boolean = false;
  private alive: boolean = true;
  private bundle: SceneBundle | undefined = undefined;
  private touchStream: SceneGesture = new SceneGesture();
  private orbit: OrbitState = new OrbitState();
  private viewW: number = 360;
  private viewH: number = 450;
  private loadToken: number = 0;
  private viewToken: number = 0;
  private loadTimer: number = -1;

  aboutToAppear(): void { this.alive = true; this.loadScene(); }
  aboutToDisappear(): void {
    this.alive = false;
    this.loadToken++;
    this.viewToken++;
    this.clearLoadTimer();
    this.touchStream.cancel();
    this.releaseScene();
  }
  onSelectedKey(): void { this.applyHighlight(); }
  onActionNonce(): void {
    if (this.actionName === 'retry') { this.loadScene(); return; }
    if (this.actionName === 'front') { frontOrbit(this.orbit); }
    else if (this.actionName === 'back') { backOrbit(this.orbit); }
    else if (this.actionName === 'reset') { resetOrbit(this.orbit, this.viewW, this.viewH); }
    this.moveCamera();
  }
  private moveCamera(): void {
    this.viewToken++;
    if (this.bundle !== undefined) { applyOrbitToCamera(this.bundle.camera, this.orbit); }
  }
  private releaseScene(): void {
    const old: SceneBundle | undefined = this.bundle;
    this.bundle = undefined;
    this.ready = false;
    if (old !== undefined) { old.scene.destroy(); }
  }
  private clearLoadTimer(): void {
    if (this.loadTimer >= 0) { clearTimeout(this.loadTimer); this.loadTimer = -1; }
  }
  private async loadScene(): Promise<void> {
    const token: number = ++this.loadToken;
    this.viewToken++;
    this.clearLoadTimer();
    this.releaseScene();
    this.failed = false;
    this.loadTimer = setTimeout(() => {
      if (this.alive && token === this.loadToken) {
        this.loadToken++;
        this.failed = true;
        this.onStatus(false);
      }
      this.loadTimer = -1;
    }, 10000);
    let loaded: Scene | undefined = undefined;
    try {
      loaded = await Scene.load($rawfile('models/body_muscles.glb'));
      if (!this.alive || token !== this.loadToken) { loaded.destroy(); return; }
      const built: SceneBundle = await this.setupScene(loaded);
      if (!this.alive || token !== this.loadToken) { loaded.destroy(); return; }
      // Publish only a complete current scene. Stale loads own only their locals.
      this.bundle = built;
      this.clearLoadTimer();
      resetOrbit(this.orbit, this.viewW, this.viewH);
      this.moveCamera();
      this.updateTheme();
      this.ready = true;
      this.onStatus(true);
    } catch (err) {
      if (loaded !== undefined && (this.bundle === undefined || this.bundle.scene !== loaded)) { loaded.destroy(); }
      if (!this.alive || token !== this.loadToken) { return; }
      this.clearLoadTimer();
      this.failed = true;
      this.ready = false;
      this.onStatus(false);
      hilog.error(0xF170, 'MuscleSceneView', 'scene initialization failed');
    }
  }
  private async setupScene(scene: Scene): Promise<SceneBundle> {
    if (scene.root === null) { throw new Error('missing model root'); }
    const materials: Map<string, Material[]> = new Map<string, Material[]>();
    this.collect(scene.root, materials);
    const factory: SceneResourceFactory = scene.getResourceFactory();
    const cameraParams: SceneNodeParameters = { name: 'picker_camera' };
    const camera: Camera = await factory.createCamera(cameraParams);
    camera.enabled = true;
    camera.fov = CAMERA_FOV;
    camera.nearPlane = 0.02;
    camera.farPlane = 30;
    camera.postProcess = null;
    const envParams: SceneResourceParameters = { name: 'picker_environment' };
    const environment: Environment = await factory.createEnvironment(envParams);
    environment.backgroundType = EnvironmentBackgroundType.BACKGROUND_NONE;
    environment.environmentImage = null;
    environment.radianceImage = null;
    environment.indirectDiffuseFactor = { x: 0.35, y: 0.35, z: 0.35, w: 1 };
    environment.indirectSpecularFactor = { x: 0, y: 0, z: 0, w: 0 };
    scene.environment = environment;
    await this.addLight(factory, 'key_light', { x: -2, y: 3, z: 3 }, 0.9);
    await this.addLight(factory, 'fill_light', { x: 2, y: 1.5, z: 1.5 }, 0.4);
    await this.addLight(factory, 'back_light', { x: 0, y: 2, z: -3 }, 0.75);
    return { scene: scene, camera: camera, materials: materials };
  }
  private collect(node: Node, materials: Map<string, Material[]>): void {
    if (node.nodeType === NodeType.CAMERA) { (node as Camera).enabled = false; }
    if (node.nodeType === NodeType.LIGHT) { (node as Light).enabled = false; }
    if (node.nodeType === NodeType.GEOMETRY) {
      const key: MuscleKey | null = muscleFromNodeChain(this.nodeNames(node));
      if (key !== null) {
        const mesh = (node as Geometry).mesh;
        const list: Material[] = materials.get(key) || [];
        if (mesh.materialOverride !== undefined && mesh.materialOverride !== null) { list.push(mesh.materialOverride); }
        for (let i = 0; i < mesh.subMeshes.length; i++) { list.push(mesh.subMeshes[i].material); }
        materials.set(key, list);
      }
    }
    for (let i = 0; i < node.children.count(); i++) {
      const child: Node | null = node.children.get(i);
      if (child !== null) { this.collect(child, materials); }
    }
  }
  private async addLight(factory: SceneResourceFactory, name: string, position: Vec3, intensity: number): Promise<void> {
    const params: SceneNodeParameters = { name: name };
    const light: Light = await factory.createLight(params, LightType.DIRECTIONAL);
    light.color = { r: 1, g: 1, b: 1, a: 1 };
    light.intensity = intensity;
    light.enabled = true;
    light.shadowEnabled = false;
    lookAt(light, position, { x: 0, y: 0.9, z: 0 }, { x: 0, y: 1, z: 0 });
  }
  private updateTheme(): void {
    if (this.bundle === undefined) { return; }
    // Native render targets encode linear RGB to sRGB; match app.color.scene_bg
    // (#EDF3F0 light / #172522 dark).
    this.bundle.camera.clearColor = this.isDark ? { r: 0.0086, g: 0.0185, b: 0.0160, a: 1 } :
      { r: 0.8469, g: 0.8963, b: 0.8714, a: 1 };
    this.applyHighlight();
  }
  private applyHighlight(): void {
    if (this.bundle === undefined) { return; }
    this.bundle.materials.forEach((materials: Material[], key: string) => {
      // Linear RGB for accent #1F8A70 (same sRGB→linear path as camera clearColor).
      const color: Vec4 = key === this.selectedKey ? { x: 0.0134, y: 0.2542, z: 0.1620, w: 1 } :
        { x: 0.52, y: 0.57, z: 0.55, w: 1 };
      for (const material of materials) {
        if (material.materialType === MaterialType.METALLIC_ROUGHNESS) {
          (material as MetallicRoughnessMaterial).baseColor.factor = color;
        }
      }
    });
  }
  private nodeNames(node: Node): string[] {
    const names: string[] = [];
    let current: Node | null = node;
    while (current !== null) { names.push(current.name); current = current.parent; }
    return names;
  }
  private nodeVisible(node: Node): boolean {
    let current: Node | null = node;
    while (current !== null) { if (!current.visible) { return false; } current = current.parent; }
    return true;
  }
  private async handlePick(x: number, y: number): Promise<void> {
    const bundle: SceneBundle | undefined = this.bundle;
    if (bundle === undefined || !this.ready) { return; }
    const load: number = this.loadToken;
    const view: number = ++this.viewToken;
    const position: Vec2 = { x: x / this.viewW, y: y / this.viewH };
    if (position.x < 0 || position.x > 1 || position.y < 0 || position.y > 1) { return; }
    const params: RaycastParameters = {};
    try {
      const hits: RaycastResult[] = await bundle.camera.raycast(position, params);
      if (!this.alive || load !== this.loadToken || view !== this.viewToken || bundle !== this.bundle) { return; }
      const mapped: SceneHit[] = [];
      for (const hit of hits) {
        const item: SceneHit = {
          names: this.nodeNames(hit.node),
          position: hit.hitPosition,
          visible: this.nodeVisible(hit.node),
          boxCenter: this.boxCenter(hit.node)
        };
        mapped.push(item);
      }
      const key: MuscleKey | null = nearestSceneMuscle(mapped, bundle.camera.position);
      if (key !== null) { this.onPicked(key); } else { this.onMissed(); }
    } catch (err) { hilog.error(0xF170, 'MuscleSceneView', 'raycast failed'); }
  }
  private boxCenter(node: Node): Vec3 | null {
    if (node.nodeType !== NodeType.GEOMETRY) { return null; }
    const bounds = (node as Geometry).mesh.aabb;
    const center: Vec3 = {
      x: (bounds.aabbMin.x + bounds.aabbMax.x) * 0.5,
      y: (bounds.aabbMin.y + bounds.aabbMax.y) * 0.5,
      z: (bounds.aabbMin.z + bounds.aabbMax.z) * 0.5
    };
    return center;
  }
  private pointers(touches: TouchObject[]): ScenePointer[] {
    const result: ScenePointer[] = [];
    for (const touch of touches) {
      const point: ScenePointer = { id: touch.id, x: touch.x, y: touch.y };
      result.push(point);
    }
    result.sort((a: ScenePointer, b: ScenePointer) => a.id - b.id);
    return result;
  }
  private handleSceneTouch(event: TouchEvent): void {
    if (!this.ready) { return; }
    const points: ScenePointer[] = this.pointers(event.touches);
    let result: SceneGestureResult = new SceneGestureResult();
    if (event.type === TouchType.Down) {
      this.viewToken++;
      this.touchStream.down(points);
    } else if (event.type === TouchType.Move) {
      result = this.touchStream.move(points);
    } else if (event.type === TouchType.Up && event.changedTouches.length > 0) {
      const lifted: ScenePointer = this.pointers(event.changedTouches)[0];
      const remaining: ScenePointer[] = points.filter((point: ScenePointer) => point.id !== lifted.id);
      result = this.touchStream.up(remaining, lifted);
    } else if (event.type === TouchType.Cancel) { this.touchStream.cancel(); }
    if (result.kind === 'rotate') { applyRotate(this.orbit, result.dx, result.dy); this.moveCamera(); }
    else if (result.kind === 'transform') {
      applyZoom(this.orbit, result.scale); applyPan(this.orbit, result.dx, result.dy); this.moveCamera();
    } else if (result.kind === 'pick') { this.handlePick(result.x, result.y); }
  }
  build() {
    Stack() {
      if (this.ready && this.bundle !== undefined) {
        Component3D({ scene: this.bundle.scene, modelType: ModelType.SURFACE }).width('100%').height('100%')
          .hitTestBehavior(HitTestMode.None)
      } else {
        Text(this.failed ? '暂时无法显示模型' : '正在加载人体模型…').fontSize($r('app.float.font_body'))
          .fontColor($r('app.color.scene_muted'))
      }
      Column().width('100%').height('100%').backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.Block)
        .onTouch((event: TouchEvent) => this.handleSceneTouch(event))
    }.width('100%').height('100%').backgroundColor($r('app.color.scene_bg'))
      .onAreaChange((_old: Area, area: Area) => {
        this.viewW = Math.max(1, Number(area.width));
        this.viewH = Math.max(1, Number(area.height));
        resizeOrbit(this.orbit, this.viewW, this.viewH);
        this.moveCamera();
      })
  }
}

