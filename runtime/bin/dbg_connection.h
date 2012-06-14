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
#if defined(TARGET_OS_LINUX)
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
  ~DebuggerConnectionHandler();
  static void StartHandler(const char* address, int port_number);

  static bool IsConnected() {
    return debugger_fd_ >= 0;
  }

 private:
  static void SendMsg(dart::TextBuffer* msg);
  static void QueueMsg(dart::TextBuffer* msg);
  static void SendQueuedMsgs();

  static void SendBreakpointEvent(Dart_StackTrace trace);
  static void SendExceptionEvent(Dart_Handle exception, Dart_StackTrace trace);
  static void BptResolvedHandler(intptr_t bp_id,
                                 Dart_Handle url,
                                 intptr_t line_number);
  static void BreakpointHandler(Dart_Breakpoint bpt, Dart_StackTrace trace);
  static void ExceptionThrownHandler(Dart_Handle exception,
                                     Dart_StackTrace stack_trace);

  static void AcceptDbgConnection(int debug_fd);
  static void WaitForConnection();
  static void CloseDbgConnection();

  static void HandleMessages();
  static void HandleResumeCmd(const char* msg);
  static void HandleStepIntoCmd(const char* msg);
  static void HandleStepOverCmd(const char* msg);
  static void HandleStepOutCmd(const char* msg);
  static void HandleGetLibrariesCmd(const char* json_msg);
  static void HandleGetClassPropsCmd(const char* json_msg);
  static void HandleGetLibPropsCmd(const char* json_msg);
  static void HandleGetObjPropsCmd(const char* json_msg);
  static void HandleGetScriptURLsCmd(const char* json_msg);
  static void HandleGetSourceCmd(const char* json_msg);
  static void HandleGetStackTraceCmd(const char* json_msg);
  static void HandlePauseOnExcCmd(const char* json_msg);
  static void HandleSetBpCmd(const char* json_msg);
  static void HandleRemBpCmd(const char* json_msg);
  static void HandleUnknownMsg(const char* json_msg);

  static void SendError(int msg_id, const char* err_msg);

  // Text buffer that accumulates messages to be sent to front end.
  static dart::TextBuffer queued_messages_;

  static bool handler_started_;

  static bool request_resume_;

  // The socket that is listening for incoming debugger connections.
  // This descriptor is created and closed by a VM thread.
  static int listener_fd_;

  // The socket that connects with the debugger client.
  // The descriptor is created by the debugger connection thread and
  // closed by a VM thread.
  static int debugger_fd_;

  // The VM thread waits on this condition variable when it reaches a
  // breakpoint and the debugger client has not connected yet.
  static dart::Monitor is_connected_;

  static MessageBuffer* msgbuf_;

  friend class DebuggerConnectionImpl;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DebuggerConnectionHandler);
};

#endif  // BIN_DBG_CONNECTION_H_
