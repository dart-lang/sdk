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

main() {
  defineSanityTests();
  defineLinterEngineTests();
  //defineRuleTests();
}

void defineLinterEngineTests() {
  group('linter engine tests', () {
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
  });
}

// Test framework sanity
void defineRuleTests() {

  //TODO: if ruleDir cannot be found print message to set CWD to project root

  print("Running tests in '$ruleDir'...");

  for (var entry in new Directory(ruleDir).listSync()) {
    if (entry is! File || !entry.path.endsWith('.dart')) continue;
    var ruleName = p.basenameWithoutExtension(entry.path);
    print("Testing rule '$ruleName'");
    testRule(ruleName, entry);
  }
}

// Linter engine tests
void defineSanityTests() {
  group('test framework tests', () {
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

// Rule tests
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

void testRule(String ruleName, File file) {
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
}

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
  @override
  AstVisitor getVisitor() => null;
}

class MockRegistry extends RuleRegistry {
  MockRegistry() : super(new MockReporter());

  expectWarnings(List<String> warnings) {
    expect((reporter as MockReporter).warnings, unorderedEquals(warnings));
  }
}

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
