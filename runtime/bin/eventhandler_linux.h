// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_LINUX_H_
#define BIN_EVENTHANDLER_LINUX_H_

#if !defined(BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_linux.h directly; use eventhandler.h instead.
#endif

#include <unistd.h>
#include <sys/epoll.h>
#include <sys/socket.h>

#include "platform/hashmap.h"
#include "platform/thread.h"


namespace dart {
namespace bin {

class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  void Notify(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  void HandleEvents(struct epoll_event* events, int size);
  static void Poll(uword args);
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(intptr_t events);

  TimeoutQueue timeout_queue_;
  bool shutdown_;
  int epoll_fd_;
  int timer_fd_;
  Mutex timer_mutex_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_LINUX_H_
