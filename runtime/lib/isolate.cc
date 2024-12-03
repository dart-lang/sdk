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
#include "vm/message_snapshot.h"
#include "vm/object.h"
#include "vm/object_graph_copy.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/service.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Capability_factory, 0, 1) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  // Keep capability IDs less than 2^53 so web clients of the service
  // protocol can process it properly.
  //
  // See https://github.com/dart-lang/sdk/issues/53081.
  uint64_t id = isolate->random()->NextJSInt();
  return Capability::New(id);
}

DEFINE_NATIVE_ENTRY(Capability_equals, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, recv, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, other, arguments->NativeArgAt(1));
  return (recv.Id() == other.Id()) ? Bool::True().ptr() : Bool::False().ptr();
}

DEFINE_NATIVE_ENTRY(Capability_get_hashcode, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, cap, arguments->NativeArgAt(0));
  int64_t id = cap.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

DEFINE_NATIVE_ENTRY(RawReceivePort_factory, 0, 2) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(String, debug_name, arguments->NativeArgAt(1));
  return isolate->CreateReceivePort(debug_name);
}

DEFINE_NATIVE_ENTRY(RawReceivePort_get_id, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(RawReceivePort_closeInternal, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  Dart_Port id = port.Id();
  isolate->CloseReceivePort(port);
  return Integer::New(id);
}

DEFINE_NATIVE_ENTRY(RawReceivePort_setActive, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, active, arguments->NativeArgAt(1));
  isolate->SetReceivePortKeepAliveState(port, active.value());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(RawReceivePort_getActive, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return Bool::Get(port.keep_isolate_alive()).ptr();
}

DEFINE_NATIVE_ENTRY(SendPort_get_id, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(SendPort_get_hashcode, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  int64_t id = port.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

static bool InSameGroup(Isolate* sender, const SendPort& receiver) {
  // Cannot determine whether sender is in same group (yet).
  if (sender->origin_id() == ILLEGAL_PORT) return false;

  // Only allow arbitrary messages between isolates of the same IG.
  return sender->origin_id() == receiver.origin_id();
}

DEFINE_NATIVE_ENTRY(SendPort_sendInternal_, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

  const Dart_Port destination_port_id = port.Id();
  const bool same_group = InSameGroup(isolate, port);
#if defined(DEBUG)
  if (same_group) {
    ASSERT(PortMap::IsReceiverInThisIsolateGroupOrClosed(destination_port_id,
                                                         isolate->group()));
  }
#endif

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(WriteMessage(same_group, obj, destination_port_id,
                                    Message::kNormalPriority));
  return Object::null();
}

class UntaggedObjectPtrSetTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "UntaggedObjectPtrSetTraits"; }

  static bool IsMatch(const ObjectPtr a, const ObjectPtr b) { return a == b; }

  static uword Hash(const ObjectPtr obj) { return static_cast<uword>(obj); }
};

#if defined(HASH_IN_OBJECT_HEADER)
// Written to avoid O(elements) pauses that block safepoints. Compare
// object_graph_copy.cc's IdentityMap, which implements something similar
// but with enough differents to make shared code less readable.
class WorkSet {
 public:
  explicit WorkSet(Thread* thread)
      : thread_(thread), list_(GrowableObjectArray::Handle()) {
    hash_table_used_ = 0;
    hash_table_capacity_ = 32;
    hash_table_ = reinterpret_cast<uint32_t*>(
        malloc(hash_table_capacity_ * sizeof(uint32_t)));
    memset(hash_table_, 0, hash_table_capacity_ * sizeof(uint32_t));

    list_ = GrowableObjectArray::New(256);
    list_.Add(Object::null_object());  // Id 0 is sentinel.
    cursor_ = 1;
  }
  ~WorkSet() { free(hash_table_); }

  void Push(const Object& obj) {
    intptr_t mask = hash_table_capacity_ - 1;
    intptr_t probe = GetHeaderHash(obj.ptr()) & mask;
    for (;;) {
      intptr_t index = hash_table_[probe];
      if (index == 0) {
        intptr_t id = list_.Length();
        list_.Add(obj);
        hash_table_[probe] = id;
        break;
      }
      if (list_.At(index) == obj.ptr()) {
        break;  // Already present.
      }
      probe = (probe + 1) & mask;
    }
    hash_table_used_++;
    if (hash_table_used_ * 2 > hash_table_capacity_) {
      Rehash(hash_table_capacity_ * 2);
    }
  }

  bool Pop(Object* obj) {
    if (cursor_ < list_.Length()) {
      *obj = list_.At(cursor_);
      cursor_++;
      return true;
    }
    return false;
  }

 private:
  DART_FORCE_INLINE
  uint32_t GetHeaderHash(ObjectPtr object) {
    uint32_t hash = Object::GetCachedHash(object);
    if (hash == 0) {
      switch (object->GetClassIdOfHeapObject()) {
        case kMintCid:
          hash = Mint::Value(static_cast<MintPtr>(object));
          // Don't write back: doesn't agree with dart:core's identityHash.
          break;
        case kDoubleCid:
          hash =
              bit_cast<uint64_t>(Double::Value(static_cast<DoublePtr>(object)));
          // Don't write back: doesn't agree with dart:core's identityHash.
          break;
        case kOneByteStringCid:
        case kTwoByteStringCid:
          hash = String::Hash(static_cast<StringPtr>(object));
          hash = Object::SetCachedHashIfNotSet(object, hash);
          break;
        default:
          do {
            hash = thread_->random()->NextUInt32();
          } while (hash == 0 || !Smi::IsValid(hash));
          hash = Object::SetCachedHashIfNotSet(object, hash);
          break;
      }
    }
    return hash;
  }

  void Rehash(intptr_t new_capacity) {
    hash_table_capacity_ = new_capacity;
    hash_table_used_ = 0;
    free(hash_table_);
    hash_table_ = reinterpret_cast<uint32_t*>(
        malloc(hash_table_capacity_ * sizeof(uint32_t)));
    for (intptr_t i = 0; i < hash_table_capacity_; i++) {
      hash_table_[i] = 0;
      if (((i + 1) % kSlotsPerInterruptCheck) == 0) {
        thread_->CheckForSafepoint();
      }
    }
    for (intptr_t id = 1; id < list_.Length(); id++) {
      ObjectPtr obj = list_.At(id);
      intptr_t mask = hash_table_capacity_ - 1;
      intptr_t probe = GetHeaderHash(obj) & mask;
      for (;;) {
        if (hash_table_[probe] == 0) {
          hash_table_[probe] = id;
          hash_table_used_++;
          break;
        }
        probe = (probe + 1) & mask;
      }
      if (((id + 1) % kSlotsPerInterruptCheck) == 0) {
        thread_->CheckForSafepoint();
      }
    }
  }

  Thread* thread_;
  uint32_t* hash_table_;
  uint32_t hash_table_capacity_;
  uint32_t hash_table_used_;
  GrowableObjectArray& list_;
  intptr_t cursor_;
};
#else   // defined(HASH_IN_OBJECT_HEADER)
class WorkSet {
 public:
  explicit WorkSet(Thread* thread)
      : isolate_(thread->isolate()), list_(GrowableObjectArray::Handle()) {
    isolate_->set_forward_table_new(new WeakTable());
    isolate_->set_forward_table_old(new WeakTable());
    list_ = GrowableObjectArray::New(256);
    cursor_ = 0;
  }
  ~WorkSet() {
    isolate_->set_forward_table_new(nullptr);
    isolate_->set_forward_table_old(nullptr);
  }

  void Push(const Object& obj) {
    ASSERT(WeakTable::kNoValue == 0);
    if (GetObjectId(obj.ptr()) == 0) {
      SetObjectId(obj.ptr(), 1);
      list_.Add(obj);
    }
  }

  bool Pop(Object* obj) {
    if (cursor_ < list_.Length()) {
      *obj = list_.At(cursor_);
      cursor_++;
      return true;
    }
    return false;
  }

 private:
  DART_FORCE_INLINE
  intptr_t GetObjectId(ObjectPtr object) {
    if (object->IsNewObject()) {
      return isolate_->forward_table_new()->GetValueExclusive(object);
    } else {
      return isolate_->forward_table_old()->GetValueExclusive(object);
    }
  }

  DART_FORCE_INLINE
  void SetObjectId(ObjectPtr object, intptr_t id) {
    if (object->IsNewObject()) {
      isolate_->forward_table_new()->SetValueExclusive(object, id);
    } else {
      isolate_->forward_table_old()->SetValueExclusive(object, id);
    }
  }

  Isolate* isolate_;
  GrowableObjectArray& list_;
  intptr_t cursor_;
};
#endif  // defined(HASH_IN_OBJECT_HEADER)

class MessageValidator : private WorkSet {
 public:
  explicit MessageValidator(Thread* thread)
      : WorkSet(thread),
        value_(PassiveObject::Handle()),
        class_table_(thread->isolate()->group()->class_table()) {}

  ObjectPtr Validate(Thread* thread, const Object& root) {
    TIMELINE_DURATION(thread, Isolate, "ValidateMessageObject");
    Visit(root.ptr());
    Object& current = Object::Handle();
    Class& klass = Class::Handle();
    while (Pop(&current)) {
      const intptr_t cid = current.GetClassId();
      switch (cid) {
        case kArrayCid:
        case kImmutableArrayCid:
          VisitArrayPointers(thread, Array::Cast(current));
          break;
        case kClosureCid:
          VisitClosurePointers(Closure::Cast(current));
          break;
        case kContextCid:
          VisitContextPointers(Context::Cast(current));
          break;
        case kGrowableObjectArrayCid:
          VisitGrowableObjectArrayPointers(GrowableObjectArray::Cast(current));
          break;
        case kSetCid:
        case kConstSetCid:
        case kMapCid:
        case kConstMapCid:
          VisitLinkedHashBasePointers(LinkedHashBase::Cast(current));
          break;
        case kRecordCid:
          VisitRecordPointers(Record::Cast(current));
          break;
        case kWeakPropertyCid:
          VisitWeakPropertyPointers(WeakProperty::Cast(current));
          break;
        case kWeakReferenceCid:
          VisitWeakReferencePointers(WeakReference::Cast(current));
          break;
#define MESSAGE_SNAPSHOT_ILLEGAL(type)                                         \
  case k##type##Cid:                                                           \
    return Error(current, "is a " #type, root);
          MESSAGE_SNAPSHOT_ILLEGAL(DynamicLibrary)
          // TODO(http://dartbug.com/47777): Send and exit support: remove this.
          MESSAGE_SNAPSHOT_ILLEGAL(Finalizer)
          MESSAGE_SNAPSHOT_ILLEGAL(NativeFinalizer)
          MESSAGE_SNAPSHOT_ILLEGAL(MirrorReference)
          MESSAGE_SNAPSHOT_ILLEGAL(Pointer)
          MESSAGE_SNAPSHOT_ILLEGAL(ReceivePort)
          MESSAGE_SNAPSHOT_ILLEGAL(UserTag)
          MESSAGE_SNAPSHOT_ILLEGAL(SuspendState)
        default:
          klass = class_table_->At(cid);
          if (klass.is_isolate_unsendable()) {
            return Error(
                current,
                "is unsendable object (see restrictions listed at"
                "`SendPort.send()` documentation for more information)",
                root);
          }
          VisitInstancePointers(Instance::Cast(current), cid);
      }

      thread->CheckForSafepoint();
    }

    return root.ptr();
  }

 private:
  void VisitArrayPointers(Thread* thread, const Array& array) {
    for (intptr_t i = 0, n = array.Length(); i < n; i++) {
      Visit(array.At(i));
      if (((i + 1) % kSlotsPerInterruptCheck) == 0) {
        thread->CheckForSafepoint();
      }
    }
  }

  void VisitGrowableObjectArrayPointers(const GrowableObjectArray& list) {
    Visit(list.data());
  }

  void VisitRecordPointers(const Record& record) {
    for (intptr_t i = 0, n = record.num_fields(); i < n; i++) {
      Visit(record.FieldAt(i));
    }
  }

  void VisitContextPointers(const Context& context) {
    Visit(context.parent());
    for (intptr_t i = 0, n = context.num_variables(); i < n; i++) {
      Visit(context.At(i));
    }
  }

  void VisitLinkedHashBasePointers(const LinkedHashBase& hash) {
    Visit(hash.data());
  }

  void VisitClosurePointers(const Closure& closure) {
    Visit(closure.RawContext());
  }

  void VisitWeakPropertyPointers(const WeakProperty& weak) {
    Visit(weak.key());
    Visit(weak.value());
  }

  void VisitWeakReferencePointers(const WeakReference& weak) {
    Visit(weak.target());
  }

  void VisitInstancePointers(const Instance& instance, intptr_t cid) {
    ASSERT(cid == kInstanceCid || cid >= kNumPredefinedCids);

    const auto bitmap = class_table_->GetUnboxedFieldsMapAt(cid);

    intptr_t size = instance.ptr()->untag()->HeapSize();
    uword heap_base = instance.ptr()->heap_base();
    intptr_t offset = kWordSize;
    intptr_t bit = offset >> kCompressedWordSizeLog2;
    for (; offset < size; offset += kCompressedWordSize) {
      if (!bitmap.Get(bit++)) {
        Visit(reinterpret_cast<CompressedObjectPtr*>(
                  reinterpret_cast<uword>(instance.ptr()->untag()) + offset)
                  ->Decompress(heap_base));
      }
    }
  }

  void Visit(ObjectPtr obj) {
    if (!obj->IsHeapObject() || obj->untag()->IsCanonical() ||
        obj->untag()->IsImmutable()) {
      return;
    }
    switch (obj->untag()->GetClassId()) {
      case kTransferableTypedDataCid:
#define CASE(clazz)                                                            \
  case kTypedData##clazz##Cid:                                                 \
  case kTypedData##clazz##ViewCid:                                             \
  case kExternalTypedData##clazz##Cid:                                         \
  case kUnmodifiableTypedData##clazz##ViewCid:
        CLASS_LIST_TYPED_DATA(CASE)
#undef CASE
      case kByteDataViewCid:
      case kUnmodifiableByteDataViewCid:
      case kByteBufferCid:
        return;
    }
    value_ = obj;
    Push(value_);
  }

  ObjectPtr Error(const Object& illegal_object,
                  const char* exception_message,
                  const Object& root) {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    Zone* zone = thread->zone();
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, illegal_object);
    args.SetAt(2, String::Handle(
                      zone, String::NewFormatted(
                                "%s%s",
                                FindRetainingPath(
                                    zone, isolate, root, illegal_object,
                                    TraversalRules::kInternalToIsolateGroup),
                                exception_message)));
    const Object& exception = Object::Handle(
        zone, Exceptions::Create(Exceptions::kArgumentValue, args));
    return UnhandledException::New(Instance::Cast(exception),
                                   StackTrace::Handle(zone));
  }

 private:
  PassiveObject& value_;
  ClassTable* class_table_;
};

// TODO(http://dartbug.com/47777): Add support for Finalizers.
DEFINE_NATIVE_ENTRY(Isolate_exit_, 0, 2) {
  GET_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  if (!port.IsNull()) {
    GET_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

    const bool same_group = InSameGroup(isolate, port);
#if defined(DEBUG)
    if (same_group) {
      ASSERT(PortMap::IsReceiverInThisIsolateGroupOrClosed(port.Id(),
                                                           isolate->group()));
    }
#endif
    if (!same_group) {
      const auto& error =
          String::Handle(String::New("exit with final message is only allowed "
                                     "for isolates in one isolate group."));
      Exceptions::ThrowArgumentError(error);
      UNREACHABLE();
    }

    Object& validated_result = Object::Handle(zone);
    const Object& msg_obj = Object::Handle(zone, obj.ptr());
    {
      MessageValidator validator(thread);
      validated_result = validator.Validate(thread, obj);
    }
    // msg_array = [
    //     <message>,
    //     <collection-lib-objects-to-rehash>,
    //     <core-lib-objects-to-rehash>,
    // ]
    const Array& msg_array = Array::Handle(zone, Array::New(3));
    msg_array.SetAt(0, msg_obj);
    if (validated_result.IsUnhandledException()) {
      Exceptions::PropagateError(Error::Cast(validated_result));
      UNREACHABLE();
    }
    PersistentHandle* handle =
        isolate->group()->api_state()->AllocatePersistentHandle();
    handle->set_ptr(msg_array);
    isolate->bequeath(std::unique_ptr<Bequest>(new Bequest(handle, port.Id())));
  }

  Thread::Current()->StartUnwindError();
  const String& msg =
      String::Handle(String::New("isolate terminated by Isolate.exit"));
  const UnwindError& error = UnwindError::Handle(UnwindError::New(msg));
  error.set_is_user_initiated(true);
  Exceptions::PropagateError(error);
  UNREACHABLE();
  // We will never execute dart code again in this isolate.
  return Object::null();
}

class IsolateSpawnState {
 public:
  IsolateSpawnState(Dart_Port parent_port,
                    Dart_Port origin_id,
                    const char* script_url,
                    PersistentHandle* closure_tuple_handle,
                    SerializedObjectBuffer* message_buffer,
                    const char* package_config,
                    bool paused,
                    bool errorsAreFatal,
                    Dart_Port onExit,
                    Dart_Port onError,
                    const char* debug_name,
                    IsolateGroup* group);
  IsolateSpawnState(Dart_Port parent_port,
                    const char* script_url,
                    const char* package_config,
                    SerializedObjectBuffer* args_buffer,
                    SerializedObjectBuffer* message_buffer,
                    bool paused,
                    bool errorsAreFatal,
                    Dart_Port onExit,
                    Dart_Port onError,
                    const char* debug_name,
                    IsolateGroup* group);
  ~IsolateSpawnState();

  Dart_Port parent_port() const { return parent_port_; }
  Dart_Port origin_id() const { return origin_id_; }
  Dart_Port on_exit_port() const { return on_exit_port_; }
  Dart_Port on_error_port() const { return on_error_port_; }
  const char* script_url() const { return script_url_; }
  const char* package_config() const { return package_config_; }
  const char* debug_name() const { return debug_name_; }
  bool is_spawn_uri() const {
    return closure_tuple_handle_ == nullptr;  // No closure entrypoint.
  }
  bool paused() const { return paused_; }
  bool errors_are_fatal() const { return errors_are_fatal_; }
  Dart_IsolateFlags* isolate_flags() { return &isolate_flags_; }
  PersistentHandle* closure_tuple_handle() const {
    return closure_tuple_handle_;
  }

  ObjectPtr ResolveFunction();
  ObjectPtr BuildArgs(Thread* thread);
  ObjectPtr BuildMessage(Thread* thread);

  IsolateGroup* isolate_group() const { return isolate_group_; }

 private:
  Dart_Port parent_port_;
  Dart_Port origin_id_ = ILLEGAL_PORT;
  Dart_Port on_exit_port_;
  Dart_Port on_error_port_;
  const char* script_url_;
  const char* package_config_;
  const char* debug_name_;
  PersistentHandle* closure_tuple_handle_ = nullptr;
  IsolateGroup* isolate_group_;
  std::unique_ptr<Message> serialized_args_;
  std::unique_ptr<Message> serialized_message_;

  Dart_IsolateFlags isolate_flags_;
  bool paused_;
  bool errors_are_fatal_;
};

static const char* NewConstChar(const char* chars) {
  size_t len = strlen(chars);
  char* mem = new char[len + 1];
  memmove(mem, chars, len + 1);
  return mem;
}

IsolateSpawnState::IsolateSpawnState(Dart_Port parent_port,
                                     Dart_Port origin_id,
                                     const char* script_url,
                                     PersistentHandle* closure_tuple_handle,
                                     SerializedObjectBuffer* message_buffer,
                                     const char* package_config,
                                     bool paused,
                                     bool errors_are_fatal,
                                     Dart_Port on_exit_port,
                                     Dart_Port on_error_port,
                                     const char* debug_name,
                                     IsolateGroup* isolate_group)
    : parent_port_(parent_port),
      origin_id_(origin_id),
      on_exit_port_(on_exit_port),
      on_error_port_(on_error_port),
      script_url_(script_url),
      package_config_(package_config),
      debug_name_(debug_name),
      closure_tuple_handle_(closure_tuple_handle),
      isolate_group_(isolate_group),
      serialized_args_(nullptr),
      serialized_message_(message_buffer->StealMessage()),
      paused_(paused),
      errors_are_fatal_(errors_are_fatal) {
  ASSERT(closure_tuple_handle_ != nullptr);

  auto thread = Thread::Current();
  auto isolate = thread->isolate();

  // Inherit flags from spawning isolate.
  isolate->FlagsCopyTo(isolate_flags());
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
                                     IsolateGroup* isolate_group)
    : parent_port_(parent_port),
      on_exit_port_(on_exit_port),
      on_error_port_(on_error_port),
      script_url_(script_url),
      package_config_(package_config),
      debug_name_(debug_name),
      isolate_group_(isolate_group),
      serialized_args_(args_buffer->StealMessage()),
      serialized_message_(message_buffer->StealMessage()),
      isolate_flags_(),
      paused_(paused),
      errors_are_fatal_(errors_are_fatal) {
  if (debug_name_ == nullptr) {
    debug_name_ = NewConstChar("main");
  }

  // By default inherit flags from spawning isolate. These can be overridden
  // from the calling code.
  Isolate::Current()->FlagsCopyTo(isolate_flags());
}

IsolateSpawnState::~IsolateSpawnState() {
  delete[] script_url_;
  delete[] package_config_;
  delete[] debug_name_;
}

ObjectPtr IsolateSpawnState::ResolveFunction() {
  Thread* thread = Thread::Current();
  auto IG = thread->isolate_group();
  Zone* zone = thread->zone();

  // Handle spawnUri lookup rules.
  // Check whether the root library defines a main function.
  const Library& lib =
      Library::Handle(zone, IG->object_store()->root_library());
  const String& main = String::Handle(zone, String::New("main"));
  Function& func = Function::Handle(zone, lib.LookupFunctionAllowPrivate(main));
  if (func.IsNull()) {
    // Check whether main is reexported from the root library.
    const Object& obj = Object::Handle(zone, lib.LookupReExport(main));
    if (obj.IsFunction()) {
      func ^= obj.ptr();
    }
  }
  if (func.IsNull()) {
    const String& msg = String::Handle(
        zone,
        String::NewFormatted(
            "Unable to resolve function 'main' in script '%s'.", script_url()));
    return LanguageError::New(msg);
  }
  return func.ptr();
}

static ObjectPtr DeserializeMessage(Thread* thread, Message* message) {
  if (message == nullptr) {
    return Object::null();
  }
  if (message->IsRaw()) {
    return Object::RawCast(message->raw_obj());
  } else {
    return ReadMessage(thread, message);
  }
}

ObjectPtr IsolateSpawnState::BuildArgs(Thread* thread) {
  const Object& result =
      Object::Handle(DeserializeMessage(thread, serialized_args_.get()));
  serialized_args_.reset();
  return result.ptr();
}

ObjectPtr IsolateSpawnState::BuildMessage(Thread* thread) {
  const Object& result =
      Object::Handle(DeserializeMessage(thread, serialized_message_.get()));
  serialized_message_.reset();
  return result.ptr();
}

static void ThrowIsolateSpawnException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}

class SpawnIsolateTask : public ThreadPool::Task {
 public:
  SpawnIsolateTask(Isolate* parent_isolate,
                   std::unique_ptr<IsolateSpawnState> state)
      : parent_isolate_(parent_isolate), state_(std::move(state)) {
    parent_isolate->IncrementSpawnCount();
  }

  ~SpawnIsolateTask() override {
    if (parent_isolate_ != nullptr) {
      parent_isolate_->DecrementSpawnCount();
    }
  }

  void Run() override {
    const char* name = state_->debug_name();
    ASSERT(name != nullptr);

    auto group = state_->isolate_group();
    if (group == nullptr) {
      RunHeavyweight(name);
    } else {
      RunLightweight(name);
    }
  }

  void RunHeavyweight(const char* name) {
    // The create isolate group callback is mandatory.  If not provided we
    // cannot spawn isolates.
    auto create_group_callback = Isolate::CreateGroupCallback();
    if (create_group_callback == nullptr) {
      FailedSpawn("Isolate spawn is not supported by this Dart embedder\n");
      return;
    }

    char* error = nullptr;

    // Make a copy of the state's isolate flags and hand it to the callback.
    Dart_IsolateFlags api_flags = *(state_->isolate_flags());

    // Inherit the system isolate property to work around issues with
    // --pause-isolates-on-start and --pause-isolates-on-exit impacting macro
    // generation isolates which are spawned by the kernel-service
    // (see https://github.com/dart-lang/sdk/issues/54729 for details).
    //
    // This flag isn't inherited in the case that the main isolate is marked as
    // a system isolate in the standalone VM using the
    // --mark-main-isolate-as-system-isolate flag as it's currently used to
    // hide test runner implementation details and spawns isolates that should
    // be debuggable as non-system isolates.
    //
    // TODO(bkonyi): revisit this decision, see
    // https://github.com/dart-lang/sdk/issues/54736 for the tracking issue.
    const bool is_parent_main_isolate =
        strcmp(parent_isolate_->name(), "main") == 0;
    api_flags.is_system_isolate =
        api_flags.is_system_isolate && !is_parent_main_isolate;
    Dart_Isolate isolate =
        (create_group_callback)(state_->script_url(), name, nullptr,
                                state_->package_config(), &api_flags,
                                parent_isolate_->init_callback_data(), &error);
    parent_isolate_->DecrementSpawnCount();
    parent_isolate_ = nullptr;

    if (isolate == nullptr) {
      FailedSpawn(error, /*has_current_isolate=*/false);
      free(error);
      return;
    }
    Dart_EnterIsolate(isolate);
    Run(reinterpret_cast<Isolate*>(isolate));
  }

  void RunLightweight(const char* name) {
    // The create isolate initialize callback is mandatory.
    auto initialize_callback = Isolate::InitializeCallback();
    if (initialize_callback == nullptr) {
      FailedSpawn(
          "Lightweight isolate spawn is not supported by this Dart embedder\n",
          /*has_current_isolate=*/false);
      return;
    }

    char* error = nullptr;

    auto group = state_->isolate_group();
    Isolate* isolate = CreateWithinExistingIsolateGroup(group, name, &error);
    parent_isolate_->DecrementSpawnCount();
    parent_isolate_ = nullptr;

    if (isolate == nullptr) {
      FailedSpawn(error, /*has_current_isolate=*/false);
      free(error);
      return;
    }

    void* child_isolate_data = nullptr;
    const bool success = initialize_callback(&child_isolate_data, &error);
    if (!success) {
      FailedSpawn(error);
      Dart_ShutdownIsolate();
      free(error);
      return;
    }

    isolate->set_init_callback_data(child_isolate_data);
    Run(isolate);
  }

 private:
  void Run(Isolate* child) {
    if (!EnsureIsRunnable(child)) {
      Dart_ShutdownIsolate();
      return;
    }

    if (state_->origin_id() != ILLEGAL_PORT) {
      // origin_id is set to parent isolate main port id when spawning via
      // spawnFunction.
      child->set_origin_id(state_->origin_id());
    }
    bool errors_are_fatal = state_->errors_are_fatal();
    Dart_Port on_error_port = state_->on_error_port();
    Dart_Port on_exit_port = state_->on_exit_port();

    bool success = true;
    {
      auto thread = Thread::Current();
      TransitionNativeToVM transition(thread);
      StackZone zone(thread);
      HandleScope hs(thread);

      success = EnqueueEntrypointInvocationAndNotifySpawner(thread);

      // Destruction of [IsolateSpawnState] may cause destruction of [Message]
      // which make need to delete persistent handles, so explicitly delete it
      // now while we are in the right safepoint state.
      state_ = nullptr;
    }

    if (!success) {
      Dart_ShutdownIsolate();
      return;
    }

    // All preconditions are met for this to always succeed.
    char* error = nullptr;
    if (!Dart_RunLoopAsync(errors_are_fatal, on_error_port, on_exit_port,
                           &error)) {
      FATAL("Dart_RunLoopAsync() failed: %s. Please file a Dart VM bug report.",
            error);
    }
  }

  bool EnsureIsRunnable(Isolate* child) {
    // We called out to the embedder to create/initialize a new isolate. The
    // embedder callback successfully did so. It is now our responsibility to
    // run the isolate.
    // If the isolate was not marked as runnable, we'll do so here and run it.
    if (!child->is_runnable()) {
      const char* error = child->MakeRunnable();
      if (error != nullptr) {
        FailedSpawn(error);
        return false;
      }
    }
    ASSERT(child->is_runnable());
    return true;
  }

  bool EnqueueEntrypointInvocationAndNotifySpawner(Thread* thread) {
    auto isolate = thread->isolate();
    auto zone = thread->zone();
    const bool is_spawn_uri = state_->is_spawn_uri();

    // Step 1) Resolve the entrypoint function.
    auto& entrypoint_closure = Closure::Handle(zone);
    if (state_->closure_tuple_handle() != nullptr) {
      const auto& result = Object::Handle(
          zone,
          ReadObjectGraphCopyMessage(thread, state_->closure_tuple_handle()));
      if (result.IsError()) {
        ReportError(
            "Failed to deserialize the passed entrypoint to the new isolate.");
        return false;
      }
      entrypoint_closure = Closure::RawCast(result.ptr());
    } else {
      const auto& result = Object::Handle(zone, state_->ResolveFunction());
      if (result.IsError()) {
        ASSERT(is_spawn_uri);
        ReportError("Failed to resolve entrypoint function.");
        return false;
      }
      ASSERT(result.IsFunction());
      auto& func = Function::Handle(zone, Function::Cast(result).ptr());
      func = func.ImplicitClosureFunction();
      entrypoint_closure = func.ImplicitStaticClosure();
    }

    // Step 2) Enqueue delayed invocation of entrypoint callback.
    const auto& args_obj = Object::Handle(zone, state_->BuildArgs(thread));
    if (args_obj.IsError()) {
      ReportError(
          "Failed to deserialize the passed arguments to the new isolate.");
      return false;
    }
    ASSERT(args_obj.IsNull() || args_obj.IsInstance());
    const auto& message_obj =
        Object::Handle(zone, state_->BuildMessage(thread));
    if (message_obj.IsError()) {
      ReportError(
          "Failed to deserialize the passed arguments to the new isolate.");
      return false;
    }
    ASSERT(message_obj.IsNull() || message_obj.IsInstance());
    const Array& args = Array::Handle(zone, Array::New(4));
    args.SetAt(0, entrypoint_closure);
    args.SetAt(1, args_obj);
    args.SetAt(2, message_obj);
    args.SetAt(3, is_spawn_uri ? Bool::True() : Bool::False());

    const auto& lib = Library::Handle(zone, Library::IsolateLibrary());
    const auto& entry_name = String::Handle(zone, String::New("_startIsolate"));
    const auto& entry_point =
        Function::Handle(zone, lib.LookupFunctionAllowPrivate(entry_name));
    ASSERT(entry_point.IsFunction() && !entry_point.IsNull());
    const auto& result =
        Object::Handle(zone, DartEntry::InvokeFunction(entry_point, args));
    if (result.IsError()) {
      ReportError("Failed to enqueue delayed entrypoint invocation.");
      return false;
    }

    // Step 3) Pause the isolate if required & Notify parent isolate about
    // isolate creation.
    const auto& capabilities = Array::Handle(zone, Array::New(2));
    auto& capability = Capability::Handle(zone);
    capability = Capability::New(isolate->pause_capability());
    capabilities.SetAt(0, capability);
    capability = Capability::New(isolate->terminate_capability());
    capabilities.SetAt(1, capability);
    const auto& send_port =
        SendPort::Handle(zone, SendPort::New(isolate->main_port()));
    const auto& message = Array::Handle(zone, Array::New(2));
    message.SetAt(0, send_port);
    message.SetAt(1, capabilities);
    if (state_->paused()) {
      capability ^= capabilities.At(0);
      const bool added = isolate->AddResumeCapability(capability);
      ASSERT(added);
      isolate->message_handler()->increment_paused();
    }
    {
      // If parent isolate died, we ignore the fact that we cannot notify it.
      PortMap::PostMessage(WriteMessage(/*same_group=*/false, message,
                                        state_->parent_port(),
                                        Message::kNormalPriority));
    }

    return true;
  }

  void FailedSpawn(const char* error, bool has_current_isolate = true) {
    ReportError(error != nullptr
                    ? error
                    : "Unknown error occurred during Isolate spawning.");
    // Destruction of [IsolateSpawnState] may cause destruction of [Message]
    // which make need to delete persistent handles (which requires a current
    // isolate group).
    if (has_current_isolate) {
      ASSERT(IsolateGroup::Current() == state_->isolate_group());
      TransitionNativeToVM transition(Thread::Current());
      state_ = nullptr;
    } else if (state_->isolate_group() != nullptr) {
      ASSERT(IsolateGroup::Current() == nullptr);
      const bool kBypassSafepoint = false;
      const bool result = Thread::EnterIsolateGroupAsHelper(
          state_->isolate_group(), Thread::kSpawnTask, kBypassSafepoint);
      ASSERT(result);
      state_ = nullptr;
      Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    } else {
      // The state won't need a current isolate group, because it belongs to a
      // [Isolate.spawnUri] call.
      state_ = nullptr;
    }
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

  DISALLOW_COPY_AND_ASSIGN(SpawnIsolateTask);
};

static const char* String2UTF8(const String& str) {
  intptr_t len = Utf8::Length(str);
  char* result = new char[len + 1];
  str.ToUTF8(reinterpret_cast<uint8_t*>(result), len);
  result[len] = 0;

  return result;
}

DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 0, 10) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, script_uri, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(6));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(7));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(8));
  GET_NATIVE_ARGUMENT(String, debugName, arguments->NativeArgAt(9));

  PersistentHandle* closure_tuple_handle = nullptr;
  // We have a non-toplevel closure that we might need to copy.
  // Result will be [<closure-copy>, <objects-in-msg-to-rehash>]
  const auto& closure_copy_tuple = Object::Handle(
      zone, CopyMutableObjectGraph(closure));  // Throws if it fails.
  ASSERT(closure_copy_tuple.IsArray());
  ASSERT(
      Object::Handle(zone, Array::Cast(closure_copy_tuple).At(0)).IsClosure());
  closure_tuple_handle =
      isolate->group()->api_state()->AllocatePersistentHandle();
  closure_tuple_handle->set_ptr(closure_copy_tuple.ptr());

  bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
  Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
  Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

  // We first try to serialize the message.  In case the message is not
  // serializable this will throw an exception.
  SerializedObjectBuffer message_buffer;
  message_buffer.set_message(WriteMessage(
      /*same_group=*/true, message, ILLEGAL_PORT, Message::kNormalPriority));

  const char* utf8_package_config =
      packageConfig.IsNull() ? nullptr : String2UTF8(packageConfig);
  const char* utf8_debug_name =
      debugName.IsNull() ? nullptr : String2UTF8(debugName);
  if (closure_tuple_handle != nullptr && utf8_debug_name == nullptr) {
    const auto& closure_function = Function::Handle(zone, closure.function());
    utf8_debug_name =
        NewConstChar(closure_function.QualifiedUserVisibleNameCString());
  }

  std::unique_ptr<IsolateSpawnState> state(new IsolateSpawnState(
      port.Id(), isolate->origin_id(), String2UTF8(script_uri),
      closure_tuple_handle, &message_buffer, utf8_package_config,
      paused.value(), fatal_errors, on_exit_port, on_error_port,
      utf8_debug_name, isolate->group()));

  isolate->group()->thread_pool()->Run<SpawnIsolateTask>(isolate,
                                                         std::move(state));
  return Object::null();
}

static const char* CanonicalizeUri(Thread* thread,
                                   const Library& library,
                                   const String& uri,
                                   char** error) {
  const char* result = nullptr;
  Zone* zone = thread->zone();
  auto isolate_group = thread->isolate_group();
  if (isolate_group->HasTagHandler()) {
    const Object& obj = Object::Handle(
        isolate_group->CallTagHandler(Dart_kCanonicalizeUrl, library, uri));
    if (obj.IsString()) {
      result = String2UTF8(String::Cast(obj));
    } else if (obj.IsError()) {
      Error& error_obj = Error::Handle();
      error_obj ^= obj.ptr();
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
  GET_NATIVE_ARGUMENT(Bool, enableAsserts, arguments->NativeArgAt(8));
  GET_NATIVE_ARGUMENT(Array, environment, arguments->NativeArgAt(9));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(10));
  GET_NATIVE_ARGUMENT(String, debugName, arguments->NativeArgAt(11));

  bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
  Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
  Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

  // We first try to serialize the arguments and the message.  In case the
  // arguments or the message are not serializable this will throw an exception.
  SerializedObjectBuffer arguments_buffer;
  SerializedObjectBuffer message_buffer;
  {
    arguments_buffer.set_message(WriteMessage(
        /*same_group=*/false, args, ILLEGAL_PORT, Message::kNormalPriority));
  }
  {
    message_buffer.set_message(WriteMessage(
        /*same_group=*/false, message, ILLEGAL_PORT, Message::kNormalPriority));
  }

  // Canonicalize the uri with respect to the current isolate.
  const Library& root_lib =
      Library::Handle(isolate->group()->object_store()->root_library());
  char* error = nullptr;
  const char* canonical_uri = CanonicalizeUri(thread, root_lib, uri, &error);
  if (canonical_uri == nullptr) {
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  const char* utf8_package_config =
      packageConfig.IsNull() ? nullptr : String2UTF8(packageConfig);
  const char* utf8_debug_name =
      debugName.IsNull() ? nullptr : String2UTF8(debugName);

  std::unique_ptr<IsolateSpawnState> state(new IsolateSpawnState(
      port.Id(), canonical_uri, utf8_package_config, &arguments_buffer,
      &message_buffer, paused.value(), fatal_errors, on_exit_port,
      on_error_port, utf8_debug_name, /*group=*/nullptr));

  // If we were passed a value then override the default flags state for
  // enableAsserts mode. The default state is the state of the current
  // isolate.
  if (!enableAsserts.IsNull()) {
    Dart_IsolateFlags* flags = state->isolate_flags();
    flags->enable_asserts = enableAsserts.value();
  }

  isolate->group()->thread_pool()->Run<SpawnIsolateTask>(isolate,
                                                         std::move(state));
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
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(Isolate_getCurrentRootUriStr, 0, 0) {
  const Library& root_lib =
      Library::Handle(zone, isolate->group()->object_store()->root_library());
  return root_lib.url();
}

DEFINE_NATIVE_ENTRY(Isolate_registerKernelBlob, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedData, kernel_blob,
                               arguments->NativeArgAt(0));
  auto register_kernel_blob_callback = Isolate::RegisterKernelBlobCallback();
  if (register_kernel_blob_callback == nullptr) {
    Exceptions::ThrowUnsupportedError(
        "Registration of kernel blobs is not supported by this Dart embedder.");
  }
  bool is_kernel = false;
  {
    NoSafepointScope no_safepoint;
    is_kernel =
        Dart_IsKernel(reinterpret_cast<uint8_t*>(kernel_blob.DataAddr(0)),
                      kernel_blob.LengthInBytes());
  }
  if (!is_kernel) {
    const auto& error = String::Handle(
        zone, String::New("kernelBlob doesn\'t contain a valid kernel.\n"));
    Exceptions::ThrowArgumentError(error);
    UNREACHABLE();
  }
  const char* uri = nullptr;
  {
    NoSafepointScope no_safepoint;
    uri = register_kernel_blob_callback(
        reinterpret_cast<uint8_t*>(kernel_blob.DataAddr(0)),
        kernel_blob.LengthInBytes());
  }
  if (uri == nullptr) {
    Exceptions::ThrowOOM();
  }
  return String::New(uri);
}

DEFINE_NATIVE_ENTRY(Isolate_unregisterKernelBlob, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, kernel_blob_uri,
                               arguments->NativeArgAt(0));
  auto unregister_kernel_blob_callback =
      Isolate::UnregisterKernelBlobCallback();
  if (unregister_kernel_blob_callback == nullptr) {
    Exceptions::ThrowUnsupportedError(
        "Registration of kernel blobs is not supported by this Dart embedder.");
  }
  unregister_kernel_blob_callback(kernel_blob_uri.ToCString());
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Isolate_sendOOB, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, msg, arguments->NativeArgAt(1));

  // Make sure to route this request to the isolate library OOB message handler.
  msg.SetAt(0, Smi::Handle(Smi::New(Message::kIsolateLibOOBMsg)));

  // Ensure message writer (and it's resources, e.g. forwarding tables) are
  // cleaned up before handling interrupts.
  {
    PortMap::PostMessage(WriteMessage(/*same_group=*/false, msg, port.Id(),
                                      Message::kOOBPriority));
  }

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
    array ^= Array::Cast(array_instance).ptr();
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

  uint8_t* data = reinterpret_cast<uint8_t*>(::malloc(total_bytes));
  if (data == nullptr) {
    const Instance& exception = Instance::Handle(
        thread->isolate_group()->object_store()->out_of_memory());
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
    peer = thread->heap()->GetPeer(t.ptr());
    // Assume that object's Peer is only used to track transferability state.
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
  tpeer->handle()->EnsureFreedExternal(IsolateGroup::Current());
  tpeer->ClearData();

  const ExternalTypedData& typed_data = ExternalTypedData::Handle(
      ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data, length,
                             thread->heap()->SpaceForExternal(length)));
  FinalizablePersistentHandle* finalizable_ref =
      FinalizablePersistentHandle::New(thread->isolate_group(), typed_data,
                                       /* peer= */ data,
                                       &ExternalTypedDataFinalizer, length,
                                       /*auto_delete=*/true);
  ASSERT(finalizable_ref != nullptr);
  return typed_data.ptr();
}

}  // namespace dart
