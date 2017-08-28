// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "bin/eventhandler.h"
#include "bin/eventhandler_linux.h"

#include <errno.h>        // NOLINT
#include <fcntl.h>        // NOLINT
#include <pthread.h>      // NOLINT
#include <stdio.h>        // NOLINT
#include <string.h>       // NOLINT
#include <sys/epoll.h>    // NOLINT
#include <sys/stat.h>     // NOLINT
#include <sys/timerfd.h>  // NOLINT
#include <unistd.h>       // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

intptr_t DescriptorInfo::GetPollEvents() {
  // Do not ask for EPOLLERR and EPOLLHUP explicitly as they are
  // triggered anyway.
  intptr_t events = 0;
  if ((Mask() & (1 << kInEvent)) != 0) {
    events |= EPOLLIN;
  }
  if ((Mask() & (1 << kOutEvent)) != 0) {
    events |= EPOLLOUT;
  }
  return events;
}

// Unregister the file descriptor for a DescriptorInfo structure with
// epoll.
static void RemoveFromEpollInstance(intptr_t epoll_fd_, DescriptorInfo* di) {
  VOID_NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_DEL, di->fd(), NULL));
}

static void AddToEpollInstance(intptr_t epoll_fd_, DescriptorInfo* di) {
  struct epoll_event event;
  event.events = EPOLLRDHUP | di->GetPollEvents();
  if (!di->IsListeningSocket()) {
    event.events |= EPOLLET;
  }
  event.data.ptr = di;
  int status =
      NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, di->fd(), &event));
  if (status == -1) {
    // TODO(dart:io): Verify that the dart end is handling this correctly.

    // Epoll does not accept the file descriptor. It could be due to
    // already closed file descriptor, or unuspported devices, such
    // as /dev/null. In such case, mark the file descriptor as closed,
    // so dart will handle it accordingly.
    di->NotifyAllDartPorts(1 << kCloseEvent);
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
    FATAL("Failed to set pipe fd non blocking\n");
  }
  if (!FDUtils::SetCloseOnExec(interrupt_fds_[0])) {
    FATAL("Failed to set pipe fd close on exec\n");
  }
  if (!FDUtils::SetCloseOnExec(interrupt_fds_[1])) {
    FATAL("Failed to set pipe fd close on exec\n");
  }
  shutdown_ = false;
  // The initial size passed to epoll_create is ignore on newer (>=
  // 2.6.8) Linux versions
  static const int kEpollInitialSize = 64;
  epoll_fd_ = NO_RETRY_EXPECTED(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL1("Failed creating epoll file descriptor: %i", errno);
  }
  if (!FDUtils::SetCloseOnExec(epoll_fd_)) {
    FATAL("Failed to set epoll fd close on exec\n");
  }
  // Register the interrupt_fd with the epoll instance.
  struct epoll_event event;
  event.events = EPOLLIN;
  event.data.ptr = NULL;
  int status = NO_RETRY_EXPECTED(
      epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, interrupt_fds_[0], &event));
  if (status == -1) {
    FATAL("Failed adding interrupt fd to epoll instance");
  }
  timer_fd_ = NO_RETRY_EXPECTED(timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC));
  if (timer_fd_ == -1) {
    FATAL1("Failed creating timerfd file descriptor: %i", errno);
  }
  // Register the timer_fd_ with the epoll instance.
  event.events = EPOLLIN;
  event.data.fd = timer_fd_;
  status =
      NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, timer_fd_, &event));
  if (status == -1) {
    FATAL2("Failed adding timerfd fd(%i) to epoll instance: %i", timer_fd_,
           errno);
  }
}

static void DeleteDescriptorInfo(void* info) {
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(info);
  di->Close();
  delete di;
}

EventHandlerImplementation::~EventHandlerImplementation() {
  socket_map_.Clear(DeleteDescriptorInfo);
  VOID_TEMP_FAILURE_RETRY(close(epoll_fd_));
  VOID_TEMP_FAILURE_RETRY(close(timer_fd_));
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[0]));
  VOID_TEMP_FAILURE_RETRY(close(interrupt_fds_[1]));
}

void EventHandlerImplementation::UpdateEpollInstance(intptr_t old_mask,
                                                     DescriptorInfo* di) {
  intptr_t new_mask = di->Mask();
  if ((old_mask != 0) && (new_mask == 0)) {
    RemoveFromEpollInstance(epoll_fd_, di);
  } else if ((old_mask == 0) && (new_mask != 0)) {
    AddToEpollInstance(epoll_fd_, di);
  } else if ((old_mask != 0) && (new_mask != 0) && (old_mask != new_mask)) {
    ASSERT(!di->IsListeningSocket());
    RemoveFromEpollInstance(epoll_fd_, di);
    AddToEpollInstance(epoll_fd_, di);
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
  // See: http://linux.die.net/man/7/pipe, section 'Pipe_buf'.
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
  ssize_t bytes = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
      read(interrupt_fds_[0], msg, MAX_MESSAGES * kInterruptMessageSize));
  for (ssize_t i = 0; i < bytes / kInterruptMessageSize; i++) {
    if (msg[i].id == kTimerId) {
      timeout_queue_.UpdateTimeout(msg[i].dart_port, msg[i].data);
      UpdateTimerFd();
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
        UpdateEpollInstance(old_mask, di);

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
        int count = TOKEN_COUNT(msg[i].data);
        intptr_t old_mask = di->Mask();
        di->ReturnTokens(msg[i].dart_port, count);
        UpdateEpollInstance(old_mask, di);
      } else if (IS_COMMAND(msg[i].data, kSetEventMaskCommand)) {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg[i].data & EVENT_MASK;
        ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));

        intptr_t old_mask = di->Mask();
        di->SetPortAndMask(msg[i].dart_port, msg[i].data & EVENT_MASK);
        UpdateEpollInstance(old_mask, di);
      } else {
        UNREACHABLE();
      }
    }
  }
}

void EventHandlerImplementation::UpdateTimerFd() {
  struct itimerspec it;
  memset(&it, 0, sizeof(it));
  if (timeout_queue_.HasTimeout()) {
    int64_t millis = timeout_queue_.CurrentTimeout();
    it.it_value.tv_sec = millis / 1000;
    it.it_value.tv_nsec = (millis % 1000) * 1000000;
  }
  VOID_NO_RETRY_EXPECTED(
      timerfd_settime(timer_fd_, TFD_TIMER_ABSTIME, &it, NULL));
}

#ifdef DEBUG_POLL
static void PrintEventMask(intptr_t fd, intptr_t events) {
  Log::Print("%d ", fd);
  if ((events & EPOLLIN) != 0) {
    Log::Print("EPOLLIN ");
  }
  if ((events & EPOLLPRI) != 0) {
    Log::Print("EPOLLPRI ");
  }
  if ((events & EPOLLOUT) != 0) {
    Log::Print("EPOLLOUT ");
  }
  if ((events & EPOLLERR) != 0) {
    Log::Print("EPOLLERR ");
  }
  if ((events & EPOLLHUP) != 0) {
    Log::Print("EPOLLHUP ");
  }
  if ((events & EPOLLRDHUP) != 0) {
    Log::Print("EPOLLRDHUP ");
  }
  int all_events =
      EPOLLIN | EPOLLPRI | EPOLLOUT | EPOLLERR | EPOLLHUP | EPOLLRDHUP;
  if ((events & ~all_events) != 0) {
    Log::Print("(and %08x) ", events & ~all_events);
  }
  Log::Print("(available %d) ", FDUtils::AvailableBytes(fd));

  Log::Print("\n");
}
#endif

intptr_t EventHandlerImplementation::GetPollEvents(intptr_t events,
                                                   DescriptorInfo* di) {
#ifdef DEBUG_POLL
  PrintEventMask(di->fd(), events);
#endif
  if ((events & EPOLLERR) != 0) {
    // Return error only if EPOLLIN is present.
    return ((events & EPOLLIN) != 0) ? (1 << kErrorEvent) : 0;
  }
  intptr_t event_mask = 0;
  if ((events & EPOLLIN) != 0) {
    event_mask |= (1 << kInEvent);
  }
  if ((events & EPOLLOUT) != 0) {
    event_mask |= (1 << kOutEvent);
  }
  if ((events & (EPOLLHUP | EPOLLRDHUP)) != 0) {
    event_mask |= (1 << kCloseEvent);
  }
  return event_mask;
}

void EventHandlerImplementation::HandleEvents(struct epoll_event* events,
                                              int size) {
  bool interrupt_seen = false;
  for (int i = 0; i < size; i++) {
    if (events[i].data.ptr == NULL) {
      interrupt_seen = true;
    } else if (events[i].data.fd == timer_fd_) {
      int64_t val;
      VOID_TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
          read(timer_fd_, &val, sizeof(val)));
      if (timeout_queue_.HasTimeout()) {
        DartUtils::PostNull(timeout_queue_.CurrentPort());
        timeout_queue_.RemoveCurrent();
      }
      UpdateTimerFd();
    } else {
      DescriptorInfo* di =
          reinterpret_cast<DescriptorInfo*>(events[i].data.ptr);
      const intptr_t old_mask = di->Mask();
      const intptr_t event_mask = GetPollEvents(events[i].events, di);
      if ((event_mask & (1 << kErrorEvent)) != 0) {
        di->NotifyAllDartPorts(event_mask);
        UpdateEpollInstance(old_mask, di);
      } else if (event_mask != 0) {
        Dart_Port port = di->NextNotifyDartPort(event_mask);
        ASSERT(port != 0);
        UpdateEpollInstance(old_mask, di);
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

void EventHandlerImplementation::Poll(uword args) {
  ThreadSignalBlocker signal_blocker(SIGPROF);
  static const intptr_t kMaxEvents = 16;
  struct epoll_event events[kMaxEvents];
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);

  while (!handler_impl->shutdown_) {
    intptr_t result = TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(
        epoll_wait(handler_impl->epoll_fd_, events, kMaxEvents, -1));
    ASSERT(EAGAIN == EWOULDBLOCK);
    if (result <= 0) {
      if (errno != EWOULDBLOCK) {
        perror("Poll failed");
      }
    } else {
      handler_impl->HandleEvents(events, result);
    }
  }
  DEBUG_ASSERT(ReferenceCounted<Socket>::instances() == 0);
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

#endif  // defined(HOST_OS_LINUX)
