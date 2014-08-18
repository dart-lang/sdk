// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.edit;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/constants.dart';
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
  });
}
