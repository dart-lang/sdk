// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// A UserTag can be used to group samples in the Observatory profiler.
abstract class UserTag {
  /// The maximum number of UserTag instances that can be created by a program.
  static const MAX_USER_TAGS = 64;

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
      throw new ArgumentError('Invalid Metric name.');
    }
  }

  Map _toJSON();
}

/// A measured value with a min and max. Initial value is min. Value will
/// be clamped to the interval [min, max].
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
      : super(name, description) {
    if (min is! double) {
      throw new ArgumentError('min must be a double');
    }
    if (max is! double) {
      throw new ArgumentError('max must be a double');
    }
    if (!(min < max)) {
      throw new ArgumentError('min must be less than max');
    }
    _value = min;
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

class Metrics {
  static final Map<String, Metric> _metrics = new Map<String, Metric>();

  /// Register [Metric]s to make them visible to Observatory.
  static void register(Metric metric) {
    if (metric is! Metric) {
      throw new ArgumentError('metric must be a Metric');
    }
    if (_metrics[metric.name] != null) {
      throw new ArgumentError('Registered metrics have unique names');
    }
    _metrics[metric.name] = metric;
  }

  /// Deregister [Metric]s to make them not visible to Observatory.
  static void deregister(Metric metric) {
    if (metric is! Metric) {
      throw new ArgumentError('metric must be a Metric');
    }
    _metrics.remove(metric.name);
  }

  static String _printMetric(String id) {
    var metric = _metrics[id];
    if (metric == null) {
      return null;
    }
    return JSON.encode(metric._toJSON());
  }

  static String _printMetrics() {
    var metrics = [];
    for (var metric in _metrics.values) {
      metrics.add(metric._toJSON());
    }
    var map = {
      'type': 'MetricList',
      'metrics': metrics,
    };
    return JSON.encode(map);
  }
}
