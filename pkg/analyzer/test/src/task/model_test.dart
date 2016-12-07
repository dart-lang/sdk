// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.model_test;

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisTaskTest);
    defineReflectiveTests(ResultDescriptorImplTest);
    defineReflectiveTests(SimpleResultCachingPolicyTest);
    defineReflectiveTests(TaskDescriptorImplTest);
  });
}

@reflectiveTest
class AnalysisTaskTest extends EngineTestCase {
  test_getRequiredInput_missingKey() {
    AnalysisTarget target = new TestSource();
    AnalysisTask task = new TestAnalysisTask(null, target);
    task.inputs = {'a': 'b'};
    expect(() => task.getRequiredInput('c'),
        throwsA(new isInstanceOf<AnalysisException>()));
  }

  test_getRequiredInput_noInputs() {
    AnalysisTarget target = new TestSource();
    AnalysisTask task = new TestAnalysisTask(null, target);
    expect(() => task.getRequiredInput('x'),
        throwsA(new isInstanceOf<AnalysisException>()));
  }

  test_getRequiredInput_valid() {
    AnalysisTarget target = new TestSource();
    AnalysisTask task = new TestAnalysisTask(null, target);
    String key = 'a';
    String value = 'b';
    task.inputs = {key: value};
    expect(task.getRequiredInput(key), value);
  }

  test_getRequiredSource() {
    AnalysisTarget target = new TestSource();
    AnalysisTask task = new TestAnalysisTask(null, target);
    expect(task.getRequiredSource(), target);
  }
}

@reflectiveTest
class ResultDescriptorImplTest extends EngineTestCase {
  test_create_withCachingPolicy() {
    ResultCachingPolicy policy = new SimpleResultCachingPolicy(128, 16);
    ResultDescriptorImpl result =
        new ResultDescriptorImpl('result', null, cachingPolicy: policy);
    expect(result.cachingPolicy, same(policy));
  }

  test_create_withoutCachingPolicy() {
    ResultDescriptorImpl result = new ResultDescriptorImpl('result', null);
    ResultCachingPolicy cachingPolicy = result.cachingPolicy;
    expect(cachingPolicy, isNotNull);
    expect(cachingPolicy.maxActiveSize, -1);
    expect(cachingPolicy.maxIdleSize, -1);
  }

  test_create_withoutContribution() {
    expect(new ResultDescriptorImpl('name', null), isNotNull);
  }

  test_inputFor() {
    AnalysisTarget target = new TestSource();
    ResultDescriptorImpl result = new ResultDescriptorImpl('result', null);
    TaskInput input = result.of(target);
    expect(input, isNotNull);
  }

  test_name() {
    String name = 'result';
    ResultDescriptorImpl result = new ResultDescriptorImpl(name, null);
    expect(result.name, name);
  }
}

@reflectiveTest
class SimpleResultCachingPolicyTest extends EngineTestCase {
  test_create() {
    ResultCachingPolicy policy = new SimpleResultCachingPolicy(256, 32);
    expect(policy.maxActiveSize, 256);
    expect(policy.maxIdleSize, 32);
    expect(policy.measure(null), 1);
  }
}

@reflectiveTest
class TaskDescriptorImplTest extends EngineTestCase {
  test_create_noOptionalArgs() {
    String name = 'name';
    BuildTask buildTask = (context, target) {};
    CreateTaskInputs createTaskInputs = (target) {};
    List<ResultDescriptor> results = <ResultDescriptor>[];
    TaskDescriptorImpl descriptor =
        new TaskDescriptorImpl(name, buildTask, createTaskInputs, results);
    expect(descriptor, isNotNull);
    expect(descriptor.name, name);
    expect(descriptor.buildTask, equals(buildTask));
    expect(descriptor.createTaskInputs, equals(createTaskInputs));
    expect(descriptor.suitabilityFor(null), TaskSuitability.LOWEST);
    expect(descriptor.results, results);
  }

  test_create_withIsAppropriateFor() {
    String name = 'name';
    BuildTask buildTask = (context, target) {};
    CreateTaskInputs createTaskInputs = (target) {};
    List<ResultDescriptor> results = <ResultDescriptor>[];
    SuitabilityFor suitabilityFor = (target) => TaskSuitability.NONE;
    TaskDescriptorImpl descriptor = new TaskDescriptorImpl(
        name, buildTask, createTaskInputs, results,
        suitabilityFor: suitabilityFor);
    expect(descriptor, isNotNull);
    expect(descriptor.name, name);
    expect(descriptor.buildTask, equals(buildTask));
    expect(descriptor.createTaskInputs, equals(createTaskInputs));
    expect(descriptor.suitabilityFor(null), TaskSuitability.NONE);
    expect(descriptor.results, results);
  }

  test_createTask() {
    BuildTask buildTask =
        (context, target) => new TestAnalysisTask(context, target);
    CreateTaskInputs createTaskInputs = (target) {};
    List<ResultDescriptor> results = <ResultDescriptor>[];
    TaskDescriptorImpl descriptor =
        new TaskDescriptorImpl('name', buildTask, createTaskInputs, results);
    AnalysisContext context = null;
    AnalysisTarget target = new TestSource();
    Map<String, dynamic> inputs = {};
    AnalysisTask createTask = descriptor.createTask(context, target, inputs);
    expect(createTask, isNotNull);
    expect(createTask.context, context);
    expect(createTask.inputs, inputs);
    expect(createTask.target, target);
  }
}
