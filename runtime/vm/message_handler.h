// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MESSAGE_HANDLER_H_
#define VM_MESSAGE_HANDLER_H_

#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/os_thread.h"
#include "vm/thread_pool.h"

namespace dart {

// A MessageHandler is an entity capable of accepting messages.
class MessageHandler {
 protected:
  MessageHandler();

 public:
  enum MessageStatus {
    kOK,        // We successfully handled a message.
    kError,     // We encountered an error handling a message.
    kRestart,   // The VM is restarting.
    kShutdown,  // The VM is shutting down.
  };
  static const char* MessageStatusString(MessageStatus status);

  virtual ~MessageHandler();

  // Allow subclasses to provide a handler name.
  virtual const char* name() const;

  typedef uword CallbackData;
  typedef MessageStatus (*StartCallback)(CallbackData data);
  typedef void (*EndCallback)(CallbackData data);

  // Runs this message handler on the thread pool.
  //
  // Before processing messages, the optional StartFunction is run.
  //
  // A message handler will run until it terminates either normally or
  // abnormally.  Normal termination occurs when the message handler
  // no longer has any live ports.  Abnormal termination occurs when
  // HandleMessage() indicates that an error has occurred during
  // message processing.
  void Run(ThreadPool* pool,
           StartCallback start_callback,
           EndCallback end_callback,
           CallbackData data);

  // Handles the next message for this message handler.  Should only
  // be used when not running the handler on the thread pool (via Run
  // or RunBlocking).
  //
  // Returns true on success.
  MessageStatus HandleNextMessage();

  // Handles any OOB messages for this message handler.  Can be used
  // even if the message handler is running on the thread pool.
  //
  // Returns true on success.
  MessageStatus HandleOOBMessages();

  // Returns true if there are pending OOB messages for this message
  // handler.
  bool HasOOBMessages();

  // A message handler tracks how many live ports it has.
  bool HasLivePorts() const { return live_ports_ > 0; }

  intptr_t live_ports() const {
    return live_ports_;
  }

  bool paused() const { return paused_ > 0; }

  void increment_paused() { paused_++; }
  void decrement_paused() { ASSERT(paused_ > 0); paused_--; }

  bool pause_on_start() const {
    return pause_on_start_;
  }

  void set_pause_on_start(bool pause_on_start) {
    pause_on_start_ = pause_on_start;
  }

  bool paused_on_start() const {
    // If pause_on_start_ is still set, tell the user we are paused,
    // even if we haven't hit the pause point yet.
    return paused_on_start_;
  }

  bool pause_on_exit() const {
    return pause_on_exit_;
  }

  void set_pause_on_exit(bool pause_on_exit) {
    pause_on_exit_ = pause_on_exit;
  }

  bool paused_on_exit() const {
    return paused_on_exit_;
  }

  // Timestamp of the paused on start or paused on exit.
  int64_t paused_timestamp() const {
    return paused_timestamp_;
  }

  class AcquiredQueues : public ValueObject {
   public:
    AcquiredQueues();

    ~AcquiredQueues();

    MessageQueue* queue() {
      if (handler_ == NULL) {
        return NULL;
      }
      return handler_->queue_;
    }

    MessageQueue* oob_queue() {
      if (handler_ == NULL) {
        return NULL;
      }
      return handler_->oob_queue_;
    }

   private:
    void Reset(MessageHandler* handler);

    MessageHandler* handler_;

    friend class MessageHandler;
  };

  // Gives temporary ownership of |queue| and |oob_queue|. Calling this
  // has the side effect that no OOB messages will be handled if a stack
  // overflow interrupt is delivered.
  void AcquireQueues(AcquiredQueues* acquired_queue);

#if defined(DEBUG)
  // Check that it is safe to access this message handler.
  //
  // For example, if this MessageHandler is an isolate, then it is
  // only safe to access it when the MessageHandler is the current
  // isolate.
  virtual void CheckAccess();
#endif

 protected:
  // ------------ START PortMap API ------------
  // These functions should only be called from the PortMap.

  // Does this message handler correspond to the current isolate?
  virtual bool IsCurrentIsolate() const { return false; }

  // Return Isolate to which this message handler corresponds to.
  virtual Isolate* isolate() const { return NULL; }

  // Posts a message on this handler's message queue.
  // If before_events is true, then the message is enqueued before any pending
  // events, but after any pending isolate library events.
  void PostMessage(Message* message, bool before_events = false);

  // Notifies this handler that a port is being closed.
  void ClosePort(Dart_Port port);

  // Notifies this handler that all ports are being closed.
  void CloseAllPorts();

  // Returns true if the handler is owned by the PortMap.
  //
  // This is used to delete handlers when their last live port is closed.
  virtual bool OwnedByPortMap() const { return false; }

  void increment_live_ports();
  void decrement_live_ports();
  // ------------ END PortMap API ------------

  // Custom message notification.  Optionally provided by subclass.
  virtual void MessageNotify(Message::Priority priority);

  // Handles a single message.  Provided by subclass.
  //
  // Returns true on success.
  virtual MessageStatus HandleMessage(Message* message) = 0;

  virtual void NotifyPauseOnStart() {}
  virtual void NotifyPauseOnExit() {}

  // TODO(iposva): Set a local field before entering MessageHandler methods.
  Thread* thread() const { return Thread::Current(); }

 private:
  friend class PortMap;
  friend class MessageHandlerTestPeer;
  friend class MessageHandlerTask;

  // Called by MessageHandlerTask to process our task queue.
  void TaskCallback();

  // Dequeue the next message.  Prefer messages from the oob_queue_ to
  // messages from the queue_.
  Message* DequeueMessage(Message::Priority min_priority);

  void ClearOOBQueue();

  // Handles any pending messages.
  MessageStatus HandleMessages(bool allow_normal_messages,
                               bool allow_multiple_normal_messages);

  Monitor monitor_;  // Protects all fields in MessageHandler.
  MessageQueue* queue_;
  MessageQueue* oob_queue_;
  // This flag is not thread safe and can only reliably be accessed on a single
  // thread.
  bool oob_message_handling_allowed_;
  intptr_t live_ports_;  // The number of open ports, including control ports.
  intptr_t paused_;  // The number of pause messages received.
  bool pause_on_start_;
  bool pause_on_exit_;
  bool paused_on_start_;
  bool paused_on_exit_;
  int64_t paused_timestamp_;
  ThreadPool* pool_;
  ThreadPool::Task* task_;
  StartCallback start_callback_;
  EndCallback end_callback_;
  CallbackData callback_data_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandler);
};

}  // namespace dart

#endif  // VM_MESSAGE_HANDLER_H_
