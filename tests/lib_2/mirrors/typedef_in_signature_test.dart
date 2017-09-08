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
  var mm = lm.declarations[#bar] as MethodMirror;
  Expect.equals(reflectType(foo2), mm.returnType);
  Expect.equals(reflectType(foo), mm.parameters[0].type);
  mm = lm.declarations[#gee] as MethodMirror;
  Expect.equals(reflectType(int), mm.parameters[0].type);
  Expect.equals(reflectType(foo3), mm.returnType);
  var ftm = (mm.returnType as TypedefMirror).referent;
  Expect.equals(reflectType(foo), ftm.returnType);
  Expect.equals(reflectType(foo2), ftm.parameters[0].type);
}
