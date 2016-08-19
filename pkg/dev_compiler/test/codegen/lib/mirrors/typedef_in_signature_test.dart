// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.typedef_in_signature_test;

@MirrorsUsed(targets: 'test.typedef_in_signature_test')
import 'dart:mirrors';

import "package:expect/expect.dart";

typedef int foo();
typedef String foo2();
typedef foo foo3(foo2 x);

foo2 bar(foo x) {
  return null;
}

foo3 gee(int x, foo3 tt) => null;

main() {
  var lm = currentMirrorSystem().findLibrary(#test.typedef_in_signature_test);
  var ftm = lm.declarations[#bar];
  Expect.equals(reflectType(foo2), ftm.returnType);
  Expect.equals(reflectType(foo), ftm.parameters[0].type);
  ftm = lm.declarations[#gee];
  Expect.equals(reflectType(int), ftm.parameters[0].type);
  Expect.equals(reflectType(foo3), ftm.returnType);
  ftm = ftm.returnType.referent;
  Expect.equals(reflectType(foo), ftm.returnType);
  Expect.equals(reflectType(foo2), ftm.parameters[0].type);
}
