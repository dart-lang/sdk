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

DECLARE_FLAG(bool, trace_isolates);
DECLARE_FLAG(bool, trace_service_pause_events);

class MessageHandlerTask : public ThreadPool::Task {
 public:
  explicit MessageHandlerTask(MessageHandler* handler)
      : handler_(handler) {
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
      pause_on_start_(false),
      pause_on_exit_(false),
      paused_on_start_(false),
      paused_on_exit_(false),
      paused_timestamp_(-1),
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
    OS::Print("[+] Starting message handler:\n"
              "\thandler:    %s\n",
              name());
  }
  ASSERT(pool_ == NULL);
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
      const char* source_name = "<native code>";
      Isolate* source_isolate = Isolate::Current();
      if (source_isolate) {
        source_name = source_isolate->name();
      }
      OS::Print("[>] Posting message:\n"
                "\tlen:        %" Pd "\n"
                "\tsource:     %s\n"
                "\tdest:       %s\n"
                "\tdest_port:  %" Pd64 "\n",
                message->len(), source_name, name(), message->dest_port());
    }

    saved_priority = message->priority();
    if (message->IsOOB()) {
      oob_queue_->Enqueue(message, before_events);
    } else {
      queue_->Enqueue(message, before_events);
    }
    message = NULL;  // Do not access message.  May have been deleted.

    if ((pool_ != NULL) && (task_ == NULL)) {
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
    bool allow_normal_messages,
    bool allow_multiple_normal_messages) {
  // TODO(turnidge): Add assert that monitor_ is held here.

  // If isolate() returns NULL StartIsolateScope does nothing.
  StartIsolateScope start_isolate(isolate());

  MessageStatus max_status = kOK;
  Message::Priority min_priority = ((allow_normal_messages && !paused())
                                    ? Message::kNormalPriority
                                    : Message::kOOBPriority);
  Message* message = DequeueMessage(min_priority);
  while (message != NULL) {
    intptr_t message_len = message->len();
    if (FLAG_trace_isolates) {
      OS::Print("[<] Handling message:\n"
                "\tlen:        %" Pd "\n"
                "\thandler:    %s\n"
                "\tport:       %" Pd64 "\n",
                message_len, name(), message->dest_port());
    }

    // Release the monitor_ temporarily while we handle the message.
    // The monitor was acquired in MessageHandler::TaskCallback().
    monitor_.Exit();
    Message::Priority saved_priority = message->priority();
    Dart_Port saved_dest_port = message->dest_port();
    MessageStatus status = HandleMessage(message);
    if (status > max_status) {
      max_status = status;
    }
    message = NULL;  // May be deleted by now.
    monitor_.Enter();
    if (FLAG_trace_isolates) {
      OS::Print("[.] Message handled (%s):\n"
                "\tlen:        %" Pd "\n"
                "\thandler:    %s\n"
                "\tport:       %" Pd64 "\n",
                MessageStatusString(status),
                message_len, name(), saved_dest_port);
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
    // have encountered an error during message processsing.
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
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(true, false);
}


MessageHandler::MessageStatus MessageHandler::HandleOOBMessages() {
  if (!oob_message_handling_allowed_) {
    return kOK;
  }
  MonitorLocker ml(&monitor_);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(false, false);
}


bool MessageHandler::HasOOBMessages() {
  MonitorLocker ml(&monitor_);
  return !oob_queue_->IsEmpty();
}


static bool ShouldPause(MessageHandler::MessageStatus status) {
  // If we are restarting or shutting down, we do not want to honor
  // pause_on_start or pause_on_exit.
  return (status != MessageHandler::kRestart &&
          status != MessageHandler::kShutdown);
}


void MessageHandler::TaskCallback() {
  ASSERT(Isolate::Current() == NULL);
  MessageStatus status = kOK;
  bool run_end_callback = false;
  {
    // We will occasionally release and reacquire this monitor in this
    // function. Whenever we reacquire the monitor we *must* process
    // all pending OOB messages, or we may miss a request for vm
    // shutdown.
    MonitorLocker ml(&monitor_);
    if (pause_on_start()) {
      if (!paused_on_start_) {
        // Temporarily release the monitor when calling out to
        // NotifyPauseOnStart.  This avoids a dead lock that can occur
        // when this message handler tries to post a message while a
        // message is being posted to it.
        paused_on_start_ = true;
        paused_timestamp_ = OS::GetCurrentTimeMillis();
        monitor_.Exit();
        NotifyPauseOnStart();
        monitor_.Enter();
      }
      // More messages may have come in before we (re)acquired the monitor.
      status = HandleMessages(false, false);
      if (ShouldPause(status) && pause_on_start()) {
        // Still paused.
        ASSERT(oob_queue_->IsEmpty());
        task_ = NULL;  // No task in queue.
        return;
      } else {
        paused_on_start_ = false;
        paused_timestamp_ = -1;
      }
    }

    if (status == kOK) {
      if (start_callback_) {
        // Initialize the message handler by running its start function,
        // if we have one.  For an isolate, this will run the isolate's
        // main() function.
        //
        // Release the monitor_ temporarily while we call the start callback.
        monitor_.Exit();
        status = start_callback_(callback_data_);
        ASSERT(Isolate::Current() == NULL);
        start_callback_ = NULL;
        monitor_.Enter();
      }

      // Handle any pending messages for this message handler.
      if (status != kShutdown) {
        status = HandleMessages((status == kOK), true);
      }
    }

    // The isolate exits when it encounters an error or when it no
    // longer has live ports.
    if (status != kOK || !HasLivePorts()) {
      if (ShouldPause(status) && pause_on_exit()) {
        if (!paused_on_exit_) {
          if (FLAG_trace_service_pause_events) {
            OS::PrintErr("Isolate %s paused before exiting. "
                         "Use the Observatory to release it.\n", name());
          }
          // Temporarily release the monitor when calling out to
          // NotifyPauseOnExit.  This avoids a dead lock that can
          // occur when this message handler tries to post a message
          // while a message is being posted to it.
          paused_on_exit_ = true;
          paused_timestamp_ = OS::GetCurrentTimeMillis();
          monitor_.Exit();
          NotifyPauseOnExit();
          monitor_.Enter();

          // More messages may have come in while we released the monitor.
          HandleMessages(false, false);
        }
        if (ShouldPause(status) && pause_on_exit()) {
          // Still paused.
          ASSERT(oob_queue_->IsEmpty());
          task_ = NULL;  // No task in queue.
          return;
        } else {
          paused_on_exit_ = false;
          paused_timestamp_ = -1;
        }
      }
      if (FLAG_trace_isolates) {
        if (status != kOK && isolate() != NULL) {
          const Error& error =
              Error::Handle(isolate()->object_store()->sticky_error());
          OS::Print("[-] Stopping message handler (%s):\n"
                    "\thandler:    %s\n"
                    "\terror:    %s\n",
                    MessageStatusString(status), name(), error.ToCString());
        } else {
          OS::Print("[-] Stopping message handler (%s):\n"
                    "\thandler:    %s\n",
                    MessageStatusString(status), name());
        }
      }
      pool_ = NULL;
      run_end_callback = true;
    }

    // Clear the task_ last.  This allows other tasks to potentially start
    // for this message handler.
    ASSERT(oob_queue_->IsEmpty());
    task_ = NULL;
  }
  if (run_end_callback && end_callback_ != NULL) {
    end_callback_(callback_data_);
    // The handler may have been deleted after this point.
  }
}


void MessageHandler::ClosePort(Dart_Port port) {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print("[-] Closing port:\n"
              "\thandler:    %s\n"
              "\tport:       %" Pd64 "\n"
              "\tports:      live(%" Pd ")\n",
              name(), port, live_ports_);
  }
}


void MessageHandler::CloseAllPorts() {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print("[-] Closing all ports:\n"
              "\thandler:    %s\n",
              name());
  }
  queue_->Clear();
  oob_queue_->Clear();
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


MessageHandler::AcquiredQueues::AcquiredQueues()
    : handler_(NULL) {
}


MessageHandler::AcquiredQueues::~AcquiredQueues() {
  Reset(NULL);
}


void MessageHandler::AcquiredQueues::Reset(MessageHandler* handler) {
  if (handler_ != NULL) {
    // Release ownership. The OOB flag is set without holding the monitor.
    handler_->monitor_.Exit();
    handler_->oob_message_handling_allowed_ = true;
  }
  handler_ = handler;
  if (handler_ == NULL) {
    return;
  }
  ASSERT(handler_ != NULL);
  // Take ownership. The OOB flag is set without holding the monitor.
  handler_->oob_message_handling_allowed_ = false;
  handler_->monitor_.Enter();
}


void MessageHandler::AcquireQueues(AcquiredQueues* acquired_queues) {
  ASSERT(acquired_queues != NULL);
  // No double dipping.
  ASSERT(acquired_queues->handler_ == NULL);
  acquired_queues->Reset(this);
}

}  // namespace dart
