// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/utils.h"

#include <errno.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"

#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(OSError_inProgressErrorCode)(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, EINPROGRESS);
}

}  // namespace bin
}  // namespace dart
