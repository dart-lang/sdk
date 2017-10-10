// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_SAFE_STACK_H_
#define RUNTIME_PLATFORM_SAFE_STACK_H_

#include "platform/globals.h"

#if defined(__has_feature)
#if __has_feature(safe_stack)
#define USING_SAFE_STACK
#endif
#endif

#if defined(USING_SAFE_STACK)
#define NO_SANITIZE_SAFE_STACK __attribute__((no_sanitize("safe-stack")))
#else
#define NO_SANITIZE_SAFE_STACK
#endif

#endif  // RUNTIME_PLATFORM_SAFE_STACK_H_
