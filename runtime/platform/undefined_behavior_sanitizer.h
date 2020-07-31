// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
#define RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_

#if defined(__has_feature)
#if __has_feature(undefined_behavior_sanitizer)
#define USING_UNDEFINED_BEHAVIOR_SANITIZER
#endif
#endif

#if defined(USING_UNDEFINED_BEHAVIOR_SANITIZER)
#define NO_SANITIZE_UNDEFINED(check) __attribute__((no_sanitize(check)))
#else
#define NO_SANITIZE_UNDEFINED(check)
#endif

#endif  // RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
