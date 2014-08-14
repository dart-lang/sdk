// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/eventhandler.h"

#include <errno.h>  // NOLINT
#include <pthread.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/epoll.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <fcntl.h>  // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/utils.h"


// Android doesn't define EPOLLRDHUP.
#if !defined(EPOLLRDHUP)
#define EPOLLRDHUP 0x2000
#endif  // !defined(EPOLLRDHUP)


namespace dart {
namespace bin {

static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
static const int kTimerId = -1;
static const int kShutdownId = -2;


intptr_t SocketData::GetPollEvents() {
  // Do not ask for EPOLLERR and EPOLLHUP explicitly as they are
  // triggered anyway.
  intptr_t events = 0;
  if ((mask_ & (1 << kInEvent)) != 0) {
    events |= EPOLLIN;
  }
  if ((mask_ & (1 << kOutEvent)) != 0) {
    events |= EPOLLOUT;
  }
  return events;
}


// Unregister the file descriptor for a SocketData structure with epoll.
static void RemoveFromEpollInstance(intptr_t epoll_fd_, SocketData* sd) {
  VOID_NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_,
                                   EPOLL_CTL_DEL,
                                   sd->fd(),
                                   NULL));
}


static void AddToEpollInstance(intptr_t epoll_fd_, SocketData* sd) {
  struct epoll_event event;
  event.events = EPOLLRDHUP | sd->GetPollEvents();
  if (!sd->IsListeningSocket()) {
    event.events |= EPOLLET;
  }
  event.data.ptr = sd;
  int status = NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_,
                                           EPOLL_CTL_ADD,
                                           sd->fd(),
                                           &event));
  if (status == -1) {
    // Epoll does not accept the file descriptor. It could be due to
    // already closed file descriptor, or unuspported devices, such
    // as /dev/null. In such case, mark the file descriptor as closed,
    // so dart will handle it accordingly.
    DartUtils::PostInt32(sd->port(), 1 << kCloseEvent);
  }
}


EventHandlerImplementation::EventHandlerImplementation()
    : socket_map_(&HashMap::SamePointerValue, 16) {
  intptr_t result;
  result = NO_RETRY_EXPECTED(pipe(interrupt_fds_));
  if (result != 0) {
    FATAL("Pipe creation failed");
  }
  FDUtils::SetNonBlocking(interrupt_fds_[0]);
  FDUtils::SetCloseOnExec(interrupt_fds_[0]);
  FDUtils::SetCloseOnExec(interrupt_fds_[1]);
  shutdown_ = false;
  // The initial size passed to epoll_create is ignore on newer (>=
  // 2.6.8) Linux versions
  static const int kEpollInitialSize = 64;
  epoll_fd_ = NO_RETRY_EXPECTED(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL("Failed creating epoll file descriptor");
  }
  FDUtils::SetCloseOnExec(epoll_fd_);
  // Register the interrupt_fd with the epoll instance.
  struct epoll_event event;
  event.events = EPOLLIN;
  event.data.ptr = NULL;
  int status = NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_ADD,
                                            interrupt_fds_[0],
                                            &event));
  if (status == -1) {
    FATAL("Failed adding interrupt fd to epoll instance");
  }
}


EventHandlerImplementation::~EventHandlerImplementation() {
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[0]));
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[1]));
}


SocketData* EventHandlerImplementation::GetSocketData(intptr_t fd) {
  ASSERT(fd >= 0);
  HashMap::Entry* entry = socket_map_.Lookup(
      GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd), true);
  ASSERT(entry != NULL);
  SocketData* sd = reinterpret_cast<SocketData*>(entry->value);
  if (sd == NULL) {
    // If there is no data in the hash map for this file descriptor a
    // new SocketData for the file descriptor is inserted.
    sd = new SocketData(fd);
    entry->value = sd;
  }
  ASSERT(fd == sd->fd());
  return sd;
}


void EventHandlerImplementation::WakeupHandler(intptr_t id,
                                               Dart_Port dart_port,
                                               int64_t data) {
  InterruptMessage msg;
  msg.id = id;
  msg.dart_port = dart_port;
  msg.data = data;
  // WriteToBlocking will write up to 512 bytes atomically, and since our msg
  // is smaller than 512, we don't need a thread lock.
  // See: http://linux.die.net/man/7/pipe, section 'Pipe_buf'.
  ASSERT(kInterruptMessageSize < PIPE_BUF);
  intptr_t result =
      FDUtils::WriteToBlocking(interrupt_fds_[1], &msg, kInterruptMessageSize);
  if (result != kInterruptMessageSize) {
    if (result == -1) {
      perror("Interrupt message failure:");
    }
    FATAL1("Interrupt message failure. Wrote %d bytes.", result);
  }
}


void EventHandlerImplementation::HandleInterruptFd() {
  const intptr_t MAX_MESSAGES = kInterruptMessageSize;
  InterruptMessage msg[MAX_MESSAGES];
  ssize_t bytes = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
      read(interrupt_fds_[0], msg, MAX_MESSAGES * kInterruptMessageSize));
  for (ssize_t i = 0; i < bytes / kInterruptMessageSize; i++) {
    if (msg[i].id == kTimerId) {
      timeout_queue_.UpdateTimeout(msg[i].dart_port, msg[i].data);
    } else if (msg[i].id == kShutdownId) {
      shutdown_ = true;
    } else {
      SocketData* sd = GetSocketData(msg[i].id);
      if ((msg[i].data & (1 << kShutdownReadCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kShutdownReadCommand));
        // Close the socket for reading.
        shutdown(sd->fd(), SHUT_RD);
      } else if ((msg[i].data & (1 << kShutdownWriteCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kShutdownWriteCommand));
        // Close the socket for writing.
        shutdown(sd->fd(), SHUT_WR);
      } else if ((msg[i].data & (1 << kCloseCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kCloseCommand));
        // Close the socket and free system resources and move on to
        // next message.
        RemoveFromEpollInstance(epoll_fd_, sd);
        intptr_t fd = sd->fd();
        sd->Close();
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        delete sd;
        DartUtils::PostInt32(msg[i].dart_port, 1 << kDestroyedEvent);
      } else if ((msg[i].data & (1 << kReturnTokenCommand)) != 0) {
        int count = msg[i].data & ((1 << kReturnTokenCommand) - 1);
        for (int i = 0; i < count; i++) {
          if (sd->ReturnToken()) {
            AddToEpollInstance(epoll_fd_, sd);
          }
        }
      } else {
        // Setup events to wait for.
        sd->SetPortAndMask(msg[i].dart_port, msg[i].data);
        AddToEpollInstance(epoll_fd_, sd);
      }
    }
  }
}

#ifdef DEBUG_POLL
static void PrintEventMask(intptr_t fd, intptr_t events) {
  Log::Print("%d ", fd);
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
  Log::Print("(available %d) ", FDUtils::AvailableBytes(fd));

  Log::Print("\n");
}
#endif

intptr_t EventHandlerImplementation::GetPollEvents(intptr_t events,
                                                   SocketData* sd) {
#ifdef DEBUG_POLL
  PrintEventMask(sd->fd(), events);
#endif
  if (events & EPOLLERR) {
    // Return error only if EPOLLIN is present.
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
  bool interrupt_seen = false;
  for (int i = 0; i < size; i++) {
    if (events[i].data.ptr == NULL) {
      interrupt_seen = true;
    } else {
      SocketData* sd = reinterpret_cast<SocketData*>(events[i].data.ptr);
      intptr_t event_mask = GetPollEvents(events[i].events, sd);
      if (event_mask != 0) {
        if (sd->TakeToken()) {
          // Took last token, remove from epoll.
          RemoveFromEpollInstance(epoll_fd_, sd);
        }
        Dart_Port port = sd->port();
        ASSERT(port != 0);
        DartUtils::PostInt32(port, event_mask);
      }
    }
  }
  if (interrupt_seen) {
    // Handle after socket events, so we avoid closing a socket before we handle
    // the current events.
    HandleInterruptFd();
  }
}


int64_t EventHandlerImplementation::GetTimeout() {
  if (!timeout_queue_.HasTimeout()) {
    return kInfinityTimeout;
  }
  int64_t millis = timeout_queue_.CurrentTimeout() -
      TimerUtils::GetCurrentTimeMilliseconds();
  return (millis < 0) ? 0 : millis;
}


void EventHandlerImplementation::HandleTimeout() {
  if (timeout_queue_.HasTimeout()) {
    int64_t millis = timeout_queue_.CurrentTimeout() -
        TimerUtils::GetCurrentTimeMilliseconds();
    if (millis <= 0) {
      DartUtils::PostNull(timeout_queue_.CurrentPort());
      timeout_queue_.RemoveCurrent();
    }
  }
}


void EventHandlerImplementation::Poll(uword args) {
  ThreadSignalBlocker signal_blocker(SIGPROF);
  static const intptr_t kMaxEvents = 16;
  struct epoll_event events[kMaxEvents];
  EventHandlerImplementation* handler =
      reinterpret_cast<EventHandlerImplementation*>(args);
  ASSERT(handler != NULL);
  while (!handler->shutdown_) {
    int64_t millis = handler->GetTimeout();
    ASSERT(millis == kInfinityTimeout || millis >= 0);
    if (millis > kMaxInt32) millis = kMaxInt32;
    intptr_t result = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
        epoll_wait(handler->epoll_fd_, events, kMaxEvents, millis));
    ASSERT(EAGAIN == EWOULDBLOCK);
    if (result == -1) {
      if (errno != EWOULDBLOCK) {
        perror("Poll failed");
      }
    } else {
      handler->HandleTimeout();
      handler->HandleEvents(events, result);
    }
  }
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
                                          intptr_t data) {
  WakeupHandler(id, dart_port, data);
}


void* EventHandlerImplementation::GetHashmapKeyFromFd(intptr_t fd) {
  // The hashmap does not support keys with value 0.
  return reinterpret_cast<void*>(fd + 1);
}


uint32_t EventHandlerImplementation::GetHashmapHashFromFd(intptr_t fd) {
  // The hashmap does not support keys with value 0.
  return dart::Utils::WordHash(fd + 1);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
