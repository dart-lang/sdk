// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get getter => 42;
  void set setter(int i) {}
  int field;
  int get property => 42;
  void set property(int i) {}
}

class B implements A {
  @override
  noSuchMethod(Invocation invocation) => null;
}

main() {}
