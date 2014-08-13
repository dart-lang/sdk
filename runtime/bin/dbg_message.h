// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_MESSAGE_H_
#define BIN_DBG_MESSAGE_H_

#include "bin/builtin.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "include/dart_debugger_api.h"

#include "platform/globals.h"
#include "platform/json.h"


namespace dart {
namespace bin {

// TODO(hausner): Need better error handling.
#define ASSERT_NOT_ERROR(handle)          \
  ASSERT(!Dart_IsError(handle))

#define RETURN_IF_ERROR(handle)           \
  if (Dart_IsError(handle)) {             \
    return Dart_GetError(handle);         \
  }


// Class to parse a JSON debug command message.
class MessageParser {
 public:
  MessageParser(const char* buf, int buf_length)
      : buf_(buf), buf_length_(buf_length) {
  }
  ~MessageParser() { }

  // Accessors.
  const char* buf() const { return buf_; }

  bool IsValidMessage() const;
  int MessageId() const;

  const char* Params() const;
  bool HasParam(const char* name) const;
  intptr_t GetIntParam(const char* name) const;
  int64_t GetInt64Param(const char* name) const;
  intptr_t GetOptIntParam(const char* name, intptr_t default_val) const;

  // GetStringParam mallocs the buffer that it returns. Caller must free.
  char* GetStringParam(const char* name) const;

 private:
  const char* buf_;
  int buf_length_;

  DISALLOW_COPY_AND_ASSIGN(MessageParser);
};


// Class which represents a debug command message and handles it.
class DbgMessage {
 public:
  DbgMessage(int32_t cmd_idx, const char* start,
             const char* end, intptr_t debug_fd)
      : next_(NULL), cmd_idx_(cmd_idx),
        buffer_(NULL), buffer_len_(end - start),
        debug_fd_(debug_fd) {
    buffer_ = reinterpret_cast<char*>(malloc(buffer_len_));
    ASSERT(buffer_ != NULL);
    memmove(buffer_, start, buffer_len_);
  }
  ~DbgMessage() {
    next_ = NULL;
    free(buffer_);
  }

  // Accessors.
  DbgMessage* next() const { return next_; }
  void set_next(DbgMessage* next) { next_ = next; }
  char* buffer() const { return buffer_; }
  int32_t buffer_len() const { return buffer_len_; }
  intptr_t debug_fd() const { return debug_fd_; }

  // Handle debugger command message.
  // Returns true if the execution needs to resume after this message is
  // handled, false otherwise.
  bool HandleMessage();

  // Send reply after successful handling of command.
  void SendReply(dart::TextBuffer* msg);

  // Reply error returned by the command handler.
  void SendErrorReply(int msg_id, const char* err_msg);

  // Handlers for specific commands, they are static because these
  // functions are populated as function pointers into a dispatch table.
  static bool HandleResumeCmd(DbgMessage* msg);
  static bool HandleStepIntoCmd(DbgMessage* msg);
  static bool HandleStepOverCmd(DbgMessage* msg);
  static bool HandleStepOutCmd(DbgMessage* msg);
  static bool HandleGetLibrariesCmd(DbgMessage* msg);
  static bool HandleGetClassPropsCmd(DbgMessage* msg);
  static bool HandleGetLibPropsCmd(DbgMessage* msg);
  static bool HandleSetLibPropsCmd(DbgMessage* msg);
  static bool HandleGetGlobalsCmd(DbgMessage* msg);
  static bool HandleEvaluateExprCmd(DbgMessage* msg);
  static bool HandleGetObjPropsCmd(DbgMessage* msg);
  static bool HandleGetListCmd(DbgMessage* msg);
  static bool HandleGetScriptURLsCmd(DbgMessage* msg);
  static bool HandleGetSourceCmd(DbgMessage* msg);
  static bool HandleGetLineNumbersCmd(DbgMessage* msg);
  static bool HandleGetStackTraceCmd(DbgMessage* msg);
  static bool HandlePauseOnExcCmd(DbgMessage* msg);
  static bool HandleSetBpCmd(DbgMessage* msg);
  static bool HandleRemBpCmd(DbgMessage* msg);

 private:
  DbgMessage* next_;  // Next message in the queue.
  int32_t cmd_idx_;  // Isolate specific debugger command index.
  char* buffer_;  // Debugger command message.
  int32_t buffer_len_;  // Length of the debugger command message.
  intptr_t debug_fd_;  // Debugger connection on which replies are to be sent.

  DISALLOW_IMPLICIT_CONSTRUCTORS(DbgMessage);
};


// Class which represents a queue of debug command messages sent to an isolate.
class DbgMsgQueue {
 public:
  DbgMsgQueue(Dart_IsolateId isolate_id, DbgMsgQueue* next)
      : is_running_(true),
        is_interrupted_(false),
        msglist_head_(NULL),
        msglist_tail_(NULL),
        queued_output_messages_(64),
        isolate_id_(isolate_id),
        next_(next) {
  }
  ~DbgMsgQueue() {
    DbgMessage* msg = msglist_head_;
    while (msglist_head_ != NULL) {
      msglist_head_ = msglist_head_->next();
      delete msg;
      msg = msglist_head_;
    }
    msglist_tail_ = NULL;
    isolate_id_ = ILLEGAL_ISOLATE_ID;
    next_ = NULL;
  }

  // Accessors.
  Dart_IsolateId isolate_id() const { return isolate_id_; }
  DbgMsgQueue* next() const { return next_; }
  void set_next(DbgMsgQueue* next) { next_ = next; }

  // Add specified debug command message to the queue.
  void AddMessage(int32_t cmd_idx,
                  const char* start,
                  const char* end,
                  intptr_t debug_fd);

  // Notify an isolate of a pending vmservice message.
  void Notify();

  // Run a message loop which handles messages as they arrive until
  // normal program execution resumes.
  void MessageLoop();

  // Handle any pending debug command messages in the queue.  Return
  // value indicates whether a resume has been requested.
  bool HandlePendingMessages();

  // Interrupt Isolate.
  void InterruptIsolate();

  // Queue output messages, these are sent out when we hit an event.
  void QueueOutputMsg(dart::TextBuffer* msg);

  // Send all queued messages over to the debugger.
  void SendQueuedMsgs();

  // Send breakpoint event message over to the debugger.
  void SendBreakpointEvent(intptr_t bp_id, const Dart_CodeLocation& location);

  // Send Exception event message over to the debugger.
  void SendExceptionEvent(Dart_Handle exception, Dart_StackTrace trace);

  // Send Isolate event message over to the debugger.
  void SendIsolateEvent(Dart_IsolateId isolate_id, Dart_IsolateEvent kind);

 private:
  bool is_running_;  // True if isolate is running and not in the debugger loop.
  bool is_interrupted_;  // True if interrupt command is pending.

  DbgMessage* msglist_head_;  // Start of debugger messages list.
  DbgMessage* msglist_tail_;  // End of debugger messages list.

  // Text buffer that accumulates messages to be output.
  dart::TextBuffer queued_output_messages_;

  Dart_IsolateId isolate_id_;  // Id of the isolate tied to this queue.

  DbgMsgQueue* next_;  // Used for creating a list of message queues.

  // The isolate waits on this condition variable when it needs to process
  // debug messages.
  dart::Monitor msg_queue_lock_;

  DISALLOW_COPY_AND_ASSIGN(DbgMsgQueue);
};


// Maintains a list of message queues.
class DbgMsgQueueList {
 public:
  static const int32_t kInvalidCommand = -1;

  // Initialize the message queue processing by setting up the appropriate
  // handlers.
  static void Initialize();

  // Parses the input message and returns the command index if the message
  // contains a valid isolate specific command.
  // It returns kInvalidCommand otherwise.
  static int32_t LookupIsolateCommand(const char* buf, int32_t buflen);

  // Queue debugger message targetted for the isolate.
  static bool AddIsolateMessage(Dart_IsolateId isolate_id,
                                int32_t cmd_idx,
                                const char* start,
                                const char* end,
                                intptr_t debug_fd);

  // Notify an isolate of a pending vmservice message.
  static void NotifyIsolate(Dart_Isolate isolate);

  // Interrupt isolate.
  static bool InterruptIsolate(Dart_IsolateId isolate_id);

  // Add Debugger Message Queue corresponding to the Isolate.
  static DbgMsgQueue* AddIsolateMsgQueue(Dart_IsolateId isolate_id);

  // Get Debugger Message Queue corresponding to the Isolate.
  static DbgMsgQueue* GetIsolateMsgQueue(Dart_IsolateId isolate_id);

  // Remove Debugger Message Queue corresponding to the Isolate.
  static void RemoveIsolateMsgQueue(Dart_IsolateId isolate_id);

  // Generic handlers for breakpoints, exceptions and delayed breakpoint
  // resolution.
  static void BptResolvedHandler(Dart_IsolateId isolate_id,
                                 intptr_t bp_id,
                                 const Dart_CodeLocation& location);
  static void PausedEventHandler(Dart_IsolateId isolate_id,
                                 intptr_t bp_id,
                                 const Dart_CodeLocation& loc);
  static void ExceptionThrownHandler(Dart_IsolateId isolate_id,
                                     Dart_Handle exception,
                                     Dart_StackTrace stack_trace);
  static void IsolateEventHandler(Dart_IsolateId isolate_id,
                                  Dart_IsolateEvent kind);

  // Print list of isolate ids of all message queues into text buffer.
  static void ListIsolateIds(dart::TextBuffer* msg);

 private:
  static DbgMsgQueue* GetIsolateMsgQueueLocked(Dart_IsolateId isolate_id);

  static DbgMsgQueue* list_;
  static dart::Mutex* msg_queue_list_lock_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DbgMsgQueueList);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_DBG_MESSAGE_H_
