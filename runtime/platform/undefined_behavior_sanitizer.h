// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
#define RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_

#define NO_SANITIZE_UNDEFINED(check) [[gnu::no_sanitize(check)]]

#endif  // RUNTIME_PLATFORM_UNDEFINED_BEHAVIOR_SANITIZER_H_
