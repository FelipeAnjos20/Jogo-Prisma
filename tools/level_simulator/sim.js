// Simulador do feixe de PRISMA (espelha scripts/light_beam.gd).
// Verifica se cada fase tem solucao, calcula o "par" de rotacoes e gera scripts/levels.gd.
const fs = require("fs");
const path = require("path");

const ROOM = { x0: 40, y0: 100, x1: 1240, y1: 690 };
const HALF = { mirror: 60, splitter: 55, filter: 50 };
const CRYSTAL_R = 28;
const MAX_BOUNCES = 12;
const MAX_SEGMENTS = 64;
const MAX_RAYS = 16;
const MIN_HIT = 0.5;
const OFFSET = 2.0;
const STEP = 15;
const PRISM_R = 30;
const PRISM_SPREAD = 30;

const rad = (d) => (d * Math.PI) / 180;
const cross = (a, b) => a[0] * b[1] - a[1] * b[0];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1]];
const add = (a, b) => [a[0] + b[0], a[1] + b[1]];
const mul = (a, s) => [a[0] * s, a[1] * s];

function segmentOf(pos, rotDeg, half) {
  const d = [Math.cos(rad(rotDeg)), Math.sin(rad(rotDeg))];
  return [sub(pos, mul(d, half)), add(pos, mul(d, half))];
}

function raySeg(o, d, a, b) {
  const s = sub(b, a);
  const div = cross(d, s);
  if (Math.abs(div) < 0.0001) return null;
  const oa = sub(a, o);
  const t = cross(oa, s) / div;
  const u = cross(oa, d) / div;
  if (t <= MIN_HIT || u < 0 || u > 1) return null;
  return t;
}

function rayCircle(o, d, c, r) {
  const oc = sub(o, c);
  const b = 2 * dot(oc, d);
  const cc = dot(oc, oc) - r * r;
  const disc = b * b - 4 * cc;
  if (disc < 0) return null;
  const root = Math.sqrt(disc);
  const t1 = (-b - root) / 2, t2 = (-b + root) / 2;
  const t = t1 > MIN_HIT ? t1 : t2;
  return t > MIN_HIT ? t : null;
}

function buildWorld(level, rots) {
  const items = [];
  level.mirrors.forEach((m, i) => {
    items.push({ type: m.kind, id: "m" + i, seg: segmentOf(m.pos, rots[i], HALF[m.kind]) });
  });
  level.filters.forEach((f, i) => {
    items.push({ type: "filter", id: "f" + i, color: f.color, seg: segmentOf(f.pos, f.rot, HALF.filter) });
  });
  level.obstacles.forEach((ob, i) => {
    const [x, y] = ob.pos, hw = ob.size[0] / 2, hh = ob.size[1] / 2;
    const c = [[x - hw, y - hh], [x + hw, y - hh], [x + hw, y + hh], [x - hw, y + hh]];
    for (let k = 0; k < 4; k++) items.push({ type: "obstacle", id: "o" + i, seg: [c[k], c[(k + 1) % 4]] });
  });
  const w = [[ROOM.x0, ROOM.y0], [ROOM.x1, ROOM.y0], [ROOM.x1, ROOM.y1], [ROOM.x0, ROOM.y1]];
  for (let k = 0; k < 4; k++) items.push({ type: "wall", id: "w", seg: [w[k], w[(k + 1) % 4]] });
  return items;
}

function trace(level, rots) {
  const items = buildWorld(level, rots);
  const lit = new Set();
  const segments = [];
  const e = level.emitter;
  const queue = [{ o: e.pos, d: [Math.cos(rad(e.rot)), Math.sin(rad(e.rot))], color: "white", ignore: null }];
  let rays = 0;

  while (queue.length && rays < MAX_RAYS && segments.length < MAX_SEGMENTS) {
    let { o, d, color, ignore } = queue.shift();
    rays++;
    for (let bounce = 0; bounce <= MAX_BOUNCES && segments.length < MAX_SEGMENTS; bounce++) {
      let best = { t: 1e9, item: null, crystal: -1 };
      for (const it of items) {
        if (it.id === ignore) continue;
        const t = raySeg(o, d, it.seg[0], it.seg[1]);
        if (t !== null && t < best.t) best = { t, item: it, crystal: -1 };
      }
      level.crystals.forEach((c, ci) => {
        const t = rayCircle(o, d, c.pos, CRYSTAL_R);
        if (t !== null && t < best.t) best = { t, item: null, crystal: ci };
      });
      (level.prisms || []).forEach((p, pi) => {
        if (ignore === "p" + pi) return;
        const t = rayCircle(o, d, p.pos, PRISM_R);
        if (t !== null && t < best.t) best = { t, item: null, crystal: -1, prism: pi };
      });
      if (best.t >= 1e9) break;
      const hit = add(o, mul(d, best.t));
      segments.push([o, hit, color]);

      if (best.prism !== undefined) {
        // Prisma: luz branca se divide em vermelho/verde/azul; luz colorida atravessa reta.
        const center = level.prisms[best.prism].pos;
        const pid = "p" + best.prism;
        if (color === "white") {
          const base = Math.atan2(d[1], d[0]);
          [["red", -PRISM_SPREAD], ["green", 0], ["blue", PRISM_SPREAD]].forEach(([col, off]) => {
            const a = base + rad(off);
            queue.push({ o: center, d: [Math.cos(a), Math.sin(a)], color: col, ignore: pid });
          });
          break;
        }
        o = center;
        ignore = pid;
        continue;
      }

      if (best.crystal >= 0) {
        const want = level.crystals[best.crystal].color;
        if (want === "any" || want === color) lit.add(best.crystal);
        break;
      }
      const it = best.item;
      if (it.type === "wall" || it.type === "obstacle") break;
      if (it.type === "filter") {
        if (color !== "white" && color !== it.color) break;
        color = it.color;
        o = add(hit, mul(d, OFFSET));
        ignore = it.id;
        continue;
      }
      const s = sub(it.seg[1], it.seg[0]);
      const len = Math.hypot(s[0], s[1]);
      const n = [-s[1] / len, s[0] / len];
      const r = sub(d, mul(n, 2 * dot(d, n)));
      if (it.type === "splitter") {
        queue.push({ o: add(hit, mul(r, OFFSET)), d: r, color, ignore: it.id });
        o = add(hit, mul(d, OFFSET));
        ignore = it.id;
        continue;
      }
      d = r;
      o = add(hit, mul(d, OFFSET));
      ignore = it.id;
    }
  }
  return { lit, segments, solved: lit.size === level.crystals.length };
}

function solve(level) {
  const base = level.mirrors.map((m) => m.rot);
  const movable = level.mirrors.map((m, i) => (m.can_rotate ? i : -1)).filter((i) => i >= 0);
  let best = null;
  const total = Math.pow(12, movable.length);
  for (let code = 0; code < total; code++) {
    let c = code, cost = 0;
    const rots = base.slice();
    for (const i of movable) {
      const k = c % 12; c = Math.floor(c / 12);
      rots[i] = base[i] + k * STEP;
      cost += Math.min(k, 12 - k);
    }
    if (best && cost >= best.cost) continue;
    if (trace(level, rots).solved) best = { cost, rots };
  }
  return best;
}

const levels = JSON.parse(fs.readFileSync(path.join(__dirname, "levels.json"), "utf8"));
let ok = true;
levels.forEach((lv, i) => {
  const initial = trace(lv, lv.mirrors.map((m) => m.rot));
  const best = solve(lv);
  const tag = `Fase ${i + 1} "${lv.name}"`;
  if (initial.solved) { ok = false; console.log(`${tag}: ERRO - ja comeca resolvida`); }
  if (!best) { ok = false; console.log(`${tag}: ERRO - sem solucao`); return; }
  lv.par = best.cost;
  const norm = (r) => ((((r + 90) % 180) + 180) % 180) - 90;
  lv.solution = best.rots.map(norm);
  console.log(`${tag}: par=${best.cost} solucao=[${lv.solution.join(", ")}]`);
});

// Gera o GDScript com os dados das fases.
const v2 = (p) => `Vector2(${p[0]}, ${p[1]})`;
const str = (s) => JSON.stringify(s);
let out = "extends RefCounted\n\n# Gerado a partir de levels.json e verificado pelo simulador do feixe.\n# Cada fase tem solucao; \"par\" e o menor numero de rotacoes possivel.\n\n\nstatic func get_levels() -> Array:\n\treturn [\n";
for (const lv of levels) {
  out += "\t\t{\n";
  out += `\t\t\t"name": ${str(lv.name)},\n\t\t\t"objective": ${str(lv.objective)},\n\t\t\t"hint": ${str(lv.hint)},\n\t\t\t"par": ${lv.par},\n`;
  out += `\t\t\t"emitter": {"position": ${v2(lv.emitter.pos)}, "rotation": ${lv.emitter.rot}.0},\n`;
  out += "\t\t\t\"crystals\": [\n" + lv.crystals.map((c) => `\t\t\t\t{"position": ${v2(c.pos)}, "color": ${str(c.color)}},\n`).join("") + "\t\t\t],\n";
  out += "\t\t\t\"mirrors\": [\n" + lv.mirrors.map((m) => `\t\t\t\t{"kind": ${str(m.kind)}, "position": ${v2(m.pos)}, "rotation": ${m.rot}.0, "can_rotate": ${m.can_rotate}},\n`).join("") + "\t\t\t],\n";
  out += "\t\t\t\"filters\": [\n" + lv.filters.map((f) => `\t\t\t\t{"position": ${v2(f.pos)}, "rotation": ${f.rot}.0, "color": ${str(f.color)}},\n`).join("") + "\t\t\t],\n";
  out += "\t\t\t\"obstacles\": [\n" + lv.obstacles.map((o) => `\t\t\t\t{"position": ${v2(o.pos)}, "size": ${v2(o.size)}},\n`).join("") + "\t\t\t],\n";
  out += "\t\t\t\"prisms\": [\n" + (lv.prisms || []).map((p) => `\t\t\t\t{"position": ${v2(p.pos)}},\n`).join("") + "\t\t\t],\n";
  out += `\t\t\t"solution": [${lv.solution.map((r) => r.toFixed(1)).join(", ")}],\n`;
  out += "\t\t},\n";
}
out += "\t]\n";

if (ok && process.argv[2]) {
  fs.writeFileSync(process.argv[2], out.replace(/\n/g, "\n"));
  console.log("levels.gd gerado em " + process.argv[2]);
} else if (!ok) {
  process.exitCode = 1;
}

// Preview SVG das fases resolvidas (apenas para conferencia visual).
if (process.argv[3]) {
  const COL = { white: "#ffe98a", red: "#ff5060", green: "#50ff80", blue: "#5a9cff", any: "#9fe0ff" };
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="${levels.length * 360}" viewBox="0 0 1280 ${levels.length * 720}">`;
  levels.forEach((lv, i) => {
    const best = solve(lv);
    const res = trace(lv, best.rots);
    svg += `<g transform="translate(0 ${i * 720})"><rect width="1280" height="720" fill="#0a0f1c"/><rect x="40" y="100" width="1200" height="590" fill="none" stroke="#345"/>`;
    svg += `<text x="50" y="60" fill="#fff" font-size="32">${i + 1}. ${lv.name} (par ${lv.par})</text>`;
    lv.obstacles.forEach((o) => svg += `<rect x="${o.pos[0] - o.size[0] / 2}" y="${o.pos[1] - o.size[1] / 2}" width="${o.size[0]}" height="${o.size[1]}" fill="#a02030"/>`);
    lv.filters.forEach((f) => { const s = segmentOf(f.pos, f.rot, HALF.filter); svg += `<line x1="${s[0][0]}" y1="${s[0][1]}" x2="${s[1][0]}" y2="${s[1][1]}" stroke="${COL[f.color]}" stroke-width="14" opacity="0.5"/>`; });
    res.segments.forEach((s) => svg += `<line x1="${s[0][0]}" y1="${s[0][1]}" x2="${s[1][0]}" y2="${s[1][1]}" stroke="${COL[s[2]]}" stroke-width="4"/>`);
    lv.mirrors.forEach((m, k) => { const s = segmentOf(m.pos, best.rots[k], HALF[m.kind]); svg += `<line x1="${s[0][0]}" y1="${s[0][1]}" x2="${s[1][0]}" y2="${s[1][1]}" stroke="${m.kind === "splitter" ? "#c0a0ff" : m.can_rotate ? "#dde" : "#79a"}" stroke-width="8"/>`; });
    (lv.prisms || []).forEach((p) => svg += `<polygon points="${p.pos[0]},${p.pos[1] - 32} ${p.pos[0] + 28},${p.pos[1] + 18} ${p.pos[0] - 28},${p.pos[1] + 18}" fill="none" stroke="#b8b8ff" stroke-width="4"/>`);
    lv.crystals.forEach((c, k) => svg +=`<circle cx="${c.pos[0]}" cy="${c.pos[1]}" r="28" fill="${COL[c.color]}" opacity="${res.lit.has(k) ? 1 : 0.3}"/>`);
    svg += `<polygon points="${lv.emitter.pos[0] - 26},${lv.emitter.pos[1] - 20} ${lv.emitter.pos[0] - 26},${lv.emitter.pos[1] + 20} ${lv.emitter.pos[0] + 26},${lv.emitter.pos[1]}" fill="orange"/></g>`;
  });
  fs.writeFileSync(process.argv[3], svg + "</svg>");
}
