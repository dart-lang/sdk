// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

// Reuse compound definitions.
import 'function_structs_by_value_generated_compounds.dart';

void main() {
  testSizeOfC();
  testSizeOfDart();
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final sizeOfStruct3BytesPackedInt =
    ffiTestFunctions.lookupFunction<Uint64 Function(), int Function()>(
        "SizeOfStruct3BytesPackedInt");

void testSizeOfC() {
  Expect.equals(3, sizeOfStruct3BytesPackedInt());
}

void testSizeOfDart() {
  // No packing needed to get to 3 bytes.
  Expect.equals(3, sizeOf<Struct3BytesHomogeneousUint8>());

  // Contents 3 bytes, but alignment forces it to be 4 bytes.
  Expect.equals(4, sizeOf<Struct3BytesInt2ByteAligned>());

  // Alignment gets the same content back to 3 bytes.
  Expect.equals(3, sizeOf<Struct3BytesPackedInt>());
}
