// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Measurements collected about individual functions.  Currently we compute
/// data about "sends", to classify whether we know the target or not.
library dart2js_info.src.measurements;

/// Top-level set of metrics
const List<Metric> _topLevelMetrics = const [Metric.functions, Metric.send];

/// Apply `f` on each metric in DFS order on the metric tree. [Metric.functions]
/// and [Metric.send] are the top level metrics. See those declarations for
/// details on the subtrees.
visitAllMetrics(f) {
  var parentsStack = [];
  helper(Metric m) {
    f(m, parentsStack);
    if (m is GroupedMetric) {
      parentsStack.add(m);
      m.submetrics.forEach(helper);
      parentsStack.removeLast();
    }
  }

  _topLevelMetrics.forEach(helper);
}

/// A metric we intend to measure.
class Metric {
  /// Name for the metric.
  final String name;

  const Metric(this.name);

  factory Metric.fromName(String name) => _nameToMetricMap[name];

  String toString() => name;

  /// Total functions in a library/package/program. Parent of
  /// [reachableFunction].
  static const Metric functions =
      const GroupedMetric('functions', const [reachableFunctions]);

  /// Subset of the functions that are reachable.
  static const Metric reachableFunctions = const Metric('reachable functions');

  /// Parent of all send metrics. We classify sends as follows:
  ///
  ///     sends
  ///       |- monomorphic
  ///       |  |- static (top-levels, statics)
  ///       |  |- super
  ///       |  |- local (access to a local var, call local function)
  ///       |  |- constructor (like factory ctros)
  ///       |  |- type variable (reading a type variable)
  ///       |  |- nsm (known no such method exception)
  ///       |  |- single-nsm-call (known no such method call, single target)
  ///       |  |- instance (non-interceptor, only one possible target)
  ///       |  '- interceptor (interceptor, known)
  ///       |
  ///       '- polymorphic
  ///          |- multi-nsm (known to be nSM, but not sure if error, or call, or
  ///                        which call)
  ///          |- virtual (traditional virtual call, polymorphic equivalent of
  ///          |           `instance`, no-interceptor)
  ///          |- multi-interceptor (1 of n possible interceptors)
  ///          '- dynamic (any combination of the above)
  ///
  static const Metric send =
      const GroupedMetric('send', const [monomorphicSend, polymorphicSend]);

  /// Parent of monomorphic sends, see [send] for details.
  static const Metric monomorphicSend =
      const GroupedMetric('monomorphic', const [
    staticSend,
    superSend,
    localSend,
    constructorSend,
    typeVariableSend,
    nsmErrorSend,
    singleNsmCallSend,
    instanceSend,
    interceptorSend
  ]);

  /// Metric for static calls, see [send] for details.
  static const Metric staticSend = const Metric('static');

  /// Metric for super calls, see [send] for details.
  static const Metric superSend = const Metric('super');

  /// Metric for local variable sends, see [send] for details.
  static const Metric localSend = const Metric('local');

  /// Metric for constructor sends, see [send] for details.
  static const Metric constructorSend = const Metric('constructor');

  /// Metric for type-variable sends, see [send] for details.
  // TODO(sigmund): delete? is mainly associated with compile-time errors
  static const Metric typeVariableSend = const Metric('type variable');

  /// Metric for no-such-method errors, see [send] for details.
  static const Metric nsmErrorSend = const Metric('nSM error');

  /// Metric for calls to noSuchMethod methods with a known target, see [send]
  /// for details.
  static const Metric singleNsmCallSend = const Metric('nSM call single');

  /// Metric for calls to a precisely known instance method, see [send] for
  /// details.
  static const Metric instanceSend = const Metric('instance');

  /// Metric for calls to a precisely known interceptor method, see [send] for
  /// details.
  static const Metric interceptorSend = const Metric('interceptor');

  /// Parent of polymorphic sends, see [send] for details.
  static const Metric polymorphicSend = const GroupedMetric('polymorphic',
      const [multiNsmCallSend, virtualSend, multiInterceptorSend, dynamicSend]);

  /// Metric for calls to noSuchMethod methods with more than one possible
  /// target, see [send] for details.
  static const Metric multiNsmCallSend = const Metric('nSM call multi');

  /// Metric for calls that are dispatched virtually ar runtime, see [send] for
  /// details.
  static const Metric virtualSend = const Metric('virtual');

  /// Metyric for calls to more than one possible interceptor, see [send] for
  /// details.
  static const Metric multiInterceptorSend = const Metric('interceptor multi');

  /// Metyric for dynamic calls for which we know nothing about the target
  /// method. See [send] for details.
  static const Metric dynamicSend = const Metric('dynamic');

  static Map<String, Metric> _nameToMetricMap = () {
    var res = <String, Metric>{};
    visitAllMetrics((m, _) => res[m.name] = m);
    return res;
  }();
}

/// A metric that is subdivided in smaller metrics.
class GroupedMetric extends Metric {
  final List<Metric> submetrics;

  const GroupedMetric(String name, this.submetrics) : super(name);
}

/// A measurement entry (practically a source-span location where the
/// measurement was seen).
class Entry {
  final int begin;
  final int end;
  Entry(this.begin, this.end);
}

/// A collection of data points for each metric. Used to summarize a single
/// function, a library, a package, or an entire program.
class Measurements {
  final Uri uri;
  final Map<Metric, List<Entry>> entries;
  final Map<Metric, int> counters;

  Measurements([this.uri])
      : entries = <Metric, List<Entry>>{},
        counters = <Metric, int>{};

  const Measurements.unreachableFunction()
      : counters = const {Metric.functions: 1},
        entries = const {},
        uri = null;

  Measurements.reachableFunction([this.uri])
      : counters = {Metric.functions: 1, Metric.reachableFunctions: 1},
        entries = {};

  /// Record [metric] was seen. The optional [begin] and [end] offsets are
  /// included for metrics that correspond to a source range. Intended to be
  /// used by `StatsBuilder`.
  record(Metric metric, [int begin, int end]) {
    if (begin != null && end != null) {
      assert(uri != null);
      entries.putIfAbsent(metric, () => []).add(new Entry(begin, end));
    }
    counters.putIfAbsent(metric, () => 0);
    counters[metric]++;
  }

  /// Removes a previously added entry. Intended only to be used by
  /// `StatsBuilder`. Internally `StatsBuilder` computes redundant information
  /// in order to check for coverage and validate invariants with
  /// [checkInvariant]. This is used to adjust some of the redundant
  /// information.
  popLast(Metric metric) {
    assert(entries[metric] != null && entries[metric].isNotEmpty);
    entries[metric].removeLast();
    counters[metric]--;
  }

  /// Add the counters from [other] into this set of measurements.
  addFrom(Measurements other) {
    other.counters.forEach((metric, value) {
      var current = counters[metric];
      counters[metric] = current == null ? value : current + value;
    });
  }

  /// Check that every grouped metric totals the individual counts of it's
  /// submetric.
  bool checkInvariant(GroupedMetric key) {
    int total = counters[key] ?? 0;
    int submetricTotal = 0;
    for (var metric in key.submetrics) {
      var n = counters[metric];
      if (n != null) submetricTotal += n;
    }
    return total == submetricTotal;
  }
}
