// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/sync_socket.h"

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

SynchronousSocket::SynchronousSocket(intptr_t fd) : fd_(fd) {}


void SynchronousSocket::SetClosedFd() {
  fd_ = kClosedFd;
}


bool SynchronousSocket::Initialize() {
  // Nothing to do on Android.
  return true;
}


static intptr_t Create(const RawAddr& addr) {
  intptr_t fd;
  intptr_t type = SOCK_STREAM | SOCK_CLOEXEC;
  fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, type, 0));
  if (fd < 0) {
    return -1;
  }
  return fd;
}


static intptr_t Connect(intptr_t fd, const RawAddr& addr) {
  intptr_t result = TEMP_FAILURE_RETRY(
      connect(fd, &addr.addr, SocketAddress::GetAddrLength(addr)));
  if (result == 0) {
    return fd;
  }
  ASSERT(errno != EINPROGRESS);
  FDUtils::FDUtils::SaveErrorAndClose(fd);
  return -1;
}


intptr_t SynchronousSocket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }
  return Connect(fd, addr);
}


void SynchronousSocket::ShutdownRead(intptr_t fd) {
  VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_RD));
}


void SynchronousSocket::ShutdownWrite(intptr_t fd) {
  VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_WR));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)

#endif  // !defined(DART_IO_DISABLED)
