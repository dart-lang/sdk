// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_ANDROID_H_
#define BIN_EVENTHANDLER_ANDROID_H_

#if !defined(BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_android.h directly;
#error use eventhandler.h instead.
#endif

#include <errno.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#include "platform/hashmap.h"
#include "platform/signal_blocker.h"


namespace dart {
namespace bin {

class InterruptMessage {
 public:
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
};


class SocketData {
 public:
  explicit SocketData(intptr_t fd)
      : fd_(fd), port_(0), mask_(0), tokens_(16) {
    ASSERT(fd_ != -1);
  }

  intptr_t GetPollEvents();

  void Close() {
    port_ = 0;
    mask_ = 0;
    VOID_TEMP_FAILURE_RETRY(close(fd_));
    fd_ = -1;
  }

  void SetPortAndMask(Dart_Port port, intptr_t mask) {
    ASSERT(fd_ != -1);
    port_ = port;
    mask_ = mask;
  }

  intptr_t fd() { return fd_; }
  Dart_Port port() { return port_; }

  bool IsListeningSocket() { return (mask_ & (1 << kListeningSocket)) != 0; }

  // Returns true if the last token was taken.
  bool TakeToken() {
    ASSERT(tokens_ > 0);
    tokens_--;
    return tokens_ == 0;
  }

  // Returns true if the tokens was 0 before adding.
  bool ReturnToken() {
    ASSERT(tokens_ >= 0);
    tokens_++;
    return tokens_ == 1;
  }

 private:
  intptr_t fd_;
  Dart_Port port_;
  intptr_t mask_;
  int tokens_;
};


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  // Gets the socket data structure for a given file
  // descriptor. Creates a new one if one is not found.
  SocketData* GetSocketData(intptr_t fd);
  void SendData(intptr_t id, Dart_Port dart_port, intptr_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  int64_t GetTimeout();
  void HandleEvents(struct epoll_event* events, int size);
  void HandleTimeout();
  static void Poll(uword args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(intptr_t events, SocketData* sd);
  static void* GetHashmapKeyFromFd(intptr_t fd);
  static uint32_t GetHashmapHashFromFd(intptr_t fd);

  HashMap socket_map_;
  TimeoutQueue timeout_queue_;
  bool shutdown_;
  int interrupt_fds_[2];
  int epoll_fd_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_ANDROID_H_
