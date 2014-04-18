// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  group('AnalysisServer', () {
    setUp(AnalysisServerTest.setUp);
    test('createContext', AnalysisServerTest.createContext);
    test('echo', AnalysisServerTest.echo);
    test('shutdown', AnalysisServerTest.shutdown);
    test('unknownRequest', AnalysisServerTest.unknownRequest);
  });
}

class AnalysisServerTest {
  static MockServerChannel channel;
  static AnalysisServer server;

  static void setUp() {
    channel = new MockServerChannel();
    server = new AnalysisServer(channel);
  }

  static Future createContext() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my27', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, sdkPath);
    request.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, 'ctx');
    return channel.sendRequest(request)
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals('my27'));
          expect(response.error, isNull);
        });
  }

  static Future echo() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'echo');
    return channel.sendRequest(request)
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals('my22'));
          expect(response.error, isNull);
        });
  }

  static Future shutdown() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my28', ServerDomainHandler.SHUTDOWN_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    return channel.sendRequest(request)
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals('my28'));
          expect(response.error, isNull);
        });
  }

  static Future unknownRequest() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'randomRequest');
    return channel.sendRequest(request)
        .timeout(new Duration(seconds: 1))
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
