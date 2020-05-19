// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_LEAK_SANITIZER_H_
#define RUNTIME_PLATFORM_LEAK_SANITIZER_H_

#include "platform/globals.h"

#if defined(__has_feature)
#if __has_feature(leak_sanitizer) || __has_feature(address_sanitizer)
#define USING_LEAK_SANITIZER
#endif
#endif

#if defined(USING_LEAK_SANITIZER)
extern "C" void __lsan_register_root_region(const void* p, size_t size);
extern "C" void __lsan_unregister_root_region(const void* p, size_t size);
#define LSAN_REGISTER_ROOT_REGION(ptr, len)                                    \
  __lsan_register_root_region(ptr, len)
#define LSAN_UNREGISTER_ROOT_REGION(ptr, len)                                  \
  __lsan_unregister_root_region(ptr, len)
#else  // defined(USING_LEAK_SANITIZER)
#define LSAN_REGISTER_ROOT_REGION(ptr, len)                                    \
  do {                                                                         \
  } while (false && (ptr) == 0 && (len) == 0)
#define LSAN_UNREGISTER_ROOT_REGION(ptr, len)                                  \
  do {                                                                         \
  } while (false && (ptr) == 0 && (len) == 0)
#endif  // defined(USING_LEAK_SANITIZER)

#endif  // RUNTIME_PLATFORM_LEAK_SANITIZER_H_
