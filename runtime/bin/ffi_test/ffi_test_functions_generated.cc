// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>

#include <cmath>
#include <iostream>
#include <limits>

#if defined(_WIN32)
#define DART_EXPORT extern "C" __declspec(dllexport)
#else
#define DART_EXPORT                                                            \
  extern "C" __attribute__((visibility("default"))) __attribute((used))
#endif

namespace dart {

#define CHECK(X)                                                               \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s\n", "Check failed: " #X);                              \
    return 1;                                                                  \
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

// Works for positive, negative and zero.
#define CHECK_APPROX(EXPECTED, ACTUAL)                                         \
  CHECK(((EXPECTED * 0.99) <= (ACTUAL) && (EXPECTED * 1.01) >= (ACTUAL)) ||    \
        ((EXPECTED * 0.99) >= (ACTUAL) && (EXPECTED * 1.01) <= (ACTUAL)))

struct Struct0Bytes {};

struct Struct1ByteInt {
  int8_t a0;
};

struct Struct3BytesHomogeneousUint8 {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
};

struct Struct3BytesInt2ByteAligned {
  int16_t a0;
  int8_t a1;
};

struct Struct4BytesHomogeneousInt16 {
  int16_t a0;
  int16_t a1;
};

struct Struct4BytesFloat {
  float a0;
};

struct Struct7BytesHomogeneousUint8 {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;
};

struct Struct7BytesInt4ByteAligned {
  int32_t a0;
  int16_t a1;
  int8_t a2;
};

struct Struct8BytesInt {
  int16_t a0;
  int16_t a1;
  int32_t a2;
};

struct Struct8BytesHomogeneousFloat {
  float a0;
  float a1;
};

struct Struct8BytesMixed {
  float a0;
  int16_t a1;
  int16_t a2;
};

struct Struct9BytesHomogeneousUint8 {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;
  uint8_t a7;
  uint8_t a8;
};

struct Struct9BytesInt4Or8ByteAligned {
  int64_t a0;
  int8_t a1;
};

struct Struct12BytesHomogeneousFloat {
  float a0;
  float a1;
  float a2;
};

struct Struct16BytesHomogeneousFloat {
  float a0;
  float a1;
  float a2;
  float a3;
};

struct Struct16BytesMixed {
  double a0;
  int64_t a1;
};

struct Struct16BytesMixed2 {
  float a0;
  float a1;
  float a2;
  int32_t a3;
};

struct Struct17BytesInt {
  int64_t a0;
  int64_t a1;
  int8_t a2;
};

struct Struct19BytesHomogeneousUint8 {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;
  uint8_t a7;
  uint8_t a8;
  uint8_t a9;
  uint8_t a10;
  uint8_t a11;
  uint8_t a12;
  uint8_t a13;
  uint8_t a14;
  uint8_t a15;
  uint8_t a16;
  uint8_t a17;
  uint8_t a18;
};

struct Struct20BytesHomogeneousInt32 {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  int32_t a4;
};

struct Struct20BytesHomogeneousFloat {
  float a0;
  float a1;
  float a2;
  float a3;
  float a4;
};

struct Struct32BytesHomogeneousDouble {
  double a0;
  double a1;
  double a2;
  double a3;
};

struct Struct40BytesHomogeneousDouble {
  double a0;
  double a1;
  double a2;
  double a3;
  double a4;
};

struct Struct1024BytesHomogeneousUint64 {
  uint64_t a0;
  uint64_t a1;
  uint64_t a2;
  uint64_t a3;
  uint64_t a4;
  uint64_t a5;
  uint64_t a6;
  uint64_t a7;
  uint64_t a8;
  uint64_t a9;
  uint64_t a10;
  uint64_t a11;
  uint64_t a12;
  uint64_t a13;
  uint64_t a14;
  uint64_t a15;
  uint64_t a16;
  uint64_t a17;
  uint64_t a18;
  uint64_t a19;
  uint64_t a20;
  uint64_t a21;
  uint64_t a22;
  uint64_t a23;
  uint64_t a24;
  uint64_t a25;
  uint64_t a26;
  uint64_t a27;
  uint64_t a28;
  uint64_t a29;
  uint64_t a30;
  uint64_t a31;
  uint64_t a32;
  uint64_t a33;
  uint64_t a34;
  uint64_t a35;
  uint64_t a36;
  uint64_t a37;
  uint64_t a38;
  uint64_t a39;
  uint64_t a40;
  uint64_t a41;
  uint64_t a42;
  uint64_t a43;
  uint64_t a44;
  uint64_t a45;
  uint64_t a46;
  uint64_t a47;
  uint64_t a48;
  uint64_t a49;
  uint64_t a50;
  uint64_t a51;
  uint64_t a52;
  uint64_t a53;
  uint64_t a54;
  uint64_t a55;
  uint64_t a56;
  uint64_t a57;
  uint64_t a58;
  uint64_t a59;
  uint64_t a60;
  uint64_t a61;
  uint64_t a62;
  uint64_t a63;
  uint64_t a64;
  uint64_t a65;
  uint64_t a66;
  uint64_t a67;
  uint64_t a68;
  uint64_t a69;
  uint64_t a70;
  uint64_t a71;
  uint64_t a72;
  uint64_t a73;
  uint64_t a74;
  uint64_t a75;
  uint64_t a76;
  uint64_t a77;
  uint64_t a78;
  uint64_t a79;
  uint64_t a80;
  uint64_t a81;
  uint64_t a82;
  uint64_t a83;
  uint64_t a84;
  uint64_t a85;
  uint64_t a86;
  uint64_t a87;
  uint64_t a88;
  uint64_t a89;
  uint64_t a90;
  uint64_t a91;
  uint64_t a92;
  uint64_t a93;
  uint64_t a94;
  uint64_t a95;
  uint64_t a96;
  uint64_t a97;
  uint64_t a98;
  uint64_t a99;
  uint64_t a100;
  uint64_t a101;
  uint64_t a102;
  uint64_t a103;
  uint64_t a104;
  uint64_t a105;
  uint64_t a106;
  uint64_t a107;
  uint64_t a108;
  uint64_t a109;
  uint64_t a110;
  uint64_t a111;
  uint64_t a112;
  uint64_t a113;
  uint64_t a114;
  uint64_t a115;
  uint64_t a116;
  uint64_t a117;
  uint64_t a118;
  uint64_t a119;
  uint64_t a120;
  uint64_t a121;
  uint64_t a122;
  uint64_t a123;
  uint64_t a124;
  uint64_t a125;
  uint64_t a126;
  uint64_t a127;
};

struct StructAlignmentInt16 {
  int8_t a0;
  int16_t a1;
  int8_t a2;
};

struct StructAlignmentInt32 {
  int8_t a0;
  int32_t a1;
  int8_t a2;
};

struct StructAlignmentInt64 {
  int8_t a0;
  int64_t a1;
  int8_t a2;
};

struct Struct8BytesNestedInt {
  Struct4BytesHomogeneousInt16 a0;
  Struct4BytesHomogeneousInt16 a1;
};

struct Struct8BytesNestedFloat {
  Struct4BytesFloat a0;
  Struct4BytesFloat a1;
};

struct Struct8BytesNestedFloat2 {
  Struct4BytesFloat a0;
  float a1;
};

struct Struct8BytesNestedMixed {
  Struct4BytesHomogeneousInt16 a0;
  Struct4BytesFloat a1;
};

struct Struct16BytesNestedInt {
  Struct8BytesNestedInt a0;
  Struct8BytesNestedInt a1;
};

struct Struct32BytesNestedInt {
  Struct16BytesNestedInt a0;
  Struct16BytesNestedInt a1;
};

struct StructNestedIntStructAlignmentInt16 {
  StructAlignmentInt16 a0;
  StructAlignmentInt16 a1;
};

struct StructNestedIntStructAlignmentInt32 {
  StructAlignmentInt32 a0;
  StructAlignmentInt32 a1;
};

struct StructNestedIntStructAlignmentInt64 {
  StructAlignmentInt64 a0;
  StructAlignmentInt64 a1;
};

struct StructNestedIrregularBig {
  uint16_t a0;
  Struct8BytesNestedMixed a1;
  uint16_t a2;
  Struct8BytesNestedFloat2 a3;
  uint16_t a4;
  Struct8BytesNestedFloat a5;
  uint16_t a6;
};

struct StructNestedIrregularBigger {
  StructNestedIrregularBig a0;
  Struct8BytesNestedMixed a1;
  float a2;
  double a3;
};

struct StructNestedIrregularEvenBigger {
  uint64_t a0;
  StructNestedIrregularBigger a1;
  StructNestedIrregularBigger a2;
  double a3;
};

// Used for testing structs by value.
// Smallest struct with data.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t PassStruct1ByteIntx10(Struct1ByteInt a0,
                                          Struct1ByteInt a1,
                                          Struct1ByteInt a2,
                                          Struct1ByteInt a3,
                                          Struct1ByteInt a4,
                                          Struct1ByteInt a5,
                                          Struct1ByteInt a6,
                                          Struct1ByteInt a7,
                                          Struct1ByteInt a8,
                                          Struct1ByteInt a9) {
  std::cout << "PassStruct1ByteIntx10"
            << "((" << static_cast<int>(a0.a0) << "), ("
            << static_cast<int>(a1.a0) << "), (" << static_cast<int>(a2.a0)
            << "), (" << static_cast<int>(a3.a0) << "), ("
            << static_cast<int>(a4.a0) << "), (" << static_cast<int>(a5.a0)
            << "), (" << static_cast<int>(a6.a0) << "), ("
            << static_cast<int>(a7.a0) << "), (" << static_cast<int>(a8.a0)
            << "), (" << static_cast<int>(a9.a0) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a1.a0;
  result += a2.a0;
  result += a3.a0;
  result += a4.a0;
  result += a5.a0;
  result += a6.a0;
  result += a7.a0;
  result += a8.a0;
  result += a9.a0;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Not a multiple of word size, not a power of two.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t
PassStruct3BytesHomogeneousUint8x10(Struct3BytesHomogeneousUint8 a0,
                                    Struct3BytesHomogeneousUint8 a1,
                                    Struct3BytesHomogeneousUint8 a2,
                                    Struct3BytesHomogeneousUint8 a3,
                                    Struct3BytesHomogeneousUint8 a4,
                                    Struct3BytesHomogeneousUint8 a5,
                                    Struct3BytesHomogeneousUint8 a6,
                                    Struct3BytesHomogeneousUint8 a7,
                                    Struct3BytesHomogeneousUint8 a8,
                                    Struct3BytesHomogeneousUint8 a9) {
  std::cout << "PassStruct3BytesHomogeneousUint8x10"
            << "((" << static_cast<int>(a0.a0) << ", "
            << static_cast<int>(a0.a1) << ", " << static_cast<int>(a0.a2)
            << "), (" << static_cast<int>(a1.a0) << ", "
            << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
            << "), (" << static_cast<int>(a2.a0) << ", "
            << static_cast<int>(a2.a1) << ", " << static_cast<int>(a2.a2)
            << "), (" << static_cast<int>(a3.a0) << ", "
            << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
            << "), (" << static_cast<int>(a4.a0) << ", "
            << static_cast<int>(a4.a1) << ", " << static_cast<int>(a4.a2)
            << "), (" << static_cast<int>(a5.a0) << ", "
            << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
            << "), (" << static_cast<int>(a6.a0) << ", "
            << static_cast<int>(a6.a1) << ", " << static_cast<int>(a6.a2)
            << "), (" << static_cast<int>(a7.a0) << ", "
            << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
            << "), (" << static_cast<int>(a8.a0) << ", "
            << static_cast<int>(a8.a1) << ", " << static_cast<int>(a8.a2)
            << "), (" << static_cast<int>(a9.a0) << ", "
            << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
            << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Not a multiple of word size, not a power of two.
// With alignment rules taken into account size is 4 bytes.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t
PassStruct3BytesInt2ByteAlignedx10(Struct3BytesInt2ByteAligned a0,
                                   Struct3BytesInt2ByteAligned a1,
                                   Struct3BytesInt2ByteAligned a2,
                                   Struct3BytesInt2ByteAligned a3,
                                   Struct3BytesInt2ByteAligned a4,
                                   Struct3BytesInt2ByteAligned a5,
                                   Struct3BytesInt2ByteAligned a6,
                                   Struct3BytesInt2ByteAligned a7,
                                   Struct3BytesInt2ByteAligned a8,
                                   Struct3BytesInt2ByteAligned a9) {
  std::cout << "PassStruct3BytesInt2ByteAlignedx10"
            << "((" << a0.a0 << ", " << static_cast<int>(a0.a1) << "), ("
            << a1.a0 << ", " << static_cast<int>(a1.a1) << "), (" << a2.a0
            << ", " << static_cast<int>(a2.a1) << "), (" << a3.a0 << ", "
            << static_cast<int>(a3.a1) << "), (" << a4.a0 << ", "
            << static_cast<int>(a4.a1) << "), (" << a5.a0 << ", "
            << static_cast<int>(a5.a1) << "), (" << a6.a0 << ", "
            << static_cast<int>(a6.a1) << "), (" << a7.a0 << ", "
            << static_cast<int>(a7.a1) << "), (" << a8.a0 << ", "
            << static_cast<int>(a8.a1) << "), (" << a9.a0 << ", "
            << static_cast<int>(a9.a1) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;
  result += a3.a0;
  result += a3.a1;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Exactly word size on 32-bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t
PassStruct4BytesHomogeneousInt16x10(Struct4BytesHomogeneousInt16 a0,
                                    Struct4BytesHomogeneousInt16 a1,
                                    Struct4BytesHomogeneousInt16 a2,
                                    Struct4BytesHomogeneousInt16 a3,
                                    Struct4BytesHomogeneousInt16 a4,
                                    Struct4BytesHomogeneousInt16 a5,
                                    Struct4BytesHomogeneousInt16 a6,
                                    Struct4BytesHomogeneousInt16 a7,
                                    Struct4BytesHomogeneousInt16 a8,
                                    Struct4BytesHomogeneousInt16 a9) {
  std::cout << "PassStruct4BytesHomogeneousInt16x10"
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;
  result += a3.a0;
  result += a3.a1;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Sub word size on 64 bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t
PassStruct7BytesHomogeneousUint8x10(Struct7BytesHomogeneousUint8 a0,
                                    Struct7BytesHomogeneousUint8 a1,
                                    Struct7BytesHomogeneousUint8 a2,
                                    Struct7BytesHomogeneousUint8 a3,
                                    Struct7BytesHomogeneousUint8 a4,
                                    Struct7BytesHomogeneousUint8 a5,
                                    Struct7BytesHomogeneousUint8 a6,
                                    Struct7BytesHomogeneousUint8 a7,
                                    Struct7BytesHomogeneousUint8 a8,
                                    Struct7BytesHomogeneousUint8 a9) {
  std::cout
      << "PassStruct7BytesHomogeneousUint8x10"
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << "))"
      << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a0.a5;
  result += a0.a6;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a1.a4;
  result += a1.a5;
  result += a1.a6;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a2.a4;
  result += a2.a5;
  result += a2.a6;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a3.a4;
  result += a3.a5;
  result += a3.a6;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;
  result += a4.a4;
  result += a4.a5;
  result += a4.a6;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a5.a4;
  result += a5.a5;
  result += a5.a6;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a6.a3;
  result += a6.a4;
  result += a6.a5;
  result += a6.a6;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a7.a4;
  result += a7.a5;
  result += a7.a6;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a8.a3;
  result += a8.a4;
  result += a8.a5;
  result += a8.a6;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;
  result += a9.a3;
  result += a9.a4;
  result += a9.a5;
  result += a9.a6;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Sub word size on 64 bit architectures.
// With alignment rules taken into account size is 8 bytes.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t
PassStruct7BytesInt4ByteAlignedx10(Struct7BytesInt4ByteAligned a0,
                                   Struct7BytesInt4ByteAligned a1,
                                   Struct7BytesInt4ByteAligned a2,
                                   Struct7BytesInt4ByteAligned a3,
                                   Struct7BytesInt4ByteAligned a4,
                                   Struct7BytesInt4ByteAligned a5,
                                   Struct7BytesInt4ByteAligned a6,
                                   Struct7BytesInt4ByteAligned a7,
                                   Struct7BytesInt4ByteAligned a8,
                                   Struct7BytesInt4ByteAligned a9) {
  std::cout << "PassStruct7BytesInt4ByteAlignedx10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << static_cast<int>(a0.a2)
            << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << static_cast<int>(a1.a2) << "), (" << a2.a0 << ", " << a2.a1
            << ", " << static_cast<int>(a2.a2) << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << static_cast<int>(a3.a2) << "), (" << a4.a0
            << ", " << a4.a1 << ", " << static_cast<int>(a4.a2) << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << static_cast<int>(a5.a2)
            << "), (" << a6.a0 << ", " << a6.a1 << ", "
            << static_cast<int>(a6.a2) << "), (" << a7.a0 << ", " << a7.a1
            << ", " << static_cast<int>(a7.a2) << "), (" << a8.a0 << ", "
            << a8.a1 << ", " << static_cast<int>(a8.a2) << "), (" << a9.a0
            << ", " << a9.a1 << ", " << static_cast<int>(a9.a2) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Exactly word size struct on 64bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT int64_t PassStruct8BytesIntx10(Struct8BytesInt a0,
                                           Struct8BytesInt a1,
                                           Struct8BytesInt a2,
                                           Struct8BytesInt a3,
                                           Struct8BytesInt a4,
                                           Struct8BytesInt a5,
                                           Struct8BytesInt a6,
                                           Struct8BytesInt a7,
                                           Struct8BytesInt a8,
                                           Struct8BytesInt a9) {
  std::cout << "PassStruct8BytesIntx10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << "), (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << "), ("
            << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << "), (" << a9.a0
            << ", " << a9.a1 << ", " << a9.a2 << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Arguments passed in FP registers as long as they fit.
// 10 struct arguments will exhaust available registers.
DART_EXPORT float PassStruct8BytesHomogeneousFloatx10(
    Struct8BytesHomogeneousFloat a0,
    Struct8BytesHomogeneousFloat a1,
    Struct8BytesHomogeneousFloat a2,
    Struct8BytesHomogeneousFloat a3,
    Struct8BytesHomogeneousFloat a4,
    Struct8BytesHomogeneousFloat a5,
    Struct8BytesHomogeneousFloat a6,
    Struct8BytesHomogeneousFloat a7,
    Struct8BytesHomogeneousFloat a8,
    Struct8BytesHomogeneousFloat a9) {
  std::cout << "PassStruct8BytesHomogeneousFloatx10"
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;
  result += a3.a0;
  result += a3.a1;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On x64, arguments go in int registers because it is not only float.
// 10 struct arguments will exhaust available registers.
DART_EXPORT float PassStruct8BytesMixedx10(Struct8BytesMixed a0,
                                           Struct8BytesMixed a1,
                                           Struct8BytesMixed a2,
                                           Struct8BytesMixed a3,
                                           Struct8BytesMixed a4,
                                           Struct8BytesMixed a5,
                                           Struct8BytesMixed a6,
                                           Struct8BytesMixed a7,
                                           Struct8BytesMixed a8,
                                           Struct8BytesMixed a9) {
  std::cout << "PassStruct8BytesMixedx10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << "), (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << "), ("
            << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << "), (" << a9.a0
            << ", " << a9.a1 << ", " << a9.a2 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Argument is a single byte over a multiple of word size.
// 10 struct arguments will exhaust available registers.
// Struct only has 1-byte aligned fields to test struct alignment itself.
// Tests upper bytes in the integer registers that are partly filled.
// Tests stack alignment of non word size stack arguments.
DART_EXPORT int64_t
PassStruct9BytesHomogeneousUint8x10(Struct9BytesHomogeneousUint8 a0,
                                    Struct9BytesHomogeneousUint8 a1,
                                    Struct9BytesHomogeneousUint8 a2,
                                    Struct9BytesHomogeneousUint8 a3,
                                    Struct9BytesHomogeneousUint8 a4,
                                    Struct9BytesHomogeneousUint8 a5,
                                    Struct9BytesHomogeneousUint8 a6,
                                    Struct9BytesHomogeneousUint8 a7,
                                    Struct9BytesHomogeneousUint8 a8,
                                    Struct9BytesHomogeneousUint8 a9) {
  std::cout
      << "PassStruct9BytesHomogeneousUint8x10"
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << ", " << static_cast<int>(a0.a7)
      << ", " << static_cast<int>(a0.a8) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << ", " << static_cast<int>(a1.a7) << ", " << static_cast<int>(a1.a8)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << ", " << static_cast<int>(a2.a7)
      << ", " << static_cast<int>(a2.a8) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << ", " << static_cast<int>(a3.a7) << ", " << static_cast<int>(a3.a8)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << ", " << static_cast<int>(a4.a7)
      << ", " << static_cast<int>(a4.a8) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << ", " << static_cast<int>(a5.a7) << ", " << static_cast<int>(a5.a8)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << ", " << static_cast<int>(a6.a7)
      << ", " << static_cast<int>(a6.a8) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << ", " << static_cast<int>(a7.a7) << ", " << static_cast<int>(a7.a8)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << ", " << static_cast<int>(a8.a7)
      << ", " << static_cast<int>(a8.a8) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << ", " << static_cast<int>(a9.a7) << ", " << static_cast<int>(a9.a8)
      << "))"
      << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a0.a5;
  result += a0.a6;
  result += a0.a7;
  result += a0.a8;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a1.a4;
  result += a1.a5;
  result += a1.a6;
  result += a1.a7;
  result += a1.a8;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a2.a4;
  result += a2.a5;
  result += a2.a6;
  result += a2.a7;
  result += a2.a8;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a3.a4;
  result += a3.a5;
  result += a3.a6;
  result += a3.a7;
  result += a3.a8;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;
  result += a4.a4;
  result += a4.a5;
  result += a4.a6;
  result += a4.a7;
  result += a4.a8;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a5.a4;
  result += a5.a5;
  result += a5.a6;
  result += a5.a7;
  result += a5.a8;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a6.a3;
  result += a6.a4;
  result += a6.a5;
  result += a6.a6;
  result += a6.a7;
  result += a6.a8;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a7.a4;
  result += a7.a5;
  result += a7.a6;
  result += a7.a7;
  result += a7.a8;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a8.a3;
  result += a8.a4;
  result += a8.a5;
  result += a8.a6;
  result += a8.a7;
  result += a8.a8;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;
  result += a9.a3;
  result += a9.a4;
  result += a9.a5;
  result += a9.a6;
  result += a9.a7;
  result += a9.a8;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Argument is a single byte over a multiple of word size.
// With alignment rules taken into account size is 12 or 16 bytes.
// 10 struct arguments will exhaust available registers.
//
DART_EXPORT int64_t
PassStruct9BytesInt4Or8ByteAlignedx10(Struct9BytesInt4Or8ByteAligned a0,
                                      Struct9BytesInt4Or8ByteAligned a1,
                                      Struct9BytesInt4Or8ByteAligned a2,
                                      Struct9BytesInt4Or8ByteAligned a3,
                                      Struct9BytesInt4Or8ByteAligned a4,
                                      Struct9BytesInt4Or8ByteAligned a5,
                                      Struct9BytesInt4Or8ByteAligned a6,
                                      Struct9BytesInt4Or8ByteAligned a7,
                                      Struct9BytesInt4Or8ByteAligned a8,
                                      Struct9BytesInt4Or8ByteAligned a9) {
  std::cout << "PassStruct9BytesInt4Or8ByteAlignedx10"
            << "((" << a0.a0 << ", " << static_cast<int>(a0.a1) << "), ("
            << a1.a0 << ", " << static_cast<int>(a1.a1) << "), (" << a2.a0
            << ", " << static_cast<int>(a2.a1) << "), (" << a3.a0 << ", "
            << static_cast<int>(a3.a1) << "), (" << a4.a0 << ", "
            << static_cast<int>(a4.a1) << "), (" << a5.a0 << ", "
            << static_cast<int>(a5.a1) << "), (" << a6.a0 << ", "
            << static_cast<int>(a6.a1) << "), (" << a7.a0 << ", "
            << static_cast<int>(a7.a1) << "), (" << a8.a0 << ", "
            << static_cast<int>(a8.a1) << "), (" << a9.a0 << ", "
            << static_cast<int>(a9.a1) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;
  result += a3.a0;
  result += a3.a1;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Arguments in FPU registers on arm hardfp and arm64.
// Struct arguments will exhaust available registers, and leave some empty.
// The last argument is to test whether arguments are backfilled.
DART_EXPORT float PassStruct12BytesHomogeneousFloatx6(
    Struct12BytesHomogeneousFloat a0,
    Struct12BytesHomogeneousFloat a1,
    Struct12BytesHomogeneousFloat a2,
    Struct12BytesHomogeneousFloat a3,
    Struct12BytesHomogeneousFloat a4,
    Struct12BytesHomogeneousFloat a5) {
  std::cout << "PassStruct12BytesHomogeneousFloatx6"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On Linux x64 argument is transferred on stack because it is over 16 bytes.
// Arguments in FPU registers on arm hardfp and arm64.
// 5 struct arguments will exhaust available registers.
DART_EXPORT float PassStruct16BytesHomogeneousFloatx5(
    Struct16BytesHomogeneousFloat a0,
    Struct16BytesHomogeneousFloat a1,
    Struct16BytesHomogeneousFloat a2,
    Struct16BytesHomogeneousFloat a3,
    Struct16BytesHomogeneousFloat a4) {
  std::cout << "PassStruct16BytesHomogeneousFloatx5"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On x64, arguments are split over FP and int registers.
// On x64, it will exhaust the integer registers with the 6th argument.
// The rest goes on the stack.
// On arm, arguments are 8 byte aligned.
DART_EXPORT double PassStruct16BytesMixedx10(Struct16BytesMixed a0,
                                             Struct16BytesMixed a1,
                                             Struct16BytesMixed a2,
                                             Struct16BytesMixed a3,
                                             Struct16BytesMixed a4,
                                             Struct16BytesMixed a5,
                                             Struct16BytesMixed a6,
                                             Struct16BytesMixed a7,
                                             Struct16BytesMixed a8,
                                             Struct16BytesMixed a9) {
  std::cout << "PassStruct16BytesMixedx10"
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << "\n";

  double result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;
  result += a3.a0;
  result += a3.a1;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On x64, arguments are split over FP and int registers.
// On x64, it will exhaust the integer registers with the 6th argument.
// The rest goes on the stack.
// On arm, arguments are 4 byte aligned.
DART_EXPORT float PassStruct16BytesMixed2x10(Struct16BytesMixed2 a0,
                                             Struct16BytesMixed2 a1,
                                             Struct16BytesMixed2 a2,
                                             Struct16BytesMixed2 a3,
                                             Struct16BytesMixed2 a4,
                                             Struct16BytesMixed2 a5,
                                             Struct16BytesMixed2 a6,
                                             Struct16BytesMixed2 a7,
                                             Struct16BytesMixed2 a8,
                                             Struct16BytesMixed2 a9) {
  std::cout << "PassStruct16BytesMixed2x10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "), (" << a5.a0 << ", "
            << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), (" << a6.a0
            << ", " << a6.a1 << ", " << a6.a2 << ", " << a6.a3 << "), ("
            << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), (" << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << ", "
            << a8.a3 << "), (" << a9.a0 << ", " << a9.a1 << ", " << a9.a2
            << ", " << a9.a3 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a6.a3;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a8.a3;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;
  result += a9.a3;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Arguments are passed as pointer to copy on arm64.
// Tests that the memory allocated for copies are rounded up to word size.
DART_EXPORT int64_t PassStruct17BytesIntx10(Struct17BytesInt a0,
                                            Struct17BytesInt a1,
                                            Struct17BytesInt a2,
                                            Struct17BytesInt a3,
                                            Struct17BytesInt a4,
                                            Struct17BytesInt a5,
                                            Struct17BytesInt a6,
                                            Struct17BytesInt a7,
                                            Struct17BytesInt a8,
                                            Struct17BytesInt a9) {
  std::cout << "PassStruct17BytesIntx10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << static_cast<int>(a0.a2)
            << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << static_cast<int>(a1.a2) << "), (" << a2.a0 << ", " << a2.a1
            << ", " << static_cast<int>(a2.a2) << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << static_cast<int>(a3.a2) << "), (" << a4.a0
            << ", " << a4.a1 << ", " << static_cast<int>(a4.a2) << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << static_cast<int>(a5.a2)
            << "), (" << a6.a0 << ", " << a6.a1 << ", "
            << static_cast<int>(a6.a2) << "), (" << a7.a0 << ", " << a7.a1
            << ", " << static_cast<int>(a7.a2) << "), (" << a8.a0 << ", "
            << a8.a1 << ", " << static_cast<int>(a8.a2) << "), (" << a9.a0
            << ", " << a9.a1 << ", " << static_cast<int>(a9.a2) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is extended to the right size.
//
DART_EXPORT int64_t
PassStruct19BytesHomogeneousUint8x10(Struct19BytesHomogeneousUint8 a0,
                                     Struct19BytesHomogeneousUint8 a1,
                                     Struct19BytesHomogeneousUint8 a2,
                                     Struct19BytesHomogeneousUint8 a3,
                                     Struct19BytesHomogeneousUint8 a4,
                                     Struct19BytesHomogeneousUint8 a5,
                                     Struct19BytesHomogeneousUint8 a6,
                                     Struct19BytesHomogeneousUint8 a7,
                                     Struct19BytesHomogeneousUint8 a8,
                                     Struct19BytesHomogeneousUint8 a9) {
  std::cout
      << "PassStruct19BytesHomogeneousUint8x10"
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << ", " << static_cast<int>(a0.a7)
      << ", " << static_cast<int>(a0.a8) << ", " << static_cast<int>(a0.a9)
      << ", " << static_cast<int>(a0.a10) << ", " << static_cast<int>(a0.a11)
      << ", " << static_cast<int>(a0.a12) << ", " << static_cast<int>(a0.a13)
      << ", " << static_cast<int>(a0.a14) << ", " << static_cast<int>(a0.a15)
      << ", " << static_cast<int>(a0.a16) << ", " << static_cast<int>(a0.a17)
      << ", " << static_cast<int>(a0.a18) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << ", " << static_cast<int>(a1.a7) << ", " << static_cast<int>(a1.a8)
      << ", " << static_cast<int>(a1.a9) << ", " << static_cast<int>(a1.a10)
      << ", " << static_cast<int>(a1.a11) << ", " << static_cast<int>(a1.a12)
      << ", " << static_cast<int>(a1.a13) << ", " << static_cast<int>(a1.a14)
      << ", " << static_cast<int>(a1.a15) << ", " << static_cast<int>(a1.a16)
      << ", " << static_cast<int>(a1.a17) << ", " << static_cast<int>(a1.a18)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << ", " << static_cast<int>(a2.a7)
      << ", " << static_cast<int>(a2.a8) << ", " << static_cast<int>(a2.a9)
      << ", " << static_cast<int>(a2.a10) << ", " << static_cast<int>(a2.a11)
      << ", " << static_cast<int>(a2.a12) << ", " << static_cast<int>(a2.a13)
      << ", " << static_cast<int>(a2.a14) << ", " << static_cast<int>(a2.a15)
      << ", " << static_cast<int>(a2.a16) << ", " << static_cast<int>(a2.a17)
      << ", " << static_cast<int>(a2.a18) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << ", " << static_cast<int>(a3.a7) << ", " << static_cast<int>(a3.a8)
      << ", " << static_cast<int>(a3.a9) << ", " << static_cast<int>(a3.a10)
      << ", " << static_cast<int>(a3.a11) << ", " << static_cast<int>(a3.a12)
      << ", " << static_cast<int>(a3.a13) << ", " << static_cast<int>(a3.a14)
      << ", " << static_cast<int>(a3.a15) << ", " << static_cast<int>(a3.a16)
      << ", " << static_cast<int>(a3.a17) << ", " << static_cast<int>(a3.a18)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << ", " << static_cast<int>(a4.a7)
      << ", " << static_cast<int>(a4.a8) << ", " << static_cast<int>(a4.a9)
      << ", " << static_cast<int>(a4.a10) << ", " << static_cast<int>(a4.a11)
      << ", " << static_cast<int>(a4.a12) << ", " << static_cast<int>(a4.a13)
      << ", " << static_cast<int>(a4.a14) << ", " << static_cast<int>(a4.a15)
      << ", " << static_cast<int>(a4.a16) << ", " << static_cast<int>(a4.a17)
      << ", " << static_cast<int>(a4.a18) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << ", " << static_cast<int>(a5.a7) << ", " << static_cast<int>(a5.a8)
      << ", " << static_cast<int>(a5.a9) << ", " << static_cast<int>(a5.a10)
      << ", " << static_cast<int>(a5.a11) << ", " << static_cast<int>(a5.a12)
      << ", " << static_cast<int>(a5.a13) << ", " << static_cast<int>(a5.a14)
      << ", " << static_cast<int>(a5.a15) << ", " << static_cast<int>(a5.a16)
      << ", " << static_cast<int>(a5.a17) << ", " << static_cast<int>(a5.a18)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << ", " << static_cast<int>(a6.a7)
      << ", " << static_cast<int>(a6.a8) << ", " << static_cast<int>(a6.a9)
      << ", " << static_cast<int>(a6.a10) << ", " << static_cast<int>(a6.a11)
      << ", " << static_cast<int>(a6.a12) << ", " << static_cast<int>(a6.a13)
      << ", " << static_cast<int>(a6.a14) << ", " << static_cast<int>(a6.a15)
      << ", " << static_cast<int>(a6.a16) << ", " << static_cast<int>(a6.a17)
      << ", " << static_cast<int>(a6.a18) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << ", " << static_cast<int>(a7.a7) << ", " << static_cast<int>(a7.a8)
      << ", " << static_cast<int>(a7.a9) << ", " << static_cast<int>(a7.a10)
      << ", " << static_cast<int>(a7.a11) << ", " << static_cast<int>(a7.a12)
      << ", " << static_cast<int>(a7.a13) << ", " << static_cast<int>(a7.a14)
      << ", " << static_cast<int>(a7.a15) << ", " << static_cast<int>(a7.a16)
      << ", " << static_cast<int>(a7.a17) << ", " << static_cast<int>(a7.a18)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << ", " << static_cast<int>(a8.a7)
      << ", " << static_cast<int>(a8.a8) << ", " << static_cast<int>(a8.a9)
      << ", " << static_cast<int>(a8.a10) << ", " << static_cast<int>(a8.a11)
      << ", " << static_cast<int>(a8.a12) << ", " << static_cast<int>(a8.a13)
      << ", " << static_cast<int>(a8.a14) << ", " << static_cast<int>(a8.a15)
      << ", " << static_cast<int>(a8.a16) << ", " << static_cast<int>(a8.a17)
      << ", " << static_cast<int>(a8.a18) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << ", " << static_cast<int>(a9.a7) << ", " << static_cast<int>(a9.a8)
      << ", " << static_cast<int>(a9.a9) << ", " << static_cast<int>(a9.a10)
      << ", " << static_cast<int>(a9.a11) << ", " << static_cast<int>(a9.a12)
      << ", " << static_cast<int>(a9.a13) << ", " << static_cast<int>(a9.a14)
      << ", " << static_cast<int>(a9.a15) << ", " << static_cast<int>(a9.a16)
      << ", " << static_cast<int>(a9.a17) << ", " << static_cast<int>(a9.a18)
      << "))"
      << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a0.a5;
  result += a0.a6;
  result += a0.a7;
  result += a0.a8;
  result += a0.a9;
  result += a0.a10;
  result += a0.a11;
  result += a0.a12;
  result += a0.a13;
  result += a0.a14;
  result += a0.a15;
  result += a0.a16;
  result += a0.a17;
  result += a0.a18;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a1.a4;
  result += a1.a5;
  result += a1.a6;
  result += a1.a7;
  result += a1.a8;
  result += a1.a9;
  result += a1.a10;
  result += a1.a11;
  result += a1.a12;
  result += a1.a13;
  result += a1.a14;
  result += a1.a15;
  result += a1.a16;
  result += a1.a17;
  result += a1.a18;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a2.a4;
  result += a2.a5;
  result += a2.a6;
  result += a2.a7;
  result += a2.a8;
  result += a2.a9;
  result += a2.a10;
  result += a2.a11;
  result += a2.a12;
  result += a2.a13;
  result += a2.a14;
  result += a2.a15;
  result += a2.a16;
  result += a2.a17;
  result += a2.a18;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a3.a4;
  result += a3.a5;
  result += a3.a6;
  result += a3.a7;
  result += a3.a8;
  result += a3.a9;
  result += a3.a10;
  result += a3.a11;
  result += a3.a12;
  result += a3.a13;
  result += a3.a14;
  result += a3.a15;
  result += a3.a16;
  result += a3.a17;
  result += a3.a18;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;
  result += a4.a4;
  result += a4.a5;
  result += a4.a6;
  result += a4.a7;
  result += a4.a8;
  result += a4.a9;
  result += a4.a10;
  result += a4.a11;
  result += a4.a12;
  result += a4.a13;
  result += a4.a14;
  result += a4.a15;
  result += a4.a16;
  result += a4.a17;
  result += a4.a18;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a5.a4;
  result += a5.a5;
  result += a5.a6;
  result += a5.a7;
  result += a5.a8;
  result += a5.a9;
  result += a5.a10;
  result += a5.a11;
  result += a5.a12;
  result += a5.a13;
  result += a5.a14;
  result += a5.a15;
  result += a5.a16;
  result += a5.a17;
  result += a5.a18;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a6.a3;
  result += a6.a4;
  result += a6.a5;
  result += a6.a6;
  result += a6.a7;
  result += a6.a8;
  result += a6.a9;
  result += a6.a10;
  result += a6.a11;
  result += a6.a12;
  result += a6.a13;
  result += a6.a14;
  result += a6.a15;
  result += a6.a16;
  result += a6.a17;
  result += a6.a18;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a7.a4;
  result += a7.a5;
  result += a7.a6;
  result += a7.a7;
  result += a7.a8;
  result += a7.a9;
  result += a7.a10;
  result += a7.a11;
  result += a7.a12;
  result += a7.a13;
  result += a7.a14;
  result += a7.a15;
  result += a7.a16;
  result += a7.a17;
  result += a7.a18;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a8.a3;
  result += a8.a4;
  result += a8.a5;
  result += a8.a6;
  result += a8.a7;
  result += a8.a8;
  result += a8.a9;
  result += a8.a10;
  result += a8.a11;
  result += a8.a12;
  result += a8.a13;
  result += a8.a14;
  result += a8.a15;
  result += a8.a16;
  result += a8.a17;
  result += a8.a18;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;
  result += a9.a3;
  result += a9.a4;
  result += a9.a5;
  result += a9.a6;
  result += a9.a7;
  result += a9.a8;
  result += a9.a9;
  result += a9.a10;
  result += a9.a11;
  result += a9.a12;
  result += a9.a13;
  result += a9.a14;
  result += a9.a15;
  result += a9.a16;
  result += a9.a17;
  result += a9.a18;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Argument too big to go into integer registers on arm64.
// The arguments are passed as pointers to copies.
// The amount of arguments exhausts the number of integer registers, such that
// pointers to copies are also passed on the stack.
DART_EXPORT int32_t
PassStruct20BytesHomogeneousInt32x10(Struct20BytesHomogeneousInt32 a0,
                                     Struct20BytesHomogeneousInt32 a1,
                                     Struct20BytesHomogeneousInt32 a2,
                                     Struct20BytesHomogeneousInt32 a3,
                                     Struct20BytesHomogeneousInt32 a4,
                                     Struct20BytesHomogeneousInt32 a5,
                                     Struct20BytesHomogeneousInt32 a6,
                                     Struct20BytesHomogeneousInt32 a7,
                                     Struct20BytesHomogeneousInt32 a8,
                                     Struct20BytesHomogeneousInt32 a9) {
  std::cout << "PassStruct20BytesHomogeneousInt32x10"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << a1.a2 << ", " << a1.a3 << ", " << a1.a4 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << ", " << a2.a3 << ", " << a2.a4
            << "), (" << a3.a0 << ", " << a3.a1 << ", " << a3.a2 << ", "
            << a3.a3 << ", " << a3.a4 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << ", " << a4.a4 << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << ", "
            << a5.a4 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << ", " << a6.a3 << ", " << a6.a4 << "), (" << a7.a0 << ", "
            << a7.a1 << ", " << a7.a2 << ", " << a7.a3 << ", " << a7.a4
            << "), (" << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << ", "
            << a8.a3 << ", " << a8.a4 << "), (" << a9.a0 << ", " << a9.a1
            << ", " << a9.a2 << ", " << a9.a3 << ", " << a9.a4 << "))"
            << "\n";

  int32_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a1.a4;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a2.a4;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a3.a4;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;
  result += a4.a4;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a5.a4;
  result += a6.a0;
  result += a6.a1;
  result += a6.a2;
  result += a6.a3;
  result += a6.a4;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a7.a4;
  result += a8.a0;
  result += a8.a1;
  result += a8.a2;
  result += a8.a3;
  result += a8.a4;
  result += a9.a0;
  result += a9.a1;
  result += a9.a2;
  result += a9.a3;
  result += a9.a4;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Argument too big to go into FPU registers in hardfp and arm64.
DART_EXPORT float PassStruct20BytesHomogeneousFloat(
    Struct20BytesHomogeneousFloat a0) {
  std::cout << "PassStruct20BytesHomogeneousFloat"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << "\n";

  float result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Arguments in FPU registers on arm64.
// 5 struct arguments will exhaust available registers.
DART_EXPORT double PassStruct32BytesHomogeneousDoublex5(
    Struct32BytesHomogeneousDouble a0,
    Struct32BytesHomogeneousDouble a1,
    Struct32BytesHomogeneousDouble a2,
    Struct32BytesHomogeneousDouble a3,
    Struct32BytesHomogeneousDouble a4) {
  std::cout << "PassStruct32BytesHomogeneousDoublex5"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "))"
            << "\n";

  double result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a2.a0;
  result += a2.a1;
  result += a2.a2;
  result += a2.a3;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a4.a0;
  result += a4.a1;
  result += a4.a2;
  result += a4.a3;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Argument too big to go into FPU registers in arm64.
DART_EXPORT double PassStruct40BytesHomogeneousDouble(
    Struct40BytesHomogeneousDouble a0) {
  std::cout << "PassStruct40BytesHomogeneousDouble"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << "\n";

  double result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test 1kb struct.
DART_EXPORT uint64_t
PassStruct1024BytesHomogeneousUint64(Struct1024BytesHomogeneousUint64 a0) {
  std::cout << "PassStruct1024BytesHomogeneousUint64"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << ", " << a0.a5 << ", " << a0.a6 << ", " << a0.a7
            << ", " << a0.a8 << ", " << a0.a9 << ", " << a0.a10 << ", "
            << a0.a11 << ", " << a0.a12 << ", " << a0.a13 << ", " << a0.a14
            << ", " << a0.a15 << ", " << a0.a16 << ", " << a0.a17 << ", "
            << a0.a18 << ", " << a0.a19 << ", " << a0.a20 << ", " << a0.a21
            << ", " << a0.a22 << ", " << a0.a23 << ", " << a0.a24 << ", "
            << a0.a25 << ", " << a0.a26 << ", " << a0.a27 << ", " << a0.a28
            << ", " << a0.a29 << ", " << a0.a30 << ", " << a0.a31 << ", "
            << a0.a32 << ", " << a0.a33 << ", " << a0.a34 << ", " << a0.a35
            << ", " << a0.a36 << ", " << a0.a37 << ", " << a0.a38 << ", "
            << a0.a39 << ", " << a0.a40 << ", " << a0.a41 << ", " << a0.a42
            << ", " << a0.a43 << ", " << a0.a44 << ", " << a0.a45 << ", "
            << a0.a46 << ", " << a0.a47 << ", " << a0.a48 << ", " << a0.a49
            << ", " << a0.a50 << ", " << a0.a51 << ", " << a0.a52 << ", "
            << a0.a53 << ", " << a0.a54 << ", " << a0.a55 << ", " << a0.a56
            << ", " << a0.a57 << ", " << a0.a58 << ", " << a0.a59 << ", "
            << a0.a60 << ", " << a0.a61 << ", " << a0.a62 << ", " << a0.a63
            << ", " << a0.a64 << ", " << a0.a65 << ", " << a0.a66 << ", "
            << a0.a67 << ", " << a0.a68 << ", " << a0.a69 << ", " << a0.a70
            << ", " << a0.a71 << ", " << a0.a72 << ", " << a0.a73 << ", "
            << a0.a74 << ", " << a0.a75 << ", " << a0.a76 << ", " << a0.a77
            << ", " << a0.a78 << ", " << a0.a79 << ", " << a0.a80 << ", "
            << a0.a81 << ", " << a0.a82 << ", " << a0.a83 << ", " << a0.a84
            << ", " << a0.a85 << ", " << a0.a86 << ", " << a0.a87 << ", "
            << a0.a88 << ", " << a0.a89 << ", " << a0.a90 << ", " << a0.a91
            << ", " << a0.a92 << ", " << a0.a93 << ", " << a0.a94 << ", "
            << a0.a95 << ", " << a0.a96 << ", " << a0.a97 << ", " << a0.a98
            << ", " << a0.a99 << ", " << a0.a100 << ", " << a0.a101 << ", "
            << a0.a102 << ", " << a0.a103 << ", " << a0.a104 << ", " << a0.a105
            << ", " << a0.a106 << ", " << a0.a107 << ", " << a0.a108 << ", "
            << a0.a109 << ", " << a0.a110 << ", " << a0.a111 << ", " << a0.a112
            << ", " << a0.a113 << ", " << a0.a114 << ", " << a0.a115 << ", "
            << a0.a116 << ", " << a0.a117 << ", " << a0.a118 << ", " << a0.a119
            << ", " << a0.a120 << ", " << a0.a121 << ", " << a0.a122 << ", "
            << a0.a123 << ", " << a0.a124 << ", " << a0.a125 << ", " << a0.a126
            << ", " << a0.a127 << "))"
            << "\n";

  uint64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a0.a5;
  result += a0.a6;
  result += a0.a7;
  result += a0.a8;
  result += a0.a9;
  result += a0.a10;
  result += a0.a11;
  result += a0.a12;
  result += a0.a13;
  result += a0.a14;
  result += a0.a15;
  result += a0.a16;
  result += a0.a17;
  result += a0.a18;
  result += a0.a19;
  result += a0.a20;
  result += a0.a21;
  result += a0.a22;
  result += a0.a23;
  result += a0.a24;
  result += a0.a25;
  result += a0.a26;
  result += a0.a27;
  result += a0.a28;
  result += a0.a29;
  result += a0.a30;
  result += a0.a31;
  result += a0.a32;
  result += a0.a33;
  result += a0.a34;
  result += a0.a35;
  result += a0.a36;
  result += a0.a37;
  result += a0.a38;
  result += a0.a39;
  result += a0.a40;
  result += a0.a41;
  result += a0.a42;
  result += a0.a43;
  result += a0.a44;
  result += a0.a45;
  result += a0.a46;
  result += a0.a47;
  result += a0.a48;
  result += a0.a49;
  result += a0.a50;
  result += a0.a51;
  result += a0.a52;
  result += a0.a53;
  result += a0.a54;
  result += a0.a55;
  result += a0.a56;
  result += a0.a57;
  result += a0.a58;
  result += a0.a59;
  result += a0.a60;
  result += a0.a61;
  result += a0.a62;
  result += a0.a63;
  result += a0.a64;
  result += a0.a65;
  result += a0.a66;
  result += a0.a67;
  result += a0.a68;
  result += a0.a69;
  result += a0.a70;
  result += a0.a71;
  result += a0.a72;
  result += a0.a73;
  result += a0.a74;
  result += a0.a75;
  result += a0.a76;
  result += a0.a77;
  result += a0.a78;
  result += a0.a79;
  result += a0.a80;
  result += a0.a81;
  result += a0.a82;
  result += a0.a83;
  result += a0.a84;
  result += a0.a85;
  result += a0.a86;
  result += a0.a87;
  result += a0.a88;
  result += a0.a89;
  result += a0.a90;
  result += a0.a91;
  result += a0.a92;
  result += a0.a93;
  result += a0.a94;
  result += a0.a95;
  result += a0.a96;
  result += a0.a97;
  result += a0.a98;
  result += a0.a99;
  result += a0.a100;
  result += a0.a101;
  result += a0.a102;
  result += a0.a103;
  result += a0.a104;
  result += a0.a105;
  result += a0.a106;
  result += a0.a107;
  result += a0.a108;
  result += a0.a109;
  result += a0.a110;
  result += a0.a111;
  result += a0.a112;
  result += a0.a113;
  result += a0.a114;
  result += a0.a115;
  result += a0.a116;
  result += a0.a117;
  result += a0.a118;
  result += a0.a119;
  result += a0.a120;
  result += a0.a121;
  result += a0.a122;
  result += a0.a123;
  result += a0.a124;
  result += a0.a125;
  result += a0.a126;
  result += a0.a127;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Tests the alignment of structs in FPU registers and backfilling.
DART_EXPORT float PassFloatStruct16BytesHomogeneousFloatFloatStruct1(
    float a0,
    Struct16BytesHomogeneousFloat a1,
    float a2,
    Struct16BytesHomogeneousFloat a3,
    float a4,
    Struct16BytesHomogeneousFloat a5,
    float a6,
    Struct16BytesHomogeneousFloat a7,
    float a8) {
  std::cout << "PassFloatStruct16BytesHomogeneousFloatFloatStruct1"
            << "(" << a0 << ", (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2
            << ", " << a1.a3 << "), " << a2 << ", (" << a3.a0 << ", " << a3.a1
            << ", " << a3.a2 << ", " << a3.a3 << "), " << a4 << ", (" << a5.a0
            << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), " << a6
            << ", (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), " << a8 << ")"
            << "\n";

  float result = 0;

  result += a0;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a4;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a6;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a8;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Tests the alignment of structs in FPU registers and backfilling.
DART_EXPORT double PassFloatStruct32BytesHomogeneousDoubleFloatStruct(
    float a0,
    Struct32BytesHomogeneousDouble a1,
    float a2,
    Struct32BytesHomogeneousDouble a3,
    float a4,
    Struct32BytesHomogeneousDouble a5,
    float a6,
    Struct32BytesHomogeneousDouble a7,
    float a8) {
  std::cout << "PassFloatStruct32BytesHomogeneousDoubleFloatStruct"
            << "(" << a0 << ", (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2
            << ", " << a1.a3 << "), " << a2 << ", (" << a3.a0 << ", " << a3.a1
            << ", " << a3.a2 << ", " << a3.a3 << "), " << a4 << ", (" << a5.a0
            << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), " << a6
            << ", (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), " << a8 << ")"
            << "\n";

  double result = 0;

  result += a0;
  result += a1.a0;
  result += a1.a1;
  result += a1.a2;
  result += a1.a3;
  result += a2;
  result += a3.a0;
  result += a3.a1;
  result += a3.a2;
  result += a3.a3;
  result += a4;
  result += a5.a0;
  result += a5.a1;
  result += a5.a2;
  result += a5.a3;
  result += a6;
  result += a7.a0;
  result += a7.a1;
  result += a7.a2;
  result += a7.a3;
  result += a8;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Tests the alignment of structs in integers registers and on the stack.
// Arm32 aligns this struct at 8.
// Also, arm32 allocates the second struct partially in registers, partially
// on stack.
// Test backfilling of integer registers.
DART_EXPORT double PassInt8Struct16BytesMixedInt8Struct16BytesMixedIn(
    int8_t a0,
    Struct16BytesMixed a1,
    int8_t a2,
    Struct16BytesMixed a3,
    int8_t a4,
    Struct16BytesMixed a5,
    int8_t a6,
    Struct16BytesMixed a7,
    int8_t a8) {
  std::cout << "PassInt8Struct16BytesMixedInt8Struct16BytesMixedIn"
            << "(" << static_cast<int>(a0) << ", (" << a1.a0 << ", " << a1.a1
            << "), " << static_cast<int>(a2) << ", (" << a3.a0 << ", " << a3.a1
            << "), " << static_cast<int>(a4) << ", (" << a5.a0 << ", " << a5.a1
            << "), " << static_cast<int>(a6) << ", (" << a7.a0 << ", " << a7.a1
            << "), " << static_cast<int>(a8) << ")"
            << "\n";

  double result = 0;

  result += a0;
  result += a1.a0;
  result += a1.a1;
  result += a2;
  result += a3.a0;
  result += a3.a1;
  result += a4;
  result += a5.a0;
  result += a5.a1;
  result += a6;
  result += a7.a0;
  result += a7.a1;
  result += a8;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On Linux x64, it will exhaust xmm registers first, after 6 doubles and 2
// structs. The rest of the structs will go on the stack.
// The int will be backfilled into the int register.
DART_EXPORT double PassDoublex6Struct16BytesMixedx4Int32(double a0,
                                                         double a1,
                                                         double a2,
                                                         double a3,
                                                         double a4,
                                                         double a5,
                                                         Struct16BytesMixed a6,
                                                         Struct16BytesMixed a7,
                                                         Struct16BytesMixed a8,
                                                         Struct16BytesMixed a9,
                                                         int32_t a10) {
  std::cout << "PassDoublex6Struct16BytesMixedx4Int32"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", (" << a6.a0 << ", " << a6.a1 << "), (" << a7.a0
            << ", " << a7.a1 << "), (" << a8.a0 << ", " << a8.a1 << "), ("
            << a9.a0 << ", " << a9.a1 << "), " << a10 << ")"
            << "\n";

  double result = 0;

  result += a0;
  result += a1;
  result += a2;
  result += a3;
  result += a4;
  result += a5;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8.a0;
  result += a8.a1;
  result += a9.a0;
  result += a9.a1;
  result += a10;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On Linux x64, it will exhaust int registers first.
// The rest of the structs will go on the stack.
// The double will be backfilled into the xmm register.
DART_EXPORT double PassInt32x4Struct16BytesMixedx4Double(int32_t a0,
                                                         int32_t a1,
                                                         int32_t a2,
                                                         int32_t a3,
                                                         Struct16BytesMixed a4,
                                                         Struct16BytesMixed a5,
                                                         Struct16BytesMixed a6,
                                                         Struct16BytesMixed a7,
                                                         double a8) {
  std::cout << "PassInt32x4Struct16BytesMixedx4Double"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", ("
            << a4.a0 << ", " << a4.a1 << "), (" << a5.a0 << ", " << a5.a1
            << "), (" << a6.a0 << ", " << a6.a1 << "), (" << a7.a0 << ", "
            << a7.a1 << "), " << a8 << ")"
            << "\n";

  double result = 0;

  result += a0;
  result += a1;
  result += a2;
  result += a3;
  result += a4.a0;
  result += a4.a1;
  result += a5.a0;
  result += a5.a1;
  result += a6.a0;
  result += a6.a1;
  result += a7.a0;
  result += a7.a1;
  result += a8;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// On various architectures, first struct is allocated on stack.
// Check that the other two arguments are allocated on registers.
DART_EXPORT double PassStruct40BytesHomogeneousDoubleStruct4BytesHomo(
    Struct40BytesHomogeneousDouble a0,
    Struct4BytesHomogeneousInt16 a1,
    Struct8BytesHomogeneousFloat a2) {
  std::cout << "PassStruct40BytesHomogeneousDoubleStruct4BytesHomo"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "), (" << a1.a0 << ", " << a1.a1 << "), ("
            << a2.a0 << ", " << a2.a1 << "))"
            << "\n";

  double result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;
  result += a0.a3;
  result += a0.a4;
  result += a1.a0;
  result += a1.a1;
  result += a2.a0;
  result += a2.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT double PassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int(
    int32_t a0,
    int32_t a1,
    int32_t a2,
    int32_t a3,
    int32_t a4,
    int32_t a5,
    int32_t a6,
    int32_t a7,
    double a8,
    double a9,
    double a10,
    double a11,
    double a12,
    double a13,
    double a14,
    double a15,
    int64_t a16,
    int8_t a17,
    Struct1ByteInt a18,
    int64_t a19,
    int8_t a20,
    Struct4BytesHomogeneousInt16 a21,
    int64_t a22,
    int8_t a23,
    Struct8BytesInt a24,
    int64_t a25,
    int8_t a26,
    Struct8BytesHomogeneousFloat a27,
    int64_t a28,
    int8_t a29,
    Struct8BytesMixed a30,
    int64_t a31,
    int8_t a32,
    StructAlignmentInt16 a33,
    int64_t a34,
    int8_t a35,
    StructAlignmentInt32 a36,
    int64_t a37,
    int8_t a38,
    StructAlignmentInt64 a39) {
  std::cout << "PassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", " << a8 << ", "
            << a9 << ", " << a10 << ", " << a11 << ", " << a12 << ", " << a13
            << ", " << a14 << ", " << a15 << ", " << a16 << ", "
            << static_cast<int>(a17) << ", (" << static_cast<int>(a18.a0)
            << "), " << a19 << ", " << static_cast<int>(a20) << ", (" << a21.a0
            << ", " << a21.a1 << "), " << a22 << ", " << static_cast<int>(a23)
            << ", (" << a24.a0 << ", " << a24.a1 << ", " << a24.a2 << "), "
            << a25 << ", " << static_cast<int>(a26) << ", (" << a27.a0 << ", "
            << a27.a1 << "), " << a28 << ", " << static_cast<int>(a29) << ", ("
            << a30.a0 << ", " << a30.a1 << ", " << a30.a2 << "), " << a31
            << ", " << static_cast<int>(a32) << ", ("
            << static_cast<int>(a33.a0) << ", " << a33.a1 << ", "
            << static_cast<int>(a33.a2) << "), " << a34 << ", "
            << static_cast<int>(a35) << ", (" << static_cast<int>(a36.a0)
            << ", " << a36.a1 << ", " << static_cast<int>(a36.a2) << "), "
            << a37 << ", " << static_cast<int>(a38) << ", ("
            << static_cast<int>(a39.a0) << ", " << a39.a1 << ", "
            << static_cast<int>(a39.a2) << "))"
            << "\n";

  double result = 0;

  result += a0;
  result += a1;
  result += a2;
  result += a3;
  result += a4;
  result += a5;
  result += a6;
  result += a7;
  result += a8;
  result += a9;
  result += a10;
  result += a11;
  result += a12;
  result += a13;
  result += a14;
  result += a15;
  result += a16;
  result += a17;
  result += a18.a0;
  result += a19;
  result += a20;
  result += a21.a0;
  result += a21.a1;
  result += a22;
  result += a23;
  result += a24.a0;
  result += a24.a1;
  result += a24.a2;
  result += a25;
  result += a26;
  result += a27.a0;
  result += a27.a1;
  result += a28;
  result += a29;
  result += a30.a0;
  result += a30.a1;
  result += a30.a2;
  result += a31;
  result += a32;
  result += a33.a0;
  result += a33.a1;
  result += a33.a2;
  result += a34;
  result += a35;
  result += a36.a0;
  result += a36.a1;
  result += a36.a2;
  result += a37;
  result += a38;
  result += a39.a0;
  result += a39.a1;
  result += a39.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT int64_t PassStructAlignmentInt16(StructAlignmentInt16 a0) {
  std::cout << "PassStructAlignmentInt16"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 32 byte int within struct.
DART_EXPORT int64_t PassStructAlignmentInt32(StructAlignmentInt32 a0) {
  std::cout << "PassStructAlignmentInt32"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 64 byte int within struct.
DART_EXPORT int64_t PassStructAlignmentInt64(StructAlignmentInt64 a0) {
  std::cout << "PassStructAlignmentInt64"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << "\n";

  int64_t result = 0;

  result += a0.a0;
  result += a0.a1;
  result += a0.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust registers on all platforms.
DART_EXPORT int64_t PassStruct8BytesNestedIntx10(Struct8BytesNestedInt a0,
                                                 Struct8BytesNestedInt a1,
                                                 Struct8BytesNestedInt a2,
                                                 Struct8BytesNestedInt a3,
                                                 Struct8BytesNestedInt a4,
                                                 Struct8BytesNestedInt a5,
                                                 Struct8BytesNestedInt a6,
                                                 Struct8BytesNestedInt a7,
                                                 Struct8BytesNestedInt a8,
                                                 Struct8BytesNestedInt a9) {
  std::cout << "PassStruct8BytesNestedIntx10"
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ", " << a0.a1.a1 << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1
            << "), (" << a1.a1.a0 << ", " << a1.a1.a1 << ")), ((" << a2.a0.a0
            << ", " << a2.a0.a1 << "), (" << a2.a1.a0 << ", " << a2.a1.a1
            << ")), ((" << a3.a0.a0 << ", " << a3.a0.a1 << "), (" << a3.a1.a0
            << ", " << a3.a1.a1 << ")), ((" << a4.a0.a0 << ", " << a4.a0.a1
            << "), (" << a4.a1.a0 << ", " << a4.a1.a1 << ")), ((" << a5.a0.a0
            << ", " << a5.a0.a1 << "), (" << a5.a1.a0 << ", " << a5.a1.a1
            << ")), ((" << a6.a0.a0 << ", " << a6.a0.a1 << "), (" << a6.a1.a0
            << ", " << a6.a1.a1 << ")), ((" << a7.a0.a0 << ", " << a7.a0.a1
            << "), (" << a7.a1.a0 << ", " << a7.a1.a1 << ")), ((" << a8.a0.a0
            << ", " << a8.a0.a1 << "), (" << a8.a1.a0 << ", " << a8.a1.a1
            << ")), ((" << a9.a0.a0 << ", " << a9.a0.a1 << "), (" << a9.a1.a0
            << ", " << a9.a1.a1 << ")))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0;
  result += a0.a0.a1;
  result += a0.a1.a0;
  result += a0.a1.a1;
  result += a1.a0.a0;
  result += a1.a0.a1;
  result += a1.a1.a0;
  result += a1.a1.a1;
  result += a2.a0.a0;
  result += a2.a0.a1;
  result += a2.a1.a0;
  result += a2.a1.a1;
  result += a3.a0.a0;
  result += a3.a0.a1;
  result += a3.a1.a0;
  result += a3.a1.a1;
  result += a4.a0.a0;
  result += a4.a0.a1;
  result += a4.a1.a0;
  result += a4.a1.a1;
  result += a5.a0.a0;
  result += a5.a0.a1;
  result += a5.a1.a0;
  result += a5.a1.a1;
  result += a6.a0.a0;
  result += a6.a0.a1;
  result += a6.a1.a0;
  result += a6.a1.a1;
  result += a7.a0.a0;
  result += a7.a0.a1;
  result += a7.a1.a0;
  result += a7.a1.a1;
  result += a8.a0.a0;
  result += a8.a0.a1;
  result += a8.a1.a0;
  result += a8.a1.a1;
  result += a9.a0.a0;
  result += a9.a0.a1;
  result += a9.a1.a0;
  result += a9.a1.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust fpu registers on all platforms.
DART_EXPORT float PassStruct8BytesNestedFloatx10(Struct8BytesNestedFloat a0,
                                                 Struct8BytesNestedFloat a1,
                                                 Struct8BytesNestedFloat a2,
                                                 Struct8BytesNestedFloat a3,
                                                 Struct8BytesNestedFloat a4,
                                                 Struct8BytesNestedFloat a5,
                                                 Struct8BytesNestedFloat a6,
                                                 Struct8BytesNestedFloat a7,
                                                 Struct8BytesNestedFloat a8,
                                                 Struct8BytesNestedFloat a9) {
  std::cout << "PassStruct8BytesNestedFloatx10"
            << "(((" << a0.a0.a0 << "), (" << a0.a1.a0 << ")), ((" << a1.a0.a0
            << "), (" << a1.a1.a0 << ")), ((" << a2.a0.a0 << "), (" << a2.a1.a0
            << ")), ((" << a3.a0.a0 << "), (" << a3.a1.a0 << ")), (("
            << a4.a0.a0 << "), (" << a4.a1.a0 << ")), ((" << a5.a0.a0 << "), ("
            << a5.a1.a0 << ")), ((" << a6.a0.a0 << "), (" << a6.a1.a0
            << ")), ((" << a7.a0.a0 << "), (" << a7.a1.a0 << ")), (("
            << a8.a0.a0 << "), (" << a8.a1.a0 << ")), ((" << a9.a0.a0 << "), ("
            << a9.a1.a0 << ")))"
            << "\n";

  float result = 0;

  result += a0.a0.a0;
  result += a0.a1.a0;
  result += a1.a0.a0;
  result += a1.a1.a0;
  result += a2.a0.a0;
  result += a2.a1.a0;
  result += a3.a0.a0;
  result += a3.a1.a0;
  result += a4.a0.a0;
  result += a4.a1.a0;
  result += a5.a0.a0;
  result += a5.a1.a0;
  result += a6.a0.a0;
  result += a6.a1.a0;
  result += a7.a0.a0;
  result += a7.a1.a0;
  result += a8.a0.a0;
  result += a8.a1.a0;
  result += a9.a0.a0;
  result += a9.a1.a0;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust fpu registers on all platforms.
// The nesting is irregular, testing homogenous float rules on arm and arm64,
// and the fpu register usage on x64.
DART_EXPORT float PassStruct8BytesNestedFloat2x10(Struct8BytesNestedFloat2 a0,
                                                  Struct8BytesNestedFloat2 a1,
                                                  Struct8BytesNestedFloat2 a2,
                                                  Struct8BytesNestedFloat2 a3,
                                                  Struct8BytesNestedFloat2 a4,
                                                  Struct8BytesNestedFloat2 a5,
                                                  Struct8BytesNestedFloat2 a6,
                                                  Struct8BytesNestedFloat2 a7,
                                                  Struct8BytesNestedFloat2 a8,
                                                  Struct8BytesNestedFloat2 a9) {
  std::cout << "PassStruct8BytesNestedFloat2x10"
            << "(((" << a0.a0.a0 << "), " << a0.a1 << "), ((" << a1.a0.a0
            << "), " << a1.a1 << "), ((" << a2.a0.a0 << "), " << a2.a1
            << "), ((" << a3.a0.a0 << "), " << a3.a1 << "), ((" << a4.a0.a0
            << "), " << a4.a1 << "), ((" << a5.a0.a0 << "), " << a5.a1
            << "), ((" << a6.a0.a0 << "), " << a6.a1 << "), ((" << a7.a0.a0
            << "), " << a7.a1 << "), ((" << a8.a0.a0 << "), " << a8.a1
            << "), ((" << a9.a0.a0 << "), " << a9.a1 << "))"
            << "\n";

  float result = 0;

  result += a0.a0.a0;
  result += a0.a1;
  result += a1.a0.a0;
  result += a1.a1;
  result += a2.a0.a0;
  result += a2.a1;
  result += a3.a0.a0;
  result += a3.a1;
  result += a4.a0.a0;
  result += a4.a1;
  result += a5.a0.a0;
  result += a5.a1;
  result += a6.a0.a0;
  result += a6.a1;
  result += a7.a0.a0;
  result += a7.a1;
  result += a8.a0.a0;
  result += a8.a1;
  result += a9.a0.a0;
  result += a9.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust all registers on all platforms.
DART_EXPORT double PassStruct8BytesNestedMixedx10(Struct8BytesNestedMixed a0,
                                                  Struct8BytesNestedMixed a1,
                                                  Struct8BytesNestedMixed a2,
                                                  Struct8BytesNestedMixed a3,
                                                  Struct8BytesNestedMixed a4,
                                                  Struct8BytesNestedMixed a5,
                                                  Struct8BytesNestedMixed a6,
                                                  Struct8BytesNestedMixed a7,
                                                  Struct8BytesNestedMixed a8,
                                                  Struct8BytesNestedMixed a9) {
  std::cout << "PassStruct8BytesNestedMixedx10"
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1 << "), (" << a1.a1.a0
            << ")), ((" << a2.a0.a0 << ", " << a2.a0.a1 << "), (" << a2.a1.a0
            << ")), ((" << a3.a0.a0 << ", " << a3.a0.a1 << "), (" << a3.a1.a0
            << ")), ((" << a4.a0.a0 << ", " << a4.a0.a1 << "), (" << a4.a1.a0
            << ")), ((" << a5.a0.a0 << ", " << a5.a0.a1 << "), (" << a5.a1.a0
            << ")), ((" << a6.a0.a0 << ", " << a6.a0.a1 << "), (" << a6.a1.a0
            << ")), ((" << a7.a0.a0 << ", " << a7.a0.a1 << "), (" << a7.a1.a0
            << ")), ((" << a8.a0.a0 << ", " << a8.a0.a1 << "), (" << a8.a1.a0
            << ")), ((" << a9.a0.a0 << ", " << a9.a0.a1 << "), (" << a9.a1.a0
            << ")))"
            << "\n";

  double result = 0;

  result += a0.a0.a0;
  result += a0.a0.a1;
  result += a0.a1.a0;
  result += a1.a0.a0;
  result += a1.a0.a1;
  result += a1.a1.a0;
  result += a2.a0.a0;
  result += a2.a0.a1;
  result += a2.a1.a0;
  result += a3.a0.a0;
  result += a3.a0.a1;
  result += a3.a1.a0;
  result += a4.a0.a0;
  result += a4.a0.a1;
  result += a4.a1.a0;
  result += a5.a0.a0;
  result += a5.a0.a1;
  result += a5.a1.a0;
  result += a6.a0.a0;
  result += a6.a0.a1;
  result += a6.a1.a0;
  result += a7.a0.a0;
  result += a7.a0.a1;
  result += a7.a1.a0;
  result += a8.a0.a0;
  result += a8.a0.a1;
  result += a8.a1.a0;
  result += a9.a0.a0;
  result += a9.a0.a1;
  result += a9.a1.a0;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Deeper nested struct to test recursive member access.
DART_EXPORT int64_t PassStruct16BytesNestedIntx2(Struct16BytesNestedInt a0,
                                                 Struct16BytesNestedInt a1) {
  std::cout << "PassStruct16BytesNestedIntx2"
            << "((((" << a0.a0.a0.a0 << ", " << a0.a0.a0.a1 << "), ("
            << a0.a0.a1.a0 << ", " << a0.a0.a1.a1 << ")), ((" << a0.a1.a0.a0
            << ", " << a0.a1.a0.a1 << "), (" << a0.a1.a1.a0 << ", "
            << a0.a1.a1.a1 << "))), (((" << a1.a0.a0.a0 << ", " << a1.a0.a0.a1
            << "), (" << a1.a0.a1.a0 << ", " << a1.a0.a1.a1 << ")), (("
            << a1.a1.a0.a0 << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0
            << ", " << a1.a1.a1.a1 << "))))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0.a0;
  result += a0.a0.a0.a1;
  result += a0.a0.a1.a0;
  result += a0.a0.a1.a1;
  result += a0.a1.a0.a0;
  result += a0.a1.a0.a1;
  result += a0.a1.a1.a0;
  result += a0.a1.a1.a1;
  result += a1.a0.a0.a0;
  result += a1.a0.a0.a1;
  result += a1.a0.a1.a0;
  result += a1.a0.a1.a1;
  result += a1.a1.a0.a0;
  result += a1.a1.a0.a1;
  result += a1.a1.a1.a0;
  result += a1.a1.a1.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Even deeper nested struct to test recursive member access.
DART_EXPORT int64_t PassStruct32BytesNestedIntx2(Struct32BytesNestedInt a0,
                                                 Struct32BytesNestedInt a1) {
  std::cout << "PassStruct32BytesNestedIntx2"
            << "(((((" << a0.a0.a0.a0.a0 << ", " << a0.a0.a0.a0.a1 << "), ("
            << a0.a0.a0.a1.a0 << ", " << a0.a0.a0.a1.a1 << ")), (("
            << a0.a0.a1.a0.a0 << ", " << a0.a0.a1.a0.a1 << "), ("
            << a0.a0.a1.a1.a0 << ", " << a0.a0.a1.a1.a1 << "))), ((("
            << a0.a1.a0.a0.a0 << ", " << a0.a1.a0.a0.a1 << "), ("
            << a0.a1.a0.a1.a0 << ", " << a0.a1.a0.a1.a1 << ")), (("
            << a0.a1.a1.a0.a0 << ", " << a0.a1.a1.a0.a1 << "), ("
            << a0.a1.a1.a1.a0 << ", " << a0.a1.a1.a1.a1 << ")))), (((("
            << a1.a0.a0.a0.a0 << ", " << a1.a0.a0.a0.a1 << "), ("
            << a1.a0.a0.a1.a0 << ", " << a1.a0.a0.a1.a1 << ")), (("
            << a1.a0.a1.a0.a0 << ", " << a1.a0.a1.a0.a1 << "), ("
            << a1.a0.a1.a1.a0 << ", " << a1.a0.a1.a1.a1 << "))), ((("
            << a1.a1.a0.a0.a0 << ", " << a1.a1.a0.a0.a1 << "), ("
            << a1.a1.a0.a1.a0 << ", " << a1.a1.a0.a1.a1 << ")), (("
            << a1.a1.a1.a0.a0 << ", " << a1.a1.a1.a0.a1 << "), ("
            << a1.a1.a1.a1.a0 << ", " << a1.a1.a1.a1.a1 << ")))))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0.a0.a0;
  result += a0.a0.a0.a0.a1;
  result += a0.a0.a0.a1.a0;
  result += a0.a0.a0.a1.a1;
  result += a0.a0.a1.a0.a0;
  result += a0.a0.a1.a0.a1;
  result += a0.a0.a1.a1.a0;
  result += a0.a0.a1.a1.a1;
  result += a0.a1.a0.a0.a0;
  result += a0.a1.a0.a0.a1;
  result += a0.a1.a0.a1.a0;
  result += a0.a1.a0.a1.a1;
  result += a0.a1.a1.a0.a0;
  result += a0.a1.a1.a0.a1;
  result += a0.a1.a1.a1.a0;
  result += a0.a1.a1.a1.a1;
  result += a1.a0.a0.a0.a0;
  result += a1.a0.a0.a0.a1;
  result += a1.a0.a0.a1.a0;
  result += a1.a0.a0.a1.a1;
  result += a1.a0.a1.a0.a0;
  result += a1.a0.a1.a0.a1;
  result += a1.a0.a1.a1.a0;
  result += a1.a0.a1.a1.a1;
  result += a1.a1.a0.a0.a0;
  result += a1.a1.a0.a0.a1;
  result += a1.a1.a0.a1.a0;
  result += a1.a1.a0.a1.a1;
  result += a1.a1.a1.a0.a0;
  result += a1.a1.a1.a0.a1;
  result += a1.a1.a1.a1.a0;
  result += a1.a1.a1.a1.a1;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 16 byte int.
DART_EXPORT int64_t PassStructNestedIntStructAlignmentInt16(
    StructNestedIntStructAlignmentInt16 a0) {
  std::cout << "PassStructNestedIntStructAlignmentInt16"
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0;
  result += a0.a0.a1;
  result += a0.a0.a2;
  result += a0.a1.a0;
  result += a0.a1.a1;
  result += a0.a1.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 32 byte int.
DART_EXPORT int64_t PassStructNestedIntStructAlignmentInt32(
    StructNestedIntStructAlignmentInt32 a0) {
  std::cout << "PassStructNestedIntStructAlignmentInt32"
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0;
  result += a0.a0.a1;
  result += a0.a0.a2;
  result += a0.a1.a0;
  result += a0.a1.a1;
  result += a0.a1.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 64 byte int.
DART_EXPORT int64_t PassStructNestedIntStructAlignmentInt64(
    StructNestedIntStructAlignmentInt64 a0) {
  std::cout << "PassStructNestedIntStructAlignmentInt64"
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << "\n";

  int64_t result = 0;

  result += a0.a0.a0;
  result += a0.a0.a1;
  result += a0.a0.a2;
  result += a0.a1.a0;
  result += a0.a1.a1;
  result += a0.a1.a2;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Return big irregular struct as smoke test.
DART_EXPORT double PassStructNestedIrregularEvenBiggerx4(
    StructNestedIrregularEvenBigger a0,
    StructNestedIrregularEvenBigger a1,
    StructNestedIrregularEvenBigger a2,
    StructNestedIrregularEvenBigger a3) {
  std::cout
      << "PassStructNestedIrregularEvenBiggerx4"
      << "((" << a0.a0 << ", ((" << a0.a1.a0.a0 << ", ((" << a0.a1.a0.a1.a0.a0
      << ", " << a0.a1.a0.a1.a0.a1 << "), (" << a0.a1.a0.a1.a1.a0 << ")), "
      << a0.a1.a0.a2 << ", ((" << a0.a1.a0.a3.a0.a0 << "), " << a0.a1.a0.a3.a1
      << "), " << a0.a1.a0.a4 << ", ((" << a0.a1.a0.a5.a0.a0 << "), ("
      << a0.a1.a0.a5.a1.a0 << ")), " << a0.a1.a0.a6 << "), ((" << a0.a1.a1.a0.a0
      << ", " << a0.a1.a1.a0.a1 << "), (" << a0.a1.a1.a1.a0 << ")), "
      << a0.a1.a2 << ", " << a0.a1.a3 << "), ((" << a0.a2.a0.a0 << ", (("
      << a0.a2.a0.a1.a0.a0 << ", " << a0.a2.a0.a1.a0.a1 << "), ("
      << a0.a2.a0.a1.a1.a0 << ")), " << a0.a2.a0.a2 << ", (("
      << a0.a2.a0.a3.a0.a0 << "), " << a0.a2.a0.a3.a1 << "), " << a0.a2.a0.a4
      << ", ((" << a0.a2.a0.a5.a0.a0 << "), (" << a0.a2.a0.a5.a1.a0 << ")), "
      << a0.a2.a0.a6 << "), ((" << a0.a2.a1.a0.a0 << ", " << a0.a2.a1.a0.a1
      << "), (" << a0.a2.a1.a1.a0 << ")), " << a0.a2.a2 << ", " << a0.a2.a3
      << "), " << a0.a3 << "), (" << a1.a0 << ", ((" << a1.a1.a0.a0 << ", (("
      << a1.a1.a0.a1.a0.a0 << ", " << a1.a1.a0.a1.a0.a1 << "), ("
      << a1.a1.a0.a1.a1.a0 << ")), " << a1.a1.a0.a2 << ", (("
      << a1.a1.a0.a3.a0.a0 << "), " << a1.a1.a0.a3.a1 << "), " << a1.a1.a0.a4
      << ", ((" << a1.a1.a0.a5.a0.a0 << "), (" << a1.a1.a0.a5.a1.a0 << ")), "
      << a1.a1.a0.a6 << "), ((" << a1.a1.a1.a0.a0 << ", " << a1.a1.a1.a0.a1
      << "), (" << a1.a1.a1.a1.a0 << ")), " << a1.a1.a2 << ", " << a1.a1.a3
      << "), ((" << a1.a2.a0.a0 << ", ((" << a1.a2.a0.a1.a0.a0 << ", "
      << a1.a2.a0.a1.a0.a1 << "), (" << a1.a2.a0.a1.a1.a0 << ")), "
      << a1.a2.a0.a2 << ", ((" << a1.a2.a0.a3.a0.a0 << "), " << a1.a2.a0.a3.a1
      << "), " << a1.a2.a0.a4 << ", ((" << a1.a2.a0.a5.a0.a0 << "), ("
      << a1.a2.a0.a5.a1.a0 << ")), " << a1.a2.a0.a6 << "), ((" << a1.a2.a1.a0.a0
      << ", " << a1.a2.a1.a0.a1 << "), (" << a1.a2.a1.a1.a0 << ")), "
      << a1.a2.a2 << ", " << a1.a2.a3 << "), " << a1.a3 << "), (" << a2.a0
      << ", ((" << a2.a1.a0.a0 << ", ((" << a2.a1.a0.a1.a0.a0 << ", "
      << a2.a1.a0.a1.a0.a1 << "), (" << a2.a1.a0.a1.a1.a0 << ")), "
      << a2.a1.a0.a2 << ", ((" << a2.a1.a0.a3.a0.a0 << "), " << a2.a1.a0.a3.a1
      << "), " << a2.a1.a0.a4 << ", ((" << a2.a1.a0.a5.a0.a0 << "), ("
      << a2.a1.a0.a5.a1.a0 << ")), " << a2.a1.a0.a6 << "), ((" << a2.a1.a1.a0.a0
      << ", " << a2.a1.a1.a0.a1 << "), (" << a2.a1.a1.a1.a0 << ")), "
      << a2.a1.a2 << ", " << a2.a1.a3 << "), ((" << a2.a2.a0.a0 << ", (("
      << a2.a2.a0.a1.a0.a0 << ", " << a2.a2.a0.a1.a0.a1 << "), ("
      << a2.a2.a0.a1.a1.a0 << ")), " << a2.a2.a0.a2 << ", (("
      << a2.a2.a0.a3.a0.a0 << "), " << a2.a2.a0.a3.a1 << "), " << a2.a2.a0.a4
      << ", ((" << a2.a2.a0.a5.a0.a0 << "), (" << a2.a2.a0.a5.a1.a0 << ")), "
      << a2.a2.a0.a6 << "), ((" << a2.a2.a1.a0.a0 << ", " << a2.a2.a1.a0.a1
      << "), (" << a2.a2.a1.a1.a0 << ")), " << a2.a2.a2 << ", " << a2.a2.a3
      << "), " << a2.a3 << "), (" << a3.a0 << ", ((" << a3.a1.a0.a0 << ", (("
      << a3.a1.a0.a1.a0.a0 << ", " << a3.a1.a0.a1.a0.a1 << "), ("
      << a3.a1.a0.a1.a1.a0 << ")), " << a3.a1.a0.a2 << ", (("
      << a3.a1.a0.a3.a0.a0 << "), " << a3.a1.a0.a3.a1 << "), " << a3.a1.a0.a4
      << ", ((" << a3.a1.a0.a5.a0.a0 << "), (" << a3.a1.a0.a5.a1.a0 << ")), "
      << a3.a1.a0.a6 << "), ((" << a3.a1.a1.a0.a0 << ", " << a3.a1.a1.a0.a1
      << "), (" << a3.a1.a1.a1.a0 << ")), " << a3.a1.a2 << ", " << a3.a1.a3
      << "), ((" << a3.a2.a0.a0 << ", ((" << a3.a2.a0.a1.a0.a0 << ", "
      << a3.a2.a0.a1.a0.a1 << "), (" << a3.a2.a0.a1.a1.a0 << ")), "
      << a3.a2.a0.a2 << ", ((" << a3.a2.a0.a3.a0.a0 << "), " << a3.a2.a0.a3.a1
      << "), " << a3.a2.a0.a4 << ", ((" << a3.a2.a0.a5.a0.a0 << "), ("
      << a3.a2.a0.a5.a1.a0 << ")), " << a3.a2.a0.a6 << "), ((" << a3.a2.a1.a0.a0
      << ", " << a3.a2.a1.a0.a1 << "), (" << a3.a2.a1.a1.a0 << ")), "
      << a3.a2.a2 << ", " << a3.a2.a3 << "), " << a3.a3 << "))"
      << "\n";

  double result = 0;

  result += a0.a0;
  result += a0.a1.a0.a0;
  result += a0.a1.a0.a1.a0.a0;
  result += a0.a1.a0.a1.a0.a1;
  result += a0.a1.a0.a1.a1.a0;
  result += a0.a1.a0.a2;
  result += a0.a1.a0.a3.a0.a0;
  result += a0.a1.a0.a3.a1;
  result += a0.a1.a0.a4;
  result += a0.a1.a0.a5.a0.a0;
  result += a0.a1.a0.a5.a1.a0;
  result += a0.a1.a0.a6;
  result += a0.a1.a1.a0.a0;
  result += a0.a1.a1.a0.a1;
  result += a0.a1.a1.a1.a0;
  result += a0.a1.a2;
  result += a0.a1.a3;
  result += a0.a2.a0.a0;
  result += a0.a2.a0.a1.a0.a0;
  result += a0.a2.a0.a1.a0.a1;
  result += a0.a2.a0.a1.a1.a0;
  result += a0.a2.a0.a2;
  result += a0.a2.a0.a3.a0.a0;
  result += a0.a2.a0.a3.a1;
  result += a0.a2.a0.a4;
  result += a0.a2.a0.a5.a0.a0;
  result += a0.a2.a0.a5.a1.a0;
  result += a0.a2.a0.a6;
  result += a0.a2.a1.a0.a0;
  result += a0.a2.a1.a0.a1;
  result += a0.a2.a1.a1.a0;
  result += a0.a2.a2;
  result += a0.a2.a3;
  result += a0.a3;
  result += a1.a0;
  result += a1.a1.a0.a0;
  result += a1.a1.a0.a1.a0.a0;
  result += a1.a1.a0.a1.a0.a1;
  result += a1.a1.a0.a1.a1.a0;
  result += a1.a1.a0.a2;
  result += a1.a1.a0.a3.a0.a0;
  result += a1.a1.a0.a3.a1;
  result += a1.a1.a0.a4;
  result += a1.a1.a0.a5.a0.a0;
  result += a1.a1.a0.a5.a1.a0;
  result += a1.a1.a0.a6;
  result += a1.a1.a1.a0.a0;
  result += a1.a1.a1.a0.a1;
  result += a1.a1.a1.a1.a0;
  result += a1.a1.a2;
  result += a1.a1.a3;
  result += a1.a2.a0.a0;
  result += a1.a2.a0.a1.a0.a0;
  result += a1.a2.a0.a1.a0.a1;
  result += a1.a2.a0.a1.a1.a0;
  result += a1.a2.a0.a2;
  result += a1.a2.a0.a3.a0.a0;
  result += a1.a2.a0.a3.a1;
  result += a1.a2.a0.a4;
  result += a1.a2.a0.a5.a0.a0;
  result += a1.a2.a0.a5.a1.a0;
  result += a1.a2.a0.a6;
  result += a1.a2.a1.a0.a0;
  result += a1.a2.a1.a0.a1;
  result += a1.a2.a1.a1.a0;
  result += a1.a2.a2;
  result += a1.a2.a3;
  result += a1.a3;
  result += a2.a0;
  result += a2.a1.a0.a0;
  result += a2.a1.a0.a1.a0.a0;
  result += a2.a1.a0.a1.a0.a1;
  result += a2.a1.a0.a1.a1.a0;
  result += a2.a1.a0.a2;
  result += a2.a1.a0.a3.a0.a0;
  result += a2.a1.a0.a3.a1;
  result += a2.a1.a0.a4;
  result += a2.a1.a0.a5.a0.a0;
  result += a2.a1.a0.a5.a1.a0;
  result += a2.a1.a0.a6;
  result += a2.a1.a1.a0.a0;
  result += a2.a1.a1.a0.a1;
  result += a2.a1.a1.a1.a0;
  result += a2.a1.a2;
  result += a2.a1.a3;
  result += a2.a2.a0.a0;
  result += a2.a2.a0.a1.a0.a0;
  result += a2.a2.a0.a1.a0.a1;
  result += a2.a2.a0.a1.a1.a0;
  result += a2.a2.a0.a2;
  result += a2.a2.a0.a3.a0.a0;
  result += a2.a2.a0.a3.a1;
  result += a2.a2.a0.a4;
  result += a2.a2.a0.a5.a0.a0;
  result += a2.a2.a0.a5.a1.a0;
  result += a2.a2.a0.a6;
  result += a2.a2.a1.a0.a0;
  result += a2.a2.a1.a0.a1;
  result += a2.a2.a1.a1.a0;
  result += a2.a2.a2;
  result += a2.a2.a3;
  result += a2.a3;
  result += a3.a0;
  result += a3.a1.a0.a0;
  result += a3.a1.a0.a1.a0.a0;
  result += a3.a1.a0.a1.a0.a1;
  result += a3.a1.a0.a1.a1.a0;
  result += a3.a1.a0.a2;
  result += a3.a1.a0.a3.a0.a0;
  result += a3.a1.a0.a3.a1;
  result += a3.a1.a0.a4;
  result += a3.a1.a0.a5.a0.a0;
  result += a3.a1.a0.a5.a1.a0;
  result += a3.a1.a0.a6;
  result += a3.a1.a1.a0.a0;
  result += a3.a1.a1.a0.a1;
  result += a3.a1.a1.a1.a0;
  result += a3.a1.a2;
  result += a3.a1.a3;
  result += a3.a2.a0.a0;
  result += a3.a2.a0.a1.a0.a0;
  result += a3.a2.a0.a1.a0.a1;
  result += a3.a2.a0.a1.a1.a0;
  result += a3.a2.a0.a2;
  result += a3.a2.a0.a3.a0.a0;
  result += a3.a2.a0.a3.a1;
  result += a3.a2.a0.a4;
  result += a3.a2.a0.a5.a0.a0;
  result += a3.a2.a0.a5.a1.a0;
  result += a3.a2.a0.a6;
  result += a3.a2.a1.a0.a0;
  result += a3.a2.a1.a0.a1;
  result += a3.a2.a1.a1.a0;
  result += a3.a2.a2;
  result += a3.a2.a3;
  result += a3.a3;

  std::cout << "result = " << result << "\n";

  return result;
}

// Used for testing structs by value.
// Smallest struct with data.
DART_EXPORT Struct1ByteInt ReturnStruct1ByteInt(int8_t a0) {
  std::cout << "ReturnStruct1ByteInt"
            << "(" << static_cast<int>(a0) << ")"
            << "\n";

  Struct1ByteInt result;

  result.a0 = a0;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Smaller than word size return value on all architectures.
DART_EXPORT Struct3BytesHomogeneousUint8
ReturnStruct3BytesHomogeneousUint8(uint8_t a0, uint8_t a1, uint8_t a2) {
  std::cout << "ReturnStruct3BytesHomogeneousUint8"
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ")"
            << "\n";

  Struct3BytesHomogeneousUint8 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Smaller than word size return value on all architectures.
// With alignment rules taken into account size is 4 bytes.
DART_EXPORT Struct3BytesInt2ByteAligned
ReturnStruct3BytesInt2ByteAligned(int16_t a0, int8_t a1) {
  std::cout << "ReturnStruct3BytesInt2ByteAligned"
            << "(" << a0 << ", " << static_cast<int>(a1) << ")"
            << "\n";

  Struct3BytesInt2ByteAligned result;

  result.a0 = a0;
  result.a1 = a1;

  std::cout << "result = "
            << "(" << result.a0 << ", " << static_cast<int>(result.a1) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Word size return value on 32 bit architectures..
DART_EXPORT Struct4BytesHomogeneousInt16
ReturnStruct4BytesHomogeneousInt16(int16_t a0, int16_t a1) {
  std::cout << "ReturnStruct4BytesHomogeneousInt16"
            << "(" << a0 << ", " << a1 << ")"
            << "\n";

  Struct4BytesHomogeneousInt16 result;

  result.a0 = a0;
  result.a1 = a1;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Non-wordsize return value.
DART_EXPORT Struct7BytesHomogeneousUint8
ReturnStruct7BytesHomogeneousUint8(uint8_t a0,
                                   uint8_t a1,
                                   uint8_t a2,
                                   uint8_t a3,
                                   uint8_t a4,
                                   uint8_t a5,
                                   uint8_t a6) {
  std::cout << "ReturnStruct7BytesHomogeneousUint8"
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ")"
            << "\n";

  Struct7BytesHomogeneousUint8 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;
  result.a5 = a5;
  result.a6 = a6;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Non-wordsize return value.
// With alignment rules taken into account size is 8 bytes.
DART_EXPORT Struct7BytesInt4ByteAligned
ReturnStruct7BytesInt4ByteAligned(int32_t a0, int16_t a1, int8_t a2) {
  std::cout << "ReturnStruct7BytesInt4ByteAligned"
            << "(" << a0 << ", " << a1 << ", " << static_cast<int>(a2) << ")"
            << "\n";

  Struct7BytesInt4ByteAligned result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in integer registers on many architectures.
DART_EXPORT Struct8BytesInt ReturnStruct8BytesInt(int16_t a0,
                                                  int16_t a1,
                                                  int32_t a2) {
  std::cout << "ReturnStruct8BytesInt"
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << "\n";

  Struct8BytesInt result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in FP registers on many architectures.
DART_EXPORT Struct8BytesHomogeneousFloat
ReturnStruct8BytesHomogeneousFloat(float a0, float a1) {
  std::cout << "ReturnStruct8BytesHomogeneousFloat"
            << "(" << a0 << ", " << a1 << ")"
            << "\n";

  Struct8BytesHomogeneousFloat result;

  result.a0 = a0;
  result.a1 = a1;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
DART_EXPORT Struct8BytesMixed ReturnStruct8BytesMixed(float a0,
                                                      int16_t a1,
                                                      int16_t a2) {
  std::cout << "ReturnStruct8BytesMixed"
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << "\n";

  Struct8BytesMixed result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is the right size and that
// dart:ffi trampolines do not write outside this size.
DART_EXPORT Struct9BytesHomogeneousUint8
ReturnStruct9BytesHomogeneousUint8(uint8_t a0,
                                   uint8_t a1,
                                   uint8_t a2,
                                   uint8_t a3,
                                   uint8_t a4,
                                   uint8_t a5,
                                   uint8_t a6,
                                   uint8_t a7,
                                   uint8_t a8) {
  std::cout << "ReturnStruct9BytesHomogeneousUint8"
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ", " << static_cast<int>(a7)
            << ", " << static_cast<int>(a8) << ")"
            << "\n";

  Struct9BytesHomogeneousUint8 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;
  result.a5 = a5;
  result.a6 = a6;
  result.a7 = a7;
  result.a8 = a8;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ", "
            << static_cast<int>(result.a7) << ", "
            << static_cast<int>(result.a8) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in two integer registers on x64.
// With alignment rules taken into account size is 12 or 16 bytes.
DART_EXPORT Struct9BytesInt4Or8ByteAligned
ReturnStruct9BytesInt4Or8ByteAligned(int64_t a0, int8_t a1) {
  std::cout << "ReturnStruct9BytesInt4Or8ByteAligned"
            << "(" << a0 << ", " << static_cast<int>(a1) << ")"
            << "\n";

  Struct9BytesInt4Or8ByteAligned result;

  result.a0 = a0;
  result.a1 = a1;

  std::cout << "result = "
            << "(" << result.a0 << ", " << static_cast<int>(result.a1) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in FPU registers, but does not use all registers on arm hardfp
// and arm64.
DART_EXPORT Struct12BytesHomogeneousFloat
ReturnStruct12BytesHomogeneousFloat(float a0, float a1, float a2) {
  std::cout << "ReturnStruct12BytesHomogeneousFloat"
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << "\n";

  Struct12BytesHomogeneousFloat result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in FPU registers on arm hardfp and arm64.
DART_EXPORT Struct16BytesHomogeneousFloat
ReturnStruct16BytesHomogeneousFloat(float a0, float a1, float a2, float a3) {
  std::cout << "ReturnStruct16BytesHomogeneousFloat"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << "\n";

  Struct16BytesHomogeneousFloat result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
DART_EXPORT Struct16BytesMixed ReturnStruct16BytesMixed(double a0, int64_t a1) {
  std::cout << "ReturnStruct16BytesMixed"
            << "(" << a0 << ", " << a1 << ")"
            << "\n";

  Struct16BytesMixed result;

  result.a0 = a0;
  result.a1 = a1;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
// The integer register contains half float half int.
DART_EXPORT Struct16BytesMixed2 ReturnStruct16BytesMixed2(float a0,
                                                          float a1,
                                                          float a2,
                                                          int32_t a3) {
  std::cout << "ReturnStruct16BytesMixed2"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << "\n";

  Struct16BytesMixed2 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Rerturn value returned in preallocated space passed by pointer on most ABIs.
// Is non word size on purpose, to test that structs are rounded up to word size
// on all ABIs.
DART_EXPORT Struct17BytesInt ReturnStruct17BytesInt(int64_t a0,
                                                    int64_t a1,
                                                    int8_t a2) {
  std::cout << "ReturnStruct17BytesInt"
            << "(" << a0 << ", " << a1 << ", " << static_cast<int>(a2) << ")"
            << "\n";

  Struct17BytesInt result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is the right size and that
// dart:ffi trampolines do not write outside this size.
DART_EXPORT Struct19BytesHomogeneousUint8
ReturnStruct19BytesHomogeneousUint8(uint8_t a0,
                                    uint8_t a1,
                                    uint8_t a2,
                                    uint8_t a3,
                                    uint8_t a4,
                                    uint8_t a5,
                                    uint8_t a6,
                                    uint8_t a7,
                                    uint8_t a8,
                                    uint8_t a9,
                                    uint8_t a10,
                                    uint8_t a11,
                                    uint8_t a12,
                                    uint8_t a13,
                                    uint8_t a14,
                                    uint8_t a15,
                                    uint8_t a16,
                                    uint8_t a17,
                                    uint8_t a18) {
  std::cout << "ReturnStruct19BytesHomogeneousUint8"
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ", " << static_cast<int>(a7)
            << ", " << static_cast<int>(a8) << ", " << static_cast<int>(a9)
            << ", " << static_cast<int>(a10) << ", " << static_cast<int>(a11)
            << ", " << static_cast<int>(a12) << ", " << static_cast<int>(a13)
            << ", " << static_cast<int>(a14) << ", " << static_cast<int>(a15)
            << ", " << static_cast<int>(a16) << ", " << static_cast<int>(a17)
            << ", " << static_cast<int>(a18) << ")"
            << "\n";

  Struct19BytesHomogeneousUint8 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;
  result.a5 = a5;
  result.a6 = a6;
  result.a7 = a7;
  result.a8 = a8;
  result.a9 = a9;
  result.a10 = a10;
  result.a11 = a11;
  result.a12 = a12;
  result.a13 = a13;
  result.a14 = a14;
  result.a15 = a15;
  result.a16 = a16;
  result.a17 = a17;
  result.a18 = a18;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ", "
            << static_cast<int>(result.a7) << ", "
            << static_cast<int>(result.a8) << ", "
            << static_cast<int>(result.a9) << ", "
            << static_cast<int>(result.a10) << ", "
            << static_cast<int>(result.a11) << ", "
            << static_cast<int>(result.a12) << ", "
            << static_cast<int>(result.a13) << ", "
            << static_cast<int>(result.a14) << ", "
            << static_cast<int>(result.a15) << ", "
            << static_cast<int>(result.a16) << ", "
            << static_cast<int>(result.a17) << ", "
            << static_cast<int>(result.a18) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value too big to go in cpu registers on arm64.
DART_EXPORT Struct20BytesHomogeneousInt32
ReturnStruct20BytesHomogeneousInt32(int32_t a0,
                                    int32_t a1,
                                    int32_t a2,
                                    int32_t a3,
                                    int32_t a4) {
  std::cout << "ReturnStruct20BytesHomogeneousInt32"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << "\n";

  Struct20BytesHomogeneousInt32 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value too big to go in FPU registers on x64, arm hardfp and arm64.
DART_EXPORT Struct20BytesHomogeneousFloat
ReturnStruct20BytesHomogeneousFloat(float a0,
                                    float a1,
                                    float a2,
                                    float a3,
                                    float a4) {
  std::cout << "ReturnStruct20BytesHomogeneousFloat"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << "\n";

  Struct20BytesHomogeneousFloat result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value in FPU registers on arm64.
DART_EXPORT Struct32BytesHomogeneousDouble
ReturnStruct32BytesHomogeneousDouble(double a0,
                                     double a1,
                                     double a2,
                                     double a3) {
  std::cout << "ReturnStruct32BytesHomogeneousDouble"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << "\n";

  Struct32BytesHomogeneousDouble result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return value too big to go in FPU registers on arm64.
DART_EXPORT Struct40BytesHomogeneousDouble
ReturnStruct40BytesHomogeneousDouble(double a0,
                                     double a1,
                                     double a2,
                                     double a3,
                                     double a4) {
  std::cout << "ReturnStruct40BytesHomogeneousDouble"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << "\n";

  Struct40BytesHomogeneousDouble result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test 1kb struct.
DART_EXPORT Struct1024BytesHomogeneousUint64
ReturnStruct1024BytesHomogeneousUint64(uint64_t a0,
                                       uint64_t a1,
                                       uint64_t a2,
                                       uint64_t a3,
                                       uint64_t a4,
                                       uint64_t a5,
                                       uint64_t a6,
                                       uint64_t a7,
                                       uint64_t a8,
                                       uint64_t a9,
                                       uint64_t a10,
                                       uint64_t a11,
                                       uint64_t a12,
                                       uint64_t a13,
                                       uint64_t a14,
                                       uint64_t a15,
                                       uint64_t a16,
                                       uint64_t a17,
                                       uint64_t a18,
                                       uint64_t a19,
                                       uint64_t a20,
                                       uint64_t a21,
                                       uint64_t a22,
                                       uint64_t a23,
                                       uint64_t a24,
                                       uint64_t a25,
                                       uint64_t a26,
                                       uint64_t a27,
                                       uint64_t a28,
                                       uint64_t a29,
                                       uint64_t a30,
                                       uint64_t a31,
                                       uint64_t a32,
                                       uint64_t a33,
                                       uint64_t a34,
                                       uint64_t a35,
                                       uint64_t a36,
                                       uint64_t a37,
                                       uint64_t a38,
                                       uint64_t a39,
                                       uint64_t a40,
                                       uint64_t a41,
                                       uint64_t a42,
                                       uint64_t a43,
                                       uint64_t a44,
                                       uint64_t a45,
                                       uint64_t a46,
                                       uint64_t a47,
                                       uint64_t a48,
                                       uint64_t a49,
                                       uint64_t a50,
                                       uint64_t a51,
                                       uint64_t a52,
                                       uint64_t a53,
                                       uint64_t a54,
                                       uint64_t a55,
                                       uint64_t a56,
                                       uint64_t a57,
                                       uint64_t a58,
                                       uint64_t a59,
                                       uint64_t a60,
                                       uint64_t a61,
                                       uint64_t a62,
                                       uint64_t a63,
                                       uint64_t a64,
                                       uint64_t a65,
                                       uint64_t a66,
                                       uint64_t a67,
                                       uint64_t a68,
                                       uint64_t a69,
                                       uint64_t a70,
                                       uint64_t a71,
                                       uint64_t a72,
                                       uint64_t a73,
                                       uint64_t a74,
                                       uint64_t a75,
                                       uint64_t a76,
                                       uint64_t a77,
                                       uint64_t a78,
                                       uint64_t a79,
                                       uint64_t a80,
                                       uint64_t a81,
                                       uint64_t a82,
                                       uint64_t a83,
                                       uint64_t a84,
                                       uint64_t a85,
                                       uint64_t a86,
                                       uint64_t a87,
                                       uint64_t a88,
                                       uint64_t a89,
                                       uint64_t a90,
                                       uint64_t a91,
                                       uint64_t a92,
                                       uint64_t a93,
                                       uint64_t a94,
                                       uint64_t a95,
                                       uint64_t a96,
                                       uint64_t a97,
                                       uint64_t a98,
                                       uint64_t a99,
                                       uint64_t a100,
                                       uint64_t a101,
                                       uint64_t a102,
                                       uint64_t a103,
                                       uint64_t a104,
                                       uint64_t a105,
                                       uint64_t a106,
                                       uint64_t a107,
                                       uint64_t a108,
                                       uint64_t a109,
                                       uint64_t a110,
                                       uint64_t a111,
                                       uint64_t a112,
                                       uint64_t a113,
                                       uint64_t a114,
                                       uint64_t a115,
                                       uint64_t a116,
                                       uint64_t a117,
                                       uint64_t a118,
                                       uint64_t a119,
                                       uint64_t a120,
                                       uint64_t a121,
                                       uint64_t a122,
                                       uint64_t a123,
                                       uint64_t a124,
                                       uint64_t a125,
                                       uint64_t a126,
                                       uint64_t a127) {
  std::cout << "ReturnStruct1024BytesHomogeneousUint64"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", " << a8 << ", "
            << a9 << ", " << a10 << ", " << a11 << ", " << a12 << ", " << a13
            << ", " << a14 << ", " << a15 << ", " << a16 << ", " << a17 << ", "
            << a18 << ", " << a19 << ", " << a20 << ", " << a21 << ", " << a22
            << ", " << a23 << ", " << a24 << ", " << a25 << ", " << a26 << ", "
            << a27 << ", " << a28 << ", " << a29 << ", " << a30 << ", " << a31
            << ", " << a32 << ", " << a33 << ", " << a34 << ", " << a35 << ", "
            << a36 << ", " << a37 << ", " << a38 << ", " << a39 << ", " << a40
            << ", " << a41 << ", " << a42 << ", " << a43 << ", " << a44 << ", "
            << a45 << ", " << a46 << ", " << a47 << ", " << a48 << ", " << a49
            << ", " << a50 << ", " << a51 << ", " << a52 << ", " << a53 << ", "
            << a54 << ", " << a55 << ", " << a56 << ", " << a57 << ", " << a58
            << ", " << a59 << ", " << a60 << ", " << a61 << ", " << a62 << ", "
            << a63 << ", " << a64 << ", " << a65 << ", " << a66 << ", " << a67
            << ", " << a68 << ", " << a69 << ", " << a70 << ", " << a71 << ", "
            << a72 << ", " << a73 << ", " << a74 << ", " << a75 << ", " << a76
            << ", " << a77 << ", " << a78 << ", " << a79 << ", " << a80 << ", "
            << a81 << ", " << a82 << ", " << a83 << ", " << a84 << ", " << a85
            << ", " << a86 << ", " << a87 << ", " << a88 << ", " << a89 << ", "
            << a90 << ", " << a91 << ", " << a92 << ", " << a93 << ", " << a94
            << ", " << a95 << ", " << a96 << ", " << a97 << ", " << a98 << ", "
            << a99 << ", " << a100 << ", " << a101 << ", " << a102 << ", "
            << a103 << ", " << a104 << ", " << a105 << ", " << a106 << ", "
            << a107 << ", " << a108 << ", " << a109 << ", " << a110 << ", "
            << a111 << ", " << a112 << ", " << a113 << ", " << a114 << ", "
            << a115 << ", " << a116 << ", " << a117 << ", " << a118 << ", "
            << a119 << ", " << a120 << ", " << a121 << ", " << a122 << ", "
            << a123 << ", " << a124 << ", " << a125 << ", " << a126 << ", "
            << a127 << ")"
            << "\n";

  Struct1024BytesHomogeneousUint64 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;
  result.a3 = a3;
  result.a4 = a4;
  result.a5 = a5;
  result.a6 = a6;
  result.a7 = a7;
  result.a8 = a8;
  result.a9 = a9;
  result.a10 = a10;
  result.a11 = a11;
  result.a12 = a12;
  result.a13 = a13;
  result.a14 = a14;
  result.a15 = a15;
  result.a16 = a16;
  result.a17 = a17;
  result.a18 = a18;
  result.a19 = a19;
  result.a20 = a20;
  result.a21 = a21;
  result.a22 = a22;
  result.a23 = a23;
  result.a24 = a24;
  result.a25 = a25;
  result.a26 = a26;
  result.a27 = a27;
  result.a28 = a28;
  result.a29 = a29;
  result.a30 = a30;
  result.a31 = a31;
  result.a32 = a32;
  result.a33 = a33;
  result.a34 = a34;
  result.a35 = a35;
  result.a36 = a36;
  result.a37 = a37;
  result.a38 = a38;
  result.a39 = a39;
  result.a40 = a40;
  result.a41 = a41;
  result.a42 = a42;
  result.a43 = a43;
  result.a44 = a44;
  result.a45 = a45;
  result.a46 = a46;
  result.a47 = a47;
  result.a48 = a48;
  result.a49 = a49;
  result.a50 = a50;
  result.a51 = a51;
  result.a52 = a52;
  result.a53 = a53;
  result.a54 = a54;
  result.a55 = a55;
  result.a56 = a56;
  result.a57 = a57;
  result.a58 = a58;
  result.a59 = a59;
  result.a60 = a60;
  result.a61 = a61;
  result.a62 = a62;
  result.a63 = a63;
  result.a64 = a64;
  result.a65 = a65;
  result.a66 = a66;
  result.a67 = a67;
  result.a68 = a68;
  result.a69 = a69;
  result.a70 = a70;
  result.a71 = a71;
  result.a72 = a72;
  result.a73 = a73;
  result.a74 = a74;
  result.a75 = a75;
  result.a76 = a76;
  result.a77 = a77;
  result.a78 = a78;
  result.a79 = a79;
  result.a80 = a80;
  result.a81 = a81;
  result.a82 = a82;
  result.a83 = a83;
  result.a84 = a84;
  result.a85 = a85;
  result.a86 = a86;
  result.a87 = a87;
  result.a88 = a88;
  result.a89 = a89;
  result.a90 = a90;
  result.a91 = a91;
  result.a92 = a92;
  result.a93 = a93;
  result.a94 = a94;
  result.a95 = a95;
  result.a96 = a96;
  result.a97 = a97;
  result.a98 = a98;
  result.a99 = a99;
  result.a100 = a100;
  result.a101 = a101;
  result.a102 = a102;
  result.a103 = a103;
  result.a104 = a104;
  result.a105 = a105;
  result.a106 = a106;
  result.a107 = a107;
  result.a108 = a108;
  result.a109 = a109;
  result.a110 = a110;
  result.a111 = a111;
  result.a112 = a112;
  result.a113 = a113;
  result.a114 = a114;
  result.a115 = a115;
  result.a116 = a116;
  result.a117 = a117;
  result.a118 = a118;
  result.a119 = a119;
  result.a120 = a120;
  result.a121 = a121;
  result.a122 = a122;
  result.a123 = a123;
  result.a124 = a124;
  result.a125 = a125;
  result.a126 = a126;
  result.a127 = a127;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ", " << result.a5
            << ", " << result.a6 << ", " << result.a7 << ", " << result.a8
            << ", " << result.a9 << ", " << result.a10 << ", " << result.a11
            << ", " << result.a12 << ", " << result.a13 << ", " << result.a14
            << ", " << result.a15 << ", " << result.a16 << ", " << result.a17
            << ", " << result.a18 << ", " << result.a19 << ", " << result.a20
            << ", " << result.a21 << ", " << result.a22 << ", " << result.a23
            << ", " << result.a24 << ", " << result.a25 << ", " << result.a26
            << ", " << result.a27 << ", " << result.a28 << ", " << result.a29
            << ", " << result.a30 << ", " << result.a31 << ", " << result.a32
            << ", " << result.a33 << ", " << result.a34 << ", " << result.a35
            << ", " << result.a36 << ", " << result.a37 << ", " << result.a38
            << ", " << result.a39 << ", " << result.a40 << ", " << result.a41
            << ", " << result.a42 << ", " << result.a43 << ", " << result.a44
            << ", " << result.a45 << ", " << result.a46 << ", " << result.a47
            << ", " << result.a48 << ", " << result.a49 << ", " << result.a50
            << ", " << result.a51 << ", " << result.a52 << ", " << result.a53
            << ", " << result.a54 << ", " << result.a55 << ", " << result.a56
            << ", " << result.a57 << ", " << result.a58 << ", " << result.a59
            << ", " << result.a60 << ", " << result.a61 << ", " << result.a62
            << ", " << result.a63 << ", " << result.a64 << ", " << result.a65
            << ", " << result.a66 << ", " << result.a67 << ", " << result.a68
            << ", " << result.a69 << ", " << result.a70 << ", " << result.a71
            << ", " << result.a72 << ", " << result.a73 << ", " << result.a74
            << ", " << result.a75 << ", " << result.a76 << ", " << result.a77
            << ", " << result.a78 << ", " << result.a79 << ", " << result.a80
            << ", " << result.a81 << ", " << result.a82 << ", " << result.a83
            << ", " << result.a84 << ", " << result.a85 << ", " << result.a86
            << ", " << result.a87 << ", " << result.a88 << ", " << result.a89
            << ", " << result.a90 << ", " << result.a91 << ", " << result.a92
            << ", " << result.a93 << ", " << result.a94 << ", " << result.a95
            << ", " << result.a96 << ", " << result.a97 << ", " << result.a98
            << ", " << result.a99 << ", " << result.a100 << ", " << result.a101
            << ", " << result.a102 << ", " << result.a103 << ", " << result.a104
            << ", " << result.a105 << ", " << result.a106 << ", " << result.a107
            << ", " << result.a108 << ", " << result.a109 << ", " << result.a110
            << ", " << result.a111 << ", " << result.a112 << ", " << result.a113
            << ", " << result.a114 << ", " << result.a115 << ", " << result.a116
            << ", " << result.a117 << ", " << result.a118 << ", " << result.a119
            << ", " << result.a120 << ", " << result.a121 << ", " << result.a122
            << ", " << result.a123 << ", " << result.a124 << ", " << result.a125
            << ", " << result.a126 << ", " << result.a127 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed in int registers in most ABIs.
DART_EXPORT Struct1ByteInt
ReturnStructArgumentStruct1ByteInt(Struct1ByteInt a0) {
  std::cout << "ReturnStructArgumentStruct1ByteInt"
            << "((" << static_cast<int>(a0.a0) << "))"
            << "\n";

  Struct1ByteInt result = a0;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed on stack on all ABIs.
DART_EXPORT Struct1ByteInt
ReturnStructArgumentInt32x8Struct1ByteInt(int32_t a0,
                                          int32_t a1,
                                          int32_t a2,
                                          int32_t a3,
                                          int32_t a4,
                                          int32_t a5,
                                          int32_t a6,
                                          int32_t a7,
                                          Struct1ByteInt a8) {
  std::cout << "ReturnStructArgumentInt32x8Struct1ByteInt"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", ("
            << static_cast<int>(a8.a0) << "))"
            << "\n";

  Struct1ByteInt result = a8;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed in float registers in most ABIs.
DART_EXPORT Struct8BytesHomogeneousFloat
ReturnStructArgumentStruct8BytesHomogeneousFloat(
    Struct8BytesHomogeneousFloat a0) {
  std::cout << "ReturnStructArgumentStruct8BytesHomogeneousFloat"
            << "((" << a0.a0 << ", " << a0.a1 << "))"
            << "\n";

  Struct8BytesHomogeneousFloat result = a0;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// On arm64, both argument and return value are passed in by pointer.
DART_EXPORT Struct20BytesHomogeneousInt32
ReturnStructArgumentStruct20BytesHomogeneousInt32(
    Struct20BytesHomogeneousInt32 a0) {
  std::cout << "ReturnStructArgumentStruct20BytesHomogeneousInt32"
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << "\n";

  Struct20BytesHomogeneousInt32 result = a0;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// On arm64, both argument and return value are passed in by pointer.
// Ints exhaust registers, so that pointer is passed on stack.
DART_EXPORT Struct20BytesHomogeneousInt32
ReturnStructArgumentInt32x8Struct20BytesHomogeneou(
    int32_t a0,
    int32_t a1,
    int32_t a2,
    int32_t a3,
    int32_t a4,
    int32_t a5,
    int32_t a6,
    int32_t a7,
    Struct20BytesHomogeneousInt32 a8) {
  std::cout << "ReturnStructArgumentInt32x8Struct20BytesHomogeneou"
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", (" << a8.a0 << ", "
            << a8.a1 << ", " << a8.a2 << ", " << a8.a3 << ", " << a8.a4 << "))"
            << "\n";

  Struct20BytesHomogeneousInt32 result = a8;

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT StructAlignmentInt16 ReturnStructAlignmentInt16(int8_t a0,
                                                            int16_t a1,
                                                            int8_t a2) {
  std::cout << "ReturnStructAlignmentInt16"
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << "\n";

  StructAlignmentInt16 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 32 byte int within struct.
DART_EXPORT StructAlignmentInt32 ReturnStructAlignmentInt32(int8_t a0,
                                                            int32_t a1,
                                                            int8_t a2) {
  std::cout << "ReturnStructAlignmentInt32"
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << "\n";

  StructAlignmentInt32 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of 64 byte int within struct.
DART_EXPORT StructAlignmentInt64 ReturnStructAlignmentInt64(int8_t a0,
                                                            int64_t a1,
                                                            int8_t a2) {
  std::cout << "ReturnStructAlignmentInt64"
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << "\n";

  StructAlignmentInt64 result;

  result.a0 = a0;
  result.a1 = a1;
  result.a2 = a2;

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct.
DART_EXPORT Struct8BytesNestedInt
ReturnStruct8BytesNestedInt(Struct4BytesHomogeneousInt16 a0,
                            Struct4BytesHomogeneousInt16 a1) {
  std::cout << "ReturnStruct8BytesNestedInt"
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "))"
            << "\n";

  Struct8BytesNestedInt result;

  result.a0.a0 = a0.a0;
  result.a0.a1 = a0.a1;
  result.a1.a0 = a1.a0;
  result.a1.a1 = a1.a1;

  std::cout << "result = "
            << "((" << result.a0.a0 << ", " << result.a0.a1 << "), ("
            << result.a1.a0 << ", " << result.a1.a1 << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct with floats.
DART_EXPORT Struct8BytesNestedFloat
ReturnStruct8BytesNestedFloat(Struct4BytesFloat a0, Struct4BytesFloat a1) {
  std::cout << "ReturnStruct8BytesNestedFloat"
            << "((" << a0.a0 << "), (" << a1.a0 << "))"
            << "\n";

  Struct8BytesNestedFloat result;

  result.a0.a0 = a0.a0;
  result.a1.a0 = a1.a0;

  std::cout << "result = "
            << "((" << result.a0.a0 << "), (" << result.a1.a0 << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// The nesting is irregular, testing homogenous float rules on arm and arm64,
// and the fpu register usage on x64.
DART_EXPORT Struct8BytesNestedFloat2
ReturnStruct8BytesNestedFloat2(Struct4BytesFloat a0, float a1) {
  std::cout << "ReturnStruct8BytesNestedFloat2"
            << "((" << a0.a0 << "), " << a1 << ")"
            << "\n";

  Struct8BytesNestedFloat2 result;

  result.a0.a0 = a0.a0;
  result.a1 = a1;

  std::cout << "result = "
            << "((" << result.a0.a0 << "), " << result.a1 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Simple nested struct with mixed members.
DART_EXPORT Struct8BytesNestedMixed
ReturnStruct8BytesNestedMixed(Struct4BytesHomogeneousInt16 a0,
                              Struct4BytesFloat a1) {
  std::cout << "ReturnStruct8BytesNestedMixed"
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << "))"
            << "\n";

  Struct8BytesNestedMixed result;

  result.a0.a0 = a0.a0;
  result.a0.a1 = a0.a1;
  result.a1.a0 = a1.a0;

  std::cout << "result = "
            << "((" << result.a0.a0 << ", " << result.a0.a1 << "), ("
            << result.a1.a0 << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Deeper nested struct to test recursive member access.
DART_EXPORT Struct16BytesNestedInt
ReturnStruct16BytesNestedInt(Struct8BytesNestedInt a0,
                             Struct8BytesNestedInt a1) {
  std::cout << "ReturnStruct16BytesNestedInt"
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ", " << a0.a1.a1 << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1
            << "), (" << a1.a1.a0 << ", " << a1.a1.a1 << ")))"
            << "\n";

  Struct16BytesNestedInt result;

  result.a0.a0.a0 = a0.a0.a0;
  result.a0.a0.a1 = a0.a0.a1;
  result.a0.a1.a0 = a0.a1.a0;
  result.a0.a1.a1 = a0.a1.a1;
  result.a1.a0.a0 = a1.a0.a0;
  result.a1.a0.a1 = a1.a0.a1;
  result.a1.a1.a0 = a1.a1.a0;
  result.a1.a1.a1 = a1.a1.a1;

  std::cout << "result = "
            << "(((" << result.a0.a0.a0 << ", " << result.a0.a0.a1 << "), ("
            << result.a0.a1.a0 << ", " << result.a0.a1.a1 << ")), (("
            << result.a1.a0.a0 << ", " << result.a1.a0.a1 << "), ("
            << result.a1.a1.a0 << ", " << result.a1.a1.a1 << ")))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Even deeper nested struct to test recursive member access.
DART_EXPORT Struct32BytesNestedInt
ReturnStruct32BytesNestedInt(Struct16BytesNestedInt a0,
                             Struct16BytesNestedInt a1) {
  std::cout << "ReturnStruct32BytesNestedInt"
            << "((((" << a0.a0.a0.a0 << ", " << a0.a0.a0.a1 << "), ("
            << a0.a0.a1.a0 << ", " << a0.a0.a1.a1 << ")), ((" << a0.a1.a0.a0
            << ", " << a0.a1.a0.a1 << "), (" << a0.a1.a1.a0 << ", "
            << a0.a1.a1.a1 << "))), (((" << a1.a0.a0.a0 << ", " << a1.a0.a0.a1
            << "), (" << a1.a0.a1.a0 << ", " << a1.a0.a1.a1 << ")), (("
            << a1.a1.a0.a0 << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0
            << ", " << a1.a1.a1.a1 << "))))"
            << "\n";

  Struct32BytesNestedInt result;

  result.a0.a0.a0.a0 = a0.a0.a0.a0;
  result.a0.a0.a0.a1 = a0.a0.a0.a1;
  result.a0.a0.a1.a0 = a0.a0.a1.a0;
  result.a0.a0.a1.a1 = a0.a0.a1.a1;
  result.a0.a1.a0.a0 = a0.a1.a0.a0;
  result.a0.a1.a0.a1 = a0.a1.a0.a1;
  result.a0.a1.a1.a0 = a0.a1.a1.a0;
  result.a0.a1.a1.a1 = a0.a1.a1.a1;
  result.a1.a0.a0.a0 = a1.a0.a0.a0;
  result.a1.a0.a0.a1 = a1.a0.a0.a1;
  result.a1.a0.a1.a0 = a1.a0.a1.a0;
  result.a1.a0.a1.a1 = a1.a0.a1.a1;
  result.a1.a1.a0.a0 = a1.a1.a0.a0;
  result.a1.a1.a0.a1 = a1.a1.a0.a1;
  result.a1.a1.a1.a0 = a1.a1.a1.a0;
  result.a1.a1.a1.a1 = a1.a1.a1.a1;

  std::cout << "result = "
            << "((((" << result.a0.a0.a0.a0 << ", " << result.a0.a0.a0.a1
            << "), (" << result.a0.a0.a1.a0 << ", " << result.a0.a0.a1.a1
            << ")), ((" << result.a0.a1.a0.a0 << ", " << result.a0.a1.a0.a1
            << "), (" << result.a0.a1.a1.a0 << ", " << result.a0.a1.a1.a1
            << "))), (((" << result.a1.a0.a0.a0 << ", " << result.a1.a0.a0.a1
            << "), (" << result.a1.a0.a1.a0 << ", " << result.a1.a0.a1.a1
            << ")), ((" << result.a1.a1.a0.a0 << ", " << result.a1.a1.a0.a1
            << "), (" << result.a1.a1.a1.a0 << ", " << result.a1.a1.a1.a1
            << "))))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 16 byte int.
DART_EXPORT StructNestedIntStructAlignmentInt16
ReturnStructNestedIntStructAlignmentInt16(StructAlignmentInt16 a0,
                                          StructAlignmentInt16 a1) {
  std::cout << "ReturnStructNestedIntStructAlignmentInt16"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << "\n";

  StructNestedIntStructAlignmentInt16 result;

  result.a0.a0 = a0.a0;
  result.a0.a1 = a0.a1;
  result.a0.a2 = a0.a2;
  result.a1.a0 = a1.a0;
  result.a1.a1 = a1.a1;
  result.a1.a2 = a1.a2;

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 32 byte int.
DART_EXPORT StructNestedIntStructAlignmentInt32
ReturnStructNestedIntStructAlignmentInt32(StructAlignmentInt32 a0,
                                          StructAlignmentInt32 a1) {
  std::cout << "ReturnStructNestedIntStructAlignmentInt32"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << "\n";

  StructNestedIntStructAlignmentInt32 result;

  result.a0.a0 = a0.a0;
  result.a0.a1 = a0.a1;
  result.a0.a2 = a0.a2;
  result.a1.a0 = a1.a0;
  result.a1.a1 = a1.a1;
  result.a1.a2 = a1.a2;

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 64 byte int.
DART_EXPORT StructNestedIntStructAlignmentInt64
ReturnStructNestedIntStructAlignmentInt64(StructAlignmentInt64 a0,
                                          StructAlignmentInt64 a1) {
  std::cout << "ReturnStructNestedIntStructAlignmentInt64"
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << "\n";

  StructNestedIntStructAlignmentInt64 result;

  result.a0.a0 = a0.a0;
  result.a0.a1 = a0.a1;
  result.a0.a2 = a0.a2;
  result.a1.a0 = a1.a0;
  result.a1.a1 = a1.a1;
  result.a1.a2 = a1.a2;

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Return big irregular struct as smoke test.
DART_EXPORT StructNestedIrregularEvenBigger
ReturnStructNestedIrregularEvenBigger(uint64_t a0,
                                      StructNestedIrregularBigger a1,
                                      StructNestedIrregularBigger a2,
                                      double a3) {
  std::cout << "ReturnStructNestedIrregularEvenBigger"
            << "(" << a0 << ", ((" << a1.a0.a0 << ", ((" << a1.a0.a1.a0.a0
            << ", " << a1.a0.a1.a0.a1 << "), (" << a1.a0.a1.a1.a0 << ")), "
            << a1.a0.a2 << ", ((" << a1.a0.a3.a0.a0 << "), " << a1.a0.a3.a1
            << "), " << a1.a0.a4 << ", ((" << a1.a0.a5.a0.a0 << "), ("
            << a1.a0.a5.a1.a0 << ")), " << a1.a0.a6 << "), ((" << a1.a1.a0.a0
            << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0 << ")), " << a1.a2
            << ", " << a1.a3 << "), ((" << a2.a0.a0 << ", ((" << a2.a0.a1.a0.a0
            << ", " << a2.a0.a1.a0.a1 << "), (" << a2.a0.a1.a1.a0 << ")), "
            << a2.a0.a2 << ", ((" << a2.a0.a3.a0.a0 << "), " << a2.a0.a3.a1
            << "), " << a2.a0.a4 << ", ((" << a2.a0.a5.a0.a0 << "), ("
            << a2.a0.a5.a1.a0 << ")), " << a2.a0.a6 << "), ((" << a2.a1.a0.a0
            << ", " << a2.a1.a0.a1 << "), (" << a2.a1.a1.a0 << ")), " << a2.a2
            << ", " << a2.a3 << "), " << a3 << ")"
            << "\n";

  StructNestedIrregularEvenBigger result;

  result.a0 = a0;
  result.a1.a0.a0 = a1.a0.a0;
  result.a1.a0.a1.a0.a0 = a1.a0.a1.a0.a0;
  result.a1.a0.a1.a0.a1 = a1.a0.a1.a0.a1;
  result.a1.a0.a1.a1.a0 = a1.a0.a1.a1.a0;
  result.a1.a0.a2 = a1.a0.a2;
  result.a1.a0.a3.a0.a0 = a1.a0.a3.a0.a0;
  result.a1.a0.a3.a1 = a1.a0.a3.a1;
  result.a1.a0.a4 = a1.a0.a4;
  result.a1.a0.a5.a0.a0 = a1.a0.a5.a0.a0;
  result.a1.a0.a5.a1.a0 = a1.a0.a5.a1.a0;
  result.a1.a0.a6 = a1.a0.a6;
  result.a1.a1.a0.a0 = a1.a1.a0.a0;
  result.a1.a1.a0.a1 = a1.a1.a0.a1;
  result.a1.a1.a1.a0 = a1.a1.a1.a0;
  result.a1.a2 = a1.a2;
  result.a1.a3 = a1.a3;
  result.a2.a0.a0 = a2.a0.a0;
  result.a2.a0.a1.a0.a0 = a2.a0.a1.a0.a0;
  result.a2.a0.a1.a0.a1 = a2.a0.a1.a0.a1;
  result.a2.a0.a1.a1.a0 = a2.a0.a1.a1.a0;
  result.a2.a0.a2 = a2.a0.a2;
  result.a2.a0.a3.a0.a0 = a2.a0.a3.a0.a0;
  result.a2.a0.a3.a1 = a2.a0.a3.a1;
  result.a2.a0.a4 = a2.a0.a4;
  result.a2.a0.a5.a0.a0 = a2.a0.a5.a0.a0;
  result.a2.a0.a5.a1.a0 = a2.a0.a5.a1.a0;
  result.a2.a0.a6 = a2.a0.a6;
  result.a2.a1.a0.a0 = a2.a1.a0.a0;
  result.a2.a1.a0.a1 = a2.a1.a0.a1;
  result.a2.a1.a1.a0 = a2.a1.a1.a0;
  result.a2.a2 = a2.a2;
  result.a2.a3 = a2.a3;
  result.a3 = a3;

  std::cout << "result = "
            << "(" << result.a0 << ", ((" << result.a1.a0.a0 << ", (("
            << result.a1.a0.a1.a0.a0 << ", " << result.a1.a0.a1.a0.a1 << "), ("
            << result.a1.a0.a1.a1.a0 << ")), " << result.a1.a0.a2 << ", (("
            << result.a1.a0.a3.a0.a0 << "), " << result.a1.a0.a3.a1 << "), "
            << result.a1.a0.a4 << ", ((" << result.a1.a0.a5.a0.a0 << "), ("
            << result.a1.a0.a5.a1.a0 << ")), " << result.a1.a0.a6 << "), (("
            << result.a1.a1.a0.a0 << ", " << result.a1.a1.a0.a1 << "), ("
            << result.a1.a1.a1.a0 << ")), " << result.a1.a2 << ", "
            << result.a1.a3 << "), ((" << result.a2.a0.a0 << ", (("
            << result.a2.a0.a1.a0.a0 << ", " << result.a2.a0.a1.a0.a1 << "), ("
            << result.a2.a0.a1.a1.a0 << ")), " << result.a2.a0.a2 << ", (("
            << result.a2.a0.a3.a0.a0 << "), " << result.a2.a0.a3.a1 << "), "
            << result.a2.a0.a4 << ", ((" << result.a2.a0.a5.a0.a0 << "), ("
            << result.a2.a0.a5.a1.a0 << ")), " << result.a2.a0.a6 << "), (("
            << result.a2.a1.a0.a0 << ", " << result.a2.a1.a0.a1 << "), ("
            << result.a2.a1.a1.a0 << ")), " << result.a2.a2 << ", "
            << result.a2.a3 << "), " << result.a3 << ")"
            << "\n";

  return result;
}

// Used for testing structs by value.
// Smallest struct with data.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct1ByteIntx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct1ByteInt a0,
                 Struct1ByteInt a1,
                 Struct1ByteInt a2,
                 Struct1ByteInt a3,
                 Struct1ByteInt a4,
                 Struct1ByteInt a5,
                 Struct1ByteInt a6,
                 Struct1ByteInt a7,
                 Struct1ByteInt a8,
                 Struct1ByteInt a9)) {
  Struct1ByteInt a0;
  Struct1ByteInt a1;
  Struct1ByteInt a2;
  Struct1ByteInt a3;
  Struct1ByteInt a4;
  Struct1ByteInt a5;
  Struct1ByteInt a6;
  Struct1ByteInt a7;
  Struct1ByteInt a8;
  Struct1ByteInt a9;

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

  std::cout << "Calling TestPassStruct1ByteIntx10("
            << "((" << static_cast<int>(a0.a0) << "), ("
            << static_cast<int>(a1.a0) << "), (" << static_cast<int>(a2.a0)
            << "), (" << static_cast<int>(a3.a0) << "), ("
            << static_cast<int>(a4.a0) << "), (" << static_cast<int>(a5.a0)
            << "), (" << static_cast<int>(a6.a0) << "), ("
            << static_cast<int>(a7.a0) << "), (" << static_cast<int>(a8.a0)
            << "), (" << static_cast<int>(a9.a0) << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(5, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Not a multiple of word size, not a power of two.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct3BytesHomogeneousUint8x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct3BytesHomogeneousUint8 a0,
                 Struct3BytesHomogeneousUint8 a1,
                 Struct3BytesHomogeneousUint8 a2,
                 Struct3BytesHomogeneousUint8 a3,
                 Struct3BytesHomogeneousUint8 a4,
                 Struct3BytesHomogeneousUint8 a5,
                 Struct3BytesHomogeneousUint8 a6,
                 Struct3BytesHomogeneousUint8 a7,
                 Struct3BytesHomogeneousUint8 a8,
                 Struct3BytesHomogeneousUint8 a9)) {
  Struct3BytesHomogeneousUint8 a0;
  Struct3BytesHomogeneousUint8 a1;
  Struct3BytesHomogeneousUint8 a2;
  Struct3BytesHomogeneousUint8 a3;
  Struct3BytesHomogeneousUint8 a4;
  Struct3BytesHomogeneousUint8 a5;
  Struct3BytesHomogeneousUint8 a6;
  Struct3BytesHomogeneousUint8 a7;
  Struct3BytesHomogeneousUint8 a8;
  Struct3BytesHomogeneousUint8 a9;

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

  std::cout << "Calling TestPassStruct3BytesHomogeneousUint8x10("
            << "((" << static_cast<int>(a0.a0) << ", "
            << static_cast<int>(a0.a1) << ", " << static_cast<int>(a0.a2)
            << "), (" << static_cast<int>(a1.a0) << ", "
            << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
            << "), (" << static_cast<int>(a2.a0) << ", "
            << static_cast<int>(a2.a1) << ", " << static_cast<int>(a2.a2)
            << "), (" << static_cast<int>(a3.a0) << ", "
            << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
            << "), (" << static_cast<int>(a4.a0) << ", "
            << static_cast<int>(a4.a1) << ", " << static_cast<int>(a4.a2)
            << "), (" << static_cast<int>(a5.a0) << ", "
            << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
            << "), (" << static_cast<int>(a6.a0) << ", "
            << static_cast<int>(a6.a1) << ", " << static_cast<int>(a6.a2)
            << "), (" << static_cast<int>(a7.a0) << ", "
            << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
            << "), (" << static_cast<int>(a8.a0) << ", "
            << static_cast<int>(a8.a1) << ", " << static_cast<int>(a8.a2)
            << "), (" << static_cast<int>(a9.a0) << ", "
            << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
            << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(465, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Not a multiple of word size, not a power of two.
// With alignment rules taken into account size is 4 bytes.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct3BytesInt2ByteAlignedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct3BytesInt2ByteAligned a0,
                 Struct3BytesInt2ByteAligned a1,
                 Struct3BytesInt2ByteAligned a2,
                 Struct3BytesInt2ByteAligned a3,
                 Struct3BytesInt2ByteAligned a4,
                 Struct3BytesInt2ByteAligned a5,
                 Struct3BytesInt2ByteAligned a6,
                 Struct3BytesInt2ByteAligned a7,
                 Struct3BytesInt2ByteAligned a8,
                 Struct3BytesInt2ByteAligned a9)) {
  Struct3BytesInt2ByteAligned a0;
  Struct3BytesInt2ByteAligned a1;
  Struct3BytesInt2ByteAligned a2;
  Struct3BytesInt2ByteAligned a3;
  Struct3BytesInt2ByteAligned a4;
  Struct3BytesInt2ByteAligned a5;
  Struct3BytesInt2ByteAligned a6;
  Struct3BytesInt2ByteAligned a7;
  Struct3BytesInt2ByteAligned a8;
  Struct3BytesInt2ByteAligned a9;

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

  std::cout << "Calling TestPassStruct3BytesInt2ByteAlignedx10("
            << "((" << a0.a0 << ", " << static_cast<int>(a0.a1) << "), ("
            << a1.a0 << ", " << static_cast<int>(a1.a1) << "), (" << a2.a0
            << ", " << static_cast<int>(a2.a1) << "), (" << a3.a0 << ", "
            << static_cast<int>(a3.a1) << "), (" << a4.a0 << ", "
            << static_cast<int>(a4.a1) << "), (" << a5.a0 << ", "
            << static_cast<int>(a5.a1) << "), (" << a6.a0 << ", "
            << static_cast<int>(a6.a1) << "), (" << a7.a0 << ", "
            << static_cast<int>(a7.a1) << "), (" << a8.a0 << ", "
            << static_cast<int>(a8.a1) << "), (" << a9.a0 << ", "
            << static_cast<int>(a9.a1) << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(10, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Exactly word size on 32-bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct4BytesHomogeneousInt16x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct4BytesHomogeneousInt16 a0,
                 Struct4BytesHomogeneousInt16 a1,
                 Struct4BytesHomogeneousInt16 a2,
                 Struct4BytesHomogeneousInt16 a3,
                 Struct4BytesHomogeneousInt16 a4,
                 Struct4BytesHomogeneousInt16 a5,
                 Struct4BytesHomogeneousInt16 a6,
                 Struct4BytesHomogeneousInt16 a7,
                 Struct4BytesHomogeneousInt16 a8,
                 Struct4BytesHomogeneousInt16 a9)) {
  Struct4BytesHomogeneousInt16 a0;
  Struct4BytesHomogeneousInt16 a1;
  Struct4BytesHomogeneousInt16 a2;
  Struct4BytesHomogeneousInt16 a3;
  Struct4BytesHomogeneousInt16 a4;
  Struct4BytesHomogeneousInt16 a5;
  Struct4BytesHomogeneousInt16 a6;
  Struct4BytesHomogeneousInt16 a7;
  Struct4BytesHomogeneousInt16 a8;
  Struct4BytesHomogeneousInt16 a9;

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

  std::cout << "Calling TestPassStruct4BytesHomogeneousInt16x10("
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(10, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Sub word size on 64 bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct7BytesHomogeneousUint8x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct7BytesHomogeneousUint8 a0,
                 Struct7BytesHomogeneousUint8 a1,
                 Struct7BytesHomogeneousUint8 a2,
                 Struct7BytesHomogeneousUint8 a3,
                 Struct7BytesHomogeneousUint8 a4,
                 Struct7BytesHomogeneousUint8 a5,
                 Struct7BytesHomogeneousUint8 a6,
                 Struct7BytesHomogeneousUint8 a7,
                 Struct7BytesHomogeneousUint8 a8,
                 Struct7BytesHomogeneousUint8 a9)) {
  Struct7BytesHomogeneousUint8 a0;
  Struct7BytesHomogeneousUint8 a1;
  Struct7BytesHomogeneousUint8 a2;
  Struct7BytesHomogeneousUint8 a3;
  Struct7BytesHomogeneousUint8 a4;
  Struct7BytesHomogeneousUint8 a5;
  Struct7BytesHomogeneousUint8 a6;
  Struct7BytesHomogeneousUint8 a7;
  Struct7BytesHomogeneousUint8 a8;
  Struct7BytesHomogeneousUint8 a9;

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

  std::cout
      << "Calling TestPassStruct7BytesHomogeneousUint8x10("
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << "))"
      << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(2485, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Sub word size on 64 bit architectures.
// With alignment rules taken into account size is 8 bytes.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct7BytesInt4ByteAlignedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct7BytesInt4ByteAligned a0,
                 Struct7BytesInt4ByteAligned a1,
                 Struct7BytesInt4ByteAligned a2,
                 Struct7BytesInt4ByteAligned a3,
                 Struct7BytesInt4ByteAligned a4,
                 Struct7BytesInt4ByteAligned a5,
                 Struct7BytesInt4ByteAligned a6,
                 Struct7BytesInt4ByteAligned a7,
                 Struct7BytesInt4ByteAligned a8,
                 Struct7BytesInt4ByteAligned a9)) {
  Struct7BytesInt4ByteAligned a0;
  Struct7BytesInt4ByteAligned a1;
  Struct7BytesInt4ByteAligned a2;
  Struct7BytesInt4ByteAligned a3;
  Struct7BytesInt4ByteAligned a4;
  Struct7BytesInt4ByteAligned a5;
  Struct7BytesInt4ByteAligned a6;
  Struct7BytesInt4ByteAligned a7;
  Struct7BytesInt4ByteAligned a8;
  Struct7BytesInt4ByteAligned a9;

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

  std::cout << "Calling TestPassStruct7BytesInt4ByteAlignedx10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << static_cast<int>(a0.a2)
            << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << static_cast<int>(a1.a2) << "), (" << a2.a0 << ", " << a2.a1
            << ", " << static_cast<int>(a2.a2) << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << static_cast<int>(a3.a2) << "), (" << a4.a0
            << ", " << a4.a1 << ", " << static_cast<int>(a4.a2) << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << static_cast<int>(a5.a2)
            << "), (" << a6.a0 << ", " << a6.a1 << ", "
            << static_cast<int>(a6.a2) << "), (" << a7.a0 << ", " << a7.a1
            << ", " << static_cast<int>(a7.a2) << "), (" << a8.a0 << ", "
            << a8.a1 << ", " << static_cast<int>(a8.a2) << "), (" << a9.a0
            << ", " << a9.a1 << ", " << static_cast<int>(a9.a2) << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(15, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Exactly word size struct on 64bit architectures.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct8BytesIntx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct8BytesInt a0,
                 Struct8BytesInt a1,
                 Struct8BytesInt a2,
                 Struct8BytesInt a3,
                 Struct8BytesInt a4,
                 Struct8BytesInt a5,
                 Struct8BytesInt a6,
                 Struct8BytesInt a7,
                 Struct8BytesInt a8,
                 Struct8BytesInt a9)) {
  Struct8BytesInt a0;
  Struct8BytesInt a1;
  Struct8BytesInt a2;
  Struct8BytesInt a3;
  Struct8BytesInt a4;
  Struct8BytesInt a5;
  Struct8BytesInt a6;
  Struct8BytesInt a7;
  Struct8BytesInt a8;
  Struct8BytesInt a9;

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

  std::cout << "Calling TestPassStruct8BytesIntx10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << "), (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << "), ("
            << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << "), (" << a9.a0
            << ", " << a9.a1 << ", " << a9.a2 << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(15, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Arguments passed in FP registers as long as they fit.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct8BytesHomogeneousFloatx10(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct8BytesHomogeneousFloat a0,
               Struct8BytesHomogeneousFloat a1,
               Struct8BytesHomogeneousFloat a2,
               Struct8BytesHomogeneousFloat a3,
               Struct8BytesHomogeneousFloat a4,
               Struct8BytesHomogeneousFloat a5,
               Struct8BytesHomogeneousFloat a6,
               Struct8BytesHomogeneousFloat a7,
               Struct8BytesHomogeneousFloat a8,
               Struct8BytesHomogeneousFloat a9)) {
  Struct8BytesHomogeneousFloat a0;
  Struct8BytesHomogeneousFloat a1;
  Struct8BytesHomogeneousFloat a2;
  Struct8BytesHomogeneousFloat a3;
  Struct8BytesHomogeneousFloat a4;
  Struct8BytesHomogeneousFloat a5;
  Struct8BytesHomogeneousFloat a6;
  Struct8BytesHomogeneousFloat a7;
  Struct8BytesHomogeneousFloat a8;
  Struct8BytesHomogeneousFloat a9;

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

  std::cout << "Calling TestPassStruct8BytesHomogeneousFloatx10("
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On x64, arguments go in int registers because it is not only float.
// 10 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct8BytesMixedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct8BytesMixed a0,
               Struct8BytesMixed a1,
               Struct8BytesMixed a2,
               Struct8BytesMixed a3,
               Struct8BytesMixed a4,
               Struct8BytesMixed a5,
               Struct8BytesMixed a6,
               Struct8BytesMixed a7,
               Struct8BytesMixed a8,
               Struct8BytesMixed a9)) {
  Struct8BytesMixed a0;
  Struct8BytesMixed a1;
  Struct8BytesMixed a2;
  Struct8BytesMixed a3;
  Struct8BytesMixed a4;
  Struct8BytesMixed a5;
  Struct8BytesMixed a6;
  Struct8BytesMixed a7;
  Struct8BytesMixed a8;
  Struct8BytesMixed a9;

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

  std::cout << "Calling TestPassStruct8BytesMixedx10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << "), (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << "), ("
            << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << "), (" << a9.a0
            << ", " << a9.a1 << ", " << a9.a2 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(15.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Argument is a single byte over a multiple of word size.
// 10 struct arguments will exhaust available registers.
// Struct only has 1-byte aligned fields to test struct alignment itself.
// Tests upper bytes in the integer registers that are partly filled.
// Tests stack alignment of non word size stack arguments.
DART_EXPORT intptr_t TestPassStruct9BytesHomogeneousUint8x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct9BytesHomogeneousUint8 a0,
                 Struct9BytesHomogeneousUint8 a1,
                 Struct9BytesHomogeneousUint8 a2,
                 Struct9BytesHomogeneousUint8 a3,
                 Struct9BytesHomogeneousUint8 a4,
                 Struct9BytesHomogeneousUint8 a5,
                 Struct9BytesHomogeneousUint8 a6,
                 Struct9BytesHomogeneousUint8 a7,
                 Struct9BytesHomogeneousUint8 a8,
                 Struct9BytesHomogeneousUint8 a9)) {
  Struct9BytesHomogeneousUint8 a0;
  Struct9BytesHomogeneousUint8 a1;
  Struct9BytesHomogeneousUint8 a2;
  Struct9BytesHomogeneousUint8 a3;
  Struct9BytesHomogeneousUint8 a4;
  Struct9BytesHomogeneousUint8 a5;
  Struct9BytesHomogeneousUint8 a6;
  Struct9BytesHomogeneousUint8 a7;
  Struct9BytesHomogeneousUint8 a8;
  Struct9BytesHomogeneousUint8 a9;

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

  std::cout
      << "Calling TestPassStruct9BytesHomogeneousUint8x10("
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << ", " << static_cast<int>(a0.a7)
      << ", " << static_cast<int>(a0.a8) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << ", " << static_cast<int>(a1.a7) << ", " << static_cast<int>(a1.a8)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << ", " << static_cast<int>(a2.a7)
      << ", " << static_cast<int>(a2.a8) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << ", " << static_cast<int>(a3.a7) << ", " << static_cast<int>(a3.a8)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << ", " << static_cast<int>(a4.a7)
      << ", " << static_cast<int>(a4.a8) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << ", " << static_cast<int>(a5.a7) << ", " << static_cast<int>(a5.a8)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << ", " << static_cast<int>(a6.a7)
      << ", " << static_cast<int>(a6.a8) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << ", " << static_cast<int>(a7.a7) << ", " << static_cast<int>(a7.a8)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << ", " << static_cast<int>(a8.a7)
      << ", " << static_cast<int>(a8.a8) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << ", " << static_cast<int>(a9.a7) << ", " << static_cast<int>(a9.a8)
      << "))"
      << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(4095, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Argument is a single byte over a multiple of word size.
// With alignment rules taken into account size is 12 or 16 bytes.
// 10 struct arguments will exhaust available registers.
//
DART_EXPORT intptr_t TestPassStruct9BytesInt4Or8ByteAlignedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct9BytesInt4Or8ByteAligned a0,
                 Struct9BytesInt4Or8ByteAligned a1,
                 Struct9BytesInt4Or8ByteAligned a2,
                 Struct9BytesInt4Or8ByteAligned a3,
                 Struct9BytesInt4Or8ByteAligned a4,
                 Struct9BytesInt4Or8ByteAligned a5,
                 Struct9BytesInt4Or8ByteAligned a6,
                 Struct9BytesInt4Or8ByteAligned a7,
                 Struct9BytesInt4Or8ByteAligned a8,
                 Struct9BytesInt4Or8ByteAligned a9)) {
  Struct9BytesInt4Or8ByteAligned a0;
  Struct9BytesInt4Or8ByteAligned a1;
  Struct9BytesInt4Or8ByteAligned a2;
  Struct9BytesInt4Or8ByteAligned a3;
  Struct9BytesInt4Or8ByteAligned a4;
  Struct9BytesInt4Or8ByteAligned a5;
  Struct9BytesInt4Or8ByteAligned a6;
  Struct9BytesInt4Or8ByteAligned a7;
  Struct9BytesInt4Or8ByteAligned a8;
  Struct9BytesInt4Or8ByteAligned a9;

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

  std::cout << "Calling TestPassStruct9BytesInt4Or8ByteAlignedx10("
            << "((" << a0.a0 << ", " << static_cast<int>(a0.a1) << "), ("
            << a1.a0 << ", " << static_cast<int>(a1.a1) << "), (" << a2.a0
            << ", " << static_cast<int>(a2.a1) << "), (" << a3.a0 << ", "
            << static_cast<int>(a3.a1) << "), (" << a4.a0 << ", "
            << static_cast<int>(a4.a1) << "), (" << a5.a0 << ", "
            << static_cast<int>(a5.a1) << "), (" << a6.a0 << ", "
            << static_cast<int>(a6.a1) << "), (" << a7.a0 << ", "
            << static_cast<int>(a7.a1) << "), (" << a8.a0 << ", "
            << static_cast<int>(a8.a1) << "), (" << a9.a0 << ", "
            << static_cast<int>(a9.a1) << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(10, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Arguments in FPU registers on arm hardfp and arm64.
// Struct arguments will exhaust available registers, and leave some empty.
// The last argument is to test whether arguments are backfilled.
DART_EXPORT intptr_t TestPassStruct12BytesHomogeneousFloatx6(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct12BytesHomogeneousFloat a0,
               Struct12BytesHomogeneousFloat a1,
               Struct12BytesHomogeneousFloat a2,
               Struct12BytesHomogeneousFloat a3,
               Struct12BytesHomogeneousFloat a4,
               Struct12BytesHomogeneousFloat a5)) {
  Struct12BytesHomogeneousFloat a0;
  Struct12BytesHomogeneousFloat a1;
  Struct12BytesHomogeneousFloat a2;
  Struct12BytesHomogeneousFloat a3;
  Struct12BytesHomogeneousFloat a4;
  Struct12BytesHomogeneousFloat a5;

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

  std::cout << "Calling TestPassStruct12BytesHomogeneousFloatx6("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << "), ("
            << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << a3.a2 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << "), (" << a5.a0 << ", " << a5.a1 << ", "
            << a5.a2 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(9.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On Linux x64 argument is transferred on stack because it is over 16 bytes.
// Arguments in FPU registers on arm hardfp and arm64.
// 5 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct16BytesHomogeneousFloatx5(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct16BytesHomogeneousFloat a0,
               Struct16BytesHomogeneousFloat a1,
               Struct16BytesHomogeneousFloat a2,
               Struct16BytesHomogeneousFloat a3,
               Struct16BytesHomogeneousFloat a4)) {
  Struct16BytesHomogeneousFloat a0;
  Struct16BytesHomogeneousFloat a1;
  Struct16BytesHomogeneousFloat a2;
  Struct16BytesHomogeneousFloat a3;
  Struct16BytesHomogeneousFloat a4;

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

  std::cout << "Calling TestPassStruct16BytesHomogeneousFloatx5("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On x64, arguments are split over FP and int registers.
// On x64, it will exhaust the integer registers with the 6th argument.
// The rest goes on the stack.
// On arm, arguments are 8 byte aligned.
DART_EXPORT intptr_t TestPassStruct16BytesMixedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(Struct16BytesMixed a0,
                Struct16BytesMixed a1,
                Struct16BytesMixed a2,
                Struct16BytesMixed a3,
                Struct16BytesMixed a4,
                Struct16BytesMixed a5,
                Struct16BytesMixed a6,
                Struct16BytesMixed a7,
                Struct16BytesMixed a8,
                Struct16BytesMixed a9)) {
  Struct16BytesMixed a0;
  Struct16BytesMixed a1;
  Struct16BytesMixed a2;
  Struct16BytesMixed a3;
  Struct16BytesMixed a4;
  Struct16BytesMixed a5;
  Struct16BytesMixed a6;
  Struct16BytesMixed a7;
  Struct16BytesMixed a8;
  Struct16BytesMixed a9;

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

  std::cout << "Calling TestPassStruct16BytesMixedx10("
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "), (" << a2.a0 << ", " << a2.a1 << "), (" << a3.a0
            << ", " << a3.a1 << "), (" << a4.a0 << ", " << a4.a1 << "), ("
            << a5.a0 << ", " << a5.a1 << "), (" << a6.a0 << ", " << a6.a1
            << "), (" << a7.a0 << ", " << a7.a1 << "), (" << a8.a0 << ", "
            << a8.a1 << "), (" << a9.a0 << ", " << a9.a1 << "))"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On x64, arguments are split over FP and int registers.
// On x64, it will exhaust the integer registers with the 6th argument.
// The rest goes on the stack.
// On arm, arguments are 4 byte aligned.
DART_EXPORT intptr_t TestPassStruct16BytesMixed2x10(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct16BytesMixed2 a0,
               Struct16BytesMixed2 a1,
               Struct16BytesMixed2 a2,
               Struct16BytesMixed2 a3,
               Struct16BytesMixed2 a4,
               Struct16BytesMixed2 a5,
               Struct16BytesMixed2 a6,
               Struct16BytesMixed2 a7,
               Struct16BytesMixed2 a8,
               Struct16BytesMixed2 a9)) {
  Struct16BytesMixed2 a0;
  Struct16BytesMixed2 a1;
  Struct16BytesMixed2 a2;
  Struct16BytesMixed2 a3;
  Struct16BytesMixed2 a4;
  Struct16BytesMixed2 a5;
  Struct16BytesMixed2 a6;
  Struct16BytesMixed2 a7;
  Struct16BytesMixed2 a8;
  Struct16BytesMixed2 a9;

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

  std::cout << "Calling TestPassStruct16BytesMixed2x10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "), (" << a5.a0 << ", "
            << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), (" << a6.a0
            << ", " << a6.a1 << ", " << a6.a2 << ", " << a6.a3 << "), ("
            << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), (" << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << ", "
            << a8.a3 << "), (" << a9.a0 << ", " << a9.a1 << ", " << a9.a2
            << ", " << a9.a3 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(20.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Arguments are passed as pointer to copy on arm64.
// Tests that the memory allocated for copies are rounded up to word size.
DART_EXPORT intptr_t TestPassStruct17BytesIntx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct17BytesInt a0,
                 Struct17BytesInt a1,
                 Struct17BytesInt a2,
                 Struct17BytesInt a3,
                 Struct17BytesInt a4,
                 Struct17BytesInt a5,
                 Struct17BytesInt a6,
                 Struct17BytesInt a7,
                 Struct17BytesInt a8,
                 Struct17BytesInt a9)) {
  Struct17BytesInt a0;
  Struct17BytesInt a1;
  Struct17BytesInt a2;
  Struct17BytesInt a3;
  Struct17BytesInt a4;
  Struct17BytesInt a5;
  Struct17BytesInt a6;
  Struct17BytesInt a7;
  Struct17BytesInt a8;
  Struct17BytesInt a9;

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

  std::cout << "Calling TestPassStruct17BytesIntx10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << static_cast<int>(a0.a2)
            << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << static_cast<int>(a1.a2) << "), (" << a2.a0 << ", " << a2.a1
            << ", " << static_cast<int>(a2.a2) << "), (" << a3.a0 << ", "
            << a3.a1 << ", " << static_cast<int>(a3.a2) << "), (" << a4.a0
            << ", " << a4.a1 << ", " << static_cast<int>(a4.a2) << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << static_cast<int>(a5.a2)
            << "), (" << a6.a0 << ", " << a6.a1 << ", "
            << static_cast<int>(a6.a2) << "), (" << a7.a0 << ", " << a7.a1
            << ", " << static_cast<int>(a7.a2) << "), (" << a8.a0 << ", "
            << a8.a1 << ", " << static_cast<int>(a8.a2) << "), (" << a9.a0
            << ", " << a9.a1 << ", " << static_cast<int>(a9.a2) << "))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(15, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is extended to the right size.
//
DART_EXPORT intptr_t TestPassStruct19BytesHomogeneousUint8x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct19BytesHomogeneousUint8 a0,
                 Struct19BytesHomogeneousUint8 a1,
                 Struct19BytesHomogeneousUint8 a2,
                 Struct19BytesHomogeneousUint8 a3,
                 Struct19BytesHomogeneousUint8 a4,
                 Struct19BytesHomogeneousUint8 a5,
                 Struct19BytesHomogeneousUint8 a6,
                 Struct19BytesHomogeneousUint8 a7,
                 Struct19BytesHomogeneousUint8 a8,
                 Struct19BytesHomogeneousUint8 a9)) {
  Struct19BytesHomogeneousUint8 a0;
  Struct19BytesHomogeneousUint8 a1;
  Struct19BytesHomogeneousUint8 a2;
  Struct19BytesHomogeneousUint8 a3;
  Struct19BytesHomogeneousUint8 a4;
  Struct19BytesHomogeneousUint8 a5;
  Struct19BytesHomogeneousUint8 a6;
  Struct19BytesHomogeneousUint8 a7;
  Struct19BytesHomogeneousUint8 a8;
  Struct19BytesHomogeneousUint8 a9;

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

  std::cout
      << "Calling TestPassStruct19BytesHomogeneousUint8x10("
      << "((" << static_cast<int>(a0.a0) << ", " << static_cast<int>(a0.a1)
      << ", " << static_cast<int>(a0.a2) << ", " << static_cast<int>(a0.a3)
      << ", " << static_cast<int>(a0.a4) << ", " << static_cast<int>(a0.a5)
      << ", " << static_cast<int>(a0.a6) << ", " << static_cast<int>(a0.a7)
      << ", " << static_cast<int>(a0.a8) << ", " << static_cast<int>(a0.a9)
      << ", " << static_cast<int>(a0.a10) << ", " << static_cast<int>(a0.a11)
      << ", " << static_cast<int>(a0.a12) << ", " << static_cast<int>(a0.a13)
      << ", " << static_cast<int>(a0.a14) << ", " << static_cast<int>(a0.a15)
      << ", " << static_cast<int>(a0.a16) << ", " << static_cast<int>(a0.a17)
      << ", " << static_cast<int>(a0.a18) << "), (" << static_cast<int>(a1.a0)
      << ", " << static_cast<int>(a1.a1) << ", " << static_cast<int>(a1.a2)
      << ", " << static_cast<int>(a1.a3) << ", " << static_cast<int>(a1.a4)
      << ", " << static_cast<int>(a1.a5) << ", " << static_cast<int>(a1.a6)
      << ", " << static_cast<int>(a1.a7) << ", " << static_cast<int>(a1.a8)
      << ", " << static_cast<int>(a1.a9) << ", " << static_cast<int>(a1.a10)
      << ", " << static_cast<int>(a1.a11) << ", " << static_cast<int>(a1.a12)
      << ", " << static_cast<int>(a1.a13) << ", " << static_cast<int>(a1.a14)
      << ", " << static_cast<int>(a1.a15) << ", " << static_cast<int>(a1.a16)
      << ", " << static_cast<int>(a1.a17) << ", " << static_cast<int>(a1.a18)
      << "), (" << static_cast<int>(a2.a0) << ", " << static_cast<int>(a2.a1)
      << ", " << static_cast<int>(a2.a2) << ", " << static_cast<int>(a2.a3)
      << ", " << static_cast<int>(a2.a4) << ", " << static_cast<int>(a2.a5)
      << ", " << static_cast<int>(a2.a6) << ", " << static_cast<int>(a2.a7)
      << ", " << static_cast<int>(a2.a8) << ", " << static_cast<int>(a2.a9)
      << ", " << static_cast<int>(a2.a10) << ", " << static_cast<int>(a2.a11)
      << ", " << static_cast<int>(a2.a12) << ", " << static_cast<int>(a2.a13)
      << ", " << static_cast<int>(a2.a14) << ", " << static_cast<int>(a2.a15)
      << ", " << static_cast<int>(a2.a16) << ", " << static_cast<int>(a2.a17)
      << ", " << static_cast<int>(a2.a18) << "), (" << static_cast<int>(a3.a0)
      << ", " << static_cast<int>(a3.a1) << ", " << static_cast<int>(a3.a2)
      << ", " << static_cast<int>(a3.a3) << ", " << static_cast<int>(a3.a4)
      << ", " << static_cast<int>(a3.a5) << ", " << static_cast<int>(a3.a6)
      << ", " << static_cast<int>(a3.a7) << ", " << static_cast<int>(a3.a8)
      << ", " << static_cast<int>(a3.a9) << ", " << static_cast<int>(a3.a10)
      << ", " << static_cast<int>(a3.a11) << ", " << static_cast<int>(a3.a12)
      << ", " << static_cast<int>(a3.a13) << ", " << static_cast<int>(a3.a14)
      << ", " << static_cast<int>(a3.a15) << ", " << static_cast<int>(a3.a16)
      << ", " << static_cast<int>(a3.a17) << ", " << static_cast<int>(a3.a18)
      << "), (" << static_cast<int>(a4.a0) << ", " << static_cast<int>(a4.a1)
      << ", " << static_cast<int>(a4.a2) << ", " << static_cast<int>(a4.a3)
      << ", " << static_cast<int>(a4.a4) << ", " << static_cast<int>(a4.a5)
      << ", " << static_cast<int>(a4.a6) << ", " << static_cast<int>(a4.a7)
      << ", " << static_cast<int>(a4.a8) << ", " << static_cast<int>(a4.a9)
      << ", " << static_cast<int>(a4.a10) << ", " << static_cast<int>(a4.a11)
      << ", " << static_cast<int>(a4.a12) << ", " << static_cast<int>(a4.a13)
      << ", " << static_cast<int>(a4.a14) << ", " << static_cast<int>(a4.a15)
      << ", " << static_cast<int>(a4.a16) << ", " << static_cast<int>(a4.a17)
      << ", " << static_cast<int>(a4.a18) << "), (" << static_cast<int>(a5.a0)
      << ", " << static_cast<int>(a5.a1) << ", " << static_cast<int>(a5.a2)
      << ", " << static_cast<int>(a5.a3) << ", " << static_cast<int>(a5.a4)
      << ", " << static_cast<int>(a5.a5) << ", " << static_cast<int>(a5.a6)
      << ", " << static_cast<int>(a5.a7) << ", " << static_cast<int>(a5.a8)
      << ", " << static_cast<int>(a5.a9) << ", " << static_cast<int>(a5.a10)
      << ", " << static_cast<int>(a5.a11) << ", " << static_cast<int>(a5.a12)
      << ", " << static_cast<int>(a5.a13) << ", " << static_cast<int>(a5.a14)
      << ", " << static_cast<int>(a5.a15) << ", " << static_cast<int>(a5.a16)
      << ", " << static_cast<int>(a5.a17) << ", " << static_cast<int>(a5.a18)
      << "), (" << static_cast<int>(a6.a0) << ", " << static_cast<int>(a6.a1)
      << ", " << static_cast<int>(a6.a2) << ", " << static_cast<int>(a6.a3)
      << ", " << static_cast<int>(a6.a4) << ", " << static_cast<int>(a6.a5)
      << ", " << static_cast<int>(a6.a6) << ", " << static_cast<int>(a6.a7)
      << ", " << static_cast<int>(a6.a8) << ", " << static_cast<int>(a6.a9)
      << ", " << static_cast<int>(a6.a10) << ", " << static_cast<int>(a6.a11)
      << ", " << static_cast<int>(a6.a12) << ", " << static_cast<int>(a6.a13)
      << ", " << static_cast<int>(a6.a14) << ", " << static_cast<int>(a6.a15)
      << ", " << static_cast<int>(a6.a16) << ", " << static_cast<int>(a6.a17)
      << ", " << static_cast<int>(a6.a18) << "), (" << static_cast<int>(a7.a0)
      << ", " << static_cast<int>(a7.a1) << ", " << static_cast<int>(a7.a2)
      << ", " << static_cast<int>(a7.a3) << ", " << static_cast<int>(a7.a4)
      << ", " << static_cast<int>(a7.a5) << ", " << static_cast<int>(a7.a6)
      << ", " << static_cast<int>(a7.a7) << ", " << static_cast<int>(a7.a8)
      << ", " << static_cast<int>(a7.a9) << ", " << static_cast<int>(a7.a10)
      << ", " << static_cast<int>(a7.a11) << ", " << static_cast<int>(a7.a12)
      << ", " << static_cast<int>(a7.a13) << ", " << static_cast<int>(a7.a14)
      << ", " << static_cast<int>(a7.a15) << ", " << static_cast<int>(a7.a16)
      << ", " << static_cast<int>(a7.a17) << ", " << static_cast<int>(a7.a18)
      << "), (" << static_cast<int>(a8.a0) << ", " << static_cast<int>(a8.a1)
      << ", " << static_cast<int>(a8.a2) << ", " << static_cast<int>(a8.a3)
      << ", " << static_cast<int>(a8.a4) << ", " << static_cast<int>(a8.a5)
      << ", " << static_cast<int>(a8.a6) << ", " << static_cast<int>(a8.a7)
      << ", " << static_cast<int>(a8.a8) << ", " << static_cast<int>(a8.a9)
      << ", " << static_cast<int>(a8.a10) << ", " << static_cast<int>(a8.a11)
      << ", " << static_cast<int>(a8.a12) << ", " << static_cast<int>(a8.a13)
      << ", " << static_cast<int>(a8.a14) << ", " << static_cast<int>(a8.a15)
      << ", " << static_cast<int>(a8.a16) << ", " << static_cast<int>(a8.a17)
      << ", " << static_cast<int>(a8.a18) << "), (" << static_cast<int>(a9.a0)
      << ", " << static_cast<int>(a9.a1) << ", " << static_cast<int>(a9.a2)
      << ", " << static_cast<int>(a9.a3) << ", " << static_cast<int>(a9.a4)
      << ", " << static_cast<int>(a9.a5) << ", " << static_cast<int>(a9.a6)
      << ", " << static_cast<int>(a9.a7) << ", " << static_cast<int>(a9.a8)
      << ", " << static_cast<int>(a9.a9) << ", " << static_cast<int>(a9.a10)
      << ", " << static_cast<int>(a9.a11) << ", " << static_cast<int>(a9.a12)
      << ", " << static_cast<int>(a9.a13) << ", " << static_cast<int>(a9.a14)
      << ", " << static_cast<int>(a9.a15) << ", " << static_cast<int>(a9.a16)
      << ", " << static_cast<int>(a9.a17) << ", " << static_cast<int>(a9.a18)
      << "))"
      << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(18145, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Argument too big to go into integer registers on arm64.
// The arguments are passed as pointers to copies.
// The amount of arguments exhausts the number of integer registers, such that
// pointers to copies are also passed on the stack.
DART_EXPORT intptr_t TestPassStruct20BytesHomogeneousInt32x10(
    // NOLINTNEXTLINE(whitespace/parens)
    int32_t (*f)(Struct20BytesHomogeneousInt32 a0,
                 Struct20BytesHomogeneousInt32 a1,
                 Struct20BytesHomogeneousInt32 a2,
                 Struct20BytesHomogeneousInt32 a3,
                 Struct20BytesHomogeneousInt32 a4,
                 Struct20BytesHomogeneousInt32 a5,
                 Struct20BytesHomogeneousInt32 a6,
                 Struct20BytesHomogeneousInt32 a7,
                 Struct20BytesHomogeneousInt32 a8,
                 Struct20BytesHomogeneousInt32 a9)) {
  Struct20BytesHomogeneousInt32 a0;
  Struct20BytesHomogeneousInt32 a1;
  Struct20BytesHomogeneousInt32 a2;
  Struct20BytesHomogeneousInt32 a3;
  Struct20BytesHomogeneousInt32 a4;
  Struct20BytesHomogeneousInt32 a5;
  Struct20BytesHomogeneousInt32 a6;
  Struct20BytesHomogeneousInt32 a7;
  Struct20BytesHomogeneousInt32 a8;
  Struct20BytesHomogeneousInt32 a9;

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

  std::cout << "Calling TestPassStruct20BytesHomogeneousInt32x10("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "), (" << a1.a0 << ", " << a1.a1 << ", "
            << a1.a2 << ", " << a1.a3 << ", " << a1.a4 << "), (" << a2.a0
            << ", " << a2.a1 << ", " << a2.a2 << ", " << a2.a3 << ", " << a2.a4
            << "), (" << a3.a0 << ", " << a3.a1 << ", " << a3.a2 << ", "
            << a3.a3 << ", " << a3.a4 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << ", " << a4.a4 << "), ("
            << a5.a0 << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << ", "
            << a5.a4 << "), (" << a6.a0 << ", " << a6.a1 << ", " << a6.a2
            << ", " << a6.a3 << ", " << a6.a4 << "), (" << a7.a0 << ", "
            << a7.a1 << ", " << a7.a2 << ", " << a7.a3 << ", " << a7.a4
            << "), (" << a8.a0 << ", " << a8.a1 << ", " << a8.a2 << ", "
            << a8.a3 << ", " << a8.a4 << "), (" << a9.a0 << ", " << a9.a1
            << ", " << a9.a2 << ", " << a9.a3 << ", " << a9.a4 << "))"
            << ")\n";

  int32_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(25, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Argument too big to go into FPU registers in hardfp and arm64.
DART_EXPORT intptr_t TestPassStruct20BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct20BytesHomogeneousFloat a0)) {
  Struct20BytesHomogeneousFloat a0;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;

  std::cout << "Calling TestPassStruct20BytesHomogeneousFloat("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << ")\n";

  float result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-3.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Arguments in FPU registers on arm64.
// 5 struct arguments will exhaust available registers.
DART_EXPORT intptr_t TestPassStruct32BytesHomogeneousDoublex5(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(Struct32BytesHomogeneousDouble a0,
                Struct32BytesHomogeneousDouble a1,
                Struct32BytesHomogeneousDouble a2,
                Struct32BytesHomogeneousDouble a3,
                Struct32BytesHomogeneousDouble a4)) {
  Struct32BytesHomogeneousDouble a0;
  Struct32BytesHomogeneousDouble a1;
  Struct32BytesHomogeneousDouble a2;
  Struct32BytesHomogeneousDouble a3;
  Struct32BytesHomogeneousDouble a4;

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

  std::cout << "Calling TestPassStruct32BytesHomogeneousDoublex5("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << "), (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2 << ", "
            << a1.a3 << "), (" << a2.a0 << ", " << a2.a1 << ", " << a2.a2
            << ", " << a2.a3 << "), (" << a3.a0 << ", " << a3.a1 << ", "
            << a3.a2 << ", " << a3.a3 << "), (" << a4.a0 << ", " << a4.a1
            << ", " << a4.a2 << ", " << a4.a3 << "))"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Argument too big to go into FPU registers in arm64.
DART_EXPORT intptr_t TestPassStruct40BytesHomogeneousDouble(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(Struct40BytesHomogeneousDouble a0)) {
  Struct40BytesHomogeneousDouble a0;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;

  std::cout << "Calling TestPassStruct40BytesHomogeneousDouble("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << ")\n";

  double result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-3.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Test 1kb struct.
DART_EXPORT intptr_t TestPassStruct1024BytesHomogeneousUint64(
    // NOLINTNEXTLINE(whitespace/parens)
    uint64_t (*f)(Struct1024BytesHomogeneousUint64 a0)) {
  Struct1024BytesHomogeneousUint64 a0;

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

  std::cout << "Calling TestPassStruct1024BytesHomogeneousUint64("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << ", " << a0.a5 << ", " << a0.a6 << ", " << a0.a7
            << ", " << a0.a8 << ", " << a0.a9 << ", " << a0.a10 << ", "
            << a0.a11 << ", " << a0.a12 << ", " << a0.a13 << ", " << a0.a14
            << ", " << a0.a15 << ", " << a0.a16 << ", " << a0.a17 << ", "
            << a0.a18 << ", " << a0.a19 << ", " << a0.a20 << ", " << a0.a21
            << ", " << a0.a22 << ", " << a0.a23 << ", " << a0.a24 << ", "
            << a0.a25 << ", " << a0.a26 << ", " << a0.a27 << ", " << a0.a28
            << ", " << a0.a29 << ", " << a0.a30 << ", " << a0.a31 << ", "
            << a0.a32 << ", " << a0.a33 << ", " << a0.a34 << ", " << a0.a35
            << ", " << a0.a36 << ", " << a0.a37 << ", " << a0.a38 << ", "
            << a0.a39 << ", " << a0.a40 << ", " << a0.a41 << ", " << a0.a42
            << ", " << a0.a43 << ", " << a0.a44 << ", " << a0.a45 << ", "
            << a0.a46 << ", " << a0.a47 << ", " << a0.a48 << ", " << a0.a49
            << ", " << a0.a50 << ", " << a0.a51 << ", " << a0.a52 << ", "
            << a0.a53 << ", " << a0.a54 << ", " << a0.a55 << ", " << a0.a56
            << ", " << a0.a57 << ", " << a0.a58 << ", " << a0.a59 << ", "
            << a0.a60 << ", " << a0.a61 << ", " << a0.a62 << ", " << a0.a63
            << ", " << a0.a64 << ", " << a0.a65 << ", " << a0.a66 << ", "
            << a0.a67 << ", " << a0.a68 << ", " << a0.a69 << ", " << a0.a70
            << ", " << a0.a71 << ", " << a0.a72 << ", " << a0.a73 << ", "
            << a0.a74 << ", " << a0.a75 << ", " << a0.a76 << ", " << a0.a77
            << ", " << a0.a78 << ", " << a0.a79 << ", " << a0.a80 << ", "
            << a0.a81 << ", " << a0.a82 << ", " << a0.a83 << ", " << a0.a84
            << ", " << a0.a85 << ", " << a0.a86 << ", " << a0.a87 << ", "
            << a0.a88 << ", " << a0.a89 << ", " << a0.a90 << ", " << a0.a91
            << ", " << a0.a92 << ", " << a0.a93 << ", " << a0.a94 << ", "
            << a0.a95 << ", " << a0.a96 << ", " << a0.a97 << ", " << a0.a98
            << ", " << a0.a99 << ", " << a0.a100 << ", " << a0.a101 << ", "
            << a0.a102 << ", " << a0.a103 << ", " << a0.a104 << ", " << a0.a105
            << ", " << a0.a106 << ", " << a0.a107 << ", " << a0.a108 << ", "
            << a0.a109 << ", " << a0.a110 << ", " << a0.a111 << ", " << a0.a112
            << ", " << a0.a113 << ", " << a0.a114 << ", " << a0.a115 << ", "
            << a0.a116 << ", " << a0.a117 << ", " << a0.a118 << ", " << a0.a119
            << ", " << a0.a120 << ", " << a0.a121 << ", " << a0.a122 << ", "
            << a0.a123 << ", " << a0.a124 << ", " << a0.a125 << ", " << a0.a126
            << ", " << a0.a127 << "))"
            << ")\n";

  uint64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(8256, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Tests the alignment of structs in FPU registers and backfilling.
DART_EXPORT intptr_t TestPassFloatStruct16BytesHomogeneousFloatFloatStruct1(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(float a0,
               Struct16BytesHomogeneousFloat a1,
               float a2,
               Struct16BytesHomogeneousFloat a3,
               float a4,
               Struct16BytesHomogeneousFloat a5,
               float a6,
               Struct16BytesHomogeneousFloat a7,
               float a8)) {
  float a0;
  Struct16BytesHomogeneousFloat a1;
  float a2;
  Struct16BytesHomogeneousFloat a3;
  float a4;
  Struct16BytesHomogeneousFloat a5;
  float a6;
  Struct16BytesHomogeneousFloat a7;
  float a8;

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

  std::cout << "Calling TestPassFloatStruct16BytesHomogeneousFloatFloatStruct1("
            << "(" << a0 << ", (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2
            << ", " << a1.a3 << "), " << a2 << ", (" << a3.a0 << ", " << a3.a1
            << ", " << a3.a2 << ", " << a3.a3 << "), " << a4 << ", (" << a5.a0
            << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), " << a6
            << ", (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), " << a8 << ")"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-11.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Tests the alignment of structs in FPU registers and backfilling.
DART_EXPORT intptr_t TestPassFloatStruct32BytesHomogeneousDoubleFloatStruct(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(float a0,
                Struct32BytesHomogeneousDouble a1,
                float a2,
                Struct32BytesHomogeneousDouble a3,
                float a4,
                Struct32BytesHomogeneousDouble a5,
                float a6,
                Struct32BytesHomogeneousDouble a7,
                float a8)) {
  float a0;
  Struct32BytesHomogeneousDouble a1;
  float a2;
  Struct32BytesHomogeneousDouble a3;
  float a4;
  Struct32BytesHomogeneousDouble a5;
  float a6;
  Struct32BytesHomogeneousDouble a7;
  float a8;

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

  std::cout << "Calling TestPassFloatStruct32BytesHomogeneousDoubleFloatStruct("
            << "(" << a0 << ", (" << a1.a0 << ", " << a1.a1 << ", " << a1.a2
            << ", " << a1.a3 << "), " << a2 << ", (" << a3.a0 << ", " << a3.a1
            << ", " << a3.a2 << ", " << a3.a3 << "), " << a4 << ", (" << a5.a0
            << ", " << a5.a1 << ", " << a5.a2 << ", " << a5.a3 << "), " << a6
            << ", (" << a7.a0 << ", " << a7.a1 << ", " << a7.a2 << ", " << a7.a3
            << "), " << a8 << ")"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-11.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Tests the alignment of structs in integers registers and on the stack.
// Arm32 aligns this struct at 8.
// Also, arm32 allocates the second struct partially in registers, partially
// on stack.
// Test backfilling of integer registers.
DART_EXPORT intptr_t TestPassInt8Struct16BytesMixedInt8Struct16BytesMixedIn(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(int8_t a0,
                Struct16BytesMixed a1,
                int8_t a2,
                Struct16BytesMixed a3,
                int8_t a4,
                Struct16BytesMixed a5,
                int8_t a6,
                Struct16BytesMixed a7,
                int8_t a8)) {
  int8_t a0;
  Struct16BytesMixed a1;
  int8_t a2;
  Struct16BytesMixed a3;
  int8_t a4;
  Struct16BytesMixed a5;
  int8_t a6;
  Struct16BytesMixed a7;
  int8_t a8;

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

  std::cout << "Calling TestPassInt8Struct16BytesMixedInt8Struct16BytesMixedIn("
            << "(" << static_cast<int>(a0) << ", (" << a1.a0 << ", " << a1.a1
            << "), " << static_cast<int>(a2) << ", (" << a3.a0 << ", " << a3.a1
            << "), " << static_cast<int>(a4) << ", (" << a5.a0 << ", " << a5.a1
            << "), " << static_cast<int>(a6) << ", (" << a7.a0 << ", " << a7.a1
            << "), " << static_cast<int>(a8) << ")"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-7.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On Linux x64, it will exhaust xmm registers first, after 6 doubles and 2
// structs. The rest of the structs will go on the stack.
// The int will be backfilled into the int register.
DART_EXPORT intptr_t TestPassDoublex6Struct16BytesMixedx4Int32(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(double a0,
                double a1,
                double a2,
                double a3,
                double a4,
                double a5,
                Struct16BytesMixed a6,
                Struct16BytesMixed a7,
                Struct16BytesMixed a8,
                Struct16BytesMixed a9,
                int32_t a10)) {
  double a0;
  double a1;
  double a2;
  double a3;
  double a4;
  double a5;
  Struct16BytesMixed a6;
  Struct16BytesMixed a7;
  Struct16BytesMixed a8;
  Struct16BytesMixed a9;
  int32_t a10;

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

  std::cout << "Calling TestPassDoublex6Struct16BytesMixedx4Int32("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", (" << a6.a0 << ", " << a6.a1 << "), (" << a7.a0
            << ", " << a7.a1 << "), (" << a8.a0 << ", " << a8.a1 << "), ("
            << a9.a0 << ", " << a9.a1 << "), " << a10 << ")"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-8.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On Linux x64, it will exhaust int registers first.
// The rest of the structs will go on the stack.
// The double will be backfilled into the xmm register.
DART_EXPORT intptr_t TestPassInt32x4Struct16BytesMixedx4Double(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(int32_t a0,
                int32_t a1,
                int32_t a2,
                int32_t a3,
                Struct16BytesMixed a4,
                Struct16BytesMixed a5,
                Struct16BytesMixed a6,
                Struct16BytesMixed a7,
                double a8)) {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  Struct16BytesMixed a4;
  Struct16BytesMixed a5;
  Struct16BytesMixed a6;
  Struct16BytesMixed a7;
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

  std::cout << "Calling TestPassInt32x4Struct16BytesMixedx4Double("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", ("
            << a4.a0 << ", " << a4.a1 << "), (" << a5.a0 << ", " << a5.a1
            << "), (" << a6.a0 << ", " << a6.a1 << "), (" << a7.a0 << ", "
            << a7.a1 << "), " << a8 << ")"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-7.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// On various architectures, first struct is allocated on stack.
// Check that the other two arguments are allocated on registers.
DART_EXPORT intptr_t TestPassStruct40BytesHomogeneousDoubleStruct4BytesHomo(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(Struct40BytesHomogeneousDouble a0,
                Struct4BytesHomogeneousInt16 a1,
                Struct8BytesHomogeneousFloat a2)) {
  Struct40BytesHomogeneousDouble a0;
  Struct4BytesHomogeneousInt16 a1;
  Struct8BytesHomogeneousFloat a2;

  a0.a0 = -1.0;
  a0.a1 = 2.0;
  a0.a2 = -3.0;
  a0.a3 = 4.0;
  a0.a4 = -5.0;
  a1.a0 = 6;
  a1.a1 = -7;
  a2.a0 = 8.0;
  a2.a1 = -9.0;

  std::cout << "Calling TestPassStruct40BytesHomogeneousDoubleStruct4BytesHomo("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "), (" << a1.a0 << ", " << a1.a1 << "), ("
            << a2.a0 << ", " << a2.a1 << "))"
            << ")\n";

  double result = f(a0, a1, a2);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(-5.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT intptr_t TestPassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(int32_t a0,
                int32_t a1,
                int32_t a2,
                int32_t a3,
                int32_t a4,
                int32_t a5,
                int32_t a6,
                int32_t a7,
                double a8,
                double a9,
                double a10,
                double a11,
                double a12,
                double a13,
                double a14,
                double a15,
                int64_t a16,
                int8_t a17,
                Struct1ByteInt a18,
                int64_t a19,
                int8_t a20,
                Struct4BytesHomogeneousInt16 a21,
                int64_t a22,
                int8_t a23,
                Struct8BytesInt a24,
                int64_t a25,
                int8_t a26,
                Struct8BytesHomogeneousFloat a27,
                int64_t a28,
                int8_t a29,
                Struct8BytesMixed a30,
                int64_t a31,
                int8_t a32,
                StructAlignmentInt16 a33,
                int64_t a34,
                int8_t a35,
                StructAlignmentInt32 a36,
                int64_t a37,
                int8_t a38,
                StructAlignmentInt64 a39)) {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  int32_t a4;
  int32_t a5;
  int32_t a6;
  int32_t a7;
  double a8;
  double a9;
  double a10;
  double a11;
  double a12;
  double a13;
  double a14;
  double a15;
  int64_t a16;
  int8_t a17;
  Struct1ByteInt a18;
  int64_t a19;
  int8_t a20;
  Struct4BytesHomogeneousInt16 a21;
  int64_t a22;
  int8_t a23;
  Struct8BytesInt a24;
  int64_t a25;
  int8_t a26;
  Struct8BytesHomogeneousFloat a27;
  int64_t a28;
  int8_t a29;
  Struct8BytesMixed a30;
  int64_t a31;
  int8_t a32;
  StructAlignmentInt16 a33;
  int64_t a34;
  int8_t a35;
  StructAlignmentInt32 a36;
  int64_t a37;
  int8_t a38;
  StructAlignmentInt64 a39;

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

  std::cout << "Calling TestPassInt32x8Doublex8Int64Int8Struct1ByteIntInt64Int("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", " << a8 << ", "
            << a9 << ", " << a10 << ", " << a11 << ", " << a12 << ", " << a13
            << ", " << a14 << ", " << a15 << ", " << a16 << ", "
            << static_cast<int>(a17) << ", (" << static_cast<int>(a18.a0)
            << "), " << a19 << ", " << static_cast<int>(a20) << ", (" << a21.a0
            << ", " << a21.a1 << "), " << a22 << ", " << static_cast<int>(a23)
            << ", (" << a24.a0 << ", " << a24.a1 << ", " << a24.a2 << "), "
            << a25 << ", " << static_cast<int>(a26) << ", (" << a27.a0 << ", "
            << a27.a1 << "), " << a28 << ", " << static_cast<int>(a29) << ", ("
            << a30.a0 << ", " << a30.a1 << ", " << a30.a2 << "), " << a31
            << ", " << static_cast<int>(a32) << ", ("
            << static_cast<int>(a33.a0) << ", " << a33.a1 << ", "
            << static_cast<int>(a33.a2) << "), " << a34 << ", "
            << static_cast<int>(a35) << ", (" << static_cast<int>(a36.a0)
            << ", " << a36.a1 << ", " << static_cast<int>(a36.a2) << "), "
            << a37 << ", " << static_cast<int>(a38) << ", ("
            << static_cast<int>(a39.a0) << ", " << a39.a1 << ", "
            << static_cast<int>(a39.a2) << "))"
            << ")\n";

  double result =
      f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15,
        a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31, a32, a33, a34, a35, a36, a37, a38, a39);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(26.0, result);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14,
             a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27,
             a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14,
             a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27,
             a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT intptr_t TestPassStructAlignmentInt16(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructAlignmentInt16 a0)) {
  StructAlignmentInt16 a0;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  std::cout << "Calling TestPassStructAlignmentInt16("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(-2, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 32 byte int within struct.
DART_EXPORT intptr_t TestPassStructAlignmentInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructAlignmentInt32 a0)) {
  StructAlignmentInt32 a0;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  std::cout << "Calling TestPassStructAlignmentInt32("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(-2, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 64 byte int within struct.
DART_EXPORT intptr_t TestPassStructAlignmentInt64(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructAlignmentInt64 a0)) {
  StructAlignmentInt64 a0;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;

  std::cout << "Calling TestPassStructAlignmentInt64("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(-2, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust registers on all platforms.
DART_EXPORT intptr_t TestPassStruct8BytesNestedIntx10(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct8BytesNestedInt a0,
                 Struct8BytesNestedInt a1,
                 Struct8BytesNestedInt a2,
                 Struct8BytesNestedInt a3,
                 Struct8BytesNestedInt a4,
                 Struct8BytesNestedInt a5,
                 Struct8BytesNestedInt a6,
                 Struct8BytesNestedInt a7,
                 Struct8BytesNestedInt a8,
                 Struct8BytesNestedInt a9)) {
  Struct8BytesNestedInt a0;
  Struct8BytesNestedInt a1;
  Struct8BytesNestedInt a2;
  Struct8BytesNestedInt a3;
  Struct8BytesNestedInt a4;
  Struct8BytesNestedInt a5;
  Struct8BytesNestedInt a6;
  Struct8BytesNestedInt a7;
  Struct8BytesNestedInt a8;
  Struct8BytesNestedInt a9;

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

  std::cout << "Calling TestPassStruct8BytesNestedIntx10("
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ", " << a0.a1.a1 << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1
            << "), (" << a1.a1.a0 << ", " << a1.a1.a1 << ")), ((" << a2.a0.a0
            << ", " << a2.a0.a1 << "), (" << a2.a1.a0 << ", " << a2.a1.a1
            << ")), ((" << a3.a0.a0 << ", " << a3.a0.a1 << "), (" << a3.a1.a0
            << ", " << a3.a1.a1 << ")), ((" << a4.a0.a0 << ", " << a4.a0.a1
            << "), (" << a4.a1.a0 << ", " << a4.a1.a1 << ")), ((" << a5.a0.a0
            << ", " << a5.a0.a1 << "), (" << a5.a1.a0 << ", " << a5.a1.a1
            << ")), ((" << a6.a0.a0 << ", " << a6.a0.a1 << "), (" << a6.a1.a0
            << ", " << a6.a1.a1 << ")), ((" << a7.a0.a0 << ", " << a7.a0.a1
            << "), (" << a7.a1.a0 << ", " << a7.a1.a1 << ")), ((" << a8.a0.a0
            << ", " << a8.a0.a1 << "), (" << a8.a1.a0 << ", " << a8.a1.a1
            << ")), ((" << a9.a0.a0 << ", " << a9.a0.a1 << "), (" << a9.a1.a0
            << ", " << a9.a1.a1 << ")))"
            << ")\n";

  int64_t result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(20, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust fpu registers on all platforms.
DART_EXPORT intptr_t TestPassStruct8BytesNestedFloatx10(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct8BytesNestedFloat a0,
               Struct8BytesNestedFloat a1,
               Struct8BytesNestedFloat a2,
               Struct8BytesNestedFloat a3,
               Struct8BytesNestedFloat a4,
               Struct8BytesNestedFloat a5,
               Struct8BytesNestedFloat a6,
               Struct8BytesNestedFloat a7,
               Struct8BytesNestedFloat a8,
               Struct8BytesNestedFloat a9)) {
  Struct8BytesNestedFloat a0;
  Struct8BytesNestedFloat a1;
  Struct8BytesNestedFloat a2;
  Struct8BytesNestedFloat a3;
  Struct8BytesNestedFloat a4;
  Struct8BytesNestedFloat a5;
  Struct8BytesNestedFloat a6;
  Struct8BytesNestedFloat a7;
  Struct8BytesNestedFloat a8;
  Struct8BytesNestedFloat a9;

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

  std::cout << "Calling TestPassStruct8BytesNestedFloatx10("
            << "(((" << a0.a0.a0 << "), (" << a0.a1.a0 << ")), ((" << a1.a0.a0
            << "), (" << a1.a1.a0 << ")), ((" << a2.a0.a0 << "), (" << a2.a1.a0
            << ")), ((" << a3.a0.a0 << "), (" << a3.a1.a0 << ")), (("
            << a4.a0.a0 << "), (" << a4.a1.a0 << ")), ((" << a5.a0.a0 << "), ("
            << a5.a1.a0 << ")), ((" << a6.a0.a0 << "), (" << a6.a1.a0
            << ")), ((" << a7.a0.a0 << "), (" << a7.a1.a0 << ")), (("
            << a8.a0.a0 << "), (" << a8.a1.a0 << ")), ((" << a9.a0.a0 << "), ("
            << a9.a1.a0 << ")))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust fpu registers on all platforms.
// The nesting is irregular, testing homogenous float rules on arm and arm64,
// and the fpu register usage on x64.
DART_EXPORT intptr_t TestPassStruct8BytesNestedFloat2x10(
    // NOLINTNEXTLINE(whitespace/parens)
    float (*f)(Struct8BytesNestedFloat2 a0,
               Struct8BytesNestedFloat2 a1,
               Struct8BytesNestedFloat2 a2,
               Struct8BytesNestedFloat2 a3,
               Struct8BytesNestedFloat2 a4,
               Struct8BytesNestedFloat2 a5,
               Struct8BytesNestedFloat2 a6,
               Struct8BytesNestedFloat2 a7,
               Struct8BytesNestedFloat2 a8,
               Struct8BytesNestedFloat2 a9)) {
  Struct8BytesNestedFloat2 a0;
  Struct8BytesNestedFloat2 a1;
  Struct8BytesNestedFloat2 a2;
  Struct8BytesNestedFloat2 a3;
  Struct8BytesNestedFloat2 a4;
  Struct8BytesNestedFloat2 a5;
  Struct8BytesNestedFloat2 a6;
  Struct8BytesNestedFloat2 a7;
  Struct8BytesNestedFloat2 a8;
  Struct8BytesNestedFloat2 a9;

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

  std::cout << "Calling TestPassStruct8BytesNestedFloat2x10("
            << "(((" << a0.a0.a0 << "), " << a0.a1 << "), ((" << a1.a0.a0
            << "), " << a1.a1 << "), ((" << a2.a0.a0 << "), " << a2.a1
            << "), ((" << a3.a0.a0 << "), " << a3.a1 << "), ((" << a4.a0.a0
            << "), " << a4.a1 << "), ((" << a5.a0.a0 << "), " << a5.a1
            << "), ((" << a6.a0.a0 << "), " << a6.a1 << "), ((" << a7.a0.a0
            << "), " << a7.a1 << "), ((" << a8.a0.a0 << "), " << a8.a1
            << "), ((" << a9.a0.a0 << "), " << a9.a1 << "))"
            << ")\n";

  float result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(10.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct. No alignment gaps on any architectures.
// 10 arguments exhaust all registers on all platforms.
DART_EXPORT intptr_t TestPassStruct8BytesNestedMixedx10(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(Struct8BytesNestedMixed a0,
                Struct8BytesNestedMixed a1,
                Struct8BytesNestedMixed a2,
                Struct8BytesNestedMixed a3,
                Struct8BytesNestedMixed a4,
                Struct8BytesNestedMixed a5,
                Struct8BytesNestedMixed a6,
                Struct8BytesNestedMixed a7,
                Struct8BytesNestedMixed a8,
                Struct8BytesNestedMixed a9)) {
  Struct8BytesNestedMixed a0;
  Struct8BytesNestedMixed a1;
  Struct8BytesNestedMixed a2;
  Struct8BytesNestedMixed a3;
  Struct8BytesNestedMixed a4;
  Struct8BytesNestedMixed a5;
  Struct8BytesNestedMixed a6;
  Struct8BytesNestedMixed a7;
  Struct8BytesNestedMixed a8;
  Struct8BytesNestedMixed a9;

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

  std::cout << "Calling TestPassStruct8BytesNestedMixedx10("
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1 << "), (" << a1.a1.a0
            << ")), ((" << a2.a0.a0 << ", " << a2.a0.a1 << "), (" << a2.a1.a0
            << ")), ((" << a3.a0.a0 << ", " << a3.a0.a1 << "), (" << a3.a1.a0
            << ")), ((" << a4.a0.a0 << ", " << a4.a0.a1 << "), (" << a4.a1.a0
            << ")), ((" << a5.a0.a0 << ", " << a5.a0.a1 << "), (" << a5.a1.a0
            << ")), ((" << a6.a0.a0 << ", " << a6.a0.a1 << "), (" << a6.a1.a0
            << ")), ((" << a7.a0.a0 << ", " << a7.a0.a1 << "), (" << a7.a1.a0
            << ")), ((" << a8.a0.a0 << ", " << a8.a0.a1 << "), (" << a8.a1.a0
            << ")), ((" << a9.a0.a0 << ", " << a9.a0.a1 << "), (" << a9.a1.a0
            << ")))"
            << ")\n";

  double result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(15.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Deeper nested struct to test recursive member access.
DART_EXPORT intptr_t TestPassStruct16BytesNestedIntx2(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct16BytesNestedInt a0, Struct16BytesNestedInt a1)) {
  Struct16BytesNestedInt a0;
  Struct16BytesNestedInt a1;

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

  std::cout << "Calling TestPassStruct16BytesNestedIntx2("
            << "((((" << a0.a0.a0.a0 << ", " << a0.a0.a0.a1 << "), ("
            << a0.a0.a1.a0 << ", " << a0.a0.a1.a1 << ")), ((" << a0.a1.a0.a0
            << ", " << a0.a1.a0.a1 << "), (" << a0.a1.a1.a0 << ", "
            << a0.a1.a1.a1 << "))), (((" << a1.a0.a0.a0 << ", " << a1.a0.a0.a1
            << "), (" << a1.a0.a1.a0 << ", " << a1.a0.a1.a1 << ")), (("
            << a1.a1.a0.a0 << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0
            << ", " << a1.a1.a1.a1 << "))))"
            << ")\n";

  int64_t result = f(a0, a1);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(8, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Even deeper nested struct to test recursive member access.
DART_EXPORT intptr_t TestPassStruct32BytesNestedIntx2(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(Struct32BytesNestedInt a0, Struct32BytesNestedInt a1)) {
  Struct32BytesNestedInt a0;
  Struct32BytesNestedInt a1;

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

  std::cout << "Calling TestPassStruct32BytesNestedIntx2("
            << "(((((" << a0.a0.a0.a0.a0 << ", " << a0.a0.a0.a0.a1 << "), ("
            << a0.a0.a0.a1.a0 << ", " << a0.a0.a0.a1.a1 << ")), (("
            << a0.a0.a1.a0.a0 << ", " << a0.a0.a1.a0.a1 << "), ("
            << a0.a0.a1.a1.a0 << ", " << a0.a0.a1.a1.a1 << "))), ((("
            << a0.a1.a0.a0.a0 << ", " << a0.a1.a0.a0.a1 << "), ("
            << a0.a1.a0.a1.a0 << ", " << a0.a1.a0.a1.a1 << ")), (("
            << a0.a1.a1.a0.a0 << ", " << a0.a1.a1.a0.a1 << "), ("
            << a0.a1.a1.a1.a0 << ", " << a0.a1.a1.a1.a1 << ")))), (((("
            << a1.a0.a0.a0.a0 << ", " << a1.a0.a0.a0.a1 << "), ("
            << a1.a0.a0.a1.a0 << ", " << a1.a0.a0.a1.a1 << ")), (("
            << a1.a0.a1.a0.a0 << ", " << a1.a0.a1.a0.a1 << "), ("
            << a1.a0.a1.a1.a0 << ", " << a1.a0.a1.a1.a1 << "))), ((("
            << a1.a1.a0.a0.a0 << ", " << a1.a1.a0.a0.a1 << "), ("
            << a1.a1.a0.a1.a0 << ", " << a1.a1.a0.a1.a1 << ")), (("
            << a1.a1.a1.a0.a0 << ", " << a1.a1.a1.a0.a1 << "), ("
            << a1.a1.a1.a1.a0 << ", " << a1.a1.a1.a1.a1 << ")))))"
            << ")\n";

  int64_t result = f(a0, a1);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(16, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0.a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0.a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 16 byte int.
DART_EXPORT intptr_t TestPassStructNestedIntStructAlignmentInt16(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructNestedIntStructAlignmentInt16 a0)) {
  StructNestedIntStructAlignmentInt16 a0;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  std::cout << "Calling TestPassStructNestedIntStructAlignmentInt16("
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(3, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 32 byte int.
DART_EXPORT intptr_t TestPassStructNestedIntStructAlignmentInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructNestedIntStructAlignmentInt32 a0)) {
  StructNestedIntStructAlignmentInt32 a0;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  std::cout << "Calling TestPassStructNestedIntStructAlignmentInt32("
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(3, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 64 byte int.
DART_EXPORT intptr_t TestPassStructNestedIntStructAlignmentInt64(
    // NOLINTNEXTLINE(whitespace/parens)
    int64_t (*f)(StructNestedIntStructAlignmentInt64 a0)) {
  StructNestedIntStructAlignmentInt64 a0;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a0.a2 = -3;
  a0.a1.a0 = 4;
  a0.a1.a1 = -5;
  a0.a1.a2 = 6;

  std::cout << "Calling TestPassStructNestedIntStructAlignmentInt64("
            << "(((" << static_cast<int>(a0.a0.a0) << ", " << a0.a0.a1 << ", "
            << static_cast<int>(a0.a0.a2) << "), ("
            << static_cast<int>(a0.a1.a0) << ", " << a0.a1.a1 << ", "
            << static_cast<int>(a0.a1.a2) << ")))"
            << ")\n";

  int64_t result = f(a0);

  std::cout << "result = " << result << "\n";

  CHECK_EQ(3, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result);

  return 0;
}

// Used for testing structs by value.
// Return big irregular struct as smoke test.
DART_EXPORT intptr_t TestPassStructNestedIrregularEvenBiggerx4(
    // NOLINTNEXTLINE(whitespace/parens)
    double (*f)(StructNestedIrregularEvenBigger a0,
                StructNestedIrregularEvenBigger a1,
                StructNestedIrregularEvenBigger a2,
                StructNestedIrregularEvenBigger a3)) {
  StructNestedIrregularEvenBigger a0;
  StructNestedIrregularEvenBigger a1;
  StructNestedIrregularEvenBigger a2;
  StructNestedIrregularEvenBigger a3;

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

  std::cout
      << "Calling TestPassStructNestedIrregularEvenBiggerx4("
      << "((" << a0.a0 << ", ((" << a0.a1.a0.a0 << ", ((" << a0.a1.a0.a1.a0.a0
      << ", " << a0.a1.a0.a1.a0.a1 << "), (" << a0.a1.a0.a1.a1.a0 << ")), "
      << a0.a1.a0.a2 << ", ((" << a0.a1.a0.a3.a0.a0 << "), " << a0.a1.a0.a3.a1
      << "), " << a0.a1.a0.a4 << ", ((" << a0.a1.a0.a5.a0.a0 << "), ("
      << a0.a1.a0.a5.a1.a0 << ")), " << a0.a1.a0.a6 << "), ((" << a0.a1.a1.a0.a0
      << ", " << a0.a1.a1.a0.a1 << "), (" << a0.a1.a1.a1.a0 << ")), "
      << a0.a1.a2 << ", " << a0.a1.a3 << "), ((" << a0.a2.a0.a0 << ", (("
      << a0.a2.a0.a1.a0.a0 << ", " << a0.a2.a0.a1.a0.a1 << "), ("
      << a0.a2.a0.a1.a1.a0 << ")), " << a0.a2.a0.a2 << ", (("
      << a0.a2.a0.a3.a0.a0 << "), " << a0.a2.a0.a3.a1 << "), " << a0.a2.a0.a4
      << ", ((" << a0.a2.a0.a5.a0.a0 << "), (" << a0.a2.a0.a5.a1.a0 << ")), "
      << a0.a2.a0.a6 << "), ((" << a0.a2.a1.a0.a0 << ", " << a0.a2.a1.a0.a1
      << "), (" << a0.a2.a1.a1.a0 << ")), " << a0.a2.a2 << ", " << a0.a2.a3
      << "), " << a0.a3 << "), (" << a1.a0 << ", ((" << a1.a1.a0.a0 << ", (("
      << a1.a1.a0.a1.a0.a0 << ", " << a1.a1.a0.a1.a0.a1 << "), ("
      << a1.a1.a0.a1.a1.a0 << ")), " << a1.a1.a0.a2 << ", (("
      << a1.a1.a0.a3.a0.a0 << "), " << a1.a1.a0.a3.a1 << "), " << a1.a1.a0.a4
      << ", ((" << a1.a1.a0.a5.a0.a0 << "), (" << a1.a1.a0.a5.a1.a0 << ")), "
      << a1.a1.a0.a6 << "), ((" << a1.a1.a1.a0.a0 << ", " << a1.a1.a1.a0.a1
      << "), (" << a1.a1.a1.a1.a0 << ")), " << a1.a1.a2 << ", " << a1.a1.a3
      << "), ((" << a1.a2.a0.a0 << ", ((" << a1.a2.a0.a1.a0.a0 << ", "
      << a1.a2.a0.a1.a0.a1 << "), (" << a1.a2.a0.a1.a1.a0 << ")), "
      << a1.a2.a0.a2 << ", ((" << a1.a2.a0.a3.a0.a0 << "), " << a1.a2.a0.a3.a1
      << "), " << a1.a2.a0.a4 << ", ((" << a1.a2.a0.a5.a0.a0 << "), ("
      << a1.a2.a0.a5.a1.a0 << ")), " << a1.a2.a0.a6 << "), ((" << a1.a2.a1.a0.a0
      << ", " << a1.a2.a1.a0.a1 << "), (" << a1.a2.a1.a1.a0 << ")), "
      << a1.a2.a2 << ", " << a1.a2.a3 << "), " << a1.a3 << "), (" << a2.a0
      << ", ((" << a2.a1.a0.a0 << ", ((" << a2.a1.a0.a1.a0.a0 << ", "
      << a2.a1.a0.a1.a0.a1 << "), (" << a2.a1.a0.a1.a1.a0 << ")), "
      << a2.a1.a0.a2 << ", ((" << a2.a1.a0.a3.a0.a0 << "), " << a2.a1.a0.a3.a1
      << "), " << a2.a1.a0.a4 << ", ((" << a2.a1.a0.a5.a0.a0 << "), ("
      << a2.a1.a0.a5.a1.a0 << ")), " << a2.a1.a0.a6 << "), ((" << a2.a1.a1.a0.a0
      << ", " << a2.a1.a1.a0.a1 << "), (" << a2.a1.a1.a1.a0 << ")), "
      << a2.a1.a2 << ", " << a2.a1.a3 << "), ((" << a2.a2.a0.a0 << ", (("
      << a2.a2.a0.a1.a0.a0 << ", " << a2.a2.a0.a1.a0.a1 << "), ("
      << a2.a2.a0.a1.a1.a0 << ")), " << a2.a2.a0.a2 << ", (("
      << a2.a2.a0.a3.a0.a0 << "), " << a2.a2.a0.a3.a1 << "), " << a2.a2.a0.a4
      << ", ((" << a2.a2.a0.a5.a0.a0 << "), (" << a2.a2.a0.a5.a1.a0 << ")), "
      << a2.a2.a0.a6 << "), ((" << a2.a2.a1.a0.a0 << ", " << a2.a2.a1.a0.a1
      << "), (" << a2.a2.a1.a1.a0 << ")), " << a2.a2.a2 << ", " << a2.a2.a3
      << "), " << a2.a3 << "), (" << a3.a0 << ", ((" << a3.a1.a0.a0 << ", (("
      << a3.a1.a0.a1.a0.a0 << ", " << a3.a1.a0.a1.a0.a1 << "), ("
      << a3.a1.a0.a1.a1.a0 << ")), " << a3.a1.a0.a2 << ", (("
      << a3.a1.a0.a3.a0.a0 << "), " << a3.a1.a0.a3.a1 << "), " << a3.a1.a0.a4
      << ", ((" << a3.a1.a0.a5.a0.a0 << "), (" << a3.a1.a0.a5.a1.a0 << ")), "
      << a3.a1.a0.a6 << "), ((" << a3.a1.a1.a0.a0 << ", " << a3.a1.a1.a0.a1
      << "), (" << a3.a1.a1.a1.a0 << ")), " << a3.a1.a2 << ", " << a3.a1.a3
      << "), ((" << a3.a2.a0.a0 << ", ((" << a3.a2.a0.a1.a0.a0 << ", "
      << a3.a2.a0.a1.a0.a1 << "), (" << a3.a2.a0.a1.a1.a0 << ")), "
      << a3.a2.a0.a2 << ", ((" << a3.a2.a0.a3.a0.a0 << "), " << a3.a2.a0.a3.a1
      << "), " << a3.a2.a0.a4 << ", ((" << a3.a2.a0.a5.a0.a0 << "), ("
      << a3.a2.a0.a5.a1.a0 << ")), " << a3.a2.a0.a6 << "), ((" << a3.a2.a1.a0.a0
      << ", " << a3.a2.a1.a0.a1 << "), (" << a3.a2.a1.a1.a0 << ")), "
      << a3.a2.a2 << ", " << a3.a2.a3 << "), " << a3.a3 << "))"
      << ")\n";

  double result = f(a0, a1, a2, a3);

  std::cout << "result = " << result << "\n";

  CHECK_APPROX(1572.0, result);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result);

  return 0;
}

// Used for testing structs by value.
// Smallest struct with data.
DART_EXPORT intptr_t TestReturnStruct1ByteInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct1ByteInt (*f)(int8_t a0)) {
  int8_t a0;

  a0 = -1;

  std::cout << "Calling TestReturnStruct1ByteInt("
            << "(" << static_cast<int>(a0) << ")"
            << ")\n";

  Struct1ByteInt result = f(a0);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result.a0);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result.a0);

  return 0;
}

// Used for testing structs by value.
// Smaller than word size return value on all architectures.
DART_EXPORT intptr_t TestReturnStruct3BytesHomogeneousUint8(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct3BytesHomogeneousUint8 (*f)(uint8_t a0, uint8_t a1, uint8_t a2)) {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;

  a0 = 1;
  a1 = 2;
  a2 = 3;

  std::cout << "Calling TestReturnStruct3BytesHomogeneousUint8("
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ")"
            << ")\n";

  Struct3BytesHomogeneousUint8 result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Smaller than word size return value on all architectures.
// With alignment rules taken into account size is 4 bytes.
DART_EXPORT intptr_t TestReturnStruct3BytesInt2ByteAligned(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct3BytesInt2ByteAligned (*f)(int16_t a0, int8_t a1)) {
  int16_t a0;
  int8_t a1;

  a0 = -1;
  a1 = 2;

  std::cout << "Calling TestReturnStruct3BytesInt2ByteAligned("
            << "(" << a0 << ", " << static_cast<int>(a1) << ")"
            << ")\n";

  Struct3BytesInt2ByteAligned result = f(a0, a1);

  std::cout << "result = "
            << "(" << result.a0 << ", " << static_cast<int>(result.a1) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Word size return value on 32 bit architectures..
DART_EXPORT intptr_t TestReturnStruct4BytesHomogeneousInt16(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct4BytesHomogeneousInt16 (*f)(int16_t a0, int16_t a1)) {
  int16_t a0;
  int16_t a1;

  a0 = -1;
  a1 = 2;

  std::cout << "Calling TestReturnStruct4BytesHomogeneousInt16("
            << "(" << a0 << ", " << a1 << ")"
            << ")\n";

  Struct4BytesHomogeneousInt16 result = f(a0, a1);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Non-wordsize return value.
DART_EXPORT intptr_t TestReturnStruct7BytesHomogeneousUint8(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct7BytesHomogeneousUint8 (*f)(uint8_t a0,
                                      uint8_t a1,
                                      uint8_t a2,
                                      uint8_t a3,
                                      uint8_t a4,
                                      uint8_t a5,
                                      uint8_t a6)) {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;

  std::cout << "Calling TestReturnStruct7BytesHomogeneousUint8("
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ")"
            << ")\n";

  Struct7BytesHomogeneousUint8 result = f(a0, a1, a2, a3, a4, a5, a6);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);
  CHECK_EQ(a3, result.a3);
  CHECK_EQ(a4, result.a4);
  CHECK_EQ(a5, result.a5);
  CHECK_EQ(a6, result.a6);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);

  return 0;
}

// Used for testing structs by value.
// Non-wordsize return value.
// With alignment rules taken into account size is 8 bytes.
DART_EXPORT intptr_t TestReturnStruct7BytesInt4ByteAligned(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct7BytesInt4ByteAligned (*f)(int32_t a0, int16_t a1, int8_t a2)) {
  int32_t a0;
  int16_t a1;
  int8_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStruct7BytesInt4ByteAligned("
            << "(" << a0 << ", " << a1 << ", " << static_cast<int>(a2) << ")"
            << ")\n";

  Struct7BytesInt4ByteAligned result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Return value in integer registers on many architectures.
DART_EXPORT intptr_t TestReturnStruct8BytesInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesInt (*f)(int16_t a0, int16_t a1, int32_t a2)) {
  int16_t a0;
  int16_t a1;
  int32_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStruct8BytesInt("
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << ")\n";

  Struct8BytesInt result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Return value in FP registers on many architectures.
DART_EXPORT intptr_t TestReturnStruct8BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesHomogeneousFloat (*f)(float a0, float a1)) {
  float a0;
  float a1;

  a0 = -1.0;
  a1 = 2.0;

  std::cout << "Calling TestReturnStruct8BytesHomogeneousFloat("
            << "(" << a0 << ", " << a1 << ")"
            << ")\n";

  Struct8BytesHomogeneousFloat result = f(a0, a1);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
DART_EXPORT intptr_t TestReturnStruct8BytesMixed(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesMixed (*f)(float a0, int16_t a1, int16_t a2)) {
  float a0;
  int16_t a1;
  int16_t a2;

  a0 = -1.0;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStruct8BytesMixed("
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << ")\n";

  Struct8BytesMixed result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is the right size and that
// dart:ffi trampolines do not write outside this size.
DART_EXPORT intptr_t TestReturnStruct9BytesHomogeneousUint8(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct9BytesHomogeneousUint8 (*f)(uint8_t a0,
                                      uint8_t a1,
                                      uint8_t a2,
                                      uint8_t a3,
                                      uint8_t a4,
                                      uint8_t a5,
                                      uint8_t a6,
                                      uint8_t a7,
                                      uint8_t a8)) {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;
  uint8_t a7;
  uint8_t a8;

  a0 = 1;
  a1 = 2;
  a2 = 3;
  a3 = 4;
  a4 = 5;
  a5 = 6;
  a6 = 7;
  a7 = 8;
  a8 = 9;

  std::cout << "Calling TestReturnStruct9BytesHomogeneousUint8("
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ", " << static_cast<int>(a7)
            << ", " << static_cast<int>(a8) << ")"
            << ")\n";

  Struct9BytesHomogeneousUint8 result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ", "
            << static_cast<int>(result.a7) << ", "
            << static_cast<int>(result.a8) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);
  CHECK_EQ(a3, result.a3);
  CHECK_EQ(a4, result.a4);
  CHECK_EQ(a5, result.a5);
  CHECK_EQ(a6, result.a6);
  CHECK_EQ(a7, result.a7);
  CHECK_EQ(a8, result.a8);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);

  return 0;
}

// Used for testing structs by value.
// Return value in two integer registers on x64.
// With alignment rules taken into account size is 12 or 16 bytes.
DART_EXPORT intptr_t TestReturnStruct9BytesInt4Or8ByteAligned(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct9BytesInt4Or8ByteAligned (*f)(int64_t a0, int8_t a1)) {
  int64_t a0;
  int8_t a1;

  a0 = -1;
  a1 = 2;

  std::cout << "Calling TestReturnStruct9BytesInt4Or8ByteAligned("
            << "(" << a0 << ", " << static_cast<int>(a1) << ")"
            << ")\n";

  Struct9BytesInt4Or8ByteAligned result = f(a0, a1);

  std::cout << "result = "
            << "(" << result.a0 << ", " << static_cast<int>(result.a1) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Return value in FPU registers, but does not use all registers on arm hardfp
// and arm64.
DART_EXPORT intptr_t TestReturnStruct12BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct12BytesHomogeneousFloat (*f)(float a0, float a1, float a2)) {
  float a0;
  float a1;
  float a2;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;

  std::cout << "Calling TestReturnStruct12BytesHomogeneousFloat("
            << "(" << a0 << ", " << a1 << ", " << a2 << ")"
            << ")\n";

  Struct12BytesHomogeneousFloat result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Return value in FPU registers on arm hardfp and arm64.
DART_EXPORT intptr_t TestReturnStruct16BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct16BytesHomogeneousFloat (
        *f)(float a0, float a1, float a2, float a3)) {
  float a0;
  float a1;
  float a2;
  float a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;

  std::cout << "Calling TestReturnStruct16BytesHomogeneousFloat("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << ")\n";

  Struct16BytesHomogeneousFloat result = f(a0, a1, a2, a3);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);
  CHECK_APPROX(a3, result.a3);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);

  return 0;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
DART_EXPORT intptr_t TestReturnStruct16BytesMixed(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct16BytesMixed (*f)(double a0, int64_t a1)) {
  double a0;
  int64_t a1;

  a0 = -1.0;
  a1 = 2;

  std::cout << "Calling TestReturnStruct16BytesMixed("
            << "(" << a0 << ", " << a1 << ")"
            << ")\n";

  Struct16BytesMixed result = f(a0, a1);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_EQ(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0);
  CHECK_EQ(0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0);
  CHECK_EQ(0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Return value split over FP and integer register in x64.
// The integer register contains half float half int.
DART_EXPORT intptr_t TestReturnStruct16BytesMixed2(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct16BytesMixed2 (*f)(float a0, float a1, float a2, int32_t a3)) {
  float a0;
  float a1;
  float a2;
  int32_t a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4;

  std::cout << "Calling TestReturnStruct16BytesMixed2("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << ")\n";

  Struct16BytesMixed2 result = f(a0, a1, a2, a3);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);
  CHECK_EQ(a3, result.a3);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_EQ(0, result.a3);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_EQ(0, result.a3);

  return 0;
}

// Used for testing structs by value.
// Rerturn value returned in preallocated space passed by pointer on most ABIs.
// Is non word size on purpose, to test that structs are rounded up to word size
// on all ABIs.
DART_EXPORT intptr_t TestReturnStruct17BytesInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct17BytesInt (*f)(int64_t a0, int64_t a1, int8_t a2)) {
  int64_t a0;
  int64_t a1;
  int8_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStruct17BytesInt("
            << "(" << a0 << ", " << a1 << ", " << static_cast<int>(a2) << ")"
            << ")\n";

  Struct17BytesInt result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// The minimum alignment of this struct is only 1 byte based on its fields.
// Test that the memory backing these structs is the right size and that
// dart:ffi trampolines do not write outside this size.
DART_EXPORT intptr_t TestReturnStruct19BytesHomogeneousUint8(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct19BytesHomogeneousUint8 (*f)(uint8_t a0,
                                       uint8_t a1,
                                       uint8_t a2,
                                       uint8_t a3,
                                       uint8_t a4,
                                       uint8_t a5,
                                       uint8_t a6,
                                       uint8_t a7,
                                       uint8_t a8,
                                       uint8_t a9,
                                       uint8_t a10,
                                       uint8_t a11,
                                       uint8_t a12,
                                       uint8_t a13,
                                       uint8_t a14,
                                       uint8_t a15,
                                       uint8_t a16,
                                       uint8_t a17,
                                       uint8_t a18)) {
  uint8_t a0;
  uint8_t a1;
  uint8_t a2;
  uint8_t a3;
  uint8_t a4;
  uint8_t a5;
  uint8_t a6;
  uint8_t a7;
  uint8_t a8;
  uint8_t a9;
  uint8_t a10;
  uint8_t a11;
  uint8_t a12;
  uint8_t a13;
  uint8_t a14;
  uint8_t a15;
  uint8_t a16;
  uint8_t a17;
  uint8_t a18;

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

  std::cout << "Calling TestReturnStruct19BytesHomogeneousUint8("
            << "(" << static_cast<int>(a0) << ", " << static_cast<int>(a1)
            << ", " << static_cast<int>(a2) << ", " << static_cast<int>(a3)
            << ", " << static_cast<int>(a4) << ", " << static_cast<int>(a5)
            << ", " << static_cast<int>(a6) << ", " << static_cast<int>(a7)
            << ", " << static_cast<int>(a8) << ", " << static_cast<int>(a9)
            << ", " << static_cast<int>(a10) << ", " << static_cast<int>(a11)
            << ", " << static_cast<int>(a12) << ", " << static_cast<int>(a13)
            << ", " << static_cast<int>(a14) << ", " << static_cast<int>(a15)
            << ", " << static_cast<int>(a16) << ", " << static_cast<int>(a17)
            << ", " << static_cast<int>(a18) << ")"
            << ")\n";

  Struct19BytesHomogeneousUint8 result =
      f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15,
        a16, a17, a18);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", "
            << static_cast<int>(result.a1) << ", "
            << static_cast<int>(result.a2) << ", "
            << static_cast<int>(result.a3) << ", "
            << static_cast<int>(result.a4) << ", "
            << static_cast<int>(result.a5) << ", "
            << static_cast<int>(result.a6) << ", "
            << static_cast<int>(result.a7) << ", "
            << static_cast<int>(result.a8) << ", "
            << static_cast<int>(result.a9) << ", "
            << static_cast<int>(result.a10) << ", "
            << static_cast<int>(result.a11) << ", "
            << static_cast<int>(result.a12) << ", "
            << static_cast<int>(result.a13) << ", "
            << static_cast<int>(result.a14) << ", "
            << static_cast<int>(result.a15) << ", "
            << static_cast<int>(result.a16) << ", "
            << static_cast<int>(result.a17) << ", "
            << static_cast<int>(result.a18) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);
  CHECK_EQ(a3, result.a3);
  CHECK_EQ(a4, result.a4);
  CHECK_EQ(a5, result.a5);
  CHECK_EQ(a6, result.a6);
  CHECK_EQ(a7, result.a7);
  CHECK_EQ(a8, result.a8);
  CHECK_EQ(a9, result.a9);
  CHECK_EQ(a10, result.a10);
  CHECK_EQ(a11, result.a11);
  CHECK_EQ(a12, result.a12);
  CHECK_EQ(a13, result.a13);
  CHECK_EQ(a14, result.a14);
  CHECK_EQ(a15, result.a15);
  CHECK_EQ(a16, result.a16);
  CHECK_EQ(a17, result.a17);
  CHECK_EQ(a18, result.a18);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14,
             a15, a16, a17, a18);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);
  CHECK_EQ(0, result.a9);
  CHECK_EQ(0, result.a10);
  CHECK_EQ(0, result.a11);
  CHECK_EQ(0, result.a12);
  CHECK_EQ(0, result.a13);
  CHECK_EQ(0, result.a14);
  CHECK_EQ(0, result.a15);
  CHECK_EQ(0, result.a16);
  CHECK_EQ(0, result.a17);
  CHECK_EQ(0, result.a18);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14,
             a15, a16, a17, a18);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);
  CHECK_EQ(0, result.a9);
  CHECK_EQ(0, result.a10);
  CHECK_EQ(0, result.a11);
  CHECK_EQ(0, result.a12);
  CHECK_EQ(0, result.a13);
  CHECK_EQ(0, result.a14);
  CHECK_EQ(0, result.a15);
  CHECK_EQ(0, result.a16);
  CHECK_EQ(0, result.a17);
  CHECK_EQ(0, result.a18);

  return 0;
}

// Used for testing structs by value.
// Return value too big to go in cpu registers on arm64.
DART_EXPORT intptr_t TestReturnStruct20BytesHomogeneousInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct20BytesHomogeneousInt32 (
        *f)(int32_t a0, int32_t a1, int32_t a2, int32_t a3, int32_t a4)) {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  int32_t a4;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;

  std::cout << "Calling TestReturnStruct20BytesHomogeneousInt32("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << ")\n";

  Struct20BytesHomogeneousInt32 result = f(a0, a1, a2, a3, a4);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);
  CHECK_EQ(a3, result.a3);
  CHECK_EQ(a4, result.a4);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  return 0;
}

// Used for testing structs by value.
// Return value too big to go in FPU registers on x64, arm hardfp and arm64.
DART_EXPORT intptr_t TestReturnStruct20BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct20BytesHomogeneousFloat (
        *f)(float a0, float a1, float a2, float a3, float a4)) {
  float a0;
  float a1;
  float a2;
  float a3;
  float a4;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;
  a4 = -5.0;

  std::cout << "Calling TestReturnStruct20BytesHomogeneousFloat("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << ")\n";

  Struct20BytesHomogeneousFloat result = f(a0, a1, a2, a3, a4);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);
  CHECK_APPROX(a3, result.a3);
  CHECK_APPROX(a4, result.a4);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);
  CHECK_APPROX(0.0, result.a4);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);
  CHECK_APPROX(0.0, result.a4);

  return 0;
}

// Used for testing structs by value.
// Return value in FPU registers on arm64.
DART_EXPORT intptr_t TestReturnStruct32BytesHomogeneousDouble(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct32BytesHomogeneousDouble (
        *f)(double a0, double a1, double a2, double a3)) {
  double a0;
  double a1;
  double a2;
  double a3;

  a0 = -1.0;
  a1 = 2.0;
  a2 = -3.0;
  a3 = 4.0;

  std::cout << "Calling TestReturnStruct32BytesHomogeneousDouble("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ")"
            << ")\n";

  Struct32BytesHomogeneousDouble result = f(a0, a1, a2, a3);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);
  CHECK_APPROX(a3, result.a3);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);

  return 0;
}

// Used for testing structs by value.
// Return value too big to go in FPU registers on arm64.
DART_EXPORT intptr_t TestReturnStruct40BytesHomogeneousDouble(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct40BytesHomogeneousDouble (
        *f)(double a0, double a1, double a2, double a3, double a4)) {
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

  std::cout << "Calling TestReturnStruct40BytesHomogeneousDouble("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ")"
            << ")\n";

  Struct40BytesHomogeneousDouble result = f(a0, a1, a2, a3, a4);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  CHECK_APPROX(a0, result.a0);
  CHECK_APPROX(a1, result.a1);
  CHECK_APPROX(a2, result.a2);
  CHECK_APPROX(a3, result.a3);
  CHECK_APPROX(a4, result.a4);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);
  CHECK_APPROX(0.0, result.a4);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);
  CHECK_APPROX(0.0, result.a2);
  CHECK_APPROX(0.0, result.a3);
  CHECK_APPROX(0.0, result.a4);

  return 0;
}

// Used for testing structs by value.
// Test 1kb struct.
DART_EXPORT intptr_t TestReturnStruct1024BytesHomogeneousUint64(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct1024BytesHomogeneousUint64 (*f)(uint64_t a0,
                                          uint64_t a1,
                                          uint64_t a2,
                                          uint64_t a3,
                                          uint64_t a4,
                                          uint64_t a5,
                                          uint64_t a6,
                                          uint64_t a7,
                                          uint64_t a8,
                                          uint64_t a9,
                                          uint64_t a10,
                                          uint64_t a11,
                                          uint64_t a12,
                                          uint64_t a13,
                                          uint64_t a14,
                                          uint64_t a15,
                                          uint64_t a16,
                                          uint64_t a17,
                                          uint64_t a18,
                                          uint64_t a19,
                                          uint64_t a20,
                                          uint64_t a21,
                                          uint64_t a22,
                                          uint64_t a23,
                                          uint64_t a24,
                                          uint64_t a25,
                                          uint64_t a26,
                                          uint64_t a27,
                                          uint64_t a28,
                                          uint64_t a29,
                                          uint64_t a30,
                                          uint64_t a31,
                                          uint64_t a32,
                                          uint64_t a33,
                                          uint64_t a34,
                                          uint64_t a35,
                                          uint64_t a36,
                                          uint64_t a37,
                                          uint64_t a38,
                                          uint64_t a39,
                                          uint64_t a40,
                                          uint64_t a41,
                                          uint64_t a42,
                                          uint64_t a43,
                                          uint64_t a44,
                                          uint64_t a45,
                                          uint64_t a46,
                                          uint64_t a47,
                                          uint64_t a48,
                                          uint64_t a49,
                                          uint64_t a50,
                                          uint64_t a51,
                                          uint64_t a52,
                                          uint64_t a53,
                                          uint64_t a54,
                                          uint64_t a55,
                                          uint64_t a56,
                                          uint64_t a57,
                                          uint64_t a58,
                                          uint64_t a59,
                                          uint64_t a60,
                                          uint64_t a61,
                                          uint64_t a62,
                                          uint64_t a63,
                                          uint64_t a64,
                                          uint64_t a65,
                                          uint64_t a66,
                                          uint64_t a67,
                                          uint64_t a68,
                                          uint64_t a69,
                                          uint64_t a70,
                                          uint64_t a71,
                                          uint64_t a72,
                                          uint64_t a73,
                                          uint64_t a74,
                                          uint64_t a75,
                                          uint64_t a76,
                                          uint64_t a77,
                                          uint64_t a78,
                                          uint64_t a79,
                                          uint64_t a80,
                                          uint64_t a81,
                                          uint64_t a82,
                                          uint64_t a83,
                                          uint64_t a84,
                                          uint64_t a85,
                                          uint64_t a86,
                                          uint64_t a87,
                                          uint64_t a88,
                                          uint64_t a89,
                                          uint64_t a90,
                                          uint64_t a91,
                                          uint64_t a92,
                                          uint64_t a93,
                                          uint64_t a94,
                                          uint64_t a95,
                                          uint64_t a96,
                                          uint64_t a97,
                                          uint64_t a98,
                                          uint64_t a99,
                                          uint64_t a100,
                                          uint64_t a101,
                                          uint64_t a102,
                                          uint64_t a103,
                                          uint64_t a104,
                                          uint64_t a105,
                                          uint64_t a106,
                                          uint64_t a107,
                                          uint64_t a108,
                                          uint64_t a109,
                                          uint64_t a110,
                                          uint64_t a111,
                                          uint64_t a112,
                                          uint64_t a113,
                                          uint64_t a114,
                                          uint64_t a115,
                                          uint64_t a116,
                                          uint64_t a117,
                                          uint64_t a118,
                                          uint64_t a119,
                                          uint64_t a120,
                                          uint64_t a121,
                                          uint64_t a122,
                                          uint64_t a123,
                                          uint64_t a124,
                                          uint64_t a125,
                                          uint64_t a126,
                                          uint64_t a127)) {
  uint64_t a0;
  uint64_t a1;
  uint64_t a2;
  uint64_t a3;
  uint64_t a4;
  uint64_t a5;
  uint64_t a6;
  uint64_t a7;
  uint64_t a8;
  uint64_t a9;
  uint64_t a10;
  uint64_t a11;
  uint64_t a12;
  uint64_t a13;
  uint64_t a14;
  uint64_t a15;
  uint64_t a16;
  uint64_t a17;
  uint64_t a18;
  uint64_t a19;
  uint64_t a20;
  uint64_t a21;
  uint64_t a22;
  uint64_t a23;
  uint64_t a24;
  uint64_t a25;
  uint64_t a26;
  uint64_t a27;
  uint64_t a28;
  uint64_t a29;
  uint64_t a30;
  uint64_t a31;
  uint64_t a32;
  uint64_t a33;
  uint64_t a34;
  uint64_t a35;
  uint64_t a36;
  uint64_t a37;
  uint64_t a38;
  uint64_t a39;
  uint64_t a40;
  uint64_t a41;
  uint64_t a42;
  uint64_t a43;
  uint64_t a44;
  uint64_t a45;
  uint64_t a46;
  uint64_t a47;
  uint64_t a48;
  uint64_t a49;
  uint64_t a50;
  uint64_t a51;
  uint64_t a52;
  uint64_t a53;
  uint64_t a54;
  uint64_t a55;
  uint64_t a56;
  uint64_t a57;
  uint64_t a58;
  uint64_t a59;
  uint64_t a60;
  uint64_t a61;
  uint64_t a62;
  uint64_t a63;
  uint64_t a64;
  uint64_t a65;
  uint64_t a66;
  uint64_t a67;
  uint64_t a68;
  uint64_t a69;
  uint64_t a70;
  uint64_t a71;
  uint64_t a72;
  uint64_t a73;
  uint64_t a74;
  uint64_t a75;
  uint64_t a76;
  uint64_t a77;
  uint64_t a78;
  uint64_t a79;
  uint64_t a80;
  uint64_t a81;
  uint64_t a82;
  uint64_t a83;
  uint64_t a84;
  uint64_t a85;
  uint64_t a86;
  uint64_t a87;
  uint64_t a88;
  uint64_t a89;
  uint64_t a90;
  uint64_t a91;
  uint64_t a92;
  uint64_t a93;
  uint64_t a94;
  uint64_t a95;
  uint64_t a96;
  uint64_t a97;
  uint64_t a98;
  uint64_t a99;
  uint64_t a100;
  uint64_t a101;
  uint64_t a102;
  uint64_t a103;
  uint64_t a104;
  uint64_t a105;
  uint64_t a106;
  uint64_t a107;
  uint64_t a108;
  uint64_t a109;
  uint64_t a110;
  uint64_t a111;
  uint64_t a112;
  uint64_t a113;
  uint64_t a114;
  uint64_t a115;
  uint64_t a116;
  uint64_t a117;
  uint64_t a118;
  uint64_t a119;
  uint64_t a120;
  uint64_t a121;
  uint64_t a122;
  uint64_t a123;
  uint64_t a124;
  uint64_t a125;
  uint64_t a126;
  uint64_t a127;

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

  std::cout << "Calling TestReturnStruct1024BytesHomogeneousUint64("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", " << a8 << ", "
            << a9 << ", " << a10 << ", " << a11 << ", " << a12 << ", " << a13
            << ", " << a14 << ", " << a15 << ", " << a16 << ", " << a17 << ", "
            << a18 << ", " << a19 << ", " << a20 << ", " << a21 << ", " << a22
            << ", " << a23 << ", " << a24 << ", " << a25 << ", " << a26 << ", "
            << a27 << ", " << a28 << ", " << a29 << ", " << a30 << ", " << a31
            << ", " << a32 << ", " << a33 << ", " << a34 << ", " << a35 << ", "
            << a36 << ", " << a37 << ", " << a38 << ", " << a39 << ", " << a40
            << ", " << a41 << ", " << a42 << ", " << a43 << ", " << a44 << ", "
            << a45 << ", " << a46 << ", " << a47 << ", " << a48 << ", " << a49
            << ", " << a50 << ", " << a51 << ", " << a52 << ", " << a53 << ", "
            << a54 << ", " << a55 << ", " << a56 << ", " << a57 << ", " << a58
            << ", " << a59 << ", " << a60 << ", " << a61 << ", " << a62 << ", "
            << a63 << ", " << a64 << ", " << a65 << ", " << a66 << ", " << a67
            << ", " << a68 << ", " << a69 << ", " << a70 << ", " << a71 << ", "
            << a72 << ", " << a73 << ", " << a74 << ", " << a75 << ", " << a76
            << ", " << a77 << ", " << a78 << ", " << a79 << ", " << a80 << ", "
            << a81 << ", " << a82 << ", " << a83 << ", " << a84 << ", " << a85
            << ", " << a86 << ", " << a87 << ", " << a88 << ", " << a89 << ", "
            << a90 << ", " << a91 << ", " << a92 << ", " << a93 << ", " << a94
            << ", " << a95 << ", " << a96 << ", " << a97 << ", " << a98 << ", "
            << a99 << ", " << a100 << ", " << a101 << ", " << a102 << ", "
            << a103 << ", " << a104 << ", " << a105 << ", " << a106 << ", "
            << a107 << ", " << a108 << ", " << a109 << ", " << a110 << ", "
            << a111 << ", " << a112 << ", " << a113 << ", " << a114 << ", "
            << a115 << ", " << a116 << ", " << a117 << ", " << a118 << ", "
            << a119 << ", " << a120 << ", " << a121 << ", " << a122 << ", "
            << a123 << ", " << a124 << ", " << a125 << ", " << a126 << ", "
            << a127 << ")"
            << ")\n";

  Struct1024BytesHomogeneousUint64 result = f(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16,
      a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31,
      a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46,
      a47, a48, a49, a50, a51, a52, a53, a54, a55, a56, a57, a58, a59, a60, a61,
      a62, a63, a64, a65, a66, a67, a68, a69, a70, a71, a72, a73, a74, a75, a76,
      a77, a78, a79, a80, a81, a82, a83, a84, a85, a86, a87, a88, a89, a90, a91,
      a92, a93, a94, a95, a96, a97, a98, a99, a100, a101, a102, a103, a104,
      a105, a106, a107, a108, a109, a110, a111, a112, a113, a114, a115, a116,
      a117, a118, a119, a120, a121, a122, a123, a124, a125, a126, a127);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ", " << result.a5
            << ", " << result.a6 << ", " << result.a7 << ", " << result.a8
            << ", " << result.a9 << ", " << result.a10 << ", " << result.a11
            << ", " << result.a12 << ", " << result.a13 << ", " << result.a14
            << ", " << result.a15 << ", " << result.a16 << ", " << result.a17
            << ", " << result.a18 << ", " << result.a19 << ", " << result.a20
            << ", " << result.a21 << ", " << result.a22 << ", " << result.a23
            << ", " << result.a24 << ", " << result.a25 << ", " << result.a26
            << ", " << result.a27 << ", " << result.a28 << ", " << result.a29
            << ", " << result.a30 << ", " << result.a31 << ", " << result.a32
            << ", " << result.a33 << ", " << result.a34 << ", " << result.a35
            << ", " << result.a36 << ", " << result.a37 << ", " << result.a38
            << ", " << result.a39 << ", " << result.a40 << ", " << result.a41
            << ", " << result.a42 << ", " << result.a43 << ", " << result.a44
            << ", " << result.a45 << ", " << result.a46 << ", " << result.a47
            << ", " << result.a48 << ", " << result.a49 << ", " << result.a50
            << ", " << result.a51 << ", " << result.a52 << ", " << result.a53
            << ", " << result.a54 << ", " << result.a55 << ", " << result.a56
            << ", " << result.a57 << ", " << result.a58 << ", " << result.a59
            << ", " << result.a60 << ", " << result.a61 << ", " << result.a62
            << ", " << result.a63 << ", " << result.a64 << ", " << result.a65
            << ", " << result.a66 << ", " << result.a67 << ", " << result.a68
            << ", " << result.a69 << ", " << result.a70 << ", " << result.a71
            << ", " << result.a72 << ", " << result.a73 << ", " << result.a74
            << ", " << result.a75 << ", " << result.a76 << ", " << result.a77
            << ", " << result.a78 << ", " << result.a79 << ", " << result.a80
            << ", " << result.a81 << ", " << result.a82 << ", " << result.a83
            << ", " << result.a84 << ", " << result.a85 << ", " << result.a86
            << ", " << result.a87 << ", " << result.a88 << ", " << result.a89
            << ", " << result.a90 << ", " << result.a91 << ", " << result.a92
            << ", " << result.a93 << ", " << result.a94 << ", " << result.a95
            << ", " << result.a96 << ", " << result.a97 << ", " << result.a98
            << ", " << result.a99 << ", " << result.a100 << ", " << result.a101
            << ", " << result.a102 << ", " << result.a103 << ", " << result.a104
            << ", " << result.a105 << ", " << result.a106 << ", " << result.a107
            << ", " << result.a108 << ", " << result.a109 << ", " << result.a110
            << ", " << result.a111 << ", " << result.a112 << ", " << result.a113
            << ", " << result.a114 << ", " << result.a115 << ", " << result.a116
            << ", " << result.a117 << ", " << result.a118 << ", " << result.a119
            << ", " << result.a120 << ", " << result.a121 << ", " << result.a122
            << ", " << result.a123 << ", " << result.a124 << ", " << result.a125
            << ", " << result.a126 << ", " << result.a127 << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);
  CHECK_EQ(a3, result.a3);
  CHECK_EQ(a4, result.a4);
  CHECK_EQ(a5, result.a5);
  CHECK_EQ(a6, result.a6);
  CHECK_EQ(a7, result.a7);
  CHECK_EQ(a8, result.a8);
  CHECK_EQ(a9, result.a9);
  CHECK_EQ(a10, result.a10);
  CHECK_EQ(a11, result.a11);
  CHECK_EQ(a12, result.a12);
  CHECK_EQ(a13, result.a13);
  CHECK_EQ(a14, result.a14);
  CHECK_EQ(a15, result.a15);
  CHECK_EQ(a16, result.a16);
  CHECK_EQ(a17, result.a17);
  CHECK_EQ(a18, result.a18);
  CHECK_EQ(a19, result.a19);
  CHECK_EQ(a20, result.a20);
  CHECK_EQ(a21, result.a21);
  CHECK_EQ(a22, result.a22);
  CHECK_EQ(a23, result.a23);
  CHECK_EQ(a24, result.a24);
  CHECK_EQ(a25, result.a25);
  CHECK_EQ(a26, result.a26);
  CHECK_EQ(a27, result.a27);
  CHECK_EQ(a28, result.a28);
  CHECK_EQ(a29, result.a29);
  CHECK_EQ(a30, result.a30);
  CHECK_EQ(a31, result.a31);
  CHECK_EQ(a32, result.a32);
  CHECK_EQ(a33, result.a33);
  CHECK_EQ(a34, result.a34);
  CHECK_EQ(a35, result.a35);
  CHECK_EQ(a36, result.a36);
  CHECK_EQ(a37, result.a37);
  CHECK_EQ(a38, result.a38);
  CHECK_EQ(a39, result.a39);
  CHECK_EQ(a40, result.a40);
  CHECK_EQ(a41, result.a41);
  CHECK_EQ(a42, result.a42);
  CHECK_EQ(a43, result.a43);
  CHECK_EQ(a44, result.a44);
  CHECK_EQ(a45, result.a45);
  CHECK_EQ(a46, result.a46);
  CHECK_EQ(a47, result.a47);
  CHECK_EQ(a48, result.a48);
  CHECK_EQ(a49, result.a49);
  CHECK_EQ(a50, result.a50);
  CHECK_EQ(a51, result.a51);
  CHECK_EQ(a52, result.a52);
  CHECK_EQ(a53, result.a53);
  CHECK_EQ(a54, result.a54);
  CHECK_EQ(a55, result.a55);
  CHECK_EQ(a56, result.a56);
  CHECK_EQ(a57, result.a57);
  CHECK_EQ(a58, result.a58);
  CHECK_EQ(a59, result.a59);
  CHECK_EQ(a60, result.a60);
  CHECK_EQ(a61, result.a61);
  CHECK_EQ(a62, result.a62);
  CHECK_EQ(a63, result.a63);
  CHECK_EQ(a64, result.a64);
  CHECK_EQ(a65, result.a65);
  CHECK_EQ(a66, result.a66);
  CHECK_EQ(a67, result.a67);
  CHECK_EQ(a68, result.a68);
  CHECK_EQ(a69, result.a69);
  CHECK_EQ(a70, result.a70);
  CHECK_EQ(a71, result.a71);
  CHECK_EQ(a72, result.a72);
  CHECK_EQ(a73, result.a73);
  CHECK_EQ(a74, result.a74);
  CHECK_EQ(a75, result.a75);
  CHECK_EQ(a76, result.a76);
  CHECK_EQ(a77, result.a77);
  CHECK_EQ(a78, result.a78);
  CHECK_EQ(a79, result.a79);
  CHECK_EQ(a80, result.a80);
  CHECK_EQ(a81, result.a81);
  CHECK_EQ(a82, result.a82);
  CHECK_EQ(a83, result.a83);
  CHECK_EQ(a84, result.a84);
  CHECK_EQ(a85, result.a85);
  CHECK_EQ(a86, result.a86);
  CHECK_EQ(a87, result.a87);
  CHECK_EQ(a88, result.a88);
  CHECK_EQ(a89, result.a89);
  CHECK_EQ(a90, result.a90);
  CHECK_EQ(a91, result.a91);
  CHECK_EQ(a92, result.a92);
  CHECK_EQ(a93, result.a93);
  CHECK_EQ(a94, result.a94);
  CHECK_EQ(a95, result.a95);
  CHECK_EQ(a96, result.a96);
  CHECK_EQ(a97, result.a97);
  CHECK_EQ(a98, result.a98);
  CHECK_EQ(a99, result.a99);
  CHECK_EQ(a100, result.a100);
  CHECK_EQ(a101, result.a101);
  CHECK_EQ(a102, result.a102);
  CHECK_EQ(a103, result.a103);
  CHECK_EQ(a104, result.a104);
  CHECK_EQ(a105, result.a105);
  CHECK_EQ(a106, result.a106);
  CHECK_EQ(a107, result.a107);
  CHECK_EQ(a108, result.a108);
  CHECK_EQ(a109, result.a109);
  CHECK_EQ(a110, result.a110);
  CHECK_EQ(a111, result.a111);
  CHECK_EQ(a112, result.a112);
  CHECK_EQ(a113, result.a113);
  CHECK_EQ(a114, result.a114);
  CHECK_EQ(a115, result.a115);
  CHECK_EQ(a116, result.a116);
  CHECK_EQ(a117, result.a117);
  CHECK_EQ(a118, result.a118);
  CHECK_EQ(a119, result.a119);
  CHECK_EQ(a120, result.a120);
  CHECK_EQ(a121, result.a121);
  CHECK_EQ(a122, result.a122);
  CHECK_EQ(a123, result.a123);
  CHECK_EQ(a124, result.a124);
  CHECK_EQ(a125, result.a125);
  CHECK_EQ(a126, result.a126);
  CHECK_EQ(a127, result.a127);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16,
      a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31,
      a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46,
      a47, a48, a49, a50, a51, a52, a53, a54, a55, a56, a57, a58, a59, a60, a61,
      a62, a63, a64, a65, a66, a67, a68, a69, a70, a71, a72, a73, a74, a75, a76,
      a77, a78, a79, a80, a81, a82, a83, a84, a85, a86, a87, a88, a89, a90, a91,
      a92, a93, a94, a95, a96, a97, a98, a99, a100, a101, a102, a103, a104,
      a105, a106, a107, a108, a109, a110, a111, a112, a113, a114, a115, a116,
      a117, a118, a119, a120, a121, a122, a123, a124, a125, a126, a127);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);
  CHECK_EQ(0, result.a9);
  CHECK_EQ(0, result.a10);
  CHECK_EQ(0, result.a11);
  CHECK_EQ(0, result.a12);
  CHECK_EQ(0, result.a13);
  CHECK_EQ(0, result.a14);
  CHECK_EQ(0, result.a15);
  CHECK_EQ(0, result.a16);
  CHECK_EQ(0, result.a17);
  CHECK_EQ(0, result.a18);
  CHECK_EQ(0, result.a19);
  CHECK_EQ(0, result.a20);
  CHECK_EQ(0, result.a21);
  CHECK_EQ(0, result.a22);
  CHECK_EQ(0, result.a23);
  CHECK_EQ(0, result.a24);
  CHECK_EQ(0, result.a25);
  CHECK_EQ(0, result.a26);
  CHECK_EQ(0, result.a27);
  CHECK_EQ(0, result.a28);
  CHECK_EQ(0, result.a29);
  CHECK_EQ(0, result.a30);
  CHECK_EQ(0, result.a31);
  CHECK_EQ(0, result.a32);
  CHECK_EQ(0, result.a33);
  CHECK_EQ(0, result.a34);
  CHECK_EQ(0, result.a35);
  CHECK_EQ(0, result.a36);
  CHECK_EQ(0, result.a37);
  CHECK_EQ(0, result.a38);
  CHECK_EQ(0, result.a39);
  CHECK_EQ(0, result.a40);
  CHECK_EQ(0, result.a41);
  CHECK_EQ(0, result.a42);
  CHECK_EQ(0, result.a43);
  CHECK_EQ(0, result.a44);
  CHECK_EQ(0, result.a45);
  CHECK_EQ(0, result.a46);
  CHECK_EQ(0, result.a47);
  CHECK_EQ(0, result.a48);
  CHECK_EQ(0, result.a49);
  CHECK_EQ(0, result.a50);
  CHECK_EQ(0, result.a51);
  CHECK_EQ(0, result.a52);
  CHECK_EQ(0, result.a53);
  CHECK_EQ(0, result.a54);
  CHECK_EQ(0, result.a55);
  CHECK_EQ(0, result.a56);
  CHECK_EQ(0, result.a57);
  CHECK_EQ(0, result.a58);
  CHECK_EQ(0, result.a59);
  CHECK_EQ(0, result.a60);
  CHECK_EQ(0, result.a61);
  CHECK_EQ(0, result.a62);
  CHECK_EQ(0, result.a63);
  CHECK_EQ(0, result.a64);
  CHECK_EQ(0, result.a65);
  CHECK_EQ(0, result.a66);
  CHECK_EQ(0, result.a67);
  CHECK_EQ(0, result.a68);
  CHECK_EQ(0, result.a69);
  CHECK_EQ(0, result.a70);
  CHECK_EQ(0, result.a71);
  CHECK_EQ(0, result.a72);
  CHECK_EQ(0, result.a73);
  CHECK_EQ(0, result.a74);
  CHECK_EQ(0, result.a75);
  CHECK_EQ(0, result.a76);
  CHECK_EQ(0, result.a77);
  CHECK_EQ(0, result.a78);
  CHECK_EQ(0, result.a79);
  CHECK_EQ(0, result.a80);
  CHECK_EQ(0, result.a81);
  CHECK_EQ(0, result.a82);
  CHECK_EQ(0, result.a83);
  CHECK_EQ(0, result.a84);
  CHECK_EQ(0, result.a85);
  CHECK_EQ(0, result.a86);
  CHECK_EQ(0, result.a87);
  CHECK_EQ(0, result.a88);
  CHECK_EQ(0, result.a89);
  CHECK_EQ(0, result.a90);
  CHECK_EQ(0, result.a91);
  CHECK_EQ(0, result.a92);
  CHECK_EQ(0, result.a93);
  CHECK_EQ(0, result.a94);
  CHECK_EQ(0, result.a95);
  CHECK_EQ(0, result.a96);
  CHECK_EQ(0, result.a97);
  CHECK_EQ(0, result.a98);
  CHECK_EQ(0, result.a99);
  CHECK_EQ(0, result.a100);
  CHECK_EQ(0, result.a101);
  CHECK_EQ(0, result.a102);
  CHECK_EQ(0, result.a103);
  CHECK_EQ(0, result.a104);
  CHECK_EQ(0, result.a105);
  CHECK_EQ(0, result.a106);
  CHECK_EQ(0, result.a107);
  CHECK_EQ(0, result.a108);
  CHECK_EQ(0, result.a109);
  CHECK_EQ(0, result.a110);
  CHECK_EQ(0, result.a111);
  CHECK_EQ(0, result.a112);
  CHECK_EQ(0, result.a113);
  CHECK_EQ(0, result.a114);
  CHECK_EQ(0, result.a115);
  CHECK_EQ(0, result.a116);
  CHECK_EQ(0, result.a117);
  CHECK_EQ(0, result.a118);
  CHECK_EQ(0, result.a119);
  CHECK_EQ(0, result.a120);
  CHECK_EQ(0, result.a121);
  CHECK_EQ(0, result.a122);
  CHECK_EQ(0, result.a123);
  CHECK_EQ(0, result.a124);
  CHECK_EQ(0, result.a125);
  CHECK_EQ(0, result.a126);
  CHECK_EQ(0, result.a127);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(
      a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16,
      a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31,
      a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46,
      a47, a48, a49, a50, a51, a52, a53, a54, a55, a56, a57, a58, a59, a60, a61,
      a62, a63, a64, a65, a66, a67, a68, a69, a70, a71, a72, a73, a74, a75, a76,
      a77, a78, a79, a80, a81, a82, a83, a84, a85, a86, a87, a88, a89, a90, a91,
      a92, a93, a94, a95, a96, a97, a98, a99, a100, a101, a102, a103, a104,
      a105, a106, a107, a108, a109, a110, a111, a112, a113, a114, a115, a116,
      a117, a118, a119, a120, a121, a122, a123, a124, a125, a126, a127);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);
  CHECK_EQ(0, result.a5);
  CHECK_EQ(0, result.a6);
  CHECK_EQ(0, result.a7);
  CHECK_EQ(0, result.a8);
  CHECK_EQ(0, result.a9);
  CHECK_EQ(0, result.a10);
  CHECK_EQ(0, result.a11);
  CHECK_EQ(0, result.a12);
  CHECK_EQ(0, result.a13);
  CHECK_EQ(0, result.a14);
  CHECK_EQ(0, result.a15);
  CHECK_EQ(0, result.a16);
  CHECK_EQ(0, result.a17);
  CHECK_EQ(0, result.a18);
  CHECK_EQ(0, result.a19);
  CHECK_EQ(0, result.a20);
  CHECK_EQ(0, result.a21);
  CHECK_EQ(0, result.a22);
  CHECK_EQ(0, result.a23);
  CHECK_EQ(0, result.a24);
  CHECK_EQ(0, result.a25);
  CHECK_EQ(0, result.a26);
  CHECK_EQ(0, result.a27);
  CHECK_EQ(0, result.a28);
  CHECK_EQ(0, result.a29);
  CHECK_EQ(0, result.a30);
  CHECK_EQ(0, result.a31);
  CHECK_EQ(0, result.a32);
  CHECK_EQ(0, result.a33);
  CHECK_EQ(0, result.a34);
  CHECK_EQ(0, result.a35);
  CHECK_EQ(0, result.a36);
  CHECK_EQ(0, result.a37);
  CHECK_EQ(0, result.a38);
  CHECK_EQ(0, result.a39);
  CHECK_EQ(0, result.a40);
  CHECK_EQ(0, result.a41);
  CHECK_EQ(0, result.a42);
  CHECK_EQ(0, result.a43);
  CHECK_EQ(0, result.a44);
  CHECK_EQ(0, result.a45);
  CHECK_EQ(0, result.a46);
  CHECK_EQ(0, result.a47);
  CHECK_EQ(0, result.a48);
  CHECK_EQ(0, result.a49);
  CHECK_EQ(0, result.a50);
  CHECK_EQ(0, result.a51);
  CHECK_EQ(0, result.a52);
  CHECK_EQ(0, result.a53);
  CHECK_EQ(0, result.a54);
  CHECK_EQ(0, result.a55);
  CHECK_EQ(0, result.a56);
  CHECK_EQ(0, result.a57);
  CHECK_EQ(0, result.a58);
  CHECK_EQ(0, result.a59);
  CHECK_EQ(0, result.a60);
  CHECK_EQ(0, result.a61);
  CHECK_EQ(0, result.a62);
  CHECK_EQ(0, result.a63);
  CHECK_EQ(0, result.a64);
  CHECK_EQ(0, result.a65);
  CHECK_EQ(0, result.a66);
  CHECK_EQ(0, result.a67);
  CHECK_EQ(0, result.a68);
  CHECK_EQ(0, result.a69);
  CHECK_EQ(0, result.a70);
  CHECK_EQ(0, result.a71);
  CHECK_EQ(0, result.a72);
  CHECK_EQ(0, result.a73);
  CHECK_EQ(0, result.a74);
  CHECK_EQ(0, result.a75);
  CHECK_EQ(0, result.a76);
  CHECK_EQ(0, result.a77);
  CHECK_EQ(0, result.a78);
  CHECK_EQ(0, result.a79);
  CHECK_EQ(0, result.a80);
  CHECK_EQ(0, result.a81);
  CHECK_EQ(0, result.a82);
  CHECK_EQ(0, result.a83);
  CHECK_EQ(0, result.a84);
  CHECK_EQ(0, result.a85);
  CHECK_EQ(0, result.a86);
  CHECK_EQ(0, result.a87);
  CHECK_EQ(0, result.a88);
  CHECK_EQ(0, result.a89);
  CHECK_EQ(0, result.a90);
  CHECK_EQ(0, result.a91);
  CHECK_EQ(0, result.a92);
  CHECK_EQ(0, result.a93);
  CHECK_EQ(0, result.a94);
  CHECK_EQ(0, result.a95);
  CHECK_EQ(0, result.a96);
  CHECK_EQ(0, result.a97);
  CHECK_EQ(0, result.a98);
  CHECK_EQ(0, result.a99);
  CHECK_EQ(0, result.a100);
  CHECK_EQ(0, result.a101);
  CHECK_EQ(0, result.a102);
  CHECK_EQ(0, result.a103);
  CHECK_EQ(0, result.a104);
  CHECK_EQ(0, result.a105);
  CHECK_EQ(0, result.a106);
  CHECK_EQ(0, result.a107);
  CHECK_EQ(0, result.a108);
  CHECK_EQ(0, result.a109);
  CHECK_EQ(0, result.a110);
  CHECK_EQ(0, result.a111);
  CHECK_EQ(0, result.a112);
  CHECK_EQ(0, result.a113);
  CHECK_EQ(0, result.a114);
  CHECK_EQ(0, result.a115);
  CHECK_EQ(0, result.a116);
  CHECK_EQ(0, result.a117);
  CHECK_EQ(0, result.a118);
  CHECK_EQ(0, result.a119);
  CHECK_EQ(0, result.a120);
  CHECK_EQ(0, result.a121);
  CHECK_EQ(0, result.a122);
  CHECK_EQ(0, result.a123);
  CHECK_EQ(0, result.a124);
  CHECK_EQ(0, result.a125);
  CHECK_EQ(0, result.a126);
  CHECK_EQ(0, result.a127);

  return 0;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed in int registers in most ABIs.
DART_EXPORT intptr_t TestReturnStructArgumentStruct1ByteInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct1ByteInt (*f)(Struct1ByteInt a0)) {
  Struct1ByteInt a0;

  a0.a0 = -1;

  std::cout << "Calling TestReturnStructArgumentStruct1ByteInt("
            << "((" << static_cast<int>(a0.a0) << "))"
            << ")\n";

  Struct1ByteInt result = f(a0);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  CHECK_EQ(a0.a0, result.a0);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result.a0);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result.a0);

  return 0;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed on stack on all ABIs.
DART_EXPORT intptr_t TestReturnStructArgumentInt32x8Struct1ByteInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct1ByteInt (*f)(int32_t a0,
                        int32_t a1,
                        int32_t a2,
                        int32_t a3,
                        int32_t a4,
                        int32_t a5,
                        int32_t a6,
                        int32_t a7,
                        Struct1ByteInt a8)) {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  int32_t a4;
  int32_t a5;
  int32_t a6;
  int32_t a7;
  Struct1ByteInt a8;

  a0 = -1;
  a1 = 2;
  a2 = -3;
  a3 = 4;
  a4 = -5;
  a5 = 6;
  a6 = -7;
  a7 = 8;
  a8.a0 = -9;

  std::cout << "Calling TestReturnStructArgumentInt32x8Struct1ByteInt("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", ("
            << static_cast<int>(a8.a0) << "))"
            << ")\n";

  Struct1ByteInt result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ")"
            << "\n";

  CHECK_EQ(a8.a0, result.a0);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);

  return 0;
}

// Used for testing structs by value.
// Test that a struct passed in as argument can be returned.
// Especially for ffi callbacks.
// Struct is passed in float registers in most ABIs.
DART_EXPORT intptr_t TestReturnStructArgumentStruct8BytesHomogeneousFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesHomogeneousFloat (*f)(Struct8BytesHomogeneousFloat a0)) {
  Struct8BytesHomogeneousFloat a0;

  a0.a0 = -1.0;
  a0.a1 = 2.0;

  std::cout << "Calling TestReturnStructArgumentStruct8BytesHomogeneousFloat("
            << "((" << a0.a0 << ", " << a0.a1 << "))"
            << ")\n";

  Struct8BytesHomogeneousFloat result = f(a0);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ")"
            << "\n";

  CHECK_APPROX(a0.a0, result.a0);
  CHECK_APPROX(a0.a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_APPROX(0.0, result.a0);
  CHECK_APPROX(0.0, result.a1);

  return 0;
}

// Used for testing structs by value.
// On arm64, both argument and return value are passed in by pointer.
DART_EXPORT intptr_t TestReturnStructArgumentStruct20BytesHomogeneousInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct20BytesHomogeneousInt32 (*f)(Struct20BytesHomogeneousInt32 a0)) {
  Struct20BytesHomogeneousInt32 a0;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a0.a3 = 4;
  a0.a4 = -5;

  std::cout << "Calling TestReturnStructArgumentStruct20BytesHomogeneousInt32("
            << "((" << a0.a0 << ", " << a0.a1 << ", " << a0.a2 << ", " << a0.a3
            << ", " << a0.a4 << "))"
            << ")\n";

  Struct20BytesHomogeneousInt32 result = f(a0);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  CHECK_EQ(a0.a0, result.a0);
  CHECK_EQ(a0.a1, result.a1);
  CHECK_EQ(a0.a2, result.a2);
  CHECK_EQ(a0.a3, result.a3);
  CHECK_EQ(a0.a4, result.a4);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  return 0;
}

// Used for testing structs by value.
// On arm64, both argument and return value are passed in by pointer.
// Ints exhaust registers, so that pointer is passed on stack.
DART_EXPORT intptr_t TestReturnStructArgumentInt32x8Struct20BytesHomogeneou(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct20BytesHomogeneousInt32 (*f)(int32_t a0,
                                       int32_t a1,
                                       int32_t a2,
                                       int32_t a3,
                                       int32_t a4,
                                       int32_t a5,
                                       int32_t a6,
                                       int32_t a7,
                                       Struct20BytesHomogeneousInt32 a8)) {
  int32_t a0;
  int32_t a1;
  int32_t a2;
  int32_t a3;
  int32_t a4;
  int32_t a5;
  int32_t a6;
  int32_t a7;
  Struct20BytesHomogeneousInt32 a8;

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

  std::cout << "Calling TestReturnStructArgumentInt32x8Struct20BytesHomogeneou("
            << "(" << a0 << ", " << a1 << ", " << a2 << ", " << a3 << ", " << a4
            << ", " << a5 << ", " << a6 << ", " << a7 << ", (" << a8.a0 << ", "
            << a8.a1 << ", " << a8.a2 << ", " << a8.a3 << ", " << a8.a4 << "))"
            << ")\n";

  Struct20BytesHomogeneousInt32 result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  std::cout << "result = "
            << "(" << result.a0 << ", " << result.a1 << ", " << result.a2
            << ", " << result.a3 << ", " << result.a4 << ")"
            << "\n";

  CHECK_EQ(a8.a0, result.a0);
  CHECK_EQ(a8.a1, result.a1);
  CHECK_EQ(a8.a2, result.a2);
  CHECK_EQ(a8.a3, result.a3);
  CHECK_EQ(a8.a4, result.a4);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3, a4, a5, a6, a7, a8);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);
  CHECK_EQ(0, result.a3);
  CHECK_EQ(0, result.a4);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 16 byte int within struct.
DART_EXPORT intptr_t TestReturnStructAlignmentInt16(
    // NOLINTNEXTLINE(whitespace/parens)
    StructAlignmentInt16 (*f)(int8_t a0, int16_t a1, int8_t a2)) {
  int8_t a0;
  int16_t a1;
  int8_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStructAlignmentInt16("
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << ")\n";

  StructAlignmentInt16 result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 32 byte int within struct.
DART_EXPORT intptr_t TestReturnStructAlignmentInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    StructAlignmentInt32 (*f)(int8_t a0, int32_t a1, int8_t a2)) {
  int8_t a0;
  int32_t a1;
  int8_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStructAlignmentInt32("
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << ")\n";

  StructAlignmentInt32 result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of 64 byte int within struct.
DART_EXPORT intptr_t TestReturnStructAlignmentInt64(
    // NOLINTNEXTLINE(whitespace/parens)
    StructAlignmentInt64 (*f)(int8_t a0, int64_t a1, int8_t a2)) {
  int8_t a0;
  int64_t a1;
  int8_t a2;

  a0 = -1;
  a1 = 2;
  a2 = -3;

  std::cout << "Calling TestReturnStructAlignmentInt64("
            << "(" << static_cast<int>(a0) << ", " << a1 << ", "
            << static_cast<int>(a2) << ")"
            << ")\n";

  StructAlignmentInt64 result = f(a0, a1, a2);

  std::cout << "result = "
            << "(" << static_cast<int>(result.a0) << ", " << result.a1 << ", "
            << static_cast<int>(result.a2) << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1, result.a1);
  CHECK_EQ(a2, result.a2);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1);
  CHECK_EQ(0, result.a2);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct.
DART_EXPORT intptr_t TestReturnStruct8BytesNestedInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesNestedInt (*f)(Struct4BytesHomogeneousInt16 a0,
                               Struct4BytesHomogeneousInt16 a1)) {
  Struct4BytesHomogeneousInt16 a0;
  Struct4BytesHomogeneousInt16 a1;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3;
  a1.a1 = 4;

  std::cout << "Calling TestReturnStruct8BytesNestedInt("
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << ", "
            << a1.a1 << "))"
            << ")\n";

  Struct8BytesNestedInt result = f(a0, a1);

  std::cout << "result = "
            << "((" << result.a0.a0 << ", " << result.a0.a1 << "), ("
            << result.a1.a0 << ", " << result.a1.a1 << "))"
            << "\n";

  CHECK_EQ(a0.a0, result.a0.a0);
  CHECK_EQ(a0.a1, result.a0.a1);
  CHECK_EQ(a1.a0, result.a1.a0);
  CHECK_EQ(a1.a1, result.a1.a1);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct with floats.
DART_EXPORT intptr_t TestReturnStruct8BytesNestedFloat(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesNestedFloat (*f)(Struct4BytesFloat a0, Struct4BytesFloat a1)) {
  Struct4BytesFloat a0;
  Struct4BytesFloat a1;

  a0.a0 = -1.0;
  a1.a0 = 2.0;

  std::cout << "Calling TestReturnStruct8BytesNestedFloat("
            << "((" << a0.a0 << "), (" << a1.a0 << "))"
            << ")\n";

  Struct8BytesNestedFloat result = f(a0, a1);

  std::cout << "result = "
            << "((" << result.a0.a0 << "), (" << result.a1.a0 << "))"
            << "\n";

  CHECK_APPROX(a0.a0, result.a0.a0);
  CHECK_APPROX(a1.a0, result.a1.a0);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0);

  return 0;
}

// Used for testing structs by value.
// The nesting is irregular, testing homogenous float rules on arm and arm64,
// and the fpu register usage on x64.
DART_EXPORT intptr_t TestReturnStruct8BytesNestedFloat2(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesNestedFloat2 (*f)(Struct4BytesFloat a0, float a1)) {
  Struct4BytesFloat a0;
  float a1;

  a0.a0 = -1.0;
  a1 = 2.0;

  std::cout << "Calling TestReturnStruct8BytesNestedFloat2("
            << "((" << a0.a0 << "), " << a1 << ")"
            << ")\n";

  Struct8BytesNestedFloat2 result = f(a0, a1);

  std::cout << "result = "
            << "((" << result.a0.a0 << "), " << result.a1 << ")"
            << "\n";

  CHECK_APPROX(a0.a0, result.a0.a0);
  CHECK_APPROX(a1, result.a1);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0.a0);
  CHECK_APPROX(0.0, result.a1);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_APPROX(0.0, result.a0.a0);
  CHECK_APPROX(0.0, result.a1);

  return 0;
}

// Used for testing structs by value.
// Simple nested struct with mixed members.
DART_EXPORT intptr_t TestReturnStruct8BytesNestedMixed(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct8BytesNestedMixed (*f)(Struct4BytesHomogeneousInt16 a0,
                                 Struct4BytesFloat a1)) {
  Struct4BytesHomogeneousInt16 a0;
  Struct4BytesFloat a1;

  a0.a0 = -1;
  a0.a1 = 2;
  a1.a0 = -3.0;

  std::cout << "Calling TestReturnStruct8BytesNestedMixed("
            << "((" << a0.a0 << ", " << a0.a1 << "), (" << a1.a0 << "))"
            << ")\n";

  Struct8BytesNestedMixed result = f(a0, a1);

  std::cout << "result = "
            << "((" << result.a0.a0 << ", " << result.a0.a1 << "), ("
            << result.a1.a0 << "))"
            << "\n";

  CHECK_EQ(a0.a0, result.a0.a0);
  CHECK_EQ(a0.a1, result.a0.a1);
  CHECK_APPROX(a1.a0, result.a1.a0);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_APPROX(0.0, result.a1.a0);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_APPROX(0.0, result.a1.a0);

  return 0;
}

// Used for testing structs by value.
// Deeper nested struct to test recursive member access.
DART_EXPORT intptr_t TestReturnStruct16BytesNestedInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct16BytesNestedInt (*f)(Struct8BytesNestedInt a0,
                                Struct8BytesNestedInt a1)) {
  Struct8BytesNestedInt a0;
  Struct8BytesNestedInt a1;

  a0.a0.a0 = -1;
  a0.a0.a1 = 2;
  a0.a1.a0 = -3;
  a0.a1.a1 = 4;
  a1.a0.a0 = -5;
  a1.a0.a1 = 6;
  a1.a1.a0 = -7;
  a1.a1.a1 = 8;

  std::cout << "Calling TestReturnStruct16BytesNestedInt("
            << "(((" << a0.a0.a0 << ", " << a0.a0.a1 << "), (" << a0.a1.a0
            << ", " << a0.a1.a1 << ")), ((" << a1.a0.a0 << ", " << a1.a0.a1
            << "), (" << a1.a1.a0 << ", " << a1.a1.a1 << ")))"
            << ")\n";

  Struct16BytesNestedInt result = f(a0, a1);

  std::cout << "result = "
            << "(((" << result.a0.a0.a0 << ", " << result.a0.a0.a1 << "), ("
            << result.a0.a1.a0 << ", " << result.a0.a1.a1 << ")), (("
            << result.a1.a0.a0 << ", " << result.a1.a0.a1 << "), ("
            << result.a1.a1.a0 << ", " << result.a1.a1.a1 << ")))"
            << "\n";

  CHECK_EQ(a0.a0.a0, result.a0.a0.a0);
  CHECK_EQ(a0.a0.a1, result.a0.a0.a1);
  CHECK_EQ(a0.a1.a0, result.a0.a1.a0);
  CHECK_EQ(a0.a1.a1, result.a0.a1.a1);
  CHECK_EQ(a1.a0.a0, result.a1.a0.a0);
  CHECK_EQ(a1.a0.a1, result.a1.a0.a1);
  CHECK_EQ(a1.a1.a0, result.a1.a1.a0);
  CHECK_EQ(a1.a1.a1, result.a1.a1.a1);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0.a0);
  CHECK_EQ(0, result.a0.a0.a1);
  CHECK_EQ(0, result.a0.a1.a0);
  CHECK_EQ(0, result.a0.a1.a1);
  CHECK_EQ(0, result.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1);
  CHECK_EQ(0, result.a1.a1.a0);
  CHECK_EQ(0, result.a1.a1.a1);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0.a0);
  CHECK_EQ(0, result.a0.a0.a1);
  CHECK_EQ(0, result.a0.a1.a0);
  CHECK_EQ(0, result.a0.a1.a1);
  CHECK_EQ(0, result.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1);
  CHECK_EQ(0, result.a1.a1.a0);
  CHECK_EQ(0, result.a1.a1.a1);

  return 0;
}

// Used for testing structs by value.
// Even deeper nested struct to test recursive member access.
DART_EXPORT intptr_t TestReturnStruct32BytesNestedInt(
    // NOLINTNEXTLINE(whitespace/parens)
    Struct32BytesNestedInt (*f)(Struct16BytesNestedInt a0,
                                Struct16BytesNestedInt a1)) {
  Struct16BytesNestedInt a0;
  Struct16BytesNestedInt a1;

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

  std::cout << "Calling TestReturnStruct32BytesNestedInt("
            << "((((" << a0.a0.a0.a0 << ", " << a0.a0.a0.a1 << "), ("
            << a0.a0.a1.a0 << ", " << a0.a0.a1.a1 << ")), ((" << a0.a1.a0.a0
            << ", " << a0.a1.a0.a1 << "), (" << a0.a1.a1.a0 << ", "
            << a0.a1.a1.a1 << "))), (((" << a1.a0.a0.a0 << ", " << a1.a0.a0.a1
            << "), (" << a1.a0.a1.a0 << ", " << a1.a0.a1.a1 << ")), (("
            << a1.a1.a0.a0 << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0
            << ", " << a1.a1.a1.a1 << "))))"
            << ")\n";

  Struct32BytesNestedInt result = f(a0, a1);

  std::cout << "result = "
            << "((((" << result.a0.a0.a0.a0 << ", " << result.a0.a0.a0.a1
            << "), (" << result.a0.a0.a1.a0 << ", " << result.a0.a0.a1.a1
            << ")), ((" << result.a0.a1.a0.a0 << ", " << result.a0.a1.a0.a1
            << "), (" << result.a0.a1.a1.a0 << ", " << result.a0.a1.a1.a1
            << "))), (((" << result.a1.a0.a0.a0 << ", " << result.a1.a0.a0.a1
            << "), (" << result.a1.a0.a1.a0 << ", " << result.a1.a0.a1.a1
            << ")), ((" << result.a1.a1.a0.a0 << ", " << result.a1.a1.a0.a1
            << "), (" << result.a1.a1.a1.a0 << ", " << result.a1.a1.a1.a1
            << "))))"
            << "\n";

  CHECK_EQ(a0.a0.a0.a0, result.a0.a0.a0.a0);
  CHECK_EQ(a0.a0.a0.a1, result.a0.a0.a0.a1);
  CHECK_EQ(a0.a0.a1.a0, result.a0.a0.a1.a0);
  CHECK_EQ(a0.a0.a1.a1, result.a0.a0.a1.a1);
  CHECK_EQ(a0.a1.a0.a0, result.a0.a1.a0.a0);
  CHECK_EQ(a0.a1.a0.a1, result.a0.a1.a0.a1);
  CHECK_EQ(a0.a1.a1.a0, result.a0.a1.a1.a0);
  CHECK_EQ(a0.a1.a1.a1, result.a0.a1.a1.a1);
  CHECK_EQ(a1.a0.a0.a0, result.a1.a0.a0.a0);
  CHECK_EQ(a1.a0.a0.a1, result.a1.a0.a0.a1);
  CHECK_EQ(a1.a0.a1.a0, result.a1.a0.a1.a0);
  CHECK_EQ(a1.a0.a1.a1, result.a1.a0.a1.a1);
  CHECK_EQ(a1.a1.a0.a0, result.a1.a1.a0.a0);
  CHECK_EQ(a1.a1.a0.a1, result.a1.a1.a0.a1);
  CHECK_EQ(a1.a1.a1.a0, result.a1.a1.a1.a0);
  CHECK_EQ(a1.a1.a1.a1, result.a1.a1.a1.a1);

  // Pass argument that will make the Dart callback throw.
  a0.a0.a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0.a0.a0);
  CHECK_EQ(0, result.a0.a0.a0.a1);
  CHECK_EQ(0, result.a0.a0.a1.a0);
  CHECK_EQ(0, result.a0.a0.a1.a1);
  CHECK_EQ(0, result.a0.a1.a0.a0);
  CHECK_EQ(0, result.a0.a1.a0.a1);
  CHECK_EQ(0, result.a0.a1.a1.a0);
  CHECK_EQ(0, result.a0.a1.a1.a1);
  CHECK_EQ(0, result.a1.a0.a0.a0);
  CHECK_EQ(0, result.a1.a0.a0.a1);
  CHECK_EQ(0, result.a1.a0.a1.a0);
  CHECK_EQ(0, result.a1.a0.a1.a1);
  CHECK_EQ(0, result.a1.a1.a0.a0);
  CHECK_EQ(0, result.a1.a1.a0.a1);
  CHECK_EQ(0, result.a1.a1.a1.a0);
  CHECK_EQ(0, result.a1.a1.a1.a1);

  // Pass argument that will make the Dart callback return null.
  a0.a0.a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0.a0.a0);
  CHECK_EQ(0, result.a0.a0.a0.a1);
  CHECK_EQ(0, result.a0.a0.a1.a0);
  CHECK_EQ(0, result.a0.a0.a1.a1);
  CHECK_EQ(0, result.a0.a1.a0.a0);
  CHECK_EQ(0, result.a0.a1.a0.a1);
  CHECK_EQ(0, result.a0.a1.a1.a0);
  CHECK_EQ(0, result.a0.a1.a1.a1);
  CHECK_EQ(0, result.a1.a0.a0.a0);
  CHECK_EQ(0, result.a1.a0.a0.a1);
  CHECK_EQ(0, result.a1.a0.a1.a0);
  CHECK_EQ(0, result.a1.a0.a1.a1);
  CHECK_EQ(0, result.a1.a1.a0.a0);
  CHECK_EQ(0, result.a1.a1.a0.a1);
  CHECK_EQ(0, result.a1.a1.a1.a0);
  CHECK_EQ(0, result.a1.a1.a1.a1);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 16 byte int.
DART_EXPORT intptr_t TestReturnStructNestedIntStructAlignmentInt16(
    // NOLINTNEXTLINE(whitespace/parens)
    StructNestedIntStructAlignmentInt16 (*f)(StructAlignmentInt16 a0,
                                             StructAlignmentInt16 a1)) {
  StructAlignmentInt16 a0;
  StructAlignmentInt16 a1;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  std::cout << "Calling TestReturnStructNestedIntStructAlignmentInt16("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << ")\n";

  StructNestedIntStructAlignmentInt16 result = f(a0, a1);

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  CHECK_EQ(a0.a0, result.a0.a0);
  CHECK_EQ(a0.a1, result.a0.a1);
  CHECK_EQ(a0.a2, result.a0.a2);
  CHECK_EQ(a1.a0, result.a1.a0);
  CHECK_EQ(a1.a1, result.a1.a1);
  CHECK_EQ(a1.a2, result.a1.a2);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 32 byte int.
DART_EXPORT intptr_t TestReturnStructNestedIntStructAlignmentInt32(
    // NOLINTNEXTLINE(whitespace/parens)
    StructNestedIntStructAlignmentInt32 (*f)(StructAlignmentInt32 a0,
                                             StructAlignmentInt32 a1)) {
  StructAlignmentInt32 a0;
  StructAlignmentInt32 a1;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  std::cout << "Calling TestReturnStructNestedIntStructAlignmentInt32("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << ")\n";

  StructNestedIntStructAlignmentInt32 result = f(a0, a1);

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  CHECK_EQ(a0.a0, result.a0.a0);
  CHECK_EQ(a0.a1, result.a0.a1);
  CHECK_EQ(a0.a2, result.a0.a2);
  CHECK_EQ(a1.a0, result.a1.a0);
  CHECK_EQ(a1.a1, result.a1.a1);
  CHECK_EQ(a1.a2, result.a1.a2);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  return 0;
}

// Used for testing structs by value.
// Test alignment and padding of nested struct with 64 byte int.
DART_EXPORT intptr_t TestReturnStructNestedIntStructAlignmentInt64(
    // NOLINTNEXTLINE(whitespace/parens)
    StructNestedIntStructAlignmentInt64 (*f)(StructAlignmentInt64 a0,
                                             StructAlignmentInt64 a1)) {
  StructAlignmentInt64 a0;
  StructAlignmentInt64 a1;

  a0.a0 = -1;
  a0.a1 = 2;
  a0.a2 = -3;
  a1.a0 = 4;
  a1.a1 = -5;
  a1.a2 = 6;

  std::cout << "Calling TestReturnStructNestedIntStructAlignmentInt64("
            << "((" << static_cast<int>(a0.a0) << ", " << a0.a1 << ", "
            << static_cast<int>(a0.a2) << "), (" << static_cast<int>(a1.a0)
            << ", " << a1.a1 << ", " << static_cast<int>(a1.a2) << "))"
            << ")\n";

  StructNestedIntStructAlignmentInt64 result = f(a0, a1);

  std::cout << "result = "
            << "((" << static_cast<int>(result.a0.a0) << ", " << result.a0.a1
            << ", " << static_cast<int>(result.a0.a2) << "), ("
            << static_cast<int>(result.a1.a0) << ", " << result.a1.a1 << ", "
            << static_cast<int>(result.a1.a2) << "))"
            << "\n";

  CHECK_EQ(a0.a0, result.a0.a0);
  CHECK_EQ(a0.a1, result.a0.a1);
  CHECK_EQ(a0.a2, result.a0.a2);
  CHECK_EQ(a1.a0, result.a1.a0);
  CHECK_EQ(a1.a1, result.a1.a1);
  CHECK_EQ(a1.a2, result.a1.a2);

  // Pass argument that will make the Dart callback throw.
  a0.a0 = 42;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  // Pass argument that will make the Dart callback return null.
  a0.a0 = 84;

  result = f(a0, a1);

  CHECK_EQ(0, result.a0.a0);
  CHECK_EQ(0, result.a0.a1);
  CHECK_EQ(0, result.a0.a2);
  CHECK_EQ(0, result.a1.a0);
  CHECK_EQ(0, result.a1.a1);
  CHECK_EQ(0, result.a1.a2);

  return 0;
}

// Used for testing structs by value.
// Return big irregular struct as smoke test.
DART_EXPORT intptr_t TestReturnStructNestedIrregularEvenBigger(
    // NOLINTNEXTLINE(whitespace/parens)
    StructNestedIrregularEvenBigger (*f)(uint64_t a0,
                                         StructNestedIrregularBigger a1,
                                         StructNestedIrregularBigger a2,
                                         double a3)) {
  uint64_t a0;
  StructNestedIrregularBigger a1;
  StructNestedIrregularBigger a2;
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

  std::cout << "Calling TestReturnStructNestedIrregularEvenBigger("
            << "(" << a0 << ", ((" << a1.a0.a0 << ", ((" << a1.a0.a1.a0.a0
            << ", " << a1.a0.a1.a0.a1 << "), (" << a1.a0.a1.a1.a0 << ")), "
            << a1.a0.a2 << ", ((" << a1.a0.a3.a0.a0 << "), " << a1.a0.a3.a1
            << "), " << a1.a0.a4 << ", ((" << a1.a0.a5.a0.a0 << "), ("
            << a1.a0.a5.a1.a0 << ")), " << a1.a0.a6 << "), ((" << a1.a1.a0.a0
            << ", " << a1.a1.a0.a1 << "), (" << a1.a1.a1.a0 << ")), " << a1.a2
            << ", " << a1.a3 << "), ((" << a2.a0.a0 << ", ((" << a2.a0.a1.a0.a0
            << ", " << a2.a0.a1.a0.a1 << "), (" << a2.a0.a1.a1.a0 << ")), "
            << a2.a0.a2 << ", ((" << a2.a0.a3.a0.a0 << "), " << a2.a0.a3.a1
            << "), " << a2.a0.a4 << ", ((" << a2.a0.a5.a0.a0 << "), ("
            << a2.a0.a5.a1.a0 << ")), " << a2.a0.a6 << "), ((" << a2.a1.a0.a0
            << ", " << a2.a1.a0.a1 << "), (" << a2.a1.a1.a0 << ")), " << a2.a2
            << ", " << a2.a3 << "), " << a3 << ")"
            << ")\n";

  StructNestedIrregularEvenBigger result = f(a0, a1, a2, a3);

  std::cout << "result = "
            << "(" << result.a0 << ", ((" << result.a1.a0.a0 << ", (("
            << result.a1.a0.a1.a0.a0 << ", " << result.a1.a0.a1.a0.a1 << "), ("
            << result.a1.a0.a1.a1.a0 << ")), " << result.a1.a0.a2 << ", (("
            << result.a1.a0.a3.a0.a0 << "), " << result.a1.a0.a3.a1 << "), "
            << result.a1.a0.a4 << ", ((" << result.a1.a0.a5.a0.a0 << "), ("
            << result.a1.a0.a5.a1.a0 << ")), " << result.a1.a0.a6 << "), (("
            << result.a1.a1.a0.a0 << ", " << result.a1.a1.a0.a1 << "), ("
            << result.a1.a1.a1.a0 << ")), " << result.a1.a2 << ", "
            << result.a1.a3 << "), ((" << result.a2.a0.a0 << ", (("
            << result.a2.a0.a1.a0.a0 << ", " << result.a2.a0.a1.a0.a1 << "), ("
            << result.a2.a0.a1.a1.a0 << ")), " << result.a2.a0.a2 << ", (("
            << result.a2.a0.a3.a0.a0 << "), " << result.a2.a0.a3.a1 << "), "
            << result.a2.a0.a4 << ", ((" << result.a2.a0.a5.a0.a0 << "), ("
            << result.a2.a0.a5.a1.a0 << ")), " << result.a2.a0.a6 << "), (("
            << result.a2.a1.a0.a0 << ", " << result.a2.a1.a0.a1 << "), ("
            << result.a2.a1.a1.a0 << ")), " << result.a2.a2 << ", "
            << result.a2.a3 << "), " << result.a3 << ")"
            << "\n";

  CHECK_EQ(a0, result.a0);
  CHECK_EQ(a1.a0.a0, result.a1.a0.a0);
  CHECK_EQ(a1.a0.a1.a0.a0, result.a1.a0.a1.a0.a0);
  CHECK_EQ(a1.a0.a1.a0.a1, result.a1.a0.a1.a0.a1);
  CHECK_APPROX(a1.a0.a1.a1.a0, result.a1.a0.a1.a1.a0);
  CHECK_EQ(a1.a0.a2, result.a1.a0.a2);
  CHECK_APPROX(a1.a0.a3.a0.a0, result.a1.a0.a3.a0.a0);
  CHECK_APPROX(a1.a0.a3.a1, result.a1.a0.a3.a1);
  CHECK_EQ(a1.a0.a4, result.a1.a0.a4);
  CHECK_APPROX(a1.a0.a5.a0.a0, result.a1.a0.a5.a0.a0);
  CHECK_APPROX(a1.a0.a5.a1.a0, result.a1.a0.a5.a1.a0);
  CHECK_EQ(a1.a0.a6, result.a1.a0.a6);
  CHECK_EQ(a1.a1.a0.a0, result.a1.a1.a0.a0);
  CHECK_EQ(a1.a1.a0.a1, result.a1.a1.a0.a1);
  CHECK_APPROX(a1.a1.a1.a0, result.a1.a1.a1.a0);
  CHECK_APPROX(a1.a2, result.a1.a2);
  CHECK_APPROX(a1.a3, result.a1.a3);
  CHECK_EQ(a2.a0.a0, result.a2.a0.a0);
  CHECK_EQ(a2.a0.a1.a0.a0, result.a2.a0.a1.a0.a0);
  CHECK_EQ(a2.a0.a1.a0.a1, result.a2.a0.a1.a0.a1);
  CHECK_APPROX(a2.a0.a1.a1.a0, result.a2.a0.a1.a1.a0);
  CHECK_EQ(a2.a0.a2, result.a2.a0.a2);
  CHECK_APPROX(a2.a0.a3.a0.a0, result.a2.a0.a3.a0.a0);
  CHECK_APPROX(a2.a0.a3.a1, result.a2.a0.a3.a1);
  CHECK_EQ(a2.a0.a4, result.a2.a0.a4);
  CHECK_APPROX(a2.a0.a5.a0.a0, result.a2.a0.a5.a0.a0);
  CHECK_APPROX(a2.a0.a5.a1.a0, result.a2.a0.a5.a1.a0);
  CHECK_EQ(a2.a0.a6, result.a2.a0.a6);
  CHECK_EQ(a2.a1.a0.a0, result.a2.a1.a0.a0);
  CHECK_EQ(a2.a1.a0.a1, result.a2.a1.a0.a1);
  CHECK_APPROX(a2.a1.a1.a0, result.a2.a1.a1.a0);
  CHECK_APPROX(a2.a2, result.a2.a2);
  CHECK_APPROX(a2.a3, result.a2.a3);
  CHECK_APPROX(a3, result.a3);

  // Pass argument that will make the Dart callback throw.
  a0 = 42;

  result = f(a0, a1, a2, a3);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1.a0.a1);
  CHECK_APPROX(0.0, result.a1.a0.a1.a1.a0);
  CHECK_EQ(0, result.a1.a0.a2);
  CHECK_APPROX(0.0, result.a1.a0.a3.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0.a3.a1);
  CHECK_EQ(0, result.a1.a0.a4);
  CHECK_APPROX(0.0, result.a1.a0.a5.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0.a5.a1.a0);
  CHECK_EQ(0, result.a1.a0.a6);
  CHECK_EQ(0, result.a1.a1.a0.a0);
  CHECK_EQ(0, result.a1.a1.a0.a1);
  CHECK_APPROX(0.0, result.a1.a1.a1.a0);
  CHECK_APPROX(0.0, result.a1.a2);
  CHECK_APPROX(0.0, result.a1.a3);
  CHECK_EQ(0, result.a2.a0.a0);
  CHECK_EQ(0, result.a2.a0.a1.a0.a0);
  CHECK_EQ(0, result.a2.a0.a1.a0.a1);
  CHECK_APPROX(0.0, result.a2.a0.a1.a1.a0);
  CHECK_EQ(0, result.a2.a0.a2);
  CHECK_APPROX(0.0, result.a2.a0.a3.a0.a0);
  CHECK_APPROX(0.0, result.a2.a0.a3.a1);
  CHECK_EQ(0, result.a2.a0.a4);
  CHECK_APPROX(0.0, result.a2.a0.a5.a0.a0);
  CHECK_APPROX(0.0, result.a2.a0.a5.a1.a0);
  CHECK_EQ(0, result.a2.a0.a6);
  CHECK_EQ(0, result.a2.a1.a0.a0);
  CHECK_EQ(0, result.a2.a1.a0.a1);
  CHECK_APPROX(0.0, result.a2.a1.a1.a0);
  CHECK_APPROX(0.0, result.a2.a2);
  CHECK_APPROX(0.0, result.a2.a3);
  CHECK_APPROX(0.0, result.a3);

  // Pass argument that will make the Dart callback return null.
  a0 = 84;

  result = f(a0, a1, a2, a3);

  CHECK_EQ(0, result.a0);
  CHECK_EQ(0, result.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1.a0.a0);
  CHECK_EQ(0, result.a1.a0.a1.a0.a1);
  CHECK_APPROX(0.0, result.a1.a0.a1.a1.a0);
  CHECK_EQ(0, result.a1.a0.a2);
  CHECK_APPROX(0.0, result.a1.a0.a3.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0.a3.a1);
  CHECK_EQ(0, result.a1.a0.a4);
  CHECK_APPROX(0.0, result.a1.a0.a5.a0.a0);
  CHECK_APPROX(0.0, result.a1.a0.a5.a1.a0);
  CHECK_EQ(0, result.a1.a0.a6);
  CHECK_EQ(0, result.a1.a1.a0.a0);
  CHECK_EQ(0, result.a1.a1.a0.a1);
  CHECK_APPROX(0.0, result.a1.a1.a1.a0);
  CHECK_APPROX(0.0, result.a1.a2);
  CHECK_APPROX(0.0, result.a1.a3);
  CHECK_EQ(0, result.a2.a0.a0);
  CHECK_EQ(0, result.a2.a0.a1.a0.a0);
  CHECK_EQ(0, result.a2.a0.a1.a0.a1);
  CHECK_APPROX(0.0, result.a2.a0.a1.a1.a0);
  CHECK_EQ(0, result.a2.a0.a2);
  CHECK_APPROX(0.0, result.a2.a0.a3.a0.a0);
  CHECK_APPROX(0.0, result.a2.a0.a3.a1);
  CHECK_EQ(0, result.a2.a0.a4);
  CHECK_APPROX(0.0, result.a2.a0.a5.a0.a0);
  CHECK_APPROX(0.0, result.a2.a0.a5.a1.a0);
  CHECK_EQ(0, result.a2.a0.a6);
  CHECK_EQ(0, result.a2.a1.a0.a0);
  CHECK_EQ(0, result.a2.a1.a0.a1);
  CHECK_APPROX(0.0, result.a2.a1.a1.a0);
  CHECK_APPROX(0.0, result.a2.a2);
  CHECK_APPROX(0.0, result.a2.a3);
  CHECK_APPROX(0.0, result.a3);

  return 0;
}

}  // namespace dart
