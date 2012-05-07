// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_CONNECTION_LINUX_H_
#define BIN_DBG_CONNECTION_LINUX_H_

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>


class DebuggerConnectionImpl {
 public:
  static void StartHandler(int port_number);
};

#endif  // BIN_DBG_CONNECTION_LINUX_H_
