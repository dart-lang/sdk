// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'ffi_test_helpers.dart';

void main() {
  testInitMemoryInDart();
  testInitMemoryInDart16();
  testInitStringInDart();
}

void testInitMemoryInDart() {
  final units = Uint8List.fromList([109, 121, 83, 116, 114, 105, 110, 103, 0]);
  final pointer = malloc<Uint8>(units.length);
  pointer.asTypedList(units.length).setAll(0, units);
  print(pointer);
  final result = takeString(pointer.cast());
  Expect.equals(114, result);
  malloc.free(pointer);
}

void testInitMemoryInDart16() {
  final units = Uint16List.fromList([
    109 + 121 * 256,
    83 + 116 * 256,
    114 + 105 * 256,
    110 + 103 * 256,
    0,
  ]);
  final Pointer<Uint16> pointer = malloc<Uint16>(units.length);
  pointer.asTypedList(units.length).setAll(0, units);
  print(pointer);
  final result = takeString(pointer.cast());
  Expect.equals(114, result);
  malloc.free(pointer);
}

void testInitStringInDart() {
  final cString = 'myString'.toNativeUtf8();
  final result = takeString(cString);
  Expect.equals(114, result);
  malloc.free(cString);
}

final takeString = ffiTestFunctions
    .lookupFunction<Char Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
      'TakeString',
    );
