// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:modular_test/src/test_specification_parser.dart';

main() {
  test('require dependencies section', () {
    expect(() => parseTestSpecification(""),
        throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('dependencies is a map', () {
    expect(() => parseTestSpecification("dependencies: []"),
        throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('dependencies can be a string or list of strings', () {
    parseTestSpecification('''
          dependencies:
            a: b
          ''');

    parseTestSpecification('''
          dependencies:
            a: [b, c]
          ''');

    expect(() => parseTestSpecification('''
          dependencies:
            a: 1
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseTestSpecification('''
          dependencies:
            a: true
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseTestSpecification('''
          dependencies:
            a: [false]
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseTestSpecification('''
          dependencies:
            a:
               c: d
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('result map is normalized', () {
    expect(
        parseTestSpecification('''
          dependencies:
            a: [b, c]
            b: d
            ''').dependencies,
        equals({
          'a': ['b', 'c'],
          'b': ['d'],
        }));
  });

  test('flags are normalized', () {
    expect(parseTestSpecification('''
          dependencies: {}
          flags: "a"
            ''').flags, equals(["a"]));

    expect(parseTestSpecification('''
          dependencies: {}
          flags: ["a"]
            ''').flags, equals(["a"]));
  });
}
