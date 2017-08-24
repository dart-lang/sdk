// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SYNC_SOCKET_H_
#define RUNTIME_BIN_SYNC_SOCKET_H_

#include "bin/socket_base.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class SynchronousSocket {
 public:
  explicit SynchronousSocket(intptr_t fd) : fd_(fd) {}
  ~SynchronousSocket() { ASSERT(fd_ == kClosedFd); }

  intptr_t fd() const { return fd_; }
  void SetClosedFd() { fd_ = kClosedFd; }

  static bool Initialize();

  static intptr_t CreateConnect(const RawAddr& addr);

  static Dart_Handle SetSocketIdNativeField(Dart_Handle handle,
                                            SynchronousSocket* socket);
  static Dart_Handle GetSocketIdNativeField(Dart_Handle socket_obj,
                                            SynchronousSocket** socket);

  static intptr_t Available(intptr_t fd);
  static intptr_t GetPort(intptr_t fd);
  static SocketAddress* GetRemotePeer(intptr_t fd, intptr_t* port);
  static intptr_t Read(intptr_t fd, void* buffer, intptr_t num_bytes);
  static intptr_t Write(intptr_t fd, const void* buffer, intptr_t num_bytes);

  static void ShutdownRead(intptr_t fd);
  static void ShutdownWrite(intptr_t fd);
  static void Close(intptr_t fd);

 private:
  static const int kClosedFd = -1;

  intptr_t fd_;

  DISALLOW_COPY_AND_ASSIGN(SynchronousSocket);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SYNC_SOCKET_H_
