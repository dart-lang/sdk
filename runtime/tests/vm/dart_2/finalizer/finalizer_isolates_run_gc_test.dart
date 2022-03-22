// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--use_compactor
// VMOptions=--use_compactor --force_evacuation

// @dart = 2.9

import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'helpers.dart';

void main() async {
  await testNormalExit();
  await testSendAndExit();
  await testSendAndExitFinalizer();
  print('End of test, shutting down.');
}

final finalizerTokens = <Nonce>{};

void callback(Nonce token) {
  print('Running finalizer: token: $token');
  finalizerTokens.add(token);
}

void runIsolateAttachFinalizer(Object message) {
  final finalizer = Finalizer<Nonce>(callback);
  final value = Nonce(1001);
  final token = Nonce(1002);
  finalizer.attach(value, token);
  final token9 = Nonce(9002);
  makeObjectWithFinalizer(finalizer, token9);
  if (message == null) {
    print('Isolate done.');
    return;
  }
  final list = message as List;
  assert(list.length == 2);
  final sendPort = list[0] as SendPort;
  final tryToSendFinalizer = list[1] as bool;
  if (tryToSendFinalizer) {
    Expect.throws(() {
      // TODO(http://dartbug.com/47777): Send and exit support.
      print('Trying to send and exit finalizer.');
      Isolate.exit(sendPort, [value, finalizer]);
    });
  }
  print('Isolate sending and exit.');
  Isolate.exit(sendPort, [value]);
}

Future testNormalExit() async {
  final portExitMessage = ReceivePort();
  await Isolate.spawn(
    runIsolateAttachFinalizer,
    null,
    onExit: portExitMessage.sendPort,
  );
  await portExitMessage.first;

  doGC();
  await yieldToMessageLoop();

  Expect.equals(0, finalizerTokens.length);
}

@pragma('vm:never-inline')
Future<Finalizer> testSendAndExitHelper({bool trySendFinalizer = false}) async {
  final port = ReceivePort();
  await Isolate.spawn(
    runIsolateAttachFinalizer,
    [port.sendPort, trySendFinalizer],
  );
  final message = await port.first as List;
  print('Received message ($message).');
  final value = message[0] as Nonce;
  print('Received value ($value), but now forgetting about it.');

  Expect.equals(1, message.length);
  // TODO(http://dartbug.com/47777): Send and exit support.
  return null;
}

Future testSendAndExit() async {
  await testSendAndExitHelper(trySendFinalizer: false);

  doGC();
  await yieldToMessageLoop();

  Expect.equals(0, finalizerTokens.length);
}

Future testSendAndExitFinalizer() async {
  final finalizer = await testSendAndExitHelper(trySendFinalizer: true);

  // TODO(http://dartbug.com/47777): Send and exit support.
  Expect.isNull(finalizer);
}
