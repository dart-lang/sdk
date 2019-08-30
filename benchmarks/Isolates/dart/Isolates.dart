// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart'
    show PrintEmitter, ScoreEmitter;
import 'package:meta/meta.dart';

class SendReceive extends AsyncBenchmarkBase {
  SendReceive(String name,
      {@required int this.size, @required bool this.useTransferable})
      : super(name);

  @override
  run() async {
    await helper.run();
  }

  @override
  setup() async {
    helper = SendReceiveHelper(size, useTransferable: useTransferable);
    await helper.setup();
  }

  @override
  teardown() async {
    await helper.finalize();
  }

  final bool useTransferable;
  final int size;
  SendReceiveHelper helper;
}

// Identical to BenchmarkBase from package:benchmark_harness but async.
abstract class AsyncBenchmarkBase {
  final String name;
  final ScoreEmitter emitter;

  run();
  setup();
  teardown();

  const AsyncBenchmarkBase(this.name, {this.emitter = const PrintEmitter()});

  // Returns the number of microseconds per call.
  Future<double> measureFor(int minimumMillis) async {
    int minimumMicros = minimumMillis * 1000;
    int iter = 0;
    Stopwatch watch = Stopwatch();
    watch.start();
    int elapsed = 0;
    while (elapsed < minimumMicros) {
      await run();
      elapsed = watch.elapsedMicroseconds;
      iter++;
    }
    return elapsed / iter;
  }

  // Measures the score for the benchmark and returns it.
  Future<double> measure() async {
    await setup();
    await measureFor(500); // warm-up
    double result = await measureFor(4000); // actual measurement
    await teardown();
    return result;
  }

  void report() async {
    emitter.emit(name, await measure());
  }
}

class StartMessage {
  final SendPort sendPort;
  final bool useTransferable;
  final int size;

  StartMessage(this.sendPort, this.useTransferable, this.size);
}

// Measures how long sending and receiving of [size]-length Uint8List takes.
class SendReceiveHelper {
  SendReceiveHelper(this.size, {@required bool this.useTransferable});

  setup() async {
    data = new Uint8List(size);

    port = ReceivePort();
    inbox = StreamIterator<dynamic>(port);
    worker = await Isolate.spawn(
        isolate, StartMessage(port.sendPort, useTransferable, size),
        paused: true);
    workerCompleted = Completer<bool>();
    workerExitedPort = ReceivePort()
      ..listen((_) => workerCompleted.complete(true));
    worker.addOnExitListener(workerExitedPort.sendPort);
    worker.resume(worker.pauseCapability);
    await inbox.moveNext();
    outbox = inbox.current;
  }

  finalize() async {
    outbox.send(null);
    await workerCompleted.future;
    workerExitedPort.close();
    port.close();
  }

  // Send data to worker, wait for an answer.
  run() async {
    outbox.send(packageList(data, useTransferable));
    await inbox.moveNext();
    final received = inbox.current;
    if (useTransferable) {
      received.materialize();
    }
  }

  Uint8List data;
  ReceivePort port;
  StreamIterator<dynamic> inbox;
  SendPort outbox;
  Isolate worker;
  Completer<bool> workerCompleted;
  ReceivePort workerExitedPort;
  final int size;
  final bool useTransferable;
}

packageList(Uint8List data, bool useTransferable) =>
    useTransferable ? TransferableTypedData.fromList(<Uint8List>[data]) : data;

Future<Null> isolate(StartMessage startMessage) async {
  final port = new ReceivePort();
  final inbox = new StreamIterator<dynamic>(port);
  startMessage.sendPort.send(port.sendPort);
  final data = Uint8List.view(new Uint8List(startMessage.size).buffer);
  while (true) {
    await inbox.moveNext();
    final received = inbox.current;
    if (received == null) {
      break;
    }
    if (startMessage.useTransferable) {
      received.materialize();
    }
    startMessage.sendPort.send(packageList(data, startMessage.useTransferable));
  }
  port.close();
}

const int TEN_MB = 10 * 1024 * 1024;
const int HUNDRED_MB = 100 * 1024 * 1024;

main() async {
  await SendReceive("SendReceive10MB", size: TEN_MB, useTransferable: false)
      .report();
  await SendReceive("SendReceiveTransferable10MB",
          size: TEN_MB, useTransferable: true)
      .report();
  await SendReceive("SendReceive100MB",
          size: HUNDRED_MB, useTransferable: false)
      .report();
  await SendReceive("SendReceiveTransferable100MB",
          size: HUNDRED_MB, useTransferable: true)
      .report();
}
