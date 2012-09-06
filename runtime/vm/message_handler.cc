// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_handler.h"
#include "vm/dart.h"

namespace dart {

DECLARE_FLAG(bool, trace_isolates);


class MessageHandlerTask : public ThreadPool::Task {
 public:
  explicit MessageHandlerTask(MessageHandler* handler)
      : handler_(handler) {
    ASSERT(handler != NULL);
  }

  void Run() {
    handler_->TaskCallback();
  }

 private:
  MessageHandler* handler_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandlerTask);
};


MessageHandler::MessageHandler()
    : queue_(new MessageQueue()),
      oob_queue_(new MessageQueue()),
      live_ports_(0),
      pool_(NULL),
      task_(NULL),
      start_callback_(NULL),
      end_callback_(NULL),
      callback_data_(NULL) {
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


void MessageHandler::PostMessage(Message* message) {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    const char* source_name = "<native code>";
    Isolate* source_isolate = Isolate::Current();
    if (source_isolate) {
      source_name = source_isolate->name();
    }
    OS::Print("[>] Posting message:\n"
              "\tsource:     %s\n"
              "\treply_port: %"Pd64"\n"
              "\tdest:       %s\n"
              "\tdest_port:  %"Pd64"\n",
              source_name, message->reply_port(), name(), message->dest_port());
  }

  Message::Priority saved_priority = message->priority();
  if (message->IsOOB()) {
    oob_queue_->Enqueue(message);
  } else {
    queue_->Enqueue(message);
  }
  message = NULL;  // Do not access message.  May have been deleted.

  if (pool_ != NULL && task_ == NULL) {
    task_ = new MessageHandlerTask(this);
    pool_->Run(task_);
  }

  // Invoke any custom message notification.
  MessageNotify(saved_priority);
}


Message* MessageHandler::DequeueMessage(Message::Priority min_priority) {
  // TODO(turnidge): Add assert that monitor_ is held here.
  Message* message = oob_queue_->Dequeue();
  if (message == NULL && min_priority < Message::kOOBPriority) {
    message = queue_->Dequeue();
  }
  return message;
}


bool MessageHandler::HandleMessages(bool allow_normal_messages,
                                    bool allow_multiple_normal_messages) {
  // TODO(turnidge): Add assert that monitor_ is held here.
  bool result = true;
  Message::Priority min_priority = (allow_normal_messages
                                    ? Message::kNormalPriority
                                    : Message::kOOBPriority);
  Message* message = DequeueMessage(min_priority);
  while (message) {
    if (FLAG_trace_isolates) {
      OS::Print("[<] Handling message:\n"
                "\thandler:    %s\n"
                "\tport:       %"Pd64"\n",
                name(), message->dest_port());
    }

    // Release the monitor_ temporarily while we handle the message.
    // The monitor was acquired in MessageHandler::TaskCallback().
    monitor_.Exit();
    Message::Priority saved_priority = message->priority();
    result = HandleMessage(message);
    // ASSERT(Isolate::Current() == NULL);
    monitor_.Enter();

    if (!result) {
      // If we hit an error, we're done processing messages.
      break;
    }
    if (!allow_multiple_normal_messages &&
        saved_priority == Message::kNormalPriority) {
      // Some callers want to process only one normal message and then quit.
      break;
    }
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
  MonitorLocker ml(&monitor_);
#if defined(DEBUG)
  CheckAccess();
#endif
  return HandleMessages(false, false);
}


void MessageHandler::TaskCallback() {
  ASSERT(Isolate::Current() == NULL);
  bool ok = true;
  bool run_end_callback = false;
  {
    MonitorLocker ml(&monitor_);
    // Initialize the message handler by running its start function,
    // if we have one.  For an isolate, this will run the isolate's
    // main() function.
    if (start_callback_) {
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
      if (FLAG_trace_isolates) {
        OS::Print("[-] Stopping message handler (%s):\n"
                  "\thandler:    %s\n",
                  (ok ? "no live ports" : "error"),
                  name());
      }
      pool_ = NULL;
      run_end_callback = true;
    }
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
              "\tport:       %"Pd64"\n",
              name(), port);
  }
  queue_->Flush(port);
  oob_queue_->Flush(port);
}


void MessageHandler::CloseAllPorts() {
  MonitorLocker ml(&monitor_);
  if (FLAG_trace_isolates) {
    OS::Print("[-] Closing all ports:\n"
              "\thandler:    %s\n",
              name());
  }
  queue_->FlushAll();
  oob_queue_->FlushAll();
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

}  // namespace dart
