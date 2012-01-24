// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/bigint_store.h"
#include "vm/code_index_table.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debuginfo.h"
#include "vm/heap.h"
#include "vm/message_queue.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/random.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/thread.h"
#include "vm/timer.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, report_invocation_count, false,
            "Count function invocations and report.");
DEFINE_FLAG(bool, trace_isolates, false,
            "Trace isolate creation and shut down.");
DECLARE_FLAG(bool, generate_gdb_symbols);


Isolate::Isolate()
    : store_buffer_(),
      message_queue_(NULL),
      message_notify_callback_(NULL),
      name_(NULL),
      num_ports_(0),
      live_ports_(0),
      main_port_(0),
      heap_(NULL),
      object_store_(NULL),
      top_resource_(NULL),
      top_context_(Context::null()),
      current_zone_(NULL),
#if defined(DEBUG)
      no_gc_scope_depth_(0),
      no_handle_scope_depth_(0),
      top_handle_scope_(NULL),
#endif
      random_seed_(Random::kDefaultRandomSeed),
      bigint_store_(NULL),
      top_exit_frame_info_(0),
      init_callback_data_(NULL),
      library_tag_handler_(NULL),
      api_state_(NULL),
      stub_code_(NULL),
      code_index_table_(NULL),
      debugger_(NULL),
      long_jump_base_(NULL),
      timer_list_(),
      ast_node_id_(AstNode::kNoId),
      mutex_(new Mutex()),
      stack_limit_(0),
      saved_stack_limit_(0) {
}


Isolate::~Isolate() {
  delete [] name_;
  delete message_queue_;
  delete heap_;
  delete object_store_;
  // Do not delete stack resources: top_resource_ and current_zone_.
  delete bigint_store_;
  delete api_state_;
  delete stub_code_;
  delete code_index_table_;
  delete debugger_;
  delete mutex_;
  mutex_ = NULL;  // Fail fast if interrupts are scheduled on a dead isolate.
}


void Isolate::PostMessage(Message* message) {
  if (FLAG_trace_isolates) {
    const char* source_name = "<native code>";
    Isolate* source_isolate = Isolate::Current();
    if (source_isolate) {
      source_name = source_isolate->name();
    }
    OS::Print("[>] Posting message:\n"
              "\tsource:     %s\n"
              "\treply_port: %lld\n"
              "\tdest:       %s\n"
              "\tdest_port:  %lld\n",
              source_name, message->reply_port(), name(), message->dest_port());
  }

  Message::Priority priority = message->priority();
  message_queue()->Enqueue(message);
  message = NULL;  // Do not access message.  May have been deleted.

  ASSERT(priority < Message::kOOBPriority);
  if (priority >= Message::kOOBPriority) {
    // Handle out of band messages even if the isolate is busy.
    ScheduleInterrupts(Isolate::kMessageInterrupt);
  }
  Dart_MessageNotifyCallback callback = message_notify_callback();
  if (callback) {
    // Allow the embedder to handle message notification.
    (*callback)(Api::CastIsolate(this));
  }
}


void Isolate::ClosePort(Dart_Port port) {
  message_queue()->Flush(port);
}


void Isolate::CloseAllPorts() {
  message_queue()->FlushAll();
}


Isolate* Isolate::Init(const char* name_prefix) {
  Isolate* result = new Isolate();
  ASSERT(result != NULL);

  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  SetCurrent(result);

  // Set up the isolate message queue.
  MessageQueue* queue = new MessageQueue();
  ASSERT(queue != NULL);
  result->set_message_queue(queue);

  // Setup the Dart API state.
  ApiState* state = new ApiState();
  ASSERT(state != NULL);
  result->set_api_state(state);

  // Initialize stack top and limit in case we are running the isolate in the
  // main thread.
  // TODO(5411455): Need to figure out how to set the stack limit for the
  // main thread.
  result->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(&result));
  result->set_main_port(PortMap::CreatePort());
  result->BuildName(name_prefix);

  result->debugger_ = new Debugger();
  result->debugger_->Initialize(result);
  if (FLAG_trace_isolates) {
    if (strcmp(name_prefix, "vm-isolate") != 0) {
      OS::Print("[+] Starting isolate:\n"
                "\tisolate:    %s\n", result->name());
    }
  }
  return result;
}


void Isolate::BuildName(const char* name_prefix) {
  ASSERT(name_ == NULL);
  if (name_prefix == NULL) {
    name_prefix = "isolate";
  }
  const char* kFormat = "%s-%lld";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, name_prefix, main_port()) + 1;
  name_ = new char[len];
  OS::SNPrint(name_, len, kFormat, name_prefix, main_port());
}


// TODO(5411455): Use flag to override default value and Validate the
// stack size by querying OS.
uword Isolate::GetSpecifiedStackSize() {
  uword stack_size = Isolate::kDefaultStackSize - Isolate::kStackSizeBuffer;
  return stack_size;
}


void Isolate::SetStackLimitFromCurrentTOS(uword stack_top_value) {
  SetStackLimit(stack_top_value - GetSpecifiedStackSize());
}


void Isolate::SetStackLimit(uword limit) {
  MutexLocker ml(mutex_);
  if (stack_limit_ == saved_stack_limit_) {
    // No interrupt pending, set stack_limit_ too.
    stack_limit_ = limit;
  }
  saved_stack_limit_ = limit;
}


void Isolate::ScheduleInterrupts(uword interrupt_bits) {
  // TODO(turnidge): Can't use MutexLocker here because MutexLocker is
  // a StackResource, which requires a current isolate.  Should
  // MutexLocker really be a StackResource?
  mutex_->Lock();
  ASSERT((interrupt_bits & ~kInterruptsMask) == 0);  // Must fit in mask.
  if (stack_limit_ == saved_stack_limit_) {
    stack_limit_ = (~static_cast<uword>(0)) & ~kInterruptsMask;
  }
  stack_limit_ |= interrupt_bits;
  mutex_->Unlock();
}


uword Isolate::GetAndClearInterrupts() {
  MutexLocker ml(mutex_);
  if (stack_limit_ == saved_stack_limit_) {
    return 0;  // No interrupt was requested.
  }
  uword interrupt_bits = stack_limit_ & kInterruptsMask;
  stack_limit_ = saved_stack_limit_;
  return interrupt_bits;
}


static int MostCalledFunctionFirst(const Function* const* a,
                                   const Function* const* b) {
  if ((*a)->invocation_counter() > (*b)->invocation_counter()) {
    return -1;
  } else if ((*a)->invocation_counter() < (*b)->invocation_counter()) {
    return 1;
  } else {
    return 0;
  }
}


void Isolate::PrintInvokedFunctions() {
  ASSERT(this == Isolate::Current());
  Zone zone(this);
  HandleScope handle_scope(this);
  Library& library = Library::Handle();
  library = object_store()->registered_libraries();
  GrowableArray<const Function*> invoked_functions;
  while (!library.IsNull()) {
    Class& cls = Class::Handle();
    ClassDictionaryIterator iter(library);
    while (iter.HasNext()) {
      cls = iter.GetNextClass();
      const Array& functions = Array::Handle(cls.functions());
      // Class 'Dynamic' is allocated/initialized in a special way, leaving
      // the functions field NULL instead of empty.
      const int func_len = functions.IsNull() ? 0 : functions.Length();
      for (int j = 0; j < func_len; j++) {
        Function& function = Function::Handle();
        function ^= functions.At(j);
        if (function.invocation_counter() > 0) {
          invoked_functions.Add(&function);
        }
      }
    }
    library = library.next_registered();
  }
  invoked_functions.Sort(MostCalledFunctionFirst);
  for (int i = 0; i < invoked_functions.length(); i++) {
    OS::Print("%10d x %s\n",
        invoked_functions[i]->invocation_counter(),
        invoked_functions[i]->ToFullyQualifiedCString());
  }
}


void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  ASSERT(top_resource_ == NULL);
  ASSERT((heap_ == NULL) || heap_->Verify());

  // Clean up debugger resources. Shutting down the debugger
  // requires a handle zone. We must set up a temporary zone because
  // Isolate::Shutdown is called without a zone.
  {
    Zone zone(this);
    HandleScope handle_scope(this);
    debugger_->Shutdown();
  }

  // Close all the ports owned by this isolate.
  PortMap::ClosePorts();

  delete message_queue();
  set_message_queue(NULL);

  // Dump all accumalated timer data for the isolate.
  timer_list_.ReportTimers();
  if (FLAG_report_invocation_count) {
    PrintInvokedFunctions();
  }
  CompilerStats::Print();
  if (FLAG_generate_gdb_symbols) {
    DebugInfo::UnregisterAllSections();
  }
  if (FLAG_trace_isolates) {
    OS::Print("[-] Stopping isolate:\n"
              "\tisolate:    %s\n", name());
  }
  // TODO(5411455): For now just make sure there are no current isolates
  // as we are shutting down the isolate.
  SetCurrent(NULL);
}


Dart_IsolateCreateCallback Isolate::create_callback_ = NULL;
Dart_IsolateInterruptCallback Isolate::interrupt_callback_ = NULL;


void Isolate::SetCreateCallback(Dart_IsolateCreateCallback cb) {
  create_callback_ = cb;
}


Dart_IsolateCreateCallback Isolate::CreateCallback() {
  return create_callback_;
}


void Isolate::SetInterruptCallback(Dart_IsolateInterruptCallback cb) {
  interrupt_callback_ = cb;
}


Dart_IsolateInterruptCallback Isolate::InterruptCallback() {
  return interrupt_callback_;
}


static RawInstance* DeserializeMessage(void* data) {
  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(data);
  ASSERT(snapshot->IsMessageSnapshot());

  // Read object back from the snapshot.
  SnapshotReader reader(snapshot, Isolate::Current());
  Instance& instance = Instance::Handle();
  instance ^= reader.ReadObject();
  return instance.raw();
}



RawObject* Isolate::StandardRunLoop() {
  ASSERT(long_jump_base() != NULL);
  ASSERT(message_notify_callback() == NULL);

  while (live_ports() > 0) {
    ASSERT(this == Isolate::Current());
    Zone zone(this);
    HandleScope handle_scope(this);

    Message* message = message_queue()->Dequeue(0);
    if (message != NULL) {
      if (message->priority() >= Message::kOOBPriority) {
        // TODO(turnidge): Out of band messages will not go through the
        // regular message handler.  Instead they will be dispatched to
        // special vm code.  Implement.
        UNIMPLEMENTED();
      }
      const Instance& msg =
          Instance::Handle(DeserializeMessage(message->data()));
      const Object& result = Object::Handle(
          DartLibraryCalls::HandleMessage(
              message->dest_port(), message->reply_port(), msg));
      delete message;
      if (result.IsError()) {
        return result.raw();
      }
      ASSERT(result.IsNull());
    }
  }

  // Indicates success.
  return Object::null();
}


void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  bool validate_frames) {
  ASSERT(visitor != NULL);

  // Visit objects in the object store.
  object_store()->VisitObjectPointers(visitor);

  // Visit objects in per isolate stubs.
  StubCode::VisitObjectPointers(visitor);

  // Visit objects in zones.
  current_zone()->VisitObjectPointers(visitor);

  // Iterate over all the stack frames and visit objects on the stack.
  StackFrameIterator frames_iterator(validate_frames);
  StackFrame* frame = frames_iterator.NextFrame();
  while (frame != NULL) {
    frame->VisitObjectPointers(visitor);
    frame = frames_iterator.NextFrame();
  }

  // Visit the dart api state for all local and persistent handles.
  if (api_state() != NULL) {
    api_state()->VisitObjectPointers(visitor);
  }

  // Visit all objects in the code index table.
  if (code_index_table() != NULL) {
    code_index_table()->VisitObjectPointers(visitor);
  }

  // Visit the top context which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&top_context_));

  // Visit objects in the debugger.
  debugger()->VisitObjectPointers(visitor);
}


void Isolate::VisitWeakPersistentHandles(HandleVisitor* visitor) {
  if (api_state() != NULL) {
    api_state()->VisitWeakHandles(visitor);
  }
}

}  // namespace dart
