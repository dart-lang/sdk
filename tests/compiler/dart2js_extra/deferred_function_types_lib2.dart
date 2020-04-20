// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

method2() {
  return (String s) => s;
}

class Class2 {}

method4() {
  return (Class2 c1, Class2 c2) => c1;
}

test4(o) => o is Class2 Function(Class2, Class2);

method6(Class2 c, int i, String s) {}

test6(o) => o is Function(Class2, int, String);
