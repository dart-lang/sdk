## 0.6.4

* Make compatible with the null-safe version of `args`. 

## 0.6.3

* Broaden version ranges for `fixnum` and `protobuf` dependencies to make
  `dart2js_info` compatible with null-safe `protobuf` version.

## 0.6.2

* Update `protobuf` dependency.
* Set min SDK to `2.3.0`, as generated code contains this version.

## 0.6.1

* Move binary subcommands under src folder. Otherwise, `pub global activate`
  fails.

## 0.6.0

This release contains several **breaking changes**:

* The fields `Info.id` and `Info.serializedId` have been removed. These
  properties were only used for serialization and deserialization. Those values
  are now computed during the serialization process instead.

* Added `CodeSpan` - a representation of code regions referring to output files.
  This will be used to transition to a lighterweight dump-info that doesn't
  embed code snippets (since they are duplicated with the output program).

  Encoder produces a new format for code-spans, but for a transitional period
  a flag is provided to produce the old format. The decoder is still backwards
  compatible (filling in just the `text` in `CodeSpan` where the json contained
  a String).

* Deleted unused `Measurements`.

* Split the json codec from info.dart.

* Introduced `lib/binary_serialization.dart` a lighterweight
  serialization/deserialization implementation. This will eventually be used by
  default by dart2js.

* Added backwards compatibility flag to the JSON codec, to make transition to
  new tools more gradual.

* Added a tool to dump info files in a readable text form.

* Consolidated all binary tools under a single command. Now you can access all
  tools as follows:
  ```
  pub global activate dart2js_info
  dart2js_info <command> [arguments] ...
  ```

  See updated documentation in README.md

## 0.5.17

* Make `live_code_size_analysis` print library URIs and not library names.

## 0.5.16

* Split out IO dependency from `util.dart`, so all other utilities can be used
  on any platform.

## 0.5.15

* Add `BasicInfo.resetIds` to free internal cache used for id uniqueness.

## 0.5.14
* Updates `coverage_log_server.dart` and `live_code_size_analysis.dart` to make
  them strong clean and match the latest changes in dart2js.

## 0.5.13

* Use a more efficient `Map` implementation for decoding existing info files.

* Use a relative path when generating unique IDs for elements in non-package
  sources.

## 0.5.12

* Improved output of `dart2js_info_diff` by sorting the diffs by
  size and outputting the summary in full output mode.

## 0.5.11

* Added `--summary` option to `dart2js_info_diff` tool.

## 0.5.10

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.5.6+4

- Changes to make the library strong mode (runtime) clean.

## 0.5.6

- Added `isRuntimeTypeUsed`, `isIsolateInUse`, `isFunctionApplyUsed` and `isMirrorsUsed` to
  `ProgramInfo`.

## 0.5.5+1

- Support the latest versions of `shelf` and `args` packages.

## 0.5.5

- Added `diff` tool.

## 0.5.4+2

- Updated minimum SDK dependency to align with package dependencies.
- Allowed the latest version of `pkg/quiver`.
- Updated the homepage.
- Improved the stability and eliminated duplicates in "holding" dump info
  output.

## 0.5.4+1

- Remove files published accidentally.

## 0.5.4

- Added script to show inferred types of functions and fields on the command
  line.

## 0.5.3+1

- Improved the stability of `ConstantInfo.id`.

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
