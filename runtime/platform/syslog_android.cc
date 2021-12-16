// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_ANDROID)

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
  va_list stdio_args;
  va_copy(stdio_args, args);
  vprintf(format, stdio_args);
  fflush(stdout);
  va_end(stdio_args);

  va_list log_args;
  va_copy(log_args, args);
  __android_log_vprint(ANDROID_LOG_INFO, "Dart", format, log_args);
  va_end(log_args);
}

void Syslog::VPrintErr(const char* format, va_list args) {
  // If we launch the DartVM inside "adb shell" we will only get messages
  // (critical ones or not) if we print them to stdout/stderr.
  // We also log using android's logging system.
  va_list stdio_args;
  va_copy(stdio_args, args);
  vfprintf(stderr, format, stdio_args);
  fflush(stderr);
  va_end(stdio_args);

  va_list log_args;
  va_copy(log_args, args);
  __android_log_vprint(ANDROID_LOG_ERROR, "Dart", format, log_args);
  va_end(log_args);
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID)
