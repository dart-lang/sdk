// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that on Windows ctrl-c SIGINT is handled by spawned dartvm.exe, parent
// dart.exe does not get in a way.
//

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

final DynamicLibrary kernel32 = DynamicLibrary.open("kernel32.dll");

typedef GenerateConsoleCtrlEventFT = bool Function(int, int);
typedef GenerateConsoleCtrlEventNFT = Bool Function(IntPtr, IntPtr);

const int CTRL_C_EVENT = 0;

final generateConsoleCtrlEvent = kernel32
    .lookupFunction<GenerateConsoleCtrlEventNFT, GenerateConsoleCtrlEventFT>(
      'GenerateConsoleCtrlEvent',
    );

typedef SetConsoleCtrlHandlerFT = bool Function(int, bool);
typedef SetConsoleCtrlHandlerNFT = Bool Function(IntPtr, Bool);

final setConsoleCtrlHandler = kernel32
    .lookupFunction<SetConsoleCtrlHandlerNFT, SetConsoleCtrlHandlerFT>(
      'SetConsoleCtrlHandler',
    );

main(List<String> args) async {
  if (!Platform.isWindows) {
    return;
  }

  // Restore ctrl-c handler
  setConsoleCtrlHandler(0, false);

  if (args.contains("--testee")) {
    ProcessSignal.sigint.watch().listen((_) {
      print('SIGINT RECEIVED');
      exit(0);
    });

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      print('Waiting...');

      // Send Ctrl-C to ourselves after 1 second.
      generateConsoleCtrlEvent(CTRL_C_EVENT, /*dwProcessGroupId=*/ 0);
    }
  } else {
    var result = await Process.run(Platform.executable, [
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      "--testee",
    ]);
    print("stdout:");
    print(result.stdout);
    Expect.isTrue(result.stdout.contains("Waiting..."));
    Expect.isTrue(result.stdout.contains("SIGINT RECEIVED"));
    print("stderr:");
    print(result.stderr);
  }
}
