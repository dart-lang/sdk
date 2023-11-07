// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/apply_options.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/implementation_imports.dart';
import 'package:linter/src/rules/package_prefixed_library_names.dart';
import 'package:linter/src/test_utilities/annotation.dart';
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
      testRules(ruleTestDataDir);

      // Rule tests run against specific configurations.
      for (var entry in Directory(testConfigDir).listSync()) {
        if (entry is! Directory) continue;
        group('(config: ${p.basename(entry.path)})', () {
          var analysisOptionsFile =
              File(p.join(entry.path, 'analysis_options.yaml'));
          var analysisOptions = analysisOptionsFile.readAsStringSync();
          testRules(ruleTestDataDir, analysisOptions: analysisOptions);
        });
      }
    });
    group('pub', () {
      for (var entry in Directory(p.join(ruleTestDataDir, 'pub')).listSync()) {
        if (entry is Directory) {
          for (var child in entry.listSync()) {
            if (child is File && isPubspecFile(child)) {
              var ruleName = p.basename(entry.path);
              testRule(ruleName, child);
            }
          }
        }
      }
    });
  });
}

void defineRuleUnitTests() {
  group('uris', () {
    group('isPackage', () {
      for (var uri in [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ]) {
        test(uri.toString(), () {
          expect(isPackage(uri), isTrue);
        });
      }
      for (var uri in [
        Uri.parse('foo/bar.dart'),
        Uri.parse('src/bar.dart'),
        Uri.parse('dart:async')
      ]) {
        test(uri.toString(), () {
          expect(isPackage(uri), isFalse);
        });
      }
    });

    group('samePackage', () {
      test('identity', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/src/bar.dart')),
            isTrue);
      });
      test('foo/bar.dart', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/bar.dart')),
            isTrue);
      });
    });

    group('implementation', () {
      for (var uri in [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ]) {
        test(uri.toString(), () {
          expect(isImplementation(uri), isTrue);
        });
      }
      for (var uri in [
        Uri.parse('package:foo/bar.dart'),
        Uri.parse('src/bar.dart')
      ]) {
        test(uri.toString(), () {
          expect(isImplementation(uri), isFalse);
        });
      }
    });
  });

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
    group('library_name_prefixes', () {
      bool isGoodPrefix(List<String> v) => matchesOrIsPrefixedBy(
          v[3],
          Analyzer.facade.createLibraryNamePrefix(
              libraryPath: v[0], projectRoot: v[1], packageName: v[2]));

      var good = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.src.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.test.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.data.a'],
        ['/u/b/c/lib/acme.dart', '/u/b/c', 'acme', 'acme']
      ];
      testEach(good, isGoodPrefix, isTrue);

      var bad = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'wrk.acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.a']
      ];
      testEach(bad, isGoodPrefix, isFalse);
    });
  });
}

void testRule(String ruleName, File file,
    {bool useMockSdk = true, String? analysisOptions}) {
  test(ruleName, () async {
    if (!file.existsSync()) {
      throw Exception('No rule found defined at: ${file.path}');
    }

    // Disable this check until migration is complete internally.
    noSoundNullSafety = false;

    try {
      var errorInfos = await _getErrorInfos(ruleName, file,
          useMockSdk: useMockSdk, analysisOptions: analysisOptions);
      _validateExpectedLints(file, errorInfos,
          analysisOptions: analysisOptions);
    } finally {
      noSoundNullSafety = true;
    }
  });
}

void testRules(String ruleDir, {String? analysisOptions}) {
  for (var entry in Directory(ruleDir).listSync()) {
    if (entry is! File || !isDartFile(entry)) continue;
    var ruleName = p.basenameWithoutExtension(entry.path);
    testRule(ruleName, entry, analysisOptions: analysisOptions);
  }
}

Future<Iterable<AnalysisErrorInfo>> _getErrorInfos(String ruleName, File file,
    {required bool useMockSdk, required String? analysisOptions}) async {
  registerLintRules();
  var rule = Registry.ruleRegistry[ruleName];
  if (rule == null) {
    fail('rule `$ruleName` is not registered; unable to test.');
  }

  if (useMockSdk) {
    var driver = buildDriver(rule, file, analysisOptions: analysisOptions);
    return await driver.lintFiles([file]);
  }

  var path = p.normalize(file.absolute.path);
  var collection = AnalysisContextCollection(
    includedPaths: [path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  var context = collection.contexts[0];
  var options = context.analysisOptions as AnalysisOptionsImpl;
  options.lintRules = context.analysisOptions.lintRules.toList();
  options.lintRules.add(rule);
  options.lint = true;

  var result =
      await context.currentSession.getResolvedUnit(path) as ResolvedUnitResult;
  return [
    AnalysisErrorInfoImpl(
      result.errors,
      result.lineInfo,
    )
  ];
}

/// Parse lint annotations in the given [file] and validate that they correspond
/// with errors in the provided [errorInfos].
void _validateExpectedLints(File file, Iterable<AnalysisErrorInfo> errorInfos,
    {String? analysisOptions}) {
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
    // TODO (asashour): to be removed after fixing
    // https://github.com/dart-lang/linter/issues/909
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Dump results for debugging purposes.

    // AST
    var optionsProvider = AnalysisOptionsProvider();
    var optionMap = optionsProvider.getOptionsFromString(analysisOptions);
    var optionsImpl = AnalysisOptionsImpl();
    optionsImpl.applyOptions(optionMap);

    var features = optionsImpl.contextFeatures;

    FileSpelunker(file.absolute.path, featureSet: features).spelunk();
    printToConsole('');
    // Lints.
    ResultReporter(errorInfos).write();

    // Rethrow and fail.
    rethrow;
  }
}

/// A [LintFilter] that filters no lint.
class NoFilter implements LintFilter {
  @override
  bool filter(AnalysisError lint) => false;
}

/// A [DetailedReporter] that filters no lint, only used in debug mode, when
/// actual lints do not match expectations.
class ResultReporter extends DetailedReporter {
  ResultReporter(Iterable<AnalysisErrorInfo> errors)
      : super(errors, NoFilter(), stdout);
}
