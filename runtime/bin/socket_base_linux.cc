// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX)

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
#include "bin/socket_base_linux.h"
#include "bin/thread.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

void SocketBase::GetError(intptr_t fd, OSError* os_error) {
  int len = sizeof(errno);
  int err = 0;
  VOID_NO_RETRY_EXPECTED(getsockopt(fd, SOL_SOCKET, SO_ERROR, &err,
                                    reinterpret_cast<socklen_t*>(&len)));
  errno = err;
  os_error->SetCodeAndMessage(OSError::kSystem, errno);
}

int SocketBase::GetType(intptr_t fd) {
  struct stat64 buf;
  int result = TEMP_FAILURE_RETRY(fstat64(fd, &buf));
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
  struct addrinfo* info = nullptr;
  int status = NO_RETRY_EXPECTED(getaddrinfo(host, nullptr, &hints, &info));
  if (status != 0) {
    // We failed, try without AI_ADDRCONFIG. This can happen when looking up
    // e.g. '::1', when there are no global IPv6 addresses.
    hints.ai_flags = 0;
    status = NO_RETRY_EXPECTED(getaddrinfo(host, nullptr, &hints, &info));
    if (status != 0) {
      ASSERT(*os_error == nullptr);
      *os_error =
          new OSError(status, gai_strerror(status), OSError::kGetAddressInfo);
      return nullptr;
    }
  }
  intptr_t count = 0;
  for (struct addrinfo* c = info; c != nullptr; c = c->ai_next) {
    if ((c->ai_family == AF_INET) || (c->ai_family == AF_INET6)) {
      count++;
    }
  }
  intptr_t i = 0;
  AddressList<SocketAddress>* addresses = new AddressList<SocketAddress>(count);
  for (struct addrinfo* c = info; c != nullptr; c = c->ai_next) {
    if ((c->ai_family == AF_INET) || (c->ai_family == AF_INET6)) {
      addresses->SetAt(i, new SocketAddress(c->ai_addr));
      i++;
    }
  }
  freeaddrinfo(info);
  return addresses;
}

bool SocketBase::SetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool enabled) {
  int on = enabled ? 1 : 0;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_LOOP
                                                     : IPV6_MULTICAST_LOOP;
  return NO_RETRY_EXPECTED(setsockopt(
             fd, level, optname, reinterpret_cast<char*>(&on), sizeof(on))) ==
         0;
}

bool SocketBase::GetOption(intptr_t fd,
                           int level,
                           int option,
                           char* data,
                           unsigned int* length) {
  socklen_t optlen = static_cast<socklen_t>(*length);
  auto result = NO_RETRY_EXPECTED(getsockopt(fd, level, option, data, &optlen));
  *length = static_cast<unsigned int>(optlen);
  return result == 0;
}

bool SocketBase::JoinMulticast(intptr_t fd,
                               const RawAddr& addr,
                               const RawAddr&,
                               int interfaceIndex) {
  int proto = addr.addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr.ss, SocketAddress::GetAddrLength(addr));
  return NO_RETRY_EXPECTED(
             setsockopt(fd, proto, MCAST_JOIN_GROUP, &mreq, sizeof(mreq))) == 0;
}

bool SocketBase::LeaveMulticast(intptr_t fd,
                                const RawAddr& addr,
                                const RawAddr&,
                                int interfaceIndex) {
  int proto = addr.addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr.ss, SocketAddress::GetAddrLength(addr));
  return NO_RETRY_EXPECTED(setsockopt(fd, proto, MCAST_LEAVE_GROUP, &mreq,
                                      sizeof(mreq))) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_LINUX)
