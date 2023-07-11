// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/src/response.dart';
import 'package:unified_analytics/unified_analytics.dart';

/// An implementation of [Analytics] that's appropriate to use when analytics
/// will be disabled for the current session, including tests.
class NoopAnalytics implements Analytics {
  @override
  String get getConsentMessage => throw UnimplementedError();

  @override
  bool get okToSend => false;

  @override
  Map<String, ToolInfo> get parsedTools => throw UnimplementedError();

  @override
  bool get shouldShowMessage => false;

  @override
  bool get telemetryEnabled => false;

  @override
  Map<String, Map<String, Object?>> get userPropertyMap =>
      throw UnimplementedError();

  @override
  void clientShowedMessage() {
    // Ignored
  }

  @override
  void close() {
    // Ignored
  }

  @override
  LogFileStats? logFileStats() {
    throw UnimplementedError();
  }

  @override
  Future<Response>? send(Event event) {
    // Ignored
    return null;
  }

  @override
  Future<void> setTelemetry(bool reportingBool) {
    throw UnimplementedError();
  }
}
