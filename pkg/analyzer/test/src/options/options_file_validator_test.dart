// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(OptionsFileValidatorTest);
    defineReflectiveTests(OptionsProviderTest);
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
          .map((DiagnosticCode code) => code.uniqueName)
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
    with LintRegistrationMixin, ResourceProviderMixin {
  late final OptionsFileValidator validator = OptionsFileValidator(
    TestSource(),
    isPrimarySource: true,
    contextRoot: '/',
    optionsProvider: optionsProvider,
    resourceProvider: resourceProvider,
    sourceFactory: SourceFactory([ResourceUriResolver(resourceProvider)]),
  );
  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  void tearDown() {
    unregisterLintRules();
  }

  test_analyzer_cannotIgnore_badValue() {
    validate(
      '''
analyzer:
  cannot-ignore:
    - not_an_error_code
''',
      [AnalysisOptionsWarningCode.unrecognizedErrorCode],
    );
  }

  test_analyzer_cannotIgnore_goodValue() {
    validate('''
analyzer:
  cannot-ignore:
    - invalid_annotation
''', []);
  }

  test_analyzer_cannotIgnore_lintRule() {
    registerLintRule(TestRule());
    validate('''
analyzer:
  cannot-ignore:
    - fantastic_test_rule
''', []);
  }

  test_analyzer_cannotIgnore_notAList() {
    validate(
      '''
analyzer:
  cannot-ignore:
    one_error_code: true
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_cannotIgnore_severity() {
    validate('''
analyzer:
  cannot-ignore:
    - error
''', []);
  }

  test_analyzer_cannotIgnore_valueNotAString() {
    validate(
      '''
analyzer:
  cannot-ignore:
    one_error_code:
      foo: bar
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_empty() {
    registerLintRule(TestRule());
    validate('''
analyzer:
''', []);
  }

  test_analyzer_enableExperiment_badValue() {
    validate(
      '''
analyzer:
  enable-experiment:
    - not-an-experiment
    ''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithoutValues],
    );
  }

  test_analyzer_enableExperiment_mapValue() {
    validate(
      '''
analyzer:
  enable-experiment:
    experiment: true
    ''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_enableExperiment_scalarValue() {
    validate(
      '''
analyzer:
  enable-experiment: 7
    ''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_error_code_supported() {
    validate('''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    assignment_of_do_not_store: error
    dead_code: info
''', []);
  }

  test_analyzer_error_code_supported_bad_value() {
    var diagnostics = validate(
      '''
analyzer:
  errors:
    unused_local_variable: ftw
    ''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues],
    );
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("The option 'ftw'"),
    );
  }

  test_analyzer_error_code_supported_bad_value_null() {
    var diagnostics = validate(
      '''
analyzer:
  errors:
    unused_local_variable: null
    ''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues],
    );
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("The option 'null'"),
    );
  }

  test_analyzer_error_code_unsupported() {
    var diagnostics = validate(
      '''
analyzer:
  errors:
    not_supported: ignore
    ''',
      [AnalysisOptionsWarningCode.unrecognizedErrorCode],
    );
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("'not_supported' isn't a recognized error code"),
    );
  }

  test_analyzer_error_code_unsupported_null() {
    var diagnostics = validate(
      '''
analyzer:
  errors:
    null: ignore
    ''',
      [AnalysisOptionsWarningCode.unrecognizedErrorCode],
    );
    expect(
      diagnostics.single.problemMessage.messageText(includeUrl: false),
      contains("'null' isn't a recognized error code"),
    );
  }

  test_analyzer_errors_notAMap() {
    validate(
      '''
analyzer:
  errors:
    - invalid_annotation
    - unused_import
    ''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_errors_valueNotAScalar() {
    validate(
      '''
analyzer:
  errors:
    invalid_annotation: ignore
    unused_import: [1, 2, 3]
    ''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_language_bad_format_list() {
    validate(
      '''
analyzer:
  language:
    - notAnOption: true
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_language_bad_format_scalar() {
    validate(
      '''
analyzer:
  language: true
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_language_supports_empty() {
    validate('''
analyzer:
  language:
''', []);
  }

  test_analyzer_language_unsupported_key() {
    validate(
      '''
analyzer:
  language:
    unsupported: true
''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues],
    );
  }

  test_analyzer_lint_codes_recognized() {
    registerLintRule(TestRule());
    validate('''
analyzer:
  errors:
    fantastic_test_rule: ignore
''', []);
  }

  test_analyzer_scalarValue() {
    validate(
      '''
analyzer: 7
    ''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_analyzer_supported_exclude() {
    validate('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
''', []);
  }

  test_analyzer_unsupported_option() {
    validate(
      '''
analyzer:
  not_supported: true
''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues],
    );
  }

  test_chromeos_manifest_checks() {
    validate('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''', []);
  }

  test_chromeos_manifest_checks_invalid() {
    validate(
      '''
analyzer:
  optional-checks:
    chromeos-manifest
''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValues],
    );
  }

  test_chromeos_manifest_checks_notAMap() {
    validate(
      '''
analyzer:
  optional-checks:
    - chrome-os-manifest-checks
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_codeStyle_format_false() {
    validate('''
code-style:
  format: false
''', []);
  }

  test_codeStyle_format_invalid() {
    validate(
      '''
code-style:
  format: 80
''',
      [AnalysisOptionsWarningCode.unsupportedValue],
    );
  }

  test_codeStyle_format_true() {
    validate('''
code-style:
  format: true
''', []);
  }

  test_codeStyle_nonMap() {
    validate(
      '''
code-style: 7
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_codeStyle_unsupported_list() {
    validate(
      '''
code-style:
  - format
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_codeStyle_unsupported_scalar() {
    validate(
      '''
code-style: format
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_codeStyle_unsupportedOption() {
    validate(
      '''
code-style:
  not_supported: true
''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithoutValues],
    );
  }

  test_formatter_invalid_key() {
    validate(
      '''
formatter:
  wrong: 123
''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithoutValues],
    );
  }

  test_formatter_invalid_keys() {
    validate(
      '''
formatter:
  wrong: 123
  wrong2: 123
''',
      [
        AnalysisOptionsWarningCode.unsupportedOptionWithoutValues,
        AnalysisOptionsWarningCode.unsupportedOptionWithoutValues,
      ],
    );
  }

  test_formatter_pageWidth_invalid_decimal() {
    validate(
      '''
formatter:
  page_width: 123.45
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_pageWidth_invalid_negativeInteger() {
    validate(
      '''
formatter:
  page_width: -123
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_pageWidth_invalid_string() {
    validate(
      '''
formatter:
  page_width: "123"
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_pageWidth_invalid_zero() {
    validate(
      '''
formatter:
  page_width: 0
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_pageWidth_valid_integer() {
    validate('''
formatter:
  page_width: 123
''', []);
  }

  test_formatter_trailingCommas_invalid_map() {
    validate(
      '''
formatter:
  trailing_commas:
    a: b
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_trailingCommas_invalid_numeric() {
    validate(
      '''
formatter:
  trailing_commas: 1
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_trailingCommas_invalid_string() {
    validate(
      '''
formatter:
  trailing_commas: foo
''',
      [AnalysisOptionsWarningCode.invalidOption],
    );
  }

  test_formatter_trailingCommas_valid() {
    validate('''
formatter:
  trailing_commas: automate
''', []);
  }

  test_formatter_valid_empty() {
    validate('''
formatter:
''', []);
  }

  test_linter_supported_rules() {
    registerLintRule(TestRule());
    validate('''
linter:
  rules:
    - fantastic_test_rule
    ''', []);
  }

  test_linter_unsupported_option() {
    validate(
      '''
linter:
  unsupported: true
    ''',
      [AnalysisOptionsWarningCode.unsupportedOptionWithLegalValue],
    );
  }

  test_plugins_each_invalid_mapKey() {
    validate('''
plugins:
  one:
    ppath: foo/bar
''', []);
  }

  test_plugins_each_valid_mapKey() {
    validate('''
plugins:
  one:
    path: foo/bar
''', []);
  }

  test_plugins_each_valid_scalar() {
    validate('''
plugins:
  one: ^1.2.3
''', []);
  }

  test_plugins_invalid_scalar() {
    validate(
      '''
plugins: 7
''',
      [AnalysisOptionsWarningCode.invalidSectionFormat],
    );
  }

  test_plugins_valid_empty() {
    validate('''
plugins:
''', []);
  }

  List<Diagnostic> validate(String source, List<DiagnosticCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    var diagnostics = validator.validate(options);
    expect(
      diagnostics.map((Diagnostic e) => e.diagnosticCode),
      unorderedEquals(expected),
    );
    return diagnostics;
  }
}

@reflectiveTest
class OptionsProviderTest with ResourceProviderMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void assertErrorsInList(
    List<Diagnostic> diagnostics,
    List<ExpectedError> expectedErrors,
  ) {
    GatheringDiagnosticListener diagnosticListener =
        GatheringDiagnosticListener();
    diagnosticListener.addAll(diagnostics);
    diagnosticListener.assertErrors(expectedErrors);
  }

  void assertErrorsInOptionsFile(
    String code,
    List<ExpectedError> expectedErrors,
  ) {
    newFile(optionsFilePath, code);
    var diagnostics = analyzeAnalysisOptions(
      sourceFactory.forUri2(toUri(optionsFilePath))!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
      resourceProvider,
    );

    assertErrorsInList(diagnostics, expectedErrors);
  }

  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) => ExpectedError(
    code,
    offset,
    length,
    correctionContains: correctionContains,
    message: text,
    messageContains: messageContains,
    expectedContextMessages: contextMessages,
  );

  void setUp() {
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_listForm() {
    newFile(convertPath('/other_options.yaml'), '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(
      r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
''',
      [error(AnalysisOptionsWarningCode.multiplePlugins, 55, 10)],
    );
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_mapForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(
      r'''
include: other_options.yaml
analyzer:
  plugins:
    plugin_two:
      foo: bar
''',
      [error(AnalysisOptionsWarningCode.multiplePlugins, 53, 10)],
    );
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_scalarForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(
      r'''
include: other_options.yaml
analyzer:
  plugins: plugin_two
''',
      [error(AnalysisOptionsWarningCode.multiplePlugins, 49, 10)],
    );
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
    assertErrorsInOptionsFile(
      r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
''',
      [error(AnalysisOptionsWarningCode.multiplePlugins, 55, 10)],
    );
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
    assertErrorsInOptionsFile(
      r'''
include: other_options.yaml
''',
      [error(AnalysisOptionsWarningCode.includedFileWarning, 9, 18)],
    );
  }

  test_multiplePlugins_multipleDirect_listForm() {
    assertErrorsInOptionsFile(
      r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_two
    - plugin_three
''',
      [
        error(AnalysisOptionsWarningCode.multiplePlugins, 44, 10),
        error(AnalysisOptionsWarningCode.multiplePlugins, 61, 12),
      ],
    );
  }

  test_multiplePlugins_multipleDirect_listForm_nonString() {
    assertErrorsInOptionsFile(r'''
analyzer:
  plugins:
    - 7
    - plugin_one
''', []);
  }

  test_multiplePlugins_multipleDirect_listForm_sameName() {
    assertErrorsInOptionsFile(r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_one
''', []);
  }

  test_multiplePlugins_multipleDirect_mapForm() {
    assertErrorsInOptionsFile(
      r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_two: sure
''',
      [error(AnalysisOptionsWarningCode.multiplePlugins, 45, 10)],
    );
  }

  test_multiplePlugins_multipleDirect_mapForm_sameName() {
    assertErrorsInOptionsFile(
      r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_one: sure
''',
      [error(AnalysisOptionsErrorCode.parseError, 45, 10)],
    );
  }

  test_pluginsInInnerOptions() {
    var code = '''
plugins:
  one: ^1.0.0
''';
    var filePath = '/inner/analysis_options.yaml';
    newFile(filePath, code);
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    var diagnostics = analyzeAnalysisOptions(
      sourceFactory.forUri2(toUri(filePath))!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
      resourceProvider,
    );

    assertErrorsInList(diagnostics, [
      error(AnalysisOptionsWarningCode.pluginsInInnerOptions, 11, 12),
    ]);
  }

  test_pluginsInInnerOptions_included() {
    newFile(optionsFilePath, '''
plugins:
  one: ^1.0.0
''');
    var code = '''
include: ../analysis_options.yaml
''';
    var filePath = '/inner/analysis_options.yaml';
    newFile(filePath, code);
    newFile('/pubspec.yaml', '''
name: test
version: 0.0.1
''');
    var diagnostics = analyzeAnalysisOptions(
      sourceFactory.forUri2(toUri(filePath))!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
      resourceProvider,
    );

    assertErrorsInList(diagnostics, []);
  }

  List<Diagnostic> validate(String code, List<DiagnosticCode> expected) {
    newFile(optionsFilePath, code);
    var diagnostics = analyzeAnalysisOptions(
      sourceFactory.forUri('file://$optionsFilePath')!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
      resourceProvider,
    );
    expect(
      diagnostics.map((Diagnostic e) => e.diagnosticCode),
      unorderedEquals(expected),
    );
    return diagnostics;
  }
}

class TestRule extends LintRule {
  static const LintCode code = LintCode(
    'fantastic_test_rule',
    'Fantastic test rule.',
    correctionMessage: 'Try fantastic test rule.',
  );

  TestRule() : super(name: 'fantastic_test_rule', description: '');

  TestRule.withName(String name) : super(name: name, description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}
