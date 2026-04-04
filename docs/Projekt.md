Jasne! Poniżej masz **pełny, scalony GDD z roadmapą i systemem łodzi** w formacie Markdown, gotowy do wklejenia do Visual Studio / Copilota. Wszystko jest uporządkowane i spójne:

---

````md id="fishing_extraction_gdd_full"
# 🎣 Fishing Extraction (Chill PvP) – Full GDD + Roadmap

---

# 1. 🎮 GAME OVERVIEW

## 1.1 High Concept
Multiplayerowa gra wędkarska typu extraction, łącząca:
- relaksujące łowienie
- decyzje ryzyka
- lekkie PvP bez frustracji

Inspiracje:
- Escape from Tarkov (extraction loop)
- Stardew Valley (chill vibe)

---

## 1.2 Core Pillars

1. 🎣 Relaxing Core – przyjemne łowienie i eksploracja
2. ⚠️ Meaningful Risk – decyzje mają realne konsekwencje
3. 😈 Soft PvP – gracze przeszkadzają, nie niszczą
4. 🔁 Always Progress – brak totalnej straty, ciągła progresja

---

# 2. 🔄 CORE GAMEPLAY LOOP

```pseudo
START RUN
  ↓
Spawn player with gear + boat loadout
  ↓
Explore map
  ↓
Fish (skill-based minigame)
  ↓
Collect fish + items
  ↓
Player interactions (PvP / PvE)
  ↓
Decision: extract vs continue
  ↓
Extraction OR fail
  ↓
Return to hub
  ↓
Sell → upgrade → modify boat
END
````

---

# 3. 🧩 CORE SYSTEMS

## 3.1 Fishing System

* States: Idle → Casting → Waiting → Hooked → Fighting → Catch/Escape
* Variables: tension, fish stamina, line strength, timing
* Skill-based minigame wpływa na sukces złowienia

---

## 3.2 Fish System

```pseudo
class Fish:
    rarity
    weight
    value
    behavior_type
    stamina
    preferred_bait
    time_of_day
```

### Rarity Table

* Common 50%
* Uncommon 25%
* Rare 15%
* Epic 8%
* Legendary 2%

---

## 3.3 Inventory System

```pseudo
class Inventory:
    slots
    protected_slots
    items[]
```

* limit slotów
* decyzje co zabrać
* presja wyboru

---

## 3.4 Economy System

```pseudo
value = base_value * weight_modifier * quality_modifier * freshness_modifier
```

* Run outcome: fail → keep 40–70%, success → 100%
* Reward structure: Common → 10–30, Rare → 100–200, Legendary → 1000+

---

## 3.5 Loss System (Soft Loss)

* Zachowujesz część loot’u, najlepiej jedną największą rybę
* Auto-odzysk ~40%, rescue płatne ~70%

---

## 3.6 PvP System (Soft)

* fish steal (częściowy)
* sabotage (minor debuff)
* spot contest
* extraction race
* brak instant kill i pełnej straty loot’u

---

## 3.7 Extraction System

```pseudo
class ExtractionPoint:
    type (static, dynamic, hidden, emergency)
    location
    active_time
    capacity
```

* Static: zawsze dostępne
* Dynamic: losowe spawn
* Hidden: odkrywane
* Emergency: końcówka rundy, wysoki stres

---

## 3.8 Risk System

```pseudo
risk_level = loot_value + time_in_match + weather_severity + player_density
```

* Im więcej loot’u / dłużej na mapie → większe ryzyko

---

## 3.9 World System

* dynamiczny day/night cycle
* pogoda: clear / fog / storm
* fish spawn zones, hotspoty

---

# 4. 🧠 PLAYER PROGRESSION

## 4.1 Gear System

```pseudo
class Gear:
    rod
    reel
    bait
    boat
```

* Tiery: Basic / Mid / High / Pro
* Efekty: lepsze ryby, szybsze łowienie, większa kontrola

---

## 4.2 Meta Progression

* unlock gear
* upgrade stats
* expand inventory
* unlock maps

---

## 4.3 Anti-Frustration

* luck boost po failach
* starter safety runs
* comeback multiplier

---

# 5. 🚤 BOAT SYSTEM

## 5.1 Overview

* Platforma gracza
* Porusza się po mapie, łowi, korzysta z Boat Items
* Decyzje wpływają na styl gry

---

## 5.2 Boat Class

```pseudo
class Boat:
    position
    velocity
    durability
    slots = {
        engine_slot,
        sonar_slot,
        utility_slot_1,
        utility_slot_2,
        special_slot
    }
    equipped_items[]
```

---

## 5.3 Controls

* movement (forward/backward/turn)
* drift / inertia
* wpływ pogody na sterowanie

---

## 5.4 Damage / Failure

* kolizje, przeciążenie, burza

```pseudo
if durability <= 0:
    trigger_emergency_state()
```

---

# 6. 💎 BOAT UNIQUE ITEM SYSTEM

## 6.1 Overview

* Moduły łodzi zmieniają gameplay
* Dodają buildy i decyzje strategiczne

---

## 6.2 Item Structure

```pseudo
class BoatItem:
    name
    rarity
    slot_type
    bonus_effect
    penalty_effect
    cooldown
```

---

## 6.3 Slot Types

* engine_slot
* sonar_slot
* utility
* special

---

## 6.4 Design Rule

```pseudo
if item_has_bonus:
    item_must_have_penalty = true
```

---

## 6.5 Example Items

### Movement

```pseudo
SilentEngine:
    +invisible_on_minimap
    -15% speed
OverdriveMotor:
    +40% speed
    chance_of_failure
```

### Fishing

```pseudo
PrecisionHook:
    +perfect_catch_bonus
    harder_timing
AutoReelAssist:
    easier_fishing
    lower_quality
```

### PvP

```pseudo
LineCutterDrone:
    can_sabotage_players
    cooldown = 60s
DecoyBuoy:
    create_fake_hotspot
```

### Risk / Economy

```pseudo
InsuranceBox:
    +1 protected_slot
    -10% total_value
GreedyNet:
    +50% fish_value
    -escape_chance
```

### Environment

```pseudo
StormAttractor:
    +rare_spawn
    +storm_risk
```

---

## 6.6 Build Examples

* stealth build
* greedy build
* PvP troll build
* safe chill build

---

## 6.7 Loot & Progression

* źródła: run loot, eventy, crafting late-game
* trade-off i ryzyko przy utracie itemów

---

## 6.8 MVP Scope

* 3 sloty, 5–8 itemów, brak craftingu

---

# 7. 🌐 MULTIPLAYER

* Host-authoritative / później dedicated server
* Sync: player pos, boat pos, fish state, extraction state
* Low precision network, focus na gameplay

---

# 8. 🗺️ MAP DESIGN

* hotspoty centralne
* outer safe zones
* distributed extraction points
* flow: early → explore, mid → fish + encounters, late → extraction rush

---

# 9. 🎨 UI SYSTEMS

* HUD: stamina, tension, inventory, minimap
* Post-run: caught fish, lost fish, earnings, bonuses

---

# 10. 🚀 ROADMAP

## Phase 1 – Prototype

* movement
* fishing
* basic boat
* 1 item slot

## Phase 2 – Core

* full boat system
* 3 slots, 5 items
* economy

## Phase 3 – PvE

* AI
* events
* legendary fish

## Phase 4 – Multiplayer

* sync boats
* PvP interactions
* shared items

## Phase 5 – Polish

* balancing items
* UX
* feedback

---

# 11. 🧪 MVP

* 1 mapa
* 1 łódź
* 3 itemy
* basic extraction
* singleplayer

---

# 12. 📁 FILE STRUCTURE (GODOT)

```pseudo
/scenes
  player.tscn
  boat.tscn
  fish.tscn
  world.tscn

/scripts
  player.gd
  boat.gd
  boat_item.gd
  fishing_system.gd
  inventory.gd
  economy.gd
```

---

# 🔑 FINAL IDEA

Gra opiera się na:

* decyzjach
* ryzyku
* buildach łodzi
* „Jeszcze jeden run”

```

---

```
