// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-isolate-groups
//
// Validates functionality of sendAndExit.

import 'dart:_internal' show sendAndExit;
import 'dart:async';
import 'dart:isolate';
import 'dart:nativewrappers';

import "package:expect/expect.dart";

doNothingWorker(data) {}

spawnWorker(worker, data) async {
  Completer completer = Completer();
  runZoned(() async {
    final isolate = await Isolate.spawn(worker, [data]);
    completer.complete(isolate);
  }, onError: (e, st) => completer.complete(e));
  return await completer.future;
}

verifyCantSendAnonymousClosure() async {
  final receivePort = ReceivePort();
  Expect.throws(
      () => sendAndExit(receivePort.sendPort, () {}),
      (e) =>
          e.toString() ==
          'Invalid argument: "Illegal argument in isolate message : '
              '(object is a closure - Function \'<anonymous closure>\': static.)"');
  receivePort.close();
}

class NativeWrapperClass extends NativeFieldWrapperClass1 {}

verifyCantSendNative() async {
  final receivePort = ReceivePort();
  Expect.throws(
      () => sendAndExit(receivePort.sendPort, NativeWrapperClass()),
      (e) => e.toString().startsWith('Invalid argument: '
          '"Illegal argument in isolate message : '
          '(object extends NativeWrapper'));
  receivePort.close();
}

verifyCantSendReceivePort() async {
  final receivePort = ReceivePort();
  Expect.throws(
      () => sendAndExit(receivePort.sendPort, receivePort),
      // closure is encountered first before we reach ReceivePort instance
      (e) => e.toString().startsWith(
          'Invalid argument: "Illegal argument in isolate message : '
          '(object is a closure - Function \''));
  receivePort.close();
}

verifyCantSendRegexp() async {
  final receivePort = ReceivePort();
  final regexp = RegExp("");
  Expect.throws(
      () => sendAndExit(receivePort.sendPort, regexp),
      (e) =>
          e.toString() ==
          'Invalid argument: '
              '"Illegal argument in isolate message : (object is a RegExp)"');
  receivePort.close();
}

add(a, b) => a + b;

worker(SendPort sendPort) async {
  sendAndExit(sendPort, add);
}

verifyCanSendStaticMethod() async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn(worker, port.sendPort);

  await inbox.moveNext();
  Expect.equals(5, (inbox.current)(2, 3));
  port.close();
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
  await verifyCantSendAnonymousClosure();
  await verifyCantSendNative();
  await verifyCantSendReceivePort();
  await verifyCantSendRegexp();
  await verifyCanSendStaticMethod();
  await verifyExitMessageIsPostedLast();
}
