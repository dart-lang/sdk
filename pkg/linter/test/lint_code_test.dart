// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/linter_lint_codes.dart';
import 'package:test/test.dart';

import 'rule_test_support.dart';

void main() {
  group('lint code', () {
    group('creation', () {
      test('without published diagnostic docs', () {
        expect(_customCode.url,
            equals('https://dart.dev/lints/${_customCode.name}'));
      });

      test('with published diagnostic docs', () {
        expect(_customCodeWithDocs.url,
            equals('https://dart.dev/diagnostics/${_customCodeWithDocs.name}'));
      });
    });
  });
}

const LintCode _customCode = LinterLintCode(
    'hash_and_equals', 'Override `==` if overriding `hashCode`.',
    correctionMessage: 'Implement `==`.');

const LintCode _customCodeWithDocs = LinterLintCode(
    'hash_and_equals', 'Override `==` if overriding `hashCode`.',
    correctionMessage: 'Implement `==`.', hasPublishedDocs: true);
