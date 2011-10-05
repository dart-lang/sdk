// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_H_
#define BIN_EVENTHANDLER_H_

#include "bin/builtin.h"

// The event handler delegation class is OS specific.
#if defined(TARGET_OS_LINUX)
#include "bin/eventhandler_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/eventhandler_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/eventhandler_win.h"
#else
#error Unknown target os.
#endif

/*
 * Keep these constant in sync with the dart poll event identifiers.
 */
enum Message {
  kInEvent = 0,
  kOutEvent,
  kErrorEvent,
  kCloseEvent,
  kCloseCommand,
};


class EventHandler {
 public:
  void SendData(intptr_t id, Dart_Port dart_port, intptr_t data) {
    delegate_.SendData(id, dart_port, data);
  }

  static EventHandler* StartEventHandler() {
    EventHandler* handler = new EventHandler();
    handler->delegate_.StartEventHandler();
    return handler;
  }

 private:
  EventHandlerImplementation delegate_;
};


#endif  // BIN_EVENTHANDLER_H_
