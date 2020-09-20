// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.metrics;

/// A collection of metrics that is normally associated with a task.
abstract class Metrics {
  /// The namespace prepended to all the metric names with a period (`.`).
  /// An empty string means no namespace.
  String get namespace;

  /// Returns all the primary metrics. Only a few metrics that give an overall
  /// picture of the compilation should be selected as primary metrics.
  Iterable<Metric> get primary;

  /// Returns all the secondary metrics. Typically these are displayed together
  /// with the primary metrics to give three levels of detail: no metrics, just
  /// the primary metrics, all metrics including primary and secondary metrics.
  Iterable<Metric> get secondary;

  factory Metrics.none() => _emptyMetrics;
}

final Metrics _emptyMetrics = MetricsBase();

class MetricsBase implements Metrics {
  @override
  String get namespace => '';

  // TODO(sra): Make these late final fields.
  List<Metric> _primary = [];
  List<Metric> _secondary = [];

  /// Setter method that is usually called in a subclass constructor to define
  /// the primary metrics.
  void set primary(Iterable<Metric> metrics) {
    assert(_primary.isEmpty);
    _primary.addAll(metrics);
  }

  /// Setter method that is usually called in a subclass constructor to define
  /// the secondary metrics.
  void set secondary(Iterable<Metric> metrics) {
    assert(_secondary.isEmpty);
    _secondary.addAll(metrics);
  }

  @override
  Iterable<Metric> get primary => _primary /*!*/;

  @override
  Iterable<Metric> get secondary => _secondary /*!*/;
}

abstract class Metric<T> {
  String get name;
  String formatValue();
}

class DurationMetric implements Metric<Duration> {
  @override
  final String name;
  Duration _duration = Duration.zero;

  DurationMetric(this.name);

  void add(Duration value) {
    _duration += value;
  }

  T measure<T>(T Function() action) {
    final stopwatch = Stopwatch()..start();
    T result = action();
    add(stopwatch.elapsed);
    return result;
  }

  @override
  String formatValue() {
    return (_duration.inMilliseconds / 1000).toStringAsFixed(3) + 's';
  }

  @override
  String toString() => 'DurationMetric("$name", $_duration)';
}

class CountMetric implements Metric<int> {
  @override
  final String name;
  int _count = 0;

  CountMetric(this.name);

  void add([int count = 1]) {
    _count += count;
  }

  @override
  String formatValue() => '$_count';

  @override
  String toString() => 'CountMetric("$name", $_count)';
}
