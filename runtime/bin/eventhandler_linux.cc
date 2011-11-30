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


static const int kInitialPortMapSize = 16;
static const int kPortMapGrowingFactor = 2;
static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
static const int kTimerId = -1;


intptr_t SocketData::GetPollEvents() {
  // Do not ask for POLLERR and POLLHUP explicitly as they are
  // triggered anyway.
  intptr_t events = 0;
  if (!IsClosedRead()) {
    if ((mask_ & (1 << kInEvent)) != 0) {
      events |= POLLIN;
    }
  }
  if (!IsClosedWrite()) {
    if ((mask_ & (1 << kOutEvent)) != 0) {
      events |= POLLOUT;
    }
  }
  return events;
}


EventHandlerImplementation::EventHandlerImplementation() {
  intptr_t result;
  socket_map_size_ = kInitialPortMapSize;
  socket_map_ = reinterpret_cast<SocketData*>(calloc(socket_map_size_,
                                                     sizeof(SocketData)));
  ASSERT(socket_map_ != NULL);
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
  free(socket_map_);
  close(interrupt_fds_[0]);
  close(interrupt_fds_[1]);
}


// TODO(hpayer): Use hash table instead of array.
SocketData* EventHandlerImplementation::GetSocketData(intptr_t fd) {
  ASSERT(fd >= 0);
  if (fd >= socket_map_size_) {
    intptr_t new_socket_map_size = socket_map_size_;
    do {
      new_socket_map_size = new_socket_map_size * kPortMapGrowingFactor;
    } while (fd >= new_socket_map_size);
    size_t new_socket_map_bytes = new_socket_map_size * sizeof(SocketData);
    socket_map_ = reinterpret_cast<SocketData*>(realloc(socket_map_,
                                                      new_socket_map_bytes));
    ASSERT(socket_map_ != NULL);
    size_t socket_map_bytes = socket_map_size_ * sizeof(SocketData);
    memset(socket_map_ + socket_map_size_,
           0,
           new_socket_map_bytes - socket_map_bytes);
    socket_map_size_ = new_socket_map_size;
  }

  SocketData* sd = socket_map_ + fd;
  sd->set_fd(fd);  // For now just make sure the fd is set.
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
    write(interrupt_fds_[1], &msg, kInterruptMessageSize);
  if (result != kInterruptMessageSize) {
    perror("Interrupt message failure");
  }
}


struct pollfd* EventHandlerImplementation::GetPollFds(intptr_t* pollfds_size) {
  struct pollfd* pollfds;

  // Calculate the number of file descriptors to poll on.
  intptr_t numPollfds = 1;
  for (int i = 0; i < socket_map_size_; i++) {
    SocketData* sd = &socket_map_[i];
    if (sd->port() > 0 && sd->GetPollEvents() != 0) numPollfds++;
  }

  pollfds = reinterpret_cast<struct pollfd*>(calloc(sizeof(struct pollfd),
                                                    numPollfds));
  pollfds[0].fd = interrupt_fds_[0];
  pollfds[0].events |= POLLIN;

  // TODO(hpayer): optimize the following iteration over the hash map
  int j = 1;
  for (int i = 0; i < socket_map_size_; i++) {
    SocketData* sd = &socket_map_[i];
    intptr_t events = sd->GetPollEvents();
    if (sd->port() > 0 && events != 0) {
      // Fd is added to the poll set.
      pollfds[j].fd = sd->fd();
      pollfds[j].events = events;
      j++;
    }
  }
  ASSERT(numPollfds == j);
  *pollfds_size = j;
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
    } else {
      SocketData* sd = GetSocketData(msg.id);
      if ((msg.data & (1 << kShutdownReadCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownReadCommand));
        // Close the socket for reading.
        sd->ShutdownRead();
      } else if ((msg.data & (1 << kShutdownWriteCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownWriteCommand));
        // Close the socket for writing.
        sd->ShutdownWrite();
      } else if ((msg.data & (1 << kCloseCommand)) != 0) {
        ASSERT(msg.data == (1 << kCloseCommand));
        // Close the socket and free system resources.
        sd->Close();
      } else {
        // Setup events to wait for.
        sd->SetPortAndMask(msg.dart_port, msg.data);
      }
    }
  }
}

#ifdef DEBUG_POLL
static void PrintEventMask(struct pollfd* pollfd) {
  printf("%d ", pollfd->fd);
  if ((pollfd->revents & POLLIN) != 0) printf("POLLIN ");
  if ((pollfd->revents & POLLPRI) != 0) printf("POLLPRI ");
  if ((pollfd->revents & POLLOUT) != 0) printf("POLLOUT ");
  if ((pollfd->revents & POLLERR) != 0) printf("POLLERR ");
  if ((pollfd->revents & POLLHUP) != 0) printf("POLLHUP ");
  if ((pollfd->revents & POLLRDHUP) != 0) printf("POLLRDHUP ");
  if ((pollfd->revents & POLLNVAL) != 0) printf("POLLNVAL ");
  int all_events = POLLIN | POLLPRI | POLLOUT |
                   POLLERR | POLLHUP | POLLRDHUP | POLLNVAL;
  if ((pollfd->revents & ~all_events) != 0) {
    printf("(and %08x) ", pollfd->revents & ~all_events);
  }
  printf("(available %d) ", FDUtils::AvailableBytes(pollfd->fd));

  printf("\n");
}
#endif

intptr_t EventHandlerImplementation::GetPollEvents(struct pollfd* pollfd) {
#ifdef DEBUG_POLL
  printf("Poll events:\n");
  if (pollfd->fd != interrupt_fds_[0]) PrintEventMask(pollfd);
#endif
  intptr_t event_mask = 0;
  SocketData* sd = GetSocketData(pollfd->fd);
  if (sd->IsListeningSocket()) {
    // For listening sockets the POLLIN event indicate that there are
    // connections ready for accept unless accompanied with one of the
    // other flags.
    if ((pollfd->revents & POLLIN) != 0) {
      if ((pollfd->revents & POLLHUP) != 0) event_mask |= (1 << kCloseEvent);
      if ((pollfd->revents & POLLERR) != 0) event_mask |= (1 << kErrorEvent);
      if (event_mask == 0) event_mask |= (1 << kInEvent);
    }
  } else {
    if ((pollfd->revents & POLLNVAL) != 0) {
      return 0;
    }

    // Prioritize data events over close and error events.
    if ((pollfd->revents & POLLIN) != 0) {
      if (FDUtils::AvailableBytes(pollfd->fd) != 0) {
        event_mask = (1 << kInEvent);
      } else if (((pollfd->revents & POLLHUP) != 0)) {
        event_mask = (1 << kCloseEvent);
        sd->MarkClosedRead();
      } else if ((pollfd->revents & POLLERR) != 0) {
        event_mask = (1 << kErrorEvent);
      } else {
        if (sd->IsPipe()) {
          // For stdin when reading from a terminal treat POLLIN with 0
          // available bytes as end-of-file.
          if (sd->fd() == STDIN_FILENO && isatty(sd->fd())) {
            event_mask = (1 << kCloseEvent);
            sd->MarkClosedRead();
          }
        } else {
          // If POLLIN is set with no available data and no POLLHUP use
          // recv to peek for whether the other end of the socket
          // actually closed.
          char buffer;
          ssize_t bytesPeeked = recv(sd->fd(), &buffer, 1, MSG_PEEK);
          if (bytesPeeked == 0) {
            event_mask = (1 << kCloseEvent);
            sd->MarkClosedRead();
          } else if (errno != EAGAIN) {
            fprintf(stderr, "Error recv: %s\n", strerror(errno));
          }
        }
      }
    }

    // On pipes POLLHUP is reported without POLLIN when there is no
    // more data to read.
    if (sd->IsPipe()) {
      if (((pollfd->revents & POLLIN) == 0) &&
          ((pollfd->revents & POLLHUP) != 0)) {
        event_mask = (1 << kCloseEvent);
        sd->MarkClosedRead();
      }
    }

    if ((pollfd->revents & POLLOUT) != 0) {
      if ((pollfd->revents & POLLERR) != 0) {
        event_mask = (1 << kErrorEvent);
        sd->MarkClosedWrite();
      } else {
        event_mask |= (1 << kOutEvent);
      }
    }
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
        SocketData* sd = GetSocketData(fd);
        Dart_Port port = sd->port();
        ASSERT(port != 0);
        sd->Unregister();
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
      if (errno != EAGAIN && errno != EINTR) {
        perror("Poll failed");
      }
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
  WakeupHandler(id, dart_port, data);
}
