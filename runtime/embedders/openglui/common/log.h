// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_LOG_H_
#define EMBEDDERS_OPENGLUI_COMMON_LOG_H_

#ifndef ANDROID
#include <stdio.h>
#define LOGI(...)       do {\
                          fprintf(stdout, __VA_ARGS__);\
                          fprintf(stdout, "\n");\
                          fflush(stdout);\
                        } while (0)
#define LOGE(...)       do { \
                          fprintf(stderr, __VA_ARGS__);\
                          fprintf(stderr, "\n");\
                          fflush(stderr);\
                        } while (0)
#else
#include "embedders/openglui/android/android_log.h"
#endif

#ifndef DEBUG
#undef LOGI
#define LOGI(...)
#endif

#endif  // EMBEDDERS_OPENGLUI_COMMON_LOG_H_

