// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=5
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
void main() {
  for (int i = 0; i < 10; ++i) {
    testPassStruct1ByteIntx10();
    testPassStruct3BytesHomogeneousUint8x10();
    testPassStruct3BytesInt2ByteAlignedx10();
    testPassStruct4BytesHomogeneousInt16x10();
    testPassStruct7BytesHomogeneousUint8x10();
    testPassStruct7BytesInt4ByteAlignedx10();
    testPassStruct8BytesIntx10();
    testPassStruct8BytesHomogeneousFloatx10();
    testPassStruct8BytesMixedx10();
    testPassStruct9BytesHomogeneousUint8x10();
    testPassStruct9BytesInt4Or8ByteAlignedx10();
    testPassStruct12BytesHomogeneousFloatx6();
    testPassStruct16BytesHomogeneousFloatx5();
    testPassStruct16BytesMixedx10();
    testPassStruct16BytesMixed2x10();
    testPassStruct17BytesIntx10();
    testPassStruct19BytesHomogeneousUint8x10();
    testPassStruct20BytesHomogeneousInt32x10();
    testPassStruct20BytesHomogeneousFloat();
    testPassStruct32BytesHomogeneousDoublex5();
    testPassStruct40BytesHomogeneousDouble();
    testPassStruct1024BytesHomogeneousUint64();
    testPassFloatStruct16BytesHomogeneousFloatFloatStruct1();
    testPassFloatStruct32BytesHomogeneousDoubleFloatStruct();
    testPassInt8Struct16BytesMixedInt8Struct16BytesMixedIn();
    testPassDoublex6Struct16BytesMixedx4Int32();
    testPassInt32x4Struct16BytesMixedx4Double();
    testPassStruct40BytesHomogeneousDoubleStruct4BytesHomo();
    testPassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int();
    testPassStructAlignmentInt16();
    testPassStructAlignmentInt32();
    testPassStructAlignmentInt64();
    testPassStruct8BytesNestedIntx10();
    testPassStruct8BytesNestedFloatx10();
    testPassStruct8BytesNestedFloat2x10();
    testPassStruct8BytesNestedMixedx10();
    testPassStruct16BytesNestedIntx2();
    testPassStruct32BytesNestedIntx2();
    testPassStructNestedIntStructAlignmentInt16();
    testPassStructNestedIntStructAlignmentInt32();
    testPassStructNestedIntStructAlignmentInt64();
    testPassStructNestedIrregularEvenBiggerx4();
    testReturnStruct1ByteInt();
    testReturnStruct3BytesHomogeneousUint8();
    testReturnStruct3BytesInt2ByteAligned();
    testReturnStruct4BytesHomogeneousInt16();
    testReturnStruct7BytesHomogeneousUint8();
    testReturnStruct7BytesInt4ByteAligned();
    testReturnStruct8BytesInt();
    testReturnStruct8BytesHomogeneousFloat();
    testReturnStruct8BytesMixed();
    testReturnStruct9BytesHomogeneousUint8();
    testReturnStruct9BytesInt4Or8ByteAligned();
    testReturnStruct12BytesHomogeneousFloat();
    testReturnStruct16BytesHomogeneousFloat();
    testReturnStruct16BytesMixed();
    testReturnStruct16BytesMixed2();
    testReturnStruct17BytesInt();
    testReturnStruct19BytesHomogeneousUint8();
    testReturnStruct20BytesHomogeneousInt32();
    testReturnStruct20BytesHomogeneousFloat();
    testReturnStruct32BytesHomogeneousDouble();
    testReturnStruct40BytesHomogeneousDouble();
    testReturnStruct1024BytesHomogeneousUint64();
    testReturnStructArgumentStruct1ByteInt();
    testReturnStructArgumentInt32x8Struct1ByteInt();
    testReturnStructArgumentStruct8BytesHomogeneousFloat();
    testReturnStructArgumentStruct20BytesHomogeneousInt32();
    testReturnStructArgumentInt32x8Struct20BytesHomogeneou();
    testReturnStructAlignmentInt16();
    testReturnStructAlignmentInt32();
    testReturnStructAlignmentInt64();
    testReturnStruct8BytesNestedInt();
    testReturnStruct8BytesNestedFloat();
    testReturnStruct8BytesNestedFloat2();
    testReturnStruct8BytesNestedMixed();
    testReturnStruct16BytesNestedInt();
    testReturnStruct32BytesNestedInt();
    testReturnStructNestedIntStructAlignmentInt16();
    testReturnStructNestedIntStructAlignmentInt32();
    testReturnStructNestedIntStructAlignmentInt64();
    testReturnStructNestedIrregularEvenBigger();
  }
}

class Struct0Bytes extends Struct {
  String toString() => "()";
}

class Struct1ByteInt extends Struct {
  @Int8()
  external int a0;

  String toString() => "(${a0})";
}

class Struct3BytesHomogeneousUint8 extends Struct {
  @Uint8()
  external int a0;

  @Uint8()
  external int a1;

  @Uint8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct3BytesInt2ByteAligned extends Struct {
  @Int16()
  external int a0;

  @Int8()
  external int a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct4BytesHomogeneousInt16 extends Struct {
  @Int16()
  external int a0;

  @Int16()
  external int a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct4BytesFloat extends Struct {
  @Float()
  external double a0;

  String toString() => "(${a0})";
}

class Struct7BytesHomogeneousUint8 extends Struct {
  @Uint8()
  external int a0;

  @Uint8()
  external int a1;

  @Uint8()
  external int a2;

  @Uint8()
  external int a3;

  @Uint8()
  external int a4;

  @Uint8()
  external int a5;

  @Uint8()
  external int a6;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6})";
}

class Struct7BytesInt4ByteAligned extends Struct {
  @Int32()
  external int a0;

  @Int16()
  external int a1;

  @Int8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct8BytesInt extends Struct {
  @Int16()
  external int a0;

  @Int16()
  external int a1;

  @Int32()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct8BytesHomogeneousFloat extends Struct {
  @Float()
  external double a0;

  @Float()
  external double a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct8BytesMixed extends Struct {
  @Float()
  external double a0;

  @Int16()
  external int a1;

  @Int16()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct9BytesHomogeneousUint8 extends Struct {
  @Uint8()
  external int a0;

  @Uint8()
  external int a1;

  @Uint8()
  external int a2;

  @Uint8()
  external int a3;

  @Uint8()
  external int a4;

  @Uint8()
  external int a5;

  @Uint8()
  external int a6;

  @Uint8()
  external int a7;

  @Uint8()
  external int a8;

  String toString() =>
      "(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6}, ${a7}, ${a8})";
}

class Struct9BytesInt4Or8ByteAligned extends Struct {
  @Int64()
  external int a0;

  @Int8()
  external int a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct12BytesHomogeneousFloat extends Struct {
  @Float()
  external double a0;

  @Float()
  external double a1;

  @Float()
  external double a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct16BytesHomogeneousFloat extends Struct {
  @Float()
  external double a0;

  @Float()
  external double a1;

  @Float()
  external double a2;

  @Float()
  external double a3;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3})";
}

class Struct16BytesMixed extends Struct {
  @Double()
  external double a0;

  @Int64()
  external int a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct16BytesMixed2 extends Struct {
  @Float()
  external double a0;

  @Float()
  external double a1;

  @Float()
  external double a2;

  @Int32()
  external int a3;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3})";
}

class Struct17BytesInt extends Struct {
  @Int64()
  external int a0;

  @Int64()
  external int a1;

  @Int8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct19BytesHomogeneousUint8 extends Struct {
  @Uint8()
  external int a0;

  @Uint8()
  external int a1;

  @Uint8()
  external int a2;

  @Uint8()
  external int a3;

  @Uint8()
  external int a4;

  @Uint8()
  external int a5;

  @Uint8()
  external int a6;

  @Uint8()
  external int a7;

  @Uint8()
  external int a8;

  @Uint8()
  external int a9;

  @Uint8()
  external int a10;

  @Uint8()
  external int a11;

  @Uint8()
  external int a12;

  @Uint8()
  external int a13;

  @Uint8()
  external int a14;

  @Uint8()
  external int a15;

  @Uint8()
  external int a16;

  @Uint8()
  external int a17;

  @Uint8()
  external int a18;

  String toString() =>
      "(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6}, ${a7}, ${a8}, ${a9}, ${a10}, ${a11}, ${a12}, ${a13}, ${a14}, ${a15}, ${a16}, ${a17}, ${a18})";
}

class Struct20BytesHomogeneousInt32 extends Struct {
  @Int32()
  external int a0;

  @Int32()
  external int a1;

  @Int32()
  external int a2;

  @Int32()
  external int a3;

  @Int32()
  external int a4;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3}, ${a4})";
}

class Struct20BytesHomogeneousFloat extends Struct {
  @Float()
  external double a0;

  @Float()
  external double a1;

  @Float()
  external double a2;

  @Float()
  external double a3;

  @Float()
  external double a4;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3}, ${a4})";
}

class Struct32BytesHomogeneousDouble extends Struct {
  @Double()
  external double a0;

  @Double()
  external double a1;

  @Double()
  external double a2;

  @Double()
  external double a3;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3})";
}

class Struct40BytesHomogeneousDouble extends Struct {
  @Double()
  external double a0;

  @Double()
  external double a1;

  @Double()
  external double a2;

  @Double()
  external double a3;

  @Double()
  external double a4;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3}, ${a4})";
}

class Struct1024BytesHomogeneousUint64 extends Struct {
  @Uint64()
  external int a0;

  @Uint64()
  external int a1;

  @Uint64()
  external int a2;

  @Uint64()
  external int a3;

  @Uint64()
  external int a4;

  @Uint64()
  external int a5;

  @Uint64()
  external int a6;

  @Uint64()
  external int a7;

  @Uint64()
  external int a8;

  @Uint64()
  external int a9;

  @Uint64()
  external int a10;

  @Uint64()
  external int a11;

  @Uint64()
  external int a12;

  @Uint64()
  external int a13;

  @Uint64()
  external int a14;

  @Uint64()
  external int a15;

  @Uint64()
  external int a16;

  @Uint64()
  external int a17;

  @Uint64()
  external int a18;

  @Uint64()
  external int a19;

  @Uint64()
  external int a20;

  @Uint64()
  external int a21;

  @Uint64()
  external int a22;

  @Uint64()
  external int a23;

  @Uint64()
  external int a24;

  @Uint64()
  external int a25;

  @Uint64()
  external int a26;

  @Uint64()
  external int a27;

  @Uint64()
  external int a28;

  @Uint64()
  external int a29;

  @Uint64()
  external int a30;

  @Uint64()
  external int a31;

  @Uint64()
  external int a32;

  @Uint64()
  external int a33;

  @Uint64()
  external int a34;

  @Uint64()
  external int a35;

  @Uint64()
  external int a36;

  @Uint64()
  external int a37;

  @Uint64()
  external int a38;

  @Uint64()
  external int a39;

  @Uint64()
  external int a40;

  @Uint64()
  external int a41;

  @Uint64()
  external int a42;

  @Uint64()
  external int a43;

  @Uint64()
  external int a44;

  @Uint64()
  external int a45;

  @Uint64()
  external int a46;

  @Uint64()
  external int a47;

  @Uint64()
  external int a48;

  @Uint64()
  external int a49;

  @Uint64()
  external int a50;

  @Uint64()
  external int a51;

  @Uint64()
  external int a52;

  @Uint64()
  external int a53;

  @Uint64()
  external int a54;

  @Uint64()
  external int a55;

  @Uint64()
  external int a56;

  @Uint64()
  external int a57;

  @Uint64()
  external int a58;

  @Uint64()
  external int a59;

  @Uint64()
  external int a60;

  @Uint64()
  external int a61;

  @Uint64()
  external int a62;

  @Uint64()
  external int a63;

  @Uint64()
  external int a64;

  @Uint64()
  external int a65;

  @Uint64()
  external int a66;

  @Uint64()
  external int a67;

  @Uint64()
  external int a68;

  @Uint64()
  external int a69;

  @Uint64()
  external int a70;

  @Uint64()
  external int a71;

  @Uint64()
  external int a72;

  @Uint64()
  external int a73;

  @Uint64()
  external int a74;

  @Uint64()
  external int a75;

  @Uint64()
  external int a76;

  @Uint64()
  external int a77;

  @Uint64()
  external int a78;

  @Uint64()
  external int a79;

  @Uint64()
  external int a80;

  @Uint64()
  external int a81;

  @Uint64()
  external int a82;

  @Uint64()
  external int a83;

  @Uint64()
  external int a84;

  @Uint64()
  external int a85;

  @Uint64()
  external int a86;

  @Uint64()
  external int a87;

  @Uint64()
  external int a88;

  @Uint64()
  external int a89;

  @Uint64()
  external int a90;

  @Uint64()
  external int a91;

  @Uint64()
  external int a92;

  @Uint64()
  external int a93;

  @Uint64()
  external int a94;

  @Uint64()
  external int a95;

  @Uint64()
  external int a96;

  @Uint64()
  external int a97;

  @Uint64()
  external int a98;

  @Uint64()
  external int a99;

  @Uint64()
  external int a100;

  @Uint64()
  external int a101;

  @Uint64()
  external int a102;

  @Uint64()
  external int a103;

  @Uint64()
  external int a104;

  @Uint64()
  external int a105;

  @Uint64()
  external int a106;

  @Uint64()
  external int a107;

  @Uint64()
  external int a108;

  @Uint64()
  external int a109;

  @Uint64()
  external int a110;

  @Uint64()
  external int a111;

  @Uint64()
  external int a112;

  @Uint64()
  external int a113;

  @Uint64()
  external int a114;

  @Uint64()
  external int a115;

  @Uint64()
  external int a116;

  @Uint64()
  external int a117;

  @Uint64()
  external int a118;

  @Uint64()
  external int a119;

  @Uint64()
  external int a120;

  @Uint64()
  external int a121;

  @Uint64()
  external int a122;

  @Uint64()
  external int a123;

  @Uint64()
  external int a124;

  @Uint64()
  external int a125;

  @Uint64()
  external int a126;

  @Uint64()
  external int a127;

  String toString() =>
      "(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6}, ${a7}, ${a8}, ${a9}, ${a10}, ${a11}, ${a12}, ${a13}, ${a14}, ${a15}, ${a16}, ${a17}, ${a18}, ${a19}, ${a20}, ${a21}, ${a22}, ${a23}, ${a24}, ${a25}, ${a26}, ${a27}, ${a28}, ${a29}, ${a30}, ${a31}, ${a32}, ${a33}, ${a34}, ${a35}, ${a36}, ${a37}, ${a38}, ${a39}, ${a40}, ${a41}, ${a42}, ${a43}, ${a44}, ${a45}, ${a46}, ${a47}, ${a48}, ${a49}, ${a50}, ${a51}, ${a52}, ${a53}, ${a54}, ${a55}, ${a56}, ${a57}, ${a58}, ${a59}, ${a60}, ${a61}, ${a62}, ${a63}, ${a64}, ${a65}, ${a66}, ${a67}, ${a68}, ${a69}, ${a70}, ${a71}, ${a72}, ${a73}, ${a74}, ${a75}, ${a76}, ${a77}, ${a78}, ${a79}, ${a80}, ${a81}, ${a82}, ${a83}, ${a84}, ${a85}, ${a86}, ${a87}, ${a88}, ${a89}, ${a90}, ${a91}, ${a92}, ${a93}, ${a94}, ${a95}, ${a96}, ${a97}, ${a98}, ${a99}, ${a100}, ${a101}, ${a102}, ${a103}, ${a104}, ${a105}, ${a106}, ${a107}, ${a108}, ${a109}, ${a110}, ${a111}, ${a112}, ${a113}, ${a114}, ${a115}, ${a116}, ${a117}, ${a118}, ${a119}, ${a120}, ${a121}, ${a122}, ${a123}, ${a124}, ${a125}, ${a126}, ${a127})";
}

class StructAlignmentInt16 extends Struct {
  @Int8()
  external int a0;

  @Int16()
  external int a1;

  @Int8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class StructAlignmentInt32 extends Struct {
  @Int8()
  external int a0;

  @Int32()
  external int a1;

  @Int8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class StructAlignmentInt64 extends Struct {
  @Int8()
  external int a0;

  @Int64()
  external int a1;

  @Int8()
  external int a2;

  String toString() => "(${a0}, ${a1}, ${a2})";
}

class Struct8BytesNestedInt extends Struct {
  external Struct4BytesHomogeneousInt16 a0;

  external Struct4BytesHomogeneousInt16 a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct8BytesNestedFloat extends Struct {
  external Struct4BytesFloat a0;

  external Struct4BytesFloat a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct8BytesNestedFloat2 extends Struct {
  external Struct4BytesFloat a0;

  @Float()
  external double a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct8BytesNestedMixed extends Struct {
  external Struct4BytesHomogeneousInt16 a0;

  external Struct4BytesFloat a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct16BytesNestedInt extends Struct {
  external Struct8BytesNestedInt a0;

  external Struct8BytesNestedInt a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct32BytesNestedInt extends Struct {
  external Struct16BytesNestedInt a0;

  external Struct16BytesNestedInt a1;

  String toString() => "(${a0}, ${a1})";
}

class StructNestedIntStructAlignmentInt16 extends Struct {
  external StructAlignmentInt16 a0;

  external StructAlignmentInt16 a1;

  String toString() => "(${a0}, ${a1})";
}

class StructNestedIntStructAlignmentInt32 extends Struct {
  external StructAlignmentInt32 a0;

  external StructAlignmentInt32 a1;

  String toString() => "(${a0}, ${a1})";
}

class StructNestedIntStructAlignmentInt64 extends Struct {
  external StructAlignmentInt64 a0;

  external StructAlignmentInt64 a1;

  String toString() => "(${a0}, ${a1})";
}

class StructNestedIrregularBig extends Struct {
  @Uint16()
  external int a0;

  external Struct8BytesNestedMixed a1;

  @Uint16()
  external int a2;

  external Struct8BytesNestedFloat2 a3;

  @Uint16()
  external int a4;

  external Struct8BytesNestedFloat a5;

  @Uint16()
  external int a6;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6})";
}

class StructNestedIrregularBigger extends Struct {
  external StructNestedIrregularBig a0;

  external Struct8BytesNestedMixed a1;

  @Float()
  external double a2;

  @Double()
  external double a3;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3})";
}

class StructNestedIrregularEvenBigger extends Struct {
  @Uint64()
  external int a0;

  external StructNestedIrregularBigger a1;

  external StructNestedIrregularBigger a2;

  @Double()
  external double a3;

  String toString() => "(${a0}, ${a1}, ${a2}, ${a3})";
}

final passStruct1ByteIntx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt),
    int Function(
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt,
        Struct1ByteInt)>("PassStruct1ByteIntx10");

/// Smallest struct with data.
/// 10 struct arguments will exhaust available registers.
void testPassStruct1ByteIntx10() {
  Struct1ByteInt a0 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a1 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a2 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a3 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a4 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a5 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a6 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a7 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a8 = allocate<Struct1ByteInt>().ref;
  Struct1ByteInt a9 = allocate<Struct1ByteInt>().ref;

  a0.a0 = -1;
  a1.a0 = 2;
  a2.a0 = -3;
  a3.a0 = 4;
  a4.a0 = -5;
  a5.a0 = 6;
  a6.a0 = -7;
  a7.a0 = 8;
  a8.a0 = -9;
  a9.a0 = 10;

  final result = passStruct1ByteIntx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(5, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct3BytesHomogeneousUint8x10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8),
    int Function(
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8,
        Struct3BytesHomogeneousUint8)>("PassStruct3BytesHomogeneousUint8x10");

/// Not a multiple of word size, not a power of two.
/// 10 struct arguments will exhaust available registers.
void testPassStruct3BytesHomogeneousUint8x10() {
  Struct3BytesHomogeneousUint8 a0 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a1 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a2 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a3 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a4 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a5 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a6 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a7 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a8 =
      allocate<Struct3BytesHomogeneousUint8>().ref;
  Struct3BytesHomogeneousUint8 a9 =
      allocate<Struct3BytesHomogeneousUint8>().ref;

  a0.a0 = 1;
  a0.a1 = 2;
  a0.a2 = 3;
  a1.a0 = 4;
  a1.a1 = 5;
  a1.a2 = 6;
  a2.a0 = 7;
  a2.a1 = 8;
  a2.a2 = 9;
  a3.a0 = 10;
  a3.a1 = 11;
  a3.a2 = 12;
  a4.a0 = 13;
  a4.a1 = 14;
  a4.a2 = 15;
  a5.a0 = 16;
  a5.a1 = 17;
  a5.a2 = 18;
  a6.a0 = 19;
  a6.a1 = 20;
  a6.a2 = 21;
  a7.a0 = 22;
  a7.a1 = 23;
  a7.a2 = 24;
  a8.a0 = 25;
  a8.a1 = 26;
  a8.a2 = 27;
  a9.a0 = 28;
  a9.a1 = 29;
  a9.a2 = 30;

  final result = passStruct3BytesHomogeneousUint8x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(465, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct3BytesInt2ByteAlignedx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned),
    int Function(
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned,
        Struct3BytesInt2ByteAligned)>("PassStruct3BytesInt2ByteAlignedx10");

/// Not a multiple of word size, not a power of two.
/// With alignment rules taken into account size is 4 bytes.
/// 10 struct arguments will exhaust available registers.
void testPassStruct3BytesInt2ByteAlignedx10() {
  Struct3BytesInt2ByteAligned a0 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a1 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a2 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a3 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a4 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a5 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a6 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a7 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a8 = allocate<Struct3BytesInt2ByteAligned>().ref;
  Struct3BytesInt2ByteAligned a9 = allocate<Struct3BytesInt2ByteAligned>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3;
  a1.a1 = 4;
  a2.a0 = -5;
  a2.a1 = 6;
  a3.a0 = -7;
  a3.a1 = 8;
  a4.a0 = -9;
  a4.a1 = 10;
  a5.a0 = -11;
  a5.a1 = 12;
  a6.a0 = -13;
  a6.a1 = 14;
  a7.a0 = -15;
  a7.a1 = 16;
  a8.a0 = -17;
  a8.a1 = 18;
  a9.a0 = -19;
  a9.a1 = 20;

  final result = passStruct3BytesInt2ByteAlignedx10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(10, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct4BytesHomogeneousInt16x10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16),
    int Function(
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16)>("PassStruct4BytesHomogeneousInt16x10");

/// Exactly word size on 32-bit architectures.
/// 10 struct arguments will exhaust available registers.
void testPassStruct4BytesHomogeneousInt16x10() {
  Struct4BytesHomogeneousInt16 a0 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a1 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a2 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a3 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a4 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a5 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a6 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a7 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a8 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a9 =
      allocate<Struct4BytesHomogeneousInt16>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3;
  a1.a1 = 4;
  a2.a0 = -5;
  a2.a1 = 6;
  a3.a0 = -7;
  a3.a1 = 8;
  a4.a0 = -9;
  a4.a1 = 10;
  a5.a0 = -11;
  a5.a1 = 12;
  a6.a0 = -13;
  a6.a1 = 14;
  a7.a0 = -15;
  a7.a1 = 16;
  a8.a0 = -17;
  a8.a1 = 18;
  a9.a0 = -19;
  a9.a1 = 20;

  final result = passStruct4BytesHomogeneousInt16x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(10, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct7BytesHomogeneousUint8x10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8),
    int Function(
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8,
        Struct7BytesHomogeneousUint8)>("PassStruct7BytesHomogeneousUint8x10");

/// Sub word size on 64 bit architectures.
/// 10 struct arguments will exhaust available registers.
void testPassStruct7BytesHomogeneousUint8x10() {
  Struct7BytesHomogeneousUint8 a0 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a1 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a2 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a3 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a4 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a5 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a6 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a7 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a8 =
      allocate<Struct7BytesHomogeneousUint8>().ref;
  Struct7BytesHomogeneousUint8 a9 =
      allocate<Struct7BytesHomogeneousUint8>().ref;

  a0.a0 = 1;
  a0.a1 = 2;
  a0.a2 = 3;
  a0.a3 = 4;
  a0.a4 = 5;
  a0.a5 = 6;
  a0.a6 = 7;
  a1.a0 = 8;
  a1.a1 = 9;
  a1.a2 = 10;
  a1.a3 = 11;
  a1.a4 = 12;
  a1.a5 = 13;
  a1.a6 = 14;
  a2.a0 = 15;
  a2.a1 = 16;
  a2.a2 = 17;
  a2.a3 = 18;
  a2.a4 = 19;
  a2.a5 = 20;
  a2.a6 = 21;
  a3.a0 = 22;
  a3.a1 = 23;
  a3.a2 = 24;
  a3.a3 = 25;
  a3.a4 = 26;
  a3.a5 = 27;
  a3.a6 = 28;
  a4.a0 = 29;
  a4.a1 = 30;
  a4.a2 = 31;
  a4.a3 = 32;
  a4.a4 = 33;
  a4.a5 = 34;
  a4.a6 = 35;
  a5.a0 = 36;
  a5.a1 = 37;
  a5.a2 = 38;
  a5.a3 = 39;
  a5.a4 = 40;
  a5.a5 = 41;
  a5.a6 = 42;
  a6.a0 = 43;
  a6.a1 = 44;
  a6.a2 = 45;
  a6.a3 = 46;
  a6.a4 = 47;
  a6.a5 = 48;
  a6.a6 = 49;
  a7.a0 = 50;
  a7.a1 = 51;
  a7.a2 = 52;
  a7.a3 = 53;
  a7.a4 = 54;
  a7.a5 = 55;
  a7.a6 = 56;
  a8.a0 = 57;
  a8.a1 = 58;
  a8.a2 = 59;
  a8.a3 = 60;
  a8.a4 = 61;
  a8.a5 = 62;
  a8.a6 = 63;
  a9.a0 = 64;
  a9.a1 = 65;
  a9.a2 = 66;
  a9.a3 = 67;
  a9.a4 = 68;
  a9.a5 = 69;
  a9.a6 = 70;

  final result = passStruct7BytesHomogeneousUint8x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(2485, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct7BytesInt4ByteAlignedx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned),
    int Function(
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned,
        Struct7BytesInt4ByteAligned)>("PassStruct7BytesInt4ByteAlignedx10");

/// Sub word size on 64 bit architectures.
/// With alignment rules taken into account size is 8 bytes.
/// 10 struct arguments will exhaust available registers.
void testPassStruct7BytesInt4ByteAlignedx10() {
  Struct7BytesInt4ByteAligned a0 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a1 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a2 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a3 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a4 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a5 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a6 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a7 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a8 = allocate<Struct7BytesInt4ByteAligned>().ref;
  Struct7BytesInt4ByteAligned a9 = allocate<Struct7BytesInt4ByteAligned>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;
  a2.a0 = -7;
  a2.a1 = 8;
  a2.a2 = -9;
  a3.a0 = 10;
  a3.a1 = -11;
  a3.a2 = 12;
  a4.a0 = -13;
  a4.a1 = 14;
  a4.a2 = -15;
  a5.a0 = 16;
  a5.a1 = -17;
  a5.a2 = 18;
  a6.a0 = -19;
  a6.a1 = 20;
  a6.a2 = -21;
  a7.a0 = 22;
  a7.a1 = -23;
  a7.a2 = 24;
  a8.a0 = -25;
  a8.a1 = 26;
  a8.a2 = -27;
  a9.a0 = 28;
  a9.a1 = -29;
  a9.a2 = 30;

  final result = passStruct7BytesInt4ByteAlignedx10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(15, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesIntx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt),
    int Function(
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt,
        Struct8BytesInt)>("PassStruct8BytesIntx10");

/// Exactly word size struct on 64bit architectures.
/// 10 struct arguments will exhaust available registers.
void testPassStruct8BytesIntx10() {
  Struct8BytesInt a0 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a1 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a2 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a3 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a4 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a5 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a6 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a7 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a8 = allocate<Struct8BytesInt>().ref;
  Struct8BytesInt a9 = allocate<Struct8BytesInt>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;
  a2.a0 = -7;
  a2.a1 = 8;
  a2.a2 = -9;
  a3.a0 = 10;
  a3.a1 = -11;
  a3.a2 = 12;
  a4.a0 = -13;
  a4.a1 = 14;
  a4.a2 = -15;
  a5.a0 = 16;
  a5.a1 = -17;
  a5.a2 = 18;
  a6.a0 = -19;
  a6.a1 = 20;
  a6.a2 = -21;
  a7.a0 = 22;
  a7.a1 = -23;
  a7.a2 = 24;
  a8.a0 = -25;
  a8.a1 = 26;
  a8.a2 = -27;
  a9.a0 = 28;
  a9.a1 = -29;
  a9.a2 = 30;

  final result = passStruct8BytesIntx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(15, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesHomogeneousFloatx10 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat),
    double Function(
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat,
        Struct8BytesHomogeneousFloat)>("PassStruct8BytesHomogeneousFloatx10");

/// Arguments passed in FP registers as long as they fit.
/// 10 struct arguments will exhaust available registers.
void testPassStruct8BytesHomogeneousFloatx10() {
  Struct8BytesHomogeneousFloat a0 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a1 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a2 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a3 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a4 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a5 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a6 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a7 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a8 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  Struct8BytesHomogeneousFloat a9 =
      allocate<Struct8BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a1.a0 = -3.0;
  a1.a1 = 4.0;
  a2.a0 = -5.0;
  a2.a1 = 6.0;
  a3.a0 = -7.0;
  a3.a1 = 8.0;
  a4.a0 = -9.0;
  a4.a1 = 10.0;
  a5.a0 = -11.0;
  a5.a1 = 12.0;
  a6.a0 = -13.0;
  a6.a1 = 14.0;
  a7.a0 = -15.0;
  a7.a1 = 16.0;
  a8.a0 = -17.0;
  a8.a1 = 18.0;
  a9.a0 = -19.0;
  a9.a1 = 20.0;

  final result = passStruct8BytesHomogeneousFloatx10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesMixedx10 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed),
    double Function(
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed,
        Struct8BytesMixed)>("PassStruct8BytesMixedx10");

/// On x64, arguments go in int registers because it is not only float.
/// 10 struct arguments will exhaust available registers.
void testPassStruct8BytesMixedx10() {
  Struct8BytesMixed a0 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a1 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a2 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a3 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a4 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a5 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a6 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a7 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a8 = allocate<Struct8BytesMixed>().ref;
  Struct8BytesMixed a9 = allocate<Struct8BytesMixed>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4.0;
  a1.a1 = -5;
  a1.a2 = 6;
  a2.a0 = -7.0;
  a2.a1 = 8;
  a2.a2 = -9;
  a3.a0 = 10.0;
  a3.a1 = -11;
  a3.a2 = 12;
  a4.a0 = -13.0;
  a4.a1 = 14;
  a4.a2 = -15;
  a5.a0 = 16.0;
  a5.a1 = -17;
  a5.a2 = 18;
  a6.a0 = -19.0;
  a6.a1 = 20;
  a6.a2 = -21;
  a7.a0 = 22.0;
  a7.a1 = -23;
  a7.a2 = 24;
  a8.a0 = -25.0;
  a8.a1 = 26;
  a8.a2 = -27;
  a9.a0 = 28.0;
  a9.a1 = -29;
  a9.a2 = 30;

  final result =
      passStruct8BytesMixedx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(15.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct9BytesHomogeneousUint8x10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8),
    int Function(
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8,
        Struct9BytesHomogeneousUint8)>("PassStruct9BytesHomogeneousUint8x10");

/// Argument is a single byte over a multiple of word size.
/// 10 struct arguments will exhaust available registers.
/// Struct only has 1-byte aligned fields to test struct alignment itself.
/// Tests upper bytes in the integer registers that are partly filled.
/// Tests stack alignment of non word size stack arguments.
void testPassStruct9BytesHomogeneousUint8x10() {
  Struct9BytesHomogeneousUint8 a0 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a1 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a2 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a3 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a4 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a5 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a6 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a7 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a8 =
      allocate<Struct9BytesHomogeneousUint8>().ref;
  Struct9BytesHomogeneousUint8 a9 =
      allocate<Struct9BytesHomogeneousUint8>().ref;

  a0.a0 = 1;
  a0.a1 = 2;
  a0.a2 = 3;
  a0.a3 = 4;
  a0.a4 = 5;
  a0.a5 = 6;
  a0.a6 = 7;
  a0.a7 = 8;
  a0.a8 = 9;
  a1.a0 = 10;
  a1.a1 = 11;
  a1.a2 = 12;
  a1.a3 = 13;
  a1.a4 = 14;
  a1.a5 = 15;
  a1.a6 = 16;
  a1.a7 = 17;
  a1.a8 = 18;
  a2.a0 = 19;
  a2.a1 = 20;
  a2.a2 = 21;
  a2.a3 = 22;
  a2.a4 = 23;
  a2.a5 = 24;
  a2.a6 = 25;
  a2.a7 = 26;
  a2.a8 = 27;
  a3.a0 = 28;
  a3.a1 = 29;
  a3.a2 = 30;
  a3.a3 = 31;
  a3.a4 = 32;
  a3.a5 = 33;
  a3.a6 = 34;
  a3.a7 = 35;
  a3.a8 = 36;
  a4.a0 = 37;
  a4.a1 = 38;
  a4.a2 = 39;
  a4.a3 = 40;
  a4.a4 = 41;
  a4.a5 = 42;
  a4.a6 = 43;
  a4.a7 = 44;
  a4.a8 = 45;
  a5.a0 = 46;
  a5.a1 = 47;
  a5.a2 = 48;
  a5.a3 = 49;
  a5.a4 = 50;
  a5.a5 = 51;
  a5.a6 = 52;
  a5.a7 = 53;
  a5.a8 = 54;
  a6.a0 = 55;
  a6.a1 = 56;
  a6.a2 = 57;
  a6.a3 = 58;
  a6.a4 = 59;
  a6.a5 = 60;
  a6.a6 = 61;
  a6.a7 = 62;
  a6.a8 = 63;
  a7.a0 = 64;
  a7.a1 = 65;
  a7.a2 = 66;
  a7.a3 = 67;
  a7.a4 = 68;
  a7.a5 = 69;
  a7.a6 = 70;
  a7.a7 = 71;
  a7.a8 = 72;
  a8.a0 = 73;
  a8.a1 = 74;
  a8.a2 = 75;
  a8.a3 = 76;
  a8.a4 = 77;
  a8.a5 = 78;
  a8.a6 = 79;
  a8.a7 = 80;
  a8.a8 = 81;
  a9.a0 = 82;
  a9.a1 = 83;
  a9.a2 = 84;
  a9.a3 = 85;
  a9.a4 = 86;
  a9.a5 = 87;
  a9.a6 = 88;
  a9.a7 = 89;
  a9.a8 = 90;

  final result = passStruct9BytesHomogeneousUint8x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(4095, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct9BytesInt4Or8ByteAlignedx10 = ffiTestFunctions.lookupFunction<
        Int64 Function(
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned),
        int Function(
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned,
            Struct9BytesInt4Or8ByteAligned)>(
    "PassStruct9BytesInt4Or8ByteAlignedx10");

/// Argument is a single byte over a multiple of word size.
/// With alignment rules taken into account size is 12 or 16 bytes.
/// 10 struct arguments will exhaust available registers.
///
void testPassStruct9BytesInt4Or8ByteAlignedx10() {
  Struct9BytesInt4Or8ByteAligned a0 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a1 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a2 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a3 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a4 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a5 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a6 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a7 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a8 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;
  Struct9BytesInt4Or8ByteAligned a9 =
      allocate<Struct9BytesInt4Or8ByteAligned>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3;
  a1.a1 = 4;
  a2.a0 = -5;
  a2.a1 = 6;
  a3.a0 = -7;
  a3.a1 = 8;
  a4.a0 = -9;
  a4.a1 = 10;
  a5.a0 = -11;
  a5.a1 = 12;
  a6.a0 = -13;
  a6.a1 = 14;
  a7.a0 = -15;
  a7.a1 = 16;
  a8.a0 = -17;
  a8.a1 = 18;
  a9.a0 = -19;
  a9.a1 = 20;

  final result = passStruct9BytesInt4Or8ByteAlignedx10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(10, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct12BytesHomogeneousFloatx6 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat),
    double Function(
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat,
        Struct12BytesHomogeneousFloat)>("PassStruct12BytesHomogeneousFloatx6");

/// Arguments in FPU registers on arm hardfp and arm64.
/// Struct arguments will exhaust available registers, and leave some empty.
/// The last argument is to test whether arguments are backfilled.
void testPassStruct12BytesHomogeneousFloatx6() {
  Struct12BytesHomogeneousFloat a0 =
      allocate<Struct12BytesHomogeneousFloat>().ref;
  Struct12BytesHomogeneousFloat a1 =
      allocate<Struct12BytesHomogeneousFloat>().ref;
  Struct12BytesHomogeneousFloat a2 =
      allocate<Struct12BytesHomogeneousFloat>().ref;
  Struct12BytesHomogeneousFloat a3 =
      allocate<Struct12BytesHomogeneousFloat>().ref;
  Struct12BytesHomogeneousFloat a4 =
      allocate<Struct12BytesHomogeneousFloat>().ref;
  Struct12BytesHomogeneousFloat a5 =
      allocate<Struct12BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a1.a0 = 4.0;
  a1.a1 = -5.0;
  a1.a2 = 6.0;
  a2.a0 = -7.0;
  a2.a1 = 8.0;
  a2.a2 = -9.0;
  a3.a0 = 10.0;
  a3.a1 = -11.0;
  a3.a2 = 12.0;
  a4.a0 = -13.0;
  a4.a1 = 14.0;
  a4.a2 = -15.0;
  a5.a0 = 16.0;
  a5.a1 = -17.0;
  a5.a2 = 18.0;

  final result = passStruct12BytesHomogeneousFloatx6(a0, a1, a2, a3, a4, a5);

  print("result = $result");

  Expect.approxEquals(9.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
}

final passStruct16BytesHomogeneousFloatx5 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat),
    double Function(
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat,
        Struct16BytesHomogeneousFloat)>("PassStruct16BytesHomogeneousFloatx5");

/// On Linux x64 argument is transferred on stack because it is over 16 bytes.
/// Arguments in FPU registers on arm hardfp and arm64.
/// 5 struct arguments will exhaust available registers.
void testPassStruct16BytesHomogeneousFloatx5() {
  Struct16BytesHomogeneousFloat a0 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  Struct16BytesHomogeneousFloat a1 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  Struct16BytesHomogeneousFloat a2 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  Struct16BytesHomogeneousFloat a3 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  Struct16BytesHomogeneousFloat a4 =
      allocate<Struct16BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a1.a0 = -5.0;
  a1.a1 = 6.0;
  a1.a2 = -7.0;
  a1.a3 = 8.0;
  a2.a0 = -9.0;
  a2.a1 = 10.0;
  a2.a2 = -11.0;
  a2.a3 = 12.0;
  a3.a0 = -13.0;
  a3.a1 = 14.0;
  a3.a2 = -15.0;
  a3.a3 = 16.0;
  a4.a0 = -17.0;
  a4.a1 = 18.0;
  a4.a2 = -19.0;
  a4.a3 = 20.0;

  final result = passStruct16BytesHomogeneousFloatx5(a0, a1, a2, a3, a4);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
}

final passStruct16BytesMixedx10 = ffiTestFunctions.lookupFunction<
    Double Function(
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed),
    double Function(
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed)>("PassStruct16BytesMixedx10");

/// On x64, arguments are split over FP and int registers.
/// On x64, it will exhaust the integer registers with the 6th argument.
/// The rest goes on the stack.
/// On arm, arguments are 8 byte aligned.
void testPassStruct16BytesMixedx10() {
  Struct16BytesMixed a0 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a1 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a2 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a3 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a4 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a5 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a6 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a7 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a8 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a9 = allocate<Struct16BytesMixed>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2;
  a1.a0 = -3.0;
  a1.a1 = 4;
  a2.a0 = -5.0;
  a2.a1 = 6;
  a3.a0 = -7.0;
  a3.a1 = 8;
  a4.a0 = -9.0;
  a4.a1 = 10;
  a5.a0 = -11.0;
  a5.a1 = 12;
  a6.a0 = -13.0;
  a6.a1 = 14;
  a7.a0 = -15.0;
  a7.a1 = 16;
  a8.a0 = -17.0;
  a8.a1 = 18;
  a9.a0 = -19.0;
  a9.a1 = 20;

  final result =
      passStruct16BytesMixedx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct16BytesMixed2x10 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2),
    double Function(
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2,
        Struct16BytesMixed2)>("PassStruct16BytesMixed2x10");

/// On x64, arguments are split over FP and int registers.
/// On x64, it will exhaust the integer registers with the 6th argument.
/// The rest goes on the stack.
/// On arm, arguments are 4 byte aligned.
void testPassStruct16BytesMixed2x10() {
  Struct16BytesMixed2 a0 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a1 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a2 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a3 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a4 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a5 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a6 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a7 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a8 = allocate<Struct16BytesMixed2>().ref;
  Struct16BytesMixed2 a9 = allocate<Struct16BytesMixed2>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4;
  a1.a0 = -5.0;
  a1.a1 = 6.0;
  a1.a2 = -7.0;
  a1.a3 = 8;
  a2.a0 = -9.0;
  a2.a1 = 10.0;
  a2.a2 = -11.0;
  a2.a3 = 12;
  a3.a0 = -13.0;
  a3.a1 = 14.0;
  a3.a2 = -15.0;
  a3.a3 = 16;
  a4.a0 = -17.0;
  a4.a1 = 18.0;
  a4.a2 = -19.0;
  a4.a3 = 20;
  a5.a0 = -21.0;
  a5.a1 = 22.0;
  a5.a2 = -23.0;
  a5.a3 = 24;
  a6.a0 = -25.0;
  a6.a1 = 26.0;
  a6.a2 = -27.0;
  a6.a3 = 28;
  a7.a0 = -29.0;
  a7.a1 = 30.0;
  a7.a2 = -31.0;
  a7.a3 = 32;
  a8.a0 = -33.0;
  a8.a1 = 34.0;
  a8.a2 = -35.0;
  a8.a3 = 36;
  a9.a0 = -37.0;
  a9.a1 = 38.0;
  a9.a2 = -39.0;
  a9.a3 = 40;

  final result =
      passStruct16BytesMixed2x10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(20.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct17BytesIntx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt),
    int Function(
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt,
        Struct17BytesInt)>("PassStruct17BytesIntx10");

/// Arguments are passed as pointer to copy on arm64.
/// Tests that the memory allocated for copies are rounded up to word size.
void testPassStruct17BytesIntx10() {
  Struct17BytesInt a0 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a1 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a2 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a3 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a4 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a5 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a6 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a7 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a8 = allocate<Struct17BytesInt>().ref;
  Struct17BytesInt a9 = allocate<Struct17BytesInt>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;
  a2.a0 = -7;
  a2.a1 = 8;
  a2.a2 = -9;
  a3.a0 = 10;
  a3.a1 = -11;
  a3.a2 = 12;
  a4.a0 = -13;
  a4.a1 = 14;
  a4.a2 = -15;
  a5.a0 = 16;
  a5.a1 = -17;
  a5.a2 = 18;
  a6.a0 = -19;
  a6.a1 = 20;
  a6.a2 = -21;
  a7.a0 = 22;
  a7.a1 = -23;
  a7.a2 = 24;
  a8.a0 = -25;
  a8.a1 = 26;
  a8.a2 = -27;
  a9.a0 = 28;
  a9.a1 = -29;
  a9.a2 = 30;

  final result =
      passStruct17BytesIntx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(15, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct19BytesHomogeneousUint8x10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8),
    int Function(
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8,
        Struct19BytesHomogeneousUint8)>("PassStruct19BytesHomogeneousUint8x10");

/// The minimum alignment of this struct is only 1 byte based on its fields.
/// Test that the memory backing these structs is extended to the right size.
///
void testPassStruct19BytesHomogeneousUint8x10() {
  Struct19BytesHomogeneousUint8 a0 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a1 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a2 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a3 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a4 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a5 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a6 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a7 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a8 =
      allocate<Struct19BytesHomogeneousUint8>().ref;
  Struct19BytesHomogeneousUint8 a9 =
      allocate<Struct19BytesHomogeneousUint8>().ref;

  a0.a0 = 1;
  a0.a1 = 2;
  a0.a2 = 3;
  a0.a3 = 4;
  a0.a4 = 5;
  a0.a5 = 6;
  a0.a6 = 7;
  a0.a7 = 8;
  a0.a8 = 9;
  a0.a9 = 10;
  a0.a10 = 11;
  a0.a11 = 12;
  a0.a12 = 13;
  a0.a13 = 14;
  a0.a14 = 15;
  a0.a15 = 16;
  a0.a16 = 17;
  a0.a17 = 18;
  a0.a18 = 19;
  a1.a0 = 20;
  a1.a1 = 21;
  a1.a2 = 22;
  a1.a3 = 23;
  a1.a4 = 24;
  a1.a5 = 25;
  a1.a6 = 26;
  a1.a7 = 27;
  a1.a8 = 28;
  a1.a9 = 29;
  a1.a10 = 30;
  a1.a11 = 31;
  a1.a12 = 32;
  a1.a13 = 33;
  a1.a14 = 34;
  a1.a15 = 35;
  a1.a16 = 36;
  a1.a17 = 37;
  a1.a18 = 38;
  a2.a0 = 39;
  a2.a1 = 40;
  a2.a2 = 41;
  a2.a3 = 42;
  a2.a4 = 43;
  a2.a5 = 44;
  a2.a6 = 45;
  a2.a7 = 46;
  a2.a8 = 47;
  a2.a9 = 48;
  a2.a10 = 49;
  a2.a11 = 50;
  a2.a12 = 51;
  a2.a13 = 52;
  a2.a14 = 53;
  a2.a15 = 54;
  a2.a16 = 55;
  a2.a17 = 56;
  a2.a18 = 57;
  a3.a0 = 58;
  a3.a1 = 59;
  a3.a2 = 60;
  a3.a3 = 61;
  a3.a4 = 62;
  a3.a5 = 63;
  a3.a6 = 64;
  a3.a7 = 65;
  a3.a8 = 66;
  a3.a9 = 67;
  a3.a10 = 68;
  a3.a11 = 69;
  a3.a12 = 70;
  a3.a13 = 71;
  a3.a14 = 72;
  a3.a15 = 73;
  a3.a16 = 74;
  a3.a17 = 75;
  a3.a18 = 76;
  a4.a0 = 77;
  a4.a1 = 78;
  a4.a2 = 79;
  a4.a3 = 80;
  a4.a4 = 81;
  a4.a5 = 82;
  a4.a6 = 83;
  a4.a7 = 84;
  a4.a8 = 85;
  a4.a9 = 86;
  a4.a10 = 87;
  a4.a11 = 88;
  a4.a12 = 89;
  a4.a13 = 90;
  a4.a14 = 91;
  a4.a15 = 92;
  a4.a16 = 93;
  a4.a17 = 94;
  a4.a18 = 95;
  a5.a0 = 96;
  a5.a1 = 97;
  a5.a2 = 98;
  a5.a3 = 99;
  a5.a4 = 100;
  a5.a5 = 101;
  a5.a6 = 102;
  a5.a7 = 103;
  a5.a8 = 104;
  a5.a9 = 105;
  a5.a10 = 106;
  a5.a11 = 107;
  a5.a12 = 108;
  a5.a13 = 109;
  a5.a14 = 110;
  a5.a15 = 111;
  a5.a16 = 112;
  a5.a17 = 113;
  a5.a18 = 114;
  a6.a0 = 115;
  a6.a1 = 116;
  a6.a2 = 117;
  a6.a3 = 118;
  a6.a4 = 119;
  a6.a5 = 120;
  a6.a6 = 121;
  a6.a7 = 122;
  a6.a8 = 123;
  a6.a9 = 124;
  a6.a10 = 125;
  a6.a11 = 126;
  a6.a12 = 127;
  a6.a13 = 128;
  a6.a14 = 129;
  a6.a15 = 130;
  a6.a16 = 131;
  a6.a17 = 132;
  a6.a18 = 133;
  a7.a0 = 134;
  a7.a1 = 135;
  a7.a2 = 136;
  a7.a3 = 137;
  a7.a4 = 138;
  a7.a5 = 139;
  a7.a6 = 140;
  a7.a7 = 141;
  a7.a8 = 142;
  a7.a9 = 143;
  a7.a10 = 144;
  a7.a11 = 145;
  a7.a12 = 146;
  a7.a13 = 147;
  a7.a14 = 148;
  a7.a15 = 149;
  a7.a16 = 150;
  a7.a17 = 151;
  a7.a18 = 152;
  a8.a0 = 153;
  a8.a1 = 154;
  a8.a2 = 155;
  a8.a3 = 156;
  a8.a4 = 157;
  a8.a5 = 158;
  a8.a6 = 159;
  a8.a7 = 160;
  a8.a8 = 161;
  a8.a9 = 162;
  a8.a10 = 163;
  a8.a11 = 164;
  a8.a12 = 165;
  a8.a13 = 166;
  a8.a14 = 167;
  a8.a15 = 168;
  a8.a16 = 169;
  a8.a17 = 170;
  a8.a18 = 171;
  a9.a0 = 172;
  a9.a1 = 173;
  a9.a2 = 174;
  a9.a3 = 175;
  a9.a4 = 176;
  a9.a5 = 177;
  a9.a6 = 178;
  a9.a7 = 179;
  a9.a8 = 180;
  a9.a9 = 181;
  a9.a10 = 182;
  a9.a11 = 183;
  a9.a12 = 184;
  a9.a13 = 185;
  a9.a14 = 186;
  a9.a15 = 187;
  a9.a16 = 188;
  a9.a17 = 189;
  a9.a18 = 190;

  final result = passStruct19BytesHomogeneousUint8x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(18145, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct20BytesHomogeneousInt32x10 = ffiTestFunctions.lookupFunction<
    Int32 Function(
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32),
    int Function(
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32,
        Struct20BytesHomogeneousInt32)>("PassStruct20BytesHomogeneousInt32x10");

/// Argument too big to go into integer registers on arm64.
/// The arguments are passed as pointers to copies.
/// The amount of arguments exhausts the number of integer registers, such that
/// pointers to copies are also passed on the stack.
void testPassStruct20BytesHomogeneousInt32x10() {
  Struct20BytesHomogeneousInt32 a0 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a1 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a2 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a3 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a4 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a5 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a6 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a7 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a8 =
      allocate<Struct20BytesHomogeneousInt32>().ref;
  Struct20BytesHomogeneousInt32 a9 =
      allocate<Struct20BytesHomogeneousInt32>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a0.a3 = 4;
  a0.a4 = -5;
  a1.a0 = 6;
  a1.a1 = -7;
  a1.a2 = 8;
  a1.a3 = -9;
  a1.a4 = 10;
  a2.a0 = -11;
  a2.a1 = 12;
  a2.a2 = -13;
  a2.a3 = 14;
  a2.a4 = -15;
  a3.a0 = 16;
  a3.a1 = -17;
  a3.a2 = 18;
  a3.a3 = -19;
  a3.a4 = 20;
  a4.a0 = -21;
  a4.a1 = 22;
  a4.a2 = -23;
  a4.a3 = 24;
  a4.a4 = -25;
  a5.a0 = 26;
  a5.a1 = -27;
  a5.a2 = 28;
  a5.a3 = -29;
  a5.a4 = 30;
  a6.a0 = -31;
  a6.a1 = 32;
  a6.a2 = -33;
  a6.a3 = 34;
  a6.a4 = -35;
  a7.a0 = 36;
  a7.a1 = -37;
  a7.a2 = 38;
  a7.a3 = -39;
  a7.a4 = 40;
  a8.a0 = -41;
  a8.a1 = 42;
  a8.a2 = -43;
  a8.a3 = 44;
  a8.a4 = -45;
  a9.a0 = 46;
  a9.a1 = -47;
  a9.a2 = 48;
  a9.a3 = -49;
  a9.a4 = 50;

  final result = passStruct20BytesHomogeneousInt32x10(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(25, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct20BytesHomogeneousFloat = ffiTestFunctions.lookupFunction<
    Float Function(Struct20BytesHomogeneousFloat),
    double Function(
        Struct20BytesHomogeneousFloat)>("PassStruct20BytesHomogeneousFloat");

/// Argument too big to go into FPU registers in hardfp and arm64.
void testPassStruct20BytesHomogeneousFloat() {
  Struct20BytesHomogeneousFloat a0 =
      allocate<Struct20BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;

  final result = passStruct20BytesHomogeneousFloat(a0);

  print("result = $result");

  Expect.approxEquals(-3.0, result);

  free(a0.addressOf);
}

final passStruct32BytesHomogeneousDoublex5 = ffiTestFunctions.lookupFunction<
        Double Function(
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble),
        double Function(
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble,
            Struct32BytesHomogeneousDouble)>(
    "PassStruct32BytesHomogeneousDoublex5");

/// Arguments in FPU registers on arm64.
/// 5 struct arguments will exhaust available registers.
void testPassStruct32BytesHomogeneousDoublex5() {
  Struct32BytesHomogeneousDouble a0 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  Struct32BytesHomogeneousDouble a1 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  Struct32BytesHomogeneousDouble a2 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  Struct32BytesHomogeneousDouble a3 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  Struct32BytesHomogeneousDouble a4 =
      allocate<Struct32BytesHomogeneousDouble>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a1.a0 = -5.0;
  a1.a1 = 6.0;
  a1.a2 = -7.0;
  a1.a3 = 8.0;
  a2.a0 = -9.0;
  a2.a1 = 10.0;
  a2.a2 = -11.0;
  a2.a3 = 12.0;
  a3.a0 = -13.0;
  a3.a1 = 14.0;
  a3.a2 = -15.0;
  a3.a3 = 16.0;
  a4.a0 = -17.0;
  a4.a1 = 18.0;
  a4.a2 = -19.0;
  a4.a3 = 20.0;

  final result = passStruct32BytesHomogeneousDoublex5(a0, a1, a2, a3, a4);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
}

final passStruct40BytesHomogeneousDouble = ffiTestFunctions.lookupFunction<
    Double Function(Struct40BytesHomogeneousDouble),
    double Function(
        Struct40BytesHomogeneousDouble)>("PassStruct40BytesHomogeneousDouble");

/// Argument too big to go into FPU registers in arm64.
void testPassStruct40BytesHomogeneousDouble() {
  Struct40BytesHomogeneousDouble a0 =
      allocate<Struct40BytesHomogeneousDouble>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;

  final result = passStruct40BytesHomogeneousDouble(a0);

  print("result = $result");

  Expect.approxEquals(-3.0, result);

  free(a0.addressOf);
}

final passStruct1024BytesHomogeneousUint64 = ffiTestFunctions.lookupFunction<
        Uint64 Function(Struct1024BytesHomogeneousUint64),
        int Function(Struct1024BytesHomogeneousUint64)>(
    "PassStruct1024BytesHomogeneousUint64");

/// Test 1kb struct.
void testPassStruct1024BytesHomogeneousUint64() {
  Struct1024BytesHomogeneousUint64 a0 =
      allocate<Struct1024BytesHomogeneousUint64>().ref;

  a0.a0 = 1;
  a0.a1 = 2;
  a0.a2 = 3;
  a0.a3 = 4;
  a0.a4 = 5;
  a0.a5 = 6;
  a0.a6 = 7;
  a0.a7 = 8;
  a0.a8 = 9;
  a0.a9 = 10;
  a0.a10 = 11;
  a0.a11 = 12;
  a0.a12 = 13;
  a0.a13 = 14;
  a0.a14 = 15;
  a0.a15 = 16;
  a0.a16 = 17;
  a0.a17 = 18;
  a0.a18 = 19;
  a0.a19 = 20;
  a0.a20 = 21;
  a0.a21 = 22;
  a0.a22 = 23;
  a0.a23 = 24;
  a0.a24 = 25;
  a0.a25 = 26;
  a0.a26 = 27;
  a0.a27 = 28;
  a0.a28 = 29;
  a0.a29 = 30;
  a0.a30 = 31;
  a0.a31 = 32;
  a0.a32 = 33;
  a0.a33 = 34;
  a0.a34 = 35;
  a0.a35 = 36;
  a0.a36 = 37;
  a0.a37 = 38;
  a0.a38 = 39;
  a0.a39 = 40;
  a0.a40 = 41;
  a0.a41 = 42;
  a0.a42 = 43;
  a0.a43 = 44;
  a0.a44 = 45;
  a0.a45 = 46;
  a0.a46 = 47;
  a0.a47 = 48;
  a0.a48 = 49;
  a0.a49 = 50;
  a0.a50 = 51;
  a0.a51 = 52;
  a0.a52 = 53;
  a0.a53 = 54;
  a0.a54 = 55;
  a0.a55 = 56;
  a0.a56 = 57;
  a0.a57 = 58;
  a0.a58 = 59;
  a0.a59 = 60;
  a0.a60 = 61;
  a0.a61 = 62;
  a0.a62 = 63;
  a0.a63 = 64;
  a0.a64 = 65;
  a0.a65 = 66;
  a0.a66 = 67;
  a0.a67 = 68;
  a0.a68 = 69;
  a0.a69 = 70;
  a0.a70 = 71;
  a0.a71 = 72;
  a0.a72 = 73;
  a0.a73 = 74;
  a0.a74 = 75;
  a0.a75 = 76;
  a0.a76 = 77;
  a0.a77 = 78;
  a0.a78 = 79;
  a0.a79 = 80;
  a0.a80 = 81;
  a0.a81 = 82;
  a0.a82 = 83;
  a0.a83 = 84;
  a0.a84 = 85;
  a0.a85 = 86;
  a0.a86 = 87;
  a0.a87 = 88;
  a0.a88 = 89;
  a0.a89 = 90;
  a0.a90 = 91;
  a0.a91 = 92;
  a0.a92 = 93;
  a0.a93 = 94;
  a0.a94 = 95;
  a0.a95 = 96;
  a0.a96 = 97;
  a0.a97 = 98;
  a0.a98 = 99;
  a0.a99 = 100;
  a0.a100 = 101;
  a0.a101 = 102;
  a0.a102 = 103;
  a0.a103 = 104;
  a0.a104 = 105;
  a0.a105 = 106;
  a0.a106 = 107;
  a0.a107 = 108;
  a0.a108 = 109;
  a0.a109 = 110;
  a0.a110 = 111;
  a0.a111 = 112;
  a0.a112 = 113;
  a0.a113 = 114;
  a0.a114 = 115;
  a0.a115 = 116;
  a0.a116 = 117;
  a0.a117 = 118;
  a0.a118 = 119;
  a0.a119 = 120;
  a0.a120 = 121;
  a0.a121 = 122;
  a0.a122 = 123;
  a0.a123 = 124;
  a0.a124 = 125;
  a0.a125 = 126;
  a0.a126 = 127;
  a0.a127 = 128;

  final result = passStruct1024BytesHomogeneousUint64(a0);

  print("result = $result");

  Expect.equals(8256, result);

  free(a0.addressOf);
}

final passFloatStruct16BytesHomogeneousFloatFloatStruct1 =
    ffiTestFunctions.lookupFunction<
        Float Function(
            Float,
            Struct16BytesHomogeneousFloat,
            Float,
            Struct16BytesHomogeneousFloat,
            Float,
            Struct16BytesHomogeneousFloat,
            Float,
            Struct16BytesHomogeneousFloat,
            Float),
        double Function(
            double,
            Struct16BytesHomogeneousFloat,
            double,
            Struct16BytesHomogeneousFloat,
            double,
            Struct16BytesHomogeneousFloat,
            double,
            Struct16BytesHomogeneousFloat,
            double)>("PassFloatStruct16BytesHomogeneousFloatFloatStruct1");

/// Tests the alignment of structs in FPU registers and backfilling.
void testPassFloatStruct16BytesHomogeneousFloatFloatStruct1() {
  double a0;
  Struct16BytesHomogeneousFloat a1 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  double a2;
  Struct16BytesHomogeneousFloat a3 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  double a4;
  Struct16BytesHomogeneousFloat a5 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  double a6;
  Struct16BytesHomogeneousFloat a7 =
      allocate<Struct16BytesHomogeneousFloat>().ref;
  double a8;

  a0 = -1.0;
  a1.a0 = 2.0;
  a1.a1 = -3.0;
  a1.a2 = 4.0;
  a1.a3 = -5.0;
  a2 = 6.0;
  a3.a0 = -7.0;
  a3.a1 = 8.0;
  a3.a2 = -9.0;
  a3.a3 = 10.0;
  a4 = -11.0;
  a5.a0 = 12.0;
  a5.a1 = -13.0;
  a5.a2 = 14.0;
  a5.a3 = -15.0;
  a6 = 16.0;
  a7.a0 = -17.0;
  a7.a1 = 18.0;
  a7.a2 = -19.0;
  a7.a3 = 20.0;
  a8 = -21.0;

  final result = passFloatStruct16BytesHomogeneousFloatFloatStruct1(
      a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.approxEquals(-11.0, result);

  free(a1.addressOf);
  free(a3.addressOf);
  free(a5.addressOf);
  free(a7.addressOf);
}

final passFloatStruct32BytesHomogeneousDoubleFloatStruct =
    ffiTestFunctions.lookupFunction<
        Double Function(
            Float,
            Struct32BytesHomogeneousDouble,
            Float,
            Struct32BytesHomogeneousDouble,
            Float,
            Struct32BytesHomogeneousDouble,
            Float,
            Struct32BytesHomogeneousDouble,
            Float),
        double Function(
            double,
            Struct32BytesHomogeneousDouble,
            double,
            Struct32BytesHomogeneousDouble,
            double,
            Struct32BytesHomogeneousDouble,
            double,
            Struct32BytesHomogeneousDouble,
            double)>("PassFloatStruct32BytesHomogeneousDoubleFloatStruct");

/// Tests the alignment of structs in FPU registers and backfilling.
void testPassFloatStruct32BytesHomogeneousDoubleFloatStruct() {
  double a0;
  Struct32BytesHomogeneousDouble a1 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  double a2;
  Struct32BytesHomogeneousDouble a3 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  double a4;
  Struct32BytesHomogeneousDouble a5 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  double a6;
  Struct32BytesHomogeneousDouble a7 =
      allocate<Struct32BytesHomogeneousDouble>().ref;
  double a8;

  a0 = -1.0;
  a1.a0 = 2.0;
  a1.a1 = -3.0;
  a1.a2 = 4.0;
  a1.a3 = -5.0;
  a2 = 6.0;
  a3.a0 = -7.0;
  a3.a1 = 8.0;
  a3.a2 = -9.0;
  a3.a3 = 10.0;
  a4 = -11.0;
  a5.a0 = 12.0;
  a5.a1 = -13.0;
  a5.a2 = 14.0;
  a5.a3 = -15.0;
  a6 = 16.0;
  a7.a0 = -17.0;
  a7.a1 = 18.0;
  a7.a2 = -19.0;
  a7.a3 = 20.0;
  a8 = -21.0;

  final result = passFloatStruct32BytesHomogeneousDoubleFloatStruct(
      a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.approxEquals(-11.0, result);

  free(a1.addressOf);
  free(a3.addressOf);
  free(a5.addressOf);
  free(a7.addressOf);
}

final passInt8Struct16BytesMixedInt8Struct16BytesMixedIn =
    ffiTestFunctions.lookupFunction<
        Double Function(Int8, Struct16BytesMixed, Int8, Struct16BytesMixed,
            Int8, Struct16BytesMixed, Int8, Struct16BytesMixed, Int8),
        double Function(
            int,
            Struct16BytesMixed,
            int,
            Struct16BytesMixed,
            int,
            Struct16BytesMixed,
            int,
            Struct16BytesMixed,
            int)>("PassInt8Struct16BytesMixedInt8Struct16BytesMixedIn");

/// Tests the alignment of structs in integers registers and on the stack.
/// Arm32 aligns this struct at 8.
/// Also, arm32 allocates the second struct partially in registers, partially
/// on stack.
/// Test backfilling of integer registers.
void testPassInt8Struct16BytesMixedInt8Struct16BytesMixedIn() {
  int a0;
  Struct16BytesMixed a1 = allocate<Struct16BytesMixed>().ref;
  int a2;
  Struct16BytesMixed a3 = allocate<Struct16BytesMixed>().ref;
  int a4;
  Struct16BytesMixed a5 = allocate<Struct16BytesMixed>().ref;
  int a6;
  Struct16BytesMixed a7 = allocate<Struct16BytesMixed>().ref;
  int a8;

  a0 = -1;
  a1.a0 = 2.0;
  a1.a1 = -3;
  a2 = 4;
  a3.a0 = -5.0;
  a3.a1 = 6;
  a4 = -7;
  a5.a0 = 8.0;
  a5.a1 = -9;
  a6 = 10;
  a7.a0 = -11.0;
  a7.a1 = 12;
  a8 = -13;

  final result = passInt8Struct16BytesMixedInt8Struct16BytesMixedIn(
      a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.approxEquals(-7.0, result);

  free(a1.addressOf);
  free(a3.addressOf);
  free(a5.addressOf);
  free(a7.addressOf);
}

final passDoublex6Struct16BytesMixedx4Int32 = ffiTestFunctions.lookupFunction<
    Double Function(
        Double,
        Double,
        Double,
        Double,
        Double,
        Double,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Int32),
    double Function(
        double,
        double,
        double,
        double,
        double,
        double,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        int)>("PassDoublex6Struct16BytesMixedx4Int32");

/// On Linux x64, it will exhaust xmm registers first, after 6 doubles and 2
/// structs. The rest of the structs will go on the stack.
/// The int will be backfilled into the int register.
void testPassDoublex6Struct16BytesMixedx4Int32() {
  double a0;
  double a1;
  double a2;
  double a3;
  double a4;
  double a5;
  Struct16BytesMixed a6 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a7 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a8 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a9 = allocate<Struct16BytesMixed>().ref;
  int a10;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;
  a4 = -5.0;
  a5 = 6.0;
  a6.a0 = -7.0;
  a6.a1 = 8;
  a7.a0 = -9.0;
  a7.a1 = 10;
  a8.a0 = -11.0;
  a8.a1 = 12;
  a9.a0 = -13.0;
  a9.a1 = 14;
  a10 = -15;

  final result = passDoublex6Struct16BytesMixedx4Int32(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);

  print("result = $result");

  Expect.approxEquals(-8.0, result);

  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passInt32x4Struct16BytesMixedx4Double = ffiTestFunctions.lookupFunction<
    Double Function(Int32, Int32, Int32, Int32, Struct16BytesMixed,
        Struct16BytesMixed, Struct16BytesMixed, Struct16BytesMixed, Double),
    double Function(
        int,
        int,
        int,
        int,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        Struct16BytesMixed,
        double)>("PassInt32x4Struct16BytesMixedx4Double");

/// On Linux x64, it will exhaust int registers first.
/// The rest of the structs will go on the stack.
/// The double will be backfilled into the xmm register.
void testPassInt32x4Struct16BytesMixedx4Double() {
  int a0;
  int a1;
  int a2;
  int a3;
  Struct16BytesMixed a4 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a5 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a6 = allocate<Struct16BytesMixed>().ref;
  Struct16BytesMixed a7 = allocate<Struct16BytesMixed>().ref;
  double a8;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4.a0 = -5.0;
  a4.a1 = 6;
  a5.a0 = -7.0;
  a5.a1 = 8;
  a6.a0 = -9.0;
  a6.a1 = 10;
  a7.a0 = -11.0;
  a7.a1 = 12;
  a8 = -13.0;

  final result =
      passInt32x4Struct16BytesMixedx4Double(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.approxEquals(-7.0, result);

  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
}

final passStruct40BytesHomogeneousDoubleStruct4BytesHomo =
    ffiTestFunctions.lookupFunction<
            Double Function(Struct40BytesHomogeneousDouble,
                Struct4BytesHomogeneousInt16, Struct8BytesHomogeneousFloat),
            double Function(Struct40BytesHomogeneousDouble,
                Struct4BytesHomogeneousInt16, Struct8BytesHomogeneousFloat)>(
        "PassStruct40BytesHomogeneousDoubleStruct4BytesHomo");

/// On various architectures, first struct is allocated on stack.
/// Check that the other two arguments are allocated on registers.
void testPassStruct40BytesHomogeneousDoubleStruct4BytesHomo() {
  Struct40BytesHomogeneousDouble a0 =
      allocate<Struct40BytesHomogeneousDouble>().ref;
  Struct4BytesHomogeneousInt16 a1 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct8BytesHomogeneousFloat a2 =
      allocate<Struct8BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;
  a1.a0 = 6;
  a1.a1 = -7;
  a2.a0 = 8.0;
  a2.a1 = -9.0;

  final result = passStruct40BytesHomogeneousDoubleStruct4BytesHomo(a0, a1, a2);

  print("result = $result");

  Expect.approxEquals(-5.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
}

final passInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int =
    ffiTestFunctions.lookupFunction<
        Double Function(
            Int32,
            Int32,
            Int32,
            Int32,
            Int32,
            Int32,
            Int32,
            Int32,
            Double,
            Double,
            Double,
            Double,
            Double,
            Double,
            Double,
            Double,
            Int64,
            Int8,
            Struct1ByteInt,
            Int64,
            Int8,
            Struct4BytesHomogeneousInt16,
            Int64,
            Int8,
            Struct8BytesInt,
            Int64,
            Int8,
            Struct8BytesHomogeneousFloat,
            Int64,
            Int8,
            Struct8BytesMixed,
            Int64,
            Int8,
            StructAlignmentInt16,
            Int64,
            Int8,
            StructAlignmentInt32,
            Int64,
            Int8,
            StructAlignmentInt64),
        double Function(
            int,
            int,
            int,
            int,
            int,
            int,
            int,
            int,
            double,
            double,
            double,
            double,
            double,
            double,
            double,
            double,
            int,
            int,
            Struct1ByteInt,
            int,
            int,
            Struct4BytesHomogeneousInt16,
            int,
            int,
            Struct8BytesInt,
            int,
            int,
            Struct8BytesHomogeneousFloat,
            int,
            int,
            Struct8BytesMixed,
            int,
            int,
            StructAlignmentInt16,
            int,
            int,
            StructAlignmentInt32,
            int,
            int,
            StructAlignmentInt64)>("PassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int");

/// Test alignment and padding of 16 byte int within struct.
void testPassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  double a8;
  double a9;
  double a10;
  double a11;
  double a12;
  double a13;
  double a14;
  double a15;
  int a16;
  int a17;
  Struct1ByteInt a18 = allocate<Struct1ByteInt>().ref;
  int a19;
  int a20;
  Struct4BytesHomogeneousInt16 a21 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  int a22;
  int a23;
  Struct8BytesInt a24 = allocate<Struct8BytesInt>().ref;
  int a25;
  int a26;
  Struct8BytesHomogeneousFloat a27 =
      allocate<Struct8BytesHomogeneousFloat>().ref;
  int a28;
  int a29;
  Struct8BytesMixed a30 = allocate<Struct8BytesMixed>().ref;
  int a31;
  int a32;
  StructAlignmentInt16 a33 = allocate<StructAlignmentInt16>().ref;
  int a34;
  int a35;
  StructAlignmentInt32 a36 = allocate<StructAlignmentInt32>().ref;
  int a37;
  int a38;
  StructAlignmentInt64 a39 = allocate<StructAlignmentInt64>().ref;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;
  a5 = 6;
  a6 = -7;
  a7 = 8;
  a8 = -9.0;
  a9 = 10.0;
  a10 = -11.0;
  a11 = 12.0;
  a12 = -13.0;
  a13 = 14.0;
  a14 = -15.0;
  a15 = 16.0;
  a16 = -17;
  a17 = 18;
  a18.a0 = -19;
  a19 = 20;
  a20 = -21;
  a21.a0 = 22;
  a21.a1 = -23;
  a22 = 24;
  a23 = -25;
  a24.a0 = 26;
  a24.a1 = -27;
  a24.a2 = 28;
  a25 = -29;
  a26 = 30;
  a27.a0 = -31.0;
  a27.a1 = 32.0;
  a28 = -33;
  a29 = 34;
  a30.a0 = -35.0;
  a30.a1 = 36;
  a30.a2 = -37;
  a31 = 38;
  a32 = -39;
  a33.a0 = 40;
  a33.a1 = -41;
  a33.a2 = 42;
  a34 = -43;
  a35 = 44;
  a36.a0 = -45;
  a36.a1 = 46;
  a36.a2 = -47;
  a37 = 48;
  a38 = -49;
  a39.a0 = 50;
  a39.a1 = -51;
  a39.a2 = 52;

  final result = passInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int(
      a0,
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18,
      a19,
      a20,
      a21,
      a22,
      a23,
      a24,
      a25,
      a26,
      a27,
      a28,
      a29,
      a30,
      a31,
      a32,
      a33,
      a34,
      a35,
      a36,
      a37,
      a38,
      a39);

  print("result = $result");

  Expect.approxEquals(26.0, result);

  free(a18.addressOf);
  free(a21.addressOf);
  free(a24.addressOf);
  free(a27.addressOf);
  free(a30.addressOf);
  free(a33.addressOf);
  free(a36.addressOf);
  free(a39.addressOf);
}

final passStructAlignmentInt16 = ffiTestFunctions.lookupFunction<
    Int64 Function(StructAlignmentInt16),
    int Function(StructAlignmentInt16)>("PassStructAlignmentInt16");

/// Test alignment and padding of 16 byte int within struct.
void testPassStructAlignmentInt16() {
  StructAlignmentInt16 a0 = allocate<StructAlignmentInt16>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  final result = passStructAlignmentInt16(a0);

  print("result = $result");

  Expect.equals(-2, result);

  free(a0.addressOf);
}

final passStructAlignmentInt32 = ffiTestFunctions.lookupFunction<
    Int64 Function(StructAlignmentInt32),
    int Function(StructAlignmentInt32)>("PassStructAlignmentInt32");

/// Test alignment and padding of 32 byte int within struct.
void testPassStructAlignmentInt32() {
  StructAlignmentInt32 a0 = allocate<StructAlignmentInt32>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  final result = passStructAlignmentInt32(a0);

  print("result = $result");

  Expect.equals(-2, result);

  free(a0.addressOf);
}

final passStructAlignmentInt64 = ffiTestFunctions.lookupFunction<
    Int64 Function(StructAlignmentInt64),
    int Function(StructAlignmentInt64)>("PassStructAlignmentInt64");

/// Test alignment and padding of 64 byte int within struct.
void testPassStructAlignmentInt64() {
  StructAlignmentInt64 a0 = allocate<StructAlignmentInt64>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  final result = passStructAlignmentInt64(a0);

  print("result = $result");

  Expect.equals(-2, result);

  free(a0.addressOf);
}

final passStruct8BytesNestedIntx10 = ffiTestFunctions.lookupFunction<
    Int64 Function(
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt),
    int Function(
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt,
        Struct8BytesNestedInt)>("PassStruct8BytesNestedIntx10");

/// Simple nested struct. No alignment gaps on any architectures.
/// 10 arguments exhaust registers on all platforms.
void testPassStruct8BytesNestedIntx10() {
  Struct8BytesNestedInt a0 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a1 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a2 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a3 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a4 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a5 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a6 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a7 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a8 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a9 = allocate<Struct8BytesNestedInt>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a1.a0 = -3;
  a0.a1.a1 = 4;
  a1.a0.a0 = -5;
  a1.a0.a1 = 6;
  a1.a1.a0 = -7;
  a1.a1.a1 = 8;
  a2.a0.a0 = -9;
  a2.a0.a1 = 10;
  a2.a1.a0 = -11;
  a2.a1.a1 = 12;
  a3.a0.a0 = -13;
  a3.a0.a1 = 14;
  a3.a1.a0 = -15;
  a3.a1.a1 = 16;
  a4.a0.a0 = -17;
  a4.a0.a1 = 18;
  a4.a1.a0 = -19;
  a4.a1.a1 = 20;
  a5.a0.a0 = -21;
  a5.a0.a1 = 22;
  a5.a1.a0 = -23;
  a5.a1.a1 = 24;
  a6.a0.a0 = -25;
  a6.a0.a1 = 26;
  a6.a1.a0 = -27;
  a6.a1.a1 = 28;
  a7.a0.a0 = -29;
  a7.a0.a1 = 30;
  a7.a1.a0 = -31;
  a7.a1.a1 = 32;
  a8.a0.a0 = -33;
  a8.a0.a1 = 34;
  a8.a1.a0 = -35;
  a8.a1.a1 = 36;
  a9.a0.a0 = -37;
  a9.a0.a1 = 38;
  a9.a1.a0 = -39;
  a9.a1.a1 = 40;

  final result =
      passStruct8BytesNestedIntx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.equals(20, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesNestedFloatx10 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat),
    double Function(
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat,
        Struct8BytesNestedFloat)>("PassStruct8BytesNestedFloatx10");

/// Simple nested struct. No alignment gaps on any architectures.
/// 10 arguments exhaust fpu registers on all platforms.
void testPassStruct8BytesNestedFloatx10() {
  Struct8BytesNestedFloat a0 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a1 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a2 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a3 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a4 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a5 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a6 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a7 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a8 = allocate<Struct8BytesNestedFloat>().ref;
  Struct8BytesNestedFloat a9 = allocate<Struct8BytesNestedFloat>().ref;

  a0.a0.a0 = -1.0;
  a0.a1.a0 = 2.0;
  a1.a0.a0 = -3.0;
  a1.a1.a0 = 4.0;
  a2.a0.a0 = -5.0;
  a2.a1.a0 = 6.0;
  a3.a0.a0 = -7.0;
  a3.a1.a0 = 8.0;
  a4.a0.a0 = -9.0;
  a4.a1.a0 = 10.0;
  a5.a0.a0 = -11.0;
  a5.a1.a0 = 12.0;
  a6.a0.a0 = -13.0;
  a6.a1.a0 = 14.0;
  a7.a0.a0 = -15.0;
  a7.a1.a0 = 16.0;
  a8.a0.a0 = -17.0;
  a8.a1.a0 = 18.0;
  a9.a0.a0 = -19.0;
  a9.a1.a0 = 20.0;

  final result =
      passStruct8BytesNestedFloatx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesNestedFloat2x10 = ffiTestFunctions.lookupFunction<
    Float Function(
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2),
    double Function(
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2,
        Struct8BytesNestedFloat2)>("PassStruct8BytesNestedFloat2x10");

/// Simple nested struct. No alignment gaps on any architectures.
/// 10 arguments exhaust fpu registers on all platforms.
/// The nesting is irregular, testing homogenous float rules on arm and arm64,
/// and the fpu register usage on x64.
void testPassStruct8BytesNestedFloat2x10() {
  Struct8BytesNestedFloat2 a0 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a1 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a2 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a3 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a4 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a5 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a6 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a7 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a8 = allocate<Struct8BytesNestedFloat2>().ref;
  Struct8BytesNestedFloat2 a9 = allocate<Struct8BytesNestedFloat2>().ref;

  a0.a0.a0 = -1.0;
  a0.a1 = 2.0;
  a1.a0.a0 = -3.0;
  a1.a1 = 4.0;
  a2.a0.a0 = -5.0;
  a2.a1 = 6.0;
  a3.a0.a0 = -7.0;
  a3.a1 = 8.0;
  a4.a0.a0 = -9.0;
  a4.a1 = 10.0;
  a5.a0.a0 = -11.0;
  a5.a1 = 12.0;
  a6.a0.a0 = -13.0;
  a6.a1 = 14.0;
  a7.a0.a0 = -15.0;
  a7.a1 = 16.0;
  a8.a0.a0 = -17.0;
  a8.a1 = 18.0;
  a9.a0.a0 = -19.0;
  a9.a1 = 20.0;

  final result =
      passStruct8BytesNestedFloat2x10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(10.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct8BytesNestedMixedx10 = ffiTestFunctions.lookupFunction<
    Double Function(
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed),
    double Function(
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed,
        Struct8BytesNestedMixed)>("PassStruct8BytesNestedMixedx10");

/// Simple nested struct. No alignment gaps on any architectures.
/// 10 arguments exhaust all registers on all platforms.
void testPassStruct8BytesNestedMixedx10() {
  Struct8BytesNestedMixed a0 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a1 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a2 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a3 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a4 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a5 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a6 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a7 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a8 = allocate<Struct8BytesNestedMixed>().ref;
  Struct8BytesNestedMixed a9 = allocate<Struct8BytesNestedMixed>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a1.a0 = -3.0;
  a1.a0.a0 = 4;
  a1.a0.a1 = -5;
  a1.a1.a0 = 6.0;
  a2.a0.a0 = -7;
  a2.a0.a1 = 8;
  a2.a1.a0 = -9.0;
  a3.a0.a0 = 10;
  a3.a0.a1 = -11;
  a3.a1.a0 = 12.0;
  a4.a0.a0 = -13;
  a4.a0.a1 = 14;
  a4.a1.a0 = -15.0;
  a5.a0.a0 = 16;
  a5.a0.a1 = -17;
  a5.a1.a0 = 18.0;
  a6.a0.a0 = -19;
  a6.a0.a1 = 20;
  a6.a1.a0 = -21.0;
  a7.a0.a0 = 22;
  a7.a0.a1 = -23;
  a7.a1.a0 = 24.0;
  a8.a0.a0 = -25;
  a8.a0.a1 = 26;
  a8.a1.a0 = -27.0;
  a9.a0.a0 = 28;
  a9.a0.a1 = -29;
  a9.a1.a0 = 30.0;

  final result =
      passStruct8BytesNestedMixedx10(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  print("result = $result");

  Expect.approxEquals(15.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
  free(a4.addressOf);
  free(a5.addressOf);
  free(a6.addressOf);
  free(a7.addressOf);
  free(a8.addressOf);
  free(a9.addressOf);
}

final passStruct16BytesNestedIntx2 = ffiTestFunctions.lookupFunction<
    Int64 Function(Struct16BytesNestedInt, Struct16BytesNestedInt),
    int Function(Struct16BytesNestedInt,
        Struct16BytesNestedInt)>("PassStruct16BytesNestedIntx2");

/// Deeper nested struct to test recursive member access.
void testPassStruct16BytesNestedIntx2() {
  Struct16BytesNestedInt a0 = allocate<Struct16BytesNestedInt>().ref;
  Struct16BytesNestedInt a1 = allocate<Struct16BytesNestedInt>().ref;

  a0.a0.a0.a0 = -1;
  a0.a0.a0.a1 = 2;
  a0.a0.a1.a0 = -3;
  a0.a0.a1.a1 = 4;
  a0.a1.a0.a0 = -5;
  a0.a1.a0.a1 = 6;
  a0.a1.a1.a0 = -7;
  a0.a1.a1.a1 = 8;
  a1.a0.a0.a0 = -9;
  a1.a0.a0.a1 = 10;
  a1.a0.a1.a0 = -11;
  a1.a0.a1.a1 = 12;
  a1.a1.a0.a0 = -13;
  a1.a1.a0.a1 = 14;
  a1.a1.a1.a0 = -15;
  a1.a1.a1.a1 = 16;

  final result = passStruct16BytesNestedIntx2(a0, a1);

  print("result = $result");

  Expect.equals(8, result);

  free(a0.addressOf);
  free(a1.addressOf);
}

final passStruct32BytesNestedIntx2 = ffiTestFunctions.lookupFunction<
    Int64 Function(Struct32BytesNestedInt, Struct32BytesNestedInt),
    int Function(Struct32BytesNestedInt,
        Struct32BytesNestedInt)>("PassStruct32BytesNestedIntx2");

/// Even deeper nested struct to test recursive member access.
void testPassStruct32BytesNestedIntx2() {
  Struct32BytesNestedInt a0 = allocate<Struct32BytesNestedInt>().ref;
  Struct32BytesNestedInt a1 = allocate<Struct32BytesNestedInt>().ref;

  a0.a0.a0.a0.a0 = -1;
  a0.a0.a0.a0.a1 = 2;
  a0.a0.a0.a1.a0 = -3;
  a0.a0.a0.a1.a1 = 4;
  a0.a0.a1.a0.a0 = -5;
  a0.a0.a1.a0.a1 = 6;
  a0.a0.a1.a1.a0 = -7;
  a0.a0.a1.a1.a1 = 8;
  a0.a1.a0.a0.a0 = -9;
  a0.a1.a0.a0.a1 = 10;
  a0.a1.a0.a1.a0 = -11;
  a0.a1.a0.a1.a1 = 12;
  a0.a1.a1.a0.a0 = -13;
  a0.a1.a1.a0.a1 = 14;
  a0.a1.a1.a1.a0 = -15;
  a0.a1.a1.a1.a1 = 16;
  a1.a0.a0.a0.a0 = -17;
  a1.a0.a0.a0.a1 = 18;
  a1.a0.a0.a1.a0 = -19;
  a1.a0.a0.a1.a1 = 20;
  a1.a0.a1.a0.a0 = -21;
  a1.a0.a1.a0.a1 = 22;
  a1.a0.a1.a1.a0 = -23;
  a1.a0.a1.a1.a1 = 24;
  a1.a1.a0.a0.a0 = -25;
  a1.a1.a0.a0.a1 = 26;
  a1.a1.a0.a1.a0 = -27;
  a1.a1.a0.a1.a1 = 28;
  a1.a1.a1.a0.a0 = -29;
  a1.a1.a1.a0.a1 = 30;
  a1.a1.a1.a1.a0 = -31;
  a1.a1.a1.a1.a1 = 32;

  final result = passStruct32BytesNestedIntx2(a0, a1);

  print("result = $result");

  Expect.equals(16, result);

  free(a0.addressOf);
  free(a1.addressOf);
}

final passStructNestedIntStructAlignmentInt16 = ffiTestFunctions.lookupFunction<
        Int64 Function(StructNestedIntStructAlignmentInt16),
        int Function(StructNestedIntStructAlignmentInt16)>(
    "PassStructNestedIntStructAlignmentInt16");

/// Test alignment and padding of nested struct with 16 byte int.
void testPassStructNestedIntStructAlignmentInt16() {
  StructNestedIntStructAlignmentInt16 a0 =
      allocate<StructNestedIntStructAlignmentInt16>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  final result = passStructNestedIntStructAlignmentInt16(a0);

  print("result = $result");

  Expect.equals(3, result);

  free(a0.addressOf);
}

final passStructNestedIntStructAlignmentInt32 = ffiTestFunctions.lookupFunction<
        Int64 Function(StructNestedIntStructAlignmentInt32),
        int Function(StructNestedIntStructAlignmentInt32)>(
    "PassStructNestedIntStructAlignmentInt32");

/// Test alignment and padding of nested struct with 32 byte int.
void testPassStructNestedIntStructAlignmentInt32() {
  StructNestedIntStructAlignmentInt32 a0 =
      allocate<StructNestedIntStructAlignmentInt32>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  final result = passStructNestedIntStructAlignmentInt32(a0);

  print("result = $result");

  Expect.equals(3, result);

  free(a0.addressOf);
}

final passStructNestedIntStructAlignmentInt64 = ffiTestFunctions.lookupFunction<
        Int64 Function(StructNestedIntStructAlignmentInt64),
        int Function(StructNestedIntStructAlignmentInt64)>(
    "PassStructNestedIntStructAlignmentInt64");

/// Test alignment and padding of nested struct with 64 byte int.
void testPassStructNestedIntStructAlignmentInt64() {
  StructNestedIntStructAlignmentInt64 a0 =
      allocate<StructNestedIntStructAlignmentInt64>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  final result = passStructNestedIntStructAlignmentInt64(a0);

  print("result = $result");

  Expect.equals(3, result);

  free(a0.addressOf);
}

final passStructNestedIrregularEvenBiggerx4 = ffiTestFunctions.lookupFunction<
        Double Function(
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger),
        double Function(
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger,
            StructNestedIrregularEvenBigger)>(
    "PassStructNestedIrregularEvenBiggerx4");

/// Return big irregular struct as smoke test.
void testPassStructNestedIrregularEvenBiggerx4() {
  StructNestedIrregularEvenBigger a0 =
      allocate<StructNestedIrregularEvenBigger>().ref;
  StructNestedIrregularEvenBigger a1 =
      allocate<StructNestedIrregularEvenBigger>().ref;
  StructNestedIrregularEvenBigger a2 =
      allocate<StructNestedIrregularEvenBigger>().ref;
  StructNestedIrregularEvenBigger a3 =
      allocate<StructNestedIrregularEvenBigger>().ref;

  a0.a0 = 1;
  a0.a1.a0.a0 = 2;
  a0.a1.a0.a1.a0.a0 = -3;
  a0.a1.a0.a1.a0.a1 = 4;
  a0.a1.a0.a1.a1.a0 = -5.0;
  a0.a1.a0.a2 = 6;
  a0.a1.a0.a3.a0.a0 = -7.0;
  a0.a1.a0.a3.a1 = 8.0;
  a0.a1.a0.a4 = 9;
  a0.a1.a0.a5.a0.a0 = 10.0;
  a0.a1.a0.a5.a1.a0 = -11.0;
  a0.a1.a0.a6 = 12;
  a0.a1.a1.a0.a0 = -13;
  a0.a1.a1.a0.a1 = 14;
  a0.a1.a1.a1.a0 = -15.0;
  a0.a1.a2 = 16.0;
  a0.a1.a3 = -17.0;
  a0.a2.a0.a0 = 18;
  a0.a2.a0.a1.a0.a0 = -19;
  a0.a2.a0.a1.a0.a1 = 20;
  a0.a2.a0.a1.a1.a0 = -21.0;
  a0.a2.a0.a2 = 22;
  a0.a2.a0.a3.a0.a0 = -23.0;
  a0.a2.a0.a3.a1 = 24.0;
  a0.a2.a0.a4 = 25;
  a0.a2.a0.a5.a0.a0 = 26.0;
  a0.a2.a0.a5.a1.a0 = -27.0;
  a0.a2.a0.a6 = 28;
  a0.a2.a1.a0.a0 = -29;
  a0.a2.a1.a0.a1 = 30;
  a0.a2.a1.a1.a0 = -31.0;
  a0.a2.a2 = 32.0;
  a0.a2.a3 = -33.0;
  a0.a3 = 34.0;
  a1.a0 = 35;
  a1.a1.a0.a0 = 36;
  a1.a1.a0.a1.a0.a0 = -37;
  a1.a1.a0.a1.a0.a1 = 38;
  a1.a1.a0.a1.a1.a0 = -39.0;
  a1.a1.a0.a2 = 40;
  a1.a1.a0.a3.a0.a0 = -41.0;
  a1.a1.a0.a3.a1 = 42.0;
  a1.a1.a0.a4 = 43;
  a1.a1.a0.a5.a0.a0 = 44.0;
  a1.a1.a0.a5.a1.a0 = -45.0;
  a1.a1.a0.a6 = 46;
  a1.a1.a1.a0.a0 = -47;
  a1.a1.a1.a0.a1 = 48;
  a1.a1.a1.a1.a0 = -49.0;
  a1.a1.a2 = 50.0;
  a1.a1.a3 = -51.0;
  a1.a2.a0.a0 = 52;
  a1.a2.a0.a1.a0.a0 = -53;
  a1.a2.a0.a1.a0.a1 = 54;
  a1.a2.a0.a1.a1.a0 = -55.0;
  a1.a2.a0.a2 = 56;
  a1.a2.a0.a3.a0.a0 = -57.0;
  a1.a2.a0.a3.a1 = 58.0;
  a1.a2.a0.a4 = 59;
  a1.a2.a0.a5.a0.a0 = 60.0;
  a1.a2.a0.a5.a1.a0 = -61.0;
  a1.a2.a0.a6 = 62;
  a1.a2.a1.a0.a0 = -63;
  a1.a2.a1.a0.a1 = 64;
  a1.a2.a1.a1.a0 = -65.0;
  a1.a2.a2 = 66.0;
  a1.a2.a3 = -67.0;
  a1.a3 = 68.0;
  a2.a0 = 69;
  a2.a1.a0.a0 = 70;
  a2.a1.a0.a1.a0.a0 = -71;
  a2.a1.a0.a1.a0.a1 = 72;
  a2.a1.a0.a1.a1.a0 = -73.0;
  a2.a1.a0.a2 = 74;
  a2.a1.a0.a3.a0.a0 = -75.0;
  a2.a1.a0.a3.a1 = 76.0;
  a2.a1.a0.a4 = 77;
  a2.a1.a0.a5.a0.a0 = 78.0;
  a2.a1.a0.a5.a1.a0 = -79.0;
  a2.a1.a0.a6 = 80;
  a2.a1.a1.a0.a0 = -81;
  a2.a1.a1.a0.a1 = 82;
  a2.a1.a1.a1.a0 = -83.0;
  a2.a1.a2 = 84.0;
  a2.a1.a3 = -85.0;
  a2.a2.a0.a0 = 86;
  a2.a2.a0.a1.a0.a0 = -87;
  a2.a2.a0.a1.a0.a1 = 88;
  a2.a2.a0.a1.a1.a0 = -89.0;
  a2.a2.a0.a2 = 90;
  a2.a2.a0.a3.a0.a0 = -91.0;
  a2.a2.a0.a3.a1 = 92.0;
  a2.a2.a0.a4 = 93;
  a2.a2.a0.a5.a0.a0 = 94.0;
  a2.a2.a0.a5.a1.a0 = -95.0;
  a2.a2.a0.a6 = 96;
  a2.a2.a1.a0.a0 = -97;
  a2.a2.a1.a0.a1 = 98;
  a2.a2.a1.a1.a0 = -99.0;
  a2.a2.a2 = 100.0;
  a2.a2.a3 = -101.0;
  a2.a3 = 102.0;
  a3.a0 = 103;
  a3.a1.a0.a0 = 104;
  a3.a1.a0.a1.a0.a0 = -105;
  a3.a1.a0.a1.a0.a1 = 106;
  a3.a1.a0.a1.a1.a0 = -107.0;
  a3.a1.a0.a2 = 108;
  a3.a1.a0.a3.a0.a0 = -109.0;
  a3.a1.a0.a3.a1 = 110.0;
  a3.a1.a0.a4 = 111;
  a3.a1.a0.a5.a0.a0 = 112.0;
  a3.a1.a0.a5.a1.a0 = -113.0;
  a3.a1.a0.a6 = 114;
  a3.a1.a1.a0.a0 = -115;
  a3.a1.a1.a0.a1 = 116;
  a3.a1.a1.a1.a0 = -117.0;
  a3.a1.a2 = 118.0;
  a3.a1.a3 = -119.0;
  a3.a2.a0.a0 = 120;
  a3.a2.a0.a1.a0.a0 = -121;
  a3.a2.a0.a1.a0.a1 = 122;
  a3.a2.a0.a1.a1.a0 = -123.0;
  a3.a2.a0.a2 = 124;
  a3.a2.a0.a3.a0.a0 = -125.0;
  a3.a2.a0.a3.a1 = 126.0;
  a3.a2.a0.a4 = 127;
  a3.a2.a0.a5.a0.a0 = 128.0;
  a3.a2.a0.a5.a1.a0 = -129.0;
  a3.a2.a0.a6 = 130;
  a3.a2.a1.a0.a0 = -131;
  a3.a2.a1.a0.a1 = 132;
  a3.a2.a1.a1.a0 = -133.0;
  a3.a2.a2 = 134.0;
  a3.a2.a3 = -135.0;
  a3.a3 = 136.0;

  final result = passStructNestedIrregularEvenBiggerx4(a0, a1, a2, a3);

  print("result = $result");

  Expect.approxEquals(1572.0, result);

  free(a0.addressOf);
  free(a1.addressOf);
  free(a2.addressOf);
  free(a3.addressOf);
}

final returnStruct1ByteInt = ffiTestFunctions.lookupFunction<
    Struct1ByteInt Function(Int8),
    Struct1ByteInt Function(int)>("ReturnStruct1ByteInt");

/// Smallest struct with data.
void testReturnStruct1ByteInt() {
  int a0;

  a0 = -1;

  final result = returnStruct1ByteInt(a0);

  print("result = $result");

  Expect.equals(a0, result.a0);
}

final returnStruct3BytesHomogeneousUint8 = ffiTestFunctions.lookupFunction<
    Struct3BytesHomogeneousUint8 Function(Uint8, Uint8, Uint8),
    Struct3BytesHomogeneousUint8 Function(
        int, int, int)>("ReturnStruct3BytesHomogeneousUint8");

/// Smaller than word size return value on all architectures.
void testReturnStruct3BytesHomogeneousUint8() {
  int a0;
  int a1;
  int a2;

  a0 = 1;
  a1 = 2;
  a2 = 3;

  final result = returnStruct3BytesHomogeneousUint8(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct3BytesInt2ByteAligned = ffiTestFunctions.lookupFunction<
    Struct3BytesInt2ByteAligned Function(Int16, Int8),
    Struct3BytesInt2ByteAligned Function(
        int, int)>("ReturnStruct3BytesInt2ByteAligned");

/// Smaller than word size return value on all architectures.
/// With alignment rules taken into account size is 4 bytes.
void testReturnStruct3BytesInt2ByteAligned() {
  int a0;
  int a1;

  a0 = -1;
  a1 = 2;

  final result = returnStruct3BytesInt2ByteAligned(a0, a1);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
}

final returnStruct4BytesHomogeneousInt16 = ffiTestFunctions.lookupFunction<
    Struct4BytesHomogeneousInt16 Function(Int16, Int16),
    Struct4BytesHomogeneousInt16 Function(
        int, int)>("ReturnStruct4BytesHomogeneousInt16");

/// Word size return value on 32 bit architectures..
void testReturnStruct4BytesHomogeneousInt16() {
  int a0;
  int a1;

  a0 = -1;
  a1 = 2;

  final result = returnStruct4BytesHomogeneousInt16(a0, a1);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
}

final returnStruct7BytesHomogeneousUint8 = ffiTestFunctions.lookupFunction<
    Struct7BytesHomogeneousUint8 Function(
        Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8),
    Struct7BytesHomogeneousUint8 Function(int, int, int, int, int, int,
        int)>("ReturnStruct7BytesHomogeneousUint8");

/// Non-wordsize return value.
void testReturnStruct7BytesHomogeneousUint8() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;

  final result = returnStruct7BytesHomogeneousUint8(a0, a1, a2, a3, a4, a5, a6);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
  Expect.equals(a3, result.a3);
  Expect.equals(a4, result.a4);
  Expect.equals(a5, result.a5);
  Expect.equals(a6, result.a6);
}

final returnStruct7BytesInt4ByteAligned = ffiTestFunctions.lookupFunction<
    Struct7BytesInt4ByteAligned Function(Int32, Int16, Int8),
    Struct7BytesInt4ByteAligned Function(
        int, int, int)>("ReturnStruct7BytesInt4ByteAligned");

/// Non-wordsize return value.
/// With alignment rules taken into account size is 8 bytes.
void testReturnStruct7BytesInt4ByteAligned() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStruct7BytesInt4ByteAligned(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct8BytesInt = ffiTestFunctions.lookupFunction<
    Struct8BytesInt Function(Int16, Int16, Int32),
    Struct8BytesInt Function(int, int, int)>("ReturnStruct8BytesInt");

/// Return value in integer registers on many architectures.
void testReturnStruct8BytesInt() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStruct8BytesInt(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct8BytesHomogeneousFloat = ffiTestFunctions.lookupFunction<
    Struct8BytesHomogeneousFloat Function(Float, Float),
    Struct8BytesHomogeneousFloat Function(
        double, double)>("ReturnStruct8BytesHomogeneousFloat");

/// Return value in FP registers on many architectures.
void testReturnStruct8BytesHomogeneousFloat() {
  double a0;
  double a1;

  a0 = -1.0;
  a1 = 2.0;

  final result = returnStruct8BytesHomogeneousFloat(a0, a1);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
}

final returnStruct8BytesMixed = ffiTestFunctions.lookupFunction<
    Struct8BytesMixed Function(Float, Int16, Int16),
    Struct8BytesMixed Function(double, int, int)>("ReturnStruct8BytesMixed");

/// Return value split over FP and integer register in x64.
void testReturnStruct8BytesMixed() {
  double a0;
  int a1;
  int a2;

  a0 = -1.0;
  a1 = 2;
  a2 = -3;

  final result = returnStruct8BytesMixed(a0, a1, a2);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct9BytesHomogeneousUint8 = ffiTestFunctions.lookupFunction<
    Struct9BytesHomogeneousUint8 Function(
        Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8),
    Struct9BytesHomogeneousUint8 Function(int, int, int, int, int, int, int,
        int, int)>("ReturnStruct9BytesHomogeneousUint8");

/// The minimum alignment of this struct is only 1 byte based on its fields.
/// Test that the memory backing these structs is the right size and that
/// dart:ffi trampolines do not write outside this size.
void testReturnStruct9BytesHomogeneousUint8() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  int a8;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;
  a7 = 8;
  a8 = 9;

  final result =
      returnStruct9BytesHomogeneousUint8(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
  Expect.equals(a3, result.a3);
  Expect.equals(a4, result.a4);
  Expect.equals(a5, result.a5);
  Expect.equals(a6, result.a6);
  Expect.equals(a7, result.a7);
  Expect.equals(a8, result.a8);
}

final returnStruct9BytesInt4Or8ByteAligned = ffiTestFunctions.lookupFunction<
    Struct9BytesInt4Or8ByteAligned Function(Int64, Int8),
    Struct9BytesInt4Or8ByteAligned Function(
        int, int)>("ReturnStruct9BytesInt4Or8ByteAligned");

/// Return value in two integer registers on x64.
/// With alignment rules taken into account size is 12 or 16 bytes.
void testReturnStruct9BytesInt4Or8ByteAligned() {
  int a0;
  int a1;

  a0 = -1;
  a1 = 2;

  final result = returnStruct9BytesInt4Or8ByteAligned(a0, a1);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
}

final returnStruct12BytesHomogeneousFloat = ffiTestFunctions.lookupFunction<
    Struct12BytesHomogeneousFloat Function(Float, Float, Float),
    Struct12BytesHomogeneousFloat Function(
        double, double, double)>("ReturnStruct12BytesHomogeneousFloat");

/// Return value in FPU registers, but does not use all registers on arm hardfp
/// and arm64.
void testReturnStruct12BytesHomogeneousFloat() {
  double a0;
  double a1;
  double a2;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;

  final result = returnStruct12BytesHomogeneousFloat(a0, a1, a2);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
}

final returnStruct16BytesHomogeneousFloat = ffiTestFunctions.lookupFunction<
    Struct16BytesHomogeneousFloat Function(Float, Float, Float, Float),
    Struct16BytesHomogeneousFloat Function(
        double, double, double, double)>("ReturnStruct16BytesHomogeneousFloat");

/// Return value in FPU registers on arm hardfp and arm64.
void testReturnStruct16BytesHomogeneousFloat() {
  double a0;
  double a1;
  double a2;
  double a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;

  final result = returnStruct16BytesHomogeneousFloat(a0, a1, a2, a3);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
  Expect.approxEquals(a3, result.a3);
}

final returnStruct16BytesMixed = ffiTestFunctions.lookupFunction<
    Struct16BytesMixed Function(Double, Int64),
    Struct16BytesMixed Function(double, int)>("ReturnStruct16BytesMixed");

/// Return value split over FP and integer register in x64.
void testReturnStruct16BytesMixed() {
  double a0;
  int a1;

  a0 = -1.0;
  a1 = 2;

  final result = returnStruct16BytesMixed(a0, a1);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.equals(a1, result.a1);
}

final returnStruct16BytesMixed2 = ffiTestFunctions.lookupFunction<
    Struct16BytesMixed2 Function(Float, Float, Float, Int32),
    Struct16BytesMixed2 Function(
        double, double, double, int)>("ReturnStruct16BytesMixed2");

/// Return value split over FP and integer register in x64.
/// The integer register contains half float half int.
void testReturnStruct16BytesMixed2() {
  double a0;
  double a1;
  double a2;
  int a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4;

  final result = returnStruct16BytesMixed2(a0, a1, a2, a3);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
  Expect.equals(a3, result.a3);
}

final returnStruct17BytesInt = ffiTestFunctions.lookupFunction<
    Struct17BytesInt Function(Int64, Int64, Int8),
    Struct17BytesInt Function(int, int, int)>("ReturnStruct17BytesInt");

/// Rerturn value returned in preallocated space passed by pointer on most ABIs.
/// Is non word size on purpose, to test that structs are rounded up to word size
/// on all ABIs.
void testReturnStruct17BytesInt() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStruct17BytesInt(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct19BytesHomogeneousUint8 = ffiTestFunctions.lookupFunction<
    Struct19BytesHomogeneousUint8 Function(
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8,
        Uint8),
    Struct19BytesHomogeneousUint8 Function(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int)>("ReturnStruct19BytesHomogeneousUint8");

/// The minimum alignment of this struct is only 1 byte based on its fields.
/// Test that the memory backing these structs is the right size and that
/// dart:ffi trampolines do not write outside this size.
void testReturnStruct19BytesHomogeneousUint8() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  int a8;
  int a9;
  int a10;
  int a11;
  int a12;
  int a13;
  int a14;
  int a15;
  int a16;
  int a17;
  int a18;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;
  a7 = 8;
  a8 = 9;
  a9 = 10;
  a10 = 11;
  a11 = 12;
  a12 = 13;
  a13 = 14;
  a14 = 15;
  a15 = 16;
  a16 = 17;
  a17 = 18;
  a18 = 19;

  final result = returnStruct19BytesHomogeneousUint8(a0, a1, a2, a3, a4, a5, a6,
      a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
  Expect.equals(a3, result.a3);
  Expect.equals(a4, result.a4);
  Expect.equals(a5, result.a5);
  Expect.equals(a6, result.a6);
  Expect.equals(a7, result.a7);
  Expect.equals(a8, result.a8);
  Expect.equals(a9, result.a9);
  Expect.equals(a10, result.a10);
  Expect.equals(a11, result.a11);
  Expect.equals(a12, result.a12);
  Expect.equals(a13, result.a13);
  Expect.equals(a14, result.a14);
  Expect.equals(a15, result.a15);
  Expect.equals(a16, result.a16);
  Expect.equals(a17, result.a17);
  Expect.equals(a18, result.a18);
}

final returnStruct20BytesHomogeneousInt32 = ffiTestFunctions.lookupFunction<
    Struct20BytesHomogeneousInt32 Function(Int32, Int32, Int32, Int32, Int32),
    Struct20BytesHomogeneousInt32 Function(
        int, int, int, int, int)>("ReturnStruct20BytesHomogeneousInt32");

/// Return value too big to go in cpu registers on arm64.
void testReturnStruct20BytesHomogeneousInt32() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;

  final result = returnStruct20BytesHomogeneousInt32(a0, a1, a2, a3, a4);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
  Expect.equals(a3, result.a3);
  Expect.equals(a4, result.a4);
}

final returnStruct20BytesHomogeneousFloat = ffiTestFunctions.lookupFunction<
    Struct20BytesHomogeneousFloat Function(Float, Float, Float, Float, Float),
    Struct20BytesHomogeneousFloat Function(double, double, double, double,
        double)>("ReturnStruct20BytesHomogeneousFloat");

/// Return value too big to go in FPU registers on x64, arm hardfp and arm64.
void testReturnStruct20BytesHomogeneousFloat() {
  double a0;
  double a1;
  double a2;
  double a3;
  double a4;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;
  a4 = -5.0;

  final result = returnStruct20BytesHomogeneousFloat(a0, a1, a2, a3, a4);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
  Expect.approxEquals(a3, result.a3);
  Expect.approxEquals(a4, result.a4);
}

final returnStruct32BytesHomogeneousDouble = ffiTestFunctions.lookupFunction<
    Struct32BytesHomogeneousDouble Function(Double, Double, Double, Double),
    Struct32BytesHomogeneousDouble Function(double, double, double,
        double)>("ReturnStruct32BytesHomogeneousDouble");

/// Return value in FPU registers on arm64.
void testReturnStruct32BytesHomogeneousDouble() {
  double a0;
  double a1;
  double a2;
  double a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;

  final result = returnStruct32BytesHomogeneousDouble(a0, a1, a2, a3);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
  Expect.approxEquals(a3, result.a3);
}

final returnStruct40BytesHomogeneousDouble = ffiTestFunctions.lookupFunction<
    Struct40BytesHomogeneousDouble Function(
        Double, Double, Double, Double, Double),
    Struct40BytesHomogeneousDouble Function(double, double, double, double,
        double)>("ReturnStruct40BytesHomogeneousDouble");

/// Return value too big to go in FPU registers on arm64.
void testReturnStruct40BytesHomogeneousDouble() {
  double a0;
  double a1;
  double a2;
  double a3;
  double a4;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;
  a4 = -5.0;

  final result = returnStruct40BytesHomogeneousDouble(a0, a1, a2, a3, a4);

  print("result = $result");

  Expect.approxEquals(a0, result.a0);
  Expect.approxEquals(a1, result.a1);
  Expect.approxEquals(a2, result.a2);
  Expect.approxEquals(a3, result.a3);
  Expect.approxEquals(a4, result.a4);
}

final returnStruct1024BytesHomogeneousUint64 = ffiTestFunctions.lookupFunction<
    Struct1024BytesHomogeneousUint64 Function(
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64,
        Uint64),
    Struct1024BytesHomogeneousUint64 Function(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int)>("ReturnStruct1024BytesHomogeneousUint64");

/// Test 1kb struct.
void testReturnStruct1024BytesHomogeneousUint64() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  int a8;
  int a9;
  int a10;
  int a11;
  int a12;
  int a13;
  int a14;
  int a15;
  int a16;
  int a17;
  int a18;
  int a19;
  int a20;
  int a21;
  int a22;
  int a23;
  int a24;
  int a25;
  int a26;
  int a27;
  int a28;
  int a29;
  int a30;
  int a31;
  int a32;
  int a33;
  int a34;
  int a35;
  int a36;
  int a37;
  int a38;
  int a39;
  int a40;
  int a41;
  int a42;
  int a43;
  int a44;
  int a45;
  int a46;
  int a47;
  int a48;
  int a49;
  int a50;
  int a51;
  int a52;
  int a53;
  int a54;
  int a55;
  int a56;
  int a57;
  int a58;
  int a59;
  int a60;
  int a61;
  int a62;
  int a63;
  int a64;
  int a65;
  int a66;
  int a67;
  int a68;
  int a69;
  int a70;
  int a71;
  int a72;
  int a73;
  int a74;
  int a75;
  int a76;
  int a77;
  int a78;
  int a79;
  int a80;
  int a81;
  int a82;
  int a83;
  int a84;
  int a85;
  int a86;
  int a87;
  int a88;
  int a89;
  int a90;
  int a91;
  int a92;
  int a93;
  int a94;
  int a95;
  int a96;
  int a97;
  int a98;
  int a99;
  int a100;
  int a101;
  int a102;
  int a103;
  int a104;
  int a105;
  int a106;
  int a107;
  int a108;
  int a109;
  int a110;
  int a111;
  int a112;
  int a113;
  int a114;
  int a115;
  int a116;
  int a117;
  int a118;
  int a119;
  int a120;
  int a121;
  int a122;
  int a123;
  int a124;
  int a125;
  int a126;
  int a127;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;
  a7 = 8;
  a8 = 9;
  a9 = 10;
  a10 = 11;
  a11 = 12;
  a12 = 13;
  a13 = 14;
  a14 = 15;
  a15 = 16;
  a16 = 17;
  a17 = 18;
  a18 = 19;
  a19 = 20;
  a20 = 21;
  a21 = 22;
  a22 = 23;
  a23 = 24;
  a24 = 25;
  a25 = 26;
  a26 = 27;
  a27 = 28;
  a28 = 29;
  a29 = 30;
  a30 = 31;
  a31 = 32;
  a32 = 33;
  a33 = 34;
  a34 = 35;
  a35 = 36;
  a36 = 37;
  a37 = 38;
  a38 = 39;
  a39 = 40;
  a40 = 41;
  a41 = 42;
  a42 = 43;
  a43 = 44;
  a44 = 45;
  a45 = 46;
  a46 = 47;
  a47 = 48;
  a48 = 49;
  a49 = 50;
  a50 = 51;
  a51 = 52;
  a52 = 53;
  a53 = 54;
  a54 = 55;
  a55 = 56;
  a56 = 57;
  a57 = 58;
  a58 = 59;
  a59 = 60;
  a60 = 61;
  a61 = 62;
  a62 = 63;
  a63 = 64;
  a64 = 65;
  a65 = 66;
  a66 = 67;
  a67 = 68;
  a68 = 69;
  a69 = 70;
  a70 = 71;
  a71 = 72;
  a72 = 73;
  a73 = 74;
  a74 = 75;
  a75 = 76;
  a76 = 77;
  a77 = 78;
  a78 = 79;
  a79 = 80;
  a80 = 81;
  a81 = 82;
  a82 = 83;
  a83 = 84;
  a84 = 85;
  a85 = 86;
  a86 = 87;
  a87 = 88;
  a88 = 89;
  a89 = 90;
  a90 = 91;
  a91 = 92;
  a92 = 93;
  a93 = 94;
  a94 = 95;
  a95 = 96;
  a96 = 97;
  a97 = 98;
  a98 = 99;
  a99 = 100;
  a100 = 101;
  a101 = 102;
  a102 = 103;
  a103 = 104;
  a104 = 105;
  a105 = 106;
  a106 = 107;
  a107 = 108;
  a108 = 109;
  a109 = 110;
  a110 = 111;
  a111 = 112;
  a112 = 113;
  a113 = 114;
  a114 = 115;
  a115 = 116;
  a116 = 117;
  a117 = 118;
  a118 = 119;
  a119 = 120;
  a120 = 121;
  a121 = 122;
  a122 = 123;
  a123 = 124;
  a124 = 125;
  a125 = 126;
  a126 = 127;
  a127 = 128;

  final result = returnStruct1024BytesHomogeneousUint64(
      a0,
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18,
      a19,
      a20,
      a21,
      a22,
      a23,
      a24,
      a25,
      a26,
      a27,
      a28,
      a29,
      a30,
      a31,
      a32,
      a33,
      a34,
      a35,
      a36,
      a37,
      a38,
      a39,
      a40,
      a41,
      a42,
      a43,
      a44,
      a45,
      a46,
      a47,
      a48,
      a49,
      a50,
      a51,
      a52,
      a53,
      a54,
      a55,
      a56,
      a57,
      a58,
      a59,
      a60,
      a61,
      a62,
      a63,
      a64,
      a65,
      a66,
      a67,
      a68,
      a69,
      a70,
      a71,
      a72,
      a73,
      a74,
      a75,
      a76,
      a77,
      a78,
      a79,
      a80,
      a81,
      a82,
      a83,
      a84,
      a85,
      a86,
      a87,
      a88,
      a89,
      a90,
      a91,
      a92,
      a93,
      a94,
      a95,
      a96,
      a97,
      a98,
      a99,
      a100,
      a101,
      a102,
      a103,
      a104,
      a105,
      a106,
      a107,
      a108,
      a109,
      a110,
      a111,
      a112,
      a113,
      a114,
      a115,
      a116,
      a117,
      a118,
      a119,
      a120,
      a121,
      a122,
      a123,
      a124,
      a125,
      a126,
      a127);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
  Expect.equals(a3, result.a3);
  Expect.equals(a4, result.a4);
  Expect.equals(a5, result.a5);
  Expect.equals(a6, result.a6);
  Expect.equals(a7, result.a7);
  Expect.equals(a8, result.a8);
  Expect.equals(a9, result.a9);
  Expect.equals(a10, result.a10);
  Expect.equals(a11, result.a11);
  Expect.equals(a12, result.a12);
  Expect.equals(a13, result.a13);
  Expect.equals(a14, result.a14);
  Expect.equals(a15, result.a15);
  Expect.equals(a16, result.a16);
  Expect.equals(a17, result.a17);
  Expect.equals(a18, result.a18);
  Expect.equals(a19, result.a19);
  Expect.equals(a20, result.a20);
  Expect.equals(a21, result.a21);
  Expect.equals(a22, result.a22);
  Expect.equals(a23, result.a23);
  Expect.equals(a24, result.a24);
  Expect.equals(a25, result.a25);
  Expect.equals(a26, result.a26);
  Expect.equals(a27, result.a27);
  Expect.equals(a28, result.a28);
  Expect.equals(a29, result.a29);
  Expect.equals(a30, result.a30);
  Expect.equals(a31, result.a31);
  Expect.equals(a32, result.a32);
  Expect.equals(a33, result.a33);
  Expect.equals(a34, result.a34);
  Expect.equals(a35, result.a35);
  Expect.equals(a36, result.a36);
  Expect.equals(a37, result.a37);
  Expect.equals(a38, result.a38);
  Expect.equals(a39, result.a39);
  Expect.equals(a40, result.a40);
  Expect.equals(a41, result.a41);
  Expect.equals(a42, result.a42);
  Expect.equals(a43, result.a43);
  Expect.equals(a44, result.a44);
  Expect.equals(a45, result.a45);
  Expect.equals(a46, result.a46);
  Expect.equals(a47, result.a47);
  Expect.equals(a48, result.a48);
  Expect.equals(a49, result.a49);
  Expect.equals(a50, result.a50);
  Expect.equals(a51, result.a51);
  Expect.equals(a52, result.a52);
  Expect.equals(a53, result.a53);
  Expect.equals(a54, result.a54);
  Expect.equals(a55, result.a55);
  Expect.equals(a56, result.a56);
  Expect.equals(a57, result.a57);
  Expect.equals(a58, result.a58);
  Expect.equals(a59, result.a59);
  Expect.equals(a60, result.a60);
  Expect.equals(a61, result.a61);
  Expect.equals(a62, result.a62);
  Expect.equals(a63, result.a63);
  Expect.equals(a64, result.a64);
  Expect.equals(a65, result.a65);
  Expect.equals(a66, result.a66);
  Expect.equals(a67, result.a67);
  Expect.equals(a68, result.a68);
  Expect.equals(a69, result.a69);
  Expect.equals(a70, result.a70);
  Expect.equals(a71, result.a71);
  Expect.equals(a72, result.a72);
  Expect.equals(a73, result.a73);
  Expect.equals(a74, result.a74);
  Expect.equals(a75, result.a75);
  Expect.equals(a76, result.a76);
  Expect.equals(a77, result.a77);
  Expect.equals(a78, result.a78);
  Expect.equals(a79, result.a79);
  Expect.equals(a80, result.a80);
  Expect.equals(a81, result.a81);
  Expect.equals(a82, result.a82);
  Expect.equals(a83, result.a83);
  Expect.equals(a84, result.a84);
  Expect.equals(a85, result.a85);
  Expect.equals(a86, result.a86);
  Expect.equals(a87, result.a87);
  Expect.equals(a88, result.a88);
  Expect.equals(a89, result.a89);
  Expect.equals(a90, result.a90);
  Expect.equals(a91, result.a91);
  Expect.equals(a92, result.a92);
  Expect.equals(a93, result.a93);
  Expect.equals(a94, result.a94);
  Expect.equals(a95, result.a95);
  Expect.equals(a96, result.a96);
  Expect.equals(a97, result.a97);
  Expect.equals(a98, result.a98);
  Expect.equals(a99, result.a99);
  Expect.equals(a100, result.a100);
  Expect.equals(a101, result.a101);
  Expect.equals(a102, result.a102);
  Expect.equals(a103, result.a103);
  Expect.equals(a104, result.a104);
  Expect.equals(a105, result.a105);
  Expect.equals(a106, result.a106);
  Expect.equals(a107, result.a107);
  Expect.equals(a108, result.a108);
  Expect.equals(a109, result.a109);
  Expect.equals(a110, result.a110);
  Expect.equals(a111, result.a111);
  Expect.equals(a112, result.a112);
  Expect.equals(a113, result.a113);
  Expect.equals(a114, result.a114);
  Expect.equals(a115, result.a115);
  Expect.equals(a116, result.a116);
  Expect.equals(a117, result.a117);
  Expect.equals(a118, result.a118);
  Expect.equals(a119, result.a119);
  Expect.equals(a120, result.a120);
  Expect.equals(a121, result.a121);
  Expect.equals(a122, result.a122);
  Expect.equals(a123, result.a123);
  Expect.equals(a124, result.a124);
  Expect.equals(a125, result.a125);
  Expect.equals(a126, result.a126);
  Expect.equals(a127, result.a127);
}

final returnStructArgumentStruct1ByteInt = ffiTestFunctions.lookupFunction<
    Struct1ByteInt Function(Struct1ByteInt),
    Struct1ByteInt Function(
        Struct1ByteInt)>("ReturnStructArgumentStruct1ByteInt");

/// Test that a struct passed in as argument can be returned.
/// Especially for ffi callbacks.
/// Struct is passed in int registers in most ABIs.
void testReturnStructArgumentStruct1ByteInt() {
  Struct1ByteInt a0 = allocate<Struct1ByteInt>().ref;

  a0.a0 = -1;

  final result = returnStructArgumentStruct1ByteInt(a0);

  print("result = $result");

  Expect.equals(a0.a0, result.a0);

  free(a0.addressOf);
}

final returnStructArgumentInt32x8Struct1ByteInt =
    ffiTestFunctions.lookupFunction<
        Struct1ByteInt Function(Int32, Int32, Int32, Int32, Int32, Int32, Int32,
            Int32, Struct1ByteInt),
        Struct1ByteInt Function(int, int, int, int, int, int, int, int,
            Struct1ByteInt)>("ReturnStructArgumentInt32x8Struct1ByteInt");

/// Test that a struct passed in as argument can be returned.
/// Especially for ffi callbacks.
/// Struct is passed on stack on all ABIs.
void testReturnStructArgumentInt32x8Struct1ByteInt() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  Struct1ByteInt a8 = allocate<Struct1ByteInt>().ref;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;
  a5 = 6;
  a6 = -7;
  a7 = 8;
  a8.a0 = -9;

  final result = returnStructArgumentInt32x8Struct1ByteInt(
      a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.equals(a8.a0, result.a0);

  free(a8.addressOf);
}

final returnStructArgumentStruct8BytesHomogeneousFloat =
    ffiTestFunctions.lookupFunction<
            Struct8BytesHomogeneousFloat Function(Struct8BytesHomogeneousFloat),
            Struct8BytesHomogeneousFloat Function(
                Struct8BytesHomogeneousFloat)>(
        "ReturnStructArgumentStruct8BytesHomogeneousFloat");

/// Test that a struct passed in as argument can be returned.
/// Especially for ffi callbacks.
/// Struct is passed in float registers in most ABIs.
void testReturnStructArgumentStruct8BytesHomogeneousFloat() {
  Struct8BytesHomogeneousFloat a0 =
      allocate<Struct8BytesHomogeneousFloat>().ref;

  a0.a0 = -1.0;
  a0.a1 = 2.0;

  final result = returnStructArgumentStruct8BytesHomogeneousFloat(a0);

  print("result = $result");

  Expect.approxEquals(a0.a0, result.a0);
  Expect.approxEquals(a0.a1, result.a1);

  free(a0.addressOf);
}

final returnStructArgumentStruct20BytesHomogeneousInt32 =
    ffiTestFunctions
        .lookupFunction<
                Struct20BytesHomogeneousInt32 Function(
                    Struct20BytesHomogeneousInt32),
                Struct20BytesHomogeneousInt32 Function(
                    Struct20BytesHomogeneousInt32)>(
            "ReturnStructArgumentStruct20BytesHomogeneousInt32");

/// On arm64, both argument and return value are passed in by pointer.
void testReturnStructArgumentStruct20BytesHomogeneousInt32() {
  Struct20BytesHomogeneousInt32 a0 =
      allocate<Struct20BytesHomogeneousInt32>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a0.a3 = 4;
  a0.a4 = -5;

  final result = returnStructArgumentStruct20BytesHomogeneousInt32(a0);

  print("result = $result");

  Expect.equals(a0.a0, result.a0);
  Expect.equals(a0.a1, result.a1);
  Expect.equals(a0.a2, result.a2);
  Expect.equals(a0.a3, result.a3);
  Expect.equals(a0.a4, result.a4);

  free(a0.addressOf);
}

final returnStructArgumentInt32x8Struct20BytesHomogeneou =
    ffiTestFunctions.lookupFunction<
            Struct20BytesHomogeneousInt32 Function(Int32, Int32, Int32, Int32,
                Int32, Int32, Int32, Int32, Struct20BytesHomogeneousInt32),
            Struct20BytesHomogeneousInt32 Function(int, int, int, int, int, int,
                int, int, Struct20BytesHomogeneousInt32)>(
        "ReturnStructArgumentInt32x8Struct20BytesHomogeneou");

/// On arm64, both argument and return value are passed in by pointer.
/// Ints exhaust registers, so that pointer is passed on stack.
void testReturnStructArgumentInt32x8Struct20BytesHomogeneou() {
  int a0;
  int a1;
  int a2;
  int a3;
  int a4;
  int a5;
  int a6;
  int a7;
  Struct20BytesHomogeneousInt32 a8 =
      allocate<Struct20BytesHomogeneousInt32>().ref;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;
  a5 = 6;
  a6 = -7;
  a7 = 8;
  a8.a0 = -9;
  a8.a1 = 10;
  a8.a2 = -11;
  a8.a3 = 12;
  a8.a4 = -13;

  final result = returnStructArgumentInt32x8Struct20BytesHomogeneou(
      a0, a1, a2, a3, a4, a5, a6, a7, a8);

  print("result = $result");

  Expect.equals(a8.a0, result.a0);
  Expect.equals(a8.a1, result.a1);
  Expect.equals(a8.a2, result.a2);
  Expect.equals(a8.a3, result.a3);
  Expect.equals(a8.a4, result.a4);

  free(a8.addressOf);
}

final returnStructAlignmentInt16 = ffiTestFunctions.lookupFunction<
    StructAlignmentInt16 Function(Int8, Int16, Int8),
    StructAlignmentInt16 Function(int, int, int)>("ReturnStructAlignmentInt16");

/// Test alignment and padding of 16 byte int within struct.
void testReturnStructAlignmentInt16() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStructAlignmentInt16(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStructAlignmentInt32 = ffiTestFunctions.lookupFunction<
    StructAlignmentInt32 Function(Int8, Int32, Int8),
    StructAlignmentInt32 Function(int, int, int)>("ReturnStructAlignmentInt32");

/// Test alignment and padding of 32 byte int within struct.
void testReturnStructAlignmentInt32() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStructAlignmentInt32(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStructAlignmentInt64 = ffiTestFunctions.lookupFunction<
    StructAlignmentInt64 Function(Int8, Int64, Int8),
    StructAlignmentInt64 Function(int, int, int)>("ReturnStructAlignmentInt64");

/// Test alignment and padding of 64 byte int within struct.
void testReturnStructAlignmentInt64() {
  int a0;
  int a1;
  int a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  final result = returnStructAlignmentInt64(a0, a1, a2);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1, result.a1);
  Expect.equals(a2, result.a2);
}

final returnStruct8BytesNestedInt = ffiTestFunctions.lookupFunction<
    Struct8BytesNestedInt Function(
        Struct4BytesHomogeneousInt16, Struct4BytesHomogeneousInt16),
    Struct8BytesNestedInt Function(Struct4BytesHomogeneousInt16,
        Struct4BytesHomogeneousInt16)>("ReturnStruct8BytesNestedInt");

/// Simple nested struct.
void testReturnStruct8BytesNestedInt() {
  Struct4BytesHomogeneousInt16 a0 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesHomogeneousInt16 a1 =
      allocate<Struct4BytesHomogeneousInt16>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3;
  a1.a1 = 4;

  final result = returnStruct8BytesNestedInt(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0, result.a0.a0);
  Expect.equals(a0.a1, result.a0.a1);
  Expect.equals(a1.a0, result.a1.a0);
  Expect.equals(a1.a1, result.a1.a1);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStruct8BytesNestedFloat = ffiTestFunctions.lookupFunction<
    Struct8BytesNestedFloat Function(Struct4BytesFloat, Struct4BytesFloat),
    Struct8BytesNestedFloat Function(
        Struct4BytesFloat, Struct4BytesFloat)>("ReturnStruct8BytesNestedFloat");

/// Simple nested struct with floats.
void testReturnStruct8BytesNestedFloat() {
  Struct4BytesFloat a0 = allocate<Struct4BytesFloat>().ref;
  Struct4BytesFloat a1 = allocate<Struct4BytesFloat>().ref;

  a0.a0 = -1.0;
  a1.a0 = 2.0;

  final result = returnStruct8BytesNestedFloat(a0, a1);

  print("result = $result");

  Expect.approxEquals(a0.a0, result.a0.a0);
  Expect.approxEquals(a1.a0, result.a1.a0);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStruct8BytesNestedFloat2 = ffiTestFunctions.lookupFunction<
    Struct8BytesNestedFloat2 Function(Struct4BytesFloat, Float),
    Struct8BytesNestedFloat2 Function(
        Struct4BytesFloat, double)>("ReturnStruct8BytesNestedFloat2");

/// The nesting is irregular, testing homogenous float rules on arm and arm64,
/// and the fpu register usage on x64.
void testReturnStruct8BytesNestedFloat2() {
  Struct4BytesFloat a0 = allocate<Struct4BytesFloat>().ref;
  double a1;

  a0.a0 = -1.0;
  a1 = 2.0;

  final result = returnStruct8BytesNestedFloat2(a0, a1);

  print("result = $result");

  Expect.approxEquals(a0.a0, result.a0.a0);
  Expect.approxEquals(a1, result.a1);

  free(a0.addressOf);
}

final returnStruct8BytesNestedMixed = ffiTestFunctions.lookupFunction<
    Struct8BytesNestedMixed Function(
        Struct4BytesHomogeneousInt16, Struct4BytesFloat),
    Struct8BytesNestedMixed Function(Struct4BytesHomogeneousInt16,
        Struct4BytesFloat)>("ReturnStruct8BytesNestedMixed");

/// Simple nested struct with mixed members.
void testReturnStruct8BytesNestedMixed() {
  Struct4BytesHomogeneousInt16 a0 =
      allocate<Struct4BytesHomogeneousInt16>().ref;
  Struct4BytesFloat a1 = allocate<Struct4BytesFloat>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3.0;

  final result = returnStruct8BytesNestedMixed(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0, result.a0.a0);
  Expect.equals(a0.a1, result.a0.a1);
  Expect.approxEquals(a1.a0, result.a1.a0);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStruct16BytesNestedInt = ffiTestFunctions.lookupFunction<
    Struct16BytesNestedInt Function(
        Struct8BytesNestedInt, Struct8BytesNestedInt),
    Struct16BytesNestedInt Function(Struct8BytesNestedInt,
        Struct8BytesNestedInt)>("ReturnStruct16BytesNestedInt");

/// Deeper nested struct to test recursive member access.
void testReturnStruct16BytesNestedInt() {
  Struct8BytesNestedInt a0 = allocate<Struct8BytesNestedInt>().ref;
  Struct8BytesNestedInt a1 = allocate<Struct8BytesNestedInt>().ref;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a1.a0 = -3;
  a0.a1.a1 = 4;
  a1.a0.a0 = -5;
  a1.a0.a1 = 6;
  a1.a1.a0 = -7;
  a1.a1.a1 = 8;

  final result = returnStruct16BytesNestedInt(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0.a0, result.a0.a0.a0);
  Expect.equals(a0.a0.a1, result.a0.a0.a1);
  Expect.equals(a0.a1.a0, result.a0.a1.a0);
  Expect.equals(a0.a1.a1, result.a0.a1.a1);
  Expect.equals(a1.a0.a0, result.a1.a0.a0);
  Expect.equals(a1.a0.a1, result.a1.a0.a1);
  Expect.equals(a1.a1.a0, result.a1.a1.a0);
  Expect.equals(a1.a1.a1, result.a1.a1.a1);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStruct32BytesNestedInt = ffiTestFunctions.lookupFunction<
    Struct32BytesNestedInt Function(
        Struct16BytesNestedInt, Struct16BytesNestedInt),
    Struct32BytesNestedInt Function(Struct16BytesNestedInt,
        Struct16BytesNestedInt)>("ReturnStruct32BytesNestedInt");

/// Even deeper nested struct to test recursive member access.
void testReturnStruct32BytesNestedInt() {
  Struct16BytesNestedInt a0 = allocate<Struct16BytesNestedInt>().ref;
  Struct16BytesNestedInt a1 = allocate<Struct16BytesNestedInt>().ref;

  a0.a0.a0.a0 = -1;
  a0.a0.a0.a1 = 2;
  a0.a0.a1.a0 = -3;
  a0.a0.a1.a1 = 4;
  a0.a1.a0.a0 = -5;
  a0.a1.a0.a1 = 6;
  a0.a1.a1.a0 = -7;
  a0.a1.a1.a1 = 8;
  a1.a0.a0.a0 = -9;
  a1.a0.a0.a1 = 10;
  a1.a0.a1.a0 = -11;
  a1.a0.a1.a1 = 12;
  a1.a1.a0.a0 = -13;
  a1.a1.a0.a1 = 14;
  a1.a1.a1.a0 = -15;
  a1.a1.a1.a1 = 16;

  final result = returnStruct32BytesNestedInt(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0.a0.a0, result.a0.a0.a0.a0);
  Expect.equals(a0.a0.a0.a1, result.a0.a0.a0.a1);
  Expect.equals(a0.a0.a1.a0, result.a0.a0.a1.a0);
  Expect.equals(a0.a0.a1.a1, result.a0.a0.a1.a1);
  Expect.equals(a0.a1.a0.a0, result.a0.a1.a0.a0);
  Expect.equals(a0.a1.a0.a1, result.a0.a1.a0.a1);
  Expect.equals(a0.a1.a1.a0, result.a0.a1.a1.a0);
  Expect.equals(a0.a1.a1.a1, result.a0.a1.a1.a1);
  Expect.equals(a1.a0.a0.a0, result.a1.a0.a0.a0);
  Expect.equals(a1.a0.a0.a1, result.a1.a0.a0.a1);
  Expect.equals(a1.a0.a1.a0, result.a1.a0.a1.a0);
  Expect.equals(a1.a0.a1.a1, result.a1.a0.a1.a1);
  Expect.equals(a1.a1.a0.a0, result.a1.a1.a0.a0);
  Expect.equals(a1.a1.a0.a1, result.a1.a1.a0.a1);
  Expect.equals(a1.a1.a1.a0, result.a1.a1.a1.a0);
  Expect.equals(a1.a1.a1.a1, result.a1.a1.a1.a1);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStructNestedIntStructAlignmentInt16 =
    ffiTestFunctions.lookupFunction<
        StructNestedIntStructAlignmentInt16 Function(
            StructAlignmentInt16, StructAlignmentInt16),
        StructNestedIntStructAlignmentInt16 Function(StructAlignmentInt16,
            StructAlignmentInt16)>("ReturnStructNestedIntStructAlignmentInt16");

/// Test alignment and padding of nested struct with 16 byte int.
void testReturnStructNestedIntStructAlignmentInt16() {
  StructAlignmentInt16 a0 = allocate<StructAlignmentInt16>().ref;
  StructAlignmentInt16 a1 = allocate<StructAlignmentInt16>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  final result = returnStructNestedIntStructAlignmentInt16(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0, result.a0.a0);
  Expect.equals(a0.a1, result.a0.a1);
  Expect.equals(a0.a2, result.a0.a2);
  Expect.equals(a1.a0, result.a1.a0);
  Expect.equals(a1.a1, result.a1.a1);
  Expect.equals(a1.a2, result.a1.a2);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStructNestedIntStructAlignmentInt32 =
    ffiTestFunctions.lookupFunction<
        StructNestedIntStructAlignmentInt32 Function(
            StructAlignmentInt32, StructAlignmentInt32),
        StructNestedIntStructAlignmentInt32 Function(StructAlignmentInt32,
            StructAlignmentInt32)>("ReturnStructNestedIntStructAlignmentInt32");

/// Test alignment and padding of nested struct with 32 byte int.
void testReturnStructNestedIntStructAlignmentInt32() {
  StructAlignmentInt32 a0 = allocate<StructAlignmentInt32>().ref;
  StructAlignmentInt32 a1 = allocate<StructAlignmentInt32>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  final result = returnStructNestedIntStructAlignmentInt32(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0, result.a0.a0);
  Expect.equals(a0.a1, result.a0.a1);
  Expect.equals(a0.a2, result.a0.a2);
  Expect.equals(a1.a0, result.a1.a0);
  Expect.equals(a1.a1, result.a1.a1);
  Expect.equals(a1.a2, result.a1.a2);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStructNestedIntStructAlignmentInt64 =
    ffiTestFunctions.lookupFunction<
        StructNestedIntStructAlignmentInt64 Function(
            StructAlignmentInt64, StructAlignmentInt64),
        StructNestedIntStructAlignmentInt64 Function(StructAlignmentInt64,
            StructAlignmentInt64)>("ReturnStructNestedIntStructAlignmentInt64");

/// Test alignment and padding of nested struct with 64 byte int.
void testReturnStructNestedIntStructAlignmentInt64() {
  StructAlignmentInt64 a0 = allocate<StructAlignmentInt64>().ref;
  StructAlignmentInt64 a1 = allocate<StructAlignmentInt64>().ref;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  final result = returnStructNestedIntStructAlignmentInt64(a0, a1);

  print("result = $result");

  Expect.equals(a0.a0, result.a0.a0);
  Expect.equals(a0.a1, result.a0.a1);
  Expect.equals(a0.a2, result.a0.a2);
  Expect.equals(a1.a0, result.a1.a0);
  Expect.equals(a1.a1, result.a1.a1);
  Expect.equals(a1.a2, result.a1.a2);

  free(a0.addressOf);
  free(a1.addressOf);
}

final returnStructNestedIrregularEvenBigger = ffiTestFunctions.lookupFunction<
    StructNestedIrregularEvenBigger Function(Uint64,
        StructNestedIrregularBigger, StructNestedIrregularBigger, Double),
    StructNestedIrregularEvenBigger Function(
        int,
        StructNestedIrregularBigger,
        StructNestedIrregularBigger,
        double)>("ReturnStructNestedIrregularEvenBigger");

/// Return big irregular struct as smoke test.
void testReturnStructNestedIrregularEvenBigger() {
  int a0;
  StructNestedIrregularBigger a1 = allocate<StructNestedIrregularBigger>().ref;
  StructNestedIrregularBigger a2 = allocate<StructNestedIrregularBigger>().ref;
  double a3;

  a0 = 1;
  a1.a0.a0 = 2;
  a1.a0.a1.a0.a0 = -3;
  a1.a0.a1.a0.a1 = 4;
  a1.a0.a1.a1.a0 = -5.0;
  a1.a0.a2 = 6;
  a1.a0.a3.a0.a0 = -7.0;
  a1.a0.a3.a1 = 8.0;
  a1.a0.a4 = 9;
  a1.a0.a5.a0.a0 = 10.0;
  a1.a0.a5.a1.a0 = -11.0;
  a1.a0.a6 = 12;
  a1.a1.a0.a0 = -13;
  a1.a1.a0.a1 = 14;
  a1.a1.a1.a0 = -15.0;
  a1.a2 = 16.0;
  a1.a3 = -17.0;
  a2.a0.a0 = 18;
  a2.a0.a1.a0.a0 = -19;
  a2.a0.a1.a0.a1 = 20;
  a2.a0.a1.a1.a0 = -21.0;
  a2.a0.a2 = 22;
  a2.a0.a3.a0.a0 = -23.0;
  a2.a0.a3.a1 = 24.0;
  a2.a0.a4 = 25;
  a2.a0.a5.a0.a0 = 26.0;
  a2.a0.a5.a1.a0 = -27.0;
  a2.a0.a6 = 28;
  a2.a1.a0.a0 = -29;
  a2.a1.a0.a1 = 30;
  a2.a1.a1.a0 = -31.0;
  a2.a2 = 32.0;
  a2.a3 = -33.0;
  a3 = 34.0;

  final result = returnStructNestedIrregularEvenBigger(a0, a1, a2, a3);

  print("result = $result");

  Expect.equals(a0, result.a0);
  Expect.equals(a1.a0.a0, result.a1.a0.a0);
  Expect.equals(a1.a0.a1.a0.a0, result.a1.a0.a1.a0.a0);
  Expect.equals(a1.a0.a1.a0.a1, result.a1.a0.a1.a0.a1);
  Expect.approxEquals(a1.a0.a1.a1.a0, result.a1.a0.a1.a1.a0);
  Expect.equals(a1.a0.a2, result.a1.a0.a2);
  Expect.approxEquals(a1.a0.a3.a0.a0, result.a1.a0.a3.a0.a0);
  Expect.approxEquals(a1.a0.a3.a1, result.a1.a0.a3.a1);
  Expect.equals(a1.a0.a4, result.a1.a0.a4);
  Expect.approxEquals(a1.a0.a5.a0.a0, result.a1.a0.a5.a0.a0);
  Expect.approxEquals(a1.a0.a5.a1.a0, result.a1.a0.a5.a1.a0);
  Expect.equals(a1.a0.a6, result.a1.a0.a6);
  Expect.equals(a1.a1.a0.a0, result.a1.a1.a0.a0);
  Expect.equals(a1.a1.a0.a1, result.a1.a1.a0.a1);
  Expect.approxEquals(a1.a1.a1.a0, result.a1.a1.a1.a0);
  Expect.approxEquals(a1.a2, result.a1.a2);
  Expect.approxEquals(a1.a3, result.a1.a3);
  Expect.equals(a2.a0.a0, result.a2.a0.a0);
  Expect.equals(a2.a0.a1.a0.a0, result.a2.a0.a1.a0.a0);
  Expect.equals(a2.a0.a1.a0.a1, result.a2.a0.a1.a0.a1);
  Expect.approxEquals(a2.a0.a1.a1.a0, result.a2.a0.a1.a1.a0);
  Expect.equals(a2.a0.a2, result.a2.a0.a2);
  Expect.approxEquals(a2.a0.a3.a0.a0, result.a2.a0.a3.a0.a0);
  Expect.approxEquals(a2.a0.a3.a1, result.a2.a0.a3.a1);
  Expect.equals(a2.a0.a4, result.a2.a0.a4);
  Expect.approxEquals(a2.a0.a5.a0.a0, result.a2.a0.a5.a0.a0);
  Expect.approxEquals(a2.a0.a5.a1.a0, result.a2.a0.a5.a1.a0);
  Expect.equals(a2.a0.a6, result.a2.a0.a6);
  Expect.equals(a2.a1.a0.a0, result.a2.a1.a0.a0);
  Expect.equals(a2.a1.a0.a1, result.a2.a1.a0.a1);
  Expect.approxEquals(a2.a1.a1.a0, result.a2.a1.a1.a0);
  Expect.approxEquals(a2.a2, result.a2.a2);
  Expect.approxEquals(a2.a3, result.a2.a3);
  Expect.approxEquals(a3, result.a3);

  free(a1.addressOf);
  free(a2.addressOf);
}
