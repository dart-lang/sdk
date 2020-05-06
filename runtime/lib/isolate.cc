// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/unicode.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/hash_table.h"
#include "vm/lockers.h"
#include "vm/longjump.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/service.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(CapabilityImpl_factory, 0, 1) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  uint64_t id = isolate->random()->NextUInt64();
  return Capability::New(id);
}

DEFINE_NATIVE_ENTRY(CapabilityImpl_equals, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, recv, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, other, arguments->NativeArgAt(1));
  return (recv.Id() == other.Id()) ? Bool::True().raw() : Bool::False().raw();
}

DEFINE_NATIVE_ENTRY(CapabilityImpl_get_hashcode, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, cap, arguments->NativeArgAt(0));
  int64_t id = cap.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_factory, 0, 1) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  Dart_Port port_id = PortMap::CreatePort(isolate->message_handler());
  return ReceivePort::New(port_id, false /* not control port */);
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_id, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_sendport, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return port.send_port();
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_closeInternal, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  Dart_Port id = port.Id();
  PortMap::ClosePort(id);
  return Integer::New(id);
}

DEFINE_NATIVE_ENTRY(SendPortImpl_get_id, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(SendPortImpl_get_hashcode, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  int64_t id = port.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

DEFINE_NATIVE_ENTRY(SendPortImpl_sendInternal_, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  // TODO(iposva): Allow for arbitrary messages to be sent.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

  const Dart_Port destination_port_id = port.Id();
  const bool can_send_any_object = isolate->origin_id() == port.origin_id();

  if (ApiObjectConverter::CanConvert(obj.raw())) {
    PortMap::PostMessage(
        Message::New(destination_port_id, obj.raw(), Message::kNormalPriority));
  } else {
    MessageWriter writer(can_send_any_object);
    // TODO(turnidge): Throw an exception when the return value is false?
    PortMap::PostMessage(writer.WriteMessage(obj, destination_port_id,
                                             Message::kNormalPriority));
  }
  return Object::null();
}

class ObjectPtrSetTraitsLayout {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "RawObjectPtrSetTraits"; }

  static bool IsMatch(const ObjectPtr a, const ObjectPtr b) { return a == b; }

  static uword Hash(const ObjectPtr obj) { return static_cast<uword>(obj); }
};

static ObjectPtr ValidateMessageObject(Zone* zone,
                                       Isolate* isolate,
                                       const Object& obj) {
  TIMELINE_DURATION(Thread::Current(), Isolate, "ValidateMessageObject");

  class SendMessageValidator : public ObjectPointerVisitor {
   public:
    SendMessageValidator(IsolateGroup* isolate_group,
                         WeakTable* visited,
                         MallocGrowableArray<ObjectPtr>* const working_set)
        : ObjectPointerVisitor(isolate_group),
          visited_(visited),
          working_set_(working_set) {}

   private:
    void VisitPointers(ObjectPtr* from, ObjectPtr* to) {
      for (ObjectPtr* raw = from; raw <= to; raw++) {
        if (!(*raw)->IsHeapObject() || (*raw)->ptr()->IsCanonical()) {
          continue;
        }
        if (visited_->GetValueExclusive(*raw) == 1) {
          continue;
        }
        visited_->SetValueExclusive(*raw, 1);
        working_set_->Add(*raw);
      }
    }

    WeakTable* visited_;
    MallocGrowableArray<ObjectPtr>* const working_set_;
  };
  if (!obj.raw()->IsHeapObject() || obj.raw()->ptr()->IsCanonical()) {
    return obj.raw();
  }
  ClassTable* class_table = isolate->class_table();

  Class& klass = Class::Handle(zone);
  Closure& closure = Closure::Handle(zone);

  MallocGrowableArray<ObjectPtr> working_set;
  std::unique_ptr<WeakTable> visited(new WeakTable());

  NoSafepointScope no_safepoint;
  SendMessageValidator visitor(isolate->group(), visited.get(), &working_set);

  visited->SetValueExclusive(obj.raw(), 1);
  working_set.Add(obj.raw());

  while (!working_set.is_empty()) {
    ObjectPtr raw = working_set.RemoveLast();

    if (visited->GetValueExclusive(raw) > 0) {
      continue;
    }
    visited->SetValueExclusive(raw, 1);

    const intptr_t cid = raw->GetClassId();
    switch (cid) {
      // List below matches the one in raw_object_snapshot.cc
#define MESSAGE_SNAPSHOT_ILLEGAL(type)                                         \
  case k##type##Cid:                                                           \
    return Exceptions::CreateUnhandledException(                               \
        zone, Exceptions::kArgumentValue,                                      \
        "Illegal argument in isolate message : (object is a " #type ")");

      MESSAGE_SNAPSHOT_ILLEGAL(DynamicLibrary);
      MESSAGE_SNAPSHOT_ILLEGAL(MirrorReference);
      MESSAGE_SNAPSHOT_ILLEGAL(Pointer);
      MESSAGE_SNAPSHOT_ILLEGAL(ReceivePort);
      MESSAGE_SNAPSHOT_ILLEGAL(RegExp);
      MESSAGE_SNAPSHOT_ILLEGAL(StackTrace);
      MESSAGE_SNAPSHOT_ILLEGAL(UserTag);

      case kClosureCid: {
        closure = Closure::RawCast(raw);
        FunctionPtr func = closure.function();
        // We only allow closure of top level methods or static functions in a
        // class to be sent in isolate messages.
        if (!Function::IsImplicitStaticClosureFunction(func)) {
          return Exceptions::CreateUnhandledException(
              zone, Exceptions::kArgumentValue, "Closures are not allowed");
        }
        break;
      }
      default:
        if (cid >= kNumPredefinedCids) {
          klass = class_table->At(cid);
          if (klass.num_native_fields() != 0) {
            return Exceptions::CreateUnhandledException(
                zone, Exceptions::kArgumentValue,
                "Objects that extend NativeWrapper are not allowed");
          }
        }
    }
    raw->ptr()->VisitPointers(&visitor);
  }
  isolate->set_forward_table_new(nullptr);
  return obj.raw();
}

DEFINE_NATIVE_ENTRY(SendPortImpl_sendAndExitInternal_, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  if (!PortMap::IsReceiverInThisIsolateGroup(port.Id(), isolate->group())) {
    const auto& error =
        String::Handle(String::New("sendAndExit is only supported across "
                                   "isolates spawned via spawnFunction."));
    Exceptions::ThrowArgumentError(error);
    UNREACHABLE();
  }

  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

  Object& validated_result = Object::Handle(zone);
  Object& msg_obj = Object::Handle(zone, obj.raw());
  validated_result = ValidateMessageObject(zone, isolate, msg_obj);
  if (validated_result.IsUnhandledException()) {
    Exceptions::PropagateError(Error::Cast(validated_result));
    UNREACHABLE();
  }
  PersistentHandle* handle =
      isolate->group()->api_state()->AllocatePersistentHandle();
  handle->set_raw(msg_obj);
  isolate->bequeath(std::unique_ptr<Bequest>(new Bequest(handle, port.Id())));
  // TODO(aam): Ensure there are no dart api calls after this point as we want
  // to ensure that validated message won't get tampered with.
  Isolate::KillIfExists(isolate, Isolate::LibMsgId::kKillMsg);
  // Drain interrupts before running so any IMMEDIATE operations on the current
  // isolate happen synchronously.
  const Error& error = Error::Handle(thread->HandleInterrupts());
  RELEASE_ASSERT(error.IsUnwindError());
  Exceptions::PropagateError(error);
  // We will never execute dart code again in this isolate.
  return Object::null();
}

static void ThrowIsolateSpawnException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}

class SpawnIsolateTask : public ThreadPool::Task {
 public:
  SpawnIsolateTask(Isolate* parent_isolate,
                   std::unique_ptr<IsolateSpawnState> state,
                   bool in_new_isolate_group)
      : parent_isolate_(parent_isolate),
        state_(std::move(state)),
        in_new_isolate_group_(in_new_isolate_group) {
    parent_isolate->IncrementSpawnCount();
  }

  ~SpawnIsolateTask() override {
    if (parent_isolate_ != nullptr) {
      parent_isolate_->DecrementSpawnCount();
    }
  }

  void Run() override {
    auto group = state_->isolate_group();

    // The create isolate group call back is mandatory.  If not provided we
    // cannot spawn isolates.
    Dart_IsolateGroupCreateCallback create_group_callback =
        Isolate::CreateGroupCallback();
    if (create_group_callback == nullptr) {
      FailedSpawn("Isolate spawn is not supported by this Dart embedder\n");
      return;
    }

    // The initialize callback is optional atm, we fall back to creating isolate
    // groups if it was not provided.
    Dart_InitializeIsolateCallback initialize_callback =
        Isolate::InitializeCallback();

    const char* name = (state_->debug_name() == NULL) ? state_->function_name()
                                                      : state_->debug_name();
    ASSERT(name != NULL);

    // Create a new isolate.
    char* error = nullptr;
    Isolate* isolate = nullptr;
    if (!FLAG_enable_isolate_groups || group == nullptr ||
        initialize_callback == nullptr || in_new_isolate_group_) {
      // Make a copy of the state's isolate flags and hand it to the callback.
      Dart_IsolateFlags api_flags = *(state_->isolate_flags());
      isolate = reinterpret_cast<Isolate*>((create_group_callback)(
          state_->script_url(), name, nullptr, state_->package_config(),
          &api_flags, parent_isolate_->init_callback_data(), &error));
      parent_isolate_->DecrementSpawnCount();
      parent_isolate_ = nullptr;
    } else {
      if (initialize_callback == nullptr) {
        FailedSpawn("Isolate spawn is not supported by this embedder.");
        return;
      }

#if defined(DART_PRECOMPILED_RUNTIME)
      isolate = CreateWithinExistingIsolateGroupAOT(group, name, &error);
#else
      isolate = CreateWithinExistingIsolateGroup(group, name, &error);
#endif
      parent_isolate_->DecrementSpawnCount();
      parent_isolate_ = nullptr;
      if (isolate == nullptr) {
        FailedSpawn(error);
        free(error);
        return;
      }

      void* child_isolate_data = nullptr;
      bool success = initialize_callback(&child_isolate_data, &error);
      isolate->set_init_callback_data(child_isolate_data);
      if (!success) {
        Dart_ShutdownIsolate();
        FailedSpawn(error);
        free(error);
        return;
      }
      Dart_ExitIsolate();
    }

    if (isolate == nullptr) {
      FailedSpawn(error);
      free(error);
      return;
    }

    if (state_->origin_id() != ILLEGAL_PORT) {
      // For isolates spawned using spawnFunction we set the origin_id
      // to the origin_id of the parent isolate.
      isolate->set_origin_id(state_->origin_id());
    }
    MutexLocker ml(isolate->mutex());
    state_->set_isolate(isolate);
    isolate->set_spawn_state(std::move(state_));
    if (isolate->is_runnable()) {
      isolate->Run();
    }
  }

 private:
  void FailedSpawn(const char* error) {
    ReportError(error != nullptr
                    ? error
                    : "Unknown error occured during Isolate spawning.");
    state_ = nullptr;
  }

  void ReportError(const char* error) {
    Dart_CObject error_cobj;
    error_cobj.type = Dart_CObject_kString;
    error_cobj.value.as_string = const_cast<char*>(error);
    if (!Dart_PostCObject(state_->parent_port(), &error_cobj)) {
      // Perhaps the parent isolate died or closed the port before we
      // could report the error.  Ignore.
    }
  }

  Isolate* parent_isolate_;
  std::unique_ptr<IsolateSpawnState> state_;
  bool in_new_isolate_group_;

  DISALLOW_COPY_AND_ASSIGN(SpawnIsolateTask);
};

static const char* String2UTF8(const String& str) {
  intptr_t len = Utf8::Length(str);
  char* result = new char[len + 1];
  str.ToUTF8(reinterpret_cast<uint8_t*>(result), len);
  result[len] = 0;

  return result;
}

DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 0, 11) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, script_uri, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(6));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(7));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(8));
  GET_NATIVE_ARGUMENT(Bool, newIsolateGroup, arguments->NativeArgAt(9));
  GET_NATIVE_ARGUMENT(String, debugName, arguments->NativeArgAt(10));

  if (closure.IsClosure()) {
    Function& func = Function::Handle();
    func = Closure::Cast(closure).function();
    if (func.IsImplicitClosureFunction() && func.is_static()) {
#if defined(DEBUG)
      Context& ctx = Context::Handle();
      ctx = Closure::Cast(closure).context();
      ASSERT(ctx.IsNull());
#endif
      // Get the parent function so that we get the right function name.
      func = func.parent_function();

      bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
      Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
      Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

      // We first try to serialize the message.  In case the message is not
      // serializable this will throw an exception.
      SerializedObjectBuffer message_buffer;
      {
        MessageWriter writer(/* can_send_any_object = */ true);
        message_buffer.set_message(writer.WriteMessage(
            message, ILLEGAL_PORT, Message::kNormalPriority));
      }

      const char* utf8_package_config =
          packageConfig.IsNull() ? NULL : String2UTF8(packageConfig);
      const char* utf8_debug_name =
          debugName.IsNull() ? NULL : String2UTF8(debugName);

      std::unique_ptr<IsolateSpawnState> state(new IsolateSpawnState(
          port.Id(), isolate->origin_id(), String2UTF8(script_uri), func,
          &message_buffer, utf8_package_config, paused.value(), fatal_errors,
          on_exit_port, on_error_port, utf8_debug_name, isolate->group()));

      // Since this is a call to Isolate.spawn, copy the parent isolate's code.
      state->isolate_flags()->copy_parent_code = true;

      const bool in_new_isolate_group = newIsolateGroup.value();
      isolate->group()->thread_pool()->Run<SpawnIsolateTask>(
          isolate, std::move(state), in_new_isolate_group);
      return Object::null();
    }
  }
  const String& msg = String::Handle(String::New(
      "Isolate.spawn expects to be passed a static or top-level function"));
  Exceptions::ThrowArgumentError(msg);
  return Object::null();
}

static const char* CanonicalizeUri(Thread* thread,
                                   const Library& library,
                                   const String& uri,
                                   char** error) {
  const char* result = NULL;
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  if (isolate->HasTagHandler()) {
    const Object& obj = Object::Handle(
        isolate->CallTagHandler(Dart_kCanonicalizeUrl, library, uri));
    if (obj.IsString()) {
      result = String2UTF8(String::Cast(obj));
    } else if (obj.IsError()) {
      Error& error_obj = Error::Handle();
      error_obj ^= obj.raw();
      *error = zone->PrintToString("Unable to canonicalize uri '%s': %s",
                                   uri.ToCString(), error_obj.ToErrorCString());
    } else {
      *error = zone->PrintToString(
          "Unable to canonicalize uri '%s': "
          "library tag handler returned wrong type",
          uri.ToCString());
    }
  } else {
    *error = zone->PrintToString(
        "Unable to canonicalize uri '%s': no library tag handler found.",
        uri.ToCString());
  }
  return result;
}

DEFINE_NATIVE_ENTRY(Isolate_spawnUri, 0, 12) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, uri, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, args, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(6));
  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(7));
  GET_NATIVE_ARGUMENT(Bool, checked, arguments->NativeArgAt(8));
  GET_NATIVE_ARGUMENT(Array, environment, arguments->NativeArgAt(9));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(10));
  GET_NATIVE_ARGUMENT(String, debugName, arguments->NativeArgAt(11));

  if (Dart::vm_snapshot_kind() == Snapshot::kFullAOT) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(
        0,
        String::Handle(String::New(
            "Isolate.spawnUri is not supported when using AOT compilation")));
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
    UNREACHABLE();
  }

  bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
  Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
  Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

  // We first try to serialize the arguments and the message.  In case the
  // arguments or the message are not serializable this will throw an exception.
  SerializedObjectBuffer arguments_buffer;
  SerializedObjectBuffer message_buffer;
  {
    MessageWriter writer(/* can_send_any_object = */ false);
    arguments_buffer.set_message(
        writer.WriteMessage(args, ILLEGAL_PORT, Message::kNormalPriority));
  }
  {
    MessageWriter writer(/* can_send_any_object = */ false);
    message_buffer.set_message(
        writer.WriteMessage(message, ILLEGAL_PORT, Message::kNormalPriority));
  }

  // Canonicalize the uri with respect to the current isolate.
  const Library& root_lib =
      Library::Handle(isolate->object_store()->root_library());
  char* error = NULL;
  const char* canonical_uri = CanonicalizeUri(thread, root_lib, uri, &error);
  if (canonical_uri == NULL) {
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  const char* utf8_package_config =
      packageConfig.IsNull() ? NULL : String2UTF8(packageConfig);
  const char* utf8_debug_name =
      debugName.IsNull() ? NULL : String2UTF8(debugName);

  std::unique_ptr<IsolateSpawnState> state(new IsolateSpawnState(
      port.Id(), canonical_uri, utf8_package_config, &arguments_buffer,
      &message_buffer, paused.value(), fatal_errors, on_exit_port,
      on_error_port, utf8_debug_name, /*group=*/nullptr));

  // If we were passed a value then override the default flags state for
  // checked mode.
  if (!checked.IsNull()) {
    Dart_IsolateFlags* flags = state->isolate_flags();
    flags->enable_asserts = checked.value();
  }

  // Since this is a call to Isolate.spawnUri, don't copy the parent's code.
  state->isolate_flags()->copy_parent_code = false;

  const bool in_new_isolate_group = false;
  isolate->group()->thread_pool()->Run<SpawnIsolateTask>(
      isolate, std::move(state), in_new_isolate_group);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Isolate_getDebugName, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  auto name = Isolate::LookupIsolateNameByPort(port.Id());
  if (name == nullptr) {
    return String::null();
  }
  return String::New(name.get());
}

DEFINE_NATIVE_ENTRY(Isolate_getPortAndCapabilitiesOfCurrentIsolate, 0, 0) {
  const Array& result = Array::Handle(Array::New(3));
  result.SetAt(0, SendPort::Handle(SendPort::New(isolate->main_port())));
  result.SetAt(
      1, Capability::Handle(Capability::New(isolate->pause_capability())));
  result.SetAt(
      2, Capability::Handle(Capability::New(isolate->terminate_capability())));
  return result.raw();
}

DEFINE_NATIVE_ENTRY(Isolate_getCurrentRootUriStr, 0, 0) {
  const Library& root_lib =
      Library::Handle(zone, isolate->object_store()->root_library());
  return root_lib.url();
}

DEFINE_NATIVE_ENTRY(Isolate_sendOOB, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, msg, arguments->NativeArgAt(1));

  // Make sure to route this request to the isolate library OOB mesage handler.
  msg.SetAt(0, Smi::Handle(Smi::New(Message::kIsolateLibOOBMsg)));

  MessageWriter writer(false);
  PortMap::PostMessage(
      writer.WriteMessage(msg, port.Id(), Message::kOOBPriority));

  // Drain interrupts before running so any IMMEDIATE operations on the current
  // isolate happen synchronously.
  const Error& error = Error::Handle(thread->HandleInterrupts());
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  return Object::null();
}

static void ExternalTypedDataFinalizer(void* isolate_callback_data,
                                       Dart_WeakPersistentHandle handle,
                                       void* peer) {
  free(peer);
}

static intptr_t GetTypedDataSizeOrThrow(const Instance& instance) {
  // From the Dart side we are guaranteed that the type of [instance] is a
  // subtype of TypedData.
  if (instance.IsTypedDataBase()) {
    return TypedDataBase::Cast(instance).LengthInBytes();
  }

  // This can happen if [instance] is `null` or an instance of a 3rd party class
  // which implements [TypedData].
  Exceptions::ThrowArgumentError(instance);
}

DEFINE_NATIVE_ENTRY(TransferableTypedData_factory, 0, 2) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());

  GET_NON_NULL_NATIVE_ARGUMENT(Instance, array_instance,
                               arguments->NativeArgAt(1));

  Array& array = Array::Handle();
  intptr_t array_length;
  if (array_instance.IsGrowableObjectArray()) {
    const auto& growable_array = GrowableObjectArray::Cast(array_instance);
    array ^= growable_array.data();
    array_length = growable_array.Length();
  } else if (array_instance.IsArray()) {
    array ^= Array::Cast(array_instance).raw();
    array_length = array.Length();
  } else {
    Exceptions::ThrowArgumentError(array_instance);
    UNREACHABLE();
  }
  Instance& instance = Instance::Handle();
  uint64_t total_bytes = 0;
  const uint64_t kMaxBytes = TypedData::MaxElements(kTypedDataUint8ArrayCid);
  for (intptr_t i = 0; i < array_length; i++) {
    instance ^= array.At(i);
    total_bytes += static_cast<uintptr_t>(GetTypedDataSizeOrThrow(instance));
    if (total_bytes > kMaxBytes) {
      const Array& error_args = Array::Handle(Array::New(3));
      error_args.SetAt(0, array);
      error_args.SetAt(1, String::Handle(String::New("data")));
      error_args.SetAt(
          2, String::Handle(String::NewFormatted(
                 "Aggregated list exceeds max size %" Pu64 "", kMaxBytes)));
      Exceptions::ThrowByType(Exceptions::kArgumentValue, error_args);
      UNREACHABLE();
    }
  }

  uint8_t* data = reinterpret_cast<uint8_t*>(malloc(total_bytes));
  if (data == nullptr) {
    const Instance& exception =
        Instance::Handle(thread->isolate()->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }
  intptr_t offset = 0;
  for (intptr_t i = 0; i < array_length; i++) {
    instance ^= array.At(i);

    {
      NoSafepointScope no_safepoint;
      const auto& typed_data = TypedDataBase::Cast(instance);
      const intptr_t length_in_bytes = typed_data.LengthInBytes();

      void* source = typed_data.DataAddr(0);
      // The memory does not overlap.
      memcpy(data + offset, source, length_in_bytes);  // NOLINT
      offset += length_in_bytes;
    }
  }
  ASSERT(static_cast<uintptr_t>(offset) == total_bytes);
  return TransferableTypedData::New(data, total_bytes);
}

DEFINE_NATIVE_ENTRY(TransferableTypedData_materialize, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TransferableTypedData, t,
                               arguments->NativeArgAt(0));

  void* peer;
  {
    NoSafepointScope no_safepoint;
    peer = thread->heap()->GetPeer(t.raw());
    // Assume that object's Peer is only used to track transferrability state.
    ASSERT(peer != nullptr);
  }

  TransferableTypedDataPeer* tpeer =
      reinterpret_cast<TransferableTypedDataPeer*>(peer);
  const intptr_t length = tpeer->length();
  uint8_t* data = tpeer->data();
  if (data == nullptr) {
    const auto& error = String::Handle(String::New(
        "Attempt to materialize object that was transferred already."));
    Exceptions::ThrowArgumentError(error);
    UNREACHABLE();
  }
  tpeer->ClearData();

  const ExternalTypedData& typed_data = ExternalTypedData::Handle(
      ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data, length,
                             thread->heap()->SpaceForExternal(length)));
  FinalizablePersistentHandle::New(thread->isolate(), typed_data,
                                   /* peer= */ data,
                                   &ExternalTypedDataFinalizer, length);
  return typed_data.raw();
}

}  // namespace dart
