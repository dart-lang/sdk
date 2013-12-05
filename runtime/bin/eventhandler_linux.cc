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
#include "bin/utils.h"
#include "platform/hashmap.h"
#include "platform/thread.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kTimerId = -1;
static const int kShutdownId = -2;


intptr_t SocketData::GetPollEvents() {
  // Do not ask for EPOLLERR and EPOLLHUP explicitly as they are
  // triggered anyway.
  intptr_t events = 0;
  if (!IsClosedRead()) {
    if ((mask_ & (1 << kInEvent)) != 0) {
      events |= EPOLLIN;
    }
  }
  if (!IsClosedWrite()) {
    if ((mask_ & (1 << kOutEvent)) != 0) {
      events |= EPOLLOUT;
    }
  }
  return events;
}


// Unregister the file descriptor for a SocketData structure with epoll.
static void RemoveFromEpollInstance(intptr_t epoll_fd_, SocketData* sd) {
  if (sd->tracked_by_epoll()) {
    int status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                              EPOLL_CTL_DEL,
                                              sd->fd(),
                                              NULL));
    if (status == -1) {
      FATAL("Failed unregistering events for file descriptor");
    }
    sd->set_tracked_by_epoll(false);
  }
}


// Register the file descriptor for a SocketData structure with epoll
// if events are requested.
static void UpdateEpollInstance(intptr_t epoll_fd_, SocketData* sd) {
  struct epoll_event event;
  event.events = sd->GetPollEvents();
  event.data.ptr = sd;
  if (sd->port() != 0 && event.events != 0) {
    // Only report events once and wait for them to be re-enabled after the
    // event has been handled by the Dart code.
    event.events |= EPOLLONESHOT;
    int status = 0;
    if (sd->tracked_by_epoll()) {
      status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_MOD,
                                            sd->fd(),
                                            &event));
    } else {
      status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_ADD,
                                            sd->fd(),
                                            &event));
      sd->set_tracked_by_epoll(true);
    }
    if (status == -1) {
      // Epoll does not accept the file descriptor. It could be due to
      // already closed file descriptor, or unuspported devices, such
      // as /dev/null. In such case, mark the file descriptor as closed,
      // so dart will handle it accordingly.
      sd->set_tracked_by_epoll(false);
      sd->ShutdownRead();
      sd->ShutdownWrite();
      DartUtils::PostInt32(sd->port(), 1 << kCloseEvent);
    }
  }
}


EventHandlerImplementation::EventHandlerImplementation()
    : socket_map_(&HashMap::SamePointerValue, 16) {
  intptr_t result;
  result = TEMP_FAILURE_RETRY(pipe(interrupt_fds_));
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
  epoll_fd_ = TEMP_FAILURE_RETRY(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL("Failed creating epoll file descriptor");
  }
  FDUtils::SetCloseOnExec(epoll_fd_);
  // Register the interrupt_fd with the epoll instance.
  struct epoll_event event;
  event.events = EPOLLIN;
  event.data.ptr = NULL;
  int status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                            EPOLL_CTL_ADD,
                                            interrupt_fds_[0],
                                            &event));
  if (status == -1) {
    FATAL("Failed adding interrupt fd to epoll instance");
  }
  timer_fd_ = TEMP_FAILURE_RETRY(timerfd_create(CLOCK_REALTIME,
                                                TFD_NONBLOCK | TFD_CLOEXEC));
  if (epoll_fd_ == -1) {
    FATAL("Failed creating timerfd file descriptor");
  }
  // Register the timer_fd_ with the epoll instance.
  event.events = EPOLLIN;
  event.data.fd = timer_fd_;
  status = TEMP_FAILURE_RETRY(epoll_ctl(epoll_fd_,
                                        EPOLL_CTL_ADD,
                                        timer_fd_,
                                        &event));
  if (status == -1) {
    FATAL("Failed adding timerfd fd to epoll instance");
  }
}


EventHandlerImplementation::~EventHandlerImplementation() {
  TEMP_FAILURE_RETRY(close(epoll_fd_));
  TEMP_FAILURE_RETRY(close(timer_fd_));
  TEMP_FAILURE_RETRY(close(interrupt_fds_[0]));
  TEMP_FAILURE_RETRY(close(interrupt_fds_[1]));
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
      struct itimerspec it;
      memset(&it, 0, sizeof(it));
      if (timeout_queue_.HasTimeout()) {
        int64_t millis = timeout_queue_.CurrentTimeout();
        it.it_value.tv_sec = millis / 1000;
        it.it_value.tv_nsec = (millis % 1000) * 1000000;
      }
      timerfd_settime(timer_fd_, TFD_TIMER_ABSTIME, &it, NULL);
    } else if (msg[i].id == kShutdownId) {
      shutdown_ = true;
    } else {
      SocketData* sd = GetSocketData(msg[i].id);
      if ((msg[i].data & (1 << kShutdownReadCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kShutdownReadCommand));
        // Close the socket for reading.
        sd->ShutdownRead();
        UpdateEpollInstance(epoll_fd_, sd);
      } else if ((msg[i].data & (1 << kShutdownWriteCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kShutdownWriteCommand));
        // Close the socket for writing.
        sd->ShutdownWrite();
        UpdateEpollInstance(epoll_fd_, sd);
      } else if ((msg[i].data & (1 << kCloseCommand)) != 0) {
        ASSERT(msg[i].data == (1 << kCloseCommand));
        // Close the socket and free system resources and move on to
        // next message.
        RemoveFromEpollInstance(epoll_fd_, sd);
        intptr_t fd = sd->fd();
        if (fd == STDOUT_FILENO) {
          // If stdout, redirect fd to /dev/null.
          int null_fd = TEMP_FAILURE_RETRY(open("/dev/null", O_WRONLY));
          ASSERT(null_fd >= 0);
          VOID_TEMP_FAILURE_RETRY(dup2(null_fd, STDOUT_FILENO));
          VOID_TEMP_FAILURE_RETRY(close(null_fd));
        } else {
          sd->Close();
        }
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        delete sd;
        DartUtils::PostInt32(msg[i].dart_port, 1 << kDestroyedEvent);
      } else {
        if ((msg[i].data & (1 << kInEvent)) != 0 && sd->IsClosedRead()) {
          DartUtils::PostInt32(msg[i].dart_port, 1 << kCloseEvent);
        } else {
          // Setup events to wait for.
          sd->SetPortAndMask(msg[i].dart_port, msg[i].data);
          UpdateEpollInstance(epoll_fd_, sd);
        }
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
  intptr_t event_mask = 0;
  if (sd->IsListeningSocket()) {
    // For listening sockets the EPOLLIN event indicate that there are
    // connections ready for accept unless accompanied with one of the
    // other flags.
    if ((events & EPOLLIN) != 0) {
      if ((events & EPOLLHUP) != 0) event_mask |= (1 << kCloseEvent);
      if ((events & EPOLLERR) != 0) event_mask |= (1 << kErrorEvent);
      if (event_mask == 0) event_mask |= (1 << kInEvent);
    }
  } else {
    // Prioritize data events over close and error events.
    if ((events & (EPOLLIN | EPOLLHUP | EPOLLERR)) != 0) {
      // If we have EPOLLIN and we have available bytes, report that.
      if ((events & EPOLLIN) && FDUtils::AvailableBytes(sd->fd()) != 0) {
        event_mask = (1 << kInEvent);
      } else if ((events & EPOLLHUP) != 0) {
        // If both EPOLLHUP and EPOLLERR are reported treat it as an
        // error.
        if ((events & EPOLLERR) != 0) {
          event_mask = (1 << kErrorEvent);
        } else {
          event_mask = (1 << kCloseEvent);
        }
        sd->MarkClosedRead();
      } else if ((events & EPOLLERR) != 0) {
        event_mask = (1 << kErrorEvent);
      } else {
        if (sd->IsPipe()) {
          // When reading from stdin (either from a terminal or piped
          // input) treat EPOLLIN with 0 available bytes as
          // end-of-file.
          if (sd->fd() == STDIN_FILENO) {
            event_mask = (1 << kCloseEvent);
            sd->MarkClosedRead();
          }
        } else {
          // If EPOLLIN is set with no available data and no EPOLLHUP use
          // recv to peek for whether the other end of the socket
          // actually closed.
          char buffer;
          ssize_t bytesPeeked =
              TEMP_FAILURE_RETRY(recv(sd->fd(), &buffer, 1, MSG_PEEK));
          ASSERT(EAGAIN == EWOULDBLOCK);
          if (bytesPeeked == 0) {
            event_mask = (1 << kCloseEvent);
            sd->MarkClosedRead();
          } else if (errno != EWOULDBLOCK) {
            const int kBufferSize = 1024;
            char error_buf[kBufferSize];
            Log::PrintErr("Error recv: %s\n",
                          strerror_r(errno, error_buf, kBufferSize));
          }
        }
      }
    }

    if ((events & EPOLLOUT) != 0) {
      if ((events & EPOLLERR) != 0) {
        event_mask = (1 << kErrorEvent);
        sd->MarkClosedWrite();
      } else {
        event_mask |= (1 << kOutEvent);
      }
    }
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
      VOID_TEMP_FAILURE_RETRY(read(timer_fd_, &val, sizeof(val)));
      if (timeout_queue_.HasTimeout()) {
        DartUtils::PostNull(timeout_queue_.CurrentPort());
        timeout_queue_.RemoveCurrent();
      }
    } else {
      SocketData* sd = reinterpret_cast<SocketData*>(events[i].data.ptr);
      intptr_t event_mask = GetPollEvents(events[i].events, sd);
      if (event_mask == 0) {
        // Event not handled, re-add to epoll.
        UpdateEpollInstance(epoll_fd_, sd);
      } else {
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


void EventHandlerImplementation::Poll(uword args) {
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

#endif  // defined(TARGET_OS_LINUX)
