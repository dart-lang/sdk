// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ADDRESS_SANITIZER_H_
#define RUNTIME_PLATFORM_ADDRESS_SANITIZER_H_

#include "platform/globals.h"

// Allow the use of ASan (AddressSanitizer). This is needed as ASan needs to be
// told about areas where the VM does the equivalent of a long-jump.
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
#define USING_ADDRESS_SANITIZER
#endif
#endif

#if defined(USING_ADDRESS_SANITIZER)
extern "C" void __asan_unpoison_memory_region(void*, size_t);
#define NO_SANITIZE_ADDRESS __attribute__((no_sanitize("address")))
#define ASAN_UNPOISON(ptr, len) __asan_unpoison_memory_region(ptr, len)
#else  // defined(USING_ADDRESS_SANITIZER)
#define NO_SANITIZE_ADDRESS
#define ASAN_UNPOISON(ptr, len)                                                \
  do {                                                                         \
  } while (false && (ptr) == 0 && (len) == 0)
#endif  // defined(USING_ADDRESS_SANITIZER)

#endif  // RUNTIME_PLATFORM_ADDRESS_SANITIZER_H_
