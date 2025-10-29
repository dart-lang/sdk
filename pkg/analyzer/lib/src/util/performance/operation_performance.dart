// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

/// The performance of an operation.
abstract class OperationPerformance {
  /// The child operations, might be empty.
  List<OperationPerformance> get children;

  /// The number of times this child has been started/run.
  int get count;

  /// The data attachments, for non-timing data, e.g. how many files were read,
  /// or how many bytes were processed.
  List<OperationPerformanceData> get data;

  /// The duration of this operation, including its children.
  Duration get elapsed;

  /// The duration of this operation, excluding its children.
  Duration get elapsedSelf;

  /// The name of the operation.
  String get name;

  OperationPerformance? getChild(String name);

  Map<String, Object?> toJson();

  /// Write this operation and its children into the [buffer].
  void write({required StringBuffer buffer, String indent = ''});
}

/// The data attachment for an [OperationPerformance].
abstract class OperationPerformanceData<T> {
  String get name;

  T get value;
}

abstract class OperationPerformanceDataImpl<T>
    implements OperationPerformanceData<T> {
  @override
  final String name;

  OperationPerformanceDataImpl(this.name);

  @override
  String toString() {
    return '$name: $value';
  }
}

// Pre-existing name.
// ignore: camel_case_types
class OperationPerformanceDataImpl_int
    extends OperationPerformanceDataImpl<int> {
  @override
  int value = 0;

  OperationPerformanceDataImpl_int(super.name);

  void add(int item) {
    value += item;
  }

  void increment() {
    value++;
  }
}

// Pre-existing name.
// ignore: camel_case_types
class OperationPerformanceDataImpl_Set<T>
    extends OperationPerformanceDataImpl<Set<T>> {
  @override
  final Set<T> value = {};

  OperationPerformanceDataImpl_Set(super.name);

  void add(T item) {
    value.add(item);
  }

  @override
  String toString() {
    return '$name: ${value.length}';
  }
}

class OperationPerformanceImpl implements OperationPerformance {
  @override
  final String name;

  final Stopwatch _timer = Stopwatch();
  int _count = 0;
  final List<OperationPerformanceImpl> _children = [];

  final Map<String, OperationPerformanceData<Object>> _data = {};

  OperationPerformanceImpl(this.name);

  @override
  List<OperationPerformance> get children {
    return _children;
  }

  @override
  int get count => _count;

  @override
  List<OperationPerformanceData<Object>> get data {
    return _data.values.toList();
  }

  @override
  Duration get elapsed {
    return _timer.elapsed;
  }

  @override
  Duration get elapsedSelf {
    return elapsed - _elapsedChildren;
  }

  Duration get _elapsedChildren {
    return children.fold<Duration>(
      Duration.zero,
      (sum, child) => sum + child.elapsed,
    );
  }

  /// Collapse any children into this operation, making [elapsedSelf] equal
  /// to [elapsed].
  void collapse() {
    _children.clear();
  }

  @override
  OperationPerformanceImpl? getChild(String name) {
    return _children.firstWhereOrNull((child) => child.name == name);
  }

  OperationPerformanceDataImpl_int getDataInt(String name) {
    var data = _data[name];
    if (data is OperationPerformanceDataImpl_int) {
      return data;
    } else if (data != null) {
      throw StateError('Not int: ${data.runtimeType}');
    } else {
      return _data[name] = OperationPerformanceDataImpl_int(name);
    }
  }

  OperationPerformanceDataImpl_Set<T> getDataSet<T>(String name) {
    var data = _data[name];
    if (data is OperationPerformanceDataImpl_Set<T>) {
      return data;
    } else if (data != null) {
      throw StateError('Not Set: ${data.runtimeType}');
    } else {
      return _data[name] = OperationPerformanceDataImpl_Set<T>(name);
    }
  }

  /// Run the [operation] as a child with the given [name].
  ///
  /// If there is no such child, a new one is created, with a new timer.
  ///
  /// If there is already a child with that name, its timer will resume and
  /// then stop. So, it will accumulate time across all runs.
  T run<T>(
    String name,
    T Function(OperationPerformanceImpl performance) operation,
  ) {
    OperationPerformanceImpl child = _existingOrNewChild(name);
    child._start();

    try {
      return operation(child);
    } finally {
      child._stop();
    }
  }

  /// Run the [operation] as a child with the given [name].
  ///
  /// If there is no such child, a new one is created, with a new timer.
  ///
  /// If there is already a child with that name, its timer will resume and
  /// then stop. So, it will accumulate time across all runs.
  Future<T> runAsync<T>(
    String name,
    Future<T> Function(OperationPerformanceImpl performance) operation,
  ) async {
    var child = _existingOrNewChild(name);
    child._start();
    try {
      return await operation(child);
    } finally {
      child._stop();
    }
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'count': count,
      'elapsed': elapsed.inMicroseconds,
      'elapsedSelf': elapsedSelf.inMicroseconds,
      'children': children,
    };
  }

  @override
  String toString() {
    return '(name: $name, count: $_count, '
        'elapsed: $elapsed, elapsedSelf: $elapsedSelf)';
  }

  @override
  void write({required StringBuffer buffer, String indent = ''}) {
    buffer.write('$indent${toString()}');

    if (_data.isNotEmpty) {
      var sortedNames = _data.keys.toList()..sort();
      var sortedData = sortedNames.map((name) => _data[name]);
      var dataStr = sortedData.map((e) => '$e').join(', ');
      buffer.write('($dataStr)');
    }

    buffer.writeln();

    var childIndent = '$indent  ';
    for (var child in children) {
      child.write(buffer: buffer, indent: childIndent);
    }
  }

  OperationPerformanceImpl _existingOrNewChild(String name) {
    var child = getChild(name);
    if (child == null) {
      child = OperationPerformanceImpl(name);
      _children.add(child);
    }
    return child;
  }

  void _start() {
    _timer.start();
    _count++;
  }

  void _stop() {
    _timer.stop();
  }
}
