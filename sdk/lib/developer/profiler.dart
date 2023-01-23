// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// A UserTag can be used to group samples in the
/// [DevTools CPU profiler](https://flutter.dev/docs/development/tools/devtools/cpu-profiler).
abstract class UserTag {
  /// The maximum number of UserTag instances that can be created by a program.
  static const maxUserTags = 64;

  @Deprecated("Use 'maxUserTags' instead. Will be removed in Dart 3.0.")
  // TODO(bkonyi): We shouldn't be using SCREAMING_CAPS for constants, so this
  // should be removed for Dart 3.0.
  static const MAX_USER_TAGS = maxUserTags;

  external factory UserTag(String label);

  /// Label of [this].
  String get label;

  /// Make [this] the current tag for the isolate. Returns the current tag
  /// before setting.
  UserTag makeCurrent();

  /// The default [UserTag] with label 'Default'.
  external static UserTag get defaultTag;
}

/// Returns the current [UserTag] for the isolate.
external UserTag getCurrentTag();

@Deprecated('Metrics are deprecated and will be removed in Dart 3.0')
/// Abstract [Metric] class. Metric names must be unique, are hierarchical,
/// and use periods as separators. For example, 'a.b.c'. Uniqueness is only
/// enforced when a Metric is registered. The name of a metric cannot contain
/// the slash ('/') character.
abstract class Metric {
  /// [name] of this metric.
  final String name;

  /// [description] of this metric.
  final String description;

  Metric(this.name, this.description) {
    if ((name == 'vm') || name.contains('/')) {
      throw ArgumentError('Invalid Metric name.');
    }
  }

  Map _toJSON();
}

@Deprecated('Metrics are deprecated and will be removed in Dart 3.0')
/// A measured value with a min and max. Initial value is min. Value will
/// be clamped to the interval `[min, max]`.
class Gauge extends Metric {
  final double min;
  final double max;

  double _value;
  double get value => _value;
  set value(double v) {
    if (v < min) {
      v = min;
    } else if (v > max) {
      v = max;
    }
    _value = v;
  }

  Gauge(String name, String description, this.min, this.max)
      : _value = min,
        super(name, description) {
    // TODO: When NNBD is complete, delete the following two lines.
    ArgumentError.checkNotNull(min, 'min');
    ArgumentError.checkNotNull(max, 'max');
    if (!(min < max)) throw ArgumentError('min must be less than max');
  }

  Map _toJSON() {
    var map = {
      'type': 'Gauge',
      'id': 'metrics/$name',
      'name': name,
      'description': description,
      'value': value,
      'min': min,
      'max': max,
    };
    return map;
  }
}

@Deprecated('Metrics are deprecated and will be removed in Dart 3.0')
/// A changing value. Initial value is 0.0.
class Counter extends Metric {
  Counter(String name, String description) : super(name, description);

  double _value = 0.0;
  double get value => _value;
  set value(double v) {
    _value = v;
  }

  Map _toJSON() {
    var map = {
      'type': 'Counter',
      'id': 'metrics/$name',
      'name': name,
      'description': description,
      'value': value,
    };
    return map;
  }
}

@Deprecated('Metrics are deprecated and will be removed in Dart 3.0')
/// Register and deregister custom [Metric]s to be displayed in developer
/// tooling.
class Metrics {
  /// The current set of registered [Metric]s.
  static UnmodifiableMapView<String, Metric> get current =>
      UnmodifiableMapView<String, Metric>(_metrics);
  static final _metrics = <String, Metric>{};

  /// Register [Metric]s to make them visible to developer tooling.
  static void register(Metric metric) {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(metric, 'metric');
    if (_metrics[metric.name] != null) {
      throw ArgumentError('Registered metrics have unique names');
    }
    _metrics[metric.name] = metric;
  }

  /// Deregister [Metric]s to make them not visible to developer tooling.
  static void deregister(Metric metric) {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(metric, 'metric');
    _metrics.remove(metric.name);
  }

  @pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
  static String? _printMetric(String id) {
    var metric = _metrics[id];
    if (metric == null) {
      return null;
    }
    return json.encode(metric._toJSON());
  }

  @pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
  static String _printMetrics() {
    var metrics = [];
    for (var metric in _metrics.values) {
      metrics.add(metric._toJSON());
    }
    var map = {
      'type': 'MetricList',
      'metrics': metrics,
    };
    return json.encode(map);
  }
}
