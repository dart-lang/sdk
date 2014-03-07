// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.server;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
//  group('ServerDomainHandler', () {
////    test('createContext', ServerDomainHandlerTest.createContext);
////    test('deleteContext_alreadyDeleted', ServerDomainHandlerTest.deleteContext_alreadyDeleted);
//    test('deleteContext_doesNotExist', ServerDomainHandlerTest.deleteContext_doesNotExist);
////    test('deleteContext_existing', ServerDomainHandlerTest.deleteContext_existing);
//    test('shutdown', ServerDomainHandlerTest.shutdown);
//    test('version', ServerDomainHandlerTest.version);
//  });
}

class ServerDomainHandlerTest {
  static void createContext() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    Request createRequest = new Request('0', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    createRequest.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    Response response = handler.handleRequest(createRequest);
    String contextId = response.getResult(ServerDomainHandler.CONTEXT_ID_RESULT);
    expect(contextId, isNotNull);
  }

  static void deleteContext_alreadyDeleted() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    Request createRequest = new Request('0', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    createRequest.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    Response response = handler.handleRequest(createRequest);
    String contextId = response.getResult(ServerDomainHandler.CONTEXT_ID_RESULT);

    Request deleteRequest = new Request('0', ServerDomainHandler.DELETE_CONTEXT_METHOD);
    deleteRequest.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, contextId);
    response = handler.handleRequest(deleteRequest);
    response = handler.handleRequest(deleteRequest);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: 'Context does not exist'
    }));
  }

  static void deleteContext_doesNotExist() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    Request deleteRequest = new Request('0', ServerDomainHandler.DELETE_CONTEXT_METHOD);
    deleteRequest.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, 'xyzzy');
    Response response = handler.handleRequest(deleteRequest);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: 'Context does not exist'
    }));
  }

  static void deleteContext_existing() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    Request createRequest = new Request('0', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    createRequest.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    Response response = handler.createContext(createRequest);
    String contextId = response.getResult(ServerDomainHandler.CONTEXT_ID_RESULT);

    Request deleteRequest = new Request('0', ServerDomainHandler.DELETE_CONTEXT_METHOD);
    deleteRequest.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, contextId);
    response = handler.handleRequest(deleteRequest);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
  }

  static void shutdown() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    expect(server.running, isTrue);
    Request shutdownRequest = new Request('0', ServerDomainHandler.SHUTDOWN_METHOD);
    Response response = handler.handleRequest(shutdownRequest);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
    expect(server.running, isFalse);
  }

  static void version() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    ServerDomainHandler handler = new ServerDomainHandler(server);

    Request versionRequest = new Request('0', ServerDomainHandler.VERSION_METHOD);
    Response response = handler.handleRequest(versionRequest);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null,
      Response.RESULT: {
        ServerDomainHandler.VERSION_RESULT: '0.0.1'
      }
    }));
  }
}
