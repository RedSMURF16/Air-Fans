<h1 align="center">Air Fans</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=WiIfoOwYL3E"><img src="https://img.youtube.com/vi/WiIfoOwYL3E/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds a fully dynamic air fan system to Counter-Strike 1.6.
Fans can be placed, managed and configured during gameplay with runtime control over visibility, team access, activation states and pushing strength.
- Create and remove air fans during gameplay via an in-game menu
- Multiple fan sizes with individual models and configurable push ranges
- Fans push players and physical entities within their direction
- Configurable per fan: team restriction, push strength, push frequency and fan length
- Delayed and timed activation with random ranges for round-based gameplay
- Dynamic fan rotation and natural ghost preview placement
- Custom fan sounds with speed/pitch based on fan strength
- Custom setups are saved per map and automatically loaded on every map start

## 📋 Requirements
- ReGameDLL
- AMX Mod X 1.10+

## 💬 Commands
- `say /af` - Opens the Air Fan menu.
- `say_team /af` - Opens the Air Fan menu.
- `af_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-fan settings (defined under each [Fan Name] section):
# FAN_FLAGS           = a - Active Delay, b - Active Duration, c - Players Only
# FAN_TEAM            = 0 - None, 1 - Terrorist, 2 - Counter-Terrorist, 3 - Both
# FAN_SPAWN_CHANCE    = Fan's respawn probability (0.0 - 1.0)
# FAN_ACTIVE_DELAY    = Minimum and maximum activation delay after round start
# FAN_ACTIVE_DURATION = Minimum and maximum active state duration
# FAN_ACTIVE_COOLDOWN = Minimum and maximum cooldown before reactivation
# FAN_PUSH_STRENGTH   = Push strength
# FAN_PUSH_FREQ       = Minimum and maximum push frequency in seconds
# FAN_LENGTH          = Fan's maximum push distance
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=WiIfoOwYL3E)
