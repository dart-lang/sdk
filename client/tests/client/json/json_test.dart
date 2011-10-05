// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Unit tests for JSON.
 */
class JsonTest {
  static void setUpTestSuite(var suite) {
    suite.addTest(() { testParse(); });
    suite.addTest(() { testStringify(); });
  }

  static void runAllTests() {
    testParse();
    testStringify();
  }

  static void testParse() {
    // Scalars.
    Expect.equals(5, JSON.parse(' 5 '));
    Expect.equals(-42, JSON.parse(' -42 '));
    Expect.equals(3, JSON.parse(' 3e0 '));
    Expect.equals(3.14, JSON.parse(' 3.14 '));
    Expect.equals(true, JSON.parse('true '));
    Expect.equals(false, JSON.parse(' false'));
    Expect.equals(null, JSON.parse(' null '));
    Expect.equals(null, JSON.parse('\n\rnull\t'));
    Expect.equals('hi there" bob', JSON.parse(' "hi there\\" bob" '));
    Expect.equals('', JSON.parse(' "" '));

    // Lists.
    expectValueEquals([], JSON.parse(' [] '));
    expectValueEquals([], JSON.parse('[ ]'));
    expectValueEquals([3, -4.5, true, 'hi', false],
                      JSON.parse(' [3, -4.5, true, "hi", false] '));
    // Nulls are tricky.
    expectValueEquals([null], JSON.parse('[null]'));
    expectValueEquals([3, -4.5, null, true, 'hi', false],
                      JSON.parse(' [3, -4.5, null, true, "hi", false] '));
    expectValueEquals([[null]], JSON.parse('[[null]]'));
    expectValueEquals([[3], [], [null], ['hi', true]],
                      JSON.parse(' [ [3], [], [null], ["hi", true]] '));

    // Maps.
    expectValueEquals({}, JSON.parse(' {} '));
    expectValueEquals({}, JSON.parse('{ }'));

    expectValueEquals(
      {'x':3, 'y':-4.5, 'z':'hi', 'u':true, 'v':false},
      JSON.parse(' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '));
    expectValueEquals({"x":3, "y":-4.5, "z":'hi'},
                      JSON.parse(' {"x":3, "y": -4.5,  "z" : "hi" } '));
    expectValueEquals({"z":'hi', "x":3, "y":-4.5},
                      JSON.parse(' {"y": -4.5,  "z" : "hi" ,"x":3 } '));

    expectValueEquals({' hi bob ':3, '':4.5},
                      JSON.parse('{ " hi bob " :3, "": 4.5}'));

    expectValueEquals({'x':{}}, JSON.parse(' { "x" : { } } '));
    expectValueEquals({'x':{}}, JSON.parse('{"x":{}}'));

    // Nulls are tricky.
    expectValueEquals({'w':null}, JSON.parse('{"w":null}'));
    expectValueEquals({'x':{'w':null}}, JSON.parse('{"x":{"w":null}}'));
    expectValueEquals(
        {'x':3, 'y':-4.5, 'z':'hi', 'w':null, 'u':true, 'v':false},
        JSON.parse(' {"x":3, "y": -4.5,  "z" : "hi",'
                   + '"w":null, "u" : true, "v": false } '));
    expectValueEquals(
        {'x':{'a':3, 'b':-4.5}, 'y':[{}], 'z':'hi', 'w':{'c':null, 'd':true},
                      'v':null},
        JSON.parse('{"x": {"a":3, "b": -4.5}, "y":[{}], '
                   + '"z":"hi","w":{"c":null,"d":true}, "v":null}'));
  }

  static void testStringify() {
    // Scalars.
    Expect.equals('5', JSON.stringify(5));
    Expect.equals('-42', JSON.stringify(-42));
    // Dart does not guarantee a formatting for doubles,
    // so reparse and compare to the original.
    testRoundTrip(3.14);
    Expect.equals('true', JSON.stringify(true));
    Expect.equals('false', JSON.stringify(false));
    Expect.equals('null', JSON.stringify(null));
    Expect.equals('" hi there\\" bob "', JSON.stringify(' hi there" bob '));
    Expect.equals('""', JSON.stringify(''));

    // Lists.
    Expect.equals('[]', JSON.stringify([]));
    Expect.equals('[]', JSON.stringify(new List(0)));
    Expect.equals('[null,null,null]', JSON.stringify(new List(3)));
    testRoundTrip([3, -4.5, null, true, 'hi', false]);
    Expect.equals('[[3],[],[null],["hi",true]]',
                  JSON.stringify([[3], [], [null], ['hi', true]]));

    // Maps.
    Expect.equals('{}', JSON.stringify({}));
    Expect.equals('{}', JSON.stringify(new Map()));
    Expect.equals('{"x":{}}', JSON.stringify({'x':{}}));
    Expect.equals('{"x":{"a":3}}', JSON.stringify({'x':{'a':3}}));

    // Dart does not guarantee an order on the keys
    // of a map literal, so reparse and compare to the original Map.
    testRoundTrip({'x':3, 'y':-4.5, 'z':'hi', 'w':null, 'u':true, 'v':false});
    testRoundTrip({"x":3, "y":-4.5, "z":'hi'});
    testRoundTrip({' hi bob ':3, '':4.5});
    testRoundTrip(
        {'x':{'a':3, 'b':-4.5}, 'y':[{}], 'z':'hi', 'w':{'c':null, 'd':true},
                  'v':null});

    testUnconvertible();
  }

  /**
   * Checks that the argument can be converted to a JSON string and
   * back, and produce something equivalent to the argument.
   */
  static void testRoundTrip(expected) {
    expectValueEquals(expected, JSON.parse(JSON.stringify(expected)));
  }

  /**
   * Checks that we get an exception (rather than silently returning null) if
   * we try to stringify something that cannot be converted to json.
   */
  static bool testUnconvertible() {
    bool gotException = false;
    try {
      JSON.stringify(new TestClass());
    } catch (var e) {
      gotException = true;
    }
    Expect.equals(true, gotException);
  }


  /**
   * Checks that expected value-equals actual, where value-equals is
   * the same as == except for Lists and Maps where it's recursive
   * value-equals.
   */
  // TODO(chambers): Move into Expect class.
  static void expectValueEquals(expected, actual, [String message='']) {
    if (expected is List && actual is List) {
      int n = Math.min(expected.length, actual.length);
      for (int i = 0; i < n; i++) {
        expectValueEquals(expected[i], actual[i], 'at index ${i} ${message}');
      }
      // We check on length at the end in order to provide better error
      // messages when an unexpected item is inserted in a list.
      Expect.equals(expected.length, actual.length);
    } else if (expected is Map && actual is Map) {
      expectIsContained(expected, actual, 'in actual ${message}');
      expectIsContained(actual, expected, 'in expected ${message}', false);
    } else {
      Expect.equals(expected, actual);
    }
  }

  static void expectIsContained(Map expected, Map actual,
                                [String message='', bool checkValues=true]) {
    for (final key in expected.getKeys()) {
      Expect.equals(true, actual.containsKey(key));
      if (checkValues) {
        expectValueEquals(expected[key], actual[key],
            'at key ${key} ${message}');
      }
    }
  }
}

class TestClass {
  int x;
  String y;

  TestClass() : x = 3, y = 'joe' { }
}
