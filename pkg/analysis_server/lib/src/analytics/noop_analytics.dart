// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dash_analytics/dash_analytics.dart';
import 'package:dash_analytics/src/config_handler.dart';
import 'package:http/src/response.dart';

/// An implementation of [Analytics] that's appropriate to use when running
/// tests.
// TODO(brianwilkerson) Remove this class when it's easier to create a test
//  version of the `Analytics` class.
class NoopAnalytics implements Analytics {
  @override
  Map<String, ToolInfo> get parsedTools => throw UnimplementedError();

  @override
  bool get shouldShowMessage => false;

  @override
  bool get telemetryEnabled => false;

  @override
  String get toolsMessage => throw UnimplementedError();

  @override
  Map<String, Map<String, Object?>> get userPropertyMap =>
      throw UnimplementedError();

  @override
  void close() {
    // Ignored
  }

  @override
  LogFileStats? logFileStats() {
    throw UnimplementedError();
  }

  @override
  Future<Response>? sendEvent(
      {required DashEvent eventName,
      Map<String, Object?> eventData = const {}}) {
    // Ignored
    return null;
  }

  @override
  Future<void> setTelemetry(bool reportingBool) {
    throw UnimplementedError();
  }
}
