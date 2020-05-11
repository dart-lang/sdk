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
  final result = await spawnWorker(doNothingWorker, () {});
  Expect.equals(
      "Invalid argument(s): Illegal argument in isolate message :"
      " (object is a closure - Function '<anonymous closure>': static.)",
      result.toString());
}

class NativeWrapperClass extends NativeFieldWrapperClass1 {}

verifyCantSendNative() async {
  final result = await spawnWorker(doNothingWorker, NativeWrapperClass());
  Expect.isTrue(result.toString().startsWith("Invalid argument(s): "
      "Illegal argument in isolate message : "
      "(object extends NativeWrapper"));
}

verifyCantSendRegexp() async {
  var receivePort = ReceivePort();
  final result = await spawnWorker(doNothingWorker, receivePort);
  Expect.equals(
      "Invalid argument(s): Illegal argument in isolate message : "
      "(object is a ReceivePort)",
      result.toString());
  receivePort.close();
}

class Message {
  SendPort sendPort;
  Function closure;

  Message(this.sendPort, this.closure);
}

add(a, b) => a + b;

worker(Message message) async {
  final port = new ReceivePort();
  final inbox = new StreamIterator<dynamic>(port);
  message.sendPort.send(message.closure(2, 3));
  port.close();
}

verifyCanSendStaticMethod() async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn(worker, Message(port.sendPort, add));

  await inbox.moveNext();
  Expect.equals(inbox.current, 5);
  port.close();
}

verifyExitMessageIsPostedLast() async {
  final port = ReceivePort();
  final inbox = new StreamIterator<dynamic>(port);
  final isolate = await Isolate.spawn(worker, Message(port.sendPort, add),
      onExit: port.sendPort);

  final receivedData = Completer<dynamic>();
  final isolateExited = Completer<bool>();
  port.listen((dynamic resultData) {
    if (receivedData.isCompleted) {
      Expect.equals(
          resultData, null); // exit message comes after data is receivedData
      isolateExited.complete(true);
    } else {
      receivedData.complete(resultData);
    }
  });
  Expect.equals(await isolateExited.future, true);
  Expect.equals(await receivedData.future, 5);
  port.close();
}

main() async {
  await verifyCantSendAnonymousClosure();
  await verifyCantSendNative();
  await verifyCantSendRegexp();
  await verifyCanSendStaticMethod();
  await verifyExitMessageIsPostedLast();
}
