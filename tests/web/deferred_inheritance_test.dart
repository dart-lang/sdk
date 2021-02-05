// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for --fast-startup. The compiler used to emit inherit calls
/// on each fragment even for classes that were already loaded on a different
/// fragment. As a result, the inheritance chain was overwritten in non-chrome
/// browsers (by using __proto__, we evaded this issue in Chrome).
library deferred_inheritance_test;

import 'deferred_inheritance_lib2.dart';
import 'deferred_inheritance_lib1.dart' deferred as d;

import 'package:expect/expect.dart';

class B extends A {}

/// If the check `y is A` is generated as `y.$isA` then the issue is not
/// exposed. We use `AssumeDynamic` to ensure that we generate as `y instanceof
/// A` in JS.
@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
check(y) => Expect.isTrue(y is A);

main() {
  check(new B());
  d.loadLibrary().then((_) {
    check(new d.C());
    check(new B()); // This fails if we overwrite the inheritance chain.
  });
}
