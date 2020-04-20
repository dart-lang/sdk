// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

Future<int> foo() async => 42;

Future<int> simpleAsyncAwait(Future<int> a, Future<int> b) async {
  return (await a) + (await b);
}

Future<int> loops(List<int> list) async {
  int sum = 0;
  for (int i = 0; i < 10; ++i) {
    for (var j in list) {
      sum += i + j + await foo();
    }
  }
  for (int k = 0; k < 10; ++k) {
    sum += k;
  }
  return sum;
}

Future<int> tryCatchRethrow(Future<int> a, Future<int> b, Future<int> c) async {
  int x = 1;
  try {
    x = x + await a;
  } catch (e) {
    if (e is Error) {
      return 42;
    }
    x = x + await b;
    rethrow;
  } finally {
    print('fin');
    x = x + await c;
    return x;
  }
}

closure(Future<int> a) {
  int x = 3;
  Future<int> nested() async {
    int y = 4;
    try {
      x = 5;
      y = await a;
      return x + y;
    } finally {
      print('fin');
    }
  }

  return nested;
}

Future<int> testAssert(Future<int> a) async {
  assert((await a) == 42);
  return 7;
}

var asyncInFieldInitializer = (Future<int> x) async {
  await x;
};

main() {}
