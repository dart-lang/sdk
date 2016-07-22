// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_FUCHSIA_H_
#define BIN_EVENTHANDLER_FUCHSIA_H_

#if !defined(BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_fuchsia.h directly; use eventhandler.h instead.
#endif

#include <magenta/syscalls.h>

namespace dart {
namespace bin {

class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  int64_t GetTimeout() const;
  void HandleEvents();
  void HandleTimeout();
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  static void Poll(uword args);

  TimeoutQueue timeout_queue_;
  bool shutdown_;
  mx_handle_t interrupt_handles_[2];

  DISALLOW_COPY_AND_ASSIGN(EventHandlerImplementation);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_FUCHSIA_H_
