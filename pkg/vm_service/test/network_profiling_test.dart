// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

const String content = 'some random content';
const String udpContent = 'aghfkjdb';
const String kClearSocketProfileRPC = 'ext.dart.io.clearSocketProfile';
const String kGetSocketProfileRPC = 'ext.dart.io.getSocketProfile';
const String kGetVersionRPC = 'ext.dart.io.getVersion';
const String kSocketProfilingEnabledRPC = 'ext.dart.io.socketProfilingEnabled';
const String localhost = '127.0.0.1';

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

Future<void> setup() async {}

Future<void> socketTest() async {
  // Socket
  final serverSocket = await io.ServerSocket.bind(localhost, 0);
  final socket = await io.Socket.connect(localhost, serverSocket.port);
  socket.write(content);
  await socket.flush();
  socket.destroy();

  // rawDatagram
  final doneCompleter = Completer<void>();
  final server = await io.RawDatagramSocket.bind(localhost, 0);
  server.listen((io.RawSocketEvent event) {
    if (event == io.RawSocketEvent.read) {
      server.receive();
      if (!doneCompleter.isCompleted) {
        doneCompleter.complete();
      }
    }
  });
  final client = await io.RawDatagramSocket.bind(localhost, 0);
  client.send(
    utf8.encode(udpContent),
    io.InternetAddress(localhost),
    server.port,
  );
  client.send([1, 2, 3], io.InternetAddress(localhost), server.port);

  // Wait for datagram to arrive.
  await doneCompleter.future;
  // Post finish event
  postEvent('socketTest', {'socket': 'test'});
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    // Ensure all network profiling service extensions are registered.
    expect(isolate.extensionRPCs!.length, greaterThanOrEqualTo(5));
    expect(isolate.extensionRPCs!.contains(kClearSocketProfileRPC), isTrue);
    expect(isolate.extensionRPCs!.contains(kGetVersionRPC), isTrue);
    expect(isolate.extensionRPCs!.contains(kSocketProfilingEnabledRPC), isTrue);
  },

  // Test getSocketProfiler
  (VmService service, IsolateRef isolateRef) async {
    final socketProfile = await service.getSocketProfile(isolateRef.id!);
    expect(socketProfile.sockets.isEmpty, isTrue);
  },
  // Exercise methods naively
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final version = await service.getDartIOVersion(isolateId);
    expect(version.major! >= 1, true);
    expect(version.minor! >= 0, true);
    await service.clearSocketProfile(isolateId);
    await service.getSocketProfile(isolateId);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final initial = (await service.socketProfilingEnabled(isolateId)).enabled;
    await waitForStreamEvent(service, isolateRef, !initial);
    expect((await service.socketProfilingEnabled(isolateId)).enabled, !initial);
    await waitForStreamEvent(service, isolateRef, initial);
    expect((await service.socketProfilingEnabled(isolateId)).enabled, initial);
  },
  // TODO(bkonyi): fully port observatory test for socket profiling.
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'network_profiling_test.dart',
      testeeBefore: setup,
    );
