// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_UTILS_H_
#define PLATFORM_UTILS_H_

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

class Utils {
 public:
  template<typename T>
  static inline T Minimum(T x, T y) {
    return x < y ? x : y;
  }

  template<typename T>
  static inline T Maximum(T x, T y) {
    return x > y ? x : y;
  }

  template<typename T>
  static inline T Abs(T x) {
    if (x < 0) return -x;
    return x;
  }

  template<typename T>
  static inline bool IsPowerOfTwo(T x) {
    return ((x & (x - 1)) == 0) && (x != 0);
  }

  template<typename T>
  static inline int ShiftForPowerOfTwo(T x) {
    ASSERT(IsPowerOfTwo(x));
    int num_shifts = 0;
    while (x > 1) {
      num_shifts++;
      x = x >> 1;
    }
    return num_shifts;
  }

  template<typename T>
  static inline bool IsAligned(T x, intptr_t n) {
    ASSERT(IsPowerOfTwo(n));
    return (x & (n - 1)) == 0;
  }

  template<typename T>
  static inline bool IsAligned(T* x, intptr_t n) {
    return IsAligned(reinterpret_cast<uword>(x), n);
  }

  template<typename T>
  static inline T RoundDown(T x, intptr_t n) {
    ASSERT(IsPowerOfTwo(n));
    return (x & -n);
  }

  template<typename T>
  static inline T* RoundDown(T* x, intptr_t n) {
    return reinterpret_cast<T*>(RoundDown(reinterpret_cast<uword>(x), n));
  }

  template<typename T>
  static inline T RoundUp(T x, intptr_t n) {
    return RoundDown(x + n - 1, n);
  }

  template<typename T>
  static inline T* RoundUp(T* x, intptr_t n) {
    return reinterpret_cast<T*>(RoundUp(reinterpret_cast<uword>(x), n));
  }

  static uintptr_t RoundUpToPowerOfTwo(uintptr_t x);
  static int CountOneBits(uint32_t x);

  static int HighestBit(int64_t v);

  static int CountTrailingZeros(uword x);

  // Computes a hash value for the given string.
  static uint32_t StringHash(const char* data, int length);

  // Computes a hash value for the given word.
  static uint32_t WordHash(word key);

  // Check whether an N-bit two's-complement representation can hold value.
  template<typename T>
  static inline bool IsInt(int N, T value) {
    ASSERT((0 < N) &&
           (static_cast<unsigned int>(N) < (kBitsPerByte * sizeof(value))));
    T limit = static_cast<T>(1) << (N - 1);
    return (-limit <= value) && (value < limit);
  }

  template<typename T>
  static inline bool IsUint(int N, T value) {
    ASSERT((0 < N) &&
           (static_cast<unsigned int>(N) < (kBitsPerByte * sizeof(value))));
    T limit = static_cast<T>(1) << N;
    return (0 <= value) && (value < limit);
  }

  // Check whether the magnitude of value fits in N bits, i.e., whether an
  // (N+1)-bit sign-magnitude representation can hold value.
  template<typename T>
  static inline bool IsAbsoluteUint(int N, T value) {
    ASSERT((0 < N) &&
           (static_cast<unsigned int>(N) < (kBitsPerByte * sizeof(value))));
    if (value < 0) value = -value;
    return IsUint(N, value);
  }

  static inline int32_t Low16Bits(int32_t value) {
    return static_cast<int32_t>(value & 0xffff);
  }

  static inline int32_t High16Bits(int32_t value) {
    return static_cast<int32_t>(value >> 16);
  }

  static inline int32_t Low32Bits(int64_t value) {
    return static_cast<int32_t>(value);
  }

  static inline int32_t High32Bits(int64_t value) {
    return static_cast<int32_t>(value >> 32);
  }

  static inline int64_t LowHighTo64Bits(uint32_t low, int32_t high) {
    return (static_cast<int64_t>(high) << 32) | (low & 0x0ffffffffLL);
  }

  static bool IsDecimalDigit(char c) {
    return ('0' <= c) && (c <= '9');
  }

  static bool IsHexDigit(char c) {
    return IsDecimalDigit(c)
          || (('A' <= c) && (c <= 'F'))
          || (('a' <= c) && (c <= 'f'));
  }

  static int HexDigitToInt(char c) {
    ASSERT(IsHexDigit(c));
    if (IsDecimalDigit(c)) return c - '0';
    if (('A' <= c) && (c <= 'F')) return 10 + (c - 'A');
    return 10 + (c - 'a');
  }

  static char IntToHexDigit(int i) {
    ASSERT(0 <= i && i < 16);
    if (i < 10) return static_cast<char>('0' + i);
    return static_cast<char>('A' + (i - 10));
  }

  // Perform a range check, checking if
  //    offset + count <= length
  // without the risk of integer overflow.
  static inline bool RangeCheck(intptr_t offset,
                                intptr_t count,
                                intptr_t length) {
    return offset >= 0 &&
           count >= 0 &&
           length >= 0 &&
           count <= (length - offset);
  }

  static inline bool WillAddOverflow(int64_t a, int64_t b) {
    return ((b > 0) && (a > (kMaxInt64 - b))) ||
           ((b < 0) && (a < (kMinInt64 - b)));
  }

  static inline bool WillSubOverflow(int64_t a, int64_t b) {
    return ((b > 0) && (a < (kMinInt64 + b))) ||
           ((b < 0) && (a > (kMaxInt64 + b)));
  }


  // Utility functions for converting values from host endianess to
  // big or little endian values.
  static uint16_t HostToBigEndian16(uint16_t host_value);
  static uint32_t HostToBigEndian32(uint32_t host_value);
  static uint64_t HostToBigEndian64(uint64_t host_value);
  static uint16_t HostToLittleEndian16(uint16_t host_value);
  static uint32_t HostToLittleEndian32(uint32_t host_value);
  static uint64_t HostToLittleEndian64(uint64_t host_value);

  static bool DoublesBitEqual(const double a, const double b) {
    return bit_cast<int64_t, double>(a) == bit_cast<int64_t, double>(b);
  }
};

}  // namespace dart

#if defined(TARGET_OS_ANDROID)
#include "platform/utils_android.h"
#elif defined(TARGET_OS_LINUX)
#include "platform/utils_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "platform/utils_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "platform/utils_win.h"
#else
#error Unknown target os.
#endif

#endif  // PLATFORM_UTILS_H_
