// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that ensures correct exception is thrown when attempting to use
// transferred transferables.

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';

import "package:expect/expect.dart";

throwsIfMaterializeAfterSend() {
  final rp = ReceivePort();
  final transferable = TransferableTypedData.fromList([Uint8List(1024)]);
  rp.sendPort.send(transferable);
  Expect.throwsArgumentError(() => transferable.materialize());
  rp.close();
}

throwsIfSendMoreThanOnce() {
  final rp = ReceivePort();
  final bytes = Uint8List(1024);
  final transferable = TransferableTypedData.fromList([bytes]);
  rp.sendPort.send(transferable);
  Expect.throwsArgumentError(() => rp.sendPort.send(transferable));
  rp.close();
}

throwsIfMaterializeMoreThanOnce() {
  final transferable = TransferableTypedData.fromList([Uint8List(1024)]);
  transferable.materialize();
  Expect.throwsArgumentError(() => transferable.materialize());
}

throwsIfReceiverMaterializesMoreThanOnce() async {
  final rp = ReceivePort();
  final completer = Completer<List>();
  final isolateErrors = ReceivePort()..listen((e) => completer.complete(e));
  await Isolate.spawn(
      receiver, TransferableTypedData.fromList([Uint8List(1024)]),
      onError: isolateErrors.sendPort);
  final error = await completer.future;
  Expect.equals(
      error[0],
      "Invalid argument(s): Attempt to materialize object that was"
      " transferred already.");
  isolateErrors.close();
  rp.close();
}

void receiver(final transferable) {
  transferable.materialize();
  transferable.materialize();
}

throwsIfCummulativeListIsTooLargeOn32bitPlatform() {
  try {
    int maxUint8ListSize = pow(2, 30);
    // Check whether we are on 32-bit or 64-bit platform.
    new Uint8List(maxUint8ListSize);
    // On 64-bit platform we will have difficulty allocating large enough
    // Uint8List to verify "too large" use case, so do nothing.
    return;
  } catch (_) {}

  var halfmax = new Uint8List(pow(2, 29) - 1);
  Expect.throwsArgumentError(
      () => TransferableTypedData.fromList([halfmax, halfmax, Uint8List(2)]));
}

throwsIfCummulativeListCantBeAllocated() {
  // Attempt to create total 1tb uint8list which should fail on 32 and 64-bit
  // platforms.
  final bytes100MB = Uint8List(100 * 1024 * 1024);
  final total1TB = List<Uint8List>.filled(10000, bytes100MB);
  // Try to make a 1 TB transferable.
  Expect.throws(() => TransferableTypedData.fromList(total1TB));
}

class MyList<T> extends ListBase<T> {
  @override
  int length;

  @override
  T operator [](int index) => null;
  @override
  void operator []=(int index, T value) {}
}

class MyTypedData implements TypedData {
  noSuchMethod(_) {}
}

main() {
  throwsIfMaterializeAfterSend();
  throwsIfSendMoreThanOnce();
  throwsIfMaterializeMoreThanOnce();
  throwsIfReceiverMaterializesMoreThanOnce();
  throwsIfCummulativeListIsTooLargeOn32bitPlatform();
  if (!Platform.isMacOS) {
    // this test crashes the process on mac.
    throwsIfCummulativeListCantBeAllocated();
  }

  Expect.throwsArgumentError(() => TransferableTypedData.fromList(null));
  Expect.throwsArgumentError(() => TransferableTypedData.fromList([null]));
  Expect.throwsArgumentError(
      () => TransferableTypedData.fromList(MyList<Uint8List>()));
  Expect.throwsArgumentError(
      () => TransferableTypedData.fromList([MyTypedData()]));
}
