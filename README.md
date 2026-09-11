# tTimersBlu
Displays time remaining on buffs and debuffs you've cast, as well as the recast timers for your spells and abilities.

## HorizonXI Fork — Version 0.26
tTimersBlu is a separately installable HorizonXI fork of [ThornyFFXI/tTimers](https://github.com/ThornyFFXI/tTimers). It adds renderer stability fixes and opt-in Blue Magic debuff tracking while preserving Thorny's original authorship and MIT license.

## Installation
### Users
Download the named `tTimersBlu-v*.zip` asset from the [Releases page](https://github.com/kunomaclis/tTimers/releases). Do not use GitHub's **Download ZIP** or **Source code (zip)** because those archives do not include the required `gdifonts` submodule.

Unzip the asset and place the included `tTimersBlu` folder in your Ashita `addons` directory. Load it with **/addon load tTimersBlu**.

tTimersBlu can be installed alongside tTimers, but it starts with independent default settings and panel positions. Use `/ttblu reposition` to arrange it. Both addons accept `/tt`, so use `/ttblu` for tTimersBlu when both are loaded.

### Developers
Clone the repository with its submodule:

```bash
git clone --recursive https://github.com/kunomaclis/tTimers.git tTimersBlu
cd tTimersBlu
git config submodule.recurse true
```

For an existing clone with an empty `gdifonts` directory:

```bash
git submodule update --init --recursive
```

## Commands

**/ttblu**<br>
Opens configuration menu.  This allows you to change themes, alter behavior, etc.

**/ttblu reposition**<br>
Forces all timer panels visible with max allowed timers, and allows them to be dragged around using the handles.  Bottom justified panels will have a red handle, and top justified panels will have a blue handle.  There is an overlapping area in the default layout allowing you to drag both together by clicking the overlap.

**/ttblu lock**<br>
Ends reposition mode.

**/ttblu custom [required: Label] [required: Duration]**<br>
This creates a custom timer with the label and duration specified.  Duration can be specified in full or partial minutes, seconds, or hours by using suffixes s, m, or h.  Example usage:<br>
**/ttblu custom "PH Repop" 5.5m**<br>
**/ttblu custom "NM Window" 1h**<br>
**/ttblu custom "Reminder" 30s**<br>
If no suffix is used, the timer will use the number as seconds.

Enter a specific time in the future in this format HH:MM:SS. Example:
**/ttblu custom "Timer" 17:13:20**<br>

**/ttblu bludebug**<br>
Starts or stops Blue Magic packet capture and opt-in experimental Blue Magic timers.

## Blue Magic Debug Capture
Want to help improve Blue Magic timers?

1. Run **/ttblu bludebug** when you start playing.
2. Cast Blue Magic normally. Using `/check` on test targets helps.
3. Run **/ttblu bludebug** again before quitting.
4. Share the log from `config/addons/tTimersBlu/logs/`.

Capture continues across zones. Timers beginning with **~** are experimental guesses shown only while capture is active.

Shared logs include your character name, level, INT, base Blue Magic skill, and equipped item IDs at cast time.

<details>
<summary>Example log entries (trimmed)</summary>

```text
2026-09-10 18:00:00 +0.001 START addon_version=0.26 capture_version=10
2026-09-10 18:00:08 +8.125 REQUEST cast_id=1 spell=603 spell_name="Wild Oats" target_name="Example Mob" player_level=62 player_int=52 blue_magic_skill_base=212 equipment="00:16557,..."
2026-09-10 18:00:09 +9.010 CANDIDATE cast_id=1 spell=603 spell_name="Wild Oats" target_name="Example Mob" expected_status=138 status_name="VIT Down"
2026-09-10 18:01:09 +69.250 DURATION confidence=candidate cast_id=1 spell=603 spell_name="Wild Oats" target_name="Example Mob" status=138 status_name="VIT Down" seconds=60.240
```

</details>

The `/tt` command remains available as a compatibility alias.

## Attribution
- Thorny — original author
- [Kunomaclis](https://github.com/kunomaclis) — fork maintainer, stability work, and HorizonXI Blue Magic tracking
- Original addon: [ThornyFFXI/tTimers](https://github.com/ThornyFFXI/tTimers)
- License: [MIT](LICENSE)

Development of this fork included AI-assisted analysis and implementation. Changes were reviewed and playtested by the maintainer.

## Other
You can shift-click any timer to make it immediately disappear.  You can ctrl-click any timer to make it immediately disappear and block that ability/buff/debuff from generating new timers in the future.  A future update will allow unblocking through GUI, but currently unblocking must be done by unloading the addon, editing the config file, and reloading the addon.  So, try not to block anything you don't want to keep blocked.