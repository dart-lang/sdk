// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.options_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';
import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextConfigurationTest);
    defineReflectiveTests(GenerateNewOptionsErrorsTaskTest);
    defineReflectiveTests(GenerateOldOptionsErrorsTaskTest);
    defineReflectiveTests(OptionsFileValidatorTest);
  });
}

isInstanceOf isGenerateOptionsErrorsTask =
    new isInstanceOf<GenerateOptionsErrorsTask>();

@reflectiveTest
class ContextConfigurationTest extends AbstractContextTest {
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  AnalysisOptions get analysisOptions => context.analysisOptions;

  configureContext(String optionsSource) =>
      applyToAnalysisOptions(analysisOptions, parseOptions(optionsSource));

  Map<String, YamlNode> parseOptions(String source) =>
      optionsProvider.getOptionsFromString(source);

  test_configure_bad_options_contents() {
    configureContext('''
analyzer:
  strong-mode:true # misformatted
''');
    expect(analysisOptions.strongMode, false);
  }

  test_configure_enableLazyAssignmentOperators() {
    expect(analysisOptions.enableStrictCallChecks, false);
    configureContext('''
analyzer:
  language:
    enableStrictCallChecks: true
''');
    expect(analysisOptions.enableStrictCallChecks, true);
  }

  test_configure_enableStrictCallChecks() {
    configureContext('''
analyzer:
  language:
    enableStrictCallChecks: true
''');
    expect(analysisOptions.enableStrictCallChecks, true);
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

  test_configure_strong_mode() {
    configureContext('''
analyzer:
  strong-mode: true
''');
    expect(analysisOptions.strongMode, true);
  }

  test_configure_strong_mode_bad_value() {
    configureContext('''
analyzer:
  strong-mode: foo
''');
    expect(analysisOptions.strongMode, false);
  }
}

@reflectiveTest
class GenerateNewOptionsErrorsTaskTest extends GenerateOptionsErrorsTaskTest {
  String get optionsFilePath => '/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}';
}

@reflectiveTest
class GenerateOldOptionsErrorsTaskTest extends GenerateOptionsErrorsTaskTest {
  String get optionsFilePath => '/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';
}

abstract class GenerateOptionsErrorsTaskTest extends AbstractContextTest {
  Source source;

  String get optionsFilePath;
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

  test_perform_bad_yaml() {
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
    newSource(
        '/other_options.yaml',
        '''
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

  test_perform_include_bad_yaml() {
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
class OptionsFileValidatorTest {
  final OptionsFileValidator validator =
      new OptionsFileValidator(new TestSource());
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  test_analyzer_error_code_supported() {
    validate(
        '''
analyzer:
  errors:
    unused_local_variable: ignore
    invalid_assignment: warning
    missing_return: error
    dead_code: info
''',
        []);
  }

  test_analyzer_error_code_supported_bad_value() {
    validate(
        '''
analyzer:
  errors:
    unused_local_variable: ftw
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_error_code_unsupported() {
    validate(
        '''
analyzer:
  errors:
    not_supported: ignore
    ''',
        [AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE]);
  }

  test_analyzer_language_supported() {
    validate(
        '''
analyzer:
  language:
    enableSuperMixins: true
''',
        []);
  }

  test_analyzer_language_unsupported_key() {
    validate(
        '''
analyzer:
  language:
    unsupported: true
''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_analyzer_language_unsupported_value() {
    validate(
        '''
analyzer:
  language:
    enableSuperMixins: foo
''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
  }

  test_analyzer_strong_mode_error_code_supported() {
    validate(
        '''
analyzer:
  errors:
    strong_mode_assignment_cast: ignore
''',
        []);
  }

  test_analyzer_supported_exclude() {
    validate(
        '''
analyzer:
  exclude:
    - test/_data/p4/lib/lib1.dart
    ''',
        []);
  }

  test_analyzer_supported_strong_mode() {
    validate(
        '''
analyzer:
  strong-mode: true
    ''',
        []);
  }

  test_analyzer_supported_strong_mode_supported_bad_value() {
    validate(
        '''
analyzer:
  strong-mode: w00t
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_VALUE]);
  }

  test_analyzer_unsupported_option() {
    validate(
        '''
analyzer:
  not_supported: true
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES]);
  }

  test_linter_supported_rules() {
    Registry.ruleRegistry.register(new TestRule());
    validate(
        '''
linter:
  rules:
    - fantastic_test_rule
    ''',
        []);
  }

  test_linter_unsupported_option() {
    validate(
        '''
linter:
  unsupported: true
    ''',
        [AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE]);
  }

  void validate(String source, List<ErrorCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    var errors = validator.validate(options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
  }
}

class TestRule extends LintRule {
  TestRule() : super(name: 'fantastic_test_rule');
}
