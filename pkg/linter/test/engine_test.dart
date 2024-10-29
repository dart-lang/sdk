// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:linter/src/test_utilities/linter_options.dart';
import 'package:linter/src/test_utilities/test_linter.dart';
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

    group('lint driver', () {
      test('pubspec', () {
        var visited = false;
        var options =
            LinterOptions(enabledRules: [MockLintRule((n) => visited = true)]);
        TestLinter(options).lintPubspecSource(contents: 'name: foo_bar');
        expect(visited, isTrue);
      });
      test('error collecting', () {
        var error = AnalysisError.tmp(
            source: StringSource('foo', ''),
            offset: 0,
            length: 0,
            errorCode: LintCode('MockLint', 'This is a test...'));
        var linter = TestLinter(LinterOptions(enabledRules: []))
          ..onError(error);
        expect(linter.errors.contains(error), isTrue);
      });
    });

    group('dtos', () {});
  });
}

typedef NodeVisitor = void Function(Object node);

class MockLintRule extends LintRule {
  final NodeVisitor nodeVisitor;
  MockLintRule(this.nodeVisitor) : super(name: 'MockLint', description: 'Desc');

  @override
  PubspecVisitor<void> getPubspecVisitor() => MockPubspecVisitor(nodeVisitor);
}

class MockPubspecVisitor extends PubspecVisitor<void> {
  final NodeVisitor? nodeVisitor;

  MockPubspecVisitor(this.nodeVisitor);

  @override
  void visitPackageName(PSEntry node) {
    nodeVisitor?.call(node);
  }
}
