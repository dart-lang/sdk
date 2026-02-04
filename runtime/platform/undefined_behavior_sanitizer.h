// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
#define RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_

#ifdef __clang__
#define NO_SANITIZE_UNDEFINED(check) [[clang::no_sanitize(check)]]
#define NO_SANITIZE_UNDEFINED_FUNCTION NO_SANITIZE_UNDEFINED("function")
#else
#define NO_SANITIZE_UNDEFINED(check) [[gnu::no_sanitize(check)]]
#define NO_SANITIZE_UNDEFINED_FUNCTION
#endif

#endif  // RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
