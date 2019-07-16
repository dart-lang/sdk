// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains test functions for the dart:ffi test cases.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>
#include <csignal>

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)
#include <psapi.h>
#else
#include <unistd.h>
#endif

#include <setjmp.h>
#include <signal.h>
#include <iostream>
#include <limits>

#include "include/dart_api.h"
#include "include/dart_native_api.h"

namespace dart {

////////////////////////////////////////////////////////////////////////////////
// Tests for Dart -> native calls.

// Sums two ints and adds 42.
// Simple function to test trampolines.
// Also used for testing argument exception on passing null instead of a Dart
// int.
DART_EXPORT int32_t SumPlus42(int32_t a, int32_t b) {
  std::cout << "SumPlus42(" << a << ", " << b << ")\n";
  int32_t retval = 42 + a + b;
  std::cout << "returning " << retval << "\n";
  return retval;
}

//// Tests for sign and zero extension of arguments and results.

DART_EXPORT uint8_t ReturnMaxUint8() {
  return 0xff;
}

DART_EXPORT uint16_t ReturnMaxUint16() {
  return 0xffff;
}

DART_EXPORT uint32_t ReturnMaxUint32() {
  return 0xffffffff;
}

DART_EXPORT int8_t ReturnMinInt8() {
  return 0x80;
}

DART_EXPORT int16_t ReturnMinInt16() {
  return 0x8000;
}

DART_EXPORT int32_t ReturnMinInt32() {
  return 0x80000000;
}

DART_EXPORT intptr_t TakeMaxUint8(uint8_t x) {
  return x == 0xff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMaxUint16(uint16_t x) {
  return x == 0xffff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMaxUint32(uint32_t x) {
  return x == 0xffffffff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt8(int8_t x) {
  const int64_t expected = -0x80;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt16(int16_t x) {
  const int64_t expected = -0x8000;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt32(int32_t x) {
  const int64_t expected = kMinInt32;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

// Performs some computation on various sized signed ints.
// Used for testing value ranges for signed ints.
DART_EXPORT int64_t IntComputation(int8_t a, int16_t b, int32_t c, int64_t d) {
  std::cout << "IntComputation(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << d << ")\n";
  int64_t retval = d - c + b - a;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Performs some computation on various sized unsigned ints.
// Used for testing value ranges for unsigned ints.
DART_EXPORT int64_t UintComputation(uint8_t a,
                                    uint16_t b,
                                    uint32_t c,
                                    uint64_t d) {
  std::cout << "UintComputation(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << d << ")\n";
  uint64_t retval = d - c + b - a;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiplies pointer sized int by three.
// Used for testing pointer sized parameter and return value.
DART_EXPORT intptr_t Times3(intptr_t a) {
  std::cout << "Times3(" << a << ")\n";
  intptr_t retval = a * 3;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiples a double by 1.337.
// Used for testing double parameter and return value.
// Also used for testing argument exception on passing null instead of a Dart
// double.
DART_EXPORT double Times1_337Double(double a) {
  std::cout << "Times1_337Double(" << a << ")\n";
  double retval = a * 1.337;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiples a float by 1.337.
// Used for testing float parameter and return value.
DART_EXPORT float Times1_337Float(float a) {
  std::cout << "Times1_337Float(" << a << ")\n";
  float retval = a * 1.337f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many ints.
// Used for testing calling conventions. With so many integers we are using all
// normal parameter registers and some stack slots.
DART_EXPORT intptr_t SumManyInts(intptr_t a,
                                 intptr_t b,
                                 intptr_t c,
                                 intptr_t d,
                                 intptr_t e,
                                 intptr_t f,
                                 intptr_t g,
                                 intptr_t h,
                                 intptr_t i,
                                 intptr_t j) {
  std::cout << "SumManyInts(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ")\n";
  intptr_t retval = a + b + c + d + e + f + g + h + i + j;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums an odd number of ints.
// Used for testing calling conventions. With so many arguments, and an odd
// number of arguments, we are testing stack alignment on various architectures.
DART_EXPORT intptr_t SumManyIntsOdd(intptr_t a,
                                    intptr_t b,
                                    intptr_t c,
                                    intptr_t d,
                                    intptr_t e,
                                    intptr_t f,
                                    intptr_t g,
                                    intptr_t h,
                                    intptr_t i,
                                    intptr_t j,
                                    intptr_t k) {
  std::cout << "SumManyInts(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ", " << k << ")\n";
  intptr_t retval = a + b + c + d + e + f + g + h + i + j + k;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many doubles.
// Used for testing calling conventions. With so many doubles we are using all
// xmm parameter registers and some stack slots.
DART_EXPORT double SumManyDoubles(double a,
                                  double b,
                                  double c,
                                  double d,
                                  double e,
                                  double f,
                                  double g,
                                  double h,
                                  double i,
                                  double j) {
  std::cout << "SumManyDoubles(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ")\n";
  double retval = a + b + c + d + e + f + g + h + i + j;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many numbers.
// Used for testing calling conventions. With so many parameters we are using
// both registers and stack slots.
DART_EXPORT double SumManyNumbers(int a,
                                  float b,
                                  int c,
                                  double d,
                                  int e,
                                  float f,
                                  int g,
                                  double h,
                                  int i,
                                  float j,
                                  int k,
                                  double l,
                                  int m,
                                  float n,
                                  int o,
                                  double p,
                                  int q,
                                  float r,
                                  int s,
                                  double t) {
  std::cout << "SumManyNumbers(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ", " << k << ", " << l << ", " << m << ", " << n
            << ", " << o << ", " << p << ", " << q << ", " << r << ", " << s
            << ", " << t << ")\n";
  double retval = a + b + c + d + e + f + g + h + i + j + k + l + m + n + o +
                  p + q + r + s + t;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Assigns 1337 to the second element and returns the address of that element.
// Used for testing Pointer parameters and return values.
DART_EXPORT int64_t* Assign1337Index1(int64_t* a) {
  std::cout << "Assign1337Index1(" << a << ")\n";
  std::cout << "val[0] = " << a[0] << "\n";
  std::cout << "val[1] = " << a[1] << "\n";
  a[1] = 1337;
  std::cout << "val[1] = " << a[1] << "\n";
  int64_t* retval = a + 1;
  std::cout << "returning " << retval << "\n";
  return retval;
}

struct Coord {
  double x;
  double y;
  Coord* next;
};

// Transposes Coordinate by (10, 10) and returns next Coordinate.
// Used for testing struct pointer parameter, struct pointer return value,
// struct field access, and struct pointer field dereference.
DART_EXPORT Coord* TransposeCoordinate(Coord* coord) {
  std::cout << "TransposeCoordinate(" << coord << " {" << coord->x << ", "
            << coord->y << ", " << coord->next << "})\n";
  coord->x = coord->x + 10.0;
  coord->y = coord->y + 10.0;
  std::cout << "returning " << coord->next << "\n";
  return coord->next;
}

// Takes a Coordinate array and returns a Coordinate pointer to the next
// element.
// Used for testing struct arrays.
DART_EXPORT Coord* CoordinateElemAt1(Coord* coord) {
  std::cout << "CoordinateElemAt1(" << coord << ")\n";
  std::cout << "sizeof(Coord): " << sizeof(Coord) << "\n";
  std::cout << "coord[0] = {" << coord[0].x << ", " << coord[0].y << ", "
            << coord[0].next << "}\n";
  std::cout << "coord[1] = {" << coord[1].x << ", " << coord[1].y << ", "
            << coord[1].next << "}\n";
  Coord* retval = coord + 1;
  std::cout << "returning " << retval << "\n";
  return retval;
}

typedef Coord* (*CoordUnOp)(Coord* coord);

// Takes a Coordinate Function(Coordinate) and applies it three times to a
// Coordinate.
// Used for testing function pointers with structs.
DART_EXPORT Coord* CoordinateUnOpTrice(CoordUnOp unop, Coord* coord) {
  std::cout << "CoordinateUnOpTrice(" << unop << ", " << coord << ")\n";
  Coord* retval = unop(unop(unop(coord)));
  std::cout << "returning " << retval << "\n";
  return retval;
}

typedef intptr_t (*IntptrBinOp)(intptr_t a, intptr_t b);

// Returns a closure.
// Note this closure is not properly marked as DART_EXPORT or extern "C".
// Used for testing passing a pointer to a closure to Dart.
// TODO(dacoharkes): is this a supported use case?
DART_EXPORT IntptrBinOp IntptrAdditionClosure() {
  std::cout << "IntptrAdditionClosure()\n";
  IntptrBinOp retval = [](intptr_t a, intptr_t b) { return a + b; };
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Applies an intptr binop function to 42 and 74.
// Used for testing passing a function pointer to C.
DART_EXPORT intptr_t ApplyTo42And74(IntptrBinOp binop) {
  std::cout << "ApplyTo42And74()\n";
  intptr_t retval = binop(42, 74);
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Returns next element in the array, unless a null pointer is passed.
// When a null pointer is passed, a null pointer is returned.
// Used for testing null pointers.
DART_EXPORT int64_t* NullableInt64ElemAt1(int64_t* a) {
  std::cout << "NullableInt64ElemAt1(" << a << ")\n";
  int64_t* retval;
  if (a) {
    std::cout << "not null pointer, address: " << a << "\n";
    retval = a + 1;
  } else {
    std::cout << "null pointer, address: " << a << "\n";
    retval = nullptr;
  }
  std::cout << "returning " << retval << "\n";
  return retval;
}

// A struct designed to exercise all kinds of alignment rules.
// Note that offset32A (System V ia32) aligns doubles on 4 bytes while offset32B
// (Arm 32 bit and MSVC ia32) aligns on 8 bytes.
// TODO(37271): Support nested structs.
// TODO(37470): Add uncommon primitive data types when we want to support them.
struct VeryLargeStruct {
  //                             size32 size64 offset32A offset32B offset64
  int8_t a;                   // 1              0         0         0
  int16_t b;                  // 2              2         2         2
  int32_t c;                  // 4              4         4         4
  int64_t d;                  // 8              8         8         8
  uint8_t e;                  // 1             16        16        16
  uint16_t f;                 // 2             18        18        18
  uint32_t g;                 // 4             20        20        20
  uint64_t h;                 // 8             24        24        24
  intptr_t i;                 // 4      8      32        32        32
  double j;                   // 8             36        40        40
  float k;                    // 4             44        48        48
  VeryLargeStruct* parent;    // 4      8      48        52        56
  intptr_t numChildren;       // 4      8      52        56        64
  VeryLargeStruct* children;  // 4      8      56        60        72
  int8_t smallLastField;      // 1             60        64        80
                              // sizeof        64        72        88
};

// Sums the fields of a very large struct, including the first field (a) from
// the parent and children.
// Used for testing alignment and padding in structs.
DART_EXPORT int64_t SumVeryLargeStruct(VeryLargeStruct* vls) {
  std::cout << "SumVeryLargeStruct(" << vls << ")\n";
  std::cout << "offsetof(a): " << offsetof(VeryLargeStruct, a) << "\n";
  std::cout << "offsetof(b): " << offsetof(VeryLargeStruct, b) << "\n";
  std::cout << "offsetof(c): " << offsetof(VeryLargeStruct, c) << "\n";
  std::cout << "offsetof(d): " << offsetof(VeryLargeStruct, d) << "\n";
  std::cout << "offsetof(e): " << offsetof(VeryLargeStruct, e) << "\n";
  std::cout << "offsetof(f): " << offsetof(VeryLargeStruct, f) << "\n";
  std::cout << "offsetof(g): " << offsetof(VeryLargeStruct, g) << "\n";
  std::cout << "offsetof(h): " << offsetof(VeryLargeStruct, h) << "\n";
  std::cout << "offsetof(i): " << offsetof(VeryLargeStruct, i) << "\n";
  std::cout << "offsetof(j): " << offsetof(VeryLargeStruct, j) << "\n";
  std::cout << "offsetof(k): " << offsetof(VeryLargeStruct, k) << "\n";
  std::cout << "offsetof(parent): " << offsetof(VeryLargeStruct, parent)
            << "\n";
  std::cout << "offsetof(numChildren): "
            << offsetof(VeryLargeStruct, numChildren) << "\n";
  std::cout << "offsetof(children): " << offsetof(VeryLargeStruct, children)
            << "\n";
  std::cout << "offsetof(smallLastField): "
            << offsetof(VeryLargeStruct, smallLastField) << "\n";
  std::cout << "sizeof(VeryLargeStruct): " << sizeof(VeryLargeStruct) << "\n";

  std::cout << "vls->a: " << static_cast<int>(vls->a) << "\n";
  std::cout << "vls->b: " << vls->b << "\n";
  std::cout << "vls->c: " << vls->c << "\n";
  std::cout << "vls->d: " << vls->d << "\n";
  std::cout << "vls->e: " << static_cast<int>(vls->e) << "\n";
  std::cout << "vls->f: " << vls->f << "\n";
  std::cout << "vls->g: " << vls->g << "\n";
  std::cout << "vls->h: " << vls->h << "\n";
  std::cout << "vls->i: " << vls->i << "\n";
  std::cout << "vls->j: " << vls->j << "\n";
  std::cout << "vls->k: " << vls->k << "\n";
  std::cout << "vls->parent: " << vls->parent << "\n";
  std::cout << "vls->numChildren: " << vls->numChildren << "\n";
  std::cout << "vls->children: " << vls->children << "\n";
  std::cout << "vls->smallLastField: " << static_cast<int>(vls->smallLastField)
            << "\n";

  int64_t retval = 0;
  retval += 0x0L + vls->a;
  retval += vls->b;
  retval += vls->c;
  retval += vls->d;
  retval += vls->e;
  retval += vls->f;
  retval += vls->g;
  retval += vls->h;
  retval += vls->i;
  retval += vls->j;
  retval += vls->k;
  retval += vls->smallLastField;
  std::cout << retval << "\n";
  if (vls->parent) {
    std::cout << "has parent\n";
    retval += vls->parent->a;
  }
  std::cout << "has " << vls->numChildren << " children\n";
  for (int i = 0; i < vls->numChildren; i++) {
    retval += vls->children[i].a;
  }
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums numbers of various sizes.
// Used for testing truncation and sign extension of non 64 bit parameters.
DART_EXPORT int64_t SumSmallNumbers(int8_t a,
                                    int16_t b,
                                    int32_t c,
                                    uint8_t d,
                                    uint16_t e,
                                    uint32_t f) {
  std::cout << "SumSmallNumbers(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << static_cast<int>(d) << ", " << e << ", " << f
            << ")\n";
  int64_t retval = 0;
  retval += a;
  retval += b;
  retval += c;
  retval += d;
  retval += e;
  retval += f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Checks whether the float is between 1336.0f and 1338.0f.
// Used for testing rounding of Dart Doubles to floats in Pointer.store().
DART_EXPORT uint8_t IsRoughly1337(float* a) {
  std::cout << "IsRoughly1337(" << a[0] << ")\n";
  uint8_t retval = (1336.0f < a[0] && a[0] < 1338.0f) ? 1 : 0;
  std::cout << "returning " << static_cast<int>(retval) << "\n";
  return retval;
}

// Does nothing with input.
// Used for testing functions that return void
DART_EXPORT void DevNullFloat(float a) {
  std::cout << "DevNullFloat(" << a << ")\n";
  std::cout << "returning nothing\n";
}

// Invents an elite floating point number.
// Used for testing functions that do not take any arguments.
DART_EXPORT float InventFloatValue() {
  std::cout << "InventFloatValue()\n";
  float retval = 1337.0f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Functions for stress-testing.

DART_EXPORT int64_t MinInt64() {
  Dart_ExecuteInternalCommand("gc-on-next-allocation");
  return 0x8000000000000000;
}

DART_EXPORT int64_t MinInt32() {
  Dart_ExecuteInternalCommand("gc-on-next-allocation");
  return 0x80000000;
}

DART_EXPORT double SmallDouble() {
  Dart_ExecuteInternalCommand("gc-on-next-allocation");
  return 0x80000000 * -1.0;
}

// Requires boxing on 32-bit and 64-bit systems, even if the top 32-bits are
// truncated.
DART_EXPORT void* LargePointer() {
  Dart_ExecuteInternalCommand("gc-on-next-allocation");
  uint64_t origin = 0x8100000082000000;
  return reinterpret_cast<void*>(origin);
}

DART_EXPORT void TriggerGC(uint64_t count) {
  Dart_ExecuteInternalCommand("gc-now");
}

// Triggers GC. Has 11 dummy arguments as unboxed odd integers which should be
// ignored by GC.
DART_EXPORT void Regress37069(uint64_t a,
                              uint64_t b,
                              uint64_t c,
                              uint64_t d,
                              uint64_t e,
                              uint64_t f,
                              uint64_t g,
                              uint64_t h,
                              uint64_t i,
                              uint64_t j,
                              uint64_t k) {
  Dart_ExecuteInternalCommand("gc-now");
}

////////////////////////////////////////////////////////////////////////////////
// Tests for callbacks.

#define CHECK(X)                                                               \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s\n", "Check failed: " #X);                              \
    return 1;                                                                  \
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

// Sanity test.
DART_EXPORT int TestSimpleAddition(int (*add)(int, int)) {
  CHECK_EQ(add(10, 20), 30);
  return 0;
}

//// Following tests are copied from above, with the role of Dart and C++ code
//// reversed.

DART_EXPORT int TestIntComputation(
    int64_t (*fn)(int8_t, int16_t, int32_t, int64_t)) {
  CHECK_EQ(fn(125, 250, 500, 1000), 625);
  CHECK_EQ(0x7FFFFFFFFFFFFFFFLL, fn(0, 0, 0, 0x7FFFFFFFFFFFFFFFLL));
  CHECK_EQ(((int64_t)-0x8000000000000000LL),
           fn(0, 0, 0, -0x8000000000000000LL));
  return 0;
}

DART_EXPORT int TestUintComputation(
    uint64_t (*fn)(uint8_t, uint16_t, uint32_t, uint64_t)) {
  CHECK_EQ(0x7FFFFFFFFFFFFFFFLL, fn(0, 0, 0, 0x7FFFFFFFFFFFFFFFLL));
  CHECK_EQ(-0x8000000000000000LL, fn(0, 0, 0, -0x8000000000000000LL));
  CHECK_EQ(-1, (int64_t)fn(0, 0, 0, -1));
  return 0;
}

DART_EXPORT int TestSimpleMultiply(double (*fn)(double)) {
  CHECK_EQ(fn(2.0), 2.0 * 1.337);
  return 0;
}

DART_EXPORT int TestSimpleMultiplyFloat(float (*fn)(float)) {
  CHECK(std::abs(fn(2.0) - 2.0 * 1.337) < 0.001);
  return 0;
}

DART_EXPORT int TestManyInts(intptr_t (*fn)(intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t,
                                            intptr_t)) {
  CHECK_EQ(55, fn(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  return 0;
}

DART_EXPORT int TestManyDoubles(double (*fn)(double,
                                             double,
                                             double,
                                             double,
                                             double,
                                             double,
                                             double,
                                             double,
                                             double,
                                             double)) {
  CHECK_EQ(55, fn(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  return 0;
}

DART_EXPORT int TestManyArgs(double (*fn)(intptr_t a,
                                          float b,
                                          intptr_t c,
                                          double d,
                                          intptr_t e,
                                          float f,
                                          intptr_t g,
                                          double h,
                                          intptr_t i,
                                          float j,
                                          intptr_t k,
                                          double l,
                                          intptr_t m,
                                          float n,
                                          intptr_t o,
                                          double p,
                                          intptr_t q,
                                          float r,
                                          intptr_t s,
                                          double t)) {
  CHECK(210.0 == fn(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13, 14.0,
                    15, 16.0, 17, 18.0, 19, 20.0));
  return 0;
}

DART_EXPORT int TestStore(int64_t* (*fn)(int64_t* a)) {
  int64_t p[2] = {42, 1000};
  int64_t* result = fn(p);
  CHECK_EQ(*result, 1337);
  CHECK_EQ(p[1], 1337);
  CHECK_EQ(result, p + 1);
  return 0;
}

DART_EXPORT int TestReturnNull(int32_t (*fn)()) {
  CHECK_EQ(fn(), 42);
  return 0;
}

DART_EXPORT int TestNullPointers(int64_t* (*fn)(int64_t* ptr)) {
  CHECK_EQ(fn(nullptr), reinterpret_cast<void*>(sizeof(int64_t)));
  int64_t p[2] = {0};
  CHECK_EQ(fn(p), p + 1);
  return 0;
}

// Defined in ffi_test_functions.S.
//
// Clobbers some registers with special meaning in Dart before re-entry, for
// stress-testing. Not used on 32-bit Windows due to complications with Windows
// "safeseh".
#if defined(TARGET_OS_WINDOWS) && defined(HOST_ARCH_IA32)
void ClobberAndCall(void (*fn)()) {
  fn();
}
#else
extern "C" void ClobberAndCall(void (*fn)());
#endif

DART_EXPORT int TestGC(void (*do_gc)()) {
  ClobberAndCall(do_gc);
  return 0;
}

DART_EXPORT int TestReturnVoid(int (*return_void)()) {
  CHECK_EQ(return_void(), 0);
  return 0;
}

DART_EXPORT int TestThrowExceptionDouble(double (*fn)()) {
  CHECK_EQ(fn(), 42.0);
  return 0;
}

DART_EXPORT int TestThrowExceptionPointer(void* (*fn)()) {
  CHECK_EQ(fn(), reinterpret_cast<void*>(42));
  return 0;
}

DART_EXPORT int TestThrowException(int (*fn)()) {
  CHECK_EQ(fn(), 42);
  return 0;
}

struct CallbackTestData {
  int success;
  void (*callback)();
};

#if defined(TARGET_OS_LINUX)

thread_local sigjmp_buf buf;
void CallbackTestSignalHandler(int) {
  siglongjmp(buf, 1);
}

int ExpectAbort(void (*fn)()) {
  fprintf(stderr, "**** EXPECT STACKTRACE TO FOLLOW. THIS IS OK. ****\n");

  struct sigaction old_action = {};
  int result = __sigsetjmp(buf, /*savesigs=*/1);
  if (result == 0) {
    // Install signal handler.
    struct sigaction handler = {};
    handler.sa_handler = CallbackTestSignalHandler;
    sigemptyset(&handler.sa_mask);
    handler.sa_flags = 0;

    sigaction(SIGABRT, &handler, &old_action);

    fn();
  } else {
    // Caught the setjmp.
    sigaction(SIGABRT, &old_action, NULL);
    exit(0);
  }
  fprintf(stderr, "Expected abort!!!\n");
  exit(1);
}

void* TestCallbackOnThreadOutsideIsolate(void* parameter) {
  CallbackTestData* data = reinterpret_cast<CallbackTestData*>(parameter);
  data->success = ExpectAbort(data->callback);
  return NULL;
}

int TestCallbackOtherThreadHelper(void* (*tester)(void*), void (*fn)()) {
  CallbackTestData data = {1, fn};
  pthread_attr_t attr;
  int result = pthread_attr_init(&attr);
  CHECK_EQ(result, 0);

  pthread_t tid;
  result = pthread_create(&tid, &attr, tester, &data);
  CHECK_EQ(result, 0);

  result = pthread_attr_destroy(&attr);
  CHECK_EQ(result, 0);

  void* retval;
  result = pthread_join(tid, &retval);

  // Doesn't actually return because the other thread will exit when the test is
  // finished.
  return 1;
}

// Run a callback on another thread and verify that it triggers SIGABRT.
DART_EXPORT int TestCallbackWrongThread(void (*fn)()) {
  return TestCallbackOtherThreadHelper(&TestCallbackOnThreadOutsideIsolate, fn);
}

// Verify that we get SIGABRT when invoking a native callback outside an
// isolate.
DART_EXPORT int TestCallbackOutsideIsolate(void (*fn)()) {
  Dart_Isolate current = Dart_CurrentIsolate();

  Dart_ExitIsolate();
  CallbackTestData data = {1, fn};
  TestCallbackOnThreadOutsideIsolate(&data);
  Dart_EnterIsolate(current);

  return data.success;
}

DART_EXPORT int TestCallbackWrongIsolate(void (*fn)()) {
  return ExpectAbort(fn);
}

#endif  // defined(TARGET_OS_LINUX)

}  // namespace dart
