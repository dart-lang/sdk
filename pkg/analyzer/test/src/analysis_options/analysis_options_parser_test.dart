// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_parser.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsParserTest);
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);

    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980
  });
}

@reflectiveTest
class AnalysisOptionsParserTest extends AbstractAnalysisOptionsTest {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  @override
  void setUp() {
    registerLintRules([
      DeprecatedLint(),
      DeprecatedSince3Lint(),
      DeprecatedLintWithReplacement(),
      StableLint(),
      RuleNeg(),
      RulePos(),
      RemovedAnalysisRule(
        name: 'removed_in_2_12_lint',
        since: dart2_12,
        description: '',
      ),
      RemovedAnalysisRule(
        name: 'replaced_lint',
        since: dart3,
        replacedBy: 'replacing_lint',
        description: '',
      ),
      ReplacingLint(),
    ]);
    super.setUp();
  }

  test_analyzer_cannotIgnore_errorSeverity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - error
''');

    // Keep this as a broad probe: `error` should include all diagnostics with
    // error severity, not just a single named code.
    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('invalid_annotation'));
    expect(unignorableCodeNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_invalid_notList() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    one_error_code: true
//  ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'cannot-ignore' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_cannotIgnore_invalid_unrecognizedCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - not_an_error_code
//    ^^^^^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'not_an_error_code' isn't a recognized diagnostic code.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  unignorableDiagnosticCodeNames
    not_an_error_code
''');
  }

  test_analyzer_cannotIgnore_invalid_valueNotString() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    one_error_code:
// [diag.invalidSectionFormat][column 5][length 30] Invalid format for the 'cannot-ignore' section.
      foo: bar
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_cannotIgnore_lintRule() {
    registerLintRule(TestRule());
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - fantastic_test_rule
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  unignorableDiagnosticCodeNames
    fantastic_test_rule
''');
  }

  test_analyzer_cannotIgnore_multipleCodes() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - invalid_assignment
    - unused_import
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  unignorableDiagnosticCodeNames
    invalid_assignment
    unused_import
''');
  }

  test_analyzer_cannotIgnore_severity_errorIncludesReclassifiedDiagnostic() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('unused_import'));
  }

  test_analyzer_cannotIgnore_severity_warningExcludesReclassifiedDiagnostic() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - warning
''');

    // Since `unused_import` has been reclassified as an error,
    // `cannot-ignore: - warning` should not apply to it.
    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, isNot(contains('unused_import')));
  }

  test_analyzer_cannotIgnore_singleCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - invalid_annotation
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  unignorableDiagnosticCodeNames
    invalid_annotation
''');
  }

  test_analyzer_empty() {
    registerLintRule(TestRule());
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalid_badValue() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment:
    - not-an-experiment
//    ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not-an-experiment' isn't supported by 'enable-experiment'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalid_mapValue() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment:
    experiment: true
//  ^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalid_notString() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment:
    - 7
//    ^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalid_notString_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment:
    - test-experiment: true
//    ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalid_scalarValue() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment: 7
//                   ^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_enableExperiment_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  enable-experiment:
    - test-experiment
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  enable-experiment: 7
//                   ^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  contextFeatures
    test-experiment: true
  nonPackageFeatureSet
    test-experiment: true
''');
  }

  test_analyzer_enableExperiment_knownExperiment() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  enable-experiment:
    - test-experiment
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  contextFeatures
    test-experiment: true
  nonPackageFeatureSet
    test-experiment: true
''');
  }

  test_analyzer_errors_errorSeverityAppliesToWarningDiagnostic() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_local_variable: error
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_local_variable: error
''');

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.unusedLocalVariable,
      arguments: [
        ['x'],
      ],
    );

    var processor = analysisOptions.errorProcessors.single;
    expect(processor.appliesTo(warning), isTrue);
  }

  test_analyzer_errors_ignoreSeverityAppliesToErrorDiagnostic() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    invalid_assignment: ignore
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_assignment: ignore
''');

    var error = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.invalidAssignment,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = analysisOptions.errorProcessors.single;
    expect(processor.appliesTo(error), isTrue);
  }

  test_analyzer_errors_include_merged() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  errors:
    invalid_assignment: warning
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
analyzer:
  errors:
    unused_import: warning
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_import: warning
    invalid_assignment: warning
''');
  }

  test_analyzer_errors_include_merged_chainOfIncludes() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: second_options.yaml
''',
      getFile('$testPackageRootPath/second_options.yaml'): '''
include: first_options.yaml
analyzer:
  errors:
    unused_import: warning
''',
      getFile('$testPackageRootPath/first_options.yaml'): '''
analyzer:
  errors:
    invalid_assignment: error
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_assignment: error
    unused_import: warning
''');
  }

  test_analyzer_errors_include_merged_multipleIncludes() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include:
  - first_options.yaml
  - second_options.yaml
''',
      getFile('$testPackageRootPath/first_options.yaml'): '''
analyzer:
  errors:
    invalid_assignment: error
''',
      getFile('$testPackageRootPath/second_options.yaml'): '''
analyzer:
  errors:
    unused_import: warning
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_assignment: error
    unused_import: warning
''');
  }

  test_analyzer_errors_include_outermostWins() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  errors:
    invalid_assignment: ignore
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
analyzer:
  errors:
    invalid_assignment: warning
    unused_import: warning
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_assignment: ignore
    unused_import: warning
''');
  }

  test_analyzer_errors_include_subsequentIncludeWins() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include:
  - first_options.yaml
  - second_options.yaml
''',
      getFile('$testPackageRootPath/first_options.yaml'): '''
analyzer:
  errors:
    invalid_assignment: warning
    unused_import: warning
''',
      getFile('$testPackageRootPath/second_options.yaml'): '''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_import: warning
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_assignment: ignore
    unused_import: warning
''');
  }

  test_analyzer_errors_invalid_keyNotScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    [invalid_annotation]: ignore
//  ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'errors' section.
    unused_import: warning
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_import: warning
''');
  }

  test_analyzer_errors_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    - invalid_annotation
// [diag.invalidSectionFormat][column 5][length 40] Invalid format for the 'errors' section.
    - unused_import
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_errors_invalid_notMap_doesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  errors:
    unused_import: warning
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  errors:
    - invalid_annotation
//  ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'errors' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_import: warning
''');
  }

  test_analyzer_errors_invalid_valueNotScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    invalid_annotation: ignore
    unused_import: [1, 2, 3]
//                 ^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'errors' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_annotation: ignore
''');
  }

  test_analyzer_errors_invalidNullSeverity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_local_variable: null
//                         ^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'null' isn't supported by 'errors'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_errors_invalidSeverity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_local_variable: ftw
//                         ^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ftw' isn't supported by 'errors'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_errors_registeredLintCode() {
    registerLintRule(TestRule());
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    fantastic_test_rule: ignore
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    fantastic_test_rule: ignore
''');
  }

  test_analyzer_errors_severityValues() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    assignment_of_do_not_store: error
    dead_code: info
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_local_variable: ignore
    invalid_assignment: warning
    assignment_of_do_not_store: error
    dead_code: info
''');
  }

  test_analyzer_errors_sharedNameMatchesSharedDiagnosticCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    invalid_return_type_for_catch_error: ignore
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    invalid_return_type_for_catch_error: ignore
''');

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = analysisOptions.errorProcessors.single;
    expect(processor.appliesTo(warning), isTrue);
  }

  test_analyzer_errors_uniqueNameDoesNotMatchSharedDiagnosticCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    return_type_invalid_for_catch_error: ignore
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'return_type_invalid_for_catch_error' isn't a recognized diagnostic code.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    return_type_invalid_for_catch_error: ignore
''');

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = analysisOptions.errorProcessors.single;
    expect(processor.appliesTo(warning), isFalse);
  }

  test_analyzer_errors_unrecognizedCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    not_supported: ignore
//  ^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'not_supported' isn't a recognized diagnostic code.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  errorProcessors
    not_supported: ignore
''');
  }

  test_analyzer_errors_unrecognizedNullCode() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    null: ignore
//  ^^^^
// [diag.unrecognizedErrorCode] 'null' isn't a recognized diagnostic code.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_exclude_include_merged() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  exclude:
    - lowlevelexclude.dart
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
analyzer:
  exclude:
    - toplevelexclude.dart
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  excludePatterns
    toplevelexclude.dart
    lowlevelexclude.dart
''');
  }

  test_analyzer_exclude_invalid_notList() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  exclude: test/_data/p4/lib/lib1.dart
//         ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'exclude' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_exclude_invalid_notList_doesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  exclude:
    - included.dart
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  exclude: local.dart
//         ^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'exclude' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  excludePatterns
    included.dart
''');
  }

  test_analyzer_exclude_invalid_withNonStrings() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
//    ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'exclude' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  excludePatterns
    foo/bar.dart
    test/**
''');
  }

  test_analyzer_exclude_patterns() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  excludePatterns
    foo/bar.dart
    test/**
''');
  }

  test_analyzer_exclude_singlePattern() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  excludePatterns
    test/_data/p4/lib/lib1.dart
''');
  }

  test_analyzer_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer: 7
//        ^
// [diag.invalidSectionFormat] Invalid format for the 'analyzer' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_empty() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_include_merged() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  language:
    strict-casts: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  language:
    strict-inference: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  strictCasts: true
  strictInference: true
''');
  }

  test_analyzer_language_include_merged_fileMap() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  language:
    strict-inference: true
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
analyzer:
  language:
    strict-casts: true
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  strictCasts: true
  strictInference: true
''');
  }

  test_analyzer_language_invalid_notMap_doesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  language:
    strict-casts: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  language: true
//          ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'language' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  strictCasts: true
''');
  }

  test_analyzer_language_invalid_notMap_list() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    - notAnOption: true
//  ^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'language' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_invalid_notMap_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language: true
//          ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'language' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_strictCasts_invalid_notScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    strict-casts:
      value: true
//    ^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'strict-casts' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_strictCasts_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  language:
    strict-casts: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  language:
    strict-casts: 1
//                ^
// [diag.unsupportedValue] The value '1' isn't supported by 'strict-casts'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  strictCasts: true
''');
  }

  test_analyzer_language_strictInference_invalid_notScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    strict-inference:
      value: true
//    ^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'strict-inference' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  // TODO(srawlins): Enable when we deprecate strict-raw-types.
  @FailingTest(reason: 'Enable when we deprecate strict-raw-types')
  test_analyzer_language_strictRawTypes_deprecated() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    strict-raw-types: true
//  ^^^^^^^^^^^^^^^^
// [diag.analysisOptionDeprecated] The option 'strict-raw-types' is no longer supported.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_strictRawTypes_invalid_notScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    strict-raw-types:
      value: true
//    ^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'strict-raw-types' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_strictRawTypes_notDeprecatedIfFalse() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    strict-raw-types: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_language_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  language:
    unsupported: true
//  ^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'unsupported' isn't supported by 'language'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_invalid() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    chromeos-manifest
//  ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'chromeos-manifest' isn't supported by ''chrome-os-manifest-checks' or 'propagate-linter-exceptions''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_invalid_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    Chrome-OS-Manifest-Checks
//  ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'Chrome-OS-Manifest-Checks' isn't supported by ''chrome-os-manifest-checks' or 'propagate-linter-exceptions''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    - chrome-os-manifest-checks
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'optional-checks' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  chromeOsManifestChecks: true
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  chromeOsManifestChecks: true
''');
  }

  test_analyzer_optionalChecks_include_falseOverridesIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_include_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
analyzer:
  optional-checks:
    propagate-linter-exceptions: maybe
//                               ^^^^^
// [diag.unsupportedValue] The value 'maybe' isn't supported by 'propagate-linter-exceptions'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  propagateLinterExceptions: true
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_invalid_notScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions:
      value: true
//    ^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'propagate-linter-exceptions' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  propagateLinterExceptions: true
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_true() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  propagateLinterExceptions: true
''');
  }

  test_analyzer_plugins_include_includedListThenDirectList() {
    newFile('$testPackageRootPath/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_include_includedListThenDirectMap() {
    newFile('$testPackageRootPath/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
analyzer:
  plugins:
    plugin_two:
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
      foo: bar
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_two
''');
  }

  test_analyzer_plugins_include_includedListThenDirectScalar() {
    newFile('$testPackageRootPath/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
analyzer:
  plugins: plugin_two
//         ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_two
''');
  }

  test_analyzer_plugins_include_indirectIncludedListThenDirectList() {
    newFile('$testPackageRootPath/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    newFile('$testPackageRootPath/other_options.yaml', '''
include: more_options.yaml
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_include_indirectIncludedListThenIncludedList() {
    newFile('$testPackageRootPath/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    newFile('$testPackageRootPath/other_options.yaml', '''
include: more_options.yaml
analyzer:
  plugins:
    - plugin_two
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options.yaml(54..63): Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_include_map() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
analyzer:
  plugins:
    toplevelplugin:
      enabled: true
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    toplevelplugin
''');
  }

  test_analyzer_plugins_include_nestedMultiple_chooseFirst() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/more_options.yaml(44..53): Multiple plugins can't be enabled.
// [diag.includedFileWarning] Warning in the included options file /home/test/more_options.yaml(61..70): Multiple plugins can't be enabled.
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options.yaml(54..63): Multiple plugins can't be enabled.
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options.yaml(71..80): Multiple plugins can't be enabled.
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options.yaml(88..97): Multiple plugins can't be enabled.
analyzer:
  plugins:
    - plugin_fff
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
    - plugin_iii
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
    - plugin_ccc
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
include: more_options.yaml
analyzer:
  plugins:
    - plugin_eee
    - plugin_hhh
    - plugin_bbb
''',
      getFile('$testPackageRootPath/more_options.yaml'): '''
analyzer:
  plugins:
    - plugin_ddd
    - plugin_ggg
    - plugin_aaa
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_ddd
''');
  }

  test_analyzer_plugins_list() {
    // TODO(srawlins): Test legacy plugins as a list of non-scalar values
    // (`- angular2: yes`).
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  plugins:
    - angular2
    - intl
//    ^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    angular2
''');
  }

  test_analyzer_plugins_list_duplicateName() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_one
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_list_multiple() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
    - plugin_three
//    ^^^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_list_nonStringAfterString() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    - plugin_one
    - 7
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_list_nonStringBeforeString() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    - 7
    - plugin_one
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_map() {
    // TODO(srawlins): Test legacy plugins as a map of scalar values
    // (`angular2: yes`).
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    angular2
''');
  }

  test_analyzer_plugins_map_duplicateKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_one: sure
//  ^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_plugins_map_multiple() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_two: sure
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_one
''');
  }

  test_analyzer_plugins_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  plugins:
    angular2
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    angular2
''');
  }

  test_analyzer_strongMode_declarationCasts() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode:
    declaration-casts: true
//  ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'declaration-casts' isn't supported by 'strong-mode'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_strongMode_implicitCasts_invalid() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode:
    implicit-casts: 1
//                  ^
// [diag.unsupportedValue] The value '1' isn't supported by 'implicit-casts'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_strongMode_implicitCasts_invalid_notScalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode:
    implicit-casts:
      value: true
//    ^^^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'implicit-casts' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_strongMode_implicitDynamic_true() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode:
    implicit-dynamic: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_strongMode_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode: true
//             ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'strong-mode' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_strongMode_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  strong-mode:
    unsupported: true
//  ^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'unsupported' isn't supported by 'strong-mode'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_analyzer_unsupportedOption() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'not_supported' isn't supported by 'analyzer'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_format_bool_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_format_bool_true() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: true
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_format_include_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
code-style:
  format: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
code-style:
  format: 80
//        ^^
// [diag.unsupportedValue] The value '80' isn't supported by 'format'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_format_invalid_int() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: 80
//        ^^
// [diag.unsupportedValue] The value '80' isn't supported by 'format'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_format_string_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: "false"
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_format_string_true() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: "true"
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_format_string_true_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: "True"
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_format_string_true_upperCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: "TRUE"
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_include_invalid_notMap_doesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
code-style:
  format: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
code-style: format
//          ^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  codeStyleOptions
    useFormatter: true
''');
  }

  test_codeStyle_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style: 7
//          ^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_invalid_notMap_list() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  - format
//^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_invalid_notMap_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style: format
//          ^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_codeStyle_lintRule_alwaysDeclareReturnTypes() {
    registerLintRule(TestRule.withName('always_declare_return_types'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - always_declare_return_types
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    always_declare_return_types
  codeStyleOptions
    specifyReturnTypes: true
''');
  }

  test_codeStyle_lintRule_alwaysPutRequiredNamedParametersFirst() {
    registerLintRule(
      TestRule.withName('always_put_required_named_parameters_first'),
    );
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - always_put_required_named_parameters_first
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    always_put_required_named_parameters_first
  codeStyleOptions
    requiredNamedParametersFirst: true
''');
  }

  test_codeStyle_lintRule_alwaysSpecifyTypes() {
    registerLintRule(TestRule.withName('always_specify_types'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - always_specify_types
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    always_specify_types
  codeStyleOptions
    specifyReturnTypes: true
    specifyTypes: true
''');
  }

  test_codeStyle_lintRule_alwaysUsePackageImports() {
    registerLintRule(TestRule.withName('always_use_package_imports'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - always_use_package_imports
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    always_use_package_imports
  codeStyleOptions
    usePackageUris: true
''');
  }

  test_codeStyle_lintRule_avoidAnnotatingWithDynamic() {
    registerLintRule(TestRule.withName('avoid_annotating_with_dynamic'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - avoid_annotating_with_dynamic
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    avoid_annotating_with_dynamic
  codeStyleOptions
    avoidAnnotatingWithDynamic: true
''');
  }

  test_codeStyle_lintRule_avoidRenamingMethodParameters() {
    registerLintRule(TestRule.withName('avoid_renaming_method_parameters'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - avoid_renaming_method_parameters
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    avoid_renaming_method_parameters
  codeStyleOptions
    avoidRenamingMethodParameters: true
''');
  }

  test_codeStyle_lintRule_combinatorsOrdering() {
    registerLintRule(TestRule.withName('combinators_ordering'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - combinators_ordering
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    combinators_ordering
  codeStyleOptions
    sortCombinators: true
''');
  }

  test_codeStyle_lintRule_preferConstDeclarations() {
    registerLintRule(TestRule.withName('prefer_const_declarations'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_const_declarations
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_const_declarations
  codeStyleOptions
    preferConstDeclarations: true
''');
  }

  test_codeStyle_lintRule_preferDoubleQuotes() {
    registerLintRule(TestRule.withName('prefer_double_quotes'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_double_quotes
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_double_quotes
  codeStyleOptions
    preferredQuoteForStrings: "
''');
  }

  test_codeStyle_lintRule_preferFinalInForEach() {
    registerLintRule(TestRule.withName('prefer_final_in_for_each'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_final_in_for_each
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_final_in_for_each
  codeStyleOptions
    finalInForEach: true
''');
  }

  test_codeStyle_lintRule_preferFinalLocals() {
    registerLintRule(TestRule.withName('prefer_final_locals'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_final_locals
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_final_locals
  codeStyleOptions
    makeLocalsFinal: true
''');
  }

  test_codeStyle_lintRule_preferIntLiterals() {
    registerLintRule(TestRule.withName('prefer_int_literals'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_int_literals
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_int_literals
  codeStyleOptions
    preferIntLiterals: true
''');
  }

  test_codeStyle_lintRule_preferRelativeImports() {
    registerLintRule(TestRule.withName('prefer_relative_imports'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - prefer_relative_imports
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    prefer_relative_imports
  codeStyleOptions
    useRelativeUris: true
''');
  }

  test_codeStyle_lintRule_requireTrailingCommas() {
    registerLintRule(TestRule.withName('require_trailing_commas'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - require_trailing_commas
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    require_trailing_commas
  codeStyleOptions
    addTrailingCommas: true
''');
  }

  test_codeStyle_lintRule_sortConstructorsFirst() {
    registerLintRule(TestRule.withName('sort_constructors_first'));
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - sort_constructors_first
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    sort_constructors_first
  codeStyleOptions
    sortConstructorsFirst: true
''');
  }

  test_codeStyle_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not_supported' isn't supported by 'code-style'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_empty() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_include_invalid_notMap_doesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
formatter:
  page_width: 80
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
formatter: format
//         ^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'formatter' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    pageWidth: 80
''');
  }

  test_formatter_include_merged() {
    newFile('$testPackageRootPath/included.yaml', '''
formatter:
  page_width: 80
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
formatter:
  trailing_commas: automate
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    pageWidth: 80
    trailingCommas: automate
''');
  }

  test_formatter_include_nullDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
formatter:
  page_width: 80
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
formatter:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    pageWidth: 80
''');
  }

  test_formatter_pageWidth_include_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
formatter:
  page_width: 80
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
formatter:
  page_width: -1
//            ^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    pageWidth: 80
''');
  }

  test_formatter_pageWidth_integer() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  page_width: 123
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    pageWidth: 123
''');
  }

  test_formatter_pageWidth_invalid_decimal() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  page_width: 123.45
//            ^^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_pageWidth_invalid_negativeInteger() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  page_width: -123
//            ^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_pageWidth_invalid_string() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  page_width: "123"
//            ^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_pageWidth_invalid_zero() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  page_width: 0
//            ^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_trailingCommas_automate() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  trailing_commas: automate
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    trailingCommas: automate
''');
  }

  test_formatter_trailingCommas_include_invalidDoesNotOverrideIncluded() {
    newFile('$testPackageRootPath/included.yaml', '''
formatter:
  trailing_commas: automate
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
formatter:
  trailing_commas: foo
//                 ^^^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  formatterOptions
    trailingCommas: automate
''');
  }

  test_formatter_trailingCommas_invalid_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  trailing_commas:
    a: b
//  ^^^^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_trailingCommas_invalid_numeric() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  trailing_commas: 1
//                 ^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_trailingCommas_invalid_string() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  trailing_commas: foo
//                 ^^^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_unsupportedKey_multiple() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
  wrong2: 123
//^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong2' isn't supported by 'formatter'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_formatter_unsupportedKey_single() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_absolutePath() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: /foo.yaml
//       ^^^^^^^^^
// [diag.includeFileNotFound] The URI '/foo.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_direct() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_nested() {
    newFile('$testPackageRootPath/other_options1.yaml', r'''
include: other_options2.yaml
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options2.yaml' included in '/home/test/other_options1.yaml' can't be found when analyzing '/home/test'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_packageUri_doubleQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
# We don't depend on pedantic, but we should consider adding it.
include: "package:pedantic/analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_packageUri_listFirst() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
  - included1.yaml
''',
      getFile('$testPackageRootPath/included1.yaml'): '',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_packageUri_listSecond() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - included1.yaml
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''',
      getFile('$testPackageRootPath/included1.yaml'): '',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_packageUri_notQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
# We don't depend on pedantic, but we should consider adding it.
include: package:pedantic/analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_missing_packageUri_singleQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
# We don't depend on pedantic, but we should consider adding it.
include: 'package:pedantic/analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/home/test/analysis_options.yaml' can't be found when analyzing '/home/test'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_multipleSections_merged() {
    registerLintRules([
      TestRule.withName('included_lint'),
      TestRule.withName('main_lint'),
    ]);
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: included_options.yaml
analyzer:
  errors:
    invalid_assignment: ignore
  language:
    strict-casts: true
code-style:
  format: true
linter:
  rules:
    - main_lint
''',
      getFile('$testPackageRootPath/included_options.yaml'): '''
analyzer:
  errors:
    unused_import: warning
linter:
  rules:
    - included_lint
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_import: warning
    invalid_assignment: ignore
  lint: true
  lintRules
    included_lint
    main_lint
  strictCasts: true
  codeStyleOptions
    useFormatter: true
''');
  }

  test_include_parse_duplicateKey_inIncludedFile() {
    newFile('$testPackageRootPath/other_options.yaml', r'''
formatter:
  page_width: 80
  page_width: 90
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileParseError] Duplicate mapping key. in /home/test/other_options.yaml(30..40)
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_cycle_direct() {
    // Test that the appropriate error is issued if `analysis_options.yaml`
    // tries to include another options file which in turn includes
    // `analysis_options.yaml`.
    newFile('$testPackageRootPath/other_options.yaml', r'''
include: analysis_options.yaml
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/other_options.yaml' includes '/home/test/other_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_cycle_inIncludedFiles() {
    // Test that the appropriate error is issued if a file included by
    // `analysis_options.yaml` tries to include itself indirectly.
    // Note: comments ensure that the `include` directives in each file are at
    // different file offsets, so that we can validate that the reported source
    // ranges are correct.
    newFile('$testPackageRootPath/other_options1.yaml', r'''
include: other_options2.yaml
''');
    newFile('$testPackageRootPath/other_options2.yaml', r'''
# comment
include: other_options1.yaml
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
# comment
# comment
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options1.yaml(9..27): The file includes itself recursively.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_includedCycle() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/a.yaml(9..14): The file includes itself recursively.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '''
include: a.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_includedFileSelf() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/a.yaml(9..14): The file includes itself recursively.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: a.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_initialThroughChain() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/b.yaml' includes '/home/test/b.yaml', creating a circular reference.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '''
include: analysis_options.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_initialThroughChain_listAtTop() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - empty.yaml
  - a.yaml
//  ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/b.yaml' includes '/home/test/b.yaml', creating a circular reference.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('$testPackageRootPath/empty.yaml'): '''
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_initialThroughChain_listInIncludedFile() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/b.yaml' includes '/home/test/b.yaml', creating a circular reference.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include:
  - empty.yaml
  - b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('$testPackageRootPath/empty.yaml'): '''
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_none_nestedSiblingIncludes() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: c.yaml
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '',
      getFile('$testPackageRootPath/c.yaml'): '''
include:
  - a.yaml
  - b.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_none_siblingIncludes() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - a.yaml
  - b.yaml
''',
      getFile('$testPackageRootPath/a.yaml'): '''
include: b.yaml
''',
      getFile('$testPackageRootPath/b.yaml'): '',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_doubleQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: "./analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_fileName() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_fileNameInList() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include:
  - analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_inIncludedFile() {
    // Test that the appropriate error is issued if a file included by
    // `analysis_options.yaml` tries to include itself.
    // Note: comments ensure that the `include` directives in each file are at
    // different file offsets, so that we can validate that the reported source
    // ranges are correct.
    newFile('$testPackageRootPath/other_options.yaml', r'''
include: other_options.yaml
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
# comment
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/other_options.yaml(9..26): The file includes itself recursively.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_listFirst() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
  - included1.yaml
''',
      getFile('$testPackageRootPath/included1.yaml'): '',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_listSecond() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''',
      getFile('$testPackageRootPath/included1.yaml'): '',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_notQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: ./analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_recursive_self_singleQuoted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: './analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/home/test/analysis_options.yaml' includes '/home/test/analysis_options.yaml', creating a circular reference.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_include_warning_fromIncludedFile() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/a.yaml(12..20): The option 'something' isn't supported by 'analyzer'.
''',
      getFile('$testPackageRootPath/a.yaml'): '''
analyzer:
  something: bad
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter: 7
//      ^
// [diag.invalidSectionFormat] Invalid format for the 'linter' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_deprecated() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_lint
''');
  }

  test_linter_rules_deprecated_inIncludedFile() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    - deprecated_lint
''');

    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_lint
''');
  }

  test_linter_rules_deprecated_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    deprecated_lint: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_deprecated_map_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    deprecated_lInt: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lInt' is deprecated and shouldn't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_deprecated_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecAted_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecAted_lint' is deprecated and shouldn't be enabled.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_lint
''');
  }

  test_linter_rules_deprecated_since_afterDeprecationSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdkVersionConstraint: dart3_3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_since_3_lint
''');
  }

  test_linter_rules_deprecated_since_atDeprecationSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdkVersionConstraint: dart3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_since_3_lint
''');
  }

  test_linter_rules_deprecated_since_beforeDeprecationSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''', sdkVersionConstraint: Version(2, 17, 0));

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_since_3_lint
''');
  }

  test_linter_rules_deprecated_since_unknownPackageSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_since_3_lint
''');
  }

  test_linter_rules_deprecated_withReplacement() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_replacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_replacement' is deprecated and replaced by 'replacing_lint'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_lint_with_replacement
''');
  }

  test_linter_rules_deprecated_withReplacement_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_rePlacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_rePlacement' is deprecated and replaced by 'replacing_lint'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    deprecated_lint_with_replacement
''');
  }

  test_linter_rules_duplicate() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - stable_lint
    - stable_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'stable_lint' is already enabled and doesn't need to be enabled again.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_duplicate_inIncludedFile() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    - stable_lint
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml

linter:
  rules:
    - stable_lint
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_duplicate_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - stable_lint
    - staBle_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'staBle_lint' is already enabled and doesn't need to be enabled again.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_empty() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_include_emptyLocal() {
    registerLintRule(TestRule.withName('included_lint'));
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: foo.yaml
linter:
  rules:
    # local_lint: false
''',
      getFile('$testPackageRootPath/foo.yaml'): r'''
linter:
  rules:
    - included_lint
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    included_lint
''');
  }

  test_linter_rules_include_merged() {
    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
linter:
  rules:
    - top_level_lint
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    low_level_lint
    top_level_lint
''');
  }

  test_linter_rules_include_merged_differentFormats() {
    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
linter:
  rules:
    top_level_lint: true
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    low_level_lint
    top_level_lint
''');
  }

  test_linter_rules_include_multipleCompatible() {
    newFile('$testPackageRootPath/included1.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    newFile('$testPackageRootPath/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include:
  - included1.yaml
  - included2.yaml
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_include_outermostWins() {
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRule(topLevelLint);
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''
include: other_options.yaml
linter:
  rules:
    top_level_lint: false
''',
      getFile('$testPackageRootPath/other_options.yaml'): '''
linter:
  rules:
    - top_level_lint
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_incompatible() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    - rule_neg
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_invalidMap_noDiagnostic() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_neg: true
    rule_pos:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
''');
  }

  test_linter_rules_incompatible_invalidMap_reports() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_neg:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/home/test/included.yaml'.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_disabled() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: true
    rule_neg: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_includedFile() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/home/test/included.yaml'.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_includedFile_disabledInMain() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_includedFile_enabledInMain() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here.
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_pos' is incompatible with ''rule_neg''.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_includedFile_mixedCase() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'Rule_pos' is incompatible with 'rulE_neg'.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
linter:
  rules:
    rulE_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rulE_neg' is enabled here in the file '/home/test/included.yaml'.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_map_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'Rule_pos' is enabled here.
    rUle_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rUle_neg' is incompatible with ''Rule_pos''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - rule_Pos
//    ^^^^^^^^
// [context 1] The rule 'rule_Pos' is enabled here.
    - rule_neG
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neG' is incompatible with ''rule_Pos''.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_disabledInMain() {
    newFile('$testPackageRootPath/included1.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    newFile('$testPackageRootPath/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include:
  - included1.yaml
  - included2.yaml

linter:
  rules:
    rule_neg: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_emptyLinterRules() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.

linter:
  rules:
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  void
  test_linter_rules_incompatible_multipleIncludes_emptyLinterRules_mixedCase() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_poS' and 'ruLe_neg', which is included from 2 files.

linter:
  rules:
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
linter:
  rules:
    - ruLe_neg
//    ^^^^^^^^
// [context 2] The rule 'ruLe_neg' is enabled here.
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    - rule_poS
//    ^^^^^^^^
// [context 1] The rule 'rule_poS' is enabled here.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_enabledInSecondInclude() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /home/test/included2.yaml(40..47): The rule 'rule_pos' is incompatible with ''rule_neg''.
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    rule_neg: true
    rule_pos: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_list() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_nestedFirst() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
include: nested.yaml
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_multipleIncludes_nestedFirst_disabled() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
''',
      getFile('$testPackageRootPath/included1.yaml'): '''
include: nested.yaml

linter:
  rules:
    rule_neg: false
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
      getFile('$testPackageRootPath/included2.yaml'): '''
linter:
  rules:
    rule_pos: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/home/test/nested.yaml'.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_disabledInIncludedFile() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml

linter:
  rules:
    rule_neg: false
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_disabledInIncludedFile_ignore() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml

linter:
  rules:
    rule_neg: ignore
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_disabledInIncludedFile_listToMap() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml

linter:
  rules:
    rule_neg: false
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    - rule_neg
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_disabledInMain() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: false
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_enabledInIncludedFile_listOverridesMap() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml

linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/home/test/included.yaml'.
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: false
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_nestedInclude_mainIgnore() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: ignore
''',
      getFile('$testPackageRootPath/included.yaml'): '''
include: nested.yaml
''',
      getFile('$testPackageRootPath/nested.yaml'): '''
linter:
  rules:
    rule_neg: true
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_incompatible_packageInclude() {
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics(
      {
        analysisOptionsFile: '''
include:
  - package:other/analysis_options.yaml

linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_neg' is incompatible with 'rule_pos'.
''',
        getFile('/other/lib/analysis_options.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here in the file '/other/lib/analysis_options.yaml'.
''',
      },
      packageMap: {'other': getFolder('/other/lib')},
    );

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_nullValue() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    -
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_registeredRule() {
    registerLintRule(TestRule());
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - fantastic_test_rule
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    fantastic_test_rule
''');
  }

  test_linter_rules_removed() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart2_12);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    removed_in_2_12_lint
''');
  }

  /// https://github.com/dart-lang/sdk/issues/59869
  test_linter_rules_removed_afterRemovalSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart3_3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    removed_in_2_12_lint
''');
  }

  test_linter_rules_removed_afterRemovalSdk_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - remOved_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'remOved_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart3_3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    removed_in_2_12_lint
''');
  }

  test_linter_rules_removed_beforeRemovalSdk() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
''', sdkVersionConstraint: Version(2, 11, 0));

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    removed_in_2_12_lint
''');
  }

  test_linter_rules_removed_inIncludedFile() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    removed_in_2_12_lint
''');
  }

  test_linter_rules_replaced() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - replaced_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaced_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdkVersionConstraint: dart3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    replaced_lint
''');
  }

  test_linter_rules_replaced_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - replaCed_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaCed_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdkVersionConstraint: dart3);

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    replaced_lint
''');
  }

  test_linter_rules_stable() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - stable_lint
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_stable_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    stable_lint: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_stable_map_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    sTable_lint: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_stable_mixedCase() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - Stable_lint
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    stable_lint
''');
  }

  test_linter_rules_undefined() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - this_rule_does_not_exist
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_undefined_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    this_rule_does_not_exist: false
//  ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_value_error() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: error
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_value_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_linter_rules_value_ignore() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: ignore
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_value_info() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: info
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_value_true() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: true
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_value_unsupported() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_rules_value_unsupported_withIncompatibleIncludedRule() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  void
  test_linter_rules_value_unsupported_withIncompatibleIncludedRule_mixedCase() {
    newFile('$testPackageRootPath/included.yaml', '''
linter:
  rules:
    rUle_neg: true
''');
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
include: included.yaml

linter:
  rules:
    Rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'Rule_pos'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_neg
    rule_pos
''');
  }

  test_linter_rules_value_warning() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    rule_pos: warning
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    rule_pos
''');
  }

  test_linter_unsupportedOption() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
linter:
  unsupported: true
//^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValue] The option 'unsupported' isn't supported by 'linter'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_parse_duplicateKey_initialFile() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics(r'''
formatter:
  page_width: 80
  page_width: 90
//^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_parse_empty() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''#empty''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_parse_invalidYaml() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r''':''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_parse_missingFile() {
    newFolder('/notFile');

    var options = parseAnalysisOptionsFile(
      getFile('/notFile/analysis_options.yaml'),
    ).analysisOptions;

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_parse_usesRequestedFile() {
    newFile('$testPackageRootPath/foo/$analysisOptionsYaml', r'''
analyzer:
  errors:
    invalid_assignment: warning
''');
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      getFile('$testPackageRootPath/foo/bar/analysis_options.yaml'): r'''
analyzer:
  errors:
    unused_import: ignore
''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    unused_import: ignore
''');
  }

  test_plugins_configuration_dependencyOverrides_git() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one: ^1.2.3
  dependency_overrides:
    some_package:
      git:
        url: https://github.com/dart-lang/some_package.git
        ref: main
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: VersionedPluginSource
          constraint: ^1.2.3
    dependencyOverrides
      some_package
        source: GitPluginSource
          url: https://github.com/dart-lang/some_package.git
          ref: main
''');
  }

  test_plugins_configuration_dependencyOverrides_relative() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    path: foo/bar
  dependency_overrides:
    some_package1:
      path: ../some_package1
    some_package2:
      path: sub_folder/some_package2
''');

    assertAnalysisOptionsText(analysisOptions, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: /home/test/foo/bar
    dependencyOverrides
      some_package1
        source: PathPluginSource
          path: /home/some_package1
      some_package2
        source: PathPluginSource
          path: /home/test/sub_folder/some_package2
''');
  }

  test_plugins_configuration_dependencyOverrides_versionConstraintHosted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one: ^1.2.3
  dependency_overrides:
    some_package1:
      version: ^3.2.1
      hosted: https://example.com/packages/
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: VersionedPluginSource
          constraint: ^1.2.3
    dependencyOverrides
      some_package1
        source: VersionedPluginSource
          constraint: ^3.2.1
          hosted: https://example.com/packages/
''');
  }

  test_plugins_configuration_path() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    path: /foo/bar
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: /foo/bar
''');
  }

  test_plugins_configuration_path_relativeNonNormal() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    path: .././foo/bar/../baz
''');

    assertAnalysisOptionsText(analysisOptions, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: /home/foo/baz
''');
  }

  test_plugins_configuration_versionHosted() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: VersionedPluginSource
          constraint: ^1.2.3
          hosted: https://example.com/packages/
''');
  }

  test_plugins_configuration_versionMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    version: ^1.2.3
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: VersionedPluginSource
          constraint: ^1.2.3
''');
  }

  test_plugins_dependencyOverrides_git() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  dependency_overrides:
    one:
      git: https://github.com/dart-lang/linter.git
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    dependencyOverrides
      one
        source: GitPluginSource
          url: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_dependencyOverrides_invalid_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  dependency_overrides:
    one:
      ppath: foo/bar
//    ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/dependency_overrides/one'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_diagnostics_bool() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    diagnostics:
      code1: true
      code2: false
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_diagnostics_invalid_notMap() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    diagnostics: 7
//               ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins/one/diagnostics' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_diagnostics_invalid_severity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    diagnostics:
      code: abc
//          ^^^
// [diag.unsupportedOptionWithLegalValues] The option 'abc' isn't supported by 'plugins/one/diagnostics'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_diagnostics_severity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    diagnostics:
      code1: ignore
      code2: warning
      code3: error
      code4: info
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_empty() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_git_invalid_refNotString() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      ref: 7
//         ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins/one/git/ref' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: GitPluginSource
          url: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_git_invalid_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      invalid: main
//    ^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'invalid' isn't supported by 'plugins/one/git'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: GitPluginSource
          url: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_git_map() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      ref: main
      path: pkg/linter
      tag_pattern: 'v*'
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: GitPluginSource
          url: https://github.com/dart-lang/linter.git
          ref: main
          path: pkg/linter
          tagPattern: v*
''');
  }

  test_plugins_git_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    git: https://github.com/dart-lang/linter.git
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: GitPluginSource
          url: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_include_pathRebased() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      getFile('$testPackageRootPath/foo/analysis_options.yaml'): r'''
include: ../analysis_options.yaml
''',
      analysisOptionsFile: '''
plugins:
  plugin_one:
    path: foo/bar
''',
    });

    assertAnalysisOptionsText(options, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: /home/test/foo/bar
''');
  }

  test_plugins_innerOptions() {
    newFile('$testPackageRootPath/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    var innerOptionsFile = getFile(
      '$testPackageRootPath/inner/analysis_options.yaml',
    );
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      innerOptionsFile: '''
plugins:
  one: ^1.0.0
//^^^^^^^^^^^
// [diag.pluginsInInnerOptions] Plugins can only be specified in the root of a pub workspace or the root of a package that isn't in a workspace.
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: VersionedPluginSource
          constraint: ^1.0.0
''');
  }

  test_plugins_innerOptions_included() {
    newFile('$testPackageRootPath/analysis_options.yaml', '''
plugins:
  one: ^1.0.0
''');
    newFile('$testPackageRootPath/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    var innerOptionsFile = getFile(
      '$testPackageRootPath/inner/analysis_options.yaml',
    );
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      innerOptionsFile: '''
include: ../analysis_options.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: VersionedPluginSource
          constraint: ^1.0.0
''');
  }

  test_plugins_innerOptions_included_notAtContextRoot() {
    var inner1Path = '$testPackageRootPath/inner1/analysis_options.yaml';
    var inner2Path = '$testPackageRootPath/inner2/analysis_options.yaml';
    newFile(inner2Path, '''
plugins:
  one: ^1.0.0
''');
    newFile('$testPackageRootPath/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    var inner1File = getFile(inner1Path);
    var analysisOptions = parseAnalysisOptionsFilesWithDiagnostics({
      inner1File: '''
include: ../inner2/analysis_options.yaml
''',
    });

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: VersionedPluginSource
          constraint: ^1.0.0
''');
  }

  test_plugins_invalid_notMap_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins: 7
//       ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins' section.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_plugin_invalid_unsupportedKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    ppath: foo/bar
//  ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/one'.
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_plugins_plugin_pathKey() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one:
    path: foo/bar
''');

    assertAnalysisOptionsText(analysisOptions, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: PathPluginSource
          path: /home/test/foo/bar
''');
  }

  test_plugins_plugin_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  one: ^1.2.3
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      one
        source: VersionedPluginSource
          constraint: ^1.2.3
''');
  }

  test_signature_differsForHostedPlugin() {
    var options = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''');
    var sig1 = options.signature;

    for (var i = 0; i < 10; i++) {
      var options2 = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, isNot(sig2));
    }
  }

  test_signature_errorOrderingStable() {
    var options = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    invalid_assignment: warning
    unused_import: ignore
    dead_code: ignore
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  errors:
    unused_import: ignore
    invalid_assignment: warning
    dead_code: ignore
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_lintsOrderingStable() {
    registerLintRules([
      TestRule.withName('signature_lint_a'),
      TestRule.withName('signature_lint_b'),
      TestRule.withName('signature_lint_c'),
    ]);
    var options = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - signature_lint_a
    - signature_lint_b
    - signature_lint_c
''');
    var sig1 = options.signature;

    var options2 = parseAnalysisOptionsWithDiagnostics('''
linter:
  rules:
    - signature_lint_c
    - signature_lint_a
    - signature_lint_b
''');
    var sig2 = options2.signature;
    expect(sig1, sig2);
  }

  test_signature_mergeStable() {
    var parseSession = AnalysisOptionsParseSession();
    var otherOptions = getFile(
      '$testPackageRootPath/analysis_options_helper.yaml',
    );
    var mainOptions = analysisOptionsFile;

    var options = parseAnalysisOptionsFilesWithDiagnostics({
      mainOptions: '''
include: analysis_options_helper.yaml
analyzer:
  errors:
    dead_code: ignore
''',
      otherOptions: '''
analyzer:
  errors:
    invalid_assignment: warning
    unused_import: ignore
    unused_local_variable: ignore
''',
    });
    var sig1 = options.signature;
    for (var i = 0; i < 100; i++) {
      var options2 = parseAnalysisOptionsFile(
        mainOptions,
        parseSession: parseSession,
      ).analysisOptions;
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_pluginOrderingStable() {
    var options = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
  plugin_three: ^1.2.3
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_three: ^1.2.3
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }
}

class DeprecatedLint extends TestLintRule {
  DeprecatedLint()
    : super(name: 'deprecated_lint', state: RuleState.deprecated());
}

class DeprecatedLintWithReplacement extends TestLintRule {
  DeprecatedLintWithReplacement()
    : super(
        name: 'deprecated_lint_with_replacement',
        state: RuleState.deprecated(replacedBy: 'replacing_lint'),
      );
}

class DeprecatedSince3Lint extends TestLintRule {
  DeprecatedSince3Lint()
    : super(
        name: 'deprecated_since_3_lint',
        state: RuleState.deprecated(since: dart3),
      );
}

@reflectiveTest
class ErrorCodeValuesTest {
  test_errorCodes() {
    // Now that we're using unique names for comparison, the only reason to
    // split the codes by class is to find all of the classes that need to be
    // checked against `errorCodeValues`.
    var errorTypeMap = <Type, List<DiagnosticCode>>{};
    for (DiagnosticCode code in diagnosticCodeValues) {
      Type type = code.runtimeType;
      errorTypeMap.putIfAbsent(type, () => <DiagnosticCode>[]).add(code);
    }

    StringBuffer missingCodes = StringBuffer();
    errorTypeMap.forEach((Type errorType, List<DiagnosticCode> codes) {
      var listedNames = codes
          .map((DiagnosticCode code) => code.lowerCaseUniqueName)
          .toSet();

      var declaredNames = reflectClass(errorType).declarations.values
          .map((DeclarationMirror declarationMirror) {
            String name = declarationMirror.simpleName.toString();
            // TODO(danrubel): find a better way to extract the text from the symbol
            assert(name.startsWith('Symbol("') && name.endsWith('")'));
            return '$errorType.${name.substring(8, name.length - 2)}';
          })
          .where((String name) {
            return name == name.toUpperCase();
          })
          .toList();

      // Assert that all declared names are in errorCodeValues.

      for (String declaredName in declaredNames) {
        if (!listedNames.contains(declaredName)) {
          missingCodes.writeln();
          missingCodes.write('  $declaredName');
        }
      }
    });
    if (missingCodes.isNotEmpty) {
      fail('Missing error codes:$missingCodes');
    }
  }
}

class ReplacingLint extends TestLintRule {
  ReplacingLint() : super(name: 'replacing_lint');
}

class RuleNeg extends TestLintRule {
  RuleNeg() : super(name: 'rule_neg');

  @override
  List<String> get incompatibleRules => ['rule_pos'];
}

class RulePos extends TestLintRule {
  RulePos() : super(name: 'rule_pos');

  @override
  List<String> get incompatibleRules => ['rule_neg'];
}

class StableLint extends TestLintRule {
  StableLint() : super(name: 'stable_lint', state: RuleState.stable());
}

abstract class TestLintRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'lint_code',
    'Lint code.',
    correctionMessage: 'Lint code.',
    uniqueName: 'LintCode.lint_code',
  );

  TestLintRule({required super.name, super.state}) : super(description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}

class TestRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'fantastic_test_rule',
    'Fantastic test rule.',
    correctionMessage: 'Try fantastic test rule.',
    uniqueName: 'LintCode.fantastic_test_rule',
  );

  TestRule() : super(name: 'fantastic_test_rule', description: '');

  TestRule.withName(String name) : super(name: name, description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}
