// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Test that ensures correct exceptions are thrown when misusing
// [TransferableTypedData].

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';

import "package:expect/expect.dart";

throwsIfMaterializeAfterSend() async {
  final completer = Completer<bool>();
  final rp = ReceivePort()
    ..listen((e) {
      completer.complete(true);
    });
  final transferable = TransferableTypedData.fromList([Uint8List(1024)]);
  rp.sendPort.send(transferable);
  Expect.throwsArgumentError(() => transferable.materialize());
  await completer.future;
  rp.close();
}

throwsIfSendMoreThanOnce() async {
  final completer = Completer<bool>();
  final rp = ReceivePort()
    ..listen((e) {
      completer.complete(true);
    });
  final bytes = Uint8List(1024);
  final transferable = TransferableTypedData.fromList([bytes]);
  rp.sendPort.send(transferable);
  Expect.throwsArgumentError(() => rp.sendPort.send(transferable));
  await completer.future;
  rp.close();
}

throwsIfMaterializeMoreThanOnce() {
  final transferable = TransferableTypedData.fromList([Uint8List(1024)]);
  transferable.materialize();
  Expect.throwsArgumentError(() => transferable.materialize());
}

throwsIfReceiverMaterializesMoreThanOnce() async {
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
}

void receiver(final transferable) {
  transferable.materialize();
  transferable.materialize();
}

throwsIfCummulativeListIsTooLargeOn32bitPlatform() {
  try {
    int maxUint8ListSize = pow(2, 30) as int;
    // Check whether we are on 32-bit or 64-bit platform.
    new Uint8List(maxUint8ListSize);
    // On 64-bit platform we will have difficulty allocating large enough
    // Uint8List to verify "too large" use case, so do nothing.
    return;
  } catch (_) {}

  var halfmax = new Uint8List(pow(2, 29) - 1 as int);
  Expect.throwsArgumentError(
      () => TransferableTypedData.fromList([halfmax, halfmax, Uint8List(2)]));
}

class MyList<T> extends ListBase<T> {
  @override
  int length = null as dynamic;

  @override
  T operator [](int index) => null as T;
  @override
  void operator []=(int index, T value) {}
}

class MyTypedData implements TypedData {
  noSuchMethod(_) {}
}

main() async {
  await throwsIfMaterializeAfterSend();
  await throwsIfSendMoreThanOnce();
  throwsIfMaterializeMoreThanOnce();
  await throwsIfReceiverMaterializesMoreThanOnce();
  throwsIfCummulativeListIsTooLargeOn32bitPlatform();

  dynamic myNull;
  if (hasUnsoundNullSafety) {
    Expect.throwsArgumentError(() => TransferableTypedData.fromList(myNull));
    Expect.throwsArgumentError(() => TransferableTypedData.fromList([myNull]));
    Expect.throwsArgumentError(
        () => TransferableTypedData.fromList(MyList<Uint8List>()));
  } else {
    Expect.throwsTypeError(() => TransferableTypedData.fromList(myNull));
    Expect.throwsTypeError(() => TransferableTypedData.fromList([myNull]));
    Expect.throwsTypeError(
        () => TransferableTypedData.fromList(MyList<Uint8List>()));
  }
  Expect.throwsArgumentError(
      () => TransferableTypedData.fromList([MyTypedData()]));
}
