// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart' show AstNode, AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/analysis.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:cli_util/cli_util.dart' show getSdkPath;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../bin/linter.dart' as dartlint;
import 'mocks.dart';
import 'rule_test.dart' show ruleDir;

main() {
  defineLinterEngineTests();
}

/// Linter engine tests
void defineLinterEngineTests() {
  group('engine', () {
    group('reporter', () {
      _test(String label, String expected, report(PrintingReporter r)) {
        test(label, () {
          String msg;
          PrintingReporter reporter = new PrintingReporter((m) => msg = m);
          report(reporter);
          expect(msg, expected);
        });
      }

      _test('exception', 'EXCEPTION: LinterException: foo',
          (r) => r.exception(new LinterException('foo')));
      _test('logError', 'ERROR: foo', (r) => r.logError('foo'));
      _test('logInformation', 'INFO: foo', (r) => r.logInformation('foo'));
      _test('warn', 'WARN: foo', (r) => r.warn('foo'));
    });

    group('exceptions', () {
      test('message', () {
        expect(const LinterException('foo').message, equals('foo'));
      });
      test('toString', () {
        expect(const LinterException().toString(), equals('LinterException'));
        expect(const LinterException('foo').toString(),
            equals('LinterException: foo'));
      });
    });

    group('analysis logger', () {
      var currentErr = errorSink;
      var currentOut = outSink;
      var errCollector = new CollectingSink();
      var outCollector = new CollectingSink();
      var logger = new StdLogger();
      setUp(() {
        errorSink = errCollector;
        outSink = outCollector;
      });
      tearDown(() {
        errorSink = currentErr;
        outSink = currentOut;
        errCollector.buffer.clear();
        outCollector.buffer.clear();
      });
      test('logError', () {
        logger.logError('logError');
        expect(errCollector.trim(), equals('logError'));
      });
      test('logInformation', () {
        logger.logInformation('logInformation');
        expect(outCollector.trim(), equals('logInformation'));
      });
    });

    group('camel case', () {
      test('humanize', () {
        expect(new CamelCaseString('FooBar').humanized, equals('Foo Bar'));
        expect(new CamelCaseString('Foo').humanized, equals('Foo'));
      });
      test('validation', () {
        expect(() => new CamelCaseString('foo'),
            throwsA(new isInstanceOf<ArgumentError>()));
      });
      test('toString', () {
        expect(new CamelCaseString('FooBar').toString(), equals('FooBar'));
      });
    });

    group('groups', () {
      test('factory', () {
        expect(new Group('style').custom, isFalse);
        expect(new Group('pub').custom, isFalse);
        expect(new Group('errors').custom, isFalse);
        expect(new Group('Kustom').custom, isTrue);
      });
      test('builtins', () {
        expect(Group.builtin.contains(Group.style), isTrue);
        expect(Group.builtin.contains(Group.errors), isTrue);
        expect(Group.builtin.contains(Group.pub), isTrue);
      });
    });

    group('lint driver', () {
      test('pubspec', () {
        bool visited;
        var options =
            new LinterOptions([new MockLinter((n) => visited = true)]);
        new SourceLinter(options).lintPubspecSource(contents: 'name: foo_bar');
        expect(visited, isTrue);
      });
      test('error collecting', () {
        var error = new AnalysisError(new StringSource('foo', ''), 0, 0,
            new LintCode('MockLint', 'This is a test...'));
        var linter = new SourceLinter(new LinterOptions([]))..onError(error);
        expect(linter.errors.contains(error), isTrue);
      });
      test('pubspec visitor error handling', () {
        var rule = new MockRule();
        var visitor = new MockPubVisitor();
        when(visitor.visitPackageAuthor(any))
            .thenAnswer((_) => throw new Exception());
        when(rule.getPubspecVisitor()).thenReturn(visitor);

        var reporter = new MockReporter();
        new SourceLinter(new LinterOptions([rule]), reporter: reporter)
          ..lintPubspecSource(contents: 'author: foo');
        verify(reporter.exception(any)).called(1);
      });
    });

    group('main', () {
      setUp(() {
        exitCode = 0;
        errorSink = new MockIOSink();
      });
      tearDown(() {
        exitCode = 0;
        errorSink = stderr;
      });
      test('smoke', () async {
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        await dartlint.main([firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('no args', () async {
        await dartlint.main([]);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('help', () async {
        await dartlint.main(['-h']);
        // Help shouldn't generate an error code
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('unknown arg', () async {
        await dartlint.main(['-XXXXX']);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('custom sdk path', () async {
        // Smoke test to ensure a custom sdk path doesn't sink the ship
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        var sdk = getSdkPath();
        await dartlint.main(['--dart-sdk', sdk, firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('custom package root', () async {
        // Smoke test to ensure a custom package root doesn't sink the ship
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        var packageDir = new Directory('.').path;
        await dartlint.main(['--package-root', packageDir, firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
    });

    group('dtos', () {
      group('hyperlink', () {
        test('html', () {
          Hyperlink link = new Hyperlink('dart', 'http://dartlang.org');
          expect(link.html, equals('<a href="http://dartlang.org">dart</a>'));
        });
        test('html - strong', () {
          Hyperlink link =
              new Hyperlink('dart', 'http://dartlang.org', bold: true);
          expect(
              link.html,
              equals(
                  '<a href="http://dartlang.org"><strong>dart</strong></a>'));
        });
      });

      group('rule', () {
        test('comparing', () {
          LintRule r1 = new MockLintRule('Bar', new Group('acme'));
          LintRule r2 = new MockLintRule('Foo', new Group('acme'));
          expect(r1.compareTo(r2), equals(-1));
          LintRule r3 = new MockLintRule('Bar', new Group('acme'));
          LintRule r4 = new MockLintRule('Bar', new Group('woody'));
          expect(r3.compareTo(r4), equals(-1));
        });
      });
      group('maturity', () {
        test('comparing', () {
          // Custom
          Maturity m1 = new Maturity('foo', ordinal: 0);
          Maturity m2 = new Maturity('bar', ordinal: 1);
          expect(m1.compareTo(m2), equals(-1));
          // Builtin
          expect(Maturity.stable.compareTo(Maturity.experimental), equals(-1));
        });
      });
    });
  });
}

typedef nodeVisitor(node);

typedef dynamic /* AstVisitor, PubSpecVisitor*/ VisitorCallback();

class MockLinter extends LintRule {
  VisitorCallback visitorCallback;

  MockLinter([nodeVisitor v])
      : super(
            name: 'MockLint',
            group: Group.style,
            description: 'Desc',
            details: 'And so on...') {
    visitorCallback = () => new MockVisitor(v);
  }

  @override
  PubspecVisitor getPubspecVisitor() => visitorCallback();

  @override
  AstVisitor getVisitor() => visitorCallback();
}

class MockLintRule extends LintRule {
  MockLintRule(String name, Group group) : super(name: name, group: group);

  @override
  AstVisitor getVisitor() => new MockVisitor(null);
}

class MockVisitor extends GeneralizingAstVisitor with PubspecVisitor {
  final nodeVisitor;

  MockVisitor(this.nodeVisitor);

  @override
  visitNode(AstNode node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }

  @override
  visitPackageName(PSEntry node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }
}
