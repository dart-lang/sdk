## 0.5.3

- Made IDs in the JSON format stable. Improves plain text diffing.

## 0.2.7
- Make dart2js_info strong-mode clean.

## 0.2.6
- Add tool to get breakdown of deferred libraries by size.

## 0.2.5
- Changed the `deferred_library_check` tool to allow parts to exclude packages
  and to not assume that unspecified packages are in the main part.

## 0.2.4
- Added `imports` field for `OutputUnitInfo`

## 0.2.3
- Moved `deferred_library_check` functionality to a library

## 0.2.2
- Added `deferred_libary_check` tool

## 0.2.1
- Merged `verify_deps` tool into `debug_info` tool

## 0.2.0
- Added `AllInfoJsonCodec`
- Added `verify_deps` tool

## 0.1.0
- Added `ProgramInfo.entrypoint`.
- Added experimental information about calls in function bodies. This will
  likely change again in the near future.

## 0.0.3
- Added executable names

## 0.0.2
- Add support for `ConstantInfo`

## 0.0.1
- Initial version
