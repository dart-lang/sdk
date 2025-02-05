// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/utils.dart';
import 'package:test/test.dart';

import 'util/test_utils.dart';

void main() {
  defineLinterEngineTests();
}

/// Linter engine tests
void defineLinterEngineTests() {
  group('engine', () {
    setUp(setUpSharedTestEnvironment);

    group('camel case', () {
      test('humanize', () {
        expect(CamelCaseString('FooBar').humanized, 'Foo Bar');
        expect(CamelCaseString('Foo').humanized, 'Foo');
      });
      test('validation', () {
        expect(() => CamelCaseString('foo'),
            throwsA(TypeMatcher<ArgumentError>()));
      });
      test('toString', () {
        expect(CamelCaseString('FooBar').toString(), 'FooBar');
      });
    });

    group('dtos', () {});
  });
}
