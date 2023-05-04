// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef FunctionType = void Function();
typedef GenericFunctionType<T> = T Function(T);

test<T>(o) {
  if (o case FunctionType(:var hashCode)) {
    print(hashCode);
    return 1;
  }
  if (o case GenericFunctionType<int>(:var hashCode)) {
    print(hashCode);
    return 2;
  }
  if (o case GenericFunctionType<String>(:var hashCode)) {
    print(hashCode);
    return 3;
  }
  if (o case GenericFunctionType<T>(:var hashCode)) {
    print(hashCode);
    return 4;
  }
  if (o case GenericFunctionType(:var hashCode)) {
    print(hashCode);
    return 5;
  }
  if (o case Null(:var hashCode)) {
    print(hashCode);
    return 6;
  }
  if (o case FutureOr<int>(:var hashCode)) {
    print(hashCode);
    return 7;
  }
  if (o case dynamic(: var hashCode)) {
    print(hashCode);
    return 0;
  }
  return -1;
}

void function() {}
int intFunction(int i) => i;
String stringFunction(String s) => s;
bool boolFunction(bool b) => b;
dynamic dynamicFunction(dynamic d) => d;
void multiArgFunction(int i, String s) {}

main() {
  expect(1, test(function));
  expect(2, test(intFunction));
  expect(3, test(stringFunction));
  expect(4, test<bool>(boolFunction));
  expect(0, test(boolFunction));
  expect(0, test<num>(boolFunction));
  expect(4, test(dynamicFunction));
  expect(4, test<dynamic>(dynamicFunction));
  expect(5, test<bool>(dynamicFunction));
  expect(0, test(multiArgFunction));
  expect(6, test(null));
  expect(7, test(0));
  expect(7, test(new Future<int>.value(0)));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}