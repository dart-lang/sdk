// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SOCKET_BASE_WIN_H_
#define RUNTIME_BIN_SOCKET_BASE_WIN_H_

#if !defined(RUNTIME_BIN_SOCKET_BASE_H_)
#error Do not include socket_base_win.h directly. Use socket_base.h.
#endif

#include <iphlpapi.h>
#include <mswsock.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#endif  // RUNTIME_BIN_SOCKET_BASE_WIN_H_
