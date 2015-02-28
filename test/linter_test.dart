// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.lint_test;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:cli_util/cli_util.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/io.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/pub.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/camel_case_types.dart';
import 'package:linter/src/util.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

import '../bin/linter.dart' as dartlint;
import 'mocks.dart';

main() {
  groupSep = ' | ';

  defineSanityTests();
  defineLinterEngineTests();
  defineRuleTests();
  defineRuleUnitTests();
}

const String ruleDir = 'test/rules';

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
      _test('logError2', 'ERROR: foo',
          (r) => r.logError2('foo', new Exception()));
      _test('logInformation', 'INFO: foo', (r) => r.logInformation('foo'));
      _test('logInformation2', 'INFO: foo',
          (r) => r.logInformation2('foo', new Exception()));
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
        expect(new Group('Style Guide').custom, isFalse);
        expect(new Group('Styleguide').custom, isFalse);
        expect(new Group('Pub').custom, isFalse);
        expect(new Group('Kustom').custom, isTrue);
      });
    });

    group('kinds', () {
      test('factory', () {
        var kinds = ['DO', 'DONT', "DON'T", 'AVOID', 'PREFER', 'CONSIDER'];
        kinds.map((n) => new Kind(n)).forEach((k) => expect(k.custom, isFalse));
        expect(new Kind('Kustom').custom, isTrue);
      });
    });

    group('lint driver', () {
      test('pubspec', () {
        bool visited;
        var options =
            new LinterOptions(() => [new MockLinter((n) => visited = true)]);
        new SourceLinter(options).lintPubspecSource(contents: 'name: foo_bar');
        expect(visited, isTrue);
      });
      test('error collecting', () {
        var error = new AnalysisError.con1(new StringSource('foo', ''),
            new LintCode('MockLint', 'This is a test...'));
        var linter = new SourceLinter(new LinterOptions(() => []));
        linter.onError(error);
        expect(linter.errors.contains(error), isTrue);
      });
      test('pubspec visitor error handling', () {
        var rule = new MockRule();
        var visitor = new MockPubVisitor();
        when(visitor.visitPackageAuthor(any))
            .thenAnswer((_) => throw new Exception());
        when(rule.getPubspecVisitor()).thenReturn(visitor);

        var reporter = new MockReporter();
        var linter = new SourceLinter(new LinterOptions(() => [rule]),
            reporter: reporter);
        linter.lintPubspecSource(contents: 'author: foo');
        verify(reporter.exception(any)).called(1);
      });
    });

    group('main', () {
      setUp(() => exitCode = 0);
      tearDown(() => exitCode = 0);
      test('smoke', () {
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        dartlint.main([firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('no args', () {
        dartlint.main([]);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('help', () {
        dartlint.main(['-h']);
        // Help shouldn't generate an error code
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('unknown arg', () {
        dartlint.main(['-XXXXX']);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      //TODO: revisit error handling
      skip_test('bad path', () {
        var badPath = new Directory(ruleDir).path + '/___NonExistent.dart';
        dartlint.main([badPath]);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('custom sdk path', () {
        // Smoke test to ensure a custom sdk path doesn't sink the ship
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        var sdk = getSdkDir();
        dartlint.main(['--dart-sdk', sdk.path, firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('custom package root', () {
        // Smoke test to ensure a custom package root doesn't sink the ship
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        var packageDir = new Directory('.').path;
        dartlint.main(['--package-root', packageDir, firstRuleTest.path]);
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
          expect(link.html, equals(
              '<a href="http://dartlang.org"><strong>dart</strong></a>'));
        });
      });
      group('kind', () {
        test('priority', () {
          expect(Kind.supported, orderedEquals(
              [Kind.DO, Kind.DONT, Kind.PREFER, Kind.AVOID, Kind.CONSIDER]));
        });
        test('comparing', () {
          expect(Kind.DO.compareTo(Kind.DONT), equals(-1));
        });
        test('synonmyms', () {
          expect(new Kind("DONT"), equals(new Kind("DON'T")));
        });
      });
      group('rule', () {
        test('sorting', () {
          expect(Kind.supported, orderedEquals(
              [Kind.DO, Kind.DONT, Kind.PREFER, Kind.AVOID, Kind.CONSIDER]));
        });
        test('comparing', () {
          LintRule r1 = new MockLintRule('Bar', Kind.DO);
          LintRule r2 = new MockLintRule('Foo', Kind.DO);
          expect(r1.compareTo(r2), equals(-1));
        });
      });
      group('maturity', () {
        test('comparing', () {
          // Custom
          Maturity m1 = new Maturity('Foo', ordinal: 0);
          Maturity m2 = new Maturity('Bar', ordinal: 1);
          expect(m1.compareTo(m2), equals(-1));
          // Builtin
          expect(Maturity.STABLE.compareTo(Maturity.EXPERIMENTAL), equals(-1));
        });
      });
    });
  });
}

/// Rule tests
void defineRuleTests() {

  //TODO: if ruleDir cannot be found print message to set CWD to project root
  group('rule', () {
    group('dart', () {
      for (var entry in new Directory(ruleDir).listSync()) {
        if (entry is! File || !isDartFile(entry)) continue;
        var ruleName = p.basenameWithoutExtension(entry.path);
        testRule(ruleName, entry);
      }
    });
    group('pub', () {
      for (var entry in new Directory(ruleDir + '/pub').listSync()) {
        if (entry is! Directory) continue;
        Directory pubTestDir = entry;
        for (var file in pubTestDir.listSync()) {
          if (file is! File || !isPubspecFile(file)) continue;
          var ruleName = p.basename(pubTestDir.path);
          testRule(ruleName, file);
        }
      }
    });
  });
}

defineRuleUnitTests() {
  group('names', () {
    group('keywords', () {
      var good = ['class', 'if', 'assert', 'catch', 'import'];
      testEach(good, isKeyWord, isTrue);
      var bad = ['_class', 'iff', 'assert_', 'Catch'];
      testEach(bad, isKeyWord, isFalse);
    });
    group('identifiers', () {
      var good = ['foo', '_if', '_', 'f2', 'fooBar', 'foo_bar'];
      testEach(good, isValidDartIdentifier, isTrue);
      var bad = ['if', '42', '3', '2f'];
      testEach(bad, isValidDartIdentifier, isFalse);
    });
    group('pubspec', () {
      testEach(['pubspec.yaml', '_pubspec.yaml'], isPubspecFileName, isTrue);
      testEach(['__pubspec.yaml', 'foo.yaml'], isPubspecFileName, isFalse);
    });

    group('camel case', () {
      group('upper', () {
        var good = [
          '_FooBar',
          'FooBar',
          '_Foo',
          'Foo',
          'F',
          'FB',
          'F1',
          'FooBar1'
        ];
        testEach(good, isUpperCamelCase, isTrue);
        var bad = ['fooBar', 'foo', 'f', '_f', 'F_B'];
        testEach(bad, isUpperCamelCase, isFalse);
      });
    });
    group('lower_case_underscores', () {
      var good = ['foo_bar', 'foo', 'foo_bar_baz'];
      testEach(good, isLowerCaseUnderScore, isTrue);

      var bad = ['Foo', 'fooBar', 'foo_Bar', 'foo_', '_f', 'F_B', 'JS', 'JSON'];
      testEach(bad, isLowerCaseUnderScore, isFalse);
    });
    group('qualified lower_case_underscores', () {
      var good = [
        'bwu_server.shared.datastore.some_file',
        'foo_bar.baz',
        'foo.bar',
        'foo_bar_baz',
        'foo',
        'foo.bar_baz.bang'
      ];
      testEach(good, isLowerCaseUnderScoreWithDots, isTrue);

      var bad = [
        'Foo',
        'fooBar.',
        '.foo_Bar',
        'foo_',
        '_f',
        'F_B',
        'JS',
        'JSON'
      ];
      testEach(bad, isLowerCaseUnderScoreWithDots, isFalse);
    });
  });
}

/// Test framework sanity
void defineSanityTests() {
  group('test framework', () {
    group('annotation', () {
      test('extraction', () {
        expect(extractAnnotation('int x; // LINT'), isNotNull);
        expect(extractAnnotation('int x; //LINT'), isNotNull);
        expect(extractAnnotation('int x; // OK'), isNull);
        expect(extractAnnotation('int x;'), isNull);
        expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
            equals('dynamic is bad'));
        expect(extractAnnotation('dynamic x; //LINT').message, isNull);
        expect(extractAnnotation('dynamic x; //LINT ').message, isNull);
      });
    });
    test('equality', () {
      expect(
          new Annotation('Actual message (to be ignored)', ErrorType.LINT, 1),
          matchesAnnotation(null, ErrorType.LINT, 1));
      expect(new Annotation('Message', ErrorType.LINT, 1),
          matchesAnnotation('Message', ErrorType.LINT, 1));
    });
    test('inequality', () {
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.HINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message2', ErrorType.LINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.LINT, 2)),
          throwsA(new isInstanceOf<TestFailure>()));
    });
  });
}

Annotation extractAnnotation(String line) {
  int index = line.indexOf(new RegExp(r'(//|#)[ ]?LINT'));
  if (index > -1) {
    int msgIndex = line.substring(index).indexOf('T') + 1;
    String msg = null;
    if (msgIndex < line.length) {
      msg = line.substring(index + msgIndex).trim();
      if (msg.length == 0) {
        msg = null;
      }
    }
    return new Annotation.forLint(msg);
  }
  return null;
}

AnnotationMatcher matchesAnnotation(
        String message, ErrorType type, int lineNumber) =>
    new AnnotationMatcher(new Annotation(message, type, lineNumber));

testEach(Iterable<String> values, dynamic f(String s), Matcher m) {
  values.forEach((s) => test('"$s"', () => expect(f(s), m)));
}

void testRule(String ruleName, File file) {
  test('$ruleName', () {
    var expected = <AnnotationMatcher>[];

    int lineNumber = 1;
    for (var line in file.readAsLinesSync()) {
      var annotation = extractAnnotation(line);
      if (annotation != null) {
        annotation.lineNumber = lineNumber;
        expected.add(new AnnotationMatcher(annotation));
      }
      ++lineNumber;
    }

    DartLinter driver = new DartLinter.forRules(
        () => [ruleMap[ruleName]].where((rule) => rule != null));

    Iterable<AnalysisErrorInfo> lints = driver.lintFiles([file]);

    List<Annotation> actual = [];
    lints.forEach((AnalysisErrorInfo info) {
      info.errors.forEach((AnalysisError error) {
        if (error.errorCode.type == ErrorType.LINT) {
          actual.add(new Annotation.forError(error, info.lineInfo));
        }
      });
    });
    expect(actual, unorderedMatches(expected));
  });
}

typedef nodeVisitor(node);

typedef dynamic /* AstVisitor, PubSpecVisitor*/ VisitorCallback();

class Annotation {
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type, this.lineNumber);

  Annotation.forError(AnalysisError error, LineInfo lineInfo) : this(
          error.message, error.errorCode.type,
          lineInfo.getLocation(error.offset).lineNumber);

  Annotation.forLint([String message]) : this(message, ErrorType.LINT, null);

  String toString() => '[$type]: "$message" (line: $lineNumber)';

  static Iterable<Annotation> fromErrors(AnalysisErrorInfo error) {
    List<Annotation> annotations = [];
    error.errors.forEach(
        (e) => annotations.add(new Annotation.forError(e, error.lineInfo)));
    return annotations;
  }
}

class AnnotationMatcher extends Matcher {
  final Annotation _expected;
  AnnotationMatcher(this._expected);

  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  bool matches(item, Map matchState) =>
      item is Annotation && _matches(item as Annotation);

  bool _matches(Annotation other) {
    // Only test messages if they're specified in the expectation
    if (_expected.message != null) {
      if (_expected.message != other.message) {
        return false;
      }
    }
    return _expected.type == other.type &&
        _expected.lineNumber == other.lineNumber;
  }
}

class MockLinter extends LintRule {
  VisitorCallback visitorCallback;

  MockLinter([nodeVisitor v]) : super(
          name: 'MockLint',
          group: Group.STYLE_GUIDE,
          kind: Kind.AVOID,
          description: 'Desc',
          details: 'And so on...') {
    visitorCallback = () => new MockVisitor(v);
  }

  @override
  PubSpecVisitor getPubspecVisitor() => visitorCallback();

  @override
  AstVisitor getVisitor() => visitorCallback();
}

class MockLintRule extends LintRule {
  MockLintRule(String name, Kind kind) : super(name: name, kind: kind);

  @override
  AstVisitor getVisitor() => new MockVisitor(null);
}

class MockVisitor extends GeneralizingAstVisitor with PubSpecVisitor {
  final nodeVisitor;

  MockVisitor(this.nodeVisitor);

  visitNode(AstNode node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }

  visitPackageName(PSEntry node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }
}
