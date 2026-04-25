# Brewmaster Pro

A polished Brewmaster Monk helper for World of Warcraft (Midnight / TWW 12.x).
Designed to put the information a Brewmaster actually needs — stagger pool,
incoming tick rate, and Purifying Brew availability — in one configurable
bar that reacts to the moment-to-moment decisions of the spec.

![interface 12.0.5](https://img.shields.io/badge/Interface-12.0.5-blue) ![license MIT](https://img.shields.io/badge/License-MIT-green) ![spec brewmaster](https://img.shields.io/badge/Spec-Brewmaster-009f5b)

## Features

- **Stagger bar** — moveable, scalable, with overflow support for high-content
  pulls where the pool exceeds 100% of max HP
- **Tick rate display** — shows incoming damage from stagger as `% HP / sec`,
  derived from the live debuff so it adapts automatically to the
  *Bob and Weave* talent (10s → 15s decay)
- **Purifying Brew tracker** — Purifying Brew icon + charge counter
  (`2/2`, `1/2 12s`, `0/2 8s`) next to the bar, with instant-refresh on cast
  via `SPELL_UPDATE_CHARGES`
- **Smart sound alert** — plays only when the stagger threshold is crossed
  *and* a Purifying Brew charge is actually available; no nag when nothing
  can be done about it
- **Critical flash** — distinct red border when Heavy stagger meets 0 PB
  charges, signalling "use Celestial Brew / Fortifying Brew instead"
- **Tooltip diagnostics** — current stagger, max HP, tick rate, decay
  duration, PB charges and recharge timer
- **Display modes** — bar only, icon only, or icon + bar; per-spell stagger
  level icon (Light / Moderate / Heavy)
- **Polished options window** — Brewmaster jade theme with smooth
  animations, scrollable sound dropdown, instant Reset that actually
  refreshes the visible controls

## Slash commands

- `/brew` or `/brewmasterpro` — open / close the options window
- `/brew sound` — preview the currently selected alert sound

## Installation

### Via CurseForge App
Search for *Brewmaster Pro* and click Install.

### Manual
1. Download the latest release from
   [GitHub Releases](https://github.com/Antrakt92/BrewmasterPro/releases)
2. Extract the `BrewmasterPro` folder into
   `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart the game, or `/reload`

## Recommended defaults

| Setting | Value | Why |
| --- | --- | --- |
| Sound threshold | 50% | Purifying Brew clears 50% of pool — math-optimal trigger |
| Smart alert | On | Suppresses sound when no PB charge is ready |
| Critical flash | On | Visually distinguishes "purify now" from "use backup mit" |
| Show tick rate | On | Lets you read incoming damage in HP terms, not raw numbers |
| Show PB charges | On | One glance covers stagger + your reaction tool |
| Flash threshold | 100% | Flashes the border once the pool exceeds your max HP |

For *Master of Harmony* with *Mantra of Purity* (Purifying Brew clears 60%
instead of 50%), bump Sound threshold to 60%.

## Credits

Brewmaster Pro is a fork of
[MonkStaggerBarPrime](https://www.curseforge.com/wow/addons/monkstaggerbarprime)
by **bljakk**, which itself was based on earlier work by **Roffe** and
**Claude**. Substantial rewrite by **antrakt92** focused on Brewmaster-specific
mechanics — Purifying Brew integration, smart alerts, tick-rate calculation,
talent-aware decay duration, and a Brewmaster-themed UI overhaul.

Released under the MIT License — see [LICENSE](./LICENSE).

## Contributing

Bug reports and feature requests welcome via
[GitHub Issues](https://github.com/Antrakt92/BrewmasterPro/issues).
