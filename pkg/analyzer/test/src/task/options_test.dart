// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.options_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(GenerateOptionsErrorsTaskTest);
}

isInstanceOf isGenerateOptionsErrorsTask =
    new isInstanceOf<GenerateOptionsErrorsTask>();

@reflectiveTest
class GenerateOptionsErrorsTaskTest extends AbstractContextTest {
  final optionsFilePath = '/${AnalysisEngine.ANALYSIS_OPTIONS_FILE}';

  Source source;
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
    List<AnalysisError> errors = outputs[ANALYSIS_OPTIONS_ERRORS];
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, AnalysisOptionsErrorCode.PARSE_ERROR);
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
  }
}
