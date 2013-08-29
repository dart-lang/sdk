// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we cannot reflect on elements not covered by the `MirrorsUsed`
// annotation.

library test;

@MirrorsUsed(targets: 'foo')
import 'dart:mirrors';

import 'package:expect/expect.dart';

import '../../language/compiler_annotations.dart';

foo() => 1;

@DontInline
// Use a closure to prevent inlining until the annotation is implemented.
bar() => () => 2;

main() {
  bar();  // Call bar, so it is included in the program.

  var lm = currentMirrorSystem().findLibrary(const Symbol('test')).single;
  Expect.equals(1, lm.invoke(const Symbol('foo'), []).reflectee);
  Expect.throws(() => lm.invoke(const Symbol('bar'),  []));
}
