// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(HOST_OS_LINUX) || defined(HOST_OS_MACOSX)
#if defined(__has_feature)
#if __has_feature(address_sanitizer)

const char* kAsanDefaultOptions =
    "strict_memcmp=0 symbolize=0 check_printf=1 use_sigaltstack=1 "
    "detect_leaks=0 fast_unwind_on_fatal=1 handle_segv=0 ";

extern "C" __attribute__((no_sanitize_address))
__attribute__((visibility("default")))
// The function isn't referenced from the executable itself. Make sure it isn't
// stripped by the linker.
__attribute__((used)) const char*
__asan_default_options() {
  return kAsanDefaultOptions;
}

#endif  // __has_feature(address_sanitizer)
#endif  // defined(__has_feature)
#endif  //  defined(HOST_OS_LINUX) || defined(HOST_OS_MACOSX)
