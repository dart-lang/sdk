// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_CONNECTION_ANDROID_H_
#define BIN_DBG_CONNECTION_ANDROID_H_

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>


namespace dart {
namespace bin {

class DebuggerConnectionImpl {
 public:
  static void StartHandler(int port_number);
  static intptr_t Send(intptr_t socket, const char* buf, int len);
  static intptr_t Receive(intptr_t socket, char* buf, int len);

 private:
  static void SetupPollQueue();
  static void HandleEvent(struct epoll_event* event);
  static void Handler(uword args);

  // File descriptors for pipes used to communicate with the debugger thread.
  static int wakeup_fds_[2];

  // File descriptor for the polling queue.
  static intptr_t epoll_fd_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_DBG_CONNECTION_ANDROID_H_
