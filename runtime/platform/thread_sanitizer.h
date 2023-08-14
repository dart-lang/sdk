// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_THREAD_SANITIZER_H_
#define RUNTIME_PLATFORM_THREAD_SANITIZER_H_

#include "platform/globals.h"

#if defined(__has_feature)
#if __has_feature(thread_sanitizer)
#define USING_THREAD_SANITIZER
#endif
#endif

#if defined(USING_THREAD_SANITIZER)
#define NO_SANITIZE_THREAD __attribute__((no_sanitize("thread")))
extern "C" void __tsan_acquire(void* addr);
extern "C" void __tsan_release(void* addr);
constexpr bool kUsingThreadSanitizer = true;
#else
#define NO_SANITIZE_THREAD
constexpr bool kUsingThreadSanitizer = false;
#endif

#if defined(USING_THREAD_SANITIZER)
#define DO_IF_TSAN(CODE) CODE
#else
#define DO_IF_TSAN(CODE)
#endif

#if defined(USING_THREAD_SANITIZER)
#define DO_IF_NOT_TSAN(CODE)
#else
#define DO_IF_NOT_TSAN(CODE) CODE
#endif

#endif  // RUNTIME_PLATFORM_THREAD_SANITIZER_H_
