// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

// VMOptions=--enable-experiment=records

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

@Native<Pointer<Void> Function(Pointer<Char>, Int)>()
external Pointer<Void> dlopen(Pointer<Char> file, int mode);

const RTLD_LAZY = 0x00001;
const RTLD_GLOBAL = 0x00100;

void main() {
  // Force dlopen so @Native lookups in DynamicLibrary.process() succeed.
  print(ffiTestFunctions);
  if (Platform.isLinux || Platform.isAndroid) {
    // TODO(https://dartbug.com/50105): enable dlopen global via package:ffi.
    using((arena) {
      final dylibHandle = dlopen(
          platformPath('ffi_test_functions')
              .toNativeUtf8(allocator: arena)
              .cast(),
          RTLD_LAZY | RTLD_GLOBAL);
      print(dylibHandle);
    });
  }

  testVariadicAt1Int64x5NativeLeaf();
}

@Native<Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>)>(symbol: 'VariadicAt1Int64x5', isLeaf:true)
external int variadicAt1Int64x5NativeLeaf(int a0, int a1, int a2, int a3, int a4);

void testVariadicAt1Int64x5NativeLeaf() {
  final result = variadicAt1Int64x5NativeLeaf(1, 2, 3, 4, 5);
  Expect.equals(15, result);
}
