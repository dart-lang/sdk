// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';
import 'post_event_custom_stream_script.dart' as script;

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'post_event_custom_stream_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  Future<Isolate> getIsolate(VmService service) async {
    while (true) {
      final vm = await service.getVM();
      if (vm.isolates!.isNotEmpty) {
        final isolateId = vm.isolates!.first.id!;
        Isolate isolate;
        bool retry;
        do {
          isolate = await service.getIsolate(isolateId);
          retry = isolate.pauseEvent?.kind != EventKind.kPauseStart;
          if (retry) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } while (retry);
        return isolate;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  test('sends a postEvent over a custom stream to multiple listeners',
      () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);

    final service1 = await vmServiceConnectUri(dds.wsUri.toString());
    final service2 = await vmServiceConnectUri(dds.wsUri.toString());
    final completer1 = Completer<Event>();
    final completer2 = Completer<Event>();
    final isolateId = (await getIsolate(service1)).id!;

    await service1.streamListen(script.customStreamId);
    service1.onEvent(script.customStreamId).listen((event) {
      completer1.complete(event);
    });
    await service2.streamListen(script.customStreamId);
    service2.onEvent(script.customStreamId).listen((event) {
      completer2.complete(event);
    });

    await service1.resume(isolateId);

    final event1 = await completer1.future;
    final event2 = await completer2.future;

    expect(event1.extensionKind, equals(script.eventKind));
    expect(event1.extensionData?.data, equals(script.eventData));

    expect(event2.extensionKind, equals(script.eventKind));
    expect(event2.extensionData?.data, equals(script.eventData));
  });

  test('can cancel custom stream listeners', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service1 = await vmServiceConnectUri(dds.wsUri.toString());
    (await getIsolate(service1)).id!;

    await service1.streamListen(script.customStreamId);

    // We should be able to cancel
    await service1.streamCancel(script.customStreamId);

    try {
      await service1.streamCancel(script.customStreamId);
      fail('Re-Canceling the custom stream should have failed');
    } on RPCError catch (e) {
      expect(
        e.message,
        'Stream not subscribed',
      );
    }
  });

  test('canceling a custom stream does not cancel other listeners', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service1 = await vmServiceConnectUri(dds.wsUri.toString());
    final isolateId = (await getIsolate(service1)).id!;
    final extensionCompleter = Completer<Event>();

    await service1.streamListen(script.customStreamId);
    await service1.streamListen('Extension');
    service1.onEvent('Extension').listen((event) {
      extensionCompleter.complete(event);
    });

    await service1.streamCancel(script.customStreamId);

    await service1.resume(isolateId);

    final event1 = await extensionCompleter.future;

    expect(event1.extensionKind, equals(script.eventKind));
    expect(event1.extensionData?.data, equals(script.eventData));
  });

  test('Canceling a normal stream does not cancel custom listeners', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service1 = await vmServiceConnectUri(dds.wsUri.toString());
    final isolateId = (await getIsolate(service1)).id!;
    final customStreamCompleter = Completer<Event>();

    await service1.streamListen(script.customStreamId);
    await service1.streamListen('Extension');
    service1.onEvent(script.customStreamId).listen((event) {
      customStreamCompleter.complete(event);
    });

    await service1.streamCancel('Extension');

    await service1.resume(isolateId);

    final event1 = await customStreamCompleter.future;

    expect(event1.extensionKind, equals(script.eventKind));
    expect(event1.extensionData?.data, equals(script.eventData));
  });
}
