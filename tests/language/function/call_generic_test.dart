// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// dart2jsOptions=-Ddart.isdart2js=true

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
List staticFn<T>([T? a1, T? a2, T? a3, T? a4, T? a5]) => [T, a1, a2, a3, a4, a5];

class C {
  @pragma('dart2js:noInline')
  List memberFn<T>([T? a1, T? a2, T? a3, T? a4, T? a5]) => [T, a1, a2, a3, a4, a5];

  @pragma('dart2js:noInline')
  // 'map' is implemented by native iterables. On dart2js, 'map' has interceptor
  // calling convention.
  List map<T>([T? a1, T? a2, T? a3, T? a4, T? a5]) => [T, a1, a2, a3, a4, a5];
}

check(expected, actual) {
  print('a:  $expected');
  print('b:  $actual');
  if (((actual[0] == Object && expected[0] == dynamic) ||
          (actual[0] == dynamic && expected[0] == Object)) &&
      !const bool.fromEnvironment('dart.isdart2js')) {
    // TODO(32483): dartdevk sometimes defaults type to 'Object' when 'dynamic'
    // is required. Remove this hack when fixed.
    // TODO(31581): dart2js needs instantiate-to-bound to generic 'dynamic'
    // instead of 'Object'.
    actual = actual.toList()..[0] = expected[0];
    print('b*: $actual');
  }
  Expect.equals(expected.toString(), actual.toString());
}

main() {
  check([Object, 1, 2, 3, null, null], staticFn(1 as dynamic, 2, 3));

  check([Object, 'Z', 2, 4, null, null], staticFn('Z', 2, 4));

  check([int, 3, 2, 1, null, null], staticFn(3, 2, 1));

  dynamic f1 = staticFn;

  check([dynamic, 4, 2, 3, null, null], f1(4 as dynamic, 2, 3));

  check([dynamic, 'Q', 2, 3, null, null], f1('Q', 2, 3));

  check([dynamic, 6, 2, 3, null, null], f1(6, 2, 3));

  check([int, 7, 2, null, null, null], f1<int>(7, 2));

  var c = new C();

  check([Object, 8, 2, 3, null, null], c.memberFn(8 as dynamic, 2, 3));

  check([Object, 'A', 2, 3, null, null], c.memberFn('A', 2, 3));

  check([int, 9, 2, 3, null, null], c.memberFn<int>(9, 2, 3));

  check([Object, 10, 2, 3, null, null], c.map(10 as dynamic, 2, 3));

  check([Object, 'B', 2, 3, null, null], c.map('B', 2, 3));

  check([int, 11, 2, 3, null, null], c.map(11, 2, 3));

  dynamic o = new C();

  check([dynamic, 12, 2, 3, null, null], o.memberFn(12 as dynamic, 2, 3));

  check([dynamic, 'C', 2, 3, null, null], o.memberFn('C', 2, 3));

  check([int, 13, 2, null, null, null], o.memberFn<int>(13, 2));

  check([dynamic, 14, 2, 3, null, null], o.map(14 as dynamic, 2, 3));

  check([dynamic, 'D', 2, 3, null, null], o.map('D', 2, 3));

  check([int, 15, null, null, null, null], o.map<int>(15));

  check([int, 16, 2, 3, 4, null], o.map<int>(16, 2, 3, 4));
}
