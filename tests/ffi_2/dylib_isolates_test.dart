// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test for DynamicLibrary.open behavior on multiple isolates.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

void main() async {
  final dl = dlopenPlatformSpecific('ffi_test_functions');
  final dl2 = dlopenPlatformSpecific('ffi_test_functions');
  Expect.equals(dl, dl2);
  Expect.isFalse(identical(dl, dl2));

  final setGlobalVar = dl
      .lookupFunction<Void Function(Int32), void Function(int)>('SetGlobalVar');
  final getGlobalVar =
      dl.lookupFunction<Int32 Function(), int Function()>('GetGlobalVar');
  setGlobalVar(123);
  Expect.equals(123, getGlobalVar());

  final receivePort = ReceivePort();
  Isolate.spawn(secondIsolateMain, receivePort.sendPort);
  await receivePort.first;
  if (!Platform.isIOS /* Static linking causes different behavior. */) {
    Expect.equals(42, getGlobalVar());
  }
}

void secondIsolateMain(SendPort sendPort) {
  final dl = dlopenPlatformSpecific('ffi_test_functions');
  final setGlobalVar = dl
      .lookupFunction<Void Function(Int32), void Function(int)>('SetGlobalVar');
  setGlobalVar(42);
  sendPort.send('done');
}
