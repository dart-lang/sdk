// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests the sizes of c types from https://dartbug.com/36140.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";
import 'dart:io' show Platform;

import 'abi_specific_ints.dart';
import 'ffi_test_helpers.dart';

void main() {
  printSizes();
  testSizes();
  testLongAssumptions();
  testWCharTAssumptions();
}

class CType {
  final int ffiSize;
  final String modifier;
  final String type;

  CType(this.ffiSize, this.type, [this.modifier = ""]);

  String get cRepresentation => "$modifier $type".trim();

  String get _getSizeName => "FfiSizeOf_$modifier\_$type";

  int Function() get sizeFunction => ffiTestFunctions
      .lookupFunction<Uint64 Function(), int Function()>(_getSizeName);

  int get size => sizeFunction();

  String toString() => cRepresentation;
}

final intptr_t = CType(sizeOf<IntPtr>(), "intptr_t");
final uintptr_t = CType(sizeOf<UintPtr>(), "uintptr_t");
final long = CType(sizeOf<Long>(), "long");
final ulong = CType(sizeOf<UnsignedLong>(), "long", "unsigned");
final wchar_t = CType(sizeOf<WChar>(), "wchar_t");

final cTypes = [
  intptr_t,
  uintptr_t,
  long,
  ulong,
  wchar_t,
];

void printSizes() {
  cTypes.forEach((element) {
    print("${element.cRepresentation.padRight(20)}: ${element.size}");
  });
}

void testSizes() {
  cTypes.forEach((element) {
    Expect.equals(element.size, element.ffiSize);
  });
}

void testLongAssumptions() {
  if (Platform.isWindows) {
    Expect.equals(4, long.size);
    Expect.equals(4, ulong.size);
  } else {
    Expect.equals(intptr_t.size, long.size);
    Expect.equals(intptr_t.size, ulong.size);
  }
}

void testWCharTAssumptions() {
  final bool isSigned = wCharMinValue() != 0;
  print("wchar_t isSigned $isSigned");
  if (Platform.isWindows) {
    Expect.equals(2, wchar_t.size);
    if (isSigned) {
      Expect.equals(-0x8000, wCharMinValue());
      Expect.equals(0x7fff, wCharMaxValue());
    } else {
      Expect.equals(0, wCharMinValue());
      Expect.equals(0xffff, wCharMaxValue());
    }
  } else {
    Expect.equals(4, wchar_t.size);
    if (isSigned) {
      Expect.equals(-0x80000000, wCharMinValue());
      Expect.equals(0x7fffffff, wCharMaxValue());
    } else {
      Expect.equals(0, wCharMinValue());
      Expect.equals(0xffffffff, wCharMaxValue());
    }
  }
}

int Function() wCharMinValue = ffiTestFunctions
    .lookupFunction<Uint64 Function(), int Function()>('WCharMinValue');

int Function() wCharMaxValue = ffiTestFunctions
    .lookupFunction<Uint64 Function(), int Function()>('WCharMaxValue');
