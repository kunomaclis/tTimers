# tTimers
Displays time remaining on buffs and debuffs you've cast, as well as the recast timers for your spells and abilities.

## HorizonXI Fork — Version 0.26
This fork adds renderer stability fixes and opt-in Blue Magic debuff tracking for HorizonXI. Blue Magic behavior is still being measured because Horizon uses both explicit application messages and silent debuff riders, with some durations differing from upstream LandSandBoat assumptions.

## Installation
### Users
Download the named `tTimers-v*.zip` asset from the [Releases page](https://github.com/kunomaclis/tTimers/releases). Do not use GitHub's **Download ZIP** or **Source code (zip)** because those archives do not include the required `gdifonts` submodule.

Unzip the asset and place the included `tTimers` folder in your Ashita `addons` directory. Load it with **/addon load tTimers**.

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

**/tt bludebug**<br>
Starts or stops Blue Magic packet capture and opt-in experimental Blue Magic timers.

## Blue Magic Debug Capture
Want to help improve Blue Magic timers?

1. Run **/tt bludebug** when you start playing.
2. Cast Blue Magic normally. Using `/check` on test targets helps.
3. Run **/tt bludebug** again before quitting.
4. Share the log from `config/addons/tTimers/logs/`.

Capture continues across zones. Timers beginning with **~** are experimental guesses shown only while capture is active.

Shared logs include your character name, level, INT, base Blue Magic skill, and equipped item IDs at cast time.

## Contributors
- Thorny — original author
- [Kunomaclis](https://github.com/kunomaclis) — fork maintainer, stability work, and HorizonXI Blue Magic tracking

## Other
You can shift-click any timer to make it immediately disappear.  You can ctrl-click any timer to make it immediately disappear and block that ability/buff/debuff from generating new timers in the future.  A future update will allow unblocking through GUI, but currently unblocking must be done by unloading the addon, editing the config file, and reloading the addon.  So, try not to block anything you don't want to keep blocked.