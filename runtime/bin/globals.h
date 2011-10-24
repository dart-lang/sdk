// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_GLOBALS_H_
#define BIN_GLOBALS_H_

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
#include <Rpc.h>
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


// The USE(x) template is used to silence C++ compiler warnings issued
// for unused variables.
template <typename T>
static inline void USE(T) { }


// On Windows the reentrent version of strtok is called
// strtok_s. Unify on the posix name strtok_r.
#if defined(TARGET_OS_WINDOWS)
#define snprintf _snprintf
#define strtok_r strtok_s
#endif

#endif  // BIN_GLOBALS_H_
