// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import '../diagnostics/analysis_options/analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(OptionsFileValidatorTest);
    defineReflectiveTests(OptionsProviderTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
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

@reflectiveTest
class OptionsFileValidatorTest
    with
        LintRegistrationMixin,
        ResourceProviderMixin,
        AnalysisOptionsDiagnosticExpectationMixin {
  late final OptionsFileValidator validator = OptionsFileValidator(
    FileSource(newFile('/analysis_options.yaml', '')),
    isPrimarySource: true,
    contextRoot: convertPath('/'),
    optionsProvider: optionsProvider,
    resourceProvider: resourceProvider,
    sourceFactory: SourceFactory([ResourceUriResolver(resourceProvider)]),
    analysisOptionsCache: {},
  );
  final optionsProvider = AnalysisOptionsProvider(SourceFactoryImpl([]));

  void tearDown() {
    unregisterLintRules();
  }

  test_analyzer_cannotIgnore_badValue() {
    validate('''
analyzer:
  cannot-ignore:
    - not_an_error_code
//    ^^^^^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'not_an_error_code' isn't a recognized diagnostic code.
''');
  }

  test_analyzer_cannotIgnore_goodValue() {
    validate('''
analyzer:
  cannot-ignore:
    - invalid_annotation
''');
  }

  test_analyzer_cannotIgnore_lintRule() {
    registerLintRule(TestRule());
    validate('''
analyzer:
  cannot-ignore:
    - fantastic_test_rule
''');
  }

  test_analyzer_cannotIgnore_notAList() {
    validate('''
analyzer:
  cannot-ignore:
    one_error_code: true
// [diag.invalidSectionFormat][column 5][length 21] Invalid format for the 'cannot-ignore' section.
''');
  }

  test_analyzer_cannotIgnore_severity() {
    validate('''
analyzer:
  cannot-ignore:
    - error
''');
  }

  test_analyzer_cannotIgnore_valueNotAString() {
    validate('''
analyzer:
  cannot-ignore:
    one_error_code:
// [diag.invalidSectionFormat][column 5][length 31] Invalid format for the 'cannot-ignore' section.
      foo: bar
''');
  }

  test_analyzer_empty() {
    registerLintRule(TestRule());
    validate('''
analyzer:
''');
  }

  test_analyzer_enableExperiment_badValue() {
    validate('''
analyzer:
  enable-experiment:
    - not-an-experiment
//    ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not-an-experiment' isn't supported by 'enable-experiment'.
    ''');
  }

  test_analyzer_enableExperiment_mapValue() {
    validate('''
analyzer:
  enable-experiment:
    experiment: true
// [diag.invalidSectionFormat][column 5][length 21] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_enableExperiment_scalarValue() {
    validate('''
analyzer:
  enable-experiment: 7
// [diag.invalidSectionFormat][column 22][length 6] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_error_code_supported() {
    validate('''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    assignment_of_do_not_store: error
    dead_code: info
''');
  }

  test_analyzer_error_code_supported_bad_value() {
    var diagnostics = validate('''
analyzer:
  errors:
    unused_local_variable: ftw
//                         ^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ftw' isn't supported by 'errors'.
    ''');
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("The option 'ftw'"),
    );
  }

  test_analyzer_error_code_supported_bad_value_null() {
    var diagnostics = validate('''
analyzer:
  errors:
    unused_local_variable: null
//                         ^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'null' isn't supported by 'errors'.
    ''');
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("The option 'null'"),
    );
  }

  test_analyzer_error_code_unsupported() {
    var diagnostics = validate('''
analyzer:
  errors:
    not_supported: ignore
//  ^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'not_supported' isn't a recognized diagnostic code.
    ''');
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("'not_supported' isn't a recognized diagnostic code"),
    );
  }

  test_analyzer_error_code_unsupported_null() {
    var diagnostics = validate('''
analyzer:
  errors:
    null: ignore
//  ^^^^
// [diag.unrecognizedErrorCode] 'null' isn't a recognized diagnostic code.
    ''');
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("'null' isn't a recognized diagnostic code"),
    );
  }

  test_analyzer_errors_notAMap() {
    validate('''
analyzer:
  errors:
    - invalid_annotation
// [diag.invalidSectionFormat][column 5][length 45] Invalid format for the 'enable-experiment' section.
    - unused_import
    ''');
  }

  test_analyzer_errors_valueNotAScalar() {
    validate('''
analyzer:
  errors:
    invalid_annotation: ignore
    unused_import: [1, 2, 3]
//                 ^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_language_bad_format_list() {
    validate('''
analyzer:
  language:
    - notAnOption: true
// [diag.invalidSectionFormat][column 5][length 20] Invalid format for the 'language' section.
''');
  }

  test_analyzer_language_bad_format_scalar() {
    validate('''
analyzer:
  language: true
//          ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'language' section.
''');
  }

  // TODO(srawlins): Enable when we deprecate strict-raw-types.
  @SkippedTest(reason: 'Enable when we deprecate strict-raw-types')
  test_analyzer_language_strictRawTypes_deprecated() {
    validate('''
analyzer:
  language:
    strict-raw-types: true
//  ^^^^^^^^^^^^^^^^
// [diag.analysisOptionDeprecated] The option 'strict-raw-types' is no longer supported.
''');
  }

  test_analyzer_language_strictRawTypes_notDeprecatedIfFalse() {
    validate('''
analyzer:
  language:
    strict-raw-types: false
''');
  }

  test_analyzer_language_supports_empty() {
    validate('''
analyzer:
  language:
''');
  }

  test_analyzer_language_unsupported_key() {
    validate('''
analyzer:
  language:
    unsupported: true
//  ^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'unsupported' isn't supported by 'language'.
''');
  }

  test_analyzer_lint_codes_recognized() {
    registerLintRule(TestRule());
    validate('''
analyzer:
  errors:
    fantastic_test_rule: ignore
''');
  }

  test_analyzer_scalarValue() {
    validate('''
analyzer: 7
// [diag.invalidSectionFormat][column 11][length 6] Invalid format for the 'cannot-ignore' section.
    ''');
  }

  test_analyzer_supported_exclude() {
    validate('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
''');
  }

  test_analyzer_unsupported_option() {
    validate('''
analyzer:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'not_supported' isn't supported by 'analyzer'.
''');
  }

  test_chromeos_manifest_checks() {
    validate('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
  }

  test_chromeos_manifest_checks_invalid() {
    validate('''
analyzer:
  optional-checks:
    chromeos-manifest
//  ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'chromeos-manifest' isn't supported by ''chrome-os-manifest-checks' or 'propagate-linter-exceptions''.
''');
  }

  test_chromeos_manifest_checks_notAMap() {
    validate('''
analyzer:
  optional-checks:
    - chrome-os-manifest-checks
// [diag.invalidSectionFormat][column 5][length 28] Invalid format for the 'enable-experiment' section.
''');
  }

  test_codeStyle_format_bool_false() {
    validate('''
code-style:
  format: false
''');
  }

  test_codeStyle_format_bool_true() {
    validate('''
code-style:
  format: true
''');
  }

  test_codeStyle_format_invalid() {
    validate('''
code-style:
  format: 80
//        ^^
// [diag.unsupportedValue] The value '80' isn't supported by 'format'.
''');
  }

  test_codeStyle_format_string_false() {
    validate('''
code-style:
  format: "false"
''');
  }

  test_codeStyle_format_string_true() {
    validate('''
code-style:
  format: "true"
''');
  }

  test_codeStyle_format_string_true_mixedCase() {
    validate('''
code-style:
  format: "True"
''');
  }

  test_codeStyle_format_string_true_upperCase() {
    validate('''
code-style:
  format: "TRUE"
''');
  }

  test_codeStyle_nonMap() {
    validate('''
code-style: 7
//          ^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_unsupported_list() {
    validate('''
code-style:
  - format
// [diag.invalidSectionFormat][column 3][length 9] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_unsupported_scalar() {
    validate('''
code-style: format
//          ^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_unsupportedOption() {
    validate('''
code-style:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not_supported' isn't supported by 'code-style'.
''');
  }

  test_formatter_invalid_key() {
    validate('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
''');
  }

  test_formatter_invalid_keys() {
    validate('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
  wrong2: 123
//^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong2' isn't supported by 'formatter'.
''');
  }

  test_formatter_pageWidth_invalid_decimal() {
    validate('''
formatter:
  page_width: 123.45
//            ^^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_negativeInteger() {
    validate('''
formatter:
  page_width: -123
//            ^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_string() {
    validate('''
formatter:
  page_width: "123"
//            ^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_zero() {
    validate('''
formatter:
  page_width: 0
//            ^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_valid_integer() {
    validate('''
formatter:
  page_width: 123
''');
  }

  test_formatter_trailingCommas_invalid_map() {
    validate('''
formatter:
  trailing_commas:
    a: b
// [diag.invalidOption][column 5][length 5] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_invalid_numeric() {
    validate('''
formatter:
  trailing_commas: 1
//                 ^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_invalid_string() {
    validate('''
formatter:
  trailing_commas: foo
//                 ^^^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_valid() {
    validate('''
formatter:
  trailing_commas: automate
''');
  }

  test_formatter_valid_empty() {
    validate('''
formatter:
''');
  }

  test_linter_supported_rules() {
    registerLintRule(TestRule());
    validate('''
linter:
  rules:
    - fantastic_test_rule
    ''');
  }

  test_linter_unsupported_option() {
    validate('''
linter:
  unsupported: true
//^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValue] The option 'unsupported' isn't supported by 'linter'.
    ''');
  }

  test_plugins_dependencyOverrides() {
    validate('''
plugins:
  dependency_overrides:
    one:
      git: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_dependencyOverrides_invalid_mapKey() {
    validate('''
plugins:
  dependency_overrides:
    one:
      ppath: foo/bar
//    ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/dependency_overrides/one'.
''');
  }

  test_plugins_diagnostics_invalid() {
    validate('''
plugins:
  one:
    diagnostics:
      code: abc
//          ^^^
// [diag.unsupportedOptionWithLegalValues] The option 'abc' isn't supported by 'plugins/one/diagnostics'.
''');
  }

  test_plugins_diagnostics_notAMap() {
    validate('''
plugins:
  one:
    diagnostics: 7
//               ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins/one/diagnostics' section.
''');
  }

  test_plugins_diagnostics_supported_severity() {
    validate('''
plugins:
  one:
    diagnostics:
      code1: ignore
      code2: warning
      code3: error
      code4: info
''');
  }

  test_plugins_diagnostics_supported_trueOrFalse() {
    validate('''
plugins:
  one:
    diagnostics:
      code1: true
      code2: false
''');
  }

  test_plugins_each_invalid_mapKey() {
    validate('''
plugins:
  one:
    ppath: foo/bar
//  ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/one'.
''');
  }

  test_plugins_each_valid_mapKey() {
    validate('''
plugins:
  one:
    path: foo/bar
''');
  }

  test_plugins_each_valid_scalar() {
    validate('''
plugins:
  one: ^1.2.3
''');
  }

  test_plugins_git_invalid_key() {
    validate('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      invalid: main
//    ^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'invalid' isn't supported by 'plugins/one/git'.
''');
  }

  test_plugins_git_invalid_value() {
    validate('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      ref: 7
//         ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins/one/git/ref' section.
''');
  }

  test_plugins_git_map() {
    validate('''
plugins:
  one:
    git:
      url: https://github.com/dart-lang/linter.git
      ref: main
      path: pkg/linter
      tag_pattern: 'v*'
''');
  }

  test_plugins_git_scalar() {
    validate('''
plugins:
  one:
    git: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_invalid_scalar() {
    validate('''
plugins: 7
//       ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins' section.
''');
  }

  test_plugins_valid_empty() {
    validate('''
plugins:
''');
  }

  test_propagate_linter_exceptions() {
    validate('''
analyzer:
  optional-checks:
    propagate-linter-exceptions
''');
  }

  test_propagate_linter_exceptions_mapKey() {
    validate('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
  }

  List<Diagnostic> validate(String source) {
    var cleanSource = removeDiagnosticExpectations(source);
    var optionsFile = newFile('/analysis_options.yaml', cleanSource);
    var sourceUrl = optionsFile.toUri();
    var options = optionsProvider.getOptionsFromString(
      cleanSource,
      sourceUrl: sourceUrl,
    );
    var diagnosticListener = RecordingDiagnosticListener();
    validator.validate(
      options,
      DiagnosticReporter(diagnosticListener, FileSource(optionsFile)),
    );
    var diagnostics = diagnosticListener.diagnostics;
    assertDiagnosticMarkersInFiles(
      codeByFile: {optionsFile: source},
      diagnostics: diagnostics,
    );
    return diagnostics;
  }
}

@reflectiveTest
class OptionsProviderTest
    with ResourceProviderMixin, AnalysisOptionsDiagnosticExpectationMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  File get analysisOptionsFile => getFile('/analysis_options.yaml');

  void assertDiagnosticsInOptionsFile(File file, String code) {
    _assertDiagnosticsInOptionsFiles(file, {file: code});
  }

  void setUp() {
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  test_circularInclude_nontrivial_direct() {
    // Test that the appropriate error is issued if `analysis_options.yaml`
    // tries to include another options file which in turn includes
    // `analysis_options.yaml`.
    newFile('/other_options.yaml', r'''
include: analysis_options.yaml
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/other_options.yaml' includes '/other_options.yaml', creating a circular reference.
''');
  }

  test_circularInclude_nontrivial_nested() {
    // Test that the appropriate error is issued if a file included by
    // `analysis_options.yaml` tries to include itself indirectly.
    // Note: comments ensure that the `include` directives in each file are at
    // different file offsets, so that we can validate that the reported source
    // ranges are correct.
    newFile('/other_options1.yaml', r'''
include: other_options2.yaml
''');
    newFile('/other_options2.yaml', r'''
# comment
include: other_options1.yaml
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
# comment
# comment
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options1.yaml(9..27): The file includes itself recursively.
''');
  }

  test_circularInclude_trivial_direct() {
    // Test that the appropriate error is issued if `analysis_options.yaml`
    // tries to include itself.
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  test_circularInclude_trivial_nested() {
    // Test that the appropriate error is issued if a file included by
    // `analysis_options.yaml` tries to include itself.
    // Note: comments ensure that the `include` directives in each file are at
    // different file offsets, so that we can validate that the reported source
    // ranges are correct.
    newFile('/other_options.yaml', r'''
include: other_options.yaml
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
# comment
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options.yaml(9..26): The file includes itself recursively.
''');
  }

  test_invalidYaml_direct() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
formatter:
  page_width: 80
  page_width: 90
//^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''');
  }

  test_invalidYaml_nested() {
    newFile('/other_options.yaml', r'''
formatter:
  page_width: 80
  page_width: 90
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileParseError] Duplicate mapping key. in /other_options.yaml(30..40)
''');
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_listForm() {
    newFile(convertPath('/other_options.yaml'), '''
analyzer:
  plugins:
    - plugin_one
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_mapForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
analyzer:
  plugins:
    plugin_two:
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
      foo: bar
''');
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_scalarForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
analyzer:
  plugins: plugin_two
//         ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');
  }

  test_multiplePlugins_firstIsIndirectlyIncluded_secondIsDirect() {
    newFile('/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    newFile('/other_options.yaml', '''
include: more_options.yaml
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');
  }

  test_multiplePlugins_firstIsIndirectlyIncluded_secondIsDirectlyIncluded() {
    newFile('/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    newFile('/other_options.yaml', '''
include: more_options.yaml
analyzer:
  plugins:
    - plugin_two
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options.yaml(54..63): Multiple plugins can't be enabled.
''');
  }

  test_multiplePlugins_multipleDirect_listForm() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
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
  }

  test_multiplePlugins_multipleDirect_listForm_nonString() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
analyzer:
  plugins:
    - 7
    - plugin_one
''');
  }

  test_multiplePlugins_multipleDirect_listForm_sameName() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_one
''');
  }

  test_multiplePlugins_multipleDirect_mapForm() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_two: sure
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''');
  }

  test_multiplePlugins_multipleDirect_mapForm_sameName() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_one: sure
//  ^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''');
  }

  test_nonExistentInclude_direct() {
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  test_nonExistentInclude_nested() {
    newFile('/other_options1.yaml', r'''
include: other_options2.yaml
''');
    assertDiagnosticsInOptionsFile(analysisOptionsFile, r'''
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options2.yaml' included in '/other_options1.yaml' can't be found when analyzing '/'.
''');
  }

  test_pluginsInInnerOptions() {
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    assertDiagnosticsInOptionsFile(getFile('/inner/analysis_options.yaml'), '''
plugins:
  one: ^1.0.0
// [diag.pluginsInInnerOptions][column 3][length 12] Plugins can only be specified in the root of a pub workspace or the root of a package that isn't in a workspace.
''');
  }

  test_pluginsInInnerOptions_included() {
    newFile('/analysis_options.yaml', '''
plugins:
  one: ^1.0.0
''');
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    assertDiagnosticsInOptionsFile(getFile('/inner/analysis_options.yaml'), '''
include: ../analysis_options.yaml
''');
  }

  test_pluginsInInnerOptions_included_notAtContextRoot() {
    var inner1Path = '/inner1/analysis_options.yaml';
    var inner2Path = '/inner2/analysis_options.yaml';
    newFile(inner2Path, '''
plugins:
  one: ^1.0.0
''');
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    assertDiagnosticsInOptionsFile(getFile(inner1Path), '''
include: ../inner2/analysis_options.yaml
''');
  }

  void _assertDiagnosticsInOptionsFiles(
    File initialFile,
    Map<File, String> codeByFile,
  ) {
    var cleanCodeByFile = writeFilesWithoutDiagnosticExpectations(codeByFile);
    var diagnostics = AnalysisOptionsAnalyzer(
      initialSource: sourceFactory.forUri2(initialFile.toUri())!,
      sourceFactory: sourceFactory,
      contextRoot: convertPath('/'),
      sdkVersionConstraint: null,
      resourceProvider: resourceProvider,
    ).walkIncludes(content: cleanCodeByFile[initialFile]!);

    assertDiagnosticMarkersInFiles(
      codeByFile: codeByFile,
      diagnostics: diagnostics,
    );
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
