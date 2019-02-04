// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisServerTest);
  });
}

@reflectiveTest
class AnalysisServerTest with ResourceProviderMixin {
  MockServerChannel channel;
  AnalysisServer server;

  /**
   * Test that having multiple analysis contexts analyze the same file doesn't
   * cause that file to receive duplicate notifications when it's modified.
   */
  Future do_not_test_no_duplicate_notifications() async {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = [ServerService.STATUS].toSet();
    newFolder('/foo');
    newFolder('/bar');
    newFile('/foo/foo.dart', content: 'import "../bar/bar.dart";');
    File bar = newFile('/bar/bar.dart', content: 'library bar;');
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    Map<AnalysisService, Set<String>> subscriptions =
        <AnalysisService, Set<String>>{};
    for (AnalysisService service in AnalysisService.VALUES) {
      subscriptions[service] = <String>[bar.path].toSet();
    }
    // The following line causes the isolate to continue running even though the
    // test completes.
    server.setAnalysisSubscriptions(subscriptions);
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    channel.notificationsReceived.clear();
    server.updateContent(
        '0', {bar.path: new AddContentOverlay('library bar; void f() {}')});
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    expect(channel.notificationsReceived, isNotEmpty);
    Set<String> notificationTypesReceived = new Set<String>();
    for (Notification notification in channel.notificationsReceived) {
      String notificationType = notification.event;
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
    channel = new MockServerChannel();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new AnalysisServer(
        channel,
        resourceProvider,
        new AnalysisServerOptions(),
        new DartSdkManager(convertPath('/sdk'), false),
        InstrumentationService.NULL_SERVICE);
  }

  Future test_echo() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'echo');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNull);
    });
  }

  Future test_serverStatusNotifications() {
    server.serverServices.add(ServerService.STATUS);
    var pkgFolder = convertPath('/pkg');
    newFolder(pkgFolder);
    newFolder(join(pkgFolder, 'lib'));
    newFile(join(pkgFolder, 'lib', 'test.dart'), content: 'class C {}');
    server.setAnalysisRoots('0', [pkgFolder], [], {});
    // Pump the event queue to make sure the server has finished any
    // analysis.
    return pumpEventQueue(times: 5000).then((_) {
      List<Notification> notifications = channel.notificationsReceived;
      expect(notifications, isNotEmpty);
      // expect at least one notification indicating analysis is in progress
      expect(notifications.any((Notification notification) {
        if (notification.event == SERVER_NOTIFICATION_STATUS) {
          var params = new ServerStatusParams.fromNotification(notification);
          if (params.analysis != null) {
            return params.analysis.isAnalyzing;
          }
        }
        return false;
      }), isTrue);
      // the last notification should indicate that analysis is complete
      Notification notification = notifications[notifications.length - 1];
      var params = new ServerStatusParams.fromNotification(notification);
      expect(params.analysis.isAnalyzing, isFalse);
    });
  }

  test_setAnalysisSubscriptions_fileInIgnoredFolder_newOptions() async {
    String path = convertPath('/project/samples/sample.dart');
    newFile(path);
    newFile('/project/analysis_options.yaml', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', [convertPath('/project')], [], {});
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: new Set<String>.from([path])
    });

    // We respect subscriptions, even for excluded files.
    await server.onAnalysisComplete;
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  test_setAnalysisSubscriptions_fileInIgnoredFolder_oldOptions() async {
    String path = convertPath('/project/samples/sample.dart');
    newFile(path);
    newFile('/project/.analysis_options', content: r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', [convertPath('/project')], [], {});
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: new Set<String>.from([path])
    });

    // We respect subscriptions, even for excluded files.
    await server.onAnalysisComplete;
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  Future test_shutdown() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my28', SERVER_REQUEST_SHUTDOWN);
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my28'));
      expect(response.error, isNull);
    });
  }

  Future test_unknownRequest() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'randomRequest');
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
      return new Response(request.id, result: {'echo': true});
    }
    return null;
  }
}
