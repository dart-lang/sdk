// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:linter/src/rules.dart' as linter_rules;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsBuildTest);

    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980
  });
}

@reflectiveTest
class AnalysisOptionsBuildTest extends AbstractAnalysisOptionsTest {
  late AnalysisOptionsProvider provider;

  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  String get optionsFilePath => '/analysis_options.yaml';

  AnalysisOptionsImpl getAnalysisOptionsFromFileContent(String content) {
    var file = newFile('/project/analysis_options.yaml', content);
    return provider.getAnalysisOptionsFromFile(
      file,
      resourceProvider: resourceProvider,
    );
  }

  AnalysisOptionsImpl getAnalysisOptionsFromFilePath(String filePath) {
    var file = getFile(filePath);
    return provider.getAnalysisOptionsFromFile(
      file,
      resourceProvider: resourceProvider,
    );
  }

  @override
  void setUp() {
    super.setUp();
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  test_fromFile_analyzer_plugins_chooseFirstLegacyPlugin() {
    newFile('/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_ddd
    - plugin_ggg
    - plugin_aaa
''');
    newFile('/other_options.yaml', '''
include: more_options.yaml
analyzer:
  plugins:
    - plugin_eee
    - plugin_hhh
    - plugin_bbb
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_fff
    - plugin_iii
    - plugin_ccc
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);
    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    plugin_ddd
''');
  }

  test_fromFile_empty() {
    newFile('/$analysisOptionsYaml', r'''#empty''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_include_analyzerErrors_merged() {
    newFile('/other_options.yaml', '''
analyzer:
  errors:
    toplevelerror: warning
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  errors:
    lowlevelerror: warning
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    toplevelerror: warning
    lowlevelerror: warning
''');
  }

  test_fromFile_include_analyzerErrors_merged_chainOfIncludes() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: error
''');
    newFile('/second_options.yaml', '''
include: first_options.yaml
analyzer:
  errors:
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include: second_options.yaml
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    error_1: error
    error_2: warning
''');
  }

  test_fromFile_include_analyzerErrors_merged_multipleIncludes() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: error
''');
    newFile('/second_options.yaml', '''
analyzer:
  errors:
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include:
  - first_options.yaml
  - second_options.yaml
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    error_1: error
    error_2: warning
''');
  }

  test_fromFile_include_analyzerErrors_outermostWins() {
    newFile('/other_options.yaml', '''
analyzer:
  errors:
    error_1: warning
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  errors:
    error_1: ignore
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    error_1: ignore
    error_2: warning
''');
  }

  test_fromFile_include_analyzerErrors_subsequentIncludeWins() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: warning
    error_2: warning
''');
    newFile('/second_options.yaml', '''
analyzer:
  errors:
    error_1: ignore
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include:
  - first_options.yaml
  - second_options.yaml
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    error_1: ignore
    error_2: warning
''');
  }

  test_fromFile_include_analyzerExclude_merged() {
    newFile('/other_options.yaml', '''
analyzer:
  exclude:
    - toplevelexclude.dart
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  exclude:
    - lowlevelexclude.dart
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  excludePatterns
    toplevelexclude.dart
    lowlevelexclude.dart
''');
  }

  test_fromFile_include_analyzerLanguage_merged() {
    newFile('/other_options.yaml', '''
analyzer:
  language:
    strict-casts: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  language:
    strict-inference: true
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  strictCasts: true
  strictInference: true
''');
  }

  test_fromFile_include_analyzerPlugins_legacyPlugin() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    toplevelplugin:
      enabled: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  enabledLegacyPluginNames
    toplevelplugin
''');
  }

  test_fromFile_include_linterRules_emptyLocal() {
    newFile('/foo.yaml', r'''
linter:
  rules:
    - included_lint
''');
    newFile('/$analysisOptionsYaml', r'''
include: foo.yaml
linter:
  rules:
    # local_lint: false
''');

    registerLintRule(TestRule.withName('included_lint'));
    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    included_lint
''');
  }

  test_fromFile_include_linterRules_merged() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    - top_level_lint
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''');

    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    low_level_lint
    top_level_lint
''');
  }

  test_fromFile_include_linterRules_merged_differentFormats() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    top_level_lint: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''');

    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  lint: true
  lintRules
    low_level_lint
    top_level_lint
''');
  }

  test_fromFile_include_linterRules_outermostWins() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    - top_level_lint
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    top_level_lint: false
''');

    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRule(topLevelLint);
    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_include_missing() {
    newFile('/$analysisOptionsYaml', r'''
include: /foo.yaml
''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_include_multipleSections_merged() {
    newFile('/included_options.yaml', '''
analyzer:
  errors:
    included_error: warning
linter:
  rules:
    - included_lint
''');
    newFile(optionsFilePath, r'''
include: included_options.yaml
analyzer:
  errors:
    main_error: ignore
  language:
    strict-casts: true
code-style:
  format: true
linter:
  rules:
    - main_lint
''');

    registerLintRules([
      TestRule.withName('included_lint'),
      TestRule.withName('main_lint'),
    ]);
    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    included_error: warning
    main_error: ignore
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
    newFile('/project/analysis_options.yaml', '''
plugins:
  plugin_one:
    path: foo/bar
''');
    newFile('/project/foo/analysis_options.yaml', r'''
include: ../analysis_options.yaml
''');

    var options = getAnalysisOptionsFromFilePath(
      '/project/foo/analysis_options.yaml',
    );

    assertAnalysisOptionsText(options, '''
AnalysisOptionsImpl
  pluginsOptions
    configurations
      plugin_one
        source: PathPluginSource
          path: ${convertPath('/project/foo/bar')}
''');
  }

  test_fromFile_invalidYaml() {
    newFile('/$analysisOptionsYaml', r''':''');

    var options = getAnalysisOptionsFromFilePath(optionsFilePath);

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_missing() {
    newFolder('/notFile');

    var options = getAnalysisOptionsFromFilePath(
      '/notFile/analysis_options.yaml',
    );

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
''');
  }

  test_fromFile_signature_mergeStable() {
    var sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    var otherOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options_helper.yaml"),
    );
    otherOptions.writeAsStringSync('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var mainOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options.yaml"),
    );
    mainOptions.writeAsStringSync('''
include: analysis_options_helper.yaml
analyzer:
  errors:
    d: ignore
''');

    var options = optionsProvider.getAnalysisOptionsFromFile(
      mainOptions,
      resourceProvider: resourceProvider,
    );
    var sig1 = options.signature;
    for (var i = 0; i < 100; i++) {
      var options2 = optionsProvider.getAnalysisOptionsFromFile(
        mainOptions,
        resourceProvider: resourceProvider,
      );
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_fromFile_usesRequestedFile() {
    newFolder('/foo/bar');
    newFile('/foo/$analysisOptionsYaml', r'''
analyzer:
  errors:
    foo_error: warning
''');
    newFile('/foo/bar/$analysisOptionsYaml', r'''
analyzer:
  errors:
    bar_error: ignore
''');

    var options = getAnalysisOptionsFromFilePath(
      '/foo/bar/analysis_options.yaml',
    );

    assertAnalysisOptionsText(options, r'''
AnalysisOptionsImpl
  errorProcessors
    bar_error: ignore
''');
  }

  test_fromYaml_analyzer_cannotIgnore() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  unignorableDiagnosticCodeNames
    another
    one_error_code
''');
  }

  test_fromYaml_analyzer_cannotIgnore_severity() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('invalid_annotation'));
    expect(unignorableCodeNames.length, greaterThan(500));
  }

  test_fromYaml_analyzer_cannotIgnore_severity_withProcessor() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  errors:
    return_type_invalid_for_catch_error: ignore
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
  chromeOsManifestChecks: true
''');
  }

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_default() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  optional-checks:
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_empty() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_fromYaml_analyzer_optionalChecks_propagateLinterExceptions_true() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
analyzer:
  plugins:
    - angular2
    - intl
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
code-style:
  format: false
''');
    assertAnalysisOptionsText(analysisOptions, r'''
AnalysisOptionsImpl
''');
  }

  test_fromYaml_codeStyle_format_true() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
          path: ${convertPath('/project/foo/bar')}
    dependencyOverrides
      some_package1
        source: PathPluginSource
          path: ${convertPath('/some_package1')}
      some_package2
        source: PathPluginSource
          path: ${convertPath('/project/sub_folder/some_package2')}
''');
  }

  test_fromYaml_plugins_dependencyOverrides_versionConstraintHosted() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
          path: ${convertPath('/project/foo/bar')}
''');
  }

  test_fromYaml_plugins_path_relativeNonNormal() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
          path: ${convertPath('/foo/baz')}
''');
  }

  test_fromYaml_plugins_scalar() {
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var analysisOptions = getAnalysisOptionsFromFileContent('''
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
    var options = getAnalysisOptionsFromFileContent('''
plugins:
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''');
    var sig1 = options.signature;

    for (var i = 0; i < 10; i++) {
      var options2 = getAnalysisOptionsFromFileContent('''
plugins:
  plugin_one: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, isNot(sig2));
    }
  }

  test_fromYaml_signature_errorOrderingStable() {
    var options = getAnalysisOptionsFromFileContent('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = getAnalysisOptionsFromFileContent('''
analyzer:
  errors:
    b: ignore
    a: warning
    c: ignore
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_fromYaml_signature_lintsOrderingStable() {
    linter_rules.registerLintRules();
    var knownRules = Registry.ruleRegistry.rules
        .map((rule) => "    - ${rule.name}")
        .toList(growable: false);
    var options = getAnalysisOptionsFromFileContent('''
linter:
  rules:
${knownRules.reversed.join("\n")}
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      knownRules.shuffle();
      var options2 = getAnalysisOptionsFromFileContent('''
linter:
  rules:
${knownRules.join("\n")}
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_fromYaml_signature_pluginOrderingStable() {
    var options = getAnalysisOptionsFromFileContent('''
plugins:
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
  plugin_three: ^1.2.3
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = getAnalysisOptionsFromFileContent('''
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
