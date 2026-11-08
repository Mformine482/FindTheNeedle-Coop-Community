# Find The Needle Co-op Community

An unofficial community fork of [AleDev11's Find The Needle Co-op Mod](https://github.com/AleDev11/FindTheNeedle-Coop-Mod), based on v0.19.5. This repository contains the community source. The release ZIP is an update for an existing upstream installation.

## Install v0.19.14

1. Install the [original v0.19.5 release](https://github.com/AleDev11/FindTheNeedle-Coop-Mod/releases/tag/v0.19.5) using the [upstream instructions](https://github.com/AleDev11/FindTheNeedle-Coop-Mod/tree/v0.19.5#install).
2. Close the game. Extract the community release ZIP next to `FindTheNeedle.exe` and replace the existing mod files when prompted.
3. Start the game through Steam. Each player needs the same community version. The host opens the multiplayer menu and invites the other players.

The community update contains GDScript, the CC0 farmer model and its tool pose configuration. Obtain the Steam runtime dependencies from the upstream release. If your security software blocks a download, keep it blocked while the detection is investigated.

## Changes since upstream v0.19.5

- The first world transfer uses the game's save builder so the guest gets the host's warehouse settings.
- F8 reloads the guest's yard from the host. The automatic building and belt updates continue during play.
- Cross-player wheelbarrow loading, dump-hatch handoff, delivery cargo and per-item progress are synchronized.
- Machines receive the host's power state. The roster shows each guest's round-trip time to the host.
- The farmer model is included in the update. Remote emotes show the game's icon and a simplified arm pose.

This is a test release. Individual paths were checked locally. Steam playtesting across more saves and layouts is still needed.

## Credits and license

Original mod by AleDev11. Farmer model by Quaternius under CC0 1.0. Find The Needle belongs to its developer. See [LICENSE](LICENSE) and the [model credits](mods/multiplayer/models/CREDITS.txt).
