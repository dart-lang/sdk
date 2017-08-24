// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/socket_base.h"

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket_base_win.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sockaddr) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  RawAddr* raw = reinterpret_cast<RawAddr*>(sockaddr);

  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  int err =
      SocketBase::FormatNumericAddress(*raw, as_string_, INET6_ADDRSTRLEN);

  if (err != 0) {
    as_string_[0] = 0;
  }
  memmove(reinterpret_cast<void*>(&addr_), sockaddr,
          SocketAddress::GetAddrLength(*raw));
}

static Mutex* init_mutex = new Mutex();
static bool socket_initialized = false;

bool SocketBase::Initialize() {
  MutexLocker lock(init_mutex);
  if (socket_initialized) {
    return true;
  }
  int err;
  WSADATA winsock_data;
  WORD version_requested = MAKEWORD(2, 2);
  err = WSAStartup(version_requested, &winsock_data);
  if (err == 0) {
    socket_initialized = true;
  } else {
    Log::PrintErr("Unable to initialize Winsock: %d\n", WSAGetLastError());
  }
  return (err == 0);
}

bool SocketBase::FormatNumericAddress(const RawAddr& addr,
                                      char* address,
                                      int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  DWORD l = len;
  RawAddr& raw = const_cast<RawAddr&>(addr);
  return WSAAddressToStringA(&raw.addr, salen, NULL, address, &l) != 0;
}

intptr_t SocketBase::Available(intptr_t fd) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(fd);
  return client_socket->Available();
}

intptr_t SocketBase::Read(intptr_t fd,
                          void* buffer,
                          intptr_t num_bytes,
                          SocketOpKind sync) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->Read(buffer, num_bytes);
}

intptr_t SocketBase::RecvFrom(intptr_t fd,
                              void* buffer,
                              intptr_t num_bytes,
                              RawAddr* addr,
                              SocketOpKind sync) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  socklen_t addr_len = sizeof(addr->ss);
  return handle->RecvFrom(buffer, num_bytes, &addr->addr, addr_len);
}

intptr_t SocketBase::Write(intptr_t fd,
                           const void* buffer,
                           intptr_t num_bytes,
                           SocketOpKind sync) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->Write(buffer, num_bytes);
}

intptr_t SocketBase::SendTo(intptr_t fd,
                            const void* buffer,
                            intptr_t num_bytes,
                            const RawAddr& addr,
                            SocketOpKind sync) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  RawAddr& raw = const_cast<RawAddr&>(addr);
  return handle->SendTo(buffer, num_bytes, &raw.addr,
                        SocketAddress::GetAddrLength(addr));
}

intptr_t SocketBase::GetPort(intptr_t fd) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getsockname(socket_handle->socket(), &raw.addr, &size) == SOCKET_ERROR) {
    return 0;
  }
  return SocketAddress::GetAddrPort(raw);
}

SocketAddress* SocketBase::GetRemotePeer(intptr_t fd, intptr_t* port) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getpeername(socket_handle->socket(), &raw.addr, &size)) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(raw);
  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  SocketAddress::SetAddrPort(&raw, 0);
  return new SocketAddress(&raw.addr);
}

bool SocketBase::IsBindError(intptr_t error_number) {
  return error_number == WSAEADDRINUSE || error_number == WSAEADDRNOTAVAIL ||
         error_number == WSAEINVAL;
}

void SocketBase::GetError(intptr_t fd, OSError* os_error) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  os_error->SetCodeAndMessage(OSError::kSystem, handle->last_error());
}

int SocketBase::GetType(intptr_t fd) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  switch (GetFileType(handle->handle())) {
    case FILE_TYPE_CHAR:
      return File::kTerminal;
    case FILE_TYPE_PIPE:
      return File::kPipe;
    case FILE_TYPE_DISK:
      return File::kFile;
    default:
      return GetLastError == NO_ERROR ? File::kOther : -1;
  }
}

intptr_t SocketBase::GetStdioHandle(intptr_t num) {
  if (num != 0) {
    return -1;
  }
  HANDLE handle = GetStdHandle(STD_INPUT_HANDLE);
  if (handle == INVALID_HANDLE_VALUE) {
    return -1;
  }
  StdHandle* std_handle = StdHandle::Stdin(handle);
  std_handle->Retain();
  std_handle->MarkDoesNotSupportOverlappedIO();
  std_handle->EnsureInitialized(EventHandler::delegate());
  return reinterpret_cast<intptr_t>(std_handle);
}

AddressList<SocketAddress>* SocketBase::LookupAddress(const char* host,
                                                      int type,
                                                      OSError** os_error) {
  Initialize();

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
    // e.g. '::1', when there are no global IPv6 addresses.
    hints.ai_flags = 0;
    status = getaddrinfo(host, 0, &hints, &info);
  }
  if (status != 0) {
    ASSERT(*os_error == NULL);
    DWORD error_code = WSAGetLastError();
    SetLastError(error_code);
    *os_error = new OSError();
    return NULL;
  }
  intptr_t count = 0;
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if ((c->ai_family == AF_INET) || (c->ai_family == AF_INET6)) {
      count++;
    }
  }
  AddressList<SocketAddress>* addresses = new AddressList<SocketAddress>(count);
  intptr_t i = 0;
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
  int status = getnameinfo(&addr.addr, SocketAddress::GetAddrLength(addr), host,
                           host_len, NULL, 0, NI_NAMEREQD);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    DWORD error_code = WSAGetLastError();
    SetLastError(error_code);
    *os_error = new OSError();
    return false;
  }
  return true;
}

bool SocketBase::ParseAddress(int type, const char* address, RawAddr* addr) {
  int result;
  Utf8ToWideScope system_address(address);
  if (type == SocketAddress::TYPE_IPV4) {
    result = InetPton(AF_INET, system_address.wide(), &addr->in.sin_addr);
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    result = InetPton(AF_INET6, system_address.wide(), &addr->in6.sin6_addr);
  }
  return result == 1;
}

bool SocketBase::ListInterfacesSupported() {
  return true;
}

AddressList<InterfaceSocketAddress>* SocketBase::ListInterfaces(
    int type,
    OSError** os_error) {
  Initialize();

  ULONG size = 0;
  DWORD flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                GAA_FLAG_SKIP_DNS_SERVER;
  // Query the size needed.
  int status = GetAdaptersAddresses(SocketAddress::FromType(type), flags, NULL,
                                    NULL, &size);
  IP_ADAPTER_ADDRESSES* addrs = NULL;
  if (status == ERROR_BUFFER_OVERFLOW) {
    addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(malloc(size));
    // Get the addresses now we have the right buffer.
    status = GetAdaptersAddresses(SocketAddress::FromType(type), flags, NULL,
                                  addrs, &size);
  }
  if (status != NO_ERROR) {
    ASSERT(*os_error == NULL);
    DWORD error_code = WSAGetLastError();
    SetLastError(error_code);
    *os_error = new OSError();
    return NULL;
  }
  intptr_t count = 0;
  for (IP_ADAPTER_ADDRESSES* a = addrs; a != NULL; a = a->Next) {
    for (IP_ADAPTER_UNICAST_ADDRESS* u = a->FirstUnicastAddress; u != NULL;
         u = u->Next) {
      count++;
    }
  }
  AddressList<InterfaceSocketAddress>* addresses =
      new AddressList<InterfaceSocketAddress>(count);
  intptr_t i = 0;
  for (IP_ADAPTER_ADDRESSES* a = addrs; a != NULL; a = a->Next) {
    for (IP_ADAPTER_UNICAST_ADDRESS* u = a->FirstUnicastAddress; u != NULL;
         u = u->Next) {
      addresses->SetAt(
          i, new InterfaceSocketAddress(
                 u->Address.lpSockaddr,
                 StringUtilsWin::WideToUtf8(a->FriendlyName), a->Ipv6IfIndex));
      i++;
    }
  }
  free(addrs);
  return addresses;
}

void SocketBase::Close(intptr_t fd) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(fd);
  client_socket->Close();
}

bool SocketBase::GetNoDelay(intptr_t fd, bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on;
  socklen_t len = sizeof(on);
  int err = getsockopt(handle->socket(), IPPROTO_TCP, TCP_NODELAY,
                       reinterpret_cast<char*>(&on), &len);
  if (err == 0) {
    *enabled = (on == 1);
  }
  return (err == 0);
}

bool SocketBase::SetNoDelay(intptr_t fd, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  return setsockopt(handle->socket(), IPPROTO_TCP, TCP_NODELAY,
                    reinterpret_cast<char*>(&on), sizeof(on)) == 0;
}

bool SocketBase::GetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  uint8_t on;
  socklen_t len = sizeof(on);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_LOOP
                                                     : IPV6_MULTICAST_LOOP;
  if (getsockopt(handle->socket(), level, optname, reinterpret_cast<char*>(&on),
                 &len) == 0) {
    *enabled = (on == 1);
    return true;
  }
  return false;
}

bool SocketBase::SetMulticastLoop(intptr_t fd,
                                  intptr_t protocol,
                                  bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_LOOP
                                                     : IPV6_MULTICAST_LOOP;
  return setsockopt(handle->socket(), level, optname,
                    reinterpret_cast<char*>(&on), sizeof(on)) == 0;
}

bool SocketBase::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  uint8_t v;
  socklen_t len = sizeof(v);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_TTL
                                                     : IPV6_MULTICAST_HOPS;
  if (getsockopt(handle->socket(), level, optname, reinterpret_cast<char*>(&v),
                 &len) == 0) {
    *value = v;
    return true;
  }
  return false;
}

bool SocketBase::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int v = value;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4 ? IP_MULTICAST_TTL
                                                     : IPV6_MULTICAST_HOPS;
  return setsockopt(handle->socket(), level, optname,
                    reinterpret_cast<char*>(&v), sizeof(v)) == 0;
}

bool SocketBase::GetBroadcast(intptr_t fd, bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on;
  socklen_t len = sizeof(on);
  int err = getsockopt(handle->socket(), SOL_SOCKET, SO_BROADCAST,
                       reinterpret_cast<char*>(&on), &len);
  if (err == 0) {
    *enabled = (on == 1);
  }
  return (err == 0);
}

bool SocketBase::SetBroadcast(intptr_t fd, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  return setsockopt(handle->socket(), SOL_SOCKET, SO_BROADCAST,
                    reinterpret_cast<char*>(&on), sizeof(on)) == 0;
}

bool SocketBase::JoinMulticast(intptr_t fd,
                               const RawAddr& addr,
                               const RawAddr&,
                               int interfaceIndex) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int proto = addr.addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr.ss, SocketAddress::GetAddrLength(addr));
  return setsockopt(handle->socket(), proto, MCAST_JOIN_GROUP,
                    reinterpret_cast<char*>(&mreq), sizeof(mreq)) == 0;
}

bool SocketBase::LeaveMulticast(intptr_t fd,
                                const RawAddr& addr,
                                const RawAddr&,
                                int interfaceIndex) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int proto = addr.addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr.ss, SocketAddress::GetAddrLength(addr));
  return setsockopt(handle->socket(), proto, MCAST_LEAVE_GROUP,
                    reinterpret_cast<char*>(&mreq), sizeof(mreq)) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
