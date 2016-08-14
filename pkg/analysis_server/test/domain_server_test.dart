// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.server;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:plugin/manager.dart';
import 'package:unittest/unittest.dart';

import 'mock_sdk.dart';
import 'mocks.dart';
import 'utils.dart';

main() {
  AnalysisServer server;
  ServerDomainHandler handler;

  initializeTestEnvironment();

  setUp(() {
    var serverChannel = new MockServerChannel();
    var resourceProvider = new MemoryResourceProvider();
    ExtensionManager manager = new ExtensionManager();
    ServerPlugin serverPlugin = new ServerPlugin();
    manager.processPlugins([serverPlugin]);
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        null,
        serverPlugin,
        new AnalysisServerOptions(),
        new DartSdkManager('', false, (_) => new MockSdk()),
        InstrumentationService.NULL_SERVICE);
    handler = new ServerDomainHandler(server);
  });

  group('ServerDomainHandler', () {
    test('getVersion', () {
      var request = new ServerGetVersionParams().toRequest('0');
      var response = handler.handleRequest(request);
      expect(
          response.toJson(),
          equals({
            Response.ID: '0',
            Response.RESULT: {VERSION: AnalysisServer.VERSION}
          }));
    });

    group('setSubscriptions', () {
      test('invalid service name', () {
        Request request = new Request('0', SERVER_SET_SUBSCRIPTIONS, {
          SUBSCRIPTIONS: ['noSuchService']
        });
        var response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
      });

      test('success', () {
        expect(server.serverServices, isEmpty);
        // send request
        Request request =
            new ServerSetSubscriptionsParams([ServerService.STATUS])
                .toRequest('0');
        var response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
        // set of services has been changed
        expect(server.serverServices, contains(ServerService.STATUS));
      });
    });

    test('shutdown', () {
      expect(server.running, isTrue);
      // send request
      var request = new ServerShutdownParams().toRequest('0');
      var response = handler.handleRequest(request);
      expect(response, isResponseSuccess('0'));
      // server is down
      expect(server.running, isFalse);
    });
  });
}
