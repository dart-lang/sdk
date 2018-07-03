// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test that top-level inference correctly handles dependencies from
// top-level field -> initializing formal -> field that overrides a getter.

abstract class B {
  String get f;
}

class A implements B {
  final f;
  A(this.f);
}

var a = new A("foo");
main() => print(a);
