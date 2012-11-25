// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/eventhandler.h"

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "platform/hashmap.h"
#include "platform/thread.h"
#include "platform/utils.h"


int64_t GetCurrentTimeMilliseconds() {
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    UNREACHABLE();
    return 0;
  }
  return ((static_cast<int64_t>(tv.tv_sec) * 1000000) + tv.tv_usec) / 1000;
}


static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
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
      FATAL1("Failed updating epoll instance: %s", strerror(errno));
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
  timeout_ = kInfinityTimeout;
  timeout_port_ = 0;
  shutdown_ = false;
  // The initial size passed to epoll_create is ignore on newer (>=
  // 2.6.8) Linux versions
  static const int kEpollInitialSize = 64;
  epoll_fd_ = TEMP_FAILURE_RETRY(epoll_create(kEpollInitialSize));
  if (epoll_fd_ == -1) {
    FATAL("Failed creating epoll file descriptor");
  }
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
}


EventHandlerImplementation::~EventHandlerImplementation() {
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
  intptr_t result =
      FDUtils::WriteToBlocking(interrupt_fds_[1], &msg, kInterruptMessageSize);
  if (result != kInterruptMessageSize) {
    if (result == -1) {
      perror("Interrupt message failure:");
    }
    FATAL1("Interrupt message failure. Wrote %d bytes.", result);
  }
}


bool EventHandlerImplementation::GetInterruptMessage(InterruptMessage* msg) {
  char* dst = reinterpret_cast<char*>(msg);
  int total_read = 0;
  int bytes_read =
      TEMP_FAILURE_RETRY(read(interrupt_fds_[0], dst, kInterruptMessageSize));
  if (bytes_read < 0) {
    return false;
  }
  total_read = bytes_read;
  while (total_read < kInterruptMessageSize) {
    bytes_read = TEMP_FAILURE_RETRY(read(interrupt_fds_[0],
                                         dst + total_read,
                                         kInterruptMessageSize - total_read));
    if (bytes_read > 0) {
      total_read = total_read + bytes_read;
    }
  }
  return (total_read == kInterruptMessageSize) ? true : false;
}

void EventHandlerImplementation::HandleInterruptFd() {
  InterruptMessage msg;
  while (GetInterruptMessage(&msg)) {
    if (msg.id == kTimerId) {
      timeout_ = msg.data;
      timeout_port_ = msg.dart_port;
    } else if (msg.id == kShutdownId) {
      shutdown_ = true;
    } else {
      SocketData* sd = GetSocketData(msg.id);
      if ((msg.data & (1 << kShutdownReadCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownReadCommand));
        // Close the socket for reading.
        sd->ShutdownRead();
        UpdateEpollInstance(epoll_fd_, sd);
      } else if ((msg.data & (1 << kShutdownWriteCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownWriteCommand));
        // Close the socket for writing.
        sd->ShutdownWrite();
        UpdateEpollInstance(epoll_fd_, sd);
      } else if ((msg.data & (1 << kCloseCommand)) != 0) {
        ASSERT(msg.data == (1 << kCloseCommand));
        // Close the socket and free system resources and move on to
        // next message.
        RemoveFromEpollInstance(epoll_fd_, sd);
        intptr_t fd = sd->fd();
        sd->Close();
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        delete sd;
      } else {
        // Setup events to wait for.
        sd->SetPortAndMask(msg.dart_port, msg.data);
        UpdateEpollInstance(epoll_fd_, sd);
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
    if ((events & EPOLLIN) != 0) {
      if (FDUtils::AvailableBytes(sd->fd()) != 0) {
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
            Log::PrintErr("Error recv: %s\n", strerror(errno));
          }
        }
      }
    }

    // On pipes EPOLLHUP is reported without EPOLLIN when there is no
    // more data to read.
    if (sd->IsPipe()) {
      if (((events & EPOLLIN) == 0) &&
          ((events & EPOLLHUP) != 0)) {
        event_mask = (1 << kCloseEvent);
        sd->MarkClosedRead();
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
  for (int i = 0; i < size; i++) {
    if (events[i].data.ptr != NULL) {
      SocketData* sd = reinterpret_cast<SocketData*>(events[i].data.ptr);
      intptr_t event_mask = GetPollEvents(events[i].events, sd);
      if (event_mask != 0) {
        // Unregister events for the file descriptor. Events will be
        // registered again when the current event has been handled in
        // Dart code.
        RemoveFromEpollInstance(epoll_fd_, sd);
        Dart_Port port = sd->port();
        ASSERT(port != 0);
        DartUtils::PostInt32(port, event_mask);
      }
    }
  }
  HandleInterruptFd();
}


intptr_t EventHandlerImplementation::GetTimeout() {
  if (timeout_ == kInfinityTimeout) {
    return kInfinityTimeout;
  }
  intptr_t millis = timeout_ - GetCurrentTimeMilliseconds();
  return (millis < 0) ? 0 : millis;
}


void EventHandlerImplementation::HandleTimeout() {
  if (timeout_ != kInfinityTimeout) {
    intptr_t millis = timeout_ - GetCurrentTimeMilliseconds();
    if (millis <= 0) {
      DartUtils::PostNull(timeout_port_);
      timeout_ = kInfinityTimeout;
      timeout_port_ = 0;
    }
  }
}


void EventHandlerImplementation::Poll(uword args) {
  static const intptr_t kMaxEvents = 16;
  struct epoll_event events[kMaxEvents];
  EventHandlerImplementation* handler =
      reinterpret_cast<EventHandlerImplementation*>(args);
  ASSERT(handler != NULL);
  while (!handler->shutdown_) {
    intptr_t millis = handler->GetTimeout();
    intptr_t result = TEMP_FAILURE_RETRY(epoll_wait(handler->epoll_fd_,
                                                    events,
                                                    kMaxEvents,
                                                    millis));
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


void EventHandlerImplementation::Start() {
  int result = dart::Thread::Start(&EventHandlerImplementation::Poll,
                                   reinterpret_cast<uword>(this));
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
