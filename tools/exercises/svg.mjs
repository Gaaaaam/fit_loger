/** Original parametric exercise artwork. Shared figure + equipment primitives. */

const DEFS = `<defs>
  <linearGradient id="body" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#E2EBED"/><stop offset=".46" stop-color="#AFBFC7"/><stop offset="1" stop-color="#708994"/>
  </linearGradient>
  <linearGradient id="muscle" x1="0" y1="0" x2=".8" y2="1">
    <stop stop-color="#F0F5F4"/><stop offset=".4" stop-color="#CDDADF"/><stop offset="1" stop-color="#91A7B2"/>
  </linearGradient>
  <linearGradient id="target" x1="0" y1="0" x2=".85" y2="1">
    <stop stop-color="#8EE4BC"/><stop offset=".35" stop-color="#39B38D"/><stop offset=".72" stop-color="#168269"/><stop offset="1" stop-color="#0B534D"/>
  </linearGradient>
  <linearGradient id="targetDeep" x1="0" y1="0" x2="1" y2=".8">
    <stop stop-color="#53CBA1"/><stop offset=".65" stop-color="#168269"/><stop offset="1" stop-color="#083D3D"/>
  </linearGradient>
  <linearGradient id="skin" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#EDD0AD"/><stop offset=".5" stop-color="#C99670"/><stop offset="1" stop-color="#946345"/>
  </linearGradient>
  <linearGradient id="kit" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#405764"/><stop offset="1" stop-color="#142C39"/>
  </linearGradient>
  <marker id="arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0 1 L9 5 L0 9 Z" fill="#168269"/>
  </marker>
</defs>`;

function esc(text) {
  return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function lerpPt(a, b, t) {
  return [lerp(a[0], b[0], t), lerp(a[1], b[1], t)];
}

function polar(o, deg, len) {
  const r = (deg * Math.PI) / 180;
  return [o[0] + Math.cos(r) * len, o[1] + Math.sin(r) * len];
}

function fillOf(active) {
  return active ? 'url(#target)' : 'url(#muscle)';
}

function strokeOf(active) {
  return active ? '#246E62' : '#627D88';
}

function capsule(a, b, r, fill, stroke = '#627D88') {
  const dx = b[0] - a[0];
  const dy = b[1] - a[1];
  const len = Math.hypot(dx, dy) || 0.001;
  const px = (-dy / len) * r;
  const py = (dx / len) * r;
  return `<path d="M ${a[0] + px} ${a[1] + py} L ${b[0] + px} ${b[1] + py} A ${r} ${r} 0 0 1 ${b[0] - px} ${b[1] - py} L ${a[0] - px} ${a[1] - py} A ${r} ${r} 0 0 1 ${a[0] + px} ${a[1] + py} Z" fill="${fill}" stroke="${stroke}" stroke-width="1.2" stroke-linejoin="round"/>`;
}

function disc(p, r, fill, stroke = '#627D88') {
  return `<circle cx="${p[0]}" cy="${p[1]}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="1.1"/>`;
}

function head(p, r = 11) {
  return disc(p, r, 'url(#skin)', '#9A7256') +
    `<path d="${`M ${p[0] - 7} ${p[1] - 4} Q ${p[0]} ${p[1] - r - 2} ${p[0] + 8} ${p[1] - 3}`}" fill="#253B43"/>`;
}

function arrow(a, b) {
  return `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="#168269" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arr)" opacity=".85"/>`;
}

function bench(x, y, w, h, tilt = 0) {
  const pad = `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="url(#kit)" stroke="#142C39" transform="rotate(${tilt} ${x + w / 2} ${y + h / 2})"/>`;
  const leg1 = `<rect x="${x + 10}" y="${y + h}" width="8" height="${28 - Math.abs(tilt) * 0.15}" rx="2" fill="#243E4B"/>`;
  const leg2 = `<rect x="${x + w - 18}" y="${y + h}" width="8" height="28" rx="2" fill="#243E4B"/>`;
  return pad + (Math.abs(tilt) < 8 ? leg1 + leg2 : '');
}

function barbell(left, right, thick = 3.2) {
  const midY = (left[1] + right[1]) / 2;
  const bar = `<line x1="${left[0]}" y1="${left[1]}" x2="${right[0]}" y2="${right[1]}" stroke="#2A4450" stroke-width="${thick}" stroke-linecap="round"/>`;
  const plate = (p, s) =>
    `<g transform="translate(${p[0]} ${p[1]}) rotate(${(Math.atan2(right[1] - left[1], right[0] - left[0]) * 180) / Math.PI})">
      <rect x="${-4 * s}" y="-14" width="${8 * s}" height="28" rx="2" fill="url(#kit)"/>
      <rect x="${-7 * s}" y="-11" width="${5 * s}" height="22" rx="1.5" fill="#1B3340"/>
    </g>`;
  return bar + plate(left, 1) + plate(right, 1) + disc([(left[0] + right[0]) / 2, midY], 2.2, '#D7E3E0', 'none');
}

function dumbbell(p, angle = 0, scale = 1) {
  return `<g transform="translate(${p[0]} ${p[1]}) rotate(${angle})">
    <rect x="${-11 * scale}" y="${-4 * scale}" width="${22 * scale}" height="${8 * scale}" rx="2" fill="#2A4450"/>
    <rect x="${-16 * scale}" y="${-8 * scale}" width="${6 * scale}" height="${16 * scale}" rx="2" fill="url(#kit)"/>
    <rect x="${10 * scale}" y="${-8 * scale}" width="${6 * scale}" height="${16 * scale}" rx="2" fill="url(#kit)"/>
  </g>`;
}

function kettlebell(p) {
  return `<g transform="translate(${p[0]} ${p[1]})">
    <path d="M-6 -12 Q0 -18 6 -12 L6 -6 Q12 2 8 12 Q0 18 -8 12 Q-12 2 -6 -6 Z" fill="url(#kit)" stroke="#142C39"/>
    <path d="M-5 -12 Q0 -16 5 -12" fill="none" stroke="#AFBFC7" stroke-width="2"/>
  </g>`;
}

function ezbar(left, right) {
  const mx = (left[0] + right[0]) / 2;
  const my = (left[1] + right[1]) / 2;
  return `<path d="M ${left[0]} ${left[1]} Q ${mx - 24} ${my + 8} ${mx} ${my} Q ${mx + 24} ${my - 8} ${right[0]} ${right[1]}" fill="none" stroke="#2A4450" stroke-width="3.2" stroke-linecap="round"/>` +
    barbell(left, right, 0).replace(/<line[\s\S]*?\/>/, '');
}

function cableStack(x = 46, y = 48) {
  return `<g>
    <rect x="${x}" y="${y}" width="22" height="118" rx="4" fill="#3A5561" stroke="#142C39"/>
    <rect x="${x + 4}" y="${y + 8}" width="14" height="10" rx="1" fill="#AFBFC7"/>
    <rect x="${x + 4}" y="${y + 20}" width="14" height="70" rx="1" fill="#1B3340"/>
    <circle cx="${x + 11}" cy="${y}" r="5" fill="#708994"/>
  </g>`;
}

function cableLine(from, to) {
  return `<line x1="${from[0]}" y1="${from[1]}" x2="${to[0]}" y2="${to[1]}" stroke="#91A7B2" stroke-width="1.8"/>`;
}

function handle(p, w = 16) {
  return `<rect x="${p[0] - w / 2}" y="${p[1] - 3}" width="${w}" height="6" rx="2" fill="#2A4450"/>`;
}

function band(a, b) {
  return `<path d="M ${a[0]} ${a[1]} Q ${(a[0] + b[0]) / 2} ${(a[1] + b[1]) / 2 + 18} ${b[0]} ${b[1]}" fill="none" stroke="#168269" stroke-width="3.2" stroke-linecap="round"/>`;
}

function pullupBar(y = 42) {
  return `<line x1="70" y1="${y}" x2="250" y2="${y}" stroke="#2A4450" stroke-width="5" stroke-linecap="round"/>
    <rect x="66" y="${y - 18}" width="6" height="28" fill="#243E4B"/>
    <rect x="248" y="${y - 18}" width="6" height="28" fill="#243E4B"/>`;
}

function dipBars() {
  return `<path d="M88 70 L88 150 L70 168" fill="none" stroke="#2A4450" stroke-width="5" stroke-linecap="round"/>
    <path d="M232 70 L232 150 L250 168" fill="none" stroke="#2A4450" stroke-width="5" stroke-linecap="round"/>`;
}

function machineFrame(x, y, w, h) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="none" stroke="#3A5561" stroke-width="5"/>
    <rect x="${x + 8}" y="${y + h - 14}" width="${w - 16}" height="10" rx="3" fill="#243E4B"/>`;
}

function floor() {
  return `<ellipse cx="160" cy="222" rx="108" ry="7" fill="#345D60" opacity=".12"/>`;
}

function has(targets, name) {
  return targets.indexOf(name) >= 0;
}

function drawSideFigure(j, targets) {
  const chest = has(targets, 'chest') || has(targets, 'upper_chest');
  const back = has(targets, 'back') || has(targets, 'lats') || has(targets, 'upper_back') || has(targets, 'erector');
  const abs = has(targets, 'abs') || has(targets, 'core');
  const glute = has(targets, 'glute');
  const quad = has(targets, 'quad');
  const ham = has(targets, 'hamstring');
  const arm = has(targets, 'biceps') || has(targets, 'triceps') || has(targets, 'arm');
  const delt = has(targets, 'front_delt') || has(targets, 'side_delt') || has(targets, 'rear_delt') || has(targets, 'shoulder');
  const calf = has(targets, 'calf');
  const parts = [];
  parts.push(capsule(j.hip, j.shoulder, 13, fillOf(chest || back || abs), strokeOf(chest || back || abs)));
  if (chest) {
    parts.push(disc(lerpPt(j.shoulder, j.hip, 0.28), 11, 'url(#targetDeep)', '#246E62'));
  }
  if (abs) {
    parts.push(disc(lerpPt(j.shoulder, j.hip, 0.62), 9, 'url(#target)', '#246E62'));
  }
  if (glute) {
    parts.push(disc(j.hip, 12, 'url(#targetDeep)', '#246E62'));
  }
  parts.push(capsule(j.hip, j.knee, 9, fillOf(quad || ham), strokeOf(quad || ham)));
  parts.push(capsule(j.knee, j.ankle, 7, fillOf(calf), strokeOf(calf)));
  if (j.hipB) {
    parts.push(capsule(j.hipB, j.kneeB, 8, fillOf(quad || ham), strokeOf(quad || ham)));
    parts.push(capsule(j.kneeB, j.ankleB, 6.5, fillOf(calf), strokeOf(calf)));
  }
  parts.push(capsule(j.shoulder, j.elbow, 7.5, fillOf(arm || delt), strokeOf(arm || delt)));
  parts.push(capsule(j.elbow, j.wrist, 6, fillOf(arm), strokeOf(arm)));
  if (j.shoulderB) {
    parts.push(capsule(j.shoulderB, j.elbowB, 7, fillOf(arm || delt), strokeOf(arm || delt)));
    parts.push(capsule(j.elbowB, j.wristB, 5.5, fillOf(arm), strokeOf(arm)));
  }
  parts.push(disc(j.shoulder, 8, fillOf(delt), strokeOf(delt)));
  parts.push(head(j.head, j.headR || 11));
  parts.push(disc(j.ankle, 5, 'url(#kit)', '#243E4B'));
  if (j.ankleB) {
    parts.push(disc(j.ankleB, 5, 'url(#kit)', '#243E4B'));
  }
  return parts.join('');
}

function drawFrontFigure(j, targets) {
  const chest = has(targets, 'chest');
  const abs = has(targets, 'abs') || has(targets, 'core');
  const delt = has(targets, 'side_delt') || has(targets, 'front_delt') || has(targets, 'shoulder');
  const arm = has(targets, 'biceps') || has(targets, 'triceps') || has(targets, 'arm');
  const quad = has(targets, 'quad');
  const glute = has(targets, 'glute');
  const parts = [];
  parts.push(capsule(j.hipL, j.shoulderL, 8, 'url(#body)'));
  parts.push(capsule(j.hipR, j.shoulderR, 8, 'url(#body)'));
  parts.push(capsule(j.shoulderL, j.shoulderR, 12, fillOf(chest || abs), strokeOf(chest || abs)));
  parts.push(capsule(j.hipL, j.hipR, 11, fillOf(glute || abs), strokeOf(glute || abs)));
  parts.push(capsule(j.hipL, j.kneeL, 8, fillOf(quad), strokeOf(quad)));
  parts.push(capsule(j.hipR, j.kneeR, 8, fillOf(quad), strokeOf(quad)));
  parts.push(capsule(j.kneeL, j.ankleL, 6.5, 'url(#muscle)'));
  parts.push(capsule(j.kneeR, j.ankleR, 6.5, 'url(#muscle)'));
  parts.push(capsule(j.shoulderL, j.elbowL, 7, fillOf(arm || delt), strokeOf(arm || delt)));
  parts.push(capsule(j.shoulderR, j.elbowR, 7, fillOf(arm || delt), strokeOf(arm || delt)));
  parts.push(capsule(j.elbowL, j.wristL, 6, fillOf(arm), strokeOf(arm)));
  parts.push(capsule(j.elbowR, j.wristR, 6, fillOf(arm), strokeOf(arm)));
  parts.push(disc(j.shoulderL, 8, fillOf(delt), strokeOf(delt)));
  parts.push(disc(j.shoulderR, 8, fillOf(delt), strokeOf(delt)));
  parts.push(head(j.head, 12));
  parts.push(disc(j.ankleL, 5, 'url(#kit)', '#243E4B'));
  parts.push(disc(j.ankleR, 5, 'url(#kit)', '#243E4B'));
  return parts.join('');
}

function standingSide(torsoDeg, thighDeg, shinDeg, uarmDeg, farmDeg, extras = {}) {
  const hip = extras.hip || [152, extras.hipY || 156];
  const shoulder = polar(hip, torsoDeg, extras.torsoLen || 50);
  const headPt = polar(shoulder, extras.headDeg || -92, 20);
  const knee = polar(hip, thighDeg, extras.thighLen || 36);
  const ankle = polar(knee, shinDeg, extras.shinLen || 34);
  const elbow = polar(shoulder, uarmDeg, extras.uarmLen || 26);
  const wrist = polar(elbow, farmDeg, extras.farmLen || 24);
  const hipB = extras.split ? polar(hip, extras.thighBDeg, extras.thighLen || 36) : null;
  const kneeB = hipB ? hipB : null;
  const ankleB = kneeB ? polar(kneeB, extras.shinBDeg, extras.shinLen || 34) : null;
  const j = {
    hip, shoulder, head: headPt, knee, ankle, elbow, wrist,
    hipB: extras.split ? hip : null,
    kneeB: extras.split ? polar(hip, extras.thighBDeg, extras.thighLen || 36) : null,
    ankleB: extras.split ? polar(polar(hip, extras.thighBDeg, extras.thighLen || 36), extras.shinBDeg, extras.shinLen || 34) : null
  };
  if (extras.farArm) {
    j.shoulderB = shoulder;
    j.elbowB = polar(shoulder, extras.uarmBDeg, 24);
    j.wristB = polar(j.elbowB, extras.farmBDeg, 22);
  }
  return j;
}

function frontStand(armDeg, extras = {}) {
  const hipY = extras.hipY || 150;
  const squat = extras.squat || 0;
  const head = [160, 46 + squat * 18];
  const shoulderL = [132, 72 + squat * 16];
  const shoulderR = [188, 72 + squat * 16];
  const hipL = [142, hipY + squat * 8];
  const hipR = [178, hipY + squat * 8];
  const kneeL = [140, 186 - squat * 6];
  const kneeR = [180, 186 - squat * 6];
  const ankleL = extras.jack ? [118, 214] : [138, 214];
  const ankleR = extras.jack ? [202, 214] : [182, 214];
  const elbowL = polar(shoulderL, 180 - armDeg, 28);
  const elbowR = polar(shoulderR, armDeg, 28);
  const wristL = polar(elbowL, 180 - (extras.farmDeg ?? armDeg), 24);
  const wristR = polar(elbowR, extras.farmDeg ?? armDeg, 24);
  return {
    head, shoulderL, shoulderR, hipL, hipR, kneeL, kneeR, ankleL, ankleR,
    elbowL, elbowR, wristL, wristR
  };
}

function sceneBench(phase, opt) {
  const t = phase;
  const inc = opt.incline || 0;
  const hip = [188, 128 - inc * 0.35];
  const shoulder = [108, 118 - inc * 0.9];
  const headPt = polar(shoulder, 188, 22);
  const knee = [236, 128];
  const ankle = [274, 118];
  const press = lerp(0, 1, t);
  const elbowY = lerp(152, 86, press);
  const wristY = lerp(118, 72, press);
  const elbow = [108 + (opt.kit === 'dumbbell' ? -8 : 0), elbowY - inc * 0.4];
  const wrist = [108, wristY - inc * 0.5];
  const elbowB = [132, elbowY - inc * 0.4];
  const wristB = [150, wristY - inc * 0.5];
  const j = {
    hip, shoulder, head: headPt, knee, ankle, elbow, wrist,
    shoulderB: [128, shoulder[1]], elbowB, wristB, hipB: hip,
    kneeB: [248, 132], ankleB: [286, 122]
  };
  let kit = bench(78, 124, 170, 16, -inc * 0.6);
  if (opt.kit === 'dumbbell') {
    kit += dumbbell(wrist, 0) + dumbbell(wristB, 0);
  } else if (opt.kit === 'machine') {
    kit += machineFrame(70, 40, 180, 150) + barbell([wrist[0] - 40, wrist[1]], [wristB[0] + 40, wrist[1]]);
  } else {
    kit += barbell([wrist[0] - 52, wrist[1]], [wristB[0] + 36, wrist[1]]);
  }
  const arr = arrow([210, lerp(150, 86, press)], [210, lerp(150, 86, press) - 22]);
  return { view: 'side', joints: j, extras: kit + arr, targets: opt.targets || ['chest'] };
}

function sceneFly(phase, opt) {
  const t = phase;
  const inc = opt.incline || 0;
  const hip = [186, 130 - inc * 0.3];
  const shoulder = [118, 120 - inc * 0.8];
  const headPt = polar(shoulder, 188, 22);
  const open = lerp(1, 0, t);
  const wristL = [58 + open * 8, 118 + open * 28 - inc * 0.3];
  const wristR = [178 - open * 8, 118 + open * 28 - inc * 0.3];
  const elbowL = lerpPt(shoulder, wristL, 0.5);
  const elbowR = lerpPt(shoulder, wristR, 0.45);
  const j = {
    hip, shoulder, head: headPt, knee: [238, 130], ankle: [276, 120],
    elbow: elbowR, wrist: wristR, shoulderB: shoulder, elbowB: elbowL, wristB: wristL
  };
  let kit = bench(80, 126, 168, 16, -inc * 0.55);
  if (opt.kit === 'cable') {
    kit += cableStack(36, 40) + cableStack(262, 40) + cableLine([47, 48], wristL) + cableLine([273, 48], wristR) + handle(wristL) + handle(wristR);
  } else {
    kit += dumbbell(wristL, 80) + dumbbell(wristR, -80);
  }
  kit += arrow(wristL, lerpPt(wristL, wristR, 0.25));
  return { view: 'side', joints: j, extras: kit, targets: ['chest'] };
}

function scenePushup(phase, opt) {
  const down = 1 - phase;
  const y = 148 + down * 22;
  const hands = opt.close ? [148, 188] : [118, 188];
  const handsB = opt.close ? [172, 188] : [202, 188];
  const feet = opt.decline ? [262, 96] : (opt.incline ? [250, 210] : [258, 188]);
  const shoulder = [136, y - 8];
  const hip = [200, y + (opt.incline ? 10 : 0)];
  const headPt = polar(shoulder, 200, 20);
  const j = {
    hip, shoulder, head: headPt, knee: lerpPt(hip, feet, 0.55), ankle: feet,
    elbow: lerpPt(shoulder, hands, 0.55), wrist: hands,
    shoulderB: [152, y - 6], elbowB: lerpPt([152, y - 6], handsB, 0.55), wristB: handsB
  };
  const kit = floor() + (opt.incline ? bench(96, 196, 90, 14, 0) : '') + (opt.decline ? bench(230, 88, 70, 12, 0) : '') +
    arrow([160, y + 8], [160, y + 8 + (down > 0.5 ? 16 : -16)]);
  return { view: 'side', joints: j, extras: kit, targets: opt.targets || ['chest'] };
}

function sceneDip(phase) {
  const down = 1 - phase;
  const y = 88 + down * 28;
  const j = standingSide(-90, 70, 80, 110, 70, { hip: [160, y + 48], torsoLen: 46, uarmLen: 22, farmLen: 20 });
  j.elbow = [92, y + 18];
  j.wrist = [88, y];
  j.shoulderB = [200, j.shoulder[1]];
  j.elbowB = [228, y + 18];
  j.wristB = [232, y];
  j.head = [160, y - 8];
  const kit = dipBars() + arrow([160, y + 70], [160, y + 70 + (down > 0.4 ? 18 : -18)]);
  return { view: 'side', joints: j, extras: kit, targets: ['chest', 'triceps'] };
}

function sceneSquat(phase, opt) {
  const d = 1 - phase;
  const hipY = 118 + d * 38;
  const torso = -100 - d * 12;
  const thigh = 50 + d * 55;
  const shin = 80 - d * 18;
  const barY = hipY - 58;
  const j = standingSide(torso, thigh, shin, -80, -70, { hip: [160, hipY], hipY });
  j.wrist = [148, barY];
  j.elbow = [150, barY + 16];
  let kit = floor();
  if (opt.kit === 'dumbbell' || opt.goblet) {
    kit += dumbbell([160, hipY - 36], 90, 1.1);
  } else if (opt.kit === 'machine') {
    kit += machineFrame(78, 36, 164, 176) + barbell([110, barY], [210, barY]);
  } else {
    kit += barbell([96, barY], [224, barY]);
  }
  kit += arrow([250, hipY], [250, hipY + (d > 0.4 ? 20 : -20)]);
  return { view: 'side', joints: j, extras: kit, targets: opt.targets || ['quad'] };
}

function sceneRow(phase, opt) {
  const pull = phase;
  const torso = opt.supported ? -70 : -40;
  const hip = opt.supported ? [170, 142] : [168, 150];
  const shoulder = polar(hip, torso, 50);
  const wrist = lerpPt(polar(shoulder, 20, 58), polar(shoulder, 170, 28), pull);
  const elbow = lerpPt(shoulder, wrist, 0.45);
  const j = {
    hip, shoulder, head: polar(shoulder, torso - 10, 20),
    knee: polar(hip, 70, 34), ankle: polar(polar(hip, 70, 34), 95, 32),
    elbow, wrist
  };
  let kit = floor();
  if (opt.supported) {
    kit += bench(92, 150, 100, 14, -18);
  }
  if (opt.kit === 'dumbbell') {
    kit += bench(70, 168, 70, 12, 0) + dumbbell(wrist, 10);
  } else if (opt.kit === 'cable' || opt.kit === 'machine') {
    kit += cableStack(40, 42) + cableLine([47, 160], wrist) + handle(wrist, 22);
  } else if (opt.kit === 'tbar') {
    kit += `<line x1="90" y1="200" x2="${wrist[0]}" y2="${wrist[1]}" stroke="#2A4450" stroke-width="4"/>` + disc(wrist, 8, 'url(#kit)');
  } else {
    kit += barbell([wrist[0] - 36, wrist[1]], [wrist[0] + 50, wrist[1] + 8]);
  }
  kit += arrow(lerpPt(wrist, shoulder, 0.1), lerpPt(wrist, shoulder, 0.55));
  return { view: 'side', joints: j, extras: kit, targets: ['lats', 'back'] };
}

function sceneRaise(phase, opt) {
  const up = opt.dir === 'front' ? lerp(80, -70, phase) : lerp(80, 8, phase);
  const farm = opt.dir === 'front' ? up : 8;
  const j = frontStand(opt.dir === 'front' ? 70 : up, { farmDeg: farm });
  if (opt.dir === 'front') {
    j.elbowL = polar(j.shoulderL, -80 + (1 - phase) * 70, 26);
    j.elbowR = polar(j.shoulderR, -100 - (1 - phase) * 70, 26);
    j.wristL = polar(j.elbowL, -80 + (1 - phase) * 70, 24);
    j.wristR = polar(j.elbowR, -100 - (1 - phase) * 70, 24);
  }
  if (opt.dir === 'rear') {
    const hinge = standingSide(-50, 78, 88, lerp(80, 10, phase), 10, { hip: [160, 150] });
    let kit = floor() + dumbbell(hinge.wrist, 0) + dumbbell(polar(hinge.shoulder, 100, 50), 0);
    kit += arrow(hinge.wrist, polar(hinge.wrist, -90, 18));
    return { view: 'side', joints: hinge, extras: kit, targets: ['rear_delt'] };
  }
  let kit = floor();
  if (opt.kit === 'cable') {
    kit += cableStack(36, 40) + cableLine([47, 158], j.wristL) + handle(j.wristL);
  } else {
    kit += dumbbell(j.wristL, 0) + dumbbell(j.wristR, 0);
  }
  kit += arrow(j.wristR, polar(j.wristR, opt.dir === 'front' ? -90 : 0, 16));
  const targets = opt.dir === 'front' ? ['front_delt'] : ['side_delt'];
  return { view: 'front', joints: j, extras: kit, targets };
}

function sceneCurl(phase, opt) {
  const curl = phase;
  const uarm = 80;
  const farm = lerp(90, -10, curl);
  const j = standingSide(-92, 88, 92, uarm, farm, { farArm: true, uarmBDeg: 100, farmBDeg: lerp(90, 0, curl) });
  let kit = floor();
  if (opt.preacher) {
    kit += bench(118, 132, 70, 14, 28);
  }
  if (opt.kit === 'ezbar') {
    kit += ezbar([j.wristB[0], j.wrist[1]], [j.wrist[0] + 8, j.wrist[1]]);
  } else if (opt.kit === 'cable') {
    kit += cableStack(40, 40) + cableLine([47, 160], j.wrist) + handle(j.wrist);
  } else if (opt.kit === 'barbell') {
    kit += barbell([j.wrist[0] - 40, j.wrist[1]], [j.wrist[0] + 48, j.wrist[1]]);
  } else {
    kit += dumbbell(j.wrist, 20) + (opt.unilateral ? '' : dumbbell(j.wristB, 20));
  }
  kit += arrow(j.wrist, polar(j.wrist, -90, 16));
  return { view: 'side', joints: j, extras: kit, targets: opt.targets || ['biceps'] };
}

function scenePress(phase, opt) {
  const up = phase;
  const sit = opt.sit ? 18 : 0;
  const hip = [160, 150 + sit];
  const shoulder = polar(hip, -92, 48);
  const wrist = lerpPt(polar(shoulder, -20, 22), polar(shoulder, -90, 46), up);
  const elbow = lerpPt(shoulder, wrist, 0.4);
  const j = {
    hip, shoulder, head: polar(shoulder, -92, 20),
    knee: opt.sit ? [196, 168] : polar(hip, 88, 36),
    ankle: opt.sit ? [220, 196] : polar(polar(hip, 88, 36), 92, 34),
    elbow, wrist, shoulderB: [168, shoulder[1]],
    elbowB: [196, elbow[1]], wristB: [188, wrist[1]]
  };
  let kit = floor();
  if (opt.sit) {
    kit += bench(120, 168, 70, 14, 0) + `<rect x="178" y="120" width="12" height="50" fill="#243E4B"/>`;
  }
  if (opt.kit === 'machine') {
    kit += machineFrame(84, 32, 152, 180);
  }
  if (opt.kit === 'dumbbell' || opt.arnold) {
    const rot = opt.arnold ? lerp(80, 0, up) : 0;
    kit += dumbbell(j.wrist, rot) + dumbbell(j.wristB, -rot);
  } else {
    kit += barbell([j.wrist[0] - 48, j.wrist[1]], [j.wristB[0] + 36, j.wrist[1]]);
  }
  kit += arrow(j.wrist, polar(j.wrist, -90, 18));
  return { view: 'side', joints: j, extras: kit, targets: ['front_delt'] };
}

function scenePull(phase, opt) {
  const up = opt.hanging ? phase : 1 - phase;
  const y = opt.hanging ? 86 + (1 - up) * 36 : 132;
  const shoulder = [160, y];
  const hip = [160, y + 48];
  const gripY = opt.hanging ? 42 : 58;
  const wrist = [opt.wide ? 118 : 148, gripY];
  const wristB = [opt.wide ? 202 : 172, gripY];
  const elbow = lerpPt(shoulder, wrist, opt.hanging ? lerp(0.7, 0.35, up) : lerp(0.3, 0.65, phase));
  const j = {
    hip, shoulder, head: [160, y - 20],
    knee: [160, y + 86], ankle: [160, y + 118],
    elbow, wrist, shoulderB: shoulder, elbowB: lerpPt(shoulder, wristB, 0.45), wristB
  };
  if (!opt.hanging) {
    j.knee = [196, 186];
    j.ankle = [186, 214];
    j.hip = [160, 150];
    j.shoulder = [160, 92];
    j.head = [160, 70];
  }
  let kit = opt.hanging ? pullupBar(42) : (cableStack(48, 36) + machineFrame(96, 40, 128, 170) +
    barbell([wrist[0], 58], [wristB[0], 58]));
  if (!opt.hanging) {
    kit += cableLine([59, 42], [160, 58]);
  }
  kit += arrow([230, shoulder[1]], [230, shoulder[1] + (opt.hanging ? (up > 0.5 ? -16 : 16) : 16)]);
  return { view: 'front', joints: frontFromSide(j, opt.wide), extras: kit + floor(), targets: ['lats'] };
}

function frontFromSide(j, wide) {
  const w = wide ? 40 : 22;
  return {
    head: [160, j.head[1]],
    shoulderL: [160 - w, j.shoulder[1]],
    shoulderR: [160 + w, j.shoulder[1]],
    hipL: [148, j.hip[1]],
    hipR: [172, j.hip[1]],
    kneeL: [146, j.knee[1]],
    kneeR: [174, j.knee[1]],
    ankleL: [144, Math.min(214, j.ankle[1])],
    ankleR: [176, Math.min(214, j.ankle[1])],
    elbowL: [j.wrist[0], j.elbow[1]],
    elbowR: [320 - j.wrist[0], j.elbow[1]],
    wristL: [j.wrist[0], j.wrist[1]],
    wristR: [320 - j.wrist[0], j.wrist[1]]
  };
}

function sceneHinge(phase, opt) {
  const hinge = lerp(0, 1, 1 - phase);
  const torso = -92 + hinge * 55;
  const j = standingSide(torso, 78, 88, 70 + hinge * 20, 90, { hip: [168, 150] });
  let kit = floor();
  if (opt.kit === 'dumbbell') {
    kit += dumbbell(j.wrist, 10);
  } else {
    kit += barbell([j.wrist[0] - 30, j.wrist[1]], [j.wrist[0] + 54, j.wrist[1]]);
  }
  kit += arrow(j.head, polar(j.head, torso + 90, 18));
  return { view: 'side', joints: j, extras: kit, targets: opt.targets || ['glute', 'hamstring'] };
}

function sceneBridge(phase, opt) {
  const up = phase;
  const hip = [168, lerp(168, 118, up)];
  const shoulder = [96, 168];
  const knee = [214, 150];
  const ankle = [248, 178];
  const j = {
    hip, shoulder, head: [74, 158], knee, ankle, elbow: [88, 188], wrist: [78, 198]
  };
  if (opt.single) {
    j.kneeB = polar(hip, -70, 40);
    j.ankleB = polar(j.kneeB, -80, 32);
    j.hipB = hip;
  }
  let kit = floor();
  if (opt.bar) {
    kit += barbell([hip[0] - 40, hip[1] - 8], [hip[0] + 44, hip[1] - 8]);
  }
  kit += arrow(hip, [hip[0], hip[1] - 20]);
  return { view: 'side', joints: j, extras: kit, targets: ['glute'] };
}

function sceneCrunch(phase, opt) {
  const curl = phase;
  const shoulder = lerpPt([110, 168], [128, 128], curl);
  const hip = [186, 168];
  const headPt = polar(shoulder, lerp(180, 230, curl), 20);
  const knee = opt.reverse ? lerpPt([230, 168], [210, 120], curl) : [228, 150];
  const ankle = opt.reverse ? lerpPt([268, 168], [200, 92], curl) : [250, 178];
  const j = {
    hip, shoulder, head: headPt, knee, ankle,
    elbow: polar(shoulder, -20, 24), wrist: polar(shoulder, -10, 36)
  };
  let kit = floor();
  if (opt.kit === 'cable') {
    kit += cableStack(44, 36) + cableLine([55, 42], j.wrist) + handle(j.wrist);
  } else if (opt.kit === 'machine') {
    kit += machineFrame(70, 48, 180, 150);
  }
  kit += arrow(shoulder, polar(shoulder, -70, 18));
  return { view: 'side', joints: j, extras: kit, targets: ['abs'] };
}

function sceneBirdDog(phase) {
  const ext = phase;
  const shoulder = [130, 128];
  const hip = [190, 132];
  const j = {
    hip, shoulder, head: [108, 118],
    knee: [210, 168], ankle: [228, 188],
    elbow: [110, 168], wrist: [96, 188],
    kneeB: lerpPt([170, 168], [250, 100], ext),
    ankleB: lerpPt([188, 188], [278, 88], ext),
    hipB: hip,
    shoulderB: shoulder,
    elbowB: lerpPt([150, 168], [70, 100], ext),
    wristB: lerpPt([140, 188], [48, 88], ext)
  };
  const kit = floor() + arrow(j.wristB, polar(j.wristB, 180, 12)) + arrow(j.ankleB, polar(j.ankleB, 0, 12));
  return { view: 'side', joints: j, extras: kit, targets: ['core'] };
}

function sceneDeadBug(phase) {
  const t = phase;
  const j = {
    hip: [168, 150], shoulder: [112, 150], head: [86, 142],
    knee: lerpPt([210, 110], [230, 168], t),
    ankle: lerpPt([248, 88], [268, 168], t),
    elbow: lerpPt([90, 96], [90, 168], 1 - t),
    wrist: lerpPt([78, 70], [78, 188], 1 - t)
  };
  return { view: 'side', joints: j, extras: floor() + arrow(j.ankle, polar(j.ankle, 90, 14)), targets: ['core'] };
}

function sceneLunge(phase, opt) {
  const d = 1 - phase;
  const hip = [168, 128 + d * 22];
  const j = standingSide(-96, 50 + d * 30, 90, 80, 80, {
    hip, split: true, thighBDeg: 120 - d * 10, shinBDeg: 80
  });
  let kit = floor();
  if (opt.kit === 'dumbbell') {
    kit += dumbbell(j.wrist, 0);
  } else if (opt.kit === 'barbell') {
    kit += barbell([hip[0] - 50, hip[1] - 52], [hip[0] + 50, hip[1] - 52]);
  }
  if (opt.step) {
    kit += `<rect x="214" y="186" width="70" height="22" rx="4" fill="url(#kit)"/>`;
  }
  kit += arrow([240, hip[1]], [240, hip[1] + 16]);
  return { view: 'side', joints: j, extras: kit, targets: ['quad', 'glute'] };
}

function sceneCalf(phase, opt) {
  const up = phase;
  const hip = [160, 148 - up * 10];
  const j = standingSide(-92, 88, 92, 80, 80, { hip });
  j.ankle = [160, 210 - up * 12];
  j.knee = [160, 176 - up * 8];
  let kit = floor();
  if (opt.sit) {
    kit += bench(120, 150, 80, 14, 0);
    j.hip = [160, 148];
    j.knee = [210, 150];
    j.ankle = [236, 188 - up * 14];
  } else {
    kit += barbell([110, hip[1] - 52], [210, hip[1] - 52]);
  }
  kit += arrow(j.ankle, [j.ankle[0], j.ankle[1] - 16]);
  return { view: 'side', joints: j, extras: kit, targets: ['calf'] };
}

function sceneLegMachine(phase, opt) {
  const t = phase;
  const hip = [128, 132];
  const knee = [186, 138];
  const ankle = opt.curl
    ? lerpPt([236, 168], [210, 96], t)
    : (opt.extension ? lerpPt([220, 188], [250, 110], t) : lerpPt([230, 80], [110, 160], t));
  const j = {
    hip, shoulder: [118, 88], head: [108, 66],
    knee, ankle, elbow: [148, 108], wrist: [168, 118]
  };
  const kit = machineFrame(64, 36, 200, 176) +
    (opt.press ? `<rect x="168" y="${lerp(70, 150, t)}" width="70" height="14" rx="4" fill="url(#kit)"/>` : disc(ankle, 7, 'url(#kit)')) +
    arrow(ankle, polar(ankle, opt.curl ? -90 : 0, 16));
  const targets = opt.curl ? ['hamstring'] : (opt.extension ? ['quad'] : ['quad', 'glute']);
  return { view: 'side', joints: j, extras: kit, targets };
}

function sceneCardio(phase, opt) {
  if (opt.kind === 'jack') {
    const j = frontStand(lerp(80, 8, phase), { jack: phase > 0.5, squat: 0 });
    return { view: 'front', joints: j, extras: floor() + arrow(j.wristR, polar(j.wristR, -90, 14)), targets: ['cardio'] };
  }
  if (opt.kind === 'mountain') {
    const t = phase;
    const j = {
      hip: [186, 128], shoulder: [118, 118], head: [96, 108],
      knee: lerpPt([200, 168], [150, 90], t), ankle: lerpPt([230, 188], [168, 70], t),
      elbow: [108, 168], wrist: [96, 188],
      kneeB: lerpPt([150, 90], [200, 168], t), ankleB: lerpPt([168, 70], [230, 188], t), hipB: [186, 128]
    };
    return { view: 'side', joints: j, extras: floor(), targets: ['core', 'cardio'] };
  }
  if (opt.kind === 'burpee') {
    const t = phase;
    if (t < 0.5) {
      return scenePushup(0.2, {});
    }
    const j = standingSide(-92, 88, 92, -70, -40, { hip: [160, 140] });
    return { view: 'side', joints: j, extras: floor() + arrow([160, 70], [160, 50]), targets: ['cardio'] };
  }
  const j = standingSide(-92, 88, 92, 50, 20, { hip: [160, 150 + Math.sin(phase * 6) * 4] });
  const kit = floor() +
    `<ellipse cx="160" cy="${j.wrist[1] + 18}" rx="26" ry="8" fill="none" stroke="#2A4450" stroke-width="3"/>` +
    `<ellipse cx="160" cy="${j.wrist[1] + 18}" rx="26" ry="8" fill="none" stroke="#2A4450" stroke-width="3" transform="rotate(70 160 ${j.wrist[1] + 18})"/>`;
  return { view: 'side', joints: j, extras: kit, targets: ['cardio'] };
}

function sceneKickback(phase, opt) {
  const t = phase;
  if (opt.cable) {
    const j = standingSide(-92, 88, 92, 80, 80, { hip: [150, 150], split: true, thighBDeg: lerp(90, 20, t), shinBDeg: 80 });
    const kit = floor() + cableStack(40, 40) + cableLine([47, 170], j.ankleB) + arrow(j.ankleB, polar(j.ankleB, -90, 16));
    return { view: 'side', joints: j, extras: kit, targets: ['glute'] };
  }
  const j = {
    hip: [168, 140], shoulder: [118, 132], head: [98, 122],
    knee: [130, 176], ankle: [118, 198], elbow: [108, 172], wrist: [96, 190],
    kneeB: lerpPt([198, 176], [230, 96], t), ankleB: lerpPt([214, 196], [248, 70], t), hipB: [168, 140]
  };
  return { view: 'side', joints: j, extras: floor() + arrow(j.ankleB, polar(j.ankleB, -90, 14)), targets: ['glute'] };
}

function sceneAbduction(phase, opt) {
  if (opt.kind === 'walk') {
    const j = frontStand(80, { jack: phase > 0.4 });
    const kit = floor() + band(j.ankleL, j.ankleR);
    return { view: 'front', joints: j, extras: kit, targets: ['glute'] };
  }
  if (opt.kind === 'clam') {
    const j = {
      hip: [160, 168], shoulder: [100, 160], head: [78, 150],
      knee: lerpPt([210, 168], [210, 120], phase), ankle: [248, 176],
      elbow: [90, 188], wrist: [78, 198]
    };
    return { view: 'side', joints: j, extras: floor() + arrow(j.knee, [j.knee[0], j.knee[1] - 16]), targets: ['glute'] };
  }
  if (opt.kind === 'machine') {
    const j = frontStand(80, {});
    j.kneeL = lerpPt([140, 186], [96, 170], phase);
    j.kneeR = lerpPt([180, 186], [224, 170], phase);
    j.ankleL = lerpPt([138, 214], [80, 196], phase);
    j.ankleR = lerpPt([182, 214], [240, 196], phase);
    return { view: 'front', joints: j, extras: machineFrame(70, 40, 180, 170) + floor(), targets: ['glute'] };
  }
  const j = {
    hip: [140, 168], shoulder: [90, 150], head: [72, 138],
    knee: lerpPt([190, 168], [190, 108], phase), ankle: lerpPt([230, 168], [230, 78], phase),
    elbow: [86, 178], wrist: [78, 196]
  };
  return { view: 'side', joints: j, extras: floor() + arrow(j.ankle, [j.ankle[0], j.ankle[1] - 16]), targets: ['glute'] };
}

function sceneCore(phase, opt) {
  if (opt.kind === 'pallof') {
    const j = standingSide(-92, 88, 92, lerp(10, -10, phase), 0, { hip: [168, 150] });
    const kit = floor() + cableStack(40, 40) + cableLine([47, 90], j.wrist) + handle(j.wrist, 18) +
      arrow(j.wrist, polar(j.wrist, 0, 16));
    return { view: 'side', joints: j, extras: kit, targets: ['core'] };
  }
  if (opt.kind === 'side') {
    const hip = [160, lerp(168, 132, phase)];
    const j = {
      hip, shoulder: [96, 150], head: [78, 138],
      knee: [210, 176], ankle: [248, 186], elbow: [90, 186], wrist: [78, 198]
    };
    return { view: 'side', joints: j, extras: floor() + arrow(hip, [hip[0], hip[1] - 16]), targets: ['core'] };
  }
  if (opt.kind === 'updown') {
    const t = phase;
    const elbowY = lerp(188, 128, t);
    const j = {
      hip: [196, 128], shoulder: [122, 118], head: [100, 108],
      knee: [230, 168], ankle: [258, 186],
      elbow: [110, elbowY], wrist: [96, t > 0.5 ? 188 : 168]
    };
    return { view: 'side', joints: j, extras: floor(), targets: ['core'] };
  }
  if (opt.kind === 'twist') {
    const t = phase;
    const j = {
      hip: [160, 176], shoulder: [160, 118], head: [160, 96],
      knee: [140, 186], ankle: [128, 210],
      elbow: lerpPt([110, 118], [210, 118], t), wrist: lerpPt([86, 108], [234, 108], t),
      kneeB: [180, 186], ankleB: [192, 210], hipB: [160, 176]
    };
    return { view: 'front', joints: frontStand(40), extras: floor() + dumbbell([lerp(100, 220, t), 120], 0) + arrow([100, 110], [220, 110]), targets: ['core'] };
  }
  if (opt.kind === 'chop') {
    const t = phase;
    const wrist = lerpPt([210, 70], [120, 176], t);
    const j = standingSide(-92, 88, 92, -40, 20, { hip: [160, 150] });
    j.wrist = wrist;
    j.elbow = lerpPt(j.shoulder, wrist, 0.45);
    const kit = floor() + cableStack(44, 36) + cableLine([55, 48], wrist) + handle(wrist);
    return { view: 'side', joints: j, extras: kit, targets: ['core'] };
  }
  if (opt.kind === 'hollow') {
    const t = phase;
    const j = {
      hip: [160, 160], shoulder: lerpPt([120, 168], [110, 140], t), head: lerpPt([96, 168], [86, 122], t),
      knee: lerpPt([200, 168], [220, 128], t), ankle: lerpPt([240, 168], [260, 110], t),
      elbow: [100, 150], wrist: [86, 138]
    };
    return { view: 'side', joints: j, extras: floor(), targets: ['core'] };
  }
  const t = phase;
  const j = {
    hip: lerpPt([186, 128], [210, 128], t), shoulder: [118, 118], head: [96, 108],
    knee: [230, 168], ankle: [258, 186], elbow: [108, 168], wrist: [96, 188]
  };
  return { view: 'side', joints: j, extras: floor() + arrow(j.hip, [j.hip[0] + 16, j.hip[1]]), targets: ['core'] };
}

function sceneMisc(phase, opt) {
  if (opt.kind === 'pullover') {
    const t = phase;
    const shoulder = [140, 128];
    const wrist = lerpPt([86, 70], [168, 118], t);
    const j = {
      hip: [200, 138], shoulder, head: [118, 118],
      knee: [246, 138], ankle: [282, 128],
      elbow: lerpPt(shoulder, wrist, 0.45), wrist
    };
    return { view: 'side', joints: j, extras: bench(92, 138, 150, 14, 0) + dumbbell(wrist, 10), targets: ['chest', 'lats'] };
  }
  if (opt.kind === 'pecdeck') {
    const t = phase;
    const j = frontStand(lerp(10, 70, 1 - t), {});
    return { view: 'front', joints: j, extras: machineFrame(64, 36, 192, 176) + floor(), targets: ['chest'] };
  }
  if (opt.kind === 'facepull') {
    const t = phase;
    const j = standingSide(-92, 88, 92, lerp(10, -20, t), lerp(20, 80, t), { hip: [176, 150] });
    const kit = floor() + cableStack(40, 36) + cableLine([55, 70], j.wrist) + handle(j.wrist, 18);
    return { view: 'side', joints: j, extras: kit, targets: ['rear_delt'] };
  }
  if (opt.kind === 'pushdown') {
    const t = phase;
    const j = standingSide(-92, 88, 92, 80, lerp(-10, 90, t), { hip: [168, 150] });
    const kit = floor() + cableStack(48, 32) + cableLine([59, 42], j.wrist) + handle(j.wrist);
    return { view: 'side', joints: j, extras: kit, targets: ['triceps'] };
  }
  if (opt.kind === 'skull') {
    const t = phase;
    const shoulder = [140, 122];
    const wrist = lerpPt([140, 78], [186, 122], t);
    const j = {
      hip: [196, 132], shoulder, head: [118, 112],
      knee: [242, 132], ankle: [278, 122],
      elbow: [148, 90], wrist
    };
    return { view: 'side', joints: j, extras: bench(90, 136, 160, 14, 0) + barbell([wrist[0] - 36, wrist[1]], [wrist[0] + 40, wrist[1]]), targets: ['triceps'] };
  }
  if (opt.kind === 'ohext') {
    const t = phase;
    const j = standingSide(-92, 88, 92, -90, lerp(20, 100, t), { hip: [160, 150] });
    const kit = floor() + (opt.kit === 'cable' ? cableStack(48, 32) + cableLine([59, 42], j.wrist) : dumbbell(j.wrist, 90));
    return { view: 'side', joints: j, extras: kit, targets: ['triceps'] };
  }
  if (opt.kind === 'kickback_arm') {
    const t = phase;
    const j = standingSide(-40, 78, 88, 20, lerp(90, 10, t), { hip: [168, 150] });
    return { view: 'side', joints: j, extras: floor() + bench(86, 168, 70, 12, 0) + dumbbell(j.wrist, 0), targets: ['triceps'] };
  }
  if (opt.kind === 'wrist') {
    const t = phase;
    const j = standingSide(-92, 88, 92, 80, 90, { hip: [160, 150] });
    j.wrist = [j.elbow[0] + 8, j.elbow[1] + lerp(18, 4, t)];
    return { view: 'side', joints: j, extras: floor() + bench(120, 168, 80, 12, 0) + barbell([j.wrist[0] - 28, j.wrist[1]], [j.wrist[0] + 28, j.wrist[1]]), targets: ['arm'] };
  }
  if (opt.kind === 'hanging') {
    const t = phase;
    const j = {
      hip: [160, lerp(110, 70, t)], shoulder: [160, 58], head: [160, 40],
      knee: [160, lerp(150, 90, t)], ankle: [160, lerp(184, 110, t)],
      elbow: [128, 48], wrist: [118, 42],
      elbowB: [192, 48], wristB: [202, 42], shoulderB: [160, 58]
    };
    const fj = frontFromSide(j, true);
    return { view: 'front', joints: fj, extras: pullupBar(42) + arrow([240, j.knee[1]], [240, j.knee[1] - 16]), targets: ['abs'] };
  }
  if (opt.kind === 'legraise') {
    const t = phase;
    const j = {
      hip: [150, 150], shoulder: [100, 150], head: [78, 142],
      knee: lerpPt([220, 150], [230, 80], t), ankle: lerpPt([260, 150], [250, 48], t),
      elbow: [90, 168], wrist: [80, 186]
    };
    return { view: 'side', joints: j, extras: floor() + arrow(j.ankle, [j.ankle[0], j.ankle[1] - 16]), targets: ['abs'] };
  }
  if (opt.kind === 'tap') {
    const t = phase;
    const j = {
      hip: [190, 124], shoulder: [122, 114], head: [102, 104],
      knee: [228, 168], ankle: [256, 186],
      elbow: [112, 168], wrist: lerpPt([100, 188], [148, 118], t)
    };
    return { view: 'side', joints: j, extras: floor(), targets: ['core'] };
  }
  if (opt.kind === 'hyper') {
    const t = phase;
    const hip = [168, 140];
    const shoulder = lerpPt([168, 188], [168, 88], t);
    const j = {
      hip, shoulder, head: polar(shoulder, 90, 18),
      knee: [210, 128], ankle: [248, 118],
      elbow: polar(shoulder, 20, 24), wrist: polar(shoulder, 10, 36)
    };
    return { view: 'side', joints: j, extras: bench(140, 138, 90, 14, 0) + `<rect x="148" y="150" width="12" height="40" fill="#243E4B"/>` + arrow(shoulder, [shoulder[0], shoulder[1] - 16]), targets: ['back'] };
  }
  if (opt.kind === 'straightarm') {
    const t = phase;
    const j = standingSide(-92, 88, 92, lerp(-20, 70, t), lerp(-20, 70, t), { hip: [170, 150] });
    const kit = floor() + cableStack(48, 32) + cableLine([59, 42], j.wrist) + handle(j.wrist, 22);
    return { view: 'side', joints: j, extras: kit, targets: ['lats'] };
  }
  if (opt.kind === 'inverted') {
    const t = phase;
    const y = 150 - t * 16;
    const j = {
      hip: [200, y + 8], shoulder: [120, y], head: [96, y + 8],
      knee: [240, y + 10], ankle: [278, 96],
      elbow: [118, y + 24], wrist: [116, 88]
    };
    return { view: 'side', joints: j, extras: pullupBar(88) + floor() + arrow([160, y], [160, y - 16]), targets: ['lats', 'back'] };
  }
  if (opt.kind === 'pullthrough') {
    const t = phase;
    const j = standingSide(lerp(-40, -92, t), 78, 88, 80, 90, { hip: [168, 150] });
    const kit = floor() + cableStack(48, 80) + cableLine([59, 190], j.wrist) + handle(j.wrist);
    return { view: 'side', joints: j, extras: kit, targets: ['glute'] };
  }
  if (opt.kind === 'concentration') {
    const t = phase;
    const j = standingSide(-92, 50, 90, 80, lerp(90, 0, t), { hip: [170, 158] });
    j.knee = [210, 168];
    j.ankle = [236, 196];
    return { view: 'side', joints: j, extras: floor() + bench(200, 150, 60, 12, 0) + dumbbell(j.wrist, 20), targets: ['biceps'] };
  }
  return sceneSquat(phase, opt);
}

export function buildScene(pose, phase) {
  const family = pose.family;
  if (family === 'bench_press') return sceneBench(phase, pose);
  if (family === 'fly') return sceneFly(phase, pose);
  if (family === 'pushup') return scenePushup(phase, pose);
  if (family === 'dip') return sceneDip(phase);
  if (family === 'squat') return sceneSquat(phase, pose);
  if (family === 'row') return sceneRow(phase, pose);
  if (family === 'raise') return sceneRaise(phase, pose);
  if (family === 'curl') return sceneCurl(phase, pose);
  if (family === 'press') return scenePress(phase, pose);
  if (family === 'pull') return scenePull(phase, pose);
  if (family === 'hinge') return sceneHinge(phase, pose);
  if (family === 'bridge') return sceneBridge(phase, pose);
  if (family === 'crunch') return sceneCrunch(phase, pose);
  if (family === 'bird_dog') return sceneBirdDog(phase);
  if (family === 'dead_bug') return sceneDeadBug(phase);
  if (family === 'lunge') return sceneLunge(phase, pose);
  if (family === 'calf') return sceneCalf(phase, pose);
  if (family === 'leg_machine') return sceneLegMachine(phase, pose);
  if (family === 'cardio') return sceneCardio(phase, pose);
  if (family === 'kickback') return sceneKickback(phase, pose);
  if (family === 'abduction') return sceneAbduction(phase, pose);
  if (family === 'core') return sceneCore(phase, pose);
  return sceneMisc(phase, pose);
}

export function renderExerciseSvg(entry, phaseName) {
  const pose = entry.pose;
  const cardMap = { start: 0.12, end: 0.88, card: pose.cardPhase == null ? 0.72 : pose.cardPhase };
  const phase = cardMap[phaseName] == null ? 0.72 : cardMap[phaseName];
  const scene = buildScene(pose, phase);
  const figure = scene.view === 'front' ? drawFrontFigure(scene.joints, scene.targets) : drawSideFigure(scene.joints, scene.targets);
  const title = `${entry.name}（${phaseName === 'start' ? '起始' : phaseName === 'end' ? '结束' : '动作'}）`;
  const desc = `原创训练示意图，绿色强调目标肌群；姿势与文字说明一致，未描摹来源不明照片。`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="240" viewBox="0 0 320 240">
<title>${esc(title)}</title>
<desc>${esc(desc)}</desc>
${DEFS}
<ellipse cx="160" cy="124" rx="115" ry="105" fill="#E9F3EF"/>
<path d="M49 83 A116 106 0 0 1 226 34 M260 166 A116 106 0 0 1 102 221" fill="none" stroke="#C5DDD3" stroke-width="1.3"/>
<circle cx="52" cy="80" r="3" fill="#52AD8D"/>
<circle cx="260" cy="168" r="2" fill="#93C7B2"/>
${scene.extras || ''}
${figure}
</svg>
`;
}
