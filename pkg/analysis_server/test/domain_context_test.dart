// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.context;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_context.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  group('ContextDomainHandlerTest', () {
    test('applyChanges', ContextDomainHandlerTest.applyChanges);
    test('createChangeSet', ContextDomainHandlerTest.createChangeSet);
    test('createChangeSet_onlyAdded', ContextDomainHandlerTest.createChangeSet_onlyAdded);
    test('setOptions', ContextDomainHandlerTest.setOptions);
    test('setPrioritySources_empty', ContextDomainHandlerTest.setPrioritySources_empty);
    test('setPrioritySources_nonEmpty', ContextDomainHandlerTest.setPrioritySources_nonEmpty);
  });
}

class ContextDomainHandlerTest {
  static int contextIdCounter = 0;

  static void applyChanges() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    String contextId = _createContext(server);
    ChangeSet changeSet = new ChangeSet();
    ContextDomainHandler handler = new ContextDomainHandler(server);

    Request request = new Request('0', ContextDomainHandler.APPLY_CHANGES_NAME);
    request.setParameter(ContextDomainHandler.CONTEXT_ID_PARAM, contextId);
    request.setParameter(ContextDomainHandler.SOURCES_PARAM, []);
    request.setParameter(ContextDomainHandler.CHANGES_PARAM, {
      ContextDomainHandler.ADDED_PARAM : ['ffile:/one.dart'],
      ContextDomainHandler.MODIFIED_PARAM : ['ffile:/two.dart'],
      ContextDomainHandler.REMOVED_PARAM : ['ffile:/three.dart']
    });
    expect(server.contextWorkQueue, isEmpty);
    Response response = handler.handleRequest(request);
    expect(server.contextWorkQueue, hasLength(1));
    expect(response.toJson(), equals({
      Response.ID: '0'
    }));
  }

  static void createChangeSet() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    Request request = new Request('0', ContextDomainHandler.APPLY_CHANGES_NAME);
    ContextDomainHandler handler = new ContextDomainHandler(server);
    SourceFactory sourceFactory = new SourceFactory([new FileUriResolver()]);
    ChangeSet changeSet = handler.createChangeSet(request, sourceFactory,
        new RequestDatum(request, ContextDomainHandler.CHANGES_PARAM, {
      ContextDomainHandler.ADDED_PARAM: ['ffile:/one.dart'],
      ContextDomainHandler.MODIFIED_PARAM: [],
      ContextDomainHandler.REMOVED_PARAM: ['ffile:/two.dart',
          'ffile:/three.dart']
    }));
    expect(changeSet.addedSources, hasLength(equals(1)));
    expect(changeSet.changedSources, hasLength(equals(0)));
    expect(changeSet.removedSources, hasLength(equals(2)));
  }

  static void createChangeSet_onlyAdded() {
    AnalysisServer server = new AnalysisServer(new MockServerChannel());
    Request request = new Request('0', ContextDomainHandler.APPLY_CHANGES_NAME);
    ContextDomainHandler handler = new ContextDomainHandler(server);
    SourceFactory sourceFactory = new SourceFactory([new FileUriResolver()]);
    ChangeSet changeSet = handler.createChangeSet(request, sourceFactory,
        new RequestDatum(request, ContextDomainHandler.CHANGES_PARAM, {
      ContextDomainHandler.ADDED_PARAM: ['ffile:/one.dart'],
    }));
    expect(changeSet.addedSources, hasLength(equals(1)));
    expect(changeSet.changedSources, hasLength(equals(0)));
    expect(changeSet.removedSources, hasLength(equals(0)));
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
      Response.ID: '0'
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
      Response.ID: '0'
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
      Response.ID: '0'
    }));
  }

  static String _createContext(AnalysisServer server) {
    String contextId = "context${contextIdCounter++}";
    ServerDomainHandler handler = new ServerDomainHandler(server);
    Request request = new Request('0', ServerDomainHandler.CREATE_CONTEXT_METHOD);
    request.setParameter(ServerDomainHandler.SDK_DIRECTORY_PARAM, sdkPath);
    request.setParameter(ServerDomainHandler.CONTEXT_ID_PARAM, contextId);
    Response response = handler.handleRequest(request);
    if (response.error != null) {
      fail('Unexpected error: ${response.error.toJson()}');
    }
    return contextId;
  }
}
