// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Validates functionality of Isolate.exit().

import 'dart:async';
import 'dart:isolate';
import 'dart:nativewrappers';

import "package:expect/expect.dart";

import "isolates/fast_object_copy_test.dart" show nonCopyableClosures;

import "isolates/fast_object_copy2_test.dart"
    show sharableObjects, copyableClosures;

doNothingWorker(data) {}

spawnWorker(worker, data) async {
  Completer completer = Completer();
  runZoned(() async {
    final isolate = await Isolate.spawn(worker, [data]);
    completer.complete(isolate);
  }, onError: (e, st) => completer.complete(e));
  return await completer.future;
}

class NativeWrapperClass extends NativeFieldWrapperClass1 {}

verifyCantSendNative() async {
  final receivePort = ReceivePort();
  Expect.throws(
      () => Isolate.exit(receivePort.sendPort, NativeWrapperClass()),
      (e) => e.toString().startsWith('Invalid argument: '
          '"Illegal argument in isolate message : '
          '(object extends NativeWrapper'));
  receivePort.close();
}

verifyCantSendReceivePort() async {
  final receivePort = ReceivePort();
  Expect.throws(
      () => Isolate.exit(receivePort.sendPort, receivePort),
      (e) => e.toString().startsWith(
          'Invalid argument: "Illegal argument in isolate message : '
          '(object is a ReceivePort)\"'));
  receivePort.close();
}

verifyCantSendNonCopyable() async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn((SendPort sendPort) {
    for (final closure in nonCopyableClosures) {
      Expect.throwsArgumentError(() => Isolate.exit(sendPort, closure));
    }
    sendPort.send(true);
  }, port.sendPort);

  await inbox.moveNext();
  Expect.isTrue(inbox.current);
  port.close();
}

sendShareable(SendPort sendPort) {
  Isolate.exit(sendPort, sharableObjects);
}

verifyCanSendShareable() async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn(sendShareable, port.sendPort);

  await inbox.moveNext();
  final result = inbox.current;
  Expect.equals(sharableObjects.length, result.length);
  port.close();
}

sendCopyable(SendPort sendPort) {
  Isolate.exit(sendPort, copyableClosures);
}

verifyCanSendCopyableClosures() async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn(sendCopyable, port.sendPort);

  await inbox.moveNext();
  final result = inbox.current;
  Expect.equals(copyableClosures.length, result.length);
  port.close();
}

add(a, b) => a + b;

worker(SendPort sendPort) async {
  Isolate.exit(sendPort, add);
}

verifyExitMessageIsPostedLast() async {
  final port = ReceivePort();
  final inbox = new StreamIterator<dynamic>(port);
  final isolate =
      await Isolate.spawn(worker, port.sendPort, onExit: port.sendPort);

  final receivedData = Completer<dynamic>();
  final isolateExited = Completer<bool>();
  port.listen((dynamic resultData) {
    if (receivedData.isCompleted) {
      Expect.equals(
          null, resultData); // exit message comes after data is receivedData
      isolateExited.complete(true);
    } else {
      receivedData.complete(resultData);
    }
  });
  Expect.equals(true, await isolateExited.future);
  Expect.equals(5, (await receivedData.future)(2, 3));
  port.close();
}

main() async {
  await verifyCantSendNative();
  await verifyCantSendReceivePort();
  await verifyCanSendShareable();
  await verifyCanSendCopyableClosures();
  await verifyExitMessageIsPostedLast();
}
