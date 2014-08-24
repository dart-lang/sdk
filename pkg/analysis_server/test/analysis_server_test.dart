// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  group('AnalysisServer', () {
    test('server.status notifications', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      MockAnalysisContext context = new MockAnalysisContext();
      MockSource source = new MockSource();
      source.when(callsTo('get fullName')).alwaysReturn('foo.dart');
      source.when(callsTo('get isInSystemLibrary')).alwaysReturn(false);
      ChangeNoticeImpl notice = new ChangeNoticeImpl(source);
      notice.setErrors([], new LineInfo([0]));
      AnalysisResult firstResult = new AnalysisResult([notice], 0, '', 0);
      AnalysisResult lastResult = new AnalysisResult(null, 1, '', 1);
      context.when(callsTo("performAnalysisTask"))
        ..thenReturn(firstResult, 3)
        ..thenReturn(lastResult);
      helper.server.serverServices.add(ServerService.STATUS);
      helper.server.schedulePerformAnalysisOperation(context);
      // Pump the event queue to make sure the server has finished any
      // analysis.
      return pumpEventQueue().then((_) {
        List<Notification> notifications = helper.channel.notificationsReceived;
        expect(notifications, isNot(isEmpty));
        // expect at least one notification indicating analysis is in progress
        expect(notifications.any((Notification notification) {
          if (notification.event == SERVER_STATUS) {
            Map analysisStatus = notification.params['analysis'];
            return analysisStatus['analyzing'];
          }
          return false;
        }), isTrue);
        // the last notification should indicate that analysis is complete
        Notification notification = notifications[notifications.length - 1];
        Map analysisStatus = notification.params['analysis'];
        expect(analysisStatus['analyzing'], isFalse);
      });
    });

    test('echo', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      helper.server.handlers = [new EchoHandler()];
      var request = new Request('my22', 'echo');
      return helper.channel.sendRequest(request)
          .then((Response response) {
            expect(response.id, equals('my22'));
            expect(response.error, isNull);
          });
    });

    test('shutdown', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      helper.server.handlers = [new ServerDomainHandler(helper.server)];
      var request = new Request('my28', SERVER_SHUTDOWN);
      return helper.channel.sendRequest(request)
          .then((Response response) {
            expect(response.id, equals('my28'));
            expect(response.error, isNull);
          });
    });

    test('unknownRequest', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      helper.server.handlers = [new EchoHandler()];
      var request = new Request('my22', 'randomRequest');
      return helper.channel.sendRequest(request)
          .then((Response response) {
            expect(response.id, equals('my22'));
            expect(response.error, isNotNull);
          });
    });

    test('rethrow exceptions', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      Exception exceptionToThrow = new Exception('test exception');
      MockServerOperation operation = new MockServerOperation(
          ServerOperationPriority.ANALYSIS, (_) { throw exceptionToThrow; });
      helper.server.operationQueue.add(operation);
      try {
        helper.server.performOperation();
        fail('exception not rethrown');
      } on AnalysisException catch (exception) {
        expect(exception.cause.exception, equals(exceptionToThrow));
      }
    });
  });
}

class AnalysisServerTestHelper {
  MockServerChannel channel;
  AnalysisServer server;

  AnalysisServerTestHelper({bool rethrowExceptions: true}) {
    channel = new MockServerChannel();
    server = new AnalysisServer(channel, PhysicalResourceProvider.INSTANCE,
        new MockPackageMapProvider(), null, new MockSdk(),
        rethrowExceptions: rethrowExceptions);
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
