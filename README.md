# GuildKPInfo

A World of Warcraft: Vanilla 1.12.1 (Turtle WoW) addon that tracks guild member DKP by parsing officer notes and logs raid loot by parsing raid chat.

## Features

- **DKP Tracker** — Reads officer notes formatted as `<00150>` (5-digit numbers inside angle brackets) and displays each guild member's current DKP.
- **Raid Loot Logger** — Automatically detects item links and DKP values from raid chat messages and logs them per raid.
- **Member List** — Searchable, filterable by class, sortable by name/class/DKP/status.
- **Raid History** — Expandable list of past raids with all looted items, player names and DKP spent.
- **Export** — Copy the full raid log to clipboard in plain text.
- **Minimap Button** — Click to toggle the main window; drag to reposition.
- **pfUI Compatible** — Adopts pfUI's visual style (fonts, colors, backdrop) when available. Works standalone otherwise.
- **Zero Dependencies** — No external libraries required.

## Requirements

- World of Warcraft client **1.12.1** (Turtle WoW)
- Guild members must have their DKP stored in officer notes using the exact format `<00000>` (e.g. `<00150>` = 150 DKP)
- All guild members can read officer notes on Turtle WoW

## Installation

1. Download or clone this repository.
2. Copy the `guildkpinfo` folder into your `Interface\AddOns\` directory.
3. Restart the game or run `/reload`.

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/gkpi` | Toggle the main window |
| `/dkp` | Toggle the main window |

### Members Tab

- **Search box** — Type a name to filter members in real time.
- **Class filter** — Dropdown to show only members of a specific class.
- **Column headers** — Click to sort (click again to reverse direction):
  - **Class** — Sort by class
  - **Name** — Sort alphabetically (colored by class)
  - **DKP** — Sort by DKP amount (default: highest first)
  - **Status** — Sort by online/offline
- **Status bar** — Shows total members, sum of DKP, and online count.

### Raid Log Tab

- Each raid is an expandable header showing date, zone and item count.
- Click a header to expand/collapse and see individual items with player names and DKP spent.
- **Export Log** button copies the full raid history to clipboard.

### Raid Detection

A new raid entry is created automatically when:

1. You are in a raid group (`GetNumRaidMembers() > 0`)
2. You enter a raid instance or change zone while in a raid

Raid chat messages are parsed on `CHAT_MSG_RAID`, `CHAT_MSG_RAID_LEADER` and `CHAT_MSG_RAID_WARNING`. A message is captured when it contains:

- An item link (`|Hitem:...|h[...]|h`)
- The word "DKP" (case insensitive)
- At least one number (extracted as the DKP cost)

Example messages that will be detected:

```
[Benediction] goes to PlayerOne for 150 DKP
PlayerTwo bids 80 DKP on [Staff of Dominance]
```

### Minimap Button

- **Left click** — Open/close the main window.
- **Left click + drag** — Reposition around the minimap. Position is saved between sessions.

## DKP Format

Officer notes must use this exact format (5 digits inside angle brackets):

| Officer Note | DKP |
|---|---|
| `<00150>` | 150 |
| `<00080>` | 80 |
| `<00000>` | 0 |
| `<150>` | **not detected** (must be 5 digits) |

If a member has no officer note or no matching pattern, their DKP displays as 0.

## Saved Variables

Stored in `WTF/Account/<account>/SavedVariables/GuildKPInfo.lua`:

- **raids** — Full raid history with items
- **minimapAngle** — Minimap button position
- **sortColumn** — Last used sort column
- **sortDirection** — Last used sort direction
- **classFilter** — Last used class filter

Data is saved when you log out or run `/reload`. If the game crashes, unsaved data from the current session is lost.

## Configuration

No configuration is needed. Optional integration with [pfUI](https://github.com/shagu/pfUI):

- If pfUI is installed, GuildKPInfo uses its fonts, colors and backdrop style.
- If pfUI is not installed, a built-in dark theme is used as fallback.

## File Structure

```
guildkpinfo/
├── guildkpinfo.toc   # Addon metadata and load order
├── guildkpinfo.lua   # Initialization, events, slash commands
├── core.lua          # DKP parsing, member data, raid chat parser
├── ui.lua            # Main window, minimap button, tab system
├── members.lua       # Members tab: list, search, filter, sort
├── raids.lua         # Raid log tab: raid list, items, export
└── style.lua         # pfUI-like visual style functions
```

## Author

Kayin
