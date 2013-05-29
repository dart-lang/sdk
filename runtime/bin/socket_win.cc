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


namespace dart {
namespace bin {

SocketAddress::SocketAddress(struct addrinfo* addrinfo) {
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  RawAddr* raw = reinterpret_cast<RawAddr*>(addrinfo->ai_addr);

  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  DWORD len = INET6_ADDRSTRLEN;
  int err = WSAAddressToStringA(&raw->addr,
                                sizeof(RawAddr),
                                NULL,
                                as_string_,
                                &len);

  if (err != 0) {
    as_string_[0] = 0;
  }
  memmove(reinterpret_cast<void *>(&addr_),
          addrinfo->ai_addr,
          addrinfo->ai_addrlen);
}

bool Socket::Initialize() {
  static bool socket_initialized = false;
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


intptr_t Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  return handle->Write(buffer, num_bytes);
}


intptr_t Socket::GetPort(intptr_t fd) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getsockname(socket_handle->socket(),
                  &raw.addr,
                  &size) == SOCKET_ERROR) {
    Log::PrintErr("Error getsockname: %d\n", WSAGetLastError());
    return 0;
  }
  return SocketAddress::GetAddrPort(&raw);
}


bool Socket::GetRemotePeer(intptr_t fd, char *host, intptr_t *port) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* socket_handle = reinterpret_cast<SocketHandle*>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getpeername(socket_handle->socket(),
                  &raw.addr,
                  &size)) {
    Log::PrintErr("Error getpeername: %d\n", WSAGetLastError());
    return false;
  }
  *port = SocketAddress::GetAddrPort(&raw);
  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  SocketAddress::SetAddrPort(&raw, 0);
  DWORD len = INET6_ADDRSTRLEN;
  int err = WSAAddressToStringA(&raw.addr,
                                sizeof(raw),
                                NULL,
                                host,
                                &len);
  if (err != 0) {
    Log::PrintErr("Error WSAAddressToString: %d\n", WSAGetLastError());
    return false;
  }
  return true;
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
  ASSERT(reinterpret_cast<Handle*>(fd)->is_socket());
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  SOCKET s = handle->socket();
  SocketAddress::SetAddrPort(&addr, port);
  int status = connect(s, &addr.addr, SocketAddress::GetAddrLength(addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(fd);
    client_socket->Close();
    SetLastError(rc);
    return -1;
  }
  return fd;
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


intptr_t Socket::GetStdioHandle(int num) {
  HANDLE handle;
  switch (num) {
    case 0:
      handle = GetStdHandle(STD_INPUT_HANDLE);
      break;
    case 1:
      handle = GetStdHandle(STD_OUTPUT_HANDLE);
      break;
    case 2:
      handle = GetStdHandle(STD_ERROR_HANDLE);
      break;
    default: UNREACHABLE();
  }
  if (handle == INVALID_HANDLE_VALUE) {
    return -1;
  }
  FileHandle* file_handle = new FileHandle(handle);
  if (file_handle == NULL) return -1;
  file_handle->MarkDoesNotSupportOverlappedIO();
  return reinterpret_cast<intptr_t>(file_handle);
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


SocketAddresses* Socket::LookupAddress(const char* host,
                                       int type,
                                       OSError** os_error) {
  Initialize();

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
    DWORD error_code = WSAGetLastError();
    SetLastError(error_code);
    *os_error = new OSError();
    return NULL;
  }
  intptr_t count = 0;
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if (c->ai_family == AF_INET || c->ai_family == AF_INET6) count++;
  }
  SocketAddresses* addresses = new SocketAddresses(count);
  intptr_t i = 0;
  for (struct addrinfo* c = info; c != NULL; c = c->ai_next) {
    if (c->ai_family == AF_INET || c->ai_family == AF_INET6) {
      addresses->SetAt(i, new SocketAddress(c));
      i++;
    }
  }
  freeaddrinfo(info);
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
                          SO_REUSEADDR,
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
                SocketAddress::GetAddrLength(addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  status = listen(s, backlog > 0 ? backlog : SOMAXCONN);
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  ListenSocket* listen_socket = new ListenSocket(s);
  return reinterpret_cast<intptr_t>(listen_socket);
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
    Log::PrintErr("ioctlsocket FIONBIO failed: %d\n", status);
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


bool Socket::SetNoDelay(intptr_t fd, bool enabled) {
  SocketHandle* handle = reinterpret_cast<SocketHandle*>(fd);
  int on = enabled ? 1 : 0;
  return setsockopt(fd,
                    IPPROTO_TCP,
                    TCP_NODELAY,
                    reinterpret_cast<char *>(&on),
                    sizeof(on)) == 0;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
