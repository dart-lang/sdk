// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/thread_sanitizer.h"

#if defined(USING_THREAD_SANITIZER)
// Functions returning default options are declared weak in the tools' runtime
// libraries. To make the linker pick the strong replacements for those
// functions from this module, we explicitly force its inclusion by passing
// -Wl,-u,_sanitizer_options_link_helper
extern "C" void _sanitizer_options_link_helper() {}

// The callbacks we define here will be called from the sanitizer runtime, but
// aren't referenced from the Dart binaries. We must ensure that those
// callbacks are not sanitizer-instrumented, and that they aren't stripped by
// the linker.
#define SANITIZER_HOOK_ATTRIBUTE                                               \
  extern "C" __attribute__((no_sanitize_address))                              \
  __attribute__((no_sanitize_memory)) __attribute__((no_sanitize_thread))      \
  __attribute__((visibility("default"))) __attribute__((used))
#endif

#if defined(USING_THREAD_SANITIZER) && defined(DART_HOST_OS_LINUX)
SANITIZER_HOOK_ATTRIBUTE const char* __tsan_default_suppressions() {
  // See https://github.com/google/sanitizers/wiki/threadsanitizersuppressions
  return R"(
# False positive in libc's tzset_internal (see http://dartbug.com/54064).
# In some environments tzset_internal is not symbolized correctly so we
# also suppress the closest caller which is properly symbolized.
race:tzset_internal
race:dart::LocalTime
)";
}
#endif  // defined(USING_THREAD_SANITIZER) && defined(DART_HOST_OS_LINUX)
