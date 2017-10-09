// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_GLOBALS_H_
#define RUNTIME_PLATFORM_GLOBALS_H_

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

#if !defined(NOUSER)
#define NOUSER
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
#include <shellapi.h>
#include <windows.h>
#include <winsock2.h>
#endif  // defined(_WIN32)

#if !defined(_WIN32)
#include <arpa/inet.h>
#include <inttypes.h>
#include <stdint.h>
#include <unistd.h>
#endif  // !defined(_WIN32)

#include <float.h>
#include <limits.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#if defined(_WIN32)
#include "platform/c99_support_win.h"
#include "platform/floating_point_win.h"
#include "platform/inttypes_support_win.h"
#endif  // defined(_WIN32)

#include "platform/math.h"

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

// Setup product, release or debug build related macros.
#if defined(PRODUCT) && defined(DEBUG)
#error Both PRODUCT and DEBUG defined.
#endif  // defined(PRODUCT) && defined(DEBUG)

#if defined(PRODUCT)
#define NOT_IN_PRODUCT(code)
#else  // defined(PRODUCT)
#define NOT_IN_PRODUCT(code) code
#endif  // defined(PRODUCT)

#if defined(DEBUG)
#define DEBUG_ONLY(code) code
#else  // defined(DEBUG)
#define DEBUG_ONLY(code)
#endif  // defined(DEBUG)

#if defined(DART_PRECOMPILED_RUNTIME) && defined(DART_PRECOMPILER)
#error DART_PRECOMPILED_RUNTIME and DART_PRECOMPILER are mutually exclusive
#endif  // defined(DART_PRECOMPILED_RUNTIME) && defined(DART_PRECOMPILER)

#if defined(DART_PRECOMPILED_RUNTIME) && defined(DART_NOSNAPSHOT)
#error DART_PRECOMPILED_RUNTIME and DART_NOSNAPSHOT are mutually exclusive
#endif  // defined(DART_PRECOMPILED_RUNTIME) && defined(DART_NOSNAPSHOT)

#if defined(DART_PRECOMPILED_RUNTIME)
#define NOT_IN_PRECOMPILED(code)
#else
#define NOT_IN_PRECOMPILED(code) code
#endif  // defined(DART_PRECOMPILED_RUNTIME)

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
    !defined(TARGET_ARCH_IA32) && !defined(TARGET_ARCH_ARM64) &&               \
    !defined(TARGET_ARCH_DBC)
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

// Verify that host and target architectures match, we cannot
// have a 64 bit Dart VM generating 32 bit code or vice-versa.
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
#if !defined(ARCH_IS_64_BIT)
#error Mismatched Host/Target architectures.
#endif
#elif defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
#if !defined(ARCH_IS_32_BIT)
#error Mismatched Host/Target architectures.
#endif
#endif

// Determine whether we will be using the simulator.
#if defined(TARGET_ARCH_IA32)
// No simulator used.
#elif defined(TARGET_ARCH_X64)
// No simulator used.
#elif defined(TARGET_ARCH_ARM)
#if !defined(HOST_ARCH_ARM)
#define USING_SIMULATOR 1
#endif

#elif defined(TARGET_ARCH_ARM64)
#if !defined(HOST_ARCH_ARM64)
#define USING_SIMULATOR 1
#endif

#elif defined(TARGET_ARCH_DBC)
#define USING_SIMULATOR 1

#else
#error Unknown architecture.
#endif

// Disable background threads by default on armv5te. The relevant
// implementations are uniprocessors.
#if !defined(TARGET_ARCH_ARM_5TE)
#define ARCH_IS_MULTI_CORE 1
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

// Short form printf format specifiers
#define Pd PRIdPTR
#define Pu PRIuPTR
#define Px PRIxPTR
#define PX PRIXPTR
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

// The following macro works on both 32 and 64-bit platforms.
// Usage: instead of writing 0x1234567890123456ULL
//      write DART_2PART_UINT64_C(0x12345678,90123456);
#define DART_2PART_UINT64_C(a, b)                                              \
  (((static_cast<uint64_t>(a) << 32) + 0x##b##u))

// Integer constants.
const int32_t kMinInt32 = 0x80000000;
const int32_t kMaxInt32 = 0x7FFFFFFF;
const uint32_t kMaxUint32 = 0xFFFFFFFF;
const int64_t kMinInt64 = DART_INT64_C(0x8000000000000000);
const int64_t kMaxInt64 = DART_INT64_C(0x7FFFFFFFFFFFFFFF);
const uint64_t kMaxUint64 = DART_2PART_UINT64_C(0xFFFFFFFF, FFFFFFFF);
const int64_t kSignBitDouble = DART_INT64_C(0x8000000000000000);

// Types for native machine words. Guaranteed to be able to hold pointers and
// integers.
typedef intptr_t word;
typedef uintptr_t uword;

// Size of a class id.
typedef uint16_t classid_t;

// Byte sizes.
const int kWordSize = sizeof(word);
const int kDoubleSize = sizeof(double);  // NOLINT
const int kFloatSize = sizeof(float);    // NOLINT
const int kQuadSize = 4 * kFloatSize;
const int kSimd128Size = sizeof(simd128_value_t);  // NOLINT
const int kInt64Size = sizeof(int64_t);            // NOLINT
const int kInt32Size = sizeof(int32_t);            // NOLINT
const int kInt16Size = sizeof(int16_t);            // NOLINT
#ifdef ARCH_IS_32_BIT
const int kWordSizeLog2 = 2;
const uword kUwordMax = kMaxUint32;
#else
const int kWordSizeLog2 = 3;
const uword kUwordMax = kMaxUint64;
#endif

// Bit sizes.
const int kBitsPerByte = 8;
const int kBitsPerByteLog2 = 3;
const int kBitsPerInt32 = kInt32Size * kBitsPerByte;
const int kBitsPerInt64 = kInt64Size * kBitsPerByte;
const int kBitsPerWord = kWordSize * kBitsPerByte;
const int kBitsPerWordLog2 = kWordSizeLog2 + kBitsPerByteLog2;

// System-wide named constants.
const intptr_t KB = 1024;
const intptr_t KBLog2 = 10;
const intptr_t MB = KB * KB;
const intptr_t MBLog2 = KBLog2 + KBLog2;
const intptr_t GB = MB * KB;
const intptr_t GBLog2 = MBLog2 + KBLog2;

const intptr_t KBInWords = KB >> kWordSizeLog2;
const intptr_t KBInWordsLog2 = KBLog2 - kWordSizeLog2;
const intptr_t MBInWords = KB * KBInWords;
const intptr_t MBInWordsLog2 = KBLog2 + KBInWordsLog2;
const intptr_t GBInWords = MB * KBInWords;
const intptr_t GBInWordsLog2 = MBLog2 + KBInWordsLog2;

// Helpers to round memory sizes to human readable values.
inline intptr_t RoundWordsToKB(intptr_t size_in_words) {
  return (size_in_words + (KBInWords >> 1)) >> KBInWordsLog2;
}
inline intptr_t RoundWordsToMB(intptr_t size_in_words) {
  return (size_in_words + (MBInWords >> 1)) >> MBInWordsLog2;
}
inline intptr_t RoundWordsToGB(intptr_t size_in_words) {
  return (size_in_words + (GBInWords >> 1)) >> GBInWordsLog2;
}

const intptr_t kIntptrOne = 1;
const intptr_t kIntptrMin = (kIntptrOne << (kBitsPerWord - 1));
const intptr_t kIntptrMax = ~kIntptrMin;

// Time constants.
const int kMillisecondsPerSecond = 1000;
const int kMicrosecondsPerMillisecond = 1000;
const int kMicrosecondsPerSecond =
    (kMicrosecondsPerMillisecond * kMillisecondsPerSecond);
const int kNanosecondsPerMicrosecond = 1000;
const int kNanosecondsPerMillisecond =
    (kNanosecondsPerMicrosecond * kMicrosecondsPerMillisecond);
const int kNanosecondsPerSecond =
    (kNanosecondsPerMicrosecond * kMicrosecondsPerSecond);

// Helpers to scale micro second times to human understandable values.
inline double MicrosecondsToSeconds(int64_t micros) {
  return static_cast<double>(micros) / kMicrosecondsPerSecond;
}
inline double MicrosecondsToMilliseconds(int64_t micros) {
  return static_cast<double>(micros) / kMicrosecondsPerMillisecond;
}

// A macro to disallow the copy constructor and operator= functions.
// This should be used in the private: declarations for a class.
#if !defined(DISALLOW_COPY_AND_ASSIGN)
#define DISALLOW_COPY_AND_ASSIGN(TypeName)                                     \
 private:                                                                      \
  TypeName(const TypeName&);                                                   \
  void operator=(const TypeName&)
#endif  // !defined(DISALLOW_COPY_AND_ASSIGN)

// A macro to disallow all the implicit constructors, namely the default
// constructor, copy constructor and operator= functions. This should be
// used in the private: declarations for a class that wants to prevent
// anyone from instantiating it. This is especially useful for classes
// containing only static methods.
#if !defined(DISALLOW_IMPLICIT_CONSTRUCTORS)
#define DISALLOW_IMPLICIT_CONSTRUCTORS(TypeName)                               \
 private:                                                                      \
  TypeName();                                                                  \
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
static inline void USE(T) {}

// Use implicit_cast as a safe version of static_cast or const_cast
// for upcasting in the type hierarchy (i.e. casting a pointer to Foo
// to a pointer to SuperclassOfFoo or casting a pointer to Foo to
// a const pointer to Foo).
// When you use implicit_cast, the compiler checks that the cast is safe.
// Such explicit implicit_casts are necessary in surprisingly many
// situations where C++ demands an exact type match instead of an
// argument type convertible to a target type.
//
// The From type can be inferred, so the preferred syntax for using
// implicit_cast is the same as for static_cast etc.:
//
//   implicit_cast<ToType>(expr)
//
// implicit_cast would have been part of the C++ standard library,
// but the proposal was submitted too late.  It will probably make
// its way into the language in the future.
template <typename To, typename From>
inline To implicit_cast(From const& f) {
  return f;
}

// Use like this: down_cast<T*>(foo);
template <typename To, typename From>  // use like this: down_cast<T*>(foo);
inline To down_cast(From* f) {         // so we only accept pointers
  // Ensures that To is a sub-type of From *.  This test is here only
  // for compile-time type checking, and has no overhead in an
  // optimized build at run-time, as it will be optimized away completely.
  if (false) {
    implicit_cast<From, To>(0);
  }
  return static_cast<To>(f);
}

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
  // Compile time assertion: sizeof(D) == sizeof(S). A compile error
  // here means your D and S have different sizes.
  DART_UNUSED typedef char VerifySizesAreEqual[sizeof(D) == sizeof(S) ? 1 : -1];

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

#if defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
// Similar to bit_copy and bit_cast, but does take the type from the argument.
template <typename T>
static inline T ReadUnaligned(const T* ptr) {
  T value;
  memcpy(reinterpret_cast<void*>(&value), reinterpret_cast<const void*>(ptr),
         sizeof(value));
  return value;
}

// Similar to bit_copy and bit_cast, but does take the type from the argument.
template <typename T>
static inline void StoreUnaligned(T* ptr, T value) {
  memcpy(reinterpret_cast<void*>(ptr), reinterpret_cast<const void*>(&value),
         sizeof(value));
}
#else   // !(HOST_ARCH_ARM || HOST_ARCH_ARM64)
// Similar to bit_copy and bit_cast, but does take the type from the argument.
template <typename T>
static inline T ReadUnaligned(const T* ptr) {
  return *ptr;
}

// Similar to bit_copy and bit_cast, but does take the type from the argument.
template <typename T>
static inline void StoreUnaligned(T* ptr, T value) {
  *ptr = value;
}
#endif  // !(HOST_ARCH_ARM || HOST_ARCH_ARM64)

// On Windows the reentrent version of strtok is called
// strtok_s. Unify on the posix name strtok_r.
#if defined(HOST_OS_WINDOWS)
#define snprintf _snprintf
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

// For checking deterministic graph generation, we can store instruction
// tag in the ICData and check it when recreating the flow graph in
// optimizing compiler. Enable it for other modes (product, release) if needed
// for debugging.
#if defined(DEBUG)
#define TAG_IC_DATA
#endif

}  // namespace dart

#endif  // RUNTIME_PLATFORM_GLOBALS_H_
