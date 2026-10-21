#!/usr/bin/env python3
"""Tải tuyến/trạm xe buýt TP.HCM từ OpenStreetMap (Overpass API, ODbL) và
đóng gói thành assets/data/hcm_bus.json cho app chạy offline.

Dữ liệu © OpenStreetMap contributors, giấy phép ODbL 1.0.
Chạy: python3 tools/build_data.py [--raw raw.json]
"""
import json, math, sys, time, urllib.request, urllib.parse, os

BBOX = (10.35, 106.35, 11.50, 107.60)  # S,W,N,E: TP.HCM (gồm Bình Dương, BR-VT cũ)
QUERY = f"""[out:json][timeout:300];
relation["type"="route"]["route"="bus"]({BBOX[0]},{BBOX[1]},{BBOX[2]},{BBOX[3]})->.r;
.r out geom;
node(r.r);
out tags;"""
ENDPOINTS = ["https://overpass-api.de/api/interpreter",
             "https://overpass.kumi.systems/api/interpreter"]
UA = "hcm-bus-data-builder/0.1 (+https://github.com/gooduselabs/hcm-bus)"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "hcm_bus.json")


def fetch():
    data = urllib.parse.urlencode({"data": QUERY}).encode()
    for ep in ENDPOINTS:
        try:
            req = urllib.request.Request(ep, data=data, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=400) as r:
                return json.load(r)
        except Exception as e:  # thử endpoint kế tiếp
            print("Lỗi", ep, e, file=sys.stderr)
            time.sleep(5)
    raise SystemExit("Không tải được dữ liệu Overpass")


def chain(ways):
    """Nối các đoạn way thành 1 polyline, tự đảo chiều khi cần."""
    line = []
    for w in ways:
        if len(w) < 2:
            continue
        if not line:
            line = list(w); continue
        if line[-1] == w[0]: line += w[1:]
        elif line[-1] == w[-1]: line += w[::-1][1:]
        elif len(line) and line[0] == w[-1] and len(line) == len(ways[0]):
            line = w + line[1:]
        elif line[0] == w[0] and len(line) == len(ways[0]):
            line = w[::-1] + line[1:]
        else: line += w
    return line


def simplify(pts, eps=0.00008):
    """Douglas-Peucker (độ) để giảm kích thước asset."""
    if len(pts) < 3: return pts
    def d(p, a, b):
        if a == b: return math.dist(p, a)
        (x, y), (x1, y1), (x2, y2) = p, a, b
        return abs((y2-y1)*x - (x2-x1)*y + x2*y1 - y2*x1) / math.dist(a, b)
    keep = [False]*len(pts); keep[0] = keep[-1] = True
    stack = [(0, len(pts)-1)]
    while stack:
        s, e = stack.pop(); dm, idx = 0, 0
        for i in range(s+1, e):
            dd = d(pts[i], pts[s], pts[e])
            if dd > dm: dm, idx = dd, i
        if dm > eps:
            keep[idx] = True; stack += [(s, idx), (idx, e)]
    return [p for p, k in zip(pts, keep) if k]


def build(raw):
    stops, routes = {}, []
    names = {str(e["id"]): (e.get("tags", {}).get("name:vi") or e.get("tags", {}).get("name") or "")
             for e in raw.get("elements", []) if e["type"] == "node"}
    for rel in raw.get("elements", []):
        if rel["type"] != "relation": continue
        t = rel.get("tags", {})
        ways, sids = [], []
        for m in rel.get("members", []):
            role = m.get("role", "")
            if m["type"] == "node" and role.startswith(("stop", "platform")) and "lat" in m:
                sid = str(m["ref"])
                if sid not in stops:
                    stops[sid] = {"id": sid, "name": "", "lat": round(m["lat"], 6), "lon": round(m["lon"], 6)}
                if not sids or sids[-1] != sid: sids.append(sid)
            elif m["type"] == "way" and role in ("", "forward", "backward") and "geometry" in m:
                ways.append([(round(g["lat"], 6), round(g["lon"], 6)) for g in m["geometry"]])
        if len(sids) < 2: continue
        geom = simplify(chain(ways))
        routes.append({
            "id": str(rel["id"]), "ref": t.get("ref", ""), "name": t.get("name", ""),
            "from": t.get("from", ""), "to": t.get("to", ""), "operator": t.get("operator", ""),
            "interval": t.get("interval", ""), "opening_hours": t.get("opening_hours", ""),
            "fee": t.get("charge", t.get("fee", "")), "colour": t.get("colour", ""),
            "stops": sids, "geom": [[round(a, 5), round(b, 5)] for a, b in geom]})
    for sid, st in stops.items():
        st["name"] = names.get(sid, "")
    return stops, routes


def main():
    if "--raw" in sys.argv and os.path.exists(sys.argv[-1]):
        raw = json.load(open(sys.argv[-1]))
    else:
        raw = fetch()
        if "--raw" in sys.argv: json.dump(raw, open(sys.argv[-1], "w"))
    stops, routes = build(raw)
    used = {s for r in routes for s in r["stops"]}
    out = {"generated": time.strftime("%Y-%m-%d"),
           "attribution": "© OpenStreetMap contributors (ODbL 1.0)",
           "stops": [stops[s] for s in sorted(used)],
           "routes": sorted(routes, key=lambda r: (len(r["ref"]), r["ref"]))}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(out['routes'])} tuyến, {len(out['stops'])} trạm -> {OUT}")


if __name__ == "__main__":
    main()
