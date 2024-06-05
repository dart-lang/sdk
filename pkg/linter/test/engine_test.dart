// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/string_source.dart' show StringSource;
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
            LinterOptions(enabledRules: [MockLinter((n) => visited = true)]);
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

    group('dtos', () {
      group('hyperlink', () {
        test('html', () {
          var link = Hyperlink('dart', 'http://dart.dev');
          expect(link.html, '<a href="http://dart.dev">dart</a>');
        });
        test('html - strong', () {
          var link = Hyperlink('dart', 'http://dart.dev', bold: true);
          expect(
              link.html, '<a href="http://dart.dev"><strong>dart</strong></a>');
        });
      });
    });
  });
}

typedef NodeVisitor = void Function(Object node);

class MockLinter extends LintRule {
  final NodeVisitor nodeVisitor;
  MockLinter(this.nodeVisitor)
      : super(
            name: 'MockLint',
            group: Group.style,
            description: 'Desc',
            details: 'And so on...');

  @override
  PubspecVisitor getPubspecVisitor() => MockPubspecVisitor(nodeVisitor);
}

class MockPubspecVisitor extends PubspecVisitor {
  final NodeVisitor? nodeVisitor;

  MockPubspecVisitor(this.nodeVisitor);

  @override
  void visitPackageName(PSEntry node) {
    nodeVisitor?.call(node);
  }
}
