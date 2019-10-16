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
#else
#define NO_SANITIZE_THREAD
#endif

#endif  // RUNTIME_PLATFORM_THREAD_SANITIZER_H_
