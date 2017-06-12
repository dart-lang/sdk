// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/socket_base.h"

#include <errno.h>        // NOLINT
#include <ifaddrs.h>      // NOLINT
#include <net/if.h>       // NOLINT
#include <netinet/tcp.h>  // NOLINT
#include <stdio.h>        // NOLINT
#include <stdlib.h>       // NOLINT
#include <string.h>       // NOLINT
#include <sys/stat.h>     // NOLINT
#include <unistd.h>       // NOLINT

#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/socket_base_macos.h"
#include "platform/signal_blocker.h"

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
  // Nothing to do on Mac OS.
  return true;
}


bool SocketBase::FormatNumericAddress(const RawAddr& addr,
                                      char* address,
                                      int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  return (NO_RETRY_EXPECTED(getnameinfo(&addr.addr, salen, address, len, NULL,
                                        0, NI_NUMERICHOST)) == 0);
}


bool SocketBase::IsBindError(intptr_t error_number) {
  return error_number == EADDRINUSE || error_number == EADDRNOTAVAIL ||
         error_number == EINVAL;
}


intptr_t SocketBase::Available(intptr_t fd) {
  return FDUtils::AvailableBytes(fd);
}


intptr_t SocketBase::Read(intptr_t fd,
                          void* buffer,
                          intptr_t num_bytes,
                          SocketOpKind sync) {
  ASSERT(fd >= 0);
  ssize_t read_bytes = TEMP_FAILURE_RETRY(read(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (read_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  }
  return read_bytes;
}


intptr_t SocketBase::RecvFrom(intptr_t fd,
                              void* buffer,
                              intptr_t num_bytes,
                              RawAddr* addr,
                              SocketOpKind sync) {
  ASSERT(fd >= 0);
  socklen_t addr_len = sizeof(addr->ss);
  ssize_t read_bytes = TEMP_FAILURE_RETRY(
      recvfrom(fd, buffer, num_bytes, 0, &addr->addr, &addr_len));
  if ((sync == kAsync) && (read_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  }
  return read_bytes;
}


intptr_t SocketBase::Write(intptr_t fd,
                           const void* buffer,
                           intptr_t num_bytes,
                           SocketOpKind sync) {
  ASSERT(fd >= 0);
  ssize_t written_bytes = TEMP_FAILURE_RETRY(write(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (written_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  }
  return written_bytes;
}


intptr_t SocketBase::SendTo(intptr_t fd,
                            const void* buffer,
                            intptr_t num_bytes,
                            const RawAddr& addr,
                            SocketOpKind sync) {
  ASSERT(fd >= 0);
  ssize_t written_bytes =
      TEMP_FAILURE_RETRY(sendto(fd, buffer, num_bytes, 0, &addr.addr,
                                SocketAddress::GetAddrLength(addr)));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (written_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  }
  return written_bytes;
}


intptr_t SocketBase::GetPort(intptr_t fd) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getsockname(fd, &raw.addr, &size))) {
    return 0;
  }
  return SocketAddress::GetAddrPort(raw);
}


SocketAddress* SocketBase::GetRemotePeer(intptr_t fd, intptr_t* port) {
  ASSERT(fd >= 0);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getpeername(fd, &raw.addr, &size))) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(raw);
  return new SocketAddress(&raw.addr);
}


void SocketBase::GetError(intptr_t fd, OSError* os_error) {
  int len = sizeof(errno);
  getsockopt(fd, SOL_SOCKET, SO_ERROR, &errno,
             reinterpret_cast<socklen_t*>(&len));
  os_error->SetCodeAndMessage(OSError::kSystem, errno);
}


int SocketBase::GetType(intptr_t fd) {
  struct stat buf;
  int result = fstat(fd, &buf);
  if (result == -1) {
    return -1;
  }
  if (S_ISCHR(buf.st_mode)) {
    return File::kTerminal;
  }
  if (S_ISFIFO(buf.st_mode)) {
    return File::kPipe;
  }
  if (S_ISREG(buf.st_mode)) {
    return File::kFile;
  }
  return File::kOther;
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
  hints.ai_flags = 0;
  hints.ai_protocol = IPPROTO_TCP;
  struct addrinfo* info = NULL;
  int status = getaddrinfo(host, 0, &hints, &info);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error =
        new OSError(status, gai_strerror(status), OSError::kGetAddressInfo);
    return NULL;
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
  ASSERT(host_len >= NI_MAXHOST);
  int status = NO_RETRY_EXPECTED(
      getnameinfo(&addr.addr, SocketAddress::GetAddrLength(addr), host,
                  host_len, NULL, 0, NI_NAMEREQD));
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error =
        new OSError(status, gai_strerror(status), OSError::kGetAddressInfo);
    return false;
  }
  return true;
}


bool SocketBase::ParseAddress(int type, const char* address, RawAddr* addr) {
  int result;
  if (type == SocketAddress::TYPE_IPV4) {
    result = inet_pton(AF_INET, address, &addr->in.sin_addr);
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    result = inet_pton(AF_INET6, address, &addr->in6.sin6_addr);
  }
  return (result == 1);
}


static bool ShouldIncludeIfaAddrs(struct ifaddrs* ifa, int lookup_family) {
  if (ifa->ifa_addr == NULL) {
    // OpenVPN's virtual device tun0.
    return false;
  }
  int family = ifa->ifa_addr->sa_family;
  return ((lookup_family == family) ||
          ((lookup_family == AF_UNSPEC) &&
           ((family == AF_INET) || (family == AF_INET6))));
}


bool SocketBase::ListInterfacesSupported() {
  return true;
}


AddressList<InterfaceSocketAddress>* SocketBase::ListInterfaces(
    int type,
    OSError** os_error) {
  struct ifaddrs* ifaddr;

  int status = getifaddrs(&ifaddr);
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
  ASSERT(fd >= 0);
  VOID_TEMP_FAILURE_RETRY(close(fd));
}


bool SocketBase::GetNoDelay(intptr_t fd, bool* enabled) {
  int on;
  socklen_t len = sizeof(on);
  int err = NO_RETRY_EXPECTED(getsockopt(fd, IPPROTO_TCP, TCP_NODELAY,
                                         reinterpret_cast<void*>(&on), &len));
  if (err == 0) {
    *enabled = (on == 1);
  }
  return (err == 0);
}


bool SocketBase::SetNoDelay(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY,
                                      reinterpret_cast<char*>(&on),
                                      sizeof(on))) == 0;
}


bool SocketBase::GetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool* enabled) {
  uint8_t on;
  socklen_t len = sizeof(on);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_LOOP
                                                     : IPV6_MULTICAST_LOOP;
  if (NO_RETRY_EXPECTED(getsockopt(fd, level, optname,
                                   reinterpret_cast<char*>(&on), &len)) == 0) {
    *enabled = (on == 1);
    return true;
  }
  return false;
}


bool SocketBase::SetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool enabled) {
  u_int on = enabled ? 1 : 0;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_LOOP
                                                     : IPV6_MULTICAST_LOOP;
  return NO_RETRY_EXPECTED(setsockopt(
             fd, level, optname, reinterpret_cast<char*>(&on), sizeof(on))) ==
         0;
}


bool SocketBase::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  uint8_t v;
  socklen_t len = sizeof(v);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_TTL
                                                     : IPV6_MULTICAST_HOPS;
  if (NO_RETRY_EXPECTED(getsockopt(fd, level, optname,
                                   reinterpret_cast<char*>(&v), &len)) == 0) {
    *value = v;
    return true;
  }
  return false;
}


bool SocketBase::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  int v = value;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_TTL
                                                     : IPV6_MULTICAST_HOPS;
  return NO_RETRY_EXPECTED(setsockopt(
             fd, level, optname, reinterpret_cast<char*>(&v), sizeof(v))) == 0;
}


bool SocketBase::GetBroadcast(intptr_t fd, bool* enabled) {
  int on;
  socklen_t len = sizeof(on);
  int err = NO_RETRY_EXPECTED(getsockopt(fd, SOL_SOCKET, SO_BROADCAST,
                                         reinterpret_cast<char*>(&on), &len));
  if (err == 0) {
    *enabled = (on == 1);
  }
  return (err == 0);
}


bool SocketBase::SetBroadcast(intptr_t fd, bool enabled) {
  int on = enabled ? 1 : 0;
  return NO_RETRY_EXPECTED(setsockopt(fd, SOL_SOCKET, SO_BROADCAST,
                                      reinterpret_cast<char*>(&on),
                                      sizeof(on))) == 0;
}


static bool JoinOrLeaveMulticast(intptr_t fd,
                                 const RawAddr& addr,
                                 const RawAddr& interface,
                                 int interfaceIndex,
                                 bool join) {
  if (addr.addr.sa_family == AF_INET) {
    ASSERT(interface.addr.sa_family == AF_INET);
    struct ip_mreq mreq;
    memmove(&mreq.imr_multiaddr, &addr.in.sin_addr,
            SocketAddress::GetInAddrLength(addr));
    memmove(&mreq.imr_interface, &interface.in.sin_addr,
            SocketAddress::GetInAddrLength(interface));
    if (join) {
      return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_IP, IP_ADD_MEMBERSHIP,
                                          &mreq, sizeof(mreq))) == 0;
    } else {
      return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_IP, IP_DROP_MEMBERSHIP,
                                          &mreq, sizeof(mreq))) == 0;
    }
  } else {
    ASSERT(addr.addr.sa_family == AF_INET6);
    struct ipv6_mreq mreq;
    memmove(&mreq.ipv6mr_multiaddr, &addr.in6.sin6_addr,
            SocketAddress::GetInAddrLength(addr));
    mreq.ipv6mr_interface = interfaceIndex;
    if (join) {
      return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_IPV6, IPV6_JOIN_GROUP,
                                          &mreq, sizeof(mreq))) == 0;
    } else {
      return NO_RETRY_EXPECTED(setsockopt(fd, IPPROTO_IPV6, IPV6_LEAVE_GROUP,
                                          &mreq, sizeof(mreq))) == 0;
    }
  }
}

bool SocketBase::JoinMulticast(intptr_t fd,
                               const RawAddr& addr,
                               const RawAddr& interface,
                               int interfaceIndex) {
  return JoinOrLeaveMulticast(fd, addr, interface, interfaceIndex, true);
}


bool SocketBase::LeaveMulticast(intptr_t fd,
                                const RawAddr& addr,
                                const RawAddr& interface,
                                int interfaceIndex) {
  return JoinOrLeaveMulticast(fd, addr, interface, interfaceIndex, false);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_MACOS)

#endif  // !defined(DART_IO_DISABLED)
