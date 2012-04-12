// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('json_tests');

#import('dart:json');
#import('dart:html');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/html_config.dart');

main() {
  useHtmlConfiguration();
  test('Parse', () {
    // Scalars.
    expect(JSON.parse(' 5 ')).equals(5);
    expect(JSON.parse(' -42 ')).equals(-42);
    expect(JSON.parse(' 3e0 ')).equals(3);
    expect(JSON.parse(' 3.14 ')).equals(3.14);
    expect(JSON.parse('true ')).equals(true);
    expect(JSON.parse(' false')).equals(false);
    expect(JSON.parse(' null ')).equals(null);
    expect(JSON.parse('\n\rnull\t')).equals(null);
    expect(JSON.parse(' "hi there\\" bob" ')).equals('hi there" bob');
    expect(JSON.parse(' "" ')).equals('');

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
  });

  test('stringify', () {
    // Scalars.
    expect(JSON.stringify(5)).equals('5');
    expect(JSON.stringify(-42)).equals('-42');
    // Dart does not guarantee a formatting for doubles,
    // so reparse and compare to the original.
    validateRoundTrip(3.14);
    expect(JSON.stringify(true)).equals('true');
    expect(JSON.stringify(false)).equals('false');
    expect(JSON.stringify(null)).equals('null');
    expect(JSON.stringify(' hi there" bob ')).equals('" hi there\\" bob "');
    expect(JSON.stringify('hi\\there')).equals('"hi\\\\there"');
    // TODO(devoncarew): these tests break the dartium build
    //expect(JSON.stringify('hi\nthere')).equals('"hi\\nthere"');
    //expect(JSON.stringify('hi\r\nthere')).equals('"hi\\r\\nthere"');
    expect(JSON.stringify('')).equals('""');

    // Lists.
    expect(JSON.stringify([])).equals('[]');
    expect(JSON.stringify(new List(0))).equals('[]');
    expect(JSON.stringify(new List(3))).equals('[null,null,null]');
    validateRoundTrip([3, -4.5, null, true, 'hi', false]);
    Expect.equals('[[3],[],[null],["hi",true]]',
                  JSON.stringify([[3], [], [null], ['hi', true]]));

    // Maps.
    expect(JSON.stringify({})).equals('{}');
    expect(JSON.stringify(new Map())).equals('{}');
    expect(JSON.stringify({'x':{}})).equals('{"x":{}}');
    expect(JSON.stringify({'x':{'a':3}})).equals('{"x":{"a":3}}');

    // Dart does not guarantee an order on the keys
    // of a map literal, so reparse and compare to the original Map.
    validateRoundTrip(
        {'x':3, 'y':-4.5, 'z':'hi', 'w':null, 'u':true, 'v':false});
    validateRoundTrip({"x":3, "y":-4.5, "z":'hi'});
    validateRoundTrip({' hi bob ':3, '':4.5});
    validateRoundTrip(
        {'x':{'a':3, 'b':-4.5}, 'y':[{}], 'z':'hi', 'w':{'c':null, 'd':true},
                  'v':null});
  });

  test('stringify throws if argument cannot be converted', () {
    /**
     * Checks that we get an exception (rather than silently returning null) if
     * we try to stringify something that cannot be converted to json.
     */
    expectThrow(() {
      JSON.stringify(new TestClass());
    });
  });
}

class TestClass {
  int x;
  String y;

  TestClass() : x = 3, y = 'joe' { }
}

/**
 * Checks that the argument can be converted to a JSON string and
 * back, and produce something equivalent to the argument.
 */
validateRoundTrip(expected) {
  expectValueEquals(expected, JSON.parse(JSON.stringify(expected)));
}

/**
 * Checks that expected value-equals actual, where value-equals is
 * the same as == except for Lists and Maps where it's recursive
 * value-equals.
 */
// TODO(chambers): Move into Expect class.
expectValueEquals(expected, actual, [String message = '']) {
  if (expected is List && actual is List) {
    int n = Math.min(expected.length, actual.length);
    for (int i = 0; i < n; i++) {
      expectValueEquals(expected[i], actual[i], 'at index ${i} ${message}');
    }
    // We check on length at the end in order to provide better error
    // messages when an unexpected item is inserted in a list.
    expect(actual.length).equals(expected.length);
  } else if (expected is Map && actual is Map) {
    expectIsContained(expected, actual, 'in actual ${message}');
    expectIsContained(actual, expected, 'in expected ${message}', false);
  } else {
    expect(actual).equals(expected);
  }
}

expectIsContained(Map expected, Map actual,
    [String message = '', bool checkValues = true]) {
  for (final key in expected.getKeys()) {
    expect(actual.containsKey(key)).equals(true);
    if (checkValues) {
      expectValueEquals(expected[key], actual[key],'at key ${key} ${message}');
    }
  }
}
