// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/utils.h"

#include "vm/thread.h"


namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct sockaddr* sockaddr) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  RawAddr* raw = reinterpret_cast<RawAddr*>(sockaddr);

  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  int err = Socket::FormatNumericAddress(raw, as_string_, INET6_ADDRSTRLEN);

  if (err != 0) {
    as_string_[0] = 0;
  }
  memmove(reinterpret_cast<void *>(&addr_),
          sockaddr,
          SocketAddress::GetAddrLength(raw));
}


bool Socket::FormatNumericAddress(RawAddr* addr, char* address, int len) {
  socklen_t salen = SocketAddress::GetAddrLength(addr);
  DWORD l = len;
  return WSAAddressToStringA(&addr->addr,
                                salen,
                                NULL,
                                address,
                                &l) != 0;
}


static Mutex* init_mutex = new Mutex();
static bool socket_initialized = false;

bool Socket::Initialize() {
  MutexLocker lock(init_mutex);
  if (socket_initialized) return true;
  int err;
  WSADATA winsock_data;
  WORD version_requested = MAKEWORD(2, 2);
  err = WSAStartup(version_requested, &winsock_data);
  if (err == 0) {
    socket_initialized = true;
  } else {
    Log::PrintErr("Unable to initialize Winsock: %d\n", WSAGetLastError());
  }
  return err == 0;
}

intptr_t Socket::Available(intptr_t fd) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(fd);
  return client_socket->Available();
}


intptr_t Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->Read(buffer, num_bytes);
}


intptr_t Socket::RecvFrom(intptr_t fd, void* buffer, intptr_t num_bytes,
                     RawAddr* addr) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  socklen_t addr_len = sizeof(addr->ss);
  return handle->RecvFrom(buffer, num_bytes, &addr->addr, addr_len);
}


intptr_t Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->Write(buffer, num_bytes);
}


intptr_t Socket::SendTo(
    intptr_t fd, const void* buffer, intptr_t num_bytes, RawAddr addr) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->SendTo(
    buffer, num_bytes, &addr.addr, SocketAddress::GetAddrLength(&addr));
}


intptr_t Socket::GetPort(intptr_t fd) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getsockname(socket_handle->socket(),
                  &raw.addr,
                  &size) == SOCKET_ERROR) {
    return 0;
  }
  return SocketAddress::GetAddrPort(&raw);
}


SocketAddress* Socket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getpeername(socket_handle->socket(),
                  &raw.addr,
                  &size)) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(&raw);
  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  SocketAddress::SetAddrPort(&raw, 0);
  return new SocketAddress(&raw.addr);
}


intptr_t Socket::Create(RawAddr addr) {
  SOCKET s = socket(addr.ss.ss_family, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  linger l;
  l.l_onoff = 1;
  l.l_linger = 10;
  int status = setsockopt(s,
                          SOL_SOCKET,
                          SO_LINGER,
                          reinterpret_cast<char*>(&l),
                          sizeof(l));
  if (status != NO_ERROR) {
    FATAL("Failed setting SO_LINGER on socket");
  }

  ClientSocket* client_socket = new ClientSocket(s);
  return reinterpret_cast<intptr_t>(client_socket);
}


intptr_t Socket::Connect(intptr_t fd, RawAddr addr, const intptr_t port) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_client_socket());
  ClientSocket* handle = reinterpret_cast<ClientSocket*>(fd);
  SOCKET s = handle->socket();

  RawAddr bind_addr;
  memset(&bind_addr, 0, sizeof(bind_addr));
  bind_addr.ss.ss_family = addr.ss.ss_family;
  if (addr.ss.ss_family == AF_INET) {
    bind_addr.in.sin_addr.s_addr = INADDR_ANY;
  } else {
    bind_addr.in6.sin6_addr = in6addr_any;
  }
  int status = bind(
      s, &bind_addr.addr, SocketAddress::GetAddrLength(&bind_addr));
  if (status != NO_ERROR) {
    int rc = WSAGetLastError();
    delete handle;
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  SocketAddress::SetAddrPort(&addr, port);

  LPFN_CONNECTEX connectEx = NULL;
  GUID guid_connect_ex = WSAID_CONNECTEX;
  DWORD bytes;
  status = WSAIoctl(s,
                    SIO_GET_EXTENSION_FUNCTION_POINTER,
                    &guid_connect_ex,
                    sizeof(guid_connect_ex),
                    &connectEx,
                    sizeof(connectEx),
                    &bytes,
                    NULL,
                    NULL);
  DWORD rc;
  if (status != SOCKET_ERROR) {
    handle->EnsureInitialized(EventHandler::delegate());

    OverlappedBuffer* overlapped = OverlappedBuffer::AllocateConnectBuffer();

    status = connectEx(s,
                       &addr.addr,
                       SocketAddress::GetAddrLength(&addr),
                       NULL,
                       0,
                       NULL,
                       overlapped->GetCleanOverlapped());


    if (status == TRUE) {
      handle->ConnectComplete(overlapped);
      return fd;
    } else if (WSAGetLastError() == ERROR_IO_PENDING) {
      return fd;
    }
    rc = WSAGetLastError();
    // Cleanup in case of error.
    OverlappedBuffer::DisposeBuffer(overlapped);
  } else {
    rc = WSAGetLastError();
  }
  handle->Close();
  delete handle;
  SetLastError(rc);
  return -1;
}


intptr_t Socket::CreateConnect(RawAddr addr, const intptr_t port) {
  intptr_t fd = Socket::Create(addr);
  if (fd < 0) {
    return fd;
  }

  return Socket::Connect(fd, addr, port);
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  os_error->SetCodeAndMessage(OSError::kSystem, handle->last_error());
}


int Socket::GetType(intptr_t fd) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  switch (GetFileType(handle->handle())) {
    case FILE_TYPE_CHAR: return File::kTerminal;
    case FILE_TYPE_PIPE: return File::kPipe;
    case FILE_TYPE_DISK: return File::kFile;
    default: return GetLastError == NO_ERROR ? File::kOther : -1;
  }
}


intptr_t Socket::GetStdioHandle(intptr_t num) {
  if (num != 0) return -1;
  HANDLE handle = GetStdHandle(STD_INPUT_HANDLE);
  if (handle == INVALID_HANDLE_VALUE) {
    return -1;
  }
  StdHandle* std_handle = new StdHandle(handle);
  std_handle->MarkDoesNotSupportOverlappedIO();
  std_handle->EnsureInitialized(EventHandler::delegate());
  return reinterpret_cast<intptr_t>(std_handle);
}


intptr_t ServerSocket::Accept(intptr_t fd) {
  ListenSocket* listen_socket = reinterpret_cast<ListenSocket*>(fd);
  ClientSocket* client_socket = listen_socket->Accept();
  if (client_socket != NULL) {
    return reinterpret_cast<intptr_t>(client_socket);
  } else {
    return -1;
  }
}


AddressList<SocketAddress>* Socket::LookupAddress(const char* host,
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
    if (c->ai_family == AF_INET || c->ai_family == AF_INET6) count++;
  }
  AddressList<SocketAddress>* addresses = new AddressList<SocketAddress>(count);
  intptr_t i = 0;
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
  int status = getnameinfo(&addr.addr,
                           SocketAddress::GetAddrLength(&addr),
                           host,
                           host_len,
                           NULL,
                           0,
                           NI_NAMEREQD);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    DWORD error_code = WSAGetLastError();
    SetLastError(error_code);
    *os_error = new OSError();
    return false;
  }
  return true;
}


bool Socket::ParseAddress(int type, const char* address, RawAddr* addr) {
  int result;
  const wchar_t* system_address = StringUtils::Utf8ToWide(address);
  if (type == SocketAddress::TYPE_IPV4) {
    result = InetPton(AF_INET, system_address, &addr->in.sin_addr);
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    result = InetPton(AF_INET6, system_address, &addr->in6.sin6_addr);
  }
  free(const_cast<wchar_t*>(system_address));
  return result == 1;
}


intptr_t Socket::CreateBindDatagram(
    RawAddr* addr, intptr_t port, bool reuseAddress) {
  SOCKET s = socket(addr->ss.ss_family, SOCK_DGRAM, IPPROTO_UDP);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  int status;
  if (reuseAddress) {
    BOOL optval = true;
    status = setsockopt(s,
                        SOL_SOCKET,
                        SO_REUSEADDR,
                        reinterpret_cast<const char*>(&optval),
                        sizeof(optval));
    if (status == SOCKET_ERROR) {
      DWORD rc = WSAGetLastError();
      closesocket(s);
      SetLastError(rc);
      return -1;
    }
  }

  SocketAddress::SetAddrPort(addr, port);

  status = bind(s,
                &addr->addr,
                SocketAddress::GetAddrLength(addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  DatagramSocket* datagram_socket = new DatagramSocket(s);
  datagram_socket->EnsureInitialized(EventHandler::delegate());
  return reinterpret_cast<intptr_t>(datagram_socket);
}


AddressList<InterfaceSocketAddress>* Socket::ListInterfaces(
    int type,
    OSError** os_error) {
  Initialize();

  ULONG size = 0;
  DWORD flags = GAA_FLAG_SKIP_ANYCAST |
                GAA_FLAG_SKIP_MULTICAST |
                GAA_FLAG_SKIP_DNS_SERVER;
  // Query the size needed.
  int status = GetAdaptersAddresses(SocketAddress::FromType(type),
                                    flags,
                                    NULL,
                                    NULL,
                                    &size);
  IP_ADAPTER_ADDRESSES* addrs = NULL;
  if (status == ERROR_BUFFER_OVERFLOW) {
    addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(malloc(size));
    // Get the addresses now we have the right buffer.
    status = GetAdaptersAddresses(SocketAddress::FromType(type),
                                  flags,
                                  NULL,
                                  addrs,
                                  &size);
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
    for (IP_ADAPTER_UNICAST_ADDRESS* u = a->FirstUnicastAddress;
         u != NULL; u = u->Next) {
      count++;
    }
  }
  AddressList<InterfaceSocketAddress>* addresses =
      new AddressList<InterfaceSocketAddress>(count);
  intptr_t i = 0;
  for (IP_ADAPTER_ADDRESSES* a = addrs; a != NULL; a = a->Next) {
    for (IP_ADAPTER_UNICAST_ADDRESS* u = a->FirstUnicastAddress;
         u != NULL; u = u->Next) {
      addresses->SetAt(i, new InterfaceSocketAddress(
          u->Address.lpSockaddr,
          StringUtils::WideToUtf8(a->FriendlyName),
          a->Ipv6IfIndex));
      i++;
    }
  }
  free(addrs);
  return addresses;
}


intptr_t ServerSocket::CreateBindListen(RawAddr addr,
                                        intptr_t port,
                                        intptr_t backlog,
                                        bool v6_only) {
  SOCKET s = socket(addr.ss.ss_family, SOCK_STREAM, IPPROTO_TCP);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  BOOL optval = true;
  int status = setsockopt(s,
                          SOL_SOCKET,
                          SO_EXCLUSIVEADDRUSE,
                          reinterpret_cast<const char*>(&optval),
                          sizeof(optval));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only;
    setsockopt(s,
               IPPROTO_IPV6,
               IPV6_V6ONLY,
               reinterpret_cast<const char*>(&optval),
               sizeof(optval));
  }

  SocketAddress::SetAddrPort(&addr, port);
  status = bind(s,
                &addr.addr,
                SocketAddress::GetAddrLength(&addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  ListenSocket* listen_socket = new ListenSocket(s);

  // Test for invalid socket port 65535 (some browsers disallow it).
  if (port == 0 &&
      Socket::GetPort(reinterpret_cast<intptr_t>(listen_socket)) == 65535) {
    // Don't close fd until we have created new. By doing that we ensure another
    // port.
    intptr_t new_s = CreateBindListen(addr, 0, backlog, v6_only);
    DWORD rc = WSAGetLastError();
    closesocket(s);
    delete listen_socket;
    SetLastError(rc);
    return new_s;
  }

  status = listen(s, backlog > 0 ? backlog : SOMAXCONN);
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    delete listen_socket;
    SetLastError(rc);
    return -1;
  }

  return reinterpret_cast<intptr_t>(listen_socket);
}


bool ServerSocket::StartAccept(intptr_t fd) {
  ListenSocket* listen_socket = reinterpret_cast<ListenSocket*>(fd);
  listen_socket->EnsureInitialized(EventHandler::delegate());
  // Always keep 5 outstanding accepts going, to enhance performance.
  for (int i = 0; i < 5; i++) {
    if (!listen_socket->IssueAccept()) {
      DWORD rc = WSAGetLastError();
      listen_socket->Close();
      if (!listen_socket->HasPendingAccept()) {
        // Delete socket now, if there are no pending accepts. Otherwise,
        // the event-handler will take care of deleting it.
        delete listen_socket;
      }
      SetLastError(rc);
      return false;
    }
  }
  return true;
}


void Socket::Close(intptr_t fd) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(fd);
  client_socket->Close();
}


static bool SetBlockingHelper(intptr_t fd, bool blocking) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  u_long iMode = blocking ? 0 : 1;
  int status = ioctlsocket(handle->socket(), FIONBIO, &iMode);
  if (status != NO_ERROR) {
    return false;
  }
  return true;
}


bool Socket::SetNonBlocking(intptr_t fd) {
  return SetBlockingHelper(fd, false);
}


bool Socket::SetBlocking(intptr_t fd) {
  return SetBlockingHelper(fd, true);
}


bool Socket::GetNoDelay(intptr_t fd, bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on;
  socklen_t len = sizeof(on);
  int err = getsockopt(handle->socket(),
                       IPPROTO_TCP,
                       TCP_NODELAY,
                       reinterpret_cast<char *>(&on),
                       &len);
  if (err == 0) {
    *enabled = on == 1;
  }
  return err == 0;
}


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  return setsockopt(handle->socket(),
                    IPPROTO_TCP,
                    TCP_NODELAY,
                    reinterpret_cast<char *>(&on),
                    sizeof(on)) == 0;
}


bool Socket::GetMulticastLoop(intptr_t fd, intptr_t protocol, bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  uint8_t on;
  socklen_t len = sizeof(on);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_LOOP : IPV6_MULTICAST_LOOP;
  if (getsockopt(handle->socket(),
                 level,
                 optname,
                 reinterpret_cast<char *>(&on),
                 &len) == 0) {
    *enabled = (on == 1);
    return true;
  }
  return false;
}


bool Socket::SetMulticastLoop(intptr_t fd, intptr_t protocol, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_LOOP : IPV6_MULTICAST_LOOP;
  return setsockopt(handle->socket(),
                    level,
                    optname,
                    reinterpret_cast<char *>(&on),
                    sizeof(on)) == 0;
  return false;
}


bool Socket::GetMulticastHops(intptr_t fd, intptr_t protocol, int* value) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  uint8_t v;
  socklen_t len = sizeof(v);
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_TTL : IPV6_MULTICAST_HOPS;
  if (getsockopt(handle->socket(),
                 level,
                 optname,
                 reinterpret_cast<char *>(&v),
                 &len) == 0) {
    *value = v;
    return true;
  }
  return false;
}


bool Socket::SetMulticastHops(intptr_t fd, intptr_t protocol, int value) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int v = value;
  int level = protocol == SocketAddress::TYPE_IPV4 ? IPPROTO_IP : IPPROTO_IPV6;
  int optname = protocol == SocketAddress::TYPE_IPV4
      ? IP_MULTICAST_TTL : IPV6_MULTICAST_HOPS;
  return setsockopt(handle->socket(),
                    level,
                    optname,
                    reinterpret_cast<char *>(&v),
                    sizeof(v)) == 0;
}


bool Socket::GetBroadcast(intptr_t fd, bool* enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on;
  socklen_t len = sizeof(on);
  int err = getsockopt(handle->socket(),
                       SOL_SOCKET,
                       SO_BROADCAST,
                       reinterpret_cast<char *>(&on),
                       &len);
  if (err == 0) {
    *enabled = on == 1;
  }
  return err == 0;
}


bool Socket::SetBroadcast(intptr_t fd, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  return setsockopt(handle->socket(),
                    SOL_SOCKET,
                    SO_BROADCAST,
                    reinterpret_cast<char *>(&on),
                    sizeof(on)) == 0;
}


bool Socket::JoinMulticast(
    intptr_t fd, RawAddr* addr, RawAddr*, int interfaceIndex) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int proto = addr->addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr->ss, SocketAddress::GetAddrLength(addr));
  return setsockopt(handle->socket(),
                    proto,
                    MCAST_JOIN_GROUP,
                    reinterpret_cast<char *>(&mreq),
                    sizeof(mreq)) == 0;
}


bool Socket::LeaveMulticast(
    intptr_t fd, RawAddr* addr, RawAddr*, int interfaceIndex) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int proto = addr->addr.sa_family == AF_INET ? IPPROTO_IP : IPPROTO_IPV6;
  struct group_req mreq;
  mreq.gr_interface = interfaceIndex;
  memmove(&mreq.gr_group, &addr->ss, SocketAddress::GetAddrLength(addr));
  return setsockopt(handle->socket(),
                    proto,
                    MCAST_LEAVE_GROUP,
                    reinterpret_cast<char *>(&mreq),
                    sizeof(mreq)) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
