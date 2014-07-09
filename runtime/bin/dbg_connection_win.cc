// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/dbg_connection.h"

#include "bin/eventhandler.h"


namespace dart {
namespace bin {

void DebuggerConnectionImpl::ThreadEntry(uword args) {
  ListenSocket* listen_socket =
      reinterpret_cast<ListenSocket*>(DebuggerConnectionHandler::listener_fd_);
  SOCKET client_socket = accept(listen_socket->socket(), NULL, NULL);
  if (client_socket == INVALID_SOCKET) {
    FATAL("Accepting new debugger connection failed.\n");
  }
  ClientSocket* socket = new ClientSocket(client_socket);
  DebuggerConnectionHandler::AcceptDbgConnection(
      reinterpret_cast<intptr_t>(socket));
}


void DebuggerConnectionImpl::StartHandler(int port_number) {
  ASSERT(DebuggerConnectionHandler::listener_fd_ != -1);
  int result = dart::Thread::Start(&DebuggerConnectionImpl::ThreadEntry, 0);
  if (result != 0) {
    FATAL1("Failed to start debugger connection handler thread: %d\n", result);
  }
}


intptr_t DebuggerConnectionImpl::Send(intptr_t socket,
                                      const char* buf,
                                      int len) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(socket);
  return send(client_socket->socket(), buf, len, 0);
}


intptr_t DebuggerConnectionImpl::Receive(intptr_t socket, char* buf, int len) {
  ClientSocket* client_socket = reinterpret_cast<ClientSocket*>(socket);
  return recv(client_socket->socket(), buf, len, 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
