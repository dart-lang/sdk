// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import '../server.dart';

/// With synchronous execution the nesting between spans is naturally induced
/// by the callstack. Consider:
///
/// ```dart
/// Timeline.timeSync('a', () {
///   work();
///   Timeline.timeSync('b', () {
///     work();
///   });
///   work();
///   Timeline.timeSync('c', () {
///     work();
///   });
///   work();
/// })
/// ```
//
/// This will created three spans `a`, `b` and `c` all properly nested. The time
/// outside of `b` and `c` will be correctly attributed to `a`.
//
/// However the same is not easy to achieve for async computations. Compare:
///
/// ```
/// void a() async {
///   work();
///   await b();
///   work();
///   await c();
///   work();
/// }
/// ```
//
/// There is no functionality available in `dart:developer` which would allow
/// to create proper span structure to automatically accurately capture the
/// work done in `a`, `b` and `c`. The best you can do is to manually wrap
/// synchronous parts of work into `timeSync`.
///
/// This class tries to help with this by creating a `Zone` which automatically
/// does this - though result still might be confusing: completion of async task
/// causes resumption of async task that awaits on the current task which creates
/// inversely nested spans (e.g. if `b` is suspended and completes
/// asynchronously you get span `a` nested inside span `b` - even though you
/// would like an opposite picture or worst case you want these spans to be
/// siblings).
///
/// Wrapping execution in a `Zone` is expensive so we only enable it if
/// recorder requests it explicitly. When disabled we only emit timeline
/// spans for the first synchronous portion of the computation and then
/// a instantaneous span for the completion. This allows developer to
/// estimate how long asynchronous action took - but it will not actually
/// reveal when it was actively running on the stack.
class AsyncSpan {
  final String name;
  final Map<String, Object?>? parameters;
  final Flow _flow = Flow.begin();
  bool issuedBegin = false;
  int running = 0;

  AsyncSpan._(this.name, {this.parameters});

  static AsyncSpan of(Zone zone) => zone[AsyncSpan] as AsyncSpan;

  static final _zoneSpecification = ZoneSpecification(
    run: <R>(self, parent, zone, R Function() f) {
      final span = AsyncSpan.of(self);

      span.startSync();
      try {
        return parent.run(zone, f);
      } finally {
        span.finishSync();
      }
    },
    runUnary: <R, T1>(self, parent, zone, R Function(T1) f, T1 a1) {
      final span = AsyncSpan.of(self);
      span.startSync();
      try {
        return parent.runUnary(zone, f, a1);
      } finally {
        span.finishSync();
      }
    },
    runBinary:
        <R, T1, T2>(self, parent, zone, R Function(T1, T2) f, T1 a1, T2 a2) {
          final span = AsyncSpan.of(self);
          span.startSync();
          try {
            return parent.runBinary(zone, f, a1, a2);
          } finally {
            span.finishSync();
          }
        },
  );

  static Future<R> run<R>(
    String name,
    Future<R> Function() action, {
    Map<String, Object?>? parameters,
  }) async {
    if (PerfWitnessServer.isRecordingTimelineWithAsyncSpans) {
      return AsyncSpan._create(name, parameters: parameters).run(action);
    } else {
      final Future<R> result;
      final flow = Flow.begin();
      try {
        Timeline.startSync(name, flow: flow);
        result = action();
      } finally {
        Timeline.finishSync();
      }

      try {
        return await result;
      } finally {
        Timeline.startSync(name, flow: Flow.end(flow.id));
        Timeline.finishSync();
      }
    }
  }

  static Future<R> runUnary<R, T>(
    String name,
    Future<R> Function(T) action,
    T arg, {
    Map<String, Object?>? parameters,
  }) async {
    if (PerfWitnessServer.isRecordingTimelineWithAsyncSpans) {
      return AsyncSpan._create(
        name,
        parameters: parameters,
      ).runUnary(action, arg);
    } else {
      final Future<R> result;
      final flow = Flow.begin();
      try {
        Timeline.startSync(name, flow: flow);
        result = action(arg);
      } finally {
        Timeline.finishSync();
      }

      try {
        return await result;
      } finally {
        Timeline.startSync(name, flow: Flow.end(flow.id));
        Timeline.finishSync();
      }
    }
  }

  static Zone _create(String name, {Map<String, Object?>? parameters}) =>
      Zone.current.fork(
        specification: _zoneSpecification,
        zoneValues: {AsyncSpan: AsyncSpan._(name, parameters: parameters)},
      );

  void startSync() {
    if (running == 0) {
      Timeline.startSync(
        name,
        flow: issuedBegin ? Flow.step(_flow.id) : _flow,
        arguments: issuedBegin ? null : parameters,
      );
      issuedBegin = true;
    }
    running++;
  }

  void finishSync() {
    if (--running == 0) {
      Timeline.finishSync();
    }
  }
}
