// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/performance.dart';

/// Overall performance of a request for quick fixes operation.
class GetFixesPerformance extends ProducerRequestPerformance {
  GetFixesPerformance({
    required super.performance,
    required super.path,
    super.requestLatency,
    required super.content,
    required super.offset,
    required super.producerTimings,
  }) : super(operation: 'GetFixes');
}
