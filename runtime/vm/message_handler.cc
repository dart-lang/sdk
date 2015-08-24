// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_handler.h"

#include "vm/dart.h"
#include "vm/lockers.h"
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
    handler_->TaskCallback();
  }

 private:
  MessageHandler* handler_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandlerTask);
};


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
  pool_->Run(task_);
}


void MessageHandler::PostMessage(Message* message, bool before_events) {
  Message::Priority saved_priority;
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

    if (pool_ != NULL && task_ == NULL) {
      task_ = new MessageHandlerTask(this);
      pool_->Run(task_);
    }
  }
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


bool MessageHandler::HandleMessages(bool allow_normal_messages,
                                    bool allow_multiple_normal_messages) {
  // If isolate() returns NULL StartIsolateScope does nothing.
  StartIsolateScope start_isolate(isolate());

  // ThreadInterrupter may have gone to sleep waiting while waiting for
  // an isolate to start handling messages.
  ThreadInterrupter::WakeUp();

  // TODO(turnidge): Add assert that monitor_ is held here.
  bool result = true;
  Message::Priority min_priority = (allow_normal_messages && !paused()) ?
      Message::kNormalPriority : Message::kOOBPriority;
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
    result = HandleMessage(message);
    message = NULL;  // May be deleted by now.
    monitor_.Enter();
    if (FLAG_trace_isolates) {
      OS::Print("[.] Message handled:\n"
                "\tlen:        %" Pd "\n"
                "\thandler:    %s\n"
                "\tport:       %" Pd64 "\n",
                message_len, name(), saved_dest_port);
    }
    if (!result) {
      // If we hit an error, we're done processing messages.
      break;
    }
    // Some callers want to process only one normal message and then quit. At
    // the same time it is OK to process multiple OOB messages.
    if ((saved_priority == Message::kNormalPriority) &&
        !allow_multiple_normal_messages) {
      break;
    }

    // Reevaluate the minimum allowable priority as the paused state might
    // have changed as part of handling the message.
    min_priority = (allow_normal_messages && !paused()) ?
        Message::kNormalPriority : Message::kOOBPriority;
    message = DequeueMessage(min_priority);
  }
  return result;
}


bool MessageHandler::HandleNextMessage() {
  // We can only call HandleNextMessage when this handler is not
  // assigned to a thread pool.
  MonitorLocker ml(&monitor_);
  ASSERT(pool_ == NULL);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(true, false);
}


bool MessageHandler::HandleOOBMessages() {
  if (!oob_message_handling_allowed_) {
    return true;
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


void MessageHandler::TaskCallback() {
  ASSERT(Isolate::Current() == NULL);
  bool ok = true;
  bool run_end_callback = false;
  bool notify_paused_on_exit = false;
  {
    MonitorLocker ml(&monitor_);
    // Initialize the message handler by running its start function,
    // if we have one.  For an isolate, this will run the isolate's
    // main() function.
    if (pause_on_start()) {
      if (!paused_on_start_) {
        // Temporarily drop the lock when calling out to NotifyPauseOnStart.
        // This avoids a dead lock that can occur when this message handler
        // tries to post a message while a message is being posted to it.
        monitor_.Exit();
        NotifyPauseOnStart();
        monitor_.Enter();
        paused_on_start_ = true;
      }
      HandleMessages(false, false);
      if (pause_on_start()) {
        // Still paused.
        task_ = NULL;  // No task in queue.
        return;
      } else {
        paused_on_start_ = false;
      }
    }

    if (start_callback_) {
      // Release the monitor_ temporarily while we call the start callback.
      // The monitor was acquired with the MonitorLocker above.
      monitor_.Exit();
      ok = start_callback_(callback_data_);
      ASSERT(Isolate::Current() == NULL);
      start_callback_ = NULL;
      monitor_.Enter();
    }

    // Handle any pending messages for this message handler.
    if (ok) {
      ok = HandleMessages(true, true);
    }
    task_ = NULL;  // No task in queue.

    if (!ok || !HasLivePorts()) {
      if (pause_on_exit()) {
        if (!paused_on_exit_) {
          if (FLAG_trace_service_pause_events) {
            OS::PrintErr("Isolate %s paused before exiting. "
                       "Use the Observatory to release it.\n", name());
          }
          notify_paused_on_exit = true;
          paused_on_exit_ = true;
        }
      } else {
        if (FLAG_trace_isolates) {
        OS::Print("[-] Stopping message handler (%s):\n"
                  "\thandler:    %s\n",
                  (ok ? "no live ports" : "error"),
                  name());
        }
        pool_ = NULL;
        run_end_callback = true;
        paused_on_exit_ = false;
      }
    }
  }
  // At this point we no longer hold the message handler lock.
  if (notify_paused_on_exit) {
    NotifyPauseOnExit();
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
