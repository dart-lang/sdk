// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/eventhandler.h"

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/event.h>
#include <sys/time.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/hashmap.h"
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


bool SocketData::HasReadEvent() {
  return !IsClosedRead() && ((mask_ & (1 << kInEvent)) != 0);
}


bool SocketData::HasWriteEvent() {
  return !IsClosedWrite() && ((mask_ & (1 << kOutEvent)) != 0);
}


// Unregister the file descriptor for a SocketData structure with kqueue.
static void RemoveFromKqueue(intptr_t kqueue_fd_, SocketData* sd) {
  static const intptr_t kMaxChanges = 2;
  intptr_t changes = 0;
  struct kevent events[kMaxChanges];
  if (sd->read_tracked_by_kqueue()) {
    EV_SET(events + changes, sd->fd(), EVFILT_READ, EV_DELETE, 0, 0, NULL);
    ++changes;
    sd->set_read_tracked_by_kqueue(false);
  }
  if (sd->write_tracked_by_kqueue()) {
    EV_SET(events + changes, sd->fd(), EVFILT_WRITE, EV_DELETE, 0, 0, sd);
    ++changes;
    sd->set_write_tracked_by_kqueue(false);
  }
  if (changes > 0) {
    ASSERT(changes <= kMaxChanges);
    int status =
      TEMP_FAILURE_RETRY(kevent(kqueue_fd_, events, changes, NULL, 0, NULL));
    if (status == -1) {
      FATAL1("Failed deleting events from kqueue: %s\n", strerror(errno));
    }
  }
}


// Update the kqueue registration for SocketData structure to reflect
// the events currently of interest.
static void UpdateKqueue(intptr_t kqueue_fd_, SocketData* sd) {
  static const intptr_t kMaxChanges = 2;
  intptr_t changes = 0;
  struct kevent events[kMaxChanges];
  if (sd->port() != 0) {
    // Register or unregister READ filter if needed.
    if (sd->HasReadEvent()) {
      if (!sd->read_tracked_by_kqueue()) {
        EV_SET(events + changes, sd->fd(), EVFILT_READ, EV_ADD, 0, 0, sd);
        ++changes;
        sd->set_read_tracked_by_kqueue(true);
      }
    } else if (sd->read_tracked_by_kqueue()) {
      EV_SET(events + changes, sd->fd(), EVFILT_READ, EV_DELETE, 0, 0, NULL);
      ++changes;
      sd->set_read_tracked_by_kqueue(false);
    }
    // Register or unregister WRITE filter if needed.
    if (sd->HasWriteEvent()) {
      if (!sd->write_tracked_by_kqueue()) {
        EV_SET(events + changes, sd->fd(), EVFILT_WRITE, EV_ADD, 0, 0, sd);
        ++changes;
        sd->set_write_tracked_by_kqueue(true);
      }
    } else if (sd->write_tracked_by_kqueue()) {
      EV_SET(events + changes, sd->fd(), EVFILT_WRITE, EV_DELETE, 0, 0, NULL);
      ++changes;
      sd->set_write_tracked_by_kqueue(false);
    }
  }
  if (changes > 0) {
    ASSERT(changes <= kMaxChanges);
    int status =
      TEMP_FAILURE_RETRY(kevent(kqueue_fd_, events, changes, NULL, 0, NULL));
    if (status == -1) {
      FATAL1("Failed updating kqueue: %s\n", strerror(errno));
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

  kqueue_fd_ = TEMP_FAILURE_RETRY(kqueue());
  if (kqueue_fd_ == -1) {
    FATAL("Failed creating kqueue");
  }
  // Register the interrupt_fd with the kqueue.
  struct kevent event;
  EV_SET(&event, interrupt_fds_[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
  int status = TEMP_FAILURE_RETRY(kevent(kqueue_fd_, &event, 1, NULL, 0, NULL));
  if (status == -1) {
    FATAL1("Failed adding interrupt fd to kqueue: %s\n", strerror(errno));
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
  int total_read = 0;
  int bytes_read =
      TEMP_FAILURE_RETRY(read(interrupt_fds_[0], msg, kInterruptMessageSize));
  if (bytes_read < 0) {
    return false;
  }
  total_read = bytes_read;
  while (total_read < kInterruptMessageSize) {
    bytes_read = TEMP_FAILURE_RETRY(read(interrupt_fds_[0],
                                         msg + total_read,
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
    } else {
      SocketData* sd = GetSocketData(msg.id);
      if ((msg.data & (1 << kShutdownReadCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownReadCommand));
        // Close the socket for reading.
        sd->ShutdownRead();
        UpdateKqueue(kqueue_fd_, sd);
      } else if ((msg.data & (1 << kShutdownWriteCommand)) != 0) {
        ASSERT(msg.data == (1 << kShutdownWriteCommand));
        // Close the socket for writing.
        sd->ShutdownWrite();
        UpdateKqueue(kqueue_fd_, sd);
      } else if ((msg.data & (1 << kCloseCommand)) != 0) {
        ASSERT(msg.data == (1 << kCloseCommand));
        // Close the socket and free system resources.
        RemoveFromKqueue(kqueue_fd_, sd);
        intptr_t fd = sd->fd();
        sd->Close();
        socket_map_.Remove(GetHashmapKeyFromFd(fd), GetHashmapHashFromFd(fd));
        delete sd;
      } else {
        // Setup events to wait for.
        sd->SetPortAndMask(msg.dart_port, msg.data);
        UpdateKqueue(kqueue_fd_, sd);
      }
    }
  }
}

#ifdef DEBUG_KQUEUE
static void PrintEventMask(intptr_t fd, struct kevent* event) {
  printf("%d ", static_cast<int>(fd));
  if (event->filter == EVFILT_READ) printf("EVFILT_READ ");
  if (event->filter == EVFILT_WRITE) printf("EVFILT_WRITE ");
  printf("flags: %x: ", event->flags);
  if ((event->flags & EV_EOF) != 0) printf("EV_EOF ");
  if ((event->flags & EV_ERROR) != 0) printf("EV_ERROR ");
  printf("- fflags: %d ", event->fflags);
  printf("(available %d) ", static_cast<int>(FDUtils::AvailableBytes(fd)));
  printf("\n");
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
    }
  } else {
    // Prioritize data events over close and error events.
    if (event->filter == EVFILT_READ) {
      if (FDUtils::AvailableBytes(sd->fd()) != 0) {
         event_mask = (1 << kInEvent);
      } else if ((event->flags & EV_EOF) != 0) {
        if (event->fflags != 0) {
          event_mask |= (1 << kErrorEvent);
        } else {
          event_mask |= (1 << kCloseEvent);
        }
        sd->MarkClosedRead();
      }
    }

    if (event->filter == EVFILT_WRITE) {
      if ((event->flags & EV_EOF) != 0) {
        if (event->fflags != 0) {
          event_mask |= (1 << kErrorEvent);
        } else {
          event_mask |= (1 << kCloseEvent);
        }
        // If the receiver closed for reading, close for writing,
        // update the registration with kqueue, and do not report a
        // write event.
        sd->MarkClosedWrite();
        UpdateKqueue(kqueue_fd_, sd);
      } else {
        event_mask |= (1 << kOutEvent);
      }
    }
  }

  return event_mask;
}


void EventHandlerImplementation::HandleEvents(struct kevent* events,
                                              int size) {
  for (int i = 0; i < size; i++) {
    // If flag EV_ERROR is set it indicates an error in kevent processing.
    if ((events[i].flags & EV_ERROR) != 0) {
      FATAL1("kevent failed %s\n", strerror(events[i].data));
    }
    if (events[i].udata != NULL) {
      SocketData* sd = reinterpret_cast<SocketData*>(events[i].udata);
      intptr_t event_mask = GetEvents(events + i, sd);
      if (event_mask != 0) {
        // Unregister events for the file descriptor. Events will be
        // registered again when the current event has been handled in
        // Dart code.
        RemoveFromKqueue(kqueue_fd_, sd);
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


void EventHandlerImplementation::EventHandlerEntry(uword args) {
  static const intptr_t kMaxEvents = 16;
  struct kevent events[kMaxEvents];
  EventHandlerImplementation* handler =
      reinterpret_cast<EventHandlerImplementation*>(args);
  ASSERT(handler != NULL);
  while (1) {
    intptr_t millis = handler->GetTimeout();
    // NULL pointer timespec for infinite timeout.
    ASSERT(kInfinityTimeout < 0);
    struct timespec* timeout = NULL;
    struct timespec ts;
    if (millis >= 0) {
      ts.tv_sec = millis / 1000;
      ts.tv_nsec = (millis - (ts.tv_sec * 1000)) * 1000000;
      timeout = &ts;
    }
    intptr_t result = TEMP_FAILURE_RETRY(kevent(handler->kqueue_fd_,
                                                NULL,
                                                0,
                                                events,
                                                kMaxEvents,
                                                timeout));
    if (result == -1) {
      FATAL1("kevent failed %s\n", strerror(errno));
    } else {
      handler->HandleTimeout();
      handler->HandleEvents(events, result);
    }
  }
}


void EventHandlerImplementation::StartEventHandler() {
  int result =
      dart::Thread::Start(&EventHandlerImplementation::EventHandlerEntry,
                          reinterpret_cast<uword>(this));
  if (result != 0) {
    FATAL1("Failed to start event handler thread %d", result);
  }
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
