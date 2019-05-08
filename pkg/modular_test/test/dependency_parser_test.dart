// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:modular_test/src/dependency_parser.dart';

main() {
  test('require dependencies section', () {
    expect(() => parseDependencyMap(""),
        throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('dependencies is a map', () {
    expect(() => parseDependencyMap("dependencies: []"),
        throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('dependencies can be a string or list of strings', () {
    parseDependencyMap('''
          dependencies:
            a: b
          ''');

    parseDependencyMap('''
          dependencies:
            a: [b, c]
          ''');

    expect(() => parseDependencyMap('''
          dependencies:
            a: 1
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseDependencyMap('''
          dependencies:
            a: true
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseDependencyMap('''
          dependencies:
            a: [false]
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));

    expect(() => parseDependencyMap('''
          dependencies:
            a:
               c: d
          '''), throwsA(TypeMatcher<InvalidSpecificationError>()));
  });

  test('result map is normalized', () {
    expect(
        parseDependencyMap('''
          dependencies:
            a: [b, c]
            b: d
            '''),
        equals({
          'a': ['b', 'c'],
          'b': ['d'],
        }));
  });
}
