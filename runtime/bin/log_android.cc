// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/log.h"

#include <stdio.h>
#include <android/log.h>

// TODO(gram): We should be buffering the data and only outputting
// it when we see a '\n'.

void Log::VPrint(const char* format, va_list args) {
  __android_log_vprint(ANDROID_LOG_INFO, "Dart", format, args);
}

void Log::VPrintErr(const char* format, va_list args) {
  __android_log_vprint(ANDROID_LOG_ERROR, "Dart", format, args);
}

