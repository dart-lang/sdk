// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.edit;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:unittest/unittest.dart';

import '../mocks.dart';

main() {
  groupSep = ' | ';

  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  EditDomainHandler handler;

  setUp(() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        serverChannel, resourceProvider, new MockPackageMapProvider(), null,
        new MockSdk());
    handler = new EditDomainHandler(server);
  });

  group('EditDomainHandler', () {
    test('applyRefactoring', () {
      var request = new Request('0', EDIT_APPLY_REFACTORING);
      request.setParameter(ID, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('createRefactoring', () {
      var request = new Request('0', EDIT_CREATE_REFACTORING);
      request.setParameter(KIND, null);
      request.setParameter(FILE, null);
      request.setParameter(OFFSET, null);
      request.setParameter(LENGTH, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('deleteRefactoring', () {
      var request = new Request('0', EDIT_DELETE_REFACTORING);
      request.setParameter(ID, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('getAssists', () {
      var request = new Request('0', EDIT_GET_ASSISTS);
      request.setParameter(FILE, null);
      request.setParameter(OFFSET, null);
      request.setParameter(LENGTH, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('getFixes', () {
      var request = new Request('0', EDIT_GET_FIXES);
      request.setParameter(ERRORS, []);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('getRefactorings', () {
      var request = new Request('0', EDIT_GET_REFACTORINGS);
      request.setParameter(FILE, 'test.dart');
      request.setParameter(OFFSET, 10);
      request.setParameter(LENGTH, 20);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('setRefactoringOptions', () {
      var request = new Request('0', EDIT_SET_REFACTORING_OPTIONS);
      request.setParameter(ID, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });
  });
}
