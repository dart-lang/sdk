// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 13817.

library test.metadata_constructor_arguments;

@MirrorsUsed(targets: "test.metadata_constructor_arguments")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class Tag {
  final name;
  const Tag({named}) : this.name = named;
}

@Tag(named: undefined) // //# 01: compile-time error
class A {}

@Tag(named: 'valid')
class B {}

@Tag(named: C.STATIC_FIELD)
class C {
  static const STATIC_FIELD = 3;
}

@Tag(named: D.instanceMethod()) // //# 02: compile-time error
class D {
  instanceMethod() {}
}

@Tag(named: instanceField) // //# 03: compile-time error
class E {
  var instanceField;
}

@Tag(named: F.nonConstStaticField) // //# 04: compile-time error
class F {
  static var nonConstStaticField = 6;
}

@Tag(named: instanceMethod) // //# 05: compile-time error
class G {
  instanceMethod() {}
}

@Tag(named: this) // //# 06: compile-time error
class H {
  instanceMethod() {}
}

@Tag(named: super) // //# 07: compile-time error
class I {
  instanceMethod() {}
}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  reflectClass(A).metadata;
  checkMetadata(reflectClass(B), [const Tag(named: 'valid')]);
  checkMetadata(reflectClass(C), [const Tag(named: C.STATIC_FIELD)]);
  reflectClass(D).metadata;
  reflectClass(E).metadata;
  reflectClass(F).metadata;
  reflectClass(G).metadata;
  reflectClass(H).metadata;
  reflectClass(I).metadata;
}
