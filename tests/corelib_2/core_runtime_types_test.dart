// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/**
 * A test of simple runtime behavior on numbers, strings and lists with
 * a focus on both correct behavior and runtime errors.
 *
 * This file is written to use minimal type declarations to match a
 * typical dynamic language coding style.
 */
class CoreRuntimeTypesTest {
  static testMain() {
    testBooleanOperators();
    testRationalOperators();
    testIntegerOperators();
    testOperatorErrors();
    testRationalMethods();
    testIntegerMethods();
    testStringOperators();
    testStringMethods();
    testListOperators();
    testListMethods();
    testMapOperators();
    testMapMethods();
    testLiterals();
    testDateMethods();
  }

  static assertEquals(a, b) {
    Expect.equals(b, a);
  }

  static assertListEquals(List a, List b) {
    Expect.equals(b.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(b[i], a[i]);
    }
  }

  static assertListContains(List a, List b) {
    a.sort((x, y) => x.compareTo(y));
    b.sort((x, y) => x.compareTo(y));
    assertListEquals(a, b);
  }

  static assertTypeError(void f()) {
    Expect.throws(
        f,
        (exception) =>
            (exception is TypeError) ||
            (exception is NoSuchMethodError) ||
            (exception is ArgumentError));
  }

  static testBooleanOperators() {
    var x = true, y = false;
    assertEquals(x, true);
    assertEquals(y, false);
    assertEquals(x, !y);
    assertEquals(!x, y);
  }

  static testRationalOperators() {
    var x = 10, y = 20;
    assertEquals(x + y, 30);
    assertEquals(x - y, -10);
    assertEquals(x * y, 200);
    assertEquals(x / y, 0.5);
    assertEquals(x ~/ y, 0);
    assertEquals(x % y, 10);
  }

  static testIntegerOperators() {
    var x = 18, y = 17;
    assertEquals(x | y, 19);
    assertEquals(x & y, 16);
    assertEquals(x ^ y, 3);
    assertEquals(2 >> 1, 1);
    assertEquals(1 << 1, 2);
  }

  static testOperatorErrors() {
    var objs = [
      1,
      '2',
      [3],
      null,
      true,
      new Map()
    ];
    for (var i = 0; i < objs.length; i++) {
      for (var j = i + 1; j < objs.length; j++) {
        testBinaryOperatorErrors(objs[i], objs[j]);
        // Allow "String * int".
        if (j > 2) testBinaryOperatorErrors(objs[j], objs[i]);
      }
      if (objs[i] != 1) {
        testUnaryOperatorErrors(objs[i]);
      }
    }
  }

  static testBinaryOperatorErrors(x, y) {
    assertTypeError(() {
      x - y;
    });
    assertTypeError(() {
      x * y;
    });
    assertTypeError(() {
      x / y;
    });
    assertTypeError(() {
      x | y;
    });
    assertTypeError(() {
      x ^ y;
    });
    assertTypeError(() {
      x & y;
    });
    assertTypeError(() {
      x << y;
    });
    assertTypeError(() {
      x >> y;
    });
    assertTypeError(() {
      x ~/ y;
    });
    assertTypeError(() {
      x % y;
    });

    testComparisonOperatorErrors(x, y);
  }

  static testComparisonOperatorErrors(x, y) {
    assertEquals(x == y, false);
    assertEquals(x != y, true);
    assertTypeError(() {
      x < y;
    });
    assertTypeError(() {
      x <= y;
    });
    assertTypeError(() {
      x > y;
    });
    assertTypeError(() {
      x >= y;
    });
  }

  static testUnaryOperatorErrors(x) {
    // TODO(jimhug): Add guard for 'is num' when 'is' is working
    assertTypeError(() {
      ~x;
    });
    assertTypeError(() {
      -x;
    });
    // TODO(jimhug): Add check for !x as an error when x is not a bool
  }

  static testRationalMethods() {
    var x = 10.6;
    assertEquals(x.abs(), 10.6);
    assertEquals((-x).abs(), 10.6);
    assertEquals(x.round(), 11);
    assertEquals(x.floor(), 10);
    assertEquals(x.ceil(), 11);
  }

  // TODO(jimhug): Determine correct behavior for mixing ints and floats.
  static testIntegerMethods() {
    var y = 9;
    assertEquals(y.isEven, false);
    assertEquals(y.isOdd, true);
    assertEquals(y.toRadixString(2), '1001');
    assertEquals(y.toRadixString(3), '100');
    assertEquals(y.toRadixString(16), '9');
    assertEquals((0).toRadixString(16), '0');
    try {
      y.toRadixString(0);
      Expect.fail("Illegal radix 0 accepted.");
    } catch (e) {}
    try {
      y.toRadixString(-1);
      Expect.fail("Illegal radix -1 accepted.");
    } catch (e) {}
  }

  static testStringOperators() {
    var s = "abcdef";
    assertEquals(s, "abcdef");
    assertEquals(s.codeUnitAt(0), 97);
    assertEquals(s[0], 'a');
    assertEquals(s.length, 6);
    assertTypeError(() {
      s[null];
    });
  }

  // TODO(jimhug): Fill out full set of string methods.
  static testStringMethods() {
    var s = "abcdef";
    assertEquals(s.isEmpty, false);
    assertEquals(s.isNotEmpty, true);
    assertEquals(s.startsWith("abc"), true);
    assertEquals(s.endsWith("def"), true);
    assertEquals(s.startsWith("aa"), false);
    assertEquals(s.endsWith("ff"), false);
    assertEquals(s.contains('cd', 0), true);
    assertEquals(s.contains('cd', 2), true);
    assertEquals(s.contains('cd', 3), false);
    assertEquals(s.indexOf('cd', 2), 2);
    assertEquals(s.indexOf('cd', 3), -1);
  }

  static testListOperators() {
    var a = [1, 2, 3, 4];
    assertEquals(a[0], 1);
    a[0] = 42;
    assertEquals(a[0], 42);
    assertEquals(a.length, 4);
  }

  // TODO(jimhug): Fill out full set of list methods.
  static testListMethods() {
    var a = [1, 2, 3, 4];
    assertEquals(a.isEmpty, false);
    assertEquals(a.length, 4);
    var exception = null;
    a.clear();
    assertEquals(a.length, 0);
  }

  static testMapOperators() {
    var d = new Map();
    d['a'] = 1;
    d['b'] = 2;
    assertEquals(d['a'], 1);
    assertEquals(d['b'], 2);
    assertEquals(d['c'], null);
  }

  static testMapMethods() {
    var d = new Map();
    d['a'] = 1;
    d['b'] = 2;
    assertEquals(d.containsValue(2), true);
    assertEquals(d.containsValue(3), false);
    assertEquals(d.containsKey('a'), true);
    assertEquals(d.containsKey('c'), false);
    assertEquals(d.keys.length, 2);
    assertEquals(d.values.length, 2);

    assertEquals(d.remove('c'), null);
    assertEquals(d.remove('b'), 2);
    assertEquals(d.keys.single, 'a');
    assertEquals(d.values.single, 1);

    d['c'] = 3;
    d['f'] = 4;
    assertEquals(d.keys.length, 3);
    assertEquals(d.values.length, 3);
    assertListContains(d.keys.toList(), ['a', 'c', 'f']);
    assertListContains(d.values.toList(), [1, 3, 4]);

    var count = 0;
    d.forEach((key, value) {
      count++;
      assertEquals(value, d[key]);
    });
    assertEquals(count, 3);

    d = {'a': 1, 'b': 2};
    assertEquals(d.containsValue(2), true);
    assertEquals(d.containsValue(3), false);
    assertEquals(d.containsKey('a'), true);
    assertEquals(d.containsKey('c'), false);
    assertEquals(d.keys.length, 2);
    assertEquals(d.values.length, 2);

    d['g'] = null;
    assertEquals(d.containsKey('g'), true);
    assertEquals(d['g'], null);
  }

  static testDateMethods() {
    var msec = 115201000;
    var d = new DateTime.fromMillisecondsSinceEpoch(msec, isUtc: true);
    assertEquals(d.second, 1);
    assertEquals(d.year, 1970);

    d = new DateTime.now();
    assertEquals(d.year >= 1970, true);
  }

  static testLiterals() {
    true.toString();
    1.0.toString();
    .5.toString();
    1.toString();
    if (false) {
      // Depends on http://b/4198808.
      null.toString();
    }
    '${null}'.toString();
    '${true}'.toString();
    '${false}'.toString();
    ''.toString();
    ''.endsWith('');
  }
}

main() {
  CoreRuntimeTypesTest.testMain();
}
