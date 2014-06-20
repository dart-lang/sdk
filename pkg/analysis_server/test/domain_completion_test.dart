// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.completion;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  groupSep = ' | ';

  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  CompletionDomainHandler handler;

  setUp(() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        serverChannel, resourceProvider, new MockPackageMapProvider());
    server.defaultSdk = new MockSdk();
    handler = new CompletionDomainHandler(server);
  });

  group('CompletionDomainHandler', () {
    test('getSuggestions', () {
      var request = new Request('0', COMPLETION_GET_SUGGESTIONS);
      request.setParameter(FILE, null);
      request.setParameter(OFFSET, null);
      var response = handler.handleRequest(request);
      // TODO(brianwilkerson) implement
      //expect(response, isNull);
    });
  });
}
