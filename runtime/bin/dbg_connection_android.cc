// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include <errno.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <stdlib.h>  // NOLINT
#include <sys/epoll.h>  // NOLINT

#include "bin/dbg_connection.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "bin/socket.h"

#include "platform/signal_blocker.h"


namespace dart {
namespace bin {

intptr_t DebuggerConnectionImpl::epoll_fd_ = -1;
int DebuggerConnectionImpl::wakeup_fds_[2] = {-1, -1};


void DebuggerConnectionImpl::HandleEvent(struct epoll_event* event) {
  if (event->data.fd == DebuggerConnectionHandler::listener_fd_) {
    if (DebuggerConnectionHandler::IsConnected()) {
      FATAL("Cannot connect to more than one debugger.\n");
    }
    intptr_t fd = ServerSocket::Accept(event->data.fd);
    if (fd < 0) {
      FATAL("Accepting new debugger connection failed.\n");
    }
    FDUtils::SetBlocking(fd);
    DebuggerConnectionHandler::AcceptDbgConnection(fd);
    // TODO(hausner): add the debugger wire socket fd to the event poll queue
    // once we poll the debugger connection.
  } else if (event->data.fd == wakeup_fds_[0]) {
    // Sync message. Not yet implemented.
    UNIMPLEMENTED();
  } else {
    Log::Print("unexpected: receiving debugger connection event.\n");
    UNIMPLEMENTED();
  }
}


void DebuggerConnectionImpl::Handler(uword args) {
  static const intptr_t kMaxEvents = 4;
  struct epoll_event events[kMaxEvents];
  while (1) {
    const int no_timeout = -1;
    intptr_t result = TEMP_FAILURE_RETRY(
        epoll_wait(epoll_fd_, events, kMaxEvents, no_timeout));
    ASSERT(EAGAIN == EWOULDBLOCK);
    if (result == -1) {
      if (errno != EWOULDBLOCK) {
        perror("epoll_wait failed");
      }
    } else {
      ASSERT(result <= kMaxEvents);
      for (int i = 0; i < result; i++) {
        HandleEvent(&events[i]);
      }
    }
  }
}


void DebuggerConnectionImpl::SetupPollQueue() {
  int result = NO_RETRY_EXPECTED(pipe(wakeup_fds_));
  if (result != 0) {
    FATAL1("Pipe creation failed with error %d\n", result);
  }
  FDUtils::SetNonBlocking(wakeup_fds_[0]);

  static const int kEpollInitialSize = 16;
  epoll_fd_ = NO_RETRY_EXPECTED(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL("Failed creating epoll file descriptor");
  }

  // Register the wakeup _fd with the epoll instance.
  struct epoll_event event;
  event.events = EPOLLIN;
  event.data.fd = wakeup_fds_[0];
  int status = NO_RETRY_EXPECTED(epoll_ctl(
                   epoll_fd_, EPOLL_CTL_ADD, wakeup_fds_[0], &event));
  if (status == -1) {
    FATAL("Failed adding wakeup fd to epoll instance");
  }

  // Register the listener_fd with the epoll instance.
  event.events = EPOLLIN;
  event.data.fd = DebuggerConnectionHandler::listener_fd_;
  status = NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_ADD,
               DebuggerConnectionHandler::listener_fd_, &event));
  if (status == -1) {
    FATAL("Failed adding listener fd to epoll instance");
  }
}


void DebuggerConnectionImpl::StartHandler(int port_number) {
  ASSERT(DebuggerConnectionHandler::listener_fd_ != -1);
  SetupPollQueue();
  int result = dart::Thread::Start(&DebuggerConnectionImpl::Handler, 0);
  if (result != 0) {
    FATAL1("Failed to start debugger connection handler thread: %d\n", result);
  }
}


intptr_t DebuggerConnectionImpl::Send(intptr_t socket,
                                      const char* buf,
                                      int len) {
  return TEMP_FAILURE_RETRY(write(socket, buf, len));
}


intptr_t DebuggerConnectionImpl::Receive(intptr_t socket, char* buf, int len) {
  return TEMP_FAILURE_RETRY(read(socket, buf, len));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
