// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_CONNECTION_H_
#define BIN_DBG_CONNECTION_H_

#include "bin/builtin.h"
#include "bin/utils.h"

#include "include/dart_debugger_api.h"

#include "platform/globals.h"
#include "platform/json.h"
#include "platform/thread.h"
// Declare the OS-specific types ahead of defining the generic class.
#if defined(TARGET_OS_ANDROID)
#include "bin/dbg_connection_android.h"
#elif defined(TARGET_OS_LINUX)
#include "bin/dbg_connection_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/dbg_connection_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/dbg_connection_win.h"
#else
#error Unknown target os.
#endif


class MessageBuffer;

class DebuggerConnectionHandler {
 public:
  explicit DebuggerConnectionHandler(int debug_fd);
  ~DebuggerConnectionHandler();

  // Accessors.
  int debug_fd() const { return debug_fd_; }

  // Return message id of current debug command message.
  int MessageId();

  // Starts the native thread which listens for connections from
  // debugger clients, reads and dispatches debug command messages
  // from the client.
  static void StartHandler(const char* address, int port_number);

  // Called by Isolates when they need to wait for a connection
  // from debugger clients.
  static void WaitForConnection();

  // Sends a reply or an error message to a specific debugger client.
  static void SendMsg(int debug_fd, dart::TextBuffer* msg);
  static void SendError(int debug_fd, int msg_id, const char* err_msg);

  // Sends an event message to all debugger clients that are connected.
  static void BroadcastMsg(dart::TextBuffer* msg);

 private:
  void HandleUnknownMsg();
  void HandleMessages();

  void CloseDbgConnection();

  // The socket that connects with the debugger client.
  // The descriptor is created and closed by the debugger connection thread.
  int debug_fd_;

  // Buffer holding the messages received over the wire from the debugger
  // front end..
  MessageBuffer* msgbuf_;

  // Accepts connection requests from debugger client and sets up a
  // connection handler object to read and handle messages from the client.
  static void AcceptDbgConnection(int debug_fd);

  // Handlers for generic debug command messages which are not specific to
  // an isolate.
  static void HandleInterruptCmd(DebuggerConnectionHandler* handler);
  static void HandleIsolatesListCmd(DebuggerConnectionHandler* handler);
  static void HandleQuitCmd(DebuggerConnectionHandler* handler);

  // Helper methods to manage debugger client connections.
  static void AddNewDebuggerConnection(int debug_fd);
  static void RemoveDebuggerConnection(int debug_fd);
  static DebuggerConnectionHandler* GetDebuggerConnectionHandler(int debug_fd);
  static bool IsConnected();

  // Helper method for sending messages back to a debugger client.
  static void SendMsgHelper(int debug_fd, dart::TextBuffer* msg);

  // mutex/condition variable used by isolates when writing back to the
  // debugger. This is also used to ensure that the isolate waits for
  // a debugger to be attached when that is requested on the command line.
  static dart::Monitor handler_lock_;

  // The socket that is listening for incoming debugger connections.
  // This descriptor is created and closed by a native thread.
  static int listener_fd_;

  friend class DebuggerConnectionImpl;

  DISALLOW_IMPLICIT_CONSTRUCTORS(DebuggerConnectionHandler);
};

#endif  // BIN_DBG_CONNECTION_H_
