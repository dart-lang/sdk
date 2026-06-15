// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(AnalysisOptionsValidationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnalysisOptionsValidationTest extends AbstractAnalysisOptionsTest {
  static const otherLib = '/other/lib';

  @override
  get dependencies => {'other': otherLib};

  void newEmptyIncludedOptionsFile() {
    // TODO(scheglov): Remove this file and the unnecessary include directives
    // in these value-only tests.
    newFile('/included.yaml', '');
  }

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

  test_analyzer_cannotIgnore_badValue() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    - not_an_error_code
//    ^^^^^^^^^^^^^^^^^
// [diag.unrecognizedErrorCode] 'not_an_error_code' isn't a recognized diagnostic code.
''');
  }

  test_analyzer_cannotIgnore_goodValue() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    - invalid_annotation
''');
  }

  test_analyzer_cannotIgnore_lintRule() {
    registerLintRule(TestRule());
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    - fantastic_test_rule
''');
  }

  test_analyzer_cannotIgnore_notAList() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    one_error_code: true
// [diag.invalidSectionFormat][column 5][length 21] Invalid format for the 'cannot-ignore' section.
''');
  }

  test_analyzer_cannotIgnore_severity() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    - error
''');
  }

  test_analyzer_cannotIgnore_valueNotAString() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  cannot-ignore:
    one_error_code:
// [diag.invalidSectionFormat][column 5][length 31] Invalid format for the 'cannot-ignore' section.
      foo: bar
''');
  }

  test_analyzer_empty() {
    registerLintRule(TestRule());
    assertAnalysisOptionsDiagnostics('''
analyzer:
''');
  }

  test_analyzer_enableExperiment_badValue() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  enable-experiment:
    - not-an-experiment
//    ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not-an-experiment' isn't supported by 'enable-experiment'.
    ''');
  }

  test_analyzer_enableExperiment_mapValue() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  enable-experiment:
    experiment: true
// [diag.invalidSectionFormat][column 5][length 21] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_enableExperiment_scalarValue() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  enable-experiment: 7
// [diag.invalidSectionFormat][column 22][length 6] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_errors_code_supported() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    assignment_of_do_not_store: error
    dead_code: info
''');
  }

  test_analyzer_errors_code_supported_badValue() {
    var diagnostics = assertAnalysisOptionsDiagnostics('''
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

  test_analyzer_errors_code_supported_nullValue() {
    var diagnostics = assertAnalysisOptionsDiagnostics('''
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

  test_analyzer_errors_code_unsupported() {
    var diagnostics = assertAnalysisOptionsDiagnostics('''
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

  test_analyzer_errors_code_unsupported_null() {
    var diagnostics = assertAnalysisOptionsDiagnostics('''
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

  test_analyzer_errors_lintCode_recognized() {
    registerLintRule(TestRule());
    assertAnalysisOptionsDiagnostics('''
analyzer:
  errors:
    fantastic_test_rule: ignore
''');
  }

  test_analyzer_errors_notMap() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  errors:
    - invalid_annotation
// [diag.invalidSectionFormat][column 5][length 45] Invalid format for the 'enable-experiment' section.
    - unused_import
    ''');
  }

  test_analyzer_errors_valueNotScalar() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  errors:
    invalid_annotation: ignore
    unused_import: [1, 2, 3]
//                 ^^^^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'enable-experiment' section.
    ''');
  }

  test_analyzer_exclude_supported() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
''');
  }

  test_analyzer_language_notMap_list() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language:
    - notAnOption: true
// [diag.invalidSectionFormat][column 5][length 20] Invalid format for the 'language' section.
''');
  }

  test_analyzer_language_notMap_scalar() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language: true
//          ^^^^
// [diag.invalidSectionFormat] Invalid format for the 'language' section.
''');
  }

  // TODO(srawlins): Enable when we deprecate strict-raw-types.
  @SkippedTest(reason: 'Enable when we deprecate strict-raw-types')
  test_analyzer_language_strictRawTypes_deprecated() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language:
    strict-raw-types: true
//  ^^^^^^^^^^^^^^^^
// [diag.analysisOptionDeprecated] The option 'strict-raw-types' is no longer supported.
''');
  }

  test_analyzer_language_strictRawTypes_notDeprecatedIfFalse() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language:
    strict-raw-types: false
''');
  }

  test_analyzer_language_supports_empty() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language:
''');
  }

  test_analyzer_language_unsupportedKey() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  language:
    unsupported: true
//  ^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'unsupported' isn't supported by 'language'.
''');
  }

  test_analyzer_notMap() {
    assertAnalysisOptionsDiagnostics('''
analyzer: 7
// [diag.invalidSectionFormat][column 11][length 6] Invalid format for the 'cannot-ignore' section.
    ''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_invalid() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  optional-checks:
    chromeos-manifest
//  ^^^^^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'chromeos-manifest' isn't supported by ''chrome-os-manifest-checks' or 'propagate-linter-exceptions''.
''');
  }

  test_analyzer_optionalChecks_chromeOsManifestChecks_notMap() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  optional-checks:
    - chrome-os-manifest-checks
// [diag.invalidSectionFormat][column 5][length 28] Invalid format for the 'enable-experiment' section.
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions
''');
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_mapKey() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
  }

  test_analyzer_plugins_multiple_directList() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
    - plugin_three
//    ^^^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_directList_nonString() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
analyzer:
  plugins:
    - 7
    - plugin_one
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_directList_sameName() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_one
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_directMap() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_two: sure
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_directMap_sameName() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_one: sure
//  ^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_firstIncludedSecondDirect_list() {
    newFile(convertPath('/other_options.yaml'), '''
analyzer:
  plugins:
    - plugin_one
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_firstIncludedSecondDirect_map() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  plugins:
    plugin_two:
//  ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
      foo: bar
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_firstIncludedSecondDirect_scalar() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  plugins: plugin_two
//         ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_firstIndirectlyIncludedSecondDirect() {
    newFile('/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    newFile('/other_options.yaml', '''
include: more_options.yaml
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
//    ^^^^^^^^^^
// [diag.multiplePlugins] Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_plugins_multiple_firstIndirectlyIncludedSecondIncluded() {
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
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options.yaml(54..63): Multiple plugins can't be enabled.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_analyzer_unsupportedOption() {
    assertAnalysisOptionsDiagnostics('''
analyzer:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'not_supported' isn't supported by 'analyzer'.
''');
  }

  test_codeStyle_format_bool_false() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: false
''');
  }

  test_codeStyle_format_bool_true() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: true
''');
  }

  test_codeStyle_format_invalid() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: 80
//        ^^
// [diag.unsupportedValue] The value '80' isn't supported by 'format'.
''');
  }

  test_codeStyle_format_string_false() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: "false"
''');
  }

  test_codeStyle_format_string_true() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: "true"
''');
  }

  test_codeStyle_format_string_true_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: "True"
''');
  }

  test_codeStyle_format_string_true_upperCase() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  format: "TRUE"
''');
  }

  test_codeStyle_notMap() {
    assertAnalysisOptionsDiagnostics('''
code-style: 7
//          ^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_notMap_list() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  - format
// [diag.invalidSectionFormat][column 3][length 9] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_notMap_scalar() {
    assertAnalysisOptionsDiagnostics('''
code-style: format
//          ^^^^^^
// [diag.invalidSectionFormat] Invalid format for the 'code-style' section.
''');
  }

  test_codeStyle_unsupportedOption() {
    assertAnalysisOptionsDiagnostics('''
code-style:
  not_supported: true
//^^^^^^^^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'not_supported' isn't supported by 'code-style'.
''');
  }

  test_formatter_pageWidth_invalid_decimal() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  page_width: 123.45
//            ^^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_negativeInteger() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  page_width: -123
//            ^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_string() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  page_width: "123"
//            ^^^^^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_invalid_zero() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  page_width: 0
//            ^
// [diag.invalidOption] Invalid option specified for 'page_width': "page_width" must be a positive integer.
''');
  }

  test_formatter_pageWidth_valid_integer() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  page_width: 123
''');
  }

  test_formatter_trailingCommas_invalid_map() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  trailing_commas:
    a: b
// [diag.invalidOption][column 5][length 5] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_invalid_numeric() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  trailing_commas: 1
//                 ^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_invalid_string() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  trailing_commas: foo
//                 ^^^
// [diag.invalidOption] Invalid option specified for 'trailing_commas': "trailing_commas" must be "automate" or "preserve".
''');
  }

  test_formatter_trailingCommas_valid() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  trailing_commas: automate
''');
  }

  test_formatter_unsupportedKey() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
''');
  }

  test_formatter_unsupportedKeys() {
    assertAnalysisOptionsDiagnostics('''
formatter:
  wrong: 123
//^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong' isn't supported by 'formatter'.
  wrong2: 123
//^^^^^^
// [diag.unsupportedOptionWithoutValues] The option 'wrong2' isn't supported by 'formatter'.
''');
  }

  test_formatter_valid_empty() {
    assertAnalysisOptionsDiagnostics('''
formatter:
''');
  }

  test_include_missing_direct() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_include_missing_nested() {
    newFile('/other_options1.yaml', r'''
include: other_options2.yaml
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'other_options2.yaml' included in '/other_options1.yaml' can't be found when analyzing '/'.
''',
    }, initialFile: analysisOptionsFile);
  }

  Future<void> test_include_missing_packageUri_doubleQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: "package:pedantic/analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  Future<void> test_include_missing_packageUri_listFirst() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
  - included1.yaml
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_include_missing_packageUri_listSecond() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - included1.yaml
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_include_missing_packageUri_notQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: package:pedantic/analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  Future<void> test_include_missing_packageUri_singleQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: 'package:pedantic/analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  test_include_parse_duplicateKey_inIncludedFile() {
    newFile('/other_options.yaml', r'''
formatter:
  page_width: 80
  page_width: 90
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileParseError] Duplicate mapping key. in /other_options.yaml(30..40)
''',
    }, initialFile: analysisOptionsFile);
  }

  test_include_recursive_cycle_direct() {
    // Test that the appropriate error is issued if `analysis_options.yaml`
    // tries to include another options file which in turn includes
    // `analysis_options.yaml`.
    newFile('/other_options.yaml', r'''
include: analysis_options.yaml
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/other_options.yaml' includes '/other_options.yaml', creating a circular reference.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_include_recursive_cycle_inIncludedFiles() {
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
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
# comment
# comment
include: other_options1.yaml
//       ^^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options1.yaml(9..27): The file includes itself recursively.
''',
    }, initialFile: analysisOptionsFile);
  }

  Future<void> test_include_recursive_includedCycle() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(9..14): The file includes itself recursively.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: a.yaml
''',
    });
  }

  Future<void> test_include_recursive_includedFileSelf() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(9..14): The file includes itself recursively.
''',
      getFile('/a.yaml'): '''
include: a.yaml
''',
    });
  }

  Future<void> test_include_recursive_initialThroughChain() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
    });
  }

  Future<void> test_include_recursive_initialThroughChain_listAtTop() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - empty.yaml
  - a.yaml
//  ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('/empty.yaml'): '''
''',
    });
  }

  Future<void>
  test_include_recursive_initialThroughChain_listInIncludedFile() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include:
  - empty.yaml
  - b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('/empty.yaml'): '''
''',
    });
  }

  Future<void> test_include_recursive_none_nestedSiblingIncludes() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: c.yaml
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '',
      getFile('/c.yaml'): '''
include:
  - a.yaml
  - b.yaml
''',
    });
  }

  Future<void> test_include_recursive_none_siblingIncludes() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - a.yaml
  - b.yaml
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '',
    });
  }

  test_include_recursive_self_direct() {
    // Test that the appropriate error is issued if `analysis_options.yaml`
    // tries to include itself.
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
include: analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''',
    }, initialFile: analysisOptionsFile);
  }

  Future<void> test_include_recursive_self_doubleQuoted() async {
    await assertDiagnosticsInCode('''
include: "./analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_include_recursive_self_fileName() async {
    await assertDiagnosticsInCode('''
include: analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_include_recursive_self_fileNameInList() async {
    await assertDiagnosticsInCode('''
include:
  - analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  test_include_recursive_self_inIncludedFile() {
    // Test that the appropriate error is issued if a file included by
    // `analysis_options.yaml` tries to include itself.
    // Note: comments ensure that the `include` directives in each file are at
    // different file offsets, so that we can validate that the reported source
    // ranges are correct.
    newFile('/other_options.yaml', r'''
include: other_options.yaml
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
# comment
include: other_options.yaml
//       ^^^^^^^^^^^^^^^^^^
// [diag.includedFileWarning] Warning in the included options file /other_options.yaml(9..26): The file includes itself recursively.
''',
    }, initialFile: analysisOptionsFile);
  }

  Future<void> test_include_recursive_self_listFirst() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
  - included1.yaml
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_include_recursive_self_listSecond() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_include_recursive_self_notQuoted() async {
    await assertDiagnosticsInCode('''
include: ./analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_include_recursive_self_singleQuoted() async {
    await assertDiagnosticsInCode('''
include: './analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_include_warning_fromIncludedFile() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(12..20): The option 'something' isn't supported by 'analyzer'.
''',
      getFile('/a.yaml'): '''
analyzer:
  something: bad
''',
    });
  }

  void test_linter_rules_deprecated() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');
  }

  Future<void> test_linter_rules_deprecated_inIncludedFile_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - deprecated_lint
''');

    assertAnalysisOptionsDiagnostics('''
include: included.yaml
''');
  }

  void test_linter_rules_deprecated_map() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    deprecated_lint: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');
  }

  void test_linter_rules_deprecated_map_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    deprecated_lInt: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lInt' is deprecated and shouldn't be enabled.
''');
  }

  void test_linter_rules_deprecated_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecAted_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecAted_lint' is deprecated and shouldn't be enabled.
''');
  }

  void test_linter_rules_deprecated_previousSdk() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdkVersionConstraint: dart3_3);
  }

  void test_linter_rules_deprecated_since_inCurrentSdk() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdkVersionConstraint: dart3);
  }

  void test_linter_rules_deprecated_since_notInCurrentSdk() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''', sdkVersionConstraint: Version(2, 17, 0));
  }

  void test_linter_rules_deprecated_since_unknownSdk() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''');
  }

  void test_linter_rules_deprecated_withReplacement() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_replacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_replacement' is deprecated and replaced by 'replacing_lint'.
''');
  }

  void test_linter_rules_deprecated_withReplacement_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_rePlacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_rePlacement' is deprecated and replaced by 'replacing_lint'.
''');
  }

  void test_linter_rules_duplicate() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - stable_lint
    - stable_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'stable_lint' is already enabled and doesn't need to be enabled again.
''');
  }

  void test_linter_rules_duplicate_inIncludedFile_ok() {
    newFile('/included.yaml', '''
linter:
  rules:
    - stable_lint
''');
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    - stable_lint
''');
  }

  void test_linter_rules_duplicate_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - stable_lint
    - staBle_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'staBle_lint' is already enabled and doesn't need to be enabled again.
''');
  }

  void test_linter_rules_empty() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
''');
  }

  void test_linter_rules_include_multipleCompatible() {
    newFile('/included1.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    newFile('/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    assertAnalysisOptionsDiagnostics('''
include:
  - included1.yaml
  - included2.yaml
''');
  }

  Future<void> test_linter_rules_incompatible() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    - rule_neg
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');
  }

  void test_linter_rules_incompatible_invalidMap_noDiagnostic() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_neg: true
    rule_pos:
''');
  }

  void test_linter_rules_incompatible_invalidMap_reports() {
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_neg:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
    });
  }

  Future<void> test_linter_rules_incompatible_map() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');
  }

  void test_linter_rules_incompatible_map_disabled() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  Future<void> test_linter_rules_incompatible_map_includedFile() async {
    await assertDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
    });
  }

  Future<void>
  test_linter_rules_incompatible_map_includedFile_disabledInMain() async {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    await assertDiagnosticsInCode('''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  Future<void>
  test_linter_rules_incompatible_map_includedFile_mixedCase() async {
    await assertDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rulE_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rulE_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'Rule_pos' is incompatible with 'rulE_neg'.
''',
    });
  }

  Future<void> test_linter_rules_incompatible_map_mixedCase() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'Rule_pos' is enabled here.
    rUle_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rUle_neg' is incompatible with ''Rule_pos''.
''');
  }

  Future<void> test_linter_rules_incompatible_mixedCase() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    - rule_Pos
//    ^^^^^^^^
// [context 1] The rule 'rule_Pos' is enabled here.
    - rule_neG
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neG' is incompatible with ''rule_Pos''.
''');
  }

  Future<void> test_linter_rules_incompatible_multipleIncludes() async {
    await assertDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
    });
  }

  Future<void>
  test_linter_rules_incompatible_multipleIncludes_disabledInMain() async {
    newFile('/included1.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    newFile('/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    await assertDiagnosticsInCode('''
include:
  - included1.yaml
  - included2.yaml

linter:
  rules:
    rule_neg: false
''');
  }

  Future<void>
  test_linter_rules_incompatible_multipleIncludes_emptyLinterRules() async {
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.

linter:
  rules:
''',
    });
  }

  Future<void>
  test_linter_rules_incompatible_multipleIncludes_emptyLinterRules_mixedCase() async {
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - ruLe_neg
//    ^^^^^^^^
// [context 2] The rule 'ruLe_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_poS
//    ^^^^^^^^
// [context 1] The rule 'rule_poS' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_poS' and 'ruLe_neg', which is included from 2 files.

linter:
  rules:
''',
    });
  }

  Future<void> test_linter_rules_incompatible_multipleIncludes_list() async {
    await assertDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
    });
  }

  void test_linter_rules_incompatible_packageInclude() {
    var testProjectPath = '/test';
    var testAnalysisOptionsFile = getFile(
      '$testProjectPath/analysis_options.yaml',
    );
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('$otherLib/analysis_options.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here in the file '/other/lib/analysis_options.yaml'.
''',
      testAnalysisOptionsFile: '''
include:
  - package:other/analysis_options.yaml

linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_neg' is incompatible with 'rule_pos'.
''',
    }, initialFile: testAnalysisOptionsFile);
  }

  void test_linter_rules_nullValue() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    -
''');
  }

  void test_linter_rules_removed() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart2_12);
  }

  Future<void> test_linter_rules_removed_inIncludedFile_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');
    assertAnalysisOptionsDiagnostics('''
include: included.yaml
''');
  }

  void test_linter_rules_removed_notYet_ok() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
''', sdkVersionConstraint: Version(2, 11, 0));
  }

  /// https://github.com/dart-lang/sdk/issues/59869
  test_linter_rules_removed_previousSdk() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart3_3);
  }

  test_linter_rules_removed_previousSdk_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - remOved_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'remOved_in_2_12_lint' was removed in Dart '2.12.0'
''', sdkVersionConstraint: dart3_3);
  }

  void test_linter_rules_replaced() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - replaced_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaced_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdkVersionConstraint: dart3);
  }

  void test_linter_rules_replaced_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - replaCed_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaCed_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdkVersionConstraint: dart3);
  }

  void test_linter_rules_stable() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - stable_lint
''');
  }

  void test_linter_rules_stable_map() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    stable_lint: true
''');
  }

  void test_linter_rules_stable_map_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    sTable_lint: true
''');
  }

  void test_linter_rules_stable_mixedCase() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - Stable_lint
''');
  }

  test_linter_rules_supported() {
    registerLintRule(TestRule());
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - fantastic_test_rule
    ''');
  }

  void test_linter_rules_undefined() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    - this_rule_does_not_exist
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');
  }

  void test_linter_rules_undefined_map() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    this_rule_does_not_exist: false
//  ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');
  }

  void test_linter_rules_value_error() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: error
''');
  }

  void test_linter_rules_value_false() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: false
''');
  }

  void test_linter_rules_value_ignore() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: ignore
''');
  }

  void test_linter_rules_value_info() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: info
''');
  }

  void test_linter_rules_value_true() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: true
''');
  }

  void test_linter_rules_value_unsupported() {
    assertAnalysisOptionsDiagnostics('''
linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');
  }

  void test_linter_rules_value_unsupported_withIncompatibleIncludedRule() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');
  }

  void
  test_linter_rules_value_unsupported_withIncompatibleIncludedRule_mixedCase() {
    newFile('/included.yaml', '''
linter:
  rules:
    rUle_neg: true
''');
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    Rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'Rule_pos'.
''');
  }

  void test_linter_rules_value_warning() {
    newEmptyIncludedOptionsFile();
    assertAnalysisOptionsDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: warning
''');
  }

  test_linter_unsupportedOption() {
    assertAnalysisOptionsDiagnostics('''
linter:
  unsupported: true
//^^^^^^^^^^^
// [diag.unsupportedOptionWithLegalValue] The option 'unsupported' isn't supported by 'linter'.
    ''');
  }

  test_parse_duplicateKey_initialFile() {
    assertAnalysisOptionsDiagnosticsInFiles({
      analysisOptionsFile: r'''
formatter:
  page_width: 80
  page_width: 90
//^^^^^^^^^^
// [diag.parseError] Duplicate mapping key.
''',
    }, initialFile: analysisOptionsFile);
  }

  test_plugins_dependencyOverrides_invalidKey() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  dependency_overrides:
    one:
      ppath: foo/bar
//    ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/dependency_overrides/one'.
''');
  }

  test_plugins_dependencyOverrides_valid() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  dependency_overrides:
    one:
      git: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_diagnostics_invalid() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    diagnostics:
      code: abc
//          ^^^
// [diag.unsupportedOptionWithLegalValues] The option 'abc' isn't supported by 'plugins/one/diagnostics'.
''');
  }

  test_plugins_diagnostics_notAMap() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    diagnostics: 7
//               ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins/one/diagnostics' section.
''');
  }

  test_plugins_diagnostics_supported_severity() {
    assertAnalysisOptionsDiagnostics('''
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
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    diagnostics:
      code1: true
      code2: false
''');
  }

  test_plugins_empty() {
    assertAnalysisOptionsDiagnostics('''
plugins:
''');
  }

  test_plugins_git_invalid_key() {
    assertAnalysisOptionsDiagnostics('''
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
    assertAnalysisOptionsDiagnostics('''
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
    assertAnalysisOptionsDiagnostics('''
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
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    git: https://github.com/dart-lang/linter.git
''');
  }

  test_plugins_innerOptions() {
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('/inner/analysis_options.yaml'): '''
plugins:
  one: ^1.0.0
// [diag.pluginsInInnerOptions][column 3][length 12] Plugins can only be specified in the root of a pub workspace or the root of a package that isn't in a workspace.
''',
    }, initialFile: getFile('/inner/analysis_options.yaml'));
  }

  test_plugins_innerOptions_included() {
    newFile('/analysis_options.yaml', '''
plugins:
  one: ^1.0.0
''');
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile('/inner/analysis_options.yaml'): '''
include: ../analysis_options.yaml
''',
    }, initialFile: getFile('/inner/analysis_options.yaml'));
  }

  test_plugins_innerOptions_included_notAtContextRoot() {
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
    assertAnalysisOptionsDiagnosticsInFiles({
      getFile(inner1Path): '''
include: ../inner2/analysis_options.yaml
''',
    }, initialFile: getFile(inner1Path));
  }

  test_plugins_notMap_scalar() {
    assertAnalysisOptionsDiagnostics('''
plugins: 7
//       ^
// [diag.invalidSectionFormat] Invalid format for the 'plugins' section.
''');
  }

  test_plugins_plugin_invalidKey() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    ppath: foo/bar
//  ^^^^^
// [diag.unsupportedOptionWithLegalValues] The option 'ppath' isn't supported by 'plugins/one'.
''');
  }

  test_plugins_plugin_validKey() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  one:
    path: foo/bar
''');
  }

  test_plugins_plugin_validScalar() {
    assertAnalysisOptionsDiagnostics('''
plugins:
  one: ^1.2.3
''');
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
