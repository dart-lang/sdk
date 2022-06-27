// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/percentile_calculator.dart';

/// Data about the notifications that have been handled that have the same
/// method.
class NotificationData {
  /// The name of the notifications.
  final String method;

  /// The percentile calculator for latency times. The _latency time_ is the
  /// time from when the client sent the request until the time the server
  /// started processing the request.
  final PercentileCalculator latencyTimes = PercentileCalculator();

  /// The percentile calculator for handling times. The _handling time_ is the
  /// time from when the server started processing the notification until the
  /// handling was complete.
  final PercentileCalculator handlingTimes = PercentileCalculator();

  /// Initialize a newly create data holder for notifications with the given
  /// [method].
  NotificationData(this.method);
}
