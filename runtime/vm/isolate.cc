// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/text_buffer.h"
#include "vm/class_finalizer.h"
#include "vm/code_observers.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/flags.h"
#include "vm/heap/heap.h"
#include "vm/heap/pointer_block.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/verifier.h"
#include "vm/image_snapshot.h"
#include "vm/interpreter.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/reverse_pc_lookup_cache.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timeline_analysis.h"
#include "vm/visitor.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/stub_code_compiler.h"
#endif

namespace dart {

DECLARE_FLAG(bool, print_metrics);
DECLARE_FLAG(bool, timing);
DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, warn_on_pause_with_no_debugger);

// TODO(bkonyi): remove this flag around Nov 2019 after UX studies are
// complete. See issue 38535.
DEFINE_FLAG(int,
            object_id_ring_size,
            ObjectIdRing::kDefaultCapacity,
            "(EXPERIMENTAL) Manually set the size of the service protocol's "
            "object ID ring buffer. Set to be removed by Nov 2019.");

// Reload flags.
DECLARE_FLAG(int, reload_every);
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
DECLARE_FLAG(bool, check_reloaded);
DECLARE_FLAG(bool, reload_every_back_off);
DECLARE_FLAG(bool, trace_reload);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

static void DeterministicModeHandler(bool value) {
  if (value) {
    FLAG_background_compilation = false;  // Timing dependent.
    FLAG_concurrent_mark = false;         // Timing dependent.
    FLAG_concurrent_sweep = false;        // Timing dependent.
    FLAG_random_seed = 0x44617274;        // "Dart"
  }
}

DEFINE_FLAG_HANDLER(DeterministicModeHandler,
                    deterministic,
                    "Enable deterministic mode.");

// Quick access to the locally defined thread() and isolate() methods.
#define T (thread())
#define I (isolate())

#if defined(DEBUG)
// Helper class to ensure that a live origin_id is never reused
// and assigned to an isolate.
class VerifyOriginId : public IsolateVisitor {
 public:
  explicit VerifyOriginId(Dart_Port id) : id_(id) {}

  void VisitIsolate(Isolate* isolate) { ASSERT(isolate->origin_id() != id_); }

 private:
  Dart_Port id_;
  DISALLOW_COPY_AND_ASSIGN(VerifyOriginId);
};
#endif

static std::unique_ptr<Message> SerializeMessage(Dart_Port dest_port,
                                                 const Instance& obj) {
  if (ApiObjectConverter::CanConvert(obj.raw())) {
    return Message::New(dest_port, obj.raw(), Message::kNormalPriority);
  } else {
    MessageWriter writer(false);
    return writer.WriteMessage(obj, dest_port, Message::kNormalPriority);
  }
}

static RawInstance* DeserializeMessage(Thread* thread, Message* message) {
  if (message == NULL) {
    return Instance::null();
  }
  Zone* zone = thread->zone();
  if (message->IsRaw()) {
    return Instance::RawCast(message->raw_obj());
  } else {
    MessageSnapshotReader reader(message, thread);
    const Object& obj = Object::Handle(zone, reader.ReadObject());
    ASSERT(!obj.IsError());
    return Instance::RawCast(obj.raw());
  }
}

IsolateGroup::IsolateGroup(std::unique_ptr<IsolateGroupSource> source,
                           void* embedder_data)
    : embedder_data_(embedder_data),
      isolates_rwlock_(new RwLock()),
      isolates_(),
      source_(std::move(source)),
      thread_registry_(new ThreadRegistry()),
      safepoint_handler_(new SafepointHandler(this)) {}

IsolateGroup::~IsolateGroup() {}

void IsolateGroup::RegisterIsolate(Isolate* isolate) {
  WriteRwLocker wl(ThreadState::Current(), isolates_rwlock_.get());
  isolates_.Append(isolate);
  isolate_count_++;
}

void IsolateGroup::UnregisterIsolate(Isolate* isolate) {
  bool is_last_isolate = false;
  {
    WriteRwLocker wl(ThreadState::Current(), isolates_rwlock_.get());
    isolates_.Remove(isolate);
    isolate_count_--;
    is_last_isolate = isolate_count_ == 0;
  }
  if (is_last_isolate) {
    // If the creation of the isolate group (or the first isolate within the
    // isolate group) failed, we do not invoke the cleanup callback (the
    // embedder is responsible for handling the creation error).
    if (initial_spawn_successful_) {
      auto group_shutdown_callback = Isolate::GroupCleanupCallback();
      if (group_shutdown_callback != nullptr) {
        group_shutdown_callback(embedder_data());
      }
    }
    delete this;
  }
}

Thread* IsolateGroup::ScheduleThreadLocked(MonitorLocker* ml,
                                           Thread* existing_mutator_thread,
                                           bool is_vm_isolate,
                                           bool is_mutator,
                                           bool bypass_safepoint) {
  ASSERT(threads_lock()->IsOwnedByCurrentThread());

  // Schedule the thread into the isolate group by associating
  // a 'Thread' structure with it (this is done while we are holding
  // the thread registry lock).
  Thread* thread = nullptr;
  OSThread* os_thread = OSThread::Current();
  if (os_thread != nullptr) {
    // If a safepoint operation is in progress wait for it
    // to finish before scheduling this thread in.
    while (!bypass_safepoint && safepoint_handler()->SafepointInProgress()) {
      ml->Wait();
    }

    if (is_mutator) {
      if (existing_mutator_thread == nullptr) {
        // Allocate a new [Thread] structure for the mutator thread.
        thread = thread_registry()->GetFreeThreadLocked(is_vm_isolate);
      } else {
        // Reuse the existing cached [Thread] structure for the mutator thread.,
        // see comment in 'base_isolate.h'.
        thread_registry()->AddToActiveListLocked(existing_mutator_thread);
        thread = existing_mutator_thread;
      }
    } else {
      thread = thread_registry()->GetFreeThreadLocked(is_vm_isolate);
    }

    // Now get a free Thread structure.
    ASSERT(thread != nullptr);

    thread->ResetHighWatermark();

    // Set up other values and set the TLS value.
    thread->isolate_ = nullptr;
    thread->isolate_group_ = this;
    thread->set_os_thread(os_thread);
    ASSERT(thread->execution_state() == Thread::kThreadInNative);
    thread->set_execution_state(Thread::kThreadInVM);
    thread->set_safepoint_state(
        Thread::SetBypassSafepoints(bypass_safepoint, 0));
    thread->set_vm_tag(VMTag::kVMTagId);
    ASSERT(thread->no_safepoint_scope_depth() == 0);
    os_thread->set_thread(thread);
    Thread::SetCurrent(thread);
    os_thread->EnableThreadInterrupts();
  }
  return thread;
}

void IsolateGroup::UnscheduleThreadLocked(MonitorLocker* ml,
                                          Thread* thread,
                                          bool is_mutator,
                                          bool bypass_safepoint) {
  // Disassociate the 'Thread' structure and unschedule the thread
  // from this isolate group.
  if (!is_mutator) {
    ASSERT(thread->api_top_scope_ == nullptr);
    ASSERT(thread->zone() == nullptr);
    ASSERT(thread->sticky_error() == Error::null());
  }
  if (!bypass_safepoint) {
    // Ensure that the thread reports itself as being at a safepoint.
    thread->EnterSafepoint();
  }
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != nullptr);
  os_thread->DisableThreadInterrupts();
  os_thread->set_thread(nullptr);
  OSThread::SetCurrent(os_thread);

  // Even if we unschedule the mutator thread, e.g. via calling
  // `Dart_ExitIsolate()` inside a native, we might still have one or more Dart
  // stacks active, which e.g. GC marker threads want to visit.  So we don't
  // clear out the isolate pointer if we are on the mutator thread.
  //
  // The [thread] structure for the mutator thread is kept alive in the thread
  // registry even if the mutator thread is temporarily unscheduled.
  //
  // All other threads are not allowed to unschedule themselves and schedule
  // again later on.
  if (!is_mutator) {
    thread->isolate_ = nullptr;
  }
  thread->heap_ = nullptr;
  thread->set_os_thread(nullptr);
  thread->set_execution_state(Thread::kThreadInNative);
  thread->set_safepoint_state(Thread::SetAtSafepoint(true, 0));
  thread->clear_pending_functions();
  ASSERT(thread->no_safepoint_scope_depth() == 0);
  if (is_mutator) {
    // The mutator thread structure stays alive and attached to the isolate as
    // long as the isolate lives. So we simply remove the thread from the list
    // of scheduled threads.
    thread_registry()->RemoveFromActiveListLocked(thread);
  } else {
    // Return thread structure.
    thread_registry()->ReturnThreadLocked(thread);
  }
}

Thread* IsolateGroup::ScheduleThread(bool bypass_safepoint) {
  // We are about to associate the thread with an isolate group and it would
  // not be possible to correctly track no_safepoint_scope_depth for the
  // thread in the constructor/destructor of MonitorLocker,
  // so we create a MonitorLocker object which does not do any
  // no_safepoint_scope_depth increments/decrements.
  MonitorLocker ml(threads_lock(), false);

  const bool is_vm_isolate = false;

  // Schedule the thread into the isolate by associating
  // a 'Thread' structure with it (this is done while we are holding
  // the thread registry lock).
  return ScheduleThreadLocked(&ml, /*existing_mutator_thread=*/nullptr,
                              is_vm_isolate, /*is_mutator=*/false,
                              bypass_safepoint);
}

void IsolateGroup::UnscheduleThread(Thread* thread,
                                    bool is_mutator,
                                    bool bypass_safepoint) {
  // Disassociate the 'Thread' structure and unschedule the thread
  // from this isolate group.
  //
  // We are disassociating the thread from an isolate and it would
  // not be possible to correctly track no_safepoint_scope_depth for the
  // thread in the constructor/destructor of MonitorLocker,
  // so we create a MonitorLocker object which does not do any
  // no_safepoint_scope_depth increments/decrements.
  MonitorLocker ml(threads_lock(), false);
  UnscheduleThreadLocked(&ml, thread, is_mutator, bypass_safepoint);
}

bool IsolateVisitor::IsVMInternalIsolate(Isolate* isolate) const {
  return Isolate::IsVMInternalIsolate(isolate);
}

NoOOBMessageScope::NoOOBMessageScope(Thread* thread)
    : ThreadStackResource(thread) {
  thread->DeferOOBMessageInterrupts();
}

NoOOBMessageScope::~NoOOBMessageScope() {
  thread()->RestoreOOBMessageInterrupts();
}

NoReloadScope::NoReloadScope(Isolate* isolate, Thread* thread)
    : ThreadStackResource(thread), isolate_(isolate) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(isolate_ != NULL);
  AtomicOperations::FetchAndIncrement(&(isolate_->no_reload_scope_depth_));
  ASSERT(AtomicOperations::LoadRelaxed(&(isolate_->no_reload_scope_depth_)) >=
         0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

NoReloadScope::~NoReloadScope() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  AtomicOperations::FetchAndDecrement(&(isolate_->no_reload_scope_depth_));
  ASSERT(AtomicOperations::LoadRelaxed(&(isolate_->no_reload_scope_depth_)) >=
         0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

void Isolate::RegisterClass(const Class& cls) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (IsReloading()) {
    reload_context()->RegisterClass(cls);
    return;
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  class_table()->Register(cls);
}

#if defined(DEBUG)
void Isolate::ValidateClassTable() {
  class_table()->Validate();
}
#endif  // DEBUG

void Isolate::RehashConstants() {
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  thread->heap()->ResetCanonicalHashTable();

  Class& cls = Class::Handle(zone);
  intptr_t top = class_table()->NumCids();
  for (intptr_t cid = kInstanceCid; cid < top; cid++) {
    if (!class_table()->IsValidIndex(cid) ||
        !class_table()->HasValidClassAt(cid)) {
      continue;
    }
    if ((cid == kTypeArgumentsCid) || RawObject::IsStringClassId(cid)) {
      // TypeArguments and Symbols have special tables for canonical objects
      // that aren't based on address.
      continue;
    }
    cls = class_table()->At(cid);
    cls.RehashConstants(zone);
  }
}

#if defined(DEBUG)
void Isolate::ValidateConstants() {
  if (FLAG_precompiled_mode) {
    // TODO(27003)
    return;
  }
  if (HasAttemptedReload()) {
    return;
  }
  // Verify that all canonical instances are correctly setup in the
  // corresponding canonical tables.
  BackgroundCompiler::Stop(this);
  heap()->CollectAllGarbage();
  Thread* thread = Thread::Current();
  HeapIterationScope iteration(thread);
  VerifyCanonicalVisitor check_canonical(thread);
  iteration.IterateObjects(&check_canonical);
}
#endif  // DEBUG

void Isolate::SendInternalLibMessage(LibMsgId msg_id, uint64_t capability) {
  const Array& msg = Array::Handle(Array::New(3));
  Object& element = Object::Handle();

  element = Smi::New(Message::kIsolateLibOOBMsg);
  msg.SetAt(0, element);
  element = Smi::New(msg_id);
  msg.SetAt(1, element);
  element = Capability::New(capability);
  msg.SetAt(2, element);

  MessageWriter writer(false);
  PortMap::PostMessage(
      writer.WriteMessage(msg, main_port(), Message::kOOBPriority));
}

class IsolateMessageHandler : public MessageHandler {
 public:
  explicit IsolateMessageHandler(Isolate* isolate);
  ~IsolateMessageHandler();

  const char* name() const;
  void MessageNotify(Message::Priority priority);
  MessageStatus HandleMessage(std::unique_ptr<Message> message);
#ifndef PRODUCT
  void NotifyPauseOnStart();
  void NotifyPauseOnExit();
#endif  // !PRODUCT

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess();
#endif
  bool IsCurrentIsolate() const;
  virtual Isolate* isolate() const { return isolate_; }

 private:
  // A result of false indicates that the isolate should terminate the
  // processing of further events.
  RawError* HandleLibMessage(const Array& message);

  MessageStatus ProcessUnhandledException(const Error& result);
  Isolate* isolate_;
};

IsolateMessageHandler::IsolateMessageHandler(Isolate* isolate)
    : isolate_(isolate) {}

IsolateMessageHandler::~IsolateMessageHandler() {}

const char* IsolateMessageHandler::name() const {
  return isolate_->name();
}

// Isolate library OOB messages are fixed sized arrays which have the
// following format:
// [ OOB dispatch, Isolate library dispatch, <message specific data> ]
RawError* IsolateMessageHandler::HandleLibMessage(const Array& message) {
  if (message.Length() < 2) return Error::null();
  Zone* zone = T->zone();
  const Object& type = Object::Handle(zone, message.At(1));
  if (!type.IsSmi()) return Error::null();
  const intptr_t msg_type = Smi::Cast(type).Value();
  switch (msg_type) {
    case Isolate::kPauseMsg: {
      // [ OOB, kPauseMsg, pause capability, resume capability ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();
      obj = message.At(3);
      if (!obj.IsCapability()) return Error::null();
      if (I->AddResumeCapability(Capability::Cast(obj))) {
        increment_paused();
      }
      break;
    }
    case Isolate::kResumeMsg: {
      // [ OOB, kResumeMsg, pause capability, resume capability ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();
      obj = message.At(3);
      if (!obj.IsCapability()) return Error::null();
      if (I->RemoveResumeCapability(Capability::Cast(obj))) {
        decrement_paused();
      }
      break;
    }
    case Isolate::kPingMsg: {
      // [ OOB, kPingMsg, responsePort, priority, response ]
      if (message.Length() != 5) return Error::null();
      const Object& obj2 = Object::Handle(zone, message.At(2));
      if (!obj2.IsSendPort()) return Error::null();
      const SendPort& send_port = SendPort::Cast(obj2);
      const Object& obj3 = Object::Handle(zone, message.At(3));
      if (!obj3.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj3).Value();
      const Object& obj4 = Object::Handle(zone, message.At(4));
      if (!obj4.IsInstance() && !obj4.IsNull()) return Error::null();
      const Instance& response =
          obj4.IsNull() ? Instance::null_instance() : Instance::Cast(obj4);
      if (priority == Isolate::kImmediateAction) {
        PortMap::PostMessage(SerializeMessage(send_port.Id(), response));
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case Isolate::kKillMsg:
    case Isolate::kInternalKillMsg: {
      // [ OOB, kKillMsg, terminate capability, priority ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(3));
      if (!obj.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj).Value();
      if (priority == Isolate::kImmediateAction) {
        obj = message.At(2);
        if (I->VerifyTerminateCapability(obj)) {
          // We will kill the current isolate by returning an UnwindError.
          if (msg_type == Isolate::kKillMsg) {
            const String& msg = String::Handle(
                String::New("isolate terminated by Isolate.kill"));
            const UnwindError& error =
                UnwindError::Handle(UnwindError::New(msg));
            error.set_is_user_initiated(true);
            return error.raw();
          } else if (msg_type == Isolate::kInternalKillMsg) {
            const String& msg =
                String::Handle(String::New("isolate terminated by vm"));
            return UnwindError::New(msg);
          } else {
            UNREACHABLE();
          }
        } else {
          return Error::null();
        }
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case Isolate::kInterruptMsg: {
      // [ OOB, kInterruptMsg, pause capability ]
      if (message.Length() != 3) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();

#if !defined(PRODUCT)
      // If we are already paused, don't pause again.
      if (I->debugger()->PauseEvent() == NULL) {
        return I->debugger()->PauseInterrupted();
      }
#endif
      break;
    }
    case Isolate::kLowMemoryMsg: {
      I->heap()->NotifyLowMemory();
      break;
    }
    case Isolate::kDrainServiceExtensionsMsg: {
#ifndef PRODUCT
      Object& obj = Object::Handle(zone, message.At(2));
      if (!obj.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj).Value();
      if (priority == Isolate::kImmediateAction) {
        return I->InvokePendingServiceExtensionCalls();
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(2,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
#else
      UNREACHABLE();
#endif  // !PRODUCT
      break;
    }

    case Isolate::kAddExitMsg:
    case Isolate::kDelExitMsg:
    case Isolate::kAddErrorMsg:
    case Isolate::kDelErrorMsg: {
      // [ OOB, msg, listener port ]
      if (message.Length() < 3) return Error::null();
      const Object& obj = Object::Handle(zone, message.At(2));
      if (!obj.IsSendPort()) return Error::null();
      const SendPort& listener = SendPort::Cast(obj);
      switch (msg_type) {
        case Isolate::kAddExitMsg: {
          if (message.Length() != 4) return Error::null();
          // [ OOB, msg, listener port, response object ]
          const Object& response = Object::Handle(zone, message.At(3));
          if (!response.IsInstance() && !response.IsNull()) {
            return Error::null();
          }
          I->AddExitListener(listener, response.IsNull()
                                           ? Instance::null_instance()
                                           : Instance::Cast(response));
          break;
        }
        case Isolate::kDelExitMsg:
          if (message.Length() != 3) return Error::null();
          I->RemoveExitListener(listener);
          break;
        case Isolate::kAddErrorMsg:
          if (message.Length() != 3) return Error::null();
          I->AddErrorListener(listener);
          break;
        case Isolate::kDelErrorMsg:
          if (message.Length() != 3) return Error::null();
          I->RemoveErrorListener(listener);
          break;
        default:
          UNREACHABLE();
      }
      break;
    }
    case Isolate::kErrorFatalMsg: {
      // [ OOB, kErrorFatalMsg, terminate capability, val ]
      if (message.Length() != 4) return Error::null();
      // Check that the terminate capability has been passed correctly.
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyTerminateCapability(obj)) return Error::null();
      // Get the value to be set.
      obj = message.At(3);
      if (!obj.IsBool()) return Error::null();
      I->SetErrorsFatal(Bool::Cast(obj).value());
      break;
    }
#if defined(DEBUG)
    // Malformed OOB messages are silently ignored in release builds.
    default:
      FATAL1("Unknown OOB message type: %" Pd "\n", msg_type);
      break;
#endif  // defined(DEBUG)
  }
  return Error::null();
}

void IsolateMessageHandler::MessageNotify(Message::Priority priority) {
  if (priority >= Message::kOOBPriority) {
    // Handle out of band messages even if the mutator thread is busy.
    I->ScheduleInterrupts(Thread::kMessageInterrupt);
  }
  Dart_MessageNotifyCallback callback = I->message_notify_callback();
  if (callback != nullptr) {
    // Allow the embedder to handle message notification.
    (*callback)(Api::CastIsolate(I));
  }
}

bool Isolate::HasPendingMessages() {
  return message_handler_->HasMessages() || message_handler_->HasOOBMessages();
}

MessageHandler::MessageStatus IsolateMessageHandler::HandleMessage(
    std::unique_ptr<Message> message) {
  ASSERT(IsCurrentIsolate());
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();
  HandleScope handle_scope(thread);
#if defined(SUPPORT_TIMELINE)
  TimelineDurationScope tds(
      thread, Timeline::GetIsolateStream(),
      message->IsOOB() ? "HandleOOBMessage" : "HandleMessage");
  tds.SetNumArguments(1);
  tds.CopyArgument(0, "isolateName", I->name());
#endif

  // If the message is in band we lookup the handler to dispatch to.  If the
  // receive port was closed, we drop the message without deserializing it.
  // Illegal port is a special case for artificially enqueued isolate library
  // messages which are handled in C++ code below.
  Object& msg_handler = Object::Handle(zone);
  if (!message->IsOOB() && (message->dest_port() != Message::kIllegalPort)) {
    msg_handler = DartLibraryCalls::LookupHandler(message->dest_port());
    if (msg_handler.IsError()) {
      return ProcessUnhandledException(Error::Cast(msg_handler));
    }
    if (msg_handler.IsNull()) {
      // If the port has been closed then the message will be dropped at this
      // point. Make sure to post to the delivery failure port in that case.
      if (message->RedirectToDeliveryFailurePort()) {
        PortMap::PostMessage(std::move(message));
      }
      return kOK;
    }
  }

  // Parse the message.
  Object& msg_obj = Object::Handle(zone);
  if (message->IsRaw()) {
    msg_obj = message->raw_obj();
    // We should only be sending RawObjects that can be converted to CObjects.
    ASSERT(ApiObjectConverter::CanConvert(msg_obj.raw()));
  } else {
    MessageSnapshotReader reader(message.get(), thread);
    msg_obj = reader.ReadObject();
  }
  if (msg_obj.IsError()) {
    // An error occurred while reading the message.
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
  Instance& msg = Instance::Handle(zone);
  msg ^= msg_obj.raw();  // Can't use Instance::Cast because may be null.

  MessageStatus status = kOK;
  if (message->IsOOB()) {
    // OOB messages are expected to be fixed length arrays where the first
    // element is a Smi describing the OOB destination. Messages that do not
    // confirm to this layout are silently ignored.
    if (msg.IsArray()) {
      const Array& oob_msg = Array::Cast(msg);
      if (oob_msg.Length() > 0) {
        const Object& oob_tag = Object::Handle(zone, oob_msg.At(0));
        if (oob_tag.IsSmi()) {
          switch (Smi::Cast(oob_tag).Value()) {
            case Message::kServiceOOBMsg: {
              if (FLAG_support_service) {
                const Error& error =
                    Error::Handle(Service::HandleIsolateMessage(I, oob_msg));
                if (!error.IsNull()) {
                  status = ProcessUnhandledException(error);
                }
              } else {
                UNREACHABLE();
              }
              break;
            }
            case Message::kIsolateLibOOBMsg: {
              const Error& error = Error::Handle(HandleLibMessage(oob_msg));
              if (!error.IsNull()) {
                status = ProcessUnhandledException(error);
              }
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
        const Object& oob_tag = Object::Handle(zone, msg_arr.At(0));
        if (oob_tag.IsSmi() &&
            (Smi::Cast(oob_tag).Value() == Message::kDelayedIsolateLibOOBMsg)) {
          const Error& error = Error::Handle(HandleLibMessage(msg_arr));
          if (!error.IsNull()) {
            status = ProcessUnhandledException(error);
          }
        }
      }
    }
  } else {
#ifndef PRODUCT
    if (!Isolate::IsVMInternalIsolate(I)) {
      // Mark all the user isolates as white-listed for the simplified timeline
      // page of Observatory. The internal isolates will be filtered out from
      // the Timeline due to absence of this argument. We still send them in
      // order to maintain the original behavior of the full timeline and allow
      // the developer to download complete dump files.
      tds.SetNumArguments(2);
      tds.CopyArgument(1, "mode", "basic");
    }
#endif
    const Object& result =
        Object::Handle(zone, DartLibraryCalls::HandleMessage(msg_handler, msg));
    if (result.IsError()) {
      status = ProcessUnhandledException(Error::Cast(result));
    } else {
      ASSERT(result.IsNull());
    }
  }
  return status;
}

#ifndef PRODUCT
void IsolateMessageHandler::NotifyPauseOnStart() {
  if (!FLAG_support_service || Isolate::IsVMInternalIsolate(I)) {
    return;
  }
  if (Service::debug_stream.enabled() || FLAG_warn_on_pause_with_no_debugger) {
    StartIsolateScope start_isolate(I);
    StackZone zone(T);
    HandleScope handle_scope(T);
    ServiceEvent pause_event(I, ServiceEvent::kPauseStart);
    Service::HandleEvent(&pause_event);
  } else if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Dropping event of type PauseStart (%s)\n",
                 I->name());
  }
}

void IsolateMessageHandler::NotifyPauseOnExit() {
  if (!FLAG_support_service || Isolate::IsVMInternalIsolate(I)) {
    return;
  }
  if (Service::debug_stream.enabled() || FLAG_warn_on_pause_with_no_debugger) {
    StartIsolateScope start_isolate(I);
    StackZone zone(T);
    HandleScope handle_scope(T);
    ServiceEvent pause_event(I, ServiceEvent::kPauseExit);
    Service::HandleEvent(&pause_event);
  } else if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Dropping event of type PauseExit (%s)\n",
                 I->name());
  }
}
#endif  // !PRODUCT

#if defined(DEBUG)
void IsolateMessageHandler::CheckAccess() {
  ASSERT(IsCurrentIsolate());
}
#endif

bool IsolateMessageHandler::IsCurrentIsolate() const {
  return (I == Isolate::Current());
}

static MessageHandler::MessageStatus StoreError(Thread* thread,
                                                const Error& error) {
  thread->set_sticky_error(error);
  if (error.IsUnwindError()) {
    const UnwindError& unwind = UnwindError::Cast(error);
    if (!unwind.is_user_initiated()) {
      return MessageHandler::kShutdown;
    }
  }
  return MessageHandler::kError;
}

MessageHandler::MessageStatus IsolateMessageHandler::ProcessUnhandledException(
    const Error& result) {
  if (FLAG_trace_isolates) {
    OS::PrintErr(
        "[!] Unhandled exception in %s:\n"
        "         exception: %s\n",
        T->isolate()->name(), result.ToErrorCString());
  }

  NoReloadScope no_reload_scope(T->isolate(), T);
  // Generate the error and stacktrace strings for the error message.
  String& exc_str = String::Handle(T->zone());
  String& stacktrace_str = String::Handle(T->zone());
  if (result.IsUnhandledException()) {
    Zone* zone = T->zone();
    const UnhandledException& uhe = UnhandledException::Cast(result);
    const Instance& exception = Instance::Handle(zone, uhe.exception());
    Object& tmp = Object::Handle(zone);
    tmp = DartLibraryCalls::ToString(exception);
    if (!tmp.IsString()) {
      tmp = String::New(exception.ToCString());
    }
    exc_str ^= tmp.raw();

    const Instance& stacktrace = Instance::Handle(zone, uhe.stacktrace());
    tmp = DartLibraryCalls::ToString(stacktrace);
    if (!tmp.IsString()) {
      tmp = String::New(stacktrace.ToCString());
    }
    stacktrace_str ^= tmp.raw();
  } else {
    exc_str = String::New(result.ToErrorCString());
  }
  if (result.IsUnwindError()) {
    // When unwinding we don't notify error listeners and we ignore
    // whether errors are fatal for the current isolate.
    return StoreError(T, result);
  } else {
    bool has_listener = I->NotifyErrorListeners(exc_str, stacktrace_str);
    if (I->ErrorsFatal()) {
      if (has_listener) {
        T->ClearStickyError();
      } else {
        T->set_sticky_error(result);
      }
#if !defined(PRODUCT)
      // Notify the debugger about specific unhandled exceptions which are
      // withheld when being thrown. Do this after setting the sticky error
      // so the isolate has an error set when paused with the unhandled
      // exception.
      if (result.IsUnhandledException()) {
        const UnhandledException& error = UnhandledException::Cast(result);
        RawInstance* exception = error.exception();
        if ((exception == I->object_store()->out_of_memory()) ||
            (exception == I->object_store()->stack_overflow())) {
          // We didn't notify the debugger when the stack was full. Do it now.
          I->debugger()->PauseException(Instance::Handle(exception));
        }
      }
#endif  // !defined(PRODUCT)
      return kError;
    }
  }
  return kOK;
}

void Isolate::FlagsInitialize(Dart_IsolateFlags* api_flags) {
  const bool false_by_default = false;
  const bool true_by_default = true;
  USE(true_by_default);
  USE(false_by_default);

  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FLAG(when, name, bitname, isolate_flag, flag)                \
  api_flags->isolate_flag = flag;
  ISOLATE_FLAG_LIST(INIT_FROM_FLAG)
#undef INIT_FROM_FLAG
  api_flags->entry_points = NULL;
  api_flags->load_vmservice_library = false;
  api_flags->copy_parent_code = false;
}

void Isolate::FlagsCopyTo(Dart_IsolateFlags* api_flags) const {
  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FIELD(when, name, bitname, isolate_flag, flag)               \
  api_flags->isolate_flag = name();
  ISOLATE_FLAG_LIST(INIT_FROM_FIELD)
#undef INIT_FROM_FIELD
  api_flags->entry_points = NULL;
  api_flags->load_vmservice_library = should_load_vmservice();
  api_flags->copy_parent_code = false;
}

void Isolate::FlagsCopyFrom(const Dart_IsolateFlags& api_flags) {
#if defined(DART_PRECOMPILER)
#define FLAG_FOR_PRECOMPILER(action) action
#else
#define FLAG_FOR_PRECOMPILER(action)
#endif

#if !defined(PRODUCT)
#define FLAG_FOR_NONPRODUCT(action) action
#else
#define FLAG_FOR_NONPRODUCT(action)
#endif

#define FLAG_FOR_PRODUCT(action) action

#define SET_FROM_FLAG(when, name, bitname, isolate_flag, flag)                 \
  FLAG_FOR_##when(isolate_flags_ = bitname##Bit::update(                       \
                      api_flags.isolate_flag, isolate_flags_));

  ISOLATE_FLAG_LIST(SET_FROM_FLAG)

#undef FLAG_FOR_NONPRODUCT
#undef FLAG_FOR_PRECOMPILER
#undef FLAG_FOR_PRODUCT
#undef SET_FROM_FLAG

  set_should_load_vmservice(api_flags.load_vmservice_library);

  // Copy entry points list.
  ASSERT(embedder_entry_points_ == NULL);
  if (api_flags.entry_points != NULL) {
    intptr_t count = 0;
    while (api_flags.entry_points[count].function_name != NULL)
      count++;
    embedder_entry_points_ = new Dart_QualifiedFunctionName[count + 1];
    for (intptr_t i = 0; i < count; i++) {
      embedder_entry_points_[i].library_uri =
          strdup(api_flags.entry_points[i].library_uri);
      embedder_entry_points_[i].class_name =
          strdup(api_flags.entry_points[i].class_name);
      embedder_entry_points_[i].function_name =
          strdup(api_flags.entry_points[i].function_name);
    }
    memset(&embedder_entry_points_[count], 0,
           sizeof(Dart_QualifiedFunctionName));
  }

  // Leave others at defaults.
}

#if defined(DEBUG)
// static
void BaseIsolate::AssertCurrent(BaseIsolate* isolate) {
  ASSERT(isolate == Isolate::Current());
}

void BaseIsolate::AssertCurrentThreadIsMutator() const {
  ASSERT(Isolate::Current() == this);
  ASSERT(Thread::Current()->IsMutatorThread());
}
#endif  // defined(DEBUG)

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object) object##_handle_(nullptr),

// TODO(srdjan): Some Isolate monitors can be shared. Replace their usage with
// that shared monitor.
Isolate::Isolate(IsolateGroup* isolate_group,
                 const Dart_IsolateFlags& api_flags)
    : BaseIsolate(),
      current_tag_(UserTag::null()),
      default_tag_(UserTag::null()),
      ic_miss_code_(Code::null()),
      shared_class_table_(new SharedClassTable()),
      class_table_(shared_class_table_.get()),
      store_buffer_(new StoreBuffer()),
#if !defined(TARGET_ARCH_DBC) && !defined(DART_PRECOMPILED_RUNTIME)
      native_callback_trampolines_(),
#endif
#if !defined(PRODUCT)
      last_resume_timestamp_(OS::GetCurrentTimeMillis()),
      vm_tag_counters_(),
      pending_service_extension_calls_(GrowableObjectArray::null()),
      registered_service_extension_handlers_(GrowableObjectArray::null()),
#define ISOLATE_METRIC_CONSTRUCTORS(type, variable, name, unit)                \
  metric_##variable##_(),
      ISOLATE_METRIC_LIST(ISOLATE_METRIC_CONSTRUCTORS)
#undef ISOLATE_METRIC_CONSTRUCTORS
          reload_every_n_stack_overflow_checks_(FLAG_reload_every),
      last_reload_timestamp_(OS::GetCurrentTimeMillis()),
#endif  // !defined(PRODUCT)
      start_time_micros_(OS::GetCurrentMonotonicMicros()),
      random_(),
      mutex_(NOT_IN_PRODUCT("Isolate::mutex_")),
      symbols_mutex_(NOT_IN_PRODUCT("Isolate::symbols_mutex_")),
      type_canonicalization_mutex_(
          NOT_IN_PRODUCT("Isolate::type_canonicalization_mutex_")),
      constant_canonicalization_mutex_(
          NOT_IN_PRODUCT("Isolate::constant_canonicalization_mutex_")),
      megamorphic_mutex_(NOT_IN_PRODUCT("Isolate::megamorphic_mutex_")),
      kernel_data_lib_cache_mutex_(
          NOT_IN_PRODUCT("Isolate::kernel_data_lib_cache_mutex_")),
      kernel_data_class_cache_mutex_(
          NOT_IN_PRODUCT("Isolate::kernel_data_class_cache_mutex_")),
      kernel_constants_mutex_(
          NOT_IN_PRODUCT("Isolate::kernel_constants_mutex_")),
      pending_deopts_(new MallocGrowableArray<PendingLazyDeopt>()),
      tag_table_(GrowableObjectArray::null()),
      deoptimized_code_array_(GrowableObjectArray::null()),
      sticky_error_(Error::null()),
      reloaded_kernel_blobs_(GrowableObjectArray::null()),
      field_list_mutex_(NOT_IN_PRODUCT("Isolate::field_list_mutex_")),
      boxed_field_list_(GrowableObjectArray::null()),
      spawn_count_monitor_(),
      handler_info_cache_(),
      catch_entry_moves_cache_() {
  FlagsCopyFrom(api_flags);
  SetErrorsFatal(true);
  set_compilation_allowed(true);
  // TODO(asiva): A Thread is not available here, need to figure out
  // how the vm_tag (kEmbedderTagId) can be set, these tags need to
  // move to the OSThread structure.
  set_user_tag(UserTags::kDefaultUserTag);

  if (obfuscate()) {
    OS::PrintErr(
        "Warning: This VM has been configured to obfuscate symbol information "
        "which violates the Dart standard.\n"
        "         See dartbug.com/30524 for more information.\n");
  }

  if (FLAG_enable_interpreter) {
    NOT_IN_PRECOMPILED(background_compiler_ = new BackgroundCompiler(
                           this, /* optimizing = */ false));
  }
  NOT_IN_PRECOMPILED(optimizing_background_compiler_ =
                         new BackgroundCompiler(this, /* optimizing = */ true));

  isolate_group->RegisterIsolate(this);
  isolate_group_ = isolate_group;
}

#undef REUSABLE_HANDLE_SCOPE_INIT
#undef REUSABLE_HANDLE_INITIALIZERS

Isolate::~Isolate() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // TODO(32796): Re-enable assertion.
  // RELEASE_ASSERT(reload_context_ == NULL);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  delete reverse_pc_lookup_cache_;
  reverse_pc_lookup_cache_ = nullptr;

  if (FLAG_enable_interpreter) {
    delete background_compiler_;
    background_compiler_ = nullptr;
  }

  delete optimizing_background_compiler_;
  optimizing_background_compiler_ = nullptr;

#if !defined(PRODUCT)
  delete debugger_;
  debugger_ = nullptr;
  if (FLAG_support_service) {
    delete object_id_ring_;
  }
  object_id_ring_ = nullptr;
  delete pause_loop_monitor_;
  pause_loop_monitor_ = nullptr;
#endif  // !defined(PRODUCT)

  free(name_);
  delete store_buffer_;
  delete heap_;
  ASSERT(marking_stack_ == nullptr);
  delete object_store_;
  delete api_state_;
#if defined(USING_SIMULATOR)
  delete simulator_;
#endif
  delete pending_deopts_;
  pending_deopts_ = nullptr;
  delete message_handler_;
  message_handler_ =
      nullptr;  // Fail fast if we send messages to a dead isolate.
  ASSERT(deopt_context_ ==
         nullptr);  // No deopt in progress when isolate deleted.
  ASSERT(spawn_count_ == 0);

  // We have cached the mutator thread, delete it.
  ASSERT(scheduled_mutator_thread_ == nullptr);
  mutator_thread_->isolate_ = nullptr;
  delete mutator_thread_;
  mutator_thread_ = nullptr;

  if (obfuscation_map_ != nullptr) {
    for (intptr_t i = 0; obfuscation_map_[i] != nullptr; i++) {
      delete[] obfuscation_map_[i];
    }
    delete[] obfuscation_map_;
  }

  if (embedder_entry_points_ != nullptr) {
    for (intptr_t i = 0; embedder_entry_points_[i].function_name != nullptr;
         i++) {
      free(const_cast<char*>(embedder_entry_points_[i].library_uri));
      free(const_cast<char*>(embedder_entry_points_[i].class_name));
      free(const_cast<char*>(embedder_entry_points_[i].function_name));
    }
    delete[] embedder_entry_points_;
  }

  // Run isolate group specific cleanup function if the last isolate in an
  // isolate group died.
  isolate_group_->UnregisterIsolate(this);
  isolate_group_ = nullptr;
}

void Isolate::InitVM() {
  create_group_callback_ = nullptr;
  initialize_callback_ = nullptr;
  shutdown_callback_ = nullptr;
  cleanup_callback_ = nullptr;
  cleanup_group_callback_ = nullptr;
  if (isolates_list_monitor_ == nullptr) {
    isolates_list_monitor_ = new Monitor();
  }
  ASSERT(isolates_list_monitor_ != nullptr);
  EnableIsolateCreation();
}

Isolate* Isolate::InitIsolate(const char* name_prefix,
                              IsolateGroup* isolate_group,
                              const Dart_IsolateFlags& api_flags,
                              bool is_vm_isolate) {
  Isolate* result = new Isolate(isolate_group, api_flags);
  ASSERT(result != nullptr);

#if !defined(PRODUCT)
// Initialize metrics.
#define ISOLATE_METRIC_INIT(type, variable, name, unit)                        \
  result->metric_##variable##_.InitInstance(result, name, NULL, Metric::unit);
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_INIT);
#undef ISOLATE_METRIC_INIT
#endif  // !defined(PRODUCT)

  bool is_service_or_kernel_isolate = false;
  if (ServiceIsolate::NameEquals(name_prefix)) {
    ASSERT(!ServiceIsolate::Exists());
    is_service_or_kernel_isolate = true;
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (KernelIsolate::NameEquals(name_prefix)) {
    ASSERT(!KernelIsolate::Exists());
    KernelIsolate::SetKernelIsolate(result);
    is_service_or_kernel_isolate = true;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  Heap::Init(result,
             is_vm_isolate
                 ? 0  // New gen size 0; VM isolate should only allocate in old.
                 : FLAG_new_gen_semi_max_size * MBInWords,
             (is_service_or_kernel_isolate ? kDefaultMaxOldGenHeapSize
                                           : FLAG_old_gen_heap_size) *
                 MBInWords);

  // TODO(5411455): For now just set the recently created isolate as
  // the current isolate.
  if (!Thread::EnterIsolate(result)) {
    // We failed to enter the isolate, it is possible the VM is shutting down,
    // return back a NULL so that CreateIsolate reports back an error.
    if (KernelIsolate::IsKernelIsolate(result)) {
      KernelIsolate::SetKernelIsolate(nullptr);
    }
    if (ServiceIsolate::IsServiceIsolate(result)) {
      ServiceIsolate::SetServiceIsolate(nullptr);
    }
    delete result;
    return nullptr;
  }

  // Setup the isolate message handler.
  MessageHandler* handler = new IsolateMessageHandler(result);
  ASSERT(handler != nullptr);
  result->set_message_handler(handler);

  // Setup the Dart API state.
  ApiState* state = new ApiState();
  ASSERT(state != nullptr);
  result->set_api_state(state);

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
#if !defined(PRODUCT)
  result->debugger_ = new Debugger(result);
#endif
  if (FLAG_trace_isolates) {
    if (name_prefix == nullptr || strcmp(name_prefix, "vm-isolate") != 0) {
      OS::PrintErr(
          "[+] Starting isolate:\n"
          "\tisolate:    %s\n",
          result->name());
    }
  }

#ifndef PRODUCT
  if (FLAG_support_service) {
    if (FLAG_object_id_ring_size != ObjectIdRing::kDefaultCapacity) {
      OS::Print(
          "WARNING: this flag is temporary, is not supported, and should"
          " only be used for UX studies. Use at your own risk!\n");
    }
    ObjectIdRing::Init(result, FLAG_object_id_ring_size);
  }
#endif  // !PRODUCT

  // Add to isolate list. Shutdown and delete the isolate on failure.
  if (!AddIsolateToList(result)) {
    result->LowLevelShutdown();
    Thread::ExitIsolate();
    if (KernelIsolate::IsKernelIsolate(result)) {
      KernelIsolate::SetKernelIsolate(nullptr);
    }
    if (ServiceIsolate::IsServiceIsolate(result)) {
      ServiceIsolate::SetServiceIsolate(nullptr);
    }

    delete result;
    return nullptr;
  }

  return result;
}

void Isolate::RetainKernelBlob(const ExternalTypedData& kernel_blob) {
  if (reloaded_kernel_blobs_ == Object::null()) {
    reloaded_kernel_blobs_ = GrowableObjectArray::New();
  }
  auto& kernel_blobs = GrowableObjectArray::Handle(reloaded_kernel_blobs_);
  kernel_blobs.Add(kernel_blob);
}

Thread* Isolate::mutator_thread() const {
  ASSERT(thread_registry() != nullptr);
  return mutator_thread_;
}

RawObject* Isolate::CallTagHandler(Dart_LibraryTag tag,
                                   const Object& arg1,
                                   const Object& arg2) {
  Thread* thread = Thread::Current();
  Api::Scope api_scope(thread);
  Dart_Handle api_arg1 = Api::NewHandle(thread, arg1.raw());
  Dart_Handle api_arg2 = Api::NewHandle(thread, arg2.raw());
  Dart_Handle api_result;
  {
    TransitionVMToNative transition(thread);
    ASSERT(HasTagHandler());
    api_result = group()->library_tag_handler()(tag, api_arg1, api_arg2);
  }
  return Api::UnwrapHandle(api_result);
}

void Isolate::SetupImagePage(const uint8_t* image_buffer, bool is_executable) {
  Image image(image_buffer);
  heap_->SetupImagePage(image.object_start(), image.object_size(),
                        is_executable);
}

void Isolate::ScheduleInterrupts(uword interrupt_bits) {
  // We take the threads lock here to ensure that the mutator thread does not
  // exit the isolate while we are trying to schedule interrupts on it.
  MonitorLocker ml(threads_lock());
  Thread* mthread = mutator_thread();
  if (mthread != nullptr) {
    mthread->ScheduleInterrupts(interrupt_bits);
  }
}

void Isolate::set_name(const char* name) {
  free(name_);
  name_ = strdup(name);
}

int64_t Isolate::UptimeMicros() const {
  return OS::GetCurrentMonotonicMicros() - start_time_micros_;
}

bool Isolate::IsPaused() const {
#if defined(PRODUCT)
  return false;
#else
  return (debugger_ != nullptr) && (debugger_->PauseEvent() != nullptr);
#endif  // !defined(PRODUCT)
}

RawError* Isolate::PausePostRequest() {
#if !defined(PRODUCT)
  if (debugger_ == nullptr) {
    return Error::null();
  }
  ASSERT(!IsPaused());
  const Error& error = Error::Handle(debugger_->PausePostRequest());
  if (!error.IsNull()) {
    if (Thread::Current()->top_exit_frame_info() == 0) {
      return error.raw();
    } else {
      Exceptions::PropagateError(error);
      UNREACHABLE();
    }
  }
#endif
  return Error::null();
}

void Isolate::BuildName(const char* name_prefix) {
  ASSERT(name_ == nullptr);
  if (name_prefix == nullptr) {
    name_ = OS::SCreate(nullptr, "isolate-%" Pd64 "", main_port());
  } else {
    name_ = strdup(name_prefix);
  }
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
bool Isolate::CanReload() const {
  return !Isolate::IsVMInternalIsolate(this) && is_runnable() &&
         !IsReloading() &&
         (AtomicOperations::LoadRelaxed(&no_reload_scope_depth_) == 0) &&
         IsolateCreationEnabled() &&
         OSThread::Current()->HasStackHeadroom(64 * KB);
}

bool Isolate::ReloadSources(JSONStream* js,
                            bool force_reload,
                            const char* root_script_url,
                            const char* packages_url,
                            bool dont_delete_reload_context) {
  ASSERT(!IsReloading());
  SetHasAttemptedReload(true);
  reload_context_ = new IsolateReloadContext(this, js);
  reload_context_->Reload(force_reload, root_script_url, packages_url,
                          /* kernel_buffer= */ nullptr,
                          /* kernel_buffer_size= */ 0);
  bool success = !reload_context_->reload_aborted();
  if (!dont_delete_reload_context) {
    DeleteReloadContext();
  }
  return success;
}

bool Isolate::ReloadKernel(JSONStream* js,
                           bool force_reload,
                           const uint8_t* kernel_buffer,
                           intptr_t kernel_buffer_size,
                           bool dont_delete_reload_context) {
  ASSERT(!IsReloading());
  SetHasAttemptedReload(true);
  reload_context_ = new IsolateReloadContext(this, js);
  reload_context_->Reload(force_reload,
                          /* root_script_url= */ nullptr,
                          /* packages_url= */ nullptr, kernel_buffer,
                          kernel_buffer_size);
  bool success = !reload_context_->reload_aborted();
  if (!dont_delete_reload_context) {
    DeleteReloadContext();
  }
  return success;
}

void Isolate::DeleteReloadContext() {
  // Another thread may be in the middle of GetClassForHeapWalkAt.
  Thread* thread = Thread::Current();
  SafepointOperationScope safepoint_scope(thread);

  delete reload_context_;
  reload_context_ = nullptr;
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

const char* Isolate::MakeRunnable() {
  ASSERT(Isolate::Current() == nullptr);

  MutexLocker ml(&mutex_);
  // Check if we are in a valid state to make the isolate runnable.
  if (is_runnable() == true) {
    return "Isolate is already runnable";
  }
  // Set the isolate as runnable and if we are being spawned schedule
  // isolate on thread pool for execution.
  ASSERT(object_store()->root_library() != Library::null());
  set_is_runnable(true);
#ifndef PRODUCT
  if (!Isolate::IsVMInternalIsolate(this)) {
    debugger()->OnIsolateRunnable();
    if (FLAG_pause_isolates_on_unhandled_exceptions) {
      debugger()->SetExceptionPauseInfo(kPauseOnUnhandledExceptions);
    }
  }
#endif  // !PRODUCT
  IsolateSpawnState* state = spawn_state();
  if (state != nullptr) {
    ASSERT(this == state->isolate());
    Run();
  }
#if defined(SUPPORT_TIMELINE)
  TimelineStream* stream = Timeline::GetIsolateStream();
  ASSERT(stream != nullptr);
  TimelineEvent* event = stream->StartEvent();
  if (event != nullptr) {
    event->Instant("Runnable");
    event->Complete();
  }
#endif
#ifndef PRODUCT
  if (FLAG_support_service && !Isolate::IsVMInternalIsolate(this) &&
      Service::isolate_stream.enabled()) {
    ServiceEvent runnableEvent(this, ServiceEvent::kIsolateRunnable);
    Service::HandleEvent(&runnableEvent);
  }
  GetRunnableLatencyMetric()->set_value(UptimeMicros());
  if (FLAG_print_benchmarking_metrics) {
    {
      StartIsolateScope scope(this);
      heap()->CollectAllGarbage();
    }
    int64_t heap_size = (heap()->UsedInWords(Heap::kNew) * kWordSize) +
                        (heap()->UsedInWords(Heap::kOld) * kWordSize);
    GetRunnableHeapSizeMetric()->set_value(heap_size);
  }
#endif  // !PRODUCT
  return nullptr;
}

bool Isolate::VerifyPauseCapability(const Object& capability) const {
  return !capability.IsNull() && capability.IsCapability() &&
         (pause_capability() == Capability::Cast(capability).Id());
}

bool Isolate::VerifyTerminateCapability(const Object& capability) const {
  return !capability.IsNull() && capability.IsCapability() &&
         (terminate_capability() == Capability::Cast(capability).Id());
}

bool Isolate::AddResumeCapability(const Capability& capability) {
  // Ensure a limit for the number of resume capabilities remembered.
  static const intptr_t kMaxResumeCapabilities =
      compiler::target::kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& caps = GrowableObjectArray::Handle(
      current_zone(), object_store()->resume_capabilities());
  Capability& current = Capability::Handle(current_zone());
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
      current_zone(), object_store()->resume_capabilities());
  Capability& current = Capability::Handle(current_zone());
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
  static const intptr_t kMaxListeners =
      compiler::target::kSmiMax / (12 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(current_zone());
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
      current_zone(), object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(current_zone());
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
      current_zone(), this->object_store()->exit_listeners());
  if (listeners.IsNull()) return;

  SendPort& listener = SendPort::Handle(current_zone());
  Instance& response = Instance::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      response ^= listeners.At(i + 1);
      PortMap::PostMessage(SerializeMessage(port_id, response));
    }
  }
}

void Isolate::AddErrorListener(const SendPort& listener) {
  // Ensure a limit for the number of listeners remembered.
  static const intptr_t kMaxListeners =
      compiler::target::kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), object_store()->error_listeners());
  SendPort& current = SendPort::Handle(current_zone());
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
      current_zone(), object_store()->error_listeners());
  SendPort& current = SendPort::Handle(current_zone());
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

bool Isolate::NotifyErrorListeners(const String& msg,
                                   const String& stacktrace) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), this->object_store()->error_listeners());
  if (listeners.IsNull()) return false;

  const Array& arr = Array::Handle(current_zone(), Array::New(2));
  arr.SetAt(0, msg);
  arr.SetAt(1, stacktrace);
  SendPort& listener = SendPort::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      PortMap::PostMessage(SerializeMessage(port_id, arr));
    }
  }
  return listeners.Length() > 0;
}

static MessageHandler::MessageStatus RunIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  IsolateSpawnState* state = nullptr;
  {
    // TODO(turnidge): Is this locking required here at all anymore?
    MutexLocker ml(isolate->mutex());
    state = isolate->spawn_state();
  }
  {
    StartIsolateScope start_scope(isolate);
    Thread* thread = Thread::Current();
    ASSERT(thread->isolate() == isolate);
    StackZone zone(thread);
    HandleScope handle_scope(thread);

    // If particular values were requested for this newly spawned isolate, then
    // they are set here before the isolate starts executing user code.
    isolate->SetErrorsFatal(state->errors_are_fatal());
    if (state->on_exit_port() != ILLEGAL_PORT) {
      const SendPort& listener =
          SendPort::Handle(SendPort::New(state->on_exit_port()));
      isolate->AddExitListener(listener, Instance::null_instance());
    }
    if (state->on_error_port() != ILLEGAL_PORT) {
      const SendPort& listener =
          SendPort::Handle(SendPort::New(state->on_error_port()));
      isolate->AddErrorListener(listener);
    }

    // Switch back to spawning isolate.

    if (!ClassFinalizer::ProcessPendingClasses()) {
// Error is in sticky error already.
#if defined(DEBUG)
      const Error& error = Error::Handle(thread->sticky_error());
      ASSERT(!error.IsUnwindError());
#endif
      return MessageHandler::kError;
    }

    Object& result = Object::Handle();
    result = state->ResolveFunction();
    bool is_spawn_uri = state->is_spawn_uri();
    if (result.IsError()) {
      return StoreError(thread, Error::Cast(result));
    }
    ASSERT(result.IsFunction());
    Function& func = Function::Handle(thread->zone());
    func ^= result.raw();

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
    args.SetAt(2, Instance::Handle(state->BuildArgs(thread)));
    args.SetAt(3, Instance::Handle(state->BuildMessage(thread)));
    args.SetAt(4, is_spawn_uri ? Bool::True() : Bool::False());
    args.SetAt(5, ReceivePort::Handle(ReceivePort::New(
                      isolate->main_port(), true /* control port */)));
    args.SetAt(6, capabilities);

    const Library& lib = Library::Handle(Library::IsolateLibrary());
    const String& entry_name = String::Handle(String::New("_startIsolate"));
    const Function& entry_point =
        Function::Handle(lib.LookupLocalFunction(entry_name));
    ASSERT(entry_point.IsFunction() && !entry_point.IsNull());

    result = DartEntry::InvokeFunction(entry_point, args);
    if (result.IsError()) {
      return StoreError(thread, Error::Cast(result));
    }
  }
  return MessageHandler::kOK;
}

static void ShutdownIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  {
    // Print the error if there is one.  This may execute dart code to
    // print the exception object, so we need to use a StartIsolateScope.
    StartIsolateScope start_scope(isolate);
    Thread* thread = Thread::Current();
    ASSERT(thread->isolate() == isolate);

    // We must wait for any outstanding spawn calls to complete before
    // running the shutdown callback.
    isolate->WaitForOutstandingSpawns();

    StackZone zone(thread);
    HandleScope handle_scope(thread);
#if defined(DEBUG)
    isolate->ValidateConstants();
#endif  // defined(DEBUG)
    Dart::RunShutdownCallback();
  }
  // Shut the isolate down.
  Dart::ShutdownIsolate(isolate);
}

void Isolate::SetStickyError(RawError* sticky_error) {
  ASSERT(
      ((sticky_error_ == Error::null()) || (sticky_error == Error::null())) &&
      (sticky_error != sticky_error_));
  sticky_error_ = sticky_error;
}

void Isolate::Run() {
  message_handler()->Run(Dart::thread_pool(), RunIsolate, ShutdownIsolate,
                         reinterpret_cast<uword>(this));
}

void Isolate::NotifyIdle(int64_t deadline) {
  heap()->NotifyIdle(deadline);
}

void Isolate::AddClosureFunction(const Function& function) const {
  ASSERT(!Compiler::IsBackgroundCompilation());
  GrowableObjectArray& closures =
      GrowableObjectArray::Handle(object_store()->closure_functions());
  ASSERT(!closures.IsNull());
  ASSERT(function.IsNonImplicitClosureFunction());
  closures.Add(function, Heap::kOld);
}

// If the linear lookup turns out to be too expensive, the list
// of closures could be maintained in a hash map, with the key
// being the token position of the closure. There are almost no
// collisions with this simple hash value. However, iterating over
// all closure functions becomes more difficult, especially when
// the list/map changes while iterating over it.
RawFunction* Isolate::LookupClosureFunction(const Function& parent,
                                            TokenPosition token_pos) const {
  const GrowableObjectArray& closures =
      GrowableObjectArray::Handle(object_store()->closure_functions());
  ASSERT(!closures.IsNull());
  Function& closure = Function::Handle();
  intptr_t num_closures = closures.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    if ((closure.token_pos() == token_pos) &&
        (closure.parent_function() == parent.raw())) {
      return closure.raw();
    }
  }
  return Function::null();
}

intptr_t Isolate::FindClosureIndex(const Function& needle) const {
  const GrowableObjectArray& closures_array =
      GrowableObjectArray::Handle(object_store()->closure_functions());
  intptr_t num_closures = closures_array.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    if (closures_array.At(i) == needle.raw()) {
      return i;
    }
  }
  return -1;
}

RawFunction* Isolate::ClosureFunctionFromIndex(intptr_t idx) const {
  const GrowableObjectArray& closures_array =
      GrowableObjectArray::Handle(object_store()->closure_functions());
  if ((idx < 0) || (idx >= closures_array.Length())) {
    return Function::null();
  }
  return Function::RawCast(closures_array.At(idx));
}

class FinalizeWeakPersistentHandlesVisitor : public HandleVisitor {
 public:
  FinalizeWeakPersistentHandlesVisitor() : HandleVisitor(Thread::Current()) {}

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    handle->UpdateUnreachable(thread()->isolate());
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(FinalizeWeakPersistentHandlesVisitor);
};

// static
void Isolate::NotifyLowMemory() {
  Isolate::KillAllIsolates(Isolate::kLowMemoryMsg);
}

void Isolate::LowLevelShutdown() {
  // Ensure we have a zone and handle scope so that we can call VM functions,
  // but we no longer allocate new heap objects.
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);
  NoSafepointScope no_safepoint_scope;

  // Notify exit listeners that this isolate is shutting down.
  if (object_store() != nullptr) {
    const Error& error = Error::Handle(thread->sticky_error());
    if (error.IsNull() || !error.IsUnwindError() ||
        UnwindError::Cast(error).is_user_initiated()) {
      NotifyExitListeners();
    }
  }

  // Close all the ports owned by this isolate.
  PortMap::ClosePorts(message_handler());

  // Fail fast if anybody tries to post any more messages to this isolate.
  delete message_handler();
  set_message_handler(nullptr);
#if defined(SUPPORT_TIMELINE)
  // Before analyzing the isolate's timeline blocks- reclaim all cached
  // blocks.
  Timeline::ReclaimCachedBlocksFromThreads();
#endif

// Dump all timing data for the isolate.
#if defined(SUPPORT_TIMELINE) && !defined(PRODUCT)
  if (FLAG_timing) {
    TimelinePauseTrace tpt;
    tpt.Print();
  }
#endif  // !PRODUCT

  // Finalize any weak persistent handles with a non-null referent.
  FinalizeWeakPersistentHandlesVisitor visitor;
  api_state()->weak_persistent_handles().VisitHandles(&visitor);

#if !defined(PRODUCT)
  if (FLAG_dump_megamorphic_stats) {
    MegamorphicCacheTable::PrintSizes(this);
  }
  if (FLAG_dump_symbol_stats) {
    Symbols::DumpStats(this);
  }
  if (FLAG_trace_isolates) {
    heap()->PrintSizes();
    OS::PrintErr(
        "[-] Stopping isolate:\n"
        "\tisolate:    %s\n",
        name());
  }
  if (FLAG_print_metrics || FLAG_print_benchmarking_metrics) {
    LogBlock lb;
    OS::PrintErr("Printing metrics for %s\n", name());
#define ISOLATE_METRIC_PRINT(type, variable, name, unit)                       \
  OS::PrintErr("%s\n", metric_##variable##_.ToString());
    ISOLATE_METRIC_LIST(ISOLATE_METRIC_PRINT)
#undef ISOLATE_METRIC_PRINT
    OS::PrintErr("\n");
  }
#endif  // !defined(PRODUCT)
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
void Isolate::MaybeIncreaseReloadEveryNStackOverflowChecks() {
  if (FLAG_reload_every_back_off) {
    if (reload_every_n_stack_overflow_checks_ < 5000) {
      reload_every_n_stack_overflow_checks_ += 99;
    } else {
      reload_every_n_stack_overflow_checks_ *= 2;
    }
    // Cap the value.
    if (reload_every_n_stack_overflow_checks_ > 1000000) {
      reload_every_n_stack_overflow_checks_ = 1000000;
    }
  }
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void Isolate::set_forward_table_new(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_new_ = std::move(value);
}
void Isolate::set_forward_table_old(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_old_ = std::move(value);
}

void Isolate::Shutdown() {
  ASSERT(this == Isolate::Current());
  BackgroundCompiler::Stop(this);
  if (FLAG_enable_interpreter) {
    delete background_compiler_;
    background_compiler_ = nullptr;
  }
  delete optimizing_background_compiler_;
  optimizing_background_compiler_ = nullptr;

#if defined(DEBUG)
  if (heap_ != nullptr && FLAG_verify_on_transition) {
    // The VM isolate keeps all objects marked.
    heap_->Verify(this == Dart::vm_isolate() ? kRequireMarked : kForbidMarked);
  }
#endif  // DEBUG

  Thread* thread = Thread::Current();

  // Don't allow anymore dart code to execution on this isolate.
  thread->ClearStackLimit();

  // Remove this isolate from the list *before* we start tearing it down, to
  // avoid exposing it in a state of decay.
  RemoveIsolateFromList(this);

  {
    // After removal from isolate list. Before tearing down the heap.
    StackZone zone(thread);
    HandleScope handle_scope(thread);
    ServiceIsolate::SendIsolateShutdownMessage();
    KernelIsolate::NotifyAboutIsolateShutdown(this);
#if !defined(PRODUCT)
    debugger()->Shutdown();
#endif
  }

  if (heap_ != nullptr) {
    // Wait for any concurrent GC tasks to finish before shutting down.
    // TODO(rmacnak): Interrupt tasks for faster shutdown.
    PageSpace* old_space = heap_->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    while (old_space->tasks() > 0) {
      ml.Wait();
    }
    // Needs to happen before ~PageSpace so TLS and the thread registery are
    // still valid.
    old_space->AbandonMarkingForShutdown();
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_check_reloaded && is_runnable() &&
      !Isolate::IsVMInternalIsolate(this)) {
    if (!HasAttemptedReload()) {
      FATAL(
          "Isolate did not reload before exiting and "
          "--check-reloaded is enabled.\n");
    }
  }

#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Then, proceed with low-level teardown.
  LowLevelShutdown();

#if defined(DEBUG)
  // No concurrent sweeper tasks should be running at this point.
  if (heap_ != nullptr) {
    PageSpace* old_space = heap_->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    ASSERT(old_space->tasks() == 0);
  }
#endif

  // TODO(5411455): For now just make sure there are no current isolates
  // as we are shutting down the isolate.
  Thread::ExitIsolate();

  // Run isolate specific cleanup function for all non "vm-isolate's.
  if (Dart::vm_isolate() != this) {
    Dart_IsolateCleanupCallback cleanup = Isolate::CleanupCallback();
    if (cleanup != nullptr) {
      cleanup(isolate_group_->embedder_data(), init_callback_data());
    }
  }
}

Dart_InitializeIsolateCallback Isolate::initialize_callback_ = nullptr;
Dart_IsolateGroupCreateCallback Isolate::create_group_callback_ = nullptr;
Dart_IsolateShutdownCallback Isolate::shutdown_callback_ = nullptr;
Dart_IsolateCleanupCallback Isolate::cleanup_callback_ = nullptr;
Dart_IsolateGroupCleanupCallback Isolate::cleanup_group_callback_ = nullptr;

Monitor* Isolate::isolates_list_monitor_ = nullptr;
Isolate* Isolate::isolates_list_head_ = nullptr;
bool Isolate::creation_enabled_ = false;

void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  ValidationPolicy validate_frames) {
  ASSERT(visitor != nullptr);

  // Visit objects in the object store.
  object_store()->VisitObjectPointers(visitor);

  // Visit objects in the class table.
  class_table()->VisitObjectPointers(visitor);

  // Visit the dart api state for all local and persistent handles.
  if (api_state() != nullptr) {
    api_state()->VisitObjectPointers(visitor);
  }

  visitor->clear_gc_root_type();
  // Visit the objects directly referenced from the isolate structure.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&current_tag_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&default_tag_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&ic_miss_code_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&tag_table_));
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&deoptimized_code_array_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&sticky_error_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&reloaded_kernel_blobs_));
#if !defined(PRODUCT)
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&pending_service_extension_calls_));
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&registered_service_extension_handlers_));
#endif  // !defined(PRODUCT)
  // Visit the boxed_field_list_.
  // 'boxed_field_list_' access via mutator and background compilation threads
  // is guarded with a monitor. This means that we can visit it only
  // when at safepoint or the field_list_mutex_ lock has been taken.
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&boxed_field_list_));

  if (background_compiler() != nullptr) {
    background_compiler()->VisitPointers(visitor);
  }
  if (optimizing_background_compiler() != nullptr) {
    optimizing_background_compiler()->VisitPointers(visitor);
  }

#if !defined(PRODUCT)
  // Visit objects in the debugger.
  debugger()->VisitObjectPointers(visitor);
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Visit objects that are being used for isolate reload.
  if (reload_context() != nullptr) {
    reload_context()->VisitObjectPointers(visitor);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  if (ServiceIsolate::IsServiceIsolate(this)) {
    ServiceIsolate::VisitObjectPointers(visitor);
  }
#endif  // !defined(PRODUCT)

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Visit objects that are being used for deoptimization.
  if (deopt_context() != nullptr) {
    deopt_context()->VisitObjectPointers(visitor);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(TARGET_ARCH_DBC)
  if (simulator() != nullptr) {
    simulator()->VisitObjectPointers(visitor);
  }
#endif  // defined(TARGET_ARCH_DBC)

  VisitStackPointers(visitor, validate_frames);
}

void Isolate::VisitStackPointers(ObjectPointerVisitor* visitor,
                                 ValidationPolicy validate_frames) {
  visitor->set_gc_root_type("stack");
  // Visit objects in all threads (e.g., Dart stack, handles in zones).
  thread_registry()->VisitObjectPointers(this, visitor, validate_frames);

  // Visit mutator thread, even if the isolate isn't entered/scheduled (there
  // might be live API handles to visit).
  if (mutator_thread_ != nullptr) {
    mutator_thread_->VisitObjectPointers(visitor, validate_frames);
  }
  visitor->clear_gc_root_type();
}

void Isolate::VisitWeakPersistentHandles(HandleVisitor* visitor) {
  if (api_state() != nullptr) {
    api_state()->VisitWeakHandles(visitor);
  }
}

void Isolate::ReleaseStoreBuffers() {
  thread_registry()->ReleaseStoreBuffers(this);
}

void Isolate::EnableIncrementalBarrier(MarkingStack* marking_stack,
                                       MarkingStack* deferred_marking_stack) {
  ASSERT(marking_stack_ == nullptr);
  marking_stack_ = marking_stack;
  deferred_marking_stack_ = deferred_marking_stack;
  thread_registry()->AcquireMarkingStacks(this);
  ASSERT(Thread::Current()->is_marking());
}

void Isolate::DisableIncrementalBarrier() {
  thread_registry()->ReleaseMarkingStacks(this);
  ASSERT(marking_stack_ != nullptr);
  marking_stack_ = nullptr;
  deferred_marking_stack_ = nullptr;
  ASSERT(!Thread::Current()->is_marking());
}

void IsolateGroup::RunWithStoppedMutators(
    std::function<void()> single_current_mutator,
    std::function<void()> otherwise,
    bool use_force_growth_in_otherwise) {
  auto thread = Thread::Current();

  ReadRwLocker wl(thread, isolates_rwlock_.get());
  const bool only_one_isolate = isolates_.First() == isolates_.Last();
  if (thread->IsMutatorThread() && only_one_isolate) {
    single_current_mutator();
  } else {
    // We use the more strict safepoint operation scope here (which ensures that
    // all other threads, including auxiliary threads are at a safepoint), even
    // though we only need to ensure that the mutator threads are stopped.
    if (use_force_growth_in_otherwise) {
      ForceGrowthSafepointOperationScope safepoint_scope(thread);
      otherwise();
    } else {
      SafepointOperationScope safepoint_scope(thread);
      otherwise();
    }
  }
}

RawClass* Isolate::GetClassForHeapWalkAt(intptr_t cid) {
  RawClass* raw_class = nullptr;
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (IsReloading()) {
    raw_class = reload_context()->GetClassForHeapWalkAt(cid);
  } else {
    raw_class = class_table()->At(cid);
  }
#else
  raw_class = class_table()->At(cid);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(raw_class != nullptr);
  ASSERT(remapping_cids() || raw_class->ptr()->id_ == cid);
  return raw_class;
}

intptr_t Isolate::GetClassSizeForHeapWalkAt(intptr_t cid) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (IsReloading()) {
    return reload_context()->GetClassSizeForHeapWalkAt(cid);
  } else {
    return class_table()->SizeAt(cid);
  }
#else
  return class_table()->SizeAt(cid);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

void Isolate::AddPendingDeopt(uword fp, uword pc) {
  // GrowableArray::Add is not atomic and may be interrupt by a profiler
  // stack walk.
  MallocGrowableArray<PendingLazyDeopt>* old_pending_deopts = pending_deopts_;
  MallocGrowableArray<PendingLazyDeopt>* new_pending_deopts =
      new MallocGrowableArray<PendingLazyDeopt>(old_pending_deopts->length() +
                                                1);
  for (intptr_t i = 0; i < old_pending_deopts->length(); i++) {
    ASSERT((*old_pending_deopts)[i].fp() != fp);
    new_pending_deopts->Add((*old_pending_deopts)[i]);
  }
  PendingLazyDeopt deopt(fp, pc);
  new_pending_deopts->Add(deopt);

  pending_deopts_ = new_pending_deopts;
  delete old_pending_deopts;
}

uword Isolate::FindPendingDeopt(uword fp) const {
  for (intptr_t i = 0; i < pending_deopts_->length(); i++) {
    if ((*pending_deopts_)[i].fp() == fp) {
      return (*pending_deopts_)[i].pc();
    }
  }
  FATAL("Missing pending deopt entry");
  return 0;
}

void Isolate::ClearPendingDeoptsAtOrBelow(uword fp) const {
  for (intptr_t i = pending_deopts_->length() - 1; i >= 0; i--) {
    if ((*pending_deopts_)[i].fp() <= fp) {
      pending_deopts_->RemoveAt(i);
    }
  }
}

#ifndef PRODUCT
static const char* ExceptionPauseInfoToServiceEnum(Dart_ExceptionPauseInfo pi) {
  switch (pi) {
    case kPauseOnAllExceptions:
      return "All";
    case kNoPauseOnExceptions:
      return "None";
    case kPauseOnUnhandledExceptions:
      return "Unhandled";
    default:
      UNIMPLEMENTED();
      return nullptr;
  }
}

void Isolate::PrintJSON(JSONStream* stream, bool ref) {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", (ref ? "@Isolate" : "Isolate"));
  jsobj.AddServiceId(ISOLATE_SERVICE_ID_FORMAT_STRING,
                     static_cast<int64_t>(main_port()));

  jsobj.AddProperty("name", name());
  jsobj.AddPropertyF("number", "%" Pd64 "", static_cast<int64_t>(main_port()));
  if (ref) {
    return;
  }
  jsobj.AddPropertyF("_originNumber", "%" Pd64 "",
                     static_cast<int64_t>(origin_id()));
  int64_t uptime_millis = UptimeMicros() / kMicrosecondsPerMillisecond;
  int64_t start_time = OS::GetCurrentTimeMillis() - uptime_millis;
  jsobj.AddPropertyTimeMillis("startTime", start_time);
  {
    JSONObject jsheap(&jsobj, "_heaps");
    heap()->PrintToJSONObject(Heap::kNew, &jsheap);
    heap()->PrintToJSONObject(Heap::kOld, &jsheap);
  }

  jsobj.AddProperty("runnable", is_runnable());
  jsobj.AddProperty("livePorts", message_handler()->live_ports());
  jsobj.AddProperty("pauseOnExit", message_handler()->should_pause_on_exit());
#if !defined(DART_PRECOMPILED_RUNTIME)
  jsobj.AddProperty("_isReloading", IsReloading());
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  if (!is_runnable()) {
    // Isolate is not yet runnable.
    ASSERT((debugger() == nullptr) || (debugger()->PauseEvent() == nullptr));
    ServiceEvent pause_event(this, ServiceEvent::kNone);
    jsobj.AddProperty("pauseEvent", &pause_event);
  } else if (message_handler()->should_pause_on_start()) {
    if (message_handler()->is_paused_on_start()) {
      ASSERT((debugger() == nullptr) || (debugger()->PauseEvent() == nullptr));
      ServiceEvent pause_event(this, ServiceEvent::kPauseStart);
      jsobj.AddProperty("pauseEvent", &pause_event);
    } else {
      // Isolate is runnable but not paused on start.
      // Some service clients get confused if they see:
      // NotRunnable -> Runnable -> PausedAtStart
      // Treat Runnable+ShouldPauseOnStart as NotRunnable so they see:
      // NonRunnable -> PausedAtStart
      // The should_pause_on_start flag is set to false after resume.
      ASSERT((debugger() == nullptr) || (debugger()->PauseEvent() == nullptr));
      ServiceEvent pause_event(this, ServiceEvent::kNone);
      jsobj.AddProperty("pauseEvent", &pause_event);
    }
  } else if (message_handler()->is_paused_on_exit() &&
             ((debugger() == nullptr) ||
              (debugger()->PauseEvent() == nullptr))) {
    ServiceEvent pause_event(this, ServiceEvent::kPauseExit);
    jsobj.AddProperty("pauseEvent", &pause_event);
  } else if ((debugger() != nullptr) && (debugger()->PauseEvent() != nullptr) &&
             !ResumeRequest()) {
    jsobj.AddProperty("pauseEvent", debugger()->PauseEvent());
  } else {
    ServiceEvent pause_event(this, ServiceEvent::kResume);

    if (debugger() != nullptr) {
      // TODO(turnidge): Don't compute a full stack trace.
      DebuggerStackTrace* stack = debugger()->StackTrace();
      if (stack->Length() > 0) {
        pause_event.set_top_frame(stack->FrameAt(0));
      }
    }
    jsobj.AddProperty("pauseEvent", &pause_event);
  }

  const Library& lib = Library::Handle(object_store()->root_library());
  if (!lib.IsNull()) {
    jsobj.AddProperty("rootLib", lib);
  }

  intptr_t zone_handle_count = thread_registry()->CountZoneHandles(this);
  intptr_t scoped_handle_count = thread_registry()->CountScopedHandles(this);

  jsobj.AddProperty("_numZoneHandles", zone_handle_count);
  jsobj.AddProperty("_numScopedHandles", scoped_handle_count);

  if (FLAG_profiler) {
    JSONObject tagCounters(&jsobj, "_tagCounters");
    vm_tag_counters()->PrintToJSONObject(&tagCounters);
  }
  if (Thread::Current()->sticky_error() != Object::null()) {
    Error& error = Error::Handle(Thread::Current()->sticky_error());
    ASSERT(!error.IsNull());
    jsobj.AddProperty("error", error, false);
  } else if (sticky_error() != Object::null()) {
    Error& error = Error::Handle(sticky_error());
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
    if (debugger() != nullptr) {
      debugger()->PrintBreakpointsToJSONArray(&breakpoints);
    }
  }

  Dart_ExceptionPauseInfo pause_info = (debugger() != nullptr)
                                           ? debugger()->GetExceptionPauseInfo()
                                           : kNoPauseOnExceptions;
  jsobj.AddProperty("exceptionPauseMode",
                    ExceptionPauseInfoToServiceEnum(pause_info));

  if (debugger() != nullptr) {
    JSONObject settings(&jsobj, "_debuggerSettings");
    debugger()->PrintSettingsToJSONObject(&settings);
  }

  {
    GrowableObjectArray& handlers =
        GrowableObjectArray::Handle(registered_service_extension_handlers());
    if (!handlers.IsNull()) {
      JSONArray extensions(&jsobj, "extensionRPCs");
      String& handler_name = String::Handle();
      for (intptr_t i = 0; i < handlers.Length(); i += kRegisteredEntrySize) {
        handler_name ^= handlers.At(i + kRegisteredNameIndex);
        extensions.AddValue(handler_name.ToCString());
      }
    }
  }

  jsobj.AddProperty("_threads", thread_registry());
}

void Isolate::PrintMemoryUsageJSON(JSONStream* stream) {
  if (!FLAG_support_service) {
    return;
  }
  heap()->PrintMemoryUsageJSON(stream);
}

#endif

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

void Isolate::set_ic_miss_code(const Code& code) {
  ic_miss_code_ = code.raw();
}

void Isolate::set_deoptimized_code_array(const GrowableObjectArray& value) {
  ASSERT(Thread::Current()->IsMutatorThread());
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

RawError* Isolate::StealStickyError() {
  NoSafepointScope no_safepoint;
  RawError* return_value = sticky_error_;
  sticky_error_ = Error::null();
  return return_value;
}

#if !defined(PRODUCT)
void Isolate::set_pending_service_extension_calls(
    const GrowableObjectArray& value) {
  pending_service_extension_calls_ = value.raw();
}

void Isolate::set_registered_service_extension_handlers(
    const GrowableObjectArray& value) {
  registered_service_extension_handlers_ = value.raw();
}
#endif  // !defined(PRODUCT)

void Isolate::AddDeoptimizingBoxedField(const Field& field) {
  ASSERT(Compiler::IsBackgroundCompilation());
  ASSERT(!field.IsOriginal());
  // The enclosed code allocates objects and can potentially trigger a GC,
  // ensure that we account for safepoints when grabbing the lock.
  SafepointMutexLocker ml(&field_list_mutex_);
  if (boxed_field_list_ == GrowableObjectArray::null()) {
    boxed_field_list_ = GrowableObjectArray::New(Heap::kOld);
  }
  const GrowableObjectArray& array =
      GrowableObjectArray::Handle(boxed_field_list_);
  array.Add(Field::Handle(field.Original()), Heap::kOld);
}

RawField* Isolate::GetDeoptimizingBoxedField() {
  ASSERT(Thread::Current()->IsMutatorThread());
  SafepointMutexLocker ml(&field_list_mutex_);
  if (boxed_field_list_ == GrowableObjectArray::null()) {
    return Field::null();
  }
  const GrowableObjectArray& array =
      GrowableObjectArray::Handle(boxed_field_list_);
  if (array.Length() == 0) {
    return Field::null();
  }
  return Field::RawCast(array.RemoveLast());
}

#ifndef PRODUCT
RawError* Isolate::InvokePendingServiceExtensionCalls() {
  if (!FLAG_support_service) {
    return Error::null();
  }
  GrowableObjectArray& calls =
      GrowableObjectArray::Handle(GetAndClearPendingServiceExtensionCalls());
  if (calls.IsNull()) {
    return Error::null();
  }
  // Grab run function.
  const Library& developer_lib = Library::Handle(Library::DeveloperLibrary());
  ASSERT(!developer_lib.IsNull());
  const Function& run_extension = Function::Handle(
      developer_lib.LookupLocalFunction(Symbols::_runExtension()));
  ASSERT(!run_extension.IsNull());

  const Array& arguments =
      Array::Handle(Array::New(kPendingEntrySize + 1, Heap::kNew));
  Object& result = Object::Handle();
  String& method_name = String::Handle();
  Instance& closure = Instance::Handle();
  Array& parameter_keys = Array::Handle();
  Array& parameter_values = Array::Handle();
  Instance& reply_port = Instance::Handle();
  Instance& id = Instance::Handle();
  for (intptr_t i = 0; i < calls.Length(); i += kPendingEntrySize) {
    // Grab arguments for call.
    closure ^= calls.At(i + kPendingHandlerIndex);
    ASSERT(!closure.IsNull());
    arguments.SetAt(kPendingHandlerIndex, closure);
    method_name ^= calls.At(i + kPendingMethodNameIndex);
    ASSERT(!method_name.IsNull());
    arguments.SetAt(kPendingMethodNameIndex, method_name);
    parameter_keys ^= calls.At(i + kPendingKeysIndex);
    ASSERT(!parameter_keys.IsNull());
    arguments.SetAt(kPendingKeysIndex, parameter_keys);
    parameter_values ^= calls.At(i + kPendingValuesIndex);
    ASSERT(!parameter_values.IsNull());
    arguments.SetAt(kPendingValuesIndex, parameter_values);
    reply_port ^= calls.At(i + kPendingReplyPortIndex);
    ASSERT(!reply_port.IsNull());
    arguments.SetAt(kPendingReplyPortIndex, reply_port);
    id ^= calls.At(i + kPendingIdIndex);
    arguments.SetAt(kPendingIdIndex, id);
    arguments.SetAt(kPendingEntrySize, Bool::Get(FLAG_trace_service));

    if (FLAG_trace_service) {
      OS::PrintErr("[+%" Pd64 "ms] Isolate %s invoking _runExtension for %s\n",
                   Dart::UptimeMillis(), name(), method_name.ToCString());
    }
    result = DartEntry::InvokeFunction(run_extension, arguments);
    if (FLAG_trace_service) {
      OS::PrintErr("[+%" Pd64 "ms] Isolate %s _runExtension complete for %s\n",
                   Dart::UptimeMillis(), name(), method_name.ToCString());
    }
    // Propagate the error.
    if (result.IsError()) {
      // Remaining service extension calls are dropped.
      if (!result.IsUnwindError()) {
        // Send error back over the protocol.
        Service::PostError(method_name, parameter_keys, parameter_values,
                           reply_port, id, Error::Cast(result));
      }
      return Error::Cast(result).raw();
    }
    // Drain the microtask queue.
    result = DartLibraryCalls::DrainMicrotaskQueue();
    // Propagate the error.
    if (result.IsError()) {
      // Remaining service extension calls are dropped.
      return Error::Cast(result).raw();
    }
  }
  return Error::null();
}

RawGrowableObjectArray* Isolate::GetAndClearPendingServiceExtensionCalls() {
  RawGrowableObjectArray* r = pending_service_extension_calls_;
  pending_service_extension_calls_ = GrowableObjectArray::null();
  return r;
}

void Isolate::AppendServiceExtensionCall(const Instance& closure,
                                         const String& method_name,
                                         const Array& parameter_keys,
                                         const Array& parameter_values,
                                         const Instance& reply_port,
                                         const Instance& id) {
  if (FLAG_trace_service) {
    OS::PrintErr("[+%" Pd64
                 "ms] Isolate %s ENQUEUING request for extension %s\n",
                 Dart::UptimeMillis(), name(), method_name.ToCString());
  }
  GrowableObjectArray& calls =
      GrowableObjectArray::Handle(pending_service_extension_calls());
  bool schedule_drain = false;
  if (calls.IsNull()) {
    calls = GrowableObjectArray::New();
    ASSERT(!calls.IsNull());
    set_pending_service_extension_calls(calls);
    schedule_drain = true;
  }
  ASSERT(kPendingHandlerIndex == 0);
  calls.Add(closure);
  ASSERT(kPendingMethodNameIndex == 1);
  calls.Add(method_name);
  ASSERT(kPendingKeysIndex == 2);
  calls.Add(parameter_keys);
  ASSERT(kPendingValuesIndex == 3);
  calls.Add(parameter_values);
  ASSERT(kPendingReplyPortIndex == 4);
  calls.Add(reply_port);
  ASSERT(kPendingIdIndex == 5);
  calls.Add(id);

  if (schedule_drain) {
    const Array& msg = Array::Handle(Array::New(3));
    Object& element = Object::Handle();
    element = Smi::New(Message::kIsolateLibOOBMsg);
    msg.SetAt(0, element);
    element = Smi::New(Isolate::kDrainServiceExtensionsMsg);
    msg.SetAt(1, element);
    element = Smi::New(Isolate::kBeforeNextEventAction);
    msg.SetAt(2, element);
    MessageWriter writer(false);
    std::unique_ptr<Message> message =
        writer.WriteMessage(msg, main_port(), Message::kOOBPriority);
    bool posted = PortMap::PostMessage(std::move(message));
    ASSERT(posted);
  }
}

// This function is written in C++ and not Dart because we must do this
// operation atomically in the face of random OOB messages. Do not port
// to Dart code unless you can ensure that the operations will can be
// done atomically.
void Isolate::RegisterServiceExtensionHandler(const String& name,
                                              const Instance& closure) {
  if (!FLAG_support_service || Isolate::IsVMInternalIsolate(this)) {
    return;
  }
  GrowableObjectArray& handlers =
      GrowableObjectArray::Handle(registered_service_extension_handlers());
  if (handlers.IsNull()) {
    handlers = GrowableObjectArray::New(Heap::kOld);
    set_registered_service_extension_handlers(handlers);
  }
#if defined(DEBUG)
  {
    // Sanity check.
    const Instance& existing_handler =
        Instance::Handle(LookupServiceExtensionHandler(name));
    ASSERT(existing_handler.IsNull());
  }
#endif
  ASSERT(kRegisteredNameIndex == 0);
  handlers.Add(name, Heap::kOld);
  ASSERT(kRegisteredHandlerIndex == 1);
  handlers.Add(closure, Heap::kOld);
  {
    // Fire off an event.
    ServiceEvent event(this, ServiceEvent::kServiceExtensionAdded);
    event.set_extension_rpc(&name);
    Service::HandleEvent(&event);
  }
}

// This function is written in C++ and not Dart because we must do this
// operation atomically in the face of random OOB messages. Do not port
// to Dart code unless you can ensure that the operations will can be
// done atomically.
RawInstance* Isolate::LookupServiceExtensionHandler(const String& name) {
  if (!FLAG_support_service) {
    return Instance::null();
  }
  const GrowableObjectArray& handlers =
      GrowableObjectArray::Handle(registered_service_extension_handlers());
  if (handlers.IsNull()) {
    return Instance::null();
  }
  String& handler_name = String::Handle();
  for (intptr_t i = 0; i < handlers.Length(); i += kRegisteredEntrySize) {
    handler_name ^= handlers.At(i + kRegisteredNameIndex);
    ASSERT(!handler_name.IsNull());
    if (handler_name.Equals(name)) {
      return Instance::RawCast(handlers.At(i + kRegisteredHandlerIndex));
    }
  }
  return Instance::null();
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
  if (pause_loop_monitor_ == nullptr) {
    pause_loop_monitor_ = new Monitor();
  }
  Dart_EnterScope();
  MonitorLocker ml(pause_loop_monitor_, false);

  Dart_MessageNotifyCallback saved_notify_callback = message_notify_callback();
  set_message_notify_callback(Isolate::WakePauseEventHandler);

#if !defined(DART_PRECOMPILED_RUNTIME)
  const bool had_isolate_reload_context = reload_context() != nullptr;
  const int64_t start_time_micros =
      !had_isolate_reload_context ? 0 : reload_context()->start_time_micros();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  bool resume = false;
  bool handle_non_service_messages = false;
  while (true) {
    // Handle all available vm service messages, up to a resume
    // request.
    while (!resume && Dart_HasServiceMessages()) {
      ml.Exit();
      resume = Dart_HandleServiceMessages();
      ml.Enter();
    }
    if (resume) {
      break;
    } else {
      handle_non_service_messages = true;
    }

#if !defined(DART_PRECOMPILED_RUNTIME)
    if (had_isolate_reload_context && (reload_context() == nullptr)) {
      if (FLAG_trace_reload) {
        const int64_t reload_time_micros =
            OS::GetCurrentMonotonicMicros() - start_time_micros;
        double reload_millis = MicrosecondsToMilliseconds(reload_time_micros);
        OS::PrintErr("Reloading has finished! (%.2f ms)\n", reload_millis);
      }
      break;
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

    // Wait for more service messages.
    Monitor::WaitResult res = ml.Wait();
    ASSERT(res == Monitor::kNotified);
  }
  // If any non-service messages came in, we need to notify the registered
  // message notify callback to check for unhandled messages. Otherwise, events
  // may be left unhandled until the next event comes in. See
  // https://github.com/dart-lang/sdk/issues/37312.
  if ((saved_notify_callback != nullptr) && handle_non_service_messages) {
    saved_notify_callback(Api::CastIsolate(this));
  }
  set_message_notify_callback(saved_notify_callback);
  Dart_ExitScope();
}
#endif  // !PRODUCT

void Isolate::VisitIsolates(IsolateVisitor* visitor) {
  if (visitor == nullptr) {
    return;
  }
  // The visitor could potentially run code that could safepoint so use
  // SafepointMonitorLocker to ensure the lock has safepoint checks.
  SafepointMonitorLocker ml(isolates_list_monitor_);
  Isolate* current = isolates_list_head_;
  while (current != nullptr) {
    visitor->VisitIsolate(current);
    current = current->next_;
  }
}

intptr_t Isolate::IsolateListLength() {
  MonitorLocker ml(isolates_list_monitor_);
  intptr_t count = 0;
  Isolate* current = isolates_list_head_;
  while (current != nullptr) {
    count++;
    current = current->next_;
  }
  return count;
}

Isolate* Isolate::LookupIsolateByPort(Dart_Port port) {
  MonitorLocker ml(isolates_list_monitor_);
  Isolate* current = isolates_list_head_;
  while (current != nullptr) {
    if (current->main_port() == port) {
      return current;
    }
    current = current->next_;
  }
  return nullptr;
}

std::unique_ptr<char[]> Isolate::LookupIsolateNameByPort(Dart_Port port) {
  MonitorLocker ml(isolates_list_monitor_);
  Isolate* current = isolates_list_head_;
  while (current != nullptr) {
    if (current->main_port() == port) {
      const size_t len = strlen(current->name()) + 1;
      auto result = std::unique_ptr<char[]>(new char[len]);
      strncpy(result.get(), current->name(), len);
      return result;
    }
    current = current->next_;
  }
  return std::unique_ptr<char[]>();
}

bool Isolate::AddIsolateToList(Isolate* isolate) {
  MonitorLocker ml(isolates_list_monitor_);
  if (!creation_enabled_) {
    return false;
  }
  ASSERT(isolate != nullptr);
  ASSERT(isolate->next_ == nullptr);
  isolate->next_ = isolates_list_head_;
  isolates_list_head_ = isolate;
  return true;
}

void Isolate::RemoveIsolateFromList(Isolate* isolate) {
  MonitorLocker ml(isolates_list_monitor_);
  ASSERT(isolate != nullptr);
  if (isolate == isolates_list_head_) {
    isolates_list_head_ = isolate->next_;
    if (!creation_enabled_) {
      ml.Notify();
    }
    return;
  }
  Isolate* previous = nullptr;
  Isolate* current = isolates_list_head_;
  while (current != nullptr) {
    if (current == isolate) {
      ASSERT(previous != nullptr);
      previous->next_ = current->next_;
      if (!creation_enabled_) {
        ml.Notify();
      }
      return;
    }
    previous = current;
    current = current->next_;
  }
  // If we are shutting down the VM, the isolate may not be in the list.
  ASSERT(!creation_enabled_);
}

void Isolate::DisableIsolateCreation() {
  MonitorLocker ml(isolates_list_monitor_);
  creation_enabled_ = false;
}

void Isolate::EnableIsolateCreation() {
  MonitorLocker ml(isolates_list_monitor_);
  creation_enabled_ = true;
}

bool Isolate::IsolateCreationEnabled() {
  MonitorLocker ml(isolates_list_monitor_);
  return creation_enabled_;
}

bool Isolate::IsVMInternalIsolate(const Isolate* isolate) {
  return (isolate == Dart::vm_isolate()) ||
         ServiceIsolate::IsServiceIsolateDescendant(isolate) ||
         KernelIsolate::IsKernelIsolate(isolate);
}

void Isolate::KillLocked(LibMsgId msg_id) {
  Dart_CObject kill_msg;
  Dart_CObject* list_values[4];
  kill_msg.type = Dart_CObject_kArray;
  kill_msg.value.as_array.length = 4;
  kill_msg.value.as_array.values = list_values;

  Dart_CObject oob;
  oob.type = Dart_CObject_kInt32;
  oob.value.as_int32 = Message::kIsolateLibOOBMsg;
  list_values[0] = &oob;

  Dart_CObject msg_type;
  msg_type.type = Dart_CObject_kInt32;
  msg_type.value.as_int32 = msg_id;
  list_values[1] = &msg_type;

  Dart_CObject cap;
  cap.type = Dart_CObject_kCapability;
  cap.value.as_capability.id = terminate_capability();
  list_values[2] = &cap;

  Dart_CObject imm;
  imm.type = Dart_CObject_kInt32;
  imm.value.as_int32 = Isolate::kImmediateAction;
  list_values[3] = &imm;

  {
    ApiMessageWriter writer;
    std::unique_ptr<Message> message =
        writer.WriteCMessage(&kill_msg, main_port(), Message::kOOBPriority);
    ASSERT(message != nullptr);

    // Post the message at the given port.
    bool success = PortMap::PostMessage(std::move(message));
    ASSERT(success);
  }
}

class IsolateKillerVisitor : public IsolateVisitor {
 public:
  explicit IsolateKillerVisitor(Isolate::LibMsgId msg_id)
      : target_(nullptr), msg_id_(msg_id) {}

  IsolateKillerVisitor(Isolate* isolate, Isolate::LibMsgId msg_id)
      : target_(isolate), msg_id_(msg_id) {
    ASSERT(isolate != Dart::vm_isolate());
  }

  virtual ~IsolateKillerVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    ASSERT(isolate != nullptr);
    if (ShouldKill(isolate)) {
      isolate->KillLocked(msg_id_);
    }
  }

 private:
  bool ShouldKill(Isolate* isolate) {
    // If a target_ is specified, then only kill the target_.
    // Otherwise, don't kill the service isolate or vm isolate.
    return (((target_ != nullptr) && (isolate == target_)) ||
            ((target_ == nullptr) && !IsVMInternalIsolate(isolate)));
  }

  Isolate* target_;
  Isolate::LibMsgId msg_id_;
};

void Isolate::KillAllIsolates(LibMsgId msg_id) {
  IsolateKillerVisitor visitor(msg_id);
  VisitIsolates(&visitor);
}

void Isolate::KillIfExists(Isolate* isolate, LibMsgId msg_id) {
  IsolateKillerVisitor visitor(isolate, msg_id);
  VisitIsolates(&visitor);
}

void Isolate::IncrementSpawnCount() {
  MonitorLocker ml(&spawn_count_monitor_);
  spawn_count_++;
}

void Isolate::DecrementSpawnCount() {
  MonitorLocker ml(&spawn_count_monitor_);
  ASSERT(spawn_count_ > 0);
  spawn_count_--;
  ml.Notify();
}

void Isolate::WaitForOutstandingSpawns() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  MonitorLocker ml(&spawn_count_monitor_);
  while (spawn_count_ > 0) {
    ml.WaitWithSafepointCheck(thread);
  }
}

Monitor* IsolateGroup::threads_lock() const {
  return thread_registry_->threads_lock();
}

Thread* Isolate::ScheduleThread(bool is_mutator, bool bypass_safepoint) {
  // We are about to associate the thread with an isolate group and it would
  // not be possible to correctly track no_safepoint_scope_depth for the
  // thread in the constructor/destructor of MonitorLocker,
  // so we create a MonitorLocker object which does not do any
  // no_safepoint_scope_depth increments/decrements.
  MonitorLocker ml(group()->threads_lock(), false);

  // Check to make sure we don't already have a mutator thread.
  if (is_mutator && scheduled_mutator_thread_ != nullptr) {
    return nullptr;
  }

  // NOTE: We cannot just use `Dart::vm_isolate() == this` here, since during
  // VM startup it might not have been set at this point.
  const bool is_vm_isolate =
      Dart::vm_isolate() == nullptr || Dart::vm_isolate() == this;

  // We lazily create a [Thread] structure for the mutator thread, but we'll
  // reuse it until the death of the isolate.
  Thread* existing_mutator_thread = is_mutator ? mutator_thread_ : nullptr;

  // Schedule the thread into the isolate by associating a 'Thread' structure
  // with it (this is done while we are holding the thread registry lock).
  Thread* thread =
      group()->ScheduleThreadLocked(&ml, existing_mutator_thread, is_vm_isolate,
                                    is_mutator, bypass_safepoint);
  if (is_mutator) {
    ASSERT(mutator_thread_ == nullptr || mutator_thread_ == thread);
    mutator_thread_ = thread;
    scheduled_mutator_thread_ = thread;
  }
  thread->isolate_ = this;

  ASSERT(heap() != nullptr);
  thread->heap_ = heap();

  return thread;
}

void Isolate::UnscheduleThread(Thread* thread,
                               bool is_mutator,
                               bool bypass_safepoint) {
  // Disassociate the 'Thread' structure and unschedule the thread
  // from this isolate.
  // We are disassociating the thread from an isolate and it would
  // not be possible to correctly track no_safepoint_scope_depth for the
  // thread in the constructor/destructor of MonitorLocker,
  // so we create a MonitorLocker object which does not do any
  // no_safepoint_scope_depth increments/decrements.
  MonitorLocker ml(group()->threads_lock(), false);

  if (is_mutator) {
    if (thread->sticky_error() != Error::null()) {
      ASSERT(sticky_error_ == Error::null());
      sticky_error_ = thread->StealStickyError();
    }
    ASSERT(mutator_thread_ == thread);
    ASSERT(mutator_thread_ == scheduled_mutator_thread_);
    scheduled_mutator_thread_ = nullptr;
  }
  group()->UnscheduleThreadLocked(&ml, thread, is_mutator, bypass_safepoint);
}

static const char* NewConstChar(const char* chars) {
  size_t len = strlen(chars);
  char* mem = new char[len + 1];
  memmove(mem, chars, len + 1);
  return mem;
}

IsolateSpawnState::IsolateSpawnState(Dart_Port parent_port,
                                     Dart_Port origin_id,
                                     const char* script_url,
                                     const Function& func,
                                     SerializedObjectBuffer* message_buffer,
                                     const char* package_config,
                                     bool paused,
                                     bool errors_are_fatal,
                                     Dart_Port on_exit_port,
                                     Dart_Port on_error_port,
                                     const char* debug_name,
                                     IsolateGroup* isolate_group)
    : isolate_(nullptr),
      parent_port_(parent_port),
      origin_id_(origin_id),
      on_exit_port_(on_exit_port),
      on_error_port_(on_error_port),
      script_url_(script_url),
      package_config_(package_config),
      library_url_(nullptr),
      class_name_(nullptr),
      function_name_(nullptr),
      debug_name_(debug_name),
      isolate_group_(isolate_group),
      serialized_args_(nullptr),
      serialized_message_(message_buffer->StealMessage()),
      paused_(paused),
      errors_are_fatal_(errors_are_fatal) {
  const Class& cls = Class::Handle(func.Owner());
  const Library& lib = Library::Handle(cls.library());
  const String& lib_url = String::Handle(lib.url());
  library_url_ = NewConstChar(lib_url.ToCString());

  String& func_name = String::Handle();
  func_name = func.name();
  func_name = String::ScrubName(func_name);
  function_name_ = NewConstChar(func_name.ToCString());
  if (!cls.IsTopLevel()) {
    const String& class_name = String::Handle(cls.Name());
    class_name_ = NewConstChar(class_name.ToCString());
  }

  // Inherit flags from spawning isolate.
  Isolate::Current()->FlagsCopyTo(isolate_flags());
}

IsolateSpawnState::IsolateSpawnState(Dart_Port parent_port,
                                     const char* script_url,
                                     const char* package_config,
                                     SerializedObjectBuffer* args_buffer,
                                     SerializedObjectBuffer* message_buffer,
                                     bool paused,
                                     bool errors_are_fatal,
                                     Dart_Port on_exit_port,
                                     Dart_Port on_error_port,
                                     const char* debug_name,
                                     IsolateGroup* group)
    : isolate_(nullptr),
      parent_port_(parent_port),
      origin_id_(ILLEGAL_PORT),
      on_exit_port_(on_exit_port),
      on_error_port_(on_error_port),
      script_url_(script_url),
      package_config_(package_config),
      library_url_(nullptr),
      class_name_(nullptr),
      function_name_(nullptr),
      debug_name_(debug_name),
      isolate_group_(group),
      serialized_args_(args_buffer->StealMessage()),
      serialized_message_(message_buffer->StealMessage()),
      isolate_flags_(),
      paused_(paused),
      errors_are_fatal_(errors_are_fatal) {
  function_name_ = NewConstChar("main");

  // By default inherit flags from spawning isolate. These can be overridden
  // from the calling code.
  Isolate::Current()->FlagsCopyTo(isolate_flags());
}

IsolateSpawnState::~IsolateSpawnState() {
  delete[] script_url_;
  delete[] package_config_;
  delete[] library_url_;
  delete[] class_name_;
  delete[] function_name_;
  delete[] debug_name_;
}

RawObject* IsolateSpawnState::ResolveFunction() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  const String& func_name = String::Handle(zone, String::New(function_name()));

  if (library_url() == nullptr) {
    // Handle spawnUri lookup rules.
    // Check whether the root library defines a main function.
    const Library& lib =
        Library::Handle(zone, I->object_store()->root_library());
    Function& func = Function::Handle(zone, lib.LookupLocalFunction(func_name));
    if (func.IsNull()) {
      // Check whether main is reexported from the root library.
      const Object& obj = Object::Handle(zone, lib.LookupReExport(func_name));
      if (obj.IsFunction()) {
        func ^= obj.raw();
      }
    }
    if (func.IsNull()) {
      const String& msg = String::Handle(
          zone, String::NewFormatted(
                    "Unable to resolve function '%s' in script '%s'.",
                    function_name(), script_url()));
      return LanguageError::New(msg);
    }
    return func.raw();
  }

  // Lookup the to be spawned function for the Isolate.spawn implementation.
  // Resolve the library.
  const String& lib_url = String::Handle(zone, String::New(library_url()));
  const Library& lib =
      Library::Handle(zone, Library::LookupLibrary(thread, lib_url));
  if (lib.IsNull() || lib.IsError()) {
    const String& msg = String::Handle(
        zone,
        String::NewFormatted("Unable to find library '%s'.", library_url()));
    return LanguageError::New(msg);
  }

  // Resolve the function.
  if (class_name() == nullptr) {
    const Function& func =
        Function::Handle(zone, lib.LookupLocalFunction(func_name));
    if (func.IsNull()) {
      const String& msg = String::Handle(
          zone, String::NewFormatted(
                    "Unable to resolve function '%s' in library '%s'.",
                    function_name(), library_url()));
      return LanguageError::New(msg);
    }
    return func.raw();
  }

  const String& cls_name = String::Handle(zone, String::New(class_name()));
  const Class& cls = Class::Handle(zone, lib.LookupLocalClass(cls_name));
  if (cls.IsNull()) {
    const String& msg = String::Handle(
        zone, String::NewFormatted(
                  "Unable to resolve class '%s' in library '%s'.", class_name(),
                  (library_url() != nullptr ? library_url() : script_url())));
    return LanguageError::New(msg);
  }
  const Function& func =
      Function::Handle(zone, cls.LookupStaticFunctionAllowPrivate(func_name));
  if (func.IsNull()) {
    const String& msg = String::Handle(
        zone, String::NewFormatted(
                  "Unable to resolve static method '%s.%s' in library '%s'.",
                  class_name(), function_name(),
                  (library_url() != nullptr ? library_url() : script_url())));
    return LanguageError::New(msg);
  }
  return func.raw();
}

RawInstance* IsolateSpawnState::BuildArgs(Thread* thread) {
  return DeserializeMessage(thread, serialized_args_.get());
}

RawInstance* IsolateSpawnState::BuildMessage(Thread* thread) {
  return DeserializeMessage(thread, serialized_message_.get());
}

}  // namespace dart
