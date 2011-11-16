// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <winsock2.h>
#include <ws2tcpip.h>
#include <mswsock.h>

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/socket.h"

bool Socket::Initialize() {
  int err;
  WSADATA winsock_data;
  WORD version_requested = MAKEWORD(1, 0);
  err = WSAStartup(version_requested, &winsock_data);
  if (err != 0) {
    fprintf(stderr, "Unable to initialize Winsock: %d\n", WSAGetLastError());
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
  struct sockaddr_in socket_address;
  socklen_t size = sizeof(socket_address);
  if (getsockname(socket_handle->socket(),
                  reinterpret_cast<struct sockaddr *>(&socket_address),
                  &size)) {
    fprintf(stderr, "Error getsockname: %s\n", strerror(errno));
    return 0;
  }
  return ntohs(socket_address.sin_port);
}


intptr_t Socket::CreateConnect(const char* host, const intptr_t port) {
  SOCKET s = socket(AF_INET, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET) {
    fprintf(stderr, "Error CreateConnect: %d\n", WSAGetLastError());
    return -1;
  }

  struct hostent* server = gethostbyname(host);
  if (server == NULL) {
    fprintf(stderr, "Error CreateConnect: %d\n", WSAGetLastError());
    closesocket(s);
    return -1;
  }

  struct sockaddr_in server_address;
  server_address.sin_family = AF_INET;
  server_address.sin_port = htons(port);
  server_address.sin_addr.s_addr = inet_addr(host);
  int status = connect(
      s,
      reinterpret_cast<struct sockaddr *>(&server_address),
      sizeof(server_address));
  if (status == SOCKET_ERROR) {
    fprintf(stderr, "Error CreateConnect: %d\n", WSAGetLastError());
    closesocket(s);
    return -1;
  }

  ClientSocket* client_socket = new ClientSocket(s);
  return reinterpret_cast<intptr_t>(client_socket);
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
    fprintf(stderr, "Error GetStdHandle: %d\n", GetLastError());
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


intptr_t ServerSocket::CreateBindListen(const char* host,
                                        intptr_t port,
                                        intptr_t backlog) {
  SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (s == INVALID_SOCKET) {
    fprintf(stderr, "Error CreateBindListen: %d\n", WSAGetLastError());
    return -1;
  }

  BOOL optval = true;
  int status = setsockopt(s,
                          SOL_SOCKET,
                          SO_REUSEADDR,
                          reinterpret_cast<const char*>(&optval),
                          sizeof(optval));
  if (status == SOCKET_ERROR) {
    fprintf(stderr, "Error CreateBindListen: %d\n", WSAGetLastError());
    closesocket(s);
    return -1;
  }

  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = inet_addr(host);
  addr.sin_port = htons(port);
  status = bind(s,
                reinterpret_cast<struct sockaddr *>(&addr),
                sizeof(addr));
  if (status == SOCKET_ERROR) {
    fprintf(stderr, "Error CreateBindListen: %d\n", WSAGetLastError());
    closesocket(s);
    return -1;
  }

  status = listen(s, backlog);
  if (status == SOCKET_ERROR) {
    fprintf(stderr, "Error socket listen: %d\n", WSAGetLastError());
    closesocket(s);
    return -1;
  }

  ListenSocket* listen_socket = new ListenSocket(s);
  return reinterpret_cast<intptr_t>(listen_socket);
}
