// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Sample illustrating manual resource management, not advised.

// @dart = 2.9

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'pool.dart';
import '../dylib_utils.dart';

main() {
  final ffiTestDynamicLibrary =
      dlopenPlatformSpecific("ffi_test_dynamic_library");

  final MemMove = ffiTestDynamicLibrary.lookupFunction<
      Void Function(Pointer<Void>, Pointer<Void>, IntPtr),
      void Function(Pointer<Void>, Pointer<Void>, int)>("MemMove");

  // To ensure resources are freed, call free manually.
  //
  // For automatic management use a Pool.
  final p = unmanaged.allocate<Int64>(count: 2);
  p[0] = 24;
  MemMove(p.elementAt(1).cast<Void>(), p.cast<Void>(), sizeOf<Int64>());
  print(p[1]);
  Expect.equals(24, p[1]);
  unmanaged.free(p);

  // Using Strings.
  final p2 = "Hello world!".toUtf8(unmanaged);
  print(p2.contents());
  unmanaged.free(p2);
}
