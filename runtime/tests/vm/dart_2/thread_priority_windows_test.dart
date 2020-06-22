// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--worker-thread-priority=-2
// A priority of -2 means THREAD_PRIORITY_LOWEST on windows

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

final DynamicLibrary kernel32 = DynamicLibrary.open("kernel32.dll");

// HANDLE GetCurrentThread();
typedef GetCurrentThreadFT = int Function();
typedef GetCurrentThreadNFT = IntPtr Function();

// int GetThreadPriority(HANDLE hThread);
typedef GetThreadPriorityFT = int Function(int handle);
typedef GetThreadPriorityNFT = Int32 Function(IntPtr handle);

final getCurrentThread =
    kernel32.lookupFunction<GetCurrentThreadNFT, GetCurrentThreadFT>(
        'GetCurrentThread');
final getThreadPriority =
    kernel32.lookupFunction<GetThreadPriorityNFT, GetThreadPriorityFT>(
        'GetThreadPriority');

main(args) {
  if (Platform.isWindows) {
    Expect.equals(-2, getThreadPriority(getCurrentThread()));
  }
}
