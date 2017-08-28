// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/eventhandler.h"
#include "bin/eventhandler_macos.h"

#include <errno.h>      // NOLINT
#include <fcntl.h>      // NOLINT
#include <pthread.h>    // NOLINT
#include <stdio.h>      // NOLINT
#include <string.h>     // NOLINT
#include <sys/event.h>  // NOLINT
#include <unistd.h>     // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

bool DescriptorInfo::HasReadEvent() {
  return (Mask() & (1 << kInEvent)) != 0;
}

bool DescriptorInfo::HasWriteEvent() {
  return (Mask() & (1 << kOutEvent)) != 0;
}

// Unregister the file descriptor for a SocketData structure with kqueue.
static void RemoveFromKqueue(intptr_t kqueue_fd_, DescriptorInfo* di) {
  if (!di->tracked_by_kqueue()) {
    return;
  }
  static const intptr_t kMaxChanges = 2;
  struct kevent events[kMaxChanges];
  EV_SET(events, di->fd(), EVFILT_READ, EV_DELETE, 0, 0, NULL);
  VOID_NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, 1, NULL, 0, NULL));
  EV_SET(events, di->fd(), EVFILT_WRITE, EV_DELETE, 0, 0, NULL);
  VOID_NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, 1, NULL, 0, NULL));
  di->set_tracked_by_kqueue(false);
}

// Update the kqueue registration for SocketData structure to reflect
// the events currently of interest.
static void AddToKqueue(intptr_t kqueue_fd_, DescriptorInfo* di) {
  ASSERT(!di->tracked_by_kqueue());
  static const intptr_t kMaxChanges = 2;
  intptr_t changes = 0;
  struct kevent events[kMaxChanges];
  int flags = EV_ADD;
  if (!di->IsListeningSocket()) {
    flags |= EV_CLEAR;
  }

  ASSERT(di->HasReadEvent() || di->HasWriteEvent());

  // Register or unregister READ filter if needed.
  if (di->HasReadEvent()) {
    EV_SET(events + changes, di->fd(), EVFILT_READ, flags, 0, 0, di);
    ++changes;
  }
  // Register or unregister WRITE filter if needed.
  if (di->HasWriteEvent()) {
    EV_SET(events + changes, di->fd(), EVFILT_WRITE, flags, 0, 0, di);
    ++changes;
  }
  ASSERT(changes > 0);
  ASSERT(changes <= kMaxChanges);
  int status =
      NO_RETRY_EXPECTED(kevent(kqueue_fd_, events, changes, NULL, 0, NULL));
  if (status == -1) {
    // TODO(dart:io): Verify that the dart end is handling this correctly.

    // kQueue does not accept the file descriptor. It could be due to
    // already closed file descriptor, or unuspported devices, such
    // as /dev/null. In such case, mark the file descriptor as closed,
    // so dart will handle it accordingly.
    di->NotifyAllDartPorts(1 << kCloseEvent);
  } else {
    di->set_tracked_by_kqueue(true);
  }
}

EventHandlerImplementation::EventHandlerImplementation()
    : socket_map_(&HashMap::SamePointerValue, 16) {
  intptr_t result;
  result = NO_RETRY_EXPECTED(pipe(interrupt_fds_));
  if (result != 0) {
    FATAL("Pipe creation failed");
  }
  if (!FDUtils::SetNonBlocking(interrupt_fds_[0])) {
    FATAL("Failed to set pipe fd non-blocking\n");
  }
  if (!FDUtils::SetCloseOnExec(interrupt_fds_[0])) {
    FATAL("Failed to set pipe fd close on exec\n");
  }
  if (!FDUtils::SetCloseOnExec(interrupt_fds_[1])) {
    FATAL("Failed to set pipe fd close on exec\n");
  }
  shutdown_ = false;

  kqueue_fd_ = NO_RETRY_EXPECTED(kqueue());
  if (kqueue_fd_ == -1) {
    FATAL("Failed creating kqueue");
  }
  if (!FDUtils::SetCloseOnExec(kqueue_fd_)) {
    FATAL("Failed to set kqueue fd close on exec\n");
  }
  // Register the interrupt_fd with the kqueue.
  struct kevent event;
  EV_SET(&event, interrupt_fds_[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
  int status = NO_RETRY_EXPECTED(kevent(kqueue_fd_, &event, 1, NULL, 0, NULL));
  if (status == -1) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    Utils::StrError(errno, error_message, kBufferSize);
    FATAL1("Failed adding interrupt fd to kqueue: %s\n", error_message);
  }
}

static void DeleteDescriptorInfo(void* info) {
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(info);
  di->Close();
  delete di;
}

EventHandlerImplementation::~EventHandlerImplementation() {
  socket_map_.Clear(DeleteDescriptorInfo);
  VOID_TEMP_FAILURE_RETRY(close(kqueue_fd_));
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[0]));
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[1]));
}

void EventHandlerImplementation::UpdateKQueueInstance(intptr_t old_mask,
                                                      DescriptorInfo* di) {
  intptr_t new_mask = di->Mask();
  if (old_mask != 0 && new_mask == 0) {
    RemoveFromKqueue(kqueue_fd_, di);
  } else if ((old_mask == 0) && (new_mask != 0)) {
    AddToKqueue(kqueue_fd_, di);
  } else if ((old_mask != 0) && (new_mask != 0) && (old_mask != new_mask)) {
    ASSERT(!di->IsListeningSocket());
    RemoveFromKqueue(kqueue_fd_, di);
    AddToKqueue(kqueue_fd_, di);
  }
}

DescriptorInfo* EventHandlerImplementation::GetDescriptorInfo(
    intptr_t fd,
    bool is_listening) {
  ASSERT(fd >= 0);
  HashMap::Entry* entry = socket_map_.Lookup(GetHashmapKeyFromFd(fd),
                                             GetHashmapHashFromFd(fd), true);
  ASSERT(entry != NULL);
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(entry->value);
  if (di == NULL) {
    // If there is no data in the hash map for this file descriptor a
    // new DescriptorInfo for the file descriptor is inserted.
    if (is_listening) {
      di = new DescriptorInfoMultiple(fd);
    } else {
      di = new DescriptorInfoSingle(fd);
    }
    entry->value = di;
  }
  ASSERT(fd == di->fd());
  return di;
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
      ASSERT((msg[i].data & COMMAND_MASK) != 0);
      Socket* socket = reinterpret_cast<Socket*>(msg[i].id);
      RefCntReleaseScope<Socket> rs(socket);
      if (socket->fd() == -1) {
        continue;
      }
      DescriptorInfo* di =
          GetDescriptorInfo(socket->fd(), IS_LISTENING_SOCKET(msg[i].data));
      if (IS_COMMAND(msg[i].data, kShutdownReadCommand)) {
        ASSERT(!di->IsListeningSocket());
        // Close the socket for reading.
        VOID_NO_RETRY_EXPECTED(shutdown(di->fd(), SHUT_RD));
      } else if (IS_COMMAND(msg[i].data, kShutdownWriteCommand)) {
        ASSERT(!di->IsListeningSocket());
        // Close the socket for writing.
        VOID_NO_RETRY_EXPECTED(shutdown(di->fd(), SHUT_WR));
      } else if (IS_COMMAND(msg[i].data, kCloseCommand)) {
        // Close the socket and free system resources and move on to next
        // message.
        intptr_t old_mask = di->Mask();
        Dart_Port port = msg[i].dart_port;
        di->RemovePort(port);
        intptr_t new_mask = di->Mask();
        UpdateKQueueInstance(old_mask, di);

        intptr_t fd = di->fd();
        if (di->IsListeningSocket()) {
          // We only close the socket file descriptor from the operating
          // system if there are no other dart socket objects which
          // are listening on the same (address, port) combination.
          ListeningSocketRegistry* registry =
              ListeningSocketRegistry::Instance();

          MutexLocker locker(registry->mutex());

          if (registry->CloseSafe(socket)) {
            ASSERT(new_mask == 0);
            socket_map_.Remove(GetHashmapKeyFromFd(fd),
                               GetHashmapHashFromFd(fd));
            di->Close();
            delete di;
            socket->SetClosedFd();
          }
        } else {
          ASSERT(new_mask == 0);
          socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
          di->Close();
          delete di;
          socket->SetClosedFd();
        }

        DartUtils::PostInt32(port, 1 << kDestroyedEvent);
      } else if (IS_COMMAND(msg[i].data, kReturnTokenCommand)) {
        intptr_t old_mask = di->Mask();
        di->ReturnTokens(msg[i].dart_port, TOKEN_COUNT(msg[i].data));
        UpdateKQueueInstance(old_mask, di);
      } else if (IS_COMMAND(msg[i].data, kSetEventMaskCommand)) {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg[i].data & EVENT_MASK;
        ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));

        intptr_t old_mask = di->Mask();
        di->SetPortAndMask(msg[i].dart_port, msg[i].data & EVENT_MASK);
        UpdateKQueueInstance(old_mask, di);
      } else {
        UNREACHABLE();
      }
    }
  }
}

#ifdef DEBUG_KQUEUE
static void PrintEventMask(intptr_t fd, struct kevent* event) {
  Log::Print("%d ", static_cast<int>(fd));

  Log::Print("filter=0x%x:", event->filter);
  if (event->filter == EVFILT_READ) {
    Log::Print("EVFILT_READ ");
  }
  if (event->filter == EVFILT_WRITE) {
    Log::Print("EVFILT_WRITE ");
  }

  Log::Print("flags: %x: ", event->flags);
  if ((event->flags & EV_EOF) != 0) {
    Log::Print("EV_EOF ");
  }
  if ((event->flags & EV_ERROR) != 0) {
    Log::Print("EV_ERROR ");
  }
  if ((event->flags & EV_CLEAR) != 0) {
    Log::Print("EV_CLEAR ");
  }
  if ((event->flags & EV_ADD) != 0) {
    Log::Print("EV_ADD ");
  }
  if ((event->flags & EV_DELETE) != 0) {
    Log::Print("EV_DELETE ");
  }

  Log::Print("- fflags: %d ", event->fflags);
  Log::Print("- data: %ld ", event->data);
  Log::Print("(available %d) ", static_cast<int>(FDUtils::AvailableBytes(fd)));
  Log::Print("\n");
}
#endif

intptr_t EventHandlerImplementation::GetEvents(struct kevent* event,
                                               DescriptorInfo* di) {
#ifdef DEBUG_KQUEUE
  PrintEventMask(di->fd(), event);
#endif
  intptr_t event_mask = 0;
  if (di->IsListeningSocket()) {
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
      if (event_mask == 0) {
        event_mask |= (1 << kInEvent);
      }
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

void EventHandlerImplementation::HandleEvents(struct kevent* events, int size) {
  bool interrupt_seen = false;
  for (int i = 0; i < size; i++) {
    // If flag EV_ERROR is set it indicates an error in kevent processing.
    if ((events[i].flags & EV_ERROR) != 0) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      Utils::StrError(events[i].data, error_message, kBufferSize);
      FATAL1("kevent failed %s\n", error_message);
    }
    if (events[i].udata == NULL) {
      interrupt_seen = true;
    } else {
      DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(events[i].udata);
      const intptr_t old_mask = di->Mask();
      const intptr_t event_mask = GetEvents(events + i, di);
      if ((event_mask & (1 << kErrorEvent)) != 0) {
        di->NotifyAllDartPorts(event_mask);
        UpdateKQueueInstance(old_mask, di);
      } else if (event_mask != 0) {
        Dart_Port port = di->NextNotifyDartPort(event_mask);
        ASSERT(port != 0);
        UpdateKQueueInstance(old_mask, di);
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
  int64_t millis =
      timeout_queue_.CurrentTimeout() - TimerUtils::GetCurrentMonotonicMillis();
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

void EventHandlerImplementation::EventHandlerEntry(uword args) {
  static const intptr_t kMaxEvents = 16;
  struct kevent events[kMaxEvents];
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);

  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT(millis == kInfinityTimeout || millis >= 0);
    if (millis > kMaxInt32) {
      millis = kMaxInt32;
    }
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
      Utils::StrError(errno, error_message, kBufferSize);
      FATAL1("kevent failed %s\n", error_message);
    } else {
      handler_impl->HandleTimeout();
      handler_impl->HandleEvents(events, result);
    }
  }
  DEBUG_ASSERT(ReferenceCounted<Socket>::instances() == 0);
  handler->NotifyShutdownDone();
}

void EventHandlerImplementation::Start(EventHandler* handler) {
  int result = Thread::Start(&EventHandlerImplementation::EventHandlerEntry,
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

#endif  // defined(HOST_OS_MACOS)
