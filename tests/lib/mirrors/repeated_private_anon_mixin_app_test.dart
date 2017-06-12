// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.repeated_private_anon_mixin_app;

// Regression test for symbol mangling.

@MirrorsUsed(targets: "test.repeated_private_anon_mixin_app")
import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'repeated_private_anon_mixin_app1.dart' as lib1;
import 'repeated_private_anon_mixin_app2.dart' as lib2;

testMA() {
  Symbol name1 = reflectClass(lib1.MA).superclass.simpleName;
  Symbol name2 = reflectClass(lib2.MA).superclass.simpleName;

  Expect.equals('lib._S with lib._M', MirrorSystem.getName(name1));
  Expect.equals('lib._S with lib._M', MirrorSystem.getName(name2));

  Expect.notEquals(name1, name2);
  Expect.notEquals(name2, name1);
}

testMA2() {
  Symbol name1 = reflectClass(lib1.MA2).superclass.simpleName;
  Symbol name2 = reflectClass(lib2.MA2).superclass.simpleName;

  Expect.equals('lib._S with lib._M, lib._M2', MirrorSystem.getName(name1));
  Expect.equals('lib._S with lib._M, lib._M2', MirrorSystem.getName(name2));

  Expect.notEquals(name1, name2);
  Expect.notEquals(name2, name1);
}

main() {
  testMA();
  testMA2();
}
