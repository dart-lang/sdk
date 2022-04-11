// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/devtools_server.dart';
import 'package:dds/src/devtools/machine_mode_command_handler.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:devtools_shared/devtools_test_utils.dart';
import 'package:test/test.dart';

import 'devtools_server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  testController = DevToolsServerTestController();

  setUp(() async {
    await testController.setUp();
  });

  tearDown(() async {
    await testController.tearDown();
  });

  test('registers service', () async {
    final serverResponse = await testController.send(
      'vm.register',
      {'uri': testController.appFixture.serviceUri.toString()},
    );
    expect(serverResponse['success'], isTrue);

    // Expect the VM service to see the launchDevTools service registered.
    expect(
      testController.registeredServices,
      contains(DevToolsServer.launchDevToolsService),
    );
  }, timeout: const Timeout.factor(10));

  test('can bind to next available port', () async {
    final server1 = await DevToolsServerDriver.create(port: 8855);
    try {
      // Wait for the first server to start up and ensure it got the
      // expected port.
      final event1 = (await server1.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      expect(event1['params']['port'], 8855);

      // Now spawn another requesting the same port and ensure it got the next
      // port number.
      final server2 = await DevToolsServerDriver.create(
        port: 8855,
        tryPorts: 2,
      );
      try {
        final event2 = (await server2.stdout.firstWhere(
          (map) => map!['event'] == 'server.started',
        ))!;

        expect(event2['params']['port'], 8856);
      } finally {
        server2.kill();
      }
    } finally {
      server1.kill();
    }
  }, timeout: const Timeout.factor(10));

  test('allows embedding without flag', () async {
    final server = await DevToolsServerDriver.create();
    final httpClient = HttpClient();
    late HttpClientResponse resp;
    try {
      final startedEvent = (await server.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];

      final req = await httpClient.get(host, port, '/');
      resp = await req.close();
      expect(resp.headers.value('x-frame-options'), isNull);
    } finally {
      httpClient.close();
      await resp.drain();
      server.kill();
    }
  }, timeout: const Timeout.factor(10));

  test('does not allow embedding with flag', () async {
    final server = await DevToolsServerDriver.create(
      additionalArgs: ['--no-allow-embedding'],
    );
    final httpClient = HttpClient();
    late HttpClientResponse resp;
    try {
      final startedEvent = (await server.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];

      final req = await httpClient.get(host, port, '/');
      resp = await req.close();
      expect(resp.headers.value('x-frame-options'), 'SAMEORIGIN');
    } finally {
      httpClient.close();
      await resp.drain();
      server.kill();
    }
  }, timeout: const Timeout.factor(10));

  test('Analytics Survey', () async {
    var serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': 'copyAndCreateDevToolsFile',
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['success'], isTrue);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiSetActiveSurvey,
      'value': 'Q3-2019',
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['success'], isTrue);
    expect(serverResponse['activeSurvey'], 'Q3-2019');

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiIncrementSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 1);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiIncrementSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 2);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiGetSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 2);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiGetSurveyActionTaken,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyActionTaken'], isFalse);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': apiSetSurveyActionTaken,
      'value': json.encode(true),
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyActionTaken'], isTrue);

    serverResponse = await testController.send('devTools.survey', {
      'surveyRequest': MachineModeCommandHandler.restoreDevToolsFile,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['success'], isTrue);
    expect(
      serverResponse['content'],
      '{\n'
      '  \"Q3-2019\": {\n'
      '    \"surveyActionTaken\": true,\n'
      '    \"surveyShownCount\": 2\n'
      '  }\n'
      '}\n',
    );
  }, timeout: const Timeout.factor(10));

  for (final bool useVmService in [true, false]) {
    group('Server (${useVmService ? 'VM Service' : 'API'})', () {
      test('can launch on a specific page', () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a request to launch at a certain page.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );

        final serverResponse =
            await testController.waitForClients(requiredPage: 'memory');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'memory');
      }, timeout: const Timeout.factor(10));

      test('can switch page', () async {
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Launch on the memory page and wait for the connection.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );
        await testController.waitForClients(requiredPage: 'memory');

        // Re-launch, allowing reuse and with a different page.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          page: 'logging',
        );

        final serverResponse =
            await testController.waitForClients(requiredPage: 'logging');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'logging');
      }, timeout: const Timeout.factor(20));

      test('Server reuses DevTools instance if already connected to same VM',
          () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a request to launch DevTools in a browser.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
        );

        {
          final serverResponse = await testController.waitForClients(
            requiredConnectionState: true,
          );
          expect(serverResponse['clients'], hasLength(1));
        }

        // Request again, allowing reuse, and server emits an event saying the
        // window was reused.
        final launchResponse = await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
        );
        expect(launchResponse['reused'], isTrue);

        // Ensure there's still only one connection (eg. we didn't spawn a new one
        // we reused the existing one).
        final serverResponse =
            await testController.waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
      }, timeout: const Timeout.factor(20));

      test('Server does not reuse DevTools instance if embedded', () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Spawn an embedded version of DevTools in a browser.
        final event = await testController.serverStartedEvent.future;
        final devToolsUri =
            'http://${event['params']['host']}:${event['params']['port']}';
        final launchUrl = '$devToolsUri/?embed=true&page=logging'
            '&uri=${Uri.encodeQueryComponent(testController.appFixture.serviceUri.toString())}';
        final chrome = await Chrome.locate()!.start(url: launchUrl);
        try {
          {
            final serverResponse = await testController.waitForClients(
              requiredConnectionState: true,
            );
            expect(serverResponse['clients'], hasLength(1));
          }

          // Send a request to the server to launch and ensure it did
          // not reuse the existing connection. Launch it on a different page
          // so we can easily tell once this one has connected.
          final launchResponse = await testController.sendLaunchDevToolsRequest(
            useVmService: useVmService,
            reuseWindows: true,
            page: 'memory',
          );
          expect(launchResponse['reused'], isFalse);

          // Ensure there's now two connections.
          final serverResponse = await testController.waitForClients(
            requiredConnectionState: true,
            requiredPage: 'memory',
          );
          expect(serverResponse['clients'], hasLength(2));
        } finally {
          chrome.kill();
        }
      }, timeout: const Timeout.factor(20));

      test('Server reuses DevTools instance if not connected to a VM',
          () async {
        // Register the VM.
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a request to launch DevTools in a browser.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
        );

        // Wait for the DevTools to inform server that it's connected.
        await testController.waitForClients(requiredConnectionState: true);

        // Terminate the VM.
        await testController.appFixture.teardown();

        // Ensure the client is marked as disconnected.
        await testController.waitForClients(requiredConnectionState: false);

        // Start up a new app.
        await testController.startApp();
        await testController.send(
          'vm.register',
          {'uri': testController.appFixture.serviceUri.toString()},
        );

        // Send a new request to launch.
        await testController.sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          notify: true,
        );

        // Ensure we now have a single connected client.
        final serverResponse =
            await testController.waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          testController.appFixture.serviceUri.toString(),
        );
      }, timeout: const Timeout.factor(20));
    });
  }
}
