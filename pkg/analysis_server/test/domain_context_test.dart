// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.context;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_context.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
//  group('ContextDomainHandlerTest', () {
//    test('applyChanges', ContextDomainHandlerTest.applyChanges);
//    test('setOptions', ContextDomainHandlerTest.setOptions);
//    test('setPrioritySources_empty', ContextDomainHandlerTest.setPrioritySources_empty);
//    test('setPrioritySources_nonEmpty', ContextDomainHandlerTest.setPrioritySources_nonEmpty);
//  });
}

class ContextDomainHandlerTest {
  static void applyChanges() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    String contextId = _createContext(server);
    ChangeSet changeSet = new ChangeSet();
    ContextDomainHandler handler = new ContextDomainHandler(server);

    Request request = new Request('0', ContextDomainHandler.APPLY_CHANGES_NAME);
    request.setParameter(ContextDomainHandler.CONTEXT_ID_PARAM, contextId);
    request.setParameter(ContextDomainHandler.CHANGES_PARAM, changeSet);
    Response response = handler.handleRequest(request);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
  }

  static void setOptions() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    String contextId = _createContext(server);
    Map<String, Object> options = new Map<String, Object>();
    ContextDomainHandler handler = new ContextDomainHandler(server);

    Request request = new Request('0', ContextDomainHandler.SET_OPTIONS_NAME);
    request.setParameter(ContextDomainHandler.CONTEXT_ID_PARAM, contextId);
    request.setParameter(ContextDomainHandler.OPTIONS_PARAM, options);
    Response response = handler.handleRequest(request);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
  }

  static void setPrioritySources_empty() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    String contextId = _createContext(server);
    List<String> sources = new List<String>();
    ContextDomainHandler handler = new ContextDomainHandler(server);

    Request request = new Request('0', ContextDomainHandler.SET_PRIORITY_SOURCES_NAME);
    request.setParameter(ContextDomainHandler.CONTEXT_ID_PARAM, contextId);
    request.setParameter(ContextDomainHandler.SOURCES_PARAM, sources);
    Response response = handler.handleRequest(request);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
  }

  static void setPrioritySources_nonEmpty() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    String contextId = _createContext(server);
    List<String> sources = new List<String>();
    sources.add("foo.dart");
    ContextDomainHandler handler = new ContextDomainHandler(server);

    Request request = new Request('0', ContextDomainHandler.SET_PRIORITY_SOURCES_NAME);
    request.setParameter(ContextDomainHandler.CONTEXT_ID_PARAM, contextId);
    request.setParameter(ContextDomainHandler.SOURCES_PARAM, sources);
    Response response = handler.handleRequest(request);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null
    }));
  }

  static String _createContext(AnalysisServer server) {
    ServerDomainHandler handler = new ServerDomainHandler(server);
    Request request = new Request('0', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, '');
    Response response = handler.handleRequest(request);
    return response.getResult(ServerDomainHandler.CONTEXT_ID_RESULT);
  }
}
