// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "symbol_map_helper.dart";

// Testing Function.apply calls correctly.
// This test is not testing error handling, only that correct parameters
// cause a correct call.

int test0() => 42;
int test0a({int a}) => 37 + a;
int test1(int i) => i + 1;
int test1a(int i, {int a}) => i + a;
int test2(int i, int j) => i + j;
int test2a(int i, int j, {int a}) => i + j + a;

class C {
  int x = 10;
  int foo(y) => this.x + y;
}

class Callable {
  int call(int x, int y) => x + y;
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

main() {
  testMap(res, func, map) {
    map = symbolMapToStringMap(map);
    Expect.equals(res, Function.apply(func, null, map));
    Expect.equals(res, Function.apply(func, [], map));
  }

  testList(res, func, list) {
    Expect.equals(res, Function.apply(func, list));
    Expect.equals(res, Function.apply(func, list, null));
    Expect.equals(res, Function.apply(func, list, new Map<Symbol, dynamic>()));
  }

  test(res, func, list, map) {
    map = symbolMapToStringMap(map);
    Expect.equals(res, Function.apply(func, list, map));
  }

  testList(42, test0, null);
  testList(42, test0, []);
  testMap(42, test0a, {"a": 5});
  testList(42, test1, [41]);
  test(42, test1a, [20], {"a": 22});
  testList(42, test2, [20, 22]);
  test(42, test2a, [10, 15], {"a": 17});

  // Test that "this" is correct when calling closurized functions.
  var cfoo = new C().foo;
  testList(42, cfoo, [32]);

  // Test that apply works even with a different name.
  var app = confuse(Function.apply);
  Expect.equals(42, app(test2, [22, 20]));

  // Test that apply can itself be applied.
  Expect.equals(
      42,
      Function.apply(Function.apply, [
        test2,
        [17, 25]
      ]));

  // Test that apply works on callable objects.
  testList(42, new Callable(), [13, 29]);
}
