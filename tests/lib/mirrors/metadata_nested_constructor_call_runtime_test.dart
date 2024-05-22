// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 17141.

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

@Box(Box())
class F {}

@Box(Box(const Box()))
class G {}

final closure = () => 42;

function() => 42;

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
  reflectClass(F).metadata;
  reflectClass(G).metadata;
  reflectClass(M).metadata;
}
