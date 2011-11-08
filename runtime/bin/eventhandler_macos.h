// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_MACOS_H_
#define BIN_EVENTHANDLER_MACOS_H_

#include <unistd.h>
#include <sys/socket.h>


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
  intptr_t GetPollEvents();

  void Unregister() {
    port_ = 0;
    mask_ = 0;
  }

  void ShutdownRead() {
    shutdown(fd_, SHUT_RD);
    MarkClosedRead();
  }

  void ShutdownWrite() {
    shutdown(fd_, SHUT_WR);
    MarkClosedWrite();
  }

  void Close() {
    Unregister();
    flags_ = 0;
    close(fd_);
    fd_ = 0;
  }

  bool IsListeningSocket() { return (mask_ & (1 << kListeningSocket)) != 0; }
  bool IsClosedRead() { return (flags_ & (1 << kClosedRead)) != 0; }
  bool IsClosedWrite() { return (flags_ & (1 << kClosedWrite)) != 0; }

  void MarkClosedRead() { flags_ |= (1 << kClosedRead); }
  void MarkClosedWrite() { flags_ |= (1 << kClosedWrite); }

  bool HasPollEvents() { return mask_ != 0; }

  void SetPortAndMask(Dart_Port port, intptr_t mask) {
    port_ = port;
    mask_ = mask;
  }

  intptr_t fd() { return fd_; }
  void set_fd(intptr_t fd) { fd_ = fd; }
  Dart_Port port() { return port_; }
  intptr_t mask() { return mask_; }

 private:
  intptr_t fd_;
  Dart_Port port_;
  intptr_t mask_;
  intptr_t flags_;
};


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  SocketData* GetSocketData(intptr_t fd);
  void SendData(intptr_t id, Dart_Port dart_port, intptr_t data);
  void StartEventHandler();

 private:
  intptr_t GetTimeout();
  bool GetInterruptMessage(InterruptMessage* msg);
  struct pollfd* GetPollFds(intptr_t* size);
  void HandleEvents(struct pollfd* pollfds, int pollfds_size, int result_size);
  void HandleTimeout();
  static void* Poll(void* args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(struct pollfd* pollfd);

  SocketData* socket_map_;
  intptr_t socket_map_size_;
  int64_t timeout_;  // Time for next timeout.
  Dart_Port timeout_port_;
  int interrupt_fds_[2];
};


#endif  // BIN_EVENTHANDLER_MACOS_H_
