// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SOCKET_WIN_H_
#define BIN_SOCKET_WIN_H_

#if !defined(BIN_SOCKET_H_)
#error Do not include socket_win.h directly. Use socket.h.
#endif

#include <iphlpapi.h>
#include <mswsock.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#endif  // BIN_SOCKET_WIN_H_
