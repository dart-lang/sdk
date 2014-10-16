// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils_test;

import 'package:unittest/unittest.dart';
import 'test_pub.dart';
import '../lib/src/utils.dart';

main() {
  initConfig();

  group('yamlToString()', () {
    test('null', () {
      expect(yamlToString(null), equals('null'));
    });

    test('numbers', () {
      expect(yamlToString(123), equals('123'));
      expect(yamlToString(12.34), equals('12.34'));
    });

    test('does not quote strings that do not need it', () {
      expect(yamlToString('a'), equals('a'));
      expect(yamlToString('some-string'), equals('some-string'));
      expect(yamlToString('hey123CAPS'), equals('hey123CAPS'));
      expect(yamlToString("_under_score"), equals('_under_score'));
    });

    test('quotes other strings', () {
      expect(yamlToString(''), equals('""'));
      expect(yamlToString('123'), equals('"123"'));
      expect(yamlToString('white space'), equals('"white space"'));
      expect(yamlToString('"quote"'), equals(r'"\"quote\""'));
      expect(yamlToString("apostrophe'"), equals('"apostrophe\'"'));
      expect(yamlToString("new\nline"), equals(r'"new\nline"'));
      expect(yamlToString("?unctu@t!on"), equals(r'"?unctu@t!on"'));
    });

    test('lists use JSON style', () {
      expect(yamlToString([1, 2, 3]), equals('[1,2,3]'));
    });

    test('uses indentation for maps', () {
      expect(yamlToString({
        'a': {
          'b': 1,
          'c': 2
        },
        'd': 3
      }), equals("""
a:
  b: 1
  c: 2
d: 3"""));
    });

    test('sorts map keys', () {
      expect(yamlToString({
        'a': 1,
        'c': 2,
        'b': 3,
        'd': 4
      }), equals("""
a: 1
b: 3
c: 2
d: 4"""));
    });

    test('quotes map keys as needed', () {
      expect(yamlToString({
        'no': 1,
        'yes!': 2,
        '123': 3
      }), equals("""
"123": 3
no: 1
"yes!": 2"""));
    });

    test('handles non-string map keys', () {
      var map = new Map();
      map[null] = "null";
      map[123] = "num";
      map[true] = "bool";

      expect(yamlToString(map), equals("""
123: num
null: null
true: bool"""));
    });

    test('handles empty maps', () {
      expect(yamlToString({}), equals("{}"));
      expect(yamlToString({
        'a': {},
        'b': {}
      }), equals("""
a: {}
b: {}"""));
    });
  });
}
