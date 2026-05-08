// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MESSAGE_HANDLER_H_
#define RUNTIME_VM_MESSAGE_HANDLER_H_

#include <memory>

#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/port_set.h"
#include "vm/thread_pool.h"

namespace dart {

// A MessageHandler is an entity capable of accepting messages.
class MessageHandler : public PortHandler {
 protected:
  MessageHandler();

 public:
  enum MessageStatus {
    kOK,        // We successfully handled a message.
    kError,     // We encountered an error handling a message.
    kShutdown,  // The VM is shutting down.
  };
  static const char* MessageStatusString(MessageStatus status);

  virtual ~MessageHandler();

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

  // Returns false if the handler terminated abnormally, otherwise it
  // returns true.
  bool Run(ThreadPool* pool,
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

#if defined(TESTING)
  std::unique_ptr<Message> StealOOBMessage();
#endif

  // Returns true if there are pending normal messages for this message
  // handler.
  bool HasMessages();

  // Whether to keep this message handler alive or whether it should shutdown.
  virtual bool KeepAliveLocked() { return true; }

  bool paused() const { return paused_ > 0; }

  void increment_paused() { paused_++; }
  void decrement_paused() {
    ASSERT(paused_ > 0);
    paused_--;
  }

#if !defined(PRODUCT)
  bool should_pause_on_start() const { return should_pause_on_start_; }

  void set_should_pause_on_start(bool should_pause_on_start) {
    should_pause_on_start_ = should_pause_on_start;
  }

  bool is_paused_on_start() const { return is_paused_on_start_; }

  bool should_pause_on_exit() const { return should_pause_on_exit_; }

  void set_should_pause_on_exit(bool should_pause_on_exit) {
    should_pause_on_exit_ = should_pause_on_exit;
  }

  bool is_paused_on_exit() const { return is_paused_on_exit_; }

  // Timestamp of the paused on start or paused on exit.
  int64_t paused_timestamp() const { return paused_timestamp_; }

  bool ShouldPauseOnStart(MessageStatus status) const;
  bool ShouldPauseOnExit(MessageStatus status) const;
  void PausedOnStart(bool paused);
  void PausedOnExit(bool paused);
#endif

  // Gives temporary ownership of |queue| and |oob_queue|. Using this object
  // has the side effect that no OOB messages will be handled if a stack
  // overflow interrupt is delivered.
  class AcquiredQueues : public ValueObject {
   public:
    explicit AcquiredQueues(MessageHandler* handler);

    ~AcquiredQueues();

    MessageQueue* queue() {
      if (handler_ == nullptr) {
        return nullptr;
      }
      return handler_->queue_;
    }

    MessageQueue* oob_queue() {
      if (handler_ == nullptr) {
        return nullptr;
      }
      return handler_->oob_queue_;
    }

   private:
    MessageHandler* handler_;
    SafepointMonitorLocker ml_;

    friend class MessageHandler;
  };

 protected:
  // Custom message notification.  Optionally provided by subclass.
  virtual void MessageNotify(Message::Priority priority);

  // Handles a single message.  Provided by subclass.
  //
  // Returns true on success.
  virtual MessageStatus HandleMessage(std::unique_ptr<Message> message) = 0;

  virtual void NotifyPauseOnStart() {}
  virtual void NotifyPauseOnExit() {}

  // TODO(iposva): Set a local field before entering MessageHandler methods.
  Thread* thread() const { return Thread::Current(); }

  // Posts a message on this handler's message queue.
  // If before_events is true, then the message is enqueued before any pending
  // events, but after any pending isolate library events.
  void PostMessage(std::unique_ptr<Message> message,
                   bool before_events = false) override;

 private:
  template <typename GCVisitorType>
  friend void MournFinalizerEntry(GCVisitorType*, FinalizerEntryPtr);
  friend class PortMap;
  friend class MessageHandlerTestPeer;
  friend class MessageHandlerTask;

  // ------------ START PortMap API ------------
  // These functions should only be called from the PortMap.
  // Implementaion of PortHandler API.

  const char* name() const override;

  void OnPortClosed(Dart_Port port) override;

  void Shutdown() override {
    // Nothing to do.
  }

  // Return Isolate to which this message handler corresponds to.
  Isolate* isolate() const override { return nullptr; }

  PortSet<PortSetEntry>* ports(PortMap::Locker& locker) override {
    return &ports_;
  }

  // Notifies this handler that all ports are being closed.
  void OnAllPortsClosed();
  // ------------ END PortMap API ------------

  // Called by MessageHandlerTask to process our task queue.
  void TaskCallback();

  // Checks if we have a slot for idle task execution, if we have a slot
  // for idle task execution it is scheduled immediately or we wait for
  // idle expiration and then attempt to schedule the idle task.
  // Returns true if their is scope for idle task execution so that we
  // can loop back to handle more messages or false if idle tasks are not
  // scheduled.
  bool CheckIfIdleLocked(MonitorLocker* ml);

  // Triggers a run of the idle task.
  void RunIdleTaskLocked(MonitorLocker* ml);

  // NOTE: These two functions release and reacquire the monitor, you may
  // need to call HandleMessages to ensure all pending messages are handled.
  void PausedOnStartLocked(MonitorLocker* ml, bool paused);
  void PausedOnExitLocked(MonitorLocker* ml, bool paused);

  // Dequeue the next message.  Prefer messages from the oob_queue_ to
  // messages from the queue_.
  std::unique_ptr<Message> DequeueMessage(Message::Priority min_priority);

  void ClearOOBQueue();

  // Handles any pending messages.
  MessageStatus HandleMessages(MonitorLocker* ml,
                               bool allow_normal_messages,
                               bool allow_multiple_normal_messages);

  Monitor monitor_;  // Protects all fields in MessageHandler.
  MessageQueue* queue_;
  MessageQueue* oob_queue_;
  // This flag is not thread safe and can only reliably be accessed on a single
  // thread.
  bool oob_message_handling_allowed_;
  bool paused_for_messages_;

  // Only accessed by [PortMap], protected by [PortMap]s lock. See ports()
  // getter.
  PortSet<PortSetEntry> ports_;

  intptr_t paused_;  // The number of pause messages received.
#if !defined(PRODUCT)
  bool should_pause_on_start_;
  bool should_pause_on_exit_;
  bool is_paused_on_start_;
  bool is_paused_on_exit_;
  // When isolate gets paused, remember the status of the message being
  // processed so that we can resume correctly(into potentially not-OK status).
  MessageStatus remembered_paused_on_exit_status_;
  int64_t paused_timestamp_;
#endif
  bool task_running_;
  ThreadPool* pool_;
  StartCallback start_callback_;
  EndCallback end_callback_;
  CallbackData callback_data_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandler);
};

}  // namespace dart

#endif  // RUNTIME_VM_MESSAGE_HANDLER_H_
