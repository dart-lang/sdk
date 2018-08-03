// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test is-test of typedefs with optional and named parameters.

typedef int Func1(int a);
typedef int Func2(int a, [int b]);
typedef int Func3(int a, [int b, int c]);
typedef int Func4([int a, int b, int c]);
typedef int Func5(int a, {int b});
typedef int Func6(int a, {int b, int c});
typedef int Func7({int a, int b, int c});

void main() {
  int func1(int i) {}
  Expect.isTrue(func1 is Func1);
  Expect.isFalse(func1 is Func2);
  Expect.isFalse(func1 is Func3);
  Expect.isFalse(func1 is Func4);
  Expect.isFalse(func1 is Func5);
  Expect.isFalse(func1 is Func6);
  Expect.isFalse(func1 is Func7);

  int func2(int i, int j) {}
  Expect.isFalse(func2 is Func1);
  Expect.isFalse(func2 is Func2);
  Expect.isFalse(func2 is Func3);
  Expect.isFalse(func2 is Func4);
  Expect.isFalse(func2 is Func5);
  Expect.isFalse(func2 is Func6);
  Expect.isFalse(func2 is Func7);

  int func3(int i, int j, int k) {}
  Expect.isFalse(func3 is Func1);
  Expect.isFalse(func3 is Func2);
  Expect.isFalse(func3 is Func3);
  Expect.isFalse(func3 is Func4);
  Expect.isFalse(func3 is Func5);
  Expect.isFalse(func3 is Func6);
  Expect.isFalse(func3 is Func7);

  int func4(int i, [int j]) {}
  Expect.isTrue(func4 is Func1);
  Expect.isTrue(func4 is Func2);
  Expect.isFalse(func4 is Func3);
  Expect.isFalse(func4 is Func4);
  Expect.isFalse(func4 is Func5);
  Expect.isFalse(func4 is Func6);
  Expect.isFalse(func4 is Func7);

  int func5(int i, [int j, int k]) {}
  Expect.isTrue(func5 is Func1);
  Expect.isTrue(func5 is Func2);
  Expect.isTrue(func5 is Func3);
  Expect.isFalse(func5 is Func4);
  Expect.isFalse(func5 is Func5);
  Expect.isFalse(func5 is Func6);
  Expect.isFalse(func5 is Func7);

  int func6([int i, int j, int k]) {}
  Expect.isTrue(func6 is Func1);
  Expect.isTrue(func6 is Func2);
  Expect.isTrue(func6 is Func3);
  Expect.isTrue(func6 is Func4);
  Expect.isFalse(func6 is Func5);
  Expect.isFalse(func6 is Func6);
  Expect.isFalse(func6 is Func7);

  int func7(int i, {int j}) {}
  Expect.isTrue(func7 is Func1);
  Expect.isFalse(func7 is Func2);
  Expect.isFalse(func7 is Func3);
  Expect.isFalse(func7 is Func4);
  Expect.isFalse(func7 is Func5);
  Expect.isFalse(func7 is Func6);
  Expect.isFalse(func7 is Func7);

  int func8(int i, {int b}) {}
  Expect.isTrue(func8 is Func1);
  Expect.isFalse(func8 is Func2);
  Expect.isFalse(func8 is Func3);
  Expect.isFalse(func8 is Func4);
  Expect.isTrue(func8 is Func5);
  Expect.isFalse(func8 is Func6);
  Expect.isFalse(func8 is Func7);

  int func9(int i, {int b, int c}) {}
  Expect.isTrue(func9 is Func1);
  Expect.isFalse(func9 is Func2);
  Expect.isFalse(func9 is Func3);
  Expect.isFalse(func9 is Func4);
  Expect.isTrue(func9 is Func5);
  Expect.isTrue(func9 is Func6);
  Expect.isFalse(func9 is Func7);

  int func10(int i, {int c, int b}) {}
  Expect.isTrue(func10 is Func1);
  Expect.isFalse(func10 is Func2);
  Expect.isFalse(func10 is Func3);
  Expect.isFalse(func10 is Func4);
  Expect.isTrue(func10 is Func5);
  Expect.isTrue(func10 is Func6);
  Expect.isFalse(func10 is Func7);

  int func11({int a, int b, int c}) {}
  Expect.isFalse(func11 is Func1);
  Expect.isFalse(func11 is Func2);
  Expect.isFalse(func11 is Func3);
  Expect.isFalse(func11 is Func4);
  Expect.isFalse(func11 is Func5);
  Expect.isFalse(func11 is Func6);
  Expect.isTrue(func11 is Func7);

  int func12({int c, int a, int b}) {}
  Expect.isFalse(func12 is Func1);
  Expect.isFalse(func12 is Func2);
  Expect.isFalse(func12 is Func3);
  Expect.isFalse(func12 is Func4);
  Expect.isFalse(func12 is Func5);
  Expect.isFalse(func12 is Func6);
  Expect.isTrue(func12 is Func7);
}
