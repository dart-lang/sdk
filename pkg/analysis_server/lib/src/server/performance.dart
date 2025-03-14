// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

abstract class ProducerRequestPerformance extends RequestPerformance {
  final String path;

  final String snippet;
  final List<ProducerTiming> producerTimings;
  ProducerRequestPerformance({
    required String operation,
    required this.path,
    required super.performance,
    super.requestLatency,
    super.startTime,
    required String content,
    required int offset,
    required this.producerTimings,
  }) : snippet = addCaretAtOffset(content, offset),
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
