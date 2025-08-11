// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dtd/dtd.dart';
import 'package:dtd/src/services/unified_analytics_service.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'utils.dart';

void main() {
  late ToolingDaemonTestProcess toolingDaemonProcess;
  late DartToolingDaemon client;

  // Use an arbitrary [DashTool] for testing.
  const tool = DashTool.devtools;

  group(UnifiedAnalyticsServiceConstants.serviceName, () {
    setUp(() async {
      toolingDaemonProcess = ToolingDaemonTestProcess(unrestricted: false);
      await toolingDaemonProcess.start();
      client = await DartToolingDaemon.connect(toolingDaemonProcess.uri);
    });

    tearDown(() async {
      toolingDaemonProcess.kill();
    });

    test(UnifiedAnalyticsServiceConstants.getConsentMessage, () async {
      final response = await client.analyticsGetConsentMessage(tool);
      expect(response.value, isNotNull);
      expect(response.value, contains('Google Analytics'));
      expect(
        response.value,
        contains('Privacy Policy (https://policies.google.com/privacy).'),
      );
    });

    test(UnifiedAnalyticsServiceConstants.clientShowedMessage, () async {
      // Verify this can be called without error.
      final response = await client.analyticsClientShowedMessage(tool);
      expect(response.value, isNull);
    });

    test(UnifiedAnalyticsServiceConstants.shouldShowMessage, () async {
      final response = await client.analyticsShouldShowConsentMessage(tool);
      // Since `clientShowedMessage` has already been called on the
      // FakeAnalytics instance when we create it in package:dtd_impl, this will
      // return false.
      expect(response.value, false);
    });

    test(
        '${UnifiedAnalyticsServiceConstants.telemetryEnabled} & '
        '${UnifiedAnalyticsServiceConstants.setTelemetry}', () async {
      await client.analyticsSetTelemetry(tool, enabled: false);
      var response = await client.analyticsTelemetryEnabled(tool);
      expect(response.value, false);

      await client.analyticsSetTelemetry(tool, enabled: true);
      response = await client.analyticsTelemetryEnabled(tool);
      expect(response.value, true);

      // Set telemetry back to false.
      await client.analyticsSetTelemetry(tool, enabled: false);
    });

    test('send', () async {
      var eventsResponse = await client.listFakeAnalyticsSentEvents(tool);
      expect(eventsResponse.value, isList);
      expect(eventsResponse.value, isEmpty);

      final testEvent = Event.hotReloadTime(timeMs: 10);
      final response = await client.analyticsSend(tool, testEvent);
      expect(response.value, null);

      eventsResponse = await client.listFakeAnalyticsSentEvents(tool);
      expect(eventsResponse.value, isList);
      expect(eventsResponse.value, isNotEmpty);
      final firstEvent = Event.fromJson(eventsResponse.value!.first);
      expect(firstEvent, testEvent);
    });
  });
}

extension on DartToolingDaemon {
  Future<StringListResponse> listFakeAnalyticsSentEvents(DashTool tool) async {
    final result = await call(
      UnifiedAnalyticsServiceConstants.serviceName,
      'listFakeAnalyticsSentEvents',
      params: {'tool': tool.name},
    );
    return StringListResponse.fromDTDResponse(result);
  }
}
