// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/socket_base.h"

// TODO(ZX-766): If/when Fuchsia adds getifaddrs(), use that instead of the
// ioctl in netconfig.h.
#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <lib/netstack/c/netconfig.h>
#include <ifaddrs.h>      // NOLINT
#include <net/if.h>       // NOLINT
#include <netinet/tcp.h>  // NOLINT
#include <stdio.h>        // NOLINT
#include <stdlib.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/ioctl.h>    // NOLINT
#include <sys/stat.h>     // NOLINT
#include <unistd.h>       // NOLINT

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
  ASSERT(handle->fd() >= 0);
  intptr_t available = FDUtils::AvailableBytes(handle->fd());
  LOG_INFO("SocketBase::Available(%ld) = %ld\n", handle->fd(), available);
  return available;
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
  LOG_ERR("SocketBase::RecvFrom is unimplemented\n");
  UNIMPLEMENTED();
  return -1;
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
  LOG_ERR("SocketBase::SendTo is unimplemented\n");
  UNIMPLEMENTED();
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
  LOG_ERR("SocketBase::GetError is unimplemented\n");
  UNIMPLEMENTED();
}

int SocketBase::GetType(intptr_t fd) {
  LOG_ERR("SocketBase::GetType is unimplemented\n");
  UNIMPLEMENTED();
  return File::kOther;
}

intptr_t SocketBase::GetStdioHandle(intptr_t num) {
  LOG_ERR("SocketBase::GetStdioHandle is unimplemented\n");
  UNIMPLEMENTED();
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
  LOG_ERR("SocketBase::ReverseLookup is unimplemented\n");
  UNIMPLEMENTED();
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

static bool ShouldIncludeIfaAddrs(netc_if_info_t* if_info, int lookup_family) {
  const int family = if_info->addr.ss_family;
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
  // We need a dummy socket.
  const int fd = socket(AF_INET6, SOCK_STREAM, 0);
  if (fd < 0) {
    LOG_ERR("ListInterfaces: socket(AF_INET, SOCK_DGRAM, 0) failed\n");
    return NULL;
  }

  // Call the ioctl.
  netc_get_if_info_t get_if_info;
  const ssize_t size = ioctl_netc_get_if_info(fd, &get_if_info);
  if (size < 0) {
    LOG_ERR("ListInterfaces: ioctl_netc_get_if_info() failed");
    close(fd);
    return NULL;
  }

  // Process the results.
  const int lookup_family = SocketAddress::FromType(type);
  intptr_t count = 0;
  for (intptr_t i = 0; i < get_if_info.n_info; i++) {
    if (ShouldIncludeIfaAddrs(&get_if_info.info[i], lookup_family)) {
      count++;
    }
  }

  AddressList<InterfaceSocketAddress>* addresses =
      new AddressList<InterfaceSocketAddress>(count);
  int addresses_idx = 0;
  for (intptr_t i = 0; i < get_if_info.n_info; i++) {
    if (ShouldIncludeIfaAddrs(&get_if_info.info[i], lookup_family)) {
      char* ifa_name = DartUtils::ScopedCopyCString(get_if_info.info[i].name);
      InterfaceSocketAddress* isa = new InterfaceSocketAddress(
          reinterpret_cast<struct sockaddr*>(&get_if_info.info[i].addr),
          ifa_name, if_nametoindex(get_if_info.info[i].name));
      addresses->SetAt(addresses_idx, isa);
      addresses_idx++;
    }
  }
  close(fd);
  return addresses;
}

void SocketBase::Close(intptr_t fd) {
  IOHandle* handle = reinterpret_cast<IOHandle*>(fd);
  ASSERT(handle->fd() >= 0);
  NO_RETRY_EXPECTED(close(handle->fd()));
}

bool SocketBase::GetNoDelay(intptr_t fd, bool* enabled) {
  LOG_ERR("SocketBase::GetNoDelay is unimplemented\n");
  UNIMPLEMENTED();
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
  LOG_ERR("SocketBase::GetMulticastLoop is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::SetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool enabled) {
  LOG_ERR("SocketBase::SetMulticastLoop is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  LOG_ERR("SocketBase::GetMulticastHops is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  LOG_ERR("SocketBase::SetMulticastHops is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::GetBroadcast(intptr_t fd, bool* enabled) {
  LOG_ERR("SocketBase::GetBroadcast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::SetBroadcast(intptr_t fd, bool enabled) {
  LOG_ERR("SocketBase::SetBroadcast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::JoinMulticast(intptr_t fd,
                               const RawAddr& addr,
                               const RawAddr&,
                               int interfaceIndex) {
  LOG_ERR("SocketBase::JoinMulticast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

bool SocketBase::LeaveMulticast(intptr_t fd,
                                const RawAddr& addr,
                                const RawAddr&,
                                int interfaceIndex) {
  LOG_ERR("SocketBase::LeaveMulticast is unimplemented\n");
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
