// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:async_helper/async_helper.dart' show asyncStart, asyncEnd;
import 'package:expect/expect.dart';

Uint8List generateSampleList(final int size) {
  final list = Uint8List(size);
  for (int i = 0; i < size; i++) {
    list[i] = i % 243;
  }
  return list;
}

void validateReceivedList(final int expectedSize, final list) {
  Expect.equals(expectedSize, list.length);
  // probe few elements
  for (int i = 0; i < list.length; i += max<num>(1, expectedSize ~/ 1000)) {
    Expect.equals(i % 243, list[i]);
  }
}

Future<Null> testSend(
    bool transferable, int toIsolateSize, int fromIsolateSize) async {
  asyncStart();
  final port = ReceivePort();
  final inbox = StreamIterator(port);
  await Isolate.spawn(isolateMain,
      [transferable, toIsolateSize, fromIsolateSize, port.sendPort]);
  await inbox.moveNext();
  final outbox = inbox.current;
  final workWatch = Stopwatch();
  final data = generateSampleList(toIsolateSize);
  int count = 10;
  workWatch.start();
  while (count-- > 0) {
    outbox.send(transferable ? TransferableTypedData.fromList([data]) : data);
    await inbox.moveNext();
    validateReceivedList(
        fromIsolateSize,
        transferable
            ? inbox.current.materialize().asUint8List()
            : inbox.current);
  }
  print('total ${workWatch.elapsedMilliseconds}ms');
  outbox.send(null);
  port.close();
  asyncEnd();
}

main() async {
  asyncStart();
  int bignum = 10 * 1000 * 1000;
  await testSend(false, bignum, 1); // none
  await testSend(true, bignum, 1); // 31959tr
  await testSend(false, bignum, 1); // 31960
  await testSend(true, bignum, 1); // 31960tr
  asyncEnd();
}

Future<Null> isolateMain(List config) async {
  bool transferable = config[0];
  int toIsolateSize = config[1];
  int fromIsolateSize = config[2];
  SendPort outbox = config[3];

  final port = ReceivePort();
  final inbox = StreamIterator(port);
  outbox.send(port.sendPort);
  final data = generateSampleList(fromIsolateSize);
  while (true) {
    await inbox.moveNext();
    if (inbox.current == null) {
      break;
    }
    validateReceivedList(
        toIsolateSize,
        transferable
            ? inbox.current.materialize().asUint8List()
            : inbox.current);
    outbox.send(transferable ? TransferableTypedData.fromList([data]) : data);
  }
  port.close();
}
