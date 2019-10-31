# 0.1.5
* Add command line options for selecting/excluding fixes to apply (`--fix`,
  `--excludeFix`, and `--required`). Call with `--help` for more details.
* Add a `--color` option for printing messages with ANSI colors. This defaults
  to true if the terminal supports ANSI colors.
* Add a `--server` option for specifying the path of the analysis server
  snapshot file which provides fixes.
* Add a `--pedantic` option for specifying fixes relating to the [pedantic]
  lints.
* Add an `--outputDir` option for specifying a directory where supplementary
  output may be written. Currently only the non-nullable fix reports
  supplementary output.
* Add experimental non-nullable migration support.

[pedantic]: https://pub.dev/packages/pedantic

# 0.1.4
 * update protocol version constraints

# 0.1.3
 * update SDK constraints

# 0.1.2
 * update SDK constraints
 * add example.dart showing what can be "fixed"

# 0.1.1
 * Remove reading dartfix version from pubspec

# 0.1.0
 * Initial version
