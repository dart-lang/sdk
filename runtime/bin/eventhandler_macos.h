// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_MACOS_H_
#define BIN_EVENTHANDLER_MACOS_H_

#if !defined(BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_macos.h directly; use eventhandler.h instead.
#endif

#include <unistd.h>
#include <sys/socket.h>

#include "platform/hashmap.h"

class InterruptMessage {
 public:
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
};


enum PortDataFlags {
  kClosedRead = 0,
  kClosedWrite = 1,
};


class SocketData {
 public:
  explicit SocketData(intptr_t fd)
      : fd_(fd),
        port_(0),
        mask_(0),
        flags_(0),
        read_tracked_by_kqueue_(false),
        write_tracked_by_kqueue_(false) {
    ASSERT(fd_ != -1);
  }

  bool HasReadEvent();
  bool HasWriteEvent();

  void ShutdownRead() {
    shutdown(fd_, SHUT_RD);
    MarkClosedRead();
  }

  void ShutdownWrite() {
    shutdown(fd_, SHUT_WR);
    MarkClosedWrite();
  }

  void Close() {
    port_ = 0;
    mask_ = 0;
    flags_ = 0;
    close(fd_);
    fd_ = -1;
  }

  bool IsListeningSocket() { return (mask_ & (1 << kListeningSocket)) != 0; }
  bool IsPipe() { return (mask_ & (1 << kPipe)) != 0; }
  bool IsClosedRead() { return (flags_ & (1 << kClosedRead)) != 0; }
  bool IsClosedWrite() { return (flags_ & (1 << kClosedWrite)) != 0; }

  void MarkClosedRead() { flags_ |= (1 << kClosedRead); }
  void MarkClosedWrite() { flags_ |= (1 << kClosedWrite); }

  void SetPortAndMask(Dart_Port port, intptr_t mask) {
    ASSERT(fd_ != -1);
    port_ = port;
    mask_ = mask;
  }

  intptr_t fd() { return fd_; }
  Dart_Port port() { return port_; }
  intptr_t mask() { return mask_; }
  bool read_tracked_by_kqueue() { return read_tracked_by_kqueue_; }
  void set_read_tracked_by_kqueue(bool value) {
    read_tracked_by_kqueue_ = value;
  }
  bool write_tracked_by_kqueue() { return write_tracked_by_kqueue_; }
  void set_write_tracked_by_kqueue(bool value) {
    write_tracked_by_kqueue_ = value;
  }

 private:
  intptr_t fd_;
  Dart_Port port_;
  intptr_t mask_;
  intptr_t flags_;
  bool read_tracked_by_kqueue_;
  bool write_tracked_by_kqueue_;
};


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  // Gets the socket data structure for a given file
  // descriptor. Creates a new one if one is not found.
  SocketData* GetSocketData(intptr_t fd);
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start();
  void Shutdown();

 private:
  intptr_t GetTimeout();
  bool GetInterruptMessage(InterruptMessage* msg);
  void HandleEvents(struct kevent* events, int size);
  void HandleTimeout();
  static void EventHandlerEntry(uword args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetEvents(struct kevent* event, SocketData* sd);
  static void* GetHashmapKeyFromFd(intptr_t fd);
  static uint32_t GetHashmapHashFromFd(intptr_t fd);

  HashMap socket_map_;
  int64_t timeout_;  // Time for next timeout.
  Dart_Port timeout_port_;
  bool shutdown_;
  int interrupt_fds_[2];
  int kqueue_fd_;
};


#endif  // BIN_EVENTHANDLER_MACOS_H_
