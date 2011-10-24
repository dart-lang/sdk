// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

#include "bin/eventhandler.h"
#include "bin/fdutils.h"


int64_t GetCurrentTimeMilliseconds() {
  struct timeval tv;
  if (gettimeofday(&tv, NULL) < 0) {
    UNREACHABLE();
    return 0;
  }
  return ((static_cast<int64_t>(tv.tv_sec) * 1000000) + tv.tv_usec) / 1000;
}


static const int kInitialPortMapSize = 128;
static const int kPortMapGrowingFactor = 2;
static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
static const int kTimerId = -1;


EventHandlerImplementation::EventHandlerImplementation() {
  intptr_t result;
  port_map_entries_ = 0;
  port_map_size_ = kInitialPortMapSize;
  port_map_ = reinterpret_cast<PortData*>(calloc(port_map_size_,
                                                 sizeof(PortData)));
  ASSERT(port_map_ != NULL);
  result = pipe(interrupt_fds_);
  if (result != 0) {
    FATAL("Pipe creation failed");
  }
  FDUtils::SetNonBlocking(interrupt_fds_[0]);
  FDUtils::SetNonBlocking(interrupt_fds_[1]);
  timeout_ = kInfinityTimeout;
  timeout_port_ = 0;
}


EventHandlerImplementation::~EventHandlerImplementation() {
  free(port_map_);
  close(interrupt_fds_[0]);
  close(interrupt_fds_[1]);
}


// TODO(hpayer): Use hash table instead of array.
void EventHandlerImplementation::SetPort(intptr_t fd,
                                 Dart_Port dart_port,
                                 intptr_t mask) {
  assert(fd >= 0);
  if (fd >= port_map_size_) {
    intptr_t new_port_map_size = port_map_size_;
    do {
      new_port_map_size = new_port_map_size * kPortMapGrowingFactor;
    } while (fd >= new_port_map_size);
    size_t new_port_map_bytes = new_port_map_size * sizeof(PortData);
    port_map_ = reinterpret_cast<PortData*>(realloc(port_map_,
                                                    new_port_map_bytes));
    ASSERT(port_map_ != NULL);
    size_t port_map_bytes = port_map_size_ * sizeof(PortData);
    memset(port_map_ + port_map_size_,
           0,
           new_port_map_bytes - port_map_bytes);
    port_map_size_ = new_port_map_size;
  }

  /*
   * Only change the port map entries count if SetPort changes
   * the port map state.
   */
  if (dart_port == 0 && PortFor(fd) != 0) {
    port_map_entries_--;
  } else if (dart_port != 0 && PortFor(fd) == 0) {
    port_map_entries_++;
  }
  port_map_[fd].dart_port = dart_port;
  port_map_[fd].mask = mask;
}


Dart_Port EventHandlerImplementation::PortFor(intptr_t fd) {
  return port_map_[fd].dart_port;
}


void EventHandlerImplementation::RegisterFdWakeup(intptr_t id,
                                                  Dart_Port dart_port,
                                                  intptr_t data) {
  WakeupHandler(id, dart_port, data);
}


void EventHandlerImplementation::CloseFd(intptr_t id) {
  SetPort(id, 0, 0);
  close(id);
}


void EventHandlerImplementation::UnregisterFdWakeup(intptr_t id) {
  WakeupHandler(id, 0, 0);
}


void EventHandlerImplementation::UnregisterFd(intptr_t id) {
  SetPort(id, 0, 0);
}


void EventHandlerImplementation::WakeupHandler(intptr_t id,
                                               Dart_Port dart_port,
                                               int64_t data) {
  InterruptMessage msg;
  msg.id = id;
  msg.dart_port = dart_port;
  msg.data = data;
  intptr_t result =
    write(interrupt_fds_[1], &msg, kInterruptMessageSize);
  if (result != kInterruptMessageSize) {
    perror("Interrupt message failure");
  }
}


void EventHandlerImplementation::SetPollEvents(struct pollfd* pollfds,
                                               intptr_t mask) {
  /*
   * We do not set POLLERR and POLLHUP explicitly since they are triggered
   * anyway.
   */
  if ((mask & (1 << kInEvent)) != 0) {
    pollfds->events |= POLLIN;
  }
  if ((mask & (1 << kOutEvent)) != 0) {
    pollfds->events |= POLLOUT;
  }
}


struct pollfd* EventHandlerImplementation::GetPollFds(intptr_t* pollfds_size) {
  struct pollfd* pollfds;

  intptr_t numPollfds = 1 + port_map_entries_;
  pollfds = reinterpret_cast<struct pollfd*>(calloc(sizeof(struct pollfd),
                                                    numPollfds));
  pollfds[0].fd = interrupt_fds_[0];
  pollfds[0].events |= POLLIN;

  // TODO(hpayer): optimize the following iteration over the hash map
  int j = 1;
  for (int i = 0; i < port_map_size_; i++) {
    if (port_map_[i].dart_port != 0) {
      // Fd is added to the poll set.
      pollfds[j].fd = i;
      SetPollEvents(&pollfds[j], port_map_[i].mask);
      j++;
    }
  }
  *pollfds_size = numPollfds;
  return pollfds;
}


bool EventHandlerImplementation::GetInterruptMessage(InterruptMessage* msg) {
  int total_read = 0;
  int bytes_read = read(interrupt_fds_[0], msg, kInterruptMessageSize);
  if (bytes_read < 0) {
    return false;
  }
  total_read = bytes_read;
  while (total_read < kInterruptMessageSize) {
    bytes_read = read(interrupt_fds_[0],
                  msg + total_read,
                  kInterruptMessageSize - total_read);
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
    } else if ((msg.data & (1 << kCloseCommand)) != 0) {
      /*
       * A close event happened in dart, we have to explicitly unregister
       * the fd and close the fd.
       */
      CloseFd(msg.id);
    } else {
      SetPort(msg.id, msg.dart_port, msg.data);
    }
  }
}


intptr_t EventHandlerImplementation::GetPollEvents(struct pollfd* pollfd) {
  intptr_t event_mask = 0;
  /*
   * We prioritize the events in the following order.
   */
  if ((pollfd->revents & POLLIN) != 0) {
    if (FDUtils::AvailableBytes(pollfd->fd) != 0) {
      event_mask = (1 << kInEvent);
    } else if ((pollfd->revents & POLLHUP) != 0) {
      event_mask = (1 << kCloseEvent);
    } else if ((pollfd->revents & POLLERR) != 0) {
      event_mask = (1 << kErrorEvent);
    } else {
      /*
       * Accept event.
       */
      event_mask = (1 << kInEvent);
    }
  }

  if ((pollfd->revents & POLLOUT) != 0) {
    event_mask |= (1 << kOutEvent);
  }

  return event_mask;
}


void EventHandlerImplementation::HandleEvents(struct pollfd* pollfds,
                                              int pollfds_size,
                                              int result_size) {
  if ((pollfds[0].revents & POLLIN) != 0) {
    result_size -= 1;
  }
  if (result_size > 0) {
    for (int i = 1; i < pollfds_size; i++) {
     /*
      * The fd is unregistered. It gets re-registered when the request
      * was handled by dart.
      */
      intptr_t event_mask = GetPollEvents(&pollfds[i]);
      if (event_mask != 0) {
        intptr_t fd = pollfds[i].fd;
        Dart_Port port = PortFor(fd);
        assert(port != 0);
        UnregisterFd(fd);
        Dart_PostIntArray(port, 1, &event_mask);
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
      Dart_PostIntArray(timeout_port_, 0, NULL);
      timeout_ = kInfinityTimeout;
      timeout_port_ = 0;
    }
  }
}


void* EventHandlerImplementation::Poll(void* args) {
  intptr_t pollfds_size;
  struct pollfd* pollfds;
  EventHandlerImplementation* handler =
      reinterpret_cast<EventHandlerImplementation*>(args);
  while (1) {
    pollfds = handler->GetPollFds(&pollfds_size);
    intptr_t millis = handler->GetTimeout();
    intptr_t result = poll(pollfds, pollfds_size, millis);
    if (result == -1) {
      perror("Poll failed");
    } else {
      handler->HandleTimeout();
      handler->HandleEvents(pollfds, pollfds_size, result);
    }
    free(pollfds);
  }
  return NULL;
}


void EventHandlerImplementation::StartEventHandler() {
  pthread_t handler_thread;
  int result = pthread_create(&handler_thread,
                              NULL,
                              &EventHandlerImplementation::Poll,
                              this);
  if (result != 0) {
    FATAL("Create start event handler thread");
  }
}


void EventHandlerImplementation::SendData(intptr_t id,
                                          Dart_Port dart_port,
                                          intptr_t data) {
  RegisterFdWakeup(id, dart_port, data);
}
