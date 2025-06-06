// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

class SendReceiveBytes extends AsyncBenchmarkBase {
  SendReceiveBytes(
    String name, {
    required this.size,
    required this.useTransferable,
  }) : super(name);

  @override
  Future<void> run() async {
    await helper.run();
  }

  @override
  Future<void> setup() async {
    helper = SendReceiveHelper(size, useTransferable: useTransferable);
    await helper.setup();
  }

  @override
  Future<void> teardown() async {
    await helper.finalize();
  }

  final bool useTransferable;
  final int size;
  late SendReceiveHelper helper;
}

class StartMessage {
  final SendPort sendPort;
  final bool useTransferable;
  final int size;

  StartMessage(this.sendPort, this.useTransferable, this.size);
}

// Measures how long sending and receiving of [size]-length Uint8List takes.
class SendReceiveHelper {
  SendReceiveHelper(this.size, {required this.useTransferable});

  Future<void> setup() async {
    data = Uint8List(size);

    port = ReceivePort();
    inbox = StreamIterator<dynamic>(port);
    workerCompleted = Completer<bool>();
    workerExitedPort = ReceivePort()
      ..listen((_) => workerCompleted.complete(true));
    worker = await Isolate.spawn(
      isolate,
      StartMessage(port.sendPort, useTransferable, size),
      onExit: workerExitedPort.sendPort,
    );
    await inbox.moveNext();
    outbox = inbox.current;
  }

  Future<void> finalize() async {
    outbox.send(null);
    await workerCompleted.future;
    workerExitedPort.close();
    port.close();
  }

  // Send data to worker, wait for an answer.
  Future<void> run() async {
    outbox.send(packageList(data, useTransferable));
    await inbox.moveNext();
    final received = inbox.current;
    if (useTransferable) {
      final TransferableTypedData transferable = received;
      transferable.materialize();
    }
  }

  late Uint8List data;
  late ReceivePort port;
  late StreamIterator<dynamic> inbox;
  late SendPort outbox;
  late Isolate worker;
  late Completer<bool> workerCompleted;
  late ReceivePort workerExitedPort;
  final int size;
  final bool useTransferable;
}

Object packageList(Uint8List data, bool useTransferable) =>
    useTransferable ? TransferableTypedData.fromList(<Uint8List>[data]) : data;

Future<void> isolate(StartMessage startMessage) async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final data = Uint8List.view(Uint8List(startMessage.size).buffer);

  startMessage.sendPort.send(port.sendPort);
  while (true) {
    await inbox.moveNext();
    final received = inbox.current;
    if (received == null) {
      break;
    }
    if (startMessage.useTransferable) {
      final TransferableTypedData transferable = received;
      transferable.materialize();
    }
    startMessage.sendPort.send(packageList(data, startMessage.useTransferable));
  }
  port.close();
}

class SizeName {
  const SizeName(this.size, this.name);

  final int size;
  final String name;
}

const List<SizeName> sizes = <SizeName>[
  SizeName(1 * 1024, '1KB'),
  SizeName(10 * 1024, '10KB'),
  SizeName(100 * 1024, '100KB'),
  SizeName(1 * 1024 * 1024, '1MB'),
  SizeName(10 * 1024 * 1024, '10MB'),
  SizeName(100 * 1024 * 1024, '100MB'),
];

Future<void> main() async {
  for (final sizeName in sizes) {
    await SendReceiveBytes(
      'Isolate.SendReceiveBytes${sizeName.name}',
      size: sizeName.size,
      useTransferable: false,
    ).report();
    await SendReceiveBytes(
      'Isolate.SendReceiveBytesTransferable${sizeName.name}',
      size: sizeName.size,
      useTransferable: true,
    ).report();
  }
}
