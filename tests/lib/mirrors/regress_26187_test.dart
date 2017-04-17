// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: const ["A", "B", "f", "g"])
import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  const A();
}

class B {
  const B();
}

typedef void f(@A() int, String);

typedef void g(@B() int, String);

main() {
  ParameterMirror fParamMirror =
      (reflectType(f) as TypedefMirror).referent.parameters[0];
  ParameterMirror gParamMirror =
      (reflectType(g) as TypedefMirror).referent.parameters[0];
  Expect.equals(
      '.A', MirrorSystem.getName(fParamMirror.metadata[0].type.qualifiedName));
  Expect.equals(
      '.B', MirrorSystem.getName(gParamMirror.metadata[0].type.qualifiedName));
}
