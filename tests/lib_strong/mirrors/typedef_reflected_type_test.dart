// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'package:expect/expect.dart';
import 'stringify.dart';

@MirrorsUsed(targets: "test")
import 'dart:mirrors';

typedef int Foo<T>(String x);
typedef int Bar();

class C {
  Bar fun(Foo<int> x) => null;
}

main() {
  var m = reflectClass(C).declarations[#fun];

  Expect.equals(Bar, m.returnType.reflectedType);
  Expect.equals("Foo<int>", m.parameters[0].type.reflectedType.toString());   /// 01: ok
  Expect.equals(int, m.parameters[0].type.typeArguments[0].reflectedType);    /// 01: continued
  Expect.isFalse(m.parameters[0].type.isOriginalDeclaration);                 /// 01: continued

  var lib = currentMirrorSystem().findLibrary(#test);
  Expect.isTrue(lib.declarations[#Foo].isOriginalDeclaration);
}
