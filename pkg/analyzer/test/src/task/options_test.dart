// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';
import '../../resource_utils.dart';

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
  final AnalysisOptions analysisOptions = AnalysisOptionsImpl();

  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  void configureContext(String optionsSource) =>
      applyToAnalysisOptions(analysisOptions, parseOptions(optionsSource));

  YamlMap parseOptions(String source) =>
      optionsProvider.getOptionsFromString(source);

  test_configure_chromeos_checks() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    expect(true, analysisOptions.chromeOsManifestChecks);
  }

  test_configure_chromeos_checks_map() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    expect(true, analysisOptions.chromeOsManifestChecks);
  }

  test_configure_error_processors() {
    configureContext('''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_local_variable: error
''');

    List<ErrorProcessor> processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(2));

    var unused_local =
        AnalysisError(TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
      ['x']
    ]);
    var invalid_assignment = AnalysisError(
        TestSource(), 0, 1, StaticTypeWarningCode.INVALID_ASSIGNMENT, [
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

  test_configure_excludes() {
    configureContext('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    List<String> excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_configure_plugins_list() {
    configureContext('''
analyzer:
  plugins:
    - angular2
    - intl
''');

    List<String> names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2', 'intl']);
  }

  test_configure_plugins_map() {
    configureContext('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    List<String> names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_configure_plugins_string() {
    configureContext('''
analyzer:
  plugins:
    angular2
''');

    List<String> names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
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
      if (type == HintCodeWithUniqueName) {
        type = HintCode;
      }
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
        return errorType.toString() + '.' + name.substring(8, name.length - 2);
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
  final OptionsFileValidator validator = OptionsFileValidator(TestSource());
  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

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
    validate('''
analyzer:
  errors:
    unused_local_variable: ftw
    ''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_error_code_unsupported() {
    validate('''
analyzer:
  errors:
    not_supported: ignore
    ''', [AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE]);
  }

  test_analyzer_language_bad_format_list() {
    validate('''
analyzer:
  language:
    - enableSuperMixins: true
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

  test_analyzer_strong_mode_unsupported_key() {
    validate('''
analyzer:
  strong-mode:
    unsupported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_strong_mode_unsupported_value() {
    validate('''
analyzer:
  strong-mode:
    implicit-dynamic: foo
''', [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
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

  void validate(String source, List<ErrorCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    var errors = validator.validate(options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
  }
}

@reflectiveTest
class OptionsProviderTest {
  TestPathTranslator pathTranslator;
  ResourceProvider resourceProvider;

  AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void setUp() {
    var rawProvider = MemoryResourceProvider();
    resourceProvider = TestResourceProvider(rawProvider);
    pathTranslator = TestPathTranslator(rawProvider);
    provider = AnalysisOptionsProvider(SourceFactory([
      ResourceUriResolver(rawProvider),
    ]));
  }

  test_perform_include_merge() {
    pathTranslator.newFile('/other_options.yaml', '''
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
  plugins:
    lowlevelplugin:
      enabled: true
  errors:
    lowlevelerror: warning
linter:
  rules:
    - lowlevellint
''';
    pathTranslator.newFile(optionsFilePath, code);

    final lowlevellint = TestRule.withName('lowlevellint');
    final toplevellint = TestRule.withName('toplevellint');
    Registry.ruleRegistry.register(lowlevellint);
    Registry.ruleRegistry.register(toplevellint);
    final options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([toplevellint, lowlevellint]));
    expect(options.enabledPluginNames,
        unorderedEquals(['toplevelplugin', 'lowlevelplugin']));
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

  YamlMap _getOptions(String posixPath, {bool crawlUp = false}) {
    Resource resource = pathTranslator.getResource(posixPath);
    return provider.getOptions(resource, crawlUp: crawlUp);
  }

  AnalysisOptions _getOptionsObject(String posixPath, {bool crawlUp = false}) {
    final map = _getOptions(posixPath, crawlUp: crawlUp);
    final options = AnalysisOptionsImpl();
    applyToAnalysisOptions(options, map);
    return options;
  }
}

class TestRule extends LintRule {
  TestRule() : super(name: 'fantastic_test_rule');

  TestRule.withName(String name) : super(name: name);
}
