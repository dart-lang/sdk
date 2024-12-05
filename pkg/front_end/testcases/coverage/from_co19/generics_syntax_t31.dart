// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Generics/syntax_t31.dart

class A {}
void testMe() {}

typedef AAlias = A;
typedef int TestFunction();
typedef Func1 = void Function(int);

void foo() {
  A<int>(); // Error
  testMe<int>(); // Error
  AAlias<int>(); // Error

  TestFunction<int> testFunction = () => 42; // Error

  Func1<int> f1 = (int i) {}; // Error
}
