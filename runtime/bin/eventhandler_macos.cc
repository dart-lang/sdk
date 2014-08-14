// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/eventhandler.h"

#include <errno.h>  // NOLINT
#include <pthread.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/event.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <fcntl.h>  // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
static const int kTimerId = -1;
static const int kShutdownId = -2;


bool SocketData::HasReadEvent() {
  return (mask_ & (1 << kInEvent)) != 0;
}


bool SocketData::HasWriteEvent() {
  return (mask_ & (1 << kOutEvent)) != 0;
}


// Unregister the file descriptor for a SocketData structure with kqueue.
static void RemoveFromKqueue(intptr_t kqueue_fd_, SocketData* sd) {
  if (!sd->tracked_by_kqueue()) return;
  static const intptr_t kMaxChanges = 2;
  struct kevent events[kMaxChanges];
  EV_SET(events, sd->fd(), EVFILT_READ, EV_DELETE, 0, 0, NULL);
  VOID_NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, 1, NULL, 0, NULL));
  EV_SET(events, sd->fd(), EVFILT_WRITE, EV_DELETE, 0, 0, NULL);
  VOID_NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, 1, NULL, 0, NULL));
  sd->set_tracked_by_kqueue(false);
}


// Update the kqueue registration for SocketData structure to reflect
// the events currently of interest.
static void AddToKqueue(intptr_t kqueue_fd_, SocketData* sd) {
  ASSERT(!sd->tracked_by_kqueue());
  static const intptr_t kMaxChanges = 2;
  intptr_t changes = 0;
  struct kevent events[kMaxChanges];
  int flags = EV_ADD;
  if (!sd->IsListeningSocket()) {
    flags |= EV_CLEAR;
  }
  // Register or unregister READ filter if needed.
  if (sd->HasReadEvent()) {
    EV_SET(events + changes,
           sd->fd(),
           EVFILT_READ,
           flags,
           0,
           0,
           sd);
    ++changes;
  }
  // Register or unregister WRITE filter if needed.
  if (sd->HasWriteEvent()) {
    EV_SET(events + changes,
           sd->fd(),
           EVFILT_WRITE,
           flags,
           0,
           0,
           sd);
    ++changes;
  }
  ASSERT(changes > 0);
  ASSERT(changes <= kMaxChanges);
  int status =
      NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, changes, NULL, 0, NULL));
  if (status == -1) {
    // kQueue does not accept the file descriptor. It could be due to
    // already closed file descriptor, or unuspported devices, such
    // as /dev/null. In such case, mark the file descriptor as closed,
    // so dart will handle it accordingly.
    DartUtils::PostInt32(sd->port(), 1 << kCloseEvent);
  } else {
    sd->set_tracked_by_kqueue(true);
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

  kqueue_fd_ = NO_RETRY_EXPECTED(kqueue());
  if (kqueue_fd_ == -1) {
    FATAL("Failed creating kqueue");
  }
  FDUtils::SetCloseOnExec(kqueue_fd_);
  // Register the interrupt_fd with the kqueue.
  struct kevent event;
  EV_SET(&event, interrupt_fds_[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
  int status = NO_RETRY_EXPECTED(kevent(kqueue_fd_, &event, 1, NULL, 0, NULL));
  if (status == -1) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    FATAL1("Failed adding interrupt fd to kqueue: %s\n", error_message);
  }
}


EventHandlerImplementation::~EventHandlerImplementation() {
  VOID_TEMP_FAILURE_RETRY(close(kqueue_fd_));
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
  ASSERT(kInterruptMessageSize < PIPE_BUF);
  intptr_t result =
      FDUtils::WriteToBlocking(interrupt_fds_[1], &msg, kInterruptMessageSize);
  if (result != kInterruptMessageSize) {
    if (result == -1) {
      perror("Interrupt message failure:");
    }
    FATAL1("Interrupt message failure. Wrote %" Pd " bytes.", result);
  }
}


void EventHandlerImplementation::HandleInterruptFd() {
  const intptr_t MAX_MESSAGES = kInterruptMessageSize;
  InterruptMessage msg[MAX_MESSAGES];
  ssize_t bytes = TEMP_FAILURE_RETRY(
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
        // Close the socket and free system resources.
        RemoveFromKqueue(kqueue_fd_, sd);
        intptr_t fd = sd->fd();
        VOID_TEMP_FAILURE_RETRY(close(fd));
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        delete sd;
        DartUtils::PostInt32(msg[i].dart_port, 1 << kDestroyedEvent);
      } else if ((msg[i].data & (1 << kReturnTokenCommand)) != 0) {
        int count = msg[i].data & ((1 << kReturnTokenCommand) - 1);
        for (int i = 0; i < count; i++) {
          if (sd->ReturnToken()) {
            AddToKqueue(kqueue_fd_, sd);
          }
        }
      } else {
        // Setup events to wait for.
        ASSERT((msg[i].data > 0) && (msg[i].data < kIntptrMax));
        ASSERT(sd->port() == 0);
        sd->SetPortAndMask(msg[i].dart_port,
                           static_cast<intptr_t>(msg[i].data));
        AddToKqueue(kqueue_fd_, sd);
      }
    }
  }
}

#ifdef DEBUG_KQUEUE
static void PrintEventMask(intptr_t fd, struct kevent* event) {
  Log::Print("%d ", static_cast<int>(fd));
  Log::Print("filter=0x%x:", event->filter);
  if (event->filter == EVFILT_READ) Log::Print("EVFILT_READ ");
  if (event->filter == EVFILT_WRITE) Log::Print("EVFILT_WRITE ");
  Log::Print("flags: %x: ", event->flags);
  if ((event->flags & EV_EOF) != 0) Log::Print("EV_EOF ");
  if ((event->flags & EV_ERROR) != 0) Log::Print("EV_ERROR ");
  if ((event->flags & EV_CLEAR) != 0) Log::Print("EV_CLEAR ");
  if ((event->flags & EV_ADD) != 0) Log::Print("EV_ADD ");
  if ((event->flags & EV_DELETE) != 0) Log::Print("EV_DELETE ");
  Log::Print("- fflags: %d ", event->fflags);
  Log::Print("- data: %ld ", event->data);
  Log::Print("(available %d) ",
      static_cast<int>(FDUtils::AvailableBytes(fd)));
  Log::Print("\n");
}
#endif


intptr_t EventHandlerImplementation::GetEvents(struct kevent* event,
                                               SocketData* sd) {
#ifdef DEBUG_KQUEUE
  PrintEventMask(sd->fd(), event);
#endif
  intptr_t event_mask = 0;
  if (sd->IsListeningSocket()) {
    // On a listening socket the READ event means that there are
    // connections ready to be accepted.
    if (event->filter == EVFILT_READ) {
      if ((event->flags & EV_EOF) != 0) {
        if (event->fflags != 0) {
          event_mask |= (1 << kErrorEvent);
        } else {
          event_mask |= (1 << kCloseEvent);
        }
      }
      if (event_mask == 0) event_mask |= (1 << kInEvent);
    } else {
      UNREACHABLE();
    }
  } else {
    // Prioritize data events over close and error events.
    if (event->filter == EVFILT_READ) {
      event_mask = (1 << kInEvent);
      if ((event->flags & EV_EOF) != 0) {
        if (event->fflags != 0) {
          event_mask = (1 << kErrorEvent);
        } else {
          event_mask |= (1 << kCloseEvent);
        }
      }
    } else if (event->filter == EVFILT_WRITE) {
      event_mask |= (1 << kOutEvent);
      if ((event->flags & EV_EOF) != 0) {
        if (event->fflags != 0) {
          event_mask = (1 << kErrorEvent);
        }
      }
    } else {
      UNREACHABLE();
    }
  }

  return event_mask;
}


void EventHandlerImplementation::HandleEvents(struct kevent* events,
                                              int size) {
  bool interrupt_seen = false;
  for (int i = 0; i < size; i++) {
    // If flag EV_ERROR is set it indicates an error in kevent processing.
    if ((events[i].flags & EV_ERROR) != 0) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      strerror_r(events[i].data, error_message, kBufferSize);
      FATAL1("kevent failed %s\n", error_message);
    }
    if (events[i].udata == NULL) {
      interrupt_seen = true;
    } else {
      SocketData* sd = reinterpret_cast<SocketData*>(events[i].udata);
      intptr_t event_mask = GetEvents(events + i, sd);
      if (event_mask != 0) {
        if (sd->TakeToken()) {
          // Took last token, remove from epoll.
          RemoveFromKqueue(kqueue_fd_, sd);
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


void EventHandlerImplementation::EventHandlerEntry(uword args) {
  static const intptr_t kMaxEvents = 16;
  struct kevent events[kMaxEvents];
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);
  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT(millis == kInfinityTimeout || millis >= 0);
    if (millis > kMaxInt32) millis = kMaxInt32;
    // NULL pointer timespec for infinite timeout.
    ASSERT(kInfinityTimeout < 0);
    struct timespec* timeout = NULL;
    struct timespec ts;
    if (millis >= 0) {
      int32_t millis32 = static_cast<int32_t>(millis);
      int32_t secs = millis32 / 1000;
      ts.tv_sec = secs;
      ts.tv_nsec = (millis32 - (secs * 1000)) * 1000000;
      timeout = &ts;
    }
    // We have to use TEMP_FAILURE_RETRY for mac, as kevent can modify the
    // current sigmask.
    intptr_t result = TEMP_FAILURE_RETRY(
        kevent(handler_impl->kqueue_fd_, NULL, 0, events, kMaxEvents, timeout));
    if (result == -1) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      strerror_r(errno, error_message, kBufferSize);
      FATAL1("kevent failed %s\n", error_message);
    } else {
      handler_impl->HandleTimeout();
      handler_impl->HandleEvents(events, result);
    }
  }
  delete handler;
}


void EventHandlerImplementation::Start(EventHandler* handler) {
  int result =
      Thread::Start(&EventHandlerImplementation::EventHandlerEntry,
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

#endif  // defined(TARGET_OS_MACOS)
