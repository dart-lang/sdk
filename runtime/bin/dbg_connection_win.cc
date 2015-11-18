// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/dbg_connection.h"

#include "bin/eventhandler.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/thread.h"

namespace dart {
namespace bin {

Monitor* DebuggerConnectionImpl::handler_monitor_ = new Monitor();
ThreadId DebuggerConnectionImpl::handler_thread_id_ = Thread::kInvalidThreadId;
bool DebuggerConnectionImpl::handler_thread_running_ = false;


void DebuggerConnectionImpl::NotifyThreadStarted() {
  MonitorLocker ml(handler_monitor_);
  ASSERT(!handler_thread_running_);
  ASSERT(handler_thread_id_ == Thread::kInvalidThreadId);
  handler_thread_running_ = true;
  handler_thread_id_ = Thread::GetCurrentThreadId();
  ml.Notify();
}


void DebuggerConnectionImpl::WaitForThreadStarted() {
  MonitorLocker ml(handler_monitor_);
  while (!handler_thread_running_) {
    ml.Wait();
  }
  ASSERT(handler_thread_id_ != Thread::kInvalidThreadId);
}


void DebuggerConnectionImpl::NotifyThreadFinished() {
  MonitorLocker ml(handler_monitor_);
  ASSERT(handler_thread_running_);
  ASSERT(handler_thread_id_ != Thread::kInvalidThreadId);
  handler_thread_running_ = false;
  ml.Notify();
}


void DebuggerConnectionImpl::WaitForThreadFinished() {
  MonitorLocker ml(handler_monitor_);
  while (handler_thread_running_) {
    ml.Wait();
  }
  ASSERT(handler_thread_id_ != Thread::kInvalidThreadId);
  Thread::Join(handler_thread_id_);
  handler_thread_id_ = Thread::kInvalidThreadId;
}


void DebuggerConnectionImpl::ThreadEntry(uword args) {
  NotifyThreadStarted();
  ListenSocket* listen_socket =
      reinterpret_cast<ListenSocket*>(DebuggerConnectionHandler::listener_fd_);
  SOCKET client_socket = accept(listen_socket->socket(), NULL, NULL);
  if (client_socket == INVALID_SOCKET) {
    FATAL("Accepting new debugger connection failed.\n");
  }
  ClientSocket* socket = new ClientSocket(client_socket);
  DebuggerConnectionHandler::AcceptDbgConnection(
      reinterpret_cast<intptr_t>(socket));
  NotifyThreadFinished();
}


void DebuggerConnectionImpl::StartHandler(int port_number) {
  ASSERT(DebuggerConnectionHandler::listener_fd_ != -1);
  int result = Thread::Start(&DebuggerConnectionImpl::ThreadEntry, 0);
  if (result != 0) {
    FATAL1("Failed to start debugger connection handler thread: %d\n", result);
  }
  WaitForThreadStarted();
}


void DebuggerConnectionImpl::StopHandler(intptr_t debug_fd) {
  Send(debug_fd, NULL, 0);
  WaitForThreadFinished();
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
