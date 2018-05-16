// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/api/general.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';
import '../../resource_utils.dart';
import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextConfigurationTest);
    defineReflectiveTests(ErrorCodeValuesTest);
    defineReflectiveTests(GenerateNewOptionsErrorsTaskTest);
    defineReflectiveTests(GenerateOldOptionsErrorsTaskTest);
    defineReflectiveTests(OptionsFileValidatorTest);
    defineReflectiveTests(OptionsProviderTest);
  });
}

isInstanceOf isGenerateOptionsErrorsTask =
    new isInstanceOf<GenerateOptionsErrorsTask>();

@reflectiveTest
class ContextConfigurationTest extends AbstractContextTest {
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  AnalysisOptions get analysisOptions => context.analysisOptions;

  void configureContext(String optionsSource) =>
      applyToAnalysisOptions(analysisOptions, parseOptions(optionsSource));

  YamlMap parseOptions(String source) =>
      optionsProvider.getOptionsFromString(source);

  test_configure_bad_options_contents() {
    (analysisOptions as AnalysisOptionsImpl)
      ..previewDart2 = false
      ..strongMode = false;
    configureContext('''
analyzer:
  strong-mode:true # misformatted
''');
    expect(analysisOptions.strongMode, false);
  }

  test_configure_enableSuperMixins() {
    configureContext('''
analyzer:
  language:
    enableSuperMixins: true
''');
    expect(analysisOptions.enableSuperMixins, true);
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

    var unused_local = new AnalysisError(
        new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
      ['x']
    ]);
    var invalid_assignment =
        new AnalysisError(new TestSource(), 0, 1, HintCode.INVALID_ASSIGNMENT, [
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

  test_configure_strong_mode() {
    configureContext('''
analyzer:
  strong-mode: true
''');
    expect(analysisOptions.strongMode, true);
  }

  test_configure_strong_mode_bad_value() {
    (analysisOptions as AnalysisOptionsImpl)
      ..previewDart2 = false
      ..strongMode = false;
    configureContext('''
analyzer:
  strong-mode: foo
''');
    expect(analysisOptions.strongMode, false);
  }
}

@reflectiveTest
class ErrorCodeValuesTest {
  test_errorCodes() {
    var errorTypeMap = <Type, List<ErrorCode>>{};
    for (ErrorCode code in errorCodeValues) {
      errorTypeMap.putIfAbsent(code.runtimeType, () => <ErrorCode>[]).add(code);
    }

    int missingErrorCodeCount = 0;
    errorTypeMap.forEach((Type errorType, List<ErrorCode> codes) {
      var listedNames = codes.map((ErrorCode code) => code.name).toSet();

      var declaredNames = reflectClass(errorType)
          .declarations
          .values
          .map((DeclarationMirror declarationMirror) {
        String name = declarationMirror.simpleName.toString();
        //TODO(danrubel): find a better way to extract the text from the symbol
        assert(name.startsWith('Symbol("') && name.endsWith('")'));
        return name.substring(8, name.length - 2);
      }).where((String name) {
        return name == name.toUpperCase();
      }).toList();

      // Remove declared names that are not supposed to be in errorCodeValues

      if (errorType == AnalysisOptionsErrorCode) {
        declaredNames
            .remove(AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR.name);
      } else if (errorType == AnalysisOptionsWarningCode) {
        declaredNames
            .remove(AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND.name);
        declaredNames
            .remove(AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING.name);
      } else if (errorType == StaticWarningCode) {
        declaredNames.remove(
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS.name +
                '_PLUS');
      } else if (errorType == StrongModeCode) {
        void removeCode(StrongModeCode code) {
          String name = code.name;
          declaredNames.remove(name);
          if (name.startsWith('STRONG_MODE_')) {
            declaredNames.remove(name.substring(12));
          }
        }

        removeCode(StrongModeCode.DOWN_CAST_COMPOSITE);
        removeCode(StrongModeCode.DOWN_CAST_IMPLICIT);
        removeCode(StrongModeCode.DOWN_CAST_IMPLICIT_ASSIGN);
        removeCode(StrongModeCode.DYNAMIC_CAST);
        removeCode(StrongModeCode.ASSIGNMENT_CAST);
        removeCode(StrongModeCode.INVALID_PARAMETER_DECLARATION);
        removeCode(StrongModeCode.COULD_NOT_INFER);
        removeCode(StrongModeCode.INFERRED_TYPE);
        removeCode(StrongModeCode.INFERRED_TYPE_LITERAL);
        removeCode(StrongModeCode.INFERRED_TYPE_ALLOCATION);
        removeCode(StrongModeCode.INFERRED_TYPE_CLOSURE);
        removeCode(StrongModeCode.INVALID_CAST_LITERAL);
        removeCode(StrongModeCode.INVALID_CAST_LITERAL_LIST);
        removeCode(StrongModeCode.INVALID_CAST_LITERAL_MAP);
        removeCode(StrongModeCode.INVALID_CAST_FUNCTION_EXPR);
        removeCode(StrongModeCode.INVALID_CAST_NEW_EXPR);
        removeCode(StrongModeCode.INVALID_CAST_METHOD);
        removeCode(StrongModeCode.INVALID_CAST_FUNCTION);
        removeCode(StrongModeCode.INVALID_SUPER_INVOCATION);
        removeCode(StrongModeCode.NON_GROUND_TYPE_CHECK_INFO);
        removeCode(StrongModeCode.DYNAMIC_INVOKE);
        removeCode(StrongModeCode.INVALID_METHOD_OVERRIDE);
        removeCode(StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_BASE);
        removeCode(StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_MIXIN);
        removeCode(StrongModeCode.INVALID_FIELD_OVERRIDE);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_PARAMETER);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_RETURN);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_VARIABLE);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_FIELD);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_TYPE);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_LIST_LITERAL);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_MAP_LITERAL);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_FUNCTION);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_METHOD);
        removeCode(StrongModeCode.IMPLICIT_DYNAMIC_INVOKE);
        removeCode(StrongModeCode.NO_DEFAULT_BOUNDS);
        removeCode(StrongModeCode.NOT_INSTANTIATED_BOUND);
        removeCode(StrongModeCode.TOP_LEVEL_CYCLE);
        removeCode(StrongModeCode.TOP_LEVEL_FUNCTION_LITERAL_BLOCK);
        removeCode(StrongModeCode.TOP_LEVEL_FUNCTION_LITERAL_PARAMETER);
        removeCode(StrongModeCode.TOP_LEVEL_IDENTIFIER_NO_TYPE);
        removeCode(StrongModeCode.TOP_LEVEL_INSTANCE_GETTER);
        removeCode(StrongModeCode.TOP_LEVEL_INSTANCE_METHOD);
        removeCode(StrongModeCode.TOP_LEVEL_UNSUPPORTED);
      } else if (errorType == TodoCode) {
        declaredNames.remove('TODO_REGEX');
      }

      // Assert that all remaining declared names are in errorCodeValues

      for (String declaredName in declaredNames) {
        if (!listedNames.contains(declaredName)) {
          ++missingErrorCodeCount;
          print('   errorCodeValues is missing $errorType $declaredName');
        }
      }
    });
    expect(missingErrorCodeCount, 0, reason: 'missing error code names');

    // Apparently, duplicate error codes are allowed
    //    expect(
    //      ErrorFilterOptionValidator.errorCodes.length,
    //      errorCodeValues.length,
    //      reason: 'some errorCodeValues have the same name',
    //    );
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
class GenerateNewOptionsErrorsTaskTest extends AbstractContextTest {
  Source source;

  String get optionsFilePath => '/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}';

  LineInfo lineInfo(String source) =>
      GenerateOptionsErrorsTask.computeLineInfo(source);

  @override
  setUp() {
    super.setUp();
    source = newSource(optionsFilePath);
  }

  test_buildInputs() {
    Map<String, TaskInput> inputs =
        GenerateOptionsErrorsTask.buildInputs(source);
    expect(inputs, isNotNull);
    expect(inputs.keys,
        unorderedEquals([GenerateOptionsErrorsTask.CONTENT_INPUT_NAME]));
  }

  test_compute_lineInfo() {
    expect(lineInfo('foo\nbar').getLocation(4).lineNumber, 2);
    expect(lineInfo('foo\nbar').getLocation(4).columnNumber, 1);
    expect(lineInfo('foo\r\nbar').getLocation(5).lineNumber, 2);
    expect(lineInfo('foo\r\nbar').getLocation(5).columnNumber, 1);
    expect(lineInfo('foo\rbar').getLocation(4).lineNumber, 2);
    expect(lineInfo('foo\rbar').getLocation(4).columnNumber, 1);
    expect(lineInfo('foo').getLocation(0).lineNumber, 1);
    expect(lineInfo('foo').getLocation(0).columnNumber, 1);
    expect(lineInfo('').getLocation(1).lineNumber, 1);
  }

  test_constructor() {
    GenerateOptionsErrorsTask task =
        new GenerateOptionsErrorsTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_createTask() {
    GenerateOptionsErrorsTask task =
        GenerateOptionsErrorsTask.createTask(context, source);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, source);
  }

  test_description() {
    GenerateOptionsErrorsTask task =
        new GenerateOptionsErrorsTask(null, source);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = GenerateOptionsErrorsTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  @failingTest
  test_perform_bad_yaml() {
    // We have lost the ability to detect this kind of error.
    String code = r'''
:
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, AnalysisOptionsErrorCode.PARSE_ERROR);
  }

  test_perform_include() {
    newSource('/other_options.yaml', '');
    String code = r'''
include: other_options.yaml
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(0));
  }

  test_perform_include_bad_value() {
    newSource('/other_options.yaml', '''
analyzer:
  errors:
    unused_local_variable: ftw
''');
    String code = r'''
include: other_options.yaml
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.errorCode, AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING);
    expect(error.source, target.source);
    expect(error.offset, 10);
    expect(error.length, 18);
    expect(error.message, contains('other_options.yaml(47..49)'));
  }

  @failingTest
  test_perform_include_bad_yaml() {
    // We have lost the ability to detect this kind of error.
    newSource('/other_options.yaml', ':');
    String code = r'''
include: other_options.yaml
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.errorCode, AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR);
    expect(error.source, target.source);
    expect(error.offset, 10);
    expect(error.length, 18);
    expect(error.message, contains('other_options.yaml(0..0)'));
  }

  test_perform_include_missing() {
    String code = r'''
include: other_options.yaml
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.errorCode, AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND);
    expect(error.offset, 10);
    expect(error.length, 18);
  }

  test_perform_OK() {
    String code = r'''
analyzer:
  strong-mode: true
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    expect(outputs[ANALYSIS_OPTIONS_ERRORS], isEmpty);
    LineInfo lineInfo = outputs[LINE_INFO];
    expect(lineInfo, isNotNull);
    expect(lineInfo.getLocation(1).lineNumber, 1);
    expect(lineInfo.getLocation(10).lineNumber, 2);
  }

  test_perform_unsupported_analyzer_option() {
    String code = r'''
analyzer:
  not_supported: true
''';
    AnalysisTarget target = newSource(optionsFilePath, code);
    computeResult(target, ANALYSIS_OPTIONS_ERRORS);
    expect(task, isGenerateOptionsErrorsTask);
    List<AnalysisError> errors =
        outputs[ANALYSIS_OPTIONS_ERRORS] as List<AnalysisError>;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode,
        AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES);
  }
}

@reflectiveTest
class GenerateOldOptionsErrorsTaskTest extends AbstractContextTest {
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  String get optionsFilePath => '/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';

  test_does_analyze_old_options_files() {
    validate('''
analyzer:
  strong-mode: true
    ''', [AnalysisOptionsHintCode.DEPRECATED_ANALYSIS_OPTIONS_FILE_NAME]);
  }

  test_finds_issues_in_old_options_files() {
    validate('''
analyzer:
  strong_mode: true
    ''', [
      AnalysisOptionsHintCode.DEPRECATED_ANALYSIS_OPTIONS_FILE_NAME,
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES
    ]);
  }

  void validate(String content, List<ErrorCode> expected) {
    final Source source = newSource(optionsFilePath, content);
    var options = optionsProvider.getOptionsFromSource(source);
    final OptionsFileValidator validator = new OptionsFileValidator(source);
    var errors = validator.validate(options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
  }
}

@reflectiveTest
class OptionsFileValidatorTest {
  final OptionsFileValidator validator =
      new OptionsFileValidator(new TestSource());
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

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

  test_analyzer_language_supported() {
    validate('''
analyzer:
  language:
    enableSuperMixins: true
''', []);
  }

  test_analyzer_language_unsupported_key() {
    validate('''
analyzer:
  language:
    unsupported: true
''', [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_language_unsupported_value() {
    validate('''
analyzer:
  language:
    enableSuperMixins: foo
''', [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
  }

  test_analyzer_lint_codes_recognized() {
    Registry.ruleRegistry.register(new TestRule());
    validate('''
analyzer:
  errors:
    fantastic_test_rule: ignore
    ''', []);
  }

  test_analyzer_strong_mode_error_code_supported() {
    validate('''
analyzer:
  errors:
    strong_mode_assignment_cast: ignore
''', []);
  }

  test_analyzer_strong_mode_false_deprecated() {
    validate('''
analyzer:
  strong-mode: false
    ''', [AnalysisOptionsHintCode.SPEC_MODE_DEPRECATED]);
  }

  test_analyzer_supported_exclude() {
    validate('''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
    ''', []);
  }

  test_analyzer_supported_strong_mode() {
    validate('''
analyzer:
  strong-mode: true
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

  test_linter_supported_rules() {
    Registry.ruleRegistry.register(new TestRule());
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
    var rawProvider = new MemoryResourceProvider();
    resourceProvider = new TestResourceProvider(rawProvider);
    pathTranslator = new TestPathTranslator(rawProvider);
    provider = new AnalysisOptionsProvider(new SourceFactory([
      new ResourceUriResolver(rawProvider),
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

    final lowlevellint = new TestRule.withName('lowlevellint');
    final toplevellint = new TestRule.withName('toplevellint');
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
          new ErrorProcessorMatcher(
              new ErrorProcessor('toplevelerror', ErrorSeverity.WARNING)),
          new ErrorProcessorMatcher(
              new ErrorProcessor('lowlevelerror', ErrorSeverity.WARNING))
        ]));
  }

  YamlMap _getOptions(String posixPath, {bool crawlUp: false}) {
    Resource resource = pathTranslator.getResource(posixPath);
    return provider.getOptions(resource, crawlUp: crawlUp);
  }

  AnalysisOptions _getOptionsObject(String posixPath, {bool crawlUp: false}) {
    final map = _getOptions(posixPath, crawlUp: crawlUp);
    final options = new AnalysisOptionsImpl();
    applyToAnalysisOptions(options, map);
    return options;
  }
}

class TestRule extends LintRule {
  TestRule() : super(name: 'fantastic_test_rule');
  TestRule.withName(String name) : super(name: name);
}
