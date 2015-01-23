// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.model_test;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/src/task/targets.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ContributionPointImplTest);
  runReflectiveTests(ResultDescriptorImplTest);
  runReflectiveTests(TaskDescriptorImplTest);
}

@reflectiveTest
class ContributionPointImplTest extends EngineTestCase {
  test_contributors_empty() {
    ContributionPointImpl point = new ContributionPointImpl('point');
    List<ResultDescriptor> contributors = point.contributors;
    expect(contributors, isEmpty);
  }

  test_contributors_nonEmpty() {
    ResultDescriptorImpl result1 = new ResultDescriptorImpl('result1');
    ResultDescriptorImpl result2 = new ResultDescriptorImpl('result2');
    ContributionPointImpl point = new ContributionPointImpl('point');
    point.recordContributor(result1);
    point.recordContributor(result2);
    List<ResultDescriptor> contributors = point.contributors;
    expect(contributors, isNotNull);
    expect(contributors, hasLength(2));
    if (!(contributors[0] == result1 && contributors[1] == result2) ||
        (contributors[0] == result2 && contributors[1] == result1)) {
      fail("Invalid contributors: $contributors");
    }
  }

  test_create() {
    expect(new ContributionPointImpl('name'), isNotNull);
  }

  test_name() {
    String name = 'point';
    ContributionPointImpl point = new ContributionPointImpl(name);
    expect(point.name, name);
  }
}

@reflectiveTest
class ResultDescriptorImplTest extends EngineTestCase {
  test_create_withContribution() {
    ContributionPointImpl point = new ContributionPointImpl('point');
    ResultDescriptorImpl result =
        new ResultDescriptorImpl('result', contributesTo: point);
    expect(result, isNotNull);
    List<ResultDescriptor> contributors = point.contributors;
    expect(contributors, unorderedEquals([result]));
  }

  test_create_withoutContribution() {
    expect(new ResultDescriptorImpl('name'), isNotNull);
  }

  test_inputFor() {
    SourceTarget target = new SourceTarget(null);
    ResultDescriptorImpl result = new ResultDescriptorImpl('result');
    TaskInput input = result.inputFor(target);
    expect(input, isNotNull);
  }

  test_name() {
    String name = 'result';
    ResultDescriptorImpl result = new ResultDescriptorImpl(name);
    expect(result.name, name);
  }
}

@reflectiveTest
class TaskDescriptorImplTest extends EngineTestCase {
  test_create() {
    String name = 'name';
    BuildTask buildTask = (context, target) {};
    CreateTaskInputs createTaskInputs = (target) {};
    List<ResultDescriptor> results = <ResultDescriptor>[];
    TaskDescriptorImpl descriptor = new TaskDescriptorImpl(name, buildTask, createTaskInputs, results);
    expect(descriptor, isNotNull);
    expect(descriptor.name, name);
    expect(descriptor.buildTask, equals(buildTask));
    expect(descriptor.createTaskInputs, equals(createTaskInputs));
    expect(descriptor.results, results);
  }

  test_createTask() {
    BuildTask buildTask = (context, target) => new TestAnalysisTask(context, target);
    CreateTaskInputs createTaskInputs = (target) {};
    List<ResultDescriptor> results = <ResultDescriptor>[];
    TaskDescriptorImpl descriptor = new TaskDescriptorImpl('name', buildTask, createTaskInputs, results);
    AnalysisContext context = null;
    SourceTarget target = new SourceTarget(null);
    Map<String, dynamic> inputs = {};
    AnalysisTask createTask = descriptor.createTask(context, target, inputs);
    expect(createTask, isNotNull);
    expect(createTask.context, context);
    expect(createTask.inputs, inputs);
    expect(createTask.target, target);
  }
}
