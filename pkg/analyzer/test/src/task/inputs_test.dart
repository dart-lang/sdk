// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.inputs_test;

import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantTaskInputBuilderTest);
    defineReflectiveTests(ConstantTaskInputTest);
    defineReflectiveTests(ListTaskInputImplTest);
    defineReflectiveTests(ListToListTaskInputTest);
    defineReflectiveTests(ListToListTaskInputBuilderTest);
    defineReflectiveTests(ListToMapTaskInputBuilderTest);
    defineReflectiveTests(ListToMapTaskInputTest);
    defineReflectiveTests(ObjectToListTaskInputBuilderTest);
    defineReflectiveTests(ObjectToListTaskInputTest);
    defineReflectiveTests(SimpleTaskInputTest);
    defineReflectiveTests(SimpleTaskInputBuilderTest);
    defineReflectiveTests(TopLevelTaskInputBuilderTest);
  });
}

@reflectiveTest
class ConstantTaskInputBuilderTest extends EngineTestCase {
  static final int value = 7;
  static final ConstantTaskInput<int> input = new ConstantTaskInput<int>(value);

  ConstantTaskInputBuilder builder;

  void setUp() {
    super.setUp();
    builder = new ConstantTaskInputBuilder(input);
  }

  test_create() {
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_beforeMoveNext() {
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_beforeMoveNext() {
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    builder.moveNext();
    expect(() {
      builder.currentValue = 'value';
    }, throwsStateError);
  }

  test_currentValue_beforeMoveNext() {
    expect(() {
      builder.currentValue = 'value';
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    builder.moveNext();
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.inputValue, value);
  }

  test_inputValue_beforeMoveNext() {
    expect(builder.inputValue, value);
  }

  test_moveNext() {
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class ConstantTaskInputTest extends EngineTestCase {
  test_create() {
    int value = 3;
    ConstantTaskInput<int> input = new ConstantTaskInput<int>(value);
    expect(input, isNotNull);
    expect(input.value, value);
  }

  test_createBuilder() {
    ConstantTaskInput<int> input = new ConstantTaskInput<int>(5);
    expect(input.createBuilder(), new isInstanceOf<ConstantTaskInputBuilder>());
  }
}

@reflectiveTest
class ListTaskInputImplTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptor<List<AnalysisTarget>> result1 =
      new ResultDescriptorImpl<List<AnalysisTarget>>('result1', null);
  static final result2 = new ResultDescriptorImpl<int>('result2', null);

  test_create() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    expect(input, isNotNull);
    expect(input.target, target);
    expect(input.result, result1);
  }

  test_createBuilder() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    expect(input.createBuilder(), new isInstanceOf<SimpleTaskInputBuilder>());
  }

  test_toList() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    TaskInput<List> input2 =
        input.toList((target) => new SimpleTaskInput(target, null));
    expect(input2,
        new isInstanceOf<ListToListTaskInput<AnalysisTarget, String>>());
  }

  test_toListOf() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    TaskInput<List> input2 = input.toListOf(result2);
    expect(
        input2, new isInstanceOf<ListToListTaskInput<AnalysisTarget, int>>());
  }

  test_toMap() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    TaskInput<Map> input2 =
        input.toMap((target) => new SimpleTaskInput(target, null));
    expect(
        input2, new isInstanceOf<ListToMapTaskInput<AnalysisTarget, String>>());
  }

  test_toMapOf() {
    var input = new ListTaskInputImpl<AnalysisTarget>(target, result1);
    TaskInput<Map> input2 = input.toMapOf(result2);
    expect(input2, new isInstanceOf<ListToMapTaskInput<AnalysisTarget, int>>());
  }
}

@reflectiveTest
class ListToListTaskInputBuilderTest extends EngineTestCase {
  static final AnalysisTarget target1 = new TestSource();
  static final ResultDescriptorImpl<List> result1 =
      new ResultDescriptorImpl<List>('result1', null);
  static final ResultDescriptorImpl result2 =
      new ResultDescriptorImpl('result2', null);
  static final ListToListTaskInput input = new ListToListTaskInput(
      result1.of(target1), (element) => result2.of(element));

  test_create() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterCurrentValueNotAvailable() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentResult, result1);
  }

  test_currentResult_beforeMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterCurrentValueNotAvailable() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentTarget, target1);
  }

  test_currentTarget_beforeMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
  }

  test_currentValue_beforeMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(() {
      builder.currentValue = [];
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    AnalysisTarget target2 = new TestSource();
    AnalysisTarget target3 = new TestSource();
    String value2 = 'value2';
    String value3 = 'value3';
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
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

  test_inputValue_afterFirstValueNotAvailable() {
    AnalysisTarget target2 = new TestSource();
    AnalysisTarget target3 = new TestSource();
    String value3 = 'value3';
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValue = [target2, target3];
    builder.moveNext(); // Advance to requesting result2 for target2
    builder.currentValueNotAvailable();
    builder.moveNext(); // Advance to requesting result2 for target3
    builder.currentValue = value3;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<List>());
    List list = inputValue;
    expect(list, orderedEquals([value3]));
  }

  test_inputValue_afterListNotAvailable() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValueNotAvailable();
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<List>());
    List list = inputValue;
    expect(list, isEmpty);
  }

  test_inputValue_afterOneMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    ListToListTaskInputBuilder builder = new ListToListTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    builder.currentValue = [];
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class ListToListTaskInputTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl<List> result =
      new ResultDescriptorImpl<List>('result', null);

  test_create() {
    SimpleTaskInput<List> baseAccessor = result.of(target);
    GenerateTaskInputs generate = (object) {};
    ListToListTaskInput input = new ListToListTaskInput(baseAccessor, generate);
    expect(input, isNotNull);
    expect(input.baseAccessor, baseAccessor);
    expect(input.generateTaskInputs, equals(generate));
  }

  test_createBuilder() {
    SimpleTaskInput<List> baseAccessor = result.of(target);
    GenerateTaskInputs generate = (object) {};
    ListToListTaskInput input = new ListToListTaskInput(baseAccessor, generate);
    expect(input.createBuilder(), isNotNull);
  }
}

@reflectiveTest
class ListToMapTaskInputBuilderTest extends EngineTestCase {
  static final AnalysisTarget target1 = new TestSource('target1');
  static final ResultDescriptorImpl<List> result1 =
      new ResultDescriptorImpl<List>('result1', null);
  static final ResultDescriptorImpl result2 =
      new ResultDescriptorImpl('result2', null);
  static final ListToMapTaskInput input = new ListToMapTaskInput(
      result1.of(target1), (element) => result2.of(element));

  test_create() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterCurrentValueNotAvailable() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentResult, result1);
  }

  test_currentResult_beforeMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterCurrentValueNotAvailable() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    expect(builder.currentTarget, target1);
  }

  test_currentTarget_beforeMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValue = [];
  }

  test_currentValue_beforeMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(() {
      builder.currentValue = [];
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    builder.currentValueNotAvailable();
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    AnalysisTarget target2 = new TestSource('target2');
    AnalysisTarget target3 = new TestSource('target3');
    String value2 = 'value2';
    String value3 = 'value3';
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValue = [target2, target3];
    builder.moveNext(); // Advance to requesting result2 for target2
    builder.currentValue = value2;
    builder.moveNext(); // Advance to requesting result2 for target3
    builder.currentValue = value3;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<Map>());
    expect(inputValue.length, 2);
    expect(inputValue, containsPair(target2, value2));
    expect(inputValue, containsPair(target3, value3));
  }

  test_inputValue_afterFirstValueNotAvailable() {
    AnalysisTarget target2 = new TestSource('target2');
    AnalysisTarget target3 = new TestSource('target3');
    String value3 = 'value3';
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValue = [target2, target3];
    builder.moveNext(); // Advance to requesting result2 for target2
    builder.currentValueNotAvailable();
    builder.moveNext(); // Advance to requesting result2 for target3
    builder.currentValue = value3;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<Map>());
    expect(inputValue, hasLength(1));
    expect(inputValue, containsPair(target3, value3));
  }

  test_inputValue_afterListNotAvailable() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext(); // Advance to requesting the list
    builder.currentValueNotAvailable();
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<Map>());
    expect(inputValue, isEmpty);
  }

  test_inputValue_afterOneMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    ListToMapTaskInputBuilder builder = new ListToMapTaskInputBuilder(input);
    expect(builder.moveNext(), true);
    builder.currentValue = [];
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class ListToMapTaskInputTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl<List> result =
      new ResultDescriptorImpl<List>('result', null);

  test_create() {
    SimpleTaskInput<List> baseAccessor = result.of(target);
    GenerateTaskInputs generate = (object) {};
    ListToMapTaskInput input = new ListToMapTaskInput(baseAccessor, generate);
    expect(input, isNotNull);
    expect(input.baseAccessor, baseAccessor);
    expect(input.generateTaskInputs, equals(generate));
  }

  test_createBuilder() {
    SimpleTaskInput<List> baseAccessor = result.of(target);
    GenerateTaskInputs generate = (object) {};
    ListToMapTaskInput input = new ListToMapTaskInput(baseAccessor, generate);
    expect(input.createBuilder(), isNotNull);
  }
}

@reflectiveTest
class ObjectToListTaskInputBuilderTest {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);
  static final SimpleTaskInput baseInput = new SimpleTaskInput(target, result);
  static final mapper = (Object x) => [x];
  static final ObjectToListTaskInput input =
      new ObjectToListTaskInput(baseInput, mapper);

  ObjectToListTaskInputBuilder builder;

  void setUp() {
    builder = new ObjectToListTaskInputBuilder(input);
  }

  test_create() {
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentResult, result);
  }

  test_currentResult_beforeMoveNext() {
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentTarget, target);
  }

  test_currentTarget_beforeMoveNext() {
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    builder.moveNext();
    builder.currentValue = 'value';
  }

  test_currentValue_beforeMoveNext() {
    expect(() {
      builder.currentValue = 'value';
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    builder.moveNext();
    builder.currentValueNotAvailable();
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    builder.moveNext();
    String value = 'value';
    builder.currentValue = value;
    builder.moveNext();
    expect(builder.inputValue, [value]);
  }

  test_inputValue_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.inputValue, [null]);
  }

  test_inputValue_afterOneMoveNext() {
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    expect(builder.moveNext(), true);
    builder.currentValue = 'value';
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}

@reflectiveTest
class ObjectToListTaskInputTest extends EngineTestCase {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);

  test_create() {
    SimpleTaskInput baseInput = new SimpleTaskInput(target, result);
    var mapper = (Object x) => [x];
    ObjectToListTaskInput input = new ObjectToListTaskInput(baseInput, mapper);
    expect(input, isNotNull);
    expect(input.baseInput, baseInput);
    expect(input.mapper, equals(mapper));
  }

  test_createBuilder() {
    SimpleTaskInput baseInput = new SimpleTaskInput(target, result);
    var mapper = (Object x) => [x];
    ObjectToListTaskInput input = new ObjectToListTaskInput(baseInput, mapper);
    expect(input.createBuilder(),
        new isInstanceOf<ObjectToListTaskInputBuilder>());
  }
}

@reflectiveTest
class SimpleTaskInputBuilderTest {
  static final AnalysisTarget target = new TestSource();
  static final ResultDescriptorImpl result =
      new ResultDescriptorImpl('result', null);
  static final SimpleTaskInput input = new SimpleTaskInput(target, result);

  SimpleTaskInputBuilder builder;

  void setUp() {
    builder = new SimpleTaskInputBuilder(input);
  }

  test_create() {
    expect(builder, isNotNull);
    expect(builder.input, input);
  }

  test_currentResult_afterComplete() {
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentResult, result);
  }

  test_currentResult_beforeMoveNext() {
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    builder.moveNext();
    builder.currentValue = 'value';
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    builder.moveNext();
    expect(builder.currentTarget, target);
  }

  test_currentTarget_beforeMoveNext() {
    expect(builder.currentTarget, null);
  }

  test_currentValue_afterOneMoveNext() {
    builder.moveNext();
    builder.currentValue = 'value';
  }

  test_currentValue_beforeMoveNext() {
    expect(() {
      builder.currentValue = 'value';
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    builder.moveNext();
    builder.currentValueNotAvailable();
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    builder.moveNext();
    String value = 'value';
    builder.currentValue = value;
    builder.moveNext();
    expect(builder.inputValue, value);
  }

  test_inputValue_afterCurrentValueNotAvailable() {
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.inputValue, isNull);
  }

  test_inputValue_afterOneMoveNext() {
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_beforeMoveNext() {
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
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
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterCurrentValueNotAvailable() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentResult, null);
  }

  test_currentResult_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {'one': input1, 'two': input2};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(builder.currentResult, result1);
  }

  test_currentResult_afterTwoMoveNext_withConstantInput() {
    ConstantTaskInput<int> constantInput = new ConstantTaskInput<int>(11);
    Map<String, TaskInput> inputDescriptors = <String, TaskInput>{
      'one': input1,
      'constant': constantInput,
      'two': input2
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
    builder.moveNext();
    expect(builder.currentResult, result2);
  }

  test_currentResult_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.currentResult, null);
  }

  test_currentTarget_afterComplete() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterCurrentValueNotAvailable() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValueNotAvailable();
    builder.moveNext();
    expect(builder.currentTarget, null);
  }

  test_currentTarget_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(builder.currentTarget, target);
  }

  test_currentTarget_afterTwoMoveNext_withConstantInput() {
    ConstantTaskInput<int> constantInput = new ConstantTaskInput<int>(11);
    Map<String, TaskInput> inputDescriptors = <String, TaskInput>{
      'one': input1,
      'constant': constantInput,
      'two': input2
    };
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
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
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValue = 'value1';
  }

  test_currentValue_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(() {
      builder.currentValue = 'value1';
    }, throwsStateError);
  }

  test_currentValueNotAvailable_afterOneMoveNext() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    builder.currentValueNotAvailable();
  }

  test_currentValueNotAvailable_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(() {
      builder.currentValueNotAvailable();
    }, throwsStateError);
  }

  test_inputValue_afterComplete() {
    String key1 = 'one';
    String key2 = 'two';
    String value1 = 'value1';
    String value2 = 'value2';
    Map<String, TaskInput> inputDescriptors = {key1: input1, key2: input2};
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
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext();
    expect(() => builder.inputValue, throwsStateError);
  }

  test_inputValue_afterOneValueNotAvailable() {
    String key1 = 'one';
    String key2 = 'two';
    String value2 = 'value2';
    Map<String, TaskInput> inputDescriptors = {key1: input1, key2: input2};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    builder.moveNext(); // Advance to requesting result1 for target
    builder.currentValueNotAvailable();
    builder.moveNext(); // Advance to requesting result2 for target
    builder.currentValue = value2;
    builder.moveNext(); // Advance to the end
    var inputValue = builder.inputValue;
    expect(inputValue, new isInstanceOf<Map>());
    Map inputs = inputValue;
    expect(inputs, hasLength(1));
    expect(inputs, containsPair(key2, value2));
  }

  test_inputValue_beforeMoveNext() {
    Map<String, TaskInput> inputDescriptors = {};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(() => builder.inputValue, throwsStateError);
  }

  test_moveNext_withoutSet() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.moveNext(), true);
    expect(() => builder.moveNext(), throwsStateError);
  }

  test_moveNext_withSet() {
    Map<String, TaskInput> inputDescriptors = {'one': input1};
    TopLevelTaskInputBuilder builder =
        new TopLevelTaskInputBuilder(inputDescriptors);
    expect(builder.moveNext(), true);
    builder.currentValue = 'value1';
    expect(builder.moveNext(), false);
    expect(builder.moveNext(), false);
  }
}
