// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/sync_socket.h"

#include <errno.h>  // NOLINT

#include "bin/fdutils.h"
#include "bin/socket_base.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool SynchronousSocket::Initialize() {
  // Nothing to do on Fuchsia.
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

intptr_t SynchronousSocket::Available(intptr_t fd) {
  return SocketBase::Available(fd);
}

intptr_t SynchronousSocket::GetPort(intptr_t fd) {
  return SocketBase::GetPort(fd);
}

SocketAddress* SynchronousSocket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  return SocketBase::GetRemotePeer(fd, port);
}

intptr_t SynchronousSocket::Read(intptr_t fd,
                                 void* buffer,
                                 intptr_t num_bytes) {
  return SocketBase::Read(fd, buffer, num_bytes, SocketBase::kSync);
}

intptr_t SynchronousSocket::Write(intptr_t fd,
                                  const void* buffer,
                                  intptr_t num_bytes) {
  return SocketBase::Write(fd, buffer, num_bytes, SocketBase::kSync);
}

void SynchronousSocket::ShutdownRead(intptr_t fd) {
  VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_RD));
}

void SynchronousSocket::ShutdownWrite(intptr_t fd) {
  VOID_NO_RETRY_EXPECTED(shutdown(fd, SHUT_WR));
}

void SynchronousSocket::Close(intptr_t fd) {
  return SocketBase::Close(fd);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
