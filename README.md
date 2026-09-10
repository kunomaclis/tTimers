# tTimers
Displays time remaining on buffs and debuffs you've cast, as well as the recast timers for your spells and abilities.

## HorizonXI Fork — Version 0.26
This fork adds renderer stability fixes and opt-in Blue Magic debuff tracking for HorizonXI. Blue Magic behavior is still being measured because Horizon uses both explicit application messages and silent debuff riders, with some durations differing from upstream LandSandBoat assumptions.

## Installation
Download the release zip(**on the right sidebar, do not click code..download as zip**). Extract directly to your Ashita directory(the folder with ashita-cli.exe in it!). Everything should fall into place. Load the addon with **/addon load tTimers**.

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
Blue Magic uses two observable behaviors on HorizonXI:

- Confirmed timers start when Horizon explicitly reports that a debuff landed.
- Experimental timers start from a successful damage result when the associated debuff rider is silent.

Experimental timer names begin with **~** because damage does not guarantee that the rider passed its separate resistance check. They are created only for the local player's casts and only while **/tt bludebug** is active. Wear-off messages, target death, entity removal, zoning, or stopping capture clear them.

Current experimental timers include Head Butt, Ice Break, Wild Oats, Battle Dance, Terror Touch, Pinecone Bomb, Sprout Smack, Queasyshroom, Feather Storm, and Poison Breath.

Capture logs are written to:

`config/addons/tTimers/logs/`

One capture file can remain active across multiple zones. Zoning writes a summary, clears zone-specific correlation state, and continues in the same file. Run **/tt bludebug** again at the end of the session to write the final summary and close the file. Normal addon unload also closes an active capture.

The diagnostic records Blue Magic action results, wear-off messages, `/check` results, base Blue Magic skill, INT, TP, and equipped item IDs. This data is used to validate Horizon-specific status IDs, duration models, and silent-rider false-positive rates.

## Contributors
- Thorny — original author
- [Kunomaclis](https://github.com/kunomaclis) — fork maintainer, stability work, and HorizonXI Blue Magic tracking

## Other
You can shift-click any timer to make it immediately disappear.  You can ctrl-click any timer to make it immediately disappear and block that ability/buff/debuff from generating new timers in the future.  A future update will allow unblocking through GUI, but currently unblocking must be done by unloading the addon, editing the config file, and reloading the addon.  So, try not to block anything you don't want to keep blocked.