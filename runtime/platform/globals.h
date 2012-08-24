// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_GLOBALS_H_
#define PLATFORM_GLOBALS_H_

// __STDC_FORMAT_MACROS has to be defined before including <inttypes.h> to
// enable platform independent printf format specifiers.
#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif

#if defined(_WIN32)
// Cut down on the amount of stuff that gets included via windows.h.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#define NOKERNEL
#define NOUSER
#define NOSERVICE
#define NOSOUND
#define NOMCX

#include <windows.h>
#include <winsock2.h>
#include <Rpc.h>
#endif

#if !defined(_WIN32)
#include <arpa/inet.h>
#include <inttypes.h>
#include <stdint.h>
#include <unistd.h>
#endif

#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#if defined(_WIN32)
#include "platform/c99_support_win.h"
#include "platform/inttypes_support_win.h"
#endif

// Target OS detection.
// for more information on predefined macros:
//   - http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   - with gcc, run: "echo | gcc -E -dM -"
#if defined(__ANDROID__)
#define TARGET_OS_ANDROID
#elif defined(__linux__) || defined(__FreeBSD__)
#define TARGET_OS_LINUX 1
#elif defined(__APPLE__)
#define TARGET_OS_MACOS 1
#elif defined(_WIN32)
#define TARGET_OS_WINDOWS 1
#else
#error Automatic target os detection failed.
#endif

// Processor architecture detection.  For more info on what's defined, see:
//   http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   http://www.agner.org/optimize/calling_conventions.pdf
//   or with gcc, run: "echo | gcc -E -dM -"
#if defined(_M_X64) || defined(__x86_64__)
#define HOST_ARCH_X64 1
#define ARCH_IS_64_BIT 1
#elif defined(_M_IX86) || defined(__i386__)
#define HOST_ARCH_IA32 1
#define ARCH_IS_32_BIT 1
#elif defined(__ARMEL__)
#define HOST_ARCH_ARM 1
#define ARCH_IS_32_BIT 1
#else
#error Architecture was not detected as supported by Dart.
#endif

#if !defined(TARGET_ARCH_ARM)
#if !defined(TARGET_ARCH_X64)
#if !defined(TARGET_ARCH_IA32)
// No target architecture specified pick the one matching the host architecture.
#if defined(HOST_ARCH_ARM)
#define TARGET_ARCH_ARM 1
#elif defined(HOST_ARCH_X64)
#define TARGET_ARCH_X64 1
#elif defined(HOST_ARCH_IA32)
#define TARGET_ARCH_IA32 1
#else
#error Automatic target architecture detection failed.
#endif
#endif
#endif
#endif

// Verify that host and target architectures match, we cannot
// have a 64 bit Dart VM generating 32 bit code or vice-versa.
#if defined(TARGET_ARCH_X64)
#if !defined(ARCH_IS_64_BIT)
#error Mismatched Host/Target architectures.
#endif
#elif defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
#if !defined(ARCH_IS_32_BIT)
#error Mismatched Host/Target architectures.
#endif
#endif


// Printf format specifiers for intptr_t on Windows.
#if defined(TARGET_OS_WINDOWS)
#if defined(ARCH_IS_32_BIT)
#define DART_PRINTF_PTR_PREFIX ""
#else
#define DART_PRINTF_PTR_PREFIX "ll"
#endif

#if !defined(PRIdPTR)
#define PRIdPTR DART_PRINTF_PTR_PREFIX "d"
#endif

#if !defined(PRIxPTR)
#define PRIxPTR DART_PRINTF_PTR_PREFIX "x"
#endif

#endif  // defined(TARGET_OS_WINDOWS)


// Suffixes for 64-bit integer literals.
#ifdef _MSC_VER
#define DART_INT64_C(x) x##I64
#define DART_UINT64_C(x) x##UI64
#else
#define DART_INT64_C(x) x##LL
#define DART_UINT64_C(x) x##ULL
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

// Types for native machine words. Guaranteed to be able to hold pointers and
// integers.
typedef intptr_t word;
typedef uintptr_t uword;

// Byte sizes.
const int kWordSize = sizeof(word);
const int kDoubleSize = sizeof(double);  // NOLINT
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
const int kBitsPerWord = kWordSize * kBitsPerByte;

// System-wide named constants.
const int KB = 1024;
const int MB = KB * KB;
const int GB = KB * KB * KB;
const intptr_t kIntptrOne = 1;
const intptr_t kIntptrMin = (kIntptrOne << (kBitsPerWord - 1));
const intptr_t kIntptrMax = ~kIntptrMin;

// Time constants.
const int kMillisecondsPerSecond = 1000;
const int kMicrosecondsPerMillisecond = 1000;
const int kMicrosecondsPerSecond = (kMicrosecondsPerMillisecond *
                                    kMillisecondsPerSecond);
const int kNanosecondsPerMicrosecond = 1000;
const int kNanosecondsPerMillisecond = (kNanosecondsPerMicrosecond *
                                        kMicrosecondsPerMillisecond);
const int kNanosecondsPerSecond = (kNanosecondsPerMicrosecond *
                                   kMicrosecondsPerSecond);

// A macro to disallow the copy constructor and operator= functions.
// This should be used in the private: declarations for a class.
#define DISALLOW_COPY_AND_ASSIGN(TypeName)                                     \
private:                                                                       \
  TypeName(const TypeName&);                                                   \
  void operator=(const TypeName&)


// A macro to disallow all the implicit constructors, namely the default
// constructor, copy constructor and operator= functions. This should be
// used in the private: declarations for a class that wants to prevent
// anyone from instantiating it. This is especially useful for classes
// containing only static methods.
#define DISALLOW_IMPLICIT_CONSTRUCTORS(TypeName)                               \
private:                                                                       \
  TypeName();                                                                  \
  DISALLOW_COPY_AND_ASSIGN(TypeName)


// Macro to disallow allocation in the C++ heap. This should be used
// in the private section for a class. Don't use UNREACHABLE here to
// avoid circular dependencies between platform/globals.h and
// platform/assert.h.
#define DISALLOW_ALLOCATION()                                                  \
public:                                                                        \
  void operator delete(void* pointer) {                                        \
    fprintf(stderr, "unreachable code\n");                                     \
    abort();                                                                   \
  }                                                                            \
private:                                                                       \
  void* operator new(size_t size);


// The USE(x) template is used to silence C++ compiler warnings issued
// for unused variables.
template <typename T>
static inline void USE(T) { }


// Use implicit_cast as a safe version of static_cast or const_cast
// for upcasting in the type hierarchy (i.e. casting a pointer to Foo
// to a pointer to SuperclassOfFoo or casting a pointer to Foo to
// a const pointer to Foo).
// When you use implicit_cast, the compiler checks that the cast is safe.
// Such explicit implicit_casts are necessary in surprisingly many
// situations where C++ demands an exact type match instead of an
// argument type convertable to a target type.
//
// The From type can be inferred, so the preferred syntax for using
// implicit_cast is the same as for static_cast etc.:
//
//   implicit_cast<ToType>(expr)
//
// implicit_cast would have been part of the C++ standard library,
// but the proposal was submitted too late.  It will probably make
// its way into the language in the future.
template<typename To, typename From>
inline To implicit_cast(From const &f) {
  return f;
}


// Use like this: down_cast<T*>(foo);
template<typename To, typename From>  // use like this: down_cast<T*>(foo);
inline To down_cast(From* f) {  // so we only accept pointers
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
  typedef char VerifySizesAreEqual[sizeof(D) == sizeof(S) ? 1 : -1];

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
template<class D, class S>
inline D bit_copy(const S& source) {
  D destination;
  // This use of memcpy is safe: source and destination cannot overlap.
  memcpy(&destination,
         reinterpret_cast<const void*>(&source),
         sizeof(destination));
  return destination;
}


// A macro to ensure that memcpy cannot be called. memcpy does not handle
// overlapping memory regions. Even though this is well documented it seems
// to be used in error quite often. To avoid problems we disallow the direct
// use of memcpy here.
//
// On Android and Windows the basic libraries use memcpy and therefore
// compilation will fail if memcpy is overwritten even if user code does not
// use memcpy.
#if defined(memcpy)
#undef memcpy
#endif
#if !( defined(TARGET_OS_ANDROID) || defined(TARGET_OS_WINDOWS) )
#define memcpy "Please use memmove instead of memcpy."
#endif


// On Windows the reentrent version of strtok is called
// strtok_s. Unify on the posix name strtok_r.
#if defined(TARGET_OS_WINDOWS)
#define snprintf _snprintf
#define strtok_r strtok_s
#endif

#if !defined(TARGET_OS_WINDOWS) && !defined(TEMP_FAILURE_RETRY)
// TEMP_FAILURE_RETRY is defined in unistd.h on some platforms. The
// definition below is copied from Linux and adapted to avoid lint
// errors (type long int changed to int64_t and do/while split on
// separate lines with body in {}s).
# define TEMP_FAILURE_RETRY(expression)                                        \
    ({ int64_t __result;                                                       \
       do {                                                                    \
         __result = (int64_t) (expression);                                    \
       } while (__result == -1L && errno == EINTR);                            \
       __result; })
#endif

#endif  // PLATFORM_GLOBALS_H_
