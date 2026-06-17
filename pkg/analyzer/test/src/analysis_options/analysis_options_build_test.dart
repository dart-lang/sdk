// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_parser.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsBuildTest);
    defineReflectiveTests(UpdateNodeTextExpectations);

    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980
  });
}

@reflectiveTest
class AnalysisOptionsBuildTest extends AbstractAnalysisOptionsTest {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  AnalysisOptionsImpl getAnalysisOptionsFromMissingFile(String filePath) {
    var file = getFile(filePath);
    return AnalysisOptionsParseSession()
        .parse(
          sourceFactory: sourceFactory,
          contextRoot: getFolder(testPackageRootPath),
          file: file,
        )
        .analysisOptions;
  }

  test_fromFile_analyzer_plugins_chooseFirstLegacyPlugin() {
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

  test_fromFile_empty() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r'''#empty''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_include_analyzerErrors_merged() {
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

  test_fromFile_include_analyzerErrors_merged_chainOfIncludes() {
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

  test_fromFile_include_analyzerErrors_merged_multipleIncludes() {
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

  test_fromFile_include_analyzerErrors_outermostWins() {
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

  test_fromFile_include_analyzerErrors_subsequentIncludeWins() {
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

  test_fromFile_include_analyzerExclude_merged() {
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

  test_fromFile_include_analyzerLanguage_merged() {
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

  test_fromFile_include_analyzerPlugins_legacyPlugin() {
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

  test_fromFile_include_linterRules_emptyLocal() {
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

  test_fromFile_include_linterRules_merged() {
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

  test_fromFile_include_linterRules_merged_differentFormats() {
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

  test_fromFile_include_linterRules_outermostWins() {
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

  test_fromFile_include_missing() {
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

  test_fromFile_include_multipleSections_merged() {
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

  test_fromFile_include_plugins_pathRebased() {
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

  test_fromFile_invalidYaml() {
    var options = parseAnalysisOptionsFilesWithDiagnostics({
      analysisOptionsFile: r''':''',
    });

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_missing() {
    newFolder('/notFile');

    var options = getAnalysisOptionsFromMissingFile(
      '/notFile/analysis_options.yaml',
    );

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_signature_mergeStable() {
    var sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
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
      var options2 = parseSession
          .parse(
            sourceFactory: sourceFactory,
            contextRoot: getFolder(testPackageRootPath),
            file: mainOptions,
          )
          .analysisOptions;
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_fromFile_usesRequestedFile() {
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

  test_fromYaml_analyzer_cannotIgnore() {
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

  test_fromYaml_analyzer_cannotIgnore_severity() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('invalid_annotation'));
    expect(unignorableCodeNames.length, greaterThan(500));
  }

  test_fromYaml_analyzer_cannotIgnore_severity_withProcessor() {
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

  test_fromYaml_analyzer_cannotIgnore_severity_withProcessor_oldSeverity() {
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

  test_fromYaml_analyzer_errors_cannotBeIgnoredByUniqueName() {
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

  test_fromYaml_analyzer_errors_severityIsError() {
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

  test_fromYaml_analyzer_errors_severityIsIgnore() {
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

  test_fromYaml_analyzer_errors_sharedNameAppliesToAllSharedCodes() {
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

  test_fromYaml_analyzer_exclude() {
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

  test_fromYaml_analyzer_exclude_withNonStrings() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  excludePatterns
    foo/bar.dart
    test/**
''');
  }

  test_fromYaml_analyzer_optionalChecks_chromeOsManifestChecks() {
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

  test_fromYaml_analyzer_optionalChecks_chromeOsManifestChecks_map() {
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

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_empty() {
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

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_true() {
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

  test_fromYaml_analyzer_plugins_legacy_list() {
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

  test_fromYaml_analyzer_plugins_legacy_map() {
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

  test_fromYaml_analyzer_plugins_legacy_string() {
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

  test_fromYaml_codeStyle_format_false() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
code-style:
  format: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_fromYaml_codeStyle_format_true() {
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

  test_fromYaml_codeStyle_lint_alwaysDeclareReturnTypes() {
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

  test_fromYaml_codeStyle_lint_alwaysPutRequiredNamedParametersFirst() {
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

  test_fromYaml_codeStyle_lint_alwaysSpecifyTypes() {
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

  test_fromYaml_codeStyle_lint_alwaysUsePackageImports() {
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

  test_fromYaml_codeStyle_lint_avoidAnnotatingWithDynamic() {
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

  test_fromYaml_codeStyle_lint_avoidRenamingMethodParameters() {
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

  test_fromYaml_codeStyle_lint_combinatorsOrdering() {
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

  test_fromYaml_codeStyle_lint_preferConstDeclarations() {
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

  test_fromYaml_codeStyle_lint_preferDoubleQuotes() {
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

  test_fromYaml_codeStyle_lint_preferFinalInForEach() {
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

  test_fromYaml_codeStyle_lint_preferFinalLocals() {
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

  test_fromYaml_codeStyle_lint_preferIntLiterals() {
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

  test_fromYaml_codeStyle_lint_preferRelativeImports() {
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

  test_fromYaml_codeStyle_lint_requireTrailingCommas() {
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

  test_fromYaml_codeStyle_lint_sortConstructorsFirst() {
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

  test_fromYaml_plugins_dependencyOverrides_git() {
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

  test_fromYaml_plugins_dependencyOverrides_relative() {
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

  test_fromYaml_plugins_dependencyOverrides_versionConstraintHosted() {
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

  test_fromYaml_plugins_git() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    git: https://github.com/dart-lang/plugin_one.git
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: GitPluginSource
          url: https://github.com/dart-lang/plugin_one.git
''');
  }

  test_fromYaml_plugins_git_full() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    git:
      url: https://github.com/dart-lang/sdk.git
      ref: main
      path: pkg/plugin_one
      tag_pattern: 'v*'
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: GitPluginSource
          url: https://github.com/dart-lang/sdk.git
          ref: main
          path: pkg/plugin_one
          tagPattern: v*
''');
  }

  test_fromYaml_plugins_git_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    git: https://github.com/dart-lang/plugin_one.git
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: GitPluginSource
          url: https://github.com/dart-lang/plugin_one.git
''');
  }

  test_fromYaml_plugins_path() {
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

  test_fromYaml_plugins_path_relative() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one:
    path: foo/bar
''');

    assertAnalysisOptionsText(analysisOptions, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: /home/test/foo/bar
''');
  }

  test_fromYaml_plugins_path_relativeNonNormal() {
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

  test_fromYaml_plugins_scalar() {
    var analysisOptions = parseAnalysisOptionsWithDiagnostics('''
plugins:
  plugin_one: ^1.2.3
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

  test_fromYaml_plugins_version() {
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

  test_fromYaml_plugins_versionHosted() {
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

  test_fromYaml_signature_differsForHostedPlugin() {
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

  test_fromYaml_signature_errorOrderingStable() {
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

  test_fromYaml_signature_lintsOrderingStable() {
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

  test_fromYaml_signature_pluginOrderingStable() {
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
