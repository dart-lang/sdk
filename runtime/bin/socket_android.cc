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

#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/socket.h"

#include "platform/signal_blocker.h"


namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sa) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  if (!Socket::FormatNumericAddress(
          reinterpret_cast<RawAddr*>(sa), as_string_, INET6_ADDRSTRLEN)) {
    as_string_[0] = 0;
  }
  socklen_t salen = GetAddrLength(reinterpret_cast<RawAddr*>(sa));
  memmove(reinterpret_cast<void *>(&addr_), sa, salen);
}


bool Socket::FormatNumericAddress(RawAddr* addr, char* address, int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  if (NO_RETRY_EXPECTED(getnameinfo(&addr->addr,
                                    salen,
                                    address,
                                    len,
                                    NULL,
                                    0,
                                    NI_NUMERICHOST)) != 0) {
    return false;
  }
  return true;
}


bool Socket::Initialize() {
  // Nothing to do on Android.
  return true;
}


intptr_t Socket::Create(RawAddr addr) {
  intptr_t fd;
  fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    Log::PrintErr("Error Create: %s\n", error_message);
    return -1;
  }

  FDUtils::SetCloseOnExec(fd);
  return fd;
}


intptr_t Socket::Connect(intptr_t fd, RawAddr addr, const intptr_t port) {
  SocketAddress::SetAddrPort(&addr, port);
  intptr_t result = TEMP_FAILURE_RETRY(
      connect(fd, &addr.addr, SocketAddress::GetAddrLength(&addr)));
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


intptr_t Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
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


intptr_t Socket::RecvFrom(intptr_t fd, void* buffer, intptr_t num_bytes,
                     RawAddr* addr) {
  ASSERT(fd >= 0);
  socklen_t addr_len = sizeof(addr->ss);
  ssize_t read_bytes = TEMP_FAILURE_RETRY(
      recvfrom(fd, buffer, num_bytes, 0, &addr->addr, &addr_len));
  if (read_bytes == -1 && errno == EWOULDBLOCK) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  }
  return read_bytes;
}


intptr_t Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
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


intptr_t Socket::SendTo(intptr_t fd, const void* buffer, intptr_t num_bytes,
                   RawAddr addr) {
  ASSERT(fd >= 0);
  ssize_t written_bytes = TEMP_FAILURE_RETRY(
      sendto(fd, buffer, num_bytes, 0,
             &addr.addr, SocketAddress::GetAddrLength(&addr)));
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
  if (NO_RETRY_EXPECTED(getsockname(fd, &raw.addr, &size))) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    Log::PrintErr("Error getsockname: %s\n", error_message);
    return 0;
  }
  return SocketAddress::GetAddrPort(&raw);
}


SocketAddress* Socket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getpeername(fd, &raw.addr, &size))) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(&raw);
  return new SocketAddress(&raw.addr);
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


intptr_t Socket::GetStdioHandle(intptr_t num) {
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
  int status = getaddrinfo(host, 0, &hints, &info);
  if (status != 0) {
    // We failed, try without AI_ADDRCONFIG. This can happen when looking up
    // e.g. '::1', when there are no IPv6 addresses.
    hints.ai_flags = 0;
    status = getaddrinfo(host, 0, &hints, &info);
    if (status != 0) {
      ASSERT(*os_error == NULL);
      *os_error = new OSError(status,
                              gai_strerror(status),
                              OSError::kGetAddressInfo);
      return NULL;
    }
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
  int status = NO_RETRY_EXPECTED(getnameinfo(
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


bool Socket::ParseAddress(int type, const char* address, RawAddr* addr) {
  int result;
  if (type == SocketAddress::TYPE_IPV4) {
    result = inet_pton(AF_INET, address, &addr->in.sin_addr);
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    result = inet_pton(AF_INET6, address, &addr->in6.sin6_addr);
  }
  return result == 1;
}


intptr_t Socket::CreateBindDatagram(
    RawAddr* addr, intptr_t port, bool reuseAddress) {
  intptr_t fd;

  fd = NO_RETRY_EXPECTED(socket(addr->addr.sa_family, SOCK_DGRAM, IPPROTO_UDP));
  if (fd < 0) return -1;

  FDUtils::SetCloseOnExec(fd);

  if (reuseAddress) {
    int optval = 1;
    VOID_NO_RETRY_EXPECTED(
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));
  }

  SocketAddress::SetAddrPort(addr, port);
  if (NO_RETRY_EXPECTED(
          bind(fd,
               &addr->addr,
               SocketAddress::GetAddrLength(addr))) < 0) {
    VOID_TEMP_FAILURE_RETRY(close(fd));
    return -1;
  }

  Socket::SetNonBlocking(fd);
  return fd;
}


AddressList<InterfaceSocketAddress>* Socket::ListInterfaces(
    int type,
    OSError** os_error) {
  // The ifaddrs.h header is not provided on Android.  An Android
  // implementation would have to use IOCTL or netlink.
  return NULL;
}


intptr_t ServerSocket::CreateBindListen(RawAddr addr,
                                        intptr_t port,
                                        intptr_t backlog,
                                        bool v6_only) {
  intptr_t fd;

  fd = NO_RETRY_EXPECTED(socket(addr.ss.ss_family, SOCK_STREAM, 0));
  if (fd < 0) return -1;

  FDUtils::SetCloseOnExec(fd);

  int optval = 1;
  VOID_NO_RETRY_EXPECTED(
      setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only ? 1 : 0;
    VOID_NO_RETRY_EXPECTED(
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &optval, sizeof(optval)));
  }

  SocketAddress::SetAddrPort(&addr, port);
  if (NO_RETRY_EXPECTED(
          bind(fd,
               &addr.addr,
               SocketAddress::GetAddrLength(&addr))) < 0) {
    VOID_TEMP_FAILURE_RETRY(close(fd));
    return -1;
  }

  // Test for invalid socket port 65535 (some browsers disallow it).
  if (port == 0 && Socket::GetPort(fd) == 65535) {
    // Don't close the socket until we have created a new socket, ensuring
    // that we do not get the bad port number again.
    intptr_t new_fd = CreateBindListen(addr, 0, backlog, v6_only);
    int err = errno;
    VOID_TEMP_FAILURE_RETRY(close(fd));
    errno = err;
    return new_fd;
  }

  if (NO_RETRY_EXPECTED(listen(fd, backlog > 0 ? backlog : SOMAXCONN)) != 0) {
    VOID_TEMP_FAILURE_RETRY(close(fd));
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


bool Socket::GetNoDelay(intptr_t fd, bool* enabled) {
  int on;
  socklen_t len = sizeof(on);
  int err = NO_RETRY_EXPECTED(getsockopt(fd,
                                         IPPROTO_TCP,
                                         TCP_NODELAY,
                                         reinterpret_cast<void *>(&on),
                                         &len));
  if (err == 0) {
    *enabled = on == 1;
  }
  return err == 0;
}


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(fd,
                                      IPPROTO_TCP,
                                      TCP_NODELAY,
                                      reinterpret_cast<char *>(&on),
                                      sizeof(on))) == 0;
}


bool Socket::GetMulticastLoop(intptr_t fd, intptr_t protocol, bool* enabled) {
  uint8_t on;
  socklen_t len = sizeof(on);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_LOOP : IPV6_MULTICAST_LOOP;
  if (NO_RETRY_EXPECTED(getsockopt(fd,
                                   level,
                                   optname,
                                   reinterpret_cast<char *>(&on),
                                   &len)) == 0) {
    *enabled = (on == 1);
    return true;
  }
  return false;
}


bool Socket::SetMulticastLoop(intptr_t fd, intptr_t protocol, bool enabled) {
  int on = enabled ? 1 : 0;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_LOOP : IPV6_MULTICAST_LOOP;
  return NO_RETRY_EXPECTED(setsockopt(fd,
                                      level,
                                      optname,
                                      reinterpret_cast<char *>(&on),
                                      sizeof(on))) == 0;
}

bool Socket::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  uint8_t v;
  socklen_t len = sizeof(v);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_TTL : IPV6_MULTICAST_HOPS;
  if (NO_RETRY_EXPECTED(getsockopt(fd,
                                   level,
                                   optname,
                                   reinterpret_cast<char *>(&v),
                                   &len)) == 0) {
    *value = v;
    return true;
  }
  return false;
}


bool Socket::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  int v = value;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_TTL : IPV6_MULTICAST_HOPS;
  return NO_RETRY_EXPECTED(setsockopt(fd,
                                      level,
                                      optname,
                                      reinterpret_cast<char *>(&v),
                                      sizeof(v))) == 0;
}


bool Socket::GetBroadcast(intptr_t fd, bool* enabled) {
  int on;
  socklen_t len = sizeof(on);
  int err = NO_RETRY_EXPECTED(getsockopt(fd,
                                         SOL_SOCKET,
                                         SO_BROADCAST,
                                         reinterpret_cast<char *>(&on),
                                         &len));
  if (err == 0) {
    *enabled = on == 1;
  }
  return err == 0;
}


bool Socket::SetBroadcast(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(fd,
                                      SOL_SOCKET,
                                      SO_BROADCAST,
                                      reinterpret_cast<char *>(&on),
                                      sizeof(on))) == 0;
}


bool Socket::JoinMulticast(
    intptr_t fd, RawAddr* addr, RawAddr*, int interfaceIndex) {
  int proto = addr->addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr->ss, SocketAddress::GetAddrLength(addr));
  return NO_RETRY_EXPECTED(setsockopt(
      fd, proto, MCAST_JOIN_GROUP, &mreq, sizeof(mreq))) == 0;
}


bool Socket::LeaveMulticast(
    intptr_t fd, RawAddr* addr, RawAddr*, int interfaceIndex) {
  int proto = addr->addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr->ss, SocketAddress::GetAddrLength(addr));
  return NO_RETRY_EXPECTED(setsockopt(
      fd, proto, MCAST_LEAVE_GROUP, &mreq, sizeof(mreq))) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
