// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)

#include "bin/console.h"

#include <errno.h>
#include <sys/ioctl.h>
#include <termios.h>

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

void Console::SaveConfig() {
}

void Console::RestoreConfig() {
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||       \
        // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
