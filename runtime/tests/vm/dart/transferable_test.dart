// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Test that validates that transferables are faster than regular typed data.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import "package:expect/expect.dart";

const int toIsolateSize = 100 * 1024 * 1024;
const int fromIsolateSize = 100 * 1024 * 1024;

const int nIterations = 5;

int iteration = -1;
bool keepTimerRunning = false;

main() async {
  keepTimerRunning = true;

  print('--- standard');
  iteration = nIterations;
  final stopwatch = new Stopwatch()..start();
  await runBatch(useTransferable: false);
  final standard = stopwatch.elapsedMilliseconds;

  print('--- transferable');
  iteration = nIterations;
  stopwatch.reset();
  await runBatch(useTransferable: true);
  final transferable = stopwatch.elapsedMilliseconds;
  print(
      'standard($standard ms)/transferable($transferable ms): ${standard / transferable}x');
  keepTimerRunning = false;
}

packageList(Uint8List data, bool useTransferable) {
  return useTransferable
      ? TransferableTypedData.fromList(<Uint8List>[data])
      : data;
}

class StartMessage {
  final SendPort sendPort;
  final bool useTransferable;

  StartMessage(this.sendPort, this.useTransferable);
}

runBatch({required bool useTransferable}) async {
  Timer.run(idleTimer);
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final worker = await Isolate.spawn(
      isolateMain, StartMessage(port.sendPort, useTransferable),
      paused: true);
  final workerCompleted = Completer<bool>();
  final workerExitedPort = ReceivePort()
    ..listen((_) => workerCompleted.complete(true));
  worker.addOnExitListener(workerExitedPort.sendPort);
  worker.resume(worker.pauseCapability!);

  await inbox.moveNext();
  final outbox = inbox.current;
  final workWatch = new Stopwatch();
  final data = new Uint8List(toIsolateSize);

  while (iteration-- > 0) {
    final packagedData = packageList(data, useTransferable);
    workWatch.start();
    outbox.send(packagedData);
    await inbox.moveNext();

    final received = inbox.current;
    final receivedData = received is TransferableTypedData
        ? received.materialize().asUint8List()
        : received;

    int time = workWatch.elapsedMilliseconds;
    print('${time}ms for round-trip');
    workWatch.reset();

    Expect.equals(data.length, receivedData.length);
  }
  outbox.send(null);

  await workerCompleted.future;
  workerExitedPort.close();
  port.close();
}

Future<Null> isolateMain(StartMessage startMessage) async {
  final port = new ReceivePort();
  final inbox = new StreamIterator<dynamic>(port);
  startMessage.sendPort.send(port.sendPort);
  final data = Uint8List.view(new Uint8List(fromIsolateSize).buffer);
  while (true) {
    await inbox.moveNext();
    final received = inbox.current;
    if (received == null) {
      break;
    }
    final receivedData =
        received is TransferableTypedData ? received.materialize() : received;

    final packagedData = packageList(data, startMessage.useTransferable);

    startMessage.sendPort.send(packagedData);
  }
  port.close();
}

final Stopwatch idleWatch = new Stopwatch();

void idleTimer() {
  idleWatch.stop();
  final time = idleWatch.elapsedMilliseconds;
  if (time > 5) print('${time}ms since last checkin');
  idleWatch.reset();
  idleWatch.start();
  if (keepTimerRunning) {
    Timer.run(idleTimer);
  }
}
