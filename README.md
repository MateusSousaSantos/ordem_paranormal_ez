# Op.ez (Ordem Paranormal EZ)

Companion app for tabletop sessions. The GM's phone **hosts** the session on the
local Wi-Fi (like a game's "local server"), and players join from their own
phones to track their character. No backend or cloud server is involved.

## How it works

- **GM** taps *Host a session*. The app starts a WebSocket server on port
  `40450` and announces itself on the Wi-Fi via mDNS (`_opez._tcp`). The GM
  device is the source of truth and saves the campaign locally.
- **Players** tap *Join as player*, pick the session from the list (or type the
  address shown on the GM screen) and edit their own sheet.
- Every change is sent to the GM, and the GM pushes changes to everyone.
  Players keep a local copy of their sheet and reconnect automatically.
  When both sides changed a sheet while disconnected, the newest one wins.

## Project layout

| Path | What it is |
| --- | --- |
| `lib/game/` | Game rules. **Placeholder** stats for now; swap in the real Op.ez rules here. |
| `lib/core/protocol.dart` | JSON messages exchanged between host and clients. |
| `lib/host/host_session.dart` | GM side: WebSocket server, sheet storage, broadcasting. |
| `lib/player/player_session.dart` | Player side: connection, reconnect, local sheet. |
| `lib/discovery/` | Finding sessions on the Wi-Fi (mDNS via `bonsoir`). |
| `lib/ui/` | Screens. |

## Running

```sh
flutter pub get
flutter test        # host/player sync tests over a real local socket
flutter run         # on a phone or emulator
```

To try it, run the app on two phones on the same Wi-Fi: one hosts, one joins.
Emulators can't usually see each other via mDNS; type the address instead.

## Later

- **Remote play:** needs a small relay server, because phones on different
  networks can't reach each other directly. The protocol is transport-agnostic,
  so a relay only has to forward the same messages.
- **Online table:** connects to the GM host as a client with
  `role: "observer"` and receives every `sheet_changed` / `player_status`.
