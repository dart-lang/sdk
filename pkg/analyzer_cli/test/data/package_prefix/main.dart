// Test data for package_prefix_test.dart
//
// To test manually:
//
// This should show a hint about an unused import in foo:
// dart ../../../bin/analyzer.dart --packages=packagelist \
//   --x-package-warnings-prefix=f main.dart

import "package:foo/foo.dart";
import "package:bar/bar.dart";

main() {
  print("$foo$bar");
}
