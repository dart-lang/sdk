// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/src/dart_io_extensions.dart';
import 'package:test/test.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String content = 'some random content';
const String udpContent = 'aghfkjdb';
const String kClearSocketProfileRPC = 'ext.dart.io.clearSocketProfile';
const String kGetSocketProfileRPC = 'ext.dart.io.getSocketProfile';
const String kGetVersionRPC = 'ext.dart.io.getVersion';
const String kPauseSocketProfilingRPC = 'ext.dart.io.pauseSocketProfiling';
const String kStartSocketProfilingRPC = 'ext.dart.io.startSocketProfiling';
const String localhost = '127.0.0.1';

Future<void> setup() async {}

Future<void> socketTest() async {
  // Socket
  var serverSocket = await io.ServerSocket.bind(localhost, 0);
  var socket = await io.Socket.connect(localhost, serverSocket.port);
  socket.write(content);
  await socket.flush();
  await socket.destroy();

  // rawDatagram
  final doneCompleter = Completer<void>();
  var server = await io.RawDatagramSocket.bind(localhost, 0);
  server.listen((io.RawSocketEvent event) {
    if (event == io.RawSocketEvent.read) {
      server.receive();
      if (!doneCompleter.isCompleted) {
        doneCompleter.complete();
      }
    }
  });
  var client = await io.RawDatagramSocket.bind(localhost, 0);
  client.send(utf8.encoder.convert(udpContent), io.InternetAddress(localhost),
      server.port);
  client.send([1, 2, 3], io.InternetAddress(localhost), server.port);

  // Wait for datagram to arrive.
  await doneCompleter.future;
  // Post finish event
  postEvent('socketTest', {'socket': 'test'});
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id);
    // Ensure all network profiling service extensions are registered.
    expect(isolate.extensionRPCs.length, greaterThanOrEqualTo(5));
    expect(isolate.extensionRPCs.contains(kClearSocketProfileRPC), isTrue);
    expect(isolate.extensionRPCs.contains(kGetVersionRPC), isTrue);
    expect(isolate.extensionRPCs.contains(kPauseSocketProfilingRPC), isTrue);
    expect(isolate.extensionRPCs.contains(kStartSocketProfilingRPC), isTrue);
    expect(isolate.extensionRPCs.contains(kPauseSocketProfilingRPC), isTrue);
  },

  // Test getSocketProfiler
  (VmService service, IsolateRef isolateRef) async {
    final socketProfile = await service.getSocketProfile(isolateRef.id);
    expect(socketProfile.sockets.isEmpty, isTrue);
  },
  // Exercise all methods naively
  (VmService service, IsolateRef isolateRef) async {
    final version = await service.getDartIOVersion(isolateRef.id);
    expect(version.major >= 1, true);
    expect(version.minor >= 0, true);
    await service.startSocketProfiling(isolateRef.id);
    await service.pauseSocketProfiling(isolateRef.id);
    await service.clearSocketProfile(isolateRef.id);
    await service.getSocketProfile(isolateRef.id);
  },
  // TODO(bkonyi): fully port observatory test for socket profiling.
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, testeeBefore: setup);
