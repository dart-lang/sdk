// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_H_
#define BIN_EVENTHANDLER_H_

#include "bin/builtin.h"
#include "bin/isolate_data.h"

namespace dart {
namespace bin {

// Flags used to provide information and actions to the eventhandler
// when sending a message about a file descriptor. These flags should
// be kept in sync with the constants in socket_impl.dart. For more
// information see the comments in socket_impl.dart
enum MessageFlags {
  kInEvent = 0,
  kOutEvent = 1,
  kErrorEvent = 2,
  kCloseEvent = 3,
  kDestroyedEvent = 4,
  kCloseCommand = 8,
  kShutdownReadCommand = 9,
  kShutdownWriteCommand = 10,
  kReturnTokenCommand = 11,
  kListeningSocket = 16,
  kPipe = 17,
};

#define COMMAND_MASK ((1 << kCloseCommand) | \
                      (1 << kShutdownReadCommand) | \
                      (1 << kShutdownWriteCommand) | \
                      (1 << kReturnTokenCommand))
#define IS_COMMAND(data, command_bit) \
    ((data & COMMAND_MASK) == (1 << command_bit))  // NOLINT
#define ASSERT_NO_COMMAND(data) ASSERT((data & COMMAND_MASK) == 0)  // NOLINT
#define TOKEN_COUNT(data) (data & ((1 << kCloseCommand) - 1))

class TimeoutQueue {
 private:
  class Timeout {
   public:
    Timeout(Dart_Port port, int64_t timeout, Timeout* next)
        : port_(port), timeout_(timeout), next_(next) {}

    Dart_Port port() const { return port_; }

    int64_t timeout() const { return timeout_; }
    void set_timeout(int64_t timeout) {
      ASSERT(timeout >= 0);
      timeout_ = timeout;
    }

    Timeout* next() const { return next_; }
    void set_next(Timeout* next) {
      next_ = next;
    }

   private:
    Dart_Port port_;
    int64_t timeout_;
    Timeout* next_;
  };

 public:
  TimeoutQueue() : next_timeout_(NULL), timeouts_(NULL) {}

  ~TimeoutQueue() {
    while (HasTimeout()) RemoveCurrent();
  }

  bool HasTimeout() const { return next_timeout_ != NULL; }

  int64_t CurrentTimeout() const {
    ASSERT(next_timeout_ != NULL);
    return next_timeout_->timeout();
  }

  Dart_Port CurrentPort() const {
    ASSERT(next_timeout_ != NULL);
    return next_timeout_->port();
  }

  void RemoveCurrent() {
    UpdateTimeout(CurrentPort(), -1);
  }

  void UpdateTimeout(Dart_Port port, int64_t timeout);

 private:
  Timeout* next_timeout_;
  Timeout* timeouts_;
};

}  // namespace bin
}  // namespace dart

// The event handler delegation class is OS specific.
#if defined(TARGET_OS_ANDROID)
#include "bin/eventhandler_android.h"
#elif defined(TARGET_OS_LINUX)
#include "bin/eventhandler_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/eventhandler_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/eventhandler_win.h"
#else
#error Unknown target os.
#endif

namespace dart {
namespace bin {

class EventHandler {
 public:
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data) {
    delegate_.SendData(id, dart_port, data);
  }

  /**
   * Start the event-handler.
   */
  static void Start();

  /**
   * Stop the event-handler. It's expected that there will be no further calls
   * to SendData after a call to Stop.
   */
  static void Stop();

  static EventHandlerImplementation* delegate();

 private:
  friend class EventHandlerImplementation;
  EventHandlerImplementation delegate_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_H_
