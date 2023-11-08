// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

void main() {
  group('SocketServer', () {
    test('createAnalysisServer_successful',
        SocketServerTest.createAnalysisServer_successful);
    test('createAnalysisServer_alreadyStarted',
        SocketServerTest.createAnalysisServer_alreadyStarted);
  });
}

class SocketServerTest {
  static void createAnalysisServer_alreadyStarted() {
    var channel1 = MockServerChannel();
    var channel2 = MockServerChannel();
    var server = _createSocketServer(channel1);
    expect(
        channel1.notificationsReceived[0].event, SERVER_NOTIFICATION_CONNECTED);
    server.createAnalysisServer(channel2);
    channel1.expectMsgCount(notificationCount: 1);
    channel2.expectMsgCount(responseCount: 1);
    expect(channel2.responsesReceived[0].id, equals(''));
    expect(channel2.responsesReceived[0].error, isNotNull);
    expect(channel2.responsesReceived[0].error!.code,
        equals(RequestErrorCode.SERVER_ALREADY_STARTED));
    channel2
        .simulateRequestFromClient(ServerShutdownParams().toRequest('0'))
        .then((Response response) {
      expect(response.id, equals('0'));
      var error = response.error!;
      expect(error.code, equals(RequestErrorCode.SERVER_ALREADY_STARTED));
      channel2.expectMsgCount(responseCount: 2);
    });
  }

  static Future<void> createAnalysisServer_successful() {
    var channel = MockServerChannel();
    _createSocketServer(channel);
    channel.expectMsgCount(notificationCount: 1);
    expect(
        channel.notificationsReceived[0].event, SERVER_NOTIFICATION_CONNECTED);
    return channel
        .simulateRequestFromClient(ServerShutdownParams().toRequest('0'))
        .then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNull);
      channel.expectMsgCount(responseCount: 1, notificationCount: 1);
    });
  }

  static SocketServer _createSocketServer(MockServerChannel channel) {
    final errorNotifier = ErrorNotifier();
    final server = SocketServer(
        AnalysisServerOptions(),
        DartSdkManager(''),
        CrashReportingAttachmentsBuilder.empty,
        errorNotifier,
        null,
        null,
        AnalyticsManager(NoOpAnalytics()),
        null);

    server.createAnalysisServer(channel);
    errorNotifier.server = server.analysisServer;
    AnalysisEngine.instance.instrumentationService = errorNotifier;

    return server;
  }
}
