// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/performance/operation_performance.dart';

class RequestPerformance {
  static var _nextId = 1;
  final int id;
  final OperationPerformance performance;
  final int? requestLatency;
  final String operation;

  RequestPerformance({
    required this.operation,
    required this.performance,
    this.requestLatency,
  }) : id = _nextId++;
}
