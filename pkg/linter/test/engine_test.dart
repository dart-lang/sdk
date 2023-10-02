// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart' show AstNode, AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart' hide CamelCaseString;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:linter/src/cli.dart' as cli;
import 'package:linter/src/utils.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'util/test_utils.dart';

void main() {
  defineLinterEngineTests();
}

/// Linter engine tests
void defineLinterEngineTests() {
  group('engine', () {
    setUp(setUpSharedTestEnvironment);
    group('reporter', () {
      void doTest(
          String label, String expected, Function(PrintingReporter r) report) {
        test(label, () {
          String? msg;
          var reporter = PrintingReporter((m) => msg = m);
          report(reporter);
          expect(msg, expected);
        });
      }

      doTest('exception', 'EXCEPTION: LinterException: foo',
          (r) => r.exception(LinterException('foo')));
      doTest('warn', 'WARN: foo', (r) => r.warn('foo'));
    });

    group('exceptions', () {
      test('message', () {
        expect(const LinterException('foo').message, 'foo');
      });
      test('toString', () {
        expect(const LinterException().toString(), 'LinterException');
        expect(const LinterException('foo').toString(), 'LinterException: foo');
      });
    });

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

    group('groups', () {
      test('factory', () {
        expect(Group('style').custom, isFalse);
        expect(Group('pub').custom, isFalse);
        expect(Group('errors').custom, isFalse);
        expect(Group('Kustom').custom, isTrue);
      });
      test('builtins', () {
        expect(Group.builtin.contains(Group.style), isTrue);
        expect(Group.builtin.contains(Group.errors), isTrue);
        expect(Group.builtin.contains(Group.pub), isTrue);
      });
    });

    group('lint driver', () {
      test('pubspec', () {
        bool? visited;
        var options = LinterOptions([MockLinter((n) => visited = true)]);
        SourceLinter(options).lintPubspecSource(contents: 'name: foo_bar');
        expect(visited, isTrue);
      });
      test('error collecting', () {
        var error = AnalysisError.tmp(
            source: StringSource('foo', ''),
            offset: 0,
            length: 0,
            errorCode: LintCode('MockLint', 'This is a test...'));
        var linter = SourceLinter(LinterOptions([]))..onError(error);
        expect(linter.errors.contains(error), isTrue);
      });
    });

    group('main', () {
      setUp(() {
        exitCode = 0;
        errorSink = MockIOSink();
      });
      tearDown(() {
        exitCode = 0;
        errorSink = stderr;
      });
      test('no args', () async {
        await cli.run([]);
        expect(exitCode, cli.unableToProcessExitCode);
      });
      test('help', () async {
        await cli.run(['-h']);
        // Help shouldn't generate an error code
        expect(cli.isLinterErrorCode(exitCode), isFalse);
      });
      test('unknown arg', () async {
        await cli.run(['-XXXXX']);
        expect(exitCode, cli.unableToProcessExitCode);
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

      group('rule', () {
        test('comparing', () {
          LintRule r1 = MockLintRule('Bar', Group('acme'));
          LintRule r2 = MockLintRule('Foo', Group('acme'));
          expect(r1.compareTo(r2), -1);
          LintRule r3 = MockLintRule('Bar', Group('acme'));
          LintRule r4 = MockLintRule('Bar', Group('woody'));
          expect(r3.compareTo(r4), -1);
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

  @override
  AstVisitor getVisitor() => MockVisitor(nodeVisitor);
}

class MockLintRule extends LintRule {
  MockLintRule(String name, Group group)
      : super(name: name, group: group, description: '', details: '');

  @override
  AstVisitor getVisitor() => MockVisitor(null);
}

class MockPubspecVisitor extends PubspecVisitor {
  final NodeVisitor? nodeVisitor;

  MockPubspecVisitor(this.nodeVisitor);

  @override
  void visitPackageName(PSEntry node) {
    nodeVisitor?.call(node);
  }
}

class MockVisitor extends GeneralizingAstVisitor {
  final NodeVisitor? nodeVisitor;

  MockVisitor(this.nodeVisitor);

  @override
  void visitNode(AstNode node) {
    nodeVisitor?.call(node);
  }
}
