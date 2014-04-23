// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  group('AnalysisServer', () {
    setUp(AnalysisServerTest.setUp);
    test('addContextToWorkQueue_twice',
        AnalysisServerTest.addContextToWorkQueue_twice);
    test('addContextToWorkQueue_whenNotRunning',
        AnalysisServerTest.addContextToWorkQueue_whenNotRunning);
    test('addContextToWorkQueue_whenRunning',
        AnalysisServerTest.addContextToWorkQueue_whenRunning);
    test('createContext', AnalysisServerTest.createContext);
    test('echo', AnalysisServerTest.echo);
    test('performTask_whenNotRunning',
        AnalysisServerTest.performTask_whenNotRunning);
    test('shutdown', AnalysisServerTest.shutdown);
    test('unknownRequest', AnalysisServerTest.unknownRequest);
  });
}

class MockAnalysisContext_withPerformAnalysisTask extends MockAnalysisContext {
  List<AnalysisResult> results = [];

  @override
  AnalysisResult performAnalysisTask() => results.removeAt(0);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AnalysisServerTest {
  static MockServerChannel channel;
  static AnalysisServer server;
  static MockAnalysisLogger logger;

  static void setUp() {
    channel = new MockServerChannel();
    server = new AnalysisServer(channel);
    logger = new MockAnalysisLogger();
    AnalysisEngine.instance.logger = logger;
  }

  static Future addContextToWorkQueue_whenNotRunning() {
    server.running = false;
    MockAnalysisContext context = new MockAnalysisContext();
    server.addContextToWorkQueue(context);
    // Pump the event queue to make sure the server doesn't try to do any
    // analysis.
    return pumpEventQueue();
  }

  static Future addContextToWorkQueue_whenRunning() {
    MockAnalysisContext_withPerformAnalysisTask context =
        new MockAnalysisContext_withPerformAnalysisTask();
    server.addContextToWorkQueue(context);
    Source source = new FileBasedSource.con1(new JavaFile('/foo.dart'));
    ChangeNoticeImpl changeNoticeImpl = new ChangeNoticeImpl(source);
    LineInfo lineInfo = new LineInfo([0]);
    AnalysisError analysisError = new AnalysisError.con1(source,
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, []);
    changeNoticeImpl.setErrors([analysisError], lineInfo);
    context.results.add(new AnalysisResult([changeNoticeImpl], 0, 'myClass', 0)
        );
    context.results.add(new AnalysisResult(null, 0, null, 0));
    return pumpEventQueue().then((_) {
      expect(context.results, isEmpty);
      expect(channel.notificationsReceived, hasLength(2));
      expect(channel.notificationsReceived[0].event, equals('server.connected')
          );
      expect(channel.notificationsReceived[1].event, equals('context.errors'));
      expect(channel.notificationsReceived[1].params['source'], equals(
          '102file:///foo.dart')); // Issue 18739
      List<AnalysisError> errors =
          channel.notificationsReceived[1].params['errors'];
      expect(errors, hasLength(1));
      expect(errors[0], equals(analysisError));
    });
  }

  static Future addContextToWorkQueue_twice() {
    // The context should only be asked to perform its analysis task once.
    MockAnalysisContext_withPerformAnalysisTask context =
        new MockAnalysisContext_withPerformAnalysisTask();
    server.addContextToWorkQueue(context);
    server.addContextToWorkQueue(context);
    context.results.add(new AnalysisResult(null, 0, null, 0));
    return pumpEventQueue().then((_) => expect(context.results, isEmpty));
  }

  static Future createContext() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my27', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, sdkPath);
    request.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, 'ctx');
    return channel.sendRequest(request)
        .then((Response response) {
          expect(response.id, equals('my27'));
          expect(response.error, isNull);
        });
  }

  static Future echo() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'echo');
    return channel.sendRequest(request)
        .then((Response response) {
          expect(response.id, equals('my22'));
          expect(response.error, isNull);
        });
  }

  static Future performTask_whenNotRunning() {
    // If the server is shut down while there is analysis still pending,
    // performTask() should notice that the server is no longer running and
    // do no analysis.
    MockAnalysisContext context = new MockAnalysisContext();
    server.addContextToWorkQueue(context);
    server.running = false;
    // Pump the event queue to make sure the server doesn't try to do any
    // analysis.
    return pumpEventQueue();
  }

  static Future shutdown() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my28', ServerDomainHandler.SHUTDOWN_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    return channel.sendRequest(request)
        .then((Response response) {
          expect(response.id, equals('my28'));
          expect(response.error, isNull);
        });
  }

  static Future unknownRequest() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'randomRequest');
    return channel.sendRequest(request)
        .then((Response response) {
          expect(response.id, equals('my22'));
          expect(response.error, isNotNull);
        });
  }
}


class EchoHandler implements RequestHandler {
  @override
  Response handleRequest(Request request) {
    if (request.method == 'echo') {
      var response = new Response(request.id);
      response.setResult('echo', true);
      return response;
    }
    return null;
  }
}
