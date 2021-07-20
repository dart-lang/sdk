// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/46568.

var genericTopLevelFunctionCallCount = 0;
var genericStaticMethodCallCount = 0;

T? genericTopLevelFunction<T>() {
  genericTopLevelFunctionCallCount++;
  return null;
}

class A {
  static T? genericStaticMethod<T>() {
    genericStaticMethodCallCount++;
    return null;
  }
}

const int? Function() cIntTopLevelFunction1 = genericTopLevelFunction;
const int? Function() cIntStaticMethod1 = A.genericStaticMethod;

void main() {
  // Two different const generic function instantiations should not be
  // canonicalized to the same value.
  Expect.isFalse(identical(cIntTopLevelFunction1, cIntStaticMethod1));
  Expect.notEquals(cIntTopLevelFunction1, cIntStaticMethod1);

  cIntTopLevelFunction1();
  Expect.equals(1, genericTopLevelFunctionCallCount);
  Expect.equals(0, genericStaticMethodCallCount);

  cIntStaticMethod1();
  Expect.equals(1, genericTopLevelFunctionCallCount);
  Expect.equals(1, genericStaticMethodCallCount);
}
