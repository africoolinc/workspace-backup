---
name: droidrun
description: Control Android devices via ADB using natural language. Use when Gibson needs to interact with his Android phone (v20) — opening apps, sending messages, making calls, reading notifications, taking screenshots, or any phone management task. Triggers on: "control android", "manage phone", "send message from phone", "check phone", "android device", "droidrun", "use phone to", "tell me what's on my phone", "open [app] on phone". Requires Portal APK installed on the Android device.
---

# Droidrun — Android ADB Control via Natural Language

## Setup (already done, for reference)

- Droidrun installed: `/opt/droidrun/bin/python3 -m droidrun`
- Python 3.13 venv: `/opt/droidrun`
- ADB devices: `20429563B4043064` (USB), `192.168.100.224:5555` (wireless)
- Portal APK: v0.6.1 installed and accessible on device `20429563B4043064`

## Always Specify the Device

When multiple ADB devices are connected, **always use `-d <serial>`**:

```bash
/opt/droidrun/bin/python3 -m droidrun ping -d 20429563B4043064
/opt/droidrun/bin/python3 -m droidrun run "Open WhatsApp" -d 20429563B4043064
```

If only one device is connected, the serial can be omitted.

## Common Commands

```bash
# Ping to verify Portal is accessible
/opt/droidrun/bin/python3 -m droidrun ping -d <serial>

# Run a natural language command
/opt/droidrun/bin/python3 -m droidrun run "Open settings and tell me the Android version" -d <serial>

# With vision (screenshot-aware)
/opt/droidrun/bin/python3 -m droidrun run "What app is currently open?" --vision -d <serial>

# With reasoning mode (complex multi-step tasks)
/opt/droidrun/bin/python3 -m droidrun run "Find contact John and send him a message" --reasoning -d <serial>

# Override LLM provider/model
/opt/droidrun/bin/python3 -m droidrun run "Check battery level" --provider OpenAI --model gpt-4o -d <serial>
```

## Key Capabilities

- **App control**: Open, close, switch apps
- **UI interaction**: Tap, swipe, type, scroll
- **Information retrieval**: Read screen, check settings, battery, storage
- **Communication**: Send SMS, WhatsApp messages (via app automation)
- **File operations**: Pull/push files via ADB
- **Notifications**: Read recent notifications

## Limitations

- Requires Portal APK accessibility service enabled on device
- Wireless ADB (192.168.100.224:5555) may have latency
- Complex tasks benefit from `--reasoning` flag
- LLM provider must be configured (default: Google Gemini)

## Device Serial Reference

| Device | Serial | Connection |
|--------|--------|------------|
| Gibson's Pixel (v20) | `20429563B4043064` | USB |
| Wireless debug | `192.168.100.224:5555` | WiFi |

Default device: `20429563B4043064` (Gibson's main phone).
