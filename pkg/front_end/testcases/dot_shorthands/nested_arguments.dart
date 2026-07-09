// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final a = A(b: .new(c: .f(0)));

class A {
  final B b;

  const A({required this.b});
}

class B {
  final C c;

  const B({required this.c});
}

class C {
  C.f(num n);
}
