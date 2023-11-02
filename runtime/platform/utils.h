// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UTILS_H_
#define RUNTIME_PLATFORM_UTILS_H_

#include <cstdlib>
#include <limits>
#include <memory>
#include <type_traits>

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
  static constexpr inline T Maximum(T x, T y) {
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
  static constexpr bool IsPowerOfTwo(T x) {
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
  static constexpr bool IsAligned(T x,
                                  uintptr_t alignment,
                                  uintptr_t offset = 0) {
    ASSERT(IsPowerOfTwo(alignment));
    ASSERT(offset < alignment);
    return (x & (alignment - 1)) == offset;
  }

  template <typename T>
  static constexpr bool IsAligned(T* x,
                                  uintptr_t alignment,
                                  uintptr_t offset = 0) {
    return IsAligned(reinterpret_cast<uword>(x), alignment, offset);
  }

  template <typename T>
  static constexpr inline T RoundDown(T x, intptr_t alignment) {
    ASSERT(IsPowerOfTwo(alignment));
    return (x & -alignment);
  }

  template <typename T>
  static inline T* RoundDown(T* x, intptr_t alignment) {
    return reinterpret_cast<T*>(
        RoundDown(reinterpret_cast<uword>(x), alignment));
  }

  template <typename T>
  static constexpr inline T RoundUp(T x,
                                    uintptr_t alignment,
                                    uintptr_t offset = 0) {
    ASSERT(offset < alignment);
    return RoundDown(x + alignment - 1 + offset, alignment) - offset;
  }

  template <typename T>
  static inline T* RoundUp(T* x, uintptr_t alignment, uintptr_t offset = 0) {
    return reinterpret_cast<T*>(
        RoundUp(reinterpret_cast<uword>(x), alignment, offset));
  }

  // Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
  // figure 3-3, page 48, where the function is called clp2.
  static constexpr uintptr_t RoundUpToPowerOfTwo(uintptr_t x) {
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >> 16);
#if defined(ARCH_IS_64_BIT)
    x = x | (x >> 32);
#endif  // defined(ARCH_IS_64_BIT)
    return x + 1;
  }

  static constexpr int CountOneBits64(uint64_t x) {
    // Apparently there are x64 chips without popcount.
#if __GNUC__ && !defined(HOST_ARCH_IA32) && !defined(HOST_ARCH_X64)
    return __builtin_popcountll(x);
#else
    x = x - ((x >> 1) & 0x5555555555555555);
    x = (x & 0x3333333333333333) + ((x >> 2) & 0x3333333333333333);
    x = (((x + (x >> 4)) & 0x0f0f0f0f0f0f0f0f) * 0x0101010101010101) >> 56;
    return x;
#endif
  }

  static constexpr int CountOneBits32(uint32_t x) {
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

  static constexpr int CountOneBitsWord(uword x) {
#ifdef ARCH_IS_64_BIT
    return CountOneBits64(x);
#else
    return CountOneBits32(x);
#endif
  }

  // TODO(koda): Compare to flsll call/intrinsic.
  static constexpr size_t HighestBit(int64_t v) {
    uint64_t x = static_cast<uint64_t>((v > 0) ? v : -v);
    uint64_t t = 0;
    size_t r = 0;
    if ((t = x >> 32) != 0) {
      x = t;
      r += 32;
    }
    if ((t = x >> 16) != 0) {
      x = t;
      r += 16;
    }
    if ((t = x >> 8) != 0) {
      x = t;
      r += 8;
    }
    if ((t = x >> 4) != 0) {
      x = t;
      r += 4;
    }
    if ((t = x >> 2) != 0) {
      x = t;
      r += 2;
    }
    if (x > 1) r += 1;
    return r;
  }

  static constexpr size_t BitLength(int64_t value) {
    // Flip bits if negative (-1 becomes 0).
    value ^= value >> (8 * sizeof(value) - 1);
    return (value == 0) ? 0 : (Utils::HighestBit(value) + 1);
  }

  static int CountLeadingZeros32(uint32_t x) {
#if defined(DART_HOST_OS_WINDOWS)
    unsigned long position;  // NOLINT
    return (_BitScanReverse(&position, x) == 0)
               ? 32
               : 31 - static_cast<int>(position);
#else
    return x == 0 ? 32 : __builtin_clz(x);
#endif
  }
  static int CountLeadingZeros64(uint64_t x) {
#if defined(DART_HOST_OS_WINDOWS)
#if defined(ARCH_IS_32_BIT)
    const uint32_t x_hi = static_cast<uint32_t>(x >> 32);
    if (x_hi != 0) {
      return CountLeadingZeros32(x_hi);
    }
    return 32 + CountLeadingZeros32(static_cast<uint32_t>(x));
#else
    unsigned long position;  // NOLINT
    return (_BitScanReverse64(&position, x) == 0)
               ? 64
               : 63 - static_cast<int>(position);
#endif
#else
    return x == 0 ? 64 : __builtin_clzll(x);
#endif
  }
  static int CountLeadingZerosWord(uword x) {
#ifdef ARCH_IS_64_BIT
    return CountLeadingZeros64(x);
#else
    return CountLeadingZeros32(x);
#endif
  }

  static int CountTrailingZeros32(uint32_t x) {
#if defined(DART_HOST_OS_WINDOWS)
    unsigned long position;  // NOLINT
    return (_BitScanForward(&position, x) == 0) ? 32
                                                : static_cast<int>(position);
#else
    return x == 0 ? 32 : __builtin_ctz(x);
#endif
  }
  static int CountTrailingZeros64(uint64_t x) {
#if defined(DART_HOST_OS_WINDOWS)
#if defined(ARCH_IS_32_BIT)
    const uint32_t x_lo = static_cast<uint32_t>(x);
    if (x_lo != 0) {
      return CountTrailingZeros32(x_lo);
    }
    return 32 + CountTrailingZeros32(static_cast<uint32_t>(x >> 32));
#else
    unsigned long position;  // NOLINT
    return (_BitScanForward64(&position, x) == 0) ? 64
                                                  : static_cast<int>(position);
#endif
#else
    return x == 0 ? 64 : __builtin_ctzll(x);
#endif
  }
  static int CountTrailingZerosWord(uword x) {
#ifdef ARCH_IS_64_BIT
    return CountTrailingZeros64(x);
#else
    return CountTrailingZeros32(x);
#endif
  }

  static uint64_t ReverseBits64(uint64_t x);
  static uint32_t ReverseBits32(uint32_t x);

  static uword ReverseBitsWord(uword x) {
#ifdef ARCH_IS_64_BIT
    return ReverseBits64(x);
#else
    return ReverseBits32(x);
#endif
  }

  // Computes magic numbers to implement DIV or MOD operator.
  static void CalculateMagicAndShiftForDivRem(int64_t divisor,
                                              int64_t* magic,
                                              int64_t* shift);

  // Computes a hash value for the given series of bytes.
  static uint32_t StringHash(const void* data, int length);

  // Computes a hash value for the given word.
  static uint32_t WordHash(intptr_t key);

  // Check whether an N-bit two's-complement representation can hold value.
  template <typename T>
  static inline bool IsInt(intptr_t N, T value) {
    ASSERT(N >= 1);
    constexpr intptr_t value_size_in_bits = kBitsPerByte * sizeof(T);
    if constexpr (std::is_signed<T>::value) {
      if (N >= value_size_in_bits) return true;  // Trivially fits.
      const T limit = static_cast<T>(1) << (N - 1);
      return (-limit <= value) && (value < limit);
    } else {
      if (N > value_size_in_bits) return true;  // Trivially fits.
      const T limit = static_cast<T>(1) << (N - 1);
      return value < limit;
    }
  }

  template <typename T>
  static inline bool IsUint(intptr_t N, T value) {
    ASSERT(N >= 1);
    constexpr intptr_t value_size_in_bits = kBitsPerByte * sizeof(T);
    if constexpr (std::is_signed<T>::value) {
      if (value < 0) return false;  // Not an unsigned value.
      if (N >= value_size_in_bits - 1) {
        return true;  // N can fit the magnitude bits.
      }
    } else {
      if (N >= value_size_in_bits) return true;  // Trivially fits.
    }
    const T limit = (static_cast<T>(1) << N) - 1;
    return value <= limit;
  }

  // Check whether the magnitude of value fits in N bits. This differs from
  // IsInt(N + 1, value) only in that this returns false for the minimum value
  // of a N+1 bit two's complement value.
  //
  // Primarily used for testing whether a two's complement value can be used in
  // a place where the sign is replaced with a marker that says whether the
  // magnitude is added or subtracted, e.g., the U bit (bit 23) in some ARM7
  // instructions.
  template <typename T>
  static inline bool MagnitudeIsUint(intptr_t N, T value) {
    ASSERT(N >= 1);
    if constexpr (std::is_signed<T>::value) {
      using Unsigned = typename std::make_unsigned<T>::type;
      if (value < 0) return IsUint<Unsigned>(N, -value);
    }
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
    return (static_cast<uint64_t>(high) << 32) | (low & 0x0ffffffffLL);
  }

  static inline constexpr bool IsAlphaNumeric(uint32_t c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
           IsDecimalDigit(c);
  }

  static inline constexpr bool IsDecimalDigit(uint32_t c) {
    return ('0' <= c) && (c <= '9');
  }

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
  template <typename T = int64_t>
  static inline T AddWithWrapAround(T a, T b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    using Unsigned = typename std::make_unsigned<T>::type;
    return static_cast<T>(static_cast<Unsigned>(a) + static_cast<Unsigned>(b));
  }

  // Subtracts two int64_t values with wrapping around
  // (two's complement arithmetic).
  template <typename T = int64_t>
  static inline T SubWithWrapAround(T a, T b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    using Unsigned = typename std::make_unsigned<T>::type;
    return static_cast<T>(static_cast<Unsigned>(a) - static_cast<Unsigned>(b));
  }

  // Multiplies two int64_t values with wrapping around
  // (two's complement arithmetic).
  template <typename T = int64_t>
  static inline T MulWithWrapAround(T a, T b) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    using Unsigned = typename std::make_unsigned<T>::type;
    return static_cast<T>(static_cast<Unsigned>(a) * static_cast<Unsigned>(b));
  }

  template <typename T = int64_t>
  static inline T NegWithWrapAround(T a) {
    // Avoid undefined behavior by doing arithmetic in the unsigned type.
    using Unsigned = typename std::make_unsigned<T>::type;
    return static_cast<T>(-static_cast<Unsigned>(a));
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

  template <typename T>
  static inline T RotateLeft(T value, uint8_t rotate) {
    const uint8_t width = sizeof(T) * kBitsPerByte;
    ASSERT(0 <= rotate);
    ASSERT(rotate <= width);
    using Unsigned = typename std::make_unsigned<T>::type;
    return (static_cast<Unsigned>(value) << rotate) |
           (static_cast<T>(value) >> ((width - rotate) & (width - 1)));
  }
  template <typename T>
  static inline T RotateRight(T value, uint8_t rotate) {
    const uint8_t width = sizeof(T) * kBitsPerByte;
    ASSERT(0 <= rotate);
    ASSERT(rotate <= width);
    using Unsigned = typename std::make_unsigned<T>::type;
    return (static_cast<T>(value) >> rotate) |
           (static_cast<Unsigned>(value) << ((width - rotate) & (width - 1)));
  }

#ifdef __GNUC__
  __attribute__((no_sanitize("float-divide-by-zero")))
#endif
  static inline float
  DivideAllowZero(float a, float b) {
    return a / b;
  }
#ifdef __GNUC__
  __attribute__((no_sanitize("float-divide-by-zero")))
#endif
  static inline double
  DivideAllowZero(double a, double b) {
    return a / b;
  }

  // Utility functions for converting values from host endianness to
  // big or little endian values.
  static uint16_t HostToBigEndian16(uint16_t host_value);
  static uint32_t HostToBigEndian32(uint32_t host_value);
  static uint64_t HostToBigEndian64(uint64_t host_value);
  static uint16_t HostToLittleEndian16(uint16_t host_value);
  static uint32_t HostToLittleEndian32(uint32_t host_value);
  static uint64_t HostToLittleEndian64(uint64_t host_value);

  // Going between Host <-> LE/BE is the same operation for all practical
  // purposes.
  static inline uint32_t BigEndianToHost32(uint32_t be_value) {
    return HostToBigEndian32(be_value);
  }
  static inline uint64_t LittleEndianToHost64(uint64_t le_value) {
    return HostToLittleEndian64(le_value);
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
  static bool IsJavaScriptInt(int64_t value) {
    return ((-0x20000000000000LL <= value) && (value <= 0x20000000000000LL));
  }

  // The lowest n bits are 1, the others are 0.
  template <typename T = uword>
  static constexpr T NBitMask(size_t n) {
    using Unsigned = typename std::make_unsigned<T>::type;
    constexpr size_t kBitsPerT = sizeof(T) * kBitsPerByte;
    assert(n <= sizeof(T) * kBitsPerT);
    return static_cast<T>(n == kBitsPerT ? std::numeric_limits<Unsigned>::max()
                                         : (static_cast<Unsigned>(1) << n) - 1);
  }

  template <typename T = uword>
  static constexpr T Bit(size_t n) {
    ASSERT(n < sizeof(T) * kBitsPerByte);
    T bit = 1;
    return bit << n;
  }

  template <typename T>
  static constexpr bool TestBit(T mask, size_t position) {
    ASSERT(position < sizeof(T) * kBitsPerByte);
    return ((mask >> position) & 1) != 0;
  }

  static char* StrError(int err, char* buffer, size_t bufsize);

  // Not all platforms support strndup.
  static char* StrNDup(const char* s, intptr_t n);
  static char* StrDup(const char* s);
  static intptr_t StrNLen(const char* s, intptr_t n);
  static bool StrStartsWith(const char* s, const char* prefix) {
    return strncmp(s, prefix, strlen(prefix)) == 0;
  }

  static int Close(int fildes);
  static size_t Read(int filedes, void* buf, size_t nbyte);
  static int Unlink(const char* path);

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
  // is of size 0.  The buffer might be nullptr if the size is 0.
  //
  // This specification conforms to C99 standard which is implemented
  // by glibc 2.1+ with one exception: the C99 standard allows a
  // negative return value.  We will terminate the vm rather than let
  // that occur.
  static int SNPrint(char* str, size_t size, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  static int VSNPrint(char* str, size_t size, const char* format, va_list args);

  // Allocate a string and print formatted output into a malloc'd buffer.
  static char* SCreate(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
  static char* VSCreate(const char* format, va_list args);

  typedef std::unique_ptr<char, decltype(std::free)*> CStringUniquePtr;

  // Returns str in a unique_ptr with free used as its deleter.
  static CStringUniquePtr CreateCStringUniquePtr(char* str);

  // Load dynamic library from the given |library_path| and return the
  // library handle. |library_path| can be |nullptr| in which case
  // library handle representing the executable is returned.
  // If an error occurs returns |nullptr| and populates
  // |error| (if provided) with an error message (caller must free this message
  // when it is no longer needed).
  static void* LoadDynamicLibrary(const char* library_path,
                                  char** error = nullptr);

  // Resolve the given |symbol| within the library referenced by the
  // given |library_handle|.
  // If an error occurs populates |error| (if provided) with an error message
  // (caller must free this message when it is no longer needed).
  // Note: on some platforms |nullptr| is a valid value for a symbol, so to
  // check if resolution succeeded one must instead provide non-null |error|
  // and then check if it was populated with an error message.
  static void* ResolveSymbolInDynamicLibrary(void* library_handle,
                                             const char* symbol,
                                             char** error = nullptr);

  // Unload the library referenced by the given |library_handle|.
  // If an error occurs returns |nullptr| and populates
  // |error| (if provided) with an error message (caller must free this message
  // when it is no longer needed).
  static void UnloadDynamicLibrary(void* library_handle,
                                   char** error = nullptr);
};

}  // namespace dart

#if defined(DART_HOST_OS_ANDROID)
#include "platform/utils_android.h"
#elif defined(DART_HOST_OS_FUCHSIA)
#include "platform/utils_fuchsia.h"
#elif defined(DART_HOST_OS_LINUX)
#include "platform/utils_linux.h"
#elif defined(DART_HOST_OS_MACOS)
#include "platform/utils_macos.h"
#elif defined(DART_HOST_OS_WINDOWS)
#include "platform/utils_win.h"
#else
#error Unknown target os.
#endif

#endif  // RUNTIME_PLATFORM_UTILS_H_
