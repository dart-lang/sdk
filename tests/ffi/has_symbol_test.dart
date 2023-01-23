// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

import 'ffi_test_helpers.dart';

void main() {
  testHasSymbol();
}

void testHasSymbol() {
  Expect.isTrue(ffiTestFunctions.providesSymbol('ReturnMaxUint8'));
  Expect.isFalse(ffiTestFunctions.providesSymbol('SymbolNotInLibrary'));

  final p = DynamicLibrary.process();
  Expect.isFalse(p.providesSymbol('symbol_that_does_not_exist_in_process'));
  if (Platform.isWindows) {
    Expect.isTrue(p.providesSymbol('HeapAlloc'));
    Expect.isTrue(p.providesSymbol('CoTaskMemAlloc'));
  } else {
    Expect.isTrue(p.providesSymbol('dlopen'));
  }

  final e = DynamicLibrary.executable();
  Expect.isTrue(e.providesSymbol('Dart_Invoke'));
  Expect.isFalse(e.providesSymbol('symbol_that_does_not_exist_in_executable'));
}
