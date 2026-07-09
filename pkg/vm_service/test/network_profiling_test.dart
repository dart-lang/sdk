// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'network_profiling_lib.dart' as testee_lib;

const String kClearSocketProfileRPC = 'ext.dart.io.clearSocketProfile';
const String kGetVersionRPC = 'ext.dart.io.getVersion';
const String kSocketProfilingEnabledRPC = 'ext.dart.io.socketProfilingEnabled';

Future<void> waitForStreamEvent(
  VmService service,
  IsolateRef isolateRef,
  bool state,
) async {
  final completer = Completer<void>();
  final isolateId = isolateRef.id!;
  late StreamSubscription sub;
  sub = service.onExtensionEvent.listen((event) {
    expect(event.extensionKind, 'SocketProfilingStateChange');
    expect(event.extensionData!.data['isolateId'], isolateRef.id);
    expect(event.extensionData!.data['enabled'], state);
    sub.cancel();
    completer.complete();
  });
  await service.streamListen(EventStreams.kExtension);
  await service.socketProfilingEnabled(isolateId, state);
  await completer.future;
  await service.streamCancel(EventStreams.kExtension);
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'network_profiling_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolate = await service.getIsolate(isolateRef.id!);
      // Ensure all network profiling service extensions are registered.
      expect(isolate.extensionRPCs!.length, greaterThanOrEqualTo(5));
      expect(isolate.extensionRPCs!.contains(kClearSocketProfileRPC), isTrue);
      expect(isolate.extensionRPCs!.contains(kGetVersionRPC), isTrue);
      expect(
        isolate.extensionRPCs!.contains(kSocketProfilingEnabledRPC),
        isTrue,
      );
    })
        // Test getSocketProfiler
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final socketProfile = await service.getSocketProfile(isolateRef.id!);
      expect(socketProfile.sockets.isEmpty, isTrue);
    })
        // Exercise methods naively
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final version = await service.getDartIOVersion(isolateId);
      expect(version.major! >= 1, true);
      expect(version.minor! >= 0, true);
      await service.clearSocketProfile(isolateId);
      await service.getSocketProfile(isolateId);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final initial = (await service.socketProfilingEnabled(isolateId)).enabled;
      await waitForStreamEvent(service, isolateRef, !initial);
      expect(
        (await service.socketProfilingEnabled(isolateId)).enabled,
        !initial,
      );
      await waitForStreamEvent(service, isolateRef, initial);
      expect(
        (await service.socketProfilingEnabled(isolateId)).enabled,
        initial,
      );
    }).run(testeeMain: testee_lib.main);
