# DartPad Release Artifacts (`dartpad.zip`)

Dart release automation builds the `dartpad` target (`utils/dartpad/BUILD.gn`) in the Dart SDK repository and uploads the output to `gs://dart-archive` as `dartpad.zip` (alongside `dartpad.zip.sha256sum`).

All files in `dartpad.zip` are archived under a top-level `dartpad/` directory.

## Download URLs

For `<channel>` in `{main, dev, beta, stable}`:

- **By commit SHA (`raw` — every built commit):**
  - `https://storage.googleapis.com/dart-archive/channels/<channel>/raw/hash/<revision>/dartpad/dartpad.zip`
  - `https://storage.googleapis.com/dart-archive/channels/<channel>/raw/latest/dartpad/dartpad.zip`
- **By release version (`release` — promoted `dev`, `beta`, `stable` releases):**
  - `https://storage.googleapis.com/dart-archive/channels/<channel>/release/<version>/dartpad/dartpad.zip`
  - `https://storage.googleapis.com/dart-archive/channels/<channel>/release/latest/dartpad/dartpad.zip`
