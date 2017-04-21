// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 17141.

library test.metadata_nested_constructor_call;

@MirrorsUsed(targets: "test.metadata_nested_constructor_call")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class Box {
  final contents;
  const Box([this.contents]);
}

class MutableBox {
  var contents;
  MutableBox([this.contents]); // Not const.
}

@Box()
class A {}

@Box(const Box())
class B {}

@Box(const Box(const Box()))
class C {}

@Box(const Box(const MutableBox())) // //# 01: compile-time error
class D {}

@Box(const MutableBox(const Box())) // //# 02: compile-time error
class E {}

@Box(Box()) // //# 03: compile-time error
class F {}

@Box(Box(const Box())) // //# 04: compile-time error
class G {}

@Box(Box(const MutableBox())) // //# 05: compile-time error
class H {}

@Box(MutableBox(const Box())) // //# 06: compile-time error
class I {}

final closure = () => 42;

@Box(closure()) // //# 07: compile-time error
class J {}

@Box(closure) // //# 08: compile-time error
class K {}

function() => 42;

@Box(function()) // //# 09: compile-time error
class L {}

// N.B. This is legal, but @function is not (tested by metadata_allowed_values).
@Box(function)
class M {}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  closure();
  checkMetadata(reflectClass(A), [const Box()]);
  checkMetadata(reflectClass(B), [const Box(const Box())]);
  checkMetadata(reflectClass(C), [const Box(const Box(const Box()))]);
  reflectClass(D).metadata;
  reflectClass(E).metadata;
  reflectClass(F).metadata;
  reflectClass(G).metadata;
  reflectClass(H).metadata;
  reflectClass(I).metadata;
  reflectClass(J).metadata;
  reflectClass(K).metadata;
  reflectClass(L).metadata;
  reflectClass(M).metadata;
}
