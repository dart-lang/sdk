// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests the sizes of c types from https://dartbug.com/36140.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'ffi_test_helpers.dart';

void main() {
  printSizes();
  testSizes();
  testIntAssumptions();
  testSizeTAssumptions();
  testLongAssumptions();
  testWCharTAssumptions();
}

class CType {
  final int ffiSize;
  final int Function(Pointer)? ffiLoad;
  final String modifier;
  final String type;
  final String type2;

  CType(this.ffiSize, this.type,
      {this.type2 = '', this.modifier = '', this.ffiLoad});

  String get cRepresentation => '$modifier $type $type2'.trim();

  String get _getSizeName => 'FfiSizeOf_$modifier\_$type\_$type2';

  String get _getSignName => 'FfiSignOf_$modifier\_$type\_$type2';

  int Function() get sizeFunction => ffiTestFunctions
      .lookupFunction<Uint64 Function(), int Function()>(_getSizeName);

  int Function() get signFunction => ffiTestFunctions
      .lookupFunction<Uint64 Function(), int Function()>(_getSignName);

  int get size => sizeFunction();

  bool get isSigned => signFunction() != 0;

  bool? get ffiIsSigned {
    final ffiLoad_ = ffiLoad;
    if (ffiLoad_ == null) {
      return null;
    }
    assert(size < 8);
    return using((Arena arena) {
      final p = arena<Int64>()..value = -1;
      return ffiLoad_(p) < 0;
    });
  }

  String toString() => cRepresentation;
}

final uchar = CType(
  sizeOf<UnsignedChar>(),
  'char',
  modifier: 'unsigned',
  ffiLoad: (Pointer p) => p.cast<UnsignedChar>().value,
);
final schar = CType(
  sizeOf<SignedChar>(),
  'char',
  modifier: 'signed',
  ffiLoad: (Pointer p) => p.cast<SignedChar>().value,
);
final short = CType(
  sizeOf<Short>(),
  'short',
  ffiLoad: (Pointer p) => p.cast<Short>().value,
);
final ushort = CType(
  sizeOf<UnsignedShort>(),
  'short',
  modifier: 'unsigned',
  ffiLoad: (Pointer p) => p.cast<UnsignedShort>().value,
);
final int_ = CType(
  sizeOf<Int>(),
  'int',
  ffiLoad: (Pointer p) => p.cast<Int>().value,
);
final uint = CType(
  sizeOf<UnsignedInt>(),
  'int',
  modifier: 'unsigned',
  ffiLoad: (Pointer p) => p.cast<UnsignedInt>().value,
);
final long = CType(
  sizeOf<Long>(),
  'long',
);
final ulong = CType(
  sizeOf<UnsignedLong>(),
  'long',
  modifier: 'unsigned',
);
final longlong = CType(
  sizeOf<LongLong>(),
  'long',
  type2: 'long',
);
final ulonglong = CType(
  sizeOf<UnsignedLongLong>(),
  'long',
  type2: 'long',
  modifier: 'unsigned',
);
final intptr_t = CType(
  sizeOf<IntPtr>(),
  'intptr_t',
);
final uintptr_t = CType(
  sizeOf<UintPtr>(),
  'uintptr_t',
);
final size_t = CType(
  sizeOf<Size>(),
  'size_t',
);
final wchar_t = CType(
  sizeOf<WChar>(),
  'wchar_t',
  ffiLoad: (Pointer p) => p.cast<WChar>().value,
);

final cTypes = [
  uchar,
  schar,
  short,
  ushort,
  int_,
  uint,
  long,
  ulong,
  longlong,
  ulonglong,
  intptr_t,
  uintptr_t,
  size_t,
  wchar_t,
];

void printSizes() {
  cTypes.forEach((element) {
    final cName = element.cRepresentation.padRight(20);
    final size = element.size;
    final signed = element.isSigned ? 'signed' : 'unsigned';
    print('$cName: $size $signed');
  });
}

void testSizes() {
  cTypes.forEach((element) {
    print(element);
    Expect.equals(element.size, element.ffiSize);
    final ffiIsSigned = element.ffiIsSigned;
    if (ffiIsSigned != null) {
      Expect.equals(element.isSigned, ffiIsSigned);
    }
  });
}

void testIntAssumptions() {
  Expect.equals(4, int_.size);
  Expect.equals(4, uint.size);
}

void testSizeTAssumptions() {
  Expect.equals(intptr_t.size, size_t.size);
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
  final bool isSigned = wchar_t.isSigned;
  print('wchar_t isSigned $isSigned');
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
