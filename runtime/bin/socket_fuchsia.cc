// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/socket.h"

#include <errno.h>  // NOLINT

#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

// #define SOCKET_LOG_INFO 1
// #define SOCKET_LOG_ERROR 1

// define SOCKET_LOG_ERROR to get log messages only for errors.
// define SOCKET_LOG_INFO to get log messages for both information and errors.
#if defined(SOCKET_LOG_INFO) || defined(SOCKET_LOG_ERROR)
#define LOG_ERR(msg, ...)                                                      \
  {                                                                            \
    int err = errno;                                                           \
    Log::PrintErr("Dart Socket ERROR: %s:%d: " msg, __FILE__, __LINE__,        \
                  ##__VA_ARGS__);                                              \
    errno = err;                                                               \
  }
#if defined(SOCKET_LOG_INFO)
#define LOG_INFO(msg, ...)                                                     \
  Log::Print("Dart Socket INFO: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#else
#define LOG_INFO(msg, ...)
#endif  // defined(SOCKET_LOG_INFO)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(SOCKET_LOG_INFO) || defined(SOCKET_LOG_ERROR)

namespace dart {
namespace bin {

Socket::Socket(intptr_t fd)
    : ReferenceCounted(), fd_(fd), port_(ILLEGAL_PORT) {}

void Socket::SetClosedFd() {
  ASSERT(fd_ != kClosedFd);
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd_);
  ASSERT(handle != NULL);
  handle->Release();
  fd_ = kClosedFd;
}

static intptr_t Create(const RawAddr& addr) {
  LOG_INFO("Create: calling socket(SOCK_STREAM)\n");
  intptr_t fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) {
    LOG_ERR("Create: socket(SOCK_STREAM) failed\n");
    return -1;
  }
  LOG_INFO("Create: socket(SOCK_STREAM) -> fd %ld\n", fd);
  if (!FDUtils::SetCloseOnExec(fd)) {
    LOG_ERR("Create: FDUtils::SetCloseOnExec(%ld) failed\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }
  IOHandle* io_handle = new IOHandle(fd);
  return reinterpret_cast<intptr_t>(io_handle);
}

static intptr_t Connect(intptr_t fd, const RawAddr& addr) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  LOG_INFO("Connect: calling connect(%ld)\n", handle->fd());
  intptr_t result = NO_RETRY_EXPECTED(
      connect(handle->fd(), &addr.addr, SocketAddress::GetAddrLength(addr)));
  if ((result == 0) || (errno == EINPROGRESS)) {
    return reinterpret_cast<intptr_t>(handle);
  }
  LOG_ERR("Connect: connect(%ld) failed\n", handle->fd());
  FDUtils::SaveErrorAndClose(handle->fd());
  handle->Release();
  return -1;
}

intptr_t Socket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  if (!FDUtils::SetNonBlocking(handle->fd())) {
    LOG_ERR("CreateConnect: FDUtils::SetNonBlocking(%ld) failed\n",
            handle->fd());
    FDUtils::SaveErrorAndClose(handle->fd());
    handle->Release();
    return -1;
  }
  return Connect(fd, addr);
}

intptr_t Socket::CreateBindConnect(const RawAddr& addr,
                                   const RawAddr& source_addr) {
  LOG_ERR("SocketBase::CreateBindConnect is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}

intptr_t Socket::CreateBindDatagram(const RawAddr& addr, bool reuseAddress) {
  LOG_ERR("SocketBase::CreateBindDatagram is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}

intptr_t ServerSocket::CreateBindListen(const RawAddr& addr,
                                        intptr_t backlog,
                                        bool v6_only) {
  LOG_INFO("ServerSocket::CreateBindListen: calling socket(SOCK_STREAM)\n");
  intptr_t fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) {
    LOG_ERR("ServerSocket::CreateBindListen: socket() failed\n");
    return -1;
  }
  LOG_INFO("ServerSocket::CreateBindListen: socket(SOCK_STREAM) -> %ld\n", fd);

  if (!FDUtils::SetCloseOnExec(fd)) {
    LOG_ERR("ServerSocket::CreateBindListen: SetCloseOnExec(%ld) failed\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }

  LOG_INFO("ServerSocket::CreateBindListen: calling setsockopt(%ld)\n", fd);
  int optval = 1;
  VOID_NO_RETRY_EXPECTED(
      setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only ? 1 : 0;
    LOG_INFO("ServerSocket::CreateBindListen: calling setsockopt(%ld)\n", fd);
    VOID_NO_RETRY_EXPECTED(
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &optval, sizeof(optval)));
  }

  LOG_INFO("ServerSocket::CreateBindListen: calling bind(%ld)\n", fd);
  if (NO_RETRY_EXPECTED(
          bind(fd, &addr.addr, SocketAddress::GetAddrLength(addr))) < 0) {
    LOG_ERR("ServerSocket::CreateBindListen: bind(%ld) failed\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }
  LOG_INFO("ServerSocket::CreateBindListen: bind(%ld) succeeded\n", fd);

  IOHandle* io_handle = new IOHandle(fd);

  // Test for invalid socket port 65535 (some browsers disallow it).
  if ((SocketAddress::GetAddrPort(addr) == 0) &&
      (SocketBase::GetPort(reinterpret_cast<intptr_t>(io_handle)) == 65535)) {
    // Don't close the socket until we have created a new socket, ensuring
    // that we do not get the bad port number again.
    intptr_t new_fd = CreateBindListen(addr, backlog, v6_only);
    FDUtils::SaveErrorAndClose(fd);
    io_handle->Release();
    return new_fd;
  }

  LOG_INFO("ServerSocket::CreateBindListen: calling listen(%ld)\n", fd);
  if (NO_RETRY_EXPECTED(listen(fd, backlog > 0 ? backlog : SOMAXCONN)) != 0) {
    LOG_ERR("ServerSocket::CreateBindListen: listen failed(%ld)\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    io_handle->Release();
    return -1;
  }
  LOG_INFO("ServerSocket::CreateBindListen: listen(%ld) succeeded\n", fd);

  if (!FDUtils::SetNonBlocking(fd)) {
    LOG_ERR("CreateBindListen: FDUtils::SetNonBlocking(%ld) failed\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    io_handle->Release();
    return -1;
  }
  return reinterpret_cast<intptr_t>(io_handle);
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
  IOHandle* listen_handle = reinterpret_cast<IOHandle*>(fd);
  intptr_t socket;
  struct sockaddr clientaddr;
  socklen_t addrlen = sizeof(clientaddr);
  LOG_INFO("ServerSocket::Accept: calling accept(%ld)\n", listen_fd);
  socket = listen_handle->Accept(&clientaddr, &addrlen);
  if (socket == -1) {
    if (IsTemporaryAcceptError(errno)) {
      // We need to signal to the caller that this is actually not an
      // error. We got woken up from the poll on the listening socket,
      // but there is no connection ready to be accepted.
      ASSERT(kTemporaryFailure != -1);
      socket = kTemporaryFailure;
    } else {
      LOG_ERR("ServerSocket::Accept: accept(%ld) failed\n", listen_fd);
    }
  } else {
    IOHandle* io_handle = new IOHandle(socket);
    LOG_INFO("ServerSocket::Accept: accept(%ld) -> socket %ld\n", listen_fd,
             socket);
    if (!FDUtils::SetCloseOnExec(socket)) {
      LOG_ERR("FDUtils::SetCloseOnExec(%ld) failed\n", socket);
      FDUtils::SaveErrorAndClose(socket);
      io_handle->Release();
      return -1;
    }
    if (!FDUtils::SetNonBlocking(socket)) {
      LOG_ERR("FDUtils::SetNonBlocking(%ld) failed\n", socket);
      FDUtils::SaveErrorAndClose(socket);
      io_handle->Release();
      return -1;
    }
    socket = reinterpret_cast<intptr_t>(io_handle);
  }
  return socket;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
