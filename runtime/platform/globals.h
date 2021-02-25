// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_GLOBALS_H_
#define RUNTIME_PLATFORM_GLOBALS_H_

#if __cplusplus >= 201703L            // C++17
#define FALL_THROUGH [[fallthrough]]  // NOLINT
#elif defined(__GNUC__) && __GNUC__ >= 7
#define FALL_THROUGH __attribute__((fallthrough));
#elif defined(__clang__)
#define FALL_THROUGH [[clang::fallthrough]]  // NOLINT
#else
#define FALL_THROUGH ((void)0)
#endif

#if defined(GOOGLE3)
// google3 builds use NDEBUG to indicate non-debug builds which is different
// from the way the Dart project expects it: DEBUG indicating a debug build.
#if !defined(NDEBUG) && !defined(DEBUG)
#define DEBUG
#endif  // !NDEBUG && !DEBUG
#endif  // GOOGLE3

// __STDC_FORMAT_MACROS has to be defined before including <inttypes.h> to
// enable platform independent printf format specifiers.
#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif

#if defined(_WIN32)
// Cut down on the amount of stuff that gets included via windows.h.
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif

#if !defined(NOMINMAX)
#define NOMINMAX
#endif

#if !defined(NOKERNEL)
#define NOKERNEL
#endif

#if !defined(NOSERVICE)
#define NOSERVICE
#endif

#if !defined(NOSOUND)
#define NOSOUND
#endif

#if !defined(NOMCX)
#define NOMCX
#endif

#if !defined(UNICODE)
#define _UNICODE
#define UNICODE
#endif

#include <Rpc.h>
#include <VersionHelpers.h>
#include <intrin.h>
#include <shellapi.h>
#include <windows.h>
#include <winsock2.h>
#endif  // defined(_WIN32)

#if !defined(_WIN32)
#include <arpa/inet.h>
#include <unistd.h>
#endif  // !defined(_WIN32)

#include <float.h>
#include <inttypes.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#if defined(_WIN32)
#include "platform/floating_point_win.h"
#endif  // defined(_WIN32)

#if !defined(_WIN32)
#include "platform/floating_point.h"
#endif  // !defined(_WIN32)

// Target OS detection.
// for more information on predefined macros:
//   - http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   - with gcc, run: "echo | gcc -E -dM -"
#if defined(__ANDROID__)

// Check for Android first, to determine its difference from Linux.
#define HOST_OS_ANDROID 1

#elif defined(__linux__) || defined(__FreeBSD__)

// Generic Linux.
#define HOST_OS_LINUX 1

#elif defined(__APPLE__)

// Define the flavor of Mac OS we are running on.
#include <TargetConditionals.h>
// TODO(iposva): Rename HOST_OS_MACOS to HOST_OS_MAC to inherit
// the value defined in TargetConditionals.h
#define HOST_OS_MACOS 1
#if TARGET_OS_IPHONE
#define HOST_OS_IOS 1
#endif

#elif defined(_WIN32)

// Windows, both 32- and 64-bit, regardless of the check for _WIN32.
#define HOST_OS_WINDOWS 1

#elif defined(__Fuchsia__)
#define HOST_OS_FUCHSIA

#elif !defined(HOST_OS_FUCHSIA)
#error Automatic target os detection failed.
#endif

#if defined(DEBUG)
#define DEBUG_ONLY(code) code
#else  // defined(DEBUG)
#define DEBUG_ONLY(code)
#endif  // defined(DEBUG)

#if defined(DEBUG)
#define UNLESS_DEBUG(code)
#else  // defined(DEBUG)
#define UNLESS_DEBUG(code) code
#endif  // defined(DEBUG)

namespace dart {

struct simd128_value_t {
  union {
    int32_t int_storage[4];
    float float_storage[4];
    double double_storage[2];
  };
  simd128_value_t& readFrom(const float* v) {
    float_storage[0] = v[0];
    float_storage[1] = v[1];
    float_storage[2] = v[2];
    float_storage[3] = v[3];
    return *this;
  }
  simd128_value_t& readFrom(const int32_t* v) {
    int_storage[0] = v[0];
    int_storage[1] = v[1];
    int_storage[2] = v[2];
    int_storage[3] = v[3];
    return *this;
  }
  simd128_value_t& readFrom(const double* v) {
    double_storage[0] = v[0];
    double_storage[1] = v[1];
    return *this;
  }
  simd128_value_t& readFrom(const simd128_value_t* v) {
    *this = *v;
    return *this;
  }
  void writeTo(float* v) {
    v[0] = float_storage[0];
    v[1] = float_storage[1];
    v[2] = float_storage[2];
    v[3] = float_storage[3];
  }
  void writeTo(int32_t* v) {
    v[0] = int_storage[0];
    v[1] = int_storage[1];
    v[2] = int_storage[2];
    v[3] = int_storage[3];
  }
  void writeTo(double* v) {
    v[0] = double_storage[0];
    v[1] = double_storage[1];
  }
  void writeTo(simd128_value_t* v) { *v = *this; }
};

// Processor architecture detection.  For more info on what's defined, see:
//   http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   http://www.agner.org/optimize/calling_conventions.pdf
//   or with gcc, run: "echo | gcc -E -dM -"
#if defined(_M_X64) || defined(__x86_64__)
#define HOST_ARCH_X64 1
#define ARCH_IS_64_BIT 1
#define kFpuRegisterSize 16
typedef simd128_value_t fpu_register_t;
#elif defined(_M_IX86) || defined(__i386__)
#define HOST_ARCH_IA32 1
#define ARCH_IS_32_BIT 1
#define kFpuRegisterSize 16
typedef simd128_value_t fpu_register_t;
#elif defined(__ARMEL__)
#define HOST_ARCH_ARM 1
#define ARCH_IS_32_BIT 1
#define kFpuRegisterSize 16
// Mark the fact that we have defined simd_value_t.
#define SIMD_VALUE_T_
typedef struct {
  union {
    uint32_t u;
    float f;
  } data_[4];
} simd_value_t;
typedef simd_value_t fpu_register_t;
#define simd_value_safe_load(addr) (*reinterpret_cast<simd_value_t*>(addr))
#define simd_value_safe_store(addr, value)                                     \
  do {                                                                         \
    reinterpret_cast<simd_value_t*>(addr)->data_[0] = value.data_[0];          \
    reinterpret_cast<simd_value_t*>(addr)->data_[1] = value.data_[1];          \
    reinterpret_cast<simd_value_t*>(addr)->data_[2] = value.data_[2];          \
    reinterpret_cast<simd_value_t*>(addr)->data_[3] = value.data_[3];          \
  } while (0)

#elif defined(__aarch64__)
#define HOST_ARCH_ARM64 1
#define ARCH_IS_64_BIT 1
#define kFpuRegisterSize 16
typedef simd128_value_t fpu_register_t;
#else
#error Architecture was not detected as supported by Dart.
#endif

// DART_FORCE_INLINE strongly hints to the compiler that a function should
// be inlined. Your function is not guaranteed to be inlined but this is
// stronger than just using "inline".
// See: http://msdn.microsoft.com/en-us/library/z8y1yy88.aspx for an
// explanation of some the cases when a function can never be inlined.
#ifdef _MSC_VER
#define DART_FORCE_INLINE __forceinline
#elif __GNUC__
#define DART_FORCE_INLINE inline __attribute__((always_inline))
#else
#error Automatic compiler detection failed.
#endif

// DART_NOINLINE tells compiler to never inline a particular function.
#ifdef _MSC_VER
#define DART_NOINLINE __declspec(noinline)
#elif __GNUC__
#define DART_NOINLINE __attribute__((noinline))
#else
#error Automatic compiler detection failed.
#endif

#ifdef _MSC_VER
#elif __GNUC__
#define DART_HAS_COMPUTED_GOTO 1
#else
#error Automatic compiler detection failed.
#endif

// LIKELY/UNLIKELY give the compiler branch preditions that may affect block
// scheduling.
#ifdef __GNUC__
#define LIKELY(cond) __builtin_expect((cond), 1)
#define UNLIKELY(cond) __builtin_expect((cond), 0)
#else
#define LIKELY(cond) cond
#define UNLIKELY(cond) cond
#endif

// DART_UNUSED indicates to the compiler that a variable or typedef is expected
// to be unused and disables the related warning.
#ifdef __GNUC__
#define DART_UNUSED __attribute__((unused))
#else
#define DART_UNUSED
#endif

// DART_USED indicates to the compiler that a global variable or typedef is used
// disables e.g. the gcc warning "unused-variable"
#ifdef __GNUC__
#define DART_USED __attribute__((used))
#else
#define DART_USED
#endif

// DART_NORETURN indicates to the compiler that a function does not return.
// It should be used on functions that unconditionally call functions like
// exit(), which end the program. We use it to avoid compiler warnings in
// callers of DART_NORETURN functions.
#ifdef _MSC_VER
#define DART_NORETURN __declspec(noreturn)
#elif __GNUC__
#define DART_NORETURN __attribute__((noreturn))
#else
#error Automatic compiler detection failed.
#endif

#ifdef _MSC_VER
#define DART_PRETTY_FUNCTION __FUNCSIG__
#elif __GNUC__
#define DART_PRETTY_FUNCTION __PRETTY_FUNCTION__
#else
#error Automatic compiler detection failed.
#endif

#if !defined(TARGET_ARCH_ARM) && !defined(TARGET_ARCH_X64) &&                  \
    !defined(TARGET_ARCH_IA32) && !defined(TARGET_ARCH_ARM64)
// No target architecture specified pick the one matching the host architecture.
#if defined(HOST_ARCH_ARM)
#define TARGET_ARCH_ARM 1
#elif defined(HOST_ARCH_X64)
#define TARGET_ARCH_X64 1
#elif defined(HOST_ARCH_IA32)
#define TARGET_ARCH_IA32 1
#elif defined(HOST_ARCH_ARM64)
#define TARGET_ARCH_ARM64 1
#else
#error Automatic target architecture detection failed.
#endif
#endif

#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
#define TARGET_ARCH_IS_32_BIT 1
#elif defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
#define TARGET_ARCH_IS_64_BIT 1
#else
#error Automatic target architecture detection failed.
#endif

// Verify that host and target architectures match, we cannot
// have a 64 bit Dart VM generating 32 bit code or vice-versa.
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
#if !defined(ARCH_IS_64_BIT) && !defined(FFI_UNIT_TESTS)
#error Mismatched Host/Target architectures.
#endif  // !defined(ARCH_IS_64_BIT) && !defined(FFI_UNIT_TESTS)
#elif defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
#if defined(HOST_ARCH_X64) && defined(TARGET_ARCH_ARM)
// This is simarm_x64, which is the only case where host/target architecture
// mismatch is allowed. Unless, we're running FFI unit tests.
#define IS_SIMARM_X64 1
#elif !defined(ARCH_IS_32_BIT) && !defined(FFI_UNIT_TESTS)
#error Mismatched Host/Target architectures.
#endif  // !defined(ARCH_IS_32_BIT) && !defined(FFI_UNIT_TESTS)
#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)

// Determine whether we will be using the simulator.
#if defined(TARGET_ARCH_IA32)
// No simulator used.
#elif defined(TARGET_ARCH_X64)
// No simulator used.
#elif defined(TARGET_ARCH_ARM)
#if !defined(HOST_ARCH_ARM)
#define TARGET_HOST_MISMATCH 1
#if !defined(IS_SIMARM_X64)
#define USING_SIMULATOR 1
#endif
#endif

#elif defined(TARGET_ARCH_ARM64)
#if !defined(HOST_ARCH_ARM64)
#define USING_SIMULATOR 1
#endif

#else
#error Unknown architecture.
#endif

#if !defined(TARGET_OS_ANDROID) && !defined(TARGET_OS_FUCHSIA) &&              \
    !defined(TARGET_OS_MACOS_IOS) && !defined(TARGET_OS_LINUX) &&              \
    !defined(TARGET_OS_MACOS) && !defined(TARGET_OS_WINDOWS)
// No target OS specified; pick the one matching the host OS.
#if defined(HOST_OS_ANDROID)
#define TARGET_OS_ANDROID 1
#elif defined(HOST_OS_FUCHSIA)
#define TARGET_OS_FUCHSIA 1
#elif defined(HOST_OS_IOS)
#define TARGET_OS_MACOS 1
#define TARGET_OS_MACOS_IOS 1
#elif defined(HOST_OS_LINUX)
#define TARGET_OS_LINUX 1
#elif defined(HOST_OS_MACOS)
#define TARGET_OS_MACOS 1
#elif defined(HOST_OS_WINDOWS)
#define TARGET_OS_WINDOWS 1
#else
#error Automatic target OS detection failed.
#endif
#endif

// Determine whether dual mapping of code pages is supported.
// We test dual mapping on linux x64 and deploy it on fuchsia.
#if !defined(DART_PRECOMPILED_RUNTIME) &&                                      \
    (defined(TARGET_OS_LINUX) && defined(TARGET_ARCH_X64) ||                   \
     defined(TARGET_OS_FUCHSIA))
#define DUAL_MAPPING_SUPPORTED 1
#endif

#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
#define SUPPORT_UNBOXED_INSTANCE_FIELDS
#endif

// Short form printf format specifiers
#define Pd PRIdPTR
#define Pu PRIuPTR
#define Px PRIxPTR
#define PX PRIXPTR
#define Pd32 PRId32
#define Pu32 PRIu32
#define Px32 PRIx32
#define PX32 PRIX32
#define Pd64 PRId64
#define Pu64 PRIu64
#define Px64 PRIx64
#define PX64 PRIX64

// Zero-padded pointer
#if defined(ARCH_IS_32_BIT)
#define Pp "08" PRIxPTR
#else
#define Pp "016" PRIxPTR
#endif

// Suffixes for 64-bit integer literals.
#ifdef _MSC_VER
#define DART_INT64_C(x) x##I64
#define DART_UINT64_C(x) x##UI64
#else
#define DART_INT64_C(x) x##LL
#define DART_UINT64_C(x) x##ULL
#endif

// Replace calls to strtoll with _strtoi64 on Windows.
#ifdef _MSC_VER
#define strtoll _strtoi64
#endif

// Byte sizes.
constexpr int kInt8SizeLog2 = 0;
constexpr int kInt8Size = 1 << kInt8SizeLog2;
static_assert(kInt8Size == sizeof(int8_t), "Mismatched int8 size constant");
constexpr int kInt16SizeLog2 = 1;
constexpr int kInt16Size = 1 << kInt16SizeLog2;
static_assert(kInt16Size == sizeof(int16_t), "Mismatched int16 size constant");
constexpr int kInt32SizeLog2 = 2;
constexpr int kInt32Size = 1 << kInt32SizeLog2;
static_assert(kInt32Size == sizeof(int32_t), "Mismatched int32 size constant");
constexpr int kInt64SizeLog2 = 3;
constexpr int kInt64Size = 1 << kInt64SizeLog2;
static_assert(kInt64Size == sizeof(int64_t), "Mismatched int64 size constant");

constexpr int kDoubleSize = sizeof(double);
constexpr int kFloatSize = sizeof(float);
constexpr int kQuadSize = 4 * kFloatSize;
constexpr int kSimd128Size = sizeof(simd128_value_t);

// Bit sizes.
constexpr int kBitsPerByteLog2 = 3;
constexpr int kBitsPerByte = 1 << kBitsPerByteLog2;
constexpr int kBitsPerInt8 = kInt8Size * kBitsPerByte;
constexpr int kBitsPerInt16 = kInt16Size * kBitsPerByte;
constexpr int kBitsPerInt32 = kInt32Size * kBitsPerByte;
constexpr int kBitsPerInt64 = kInt64Size * kBitsPerByte;

// The following macro works on both 32 and 64-bit platforms.
// Usage: instead of writing 0x1234567890123456ULL
//      write DART_2PART_UINT64_C(0x12345678,90123456);
#define DART_2PART_UINT64_C(a, b)                                              \
  (((static_cast<uint64_t>(a) << kBitsPerInt32) + 0x##b##u))

// Integer constants.
constexpr int8_t kMinInt8 = 0x80;
constexpr int8_t kMaxInt8 = 0x7F;
constexpr uint8_t kMaxUint8 = 0xFF;
constexpr int16_t kMinInt16 = 0x8000;
constexpr int16_t kMaxInt16 = 0x7FFF;
constexpr uint16_t kMaxUint16 = 0xFFFF;
constexpr int32_t kMinInt32 = 0x80000000;
constexpr int32_t kMaxInt32 = 0x7FFFFFFF;
constexpr uint32_t kMaxUint32 = 0xFFFFFFFF;
constexpr int64_t kMinInt64 = DART_INT64_C(0x8000000000000000);
constexpr int64_t kMaxInt64 = DART_INT64_C(0x7FFFFFFFFFFFFFFF);
constexpr uint64_t kMaxUint64 = DART_2PART_UINT64_C(0xFFFFFFFF, FFFFFFFF);

constexpr int kMinInt = INT_MIN;
constexpr int kMaxInt = INT_MAX;
constexpr int kMaxUint = UINT_MAX;

constexpr int64_t kMinInt64RepresentableAsDouble = kMinInt64;
constexpr int64_t kMaxInt64RepresentableAsDouble =
    DART_INT64_C(0x7FFFFFFFFFFFFC00);
constexpr int64_t kSignBitDouble = DART_INT64_C(0x8000000000000000);

// Types for native machine words. Guaranteed to be able to hold pointers and
// integers.
typedef intptr_t word;
typedef uintptr_t uword;

// Byte sizes for native machine words.
#ifdef ARCH_IS_32_BIT
constexpr int kWordSizeLog2 = kInt32SizeLog2;
#else
constexpr int kWordSizeLog2 = kInt64SizeLog2;
#endif
constexpr int kWordSize = 1 << kWordSizeLog2;
static_assert(kWordSize == sizeof(word), "Mismatched word size constant");

// Bit sizes for native machine words.
constexpr int kBitsPerWordLog2 = kWordSizeLog2 + kBitsPerByteLog2;
constexpr int kBitsPerWord = 1 << kBitsPerWordLog2;

// Integer constants for native machine words.
constexpr word kWordMin = static_cast<uword>(1) << (kBitsPerWord - 1);
constexpr word kWordMax = (static_cast<uword>(1) << (kBitsPerWord - 1)) - 1;
constexpr uword kUwordMax = static_cast<uword>(-1);

// Size of a class id assigned to concrete, abstract and top-level classes.
//
// We use a signed integer type here to make it comparable with intptr_t.
typedef int32_t classid_t;

// System-wide named constants.
constexpr intptr_t KBLog2 = 10;
constexpr intptr_t KB = 1 << KBLog2;
constexpr intptr_t MBLog2 = KBLog2 + KBLog2;
constexpr intptr_t MB = 1 << MBLog2;
constexpr intptr_t GBLog2 = MBLog2 + KBLog2;
constexpr intptr_t GB = 1 << GBLog2;

constexpr intptr_t KBInWordsLog2 = KBLog2 - kWordSizeLog2;
constexpr intptr_t KBInWords = 1 << KBInWordsLog2;
constexpr intptr_t MBInWordsLog2 = KBLog2 + KBInWordsLog2;
constexpr intptr_t MBInWords = 1 << MBInWordsLog2;
constexpr intptr_t GBInWordsLog2 = MBLog2 + KBInWordsLog2;
constexpr intptr_t GBInWords = 1 << GBInWordsLog2;

// Helpers to round memory sizes to human readable values.
constexpr intptr_t RoundWordsToKB(intptr_t size_in_words) {
  return (size_in_words + (KBInWords >> 1)) >> KBInWordsLog2;
}
constexpr intptr_t RoundWordsToMB(intptr_t size_in_words) {
  return (size_in_words + (MBInWords >> 1)) >> MBInWordsLog2;
}
constexpr intptr_t RoundWordsToGB(intptr_t size_in_words) {
  return (size_in_words + (GBInWords >> 1)) >> GBInWordsLog2;
}

constexpr intptr_t kIntptrOne = 1;
constexpr intptr_t kIntptrMin = (kIntptrOne << (kBitsPerWord - 1));
constexpr intptr_t kIntptrMax = ~kIntptrMin;

// Time constants.
constexpr int kMillisecondsPerSecond = 1000;
constexpr int kMicrosecondsPerMillisecond = 1000;
constexpr int kMicrosecondsPerSecond =
    (kMicrosecondsPerMillisecond * kMillisecondsPerSecond);
constexpr int kNanosecondsPerMicrosecond = 1000;
constexpr int kNanosecondsPerMillisecond =
    (kNanosecondsPerMicrosecond * kMicrosecondsPerMillisecond);
constexpr int kNanosecondsPerSecond =
    (kNanosecondsPerMicrosecond * kMicrosecondsPerSecond);

// Helpers to scale micro second times to human understandable values.
constexpr double MicrosecondsToSeconds(int64_t micros) {
  return static_cast<double>(micros) / kMicrosecondsPerSecond;
}
constexpr double MicrosecondsToMilliseconds(int64_t micros) {
  return static_cast<double>(micros) / kMicrosecondsPerMillisecond;
}

// A macro to disallow the copy constructor and operator= functions.
// This should be used in the private: declarations for a class.
#if !defined(DISALLOW_COPY_AND_ASSIGN)
#define DISALLOW_COPY_AND_ASSIGN(TypeName)                                     \
 private:                                                                      \
  TypeName(const TypeName&) = delete;                                          \
  void operator=(const TypeName&) = delete
#endif  // !defined(DISALLOW_COPY_AND_ASSIGN)

// A macro to disallow all the implicit constructors, namely the default
// constructor, copy constructor and operator= functions. This should be
// used in the private: declarations for a class that wants to prevent
// anyone from instantiating it. This is especially useful for classes
// containing only static methods.
#if !defined(DISALLOW_IMPLICIT_CONSTRUCTORS)
#define DISALLOW_IMPLICIT_CONSTRUCTORS(TypeName)                               \
 private:                                                                      \
  TypeName() = delete;                                                         \
  DISALLOW_COPY_AND_ASSIGN(TypeName)
#endif  // !defined(DISALLOW_IMPLICIT_CONSTRUCTORS)

// Macro to disallow allocation in the C++ heap. This should be used
// in the private section for a class. Don't use UNREACHABLE here to
// avoid circular dependencies between platform/globals.h and
// platform/assert.h.
#if !defined(DISALLOW_ALLOCATION)
#define DISALLOW_ALLOCATION()                                                  \
 public:                                                                       \
  void operator delete(void* pointer) {                                        \
    fprintf(stderr, "unreachable code\n");                                     \
    abort();                                                                   \
  }                                                                            \
                                                                               \
 private:                                                                      \
  void* operator new(size_t size);
#endif  // !defined(DISALLOW_ALLOCATION)

// The USE(x) template is used to silence C++ compiler warnings issued
// for unused variables.
template <typename T>
static inline void USE(T&&) {}

// The type-based aliasing rule allows the compiler to assume that
// pointers of different types (for some definition of different)
// never alias each other. Thus the following code does not work:
//
// float f = foo();
// int fbits = *(int*)(&f);
//
// The compiler 'knows' that the int pointer can't refer to f since
// the types don't match, so the compiler may cache f in a register,
// leaving random data in fbits.  Using C++ style casts makes no
// difference, however a pointer to char data is assumed to alias any
// other pointer. This is the 'memcpy exception'.
//
// The bit_cast function uses the memcpy exception to move the bits
// from a variable of one type to a variable of another type. Of
// course the end result is likely to be implementation dependent.
// Most compilers (gcc-4.2 and MSVC 2005) will completely optimize
// bit_cast away.
//
// There is an additional use for bit_cast. Recent gccs will warn when
// they see casts that may result in breakage due to the type-based
// aliasing rule. If you have checked that there is no breakage you
// can use bit_cast to cast one pointer type to another. This confuses
// gcc enough that it can no longer see that you have cast one pointer
// type to another thus avoiding the warning.
template <class D, class S>
inline D bit_cast(const S& source) {
  static_assert(sizeof(D) == sizeof(S),
                "Source and destination must have the same size");

  D destination;
  // This use of memcpy is safe: source and destination cannot overlap.
  memcpy(&destination, &source, sizeof(destination));
  return destination;
}

// Similar to bit_cast, but allows copying from types of unrelated
// sizes. This method was introduced to enable the strict aliasing
// optimizations of GCC 4.4. Basically, GCC mindlessly relies on
// obscure details in the C++ standard that make reinterpret_cast
// virtually useless.
template <class D, class S>
inline D bit_copy(const S& source) {
  D destination;
  // This use of memcpy is safe: source and destination cannot overlap.
  memcpy(&destination, reinterpret_cast<const void*>(&source),
         sizeof(destination));
  return destination;
}

// On Windows the reentrent version of strtok is called
// strtok_s. Unify on the posix name strtok_r.
#if defined(HOST_OS_WINDOWS)
#define snprintf _sprintf_p
#define strtok_r strtok_s
#endif

#if !defined(HOST_OS_WINDOWS)
#if defined(TEMP_FAILURE_RETRY)
// TEMP_FAILURE_RETRY is defined in unistd.h on some platforms. We should
// not use that version, but instead the one in signal_blocker.h, to ensure
// we disable signal interrupts.
#undef TEMP_FAILURE_RETRY
#endif  // defined(TEMP_FAILURE_RETRY)
#endif  // !defined(HOST_OS_WINDOWS)

#if __GNUC__
// Tell the compiler to do printf format string checking if the
// compiler supports it; see the 'format' attribute in
// <http://gcc.gnu.org/onlinedocs/gcc-4.3.0/gcc/Function-Attributes.html>.
//
// N.B.: As the GCC manual states, "[s]ince non-static C++ methods
// have an implicit 'this' argument, the arguments of such methods
// should be counted from two, not one."
#define PRINTF_ATTRIBUTE(string_index, first_to_check)                         \
  __attribute__((__format__(__printf__, string_index, first_to_check)))
#else
#define PRINTF_ATTRIBUTE(string_index, first_to_check)
#endif

#if defined(_WIN32)
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
#endif

#ifndef PATH_MAX
// Most platforms use PATH_MAX, but in Windows it's called MAX_PATH.
#define PATH_MAX MAX_PATH
#endif

// Undefine math.h definition which clashes with our condition names.
#undef OVERFLOW

}  // namespace dart

#endif  // RUNTIME_PLATFORM_GLOBALS_H_
