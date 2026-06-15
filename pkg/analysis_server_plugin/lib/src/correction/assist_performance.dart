// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A callback for recording assist request timings.
class AssistPerformance {
  final OperationPerformanceImpl? operationPerformance;
  Duration? computeTime;
  List<ProducerTiming> producerTimings = [];

  AssistPerformance([this.operationPerformance]);
}

/// Overall performance of a request for assists operation.
class GetAssistsPerformance extends ProducerRequestPerformance {
  GetAssistsPerformance({
    required super.performance,
    required super.path,
    super.requestLatency,
    required super.content,
    required super.offset,
    required super.producerTimings,
  }) : super(operation: 'GetAssists');
}
