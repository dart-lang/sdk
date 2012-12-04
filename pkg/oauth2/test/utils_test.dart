// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils_test;

import '../../unittest/lib/unittest.dart';
import '../lib/src/utils.dart';


void main() {
  group('AuthenticateHeader', () {
    test("parses a scheme", () {
      var header = new AuthenticateHeader.parse('bearer');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({}));
    });

    test("lower-cases the scheme", () {
      var header = new AuthenticateHeader.parse('BeaRer');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({}));
    });

    test("parses a scheme with trailing whitespace", () {
      var header = new AuthenticateHeader.parse('bearer   ');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({}));
    });

    test("parses a scheme with one param", () {
      var header = new AuthenticateHeader.parse('bearer  foo="bar"');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({'foo': 'bar'}));
    });

    test("parses a scheme with several params", () {
      var header = new AuthenticateHeader.parse(
          'bearer foo="bar", bar="baz"  ,baz="qux"');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({
        'foo': 'bar',
        'bar': 'baz',
        'baz': 'qux'
      }));
    });

    test("lower-cases parameter names but not values", () {
      var header = new AuthenticateHeader.parse('bearer FoO="bAr"');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({'foo': 'bAr'}));
    });

    test("allows empty values", () {
      var header = new AuthenticateHeader.parse('bearer foo=""');
      expect(header.scheme, equals('bearer'));
      expect(header.parameters, equals({'foo': ''}));
    });

    test("won't parse an empty string", () {
      expect(() => new AuthenticateHeader.parse(''),
          throwsFormatException);
    });

    test("won't parse a token without a value", () {
      expect(() => new AuthenticateHeader.parse('bearer foo'),
          throwsFormatException);

      expect(() => new AuthenticateHeader.parse('bearer foo='),
          throwsFormatException);
    });

    test("won't parse a token without a value", () {
      expect(() => new AuthenticateHeader.parse('bearer foo'),
          throwsFormatException);

      expect(() => new AuthenticateHeader.parse('bearer foo='),
          throwsFormatException);
    });

    test("won't parse a trailing comma", () {
      expect(() => new AuthenticateHeader.parse('bearer foo="bar",'),
          throwsFormatException);
    });

    test("won't parse a multiple params without a comma", () {
      expect(() => new AuthenticateHeader.parse('bearer foo="bar" bar="baz"'),
          throwsFormatException);
    });
  });
}
