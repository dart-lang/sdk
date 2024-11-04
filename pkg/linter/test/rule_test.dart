// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/util.dart' show FileSpelunker;
import 'package:linter/src/ast.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/test_utilities/analysis_error_info.dart';
import 'package:linter/src/test_utilities/annotation.dart';
import 'package:linter/src/test_utilities/formatter.dart';
import 'package:linter/src/test_utilities/test_resource_provider.dart';
import 'package:linter/src/utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_constants.dart';
import 'util/annotation_matcher.dart';
import 'util/test_utils.dart';

void main() {
  group('rule tests', () {
    setUp(setUpSharedTestEnvironment);
    defineRuleTests();
    defineRuleUnitTests();
  });
}

/// Rule tests
void defineRuleTests() {
  group('rule', () {
    group('dart', () {
      // Rule tests run with default analysis options.
      for (var entry in Directory(ruleTestDataDir).listSync()) {
        if (entry is! File || !isDartFile(entry)) continue;
        var ruleName = p.basenameWithoutExtension(entry.path);
        testRule(ruleName, entry);
      }
    });
  });
}

void defineRuleUnitTests() {
  group('names', () {
    group('keywords', () {
      var good = ['class', 'if', 'assert', 'catch', 'import'];
      testEach(good, isKeyWord, isTrue);
      var bad = ['_class', 'iff', 'assert_', 'Catch'];
      testEach(bad, isKeyWord, isFalse);
    });
    group('identifiers', () {
      var good = [
        'foo',
        '_if',
        '_',
        'f2',
        'fooBar',
        'foo_bar',
        '\$foo',
        'foo\$Bar',
        'foo\$'
      ];
      testEach(good, isValidDartIdentifier, isTrue);
      var bad = ['if', '42', '3', '2f'];
      testEach(bad, isValidDartIdentifier, isFalse);
    });
  });
}

void testRule(String ruleName, File file, {bool useMockSdk = true}) {
  test(ruleName, () async {
    if (!file.existsSync()) {
      throw Exception('No rule found defined at: ${file.path}');
    }

    var errorInfos =
        await _getErrorInfos(ruleName, file, useMockSdk: useMockSdk);
    _validateExpectedLints(file, errorInfos);
  });
}

Future<Iterable<AnalysisErrorInfo>> _getErrorInfos(String ruleName, File file,
    {required bool useMockSdk}) async {
  registerLintRules();
  var rule = Registry.ruleRegistry[ruleName];
  if (rule == null) {
    fail('rule `$ruleName` is not registered; unable to test.');
  }

  if (useMockSdk) {
    var driver = buildDriver(rule, file);
    return await driver.lintFiles([file]);
  }

  var path = p.normalize(file.absolute.path);
  var collection = AnalysisContextCollection(
    includedPaths: [path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  var context = collection.contexts.first;
  var contextFile = (context.currentSession.getFile(path) as FileResult).file;
  var options =
      context.getAnalysisOptionsForFile(contextFile) as AnalysisOptionsImpl;
  options.lintRules = options.lintRules.toList();

  // TODO(pq): consider a different way to configure lints
  // https://github.com/dart-lang/sdk/issues/54045
  options.lintRules.add(rule);
  options.lint = true;

  var result =
      await context.currentSession.getResolvedUnit(path) as ResolvedUnitResult;
  return [
    AnalysisErrorInfo(result.errors, result.lineInfo),
  ];
}

/// Parse lint annotations in the given [file] and validate that they correspond
/// with errors in the provided [errorInfos].
void _validateExpectedLints(
  File file,
  Iterable<AnalysisErrorInfo> errorInfos,
) {
  var expected = <AnnotationMatcher>[];

  var lineNumber = 1;
  for (var line in file.readAsLinesSync()) {
    var annotation = extractAnnotation(lineNumber, line);
    if (annotation != null) {
      expected.add(AnnotationMatcher(annotation));
    }
    ++lineNumber;
  }

  var actual = <Annotation>[];
  var errors = <String>[];
  for (var info in errorInfos) {
    for (var error in info.errors) {
      var errorType = error.errorCode.type;
      if (errorType == ErrorType.LINT) {
        actual.add(Annotation.forError(error, info.lineInfo));
      } else if (errorType.severity == ErrorSeverity.ERROR) {
        var location = info.lineInfo.getLocation(error.offset);
        errors
            .add('${file.path} ${location.lineNumber}:${location.columnNumber} '
                '${error.message}');
      }
    }
  }

  if (errors.isNotEmpty) {
    fail(['Unexpected diagnostics:\n', ...errors].join('\n'));
  }

  actual.sort();
  try {
    expect(actual, unorderedMatches(expected));
    // TODO(asashour): to be removed after fixing
    // https://github.com/dart-lang/linter/issues/909
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Dump results for debugging purposes.

    // AST
    var features = AnalysisOptionsImpl().contextFeatures;

    FileSpelunker(file.absolute.path, featureSet: features).spelunk();
    printToConsole('');
    // Lints.
    ReportFormatter(errorInfos, stdout).write();

    // Rethrow and fail.
    rethrow;
  }
}
