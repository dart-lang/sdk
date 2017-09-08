// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error in class finalization triggered via mirror in a static initializer.
// Simply check that we do not crash.
// This is a regression test for the VM.

library mirror_in_static_init_test;

@MirrorsUsed(targets: "mirror_in_static_init_test")
import 'dart:mirrors';

// This class is only loaded during initialization of `staticField`.
abstract class C {
  int _a;
  // This is a syntax error on purpose.
  C([this._a: 0]); //# 01: compile-time error
}

final int staticField = () {
  var lib = currentMirrorSystem().findLibrary(#mirror_in_static_init_test);
  var c = lib.declarations[#C] as ClassMirror;
  var lst = new List.from(c.declarations.values);
  return 42;
}();

main() {
  return staticField;
}
