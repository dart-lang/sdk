// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Measures performance of RegExp reuse between isolates.

import 'dart:async';
import 'dart:isolate';

import 'package:benchmark_harness/benchmark_harness.dart';

class SendReceiveRegExp extends AsyncBenchmarkBase {
  SendReceiveRegExp(String name, this.re) : super(name);

  @override
  Future<void> run() async {
    await helper.run(re);
  }

  @override
  Future<void> setup() async {
    helper = SendReceiveHelper();
    await helper.setup();
  }

  @override
  Future<void> teardown() async {
    await helper.finalize();
  }

  late SendReceiveHelper helper;
  RegExp re;
}

class SendReceiveHelper {
  SendReceiveHelper();

  Future<void> setup() async {
    final port = ReceivePort();
    inbox = StreamIterator<dynamic>(port);
    workerExitedPort = ReceivePort();
    await Isolate.spawn(isolate, port.sendPort,
        onExit: workerExitedPort.sendPort);
    await inbox.moveNext();
    outbox = inbox.current;
  }

  Future<void> finalize() async {
    outbox.send(null);
    await workerExitedPort.first;
    workerExitedPort.close();
    await inbox.cancel();
  }

  // Send regexp to worker, get one back, repeat few times.
  Future<void> run(RegExp re) async {
    for (int i = 0; i < 5; i++) {
      outbox.send(re);
      await inbox.moveNext();
      re = inbox.current;
    }
  }

  late StreamIterator<dynamic> inbox;
  late SendPort outbox;
  late ReceivePort workerExitedPort;
}

Future<void> isolate(SendPort sendPort) async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);

  sendPort.send(port.sendPort);
  while (true) {
    await inbox.moveNext();
    final received = inbox.current;
    if (received == null) {
      break;
    }
    // use RegExp to ensure it is compiled
    final RegExp re = received as RegExp;
    re.firstMatch('h' * 1000);
    // send the RegExp
    sendPort.send(re);
  }
  port.close();
}

Future<void> main() async {
  await SendReceiveRegExp('IsolateRegExp.MatchFast', RegExp('h?h')).report();
  await SendReceiveRegExp('IsolateRegExp.MatchSlow',
          RegExp(r'(?<=\W|\b|^)(a.? b c.?) ?(\(.*\))?$'))
      .report();
}
