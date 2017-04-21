// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_tests;

import 'package:unittest/unittest.dart';
import 'dart:convert';

main() {
  test('Parse', () {
    // Scalars.
    expect(JSON.decode(' 5 '), equals(5));
    expect(JSON.decode(' -42 '), equals(-42));
    expect(JSON.decode(' 3e0 '), equals(3));
    expect(JSON.decode(' 3.14 '), equals(3.14));
    expect(JSON.decode('true '), isTrue);
    expect(JSON.decode(' false'), isFalse);
    expect(JSON.decode(' null '), isNull);
    expect(JSON.decode('\n\rnull\t'), isNull);
    expect(JSON.decode(' "hi there\\" bob" '), equals('hi there" bob'));
    expect(JSON.decode(' "" '), isEmpty);

    // Lists.
    expect(JSON.decode(' [] '), isEmpty);
    expect(JSON.decode('[ ]'), isEmpty);
    expect(JSON.decode(' [3, -4.5, true, "hi", false] '),
        equals([3, -4.5, true, 'hi', false]));
    // Nulls are tricky.
    expect(JSON.decode('[null]'), orderedEquals([null]));
    expect(JSON.decode(' [3, -4.5, null, true, "hi", false] '),
        equals([3, -4.5, null, true, 'hi', false]));
    expect(
        JSON.decode('[[null]]'),
        equals([
          [null]
        ]));
    expect(
        JSON.decode(' [ [3], [], [null], ["hi", true]] '),
        equals([
          [3],
          [],
          [null],
          ['hi', true]
        ]));

    // Maps.
    expect(JSON.decode(' {} '), isEmpty);
    expect(JSON.decode('{ }'), isEmpty);

    expect(
        JSON.decode(
            ' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '),
        equals({"x": 3, "y": -4.5, "z": "hi", "u": true, "v": false}));

    expect(JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi" } '),
        equals({"x": 3, "y": -4.5, "z": "hi"}));

    expect(JSON.decode(' {"y": -4.5,  "z" : "hi" ,"x":3 } '),
        equals({"y": -4.5, "z": "hi", "x": 3}));

    expect(JSON.decode('{ " hi bob " :3, "": 4.5}'),
        equals({" hi bob ": 3, "": 4.5}));

    expect(JSON.decode(' { "x" : { } } '), equals({'x': {}}));
    expect(JSON.decode('{"x":{}}'), equals({'x': {}}));

    // Nulls are tricky.
    expect(JSON.decode('{"w":null}'), equals({'w': null}));

    expect(
        JSON.decode('{"x":{"w":null}}'),
        equals({
          "x": {"w": null}
        }));

    expect(
        JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi",'
            '"w":null, "u" : true, "v": false } '),
        equals(
            {"x": 3, "y": -4.5, "z": "hi", "w": null, "u": true, "v": false}));

    expect(
        JSON.decode('{"x": {"a":3, "b": -4.5}, "y":[{}], '
            '"z":"hi","w":{"c":null,"d":true}, "v":null}'),
        equals({
          "x": {"a": 3, "b": -4.5},
          "y": [{}],
          "z": "hi",
          "w": {"c": null, "d": true},
          "v": null
        }));
  });

  test('stringify', () {
    // Scalars.
    expect(JSON.encode(5), equals('5'));
    expect(JSON.encode(-42), equals('-42'));
    // Dart does not guarantee a formatting for doubles,
    // so reparse and compare to the original.
    validateRoundTrip(3.14);
    expect(JSON.encode(true), equals('true'));
    expect(JSON.encode(false), equals('false'));
    expect(JSON.encode(null), equals('null'));
    expect(JSON.encode(' hi there" bob '), equals('" hi there\\" bob "'));
    expect(JSON.encode('hi\\there'), equals('"hi\\\\there"'));
    expect(JSON.encode('hi\nthere'), equals('"hi\\nthere"'));
    expect(JSON.encode('hi\r\nthere'), equals('"hi\\r\\nthere"'));
    expect(JSON.encode(''), equals('""'));

    // Lists.
    expect(JSON.encode([]), equals('[]'));
    expect(JSON.encode(new List(0)), equals('[]'));
    expect(JSON.encode(new List(3)), equals('[null,null,null]'));
    validateRoundTrip([3, -4.5, null, true, 'hi', false]);
    expect(
        JSON.encode([
          [3],
          [],
          [null],
          ['hi', true]
        ]),
        equals('[[3],[],[null],["hi",true]]'));

    // Maps.
    expect(JSON.encode({}), equals('{}'));
    expect(JSON.encode(new Map()), equals('{}'));
    expect(JSON.encode({'x': {}}), equals('{"x":{}}'));
    expect(
        JSON.encode({
          'x': {'a': 3}
        }),
        equals('{"x":{"a":3}}'));

    // Dart does not guarantee an order on the keys
    // of a map literal, so reparse and compare to the original Map.
    validateRoundTrip(
        {'x': 3, 'y': -4.5, 'z': 'hi', 'w': null, 'u': true, 'v': false});
    validateRoundTrip({"x": 3, "y": -4.5, "z": 'hi'});
    validateRoundTrip({' hi bob ': 3, '': 4.5});
    validateRoundTrip({
      'x': {'a': 3, 'b': -4.5},
      'y': [{}],
      'z': 'hi',
      'w': {'c': null, 'd': true},
      'v': null
    });

    expect(JSON.encode(new ToJson(4)), "4");
    expect(JSON.encode(new ToJson([4, "a"])), '[4,"a"]');
    expect(
        JSON.encode(new ToJson([
          4,
          new ToJson({"x": 42})
        ])),
        '[4,{"x":42}]');

    expect(() {
      JSON.encode([new ToJson(new ToJson(4))]);
    }, throwsJsonError);

    expect(() {
      JSON.encode([new Object()]);
    }, throwsJsonError);
  });

  test('stringify throws if argument cannot be converted', () {
    /**
     * Checks that we get an exception (rather than silently returning null) if
     * we try to stringify something that cannot be converted to json.
     */
    expect(() => JSON.encode(new TestClass()), throwsJsonError);
  });

  test('stringify throws if toJson throws', () {
    expect(
        () => JSON.encode(new ToJsoner("bad", throws: true)), throwsJsonError);
  });

  test('stringify throws if toJson returns non-serializable value', () {
    expect(() => JSON.encode(new ToJsoner(new TestClass())), throwsJsonError);
  });

  test('stringify throws on cyclic values', () {
    var a = [];
    var b = a;
    for (int i = 0; i < 50; i++) {
      b = [b];
    }
    a.add(b);
    expect(() => JSON.encode(a), throwsJsonError);
  });
}

class TestClass {
  int x;
  String y;

  TestClass()
      : x = 3,
        y = 'joe' {}
}

class ToJsoner {
  final Object returnValue;
  final bool throws;
  ToJsoner(this.returnValue, {this.throws});
  Object toJson() {
    if (throws) throw returnValue;
    return returnValue;
  }
}

class ToJson {
  final object;
  const ToJson(this.object);
  toJson() => object;
}

var throwsJsonError = throwsA(new isInstanceOf<JsonUnsupportedObjectError>());

/**
 * Checks that the argument can be converted to a JSON string and
 * back, and produce something equivalent to the argument.
 */
validateRoundTrip(expected) {
  expect(JSON.decode(JSON.encode(expected)), equals(expected));
}
