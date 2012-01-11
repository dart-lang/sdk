// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_GLOBALS_H_
#define PLATFORM_GLOBALS_H_

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
#include <Rpc.h>
#endif

#if !defined(_WIN32)
#include <inttypes.h>
#include <stdint.h>
#include <unistd.h>
#endif

#include <float.h>
#include <limits.h>
#include <math.h>
#include <openssl/bn.h>
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
