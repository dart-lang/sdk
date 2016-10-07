// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/eventhandler.h"
#include "bin/eventhandler_fuchsia.h"

#include <magenta/syscalls.h>
#include <runtime/status.h>

#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

EventHandlerImplementation::EventHandlerImplementation() {
  mx_status_t status = mx_msgpipe_create(interrupt_handles_, 0);
  if (status != NO_ERROR) {
    FATAL1("mx_msgpipe_create failed: %s\n", mx_strstatus(status));
  }
  shutdown_ = false;
}


EventHandlerImplementation::~EventHandlerImplementation() {
  mx_status_t status = mx_handle_close(interrupt_handles_[0]);
  if (status != NO_ERROR) {
    FATAL1("mx_handle_close failed: %s\n", mx_strstatus(status));
  }
  status = mx_handle_close(interrupt_handles_[1]);
  if (status != NO_ERROR) {
    FATAL1("mx_handle_close failed: %s\n", mx_strstatus(status));
  }
}


void EventHandlerImplementation::WakeupHandler(intptr_t id,
                                               Dart_Port dart_port,
                                               int64_t data) {
  InterruptMessage msg;
  msg.id = id;
  msg.dart_port = dart_port;
  msg.data = data;

  mx_status_t status =
    mx_msgpipe_write(interrupt_handles_[1], &msg, sizeof(msg), NULL, 0, 0);
  if (status != NO_ERROR) {
    FATAL1("mx_msgpipe_write failed: %s\n", mx_strstatus(status));
  }
}


void EventHandlerImplementation::HandleInterruptFd() {
  InterruptMessage msg;
  uint32_t bytes = kInterruptMessageSize;
  mx_status_t status;
  while (true) {
    status = mx_msgpipe_read(
        interrupt_handles_[0], &msg, &bytes, NULL, NULL, 0);
    if (status != NO_ERROR) {
      break;
    }
    ASSERT(bytes == kInterruptMessageSize);
    if (msg.id == kTimerId) {
      timeout_queue_.UpdateTimeout(msg.dart_port, msg.data);
    } else if (msg.id == kShutdownId) {
      shutdown_ = true;
    } else {
      UNIMPLEMENTED();
    }
  }
  // status == ERR_BAD_STATE when we try to read and there are no messages
  // available, so it is an error if we get here and status != ERR_BAD_STATE.
  if (status != ERR_BAD_STATE) {
    FATAL1("mx_msgpipe_read failed: %s\n", mx_strstatus(status));
  }
}


void EventHandlerImplementation::HandleEvents() {
  // TODO(zra): Handle events from other handles. At the moment we are only
  // interrupted when there is a message on interrupt_handles_[0].
  HandleInterruptFd();
}


int64_t EventHandlerImplementation::GetTimeout() const {
  if (!timeout_queue_.HasTimeout()) {
    return kInfinityTimeout;
  }
  int64_t millis = timeout_queue_.CurrentTimeout() -
      TimerUtils::GetCurrentMonotonicMillis();
  return (millis < 0) ? 0 : millis;
}


void EventHandlerImplementation::HandleTimeout() {
  if (timeout_queue_.HasTimeout()) {
    int64_t millis = timeout_queue_.CurrentTimeout() -
        TimerUtils::GetCurrentMonotonicMillis();
    if (millis <= 0) {
      DartUtils::PostNull(timeout_queue_.CurrentPort());
      timeout_queue_.RemoveCurrent();
    }
  }
}


void EventHandlerImplementation::Poll(uword args) {
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);

  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT((millis == kInfinityTimeout) || (millis >= 0));

    mx_time_t timeout =
        millis * kMicrosecondsPerMillisecond * kNanosecondsPerMicrosecond;
    mx_signals_state_t signals_state;
    mx_status_t status = mx_handle_wait_one(
        handler_impl->interrupt_handles_[0],
        MX_SIGNAL_READABLE | MX_SIGNAL_PEER_CLOSED,
        timeout,
        &signals_state);
    if ((status != NO_ERROR) && (status != ERR_TIMED_OUT)) {
      FATAL1("mx_handle_wait_one failed: %s\n", mx_strstatus(status));
    } else {
      handler_impl->HandleTimeout();
      if ((signals_state.satisfied & MX_SIGNAL_READABLE) != 0) {
        handler_impl->HandleEvents();
      }
      if ((signals_state.satisfied & MX_SIGNAL_PEER_CLOSED) != 0) {
        FATAL("EventHandlerImplementation::Poll: Unexpected peer closed\n");
      }
    }
  }
  handler->NotifyShutdownDone();
}


void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = Thread::Start(&EventHandlerImplementation::Poll,
                             reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }
}


void EventHandlerImplementation::Shutdown() {
  SendData(kShutdownId, 0, 0);
}


void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          int64_t data) {
  WakeupHandler(id, dart_port, data);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
