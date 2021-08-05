// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test the use of `null` keys in const maps. In versions before 2.12, when
// nullable types were introduced, types were nullable so it was legal to have
// `null` keys in maps.

library map_literal15_test;

import "package:expect/expect.dart";

void test1() {
  var m1 = const <String, int>{null: 10, 'null': 20};
  Expect.isTrue(m1.containsKey(null));
  Expect.isTrue(m1.containsKey(undefined()));
  Expect.equals(10, m1[null]);
  Expect.equals(10, m1[undefined()]);
  Expect.isTrue(m1.containsKey('null'));
  Expect.equals(20, m1['null']);
  // The '.keys' carry the 'String' type
  Expect.type<Iterable<String>>(m1.keys);
  Expect.type<Iterable<Comparable>>(m1.keys);
  Expect.notType<Iterable<int>>(m1.keys);
}

void test2() {
  var m2 = const <Comparable, int>{null: 10, 'null': 20};
  Expect.isTrue(m2.containsKey(null));
  Expect.isTrue(m2.containsKey(undefined()));
  Expect.equals(10, m2[null]);
  Expect.equals(10, m2[undefined()]);
  Expect.isTrue(m2.containsKey('null'));
  Expect.equals(20, m2['null']);
  // The '.keys' carry the 'Comparable' type
  Expect.notType<Iterable<String>>(m2.keys);
  Expect.type<Iterable<Comparable>>(m2.keys);
  Expect.notType<Iterable<int>>(m2.keys);
}

main() {
  test1();
  test2();
}

// Calling `undefined()` gives us a `null` that is implemented as JavaScript
// `undefined` on dart2js.
@pragma('dart2js:noInline')
dynamic get undefined => _undefined;

@pragma('dart2js:noInline')
void _undefined() {}
