// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_H_
#define RUNTIME_PLATFORM_UTILS_H_

#include <limits>

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

class Utils {
 public:
  template <typename T>
  static inline T Minimum(T x, T y) {
    return x < y ? x : y;
  }

  template <typename T>
  static inline T Maximum(T x, T y) {
    return x > y ? x : y;
  }

  // Calculates absolute value of a given signed integer.
  // `x` must not be equal to minimum value representable by `T`
  // as its absolute value is out of range.
  template <typename T>
  static inline T Abs(T x) {
    // Note: as a general rule, it is not OK to use STL in Dart VM.
    // However, std::numeric_limits<T>::min() and max() are harmless
    // and worthwhile exception from this rule.
    ASSERT(x != std::numeric_limits<T>::min());
    if (x < 0) return -x;
    return x;
  }

  // Calculates absolute value of a given signed integer with saturation.
  // If `x` equals to minimum value representable by `T`, then
  // absolute value is saturated to the maximum value representable by `T`.
  template <typename T>
  static inline T AbsWithSaturation(T x) {
    if (x < 0) {
      // Note: as a general rule, it is not OK to use STL in Dart VM.
      // However, std::numeric_limits<T>::min() and max() are harmless
      // and worthwhile exception from this rule.
      if (x == std::numeric_limits<T>::min()) {
        return std::numeric_limits<T>::max();
      }
      return -x;
    }
    return x;
  }

  template <typename T>
  static inline bool IsPowerOfTwo(T x) {
    return ((x & (x - 1)) == 0) && (x != 0);
  }

  template <typename T>
  static inline int ShiftForPowerOfTwo(T x) {
    ASSERT(IsPowerOfTwo(x));
    int num_shifts = 0;
    while (x > 1) {
      num_shifts++;
      x = x >> 1;
    }
    return num_shifts;
  }

  template <typename T>
  static inline bool IsAligned(T x, intptr_t n) {
    ASSERT(IsPowerOfTwo(n));
    return (x & (n - 1)) == 0;
  }

  template <typename T>
  static inline bool IsAligned(T* x, intptr_t n) {
    return IsAligned(reinterpret_cast<uword>(x), n);
  }

  template <typename T>
  static inline T RoundDown(T x, intptr_t n) {
    ASSERT(IsPowerOfTwo(n));
    return (x & -n);
  }

  template <typename T>
  static inline T* RoundDown(T* x, intptr_t n) {
    return reinterpret_cast<T*>(RoundDown(reinterpret_cast<uword>(x), n));
  }

  template <typename T>
  static inline T RoundUp(T x, intptr_t n) {
    return RoundDown(x + n - 1, n);
  }

  template <typename T>
  static inline T* RoundUp(T* x, intptr_t n) {
    return reinterpret_cast<T*>(RoundUp(reinterpret_cast<uword>(x), n));
  }

  static uintptr_t RoundUpToPowerOfTwo(uintptr_t x);

  static int CountOneBits32(uint32_t x) {
    // Apparently there are x64 chips without popcount.
#if __GNUC__ && !defined(HOST_ARCH_IA32) && !defined(HOST_ARCH_X64)
    return __builtin_popcount(x);
#else
    // Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
    // figure 5-2, page 66, where the function is called pop.
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0F0F0F0F;
    x = x + (x >> 8);
    x = x + (x >> 16);
    return static_cast<int>(x & 0x0000003F);
#endif
  }

  static int CountOneBits64(uint64_t x) {
    // Apparently there are x64 chips without popcount.
#if __GNUC__ && !defined(HOST_ARCH_IA32) && !defined(HOST_ARCH_X64)
    return __builtin_popcountll(x);
#else
    return CountOneBits32(static_cast<uint32_t>(x)) +
           CountOneBits32(static_cast<uint32_t>(x >> 32));
#endif
  }

  static int CountOneBitsWord(uword x) {
#ifdef ARCH_IS_64_BIT
    return CountOneBits64(x);
#else
    return CountOneBits32(x);
#endif
  }

  static int HighestBit(int64_t v);

  static int BitLength(int64_t value) {
    // Flip bits if negative (-1 becomes 0).
    value ^= value >> (8 * sizeof(value) - 1);
    return (value == 0) ? 0 : (Utils::HighestBit(value) + 1);
  }

  static int CountLeadingZeros(uword x);
  static int CountTrailingZeros(uword x);

  // Computes a hash value for the given string.
  static uint32_t StringHash(const char* data, int length);

  // Computes a hash value for the given word.
  static uint32_t WordHash(intptr_t key);

  // Check whether an N-bit two's-complement representation can hold value.
  template <typename T>
  static inline bool IsInt(int N, T value) {
    ASSERT((0 < N) &&
           (static_cast<unsigned int>(N) < (kBitsPerByte * sizeof(value))));
    T limit = static_cast<T>(1) << (N - 1);
    return (-limit <= value) && (value < limit);
  }

  template <typename T>
  static inline bool IsUint(int N, T value) {
    ASSERT((0 < N) &&
           (static_cast<unsigned int>(N) < (kBitsPerByte * sizeof(value))));
    T limit = static_cast<T>(1) << N;
    return (0 <= value) && (value < limit);
  }

  // Check whether the magnitude of value fits in N bits, i.e., whether an
  // (N+1)-bit sign-magnitude representation can hold value.
  template <typename T>
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

  static bool IsDecimalDigit(char c) { return ('0' <= c) && (c <= '9'); }

  static bool IsHexDigit(char c) {
    return IsDecimalDigit(c) || (('A' <= c) && (c <= 'F')) ||
           (('a' <= c) && (c <= 'f'));
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
    return offset >= 0 && count >= 0 && length >= 0 &&
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

  // Adds two int64_t values with wrapping around
  // (two's complement arithmetic).
  static inline int64_t AddWithWrapAround(int64_t a, int64_t b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    return static_cast<int64_t>(static_cast<uint64_t>(a) +
                                static_cast<uint64_t>(b));
  }

  // Subtracts two int64_t values with wrapping around
  // (two's complement arithmetic).
  static inline int64_t SubWithWrapAround(int64_t a, int64_t b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    return static_cast<int64_t>(static_cast<uint64_t>(a) -
                                static_cast<uint64_t>(b));
  }

  // Multiplies two int64_t values with wrapping around
  // (two's complement arithmetic).
  static inline int64_t MulWithWrapAround(int64_t a, int64_t b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    return static_cast<int64_t>(static_cast<uint64_t>(a) *
                                static_cast<uint64_t>(b));
  }

  // Shifts int64_t value left. Supports any non-negative number of bits and
  // silently discards shifted out bits.
  static inline int64_t ShiftLeftWithTruncation(int64_t a, int64_t b) {
    ASSERT(b >= 0);
    if (b >= kBitsPerInt64) {
      return 0;
    }
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    return static_cast<int64_t>(static_cast<uint64_t>(a) << b);
  }

  // Utility functions for converting values from host endianness to
  // big or little endian values.
  static uint16_t HostToBigEndian16(uint16_t host_value);
  static uint32_t HostToBigEndian32(uint32_t host_value);
  static uint64_t HostToBigEndian64(uint64_t host_value);
  static uint16_t HostToLittleEndian16(uint16_t host_value);
  static uint32_t HostToLittleEndian32(uint32_t host_value);
  static uint64_t HostToLittleEndian64(uint64_t host_value);

  static uint32_t BigEndianToHost32(uint32_t be_value) {
    // Going between Host <-> BE is the same operation for all practical
    // purposes.
    return HostToBigEndian32(be_value);
  }

  static bool DoublesBitEqual(const double a, const double b) {
    return bit_cast<int64_t, double>(a) == bit_cast<int64_t, double>(b);
  }

  // A double-to-integer conversion that avoids undefined behavior.
  // Out of range values and NaNs are converted to minimum value
  // for type T.
  template <typename T>
  static T SafeDoubleToInt(double v) {
    const double min = static_cast<double>(std::numeric_limits<T>::min());
    const double max = static_cast<double>(std::numeric_limits<T>::max());
    return (min <= v && v <= max) ? static_cast<T>(v)
                                  : std::numeric_limits<T>::min();
  }

  // dart2js represents integers as double precision floats, which can
  // represent anything in the range -2^53 ... 2^53.
  static bool IsJavascriptInt(int64_t value) {
    return ((-0x20000000000000LL <= value) && (value <= 0x20000000000000LL));
  }

  // The lowest n bits are 1, the others are 0.
  static uword NBitMask(uint32_t n) {
    ASSERT(n <= kBitsPerWord);
    if (n == kBitsPerWord) {
#if defined(TARGET_ARCH_X64)
      return 0xffffffffffffffffll;
#else
      return 0xffffffff;
#endif
    }
    return (1ll << n) - 1;
  }

  static word SignedNBitMask(uint32_t n) {
    uword mask = NBitMask(n);
    return bit_cast<word>(mask);
  }

  static uword Bit(uint32_t n) {
    ASSERT(n < kBitsPerWord);
    uword bit = 1;
    return bit << n;
  }

  static char* StrError(int err, char* buffer, size_t bufsize);

  // Not all platforms support strndup.
  static char* StrNDup(const char* s, intptr_t n);
  static intptr_t StrNLen(const char* s, intptr_t n);

  // Print formatted output info a buffer.
  //
  // Does not write more than size characters (including the trailing '\0').
  //
  // Returns the number of characters (excluding the trailing '\0')
  // that would been written if the buffer had been big enough.  If
  // the return value is greater or equal than the given size then the
  // output has been truncated.  The return value is never negative.
  //
  // The buffer will always be terminated by a '\0', unless the buffer
  // is of size 0.  The buffer might be NULL if the size is 0.
  //
  // This specification conforms to C99 standard which is implemented
  // by glibc 2.1+ with one exception: the C99 standard allows a
  // negative return value.  We will terminate the vm rather than let
  // that occur.
  static int SNPrint(char* str, size_t size, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  static int VSNPrint(char* str, size_t size, const char* format, va_list args);
};

}  // namespace dart

#if defined(HOST_OS_ANDROID)
#include "platform/utils_android.h"
#elif defined(HOST_OS_FUCHSIA)
#include "platform/utils_fuchsia.h"
#elif defined(HOST_OS_LINUX)
#include "platform/utils_linux.h"
#elif defined(HOST_OS_MACOS)
#include "platform/utils_macos.h"
#elif defined(HOST_OS_WINDOWS)
#include "platform/utils_win.h"
#else
#error Unknown target os.
#endif

#endif  // RUNTIME_PLATFORM_UTILS_H_
