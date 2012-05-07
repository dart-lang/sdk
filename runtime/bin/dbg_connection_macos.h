// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_CONNECTION_MACOS_H_
#define BIN_DBG_CONNECTION_MACOS_H_

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>


class DebuggerConnectionImpl {
 public:
  static void StartHandler(int port_number);

 private:
  enum MessageType {
    kAddDbgFd = 1,
    kRemoveDbgFd,
    kQuit
  };

  struct Message {
    MessageType msg_id;
  };

  static void SendMessage(MessageType id);
  static bool ReceiveMessage(Message* msg);

  static void SetupPollQueue();
  static void HandleEvent(struct kevent* event);
  static void Handler(uword args);



  // File descriptors for pipes used to communicate with the debugger thread.
  static int wakeup_fds_[2];
  // File descriptor for the polling queue.
  static int kqueue_fd_;
};


#endif  // BIN_DBG_CONNECTION_MACOS_H_
