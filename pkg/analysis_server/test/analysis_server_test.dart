// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

class AnalysisServerTestHelper {
  MockServerChannel channel;
  AnalysisServer server;
  MockAnalysisLogger logger;

  AnalysisServerTestHelper() {
    channel = new MockServerChannel();
    server = new AnalysisServer(channel, PhysicalResourceProvider.INSTANCE);
    logger = new MockAnalysisLogger();
    AnalysisEngine.instance.logger = logger;
  }
}

main() {
  group('AnalysisServer', () {
    test('addContextToWorkQueue_whenNotRunning', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      helper.server.running = false;
      MockAnalysisContext context = new MockAnalysisContext();
      helper.server.addContextToWorkQueue(context);
      // Pump the event queue to make sure the server doesn't try to do any
      // analysis.
      return pumpEventQueue();
    });

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
      helper.server.addContextToWorkQueue(context);
      // Pump the event queue to make sure the server has finished any
      // analysis.
      return pumpEventQueue().then((_) {
        List<Notification> notifications = helper.channel.notificationsReceived;
        expect(notifications.length, equals(9));
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

    test('errorToJson_formattingApplied', () {
      MockSource source = new MockSource();
      source.when(callsTo('get encoding')).alwaysReturn('foo.dart');
      CompileTimeErrorCode errorCode = CompileTimeErrorCode.AMBIGUOUS_EXPORT;
      AnalysisError analysisError =
          new AnalysisError.con1(source, errorCode, ['foo', 'bar', 'baz']);
      Map<String, Object> json = AnalysisServer.errorToJson(analysisError);

      expect(json['message'],
          equals("The name 'foo' is defined in the libraries 'bar' and 'baz'"));
    });

    test('errorToJson_noCorrection', () {
      MockSource source = new MockSource();
      source.when(callsTo('get fullName')).alwaysReturn('foo.dart');
      CompileTimeErrorCode errorCode =
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER;
      AnalysisError analysisError =
          new AnalysisError.con2(source, 10, 5, errorCode, ['Foo']);
      Map<String, Object> json = AnalysisServer.errorToJson(analysisError);
      expect(json, hasLength(5));
      expect(json['file'], equals('foo.dart'));
      expect(json['errorCode'], 'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER');
      expect(json['offset'], equals(analysisError.offset));
      expect(json['length'], equals(analysisError.length));
      expect(json['message'], equals(errorCode.message.replaceAll('%s', 'Foo')));
    });

    test('errorToJson_withCorrection', () {
      MockSource source = new MockSource();
      source.when(callsTo('get encoding')).alwaysReturn('foo.dart');

      // TODO(paulberry): in principle we should test an error or hint that uses
      // %s formatting in its correction string.  But no such errors or hints
      // currently exist!
      HintCode errorCode = HintCode.MISSING_RETURN;

      AnalysisError analysisError =
          new AnalysisError.con2(source, 10, 5, errorCode, ['int']);
      Map<String, Object> json = AnalysisServer.errorToJson(analysisError);
      expect(json['correction'], equals(errorCode.correction));
    });

    test('performTask_whenNotRunning', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      // If the server is shut down while there is analysis still pending,
      // performTask() should notice that the server is no longer running and
      // do no analysis.
      MockAnalysisContext context = new MockAnalysisContext();
      helper.server.addContextToWorkQueue(context);
      helper.server.running = false;
      // Pump the event queue to make sure the server doesn't try to do any
      // analysis.
      return pumpEventQueue();
    });

    test('shutdown', () {
      AnalysisServerTestHelper helper = new AnalysisServerTestHelper();
      helper.server.handlers = [new ServerDomainHandler(helper.server)];
      var request = new Request('my28', METHOD_SHUTDOWN);
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
  });
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
