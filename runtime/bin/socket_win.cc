// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

  // Perform a name lookup for an IPv4 address.
  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_protocol = IPPROTO_TCP;
  struct addrinfo* result = NULL;
  status = getaddrinfo(host, 0, &hints, &result);
  if (status != NO_ERROR) {
    return -1;
  }

  // Copy IPv4 address and set the port.
  struct sockaddr_in server_address;
  memcpy(&server_address,
         reinterpret_cast<sockaddr_in *>(result->ai_addr),
         sizeof(server_address));
  server_address.sin_port = htons(port);
  freeaddrinfo(result);  // Free data allocated by getaddrinfo.
  status = connect(
      s,
      reinterpret_cast<struct sockaddr*>(&server_address),
      sizeof(server_address));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  ClientSocket* client_socket = new ClientSocket(s);
  return reinterpret_cast<intptr_t>(client_socket);
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  Handle* handle = reinterpret_cast<Handle*>(fd);
  os_error->SetCodeAndMessage(OSError::kSystem, handle->last_error());
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


const char* Socket::LookupIPv4Address(char* host, OSError** os_error) {
  // Perform a name lookup for an IPv4 address.
  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_protocol = IPPROTO_TCP;
  struct addrinfo* info = NULL;
  int status = getaddrinfo(host, 0, &hints, &info);
  if (status != 0) {
    ASSERT(*os_error == NULL);
    *os_error = new OSError(status,
                            gai_strerror(status),
                            OSError::kGetAddressInfo);
    return NULL;
  }
  // Convert the address into IPv4 dotted decimal notation.
  char* buffer = reinterpret_cast<char*>(malloc(INET_ADDRSTRLEN));
  sockaddr_in *sockaddr = reinterpret_cast<sockaddr_in *>(info->ai_addr);
  const char* result = inet_ntop(AF_INET,
                                 reinterpret_cast<void *>(&sockaddr->sin_addr),
                                 buffer,
                                 INET_ADDRSTRLEN);
  if (result == NULL) {
    free(buffer);
    return NULL;
  }
  ASSERT(result == buffer);
  return buffer;
}


intptr_t ServerSocket::CreateBindListen(const char* host,
                                        intptr_t port,
                                        intptr_t backlog) {
  SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
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

  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = inet_addr(host);
  addr.sin_port = htons(port);
  status = bind(s,
                reinterpret_cast<struct sockaddr *>(&addr),
                sizeof(addr));
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  status = listen(s, backlog);
  if (status == SOCKET_ERROR) {
    DWORD rc = WSAGetLastError();
    closesocket(s);
    SetLastError(rc);
    return -1;
  }

  ListenSocket* listen_socket = new ListenSocket(s);
  return reinterpret_cast<intptr_t>(listen_socket);
}
