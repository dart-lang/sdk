// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--trace-finalizers

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'ffi_test_helpers.dart';

void main(List<String> args, int? address) async {
  if (address != null) {
    await mainHelper(args, address);
  } else {
    await testFinalizerRunsOnIsolateGroupShutdown();
  }
}

Future mainHelper(List<String> args, int address) async {
  final token = Pointer<IntPtr>.fromAddress(address);
  createAndLoseFinalizable(token);
  print('Isolate done.');
}

Future<void> testFinalizerRunsOnIsolateGroupShutdown() async {
  await using((Arena allocator) async {
    final token = allocator<IntPtr>();
    Expect.equals(0, token.value);
    final portExitMessage = ReceivePort();
    await Isolate.spawnUri(
      Platform.script,
      [],
      token.address,
      onExit: portExitMessage.sendPort,
    );
    await portExitMessage.first;
    print('Helper isolate has exited.');

    Expect.equals(42, token.value);

    print('End of test, shutting down.');
  });
}
