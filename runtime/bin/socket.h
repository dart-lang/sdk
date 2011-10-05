// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SOCKET_H_
#define BIN_SOCKET_H_

#include "bin/builtin.h"
#include "bin/globals.h"


class Socket {
 public:
  static bool Initialize();
  static intptr_t Available(intptr_t fd);
  static intptr_t Read(intptr_t fd, void* buffer, intptr_t num_bytes);
  static intptr_t Write(intptr_t fd, const void* buffer, intptr_t num_bytes);
  static intptr_t CreateConnect(const char* host, const intptr_t port);
  static intptr_t GetPort(intptr_t fd);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Socket);
};


class ServerSocket {
 public:
  static intptr_t Accept(intptr_t fd);
  static intptr_t CreateBindListen(const char* bindAddress,
                                   intptr_t port,
                                   intptr_t backlog);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ServerSocket);
};

#endif  // BIN_SOCKET_H_
