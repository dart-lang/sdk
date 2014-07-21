// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.server;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  AnalysisServer server;
  ServerDomainHandler handler;

  setUp(() {
    var serverChannel = new MockServerChannel();
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    server = new AnalysisServer(
        serverChannel, resourceProvider, new MockPackageMapProvider(), null,
        new MockSdk());
    handler = new ServerDomainHandler(server);
  });

  group('ServerDomainHandler', () {
    test('getVersion', () {
      var request = new Request('0', SERVER_GET_VERSION);
      var response = handler.handleRequest(request);
      expect(response.toJson(), equals({
        Response.ID: '0',
        Response.RESULT: {
          VERSION: '0.0.1'
        }
      }));
    });

    group('setSubscriptions', () {
      Request request;
      setUp(() {
        request = new Request('0', SERVER_SET_SUBSCRIPTIONS);
      });

      test('invalid service name', () {
        request.setParameter(
            SUBSCRIPTIONS,
            ['noSuchService']);
        var response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
      });

      test('success', () {
        expect(server.serverServices, isEmpty);
        // send request
        request.setParameter(
            SUBSCRIPTIONS,
            [ServerService.STATUS.name]);
        var response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
        // set of services has been changed
        expect(server.serverServices, contains(ServerService.STATUS));
      });
    });

    test('shutdown', () {
      expect(server.running, isTrue);
      // send request
      var request = new Request('0', SERVER_SHUTDOWN);
      var response = handler.handleRequest(request);
      expect(response, isResponseSuccess('0'));
      // server is down
      expect(server.running, isFalse);
    });
  });
}
