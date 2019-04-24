// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains test functions for the dart:ffi test cases.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>

#include "platform/assert.h"
#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)
#include <psapi.h>
#else
#include <unistd.h>
#endif

#include <iostream>
#include <limits>

#include "include/dart_api.h"

namespace dart {

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
// Used for testing calling conventions. With so many doubles we are using all
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

struct VeryLargeStruct {
  int8_t a;
  int16_t b;
  int32_t c;
  int64_t d;
  uint8_t e;
  uint16_t f;
  uint32_t g;
  uint64_t h;
  intptr_t i;
  float j;
  double k;
  VeryLargeStruct* parent;
  intptr_t numChildren;
  VeryLargeStruct* children;
  int8_t smallLastField;
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

// Functions for stress-testing GC by returning values that require boxing.

DART_EXPORT int64_t MinInt64() {
  return 0x8000000000000000;
}

DART_EXPORT int64_t MinInt32() {
  return 0x80000000;
}

DART_EXPORT double SmallDouble() {
  return 0x80000000 * -1.0;
}

// Requires boxing on 32-bit and 64-bit systems, even if the top 32-bits are
// truncated.
DART_EXPORT void* LargePointer() {
  uint64_t origin = 0x8100000082000000;
  return reinterpret_cast<void*>(origin);
}

// Allocates 'count'-many Mint boxes, to stress-test GC during an FFI call.
DART_EXPORT void AllocateMints(uint64_t count) {
  Dart_EnterScope();
  for (uint64_t i = 0; i < count; ++i) {
    Dart_NewInteger(0x8000000000000001);
  }
  Dart_ExitScope();
}

// Calls a Dart function to allocate 'count' objects.
// Used for stress-testing GC when re-entering the API.
DART_EXPORT void AllocateThroughDart(uint64_t count) {
  Dart_EnterScope();
  Dart_Handle root = Dart_RootLibrary();
  Dart_Handle arguments[1] = {Dart_NewIntegerFromUint64(count)};
  Dart_Handle result = Dart_Invoke(
      root, Dart_NewStringFromCString("testAllocationsInDartHelper"), 1,
      arguments);
  const char* error;
  if (Dart_IsError(result)) {
    Dart_StringToCString(Dart_ToString(result), &error);
    fprintf(stderr, "Could not call 'testAllocationsInDartHelper': %s\n",
            error);
    Dart_DumpNativeStackTrace(nullptr);
    Dart_PrepareToAbort();
    abort();
  }
  Dart_ExitScope();
}

#if !defined(_WIN32)
DART_EXPORT int RedirectStderr() {
  char filename[256];
  snprintf(filename, sizeof(filename), "/tmp/captured_stderr_%d", getpid());
  FILE* f = freopen(filename, "w", stderr);
  ASSERT(f);
  printf("Got file %s\n", filename);
  return getpid();
}
#endif

}  // namespace dart
