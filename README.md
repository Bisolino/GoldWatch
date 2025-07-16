+ [![Downloads](https://cf.way2muchnoise.eu/full_goldwatch-gw_downloads.svg)](https://www.curseforge.com/wow/addons/goldwatch-gw)


# GoldWatch - Gold Tracker for WoW

**GoldWatch** is a World of Warcraft addon that tracks your gold earnings in real-time during farming sessions. It calculates your gold per hour (GPH) and provides accurate projections, featuring an intelligent "hyperspawn" detection system.

## 📥 Installation
1. Download latest version
2. Extract `GoldWatch` folder to WoW `Interface\AddOns`
3. Launch/reload WoW

## 🚀 Getting Started
1. **Open addon**: Type `/gw` or click minimap icon
2. **Enter dungeon**: Go to your farming location
3. **Start tracking**: Click `Start`
4. **Farm normally**: Kill mobs, loot, complete quests
5. **Sell to NPCs**: Sell all farmed items to vendors
6. **Stop tracking**: Click `Stop` when finished

## ⚙️ Key Features
| Feature | Description |
|---------|-----------|
| 📊 Real-Time Tracking | Monitors every copper earned |
| ⏱️ 60-Min Projection | Estimates hourly earnings at current rate |
| 🗺️ Per-Dungeon Data | Learns your average GPH per location |
| 🚨 Anti-Hyperspawn | Detects abnormal earnings and auto-adjusts |
| 📜 Session History | Stores all sessions with detailed stats |

## 🚨 Anti-Hyperspawn System
**What is hyperspawn?**  
When mobs respawn abnormally fast, creating unrealistic gold patterns. GoldWatch compares current GPH with historical averages.

**Operation modes:**
- 🔔 `Alert`: Notifies with sound/text (default)
- 📉 `Adjust`: Reduces earnings by 30% for realism
- ⏸️ `Pause`: Pauses tracking for 10 minutes

Configure via: `/gw config`

## 💻 Useful Commands
| Command | Function |
|---------|--------|
| `/gw` | Toggle main window |
| `/gw config` | Open settings |
| `/gw summary` | Show session summary in chat |
| `/gw reset` | Reset current session |
| `/zd` | Show current dungeon data |
| `/gw history` | Open session history |

## ❓ FAQ

### 1. What is GoldWatch?
A: An addon that tracks gold earnings in real-time during farming sessions.

### 2. How do I start tracking?
A: Enter dungeon and click `Start` in main window.

### 3. Does it count auction house sales?
A: No, only loot, NPC sales and quest rewards.

### 4. What is Anti-Hyperspawn?
A: System detecting abnormally fast mob respawns and adjusting values.

### 5. How view history?
A: Use `/gw history` or click `History` button.

### 6. Is data saved?
A: Yes, locally in `WTF\Account\<your_account>\SavedVariables`.

### 7. Multi-character support?
A: Yes! Learning data shared, sessions per character.

### 8. Full Command List
| Command | Function |
|---------|--------|
| /gw | Open/close main window |
| /goldwatch | Alternative to open/close main window |
| /gw config | Open addon settings |
| /gw summary | Show current session summary in chat |
| /gw summary all | Show full session history in chat |
| /gw reset | Reset current session (ongoing data) |
| /gw reset data | Delete learning data (dungeon averages) |
| /gw reset all | Delete ALL addon data (requires confirmation) |
| /gw history | Open session history window |
| /zd | Show current dungeon data (average GPH, samples) |
| /zd all | Show data for all recorded dungeons |


---

### Support and Updates
**Author**: Levindo 
**Version**: 1.0.0 
**Compatible with**: WoW Retail (v10.0+)
