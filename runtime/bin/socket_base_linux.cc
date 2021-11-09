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

SocketAddress::SocketAddress(struct sockaddr* sa, bool unnamed_unix_socket) {
  if (unnamed_unix_socket) {
    // This is an unnamed unix domain socket.
    as_string_[0] = 0;
  } else if (sa->sa_family == AF_UNIX) {
    struct sockaddr_un* un = ((struct sockaddr_un*)sa);
    memmove(as_string_, un->sun_path, sizeof(un->sun_path));
  } else {
    ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
    if (!SocketBase::FormatNumericAddress(*reinterpret_cast<RawAddr*>(sa),
                                          as_string_, INET6_ADDRSTRLEN)) {
      as_string_[0] = 0;
    }
  }
  socklen_t salen =
      GetAddrLength(*reinterpret_cast<RawAddr*>(sa), unnamed_unix_socket);
  memmove(reinterpret_cast<void*>(&addr_), sa, salen);
}

bool SocketBase::Initialize() {
  // Nothing to do on Linux.
  return true;
}

bool SocketBase::FormatNumericAddress(const RawAddr& addr,
                                      char* address,
                                      int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  return (NO_RETRY_EXPECTED(getnameinfo(&addr.addr, salen, address, len, NULL,
                                        0, NI_NUMERICHOST) == 0)) != 0;
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

bool SocketControlMessage::is_file_descriptors_control_message() {
  return level_ == SOL_SOCKET && type_ == SCM_RIGHTS;
}

// /proc/sys/net/core/optmem_max is corresponding kernel setting.
const size_t kMaxSocketMessageControlLength = 2048;

// if return value is positive or zero - it's number of messages read
// if it's negative - it's error code
intptr_t SocketBase::ReceiveMessage(intptr_t fd,
                                    void* buffer,
                                    int64_t* p_buffer_num_bytes,
                                    SocketControlMessage** p_messages,
                                    SocketOpKind sync,
                                    OSError* p_oserror) {
  ASSERT(fd >= 0);
  ASSERT(p_messages != nullptr);
  ASSERT(p_buffer_num_bytes != nullptr);

  struct iovec iov[1];
  memset(iov, 0, sizeof(iov));
  iov[0].iov_base = buffer;
  iov[0].iov_len = *p_buffer_num_bytes;

  struct msghdr msg;
  memset(&msg, 0, sizeof(msg));
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;  // number of elements in iov
  uint8_t control_buffer[kMaxSocketMessageControlLength];
  msg.msg_control = control_buffer;
  msg.msg_controllen = sizeof(control_buffer);

  ssize_t read_bytes = TEMP_FAILURE_RETRY(recvmsg(fd, &msg, MSG_CMSG_CLOEXEC));
  if ((sync == kAsync) && (read_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes read.
    return 0;
  }
  if (read_bytes < 0) {
    p_oserror->Reload();
    return read_bytes;
  }
  *p_buffer_num_bytes = read_bytes;

  struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
  size_t num_messages = 0;
  while (cmsg != nullptr) {
    num_messages++;
    cmsg = CMSG_NXTHDR(&msg, cmsg);
  }
  (*p_messages) = reinterpret_cast<SocketControlMessage*>(
      Dart_ScopeAllocate(sizeof(SocketControlMessage) * num_messages));
  SocketControlMessage* control_message = *p_messages;
  for (cmsg = CMSG_FIRSTHDR(&msg); cmsg != nullptr;
       cmsg = CMSG_NXTHDR(&msg, cmsg), control_message++) {
    void* data = CMSG_DATA(cmsg);
    size_t data_length = cmsg->cmsg_len - (reinterpret_cast<uint8_t*>(data) -
                                           reinterpret_cast<uint8_t*>(cmsg));
    void* copied_data = Dart_ScopeAllocate(data_length);
    ASSERT(copied_data != nullptr);
    memmove(copied_data, data, data_length);
    ASSERT(cmsg->cmsg_level == SOL_SOCKET);
    ASSERT(cmsg->cmsg_type == SCM_RIGHTS);
    new (control_message) SocketControlMessage(
        cmsg->cmsg_level, cmsg->cmsg_type, copied_data, data_length);
  }
  return num_messages;
}

bool SocketBase::AvailableDatagram(intptr_t fd,
                                   void* buffer,
                                   intptr_t num_bytes) {
  ASSERT(fd >= 0);
  ssize_t read_bytes =
      TEMP_FAILURE_RETRY(recvfrom(fd, buffer, num_bytes, MSG_PEEK, NULL, NULL));
  return read_bytes >= 0;
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

intptr_t SocketBase::SendMessage(intptr_t fd,
                                 void* buffer,
                                 size_t num_bytes,
                                 SocketControlMessage* messages,
                                 intptr_t num_messages,
                                 SocketOpKind sync,
                                 OSError* p_oserror) {
  ASSERT(fd >= 0);

  struct iovec iov = {
      .iov_base = buffer,
      .iov_len = num_bytes,
  };

  struct msghdr msg;
  memset(&msg, 0, sizeof(msg));
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;

  if (messages != nullptr && num_messages > 0) {
    SocketControlMessage* message = messages;
    size_t total_length = 0;
    for (intptr_t i = 0; i < num_messages; i++, message++) {
      total_length += CMSG_SPACE(message->data_length());
    }

    uint8_t* control_buffer =
        reinterpret_cast<uint8_t*>(Dart_ScopeAllocate(total_length));
    memset(control_buffer, 0, total_length);
    msg.msg_control = control_buffer;
    msg.msg_controllen = total_length;

    struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    message = messages;
    for (intptr_t i = 0; i < num_messages;
         i++, message++, cmsg = CMSG_NXTHDR(&msg, cmsg)) {
      ASSERT(message->is_file_descriptors_control_message());
      cmsg->cmsg_level = SOL_SOCKET;
      cmsg->cmsg_type = SCM_RIGHTS;

      intptr_t data_length = message->data_length();
      cmsg->cmsg_len = CMSG_LEN(data_length);
      memmove(CMSG_DATA(cmsg), message->data(), data_length);
    }
    msg.msg_controllen = total_length;
  }

  ssize_t written_bytes = TEMP_FAILURE_RETRY(sendmsg(fd, &msg, 0));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if ((sync == kAsync) && (written_bytes == -1) && (errno == EWOULDBLOCK)) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  }
  if (written_bytes < 0) {
    p_oserror->Reload();
  }

  return written_bytes;
}

bool SocketBase::GetSocketName(intptr_t fd, SocketAddress* p_sa) {
  ASSERT(fd >= 0);
  ASSERT(p_sa != nullptr);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (NO_RETRY_EXPECTED(getsockname(fd, &raw.addr, &size))) {
    return false;
  }

  // sockaddr_un contains sa_family_t sun_family and char[] sun_path.
  // If size is the size of sa_family_t, this is an unnamed socket and
  // sun_path contains garbage.
  new (p_sa) SocketAddress(&raw.addr,
                           /*unnamed_unix_socket=*/size == sizeof(sa_family_t));
  return true;
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
  // sockaddr_un contains sa_family_t sun_family and char[] sun_path.
  // If size is the size of sa_family_t, this is an unnamed socket and
  // sun_path contains garbage.
  if (size == sizeof(sa_family_t)) {
    *port = 0;
    return new SocketAddress(&raw.addr, /*unnamed_unix_socket=*/true);
  }
  *port = SocketAddress::GetAddrPort(raw);
  return new SocketAddress(&raw.addr);
}

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
  int status = NO_RETRY_EXPECTED(getaddrinfo(host, 0, &hints, &info));
  if (status != 0) {
    // We failed, try without AI_ADDRCONFIG. This can happen when looking up
    // e.g. '::1', when there are no global IPv6 addresses.
    hints.ai_flags = 0;
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
  ASSERT(fd >= 0);
  close(fd);
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
  int on = enabled ? 1 : 0;
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

bool SocketBase::SetOption(intptr_t fd,
                           int level,
                           int option,
                           const char* data,
                           int length) {
  return NO_RETRY_EXPECTED(setsockopt(fd, level, option, data, length)) == 0;
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
