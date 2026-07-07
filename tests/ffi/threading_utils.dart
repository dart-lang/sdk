// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

typedef PthreadAttrInitFT = int Function(Pointer<Char>);
typedef PthreadAttrInitNFT = IntPtr Function(Pointer<Char>);
final pthreadAttrInit = DynamicLibrary.process()
    .lookupFunction<PthreadAttrInitNFT, PthreadAttrInitFT>('pthread_attr_init');

typedef PthreadAttrDestroyFT = int Function(Pointer<Char>);
typedef PthreadAttrDestroyNFT = IntPtr Function(Pointer<Char>);
final pthreadAttrDestroy = DynamicLibrary.process()
    .lookupFunction<PthreadAttrDestroyNFT, PthreadAttrDestroyFT>(
      'pthread_attr_destroy',
    );

typedef PthreadCreateFT =
    int Function(Pointer<IntPtr>, Pointer<Char>, Pointer, Pointer<Void>);
typedef PthreadCreateNFT =
    IntPtr Function(Pointer<IntPtr>, Pointer<Char>, Pointer, Pointer<Void>);
final pthreadCreate = DynamicLibrary.process()
    .lookupFunction<PthreadCreateNFT, PthreadCreateFT>('pthread_create');

typedef PthreadJoinFT = int Function(int, Pointer<Void>);
typedef PthreadJoinNFT = IntPtr Function(IntPtr, Pointer<Void>);
final pthreadJoin = DynamicLibrary.process()
    .lookupFunction<PthreadJoinNFT, PthreadJoinFT>('pthread_join');

typedef PthreadSelfFT = int Function();
typedef PthreadSelfNFT = IntPtr Function();
final pthreadSelf = DynamicLibrary.process()
    .lookupFunction<PthreadSelfNFT, PthreadSelfFT>('pthread_self');

class ThreadInfo {
  final ptr_attr = calloc<Char>(64); // big enough to fit pthread_attr_t?
  final ptr_tid = calloc<IntPtr>(1);
  final ptr_data = calloc<Int32>(1024);
  final ptr_retval = calloc<IntPtr>(1024);

  void joinAndDestroy() {
    Expect.equals(0, pthreadJoin(ptr_tid.value, ptr_retval.cast<Void>()));
    calloc.free(ptr_retval);

    calloc.free(ptr_data);
    calloc.free(ptr_tid);

    Expect.equals(0, pthreadAttrDestroy(ptr_attr));
    calloc.free(ptr_attr);
  }
}
