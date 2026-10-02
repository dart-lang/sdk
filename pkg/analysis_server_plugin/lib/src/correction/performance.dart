// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/src/utilities/string_extensions.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:meta/meta.dart';

/// Timing information for a (correction) producer's call to `compute()`.
typedef ProducerTiming = ({
  /// The producer class name.
  String className,

  /// The time elapsed during `compute()`.
  int elapsedTime,
});

abstract class ProducerRequestPerformance extends RequestPerformance {
  final String path;

  final String snippet;
  final List<ProducerTiming> producerTimings;

  ProducerRequestPerformance({
    required super.operation,
    required this.path,
    required super.performance,
    super.requestLatency,
    super.startTime,
    required String content,
    required int offset,
    required this.producerTimings,
  }) : snippet = content.withCaretAt(offset);

  int get elapsedInMilliseconds => performance.elapsed.inMilliseconds;
}

class RequestPerformance {
  static var _nextId = 1;
  final int id;
  final OperationPerformance performance;
  final int? requestLatency;
  final String operation;
  final DateTime? startTime;

  /// Additional timings for this request.
  ///
  /// This [RequestPerformanceAdditionalTimings] is captured for the current
  /// zone from zoneValues when this instance is created.
  final RequestPerformanceAdditionalTimings? additionalTimings =
      RequestPerformanceAdditionalTimings.current;

  RequestPerformance({
    required this.operation,
    required this.performance,
    this.requestLatency,
    this.startTime,
  }) : id = _nextId++;
}

enum RequestPerformanceAdditionalTimingKind { analysis }

/// Additional timings captured during a request (stored in
/// [RequestPerformance]) that can be accessed via zoneValues from anywhere.
class RequestPerformanceAdditionalTimings {
  static const zoneValueKey = 'RequestPerformanceAdditionalTimings';

  static RequestPerformanceAdditionalTimings? get current =>
      Zone.current[zoneValueKey] as RequestPerformanceAdditionalTimings?;

  /// A map containing [Stopwatch]es that are stopped/started when the stack
  /// size for a given action changes from 0 to 1 or 1 to 0.
  @visibleForTesting
  final Map<RequestPerformanceAdditionalTimingKind, Stopwatch> timings = {};

  /// The stack sizes of each action to support overlapping async calls without
  /// double-counting time.
  final Map<RequestPerformanceAdditionalTimingKind, int> _stackSize = {};

  Map<String, int>? _timingsInMilliseconds;

  /// The current timings in milliseconds, keyed by the name of the kind.
  ///
  /// Only non-zero values are included.
  Map<String, int> get timingsInMilliseconds =>
      _timingsInMilliseconds ??= timings.map(
        (kind, stopwatch) => MapEntry(kind.name, stopwatch.elapsedMilliseconds),
      )..removeWhere((_, value) => value == 0);

  /// Total time recorded for additional timings.
  int get totalTime => timings.values.fold(
    0,
    (acc, stopwatch) => acc + stopwatch.elapsedMilliseconds,
  );

  void popAnalysis() => _pop(RequestPerformanceAdditionalTimingKind.analysis);
  void pushAnalysis() => _push(RequestPerformanceAdditionalTimingKind.analysis);

  /// Pops an operation off the stack for timing.
  ///
  /// We keep track of the number of active timings so that concurrent calls
  /// (from the same message, since each message runs in its own Zone and has
  /// its own instance of this class) are combined without double-counting.
  ///
  /// Only on transitions from 1->0 do we stop timing, and only on transitions
  /// from 0->1 in [_push] do we start.
  void _pop(RequestPerformanceAdditionalTimingKind kind) {
    assert(_stackSize.containsKey(kind));
    _timingsInMilliseconds = null; // Wipe cached timings
    var newCount = _stackSize.update(
      kind,
      (size) => size - 1,
      ifAbsent: () => 0,
    );
    if (newCount == 0) {
      timings[kind]?.stop();
    }
  }

  /// Pushes an operation onto the stack for timing.
  ///
  /// We keep track of the number of active timings so that concurrent calls
  /// (from the same message, since each message runs in its own Zone and has
  /// its own instance of this class) are combined without double-counting.
  ///
  /// Only on transitions from 0->1 do we start timing, and only on transitions
  /// from 1->0 in [_pop] do we stop.
  void _push(RequestPerformanceAdditionalTimingKind kind) {
    _timingsInMilliseconds = null; // Wipe cached timings
    var newCount = _stackSize.update(
      kind,
      (size) => size + 1,
      ifAbsent: () => 1,
    );
    if (newCount == 1) {
      timings.putIfAbsent(kind, Stopwatch.new).start();
    }
  }
}
