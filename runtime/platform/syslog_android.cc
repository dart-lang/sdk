// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "platform/syslog.h"

#include <android/log.h>  // NOLINT
#include <stdio.h>        // NOLINT

namespace dart {

// TODO(gram): We should be buffering the data and only outputting
// it when we see a '\n'.

void Syslog::VPrint(const char* format, va_list args) {
  // If we launch the DartVM inside "adb shell" we will only get messages
  // (critical ones or not) if we print them to stdout/stderr.
  // We also log using android's logging system.
  vprintf(format, args);
  fflush(stdout);
  __android_log_vprint(ANDROID_LOG_INFO, "Dart", format, args);
}

void Syslog::VPrintErr(const char* format, va_list args) {
  // If we launch the DartVM inside "adb shell" we will only get messages
  // (critical ones or not) if we print them to stdout/stderr.
  // We also log using android's logging system.
  vfprintf(stderr, format, args);
  fflush(stderr);
  __android_log_vprint(ANDROID_LOG_ERROR, "Dart", format, args);
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
