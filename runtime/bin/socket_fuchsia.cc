// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/socket.h"
#include "bin/socket_fuchsia.h"

#include <errno.h>        // NOLINT
#include <fcntl.h>        // NOLINT
#include <ifaddrs.h>      // NOLINT
#include <net/if.h>       // NOLINT
#include <netinet/tcp.h>  // NOLINT
#include <stdio.h>        // NOLINT
#include <stdlib.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/ioctl.h>    // NOLINT
#include <sys/stat.h>     // NOLINT
#include <unistd.h>       // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"
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

SocketAddress::SocketAddress(struct sockaddr* sa) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  if (!Socket::FormatNumericAddress(*reinterpret_cast<RawAddr*>(sa), as_string_,
                                    INET6_ADDRSTRLEN)) {
    as_string_[0] = 0;
  }
  socklen_t salen = GetAddrLength(*reinterpret_cast<RawAddr*>(sa));
  memmove(reinterpret_cast<void*>(&addr_), sa, salen);
}


bool Socket::FormatNumericAddress(const RawAddr& addr, char* address, int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  LOG_INFO("Socket::FormatNumericAddress: calling getnameinfo\n");
  return (NO_RETRY_EXPECTED(getnameinfo(&addr.addr, salen, address, len, NULL,
                                        0, NI_NUMERICHOST) == 0));
}


bool Socket::Initialize() {
  // Nothing to do on Fuchsia.
  return true;
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
  return fd;
}


static intptr_t Connect(intptr_t fd, const RawAddr& addr) {
  LOG_INFO("Connect: calling connect(%ld)\n", fd);
  intptr_t result = NO_RETRY_EXPECTED(
      connect(fd, &addr.addr, SocketAddress::GetAddrLength(addr)));
  if ((result == 0) || (errno == EINPROGRESS)) {
    return fd;
  }
  LOG_ERR("Connect: connect(%ld) failed\n", fd);
  FDUtils::SaveErrorAndClose(fd);
  return -1;
}


intptr_t Socket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }
  if (!FDUtils::SetNonBlocking(fd)) {
    LOG_ERR("CreateConnect: FDUtils::SetNonBlocking(%ld) failed\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }
  return Connect(fd, addr);
}


intptr_t Socket::CreateBindConnect(const RawAddr& addr,
                                   const RawAddr& source_addr) {
  LOG_ERR("Socket::CreateBindConnect is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}


bool Socket::IsBindError(intptr_t error_number) {
  return error_number == EADDRINUSE || error_number == EADDRNOTAVAIL ||
         error_number == EINVAL;
}


intptr_t Socket::Available(intptr_t fd) {
  return FDUtils::AvailableBytes(fd);
}


intptr_t Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  LOG_INFO("Socket::Read: calling read(%ld, %p, %ld)\n", fd, buffer, num_bytes);
  ssize_t read_bytes = NO_RETRY_EXPECTED(read(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((read_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  } else if (read_bytes == -1) {
    LOG_ERR("Socket::Read: read(%ld, %p, %ld) failed\n", fd, buffer, num_bytes);
  } else {
    LOG_INFO("Socket::Read: read(%ld, %p, %ld) succeeded\n", fd, buffer,
             num_bytes);
  }
  return read_bytes;
}


intptr_t Socket::RecvFrom(intptr_t fd,
                          void* buffer,
                          intptr_t num_bytes,
                          RawAddr* addr) {
  LOG_ERR("Socket::RecvFrom is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  LOG_INFO("Socket::Write: calling write(%ld, %p, %ld)\n", fd, buffer,
           num_bytes);
  ssize_t written_bytes = NO_RETRY_EXPECTED(write(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((written_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  } else if (written_bytes == -1) {
    LOG_ERR("Socket::Write: write(%ld, %p, %ld) failed\n", fd, buffer,
            num_bytes);
  } else {
    LOG_INFO("Socket::Write: write(%ld, %p, %ld) succeeded\n", fd, buffer,
             num_bytes);
  }
  return written_bytes;
}


intptr_t Socket::SendTo(intptr_t fd,
                        const void* buffer,
                        intptr_t num_bytes,
                        const RawAddr& addr) {
  LOG_ERR("Socket::SendTo is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}


intptr_t Socket::GetPort(intptr_t fd) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  LOG_INFO("Socket::GetPort: calling getsockname(%ld)\n", fd);
  if (NO_RETRY_EXPECTED(getsockname(fd, &raw.addr, &size))) {
    return 0;
  }
  return SocketAddress::GetAddrPort(raw);
}


SocketAddress* Socket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getpeername(fd, &raw.addr, &size))) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(raw);
  return new SocketAddress(&raw.addr);
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  LOG_ERR("Socket::GetError is unimplemented\n");
  UNIMPLEMENTED();
}


int Socket::GetType(intptr_t fd) {
  LOG_ERR("Socket::GetType is unimplemented\n");
  UNIMPLEMENTED();
  return File::kOther;
}


intptr_t Socket::GetStdioHandle(intptr_t num) {
  LOG_ERR("Socket::GetStdioHandle is unimplemented\n");
  UNIMPLEMENTED();
  return num;
}


AddressList<SocketAddress>* Socket::LookupAddress(const char* host,
                                                  int type,
                                                  OSError** os_error) {
  // Perform a name lookup for a host name.
  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = SocketAddress::FromType(type);
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_ADDRCONFIG;
  hints.ai_protocol = IPPROTO_TCP;
  struct addrinfo* info = NULL;
  LOG_INFO("Socket::LookupAddress: calling getaddrinfo\n");
  int status = NO_RETRY_EXPECTED(getaddrinfo(host, 0, &hints, &info));
  if (status != 0) {
    // We failed, try without AI_ADDRCONFIG. This can happen when looking up
    // e.g. '::1', when there are no global IPv6 addresses.
    hints.ai_flags = 0;
    LOG_INFO("Socket::LookupAddress: calling getaddrinfo again\n");
    status = NO_RETRY_EXPECTED(getaddrinfo(host, 0, &hints, &info));
    if (status != 0) {
      ASSERT(*os_error == NULL);
      *os_error =
          new OSError(status, gai_strerror(status), OSError::kGetAddressInfo);
      return NULL;
    }
  }
  intptr_t count = 0;
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if ((c->ai_family == AF_INET) || (c->ai_family == AF_INET6)) {
      count++;
    }
  }
  intptr_t i = 0;
  AddressList<SocketAddress>* addresses = new AddressList<SocketAddress>(count);
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if ((c->ai_family == AF_INET) || (c->ai_family == AF_INET6)) {
      addresses->SetAt(i, new SocketAddress(c->ai_addr));
      i++;
    }
  }
  freeaddrinfo(info);
  return addresses;
}


bool Socket::ReverseLookup(const RawAddr& addr,
                           char* host,
                           intptr_t host_len,
                           OSError** os_error) {
  LOG_ERR("Socket::ReverseLookup is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::ParseAddress(int type, const char* address, RawAddr* addr) {
  int result;
  if (type == SocketAddress::TYPE_IPV4) {
    result = NO_RETRY_EXPECTED(inet_pton(AF_INET, address, &addr->in.sin_addr));
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    result =
        NO_RETRY_EXPECTED(inet_pton(AF_INET6, address, &addr->in6.sin6_addr));
  }
  return (result == 1);
}


intptr_t Socket::CreateBindDatagram(const RawAddr& addr, bool reuseAddress) {
  LOG_ERR("Socket::CreateBindDatagram is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
}


bool Socket::ListInterfacesSupported() {
  return false;
}


AddressList<InterfaceSocketAddress>* Socket::ListInterfaces(
    int type,
    OSError** os_error) {
  UNIMPLEMENTED();
  return NULL;
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

  // Test for invalid socket port 65535 (some browsers disallow it).
  if ((SocketAddress::GetAddrPort(addr) == 0) &&
      (Socket::GetPort(fd) == 65535)) {
    // Don't close the socket until we have created a new socket, ensuring
    // that we do not get the bad port number again.
    intptr_t new_fd = CreateBindListen(addr, backlog, v6_only);
    FDUtils::SaveErrorAndClose(fd);
    return new_fd;
  }

  LOG_INFO("ServerSocket::CreateBindListen: calling listen(%ld)\n", fd);
  if (NO_RETRY_EXPECTED(listen(fd, backlog > 0 ? backlog : SOMAXCONN)) != 0) {
    LOG_ERR("ServerSocket::CreateBindListen: listen failed(%ld)\n", fd);
    FDUtils::SaveErrorAndClose(fd);
    return -1;
  }
  LOG_INFO("ServerSocket::CreateBindListen: listen(%ld) succeeded\n", fd);

  if (!FDUtils::SetNonBlocking(fd)) {
    LOG_ERR("CreateBindListen: FDUtils::SetNonBlocking(%ld) failed\n", fd);
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
  LOG_INFO("ServerSocket::Accept: calling accept(%ld)\n", fd);
  socket = NO_RETRY_EXPECTED(accept(fd, &clientaddr, &addrlen));
  if (socket == -1) {
    if (IsTemporaryAcceptError(errno)) {
      // We need to signal to the caller that this is actually not an
      // error. We got woken up from the poll on the listening socket,
      // but there is no connection ready to be accepted.
      ASSERT(kTemporaryFailure != -1);
      socket = kTemporaryFailure;
    } else {
      LOG_ERR("ServerSocket::Accept: accept(%ld) failed\n", fd);
    }
  } else {
    LOG_INFO("ServerSocket::Accept: accept(%ld) -> socket %ld\n", fd, socket);
    if (!FDUtils::SetCloseOnExec(socket)) {
      LOG_ERR("FDUtils::SetCloseOnExec(%ld) failed\n", socket);
      FDUtils::SaveErrorAndClose(socket);
      return -1;
    }
    if (!FDUtils::SetNonBlocking(socket)) {
      LOG_ERR("FDUtils::SetNonBlocking(%ld) failed\n", socket);
      FDUtils::SaveErrorAndClose(socket);
      return -1;
    }
  }
  return socket;
}


void Socket::Close(intptr_t fd) {
  ASSERT(fd >= 0);
  NO_RETRY_EXPECTED(close(fd));
}


bool Socket::GetNoDelay(intptr_t fd, bool* enabled) {
  LOG_ERR("Socket::GetNoDelay is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY,
                                      reinterpret_cast<char*>(&on),
                                      sizeof(on))) == 0;
}


bool Socket::GetMulticastLoop(intptr_t fd, intptr_t protocol, bool* enabled) {
  LOG_ERR("Socket::GetMulticastLoop is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetMulticastLoop(intptr_t fd, intptr_t protocol, bool enabled) {
  LOG_ERR("Socket::SetMulticastLoop is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  LOG_ERR("Socket::GetMulticastHops is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  LOG_ERR("Socket::SetMulticastHops is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::GetBroadcast(intptr_t fd, bool* enabled) {
  LOG_ERR("Socket::GetBroadcast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::SetBroadcast(intptr_t fd, bool enabled) {
  LOG_ERR("Socket::SetBroadcast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::JoinMulticast(intptr_t fd,
                           const RawAddr& addr,
                           const RawAddr&,
                           int interfaceIndex) {
  LOG_ERR("Socket::JoinMulticast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}


bool Socket::LeaveMulticast(intptr_t fd,
                            const RawAddr& addr,
                            const RawAddr&,
                            int interfaceIndex) {
  LOG_ERR("Socket::LeaveMulticast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
