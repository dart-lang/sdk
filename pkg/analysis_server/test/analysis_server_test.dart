// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisServerTest);
  });
}

@reflectiveTest
class AnalysisServerTest with ResourceProviderMixin {
  MockServerChannel channel;
  AnalysisServer server;

  /// Test that having multiple analysis contexts analyze the same file doesn't
  /// cause that file to receive duplicate notifications when it's modified.
  Future do_not_test_no_duplicate_notifications() async {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = {ServerService.STATUS};
    newFolder('/foo');
    newFolder('/bar');
    newFile('/foo/foo.dart', content: 'import "../bar/bar.dart";');
    var bar = newFile('/bar/bar.dart', content: 'library bar;');
    server.setAnalysisRoots('0', ['/foo', '/bar'], []);
    var subscriptions = <AnalysisService, Set<String>>{};
    for (var service in AnalysisService.VALUES) {
      subscriptions[service] = <String>{bar.path};
    }
    // The following line causes the isolate to continue running even though the
    // test completes.
    server.setAnalysisSubscriptions(subscriptions);
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    channel.notificationsReceived.clear();
    server.updateContent(
        '0', {bar.path: AddContentOverlay('library bar; void f() {}')});
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    expect(channel.notificationsReceived, isNotEmpty);
    var notificationTypesReceived = <String>{};
    for (var notification in channel.notificationsReceived) {
      var notificationType = notification.event;
      switch (notificationType) {
        case 'server.status':
        case 'analysis.errors':
          // It's normal for these notifications to be sent multiple times.
          break;
        case 'analysis.outline':
          // It's normal for this notification to be sent twice.
          // TODO(paulberry): why?
          break;
        default:
          if (!notificationTypesReceived.add(notificationType)) {
            fail('Notification type $notificationType received more than once');
          }
          break;
      }
    }
  }

  void setUp() {
    channel = MockServerChannel();
    // Create an SDK in the mock file system.
    MockSdk(resourceProvider: resourceProvider);
    server = AnalysisServer(
        channel,
        resourceProvider,
        AnalysisServerOptions(),
        DartSdkManager(convertPath('/sdk')),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
  }

  Future test_echo() {
    server.handlers = [EchoHandler()];
    var request = Request('my22', 'echo');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNull);
    });
  }

  Future test_serverStatusNotifications_hasFile() async {
    server.serverServices.add(ServerService.STATUS);

    newFile('/test/lib/a.dart', content: r'''
class A {}
''');
    server.setAnalysisRoots('0', [convertPath('/test')], []);

    // Pump the event queue, so that the server has finished any analysis.
    await pumpEventQueue(times: 5000);

    var notifications = channel.notificationsReceived;
    expect(notifications, isNotEmpty);

    // At least one notification indicating analysis is in progress.
    expect(notifications.any((Notification notification) {
      if (notification.event == SERVER_NOTIFICATION_STATUS) {
        var params = ServerStatusParams.fromNotification(notification);
        if (params.analysis != null) {
          return params.analysis.isAnalyzing;
        }
      }
      return false;
    }), isTrue);

    // The last notification should indicate that analysis is complete.
    var notification = notifications[notifications.length - 1];
    var params = ServerStatusParams.fromNotification(notification);
    expect(params.analysis.isAnalyzing, isFalse);
  }

  Future test_serverStatusNotifications_noFiles() async {
    server.serverServices.add(ServerService.STATUS);

    newFolder('/test');
    server.setAnalysisRoots('0', [convertPath('/test')], []);

    // Pump the event queue, so that the server has finished any analysis.
    await pumpEventQueue(times: 5000);

    var notifications = channel.notificationsReceived;
    expect(notifications, isNotEmpty);

    // At least one notification indicating analysis is in progress.
    expect(notifications.any((Notification notification) {
      if (notification.event == SERVER_NOTIFICATION_STATUS) {
        var params = ServerStatusParams.fromNotification(notification);
        if (params.analysis != null) {
          return params.analysis.isAnalyzing;
        }
      }
      return false;
    }), isTrue);

    // The last notification should indicate that analysis is complete.
    var notification = notifications[notifications.length - 1];
    var params = ServerStatusParams.fromNotification(notification);
    expect(params.analysis.isAnalyzing, isFalse);
  }

  Future<void>
      test_setAnalysisSubscriptions_fileInIgnoredFolder_newOptions() async {
    var path = convertPath('/project/samples/sample.dart');
    newFile(path);
    newFile('/project/analysis_options.yaml', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', [convertPath('/project')], []);
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: <String>{path}
    });

    // We respect subscriptions, even for excluded files.
    await pumpEventQueue();
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  Future<void>
      test_setAnalysisSubscriptions_fileInIgnoredFolder_oldOptions() async {
    var path = convertPath('/project/samples/sample.dart');
    newFile(path);
    newFile('/project/.analysis_options', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', [convertPath('/project')], []);
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: <String>{path}
    });

    // We respect subscriptions, even for excluded files.
    await pumpEventQueue();
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  Future test_shutdown() {
    server.handlers = [ServerDomainHandler(server)];
    var request = Request('my28', SERVER_REQUEST_SHUTDOWN);
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my28'));
      expect(response.error, isNull);
    });
  }

  Future test_unknownRequest() {
    server.handlers = [EchoHandler()];
    var request = Request('my22', 'randomRequest');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNotNull);
    });
  }
}

class EchoHandler implements RequestHandler {
  @override
  Response handleRequest(Request request) {
    if (request.method == 'echo') {
      return Response(request.id, result: {'echo': true});
    }
    return null;
  }
}
