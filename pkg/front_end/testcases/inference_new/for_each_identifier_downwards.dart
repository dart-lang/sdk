// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

T f<T>() => throw '';

class A {}

A aTopLevel = throw '';
void set aTopLevelSetter(A value) {}

class C {
  A aField = throw '';
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in f()) {}

    for (aField in f()) {}

    for (aSetter in f()) {}

    for (aTopLevel in f()) {}

    for (aTopLevelSetter in f()) {}
  }
}

main() {}
