// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_test;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask,
    ParseDartTask, ScanDartTask;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuildCompilationUnitElementTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(ScanDartTaskTest);
}

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs =
        BuildCompilationUnitElementTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs, hasLength(1));
    expect(
        inputs[BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME],
        isNotNull);
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        BuildCompilationUnitElementTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildCompilationUnitElementTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_library() {
    BuildCompilationUnitElementTask task = _performBuildTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(2));
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[BUILT_UNIT], isNotNull);
  }

  BuildCompilationUnitElementTask _performBuildTask(String content) {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {
      ScanDartTask.CONTENT_INPUT_NAME: content
    };
    scanTask.perform();
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;

    ParseDartTask parseTask = new ParseDartTask(context, target);
    parseTask.inputs = {
      ParseDartTask.LINE_INFO_INPUT_NAME: scanOutputs[LINE_INFO],
      ParseDartTask.TOKEN_STREAM_INPUT_NAME: scanOutputs[TOKEN_STREAM]
    };
    parseTask.perform();
    Map<ResultDescriptor, dynamic> parseOutputs = parseTask.outputs;

    BuildCompilationUnitElementTask buildTask =
        new BuildCompilationUnitElementTask(context, target);
    buildTask.inputs = {
      BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME:
          parseOutputs[PARSED_UNIT]
    };
    buildTask.perform();

    return buildTask;
  }
}

@reflectiveTest
class ParseDartTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = ParseDartTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs, hasLength(2));
    expect(inputs[ParseDartTask.LINE_INFO_INPUT_NAME], isNotNull);
    expect(inputs[ParseDartTask.TOKEN_STREAM_INPUT_NAME], isNotNull);
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ParseDartTask task = new ParseDartTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ParseDartTask task = ParseDartTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    ParseDartTask task = new ParseDartTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ParseDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    ParseDartTask task = _performParseTask(r'''
part of lib;
class B {}''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
  }

  test_perform_invalidDirectives() {
    ParseDartTask task = _performParseTask(r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(2));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  test_perform_library() {
    ParseDartTask task = _performParseTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(1));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  ParseDartTask _performParseTask(String content) {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {
      ScanDartTask.CONTENT_INPUT_NAME: content
    };
    scanTask.perform();
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;

    ParseDartTask parseTask = new ParseDartTask(context, target);
    parseTask.inputs = {
      ParseDartTask.LINE_INFO_INPUT_NAME: scanOutputs[LINE_INFO],
      ParseDartTask.TOKEN_STREAM_INPUT_NAME: scanOutputs[TOKEN_STREAM]
    };
    parseTask.perform();
    return parseTask;
  }
}

@reflectiveTest
class ScanDartTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = ScanDartTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs, hasLength(1));
    expect(inputs[ScanDartTask.CONTENT_INPUT_NAME], isNotNull);
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ScanDartTask task = new ScanDartTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ScanDartTask task = ScanDartTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    ScanDartTask task = new ScanDartTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ScanDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_errors() {
    ScanDartTask scanTask = _performScanTask('import "');

    expect(scanTask.caughtException, isNull);
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;
    expect(scanOutputs, hasLength(3));
    expect(scanOutputs[LINE_INFO], isNotNull);
    expect(scanOutputs[SCAN_ERRORS], hasLength(1));
    expect(scanOutputs[TOKEN_STREAM], isNotNull);
  }

  test_perform_noErrors() {
    ScanDartTask scanTask = _performScanTask('class A {}');

    expect(scanTask.caughtException, isNull);
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;
    expect(scanOutputs, hasLength(3));
    expect(scanOutputs[LINE_INFO], isNotNull);
    expect(scanOutputs[SCAN_ERRORS], hasLength(0));
    expect(scanOutputs[TOKEN_STREAM], isNotNull);
  }

  ScanDartTask _performScanTask(String content) {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {
      ScanDartTask.CONTENT_INPUT_NAME: content
    };
    scanTask.perform();
    return scanTask;
  }
}
