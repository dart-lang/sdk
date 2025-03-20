// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/utilities/string_extensions.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

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
    // TODO(srawlins): This should probably be used in the super call?
    // ignore: avoid_unused_constructor_parameters
    required String operation,
    required this.path,
    required super.performance,
    super.requestLatency,
    super.startTime,
    required String content,
    required int offset,
    required this.producerTimings,
  })  : snippet = content.withCaretAt(offset),
        super(operation: 'GetAssists');

  int get elapsedInMilliseconds => performance.elapsed.inMilliseconds;
}

class RequestPerformance {
  static var _nextId = 1;
  final int id;
  final OperationPerformance performance;
  final int? requestLatency;
  final String operation;
  final DateTime? startTime;

  RequestPerformance({
    required this.operation,
    required this.performance,
    this.requestLatency,
    this.startTime,
  }) : id = _nextId++;
}
