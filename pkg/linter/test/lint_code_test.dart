// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_codes.dart';
import 'package:test/test.dart';

import 'rule_test_support.dart';

void main() {
  group('lint code', () {
    group('creation', () {
      test('without published diagnostic docs', () {
        expect(
          _customCode.url,
          equals('https://dart.dev/lints/${_customCode.name}'),
        );
      });

      test('with published diagnostic docs', () {
        expect(
          _customCodeWithDocs.url,
          equals('https://dart.dev/diagnostics/${_customCodeWithDocs.name}'),
        );
      });
    });
  });
}

const LintCode _customCode = LinterLintCode.internal(
  name: 'hash_and_equals',
  problemMessage: 'Override `==` if overriding `hashCode`.',
  correctionMessage: 'Implement `==`.',
  expectedTypes: [],
  uniqueNameCheck: 'LintCode.hash_and_equals',
);

const LintCode _customCodeWithDocs = LinterLintCode.internal(
  name: 'hash_and_equals',
  problemMessage: 'Override `==` if overriding `hashCode`.',
  correctionMessage: 'Implement `==`.',
  hasPublishedDocs: true,
  expectedTypes: [],
  uniqueNameCheck: 'LintCode.hash_and_equals',
);
