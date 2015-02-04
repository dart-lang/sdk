// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_lint.test.lint_test;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:dart_lint/src/linter.dart';
import 'package:dart_lint/src/rules.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

const ruleDir = 'test/rules';

/// Linter engine tests
void defineLinterEngineTests() {
  group('engine', () {
    group('registry', () {
      test('duplicate rules', () {
        var registry = new MockRegistry();
        registry
          ..registerLinter('r1', new MockLinter())
          ..registerLinter('r1', new MockLinter())
          ..expectWarnings(["Multiple linter rules registered to name 'r1'"]);
      });
      test('empty to start', () {
        var registry = new MockRegistry();
        expect(registry.enabledLints, isEmpty);
      });
      test('new entries disabled by default', () {
        var registry = new MockRegistry();
        registry.registerLinter('my_first_lint', new MockLinter());
        expect(registry.enabledLints, isEmpty);
      });
      test('enablement', () {
        var registry = new MockRegistry();
        var linter = new MockLinter();
        registry.registerLinter('my_first_lint', linter);
        registry.enable('my_first_lint');
        expect(registry.enabledLints, contains(linter));
      });
      test('enablement - unregistered', () {
        var registry = new MockRegistry();
        registry.enable('unknown_rule');
        registry.expectWarnings(
            ["No rule registered to 'unknown_rule', cannot enable"]);
      });
      test('disablement', () {
        var registry = new MockRegistry();
        var linter = new MockLinter();
        registry.registerLinter('my_first_lint', linter);
        registry.disable('my_first_lint');
        expect(registry.enabledLints, isEmpty);
      });
      test('disablement - unregistered', () {
        var registry = new MockRegistry();
        registry.disable('unknown_rule');
        registry.expectWarnings(
            ["No rule registered to 'unknown_rule', cannot disable"]);
      });
    });

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

    group('source linter', () {
      test('enable rule', () {
        var registry = new MockRegistry();
        var lint = new MockLinter();
        registry.registerLinter('my_first_lint', lint);
        var linter = new SourceLinter(registry: registry);
        linter.enableRule('my_first_lint');
        expect(linter.registry.enabledLints, unorderedEquals([lint]));
      });
      test('disable rule', () {
        var registry = new MockRegistry();
        var lint = new MockLinter();
        registry.registerLinter('my_first_lint', lint);
        var linter = new SourceLinter(registry: registry);
        linter.enableRule('my_first_lint');
        expect(linter.registry.enabledLints, unorderedEquals([lint]));
        linter.disableRule('my_first_lint');
        expect(linter.registry.enabledLints, isEmpty);
      });
    });

    group('lint driver', () {
      test('basic', () {
        bool visited;
        var r = new MockRegistry([new MockLinter((n) => visited = true)]);
        new SourceLinter(registry: r).lintLibrarySource(
            libraryName: 'testLibrary',
            libraryContents: 'library testLibrary;');
        expect(visited, isTrue);
      });
    });
  });
}

/// Rule tests
void defineRuleTests() {

  //TODO: if ruleDir cannot be found print message to set CWD to project root
  group('rule', () {
    for (var entry in new Directory(ruleDir).listSync()) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      var ruleName = p.basenameWithoutExtension(entry.path);
      testRule(ruleName, entry);
    }
  });
}

/// Test framework sanity
void defineSanityTests() {
  group('test framework', () {
    test('annotation extraction', () {
      expect(extractAnnotation('int x; // LINT'), isNotNull);
      expect(extractAnnotation('int x; //LINT'), isNotNull);
      expect(extractAnnotation('int x; // OK'), isNull);
      expect(extractAnnotation('int x;'), isNull);
      expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
          equals('dynamic is bad'));
    });
  });
}

Annotation extractAnnotation(String line) {
  int index = line.indexOf(new RegExp(r'//[ ]?LINT'));
  if (index > -1) {
    int msgIndex = line.substring(index).indexOf('T') + 1;
    String msg = null;
    if (msgIndex < line.length) {
      msg = line.substring(index + msgIndex).trim();
    }
    return new Annotation.forLint(msg);
  }
  return null;
}

main() {
  groupSep = ' | ';

  defineSanityTests();
  defineLinterEngineTests();
  //defineRuleTests();
}

void testRule(String ruleName, File file) {
  test('$ruleName', () {
    var expected = <Annotation>[];

    int lineNumber = 0;
    for (var line in file.readAsLinesSync()) {
      var annotation = extractAnnotation(line);
      if (annotation != null) {
        annotation.lineNumber = lineNumber;
        expected.add(annotation);
      }
      ++lineNumber;
    }

    DartLinter driver = new DartLinter();
    driver.enableRule(ruleName);

    Iterable<AnalysisErrorInfo> lints = driver.lintFile(file);

    List<Annotation> actual = [];
    lints.forEach((AnalysisErrorInfo info) {
      info.errors.forEach((AnalysisError error) {
        actual.add(new Annotation.forError(error, info.lineInfo));
      });
    });

    print(lints);

    expect(actual, unorderedEquals(expected));
  });
}

typedef nodeVisitor(AstNode node);

typedef AstVisitor VisitorCallback();

class Annotation {
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type);

  Annotation.forError(AnalysisError error, LineInfo lineInfo)
      : this(error.message, error.errorCode.type);

  Annotation.forLint([String message]) : this(message, ErrorType.LINT);

  String toString() => '[$type]: "$message" (line: $lineNumber)';

  static Iterable<Annotation> fromErrors(AnalysisErrorInfo error) {
    List<Annotation> annotations = [];
    error.errors.forEach(
        (e) => annotations.add(new Annotation.forError(e, error.lineInfo)));
    return annotations;
  }
}

class MockLinter extends Linter {
  VisitorCallback visitorCallback;

  MockLinter([nodeVisitor v]) {
    visitorCallback = () => new MockVisitor(v);
  }

  @override
  AstVisitor getVisitor() => visitorCallback();
}

class MockRegistry extends RuleRegistry {
  MockRegistry([List<Linter> lints]) : super(new MockReporter()) {
    if (lints != null) {
      for (int i = 0; i < lints.length; ++i) {
        registerLinter('_linter_$i', lints[i]);
        enable('_linter_$i');
      }
    }
  }

  expectWarnings(List<String> warnings) {
    expect((reporter as MockReporter).warnings, unorderedEquals(warnings));
  }
}

//class MockLinter extends Linter {
//  @override
//  AstVisitor getVisitor() => null;
//}

class MockReporter extends Reporter {
  var exceptions = <LinterException>[];
  var warnings = <String>[];

  @override
  void exception(LinterException exception) {
    exceptions.add(exception);
  }

  @override
  void warn(String message) {
    warnings.add(message);
  }
}

class MockVisitor extends GeneralizingAstVisitor {
  final nodeVisitor;

  MockVisitor(this.nodeVisitor);

  visitNode(AstNode node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }
}
