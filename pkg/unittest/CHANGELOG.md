##0.11.0+2

*  Removed unused files from tests and standardized remaining test file names.

##0.11.0+1

* Widen the version constraint for `stack_trace`.

##0.11.0

* Deprecated methods have been removed:
    * `expectAsync0`, `expectAsync1`, and `expectAsync2` - use `expectAsync`
      instead
    * `expectAsyncUntil0`, `expectAsyncUntil1`, and `expectAsyncUntil2` - use
      `expectAsyncUntil` instead
    * `guardAsync` - no longer needed
    * `protectAsync0`, `protectAsync1`, and `protectAsync2` - no longer needed
* `matcher.dart` and `mirror_matchers.dart` have been removed. They are now in
  the `matcher` package.
* `mock.dart` has been removed. It is now in the `mock` package.

##0.10.1+2

* Fixed deprecation message for `mock`.

##0.10.1+1

* Fixed CHANGELOG
* Moved to triple-slash for all doc comments.

##0.10.1

* **DEPRECATED**
    * `matcher.dart` and `mirror_matchers.dart` are now in the `matcher`
      package.
    * `mock.dart` is now in the `mock` package.
* `equals` now allows a nested matcher as an expected list element or map value
  when doing deep matching.
* `expectAsync` and `expectAsyncUntil` now support up to 6 positional arguments
  and correctly handle functions with optional positional arguments with default
  values.

##0.10.0

* Each test is run in a separate `Zone`. This ensures that any exceptions that
occur is async operations are reported back to the source test case.
* **DEPRECATED** `guardAsync`, `protectAsync0`, `protectAsync1`,
and `protectAsync2`
    * Running each test in a `Zone` addresses the need for these methods.
* **NEW!** `expectAsync` replaces the now deprecated `expectAsync0`,
    `expectAsync1` and `expectAsync2`
* **NEW!** `expectAsyncUntil` replaces the now deprecated `expectAsyncUntil0`,
    `expectAsyncUntil1` and `expectAsyncUntil2`
* `TestCase`:
    * Removed properties: `setUp`, `tearDown`, `testFunction`
    * `enabled` is now get-only
    * Removed methods: `pass`, `fail`, `error`
* `interactive_html_config.dart` has been removed.
* `runTests`, `tearDown`, `setUp`, `test`, `group`, `solo_test`, and
  `solo_group` now throw a `StateError` if called while tests are running.
* `rerunTests` has been removed.
