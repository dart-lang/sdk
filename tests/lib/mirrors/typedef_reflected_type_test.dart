// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'dart:mirrors';

typedef int Foo<T>(String x);
typedef int Bar();

class C {
  Bar fun(Foo<int> x) =>
      () => 123;
}

typedef TypeOf<T> = T;

void main() {
  var m = reflectClass(C).declarations[#fun] as MethodMirror;

  Expect.equals(TypeOf<int Function()>, m.returnType.reflectedType);
  Expect.equals(
    TypeOf<int Function(String)>,
    m.parameters[0].type.reflectedType,
  );
  Expect.equals(0, m.parameters[0].type.typeArguments.length);
  Expect.isTrue(m.parameters[0].type.isOriginalDeclaration);

  var lib = reflectClass(C).owner as LibraryMirror;
  // Cannot reflect on type alias declarations.
  Expect.isFalse(lib.declarations.containsKey(#Foo));
  Expect.isFalse(lib.declarations.containsKey(#Bar));
}
