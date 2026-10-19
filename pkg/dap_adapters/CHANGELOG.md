## 1.2.0-wip

- Expanding a `dart:ffi` `Pointer` to a `Struct` or `Union` in the debugger now
  shows its decoded fields, including nested structs/unions and inline arrays.

## 1.1.0

- Require `package:vm_service` 15.1.0 or later.
- Output events for tests (generated when an adapter calls `sendTestEvents`) now
  include timestamps and summary counts and are colored if the client supports
  ANSI color codes.

## 1.0.1

- Updated stack frame parsing to better handle `widget:uri:line:col` in Flutter
  error output.

## 1.0.0

- Initial release.
- Contains Dart CLI and Dart Test DAP adapters migrated from `package:dds`.
