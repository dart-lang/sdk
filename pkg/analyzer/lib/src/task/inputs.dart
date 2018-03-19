// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/task/model.dart';

/**
 * A function that converts an object of the type [B] into a [TaskInput].
 * This is used, for example, by a [ListToListTaskInput] to create task inputs
 * for each value in a list of values.
 */
typedef TaskInput<E> GenerateTaskInputs<B, E>(B object);

/**
 * A function that maps one [value] to another value.
 */
typedef R Mapper<P, R>(P value);

/**
 * An input to an [AnalysisTask] that is computed by accessing a single result
 * defined on a single target.
 */
class ConstantTaskInput<V> extends TaskInputImpl<V> {
  final V value;

  ConstantTaskInput(this.value);

  @override
  TaskInputBuilder<V> createBuilder() {
    return new ConstantTaskInputBuilder<V>(this);
  }
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ConstantTaskInput].
 */
class ConstantTaskInputBuilder<V> implements TaskInputBuilder<V> {
  final ConstantTaskInput<V> input;

  ConstantTaskInputBuilder(this.input);

  @override
  ResultDescriptor get currentResult => null;

  @override
  AnalysisTarget get currentTarget => null;

  @override
  void set currentValue(Object value) {
    throw new StateError('Only supported after moveNext() returns true');
  }

  @override
  bool get flushOnAccess => false;

  @override
  V get inputValue => input.value;

  @override
  void currentValueNotAvailable() {
    throw new StateError('Only supported after moveNext() returns true');
  }

  @override
  bool moveNext() => false;
}

/**
 * An input to an [AnalysisTask] that is computed by accessing a single result
 * defined on a single target.
 */
class ListTaskInputImpl<E> extends SimpleTaskInput<List<E>>
    with ListTaskInputMixin<E>
    implements ListTaskInput<E> {
  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [result] associated with the given [target].
   */
  ListTaskInputImpl(AnalysisTarget target, ResultDescriptor<List<E>> result)
      : super._unflushable(target, result);
}

/**
 * A mixin-ready implementation of [ListTaskInput].
 */
abstract class ListTaskInputMixin<E> implements ListTaskInput<E> {
  @override
  ListTaskInput<V> toFlattenListOf<V>(ListResultDescriptor<V> subListResult) {
    return new ListToFlattenListTaskInput<E, V>(
        this,
        (E element) =>
            subListResult.of(element as AnalysisTarget) as TaskInput<V>);
  }

  ListTaskInput<V> toList<V>(UnaryFunction<E, V> mapper) {
    return new ListToListTaskInput<E, V>(this, mapper);
  }

  ListTaskInput<V> toListOf<V>(ResultDescriptor<V> valueResult) {
    return (this as ListTaskInput<AnalysisTarget>).toList(valueResult.of);
  }

  MapTaskInput<E, V> toMap<V>(UnaryFunction<E, V> mapper) {
    return new ListToMapTaskInput<E, V>(this, mapper);
  }

  MapTaskInput<AnalysisTarget, V> toMapOf<V>(ResultDescriptor<V> valueResult) {
    return (this as ListTaskInputImpl<AnalysisTarget>).toMap<V>(valueResult.of);
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and the list of the analysis results is used as the input to the task.
 */
class ListToFlattenListTaskInput<B, E>
    extends _ListToCollectionTaskInput<B, E, List<E>>
    with ListTaskInputMixin<E>
    implements ListTaskInput<E> {
  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  ListToFlattenListTaskInput(TaskInput<List<B>> baseAccessor,
      GenerateTaskInputs<B, E> generateTaskInputs)
      : super(baseAccessor, generateTaskInputs);

  @override
  TaskInputBuilder<List<E>> createBuilder() =>
      new ListToFlattenListTaskInputBuilder<B, E>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ListToFlattenListTaskInput].
 */
class ListToFlattenListTaskInputBuilder<B, E>
    extends _ListToCollectionTaskInputBuilder<B, E, List<E>> {
  /**
   * The list of values being built.
   */
  List<E> _resultValue;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ListToFlattenListTaskInputBuilder(ListToFlattenListTaskInput<B, E> input)
      : super(input);

  @override
  void _addResultElement(B baseElement, E resultElement) {
    _resultValue.addAll(resultElement as Iterable<E>);
  }

  @override
  void _initResultValue() {
    _resultValue = <E>[];
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and the list of the analysis results is used as the input to the task.
 */
class ListToListTaskInput<B, E>
    extends _ListToCollectionTaskInput<B, E, List<E>>
    with ListTaskInputMixin<E> {
  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  ListToListTaskInput(TaskInput<List<B>> baseAccessor,
      GenerateTaskInputs<B, E> generateTaskInputs)
      : super(baseAccessor, generateTaskInputs);

  @override
  TaskInputBuilder<List<E>> createBuilder() =>
      new ListToListTaskInputBuilder<B, E>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ListToListTaskInput].
 */
class ListToListTaskInputBuilder<B, E>
    extends _ListToCollectionTaskInputBuilder<B, E, List<E>> {
  /**
   * The list of values being built.
   */
  List<E> _resultValue;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ListToListTaskInputBuilder(ListToListTaskInput<B, E> input) : super(input);

  @override
  void _addResultElement(B baseElement, E resultElement) {
    _resultValue.add(resultElement);
  }

  @override
  void _initResultValue() {
    _resultValue = <E>[];
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and the map of the base elements to the analysis results is used as the
 * input to the task.
 */
class ListToMapTaskInput<B, E>
    extends _ListToCollectionTaskInput<B, E, Map<B, E>>
    with MapTaskInputMixin<B, E> {
  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  ListToMapTaskInput(TaskInput<List<B>> baseAccessor,
      GenerateTaskInputs<B, E> generateTaskInputs)
      : super(baseAccessor, generateTaskInputs);

  @override
  TaskInputBuilder<Map<B, E>> createBuilder() =>
      new ListToMapTaskInputBuilder<B, E>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [ListToMapTaskInput].
 */
class ListToMapTaskInputBuilder<B, E>
    extends _ListToCollectionTaskInputBuilder<B, E, Map<B, E>> {
  /**
   * The map being built.
   */
  Map<B, E> _resultValue;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ListToMapTaskInputBuilder(ListToMapTaskInput<B, E> input) : super(input);

  @override
  void _addResultElement(B baseElement, E resultElement) {
    _resultValue[baseElement] = resultElement;
  }

  @override
  void _initResultValue() {
    _resultValue = new HashMap<B, E>();
  }
}

/**
 * A mixin-ready implementation of [MapTaskInput].
 */
abstract class MapTaskInputMixin<K, V> implements MapTaskInput<K, V> {
  TaskInput<List<E>> toFlattenList<E>(
      BinaryFunction<K, dynamic /*element of V*/, E> mapper) {
    return new MapToFlattenListTaskInput<K, dynamic /*element of V*/, E>(
        this as MapTaskInput<K, List /*element of V*/ >, mapper);
  }
}

/**
 * A [TaskInput] that is computed by the following steps.
 *
 * First the [base] task input is used to compute a [Map]-valued result.
 * The values of the [Map] must be [List]s.
 *
 * The given [mapper] is used to transform each key / value pair of the [Map]
 * into task inputs.
 *
 * Finally, each of the task inputs are used to access analysis results,
 * and the list of the results is used as the input.
 */
class MapToFlattenListTaskInput<K, V, E> extends TaskInputImpl<List<E>> {
  final MapTaskInput<K, List<V>> base;
  final BinaryFunction<K, V, E> mapper;

  MapToFlattenListTaskInput(this.base, this.mapper);

  @override
  TaskInputBuilder<List<E>> createBuilder() {
    return new MapToFlattenListTaskInputBuilder<K, V, E>(base, mapper);
  }
}

/**
 * The [TaskInputBuilder] for [MapToFlattenListTaskInput].
 */
class MapToFlattenListTaskInputBuilder<K, V, E>
    implements TaskInputBuilder<List<E>> {
  final MapTaskInput<K, List<V>> base;
  final BinaryFunction<K, V, E> mapper;

  TaskInputBuilder currentBuilder;
  Map<K, List<V>> baseMap;
  Iterator<K> keyIterator;
  Iterator<V> valueIterator;

  final List<E> inputValue = <E>[];

  MapToFlattenListTaskInputBuilder(this.base, this.mapper) {
    currentBuilder = base.createBuilder();
  }

  @override
  ResultDescriptor get currentResult {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentResult;
  }

  AnalysisTarget get currentTarget {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValue = value;
  }

  @override
  bool get flushOnAccess => currentBuilder.flushOnAccess;

  @override
  void currentValueNotAvailable() {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValueNotAvailable();
  }

  @override
  bool moveNext() {
    // Prepare base Map.
    if (baseMap == null) {
      if (currentBuilder.moveNext()) {
        return true;
      }
      baseMap = currentBuilder.inputValue as Map<K, List<V>>;
      if (baseMap == null) {
        // No base map could be computed due to a circular dependency.  Use an
        // empty map so that no further results will be computed.
        baseMap = {};
      }
      keyIterator = baseMap.keys.iterator;
      // Done with this builder.
      currentBuilder = null;
    }
    // Prepare the next result value.
    if (currentBuilder != null) {
      if (currentBuilder.moveNext()) {
        return true;
      }
      // Add the result value for the current Map key/value.
      E resultValue = currentBuilder.inputValue as E;
      if (resultValue != null) {
        inputValue.add(resultValue);
      }
      // Done with this builder.
      currentBuilder = null;
    }
    // Move to the next Map value.
    if (valueIterator != null && valueIterator.moveNext()) {
      K key = keyIterator.current;
      V value = valueIterator.current;
      currentBuilder = mapper(key, value).createBuilder();
      return moveNext();
    }
    // Move to the next Map key.
    if (keyIterator.moveNext()) {
      K key = keyIterator.current;
      valueIterator = baseMap[key].iterator;
      return moveNext();
    }
    // No more Map values/keys to transform.
    return false;
  }
}

/**
 * An input to an [AnalysisTask] that is computed by mapping the value of
 * another task input to a list of values.
 */
class ObjectToListTaskInput<E> extends TaskInputImpl<List<E>>
    with ListTaskInputMixin<E>
    implements ListTaskInput<E> {
  // TODO(brianwilkerson) Add another type parameter to this class that can be
  // used as the type of the keys of [mapper].
  /**
   * The input used to compute the value to be mapped.
   */
  final TaskInput baseInput;

  /**
   * The function used to map the value of the base input to the list of values.
   */
  final Mapper<Object, List<E>> mapper;

  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [baseInput] associated with the given [mapper].
   */
  ObjectToListTaskInput(this.baseInput, this.mapper);

  @override
  TaskInputBuilder<List<E>> createBuilder() =>
      new ObjectToListTaskInputBuilder<E>(this);

  @override
  ListTaskInput<V> toFlattenListOf<V>(ListResultDescriptor<V> subListResult) {
    return new ListToFlattenListTaskInput<E, V>(
        this,
        (E element) =>
            subListResult.of(element as AnalysisTarget) as TaskInput<V>);
  }

  @override
  ListTaskInput<V> toListOf<V>(ResultDescriptor<V> valueResult) {
    return new ListToListTaskInput<E, V>(
        this, (E element) => valueResult.of(element as AnalysisTarget));
  }

  @override
  MapTaskInput<AnalysisTarget, V> toMapOf<V>(ResultDescriptor<V> valueResult) {
    return new ListToMapTaskInput<AnalysisTarget, V>(
        this as TaskInput<List<AnalysisTarget>>, valueResult.of);
  }
}

/**
 * A [TaskInputBuilder] used to build an input based on a [SimpleTaskInput].
 */
class ObjectToListTaskInputBuilder<E> implements TaskInputBuilder<List<E>> {
  /**
   * The input being built.
   */
  final ObjectToListTaskInput<E> input;

  /**
   * The builder created by the input.
   */
  TaskInputBuilder builder;

  /**
   * The value of the input being built, or `null` if the value hasn't been set
   * yet or if no result is available ([currentValueNotAvailable] was called).
   */
  List<E> _inputValue = null;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  ObjectToListTaskInputBuilder(this.input) {
    builder = input.baseInput.createBuilder();
  }

  @override
  ResultDescriptor get currentResult {
    if (builder == null) {
      return null;
    }
    return builder.currentResult;
  }

  @override
  AnalysisTarget get currentTarget {
    if (builder == null) {
      return null;
    }
    return builder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (builder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    builder.currentValue = value;
  }

  @override
  bool get flushOnAccess => builder.flushOnAccess;

  @override
  List<E> get inputValue {
    if (builder != null) {
      throw new StateError('Result value has not been created');
    }
    return _inputValue;
  }

  @override
  void currentValueNotAvailable() {
    if (builder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    builder.currentValueNotAvailable();
  }

  @override
  bool moveNext() {
    if (builder == null) {
      return false;
    } else if (builder.moveNext()) {
      return true;
    } else {
      // This might not be the right semantics. If the value could not be
      // computed then we pass the resulting `null` in to the mapper function.
      // Unfortunately, we cannot tell the difference between a `null` that's
      // there because no value could be computed and a `null` that's there
      // because that's what *was* computed.
      _inputValue = input.mapper(builder.inputValue);
      builder = null;
      return false;
    }
  }
}

/**
 * An input to an [AnalysisTask] that is computed by accessing a single result
 * defined on a single target.
 */
class SimpleTaskInput<V> extends TaskInputImpl<V> {
  /**
   * The target on which the result is defined.
   */
  final AnalysisTarget target;

  /**
   * The result to be accessed.
   */
  final ResultDescriptor<V> result;

  /**
   * Return `true` if the value accessed by this input builder should be flushed
   * from the cache at the time it is retrieved.
   */
  final bool flushOnAccess;

  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [result] associated with the given [target].
   */
  SimpleTaskInput(this.target, this.result, {this.flushOnAccess: false});

  /**
   * Initialize a newly created task input that computes the input by accessing
   * the given [result] associated with the given [target].
   */
  SimpleTaskInput._unflushable(this.target, this.result)
      : flushOnAccess = false;

  @override
  TaskInputBuilder<V> createBuilder() => new SimpleTaskInputBuilder<V>(this);
}

/**
 * A [TaskInputBuilder] used to build an input based on a [SimpleTaskInput].
 */
class SimpleTaskInputBuilder<V> implements TaskInputBuilder<V> {
  /**
   * The state value indicating that the builder is positioned before the single
   * result.
   */
  static const _BEFORE = -1;

  /**
   * The state value indicating that the builder is positioned at the single
   * result.
   */
  static const _AT = 0;

  /**
   * The state value indicating that the builder is positioned after the single
   * result.
   */
  static const _AFTER = 1;

  /**
   * The input being built.
   */
  final SimpleTaskInput<V> input;

  /**
   * The value of the input being built.  `null` if the value hasn't been set
   * yet, or if no result is available ([currentValueNotAvailable] was called).
   */
  V _resultValue = null;

  /**
   * The state of the builder.
   */
  int _state = _BEFORE;

  /**
   * A flag indicating whether the result value was explicitly set.
   */
  bool _resultSet = false;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  SimpleTaskInputBuilder(this.input);

  @override
  ResultDescriptor get currentResult => _state == _AT ? input.result : null;

  @override
  AnalysisTarget get currentTarget => _state == _AT ? input.target : null;

  @override
  void set currentValue(Object value) {
    if (_state != _AT) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    if (value is! V) {
      throw new StateError(
          'Cannot build $input: computed ${value.runtimeType}, needed $V');
    }
    _resultValue = value as V;
    _resultSet = true;
  }

  @override
  bool get flushOnAccess => input.flushOnAccess;

  @override
  V get inputValue {
    if (_state != _AFTER) {
      throw new StateError('Result value has not been created');
    }
    return _resultValue;
  }

  @override
  void currentValueNotAvailable() {
    if (_state != _AT) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    _resultValue = null;
    _resultSet = true;
  }

  @override
  bool moveNext() {
    if (_state == _BEFORE) {
      _state = _AT;
      return true;
    } else {
      if (!_resultSet) {
        throw new StateError(
            'The value of the current result must be set before moving to the next result.');
      }
      _state = _AFTER;
      return false;
    }
  }
}

abstract class TaskInputImpl<V> implements TaskInput<V> {
  @override
  ListTaskInput<E> mappedToList<E>(List<E> mapper(V value)) {
    return new ObjectToListTaskInput(
        this, (Object element) => mapper(element as V));
  }
}

/**
 * A [TaskInputBuilder] used to build an input based on one or more other task
 * inputs. The task inputs to be built are specified by a table mapping the name
 * of the input to the task used to access the input's value.
 */
class TopLevelTaskInputBuilder
    implements TaskInputBuilder<Map<String, Object>> {
  /**
   * The descriptors describing the inputs to be built.
   */
  final Map<String, TaskInput> inputDescriptors;

  /**
   * The names of the inputs. There are the keys from the [inputDescriptors] in
   * an indexable form.
   */
  List<String> inputNames;

  /**
   * The index of the input name associated with the current result and target.
   */
  int nameIndex = -1;

  /**
   * The builder used to build the current result.
   */
  TaskInputBuilder currentBuilder;

  /**
   * The inputs that are being or have been built. The map will be incomplete
   * unless the method [moveNext] returns `false`.
   */
  final Map<String, Object> inputs = new HashMap<String, Object>();

  /**
   * Initialize a newly created task input builder to build the inputs described
   * by the given [inputDescriptors].
   */
  TopLevelTaskInputBuilder(this.inputDescriptors) {
    inputNames = inputDescriptors.keys.toList();
  }

  @override
  ResultDescriptor get currentResult {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentResult;
  }

  @override
  AnalysisTarget get currentTarget {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValue = value;
  }

  @override
  bool get flushOnAccess => currentBuilder.flushOnAccess;

  @override
  Map<String, Object> get inputValue {
    if (nameIndex < inputNames.length) {
      throw new StateError('Result value has not been created');
    }
    return inputs;
  }

  /**
   * Assuming that there is a current input, return its name.
   */
  String get _currentName => inputNames[nameIndex];

  @override
  void currentValueNotAvailable() {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValueNotAvailable();
  }

  @override
  bool moveNext() {
    if (nameIndex >= inputNames.length) {
      // We have already computed all of the results, so just return false.
      return false;
    }
    if (nameIndex < 0) {
      // This is the first time moveNext has been invoked, so we just determine
      // whether there are any results to be computed.
      nameIndex = 0;
    } else {
      if (currentBuilder.moveNext()) {
        // We are still working on building the value associated with the
        // current name.
        return true;
      }
      if (currentBuilder.inputValue != null) {
        inputs[_currentName] = currentBuilder.inputValue;
      }
      nameIndex++;
    }
    if (nameIndex >= inputNames.length) {
      // There is no next value, so we're done.
      return false;
    }
    currentBuilder = inputDescriptors[_currentName].createBuilder();
    while (!currentBuilder.moveNext()) {
      if (currentBuilder.inputValue != null) {
        inputs[_currentName] = currentBuilder.inputValue;
      }
      nameIndex++;
      if (nameIndex >= inputNames.length) {
        // There is no next value, so we're done.
        return false;
      }
      currentBuilder = inputDescriptors[_currentName].createBuilder();
    }
    return true;
  }
}

/**
 * An input to an [AnalysisTask] that is computed by the following steps. First
 * another (base) task input is used to compute a [List]-valued result. An input
 * generator function is then used to map each element of that list to a task
 * input. Finally, each of the task inputs are used to access analysis results,
 * and a collection of the analysis results is used as the input to the task.
 */
abstract class _ListToCollectionTaskInput<B, E, C> extends TaskInputImpl<C> {
  /**
   * The accessor used to access the list of elements being mapped.
   */
  final TaskInput<List<B>> baseAccessor;

  /**
   * The function used to convert an element in the list returned by the
   * [baseAccessor] to a task input.
   */
  final GenerateTaskInputs<B, E> generateTaskInputs;

  /**
   * Initialize a result accessor to use the given [baseAccessor] to access a
   * list of values that can be passed to the given [generateTaskInputs] to
   * generate a list of task inputs that can be used to access the elements of
   * the input being accessed.
   */
  _ListToCollectionTaskInput(this.baseAccessor, this.generateTaskInputs);
}

/**
 * A [TaskInputBuilder] used to build an [_ListToCollectionTaskInput].
 */
abstract class _ListToCollectionTaskInputBuilder<B, E, C>
    implements TaskInputBuilder<C> {
  /**
   * The input being built.
   */
  final _ListToCollectionTaskInput<B, E, C> input;

  /**
   * The builder used to build the current result.
   */
  TaskInputBuilder currentBuilder;

  /**
   * The list of values computed by the [input]'s base accessor.
   */
  List<B> _baseList = null;

  /**
   * The index in the [_baseList] of the value for which a value is currently
   * being built.
   */
  int _baseListIndex = -1;

  /**
   * The element of the [_baseList] for which a value is currently being built.
   */
  B _baseListElement;

  /**
   * Initialize a newly created task input builder that computes the result
   * specified by the given [input].
   */
  _ListToCollectionTaskInputBuilder(this.input);

  @override
  ResultDescriptor get currentResult {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentResult;
  }

  @override
  AnalysisTarget get currentTarget {
    if (currentBuilder == null) {
      return null;
    }
    return currentBuilder.currentTarget;
  }

  @override
  void set currentValue(Object value) {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValue = value;
  }

  @override
  bool get flushOnAccess => currentBuilder.flushOnAccess;

  @override
  C get inputValue {
    if (currentBuilder != null || _resultValue == null) {
      throw new StateError('Result value has not been created');
    }
    return _resultValue;
  }

  /**
   * The list of values being built.
   */
  C get _resultValue;

  @override
  void currentValueNotAvailable() {
    if (currentBuilder == null) {
      throw new StateError(
          'Cannot set the result value when there is no current result');
    }
    currentBuilder.currentValueNotAvailable();
  }

  @override
  bool moveNext() {
    if (currentBuilder == null) {
      if (_resultValue == null) {
        // This is the first time moveNext has been invoked, so start by
        // computing the list of values from which the results will be derived.
        currentBuilder = input.baseAccessor.createBuilder();
        return currentBuilder.moveNext();
      } else {
        // We have already computed all of the results, so just return false.
        return false;
      }
    }
    if (currentBuilder.moveNext()) {
      return true;
    }
    if (_resultValue == null) {
      // We have finished computing the list of values from which the results
      // will be derived.
      _baseList = currentBuilder.inputValue as List<B>;
      if (_baseList == null) {
        // No base list could be computed due to a circular dependency.  Use an
        // empty list so that no further results will be computed.
        _baseList = [];
      }
      _baseListIndex = 0;
      _initResultValue();
    } else {
      // We have finished computing one of the elements in the result list.
      if (currentBuilder.inputValue != null) {
        _addResultElement(_baseListElement, currentBuilder.inputValue as E);
      }
      _baseListIndex++;
    }
    if (_baseListIndex >= _baseList.length) {
      currentBuilder = null;
      return false;
    }
    _baseListElement = _baseList[_baseListIndex];
    currentBuilder = input.generateTaskInputs(_baseListElement).createBuilder();
    return currentBuilder.moveNext();
  }

  void _addResultElement(B baseElement, E resultElement);
  void _initResultValue();
}
