// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "platform/syslog.h"

#include <stdio.h>  // NOLINT

namespace dart {

void Syslog::VPrint(const char* format, va_list args) {
  vfprintf(stdout, format, args);
  fflush(stdout);
}

void Syslog::VPrintErr(const char* format, va_list args) {
  vfprintf(stderr, format, args);
  fflush(stderr);
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
