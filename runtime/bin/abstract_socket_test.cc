// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a utility program for testing that a Dart program can connect to an
// abstract UNIX socket created by a non-Dart program. It creates such a socket
// accepts one connection, echoes back the first message it receives, and then
// closes the connection and UNIX socket.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

const intptr_t kOffsetOfPtr = 32;

#define OFFSET_OF(type, field)                                                 \
  (reinterpret_cast<intptr_t>(                                                 \
       &(reinterpret_cast<type*>(kOffsetOfPtr)->field)) -                      \
   kOffsetOfPtr)  // NOLINT

int main(int argc, char* argv[]) {
  struct sockaddr_un addr;
  char* socket_path;
  int server_socket;
  char buf[1024];

  if (argc < 2) {
    fprintf(
        stderr,
        "Usage: abstract_socket_test <address>\n\n"
        "<address> should be an abstract UNIX socket address like @hidden\n");
    exit(-1);
  }

  socket_path = argv[1];
  if (socket_path[0] != '@') {
    fprintf(stderr,
            "The first argument should be an abstract socket "
            "address and start with '@'\n");
    exit(-1);
  }

  if ((server_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    perror("socket error");
    exit(-1);
  }

  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  addr.sun_path[0] = '\0';
  strncpy(addr.sun_path + 1, socket_path + 1, sizeof(addr.sun_path) - 2);

  int address_length =
      OFFSET_OF(struct sockaddr_un, sun_path) + strlen(socket_path);
  if (bind(server_socket, (struct sockaddr*)&addr, address_length) == -1) {
    perror("bind error");
    exit(-1);
  }

  if (listen(server_socket, 5) == -1) {
    perror("listen error");
    exit(-1);
  }

  int client_socket;
  if ((client_socket = accept(server_socket, nullptr, nullptr)) == -1) {
    perror("accept error");
    exit(-1);
  }

  int read_count;
  while ((read_count = read(client_socket, buf, sizeof(buf))) > 0) {
    int write_count = 0;
    while (write_count < read_count) {
      int w;
      if ((w = write(client_socket, buf, read_count)) < 0) {
        perror("write");
        exit(-1);
      }
      write_count += w;
    }
  }
  if (read_count == -1) {
    perror("read");
    exit(-1);
  }

  close(client_socket);
  close(server_socket);
  return 0;
}

#else

int main() {
  return -1;
}

#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
