import {
  Scene, Camera, Node, NodeType, Geometry, Light, LightType, MaterialType,
  MetallicRoughnessMaterial, EnvironmentBackgroundType, RaycastResult
} from '@kit.ArkGraphics3D';
import {
  OrbitCamera, TapTracker, SceneEpoch, MuscleHit, Point3, muscleNodeKey, nearestMuscle, orbitRotation
} from '../common/OrbitCamera';

interface RegionMaterial {
  key: string;
  material: MetallicRoughnessMaterial;
}

@Component
export struct MuscleSceneView {
  @Prop @Watch('selectionChanged') selectedKey: string = '';
  @Prop actionName: string = '';
  @Prop @Watch('actionChanged') actionNonce: number = 0;
  @Prop @Watch('themeChanged') isDark: boolean = false;
  onPicked: (key: string) => void = () => {};
  onStatus: (ok: boolean) => void = () => {};

  @State private scene: Scene | undefined = undefined;
  @State private loading: boolean = true;
  @State private failed: boolean = false;
  private camera: Camera | undefined = undefined;
  private materials: RegionMaterial[] = [];
  private orbit: OrbitCamera = new OrbitCamera();
  private taps: TapTracker = new TapTracker();
  private epoch: SceneEpoch = new SceneEpoch();
  private loadToken: number = 0;
  private pickNonce: number = 0;
  private fingers: number = 0;
  private lastX: number = 0;
  private lastY: number = 0;
  private lastSpan: number = 0;

  aboutToAppear(): void {
    this.loadScene();
  }

  aboutToDisappear(): void {
    this.epoch.stop();
    this.pickNonce++;
    this.fingers = 0;
    this.taps.multitouch();
    this.releaseReadyScene();
  }

  private releaseReadyScene(): void {
    const oldScene = this.scene;
    this.scene = undefined;
    this.camera = undefined;
    this.materials = [];
    if (oldScene) oldScene.destroy();
  }

  private async loadScene(): Promise<void> {
    const token = this.epoch.begin();
    this.loadToken = token;
    this.pickNonce++;
    this.releaseReadyScene();
    this.loading = true;
    this.failed = false;
    let loaded: Scene | undefined = undefined;
    try {
      loaded = await Scene.load($rawfile('models/body_muscles.glb'));
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      const factory = loaded.getResourceFactory();
      const camera = await factory.createCamera({ name: 'muscle_camera' });
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      camera.fov = this.orbit.fov;
      camera.nearPlane = 0.02;
      camera.farPlane = 30;
      camera.postProcess = null;
      camera.enabled = true;

      const environment = await factory.createEnvironment({ name: 'muscle_stage_environment' });
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      environment.backgroundType = EnvironmentBackgroundType.BACKGROUND_NONE;
      environment.environmentImage = null;
      environment.radianceImage = null;
      environment.indirectDiffuseFactor = { x: 0.6, y: 0.6, z: 0.6, w: 1 };
      environment.indirectSpecularFactor = { x: 0, y: 0, z: 0, w: 0 };
      environment.irradianceCoefficients = [
        { x: 0.45, y: 0.45, z: 0.45 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }
      ];
      loaded.environment = environment;
      const key = await factory.createLight({ name: 'muscle_key' }, LightType.DIRECTIONAL);
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      this.configureLight(key, -0.6, 0.45, 1.15);
      const fill = await factory.createLight({ name: 'muscle_fill' }, LightType.DIRECTIONAL);
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      this.configureLight(fill, 1.7, 0.25, 0.7);
      const back = await factory.createLight({ name: 'muscle_back' }, LightType.DIRECTIONAL);
      if (!this.epoch.current(token)) { loaded.destroy(); return; }
      this.configureLight(back, Math.PI + 0.4, 0.35, 1.05);

      const collected: RegionMaterial[] = [];
      if (!loaded.root) throw new Error('Model contains no root');
      this.collectMaterials(loaded.root, '', collected);
      if (collected.length === 0) throw new Error('Model contains no muscle materials');
      this.camera = camera;
      this.materials = collected;
      this.scene = loaded;
      this.themeChanged();
      this.selectionChanged();
      this.updateCamera();
      this.loading = false;
      this.onStatus(true);
    } catch (_) {
      // Only dispose this attempt's captured scene. A newer load owns different resources.
      if (loaded) loaded.destroy();
      if (!this.epoch.current(token)) return;
      this.scene = undefined;
      this.camera = undefined;
      this.materials = [];
      this.loading = false;
      this.failed = true;
      this.onStatus(false);
    }
  }

  private configureLight(light: Light, yaw: number, pitch: number, intensity: number): void {
    light.rotation = orbitRotation(yaw, pitch);
    light.color = { r: 1, g: 1, b: 1, a: 1 };
    light.intensity = intensity;
    light.shadowEnabled = false;
    light.enabled = true;
  }

  private collectMaterials(node: Node, parentKey: string, output: RegionMaterial[]): void {
    const ownKey = muscleNodeKey(node.name);
    const key = node.name.startsWith('base_') ? '' : (ownKey || parentKey);
    if (node.nodeType === NodeType.GEOMETRY) {
      const geometry = node as Geometry;
      for (let i = 0; i < geometry.mesh.subMeshes.length; i++) {
        const material = geometry.mesh.subMeshes[i].material;
        if (material.materialType === MaterialType.METALLIC_ROUGHNESS) {
          const pbr = material as MetallicRoughnessMaterial;
          pbr.blend = { enabled: false };
          pbr.material.factor = { x: 1, y: 0.88, z: 0, w: 0.12 };
          pbr.emissive.factor = { x: 0, y: 0, z: 0, w: 0 };
          output.push({ key: key, material: pbr });
        }
      }
    }
    for (let i = 0; i < node.children.count(); i++) {
      const child = node.children.get(i);
      if (child) this.collectMaterials(child, key, output);
    }
  }

  private selectionChanged(): void {
    for (let i = 0; i < this.materials.length; i++) {
      const item = this.materials[i];
      if (item.key && item.key === this.selectedKey) {
        item.material.baseColor.factor = { x: 0.025, y: 0.48, z: 0.34, w: 1 };
      } else if (item.key) {
        item.material.baseColor.factor = { x: 0.38, y: 0.46, z: 0.40, w: 1 };
      } else {
        item.material.baseColor.factor = { x: 0.26, y: 0.30, z: 0.28, w: 1 };
      }
    }
  }

  private themeChanged(): void {
    if (this.camera) {
      this.camera.clearColor = this.isDark ?
        { r: 0.070588, g: 0.070588, b: 0.070588, a: 1 } :
        { r: 0.956863, g: 0.964706, b: 0.972549, a: 1 };
    }
  }

  private actionChanged(): void {
    if (this.actionName === 'retry') {
      this.loadScene();
      return;
    }
    if (this.actionName === 'front' || this.actionName === 'back' || this.actionName === 'reset') {
      this.orbit.reset(this.actionName === 'back');
      this.taps.multitouch();
      this.updateCamera();
    }
  }

  private updateCamera(): void {
    this.epoch.invalidateView();
    if (!this.camera) return;
    const pose = this.orbit.pose();
    this.camera.position = pose.position;
    this.camera.rotation = pose.rotation;
  }

  private hitName(node: Node): string {
    let current: Node | null = node;
    while (current) {
      if (current.name.startsWith('base_') || muscleNodeKey(current.name)) return current.name;
      current = current.parent;
    }
    return node.name;
  }

  private async pick(x: number, y: number): Promise<void> {
    const scene = this.scene;
    const camera = this.camera;
    if (!scene || !camera || this.loading || this.failed) return;
    const token = this.loadToken;
    const view = this.epoch.view;
    const nonce = ++this.pickNonce;
    const cameraPosition = this.orbit.pose().position;
    try {
      const hits: RaycastResult[] = await camera.raycast({
        x: Math.max(0, Math.min(1, x / this.orbit.width)),
        y: Math.max(0, Math.min(1, y / this.orbit.height))
      }, {});
      if (!this.epoch.current(token) || this.scene !== scene || this.camera !== camera ||
        this.epoch.view !== view || this.pickNonce !== nonce) return;
      const candidates: MuscleHit[] = [];
      for (let i = 0; i < hits.length; i++) {
        const hitPos: Point3 = {
          x: hits[i].hitPosition.x,
          y: hits[i].hitPosition.y,
          z: hits[i].hitPosition.z
        };
        candidates.push(new MuscleHit(this.hitName(hits[i].node), hitPos));
      }
      const key = nearestMuscle(candidates, cameraPosition);
      if (key) this.onPicked(key);
    } catch (_) {
      // A disappearing surface can cancel its pending native raycast.
    }
  }

  private handleSceneTouch(event: TouchEvent): void {
    event.stopPropagation();
    if (event.type === TouchType.Cancel) {
      this.fingers = 0;
      this.taps.multitouch();
      this.pickNonce++;
      return;
    }
    if (event.type === TouchType.Up) {
      const point = event.changedTouches[0];
      if (point && this.fingers === 1 && this.taps.end(point.x, point.y, Date.now())) {
        this.pick(point.x, point.y);
      }
      this.fingers = 0;
      this.lastSpan = 0;
      return;
    }
    const touches = event.touches;
    if (touches.length === 0) return;
    const count = touches.length;
    const x = count > 1 ? (touches[0].x + touches[1].x) / 2 : touches[0].x;
    const y = count > 1 ? (touches[0].y + touches[1].y) / 2 : touches[0].y;
    const span = count > 1 ? Math.hypot(touches[0].x - touches[1].x, touches[0].y - touches[1].y) : 0;
    if (event.type === TouchType.Down || this.fingers !== count) {
      this.pickNonce++;
      if (this.fingers === 0 && count === 1 && event.type === TouchType.Down) {
        this.taps.begin(x, y, Date.now());
      } else {
        this.taps.multitouch();
      }
      this.fingers = count;
      this.lastX = x;
      this.lastY = y;
      this.lastSpan = span;
      return;
    }
    if (count === 1) {
      this.taps.move(x, y);
      this.orbit.orbit(x - this.lastX, y - this.lastY);
    } else {
      this.taps.multitouch();
      if (this.lastSpan > 1) this.orbit.setZoom(this.orbit.zoom * span / this.lastSpan);
      this.orbit.pan(x - this.lastX, y - this.lastY);
    }
    this.lastX = x;
    this.lastY = y;
    this.lastSpan = span;
    this.updateCamera();
  }

  build() {
    Stack() {
      if (this.scene && !this.loading && !this.failed) {
        Component3D({ scene: this.scene, modelType: ModelType.SURFACE })
          .width('100%')
          .height('100%')
          .onTouch((event: TouchEvent) => this.handleSceneTouch(event))
      }
      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress().width(30).height(30).color('#23896B')
          Text('正在加载肌肉模型').fontSize(13).fontColor(this.isDark ? '#A6B7AF' : '#728078')
        }
      } else if (this.failed) {
        Column({ space: 12 }) {
          Text('肌肉模型加载失败').fontSize(15).fontColor(this.isDark ? '#DCE6DF' : '#35483E')
          Text('请重试，或从下方选择部位').fontSize(12).fontColor(this.isDark ? '#A6B7AF' : '#728078')
          Button('重新加载').fontSize(13).height(36).backgroundColor('#23896B').onClick(() => this.loadScene())
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const width = Number(newArea.width);
      const height = Number(newArea.height);
      if (width > 0 && height > 0) {
        this.orbit.resize(width, height);
        this.updateCamera();
      }
    })
  }
}
