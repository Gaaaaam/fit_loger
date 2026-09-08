import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

function load(relative, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
    .replace(/^import[\s\S]*?;\r?\n/gm, '').replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}
const types = load('model/muscleTypes.ets', ['toMuscleKey']);
const logic = load('common/MuscleLogic.ets', ['clampPitch', 'wrapYaw', 'DEFAULT_CAMERA_DISTANCE',
  'clampDistance', 'canPanAfterZoom', 'muscleFromNodeChain'], types);
const orbit = load('common/OrbitCamera.ets', ['OrbitState', 'resetOrbit', 'frontOrbit', 'backOrbit',
  'applyRotate', 'applyZoom', 'applyPan', 'applyOrbitToCamera', 'lookAt'], logic);

// The full-height 1.8 m model must fit even on a narrow portrait viewport.
const state = new orbit.OrbitState();
orbit.resetOrbit(state, 220, 600);
assert.ok(state.distance > 3.6, 'narrow viewport needs a longer fit distance');
const initialDistance = state.distance;
orbit.applyZoom(state, 2);
orbit.applyPan(state, 999999, 999999);
assert.ok(Math.abs(state.panRight) <= 0.55, 'horizontal panning must stay near the model');
assert.ok(Math.abs(state.panUp) <= 0.8, 'vertical panning must stay near the model');
orbit.applyZoom(state, 0.01);
assert.equal(state.distance, initialDistance, 'zoom out stops at the full body fit');
assert.equal(state.panRight, 0);
assert.equal(state.panUp, 0);

function rotateVector(q, v) {
  const cross = (a, b) => ({ x: a.y*b.z-a.z*b.y, y: a.z*b.x-a.x*b.z, z: a.x*b.y-a.y*b.x });
  const a = cross(q, v), b = cross(q, a);
  return { x: v.x+2*(q.w*a.x+b.x), y: v.y+2*(q.w*a.y+b.y), z: v.z+2*(q.w*a.z+b.z) };
}
for (const eye of [{x:0,y:0,z:3},{x:0,y:0,z:-3},{x:3,y:1,z:0},{x:-2,y:-1,z:3}]) {
  const node = {};
  orbit.lookAt(node, eye, {x:0,y:0,z:0}, {x:0,y:1,z:0});
  const actual = rotateVector(node.rotation, {x:0,y:0,z:-1});
  const len = Math.hypot(eye.x,eye.y,eye.z);
  assert.ok(Math.hypot(actual.x+eye.x/len,actual.y+eye.y/len,actual.z+eye.z/len)<1e-6,
    'local camera -Z must point toward its target');
}
orbit.backOrbit(state);
const camera = {};
orbit.applyOrbitToCamera(camera, state);
assert.ok(camera.position.z < 0);
orbit.frontOrbit(state);
orbit.applyRotate(state, 8000, 8000);
assert.ok(state.yaw >= 0 && state.yaw < Math.PI*2);
assert.ok(state.pitch <= 0.58);

console.log('scene camera orientation, adaptive framing and bounded manipulation passed');

const interaction = load('common/SceneInteraction.ets', ['SceneGesture', 'nearestSceneMuscle'], logic);
const gesture = new interaction.SceneGesture();
const point = (x,y,id=0) => ({x,y,id});
gesture.down([point(0,0)]);
assert.equal(gesture.move([point(20,0)]).kind, 'rotate');
assert.equal(gesture.up([], point(20,0)).kind, 'none');
gesture.down([point(30,30)]);
const tap = gesture.up([], point(30,30));
assert.equal(tap.kind, 'pick', 'a tap after a drag must work');
gesture.down([point(0,0)]);
gesture.down([point(0,0),point(10,0,1)]);
const pinch = gesture.move([point(10,5),point(30,5,1)]);
assert.equal(pinch.kind, 'transform');
assert.equal(pinch.scale, 2);
assert.equal(pinch.dx, 15);
assert.equal(pinch.dy, 5);
gesture.up([point(10,5)],point(30,5,1));
assert.equal(gesture.move([point(20,5)]).kind, 'none', 'remaining pinch finger cannot rotate');
assert.equal(gesture.up([],point(20,5)).kind,'none');
gesture.down([point(4,4)]);
gesture.cancel();
assert.equal(gesture.up([],point(4,4)).kind,'none');
const hits = [
  {names:['pick_lats_L'],position:{x:0,y:0,z:-0.2},visible:true},
  {names:['pick_chest_L'],position:{x:0,y:0,z:0.2},visible:true}
];
assert.equal(interaction.nearestSceneMuscle(hits,{x:0,y:0,z:3}),'chest');
assert.equal(interaction.nearestSceneMuscle(hits,{x:0,y:0,z:-3}),'lats');
hits.push({names:['base_head'],position:{x:0,y:0,z:0.3},visible:true});
assert.equal(interaction.nearestSceneMuscle(hits,{x:0,y:0,z:3}),null,'solid unselectable geometry occludes muscles');
hits[2].visible=false;
assert.equal(interaction.nearestSceneMuscle(hits,{x:0,y:0,z:3}),'chest');
console.log('scene gesture arbitration and nearest visible intersection passed');

function deferred() {
  let resolve;
  const promise = new Promise(r => { resolve=r; });
  return {promise,resolve};
}
let componentSource = readFileSync(new URL('../entry/src/main/ets/components/MuscleSceneView.ets', import.meta.url),'utf8')
  .replace(/^import[\s\S]*?;\r?\n/gm,'')
  .replace(/@(?:Component|Prop|State|Watch\([^)]*\))/g,'')
  .replace('export struct MuscleSceneView','class MuscleSceneView');
componentSource = componentSource.slice(0,componentSource.indexOf('  build() {'))+'\n}';
const loads=[];
const timers=new Map();
let nextTimer=1;
const context={...orbit,...interaction, Map, Scene:{load:()=>{const d=deferred();loads.push(d);return d.promise;}},
  $rawfile:()=>'',hilog:{error:()=>{}},
  setTimeout:fn=>{const id=nextTimer++;timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id)};
runInNewContext(stripTypeScriptTypes(componentSource)+'\nglobalThis.Component=MuscleSceneView;',context);
const view=new context.Component();
const setupA=deferred();
const makeScene=name=>({name,destroyed:false,destroy(){this.destroyed=true;}});
const sceneA=makeScene('A'),sceneB=makeScene('B');
view.setupScene=async(scene)=>{
  if(scene===sceneA) await setupA.promise;
  return {scene,camera:{},materials:new Map()};
};
const loadA=view.loadScene();
loads[0].resolve(sceneA);
await Promise.resolve();await Promise.resolve();
const loadB=view.loadScene();
loads[1].resolve(sceneB);
await loadB;
setupA.resolve();
await loadA;
assert.equal(sceneB.destroyed,false,'obsolete setup must never destroy the current scene');
assert.equal(sceneA.destroyed,true,'obsolete scene must be released');
assert.equal(view.ready,true);
view.aboutToDisappear();
assert.equal(sceneB.destroyed,true);
const timeoutView=new context.Component();
const pending=timeoutView.loadScene();
assert.ok(timers.size>0,'loading must have a bounded timeout');
for(const fn of [...timers.values()]) fn();
assert.equal(timeoutView.ready,false);
assert.equal(timeoutView.failed,true);
const late=makeScene('late');
loads[2].resolve(late);
await pending;
assert.equal(late.destroyed,true,'late native load after timeout must be released');
console.log('scene retry races, disposal and loading timeout passed');
