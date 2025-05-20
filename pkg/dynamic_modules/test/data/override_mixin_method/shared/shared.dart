// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends B with M1, M2 {}

class B {
  String bar() => 'B.bar';
}

mixin M1 on B {}

mixin M2 on B, M1 {
  String foo() => 'M2.foo';

  @override
  String bar() => 'M2.bar';
}

mixin M3 on B {
  @override
  String bar() => 'M3.bar';
}
