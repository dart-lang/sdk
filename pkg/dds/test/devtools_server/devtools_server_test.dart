// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dds/devtools_server.dart';
import 'package:dds/src/devtools/machine_mode_command_handler.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:devtools_shared/devtools_test_utils.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'devtools_server_driver.dart';

late CliAppFixture appFixture;
late DevToolsServerDriver server;
final completers = <String, Completer<Map<String, dynamic>>>{};

/// A broadcast stream controller for streaming events from the server.
late StreamController<Map<String, dynamic>> eventController;

/// A broadcast stream of events from the server.
///
/// Listening for "server.started" events on this stream may be unreliable
/// because it may have occurred before the test starts. Use the
/// [serverStartedEvent] instead.
Stream<Map<String, dynamic>> get events => eventController.stream;

/// Completer that signals when the server started event has been received.
late Completer<Map<String, dynamic>> serverStartedEvent;

final Map<String, String> registeredServices = {};

// A list of PIDs for Chrome instances spawned by tests that should be
// cleaned up.
final List<int> browserPids = [];

void main() {
  late StreamSubscription<String> stderrSub;
  late StreamSubscription<Map<String, dynamic>?> stdoutSub;

  setUp(() async {
    serverStartedEvent = Completer<Map<String, dynamic>>();
    eventController = StreamController<Map<String, dynamic>>.broadcast();

    // Start the command-line server.
    server = await DevToolsServerDriver.create();

    // Fail tests on any stderr.
    stderrSub = server.stderr.listen((text) => throw 'STDERR: $text');
    stdoutSub = server.stdout.listen((map) {
      if (map!.containsKey('id')) {
        if (map.containsKey('result')) {
          completers[map['id']]!.complete(map['result']);
        } else {
          completers[map['id']]!.completeError(map['error']);
        }
      } else if (map.containsKey('event')) {
        if (map['event'] == 'server.started') {
          serverStartedEvent.complete(map);
        }
        eventController.add(map);
      }
    });

    await serverStartedEvent.future;
    await _startApp();
  });

  tearDown(() async {
    browserPids
      ..forEach((pid) => Process.killPid(pid, ProcessSignal.sigkill))
      ..clear();
    await stdoutSub.cancel();
    await stderrSub.cancel();
    server.kill();
    await appFixture.teardown();
  });

  test('registers service', () async {
    final serverResponse = await _send(
      'vm.register',
      {'uri': appFixture.serviceUri.toString()},
    );
    expect(serverResponse['success'], isTrue);

    // Expect the VM service to see the launchDevTools service registered.
    expect(registeredServices, contains(DevToolsServer.launchDevToolsService));
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
    var serverResponse = await _send('devTools.survey', {
      'surveyRequest': 'copyAndCreateDevToolsFile',
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['success'], isTrue);

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiSetActiveSurvey,
      'value': 'Q3-2019',
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['success'], isTrue);
    expect(serverResponse['activeSurvey'], 'Q3-2019');

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiIncrementSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 1);

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiIncrementSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 2);

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiGetSurveyShownCount,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyShownCount'], 2);

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiGetSurveyActionTaken,
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyActionTaken'], isFalse);

    serverResponse = await _send('devTools.survey', {
      'surveyRequest': apiSetSurveyActionTaken,
      'value': json.encode(true),
    });
    expect(serverResponse, isNotNull);
    expect(serverResponse['activeSurvey'], 'Q3-2019');
    expect(serverResponse['surveyActionTaken'], isTrue);

    serverResponse = await _send('devTools.survey', {
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
      test(
          'DevTools connects back to server API and registers that it is connected',
          () async {
        // Register the VM.
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a request to launch DevTools in a browser.
        await _sendLaunchDevToolsRequest(useVmService: useVmService);

        final serverResponse =
            await _waitForClients(requiredConnectionState: true);
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          appFixture.serviceUri.toString(),
        );
      }, timeout: const Timeout.factor(10));

      test('can launch on a specific page', () async {
        // Register the VM.
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a request to launch at a certain page.
        await _sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );

        final serverResponse = await _waitForClients(requiredPage: 'memory');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'memory');
      }, timeout: const Timeout.factor(10));

      test('can switch page', () async {
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Launch on the memory page and wait for the connection.
        await _sendLaunchDevToolsRequest(
          useVmService: useVmService,
          page: 'memory',
        );
        await _waitForClients(requiredPage: 'memory');

        // Re-launch, allowing reuse and with a different page.
        await _sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          page: 'logging',
        );

        final serverResponse = await _waitForClients(requiredPage: 'logging');
        expect(serverResponse, isNotNull);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          appFixture.serviceUri.toString(),
        );
        expect(serverResponse['clients'][0]['currentPage'], 'logging');
      }, timeout: const Timeout.factor(20));

      test('DevTools reports disconnects from a VM', () async {
        // Register the VM.
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a request to launch DevTools in a browser.
        await _sendLaunchDevToolsRequest(useVmService: useVmService);

        // Wait for the DevTools to inform server that it's connected.
        await _waitForClients(requiredConnectionState: true);

        // Terminate the VM.
        await appFixture.teardown();

        // Ensure the client is marked as disconnected.
        final serverResponse =
            await _waitForClients(requiredConnectionState: false);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isFalse);
        expect(serverResponse['clients'][0]['vmServiceUri'], isNull);
      }, timeout: const Timeout.factor(20));

      test('server removes clients that disconnect from the API', () async {
        final event = await serverStartedEvent.future;

        // Spawn our own Chrome process so we can terminate it.
        final devToolsUri =
            'http://${event['params']['host']}:${event['params']['port']}';
        final chrome = await Chrome.locate()!.start(url: devToolsUri);

        // Wait for DevTools to inform server that it's connected.
        await _waitForClients();

        // Close the browser, which will disconnect DevTools SSE connection
        // back to the server.
        chrome.kill();

        // Await a long delay to wait for the SSE client to close.
        await delay(duration: const Duration(seconds: 20));

        // Ensure the client is completely removed from the list.
        await _waitForClients(expectNone: true, useLongTimeout: true);
      }, timeout: const Timeout.factor(20));

      test('Server reuses DevTools instance if already connected to same VM',
          () async {
        // Register the VM.
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a request to launch DevTools in a browser.
        await _sendLaunchDevToolsRequest(useVmService: useVmService);

        {
          final serverResponse = await _waitForClients(
            requiredConnectionState: true,
          );
          expect(serverResponse['clients'], hasLength(1));
        }

        // Request again, allowing reuse, and server emits an event saying the
        // window was reused.
        final launchResponse = await _sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
        );
        expect(launchResponse['reused'], isTrue);

        // Ensure there's still only one connection (eg. we didn't spawn a new one
        // we reused the existing one).
        final serverResponse =
            await _waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
      }, timeout: const Timeout.factor(20));

      test('Server does not reuse DevTools instance if embedded', () async {
        // Register the VM.
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Spawn an embedded version of DevTools in a browser.
        final event = await serverStartedEvent.future;
        final devToolsUri =
            'http://${event['params']['host']}:${event['params']['port']}';
        final launchUrl = '$devToolsUri/?embed=true&page=logging'
            '&uri=${Uri.encodeQueryComponent(appFixture.serviceUri.toString())}';
        final chrome = await Chrome.locate()!.start(url: launchUrl);
        try {
          {
            final serverResponse =
                await _waitForClients(requiredConnectionState: true);
            expect(serverResponse['clients'], hasLength(1));
          }

          // Send a request to the server to launch and ensure it did
          // not reuse the existing connection. Launch it on a different page
          // so we can easily tell once this one has connected.
          final launchResponse = await _sendLaunchDevToolsRequest(
            useVmService: useVmService,
            reuseWindows: true,
            page: 'memory',
          );
          expect(launchResponse['reused'], isFalse);

          // Ensure there's now two connections.
          final serverResponse = await _waitForClients(
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
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a request to launch DevTools in a browser.
        await _sendLaunchDevToolsRequest(useVmService: useVmService);

        // Wait for the DevTools to inform server that it's connected.
        await _waitForClients(requiredConnectionState: true);

        // Terminate the VM.
        await appFixture.teardown();

        // Ensure the client is marked as disconnected.
        await _waitForClients(requiredConnectionState: false);

        // Start up a new app.
        await _startApp();
        await _send('vm.register', {'uri': appFixture.serviceUri.toString()});

        // Send a new request to launch.
        await _sendLaunchDevToolsRequest(
          useVmService: useVmService,
          reuseWindows: true,
          notify: true,
        );

        // Ensure we now have a single connected client.
        final serverResponse =
            await _waitForClients(requiredConnectionState: true);
        expect(serverResponse['clients'], hasLength(1));
        expect(serverResponse['clients'][0]['hasConnection'], isTrue);
        expect(
          serverResponse['clients'][0]['vmServiceUri'],
          appFixture.serviceUri.toString(),
        );
      }, timeout: const Timeout.factor(20));
    });
  }
}

Future<Map<String, dynamic>> _sendLaunchDevToolsRequest({
  required bool useVmService,
  String? page,
  bool notify = false,
  bool reuseWindows = false,
}) async {
  print('grabbing client.launch event');
  final launchEvent = events.where((e) => e['event'] == 'client.launch').first;
  if (useVmService) {
    await appFixture.serviceConnection.callMethod(
      registeredServices[DevToolsServer.launchDevToolsService]!,
      args: {
        'reuseWindows': reuseWindows,
        'page': page,
        'notify': notify,
      },
    );
  } else {
    await _send(
      'devTools.launch',
      {
        'vmServiceUri': appFixture.serviceUri.toString(),
        'reuseWindows': reuseWindows,
        'page': page,
      },
    );
  }
  final response = await launchEvent;
  final pid = response['params']['pid'];
  if (pid != null) {
    browserPids.add(pid);
  }
  return response['params'];
}

Future<void> _startApp() async {
  final appUri =
      Platform.script.resolveUri(Uri.parse('../fixtures/empty_dart_app.dart'));
  appFixture = await CliAppFixture.create(appUri.path);

  // Track services method names as they're registered.
  appFixture.serviceConnection
      .onEvent(EventStreams.kService)
      .where((e) => e.kind == EventKind.kServiceRegistered)
      .listen((e) => registeredServices[e.service!] = e.method!);
  await appFixture.serviceConnection.streamListen(EventStreams.kService);
}

int nextId = 0;
Future<Map<String, dynamic>> _send(
  String method, [
  Map<String, dynamic>? params,
]) {
  final id = (nextId++).toString();
  completers[id] = Completer<Map<String, dynamic>>();
  server.write({'id': id.toString(), 'method': method, 'params': params});
  return completers[id]!.future;
}

// It may take time for the servers client list to be updated as the web app
// connects, so this helper just polls waiting for the expected state and
// then returns the client list.
Future<Map<String, dynamic>> _waitForClients({
  bool? requiredConnectionState,
  String? requiredPage,
  bool expectNone = false,
  bool useLongTimeout = false,
  Duration delayDuration = defaultDelay,
}) async {
  late Map<String, dynamic> serverResponse;

  final isOnPage = (client) => client['currentPage'] == requiredPage;
  final hasConnectionState = (client) => requiredConnectionState ?? false
      // If we require a connected client, also require a non-null page. This
      // avoids a race in tests where we may proceed to send messages to a client
      // that is not fully initialised.
      ? (client['hasConnection'] && client['currentPage'] != null)
      : !client['hasConnection'];

  await _waitFor(
    () async {
      // Await a short delay to give the client time to connect.
      await delay();

      serverResponse = await _send('client.list');
      final clients = serverResponse['clients'];
      return clients is List &&
          (clients.isEmpty == expectNone) &&
          (requiredPage == null || clients.any(isOnPage)) &&
          (requiredConnectionState == null || clients.any(hasConnectionState));
    },
    delayDuration: delayDuration,
  );

  return serverResponse;
}

Future<void> _waitFor(
  Future<bool> condition(), {
  Duration delayDuration = defaultDelay,
}) async {
  while (true) {
    if (await condition()) {
      return;
    }
    await delay(duration: delayDuration);
  }
}

const defaultDelay = Duration(milliseconds: 500);
