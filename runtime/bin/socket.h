// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SOCKET_H_
#define BIN_SOCKET_H_

#include "bin/builtin.h"
#include "bin/utils.h"
#include "platform/globals.h"
#include "platform/thread.h"


class Socket {
 public:
  enum SocketRequest {
    kLookupRequest = 0,
  };

  static bool Initialize();
  static intptr_t Available(intptr_t fd);
  static int Read(intptr_t fd, void* buffer, intptr_t num_bytes);
  static int Write(intptr_t fd, const void* buffer, intptr_t num_bytes);
  static intptr_t CreateConnect(const char* host, const intptr_t port);
  static intptr_t GetPort(intptr_t fd);
  static void GetError(intptr_t fd, OSError* os_error);
  static intptr_t GetStdioHandle(int num);

  // Perform a IPv4 hostname lookup. Returns the hostname string in
  // IPv4 dotted-decimal format.
  static const char* LookupIPv4Address(char* host, OSError** os_error);

  static Dart_Port GetServicePort();

 private:
  static dart::Mutex mutex_;
  static int service_ports_size_;
  static Dart_Port* service_ports_;
  static int service_ports_index_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Socket);
};


class ServerSocket {
 public:
  static const intptr_t kTemporaryFailure = -2;

  static intptr_t Accept(intptr_t fd);
  static intptr_t CreateBindListen(const char* bindAddress,
                                   intptr_t port,
                                   intptr_t backlog);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ServerSocket);
};

#endif  // BIN_SOCKET_H_
