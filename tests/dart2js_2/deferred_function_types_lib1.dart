// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

method1() {
  return (int i) => i;
}

class Class1 {}

method3() {
  return (Class1 c) => c;
}

test3(o) => o is Class1 Function(Class1);

method5(Class1 c, String s, int i) {}

test5(o) => o is Function(Class1, String, int);
