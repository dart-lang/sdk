// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests the sizes of c types from https://dartbug.com/36140.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import 'dart:io' show Platform;

import 'abi_specific_ints.dart';
import 'ffi_test_helpers.dart';

void main() {
  printSizes();
  testSizes();
  testIntAssumptions();
  testSizeTAssumptions();
  testLongAssumptions();
  testOffTAssumptions();
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
final int_ = CType(sizeOf<Int>(), "int");
final uint = CType(sizeOf<UnsignedInt>(), "int", "unsigned");
final long = CType(sizeOf<Long>(), "long");
final ulong = CType(sizeOf<UnsignedLong>(), "long", "unsigned");
final wchar_t = CType(sizeOf<WChar>(), "wchar_t");
final size_t = CType(sizeOf<Size>(), "size_t");
final ssize_t = CType(sizeOf<SSize>(), "ssize_t");
final off_t = CType(sizeOf<Off>(), "off_t");

final cTypes = [
  intptr_t,
  uintptr_t,
  int_,
  uint,
  long,
  ulong,
  wchar_t,
  size_t,
  ssize_t,
  off_t
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

void testIntAssumptions() {
  Expect.equals(4, int_.size);
  Expect.equals(4, uint.size);
}

void testSizeTAssumptions() {
  Expect.equals(intptr_t.size, size_t.size);
  Expect.equals(intptr_t.size, ssize_t.size);
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

void testOffTAssumptions() {
  Expect.equals(long.size, off_t.size);
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
