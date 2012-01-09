// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_H_
#define BIN_EVENTHANDLER_H_

#include "bin/builtin.h"
#include "bin/thread_pool.h"

// Flags used to provide information and actions to the eventhandler
// when sending a message about a file descriptor. These flags should
// be kept in sync with the constants in socket_impl.dart. For more
// information see the comments in socket_impl.dart
enum MessageFlags {
  kInEvent = 0,
  kOutEvent = 1,
  kErrorEvent = 2,
  kCloseEvent = 3,
  kCloseCommand = 8,
  kShutdownReadCommand = 9,
  kShutdownWriteCommand = 10,
  kListeningSocket = 16,
  kPipe = 17,
};


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

class EventHandler {
 public:
  void SendData(intptr_t id, Dart_Port dart_port, intptr_t data) {
    delegate_.SendData(id, dart_port, data);
  }

  static void* AsyncTaskHandler(void* args) {
    if (Dart_IsVMFlagSet("trace_thread_pool")) {
      printf("Got async task\n");
    }
    return NULL;
  }

  static void Initialize() {
    if (Dart_IsVMFlagSet("enable_thread_pool")) {
      ASSERT(thread_pool_ == NULL);
      thread_pool_ = new ThreadPool(&EventHandler::AsyncTaskHandler);
      thread_pool_->Start();
    }
  }

  static void Terminate() {
    if (Dart_IsVMFlagSet("enable_thread_pool")) {
      if (thread_pool_ != NULL) {
        thread_pool_->Shutdown();
      }
    }
  }

  static EventHandler* StartEventHandler() {
    EventHandler* handler = new EventHandler();
    handler->delegate_.StartEventHandler();
    return handler;
  }

 private:
  EventHandlerImplementation delegate_;
  static ThreadPool* thread_pool_;
};


#endif  // BIN_EVENTHANDLER_H_
