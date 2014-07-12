// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.search;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_search.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';

main() {
  groupSep = ' | ';
  group('SearchDomainHandler', () {
    runReflectiveTests(SearchDomainTest);
  });

  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  SearchDomainHandler handler;

  setUp(() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        serverChannel, resourceProvider, new MockPackageMapProvider(), null);
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
      //expect(response, isNull);
    });

    test('findMemberDeclarations', () {
      var request = new Request('0', SEARCH_FIND_MEMBER_DECLARATIONS);
      request.setParameter(NAME, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('findMemberReferences', () {
      var request = new Request('0', SEARCH_FIND_MEMBER_REFERENCES);
      request.setParameter(NAME, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('findTopLevelDeclarations', () {
      var request = new Request('0', SEARCH_FIND_TOP_LEVEL_DECLARATIONS);
      request.setParameter(PATTERN, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });
  });
}

@ReflectiveTestCase()
class SearchDomainTest extends AbstractAnalysisTest {
  Index index;

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  @override
  void setUp() {
    super.setUp();
    index = server.index;
    createProject();
  }

//  Future test_findTopLevelDeclarations() {
//    // TODO(scheglov) replace this temporary Index test with an actual
//    // SearchEngine and SearchDomainHandler test.
//    addTestFile('''
//class AAA {
//  AAA() {}
//}
//''');
//    return waitForTasksFinished().then((_) {
//      return index.getRelationships(UniverseElement.INSTANCE,
//          IndexConstants.DEFINES_CLASS).then((List<Location> locations) {
//        bool hasClassFunction = false;
//        bool hasClassAAA = false;
//        for (var location in locations) {
//          if (location.element.name == 'Function') {
//            hasClassFunction = true;
//          }
//          if (location.element.name == 'AAA') {
//            hasClassAAA = true;
//          }
//        }
//        expect(hasClassFunction, isTrue, reason: locations.toString());
//        expect(hasClassAAA, isTrue, reason: locations.toString());
//      });
//    });
//  }
}
