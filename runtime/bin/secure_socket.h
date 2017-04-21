// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SECURE_SOCKET_H_
#define RUNTIME_BIN_SECURE_SOCKET_H_

#if defined(DART_IO_DISABLED) || defined(DART_IO_SECURE_SOCKET_DISABLED)
#error "secure_socket.h can only be included on builds with SSL enabled"
#endif

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX) ||                      \
    defined(HOST_OS_WINDOWS) || defined(HOST_OS_FUCHSIA)
#include "bin/secure_socket_boringssl.h"
#elif defined(HOST_OS_MACOS)
#if HOST_OS_IOS
#include "bin/secure_socket_ios.h"
#else  // HOST_OS_IOS
#include "bin/secure_socket_macos.h"
#endif  // HOST_OS_IOS
#else
#error Unknown target os.
#endif

#endif  // RUNTIME_BIN_SECURE_SOCKET_H_
