// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include <errno.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <stdlib.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <netinet/tcp.h>  // NOLINT
#include <ifaddrs.h>  // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/socket.h"


namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sockaddr) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  RawAddr* raw = reinterpret_cast<RawAddr*>(sockaddr);
  const char* result = inet_ntop(sockaddr->sa_family,
                                 &raw->in.sin_addr,
                                 as_string_,
                                 INET6_ADDRSTRLEN);
  if (result == NULL) as_string_[0] = 0;
  memmove(reinterpret_cast<void *>(&addr_),
          sockaddr,
          GetAddrLength(raw));
}


bool Socket::Initialize() {
  // Nothing to do on Android.
  return true;
}


intptr_t Socket::Create(RawAddr addr) {
  intptr_t fd;

  fd = TEMP_FAILURE_RETRY(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) {
    Log::PrintErr("Error Create: %s\n", strerror(errno));
    return -1;
  }

  FDUtils::SetCloseOnExec(fd);
  return fd;
}


intptr_t Socket::Connect(intptr_t fd, RawAddr addr, const intptr_t port) {
  SocketAddress::SetAddrPort(&addr, port);
  intptr_t result = TEMP_FAILURE_RETRY(
      connect(fd,
              &addr.addr,
              SocketAddress::GetAddrLength(&addr)));
  if (result == 0 || errno == EINPROGRESS) {
    return fd;
  }
  VOID_TEMP_FAILURE_RETRY(close(fd));
  return -1;
}


intptr_t Socket::CreateConnect(RawAddr addr, const intptr_t port) {
  intptr_t fd = Socket::Create(addr);
  if (fd < 0) {
    return fd;
  }

  Socket::SetNonBlocking(fd);

  return Socket::Connect(fd, addr, port);
}


intptr_t Socket::Available(intptr_t fd) {
  return FDUtils::AvailableBytes(fd);
}


int Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  ssize_t read_bytes = TEMP_FAILURE_RETRY(read(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if (read_bytes == -1 && errno == EWOULDBLOCK) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  }
  return read_bytes;
}


int Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  ssize_t written_bytes = TEMP_FAILURE_RETRY(write(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if (written_bytes == -1 && errno == EWOULDBLOCK) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  }
  return written_bytes;
}


intptr_t Socket::GetPort(intptr_t fd) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (TEMP_FAILURE_RETRY(
          getsockname(fd,
                      &raw.addr,
                      &size))) {
    Log::PrintErr("Error getsockname: %s\n", strerror(errno));
    return 0;
  }
  return SocketAddress::GetAddrPort(&raw);
}


bool Socket::GetRemotePeer(intptr_t fd, char *host, intptr_t *port) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (TEMP_FAILURE_RETRY(
          getpeername(fd,
                      &raw.addr,
                      &size))) {
    Log::PrintErr("Error getpeername: %s\n", strerror(errno));
    return false;
  }
  const void* src;
  if (raw.ss.ss_family == AF_INET6) {
    src = reinterpret_cast<const void*>(&raw.in6.sin6_addr);
  } else {
    src = reinterpret_cast<const void*>(&raw.in.sin_addr);
  }
  if (inet_ntop(raw.ss.ss_family,
                src,
                host,
                INET_ADDRSTRLEN) == NULL) {
    Log::PrintErr("Error inet_ntop: %s\n", strerror(errno));
    return false;
  }
  *port = SocketAddress::GetAddrPort(&raw);
  return true;
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  int errorNumber;
  socklen_t len = sizeof(errorNumber);
  getsockopt(fd,
             SOL_SOCKET,
             SO_ERROR,
             reinterpret_cast<void*>(&errorNumber),
             &len);
  os_error->SetCodeAndMessage(OSError::kSystem, errorNumber);
}


int Socket::GetType(intptr_t fd) {
  struct stat buf;
  int result = fstat(fd, &buf);
  if (result == -1) return -1;
  if (S_ISCHR(buf.st_mode)) return File::kTerminal;
  if (S_ISFIFO(buf.st_mode)) return File::kPipe;
  if (S_ISREG(buf.st_mode)) return File::kFile;
  return File::kOther;
}


intptr_t Socket::GetStdioHandle(int num) {
  return static_cast<intptr_t>(num);
}


AddressList<SocketAddress>* Socket::LookupAddress(const char* host,
                                                  int type,
                                                  OSError** os_error) {
  // Perform a name lookup for a host name.
  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = SocketAddress::FromType(type);
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = 0;
  hints.ai_protocol = IPPROTO_TCP;
  struct addrinfo* info = NULL;
  int status = getaddrinfo(host, 0, &hints, &info);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error = new OSError(status,
                            gai_strerror(status),
                            OSError::kGetAddressInfo);
    return NULL;
  }
  intptr_t count = 0;
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if (c->ai_family == AF_INET || c->ai_family == AF_INET6) count++;
  }
  intptr_t i = 0;
  AddressList<SocketAddress>* addresses = new AddressList<SocketAddress>(count);
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if (c->ai_family == AF_INET || c->ai_family == AF_INET6) {
      addresses->SetAt(i, new SocketAddress(c->ai_addr));
      i++;
    }
  }
  freeaddrinfo(info);
  return addresses;
}


bool Socket::ReverseLookup(RawAddr addr,
                           char* host,
                           intptr_t host_len,
                           OSError** os_error) {
  ASSERT(host_len >= NI_MAXHOST);
  int status = TEMP_FAILURE_RETRY(getnameinfo(
      &addr.addr,
      SocketAddress::GetAddrLength(&addr),
      host,
      host_len,
      NULL,
      0,
      NI_NAMEREQD));
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error = new OSError(status,
                            gai_strerror(status),
                            OSError::kGetAddressInfo);
    return false;
  }
  return true;
}


static bool ShouldIncludeIfaAddrs(struct ifaddrs* ifa, int lookup_family) {
  int family = ifa->ifa_addr->sa_family;
  if (lookup_family == family) return true;
  if (lookup_family == AF_UNSPEC &&
      (family == AF_INET || family == AF_INET6)) {
    return true;
  }
  return false;
}


AddressList<InterfaceSocketAddress>* Socket::ListInterfaces(
    int type,
    OSError** os_error) {
  struct ifaddrs* ifaddr;

  int status = getifaddrs(&ifaddr);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error = new OSError(status,
                            gai_strerror(status),
                            OSError::kGetAddressInfo);
    return NULL;
  }

  int lookup_family = SocketAddress::FromType(type);

  intptr_t count = 0;
  for (struct ifaddrs* ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (ShouldIncludeIfaAddrs(ifa, lookup_family)) count++;
  }

  AddressList<InterfaceSocketAddress>* addresses =
      new AddressList<InterfaceSocketAddress>(count);
  int i = 0;
  for (struct ifaddrs* ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (ShouldIncludeIfaAddrs(ifa, lookup_family)) {
      addresses->SetAt(i, new InterfaceSocketAddress(
          ifa->ifa_addr, strdup(ifa->ifa_name)));
      i++;
    }
  }
  freeifaddrs(ifaddr);
  return addresses;
}


intptr_t ServerSocket::CreateBindListen(RawAddr addr,
                                        intptr_t port,
                                        intptr_t backlog,
                                        bool v6_only) {
  intptr_t fd;

  fd = TEMP_FAILURE_RETRY(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) return -1;

  FDUtils::SetCloseOnExec(fd);

  int optval = 1;
  TEMP_FAILURE_RETRY(
      setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only ? 1 : 0;
    TEMP_FAILURE_RETRY(
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &optval, sizeof(optval)));
  }

  SocketAddress::SetAddrPort(&addr, port);
  if (TEMP_FAILURE_RETRY(
          bind(fd,
               &addr.addr,
               SocketAddress::GetAddrLength(&addr))) < 0) {
    TEMP_FAILURE_RETRY(close(fd));
    return -1;
  }

  if (TEMP_FAILURE_RETRY(listen(fd, backlog > 0 ? backlog : SOMAXCONN)) != 0) {
    TEMP_FAILURE_RETRY(close(fd));
    return -1;
  }

  Socket::SetNonBlocking(fd);
  return fd;
}


static bool IsTemporaryAcceptError(int error) {
  // On Android a number of protocol errors should be treated as EAGAIN.
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
    Socket::SetNonBlocking(socket);
  }
  return socket;
}


void Socket::Close(intptr_t fd) {
  ASSERT(fd >= 0);
  int err = TEMP_FAILURE_RETRY(close(fd));
  if (err != 0) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    Log::PrintErr("%s\n", error_message);
  }
}


bool Socket::SetNonBlocking(intptr_t fd) {
  return FDUtils::SetNonBlocking(fd);
}


bool Socket::SetBlocking(intptr_t fd) {
  return FDUtils::SetBlocking(fd);
}


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return TEMP_FAILURE_RETRY(setsockopt(fd,
                                       SOL_TCP,
                                       TCP_NODELAY,
                                       reinterpret_cast<char *>(&on),
                                       sizeof(on))) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
