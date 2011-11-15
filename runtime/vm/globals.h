// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GLOBALS_H_
#define VM_GLOBALS_H_

// __STDC_FORMAT_MACROS has to be defined to enable platform independent printf.
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

// Undef conflicting defines.
#undef PARITY_EVEN
#undef PARITY_ODD
#undef near
#endif

#if !defined(_WIN32)
#include <inttypes.h>
#include <stdint.h>
#endif

#include <math.h>
#include <openssl/bn.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#if defined(_WIN32)
#include "vm/c99_support_win.h"
#include "vm/inttypes_support_win.h"
#endif

// The following #defines are invalidated.
#undef OVERFLOW  // From math.h conflicts in constants_ia32.h

namespace dart {

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


// Target OS detection.
// for more information on predefined macros:
//   - http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   - with gcc, run: "echo | gcc -E -dM -"
#if defined(__linux__) || defined(__FreeBSD__)
#define TARGET_OS_LINUX 1
#elif defined(__APPLE__)
#define TARGET_OS_MACOS 1
#elif defined(_WIN32)
#define TARGET_OS_WINDOWS 1
#else
#error Automatic target os detection failed.
#endif


// Printf format for intptr_t on Windows.
#if !defined(PRIxPTR) && defined(TARGET_OS_WINDOWS)
#if defined(ARCH_IS_32_BIT)
#define PRIxPTR "x"
#else
#define PRIxPTR "llx"
#endif  // defined(ARCH_IS_32_BIT)
#endif  // !defined(PRIxPTR) && defined(TARGET_OS_WINDOWS)


// The following macro works on both 32 and 64-bit platforms.
// Usage: instead of writing 0x1234567890123456
//      write DART_2PART_UINT64_C(0x12345678,90123456);
#define DART_2PART_UINT64_C(a, b)                                              \
                 (((static_cast<uint64_t>(a) << 32) + 0x##b##u))


// Types for native machine words. Guaranteed to be able to hold pointers and
// integers.
typedef intptr_t word;
typedef uintptr_t uword;

// A type large enough to contain the value of the C++ vtable. This is needed
// to support the handle operations.
typedef uword cpp_vtable;

// Byte sizes.
const int kWordSize = sizeof(word);
#ifdef ARCH_IS_32_BIT
const int kWordSizeLog2 = 2;
#else
const int kWordSizeLog2 = 3;
#endif

// Bit sizes.
const int kBitsPerByte = 8;
const int kBitsPerByteLog2 = 3;
const int kBitsPerWord = kWordSize * kBitsPerByte;

// System-wide named constants.
const int KB = 1024;
const int MB = KB * KB;
const int GB = KB * KB * KB;

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
// in the private section for a class.
#define DISALLOW_ALLOCATION()                                                  \
public:                                                                        \
  void operator delete(void* pointer) { UNREACHABLE(); }                       \
private:                                                                       \
  void* operator new(size_t size);


// The expression ARRAY_SIZE(array) is a compile-time constant of type
// size_t which represents the number of elements of the given
// array. You should only use ARRAY_SIZE on statically allocated
// arrays.
#define ARRAY_SIZE(array)                                       \
  ((sizeof(array) / sizeof(*(array))) /                         \
  static_cast<intptr_t>(!(sizeof(array) % sizeof(*(array)))))


// The expression OFFSET_OF(type, field) computes the byte-offset of
// the specified field relative to the containing type.
//
// The expression OFFSET_OF_RETURNED_VALUE(type, accessor) computes the
// byte-offset of the return value of the accessor to the containing type.
//
// None of these use 0 or NULL, which causes a problem with the compiler
// warnings we have enabled (which is also why 'offsetof' doesn't seem to work).
// The workaround is to use the non-zero value kOffsetOfPtr.
const intptr_t kOffsetOfPtr = 32;

#define OFFSET_OF(type, field)                                                 \
  (reinterpret_cast<intptr_t>(&(reinterpret_cast<type*>(kOffsetOfPtr)->field)) \
      - kOffsetOfPtr)

#define OFFSET_OF_RETURNED_VALUE(type, accessor)                            \
  (reinterpret_cast<intptr_t>(                                              \
      (reinterpret_cast<type*>(kOffsetOfPtr)->accessor())) - kOffsetOfPtr)


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
    implicit_cast<From*, To>(0);
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
// On Windows the basic libraries use memcpy and therefore compilation will
// fail if memcpy is overwritten even if user code does not use memcpy.
#if defined(memcpy)
#undef memcpy
#endif
#if !defined(TARGET_OS_WINDOWS)
#define memcpy "Please use memmove instead of memcpy."
#endif


// When using GCC we can use GCC attributes to ensure that certain
// contants are 16 byte aligned.
#if defined(TARGET_OS_WINDOWS)
#define ALIGN16 __declspec(align(16))
#else
#define ALIGN16 __attribute__((aligned(16)))
#endif

}  // namespace dart

#endif  // VM_GLOBALS_H_
