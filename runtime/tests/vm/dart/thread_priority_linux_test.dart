// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--worker-thread-priority=12

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

// Value of "PRIO_PROCESS".
const int kPrioProcess = 0;
const int kCurrentThreadId = 0;

// int getpriority(int which, id_t who)
typedef GetPriorityFT = int Function(int which, int who);
typedef GetPriorityNFT = Int32 Function(Int32 which, Uint32 who);

final getPriority = DynamicLibrary.process()
    .lookupFunction<GetPriorityNFT, GetPriorityFT>('getpriority');

main(args) {
  if (Platform.isLinux || Platform.isAndroid) {
    Expect.equals(12, getPriority(kPrioProcess, kCurrentThreadId));
  }
}
