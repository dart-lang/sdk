// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import 'constants.dart';
import 'dart_tooling_daemon.dart';
import 'response_types.dart';

/// Extension methods on the [DartToolingDaemon] that call the UnifiedAnalytics
/// service.
///
/// This library lives under src/ and is intentionally not exported from lib/.
/// First party Dash products that use this service should import this library
/// from src/ and add an analyzer ignore to supress the warning.
extension UnifiedAnalyticsExtension on DartToolingDaemon {
  /// Gets the Dart and Flutter unified analytics consent message to prompt
  /// users with on first run or when the message has been updated.
  Future<StringResponse> analyticsGetConsentMessage(DashTool tool) {
    return _callServiceWithStringResponse(tool, 'getConsentMessage');
  }

  /// Whether the unified analytics client should display the consent message.
  Future<BoolResponse> analyticsShouldShowConsentMessage(DashTool tool) {
    return _callServiceWithBoolResponse(tool, 'shouldShowMessage');
  }

  /// Method to be invoked by a Dart & Flutter unified analytics client to
  /// confirm that:
  /// * the client has shown the consent message
  /// * the [DashTool] [tool] can be added to the config file and start sending
  ///   events the next time it starts up.
  Future<Success> analyticsClientShowedMessage(DashTool tool) {
    return _callServiceWithSuccessResponse(tool, 'clientShowedMessage');
  }

  /// Whether the unified analytics telemetry is enabled.
  Future<BoolResponse> analyticsTelemetryEnabled(DashTool tool) {
    return _callServiceWithBoolResponse(tool, 'telemetryEnabled');
  }

  /// Sets the unified analytics telemetry to enabled or disabled based on the
  /// value of [enabled].
  ///
  /// [tool] is the [DashTool] making the request, but this method sets the
  /// unified analytics telemetry enabled state for all [DashTool]s.
  Future<Success> analyticsSetTelemetry(
    DashTool tool, {
    required bool enabled,
  }) {
    return _callServiceWithSuccessResponse(
      tool,
      'setTelemetry',
      additionalParams: {'enable': enabled},
    );
  }

  /// Sends an [event] to unified analytics for [tool].
  Future<Success> analyticsSend(DashTool tool, Event event) {
    return _callServiceWithSuccessResponse(
      tool,
      'send',
      additionalParams: {'event': event.toJson()},
    );
  }

  Future<Success> _callServiceWithSuccessResponse(
    DashTool tool,
    String methodName, {
    Map<String, Object> additionalParams = const {},
  }) async {
    return _callOnUnifiedAnalyticsService<Success>(
      tool,
      methodName,
      additionalParams: additionalParams,
      parseResponse: Success.fromDTDResponse,
    );
  }

  Future<BoolResponse> _callServiceWithBoolResponse(
    DashTool tool,
    String methodName, {
    Map<String, Object> additionalParams = const {},
  }) async {
    return _callOnUnifiedAnalyticsService<BoolResponse>(
      tool,
      methodName,
      additionalParams: additionalParams,
      parseResponse: BoolResponse.fromDTDResponse,
    );
  }

  Future<StringResponse> _callServiceWithStringResponse(
    DashTool tool,
    String methodName, {
    Map<String, Object> additionalParams = const {},
  }) async {
    return _callOnUnifiedAnalyticsService<StringResponse>(
      tool,
      methodName,
      additionalParams: additionalParams,
      parseResponse: StringResponse.fromDTDResponse,
    );
  }

  Future<T> _callOnUnifiedAnalyticsService<T>(
    DashTool tool,
    String methodName, {
    Map<String, Object> additionalParams = const {},
    required T Function(DTDResponse) parseResponse,
  }) async {
    final response = await call(
      kUnifiedAnalyticsServiceName,
      methodName,
      params: {'tool': tool.name, ...additionalParams},
    );
    return parseResponse(response);
  }
}
