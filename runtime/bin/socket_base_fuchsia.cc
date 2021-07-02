// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/socket_base.h"

#include <errno.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/tcp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/socket_base_fuchsia.h"
#include "platform/signal_blocker.h"

// #define SOCKET_LOG_INFO 1
// #define SOCKET_LOG_ERROR 1

// define SOCKET_LOG_ERROR to get log messages only for errors.
// define SOCKET_LOG_INFO to get log messages for both information and errors.
#if defined(SOCKET_LOG_INFO) || defined(SOCKET_LOG_ERROR)
#define LOG_ERR(msg, ...)                                                      \
  {                                                                            \
    int err = errno;                                                           \
    Syslog::PrintErr("Dart Socket ERROR: %s:%d: " msg, __FILE__, __LINE__,     \
                     ##__VA_ARGS__);                                           \
    errno = err;                                                               \
  }
#if defined(SOCKET_LOG_INFO)
#define LOG_INFO(msg, ...)                                                     \
  Syslog::Print("Dart Socket INFO: %s:%d: " msg, __FILE__, __LINE__,           \
                ##__VA_ARGS__)
#else
#define LOG_INFO(msg, ...)
#endif  // defined(SOCKET_LOG_INFO)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(SOCKET_LOG_INFO) || defined(SOCKET_LOG_ERROR)

namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sa, bool unnamed_unix_socket) {
  // Fuchsia does not support unix domain sockets.
  if (unnamed_unix_socket) {
    FATAL("Fuchsia does not support unix domain sockets.");
  }
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  if (!SocketBase::FormatNumericAddress(*reinterpret_cast<RawAddr*>(sa),
                                        as_string_, INET6_ADDRSTRLEN)) {
    as_string_[0] = 0;
  }
  socklen_t salen = GetAddrLength(*reinterpret_cast<RawAddr*>(sa));
  memmove(reinterpret_cast<void*>(&addr_), sa, salen);
}


bool SocketBase::Initialize() {
  // Nothing to do on Fuchsia.
  return true;
}

bool SocketBase::FormatNumericAddress(const RawAddr& addr,
                                      char* address,
                                      int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  LOG_INFO("SocketBase::FormatNumericAddress: calling getnameinfo\n");
  return (NO_RETRY_EXPECTED(getnameinfo(&addr.addr, salen, address, len, NULL,
                                        0, NI_NUMERICHOST) == 0));
}

bool SocketBase::IsBindError(intptr_t error_number) {
  return error_number == EADDRINUSE || error_number == EADDRNOTAVAIL ||
         error_number == EINVAL;
}

intptr_t SocketBase::Available(intptr_t fd) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  return handle->AvailableBytes();
}

intptr_t SocketBase::Read(intptr_t fd,
                          void* buffer,
                          intptr_t num_bytes,
                          SocketOpKind sync) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  LOG_INFO("SocketBase::Read: calling read(%ld, %p, %ld)\n", handle->fd(),
           buffer, num_bytes);
  intptr_t read_bytes = handle->Read(buffer, num_bytes);
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (read_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  } else if (read_bytes == -1) {
    LOG_ERR("SocketBase::Read: read(%ld, %p, %ld) failed\n", handle->fd(),
            buffer, num_bytes);
  } else {
    LOG_INFO("SocketBase::Read: read(%ld, %p, %ld) succeeded\n", handle->fd(),
             buffer, num_bytes);
  }
  return read_bytes;
}

intptr_t SocketBase::RecvFrom(intptr_t fd,
                              void* buffer,
                              intptr_t num_bytes,
                              RawAddr* addr,
                              SocketOpKind sync) {
  errno = ENOSYS;
  return -1;
}

bool SocketBase::AvailableDatagram(intptr_t fd,
                                   void* buffer,
                                   intptr_t num_bytes) {
  return false;
}

intptr_t SocketBase::Write(intptr_t fd,
                           const void* buffer,
                           intptr_t num_bytes,
                           SocketOpKind sync) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  LOG_INFO("SocketBase::Write: calling write(%ld, %p, %ld)\n", handle->fd(),
           buffer, num_bytes);
  intptr_t written_bytes = handle->Write(buffer, num_bytes);
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (written_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  } else if (written_bytes == -1) {
    LOG_ERR("SocketBase::Write: write(%ld, %p, %ld) failed\n", handle->fd(),
            buffer, num_bytes);
  } else {
    LOG_INFO("SocketBase::Write: write(%ld, %p, %ld) succeeded\n", handle->fd(),
             buffer, num_bytes);
  }
  return written_bytes;
}

intptr_t SocketBase::SendTo(intptr_t fd,
                            const void* buffer,
                            intptr_t num_bytes,
                            const RawAddr& addr,
                            SocketOpKind sync) {
  errno = ENOSYS;
  return -1;
}

intptr_t SocketBase::GetPort(intptr_t fd) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  LOG_INFO("SocketBase::GetPort: calling getsockname(%ld)\n", handle->fd());
  if (NO_RETRY_EXPECTED(getsockname(handle->fd(), &raw.addr, &size))) {
    return 0;
  }
  return SocketAddress::GetAddrPort(raw);
}

SocketAddress* SocketBase::GetRemotePeer(intptr_t fd, intptr_t* port) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getpeername(handle->fd(), &raw.addr, &size))) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(raw);
  return new SocketAddress(&raw.addr);
}

void SocketBase::GetError(intptr_t fd, OSError* os_error) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  int len = sizeof(errno);
  int err = 0;
  VOID_NO_RETRY_EXPECTED(getsockopt(handle->fd(), SOL_SOCKET, SO_ERROR, &err,
                                    reinterpret_cast<socklen_t*>(&len)));
  errno = err;
  os_error->SetCodeAndMessage(OSError::kSystem, errno);
}

int SocketBase::GetType(intptr_t fd) {
  errno = ENOSYS;
  return -1;
}

intptr_t SocketBase::GetStdioHandle(intptr_t num) {
  return num;
}

AddressList<SocketAddress>* SocketBase::LookupAddress(const char* host,
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
  LOG_INFO("SocketBase::LookupAddress: calling getaddrinfo\n");
  int status = NO_RETRY_EXPECTED(getaddrinfo(host, 0, &hints, &info));
  if (status != 0) {
    // We failed, try without AI_ADDRCONFIG. This can happen when looking up
    // e.g. '::1', when there are no global IPv6 addresses.
    hints.ai_flags = 0;
    LOG_INFO("SocketBase::LookupAddress: calling getaddrinfo again\n");
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

bool SocketBase::ReverseLookup(const RawAddr& addr,
                               char* host,
                               intptr_t host_len,
                               OSError** os_error) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::ParseAddress(int type, const char* address, RawAddr* addr) {
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

bool SocketBase::RawAddrToString(RawAddr* addr, char* str) {
  if (addr->addr.sa_family == AF_INET) {
    return inet_ntop(AF_INET, &addr->in.sin_addr, str, INET_ADDRSTRLEN) != NULL;
  } else {
    ASSERT(addr->addr.sa_family == AF_INET6);
    return inet_ntop(AF_INET6, &addr->in6.sin6_addr, str, INET6_ADDRSTRLEN) !=
           NULL;
  }
}

static bool ShouldIncludeIfaAddrs(struct ifaddrs* ifa, int lookup_family) {
  if (ifa->ifa_addr == NULL) {
    // OpenVPN's virtual device tun0.
    return false;
  }
  int family = ifa->ifa_addr->sa_family;
  return ((lookup_family == family) ||
          (((lookup_family == AF_UNSPEC) &&
            ((family == AF_INET) || (family == AF_INET6)))));
}

bool SocketBase::ListInterfacesSupported() {
  return true;
}

AddressList<InterfaceSocketAddress>* SocketBase::ListInterfaces(
    int type,
    OSError** os_error) {
  struct ifaddrs* ifaddr;

  int status = NO_RETRY_EXPECTED(getifaddrs(&ifaddr));
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error =
        new OSError(status, gai_strerror(status), OSError::kGetAddressInfo);
    return NULL;
  }

  int lookup_family = SocketAddress::FromType(type);

  intptr_t count = 0;
  for (struct ifaddrs* ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (ShouldIncludeIfaAddrs(ifa, lookup_family)) {
      count++;
    }
  }

  AddressList<InterfaceSocketAddress>* addresses =
      new AddressList<InterfaceSocketAddress>(count);
  int i = 0;
  for (struct ifaddrs* ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (ShouldIncludeIfaAddrs(ifa, lookup_family)) {
      char* ifa_name = DartUtils::ScopedCopyCString(ifa->ifa_name);
      addresses->SetAt(
          i, new InterfaceSocketAddress(ifa->ifa_addr, ifa_name,
                                        if_nametoindex(ifa->ifa_name)));
      i++;
    }
  }
  freeifaddrs(ifaddr);
  return addresses;
}

void SocketBase::Close(intptr_t fd) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  NO_RETRY_EXPECTED(close(handle->fd()));
}

bool SocketBase::GetNoDelay(intptr_t fd, bool* enabled) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::SetNoDelay(intptr_t fd, bool enabled) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(handle->fd(), IPPROTO_TCP, TCP_NODELAY,
                                      reinterpret_cast<char*>(&on),
                                      sizeof(on))) == 0;
}

bool SocketBase::GetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool* enabled) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::SetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool enabled) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::GetBroadcast(intptr_t fd, bool* enabled) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::SetBroadcast(intptr_t fd, bool enabled) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::SetOption(intptr_t fd,
                           int level,
                           int option,
                           const char* data,
                           int length) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  return NO_RETRY_EXPECTED(
             setsockopt(handle->fd(), level, option, data, length)) == 0;
}

bool SocketBase::GetOption(intptr_t fd,
                           int level,
                           int option,
                           char* data,
                           unsigned int* length) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  socklen_t optlen = static_cast<socklen_t>(*length);
  auto result =
      NO_RETRY_EXPECTED(getsockopt(handle->fd(), level, option, data, &optlen));
  *length = static_cast<unsigned int>(optlen);
  return result == 0;
}

bool SocketBase::JoinMulticast(intptr_t fd,
                               const RawAddr& addr,
                               const RawAddr&,
                               int interfaceIndex) {
  errno = ENOSYS;
  return false;
}

bool SocketBase::LeaveMulticast(intptr_t fd,
                                const RawAddr& addr,
                                const RawAddr&,
                                int interfaceIndex) {
  errno = ENOSYS;
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
