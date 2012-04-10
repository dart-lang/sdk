// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "bin/fdutils.h"
#include "bin/socket.h"


bool Socket::Initialize() {
  // Nothing to do on Linux.
  return true;
}


intptr_t Socket::CreateConnect(const char* host, const intptr_t port) {
  intptr_t fd;
  struct hostent* server;
  struct sockaddr_in server_address;

  fd = TEMP_FAILURE_RETRY(socket(AF_INET, SOCK_STREAM, 0));
  if (fd < 0) {
    fprintf(stderr, "Error CreateConnect: %s\n", strerror(errno));
    return -1;
  }

  FDUtils::SetNonBlocking(fd);

  server = gethostbyname(host);
  if (server == NULL) {
    TEMP_FAILURE_RETRY(close(fd));
    fprintf(stderr, "Error CreateConnect: %s\n", strerror(errno));
    return -1;
  }

  server_address.sin_family = AF_INET;
  server_address.sin_port = htons(port);
  bcopy(server->h_addr, &server_address.sin_addr.s_addr, server->h_length);
  memset(&server_address.sin_zero, 0, sizeof(server_address.sin_zero));
  intptr_t result = TEMP_FAILURE_RETRY(
      connect(fd,
              reinterpret_cast<struct sockaddr *>(&server_address),
              sizeof(server_address)));
  if (result == 0 || errno == EINPROGRESS) {
    return fd;
  }
  return -1;
}


intptr_t Socket::Available(intptr_t fd) {
  return FDUtils::AvailableBytes(fd);
}


int Socket::Read(intptr_t fd, void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  ssize_t read_bytes = TEMP_FAILURE_RETRY(read(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if (read_bytes == -1 && errno == EWOULDBLOCK) {
    // If the read would block we need to retry and therefore return 0
    // as the number of bytes written.
    read_bytes = 0;
  }
  return read_bytes;
}


int Socket::Write(intptr_t fd, const void* buffer, intptr_t num_bytes) {
  ASSERT(fd >= 0);
  ssize_t written_bytes = TEMP_FAILURE_RETRY(write(fd, buffer, num_bytes));
  ASSERT(EAGAIN == EWOULDBLOCK);
  if (written_bytes == -1 && errno == EWOULDBLOCK) {
    // If the would block we need to retry and therefore return 0 as
    // the number of bytes written.
    written_bytes = 0;
  }
  return written_bytes;
}


intptr_t Socket::GetPort(intptr_t fd) {
  ASSERT(fd >= 0);
  struct sockaddr_in socket_address;
  socklen_t size = sizeof(socket_address);
  if (TEMP_FAILURE_RETRY(
          getsockname(fd,
                      reinterpret_cast<struct sockaddr *>(&socket_address),
                      &size))) {
    fprintf(stderr, "Error getsockname: %s\n", strerror(errno));
    return 0;
  }
  return ntohs(socket_address.sin_port);
}


bool Socket::GetRemotePeer(intptr_t fd, char *host, intptr_t *port) {
  ASSERT(fd >= 0);
  struct sockaddr_in socket_address;
  socklen_t size = sizeof(socket_address);
  if (TEMP_FAILURE_RETRY(
          getpeername(fd,
                      reinterpret_cast<struct sockaddr *>(&socket_address),
                      &size))) {
    fprintf(stderr, "Error getpeername: %s\n", strerror(errno));
    return false;
  }
  if (inet_ntop(socket_address.sin_family,
                reinterpret_cast<const void *>(&socket_address.sin_addr),
                host,
                INET_ADDRSTRLEN) == NULL) {
    fprintf(stderr, "Error inet_ntop: %s\n", strerror(errno));
    return false;
  }
  *port = ntohs(socket_address.sin_port);
  return true;
}


void Socket::GetError(intptr_t fd, OSError* os_error) {
  int len = sizeof(errno);
  getsockopt(fd,
             SOL_SOCKET,
             SO_ERROR,
             &errno,
             reinterpret_cast<socklen_t*>(&len));
  os_error->SetCodeAndMessage(OSError::kSystem, errno);
}


intptr_t Socket::GetStdioHandle(int num) {
  return static_cast<intptr_t>(num);
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
  intptr_t fd;
  struct sockaddr_in server_address;

  fd = TEMP_FAILURE_RETRY(socket(AF_INET, SOCK_STREAM, 0));
  if (fd < 0) {
    fprintf(stderr, "Error CreateBind: %s\n", strerror(errno));
    return -1;
  }

  int optval = 1;
  TEMP_FAILURE_RETRY(
      setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)));

  server_address.sin_family = AF_INET;
  server_address.sin_port = htons(port);
  server_address.sin_addr.s_addr = inet_addr(host);
  memset(&server_address.sin_zero, 0, sizeof(server_address.sin_zero));

  if (TEMP_FAILURE_RETRY(
          bind(fd,
               reinterpret_cast<struct sockaddr *>(&server_address),
               sizeof(server_address))) < 0) {
    TEMP_FAILURE_RETRY(close(fd));
    fprintf(stderr, "Error Bind: %s\n", strerror(errno));
    return -1;
  }

  if (TEMP_FAILURE_RETRY(listen(fd, backlog)) != 0) {
    fprintf(stderr, "Error Listen: %s\n", strerror(errno));
    return -1;
  }

  FDUtils::SetNonBlocking(fd);
  return fd;
}


static bool IsTemporaryAcceptError(int error) {
  // On Linux a number of protocol errors should be treated as EAGAIN.
  // These are the ones for TCP/IP.
  return (error == EAGAIN) || (error == ENETDOWN) || (error == EPROTO) ||
      (error == ENOPROTOOPT) || (error == EHOSTDOWN) || (error == ENONET) ||
      (error == EHOSTUNREACH) || (error == EOPNOTSUPP) ||
      (error == ENETUNREACH);
}


intptr_t ServerSocket::Accept(intptr_t fd) {
  intptr_t socket;
  struct sockaddr clientaddr;
  socklen_t addrlen = sizeof(clientaddr);
  socket = TEMP_FAILURE_RETRY(accept(fd, &clientaddr, &addrlen));
  if (socket == -1) {
    if (IsTemporaryAcceptError(errno)) {
      // We need to signal to the caller that this is actually not an
      // error. We got woken up from the poll on the listening socket,
      // but there is no connection ready to be accepted.
      ASSERT(kTemporaryFailure != -1);
      socket = kTemporaryFailure;
    }
  } else {
    FDUtils::SetNonBlocking(socket);
  }
  return socket;
}
