// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dylib_utils.dart';

import 'dart:ffi' as ffi;

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main() {
  using((arena) {
    final structs = arena<VarArgs>(2);
    structs[0].a = 1;
    structs[1].a = 2;
    final result = variadicStructVarArgs(structs[0], structs[1]);
    Expect.equals(3, result);
  });
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final variadicStructVarArgs = ffiTestFunctions.lookupFunction<
  ffi.Int64 Function(VarArgs, ffi.VarArgs<(VarArgs,)>),
  int Function(VarArgs, VarArgs)
>('VariadicStructVarArgs');

final class VarArgs extends ffi.Struct {
  @ffi.Int32()
  external int a;
}
