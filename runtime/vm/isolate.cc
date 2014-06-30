// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/json.h"
#include "lib/mirrors.h"
#include "vm/code_observers.h"
#include "vm/compiler_stats.h"
#include "vm/coverage.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/heap.h"
#include "vm/message_handler.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/service.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/thread_interrupter.h"
#include "vm/timer.h"
#include "vm/visitor.h"


namespace dart {

DEFINE_FLAG(bool, trace_isolates, false,
            "Trace isolate creation and shut down.");
DEFINE_FLAG(bool, pause_isolates_on_start, false,
            "Pause isolates before starting.");
DEFINE_FLAG(bool, pause_isolates_on_exit, false,
            "Pause isolates exiting.");


// Quick access to the locally defined isolate() method.
#define I (isolate())


void Isolate::RegisterClass(const Class& cls) {
  class_table()->Register(cls);
}


void Isolate::RegisterClassAt(intptr_t index, const Class& cls) {
  class_table()->RegisterAt(index, cls);
}


void Isolate::ValidateClassTable() {
  class_table()->Validate();
}


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
  bool IsCurrentIsolate() const;
  virtual Isolate* isolate() const { return isolate_; }
  bool UnhandledExceptionCallbackHandler(const Object& message,
                                         const UnhandledException& error);

 private:
  bool ProcessUnhandledException(const Object& message, const Error& result);
  RawFunction* ResolveCallbackFunction();
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
    I->ScheduleInterrupts(Isolate::kMessageInterrupt);
  }
  Dart_MessageNotifyCallback callback = I->message_notify_callback();
  if (callback) {
    // Allow the embedder to handle message notification.
    (*callback)(Api::CastIsolate(I));
  }
}


bool IsolateMessageHandler::HandleMessage(Message* message) {
  StartIsolateScope start_scope(I);
  StackZone zone(I);
  HandleScope handle_scope(I);
  // TODO(turnidge): Rework collection total dart execution.  This can
  // overcount when other things (gc, compilation) are active.
  TIMERSCOPE(isolate_, time_dart_execution);

  // If the message is in band we lookup the handler to dispatch to.  If the
  // receive port was closed, we drop the message without deserializing it.
  Object& msg_handler = Object::Handle(I);
  if (!message->IsOOB()) {
    msg_handler = DartLibraryCalls::LookupHandler(message->dest_port());
    if (msg_handler.IsError()) {
      return ProcessUnhandledException(Object::null_instance(),
                                       Error::Cast(msg_handler));
    }
    if (msg_handler.IsNull()) {
      // If the port has been closed then the message will be dropped at this
      // point. Make sure to post to the delivery failure port in that case.
      if (message->RedirectToDeliveryFailurePort()) {
        PortMap::PostMessage(message);
      } else {
        delete message;
      }
      return true;
    }
  }

  // Parse the message.
  SnapshotReader reader(message->data(), message->len(), Snapshot::kMessage, I);
  const Object& msg_obj = Object::Handle(I, reader.ReadObject());
  if (msg_obj.IsError()) {
    // An error occurred while reading the message.
    return ProcessUnhandledException(Object::null_instance(),
                                     Error::Cast(msg_obj));
  }
  if (!msg_obj.IsNull() && !msg_obj.IsInstance()) {
    // TODO(turnidge): We need to decide what an isolate does with
    // malformed messages.  If they (eventually) come from a remote
    // machine, then it might make sense to drop the message entirely.
    // In the case that the message originated locally, which is
    // always true for now, then this should never occur.
    UNREACHABLE();
  }

  Instance& msg = Instance::Handle(I);
  msg ^= msg_obj.raw();  // Can't use Instance::Cast because may be null.

  bool success = true;
  if (message->IsOOB()) {
    ASSERT(msg.IsArray());
    const Object& oob_tag = Object::Handle(I, Array::Cast(msg).At(0));
    ASSERT(oob_tag.IsSmi());
    switch (Smi::Cast(oob_tag).Value()) {
      case Message::kServiceOOBMsg: {
        Service::HandleIsolateMessage(I, msg);
        break;
      }
      default: {
        UNREACHABLE();
        break;
      }
    }
  } else {
    const Object& result = Object::Handle(I,
        DartLibraryCalls::HandleMessage(msg_handler, msg));
    if (result.IsError()) {
      success = ProcessUnhandledException(msg, Error::Cast(result));
    } else {
      ASSERT(result.IsNull());
    }
  }
  delete message;
  return success;
}


RawFunction* IsolateMessageHandler::ResolveCallbackFunction() {
  ASSERT(I->object_store()->unhandled_exception_handler() != NULL);
  String& callback_name = String::Handle(I);
  if (I->object_store()->unhandled_exception_handler() != String::null()) {
    callback_name = I->object_store()->unhandled_exception_handler();
  } else {
    callback_name = String::New("_unhandledExceptionCallback");
  }
  Library& lib = Library::Handle(I, I->object_store()->isolate_library());
  Function& func = Function::Handle(I, lib.LookupLocalFunction(callback_name));
  if (func.IsNull()) {
    lib = I->object_store()->root_library();
    // Note: bootstrap code in builtin library may attempt to resolve a
    // callback function before the script is fully loaded, in which case
    // the root library may not be registered yet.
    if (!lib.IsNull()) {
      func = lib.LookupLocalFunction(callback_name);
    }
  }
  return func.raw();
}


bool IsolateMessageHandler::UnhandledExceptionCallbackHandler(
    const Object& message, const UnhandledException& error) {
  const Instance& cause = Instance::Handle(I, error.exception());
  const Instance& stacktrace = Instance::Handle(I, error.stacktrace());

  // Wrap these args into an IsolateUncaughtException object.
  const Array& exception_args = Array::Handle(I, Array::New(3));
  exception_args.SetAt(0, message);
  exception_args.SetAt(1, cause);
  exception_args.SetAt(2, stacktrace);
  const Object& exception = Object::Handle(I,
      Exceptions::Create(Exceptions::kIsolateUnhandledException,
                         exception_args));
  if (exception.IsError()) {
    return false;
  }
  ASSERT(exception.IsInstance());

  // Invoke script's callback function.
  Object& function = Object::Handle(I, ResolveCallbackFunction());
  if (function.IsNull() || function.IsError()) {
    return false;
  }
  const Array& callback_args = Array::Handle(I, Array::New(1));
  callback_args.SetAt(0, exception);
  const Object& result = Object::Handle(I,
      DartEntry::InvokeFunction(Function::Cast(function), callback_args));
  if (result.IsError()) {
    const Error& err = Error::Cast(result);
    OS::PrintErr("failed calling unhandled exception callback: %s\n",
                 err.ToErrorCString());
    return false;
  }

  ASSERT(result.IsBool());
  bool continue_from_exception = Bool::Cast(result).value();
  if (continue_from_exception) {
    I->object_store()->clear_sticky_error();
  }
  return continue_from_exception;
}

#if defined(DEBUG)
void IsolateMessageHandler::CheckAccess() {
  ASSERT(IsCurrentIsolate());
}
#endif


bool IsolateMessageHandler::IsCurrentIsolate() const {
  return (I == Isolate::Current());
}


bool IsolateMessageHandler::ProcessUnhandledException(
    const Object& message, const Error& result) {
  if (result.IsUnhandledException()) {
    // Invoke the isolate's uncaught exception handler, if it exists.
    const UnhandledException& error = UnhandledException::Cast(result);
    RawInstance* exception = error.exception();
    if ((exception != I->object_store()->out_of_memory()) &&
        (exception != I->object_store()->stack_overflow())) {
      if (UnhandledExceptionCallbackHandler(message, error)) {
        return true;
      }
    }
  }

  // Invoke the isolate's unhandled exception callback if there is one.
  if (Isolate::UnhandledExceptionCallback() != NULL) {
    Dart_EnterScope();
    Dart_Handle error = Api::NewHandle(I, result.raw());
    (Isolate::UnhandledExceptionCallback())(error);
    Dart_ExitScope();
  }

  I->object_store()->set_sticky_error(result);
  return false;
}


#if defined(DEBUG)
// static
void BaseIsolate::AssertCurrent(BaseIsolate* isolate) {
  ASSERT(isolate == Isolate::Current());
}
#endif  // defined(DEBUG)

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object)                                   \
  object##_handle_(NULL),

Isolate::Isolate()
    : store_buffer_(),
      message_notify_callback_(NULL),
      name_(NULL),
      start_time_(OS::GetCurrentTimeMicros()),
      main_port_(0),
      heap_(NULL),
      object_store_(NULL),
      top_context_(Context::null()),
      top_exit_frame_info_(0),
      init_callback_data_(NULL),
      environment_callback_(NULL),
      library_tag_handler_(NULL),
      api_state_(NULL),
      stub_code_(NULL),
      debugger_(NULL),
      single_step_(false),
      resume_request_(false),
      random_(),
      simulator_(NULL),
      long_jump_base_(NULL),
      timer_list_(),
      deopt_id_(0),
      mutex_(new Mutex()),
      stack_limit_(0),
      saved_stack_limit_(0),
      stack_overflow_flags_(0),
      stack_overflow_count_(0),
      message_handler_(NULL),
      spawn_state_(NULL),
      is_runnable_(false),
      gc_prologue_callback_(NULL),
      gc_epilogue_callback_(NULL),
      defer_finalization_count_(0),
      deopt_context_(NULL),
      stacktrace_(NULL),
      stack_frame_index_(-1),
      last_allocationprofile_accumulator_reset_timestamp_(0),
      last_allocationprofile_gc_timestamp_(0),
      cha_used_(false),
      object_id_ring_(NULL),
      trace_buffer_(NULL),
      profiler_data_(NULL),
      thread_state_(NULL),
      tag_table_(GrowableObjectArray::null()),
      current_tag_(UserTag::null()),
      next_(NULL),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
      reusable_handles_() {
  set_vm_tag(VMTag::kIdleTagId);
  set_user_tag(UserTags::kDefaultUserTag);
}
#undef REUSABLE_HANDLE_SCOPE_INIT
#undef REUSABLE_HANDLE_INITIALIZERS


Isolate::~Isolate() {
  delete [] name_;
  delete heap_;
  delete object_store_;
  delete api_state_;
  delete stub_code_;
  delete debugger_;
#if defined(USING_SIMULATOR)
  delete simulator_;
#endif
  delete mutex_;
  mutex_ = NULL;  // Fail fast if interrupts are scheduled on a dead isolate.
  delete message_handler_;
  message_handler_ = NULL;  // Fail fast if we send messages to a dead isolate.
  ASSERT(deopt_context_ == NULL);  // No deopt in progress when isolate deleted.
  delete spawn_state_;
}


void Isolate::SetCurrent(Isolate* current) {
  Isolate* old_current = Current();
  if (old_current != NULL) {
    old_current->set_vm_tag(VMTag::kIdleTagId);
    old_current->set_thread_state(NULL);
    Profiler::EndExecution(old_current);
  }
  Thread::SetThreadLocal(isolate_key, reinterpret_cast<uword>(current));
  if (current != NULL) {
    ASSERT(current->thread_state() == NULL);
    InterruptableThreadState* thread_state =
        ThreadInterrupter::GetCurrentThreadState();
#if defined(DEBUG)
    CheckForDuplicateThreadState(thread_state);
#endif
    ASSERT(thread_state != NULL);
    Profiler::BeginExecution(current);
    current->set_thread_state(thread_state);
    current->set_vm_tag(VMTag::kVMTagId);
  }
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
  isolates_list_monitor_ = new Monitor();
  ASSERT(isolates_list_monitor_ != NULL);
}


Isolate* Isolate::Init(const char* name_prefix) {
  Isolate* result = new Isolate();
  ASSERT(result != NULL);

  // Add to isolate list.
  AddIsolateTolist(result);

  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  SetCurrent(result);

  // Setup the isolate specific resuable handles.
#define REUSABLE_HANDLE_ALLOCATION(object)                                     \
  result->object##_handle_ = result->AllocateReusableHandle<object>();
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ALLOCATION)
#undef REUSABLE_HANDLE_ALLOCATION

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
  ASSERT(Isolate::kStackSizeBuffer < Thread::GetMaxStackSize());
  uword stack_size = Thread::GetMaxStackSize() - Isolate::kStackSizeBuffer;
  return stack_size;
}


void Isolate::SetStackLimitFromCurrentTOS(uword stack_top_value) {
#if defined(USING_SIMULATOR)
  // Ignore passed-in native stack top and use Simulator stack top.
  Simulator* sim = Simulator::Current();  // May allocate a simulator.
  ASSERT(simulator() == sim);  // This isolate's simulator is the current one.
  stack_top_value = sim->StackTop();
  // The overflow area is accounted for by the simulator.
#endif
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


bool Isolate::GetStackBounds(uword* lower, uword* upper) {
  uword stack_lower = stack_limit();
  if (stack_lower == kUwordMax) {
    stack_lower = saved_stack_limit();
  }
  if (stack_lower == kUwordMax) {
    return false;
  }
  uword stack_upper = stack_lower + GetSpecifiedStackSize();
  *lower = stack_lower;
  *upper = stack_upper;
  return true;
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


void Isolate::DoneLoading() {
  GrowableObjectArray& libs =
      GrowableObjectArray::Handle(this, object_store()->libraries());
  Library& lib = Library::Handle(this);
  intptr_t num_libs = libs.Length();
  for (intptr_t i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    // If this library was loaded with Dart_LoadLibrary, it was marked
    // as 'load in progres'. Set the status to 'loaded'.
    if (lib.LoadInProgress()) {
      lib.SetLoaded();
    }
  }
}


bool Isolate::MakeRunnable() {
  ASSERT(Isolate::Current() == NULL);
  // Can't use MutexLocker here because MutexLocker is
  // a StackResource, which requires a current isolate.
  mutex_->Lock();
  // Check if we are in a valid state to make the isolate runnable.
  if (is_runnable_ == true) {
    mutex_->Unlock();
    return false;  // Already runnable.
  }
  // Set the isolate as runnable and if we are being spawned schedule
  // isolate on thread pool for execution.
  is_runnable_ = true;
  if (!Service::IsServiceIsolate(this)) {
    message_handler()->set_pause_on_start(FLAG_pause_isolates_on_start);
    message_handler()->set_pause_on_exit(FLAG_pause_isolates_on_exit);
  }
  IsolateSpawnState* state = spawn_state();
  if (state != NULL) {
    ASSERT(this == state->isolate());
    Run();
  }
  mutex_->Unlock();
  return true;
}


static void StoreError(Isolate* isolate, const Object& obj) {
  ASSERT(obj.IsError());
  isolate->object_store()->set_sticky_error(Error::Cast(obj));
}


static bool RunIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  IsolateSpawnState* state = NULL;
  {
    // TODO(turnidge): Is this locking required here at all anymore?
    MutexLocker ml(isolate->mutex());
    state = isolate->spawn_state();
  }
  {
    StartIsolateScope start_scope(isolate);
    StackZone zone(isolate);
    HandleScope handle_scope(isolate);
    if (!ClassFinalizer::ProcessPendingClasses()) {
      // Error is in sticky error already.
      return false;
    }

    // Set up specific unhandled exception handler.
    const String& callback_name = String::Handle(
        isolate, String::New(state->exception_callback_name()));
    isolate->object_store()->
        set_unhandled_exception_handler(callback_name);

    Object& result = Object::Handle();
    result = state->ResolveFunction();
    bool is_spawn_uri = state->is_spawn_uri();
    if (result.IsError()) {
      StoreError(isolate, result);
      return false;
    }
    ASSERT(result.IsFunction());
    Function& func = Function::Handle(isolate);
    func ^= result.raw();
    func = func.ImplicitClosureFunction();

    // Instead of directly invoking the entry point we call '_startIsolate' with
    // the entry point as argument. The '_startIsolate' function will
    // communicate with the spawner to receive the initial message before it
    // executes the real entry point.
    // Since this function ("RunIsolate") is used for both Isolate.spawn and
    // Isolate.spawnUri we also send a boolean flag as argument so that the
    // "_startIsolate" function can act corresponding to how the isolate was
    // created.
    const Array& args = Array::Handle(Array::New(2));
    args.SetAt(0, Instance::Handle(func.ImplicitStaticClosure()));
    args.SetAt(1, is_spawn_uri ? Bool::True() : Bool::False());

    const Library& lib = Library::Handle(Library::IsolateLibrary());
    const String& entry_name = String::Handle(String::New("_startIsolate"));
    const Function& entry_point =
        Function::Handle(lib.LookupLocalFunction(entry_name));
    ASSERT(entry_point.IsFunction() && !entry_point.IsNull());

    result = DartEntry::InvokeFunction(entry_point, args);
    if (result.IsError()) {
      StoreError(isolate, result);
      return false;
    }
  }
  return true;
}


static void ShutdownIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  {
    // Print the error if there is one.  This may execute dart code to
    // print the exception object, so we need to use a StartIsolateScope.
    StartIsolateScope start_scope(isolate);
    StackZone zone(isolate);
    HandleScope handle_scope(isolate);
    Error& error = Error::Handle();
    error = isolate->object_store()->sticky_error();
    if (!error.IsNull()) {
      OS::PrintErr("in ShutdownIsolate: %s\n", error.ToErrorCString());
    }
    Dart::RunShutdownCallback();
  }
  {
    // Shut the isolate down.
    SwitchIsolateScope switch_scope(isolate);
    Dart::ShutdownIsolate();
  }
}


void Isolate::Run() {
  message_handler()->Run(Dart::thread_pool(),
                         RunIsolate,
                         ShutdownIsolate,
                         reinterpret_cast<uword>(this));
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


uword Isolate::GetAndClearStackOverflowFlags() {
  uword stack_overflow_flags = stack_overflow_flags_;
  stack_overflow_flags_ = 0;
  return stack_overflow_flags;
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
  // Class 'dynamic' is allocated/initialized in a special way, leaving
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
  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(object_store()->libraries());
  Library& library = Library::Handle();
  GrowableArray<const Function*> invoked_functions;
  for (int i = 0; i < libraries.Length(); i++) {
    library ^= libraries.At(i);
    Class& cls = Class::Handle();
    ClassDictionaryIterator iter(library,
                                 ClassDictionaryIterator::kIteratePrivate);
    while (iter.HasNext()) {
      cls = iter.GetNextClass();
      AddFunctionsFromClass(cls, &invoked_functions);
    }
  }
  invoked_functions.Sort(MostUsedFunctionFirst);
  for (int i = 0; i < invoked_functions.length(); i++) {
    OS::Print("%10" Pd " x %s\n",
        invoked_functions[i]->usage_counter(),
        invoked_functions[i]->ToFullyQualifiedCString());
  }
}


class FinalizeWeakPersistentHandlesVisitor : public HandleVisitor {
 public:
  FinalizeWeakPersistentHandlesVisitor() : HandleVisitor(Isolate::Current()) {
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    handle->UpdateUnreachable(isolate());
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(FinalizeWeakPersistentHandlesVisitor);
};


void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  ASSERT(top_resource() == NULL);
  ASSERT((heap_ == NULL) || heap_->Verify());

  // Remove this isolate from the list *before* we start tearing it down, to
  // avoid exposing it in a state of decay.
  RemoveIsolateFromList(this);

  // Create an area where we do have a zone and a handle scope so that we can
  // call VM functions while tearing this isolate down.
  {
    StackZone stack_zone(this);
    HandleScope handle_scope(this);

    // Clean up debugger resources.
    debugger()->Shutdown();

    // Close all the ports owned by this isolate.
    PortMap::ClosePorts(message_handler());

    // Fail fast if anybody tries to post any more messsages to this isolate.
    delete message_handler();
    set_message_handler(NULL);

    // Dump all accumulated timer data for the isolate.
    timer_list_.ReportTimers();

    // Write out profiler data if requested.
    Profiler::WriteProfile(this);

    // Write out the coverage data if collection has been enabled.
    CodeCoverage::Write(this);

    // Finalize any weak persistent handles with a non-null referent.
    FinalizeWeakPersistentHandlesVisitor visitor;
    api_state()->weak_persistent_handles().VisitHandles(&visitor);
    api_state()->prologue_weak_persistent_handles().VisitHandles(&visitor);

    CompilerStats::Print();
    if (FLAG_trace_isolates) {
      heap()->PrintSizes();
      megamorphic_cache_table()->PrintSizes();
      Symbols::DumpStats();
      OS::Print("[-] Stopping isolate:\n"
                "\tisolate:    %s\n", name());
    }
  }

  // TODO(5411455): For now just make sure there are no current isolates
  // as we are shutting down the isolate.
  SetCurrent(NULL);
  Profiler::ShutdownProfilingForIsolate(this);
}


Dart_IsolateCreateCallback Isolate::create_callback_ = NULL;
Dart_IsolateInterruptCallback Isolate::interrupt_callback_ = NULL;
Dart_IsolateUnhandledExceptionCallback
    Isolate::unhandled_exception_callback_ = NULL;
Dart_IsolateShutdownCallback Isolate::shutdown_callback_ = NULL;
Dart_FileOpenCallback Isolate::file_open_callback_ = NULL;
Dart_FileReadCallback Isolate::file_read_callback_ = NULL;
Dart_FileWriteCallback Isolate::file_write_callback_ = NULL;
Dart_FileCloseCallback Isolate::file_close_callback_ = NULL;
Dart_EntropySource Isolate::entropy_source_callback_ = NULL;
Dart_IsolateInterruptCallback Isolate::vmstats_callback_ = NULL;
Dart_ServiceIsolateCreateCalback Isolate::service_create_callback_ = NULL;

Monitor* Isolate::isolates_list_monitor_ = NULL;
Isolate* Isolate::isolates_list_head_ = NULL;


void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  bool visit_prologue_weak_handles,
                                  bool validate_frames) {
  ASSERT(visitor != NULL);

  // Visit objects in the object store.
  object_store()->VisitObjectPointers(visitor);

  // Visit objects in the class table.
  class_table()->VisitObjectPointers(visitor);

  // Visit objects in the megamorphic cache.
  megamorphic_cache_table()->VisitObjectPointers(visitor);

  // Visit objects in per isolate stubs.
  StubCode::VisitObjectPointers(visitor);

  // Visit objects in zones.
  current_zone()->VisitObjectPointers(visitor);

  // Visit objects in isolate specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

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

  // Visit the current tag which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&current_tag_));

  // Visit the tag table which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&tag_table_));

  // Visit objects in the debugger.
  debugger()->VisitObjectPointers(visitor);

  // Visit objects that are being used for deoptimization.
  if (deopt_context() != NULL) {
    deopt_context()->VisitObjectPointers(visitor);
  }
}


void Isolate::VisitWeakPersistentHandles(HandleVisitor* visitor,
                                         bool visit_prologue_weak_handles) {
  if (api_state() != NULL) {
    api_state()->VisitWeakHandles(visitor, visit_prologue_weak_handles);
  }
}


void Isolate::VisitPrologueWeakPersistentHandles(HandleVisitor* visitor) {
  if (api_state() != NULL) {
    api_state()->VisitPrologueWeakHandles(visitor);
  }
}


void Isolate::PrintJSON(JSONStream* stream, bool ref) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", (ref ? "@Isolate" : "Isolate"));
  jsobj.AddPropertyF("id", "isolates/%" Pd "",
                     static_cast<intptr_t>(main_port()));
  jsobj.AddPropertyF("mainPort", "%" Pd "",
                     static_cast<intptr_t>(main_port()));

  // Assign an isolate name based on the entry function.
  IsolateSpawnState* state = spawn_state();
  if (state == NULL) {
    jsobj.AddPropertyF("name", "root");
  } else if (state->class_name() != NULL) {
    jsobj.AddPropertyF("name", "%s.%s",
                       state->class_name(),
                       state->function_name());
  } else {
    jsobj.AddPropertyF("name", "%s", state->function_name());
  }
  if (ref) {
    return;
  }
  if (state != NULL) {
    const Object& entry = Object::Handle(this, state->ResolveFunction());
    if (!entry.IsNull() && entry.IsFunction()) {
      Function& func = Function::Handle(this);
      func ^= entry.raw();
      jsobj.AddProperty("entry", func);
    }
  }
  {
    JSONObject jsheap(&jsobj, "heaps");
    heap()->PrintToJSONObject(Heap::kNew, &jsheap);
    heap()->PrintToJSONObject(Heap::kOld, &jsheap);
  }

  // TODO(turnidge): Don't compute a full stack trace every time we
  // request an isolate's info.
  DebuggerStackTrace* stack = debugger()->StackTrace();
  if (stack->Length() > 0) {
    JSONObject jsframe(&jsobj, "topFrame");

    ActivationFrame* frame = stack->FrameAt(0);
    frame->PrintToJSONObject(&jsobj);
    // TODO(turnidge): Implement depth differently -- differentiate
    // inlined frames.
    jsobj.AddProperty("depth", (intptr_t)0);
  }
  jsobj.AddProperty("livePorts", message_handler()->live_ports());
  jsobj.AddProperty("controlPorts", message_handler()->control_ports());
  jsobj.AddProperty("pauseOnExit", message_handler()->pause_on_exit());

  // TODO(turnidge): Make the debugger support paused_on_start/exit.
  if (message_handler()->paused_on_start()) {
    ASSERT(debugger()->PauseEvent() == NULL);
    DebuggerEvent pauseEvent(this, DebuggerEvent::kIsolateCreated);
    jsobj.AddProperty("pauseEvent", &pauseEvent);
  } else if (message_handler()->paused_on_exit()) {
    ASSERT(debugger()->PauseEvent() == NULL);
    DebuggerEvent pauseEvent(this, DebuggerEvent::kIsolateShutdown);
    jsobj.AddProperty("pauseEvent", &pauseEvent);
  } else if (debugger()->PauseEvent() != NULL) {
    jsobj.AddProperty("pauseEvent", debugger()->PauseEvent());
  }

  const Library& lib =
      Library::Handle(object_store()->root_library());
  jsobj.AddProperty("rootLib", lib);

  timer_list().PrintTimersToJSONProperty(&jsobj);
  {
    JSONObject tagCounters(&jsobj, "tagCounters");
    vm_tag_counters()->PrintToJSONObject(&tagCounters);
  }
  if (object_store()->sticky_error() != Object::null()) {
    Error& error = Error::Handle(this, object_store()->sticky_error());
    ASSERT(!error.IsNull());
    jsobj.AddProperty("error", error, false);
  }

  {
    JSONObject typeargsRef(&jsobj, "canonicalTypeArguments");
    typeargsRef.AddProperty("type", "@TypeArgumentsList");
    typeargsRef.AddProperty("id", "typearguments");
    typeargsRef.AddProperty("name", "canonical type arguments");
  }
  bool is_io_enabled = false;
  {
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(object_store()->libraries());
    intptr_t num_libs = libs.Length();
    Library& lib = Library::Handle();
    String& name = String::Handle();

    JSONArray lib_array(&jsobj, "libraries");
    for (intptr_t i = 0; i < num_libs; i++) {
      lib ^= libs.At(i);
      name = lib.name();
      if (name.Equals(Symbols::DartIOLibName())) {
        is_io_enabled = true;
      }
      ASSERT(!lib.IsNull());
      lib_array.AddValue(lib);
    }
  }
  {
    JSONArray features_array(&jsobj, "features");
    if (is_io_enabled) {
      features_array.AddValue("io");
    }
  }
}


intptr_t Isolate::ProfileInterrupt() {
  // Other threads might be modifying these fields. Save them in locals so that
  // we can at least trust the NULL check.
  IsolateProfilerData* prof_data = profiler_data();
  if (prof_data == NULL) {
    // Profiler not setup for isolate.
    return 0;
  }
  if (prof_data->blocked()) {
    // Profiler blocked for this isolate.
    return 0;
  }
  Debugger* debug = debugger();
  if ((debug != NULL) && debug->IsPaused()) {
    // Paused at breakpoint. Don't tick.
    return 0;
  }
  MessageHandler* msg_handler = message_handler();
  if ((msg_handler != NULL) &&
      (msg_handler->paused_on_start() ||
       msg_handler->paused_on_exit())) {
    // Paused at start / exit . Don't tick.
    return 0;
  }
  InterruptableThreadState* state = thread_state();
  if (state == NULL) {
    // Isolate is not scheduled on a thread.
    ProfileIdle();
    return 1;
  }
  ASSERT(state->id != Thread::kInvalidThreadId);
  ThreadInterrupter::InterruptThread(state);
  return 1;
}


void Isolate::ProfileIdle() {
  vm_tag_counters_.Increment(vm_tag());
}


void Isolate::set_tag_table(const GrowableObjectArray& value) {
  tag_table_ = value.raw();
}


void Isolate::set_current_tag(const UserTag& tag) {
  intptr_t user_tag = tag.tag();
  set_user_tag(static_cast<uword>(user_tag));
  current_tag_ = tag.raw();
}


void Isolate::VisitIsolates(IsolateVisitor* visitor) {
  if (visitor == NULL) {
    return;
  }
  MonitorLocker ml(isolates_list_monitor_);
  Isolate* current = isolates_list_head_;
  while (current) {
    visitor->VisitIsolate(current);
    current = current->next_;
  }
}


void Isolate::AddIsolateTolist(Isolate* isolate) {
  MonitorLocker ml(isolates_list_monitor_);
  ASSERT(isolate != NULL);
  ASSERT(isolate->next_ == NULL);
  isolate->next_ = isolates_list_head_;
  isolates_list_head_ = isolate;
}


void Isolate::RemoveIsolateFromList(Isolate* isolate) {
  MonitorLocker ml(isolates_list_monitor_);
  ASSERT(isolate != NULL);
  if (isolate == isolates_list_head_) {
    isolates_list_head_ = isolate->next_;
    return;
  }
  Isolate* previous = NULL;
  Isolate* current = isolates_list_head_;
  while (current) {
    if (current == isolate) {
      ASSERT(previous != NULL);
      previous->next_ = current->next_;
      return;
    }
    previous = current;
    current = current->next_;
  }
  UNREACHABLE();
}


#if defined(DEBUG)
void Isolate::CheckForDuplicateThreadState(InterruptableThreadState* state) {
  MonitorLocker ml(isolates_list_monitor_);
  ASSERT(state != NULL);
  Isolate* current = isolates_list_head_;
  while (current) {
    ASSERT(current->thread_state() != state);
    current = current->next_;
  }
}
#endif


template<class T>
T* Isolate::AllocateReusableHandle() {
  T* handle = reinterpret_cast<T*>(reusable_handles_.AllocateScopedHandle());
  T::initializeHandle(handle, T::null());
  return handle;
}


IsolateSpawnState::IsolateSpawnState(const Function& func)
    : isolate_(NULL),
      script_url_(NULL),
      library_url_(NULL),
      class_name_(NULL),
      function_name_(NULL),
      exception_callback_name_(NULL) {
  script_url_ = NULL;
  const Class& cls = Class::Handle(func.Owner());
  const Library& lib = Library::Handle(cls.library());
  const String& lib_url = String::Handle(lib.url());
  library_url_ = strdup(lib_url.ToCString());

  const String& func_name = String::Handle(func.name());
  function_name_ = strdup(func_name.ToCString());
  if (!cls.IsTopLevel()) {
    const String& class_name = String::Handle(cls.Name());
    class_name_ = strdup(class_name.ToCString());
  }
  exception_callback_name_ = strdup("_unhandledExceptionCallback");
}


IsolateSpawnState::IsolateSpawnState(const char* script_url)
    : isolate_(NULL),
      library_url_(NULL),
      class_name_(NULL),
      function_name_(NULL),
      exception_callback_name_(NULL) {
  script_url_ = strdup(script_url);
  library_url_ = NULL;
  function_name_ = strdup("main");
  exception_callback_name_ = strdup("_unhandledExceptionCallback");
}


IsolateSpawnState::~IsolateSpawnState() {
  free(script_url_);
  free(library_url_);
  free(function_name_);
  free(class_name_);
  free(exception_callback_name_);
}


RawObject* IsolateSpawnState::ResolveFunction() {
  // Resolve the library.
  Library& lib = Library::Handle();
  if (library_url()) {
    const String& lib_url = String::Handle(String::New(library_url()));
    lib = Library::LookupLibrary(lib_url);
    if (lib.IsNull() || lib.IsError()) {
      const String& msg = String::Handle(String::NewFormatted(
          "Unable to find library '%s'.", library_url()));
      return LanguageError::New(msg);
    }
  } else {
    lib = isolate()->object_store()->root_library();
  }
  ASSERT(!lib.IsNull());

  // Resolve the function.
  const String& func_name = String::Handle(String::New(function_name()));

  if (class_name() == NULL) {
    const Function& func = Function::Handle(lib.LookupLocalFunction(func_name));
    if (func.IsNull()) {
      const String& msg = String::Handle(String::NewFormatted(
          "Unable to resolve function '%s' in library '%s'.",
          function_name(),
          (library_url() != NULL ? library_url() : script_url())));
      return LanguageError::New(msg);
    }
    return func.raw();
  }

  const String& cls_name = String::Handle(String::New(class_name()));
  const Class& cls = Class::Handle(lib.LookupLocalClass(cls_name));
  if (cls.IsNull()) {
    const String& msg = String::Handle(String::NewFormatted(
          "Unable to resolve class '%s' in library '%s'.",
          class_name(),
          (library_url() != NULL ? library_url() : script_url())));
    return LanguageError::New(msg);
  }
  const Function& func =
      Function::Handle(cls.LookupStaticFunctionAllowPrivate(func_name));
  if (func.IsNull()) {
    const String& msg = String::Handle(String::NewFormatted(
          "Unable to resolve static method '%s.%s' in library '%s'.",
          class_name(), function_name(),
          (library_url() != NULL ? library_url() : script_url())));
    return LanguageError::New(msg);
  }
  return func.raw();
}


void IsolateSpawnState::Cleanup() {
  SwitchIsolateScope switch_scope(isolate());
  Dart::ShutdownIsolate();
}

}  // namespace dart
