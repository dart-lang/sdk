// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.profiler;

import 'dart:convert';

/// A UserTag can be used to group samples in the Observatory profiler.
abstract class UserTag {
  /// The maximum number of UserTag instances that can be created by a program.
  static const MAX_USER_TAGS = 64;

  factory UserTag(String label) => new _FakeUserTag(label);

  /// Label of [this].
  String get label;

  /// Make [this] the current tag for the isolate. Returns the current tag
  /// before setting.
  UserTag makeCurrent();

  /// The default [UserTag] with label 'Default'.
  static UserTag get defaultTag => _FakeUserTag._defaultTag;
}

// This is a fake implementation of UserTag so that code can compile and run
// in dart2js.
class _FakeUserTag implements UserTag {
  static Map _instances = {};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.MAX_USER_TAGS) {
      throw new UnsupportedError(
          'UserTag instance limit (${UserTag.MAX_USER_TAGS}) reached.');
    }
    // Create a new instance and add it to the instance map.
    var instance = new _FakeUserTag.real(label);
    _instances[label] = instance;
    return instance;
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = new _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

/// Returns the current [UserTag] for the isolate.
UserTag getCurrentTag() {
  return _currentTag;
}

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
  Counter(String name, String description)
      : super(name, description);

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
    var members = [];
    for (var metric in _metrics.values) {
      members.add(metric._toJSON());
    }
    var map = {
      'type': 'MetricList',
      'id': 'metrics',
      'members': members,
    };
    return JSON.encode(map);
  }
}
