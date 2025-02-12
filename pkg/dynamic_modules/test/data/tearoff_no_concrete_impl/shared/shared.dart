// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class C {
  void foo();
}

class B {
  final C c;

  B(this.c);
}

class A {
  final void Function() f;
  A(this.f);
}
