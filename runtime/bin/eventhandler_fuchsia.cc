// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/eventhandler.h"
#include "bin/eventhandler_fuchsia.h"

#include <errno.h>      // NOLINT
#include <fcntl.h>      // NOLINT
#include <pthread.h>    // NOLINT
#include <stdio.h>      // NOLINT
#include <string.h>     // NOLINT
#include <sys/epoll.h>  // NOLINT
#include <sys/stat.h>   // NOLINT
#include <unistd.h>     // NOLINT

#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/utils.h"

// #define EVENTHANDLER_LOGGING 1
#if defined(EVENTHANDLER_LOGGING)
#define LOG_ERR(msg, ...) Log::PrintErr(msg, ##__VA_ARGS__)
#define LOG_INFO(msg, ...) Log::Print(msg, ##__VA_ARGS__)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(EVENTHANDLER_LOGGING)

namespace dart {
namespace bin {

#if defined(EVENTHANDLER_LOGGING)
static void PrintEventMask(intptr_t fd, intptr_t events) {
  Log::PrintErr("%d ", fd);
  if ((events & EPOLLIN) != 0) {
    Log::PrintErr("EPOLLIN ");
  }
  if ((events & EPOLLPRI) != 0) {
    Log::PrintErr("EPOLLPRI ");
  }
  if ((events & EPOLLOUT) != 0) {
    Log::PrintErr("EPOLLOUT ");
  }
  if ((events & EPOLLERR) != 0) {
    Log::PrintErr("EPOLLERR ");
  }
  if ((events & EPOLLHUP) != 0) {
    Log::PrintErr("EPOLLHUP ");
  }
  if ((events & EPOLLRDHUP) != 0) {
    Log::PrintErr("EPOLLRDHUP ");
  }
  int all_events =
      EPOLLIN | EPOLLPRI | EPOLLOUT | EPOLLERR | EPOLLHUP | EPOLLRDHUP;
  if ((events & ~all_events) != 0) {
    Log::PrintErr("(and %08x) ", events & ~all_events);
  }

  Log::PrintErr("\n");
}
#endif


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
  LOG_INFO("RemoveFromEpollInstance: fd = %ld\n", di->fd());
  VOID_NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_DEL, di->fd(), NULL));
}


static void AddToEpollInstance(intptr_t epoll_fd_, DescriptorInfo* di) {
  struct epoll_event event;
  event.events = EPOLLRDHUP | di->GetPollEvents();
  if (!di->IsListeningSocket()) {
    event.events |= EPOLLET;
  }
  event.data.ptr = di;
  LOG_INFO("AddToEpollInstance: fd = %ld\n", di->fd());
  int status =
      NO_RETRY_EXPECTED(epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, di->fd(), &event));
  LOG_INFO("AddToEpollInstance: fd = %ld, status = %d\n", di->fd(), status);
#if defined(EVENTHANDLER_LOGGING)
  PrintEventMask(di->fd(), event.events);
#endif
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
  LOG_INFO("EventHandlerImplementation(): epoll_ctl: fd = %ld\n", epoll_fd_);
  int status = NO_RETRY_EXPECTED(
      epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, interrupt_fds_[0], &event));
  LOG_INFO("EventHandlerImplementation(): epoll_ctl: fd = %ld, status = %d\n",
           epoll_fd_, status);
  if (status == -1) {
    FATAL("Failed adding interrupt fd to epoll instance");
  }
}


static void DeleteDescriptorInfo(void* info) {
  DescriptorInfo* di = reinterpret_cast<DescriptorInfo*>(info);
  di->Close();
  LOG_INFO("Closed %d\n", di->fd());
  delete di;
}


EventHandlerImplementation::~EventHandlerImplementation() {
  socket_map_.Clear(DeleteDescriptorInfo);
  VOID_NO_RETRY_EXPECTED(close(epoll_fd_));
  VOID_NO_RETRY_EXPECTED(close(interrupt_fds_[0]));
  VOID_NO_RETRY_EXPECTED(close(interrupt_fds_[1]));
}


void EventHandlerImplementation::UpdateEpollInstance(intptr_t old_mask,
                                                     DescriptorInfo* di) {
  intptr_t new_mask = di->Mask();
  LOG_INFO("UpdateEpollInstance: %d old=%ld, new=%ld\n", di->fd(), old_mask,
           new_mask);
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


static ssize_t WriteToBlocking(int fd, const void* buffer, size_t count) {
  size_t remaining = count;
  char* buffer_pos = const_cast<char*>(reinterpret_cast<const char*>(buffer));
  while (remaining > 0) {
    ssize_t bytes_written = NO_RETRY_EXPECTED(write(fd, buffer_pos, remaining));
    if (bytes_written == 0) {
      return count - remaining;
    } else if (bytes_written == -1) {
      ASSERT(EAGAIN == EWOULDBLOCK);
      // Error code EWOULDBLOCK should only happen for non blocking
      // file descriptors.
      ASSERT(errno != EWOULDBLOCK);
      return -1;
    } else {
      ASSERT(bytes_written > 0);
      remaining -= bytes_written;
      buffer_pos += bytes_written;
    }
  }
  return count;
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
      WriteToBlocking(interrupt_fds_[1], &msg, kInterruptMessageSize);
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
  ssize_t bytes = NO_RETRY_EXPECTED(
      read(interrupt_fds_[0], msg, MAX_MESSAGES * kInterruptMessageSize));
  LOG_INFO("HandleInterruptFd read %ld bytes\n", bytes);
  for (ssize_t i = 0; i < bytes / kInterruptMessageSize; i++) {
    if (msg[i].id == kTimerId) {
      LOG_INFO("HandleInterruptFd read timer update\n");
      timeout_queue_.UpdateTimeout(msg[i].dart_port, msg[i].data);
    } else if (msg[i].id == kShutdownId) {
      LOG_INFO("HandleInterruptFd read shutdown\n");
      shutdown_ = true;
    } else {
      ASSERT((msg[i].data & COMMAND_MASK) != 0);
      LOG_INFO("HandleInterruptFd command\n");
      DescriptorInfo* di =
          GetDescriptorInfo(msg[i].id, IS_LISTENING_SOCKET(msg[i].data));
      if (IS_COMMAND(msg[i].data, kShutdownReadCommand)) {
        ASSERT(!di->IsListeningSocket());
        // Close the socket for reading.
        LOG_INFO("\tSHUT_RD: %d\n", di->fd());
        VOID_NO_RETRY_EXPECTED(shutdown(di->fd(), SHUT_RD));
      } else if (IS_COMMAND(msg[i].data, kShutdownWriteCommand)) {
        ASSERT(!di->IsListeningSocket());
        // Close the socket for writing.
        LOG_INFO("\tSHUT_WR: %d\n", di->fd());
        VOID_NO_RETRY_EXPECTED(shutdown(di->fd(), SHUT_WR));
      } else if (IS_COMMAND(msg[i].data, kCloseCommand)) {
        // Close the socket and free system resources and move on to next
        // message.
        intptr_t old_mask = di->Mask();
        Dart_Port port = msg[i].dart_port;
        di->RemovePort(port);
        intptr_t new_mask = di->Mask();
        UpdateEpollInstance(old_mask, di);

        LOG_INFO("\tCLOSE: %d: %lx -> %lx\n", di->fd(), old_mask, new_mask);
        intptr_t fd = di->fd();
        if (di->IsListeningSocket()) {
          // We only close the socket file descriptor from the operating
          // system if there are no other dart socket objects which
          // are listening on the same (address, port) combination.
          ListeningSocketRegistry* registry =
              ListeningSocketRegistry::Instance();

          MutexLocker locker(registry->mutex());

          if (registry->CloseSafe(fd)) {
            ASSERT(new_mask == 0);
            socket_map_.Remove(GetHashmapKeyFromFd(fd),
                               GetHashmapHashFromFd(fd));
            di->Close();
            LOG_INFO("Closed %d\n", di->fd());
            delete di;
          }
        } else {
          ASSERT(new_mask == 0);
          socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
          di->Close();
          LOG_INFO("Closed %d\n", di->fd());
          delete di;
        }

        DartUtils::PostInt32(port, 1 << kDestroyedEvent);
      } else if (IS_COMMAND(msg[i].data, kReturnTokenCommand)) {
        int count = TOKEN_COUNT(msg[i].data);
        intptr_t old_mask = di->Mask();
        LOG_INFO("\t Return Token: %d: %lx\n", di->fd(), old_mask);
        di->ReturnTokens(msg[i].dart_port, count);
        UpdateEpollInstance(old_mask, di);
      } else if (IS_COMMAND(msg[i].data, kSetEventMaskCommand)) {
        // `events` can only have kInEvent/kOutEvent flags set.
        intptr_t events = msg[i].data & EVENT_MASK;
        ASSERT(0 == (events & ~(1 << kInEvent | 1 << kOutEvent)));

        intptr_t old_mask = di->Mask();
        LOG_INFO("\t Set Event Mask: %d: %lx %lx\n", di->fd(), old_mask,
                 msg[i].data & EVENT_MASK);
        di->SetPortAndMask(msg[i].dart_port, msg[i].data & EVENT_MASK);
        UpdateEpollInstance(old_mask, di);
      } else {
        UNREACHABLE();
      }
    }
  }
  LOG_INFO("HandleInterruptFd exit\n");
}


intptr_t EventHandlerImplementation::GetPollEvents(intptr_t events,
                                                   DescriptorInfo* di) {
#ifdef EVENTHANDLER_LOGGING
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
    } else {
      DescriptorInfo* di =
          reinterpret_cast<DescriptorInfo*>(events[i].data.ptr);
      intptr_t event_mask = GetPollEvents(events[i].events, di);

      if ((event_mask & (1 << kErrorEvent)) != 0) {
        di->NotifyAllDartPorts(event_mask);
      }
      event_mask &= ~(1 << kErrorEvent);

      LOG_INFO("HandleEvents: fd=%ld events=%ld\n", di->fd(), event_mask);
      if (event_mask != 0) {
        intptr_t old_mask = di->Mask();
        Dart_Port port = di->NextNotifyDartPort(event_mask);
        ASSERT(port != 0);
        UpdateEpollInstance(old_mask, di);
        LOG_INFO("HandleEvents: Posting %ld to %ld for fd=%ld\n", event_mask,
                 port, di->fd());
        bool success = DartUtils::PostInt32(port, event_mask);
        if (!success) {
          // This can happen if e.g. the isolate that owns the port has died
          // for some reason.
          FATAL2("Failed to post event for fd %ld to port %ld", di->fd(), port);
        }
      }
    }
  }
  if (interrupt_seen) {
    // Handle after socket events, so we avoid closing a socket before we handle
    // the current events.
    HandleInterruptFd();
  }
}


int64_t EventHandlerImplementation::GetTimeout() const {
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


void EventHandlerImplementation::Poll(uword args) {
  static const intptr_t kMaxEvents = 16;
  struct epoll_event events[kMaxEvents];
  EventHandler* handler = reinterpret_cast<EventHandler*>(args);
  EventHandlerImplementation* handler_impl = &handler->delegate_;
  ASSERT(handler_impl != NULL);

  while (!handler_impl->shutdown_) {
    int64_t millis = handler_impl->GetTimeout();
    ASSERT((millis == kInfinityTimeout) || (millis >= 0));
    // TODO(US-109): When the epoll implementation is properly edge-triggered,
    // remove this sleep, which prevents the message queue from being
    // overwhelmed and leading to memory exhaustion.
    usleep(5000);
    LOG_INFO("epoll_wait(millis = %ld)\n", millis);
    intptr_t result = NO_RETRY_EXPECTED(
        epoll_wait(handler_impl->epoll_fd_, events, kMaxEvents, millis));
    ASSERT(EAGAIN == EWOULDBLOCK);
    LOG_INFO("epoll_wait(millis = %ld) -> %ld\n", millis, result);
    if (result < 0) {
      if (errno != EWOULDBLOCK) {
        perror("Poll failed");
      }
    } else {
      handler_impl->HandleTimeout();
      handler_impl->HandleEvents(events, result);
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

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
