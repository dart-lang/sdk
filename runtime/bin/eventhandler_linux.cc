// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/eventhandler.h"

#include <errno.h>  // NOLINT
#include <pthread.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/epoll.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <sys/timerfd.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <fcntl.h>  // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "platform/hashmap.h"
#include "platform/thread.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

static const int kTimerId = -1;


static void AddToEpollInstance(intptr_t epoll_fd_,
                               int fd, Dart_Port port,
                               int mask) {
  struct epoll_event event;
  event.events = EPOLLET | EPOLLRDHUP;
  if ((mask & (1 << kInEvent)) != 0) event.events |= EPOLLIN;
  if ((mask & (1 << kOutEvent)) != 0) event.events |= EPOLLOUT;
  // Be sure we don't collide with the TIMER_BIT.
  if (port == ILLEGAL_PORT) {
    FATAL("Illigal port sent to event handler");
  }
  event.data.u64 = port;
  int status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_ADD,
                                            fd,
                                            &event));
  if (status == -1) {
    // Epoll does not accept the file descriptor. It could be due to
    // already closed file descriptor, or unuspported devices, such
    // as /dev/null. In such case, mark the file descriptor as closed,
    // so dart will handle it accordingly.
    DartUtils::PostInt32(port, 1 << kCloseEvent);
  }
}


EventHandlerImplementation::EventHandlerImplementation() : shutdown_(false) {
  // The initial size passed to epoll_create is ignore on newer (>=
  // 2.6.8) Linux versions
  static const int kEpollInitialSize = 64;
  epoll_fd_ = TEMP_FAILURE_RETRY(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL1("Failed creating epoll file descriptor: %i", errno);
  }
  FDUtils::SetCloseOnExec(epoll_fd_);
  timer_fd_ = TEMP_FAILURE_RETRY(timerfd_create(CLOCK_REALTIME, TFD_CLOEXEC));
  if (timer_fd_ == -1) {
    FATAL1("Failed creating timerfd file descriptor: %i", errno);
  }
  // Register the timer_fd_ with the epoll instance.
  struct epoll_event event;
  event.events = EPOLLIN;
  event.data.u64 = ILLEGAL_PORT;  // Use ILLEGAL_PORT to identify timer-fd.
  int status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_ADD,
                                            timer_fd_,
                                            &event));
  if (status == -1) {
    FATAL2(
        "Failed adding timerfd fd(%i) to epoll instance: %i", timer_fd_, errno);
  }
}


EventHandlerImplementation::~EventHandlerImplementation() {
  TEMP_FAILURE_RETRY(close(epoll_fd_));
  TEMP_FAILURE_RETRY(close(timer_fd_));
}

#ifdef DEBUG_POLL
static void PrintEventMask(intptr_t events) {
  // TODO(ajohnsen): When DEBUG_POLL is enabled, we could add the fd to the
  // epoll-data as well.
  if ((events & EPOLLIN) != 0) Log::Print("EPOLLIN ");
  if ((events & EPOLLPRI) != 0) Log::Print("EPOLLPRI ");
  if ((events & EPOLLOUT) != 0) Log::Print("EPOLLOUT ");
  if ((events & EPOLLERR) != 0) Log::Print("EPOLLERR ");
  if ((events & EPOLLHUP) != 0) Log::Print("EPOLLHUP ");
  if ((events & EPOLLRDHUP) != 0) Log::Print("EPOLLRDHUP ");
  int all_events = EPOLLIN | EPOLLPRI | EPOLLOUT |
      EPOLLERR | EPOLLHUP | EPOLLRDHUP;
  if ((events & ~all_events) != 0) {
    Log::Print("(and %08x) ", events & ~all_events);
  }

  Log::Print("\n");
}
#endif

intptr_t EventHandlerImplementation::GetPollEvents(intptr_t events) {
#ifdef DEBUG_POLL
  PrintEventMask(events);
#endif
  if (events & EPOLLERR) {
    // Return only error if EPOLLIN is present.
    return (events & EPOLLIN) ? (1 << kErrorEvent) : 0;
  }
  intptr_t event_mask = 0;
  if (events & EPOLLIN) event_mask |= (1 << kInEvent);
  if (events & EPOLLOUT) event_mask |= (1 << kOutEvent);
  if (events & (EPOLLHUP | EPOLLRDHUP)) event_mask |= (1 << kCloseEvent);
  return event_mask;
}


void EventHandlerImplementation::HandleEvents(struct epoll_event* events,
                                              int size) {
  for (int i = 0; i < size; i++) {
    uint64_t data = events[i].data.u64;
    // ILLEGAL_PORT is used to identify timer-fd.
    if (data == ILLEGAL_PORT) {
      int64_t val;
      VOID_TEMP_FAILURE_RETRY(read(timer_fd_, &val, sizeof(val)));
      timer_mutex_.Lock();
      if (timeout_queue_.HasTimeout()) {
        DartUtils::PostNull(timeout_queue_.CurrentPort());
        timeout_queue_.RemoveCurrent();
      }
      timer_mutex_.Unlock();
    } else {
      int32_t event_mask = GetPollEvents(events[i].events);
      if (event_mask != 0) {
        Dart_Port port = data;
        ASSERT(port != 0);
        DartUtils::PostInt32(port, event_mask);
      }
    }
  }
}


void EventHandlerImplementation::Poll(uword args) {
  // Main event-handler thread loop.
  static const intptr_t kMaxEvents = 16;
  struct epoll_event events[kMaxEvents];
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);
  while (!handler_impl->shutdown_) {
    intptr_t result = TEMP_FAILURE_RETRY(epoll_wait(handler_impl->epoll_fd_,
                                                    events,
                                                    kMaxEvents,
                                                    -1));
    ASSERT(EAGAIN == EWOULDBLOCK);
    if (result <= 0) {
      if (errno != EWOULDBLOCK) {
        perror("Poll failed");
      }
    } else {
      handler_impl->HandleEvents(events, result);
    }
  }
  delete handler;
}


void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = dart::Thread::Start(&EventHandlerImplementation::Poll,
                                   reinterpret_cast<uword>(handler));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }
}


void EventHandlerImplementation::Shutdown() {
  shutdown_ = true;
}


void EventHandlerImplementation::Notify(intptr_t id,
                                        Dart_Port dart_port,
                                        int64_t data) {
  // This method is called by isolates, that is, not in the event-handler
  // thread.
  if (id == kTimerId) {
    // Lock this region, as multiple isolates may attempt to update
    // timeout_queue_.
    // TODO(ajohnsen): Consider using a timer-fd per isolate to avoid the lock.
    timer_mutex_.Lock();
    timeout_queue_.UpdateTimeout(dart_port, data);
    struct itimerspec it;
    memset(&it, 0, sizeof(it));
    if (timeout_queue_.HasTimeout()) {
      int64_t millis = timeout_queue_.CurrentTimeout();
      it.it_value.tv_sec = millis / 1000;
      it.it_value.tv_nsec = (millis % 1000) * 1000000;
    }
    timerfd_settime(timer_fd_, TFD_TIMER_ABSTIME, &it, NULL);
    timer_mutex_.Unlock();
  } else {
    if ((data & (1 << kShutdownReadCommand)) != 0) {
      ASSERT(data == (1 << kShutdownReadCommand));
      // Close the socket for reading.
      shutdown(id, SHUT_RD);
    } else if ((data & (1 << kShutdownWriteCommand)) != 0) {
      ASSERT(data == (1 << kShutdownWriteCommand));
      // Close the socket for writing.
      shutdown(id, SHUT_WR);
    } else if ((data & (1 << kCloseCommand)) != 0) {
      ASSERT(data == (1 << kCloseCommand));
      // Close the socket and free system resources and move on to
      // next message.
      // This will also remove the file descriptor from epoll.
      Socket::Close(id);
      DartUtils::PostInt32(dart_port, 1 << kDestroyedEvent);
    } else {
      // Add to epoll - this is the first time we see it.
      AddToEpollInstance(epoll_fd_, id, dart_port, data);
    }
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
