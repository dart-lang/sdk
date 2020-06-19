// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The performance of an operation.
abstract class CiderOperationPerformance {
  /// The children operation, might be empty.
  List<CiderOperationPerformance> get children;

  /// The duration of the operation itself and its children.
  Duration get elapsed;

  /// The duration of the operation itself.
  Duration get elapsedSelf;

  /// The name of the operation.
  String get name;

  CiderOperationPerformance getChild(String name);
}

class CiderOperationPerformanceFixed implements CiderOperationPerformance {
  @override
  final String name;

  @override
  final Duration elapsedSelf;

  CiderOperationPerformanceFixed(this.name, this.elapsedSelf);

  @override
  List<CiderOperationPerformance> get children => const [];

  @override
  Duration get elapsed => elapsedSelf;

  @override
  CiderOperationPerformance getChild(String name) {
    return null;
  }

  @override
  String toString() {
    return '(name: $name, elapsed: $elapsed)';
  }
}

class CiderOperationPerformanceImpl implements CiderOperationPerformance {
  @override
  final String name;

  final Stopwatch _timer = Stopwatch();
  final List<CiderOperationPerformance> _children = [];

  CiderOperationPerformanceImpl(this.name);

  @override
  List<CiderOperationPerformance> get children {
    return _children;
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

  /// Add a new child with the known elapsed time.
  ///
  /// This method is used when we already measure performance using some other
  /// mechanism, but want to add it to this performance hierarchy.
  void addChildFixed(String name, Duration elapsed) {
    _children.add(
      CiderOperationPerformanceFixed(name, elapsed),
    );
  }

  @override
  CiderOperationPerformance getChild(String name) {
    return children.firstWhere(
      (child) => child.name == name,
      orElse: () => null,
    );
  }

  /// Run the [operation] as a new child.
  T run<T>(
    String name,
    T Function(CiderOperationPerformanceImpl) operation,
  ) {
    var child = CiderOperationPerformanceImpl(name);
    _children.add(child);
    child._timer.start();

    try {
      return operation(child);
    } finally {
      child._timer.stop();
    }
  }

  /// Run the [operation] as a new child.
  Future<T> runAsync<T>(
    String name,
    Future<T> Function(CiderOperationPerformanceImpl) operation,
  ) async {
    var child = CiderOperationPerformanceImpl(name);
    _children.add(child);
    child._timer.start();

    try {
      return await operation(child);
    } finally {
      child._timer.stop();
    }
  }

  @override
  String toString() {
    return '(name: $name, elapsed: $elapsed, elapsedSelf: $elapsedSelf)';
  }
}
