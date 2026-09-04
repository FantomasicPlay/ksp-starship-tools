# KSP_Starship-kOS-Interface — version Hiro

A modified build of [KSP_Starship-kOS-Interface](https://github.com/Nubro24/KSP_Starship-kOS-Interface)
by Nubro24, plus a telemetry overlay for the game window.

This repository ships **prebuilt files only** — no C# sources.

```
overlay/    ready-to-run KspOverlay.exe and everything it needs
scripts/    kOS flight scripts: booster.ks, starship.ks, tower.ks
```

## Required mods

Tested on this exact set. Other versions may work, but the scripts touch
part modules by name, so a different SEP or SLE build can break them.

| Mod | Version |
| --- | --- |
| Kerbal Space Program | 1.12.5 |
| kOS | 1.6.0.1 |
| Starship Expansion Project (SEP) | 3.1.0.0 |
| Starship Launch Expansion (SLE) | 0.6.0.0 |
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

This build needs the
**[.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)**.
If you would rather not install it, the archive in
[Releases](../../releases) is self-contained — .NET is bundled inside.

WebView2 Runtime ships with Windows 11. On Windows 10 you may need to install
it separately.

### How milestones behave

A milestone has exactly two states. Until the vehicle reports the event as a
fact, the milestone is never highlighted, and its marker can never sit to the
left of the current time tick — otherwise it reads as "already happened" when
it has not. Before the fact arrives, the marker follows the vehicle's own live
prediction, or, failing that, an estimate scaled by liftoff thrust-to-weight.

## scripts

Drop them into `Ships/Script` of your KSP install. Compiled `.ksm` files are
not included — kOS builds them itself.

- `booster.ks` — Super Heavy: ascent, boostback, glide, landing burn, Mechazilla catch
- `starship.ks` — Starship: ascent, orbit, entry, landing
- `tower.ks` — tower: arms, pushers, stabilizers, command handling

## What is changed compared to the original

- **Raptor thrust is measured in flight** instead of being taken from a
  constant. The constant overstated it by roughly fifteen percent, so the
  landing burn ignition altitude was computed wrong and touchdown came in at
  30 m/s. Measured thrust brought it down to single digits.
- **The turn into the glide attitude** is driven by one closed-loop target
  instead of two open-loop rotations about a frozen axis. The old "up"
  reference degenerated to a zero vector exactly when the vehicle's roof
  reached the zenith — its normal boostback attitude — so roll received an
  arbitrary command and the booster spent the glide twisting it out.
- **Roll is no longer frozen through the burn.** The freeze threshold used to
  latch a 90° error for sixteen seconds of powered flight and defer the
  correction into the glide, where it was visible as the grid fins fighting.
- **Mechazilla catch.** The tower rotation angle is computed by projecting
  along the vehicle's own axis, so its tilt is taken into account, and it is
  latched near the ground with lead extrapolated from its trend. The arm gap
  holds a throat wide enough for the guidance error until the pins arrive,
  then closes with a single explicit close command.
- **Telemetry and flight log.** `telemetry*.json` for the overlay, plus a
  detailed CSV carrying every guidance quantity — that log is what the fixes
  above were found with.

## Credits

Original scripts and flight logic: [Nubro24](https://github.com/Nubro24/KSP_Starship-kOS-Interface).
Mods: Starship Expansion Project by Kari1407, Starship Launch Expansion,
kOS, Trajectories, MechJeb 2 — all by their respective authors.
