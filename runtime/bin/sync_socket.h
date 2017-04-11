// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SYNC_SOCKET_H_
#define RUNTIME_BIN_SYNC_SOCKET_H_

#if defined(DART_IO_DISABLED)
#error "sync_socket.h can only be included on builds with IO enabled"
#endif

#include "bin/socket_base.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class SynchronousSocket {
 public:
  explicit SynchronousSocket(intptr_t fd);
  ~SynchronousSocket() { ASSERT(fd_ == kClosedFd); }

  intptr_t fd() const { return fd_; }
  void SetClosedFd();

  static bool Initialize();

  static intptr_t CreateConnect(const RawAddr& addr);

  static Dart_Handle SetSocketIdNativeField(Dart_Handle handle, intptr_t id);
  static Dart_Handle GetSocketIdNativeField(Dart_Handle socket_obj,
                                            SynchronousSocket** socket);

  static void ShutdownRead(intptr_t fd);
  static void ShutdownWrite(intptr_t fd);

 private:
  static const int kClosedFd = -1;

  intptr_t fd_;

  DISALLOW_COPY_AND_ASSIGN(SynchronousSocket);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SYNC_SOCKET_H_
