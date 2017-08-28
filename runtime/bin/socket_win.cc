// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/socket_base_win.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

Socket::Socket(intptr_t fd) : ReferenceCounted(), fd_(fd), port_(ILLEGAL_PORT) {
  ASSERT(fd_ != kClosedFd);
  Handle* handle = reinterpret_cast<Handle*>(fd_);
  ASSERT(handle != NULL);
}

void Socket::SetClosedFd() {
  ASSERT(fd_ != kClosedFd);
  Handle* handle = reinterpret_cast<Handle*>(fd_);
  ASSERT(handle != NULL);
  handle->Release();
  fd_ = kClosedFd;
}

static intptr_t Create(const RawAddr& addr) {
  SOCKET s = socket(addr.ss.ss_family, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  linger l;
  l.l_onoff = 1;
  l.l_linger = 10;
  int status = setsockopt(s, SOL_SOCKET, SO_LINGER, reinterpret_cast<char*>(&l),
                          sizeof(l));
  if (status != NO_ERROR) {
    FATAL("Failed setting SO_LINGER on socket");
  }

  ClientSocket* client_socket = new ClientSocket(s);
  return reinterpret_cast<intptr_t>(client_socket);
}

static intptr_t Connect(intptr_t fd,
                        const RawAddr& addr,
                        const RawAddr& bind_addr) {
  ASSERT(reinterpret_cast<Handle*>(fd)->is_client_socket());
  ClientSocket* handle = reinterpret_cast<ClientSocket*>(fd);
  SOCKET s = handle->socket();

  int status =
      bind(s, &bind_addr.addr, SocketAddress::GetAddrLength(bind_addr));
  if (status != NO_ERROR) {
    int rc = WSAGetLastError();
    handle->mark_closed();  // Destructor asserts that socket is marked closed.
    handle->Release();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  LPFN_CONNECTEX connectEx = NULL;
  GUID guid_connect_ex = WSAID_CONNECTEX;
  DWORD bytes;
  status = WSAIoctl(s, SIO_GET_EXTENSION_FUNCTION_POINTER, &guid_connect_ex,
                    sizeof(guid_connect_ex), &connectEx, sizeof(connectEx),
                    &bytes, NULL, NULL);
  DWORD rc;
  if (status != SOCKET_ERROR) {
    handle->EnsureInitialized(EventHandler::delegate());

    OverlappedBuffer* overlapped = OverlappedBuffer::AllocateConnectBuffer();

    status = connectEx(s, &addr.addr, SocketAddress::GetAddrLength(addr), NULL,
                       0, NULL, overlapped->GetCleanOverlapped());

    if (status == TRUE) {
      handle->ConnectComplete(overlapped);
      return fd;
    } else if (WSAGetLastError() == ERROR_IO_PENDING) {
      return fd;
    }
    rc = WSAGetLastError();
    // Cleanup in case of error.
    OverlappedBuffer::DisposeBuffer(overlapped);
    handle->Release();
  } else {
    rc = WSAGetLastError();
  }
  handle->Close();
  handle->Release();
  SetLastError(rc);
  return -1;
}

intptr_t Socket::CreateConnect(const RawAddr& addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }

  RawAddr bind_addr;
  memset(&bind_addr, 0, sizeof(bind_addr));
  bind_addr.ss.ss_family = addr.ss.ss_family;
  if (addr.ss.ss_family == AF_INET) {
    bind_addr.in.sin_addr.s_addr = INADDR_ANY;
  } else {
    bind_addr.in6.sin6_addr = in6addr_any;
  }

  return Connect(fd, addr, bind_addr);
}

intptr_t Socket::CreateBindConnect(const RawAddr& addr,
                                   const RawAddr& source_addr) {
  intptr_t fd = Create(addr);
  if (fd < 0) {
    return fd;
  }

  return Connect(fd, addr, source_addr);
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

intptr_t Socket::CreateBindDatagram(const RawAddr& addr, bool reuseAddress) {
  SOCKET s = socket(addr.ss.ss_family, SOCK_DGRAM, IPPROTO_UDP);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  int status;
  if (reuseAddress) {
    BOOL optval = true;
    status = setsockopt(s, SOL_SOCKET, SO_REUSEADDR,
                        reinterpret_cast<const char*>(&optval), sizeof(optval));
    if (status == SOCKET_ERROR) {
      DWORD rc = WSAGetLastError();
      closesocket(s);
      SetLastError(rc);
      return -1;
    }
  }

  status = bind(s, &addr.addr, SocketAddress::GetAddrLength(addr));
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

intptr_t ServerSocket::CreateBindListen(const RawAddr& addr,
                                        intptr_t backlog,
                                        bool v6_only) {
  SOCKET s = socket(addr.ss.ss_family, SOCK_STREAM, IPPROTO_TCP);
  if (s == INVALID_SOCKET) {
    return -1;
  }

  BOOL optval = true;
  int status =
      setsockopt(s, SOL_SOCKET, SO_EXCLUSIVEADDRUSE,
                 reinterpret_cast<const char*>(&optval), sizeof(optval));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  if (addr.ss.ss_family == AF_INET6) {
    optval = v6_only;
    setsockopt(s, IPPROTO_IPV6, IPV6_V6ONLY,
               reinterpret_cast<const char*>(&optval), sizeof(optval));
  }

  status = bind(s, &addr.addr, SocketAddress::GetAddrLength(addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  ListenSocket* listen_socket = new ListenSocket(s);

  // Test for invalid socket port 65535 (some browsers disallow it).
  if ((SocketAddress::GetAddrPort(addr) == 0) &&
      (SocketBase::GetPort(reinterpret_cast<intptr_t>(listen_socket)) ==
       65535)) {
    // Don't close fd until we have created new. By doing that we ensure another
    // port.
    intptr_t new_s = CreateBindListen(addr, backlog, v6_only);
    DWORD rc = WSAGetLastError();
    closesocket(s);
    listen_socket->Release();
    SetLastError(rc);
    return new_s;
  }

  status = listen(s, backlog > 0 ? backlog : SOMAXCONN);
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    listen_socket->Release();
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
        listen_socket->Release();
      }
      SetLastError(rc);
      return false;
    }
  }
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
