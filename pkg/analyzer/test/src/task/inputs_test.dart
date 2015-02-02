// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.inputs_test;

import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ListBasedTaskInputTest);
  runReflectiveTests(ListBasedTaskInputBuilderTest);
  runReflectiveTests(SimpleTaskInputTest);
  runReflectiveTests(SimpleTaskInputBuilderTest);
  runReflectiveTests(TopLevelTaskInputBuilderTest);
}

@reflectiveTest
class ListBasedTaskInputBuilderTest extends EngineTestCase {
  static final AnalysisTarget target1 = new TestSource();
  static final ResultDescriptorImpl result1 =
      new ResultDescriptorImpl('result1', null);
  static final ResultDescriptorImpl result2 =
      new ResultDescriptorImpl('result2', null);
  static final ListBasedTaskInput input = new ListBasedTaskInput(
      result1.inputFor(target1),
      (element) => result2.inputFor(element));

  test_create() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentResult, result1);
  }

  test_currentResult_beforeMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentTarget, target1);
  }

  test_currentTarget_beforeMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
  }

  test_currentValue_beforeMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(() {
      builder.currentValue = [];
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    AnalysisTarget target2 = new TestSource();
    AnalysisTarget target3 = new TestSource();
    String value2 = 'value2';
    String value3 = 'value3';
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValue = [target2, target3];
    builder.moveNext(); // Advance to requesting result2 for target2
    builder.currentValue = value2;
    builder.moveNext(); // Advance to requesting result2 for target3
    builder.currentValue = value3;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<List>());
    List list = inputValue;
    expect(list.length, 2);
    expect(list[0], value2);
    expect(list[1], value3);
  }

  test_inputValue_afterOneMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    ListBasedTaskInputBuilder builder = new ListBasedTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    builder.currentValue = [];
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class ListBasedTaskInputTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);

  test_create() {
    SimpleTaskInput baseAccessor = result.inputFor(target);
    GenerateTaskInputs generate = (object) {};
    ListBasedTaskInput input = new ListBasedTaskInput(baseAccessor, generate);
    expect(input, isNotNull);
    expect(input.baseAccessor, baseAccessor);
    expect(input.generateTaskInputs, equals(generate));
  }

  test_createBuilder() {
    SimpleTaskInput baseAccessor = result.inputFor(target);
    GenerateTaskInputs generate = (object) {};
    ListBasedTaskInput input = new ListBasedTaskInput(baseAccessor, generate);
    expect(input.createBuilder(), isNotNull);
  }
}

@reflectiveTest
class SimpleTaskInputBuilderTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);
  static final SimpleTaskInput input = new SimpleTaskInput(target, result);

  test_create() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentResult, result);
  }

  test_currentResult_beforeMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentTarget, target);
  }

  test_currentTarget_beforeMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = 'value';
  }

  test_currentValue_beforeMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(() {
      builder.currentValue = 'value';
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    String value = 'value';
    builder.currentValue = value;
    builder.moveNext();
    expect(builder.inputValue, value);
  }

  test_inputValue_afterOneMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    SimpleTaskInputBuilder builder = new SimpleTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    builder.currentValue = 'value';
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class SimpleTaskInputTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);

  test_create() {
    SimpleTaskInput input = new SimpleTaskInput(target, result);
    expect(input, isNotNull);
    expect(input.target, target);
    expect(input.result, result);
  }

  test_createBuilder() {
    SimpleTaskInput input = new SimpleTaskInput(target, result);
    expect(input.createBuilder(), new isInstanceOf<SimpleTaskInputBuilder>());
  }
}

@reflectiveTest
class TopLevelTaskInputBuilderTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result1 =
      new ResultDescriptorImpl('result1', null);
  static final ResultDescriptorImpl result2 =
      new ResultDescriptorImpl('result2', null);
  static final SimpleTaskInput input1 = new SimpleTaskInput(target, result1);
  static final SimpleTaskInput input2 = new SimpleTaskInput(target, result2);

  test_create() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder, isNotNull);
    expect(builder.inputDescriptors, inputDescriptors);
  }

  test_currentResult_afterComplete() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1,
      'two': input2
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(builder.currentResult, result1);
  }

  test_currentResult_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(builder.currentTarget, target);
  }

  test_currentTarget_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
  }

  test_currentValue_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(() {
      builder.currentValue = 'value1';
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    String key1 = 'one';
    String key2 = 'two';
    String value1 = 'value1';
    String value2 = 'value2';
    Map<String, TaskInput> inputDescriptors = {
      key1: input1,
      key2: input2
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext(); // Advance to requesting result1 for target
    builder.currentValue = value1;
    builder.moveNext(); // Advance to requesting result2 for target
    builder.currentValue = value2;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<Map>());
    Map inputs = inputValue;
    expect(inputs.length, 2);
    expect(inputs, containsPair(key1, value1));
    expect(inputs, containsPair(key2, value2));
  }

  test_inputValue_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    Map<String, TaskInput> inputDescriptors = {
      'one': input1
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.moveNext(), true);
    builder.currentValue = 'value1';
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}
