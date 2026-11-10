// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  abstract int field;
  void method();
  int get getter;
  void set setter(int value);
}

mixin Mixin on Super {
  void test() {
    super.field = super.field;
    super.method;
    super.method();
    super.setter = super.getter;
  }
}
