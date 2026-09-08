import assert from 'node:assert/strict';
import fs from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';

const file = new URL('../entry/src/main/ets/common/OrbitCamera.ets', import.meta.url);
assert.ok(fs.existsSync(file), 'Production orbit controller must exist');
const { OrbitCamera, TapTracker, nearestMuscle, SceneEpoch } = await import('data:text/javascript;base64,' +
  Buffer.from(stripTypeScriptTypes(fs.readFileSync(file, 'utf8'))).toString('base64'));
function rotate(v, q) {
  const t = [2*(q.y*v[2]-q.z*v[1]), 2*(q.z*v[0]-q.x*v[2]), 2*(q.x*v[1]-q.y*v[0])];
  return [v[0]+q.w*t[0]+q.y*t[2]-q.z*t[1],v[1]+q.w*t[1]+q.z*t[0]-q.x*t[2],v[2]+q.w*t[2]+q.x*t[1]-q.y*t[0]];
}
const near = (a,b) => assert.ok(Math.abs(a-b)<1e-8, `${a} != ${b}`);
const orbit = new OrbitCamera();
for (const aspect of [.3,.65,1,2.2]) {
  orbit.resize(aspect*1000,1000);
  for (const yaw of [0,Math.PI/2,Math.PI,5.8]) {
    for (const pitch of [-.6,0,.6]) {
      orbit.yaw=yaw; orbit.pitch=pitch;
      const pose=orbit.pose();
      const forward=rotate([0,0,-1],pose.rotation);
      const delta=[pose.target.x-pose.position.x,pose.target.y-pose.position.y,pose.target.z-pose.position.z];
      const len=Math.hypot(...delta);
      forward.forEach((n,i)=>near(n,delta[i]/len));
      const inv={x:-pose.rotation.x,y:-pose.rotation.y,z:-pose.rotation.z,w:pose.rotation.w};
      for (const x of [-.35,.35]) for (const y of [0,1.8]) for (const z of [-.14,.14]) {
        const c=rotate([x-pose.position.x,y-pose.position.y,z-pose.position.z],inv);
        assert.ok(Math.abs(c[0]/-c[2]) < Math.tan(orbit.fov/2)*aspect, 'horizontal full-body fit');
        assert.ok(Math.abs(c[1]/-c[2]) < Math.tan(orbit.fov/2), 'vertical full-body fit');
      }
    }
  }
}
orbit.orbit(100000,100000); assert.ok(orbit.yaw>=0 && orbit.yaw<2*Math.PI); assert.equal(orbit.pitch,.65);
orbit.setZoom(100); assert.equal(orbit.zoom,3);
orbit.pan(100000,100000); assert.ok(Math.abs(orbit.panX)<=.45 && Math.abs(orbit.panY)<=.7);
orbit.setZoom(0); assert.equal(orbit.zoom,1); assert.equal(orbit.panX,0); assert.equal(orbit.panY,0);
orbit.reset(true); near(orbit.yaw,Math.PI); orbit.reset(); near(orbit.yaw,0);
const tap=new TapTracker();
tap.begin(10,10,0); tap.move(40,10); assert.equal(tap.end(40,10,100),false);
tap.begin(10,10,200); assert.equal(tap.end(11,10,300),true,'a prior drag cannot suppress next tap');
tap.begin(10,10,400); tap.multitouch(); assert.equal(tap.end(10,10,450),false);
tap.begin(10,10,500); tap.move(40,10); assert.equal(tap.end(10,10,600),false,'out-and-back drag is still a drag');
tap.begin(10,10,700); assert.equal(tap.end(10,10,1300),false,'long press does not pick');
const hit=(name,z,centerDistance=0)=>({name,hitPosition:{x:0,y:.9,z},centerDistance});
assert.equal(nearestMuscle([hit('pick_chest_L',.1,100),hit('pick_lats_R',-.1,0)],{x:0,y:.9,z:3}), 'chest');
assert.equal(nearestMuscle([hit('pick_chest_L',.1),hit('base_hand',.2)],{x:0,y:.9,z:3}), '');
assert.equal(nearestMuscle([hit('pick_chest_L',.1),hit('pick_lats_R',-.1)],{x:0,y:.9,z:-3}), 'lats');
assert.equal(nearestMuscle([hit('pick_unknown_L',.2)],{x:0,y:.9,z:3}), '');
assert.equal(nearestMuscle([],{x:0,y:.9,z:3}), '');
const epoch=new SceneEpoch(); const first=epoch.begin(); assert.ok(epoch.current(first));
const second=epoch.begin(); assert.ok(!epoch.current(first)); assert.ok(epoch.current(second));
epoch.invalidateView(); assert.ok(epoch.current(second)); const view=epoch.view;
epoch.invalidateView(); assert.notEqual(epoch.view,view);
epoch.stop(); assert.ok(!epoch.current(second));
console.log('Muscle scene behavior: quaternion look-at, all-aspect fit, orbit/zoom/pan bounds, tap reset, occlusion picking, lifecycle epochs passed.');
