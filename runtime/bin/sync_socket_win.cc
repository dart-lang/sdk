// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/socket_base.h"
#include "bin/sync_socket.h"

namespace dart {
namespace bin {

bool SynchronousSocket::Initialize() {
  return SocketBase::Initialize();
}

static intptr_t Create(const RawAddr& addr) {
  const intptr_t type = SOCK_STREAM;
  SOCKET s = WSASocket(addr.ss.ss_family, type, 0, NULL, 0, 0);
  return (s == INVALID_SOCKET) ? -1 : s;
}

static intptr_t Connect(intptr_t fd, const RawAddr& addr) {
  SOCKET socket = static_cast<SOCKET>(fd);
  intptr_t result =
      connect(socket, &addr.addr, SocketAddress::GetAddrLength(addr));
  return (result == SOCKET_ERROR) ? -1 : socket;
}

intptr_t SynchronousSocket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  return (fd < 0) ? fd : Connect(fd, addr);
}

intptr_t SynchronousSocket::Available(intptr_t fd) {
  SOCKET socket = static_cast<SOCKET>(fd);
  DWORD available;
  intptr_t result = ioctlsocket(socket, FIONREAD, &available);
  return (result == SOCKET_ERROR) ? -1 : static_cast<intptr_t>(available);
}

intptr_t SynchronousSocket::GetPort(intptr_t fd) {
  SOCKET socket = static_cast<SOCKET>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getsockname(socket, &raw.addr, &size) == SOCKET_ERROR) {
    return 0;
  }
  return SocketAddress::GetAddrPort(raw);
}

SocketAddress* SynchronousSocket::GetRemotePeer(intptr_t fd, intptr_t* port) {
  SOCKET socket = static_cast<SOCKET>(fd);
  RawAddr raw;
  socklen_t size = sizeof(raw);
  if (getpeername(socket, &raw.addr, &size)) {
    return NULL;
  }
  *port = SocketAddress::GetAddrPort(raw);
  // Clear the port before calling WSAAddressToString as WSAAddressToString
  // includes the port in the formatted string.
  SocketAddress::SetAddrPort(&raw, 0);
  return new SocketAddress(&raw.addr);
}

intptr_t SynchronousSocket::Read(intptr_t fd,
                                 void* buffer,
                                 intptr_t num_bytes) {
  SOCKET socket = static_cast<SOCKET>(fd);
  return recv(socket, reinterpret_cast<char*>(buffer), num_bytes, 0);
}

intptr_t SynchronousSocket::Write(intptr_t fd,
                                  const void* buffer,
                                  intptr_t num_bytes) {
  SOCKET socket = static_cast<SOCKET>(fd);
  return send(socket, reinterpret_cast<const char*>(buffer), num_bytes, 0);
}

void SynchronousSocket::ShutdownRead(intptr_t fd) {
  SOCKET socket = static_cast<SOCKET>(fd);
  shutdown(socket, SD_RECEIVE);
}

void SynchronousSocket::ShutdownWrite(intptr_t fd) {
  SOCKET socket = static_cast<SOCKET>(fd);
  shutdown(socket, SD_SEND);
}

void SynchronousSocket::Close(intptr_t fd) {
  SOCKET socket = static_cast<SOCKET>(fd);
  closesocket(socket);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
