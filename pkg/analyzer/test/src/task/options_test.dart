// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextConfigurationTest);
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(OptionsFileValidatorTest);
    defineReflectiveTests(OptionsProviderTest);
  });
}

@reflectiveTest
class ContextConfigurationTest {
  final AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();

  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  void configureContext(String optionsSource) =>
      applyToAnalysisOptions(analysisOptions, parseOptions(optionsSource));

  YamlMap parseOptions(String source) =>
      optionsProvider.getOptionsFromString(source);

  test_analyzer_cannotIgnore() {
    configureContext('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, unorderedEquals(['ONE_ERROR_CODE', 'ANOTHER']));
  }

  test_analyzer_cannotIgnore_severity() {
    configureContext('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('INVALID_ANNOTATION'));
    expect(unignorableNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_severity_withProcessor() {
    configureContext('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('UNUSED_IMPORT'));
  }

  test_analyzer_chromeos_checks() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    expect(true, analysisOptions.chromeOsManifestChecks);
  }

  test_analyzer_chromeos_checks_map() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    expect(true, analysisOptions.chromeOsManifestChecks);
  }

  test_analyzer_errors_processors() {
    configureContext('''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_local_variable: error
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(2));

    var unused_local =
        AnalysisError(TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
      ['x']
    ]);
    var invalid_assignment = AnalysisError(
        TestSource(), 0, 1, CompileTimeErrorCode.INVALID_ASSIGNMENT, [
      ['x'],
      ['y']
    ]);

    // ignore
    var invalidAssignment =
        processors.firstWhere((p) => p.appliesTo(invalid_assignment));
    expect(invalidAssignment.severity, isNull);

    // error
    var unusedLocal = processors.firstWhere((p) => p.appliesTo(unused_local));
    expect(unusedLocal.severity, ErrorSeverity.ERROR);
  }

  test_analyzer_exclude() {
    configureContext('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_exclude_withNonStrings() {
    configureContext('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_plugins_list() {
    // TODO(srawlins): Test plugins as a list of non-scalar values
    // (`- angular2: yes`).
    configureContext('''
analyzer:
  plugins:
    - angular2
    - intl
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_plugins_map() {
    // TODO(srawlins): Test plugins as a map of scalar values (`angular2: yes`).
    configureContext('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_plugins_string() {
    configureContext('''
analyzer:
  plugins:
    angular2
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_codeStyle_format_false() {
    configureContext('''
code-style:
  format: false
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, false);
  }

  test_codeStyle_format_true() {
    configureContext('''
code-style:
  format: true
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, true);
  }
}

@reflectiveTest
class ErrorCodeValuesTest {
  test_errorCodes() {
    // Now that we're using unique names for comparison, the only reason to
    // split the codes by class is to find all of the classes that need to be
    // checked against `errorCodeValues`.
    var errorTypeMap = <Type, List<ErrorCode>>{};
    for (ErrorCode code in errorCodeValues) {
      Type type = code.runtimeType;
      errorTypeMap.putIfAbsent(type, () => <ErrorCode>[]).add(code);
    }

    StringBuffer missingCodes = StringBuffer();
    errorTypeMap.forEach((Type errorType, List<ErrorCode> codes) {
      var listedNames = codes.map((ErrorCode code) => code.uniqueName).toSet();

      var declaredNames = reflectClass(errorType)
          .declarations
          .values
          .map((DeclarationMirror declarationMirror) {
        String name = declarationMirror.simpleName.toString();
        //TODO(danrubel): find a better way to extract the text from the symbol
        assert(name.startsWith('Symbol("') && name.endsWith('")'));
        return '$errorType.${name.substring(8, name.length - 2)}';
      }).where((String name) {
        return name == name.toUpperCase();
      }).toList();

      // Assert that all declared names are in errorCodeValues

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

class ErrorProcessorMatcher extends Matcher {
  final ErrorProcessor required;

  ErrorProcessorMatcher(this.required);

  @override
  Description describe(Description desc) => desc
    ..add("an ErrorProcessor setting ${required.code} to ${required.severity}");

  @override
  bool matches(dynamic o, Map<dynamic, dynamic> options) {
    return o is ErrorProcessor &&
        o.code.toUpperCase() == required.code.toUpperCase() &&
        o.severity == required.severity;
  }
}

@reflectiveTest
class OptionsFileValidatorTest {
  final OptionsFileValidator validator =
      OptionsFileValidator(TestSource(), sdkVersionConstraint: null);
  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  test_analyzer_cannotIgnore_badValue() {
    validate('''
analyzer:
  cannot-ignore:
    - not_an_error_code
''', [AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE]);
  }

  test_analyzer_cannotIgnore_goodValue() {
    validate('''
analyzer:
  cannot-ignore:
    - invalid_annotation
''', []);
  }

  test_analyzer_cannotIgnore_lintRule() {
    Registry.ruleRegistry.register(TestRule());
    validate('''
analyzer:
  cannot-ignore:
    - fantastic_test_rule
''', []);
  }

  test_analyzer_cannotIgnore_notAList() {
    validate('''
analyzer:
  cannot-ignore:
    one_error_code: true
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_cannotIgnore_severity() {
    validate('''
analyzer:
  cannot-ignore:
    - error
''', []);
  }

  test_analyzer_cannotIgnore_valueNotAString() {
    validate('''
analyzer:
  cannot-ignore:
    one_error_code:
      foo: bar
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_enableExperiment_badValue() {
    validate('''
analyzer:
  enable-experiment:
    - not-an-experiment
    ''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES]);
  }

  test_analyzer_enableExperiment_notAList() {
    validate('''
analyzer:
  enable-experiment:
    experiment: true
    ''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_error_code_supported() {
    validate('''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    missing_return: error
    dead_code: info
''', []);
  }

  test_analyzer_error_code_supported_bad_value() {
    var errors = validate('''
analyzer:
  errors:
    unused_local_variable: ftw
    ''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
    expect(errors.single.problemMessage.messageText(includeUrl: false),
        contains("The option 'ftw'"));
  }

  test_analyzer_error_code_supported_bad_value_null() {
    var errors = validate('''
analyzer:
  errors:
    unused_local_variable: null
    ''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
    expect(errors.single.problemMessage.messageText(includeUrl: false),
        contains("The option 'null'"));
  }

  test_analyzer_error_code_unsupported() {
    var errors = validate('''
analyzer:
  errors:
    not_supported: ignore
    ''', [AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE]);
    expect(errors.single.problemMessage.messageText(includeUrl: false),
        contains("'not_supported' isn't a recognized error code"));
  }

  test_analyzer_error_code_unsupported_null() {
    var errors = validate('''
analyzer:
  errors:
    null: ignore
    ''', [AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE]);
    expect(errors.single.problemMessage.messageText(includeUrl: false),
        contains("'null' isn't a recognized error code"));
  }

  test_analyzer_errors_notAMap() {
    validate('''
analyzer:
  errors:
    - invalid_annotation
    - unused_import
    ''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_errors_valueNotAScalar() {
    validate('''
analyzer:
  errors:
    invalid_annotation: ignore
    unused_import: [1, 2, 3]
    ''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_language_bad_format_list() {
    validate('''
analyzer:
  language:
    - notAnOption: true
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_language_bad_format_scalar() {
    validate('''
analyzer:
  language: true
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_language_supports_empty() {
    validate('''
analyzer:
  language:
''', []);
  }

  test_analyzer_language_unsupported_key() {
    validate('''
analyzer:
  language:
    unsupported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_lint_codes_recognized() {
    Registry.ruleRegistry.register(TestRule());
    validate('''
analyzer:
  errors:
    fantastic_test_rule: ignore
''', []);
  }

  test_analyzer_strong_mode_deprecated() {
    validate('''
analyzer:
  strong-mode: true
''', [AnalysisOptionsHintCode.STRONG_MODE_SETTING_DEPRECATED]);
  }

  test_analyzer_strong_mode_deprecated_key() {
    validate('''
analyzer:
  strong-mode:
    declaration-casts: false
''', [AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED]);
  }

  test_analyzer_strong_mode_deprecated_key_implicit_casts() {
    validate('''
analyzer:
  strong-mode:
    implicit-casts: false
''', [AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT]);
  }

  test_analyzer_strong_mode_deprecated_key_implicit_dynamic() {
    validate('''
analyzer:
  strong-mode:
    implicit-dynamic: false
''', [AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT]);
  }

  test_analyzer_strong_mode_error_code_supported() {
    validate('''
analyzer:
  errors:
    invalid_cast_method: ignore
''', []);
  }

  test_analyzer_strong_mode_false_removed() {
    validate('''
analyzer:
  strong-mode: false
''', [AnalysisOptionsWarningCode.SPEC_MODE_REMOVED]);
  }

  test_analyzer_strong_mode_notAMap() {
    validate('''
analyzer:
  strong-mode:
    - implicit_casts
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_analyzer_strong_mode_unsupported_key() {
    validate('''
analyzer:
  strong-mode:
    unsupported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_supported_exclude() {
    validate('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
''', []);
  }

  test_analyzer_supported_strong_mode_supported_bad_value() {
    validate('''
analyzer:
  strong-mode: w00t
''', [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
  }

  test_analyzer_unsupported_option() {
    validate('''
analyzer:
  not_supported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_chromeos_manifest_checks() {
    validate('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''', []);
  }

  test_chromeos_manifest_checks_invalid() {
    validate('''
analyzer:
  optional-checks:
    chromeos-manifest
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE]);
  }

  test_chromeos_manifest_checks_notAMap() {
    validate('''
analyzer:
  optional-checks:
    - chrome-os-manifest-checks
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_codeStyle_format_false() {
    validate('''
code-style:
  format: false
''', []);
  }

  test_codeStyle_format_invalid() {
    validate('''
code-style:
  format: 80
''', [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
  }

  test_codeStyle_format_true() {
    validate('''
code-style:
  format: true
''', []);
  }

  test_codeStyle_unsupported_list() {
    validate('''
code-style:
  - format
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_codeStyle_unsupported_scalar() {
    validate('''
code-style: format
''', [AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT]);
  }

  test_codeStyle_unsupportedOption() {
    validate('''
code-style:
  not_supported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES]);
  }

  test_linter_supported_rules() {
    Registry.ruleRegistry.register(TestRule());
    validate('''
linter:
  rules:
    - fantastic_test_rule
    ''', []);
  }

  test_linter_unsupported_option() {
    validate('''
linter:
  unsupported: true
    ''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE]);
  }

  List<AnalysisError> validate(String source, List<ErrorCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    var errors = validator.validate(options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
    return errors;
  }
}

@reflectiveTest
class OptionsProviderTest with ResourceProviderMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void assertErrorsInList(
    List<AnalysisError> errors,
    List<ExpectedError> expectedErrors,
  ) {
    GatheringErrorListener errorListener = GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrors(expectedErrors);
  }

  void assertErrorsInOptionsFile(
      String code, List<ExpectedError> expectedErrors) async {
    newFile(optionsFilePath, code);
    var errors = analyzeAnalysisOptions(
      sourceFactory.forUri2(toUri(optionsFilePath))!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
    );

    assertErrorsInList(errors, expectedErrors);
  }

  ExpectedError error(
    ErrorCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) =>
      ExpectedError(
        code,
        offset,
        length,
        correctionContains: correctionContains,
        message: text,
        messageContains: messageContains,
        expectedContextMessages: contextMessages,
      );

  void setUp() {
    resourceProvider = MemoryResourceProvider();
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  test_chooseFirstPlugin() {
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
    String code = r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_fff
    - plugin_iii
    - plugin_ccc
''';
    newFile(optionsFilePath, code);

    final options = _getOptionsObject('/');
    expect(options.enabledPluginNames, unorderedEquals(['plugin_ddd']));
  }

  test_mergeIncludedOptions() {
    // TODO(https://github.com/dart-lang/sdk/issues/50978): add tests for
    // INCLUDED_FILE_WARNING.
    // TODO(https://github.com/dart-lang/sdk/issues/50979): add tests for cyclic
    // includes.
    // TODO(srawlins): add tests for multiple includes.
    // TODO(https://github.com/dart-lang/sdk/issues/50980): add tests with
    // duplicate plugin names.

    newFile('/other_options.yaml', '''
analyzer:
  exclude:
    - toplevelexclude.dart
  plugins:
    toplevelplugin:
      enabled: true
  errors:
    toplevelerror: warning
linter:
  rules:
    - toplevellint
''');
    String code = r'''
include: other_options.yaml
analyzer:
  exclude:
    - lowlevelexclude.dart
  errors:
    lowlevelerror: warning
linter:
  rules:
    - lowlevellint
''';
    newFile(optionsFilePath, code);

    final lowlevellint = TestRule.withName('lowlevellint');
    final toplevellint = TestRule.withName('toplevellint');
    Registry.ruleRegistry.register(lowlevellint);
    Registry.ruleRegistry.register(toplevellint);
    final options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([toplevellint, lowlevellint]));
    expect(options.enabledPluginNames, unorderedEquals(['toplevelplugin']));
    expect(options.excludePatterns,
        unorderedEquals(['toplevelexclude.dart', 'lowlevelexclude.dart']));
    expect(
        options.errorProcessors,
        unorderedMatches([
          ErrorProcessorMatcher(
              ErrorProcessor('toplevelerror', ErrorSeverity.WARNING)),
          ErrorProcessorMatcher(
              ErrorProcessor('lowlevelerror', ErrorSeverity.WARNING))
        ]));
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_listForm() {
    newFile(convertPath('/other_options.yaml'), '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 55, 10),
    ]);
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_mapForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(r'''
include: other_options.yaml
analyzer:
  plugins:
    plugin_two:
      foo: bar
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 53, 10),
    ]);
  }

  test_multiplePlugins_firstIsDirectlyIncluded_secondIsDirect_scalarForm() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    - plugin_one
''');
    assertErrorsInOptionsFile(r'''
include: other_options.yaml
analyzer:
  plugins: plugin_two
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 49, 10),
    ]);
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
    assertErrorsInOptionsFile(r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_two
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 55, 10),
    ]);
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
    assertErrorsInOptionsFile(r'''
include: other_options.yaml
''', [
      error(AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING, 9, 18),
    ]);
  }

  test_multiplePlugins_multipleDirect_listForm() {
    assertErrorsInOptionsFile(r'''
analyzer:
  plugins:
    - plugin_one
    - plugin_two
    - plugin_three
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 44, 10),
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 61, 12),
    ]);
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
    assertErrorsInOptionsFile(r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_two: sure
''', [
      error(AnalysisOptionsWarningCode.MULTIPLE_PLUGINS, 45, 10),
    ]);
  }

  test_multiplePlugins_multipleDirect_mapForm_sameName() {
    assertErrorsInOptionsFile(r'''
analyzer:
  plugins:
    plugin_one: yes
    plugin_one: sure
''', [
      error(AnalysisOptionsErrorCode.PARSE_ERROR, 45, 10),
    ]);
  }

  List<AnalysisError> validate(String code, List<ErrorCode> expected) {
    newFile(optionsFilePath, code);
    var errors = analyzeAnalysisOptions(
      sourceFactory.forUri('file://$optionsFilePath')!,
      code,
      sourceFactory,
      '/',
      null /*sdkVersionConstraint*/,
    );
    expect(
      errors.map((AnalysisError e) => e.errorCode),
      unorderedEquals(expected),
    );
    return errors;
  }

  YamlMap _getOptions(String posixPath) {
    var resource = getFolder(posixPath);
    return provider.getOptions(resource);
  }

  AnalysisOptions _getOptionsObject(String posixPath) {
    final map = _getOptions(posixPath);
    final options = AnalysisOptionsImpl();
    applyToAnalysisOptions(options, map);
    return options;
  }
}

class TestRule extends LintRule {
  TestRule()
      : super(
          name: 'fantastic_test_rule',
          description: '',
          details: '',
          group: Group.style,
        );

  TestRule.withName(String name)
      : super(
          name: name,
          description: '',
          details: '',
          group: Group.style,
        );
}
