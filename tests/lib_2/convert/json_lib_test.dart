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
  Expect.equals(5, json.decode(' 5 '));
  Expect.equals(-42, json.decode(' -42 '));
  Expect.equals(3, json.decode(' 3e0 '));
  Expect.equals(3.14, json.decode(' 3.14 '));
  Expect.isTrue(json.decode('true '));
  Expect.isFalse(json.decode(' false'));
  Expect.isNull(json.decode(' null '));
  Expect.isNull(json.decode('\n\rnull\t'));
  Expect.equals('hi there" bob', json.decode(' "hi there\\" bob" '));
  Expect.equals('', json.decode(' "" '));

  // Lists.
  Expect.deepEquals([], json.decode(' [] '));
  Expect.deepEquals([], json.decode('[ ]'));
  Expect.deepEquals([3, -4.5, true, 'hi', false],
      json.decode(' [3, -4.5, true, "hi", false] '));
  // Nulls are tricky.
  Expect.deepEquals([null], json.decode('[null]'));
  Expect.deepEquals([3, -4.5, null, true, 'hi', false],
      json.decode(' [3, -4.5, null, true, "hi", false] '));
  Expect.deepEquals([
    [null]
  ], json.decode('[[null]]'));
  Expect.deepEquals([
    [3],
    [],
    [null],
    ['hi', true]
  ], json.decode(' [ [3], [], [null], ["hi", true]] '));

  // Maps.
  Expect.deepEquals({}, json.decode(' {} '));
  Expect.deepEquals({}, json.decode('{ }'));

  Expect.deepEquals({"x": 3, "y": -4.5, "z": "hi", "u": true, "v": false},
      json.decode(' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '));

  Expect.deepEquals({"x": 3, "y": -4.5, "z": "hi"},
      json.decode(' {"x":3, "y": -4.5,  "z" : "hi" } '));

  Expect.deepEquals({"y": -4.5, "z": "hi", "x": 3},
      json.decode(' {"y": -4.5,  "z" : "hi" ,"x":3 } '));

  Expect.deepEquals(
      {" hi bob ": 3, "": 4.5}, json.decode('{ " hi bob " :3, "": 4.5}'));

  Expect.deepEquals({'x': {}}, json.decode(' { "x" : { } } '));
  Expect.deepEquals({'x': {}}, json.decode('{"x":{}}'));

  // Nulls are tricky.
  Expect.deepEquals({'w': null}, json.decode('{"w":null}'));

  Expect.deepEquals({
    "x": {"w": null}
  }, json.decode('{"x":{"w":null}}'));

  Expect.deepEquals(
      {"x": 3, "y": -4.5, "z": "hi", "w": null, "u": true, "v": false},
      json.decode(' {"x":3, "y": -4.5,  "z" : "hi",'
          '"w":null, "u" : true, "v": false } '));

  Expect.deepEquals(
      {
        "x": {"a": 3, "b": -4.5},
        "y": [{}],
        "z": "hi",
        "w": {"c": null, "d": true},
        "v": null
      },
      json.decode('{"x": {"a":3, "b": -4.5}, "y":[{}], '
          '"z":"hi","w":{"c":null,"d":true}, "v":null}'));
}

void testStringify() {
  // Scalars.
  Expect.equals('5', json.encode(5));
  Expect.equals('-42', json.encode(-42));
  // Dart does not guarantee a formatting for doubles,
  // so reparse and compare to the original.
  validateRoundTrip(3.14);
  Expect.equals('true', json.encode(true));
  Expect.equals('false', json.encode(false));
  Expect.equals('null', json.encode(null));
  Expect.equals('" hi there\\" bob "', json.encode(' hi there" bob '));
  Expect.equals('"hi\\\\there"', json.encode('hi\\there'));
  Expect.equals('"hi\\nthere"', json.encode('hi\nthere'));
  Expect.equals('"hi\\r\\nthere"', json.encode('hi\r\nthere'));
  Expect.equals('""', json.encode(''));

  // Lists.
  Expect.equals('[]', json.encode([]));
  Expect.equals('[]', json.encode(new List(0)));
  Expect.equals('[null,null,null]', json.encode(new List(3)));
  validateRoundTrip([3, -4.5, null, true, 'hi', false]);
  Expect.equals(
      '[[3],[],[null],["hi",true]]',
      json.encode([
        [3],
        [],
        [null],
        ['hi', true]
      ]));

  // Maps.
  Expect.equals('{}', json.encode({}));
  Expect.equals('{}', json.encode(new Map()));
  Expect.equals('{"x":{}}', json.encode({'x': {}}));
  Expect.equals(
      '{"x":{"a":3}}',
      json.encode({
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

  Expect.equals("4", json.encode(new ToJson(4)));
  Expect.equals('[4,"a"]', json.encode(new ToJson([4, "a"])));
  Expect.equals(
      '[4,{"x":42}]',
      json.encode(new ToJson([
        4,
        new ToJson({"x": 42})
      ])));

  expectThrowsJsonError(() => json.encode([new ToJson(new ToJson(4))]));
  expectThrowsJsonError(() => json.encode([new Object()]));
}

void testStringifyErrors() {
  // Throws if argument cannot be converted.
  expectThrowsJsonError(() => json.encode(new TestClass()));

  // Throws if toJson throws.
  expectThrowsJsonError(() => json.encode(new ToJsoner("bad", throws: true)));

  // Throws if toJson returns non-serializable value.
  expectThrowsJsonError(() => json.encode(new ToJsoner(new TestClass())));

  // Throws on cyclic values.
  var a = [];
  var b = a;
  for (int i = 0; i < 50; i++) {
    b = [b];
  }
  a.add(b);
  expectThrowsJsonError(() => json.encode(a));
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
  Expect.deepEquals(expected, json.decode(json.encode(expected)));
}
