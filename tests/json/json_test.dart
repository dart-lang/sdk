// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_tests;
import "package:expect/expect.dart";
import 'dart:json' as json;
import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

main() {
  useHtmlConfiguration();
  test('Parse', () {
    // Scalars.
    expect(json.parse(' 5 '), equals(5));
    expect(json.parse(' -42 '), equals(-42));
    expect(json.parse(' 3e0 '), equals(3));
    expect(json.parse(' 3.14 '), equals(3.14));
    expect(json.parse('true '), isTrue);
    expect(json.parse(' false'), isFalse);
    expect(json.parse(' null '), isNull);
    expect(json.parse('\n\rnull\t'), isNull);
    expect(json.parse(' "hi there\\" bob" '), equals('hi there" bob'));
    expect(json.parse(' "" '), isEmpty);

    // Lists.
    expect(json.parse(' [] '), isEmpty);
    expect(json.parse('[ ]'), isEmpty);
    expect(json.parse(' [3, -4.5, true, "hi", false] '),
      equals([3, -4.5, true, 'hi', false]));
    // Nulls are tricky.
    expect(json.parse('[null]'), orderedEquals([null]));
    expect(json.parse(' [3, -4.5, null, true, "hi", false] '),
      equals([3, -4.5, null, true, 'hi', false]));
    expect(json.parse('[[null]]'), equals([[null]]));
    expect(json.parse(' [ [3], [], [null], ["hi", true]] '),
      equals([[3], [], [null], ['hi', true]]));

    // Maps.
    expect(json.parse(' {} '), isEmpty);
    expect(json.parse('{ }'), isEmpty);

    expect(json.parse(
        ' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '),
        equals({"x":3, "y": -4.5,  "z" : "hi", "u" : true, "v": false }));

    expect(json.parse(' {"x":3, "y": -4.5,  "z" : "hi" } '),
        equals({"x":3, "y": -4.5,  "z" : "hi" }));

    expect(json.parse(' {"y": -4.5,  "z" : "hi" ,"x":3 } '),
        equals({"y": -4.5,  "z" : "hi" ,"x":3 }));

    expect(json.parse('{ " hi bob " :3, "": 4.5}'),
        equals({ " hi bob " :3, "": 4.5}));

    expect(json.parse(' { "x" : { } } '), equals({ 'x' : {}}));
    expect(json.parse('{"x":{}}'), equals({ 'x' : {}}));

    // Nulls are tricky.
    expect(json.parse('{"w":null}'), equals({ 'w' : null}));

    expect(json.parse('{"x":{"w":null}}'), equals({"x":{"w":null}}));

    expect(json.parse(' {"x":3, "y": -4.5,  "z" : "hi",'
                   '"w":null, "u" : true, "v": false } '),
        equals({"x":3, "y": -4.5,  "z" : "hi",
                   "w":null, "u" : true, "v": false }));

    expect(json.parse('{"x": {"a":3, "b": -4.5}, "y":[{}], '
                   '"z":"hi","w":{"c":null,"d":true}, "v":null}'),
        equals({"x": {"a":3, "b": -4.5}, "y":[{}],
                   "z":"hi","w":{"c":null,"d":true}, "v":null}));

  test('stringify', () {
    // Scalars.
    expect(json.stringify(5), equals('5'));
    expect(json.stringify(-42), equals('-42'));
    // Dart does not guarantee a formatting for doubles,
    // so reparse and compare to the original.
    validateRoundTrip(3.14);
    expect(json.stringify(true), equals('true'));
    expect(json.stringify(false), equals('false'));
    expect(json.stringify(null), equals('null'));
    expect(json.stringify(' hi there" bob '), equals('" hi there\\" bob "'));
    expect(json.stringify('hi\\there'), equals('"hi\\\\there"'));
    // TODO(devoncarew): these tests break the dartium build
    //expect(json.stringify('hi\nthere'), equals('"hi\\nthere"'));
    //expect(json.stringify('hi\r\nthere'), equals('"hi\\r\\nthere"'));
    expect(json.stringify(''), equals('""'));

    // Lists.
    expect(json.stringify([]), equals('[]'));
    expect(json.stringify(new List(0)), equals('[]'));
    expect(json.stringify(new List(3)), equals('[null,null,null]'));
    validateRoundTrip([3, -4.5, null, true, 'hi', false]);
    expect(json.stringify([[3], [], [null], ['hi', true]]),
      equals('[[3],[],[null],["hi",true]]'));

    // Maps.
    expect(json.stringify({}), equals('{}'));
    expect(json.stringify(new Map()), equals('{}'));
    expect(json.stringify({'x':{}}), equals('{"x":{}}'));
    expect(json.stringify({'x':{'a':3}}), equals('{"x":{"a":3}}'));

    // Dart does not guarantee an order on the keys
    // of a map literal, so reparse and compare to the original Map.
    validateRoundTrip(
        {'x':3, 'y':-4.5, 'z':'hi', 'w':null, 'u':true, 'v':false});
    validateRoundTrip({"x":3, "y":-4.5, "z":'hi'});
    validateRoundTrip({' hi bob ':3, '':4.5});
    validateRoundTrip(
        {'x':{'a':3, 'b':-4.5}, 'y':[{}], 'z':'hi', 'w':{'c':null, 'd':true},
                  'v':null});

    expect(json.stringify(new ToJson(4)), "4");
    expect(json.stringify(new ToJson([4, "a"])), '[4,"a"]');
    expect(json.stringify(new ToJson([4, new ToJson({"x":42})])),
           '[4,{"x":42}]');

    Expect.throws(() {
      json.stringify([new ToJson(new ToJson(4))]);
    });

    Expect.throws(() {
      json.stringify([new Object()]);
    });

  });

  test('stringify throws if argument cannot be converted', () {
    /**
     * Checks that we get an exception (rather than silently returning null) if
     * we try to stringify something that cannot be converted to json.
     */
    expect(() => json.stringify(new TestClass()), throws);
    });
  });
}

class TestClass {
  int x;
  String y;

  TestClass() : x = 3, y = 'joe' { }
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
  expect(json.parse(json.stringify(expected)), equals(expected));
}


