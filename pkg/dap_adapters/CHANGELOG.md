## 1.1.0-wip

- Output events for tests (generated when an adapter calls `sendTestEvents`) now
  include timestamps and summary counts and are coloured if the client supports
  ansii color codes.

## 1.0.1

- Updated stack frame parsing to better handle `widget:uri:line:col` in Flutter
  error output.

## 1.0.0

- Initial release.
- Contains Dart CLI and Dart Test DAP adapters migrated from `package:dds`.
