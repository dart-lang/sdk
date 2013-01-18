// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_LOG_H_
#define EMBEDDERS_OPENGLUI_COMMON_LOG_H_

#ifndef ANDROID
#include <stdio.h>
#define LOGI(...)       fprintf(stdout, __VA_ARGS__)
#define LOGE(...)       fprintf(stderr, __VA_ARGS__)
#else
#include "embedders/openglui/android/android_log.h"
#endif

#endif  // EMBEDDERS_OPENGLUI_COMMON_LOG_H_

