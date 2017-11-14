// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:convert';

main() {
  testParsing();
  testStringify();
  testStringifyErrors();
}

void testParsing() {
  // Scalars.
  Expect.equals(5, JSON.decode(' 5 '));
  Expect.equals(-42, JSON.decode(' -42 '));
  Expect.equals(3, JSON.decode(' 3e0 '));
  Expect.equals(3.14, JSON.decode(' 3.14 '));
  Expect.isTrue(JSON.decode('true '));
  Expect.isFalse(JSON.decode(' false'));
  Expect.isNull(JSON.decode(' null '));
  Expect.isNull(JSON.decode('\n\rnull\t'));
  Expect.equals('hi there" bob', JSON.decode(' "hi there\\" bob" '));
  Expect.equals('', JSON.decode(' "" '));

  // Lists.
  Expect.deepEquals([], JSON.decode(' [] '));
  Expect.deepEquals([], JSON.decode('[ ]'));
  Expect.deepEquals([3, -4.5, true, 'hi', false],
      JSON.decode(' [3, -4.5, true, "hi", false] '));
  // Nulls are tricky.
  Expect.deepEquals([null], JSON.decode('[null]'));
  Expect.deepEquals([3, -4.5, null, true, 'hi', false],
      JSON.decode(' [3, -4.5, null, true, "hi", false] '));
  Expect.deepEquals([
    [null]
  ], JSON.decode('[[null]]'));
  Expect.deepEquals([
    [3],
    [],
    [null],
    ['hi', true]
  ], JSON.decode(' [ [3], [], [null], ["hi", true]] '));

  // Maps.
  Expect.deepEquals({}, JSON.decode(' {} '));
  Expect.deepEquals({}, JSON.decode('{ }'));

  Expect.deepEquals({"x": 3, "y": -4.5, "z": "hi", "u": true, "v": false},
      JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '));

  Expect.deepEquals({"x": 3, "y": -4.5, "z": "hi"},
      JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi" } '));

  Expect.deepEquals({"y": -4.5, "z": "hi", "x": 3},
      JSON.decode(' {"y": -4.5,  "z" : "hi" ,"x":3 } '));

  Expect.deepEquals(
      {" hi bob ": 3, "": 4.5}, JSON.decode('{ " hi bob " :3, "": 4.5}'));

  Expect.deepEquals({'x': {}}, JSON.decode(' { "x" : { } } '));
  Expect.deepEquals({'x': {}}, JSON.decode('{"x":{}}'));

  // Nulls are tricky.
  Expect.deepEquals({'w': null}, JSON.decode('{"w":null}'));

  Expect.deepEquals({
    "x": {"w": null}
  }, JSON.decode('{"x":{"w":null}}'));

  Expect.deepEquals(
      {"x": 3, "y": -4.5, "z": "hi", "w": null, "u": true, "v": false},
      JSON.decode(' {"x":3, "y": -4.5,  "z" : "hi",'
          '"w":null, "u" : true, "v": false } '));

  Expect.deepEquals(
      {
        "x": {"a": 3, "b": -4.5},
        "y": [{}],
        "z": "hi",
        "w": {"c": null, "d": true},
        "v": null
      },
      JSON.decode('{"x": {"a":3, "b": -4.5}, "y":[{}], '
          '"z":"hi","w":{"c":null,"d":true}, "v":null}'));
}

void testStringify() {
  // Scalars.
  Expect.equals('5', JSON.encode(5));
  Expect.equals('-42', JSON.encode(-42));
  // Dart does not guarantee a formatting for doubles,
  // so reparse and compare to the original.
  validateRoundTrip(3.14);
  Expect.equals('true', JSON.encode(true));
  Expect.equals('false', JSON.encode(false));
  Expect.equals('null', JSON.encode(null));
  Expect.equals('" hi there\\" bob "', JSON.encode(' hi there" bob '));
  Expect.equals('"hi\\\\there"', JSON.encode('hi\\there'));
  Expect.equals('"hi\\nthere"', JSON.encode('hi\nthere'));
  Expect.equals('"hi\\r\\nthere"', JSON.encode('hi\r\nthere'));
  Expect.equals('""', JSON.encode(''));

  // Lists.
  Expect.equals('[]', JSON.encode([]));
  Expect.equals('[]', JSON.encode(new List(0)));
  Expect.equals('[null,null,null]', JSON.encode(new List(3)));
  validateRoundTrip([3, -4.5, null, true, 'hi', false]);
  Expect.equals(
      '[[3],[],[null],["hi",true]]',
      JSON.encode([
        [3],
        [],
        [null],
        ['hi', true]
      ]));

  // Maps.
  Expect.equals('{}', JSON.encode({}));
  Expect.equals('{}', JSON.encode(new Map()));
  Expect.equals('{"x":{}}', JSON.encode({'x': {}}));
  Expect.equals(
      '{"x":{"a":3}}',
      JSON.encode({
        'x': {'a': 3}
      }));

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

  Expect.equals("4", JSON.encode(new ToJson(4)));
  Expect.equals('[4,"a"]', JSON.encode(new ToJson([4, "a"])));
  Expect.equals(
      '[4,{"x":42}]',
      JSON.encode(new ToJson([
        4,
        new ToJson({"x": 42})
      ])));

  expectThrowsJsonError(() => JSON.encode([new ToJson(new ToJson(4))]));
  expectThrowsJsonError(() => JSON.encode([new Object()]));
}

void testStringifyErrors() {
  // Throws if argument cannot be converted.
  expectThrowsJsonError(() => JSON.encode(new TestClass()));

  // Throws if toJson throws.
  expectThrowsJsonError(() => JSON.encode(new ToJsoner("bad", throws: true)));

  // Throws if toJson returns non-serializable value.
  expectThrowsJsonError(() => JSON.encode(new ToJsoner(new TestClass())));

  // Throws on cyclic values.
  var a = [];
  var b = a;
  for (int i = 0; i < 50; i++) {
    b = [b];
  }
  a.add(b);
  expectThrowsJsonError(() => JSON.encode(a));
}

void expectThrowsJsonError(void f()) {
  Expect.throws(f, (e) => e is JsonUnsupportedObjectError);
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

/**
 * Checks that the argument can be converted to a JSON string and
 * back, and produce something equivalent to the argument.
 */
validateRoundTrip(expected) {
  Expect.deepEquals(expected, JSON.decode(JSON.encode(expected)));
}
