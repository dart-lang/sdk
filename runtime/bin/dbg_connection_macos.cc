// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include <errno.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <stdlib.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/event.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "bin/dartutils.h"
#include "bin/dbg_connection.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

#define INVALID_FD -1

int DebuggerConnectionImpl::kqueue_fd_ = INVALID_FD;
int DebuggerConnectionImpl::wakeup_fds_[2] = {INVALID_FD, INVALID_FD};


// Used by VM threads to send a message to the debugger connetion
// handler thread.
void DebuggerConnectionImpl::SendMessage(MessageType id) {
  ASSERT(wakeup_fds_[1] != INVALID_FD);
  struct Message msg;
  msg.msg_id = id;
  int result = FDUtils::WriteToBlocking(wakeup_fds_[1], &msg, sizeof(msg));
  if (result != sizeof(msg)) {
    if (result == -1) {
      perror("Wakeup message failure: ");
    }
    FATAL1("Wakeup message failure. Wrote %d bytes.", result);
  }
}


// Used by the debugger connection handler to read the messages sent
// by the VM.
bool DebuggerConnectionImpl::ReceiveMessage(Message* msg) {
  int total_read = 0;
  int bytes_read = 0;
  int remaining = sizeof(Message);
  uint8_t* buf = reinterpret_cast<uint8_t*>(msg);
  while (remaining > 0) {
    bytes_read =
        TEMP_FAILURE_RETRY(read(wakeup_fds_[0], buf + total_read, remaining));
    if ((bytes_read < 0) && (total_read == 0)) {
      return false;
    }
    if (bytes_read > 0) {
      total_read += bytes_read;
      remaining -= bytes_read;
    }
  }
  ASSERT(remaining >= 0);
  return remaining == 0;
}


void DebuggerConnectionImpl::HandleEvent(struct kevent* event) {
  intptr_t ident = event->ident;
  if (ident == DebuggerConnectionHandler::listener_fd_) {
    if (DebuggerConnectionHandler::IsConnected()) {
      FATAL("Cannot connect to more than one debugger.\n");
    }
    intptr_t fd = ServerSocket::Accept(ident);
    if (fd < 0) {
      FATAL("Accepting new debugger connection failed.\n");
    }
    FDUtils::SetBlocking(fd);
    DebuggerConnectionHandler::AcceptDbgConnection(fd);

    /* For now, don't poll the debugger connection.
    struct kevent ev_add;
    EV_SET(&ev_add, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
    int status =
        TEMP_FAILURE_RETRY(kevent(kqueue_fd_, &ev_add, 1, NULL, 0, NULL));
    if (status == -1) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      strerror_r(errno, error_message, kBufferSize);
      FATAL1("Failed adding debugger socket to kqueue: %s\n", error_message);
    }
    */
  } else if (ident == wakeup_fds_[0]) {
    Message msg;
    if (ReceiveMessage(&msg)) {
      Log::Print("Received sync message id %d.\n", msg.msg_id);
    }
  } else {
    Log::Print("unexpected: receiving debugger connection event.\n");
    UNIMPLEMENTED();
  }
}


void DebuggerConnectionImpl::Handler(uword args) {
  static const int kMaxEvents = 4;
  struct kevent events[kMaxEvents];

  while (1) {
    // Wait indefinitely for an event.
    int result = TEMP_FAILURE_RETRY(
        kevent(kqueue_fd_, NULL, 0, events, kMaxEvents, NULL));
    if (result == -1) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      strerror_r(errno, error_message, kBufferSize);
      FATAL1("kevent failed %s\n", error_message);
    } else {
      ASSERT(result <= kMaxEvents);
      for (int i = 0; i < result; i++) {
        HandleEvent(&events[i]);
      }
    }
  }
  Log::Print("shutting down debugger thread\n");
}


void DebuggerConnectionImpl::SetupPollQueue() {
  int result;
  result = NO_RETRY_EXPECTED(pipe(wakeup_fds_));
  if (result != 0) {
    FATAL1("Pipe creation failed with error %d\n", result);
  }
  FDUtils::SetNonBlocking(wakeup_fds_[0]);

  kqueue_fd_ = NO_RETRY_EXPECTED(kqueue());
  if (kqueue_fd_ == -1) {
    FATAL("Failed creating kqueue\n");
  }
  // Register the wakeup_fd_ with the kqueue.
  struct kevent event;
  EV_SET(&event, wakeup_fds_[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
  int status = NO_RETRY_EXPECTED(kevent(kqueue_fd_, &event, 1, NULL, 0, NULL));
  if (status == -1) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    FATAL1("Failed adding wakeup pipe fd to kqueue: %s\n", error_message);
  }

  // Register the listening socket.
  EV_SET(&event, DebuggerConnectionHandler::listener_fd_,
         EVFILT_READ, EV_ADD, 0, 0, NULL);
  status = NO_RETRY_EXPECTED(kevent(kqueue_fd_, &event, 1, NULL, 0, NULL));
  if (status == -1) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    FATAL1("Failed adding listener socket to kqueue: %s\n", error_message);
  }
}


void DebuggerConnectionImpl::StartHandler(int port_number) {
  ASSERT(DebuggerConnectionHandler::listener_fd_ != -1);
  SetupPollQueue();
  int result = Thread::Start(&DebuggerConnectionImpl::Handler, 0);
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

#endif  // defined(TARGET_OS_MACOS)
