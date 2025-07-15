// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:dtd/dtd.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late ToolingDaemonTestProcess toolingDaemonProcess;
  late DartToolingDaemon client;
  late String? dtdSecret;

  Future<void> startDtd({bool unrestricted = false}) async {
    toolingDaemonProcess = ToolingDaemonTestProcess(unrestricted: unrestricted);
    await toolingDaemonProcess.start();
    client = await DartToolingDaemon.connect(toolingDaemonProcess.uri);
    dtdSecret = toolingDaemonProcess.trustedSecret;
  }

  group(ConnectedAppServiceConstants.serviceName, () {
    tearDown(() async {
      toolingDaemonProcess.kill();
    });

    group('restricted mode (default)', () {
      setUp(() async {
        await startDtd();
      });

      group(ConnectedAppServiceConstants.registerVmService, () {
        test('succeeds', () async {
          final testApp = DartCliAppProcess();
          await testApp.start();
          final response = await client.registerVmService(
            uri: testApp.vmServiceUri,
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
        });

        test('succeeds for URI that is already registered', () async {
          final testApp = DartCliAppProcess();
          await testApp.start();
          var response = await client.registerVmService(
            uri: testApp.vmServiceUri,
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
          expect(
            (await client.getVmServices())
                .vmServicesInfos
                .map((s) => s.toJson()),
            [
              {'uri': testApp.vmServiceUri},
            ],
          );

          response = await client.registerVmService(
            uri: testApp.vmServiceUri,
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
          expect(
            (await client.getVmServices())
                .vmServicesInfos
                .map((s) => s.toJson()),
            [
              {'uri': testApp.vmServiceUri},
            ],
          );
        });

        test('throws exception for invalid secret', () {
          expect(
            () => client.registerVmService(
              uri: 'test_uri',
              secret: 'fake_secret',
            ),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
        });

        test('throws exception for invalid URI', () async {
          expect(
            () => client.registerVmService(uri: 'invalid', secret: dtdSecret!),
            throwsAnRpcError(RpcErrorCodes.kConnectionFailed),
          );
        });
      });

      group(ConnectedAppServiceConstants.unregisterVmService, () {
        test('succeeds', () async {
          final testApp = DartCliAppProcess();
          await testApp.start();
          var response = await client.registerVmService(
            uri: testApp.vmServiceUri,
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
          expect(
            (await client.getVmServices())
                .vmServicesInfos
                .map((s) => s.toJson()),
            [
              {'uri': testApp.vmServiceUri},
            ],
          );

          response = await client.unregisterVmService(
            uri: testApp.vmServiceUri,
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
          expect((await client.getVmServices()).vmServicesInfos, isEmpty);
        });

        test('succeeds for URI that is not in the registry', () async {
          final response = await client.unregisterVmService(
            uri: 'some_uri',
            secret: dtdSecret!,
          );
          expect(response.type, 'Success');
          expect(response.value, null);
        });

        test('throws exception for invalid secret', () {
          expect(
            () => client.unregisterVmService(
              uri: 'test_uri',
              secret: 'fake_secret',
            ),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
        });
      });
    });

    group('unrestriced mode', () {
      setUp(() async {
        await startDtd(unrestricted: true);
      });

      test(
          '${ConnectedAppServiceConstants.registerVmService} succeeds with '
          'invalid secret', () async {
        final testApp = DartCliAppProcess();
        await testApp.start();
        final response = await client.registerVmService(
          uri: testApp.vmServiceUri,
          secret: 'invalid secret',
        );
        expect(response.type, 'Success');
        expect(response.value, null);
      });

      test(
          '${ConnectedAppServiceConstants.unregisterVmService} succeeds with '
          'invalid secret', () async {
        final response = await client.unregisterVmService(
          // The URI does not need to be a real URI to test this case.
          uri: 'some_uri',
          secret: 'invalid secret',
        );
        expect(response.type, 'Success');
        expect(response.value, null);
      });
    });

    test(ConnectedAppServiceConstants.getVmServices, () async {
      await startDtd();

      final testApp1 = DartCliAppProcess();
      await testApp1.start();
      var response = await client.registerVmService(
        uri: testApp1.vmServiceUri,
        name: 'app 1',
        secret: dtdSecret!,
      );
      expect(response.type, 'Success');
      expect(response.value, null);

      final testApp2 = DartCliAppProcess();
      await testApp2.start();
      response = await client.registerVmService(
        uri: testApp2.vmServiceUri,
        exposedUri: testApp2.vmServiceUri,
        secret: dtdSecret!,
      );
      expect(response.type, 'Success');
      expect(response.value, null);

      final servicesResponse = await client.getVmServices();
      expect(
        servicesResponse.vmServicesInfos.map((s) => s.toJson()),
        [
          {'uri': testApp1.vmServiceUri, 'name': 'app 1'},
          {'uri': testApp2.vmServiceUri, 'exposedUri': testApp2.vmServiceUri},
        ],
      );
    });

    group('sends stream updates', () {
      late StreamController<DTDEvent> eventStream;
      late StreamQueue<DTDEvent> events;
      StreamSubscription<DTDEvent>? subscription;

      setUp(() async {
        await startDtd();
        eventStream = StreamController<DTDEvent>();
        events = StreamQueue<DTDEvent>(eventStream.stream);
      });

      tearDown(() async {
        await events.cancel();
        await eventStream.close();
        await subscription?.cancel();
      });

      test('for register and unregister events', () async {
        var eventsCount = 0;
        subscription = client.onVmServiceUpdate().listen((e) {
          eventStream.add(e);
          eventsCount++;
        });
        await client.streamListen(ConnectedAppServiceConstants.serviceName);

        expect(eventsCount, 0);

        final testApp1 = DartCliAppProcess();
        await testApp1.start();
        var response = await client.registerVmService(
          uri: testApp1.vmServiceUri,
          name: 'name1',
          secret: dtdSecret!,
        );
        expect(response.type, 'Success');
        expect(response.value, null);

        var next = await events.next;
        expect(eventsCount, 1);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceRegistered,
            'data': {
              'uri': testApp1.vmServiceUri,
              'exposedUri': null,
              'name': 'name1',
            },
            'timestamp': isNotNull,
          },
        );

        final testApp2 = DartCliAppProcess();
        await testApp2.start();
        response = await client.registerVmService(
          uri: testApp2.vmServiceUri,
          exposedUri: testApp2.vmServiceUri,
          secret: dtdSecret!,
          name: 'name2',
        );
        expect(response.type, 'Success');
        expect(response.value, null);

        next = await events.next;
        expect(eventsCount, 2);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceRegistered,
            'data': {
              'uri': testApp2.vmServiceUri,
              'exposedUri': testApp2.vmServiceUri,
              'name': 'name2',
            },
            'timestamp': isNotNull,
          },
        );

        response = await client.unregisterVmService(
          uri: testApp1.vmServiceUri,
          secret: dtdSecret!,
        );
        expect(response.type, 'Success');
        expect(response.value, null);

        next = await events.next;
        expect(eventsCount, 3);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceUnregistered,
            'data': {
              'uri': testApp1.vmServiceUri,
              'exposedUri': null,
              'name': 'name1',
            },
            'timestamp': isNotNull,
          },
        );

        // This should not send a
        // [ConnectedAppServiceConstants.vmServiceUnregistered] event
        // from the `VmService.onDone` handler added in [ConnectedAppService]
        // because this VM Service was already unregistered above. This
        // behavior is validated by checking the next event after calling
        // `testApp2.kill()` below.
        testApp1.kill();

        // Sends a [ConnectedAppServiceConstants.vmServiceUnregistered] event
        // from the `VmService.onDone` handler added in [ConnectedAppService].
        testApp2.kill();
        next = await events.next;
        expect(eventsCount, 4);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceUnregistered,
            'data': {
              'uri': testApp2.vmServiceUri,
              'exposedUri': testApp2.vmServiceUri,
              'name': 'name2',
            },
            'timestamp': isNotNull,
          },
        );
      });

      test('only after subscription has been established', () async {
        var eventsCount = 0;
        expect(eventsCount, 0);

        // This event will be dropped.
        final testApp1 = DartCliAppProcess();
        await testApp1.start();
        var response = await client.registerVmService(
          uri: testApp1.vmServiceUri,
          secret: dtdSecret!,
        );
        expect(response.type, 'Success');
        expect(response.value, null);

        // This event will be dropped.
        final testApp2 = DartCliAppProcess();
        await testApp2.start();
        response = await client.registerVmService(
          uri: testApp2.vmServiceUri,
          secret: dtdSecret!,
        );
        expect(response.type, 'Success');
        expect(response.value, null);

        // Await a zero delay to release the Dart event loop, ensuring the
        // stream notifications from above have already occurred before we add
        // a stream subscription.
        await Future<void>.delayed(Duration.zero);

        // Subscribe late and verify that we do not get any previous events.
        expect(eventsCount, 0);
        subscription = client.onVmServiceUpdate().listen((e) {
          eventStream.add(e);
          eventsCount++;
        });
        await client.streamListen(ConnectedAppServiceConstants.serviceName);

        expect(eventsCount, 0);

        // We expect to recieve the this event.
        testApp1.kill();
        var next = await events.next;
        expect(eventsCount, 1);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceUnregistered,
            'data': {
              'uri': testApp1.vmServiceUri,
              'exposedUri': null,
              'name': null,
            },
            'timestamp': isNotNull,
          },
        );

        // We expect to recieve the this event.
        testApp2.kill();
        next = await events.next;
        expect(eventsCount, 2);
        expect(
          jsonDecode(next.toString()),
          {
            'stream': ConnectedAppServiceConstants.serviceName,
            'kind': ConnectedAppServiceConstants.vmServiceUnregistered,
            'data': {
              'uri': testApp2.vmServiceUri,
              'exposedUri': null,
              'name': null,
            },
            'timestamp': isNotNull,
          },
        );
      });
    });
  });
}
