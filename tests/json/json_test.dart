// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('json_tests');

#import('dart:json');
#import('dart:html');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');

main() {
  useHtmlConfiguration();
  test('Parse', () {
    // Scalars.
    expect(JSON.parse(' 5 '), equals(5));
    expect(JSON.parse(' -42 '), equals(-42));
    expect(JSON.parse(' 3e0 '), equals(3));
    expect(JSON.parse(' 3.14 '), equals(3.14));
    expect(JSON.parse('true '), isTrue);
    expect(JSON.parse(' false'), isFalse);
    expect(JSON.parse(' null '), isNull);
    expect(JSON.parse('\n\rnull\t'), isNull);
    expect(JSON.parse(' "hi there\\" bob" '), equals('hi there" bob'));
    expect(JSON.parse(' "" '), isEmpty);

    // Lists.
    expect(JSON.parse(' [] '), isEmpty);
    expect(JSON.parse('[ ]'), isEmpty);
    expect(JSON.parse(' [3, -4.5, true, "hi", false] '),
      equals([3, -4.5, true, 'hi', false]));
    // Nulls are tricky.
    expect(JSON.parse('[null]'), orderedEquals([null]));
    expect(JSON.parse(' [3, -4.5, null, true, "hi", false] '),
      equals([3, -4.5, null, true, 'hi', false]));
    expect(JSON.parse('[[null]]'), equals([[null]]));
    expect(JSON.parse(' [ [3], [], [null], ["hi", true]] '),
      equals([[3], [], [null], ['hi', true]]));

    // Maps.
    expect(JSON.parse(' {} '), isEmpty);
    expect(JSON.parse('{ }'), isEmpty);

    expect(JSON.parse(
        ' {"x":3, "y": -4.5,  "z" : "hi","u" : true, "v": false } '),
        equals({"x":3, "y": -4.5,  "z" : "hi", "u" : true, "v": false }));

    expect(JSON.parse(' {"x":3, "y": -4.5,  "z" : "hi" } '),
        equals({"x":3, "y": -4.5,  "z" : "hi" }));

    expect(JSON.parse(' {"y": -4.5,  "z" : "hi" ,"x":3 } '),
        equals({"y": -4.5,  "z" : "hi" ,"x":3 }));

    expect(JSON.parse('{ " hi bob " :3, "": 4.5}'),
        equals({ " hi bob " :3, "": 4.5}));
  
    expect(JSON.parse(' { "x" : { } } '), equals({ 'x' : {}}));
    expect(JSON.parse('{"x":{}}'), equals({ 'x' : {}}));

    // Nulls are tricky.
    expect(JSON.parse('{"w":null}'), equals({ 'w' : null}));

    expect(JSON.parse('{"x":{"w":null}}'), equals({"x":{"w":null}}));

    expect(JSON.parse(' {"x":3, "y": -4.5,  "z" : "hi",'
                   '"w":null, "u" : true, "v": false } '),
        equals({"x":3, "y": -4.5,  "z" : "hi",
                   "w":null, "u" : true, "v": false }));

    expect(JSON.parse('{"x": {"a":3, "b": -4.5}, "y":[{}], '
                   '"z":"hi","w":{"c":null,"d":true}, "v":null}'),
        equals({"x": {"a":3, "b": -4.5}, "y":[{}],
                   "z":"hi","w":{"c":null,"d":true}, "v":null}));

  test('stringify', () {
    // Scalars.
    expect(JSON.stringify(5), equals('5'));
    expect(JSON.stringify(-42), equals('-42'));
    // Dart does not guarantee a formatting for doubles,
    // so reparse and compare to the original.
    validateRoundTrip(3.14);
    expect(JSON.stringify(true), equals('true'));
    expect(JSON.stringify(false), equals('false'));
    expect(JSON.stringify(null), equals('null'));
    expect(JSON.stringify(' hi there" bob '), equals('" hi there\\" bob "'));
    expect(JSON.stringify('hi\\there'), equals('"hi\\\\there"'));
    // TODO(devoncarew): these tests break the dartium build
    //expect(JSON.stringify('hi\nthere'), equals('"hi\\nthere"'));
    //expect(JSON.stringify('hi\r\nthere'), equals('"hi\\r\\nthere"'));
    expect(JSON.stringify(''), equals('""'));

    // Lists.
    expect(JSON.stringify([]), equals('[]'));
    expect(JSON.stringify(new List(0)), equals('[]'));
    expect(JSON.stringify(new List(3)), equals('[null,null,null]'));
    validateRoundTrip([3, -4.5, null, true, 'hi', false]);
    expect(JSON.stringify([[3], [], [null], ['hi', true]]),
      equals('[[3],[],[null],["hi",true]]'));

    // Maps.
    expect(JSON.stringify({}), equals('{}'));
    expect(JSON.stringify(new Map()), equals('{}'));
    expect(JSON.stringify({'x':{}}), equals('{"x":{}}'));
    expect(JSON.stringify({'x':{'a':3}}), equals('{"x":{"a":3}}'));

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
    expect(() => JSON.stringify(new TestClass()), throws);
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
  expect(JSON.parse(JSON.stringify(expected)), equals(expected));
}


