// Copyright (c) 2015, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

/// Checks that lib1.fooX's dependencies on [A] via is-checks, as-expressions
/// and type-annotations(in checked-mode) is correctly tracked.

import "deferred_type_dependency_lib1.dart" deferred as lib1;
import "deferred_type_dependency_lib2.dart" deferred as lib2;
import "package:expect/expect.dart";

main() async {
  await lib1.loadLibrary();
  // Split the cases into a multi-test to test each feature separately.
  Expect.isFalse(
      lib1.fooIs //# is: ok
      lib1.fooAs //# as: ok
      lib1.fooAnnotation //# type_annotation: ok
      ("string")
      is! String //# none: ok
      );
  await lib2.loadLibrary();
  Expect.isTrue(
      lib1.fooIs //# is: ok
      lib1.fooAs //# as: ok
      lib1.fooAnnotation //# type_annotation: ok
      (lib2.getInstance())
      is! String //# none: ok
      );
}
