// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--worker-thread-priority=15

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

// pthread_t pthread_self()
typedef PthreadSelfFT = int Function();
typedef PthreadSelfNFT = IntPtr Function();

// int pthread_getschedparam(pthread_t thread, int *policy, struct sched_param *param);
typedef GetSchedParamFT = int Function(
    int self, Pointer<Int32> policy, Pointer<SchedParam> param);
typedef GetSchedParamNFT = IntPtr Function(
    IntPtr self, Pointer<Int32> policy, Pointer<SchedParam> param);

final pthreadSelf = DynamicLibrary.process()
    .lookupFunction<PthreadSelfNFT, PthreadSelfFT>('pthread_self');

final pthreadGetSchedParam = DynamicLibrary.process()
    .lookupFunction<GetSchedParamNFT, GetSchedParamFT>('pthread_getschedparam');

//  struct sched_param { int sched_priority; }
class SchedParam extends Struct {
  @Int32()
  external int schedPriority;
}

main(args) {
  if (Platform.isMacOS) {
    final policy = allocate<Int32>(count: 1);
    final param = allocate<SchedParam>(count: 1);
    Expect.equals(0, pthreadGetSchedParam(pthreadSelf(), policy, param));
    Expect.equals(15, param.ref.schedPriority);
    free(policy);
    free(param);
  }
}
