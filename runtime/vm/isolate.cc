// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/json.h"
#include "vm/code_observers.h"
#include "vm/compiler_stats.h"
#include "vm/coverage.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/heap.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/store_buffer.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/visitor.h"


namespace dart {

DEFINE_FLAG(bool, trace_isolates, false,
            "Trace isolate creation and shut down.");
DEFINE_FLAG(bool, pause_isolates_on_start, false,
            "Pause isolates before starting.");
DEFINE_FLAG(bool, pause_isolates_on_exit, false,
            "Pause isolates exiting.");
DEFINE_FLAG(bool, break_at_isolate_spawn, false,
            "Insert a one-time breakpoint at the entrypoint for all spawned "
            "isolates");
DEFINE_FLAG(charp, isolate_log_filter, NULL,
            "Log isolates whose name include the filter. "
            "Default: service isolate log messages are suppressed.");

DEFINE_FLAG(charp, timeline_trace_dir, NULL,
            "Enable all timeline trace streams and output traces "
            "into specified directory.");

// TODO(iposva): Make these isolate specific flags inaccessible using the
// regular FLAG_xyz pattern.
// These flags are per-isolate and only influence the defaults.
DEFINE_FLAG(bool, enable_asserts, false, "Enable assert statements.");
DEFINE_FLAG(bool, enable_type_checks, false, "Enable type checks.");
DEFINE_FLAG(bool, error_on_bad_override, false,
            "Report error for bad overrides.");
DEFINE_FLAG(bool, error_on_bad_type, false,
            "Report error for malformed types.");

static void CheckedModeHandler(bool value) {
  FLAG_enable_asserts = value;
  FLAG_enable_type_checks = value;
}

// --enable-checked-mode and --checked both enable checked mode which is
// equivalent to setting --enable-asserts and --enable-type-checks.
DEFINE_FLAG_HANDLER(CheckedModeHandler,
                    enable_checked_mode,
                    "Enable checked mode.");

DEFINE_FLAG_HANDLER(CheckedModeHandler,
                    checked,
                    "Enable checked mode.");


// Quick access to the locally defined isolate() method.
#define I (isolate())

#if defined(DEBUG)
// Helper class to ensure that a live origin_id is never reused
// and assigned to an isolate.
class VerifyOriginId : public IsolateVisitor {
 public:
  explicit VerifyOriginId(Dart_Port id) : id_(id) {}

  void VisitIsolate(Isolate* isolate) {
    ASSERT(isolate->origin_id() != id_);
  }

 private:
  Dart_Port id_;
  DISALLOW_COPY_AND_ASSIGN(VerifyOriginId);
};
#endif


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void SerializeObject(const Instance& obj,
                            uint8_t** obj_data,
                            intptr_t* obj_len,
                            bool allow_any_object) {
  MessageWriter writer(obj_data, &allocator, allow_any_object);
  writer.WriteMessage(obj);
  *obj_len = writer.BytesWritten();
}


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
  void NotifyPauseOnStart();
  void NotifyPauseOnExit();

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess();
#endif
  bool IsCurrentIsolate() const;
  virtual Isolate* isolate() const { return isolate_; }

 private:
  // Keep both these enums in sync with isolate_patch.dart.
  // The different Isolate API message types.
  enum {
    kPauseMsg = 1,
    kResumeMsg = 2,
    kPingMsg = 3,
    kKillMsg = 4,
    kAddExitMsg = 5,
    kDelExitMsg = 6,
    kAddErrorMsg = 7,
    kDelErrorMsg = 8,
    kErrorFatalMsg = 9,
  };
  // The different Isolate API message priorities for ping and kill messages.
  enum {
    kImmediateAction = 0,
    kBeforeNextEventAction = 1,
    kAsEventAction = 2
  };

  // A result of false indicates that the isolate should terminate the
  // processing of further events.
  bool HandleLibMessage(const Array& message);

  bool ProcessUnhandledException(const Error& result);
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


// Isolate library OOB messages are fixed sized arrays which have the
// following format:
// [ OOB dispatch, Isolate library dispatch, <message specific data> ]
bool IsolateMessageHandler::HandleLibMessage(const Array& message) {
  if (message.Length() < 2) return true;
  const Object& type = Object::Handle(I, message.At(1));
  if (!type.IsSmi()) return true;
  const intptr_t msg_type = Smi::Cast(type).Value();
  switch (msg_type) {
    case kPauseMsg: {
      // [ OOB, kPauseMsg, pause capability, resume capability ]
      if (message.Length() != 4) return true;
      Object& obj = Object::Handle(I, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return true;
      obj = message.At(3);
      if (!obj.IsCapability()) return true;
      if (I->AddResumeCapability(Capability::Cast(obj))) {
        increment_paused();
      }
      break;
    }
    case kResumeMsg: {
      // [ OOB, kResumeMsg, pause capability, resume capability ]
      if (message.Length() != 4) return true;
      Object& obj = Object::Handle(I, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return true;
      obj = message.At(3);
      if (!obj.IsCapability()) return true;
      if (I->RemoveResumeCapability(Capability::Cast(obj))) {
        decrement_paused();
      }
      break;
    }
    case kPingMsg: {
      // [ OOB, kPingMsg, responsePort, priority, response ]
      if (message.Length() != 5) return true;
      const Object& obj2 = Object::Handle(I, message.At(2));
      if (!obj2.IsSendPort()) return true;
      const SendPort& send_port = SendPort::Cast(obj2);
      const Object& obj3 = Object::Handle(I, message.At(3));
      if (!obj3.IsSmi()) return true;
      const intptr_t priority = Smi::Cast(obj3).Value();
      const Object& obj4 = Object::Handle(I, message.At(4));
      if (!obj4.IsInstance() && !obj4.IsNull()) return true;
      const Instance& response =
          obj4.IsNull() ? Instance::null_instance() : Instance::Cast(obj4);
      if (priority == kImmediateAction) {
        uint8_t* data = NULL;
        intptr_t len = 0;
        SerializeObject(response, &data, &len, false);
        PortMap::PostMessage(new Message(send_port.Id(),
                                         data, len,
                                         Message::kNormalPriority));
      } else {
        ASSERT((priority == kBeforeNextEventAction) ||
               (priority == kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(I, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3, Smi::Handle(I, Smi::New(kImmediateAction)));
        uint8_t* data = NULL;
        intptr_t len = 0;
        SerializeObject(message, &data, &len, false);
        this->PostMessage(new Message(Message::kIllegalPort,
                                      data, len,
                                      Message::kNormalPriority),
                          priority == kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case kKillMsg: {
      // [ OOB, kKillMsg, terminate capability, priority ]
      if (message.Length() != 4) return true;
      Object& obj = Object::Handle(I, message.At(3));
      if (!obj.IsSmi()) return true;
      const intptr_t priority = Smi::Cast(obj).Value();
      if (priority == kImmediateAction) {
        obj = message.At(2);
        // Signal that the isolate should stop execution.
        return !I->VerifyTerminateCapability(obj);
      } else {
        ASSERT((priority == kBeforeNextEventAction) ||
               (priority == kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(I, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3, Smi::Handle(I, Smi::New(kImmediateAction)));
        uint8_t* data = NULL;
        intptr_t len = 0;
        SerializeObject(message, &data, &len, false);
        this->PostMessage(new Message(Message::kIllegalPort,
                                      data, len,
                                      Message::kNormalPriority),
                          priority == kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case kAddExitMsg:
    case kDelExitMsg:
    case kAddErrorMsg:
    case kDelErrorMsg: {
      // [ OOB, msg, listener port ]
      if (message.Length() < 3) return true;
      const Object& obj = Object::Handle(I, message.At(2));
      if (!obj.IsSendPort()) return true;
      const SendPort& listener = SendPort::Cast(obj);
      switch (msg_type) {
        case kAddExitMsg: {
          if (message.Length() != 4) return true;
          // [ OOB, msg, listener port, response object ]
          const Object& response = Object::Handle(I, message.At(3));
          if (!response.IsInstance() && !response.IsNull()) return true;
          I->AddExitListener(listener,
                             response.IsNull() ? Instance::null_instance()
                                               : Instance::Cast(response));
          break;
        }
        case kDelExitMsg:
          if (message.Length() != 3) return true;
          I->RemoveExitListener(listener);
          break;
        case kAddErrorMsg:
          if (message.Length() != 3) return true;
          I->AddErrorListener(listener);
          break;
        case kDelErrorMsg:
          if (message.Length() != 3) return true;
          I->RemoveErrorListener(listener);
          break;
        default:
          UNREACHABLE();
      }
      break;
    }
    case kErrorFatalMsg: {
      // [ OOB, kErrorFatalMsg, terminate capability, val ]
      if (message.Length() != 4) return true;
      // Check that the terminate capability has been passed correctly.
      Object& obj = Object::Handle(I, message.At(2));
      if (!I->VerifyTerminateCapability(obj)) return true;
      // Get the value to be set.
      obj = message.At(3);
      if (!obj.IsBool()) return true;
      I->SetErrorsFatal(Bool::Cast(obj).value());
      break;
    }
#if defined(DEBUG)
    // Malformed OOB messages are silently ignored in release builds.
    default:
      UNREACHABLE();
      break;
#endif  // defined(DEBUG)
  }
  return true;
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
  StackZone zone(I);
  HandleScope handle_scope(I);
  TimelineDurationScope tds(I, I->GetIsolateStream(), "HandleMessage");

  // TODO(turnidge): Rework collection total dart execution.  This can
  // overcount when other things (gc, compilation) are active.
  TIMERSCOPE(isolate_, time_dart_execution);

  // If the message is in band we lookup the handler to dispatch to.  If the
  // receive port was closed, we drop the message without deserializing it.
  // Illegal port is a special case for artificially enqueued isolate library
  // messages which are handled in C++ code below.
  Object& msg_handler = Object::Handle(I);
  if (!message->IsOOB() && (message->dest_port() != Message::kIllegalPort)) {
    msg_handler = DartLibraryCalls::LookupHandler(message->dest_port());
    if (msg_handler.IsError()) {
      delete message;
      return ProcessUnhandledException(Error::Cast(msg_handler));
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
  MessageSnapshotReader reader(message->data(),
                               message->len(),
                               I, zone.GetZone());
  const Object& msg_obj = Object::Handle(I, reader.ReadObject());
  if (msg_obj.IsError()) {
    // An error occurred while reading the message.
    delete message;
    return ProcessUnhandledException(Error::Cast(msg_obj));
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
    // OOB messages are expected to be fixed length arrays where the first
    // element is a Smi describing the OOB destination. Messages that do not
    // confirm to this layout are silently ignored.
    if (msg.IsArray()) {
      const Array& oob_msg = Array::Cast(msg);
      if (oob_msg.Length() > 0) {
        const Object& oob_tag = Object::Handle(I, oob_msg.At(0));
        if (oob_tag.IsSmi()) {
          switch (Smi::Cast(oob_tag).Value()) {
            case Message::kServiceOOBMsg: {
              Service::HandleIsolateMessage(I, oob_msg);
              break;
            }
            case Message::kIsolateLibOOBMsg: {
              success = HandleLibMessage(oob_msg);
              break;
            }
#if defined(DEBUG)
            // Malformed OOB messages are silently ignored in release builds.
            default: {
              UNREACHABLE();
              break;
            }
#endif  // defined(DEBUG)
          }
        }
      }
    }
  } else if (message->dest_port() == Message::kIllegalPort) {
    // Check whether this is a delayed OOB message which needed handling as
    // part of the regular message dispatch. All other messages are dropped on
    // the floor.
    if (msg.IsArray()) {
      const Array& msg_arr = Array::Cast(msg);
      if (msg_arr.Length() > 0) {
        const Object& oob_tag = Object::Handle(I, msg_arr.At(0));
        if (oob_tag.IsSmi() &&
            (Smi::Cast(oob_tag).Value() == Message::kDelayedIsolateLibOOBMsg)) {
          success = HandleLibMessage(Array::Cast(msg_arr));
        }
      }
    }
  } else {
    const Object& result = Object::Handle(I,
        DartLibraryCalls::HandleMessage(msg_handler, msg));
    if (result.IsError()) {
      success = ProcessUnhandledException(Error::Cast(result));
    } else {
      ASSERT(result.IsNull());
    }
  }
  delete message;
  return success;
}


void IsolateMessageHandler::NotifyPauseOnStart() {
  if (Service::debug_stream.enabled()) {
    StartIsolateScope start_isolate(isolate());
    StackZone zone(I);
    HandleScope handle_scope(I);
    ServiceEvent pause_event(isolate(), ServiceEvent::kPauseStart);
    Service::HandleEvent(&pause_event);
  }
}


void IsolateMessageHandler::NotifyPauseOnExit() {
  if (Service::debug_stream.enabled()) {
    StartIsolateScope start_isolate(isolate());
    StackZone zone(I);
    HandleScope handle_scope(I);
    ServiceEvent pause_event(isolate(), ServiceEvent::kPauseExit);
    Service::HandleEvent(&pause_event);
  }
}


#if defined(DEBUG)
void IsolateMessageHandler::CheckAccess() {
  ASSERT(IsCurrentIsolate());
}
#endif


bool IsolateMessageHandler::IsCurrentIsolate() const {
  return (I == Isolate::Current());
}


bool IsolateMessageHandler::ProcessUnhandledException(const Error& result) {
  // Notify the debugger about specific unhandled exceptions which are withheld
  // when being thrown.
  if (result.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(result);
    RawInstance* exception = error.exception();
    if ((exception == I->object_store()->out_of_memory()) ||
        (exception == I->object_store()->stack_overflow())) {
      // We didn't notify the debugger when the stack was full. Do it now.
      I->debugger()->SignalExceptionThrown(Instance::Handle(exception));
    }
  }

  // Invoke the isolate's unhandled exception callback if there is one.
  if (Isolate::UnhandledExceptionCallback() != NULL) {
    Dart_EnterScope();
    Dart_Handle error = Api::NewHandle(I, result.raw());
    (Isolate::UnhandledExceptionCallback())(error);
    Dart_ExitScope();
  }

  // Generate the error and stacktrace strings for the error message.
  String& exc_str = String::Handle(I);
  String& stacktrace_str = String::Handle(I);
  if (result.IsUnhandledException()) {
    const UnhandledException& uhe = UnhandledException::Cast(result);
    const Instance& exception = Instance::Handle(I, uhe.exception());
    Object& tmp = Object::Handle(I);
    tmp = DartLibraryCalls::ToString(exception);
    if (!tmp.IsString()) {
      tmp = String::New(exception.ToCString());
    }
    exc_str ^= tmp.raw();

    const Instance& stacktrace = Instance::Handle(I, uhe.stacktrace());
    tmp = DartLibraryCalls::ToString(stacktrace);
    if (!tmp.IsString()) {
      tmp = String::New(stacktrace.ToCString());
    }
    stacktrace_str ^= tmp.raw();;
  } else {
    exc_str = String::New(result.ToErrorCString());
  }
  I->NotifyErrorListeners(exc_str, stacktrace_str);

  if (I->ErrorsFatal()) {
    I->object_store()->set_sticky_error(result);
    return false;
  }
  return true;
}


Isolate::Flags::Flags()
  : type_checks_(FLAG_enable_type_checks),
    asserts_(FLAG_enable_asserts),
    error_on_bad_type_(FLAG_error_on_bad_type),
    error_on_bad_override_(FLAG_error_on_bad_override) {}


void Isolate::Flags::CopyFrom(const Flags& orig) {
  type_checks_ = orig.type_checks();
  asserts_ = orig.asserts();
  error_on_bad_type_ = orig.error_on_bad_type();
  error_on_bad_override_ = orig.error_on_bad_override();
}


void Isolate::Flags::CopyFrom(const Dart_IsolateFlags& api_flags) {
  type_checks_ = api_flags.enable_type_checks;
  asserts_ = api_flags.enable_asserts;
  // Leave others at defaults.
}


void Isolate::Flags::CopyTo(Dart_IsolateFlags* api_flags) const {
  api_flags->version = DART_FLAGS_CURRENT_VERSION;
  api_flags->enable_type_checks = type_checks();
  api_flags->enable_asserts = asserts();
}


#if defined(DEBUG)
// static
void BaseIsolate::AssertCurrent(BaseIsolate* isolate) {
  ASSERT(isolate == Isolate::Current());
}

void BaseIsolate::AssertCurrentThreadIsMutator() const {
  ASSERT(Isolate::Current() == this);
  ASSERT(Isolate::Current()->mutator_thread() == Thread::Current());
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

Isolate::Isolate(const Dart_IsolateFlags& api_flags)
  :   vm_tag_(0),
      store_buffer_(new StoreBuffer()),
      thread_registry_(new ThreadRegistry()),
      message_notify_callback_(NULL),
      name_(NULL),
      debugger_name_(NULL),
      start_time_(OS::GetCurrentTimeMicros()),
      main_port_(0),
      origin_id_(0),
      pause_capability_(0),
      terminate_capability_(0),
      errors_fatal_(true),
      heap_(NULL),
      object_store_(NULL),
      top_exit_frame_info_(0),
      init_callback_data_(NULL),
      environment_callback_(NULL),
      library_tag_handler_(NULL),
      api_state_(NULL),
      stub_code_(NULL),
      debugger_(NULL),
      single_step_(false),
      resume_request_(false),
      has_compiled_(false),
      flags_(),
      random_(),
      simulator_(NULL),
      long_jump_base_(NULL),
      timer_list_(),
      deopt_id_(0),
      mutex_(new Mutex()),
      stack_limit_(0),
      saved_stack_limit_(0),
      stack_base_(0),
      stack_overflow_flags_(0),
      stack_overflow_count_(0),
      message_handler_(NULL),
      spawn_state_(NULL),
      is_runnable_(false),
      gc_prologue_callback_(NULL),
      gc_epilogue_callback_(NULL),
      defer_finalization_count_(0),
      deopt_context_(NULL),
      edge_counter_increment_size_(-1),
      compiler_stats_(NULL),
      is_service_isolate_(false),
      log_(new class Log()),
      stacktrace_(NULL),
      stack_frame_index_(-1),
      last_allocationprofile_accumulator_reset_timestamp_(0),
      last_allocationprofile_gc_timestamp_(0),
      object_id_ring_(NULL),
      trace_buffer_(NULL),
      timeline_event_recorder_(NULL),
      profiler_data_(NULL),
      thread_state_(NULL),
      tag_table_(GrowableObjectArray::null()),
      current_tag_(UserTag::null()),
      default_tag_(UserTag::null()),
      deoptimized_code_array_(GrowableObjectArray::null()),
      metrics_list_head_(NULL),
      cha_(NULL),
      next_(NULL),
      pause_loop_monitor_(NULL),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
      reusable_handles_() {
  flags_.CopyFrom(api_flags);
  set_vm_tag(VMTag::kEmbedderTagId);
  set_user_tag(UserTags::kDefaultUserTag);
}

#undef REUSABLE_HANDLE_SCOPE_INIT
#undef REUSABLE_HANDLE_INITIALIZERS

Isolate::~Isolate() {
  free(name_);
  free(debugger_name_);
  delete store_buffer_;
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
  delete log_;
  log_ = NULL;
  delete object_id_ring_;
  object_id_ring_ = NULL;
  delete pause_loop_monitor_;
  pause_loop_monitor_ = NULL;
  if (compiler_stats_ != NULL) {
    delete compiler_stats_;
    compiler_stats_ = NULL;
  }
  RemoveTimelineEventRecorder();
  delete thread_registry_;
}


#if defined(DEBUG)
bool Isolate::IsIsolateOf(Thread* thread) {
  return this == thread->isolate();
}
#endif  // DEBUG


void Isolate::InitOnce() {
  create_callback_ = NULL;
  isolates_list_monitor_ = new Monitor();
  ASSERT(isolates_list_monitor_ != NULL);
}


Isolate* Isolate::Init(const char* name_prefix,
                       const Dart_IsolateFlags& api_flags,
                       bool is_vm_isolate) {
  Isolate* result = new Isolate(api_flags);
  ASSERT(result != NULL);

  // Initialize metrics.
#define ISOLATE_METRIC_INIT(type, variable, name, unit)                        \
  result->metric_##variable##_.Init(result, name, NULL, Metric::unit);
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_INIT);
#undef ISOLATE_METRIC_INIT

  const bool force_streams = FLAG_timeline_trace_dir != NULL;

  // Initialize Timeline streams.
#define ISOLATE_TIMELINE_STREAM_INIT(name, enabled_by_default)                 \
  result->stream_##name##_.Init(#name, force_streams || enabled_by_default);
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_INIT);
#undef ISOLATE_TIMELINE_STREAM_INIT


  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  Thread::EnterIsolate(result);

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

  // Initialize stack limit (wait until later for the VM isolate, since the
  // needed GetStackPointer stub has not yet been generated in that case).
  if (!is_vm_isolate) {
    result->InitializeStackLimit();
  }
  result->set_main_port(PortMap::CreatePort(result->message_handler()));
#if defined(DEBUG)
  // Verify that we are never reusing a live origin id.
  VerifyOriginId id_verifier(result->main_port());
  Isolate::VisitIsolates(&id_verifier);
#endif
  result->set_origin_id(result->main_port());
  result->set_pause_capability(result->random()->NextUInt64());
  result->set_terminate_capability(result->random()->NextUInt64());

  result->BuildName(name_prefix);
  result->debugger_ = new Debugger();
  result->debugger_->Initialize(result);
  if (FLAG_trace_isolates) {
    if (name_prefix == NULL || strcmp(name_prefix, "vm-isolate") != 0) {
      OS::Print("[+] Starting isolate:\n"
                "\tisolate:    %s\n", result->name());
    }
  }
  if (FLAG_compiler_stats) {
    result->compiler_stats_ = new CompilerStats(result);
  }
  ObjectIdRing::Init(result);
  // Add to isolate list.
  AddIsolateTolist(result);

  return result;
}


void Isolate::InitializeStackLimit() {
  SetStackLimitFromStackBase(Isolate::GetCurrentStackPointer());
}


/* static */
uword Isolate::GetCurrentStackPointer() {
  // Since AddressSanitizer's detect_stack_use_after_return instruments the
  // C++ code to give out fake stack addresses, we call a stub in that case.
  uword (*func)() =
      reinterpret_cast<uword (*)()>(StubCode::GetStackPointerEntryPoint());
  // But for performance (and to support simulators), we normally use a local.
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
  uword current_sp = func();
  return current_sp;
#else
  uword stack_allocated_local_address = reinterpret_cast<uword>(&func);
  return stack_allocated_local_address;
#endif
#else
  uword stack_allocated_local_address = reinterpret_cast<uword>(&func);
  return stack_allocated_local_address;
#endif
}


void Isolate::set_debugger_name(const char* name) {
  free(debugger_name_);
  debugger_name_ = strdup(name);
}


void Isolate::BuildName(const char* name_prefix) {
  ASSERT(name_ == NULL);
  if (name_prefix == NULL) {
    name_prefix = "isolate";
  }
  set_debugger_name(name_prefix);
  if (ServiceIsolate::NameEquals(name_prefix)) {
    name_ = strdup(name_prefix);
    return;
  }
  const char* kFormat = "%s-%lld";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, name_prefix, main_port()) + 1;
  name_ = reinterpret_cast<char*>(malloc(len));
  OS::SNPrint(name_, len, kFormat, name_prefix, main_port());
}


Log* Isolate::Log() const {
  if (FLAG_isolate_log_filter == NULL) {
    if (is_service_isolate_) {
      // By default, do not log for the service isolate.
      return Log::NoOpLog();
    }
    return log_;
  }
  ASSERT(name_ != NULL);
  if (strstr(name_, FLAG_isolate_log_filter) == NULL) {
    // Filter does not match, do not log for this isolate.
    return Log::NoOpLog();
  }
  return log_;
}


// TODO(5411455): Use flag to override default value and Validate the
// stack size by querying OS.
uword Isolate::GetSpecifiedStackSize() {
  ASSERT(Isolate::kStackSizeBuffer < OSThread::GetMaxStackSize());
  uword stack_size = OSThread::GetMaxStackSize() - Isolate::kStackSizeBuffer;
  return stack_size;
}


void Isolate::SetStackLimitFromStackBase(uword stack_base) {
  // Set stack base.
  stack_base_ = stack_base;

  // Set stack limit.
#if defined(USING_SIMULATOR)
  // Ignore passed-in native stack top and use Simulator stack top.
  Simulator* sim = Simulator::Current();  // May allocate a simulator.
  ASSERT(simulator() == sim);  // This isolate's simulator is the current one.
  stack_base = sim->StackTop();
  // The overflow area is accounted for by the simulator.
#endif
  SetStackLimit(stack_base - GetSpecifiedStackSize());
}


void Isolate::SetStackLimit(uword limit) {
  // The isolate setting the stack limit is not necessarily the isolate which
  // the stack limit is being set on.
  MutexLocker ml(mutex_);
  if (stack_limit_ == saved_stack_limit_) {
    // No interrupt pending, set stack_limit_ too.
    stack_limit_ = limit;
  }
  saved_stack_limit_ = limit;
}


void Isolate::ClearStackLimit() {
  SetStackLimit(~static_cast<uword>(0));
  stack_base_ = 0;
}


bool Isolate::GetProfilerStackBounds(uword* lower, uword* upper) const {
  uword stack_upper = stack_base_;
  if (stack_upper == 0) {
    return false;
  }
  uword stack_lower = stack_upper - GetSpecifiedStackSize();
  *lower = stack_lower;
  *upper = stack_upper;
  return true;
}


void Isolate::ScheduleInterrupts(uword interrupt_bits) {
  MutexLocker ml(mutex_);
  ASSERT((interrupt_bits & ~kInterruptsMask) == 0);  // Must fit in mask.
  if (stack_limit_ == saved_stack_limit_) {
    stack_limit_ = (~static_cast<uword>(0)) & ~kInterruptsMask;
  }
  stack_limit_ |= interrupt_bits;
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

  MutexLocker ml(mutex_);
  // Check if we are in a valid state to make the isolate runnable.
  if (is_runnable() == true) {
    return false;  // Already runnable.
  }
  // Set the isolate as runnable and if we are being spawned schedule
  // isolate on thread pool for execution.
  ASSERT(object_store()->root_library() != Library::null());
  set_is_runnable(true);
  if (!ServiceIsolate::IsServiceIsolate(this)) {
    message_handler()->set_pause_on_start(FLAG_pause_isolates_on_start);
    message_handler()->set_pause_on_exit(FLAG_pause_isolates_on_exit);
  }
  IsolateSpawnState* state = spawn_state();
  if (state != NULL) {
    ASSERT(this == state->isolate());
    Run();
  }
  TimelineStream* stream = GetIsolateStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->Instant("Runnable");
    event->Complete();
  }
  return true;
}


bool Isolate::VerifyPauseCapability(const Object& capability) const {
  return !capability.IsNull() &&
      capability.IsCapability() &&
      (pause_capability() == Capability::Cast(capability).Id());
}


bool Isolate::VerifyTerminateCapability(const Object& capability) const {
  return !capability.IsNull() &&
      capability.IsCapability() &&
      (terminate_capability() == Capability::Cast(capability).Id());
}


bool Isolate::AddResumeCapability(const Capability& capability) {
  // Ensure a limit for the number of resume capabilities remembered.
  static const intptr_t kMaxResumeCapabilities = kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& caps = GrowableObjectArray::Handle(
      this, object_store()->resume_capabilities());
  Capability& current = Capability::Handle(this);
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < caps.Length(); i++) {
    current ^= caps.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == capability.Id()) {
      return false;
    }
  }
  if (insertion_index < 0) {
    if (caps.Length() >= kMaxResumeCapabilities) {
      // Cannot grow the array of resume capabilities beyond its max. Additional
      // pause requests are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return false;
    }
    caps.Add(capability);
  } else {
    caps.SetAt(insertion_index, capability);
  }
  return true;
}


bool Isolate::RemoveResumeCapability(const Capability& capability) {
  const GrowableObjectArray& caps = GrowableObjectArray::Handle(
       this, object_store()->resume_capabilities());
  Capability& current = Capability::Handle(this);
  for (intptr_t i = 0; i < caps.Length(); i++) {
    current ^= caps.At(i);
    if (!current.IsNull() && (current.Id() == capability.Id())) {
      // Remove the matching capability from the list.
      current = Capability::null();
      caps.SetAt(i, current);
      return true;
    }
  }
  return false;
}


// TODO(iposva): Remove duplicated code and start using some hash based
// structure instead of these linear lookups.
void Isolate::AddExitListener(const SendPort& listener,
                              const Instance& response) {
  // Ensure a limit for the number of listeners remembered.
  static const intptr_t kMaxListeners = kSmiMax / (12 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
       this, object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(this);
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    current ^= listeners.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == listener.Id()) {
      listeners.SetAt(i + 1, response);
      return;
    }
  }
  if (insertion_index < 0) {
    if (listeners.Length() >= kMaxListeners) {
      // Cannot grow the array of listeners beyond its max. Additional
      // listeners are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return;
    }
    listeners.Add(listener);
    listeners.Add(response);
  } else {
    listeners.SetAt(insertion_index, listener);
    listeners.SetAt(insertion_index + 1, response);
  }
}


void Isolate::RemoveExitListener(const SendPort& listener) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      this, object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(this);
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    current ^= listeners.At(i);
    if (!current.IsNull() && (current.Id() == listener.Id())) {
      // Remove the matching listener from the list.
      current = SendPort::null();
      listeners.SetAt(i, current);
      listeners.SetAt(i + 1, Object::null_instance());
      return;
    }
  }
}


void Isolate::NotifyExitListeners() {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      this, this->object_store()->exit_listeners());
  if (listeners.IsNull()) return;

  SendPort& listener = SendPort::Handle(this);
  Instance& response = Instance::Handle(this);
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      uint8_t* data = NULL;
      intptr_t len = 0;
      response ^= listeners.At(i + 1);
      SerializeObject(response, &data, &len, false);
      Message* msg = new Message(port_id, data, len, Message::kNormalPriority);
      PortMap::PostMessage(msg);
    }
  }
}


void Isolate::AddErrorListener(const SendPort& listener) {
  // Ensure a limit for the number of listeners remembered.
  static const intptr_t kMaxListeners = kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      this, object_store()->error_listeners());
  SendPort& current = SendPort::Handle(this);
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    current ^= listeners.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == listener.Id()) {
      return;
    }
  }
  if (insertion_index < 0) {
    if (listeners.Length() >= kMaxListeners) {
      // Cannot grow the array of listeners beyond its max. Additional
      // listeners are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return;
    }
    listeners.Add(listener);
  } else {
    listeners.SetAt(insertion_index, listener);
  }
}


void Isolate::RemoveErrorListener(const SendPort& listener) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      this, object_store()->error_listeners());
  SendPort& current = SendPort::Handle(this);
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    current ^= listeners.At(i);
    if (!current.IsNull() && (current.Id() == listener.Id())) {
      // Remove the matching listener from the list.
      current = SendPort::null();
      listeners.SetAt(i, current);
      return;
    }
  }
}


void Isolate::NotifyErrorListeners(const String& msg,
                                   const String& stacktrace) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      this, this->object_store()->error_listeners());
  if (listeners.IsNull()) return;

  const Array& arr = Array::Handle(this, Array::New(2));
  arr.SetAt(0, msg);
  arr.SetAt(1, stacktrace);
  SendPort& listener = SendPort::Handle(this);
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      uint8_t* data = NULL;
      intptr_t len = 0;
      SerializeObject(arr, &data, &len, false);
      Message* msg = new Message(port_id, data, len, Message::kNormalPriority);
      PortMap::PostMessage(msg);
    }
  }
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

    // TODO(turnidge): Currently we need a way to force a one-time
    // breakpoint for all spawned isolates to support isolate
    // debugging.  Remove this once the vmservice becomes the standard
    // way to debug. Set the breakpoint on the static function instead
    // of its implicit closure function because that latter is merely
    // a dispatcher that is marked as undebuggable.
    if (FLAG_break_at_isolate_spawn) {
      isolate->debugger()->OneTimeBreakAtEntry(func);
    }

    func = func.ImplicitClosureFunction();

    const Array& capabilities = Array::Handle(Array::New(2));
    Capability& capability = Capability::Handle();
    capability = Capability::New(isolate->pause_capability());
    capabilities.SetAt(0, capability);
    // Check whether this isolate should be started in paused state.
    if (state->paused()) {
      bool added = isolate->AddResumeCapability(capability);
      ASSERT(added);  // There should be no pending resume capabilities.
      isolate->message_handler()->increment_paused();
    }
    capability = Capability::New(isolate->terminate_capability());
    capabilities.SetAt(1, capability);

    // Instead of directly invoking the entry point we call '_startIsolate' with
    // the entry point as argument.
    // Since this function ("RunIsolate") is used for both Isolate.spawn and
    // Isolate.spawnUri we also send a boolean flag as argument so that the
    // "_startIsolate" function can act corresponding to how the isolate was
    // created.
    const Array& args = Array::Handle(Array::New(7));
    args.SetAt(0, SendPort::Handle(SendPort::New(state->parent_port())));
    args.SetAt(1, Instance::Handle(func.ImplicitStaticClosure()));
    args.SetAt(2, Instance::Handle(state->BuildArgs(zone.GetZone())));
    args.SetAt(3, Instance::Handle(state->BuildMessage(zone.GetZone())));
    args.SetAt(4, is_spawn_uri ? Bool::True() : Bool::False());
    args.SetAt(5, ReceivePort::Handle(
        ReceivePort::New(isolate->main_port(), true /* control port */)));
    args.SetAt(6, capabilities);

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
    if (!error.IsNull() && !error.IsUnwindError()) {
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
    handle->UpdateUnreachable(I);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(FinalizeWeakPersistentHandlesVisitor);
};


void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  ASSERT(top_resource() == NULL);
#if defined(DEBUG)
  if (heap_ != NULL) {
    // The VM isolate keeps all objects marked.
    heap_->Verify(this == Dart::vm_isolate() ? kRequireMarked : kForbidMarked);
  }
#endif  // DEBUG

  // First, perform higher-level cleanup that may need to allocate.
  {
    // Ensure we have a zone and handle scope so that we can call VM functions.
    StackZone stack_zone(this);
    HandleScope handle_scope(this);

    // Write out the coverage data if collection has been enabled.
    CodeCoverage::Write(this);

    if ((timeline_event_recorder_ != NULL) &&
        (FLAG_timeline_trace_dir != NULL)) {
      timeline_event_recorder_->WriteTo(FLAG_timeline_trace_dir);
    }
  }

  // Remove this isolate from the list *before* we start tearing it down, to
  // avoid exposing it in a state of decay.
  RemoveIsolateFromList(this);

  if (heap_ != NULL) {
    // Wait for any concurrent GC tasks to finish before shutting down.
    // TODO(koda): Support faster sweeper shutdown (e.g., after current page).
    PageSpace* old_space = heap_->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    while (old_space->tasks() > 0) {
      ml.Wait();
    }
  }

  // Then, proceed with low-level teardown.
  {
    // Ensure we have a zone and handle scope so that we can call VM functions,
    // but we no longer allocate new heap objects.
    StackZone stack_zone(this);
    HandleScope handle_scope(this);
    NoSafepointScope no_safepoint_scope;

    if (compiler_stats_ != NULL) {
      compiler_stats()->Print();
    }

    // Notify exit listeners that this isolate is shutting down.
    if (object_store() != NULL) {
      NotifyExitListeners();
    }

    // Clean up debugger resources.
    debugger()->Shutdown();

    // Close all the ports owned by this isolate.
    PortMap::ClosePorts(message_handler());

    // Fail fast if anybody tries to post any more messsages to this isolate.
    delete message_handler();
    set_message_handler(NULL);

    // Dump all accumulated timer data for the isolate.
    timer_list_.ReportTimers();

    // Finalize any weak persistent handles with a non-null referent.
    FinalizeWeakPersistentHandlesVisitor visitor;
    api_state()->weak_persistent_handles().VisitHandles(&visitor);
    api_state()->prologue_weak_persistent_handles().VisitHandles(&visitor);

    if (FLAG_trace_isolates) {
      heap()->PrintSizes();
      megamorphic_cache_table()->PrintSizes();
      Symbols::DumpStats();
      OS::Print("[-] Stopping isolate:\n"
                "\tisolate:    %s\n", name());
    }
  }

#if defined(DEBUG)
  // No concurrent sweeper tasks should be running at this point.
  if (heap_ != NULL) {
    PageSpace* old_space = heap_->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    ASSERT(old_space->tasks() == 0);
  }
#endif

  // TODO(5411455): For now just make sure there are no current isolates
  // as we are shutting down the isolate.
  Thread::ExitIsolate();
  // All threads should have exited by now.
  thread_registry()->CheckNotScheduled(this);
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

Monitor* Isolate::isolates_list_monitor_ = NULL;
Isolate* Isolate::isolates_list_head_ = NULL;


void Isolate::IterateObjectPointers(ObjectPointerVisitor* visitor,
                                    bool visit_prologue_weak_handles,
                                    bool validate_frames) {
  HeapIterationScope heap_iteration_scope;
  VisitObjectPointers(visitor, visit_prologue_weak_handles, validate_frames);
}


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

  // Visit the current tag which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&current_tag_));

  // Visit the default tag which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&default_tag_));

  // Visit the tag table which is stored in the isolate.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&tag_table_));

  // Visit the deoptimized code array which is stored in the isolate.
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&deoptimized_code_array_));

  // Visit objects in the debugger.
  debugger()->VisitObjectPointers(visitor);

  // Visit objects that are being used for deoptimization.
  if (deopt_context() != NULL) {
    deopt_context()->VisitObjectPointers(visitor);
  }

  // Visit objects in thread registry (e.g., handles in zones).
  thread_registry()->VisitObjectPointers(visitor);
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


void Isolate::SetTimelineEventRecorder(
    TimelineEventRecorder* timeline_event_recorder) {
#define ISOLATE_TIMELINE_STREAM_SET_BUFFER(name, enabled_by_default)           \
  stream_##name##_.set_recorder(timeline_event_recorder);
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_SET_BUFFER)
#undef ISOLATE_TIMELINE_STREAM_SET_BUFFER
  timeline_event_recorder_ = timeline_event_recorder;
}

void Isolate::RemoveTimelineEventRecorder() {
  SetTimelineEventRecorder(NULL);
  delete timeline_event_recorder_;
}


void Isolate::PrintJSON(JSONStream* stream, bool ref) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", (ref ? "@Isolate" : "Isolate"));
  jsobj.AddFixedServiceId("isolates/%" Pd "",
                          static_cast<intptr_t>(main_port()));

  jsobj.AddProperty("name", debugger_name());
  jsobj.AddPropertyF("number", "%" Pd "",
                     static_cast<intptr_t>(main_port()));
  if (ref) {
    return;
  }
  int64_t start_time_millis = start_time() / kMicrosecondsPerMillisecond;
  jsobj.AddProperty64("startTime", start_time_millis);
  IsolateSpawnState* state = spawn_state();
  if (state != NULL) {
    const Object& entry = Object::Handle(this, state->ResolveFunction());
    if (!entry.IsNull() && entry.IsFunction()) {
      Function& func = Function::Handle(this);
      func ^= entry.raw();
      jsobj.AddProperty("entry", func);
    }
  }
  {
    JSONObject jsheap(&jsobj, "_heaps");
    heap()->PrintToJSONObject(Heap::kNew, &jsheap);
    heap()->PrintToJSONObject(Heap::kOld, &jsheap);
  }

  jsobj.AddProperty("livePorts", message_handler()->live_ports());
  jsobj.AddProperty("pauseOnExit", message_handler()->pause_on_exit());

  if (message_handler()->paused_on_start()) {
    ASSERT(debugger()->PauseEvent() == NULL);
    ServiceEvent pause_event(this, ServiceEvent::kPauseStart);
    jsobj.AddProperty("pauseEvent", &pause_event);
  } else if (message_handler()->paused_on_exit()) {
    ASSERT(debugger()->PauseEvent() == NULL);
    ServiceEvent pause_event(this, ServiceEvent::kPauseExit);
    jsobj.AddProperty("pauseEvent", &pause_event);
  } else if (debugger()->PauseEvent() != NULL) {
    ServiceEvent pause_event(debugger()->PauseEvent());
    jsobj.AddProperty("pauseEvent", &pause_event);
  } else {
    ServiceEvent pause_event(this, ServiceEvent::kResume);

    // TODO(turnidge): Don't compute a full stack trace.
    DebuggerStackTrace* stack = debugger()->StackTrace();
    if (stack->Length() > 0) {
      pause_event.set_top_frame(stack->FrameAt(0));
    }
    jsobj.AddProperty("pauseEvent", &pause_event);
  }

  const Library& lib =
      Library::Handle(object_store()->root_library());
  jsobj.AddProperty("rootLib", lib);

  timer_list().PrintTimersToJSONProperty(&jsobj);
  {
    JSONObject tagCounters(&jsobj, "_tagCounters");
    vm_tag_counters()->PrintToJSONObject(&tagCounters);
  }
  if (object_store()->sticky_error() != Object::null()) {
    Error& error = Error::Handle(this, object_store()->sticky_error());
    ASSERT(!error.IsNull());
    jsobj.AddProperty("error", error, false);
  }

  {
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(object_store()->libraries());
    intptr_t num_libs = libs.Length();
    Library& lib = Library::Handle();

    JSONArray lib_array(&jsobj, "libraries");
    for (intptr_t i = 0; i < num_libs; i++) {
      lib ^= libs.At(i);
      ASSERT(!lib.IsNull());
      lib_array.AddValue(lib);
    }
  }
  {
    JSONArray breakpoints(&jsobj, "breakpoints");
    debugger()->PrintBreakpointsToJSONArray(&breakpoints);
  }

  {
    JSONObject jssettings(&jsobj, "_debuggerSettings");
    debugger()->PrintSettingsToJSONObject(&jssettings);
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
  ASSERT(state->id != OSThread::kInvalidThreadId);
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
  uword user_tag = tag.tag();
  ASSERT(user_tag < kUwordMax);
  set_user_tag(user_tag);
  current_tag_ = tag.raw();
}


void Isolate::set_default_tag(const UserTag& tag) {
  default_tag_ = tag.raw();
}


void Isolate::set_deoptimized_code_array(const GrowableObjectArray& value) {
  deoptimized_code_array_ = value.raw();
}


void Isolate::TrackDeoptimizedCode(const Code& code) {
  ASSERT(!code.IsNull());
  const GrowableObjectArray& deoptimized_code =
      GrowableObjectArray::Handle(deoptimized_code_array());
  if (deoptimized_code.IsNull()) {
    // Not tracking deoptimized code.
    return;
  }
  // TODO(johnmccutchan): Scan this array and the isolate's profile before
  // old space GC and remove the keep_code flag.
  deoptimized_code.Add(code);
}


void Isolate::WakePauseEventHandler(Dart_Isolate isolate) {
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  MonitorLocker ml(iso->pause_loop_monitor_);
  ml.Notify();
}


void Isolate::PauseEventHandler() {
  // We are stealing a pause event (like a breakpoint) from the
  // embedder.  We don't know what kind of thread we are on -- it
  // could be from our thread pool or it could be a thread from the
  // embedder.  Sit on the current thread handling service events
  // until we are told to resume.
  if (pause_loop_monitor_ == NULL) {
    pause_loop_monitor_ = new Monitor();
  }
  Dart_EnterScope();
  MonitorLocker ml(pause_loop_monitor_);

  Dart_MessageNotifyCallback saved_notify_callback =
      message_notify_callback();
  set_message_notify_callback(Isolate::WakePauseEventHandler);

  bool resume = false;
  while (true) {
    // Handle all available vm service messages, up to a resume
    // request.
    while (!resume && Dart_HasServiceMessages()) {
      pause_loop_monitor_->Exit();
      resume = Dart_HandleServiceMessages();
      pause_loop_monitor_->Enter();
    }
    if (resume) {
      break;
    }

    // Wait for more service messages.
    Monitor::WaitResult res = ml.Wait();
    ASSERT(res == Monitor::kNotified);
  }
  set_message_notify_callback(saved_notify_callback);
  Dart_ExitScope();
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


intptr_t Isolate::IsolateListLength() {
  MonitorLocker ml(isolates_list_monitor_);
  intptr_t count = 0;
  Isolate* current = isolates_list_head_;
  while (current != NULL) {
    count++;
    current = current->next_;
  }
  return count;
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


static RawInstance* DeserializeObject(Isolate* isolate,
                                      Zone* zone,
                                      uint8_t* obj_data,
                                      intptr_t obj_len) {
  if (obj_data == NULL) {
    return Instance::null();
  }
  MessageSnapshotReader reader(obj_data,
                               obj_len,
                               isolate,
                               zone);
  const Object& obj = Object::Handle(isolate, reader.ReadObject());
  ASSERT(!obj.IsError());
  Instance& instance = Instance::Handle(isolate);
  instance ^= obj.raw();  // Can't use Instance::Cast because may be null.
  return instance.raw();
}


IsolateSpawnState::IsolateSpawnState(Dart_Port parent_port,
                                     const Function& func,
                                     const Instance& message,
                                     bool paused)
    : isolate_(NULL),
      parent_port_(parent_port),
      script_url_(NULL),
      package_root_(NULL),
      library_url_(NULL),
      class_name_(NULL),
      function_name_(NULL),
      serialized_args_(NULL),
      serialized_args_len_(0),
      serialized_message_(NULL),
      serialized_message_len_(0),
      isolate_flags_(),
      paused_(paused) {
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
  bool can_send_any_object = true;
  SerializeObject(message,
                  &serialized_message_,
                  &serialized_message_len_,
                  can_send_any_object);
  // Inherit flags from spawning isolate.
  isolate_flags()->CopyFrom(Isolate::Current()->flags());
}


IsolateSpawnState::IsolateSpawnState(Dart_Port parent_port,
                                     const char* script_url,
                                     const char* package_root,
                                     const Instance& args,
                                     const Instance& message,
                                     bool paused)
    : isolate_(NULL),
      parent_port_(parent_port),
      package_root_(NULL),
      library_url_(NULL),
      class_name_(NULL),
      function_name_(NULL),
      serialized_args_(NULL),
      serialized_args_len_(0),
      serialized_message_(NULL),
      serialized_message_len_(0),
      isolate_flags_(),
      paused_(paused) {
  script_url_ = strdup(script_url);
  if (package_root != NULL) {
    package_root_ = strdup(package_root);
  }
  library_url_ = NULL;
  function_name_ = strdup("main");
  bool can_send_any_object = false;
  SerializeObject(args,
                  &serialized_args_,
                  &serialized_args_len_,
                  can_send_any_object);
  SerializeObject(message,
                  &serialized_message_,
                  &serialized_message_len_,
                  can_send_any_object);
  // By default inherit flags from spawning isolate. These can be overridden
  // from the calling code.
  isolate_flags()->CopyFrom(Isolate::Current()->flags());
}


IsolateSpawnState::~IsolateSpawnState() {
  free(script_url_);
  free(package_root_);
  free(library_url_);
  free(function_name_);
  free(class_name_);
  free(serialized_args_);
  free(serialized_message_);
}


RawObject* IsolateSpawnState::ResolveFunction() {
  const String& func_name = String::Handle(String::New(function_name()));

  if (library_url() == NULL) {
    // Handle spawnUri lookup rules.
    // Check whether the root library defines a main function.
    const Library& lib = Library::Handle(I->object_store()->root_library());
    Function& func = Function::Handle(lib.LookupLocalFunction(func_name));
    if (func.IsNull()) {
      // Check whether main is reexported from the root library.
      const Object& obj = Object::Handle(lib.LookupReExport(func_name));
      if (obj.IsFunction()) {
        func ^= obj.raw();
      }
    }
    if (func.IsNull()) {
      const String& msg = String::Handle(String::NewFormatted(
          "Unable to resolve function '%s' in script '%s'.",
          function_name(), script_url()));
      return LanguageError::New(msg);
    }
    return func.raw();
  }

  ASSERT(script_url() == NULL);
  // Resolve the library.
  const String& lib_url = String::Handle(String::New(library_url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(lib_url));
  if (lib.IsNull() || lib.IsError()) {
    const String& msg = String::Handle(String::NewFormatted(
        "Unable to find library '%s'.", library_url()));
    return LanguageError::New(msg);
  }

  // Resolve the function.
  if (class_name() == NULL) {
    const Function& func = Function::Handle(lib.LookupLocalFunction(func_name));
    if (func.IsNull()) {
      const String& msg = String::Handle(String::NewFormatted(
          "Unable to resolve function '%s' in library '%s'.",
          function_name(), library_url()));
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


RawInstance* IsolateSpawnState::BuildArgs(Zone* zone) {
  return DeserializeObject(isolate_, zone,
                           serialized_args_, serialized_args_len_);
}


RawInstance* IsolateSpawnState::BuildMessage(Zone* zone) {
  return DeserializeObject(isolate_, zone,
                           serialized_message_, serialized_message_len_);
}


void IsolateSpawnState::Cleanup() {
  SwitchIsolateScope switch_scope(I);
  Dart::ShutdownIsolate();
}

}  // namespace dart
