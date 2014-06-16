// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.search;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_search.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  groupSep = ' | ';

  MockServerChannel serverChannel;
  AnalysisServer server;
  SearchDomainHandler handler;
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  setUp(() {
    serverChannel = new MockServerChannel();
    server = new AnalysisServer(serverChannel, resourceProvider);
    server.defaultSdk = new MockSdk();
    handler = new SearchDomainHandler(server);
  });

  group('SearchDomainHandler', () {
    test('findElementReferences', () {
      var request = new Request('0', SEARCH_FIND_ELEMENT_REFERENCES);
      request.setParameter(FILE, null);
      request.setParameter(OFFSET, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      expect(response, isNull);
    });

    test('findMemberDeclarations', () {
      var request = new Request('0', SEARCH_FIND_MEMBER_DECLARATIONS);
      request.setParameter(NAME, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      expect(response, isNull);
    });

    test('findMemberReferences', () {
      var request = new Request('0', SEARCH_FIND_MEMBER_REFERENCES);
      request.setParameter(NAME, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      expect(response, isNull);
    });

    test('findTopLevelDeclarations', () {
      var request = new Request('0', SEARCH_FIND_TOP_LEVEL_DECLARATIONS);
      request.setParameter(PATTERN, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      expect(response, isNull);
    });
  });
}
