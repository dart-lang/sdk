// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_handler.h"

#include "vm/dart.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/port.h"
#include "vm/thread_interrupter.h"

namespace dart {

DECLARE_FLAG(bool, trace_service_pause_events);

class MessageHandlerTask : public ThreadPool::Task {
 public:
  explicit MessageHandlerTask(MessageHandler* handler) : handler_(handler) {
    ASSERT(handler != NULL);
  }

  virtual void Run() {
    ASSERT(handler_ != NULL);
    handler_->TaskCallback();
  }

 private:
  MessageHandler* handler_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandlerTask);
};

// static
const char* MessageHandler::MessageStatusString(MessageStatus status) {
  switch (status) {
    case kOK:
      return "OK";
    case kError:
      return "Error";
    case kRestart:
      return "Restart";
    case kShutdown:
      return "Shutdown";
    default:
      UNREACHABLE();
      return "Illegal";
  }
}

MessageHandler::MessageHandler()
    : queue_(new MessageQueue()),
      oob_queue_(new MessageQueue()),
      oob_message_handling_allowed_(true),
      live_ports_(0),
      paused_(0),
#if !defined(PRODUCT)
      should_pause_on_start_(false),
      should_pause_on_exit_(false),
      is_paused_on_start_(false),
      is_paused_on_exit_(false),
      paused_timestamp_(-1),
#endif
      delete_me_(false),
      pool_(NULL),
      task_(NULL),
      start_callback_(NULL),
      end_callback_(NULL),
      callback_data_(0) {
  ASSERT(queue_ != NULL);
  ASSERT(oob_queue_ != NULL);
}

MessageHandler::~MessageHandler() {
  delete queue_;
  delete oob_queue_;
  queue_ = NULL;
  oob_queue_ = NULL;
  pool_ = NULL;
  task_ = NULL;
}

const char* MessageHandler::name() const {
  return "<unnamed>";
}

#if defined(DEBUG)
void MessageHandler::CheckAccess() {
  // By default there is no checking.
}
#endif

void MessageHandler::MessageNotify(Message::Priority priority) {
  // By default, there is no custom message notification.
}

void MessageHandler::Run(ThreadPool* pool,
                         StartCallback start_callback,
                         EndCallback end_callback,
                         CallbackData data) {
  bool task_running;
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print(
        "[+] Starting message handler:\n"
        "\thandler:    %s\n",
        name());
  }
  ASSERT(pool_ == NULL);
  ASSERT(!delete_me_);
  pool_ = pool;
  start_callback_ = start_callback;
  end_callback_ = end_callback;
  callback_data_ = data;
  task_ = new MessageHandlerTask(this);
  task_running = pool_->Run(task_);
  ASSERT(task_running);
}

void MessageHandler::PostMessage(Message* message, bool before_events) {
  Message::Priority saved_priority;
  bool task_running = true;
  {
    MonitorLocker ml(&monitor_);
    if (FLAG_trace_isolates) {
      Isolate* source_isolate = Isolate::Current();
      if (source_isolate) {
        OS::Print(
            "[>] Posting message:\n"
            "\tlen:        %" Pd "\n\tsource:     (%" Pd64
            ") %s\n\tdest:       %s\n"
            "\tdest_port:  %" Pd64 "\n",
            message->len(), static_cast<int64_t>(source_isolate->main_port()),
            source_isolate->name(), name(), message->dest_port());
      } else {
        OS::Print(
            "[>] Posting message:\n"
            "\tlen:        %" Pd
            "\n\tsource:     <native code>\n"
            "\tdest:       %s\n"
            "\tdest_port:  %" Pd64 "\n",
            message->len(), name(), message->dest_port());
      }
    }

    saved_priority = message->priority();
    if (message->IsOOB()) {
      oob_queue_->Enqueue(message, before_events);
    } else {
      queue_->Enqueue(message, before_events);
    }
    message = NULL;  // Do not access message.  May have been deleted.

    if ((pool_ != NULL) && (task_ == NULL)) {
      ASSERT(!delete_me_);
      task_ = new MessageHandlerTask(this);
      task_running = pool_->Run(task_);
    }
  }
  ASSERT(task_running);

  // Invoke any custom message notification.
  MessageNotify(saved_priority);
}

Message* MessageHandler::DequeueMessage(Message::Priority min_priority) {
  // TODO(turnidge): Add assert that monitor_ is held here.
  Message* message = oob_queue_->Dequeue();
  if ((message == NULL) && (min_priority < Message::kOOBPriority)) {
    message = queue_->Dequeue();
  }
  return message;
}

void MessageHandler::ClearOOBQueue() {
  oob_queue_->Clear();
}

MessageHandler::MessageStatus MessageHandler::HandleMessages(
    MonitorLocker* ml,
    bool allow_normal_messages,
    bool allow_multiple_normal_messages) {
  // TODO(turnidge): Add assert that monitor_ is held here.

  // If isolate() returns NULL StartIsolateScope does nothing.
  StartIsolateScope start_isolate(isolate());

  MessageStatus max_status = kOK;
  Message::Priority min_priority =
      ((allow_normal_messages && !paused()) ? Message::kNormalPriority
                                            : Message::kOOBPriority);
  Message* message = DequeueMessage(min_priority);
  while (message != NULL) {
    intptr_t message_len = message->len();
    if (FLAG_trace_isolates) {
      OS::Print(
          "[<] Handling message:\n"
          "\tlen:        %" Pd
          "\n"
          "\thandler:    %s\n"
          "\tport:       %" Pd64 "\n",
          message_len, name(), message->dest_port());
    }

    // Release the monitor_ temporarily while we handle the message.
    // The monitor was acquired in MessageHandler::TaskCallback().
    ml->Exit();
    Message::Priority saved_priority = message->priority();
    Dart_Port saved_dest_port = message->dest_port();
    MessageStatus status = HandleMessage(message);
    if (status > max_status) {
      max_status = status;
    }
    message = NULL;  // May be deleted by now.
    ml->Enter();
    if (FLAG_trace_isolates) {
      OS::Print(
          "[.] Message handled (%s):\n"
          "\tlen:        %" Pd
          "\n"
          "\thandler:    %s\n"
          "\tport:       %" Pd64 "\n",
          MessageStatusString(status), message_len, name(), saved_dest_port);
    }
    // If we are shutting down, do not process any more messages.
    if (status == kShutdown) {
      ClearOOBQueue();
      break;
    }

    // Some callers want to process only one normal message and then quit. At
    // the same time it is OK to process multiple OOB messages.
    if ((saved_priority == Message::kNormalPriority) &&
        !allow_multiple_normal_messages) {
      // We processed one normal message.  Allow no more.
      allow_normal_messages = false;
    }

    // Reevaluate the minimum allowable priority.  The paused state
    // may have changed as part of handling the message.  We may also
    // have encountered an error during message processing.
    //
    // Even if we encounter an error, we still process pending OOB
    // messages so that we don't lose the message notification.
    min_priority = (((max_status == kOK) && allow_normal_messages && !paused())
                        ? Message::kNormalPriority
                        : Message::kOOBPriority);
    message = DequeueMessage(min_priority);
  }
  return max_status;
}

MessageHandler::MessageStatus MessageHandler::HandleNextMessage() {
  // We can only call HandleNextMessage when this handler is not
  // assigned to a thread pool.
  MonitorLocker ml(&monitor_);
  ASSERT(pool_ == NULL);
  ASSERT(!delete_me_);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(&ml, true, false);
}

MessageHandler::MessageStatus MessageHandler::HandleAllMessages() {
  // We can only call HandleAllMessages when this handler is not
  // assigned to a thread pool.
  MonitorLocker ml(&monitor_);
  ASSERT(pool_ == NULL);
  ASSERT(!delete_me_);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(&ml, true, true);
}

MessageHandler::MessageStatus MessageHandler::HandleOOBMessages() {
  if (!oob_message_handling_allowed_) {
    return kOK;
  }
  MonitorLocker ml(&monitor_);
  ASSERT(!delete_me_);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(&ml, false, false);
}

#if !defined(PRODUCT)
bool MessageHandler::ShouldPauseOnStart(MessageStatus status) const {
  Isolate* owning_isolate = isolate();
  if (owning_isolate == NULL) {
    return false;
  }
  // If we are restarting or shutting down, we do not want to honor
  // should_pause_on_start or should_pause_on_exit.
  return (status != MessageHandler::kRestart &&
          status != MessageHandler::kShutdown) &&
         should_pause_on_start() && owning_isolate->is_runnable();
}

bool MessageHandler::ShouldPauseOnExit(MessageStatus status) const {
  Isolate* owning_isolate = isolate();
  if (owning_isolate == NULL) {
    return false;
  }
  return (status != MessageHandler::kRestart &&
          status != MessageHandler::kShutdown) &&
         should_pause_on_exit() && owning_isolate->is_runnable();
}
#endif

bool MessageHandler::HasOOBMessages() {
  MonitorLocker ml(&monitor_);
  return !oob_queue_->IsEmpty();
}

void MessageHandler::TaskCallback() {
  ASSERT(Isolate::Current() == NULL);
  MessageStatus status = kOK;
  bool run_end_callback = false;
  bool delete_me = false;
  EndCallback end_callback = NULL;
  CallbackData callback_data = 0;
  {
    // We will occasionally release and reacquire this monitor in this
    // function. Whenever we reacquire the monitor we *must* process
    // all pending OOB messages, or we may miss a request for vm
    // shutdown.
    MonitorLocker ml(&monitor_);
#if !defined(PRODUCT)
    if (ShouldPauseOnStart(kOK)) {
      if (!is_paused_on_start()) {
        PausedOnStartLocked(&ml, true);
      }
      // More messages may have come in before we (re)acquired the monitor.
      status = HandleMessages(&ml, false, false);
      if (ShouldPauseOnStart(status)) {
        // Still paused.
        ASSERT(oob_queue_->IsEmpty());
        task_ = NULL;  // No task in queue.
        return;
      } else {
        PausedOnStartLocked(&ml, false);
      }
    }
#endif

    if (status == kOK) {
      if (start_callback_) {
        // Initialize the message handler by running its start function,
        // if we have one.  For an isolate, this will run the isolate's
        // main() function.
        //
        // Release the monitor_ temporarily while we call the start callback.
        ml.Exit();
        status = start_callback_(callback_data_);
        ASSERT(Isolate::Current() == NULL);
        start_callback_ = NULL;
        ml.Enter();
      }

      // Handle any pending messages for this message handler.
      if (status != kShutdown) {
        status = HandleMessages(&ml, (status == kOK), true);
      }
    }

    // The isolate exits when it encounters an error or when it no
    // longer has live ports.
    if (status != kOK || !HasLivePorts()) {
#if !defined(PRODUCT)
      if (ShouldPauseOnExit(status)) {
        if (!is_paused_on_exit()) {
          if (FLAG_trace_service_pause_events) {
            OS::PrintErr(
                "Isolate %s paused before exiting. "
                "Use the Observatory to release it.\n",
                name());
          }
          PausedOnExitLocked(&ml, true);
          // More messages may have come in while we released the monitor.
          status = HandleMessages(&ml, false, false);
        }
        if (ShouldPauseOnExit(status)) {
          // Still paused.
          ASSERT(oob_queue_->IsEmpty());
          task_ = NULL;  // No task in queue.
          return;
        } else {
          PausedOnExitLocked(&ml, false);
        }
      }
#endif  // !defined(PRODUCT)
      if (FLAG_trace_isolates) {
        if (status != kOK && thread() != NULL) {
          const Error& error = Error::Handle(thread()->sticky_error());
          OS::Print(
              "[-] Stopping message handler (%s):\n"
              "\thandler:    %s\n"
              "\terror:    %s\n",
              MessageStatusString(status), name(), error.ToCString());
        } else {
          OS::Print(
              "[-] Stopping message handler (%s):\n"
              "\thandler:    %s\n",
              MessageStatusString(status), name());
        }
      }
      pool_ = NULL;
      // Decide if we have a callback before releasing the monitor.
      end_callback = end_callback_;
      callback_data = callback_data_;
      run_end_callback = end_callback_ != NULL;
      delete_me = delete_me_;
    }

    // Clear the task_ last.  This allows other tasks to potentially start
    // for this message handler.
    ASSERT(oob_queue_->IsEmpty());
    task_ = NULL;
  }

  // The handler may have been deleted by another thread here if it is a native
  // message handler.

  // Message handlers either use delete_me or end_callback but not both.
  ASSERT(!delete_me || !run_end_callback);

  if (run_end_callback) {
    ASSERT(end_callback != NULL);
    end_callback(callback_data);
    // The handler may have been deleted after this point.
  }
  if (delete_me) {
    delete this;
  }
}

void MessageHandler::ClosePort(Dart_Port port) {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print(
        "[-] Closing port:\n"
        "\thandler:    %s\n"
        "\tport:       %" Pd64
        "\n"
        "\tports:      live(%" Pd ")\n",
        name(), port, live_ports_);
  }
}

void MessageHandler::CloseAllPorts() {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print(
        "[-] Closing all ports:\n"
        "\thandler:    %s\n",
        name());
  }
  queue_->Clear();
  oob_queue_->Clear();
}

void MessageHandler::RequestDeletion() {
  ASSERT(OwnedByPortMap());
  {
    MonitorLocker ml(&monitor_);
    if (task_ != NULL) {
      // This message handler currently has a task running on the thread pool.
      delete_me_ = true;
      return;
    }
  }

  // This message handler has no current task.  Delete it.
  delete this;
}

void MessageHandler::increment_live_ports() {
  MonitorLocker ml(&monitor_);
#if defined(DEBUG)
  CheckAccess();
#endif
  live_ports_++;
}

void MessageHandler::decrement_live_ports() {
  MonitorLocker ml(&monitor_);
#if defined(DEBUG)
  CheckAccess();
#endif
  live_ports_--;
}

#if !defined(PRODUCT)
void MessageHandler::DebugDump() {
  PortMap::DebugDumpForMessageHandler(this);
}

void MessageHandler::PausedOnStart(bool paused) {
  MonitorLocker ml(&monitor_);
  PausedOnStartLocked(&ml, paused);
}

void MessageHandler::PausedOnStartLocked(MonitorLocker* ml, bool paused) {
  if (paused) {
    ASSERT(!is_paused_on_start_);
    is_paused_on_start_ = true;
    paused_timestamp_ = OS::GetCurrentTimeMillis();
  } else {
    ASSERT(is_paused_on_start_);
    is_paused_on_start_ = false;
    paused_timestamp_ = -1;
  }
  if (is_paused_on_start_) {
    // Temporarily release the monitor when calling out to
    // NotifyPauseOnStart.  This avoids a dead lock that can occur
    // when this message handler tries to post a message while a
    // message is being posted to it.
    ml->Exit();
    NotifyPauseOnStart();
    ml->Enter();
  } else {
    // Resumed. Clear the resume request of the owning isolate.
    Isolate* owning_isolate = isolate();
    if (owning_isolate != NULL) {
      owning_isolate->GetAndClearResumeRequest();
    }
  }
}

void MessageHandler::PausedOnExit(bool paused) {
  MonitorLocker ml(&monitor_);
  PausedOnExitLocked(&ml, paused);
}

void MessageHandler::PausedOnExitLocked(MonitorLocker* ml, bool paused) {
  if (paused) {
    ASSERT(!is_paused_on_exit_);
    is_paused_on_exit_ = true;
    paused_timestamp_ = OS::GetCurrentTimeMillis();
  } else {
    ASSERT(is_paused_on_exit_);
    is_paused_on_exit_ = false;
    paused_timestamp_ = -1;
  }
  if (is_paused_on_exit_) {
    // Temporarily release the monitor when calling out to
    // NotifyPauseOnExit.  This avoids a dead lock that can
    // occur when this message handler tries to post a message
    // while a message is being posted to it.
    ml->Exit();
    NotifyPauseOnExit();
    ml->Enter();
  } else {
    // Resumed. Clear the resume request of the owning isolate.
    Isolate* owning_isolate = isolate();
    if (owning_isolate != NULL) {
      owning_isolate->GetAndClearResumeRequest();
    }
  }
}
#endif  // !defined(PRODUCT)

MessageHandler::AcquiredQueues::AcquiredQueues(MessageHandler* handler)
    : handler_(handler), ml_(&handler->monitor_) {
  ASSERT(handler != NULL);
  handler_->oob_message_handling_allowed_ = false;
}

MessageHandler::AcquiredQueues::~AcquiredQueues() {
  ASSERT(handler_ != NULL);
  handler_->oob_message_handling_allowed_ = true;
}

}  // namespace dart
