// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we cannot reflect on elements not covered by the `MirrorsUsed`
// annotation.

library test;

@MirrorsUsed(targets: 'C.foo')
import 'dart:mirrors';

import 'package:expect/expect.dart';

import '../../language/compiler_annotations.dart';

class C {
  static foo() => 1;

  @DontInline
  // Use a closure to prevent inlining until the annotation is implemented.
  static bar() => () => 2;
}

main() {
  C.bar();  // Call bar, so it is included in the program.

  var mirror = reflect(new C()).type; // Workaround bug 12799.
  Expect.equals(1, mirror.invoke(const Symbol('foo'), []).reflectee);
  Expect.throws(() => mirror.invoke(const Symbol('bar'),  []),
                (e) => e is UnsupportedError);
}
