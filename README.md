# physicalpknu

Self-hosted MQTT system for the XIAO ESP32C6: one Mosquitto broker on your own
laptop, a firmware sketch per board, a browser dashboard, and a skill to control
the boards from the shell. Team topic prefix: **`physicalpknu`**.

```
broker/     Mosquitto config (TCP 1883 + WebSockets 9001) + setup script
firmware/   XIAO ESP32C6 sketch (MqttNode): LED control in, A0 readings out
web/        dashboard.html - live view of every node, no build step
skills/     physicalpknu skill (SKILL.md + skill.sh)
```

## Install (the skill)

```bash
npx skills add dptjddl285-ship-it/test
```

That is the [skills.sh](https://www.skills.sh) CLI. It finds the skill in
`skills/physicalpknu/`, installs it to `~/.agents/skills/physicalpknu`, and
links it into `~/.claude/skills/` for Claude Code. Add `-g` for a user-level
install, `-l` to list without installing.

No Node? A plain shell installer does the same thing:

```bash
curl -fsSL https://raw.githubusercontent.com/dptjddl285-ship-it/test/main/install.sh | bash
```

On Windows run either from **Git Bash**, not cmd.

Then:

```bash
cd ~/.claude/skills/physicalpknu   # or ~/.agents/skills/physicalpknu
./skill.sh name yesssng            # your board's name, saved to ~/.physicalpknu
./skill.sh check                   # is the broker reachable?
./skill.sh devices                 # which boards are online
./skill.sh led on
```

The name must match `DEVICE_NAME` in your board's `arduino_secrets.h`.

`skill.sh` needs the mosquitto clients — `brew install mosquitto` (macOS),
`sudo apt install mosquitto-clients` (Linux), or the
[Windows installer](https://mosquitto.org/download/) (its default path is
detected automatically, so you do not have to touch `PATH`).

## Run your own broker

Mosquitto 2.x binds to localhost only until a listener is declared, so a default
install accepts no LAN clients. In an **elevated** PowerShell:

```powershell
cd broker
powershell -ExecutionPolicy Bypass -File .\setup-broker.ps1
```

That backs up the existing config, installs `mosquitto.conf`, adds firewall
rules for 1883 and 9001 (all profiles), restarts the service, and prints the LAN
address to hand out. The config opens `allow_anonymous true` with no TLS — fine
on a trusted LAN, never expose 1883/9001 to the internet.

## Flash a board

`firmware/MqttNode/` keeps credentials out of the repo:

```bash
cd firmware/MqttNode
cp arduino_secrets.example.h arduino_secrets.h   # then edit it
```

Set `DEVICE_NAME` to the board's name — that becomes its topic prefix under
`physicalpknu/`. Leave it `""` and the board falls back to `c6-` plus the last 3
bytes of its MAC.

```bash
arduino-cli lib install PubSubClient
arduino-cli compile --fqbn esp32:esp32:XIAO_ESP32C6 .
arduino-cli upload -p COM3 --fqbn esp32:esp32:XIAO_ESP32C6 .
```

The board prints its name on the serial monitor at 115200 baud on boot.

## Dashboard

Open `web/dashboard.html` in a browser — a single self-contained file, no server
and no build step. It connects to the broker over WebSockets (9001) and draws
each node's link to the broker, live A0 values, LED state, and a message log.
`dashboard.html?host=192.168.0.30` points it somewhere else.

It speaks MQTT over a raw WebSocket rather than loading mqtt.js from a CDN, so
it works on a network with no internet access. You must be on the same WiFi as
the broker machine.

## Topics

| Topic | Direction | Payload |
|---|---|---|
| `physicalpknu/<id>/led/set` | client → board | `on`, `off`, `toggle` |
| `physicalpknu/<id>/led/state` | board → client | `on`, `off` (retained) |
| `physicalpknu/<id>/sensor/a0` | board → client | `{"raw":2048,"mv":1650}` every 2s |
| `physicalpknu/<id>/status` | board → client | `online`, `offline` (retained, last will) |

## Hardware notes

- Board: Seeed XIAO ESP32C6. FQBN: `esp32:esp32:XIAO_ESP32C6`.
- User LED: GPIO 15 (`LED_BUILTIN`), **active-low** (`LOW` = on, `HIGH` = off).
- A0 sensor: GPIO 0.
- 2.4GHz WiFi only (no 5GHz radio).

## Security

The broker runs with `allow_anonymous true` and no TLS. Anyone on the same
network can publish to any topic, including other boards. This is fine for a lab
on a trusted LAN and unacceptable anywhere else — do not expose port 1883 or
9001 to the internet.
