// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
   Generated with:
     dart pkg/vm/tool/generate_entry_point_shims.dart \
         out/ReleaseX64/gen/samples/embedder/timer_aot.dart.dill \
         samples/embedder/timer
*/

#ifndef SAMPLES_EMBEDDER_TIMER_H
#define SAMPLES_EMBEDDER_TIMER_H

#include "include/dart_engine.h"

#ifdef __cplusplus
#define PACKAGE_EXTERN_C extern "C"
#else
#define PACKAGE_EXTERN_C extern
#endif

#if defined(__CYGWIN__)
#error Tool chain and platform not supported.
#elif defined(_WIN32)
#define PACKAGE_EXPORT PACKAGE_EXTERN_C __declspec(dllexport)
#else
#if __GNUC__ >= 4
#define PACKAGE_EXPORT                                                         \
  PACKAGE_EXTERN_C __attribute__((visibility("default"))) __attribute((used))
#else
#error Tool chain not supported.
#endif
#endif

// startTimer
PACKAGE_EXPORT void Call_startTimer(Dart_Isolate dart_isolate,
                                    int64_t v_millis);
// stopTimer
PACKAGE_EXPORT void Call_stopTimer(Dart_Isolate dart_isolate);
// resetTimer
PACKAGE_EXPORT void Call_resetTimer(Dart_Isolate dart_isolate);
// ticks
PACKAGE_EXPORT int64_t Get_ticks(Dart_Isolate dart_isolate);

#undef PACKAGE_EXPORT
#undef PACKAGE_EXTERN_C

#endif  // SAMPLES_EMBEDDER_TIMER_H
