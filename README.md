# tTimers
Displays time remaining on buffs and debuffs you've cast, as well as the recast timers for your spells and abilities.

## Fork — Version 0.27
This is a fork of [ThornyFFXI/tTimers](https://github.com/ThornyFFXI/tTimers) for Ashita v4. It adds renderer stability fixes and an optional Blue Magic debuff tracker built on LandSandBoat spell data, while preserving Thorny's original authorship and MIT license.

## Installation
### Users
Download the named `tTimers-v*.zip` asset from the [Releases page](https://github.com/kunomaclis/tTimers/releases). Do not use GitHub's **Download ZIP** or **Source code (zip)** because those archives do not include the required `gdifonts` submodule.

1. Unzip `tTimers` into your Ashita `addons` folder, replacing any existing `tTimers` folder.
2. In game, run `/addon reload tTimers` (or `/addon load tTimers`).

Your existing tTimers settings carry over.

### Developers
Clone the repository with its submodule:

```bash
git clone --recursive https://github.com/kunomaclis/tTimers.git
cd tTimers
git config submodule.recurse true
```

For an existing clone with an empty `gdifonts` directory:

```bash
git submodule update --init --recursive
```

## Commands

**/tt**<br>
Opens configuration menu.  This allows you to change themes, alter behavior, etc.

**/tt reposition**<br>
Forces all timer panels visible with max allowed timers, and allows them to be dragged around using the handles.  Bottom justified panels will have a red handle, and top justified panels will have a blue handle.  There is an overlapping area in the default layout allowing you to drag both together by clicking the overlap.

**/tt lock**<br>
Ends reposition mode.

**/tt custom [required: Label] [required: Duration]**<br>
This creates a custom timer with the label and duration specified.  Duration can be specified in full or partial minutes, seconds, or hours by using suffixes s, m, or h.  Example usage:<br>
**/tt custom "PH Repop" 5.5m**<br>
**/tt custom "NM Window" 1h**<br>
**/tt custom "Reminder" 30s**<br>
If no suffix is used, the timer will use the number as seconds.

Enter a specific time in the future in this format HH:MM:SS. Example:
**/tt custom "Timer" 17:13:20**<br>

**/tt blumode**<br>
Turns estimated Blue Magic timers on or off. You can also use the **Blue Magic Estimates** checkbox under Debuffs in the **/tt** menu. The setting is saved per character.

## Blue Magic
![Estimated Head Butt and confirmed Awful Eye timers](docs/images/blu-timers.png)

Blue Magic debuffs land in two ways:

- **Confirmed** — Spells like Sheep Song, Awful Eye, and Frightful Roar tell you when they land. These timers are always on.
- **Estimated (~)** — Spells like Head Butt, Wild Oats, and Bad Breath apply their effect silently on hit. The game never says whether it landed, so these timers start whenever the spell hits. They only appear with **/tt blumode** or the **Blue Magic Estimates** checkbox on.

Both kinds end early if the game reports the effect wearing off or the target dies. Durations use LandSandBoat's base values for Treasures of Aht Urhgan spells (level 75 and under). Resists can shorten the real duration.

Wild Oats, Sprout Smack, Pinecone Bomb, Queasyshroom, Feather Storm, and Battle Dance last longer when cast with Chain Affinity and more TP, or with Azure Lore. Estimated timers account for this.

## Attribution
- Thorny — original author
- [Kunomaclis](https://github.com/kunomaclis) — fork maintainer, stability work, and Blue Magic tracking
- Original addon: [ThornyFFXI/tTimers](https://github.com/ThornyFFXI/tTimers)
- License: [MIT](LICENSE)

Development of this fork included AI-assisted analysis and implementation. Changes were reviewed and playtested by the maintainer.

## Other
You can shift-click any timer to make it immediately disappear.  You can ctrl-click any timer to make it immediately disappear and block that ability/buff/debuff from generating new timers in the future.  A future update will allow unblocking through GUI, but currently unblocking must be done by unloading the addon, editing the config file, and reloading the addon.  So, try not to block anything you don't want to keep blocked.
