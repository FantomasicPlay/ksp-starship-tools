"""
Находит центры и радиусы кружков-сопел на картинке-референсе и печатает
готовые координаты для оверлея (в системе 0..120, как в svg).

Запуск:  python detect-engines.py ui/img/engines-booster.png [ожидаемое_число]

Работает без OpenCV: бинаризует картинку, размечает связные области
(заливкой), отбрасывает мусор по площади и круглости.
"""
import sys, json, math
from collections import deque
from PIL import Image


def load_mask(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    # непрозрачный и достаточно светлый пиксель считаем "чернилами"
    mask = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 60 and (r + g + b) / 3 > 110:
                mask[y * w + x] = 1
    return mask, w, h


def blobs(mask, w, h):
    seen = bytearray(w * h)
    out = []
    for y0 in range(h):
        for x0 in range(w):
            i0 = y0 * w + x0
            if not mask[i0] or seen[i0]:
                continue
            q = deque([i0])
            seen[i0] = 1
            pts = []
            while q:
                i = q.popleft()
                x, y = i % w, i // w
                pts.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if mask[j] and not seen[j]:
                            seen[j] = 1
                            q.append(j)
            out.append(pts)
    return out


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    path = sys.argv[1]
    want = int(sys.argv[2]) if len(sys.argv) > 2 else None

    mask, w, h = load_mask(path)
    comps = blobs(mask, w, h)
    if not comps:
        print("на картинке ничего не найдено")
        return

    cand = []
    for pts in comps:
        n = len(pts)
        if n < 12:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        cx, cy = sum(xs) / n, sum(ys) / n
        bw, bh = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
        if bw == 0 or bh == 0:
            continue
        aspect = bw / bh
        if not (0.65 < aspect < 1.55):          # не круг
            continue
        r = (bw + bh) / 4
        cand.append((n, cx, cy, r))

    if not cand:
        print("кружков не распознано — проверь, что фон контрастный")
        return

    # если знаем ожидаемое число — берём самые крупные подходящие
    cand.sort(key=lambda c: -c[0])
    if want:
        cand = cand[:want]

    cxs = [c[1] for c in cand]
    cys = [c[2] for c in cand]
    mx, my = sum(cxs) / len(cxs), sum(cys) / len(cys)
    span = max(max(cxs) - min(cxs), max(cys) - min(cys))
    rad = sum(c[3] for c in cand) / len(cand)
    scale = 76.0 / (span + 2 * rad)          # вписываем в круг радиуса ~38 из 120

    items = []
    for _, cx, cy, r in cand:
        items.append({
            "x": round(60 + (cx - mx) * scale, 2),
            "y": round(60 + (cy - my) * scale, 2),
            "r": round(r * scale, 2),
        })
    # сверху вниз, слева направо — чтобы порядок подсветки был предсказуем
    items.sort(key=lambda p: (round(p["y"], 1), p["x"]))

    print(f"найдено кружков: {len(items)}   средний радиус в svg: {items[0]['r']}")
    out = path.rsplit(".", 1)[0] + ".json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=1)
    print("координаты записаны в", out)


if __name__ == "__main__":
    main()
