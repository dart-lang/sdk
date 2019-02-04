// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "bin/socket.h"

#include <errno.h>  // NOLINT

#include "bin/fdutils.h"
#include "bin/log.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

Socket::Socket(intptr_t fd)
    : ReferenceCounted(),
      fd_(fd),
      isolate_port_(Dart_GetMainPortId()),
      port_(ILLEGAL_PORT),
      udp_receive_buffer_(NULL) {}

void Socket::SetClosedFd() {
  fd_ = kClosedFd;
}

static intptr_t Create(const RawAddr& addr) {
  intptr_t fd;
  intptr_t type = SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC;
  fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, type, 0));
  if (fd < 0) {
    return -1;
  }
  return fd;
}

static intptr_t Connect(intptr_t fd, const RawAddr& addr) {
  intptr_t result = TEMP_FAILURE_RETRY(
      connect(fd, &addr.addr, SocketAddress::GetAddrLength(addr)));
  if ((result == 0) || (errno == EINPROGRESS)) {
    return fd;
  }
  FDUtils::FDUtils::SaveErrorAndClose(fd);
  return -1;
}

intptr_t Socket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }
  return Connect(fd, addr);
}

intptr_t Socket::CreateBindConnect(const RawAddr& addr,
                                   const RawAddr& source_addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }

  intptr_t result = TEMP_FAILURE_RETRY(
      bind(fd, &source_addr.addr, SocketAddress::GetAddrLength(source_addr)));
  if ((result != 0) && (errno != EINPROGRESS)) {
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }

  return Connect(fd, addr);
}

intptr_t Socket::CreateBindDatagram(const RawAddr& addr,
                                    bool reuseAddress,
                                    bool reusePort,
                                    int ttl) {
  intptr_t fd;

  fd = NO_RETRY_EXPECTED(socket(addr.addr.sa_family,
                                SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK,
                                IPPROTO_UDP));
  if (fd < 0) {
    return -1;
  }

  if (reuseAddress) {
    int optval = 1;
    VOID_NO_RETRY_EXPECTED(
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));
  }

  if (reusePort) {
#ifdef SO_REUSEPORT  // Not all Linux versions support this.
    int optval = 1;
    int reuse_port_success =
        setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &optval, sizeof(optval));
    // Even if it's defined, we might be running on a kernel
    // that doesn't support it at runtime.
    if (reuse_port_success != 0) {
      if (errno == EINTR) {
        FATAL("Unexpected EINTR errno");
      }
      const int kBufferSize = 1024;
      char error_buf[kBufferSize];
      Log::PrintErr("Dart Socket ERROR: %s:%d: %s.", __FILE__, __LINE__,
                    Utils::StrError(errno, error_buf, kBufferSize));
    }
#else   // !defined SO_REUSEPORT
    Log::PrintErr(
        "Dart Socket ERROR: %s:%d: `reusePort` not available on this Linux "
        "version.",
        __FILE__, __LINE__);
#endif  // SO_REUSEPORT
  }

  if (!SocketBase::SetMulticastHops(fd,
                                    addr.addr.sa_family == AF_INET
                                        ? SocketAddress::TYPE_IPV4
                                        : SocketAddress::TYPE_IPV6,
                                    ttl)) {
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }

  if (NO_RETRY_EXPECTED(
          bind(fd, &addr.addr, SocketAddress::GetAddrLength(addr))) < 0) {
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }
  return fd;
}

intptr_t ServerSocket::CreateBindListen(const RawAddr& addr,
                                        intptr_t backlog,
                                        bool v6_only) {
  intptr_t fd;

  fd = NO_RETRY_EXPECTED(
      socket(addr.ss.ss_family, SOCK_STREAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0));
  if (fd < 0) {
    return -1;
  }

  int optval = 1;
  VOID_NO_RETRY_EXPECTED(
      setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only ? 1 : 0;
    VOID_NO_RETRY_EXPECTED(
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &optval, sizeof(optval)));
  }

  if (NO_RETRY_EXPECTED(
          bind(fd, &addr.addr, SocketAddress::GetAddrLength(addr))) < 0) {
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }

  // Test for invalid socket port 65535 (some browsers disallow it).
  if ((SocketAddress::GetAddrPort(addr) == 0) &&
      (SocketBase::GetPort(fd) == 65535)) {
    // Don't close the socket until we have created a new socket, ensuring
    // that we do not get the bad port number again.
    intptr_t new_fd = CreateBindListen(addr, backlog, v6_only);
    FDUtils::SaveErrorAndClose(fd);
    return new_fd;
  }

  if (NO_RETRY_EXPECTED(listen(fd, backlog > 0 ? backlog : SOMAXCONN)) != 0) {
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }

  return fd;
}

bool ServerSocket::StartAccept(intptr_t fd) {
  USE(fd);
  return true;
}

static bool IsTemporaryAcceptError(int error) {
  // On Linux a number of protocol errors should be treated as EAGAIN.
  // These are the ones for TCP/IP.
  return (error == EAGAIN) || (error == ENETDOWN) || (error == EPROTO) ||
         (error == ENOPROTOOPT) || (error == EHOSTDOWN) || (error == ENONET) ||
         (error == EHOSTUNREACH) || (error == EOPNOTSUPP) ||
         (error == ENETUNREACH);
}

intptr_t ServerSocket::Accept(intptr_t fd) {
  intptr_t socket;
  struct sockaddr clientaddr;
  socklen_t addrlen = sizeof(clientaddr);
  socket = TEMP_FAILURE_RETRY(accept(fd, &clientaddr, &addrlen));
  if (socket == -1) {
    if (IsTemporaryAcceptError(errno)) {
      // We need to signal to the caller that this is actually not an
      // error. We got woken up from the poll on the listening socket,
      // but there is no connection ready to be accepted.
      ASSERT(kTemporaryFailure != -1);
      socket = kTemporaryFailure;
    }
  } else {
    if (!FDUtils::SetCloseOnExec(socket)) {
      FDUtils::SaveErrorAndClose(socket);
      return -1;
    }
    if (!FDUtils::SetNonBlocking(socket)) {
      FDUtils::SaveErrorAndClose(socket);
      return -1;
    }
  }
  return socket;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
