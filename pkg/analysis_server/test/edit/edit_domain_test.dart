// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.edit;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol2.dart';
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
      // TODO(paulberry): Why are we passing null here?
      var request = new EditGetAssistsParams(null, null, null).toRequest('0');
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });

    test('getFixes', () {
      // TODO(paulberry): Test not yet written, and the code below doesn't
      // follow the API.
//      var request = new Request('0', EDIT_GET_FIXES);
//      request.setParameter(ERRORS, []);
//      var response = handler.handleRequest(request);
//      // TODO(brianwilkerson) implement
//      //expect(response, isNull);
    });
  });
}
