# KSP_Starship-kOS-Interface — version Hiro

A modified build of [KSP_Starship-kOS-Interface](https://github.com/Nubro24/KSP_Starship-kOS-Interface)
by Nubro24, plus a telemetry overlay for the game window.

```
overlay/    ready-to-run KspOverlay.exe and everything it needs
scripts/    kOS flight scripts: booster.ks, starship.ks, tower.ks
```

## Required mods

Tested on this exact set. Other versions may work, but the scripts touch
part modules by name, so a different SEP or SLE build can break them.

| Mod | Version |
| --- | --- |
| kOS | 1.6.0.1 |
| Starship Expansion Project (SEP) | 3.3.0 |
| Starship Launch Expansion (SLE) | 0.6.0 |
| Trajectories | 2.4.5.4 |
| MechJeb 2 | 2.14.3 |

`Trajectories` is not optional: the booster's landing guidance reads its
predicted impact point every frame. `MechJeb 2` flies the ship's orbital
insertion. The overlay itself needs neither — only the two JSON files the
scripts write.

## overlay

A broadcast-style overlay drawn on top of the game window: speed, altitude,
engine grid, propellant bars and a milestone strip — Liftoff, Max Q, Stage Sep,
SECO, Super Heavy landing, Starship landing.

It reads `telemetry.json` and `telemetry_ship.json`, which the kOS scripts
write about ten times per second.

**Setup.** Download the `overlay` folder, open `overlay.config.json` and point
it at the `Ships/Script` folder of your KSP install, then run `KspOverlay.exe`.

## scripts

Drop them into `Ships/Script` of your KSP install. Compiled `.ksm` files are
not included — kOS builds them itself.

- `booster.ks` — Super Heavy: ascent, boostback, glide, landing burn, Mechazilla catch
- `starship.ks` — Starship: ascent, orbit, entry, landing
- `tower.ks` — tower: arms, pushers, stabilizers, command handling

## Credits

Original scripts and flight logic: [Nubro24](https://github.com/Nubro24/KSP_Starship-kOS-Interface).
Mods: Starship Expansion Project by Kari1407, Starship Launch Expansion,
kOS, Trajectories, MechJeb 2 — all by their respective authors.
