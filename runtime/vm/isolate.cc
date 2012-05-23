// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "lib/mirrors.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debuginfo.h"
#include "vm/heap.h"
#include "vm/message_handler.h"
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

DEFINE_FLAG(bool, report_usage_count, false,
            "Track function usage and report.");
DEFINE_FLAG(bool, trace_isolates, false,
            "Trace isolate creation and shut down.");
DECLARE_FLAG(bool, generate_gdb_symbols);


class IsolateMessageHandler : public MessageHandler {
 public:
  explicit IsolateMessageHandler(Isolate* isolate);
  ~IsolateMessageHandler();

  const char* name() const;
  void MessageNotify(Message::Priority priority);
  bool HandleMessage(Message* message);

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess();
#endif
 private:
  Isolate* isolate_;
};


IsolateMessageHandler::IsolateMessageHandler(Isolate* isolate)
    : isolate_(isolate) {
}


IsolateMessageHandler::~IsolateMessageHandler() {
}

const char* IsolateMessageHandler::name() const {
  return isolate_->name();
}


void IsolateMessageHandler::MessageNotify(Message::Priority priority) {
  if (priority >= Message::kOOBPriority) {
    // Handle out of band messages even if the isolate is busy.
    isolate_->ScheduleInterrupts(Isolate::kMessageInterrupt);
  }
  Dart_MessageNotifyCallback callback = isolate_->message_notify_callback();
  if (callback) {
    // Allow the embedder to handle message notification.
    (*callback)(Api::CastIsolate(isolate_));
  }
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


bool IsolateMessageHandler::HandleMessage(Message* message) {
  StartIsolateScope start_scope(isolate_);
  Zone zone(isolate_);
  HandleScope handle_scope(isolate_);

  const Instance& msg =
      Instance::Handle(DeserializeMessage(message->data()));
  if (message->IsOOB()) {
    // For now the only OOB messages are Mirrors messages.
    HandleMirrorsMessage(isolate_, message->reply_port(), msg);
    delete message;
  } else {
    const Object& result = Object::Handle(
        DartLibraryCalls::HandleMessage(
            message->dest_port(), message->reply_port(), msg));
    delete message;
    if (result.IsError()) {
      Error& error = Error::Handle();
      error ^= result.raw();
      isolate_->object_store()->set_sticky_error(error);
      return false;
    }
    ASSERT(result.IsNull());
  }
  return true;
}


#if defined(DEBUG)
void IsolateMessageHandler::CheckAccess() {
  ASSERT(isolate_ == Isolate::Current());
}
#endif


#if defined(DEBUG)
// static
void BaseIsolate::AssertCurrent(BaseIsolate* isolate) {
  ASSERT(isolate == Isolate::Current());
}
#endif


Isolate::Isolate()
    : store_buffer_(),
      message_notify_callback_(NULL),
      name_(NULL),
      main_port_(0),
      heap_(NULL),
      object_store_(NULL),
      top_context_(Context::null()),
      random_seed_(Random::kDefaultRandomSeed),
      top_exit_frame_info_(0),
      init_callback_data_(NULL),
      library_tag_handler_(NULL),
      api_state_(NULL),
      stub_code_(NULL),
      debugger_(NULL),
      long_jump_base_(NULL),
      timer_list_(),
      ast_node_id_(AstNode::kNoId),
      computation_id_(AstNode::kNoId),
      ic_data_array_(Array::null()),
      mutex_(new Mutex()),
      stack_limit_(0),
      saved_stack_limit_(0),
      message_handler_(NULL),
      spawn_data_(NULL) {
}


Isolate::~Isolate() {
  delete [] name_;
  delete heap_;
  delete object_store_;
  delete api_state_;
  delete stub_code_;
  delete debugger_;
  delete mutex_;
  mutex_ = NULL;  // Fail fast if interrupts are scheduled on a dead isolate.
  delete message_handler_;
  message_handler_ = NULL;  // Fail fast if we send messages to a dead isolate.
}

void Isolate::SetCurrent(Isolate* current) {
  Thread::SetThreadLocal(isolate_key, reinterpret_cast<uword>(current));
}


// The single thread local key which stores all the thread local data
// for a thread. Since an Isolate is the central repository for
// storing all isolate specific information a single thread local key
// is sufficient.
ThreadLocalKey Isolate::isolate_key = Thread::kUnsetThreadLocalKey;


void Isolate::InitOnce() {
  ASSERT(isolate_key == Thread::kUnsetThreadLocalKey);
  isolate_key = Thread::CreateThreadLocal();
  ASSERT(isolate_key != Thread::kUnsetThreadLocalKey);
  create_callback_ = NULL;
}


Isolate* Isolate::Init(const char* name_prefix) {
  Isolate* result = new Isolate();
  ASSERT(result != NULL);

  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  SetCurrent(result);

  // Setup the isolate message handler.
  MessageHandler* handler = new IsolateMessageHandler(result);
  ASSERT(handler != NULL);
  result->set_message_handler(handler);

  // Setup the Dart API state.
  ApiState* state = new ApiState();
  ASSERT(state != NULL);
  result->set_api_state(state);

  // Initialize stack top and limit in case we are running the isolate in the
  // main thread.
  // TODO(5411455): Need to figure out how to set the stack limit for the
  // main thread.
  result->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(&result));
  result->set_main_port(PortMap::CreatePort(result->message_handler()));
  result->BuildName(name_prefix);

  result->debugger_ = new Debugger();
  result->debugger_->Initialize(result);
  if (FLAG_trace_isolates) {
    if (name_prefix == NULL || strcmp(name_prefix, "vm-isolate") != 0) {
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


static int MostUsedFunctionFirst(const Function* const* a,
                                 const Function* const* b) {
  if ((*a)->usage_counter() > (*b)->usage_counter()) {
    return -1;
  } else if ((*a)->usage_counter() < (*b)->usage_counter()) {
    return 1;
  } else {
    return 0;
  }
}


static void AddFunctionsFromClass(const Class& cls,
                                  GrowableArray<const Function*>* functions) {
  const Array& class_functions = Array::Handle(cls.functions());
  // Class 'Dynamic' is allocated/initialized in a special way, leaving
  // the functions field NULL instead of empty.
  const int func_len = class_functions.IsNull() ? 0 : class_functions.Length();
  for (int j = 0; j < func_len; j++) {
    Function& function = Function::Handle();
    function ^= class_functions.At(j);
    if (function.usage_counter() > 0) {
      functions->Add(&function);
    }
  }
}


void Isolate::PrintInvokedFunctions() {
  ASSERT(this == Isolate::Current());
  Zone zone(this);
  HandleScope handle_scope(this);
  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(object_store()->libraries());
  Library& library = Library::Handle();
  GrowableArray<const Function*> invoked_functions;
  for (int i = 0; i < libraries.Length(); i++) {
    library ^= libraries.At(i);
    Class& cls = Class::Handle();
    ClassDictionaryIterator iter(library);
    while (iter.HasNext()) {
      cls = iter.GetNextClass();
      AddFunctionsFromClass(cls, &invoked_functions);
    }
    Array& anon_classes = Array::Handle(library.raw_ptr()->anonymous_classes_);
    for (int i = 0; i < library.raw_ptr()->num_anonymous_; i++) {
      cls ^= anon_classes.At(i);
      AddFunctionsFromClass(cls, &invoked_functions);
    }
  }
  invoked_functions.Sort(MostUsedFunctionFirst);
  for (int i = 0; i < invoked_functions.length(); i++) {
    OS::Print("%10d x %s\n",
        invoked_functions[i]->usage_counter(),
        invoked_functions[i]->ToFullyQualifiedCString());
  }
}


void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  ASSERT(top_resource() == NULL);
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
  PortMap::ClosePorts(message_handler());

  // Fail fast if anybody tries to post any more messsages to this isolate.
  delete message_handler();
  set_message_handler(NULL);

  // Dump all accumalated timer data for the isolate.
  timer_list_.ReportTimers();
  if (FLAG_report_usage_count) {
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


void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  bool visit_prologue_weak_handles,
                                  bool validate_frames) {
  ASSERT(visitor != NULL);

  // Visit objects in the object store.
  object_store()->VisitObjectPointers(visitor);

  // Visit objects in the class table.
  class_table()->VisitObjectPointers(visitor);

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
    api_state()->VisitObjectPointers(visitor, visit_prologue_weak_handles);
  }

  // Visit the top context which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&top_context_));

  // Visit the currently active IC data array.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&ic_data_array_));

  // Visit objects in the debugger.
  debugger()->VisitObjectPointers(visitor);
}


void Isolate::VisitWeakPersistentHandles(HandleVisitor* visitor,
                                         bool visit_prologue_weak_handles) {
  if (api_state() != NULL) {
    api_state()->VisitWeakHandles(visitor, visit_prologue_weak_handles);
  }
}

}  // namespace dart
