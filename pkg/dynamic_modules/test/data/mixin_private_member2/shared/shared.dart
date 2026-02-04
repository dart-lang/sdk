// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

mixin M1 on A {
  int _privateMethod() => 1;
  String publicMethod() => '${_privateMethod()} 2';
}

mixin M2 on A, M1 {}

class B extends A with M1, M2 {}
