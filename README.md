# HealerAlerts

HealerAlerts is a lightweight, purpose-built addon for World of Warcraft: Wrath of the Lich King (3.3.5) that automatically calls out your healer's status to your group — so no one is ever caught off guard mid-pull.

When your mana gets low, your health drops, or you die, the addon sends a message to your group chat automatically. No buttons to press, no macros to set up.

---

## What It Announces

| Event | Default Message |
|---|---|
| Low on mana | `[HealerAlerts] PlayerName is Low on Mana! (28%)` |
| Out of mana | `[HealerAlerts] PlayerName is Out of Mana! (8%)` |
| Low on health | `[HealerAlerts] PlayerName is Low on Health! (22%)` |
| Healer death | `[HealerAlerts] Healer PlayerName has died!` |
| Healer has aggro | `[HealerAlerts] PlayerName has aggro!` |

---

## Smart Chat Channel

HealerAlerts automatically picks the right chat channel based on where you are — you never need to configure this manually:

| Situation | Where it announces |
|---|---|
| In a raid | Raid chat |
| In a party or dungeon | Party chat |
| In a battleground | Battleground chat |
| Solo (not grouped) | Yell |
| Solo with "group only" enabled | Silent (no announcement) |

---

## Settings

All settings are available in-game via **Interface Options → HealerAlerts**, or via slash commands.

### Only Announce when in Group
**Default: Off**

When enabled, HealerAlerts will stay silent if you are not in a party, raid, or battleground. Useful if you don't want yell announcements while questing or farming solo.

### Announce in Battleground
**Default: On**

When enabled, alerts are sent to Battleground chat while you are in a PvP instance (battleground or arena). Turn this off if you prefer to keep your status private during PvP.

### Enable Low Mana Alert
**Default: On**

Announces when your mana drops below the configured threshold. This is the early warning — your group will know before you actually run out.

### Low Mana Threshold
**Default: 30%**

The mana percentage at which the Low Mana alert fires. For example, at 30% you'll get a warning with plenty of mana still remaining to finish a cast or two.

### Enable Out of Mana Alert
**Default: On**

Announces when your mana drops critically low (below the Out of Mana threshold). This is the urgent callout — healers are nearly empty and need an innervate, mana tide, or a break in combat.

### Out of Mana Threshold
**Default: 10%**

The mana percentage that triggers the Out of Mana alert. Kept separate from Low Mana so your group gets two distinct warnings with different urgency.

### Enable Low Health Alert
**Default: On**

Announces when your own health drops below the configured threshold. Useful when your healer is being attacked and the rest of the group may not notice.

### Low Health Threshold
**Default: 30%**

The health percentage that triggers the Low Health alert.

### Announcement Cooldown
**Default: 30 seconds**

The minimum time between any two announcements. This prevents the chat from being spammed if your mana fluctuates around the threshold repeatedly. After each combat encounter ends, the cooldown resets automatically so the first pull of a new fight is never suppressed.

---

## Slash Commands

Open the settings panel in-game:
```
/ha
```

Toggle individual alerts or adjust thresholds directly from chat:

| Command | What it does |
|---|---|
| `/ha lowmana` | Toggle the Low Mana alert on/off |
| `/ha oom` | Toggle the Out of Mana alert on/off |
| `/ha lowhealth` | Toggle the Low Health alert on/off |
| `/ha battleground` | Toggle Battleground announcements on/off |
| `/ha setmana 25` | Set the Low Mana threshold to 25% |
| `/ha setoom 5` | Set the Out of Mana threshold to 5% |
| `/ha sethealth 20` | Set the Low Health threshold to 20% |

---

## Installation

### From GitHub

1. Go to the repository page on GitHub
2. Click the green **Code** button, then choose **Download ZIP**
3. Extract the ZIP file on your computer
4. Inside the extracted folder, find the **`HealerAlerts`** folder (it contains `HealerAlerts.lua` and `HealerAlerts.toc`)
5. Move that **`HealerAlerts`** folder into your WoW addons directory:
   - **Windows:** `C:\Program Files (x86)\World of Warcraft\_classic_wotlk_\Interface\AddOns\`
   - The path may vary depending on where your WoW client is installed
6. Launch WoW (or reload if already logged in with `/reload`)
7. At the character select screen, click **AddOns** and confirm HealerAlerts is listed and enabled

> The addon saves your settings automatically — you only need to configure it once per character.
