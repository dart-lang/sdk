// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_snapshot.h"

#include <memory>

#include "platform/assert.h"
#include "platform/unicode.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/heap/heap.h"
#include "vm/heap/weak_table.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_graph_copy.h"
#include "vm/object_store.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"

namespace dart {

static Dart_CObject cobj_sentinel = {Dart_CObject_kUnsupported, {false}};
static Dart_CObject cobj_transition_sentinel = {Dart_CObject_kUnsupported,
                                                {false}};
static Dart_CObject cobj_dynamic_type = {Dart_CObject_kUnsupported, {false}};
static Dart_CObject cobj_void_type = {Dart_CObject_kUnsupported, {false}};
static Dart_CObject cobj_empty_type_arguments = {Dart_CObject_kUnsupported,
                                                 {false}};
static Dart_CObject cobj_true = {Dart_CObject_kBool, {true}};
static Dart_CObject cobj_false = {Dart_CObject_kBool, {false}};

// Workaround for lack of designated initializers until we adopt c++20
class PredefinedCObjects {
 public:
  static PredefinedCObjects& getInstance() {
    static PredefinedCObjects instance;
    return instance;
  }

  static Dart_CObject* cobj_null() { return &getInstance().cobj_null_; }
  static Dart_CObject* cobj_empty_array() {
    return &getInstance().cobj_empty_array_;
  }

 private:
  PredefinedCObjects() {
    cobj_null_.type = Dart_CObject_kNull;
    cobj_null_.value.as_int64 = 0;
    cobj_empty_array_.type = Dart_CObject_kArray;
    cobj_empty_array_.value.as_array = {0, nullptr};
  }

  Dart_CObject cobj_null_;
  Dart_CObject cobj_empty_array_;

  DISALLOW_COPY_AND_ASSIGN(PredefinedCObjects);
};

enum class MessagePhase {
  kBeforeTypes = 0,
  kTypes = 1,
  kCanonicalInstances = 2,
  kNonCanonicalInstances = 3,

  kNumPhases = 4,
};

class MessageSerializer;
class MessageDeserializer;
class ApiMessageSerializer;
class ApiMessageDeserializer;

class MessageSerializationCluster : public ZoneAllocated {
 public:
  explicit MessageSerializationCluster(const char* name,
                                       MessagePhase phase,
                                       intptr_t cid,
                                       bool is_canonical = false)
      : name_(name), phase_(phase), cid_(cid), is_canonical_(is_canonical) {}
  virtual ~MessageSerializationCluster() {}

  virtual void Trace(MessageSerializer* s, Object* object) = 0;
  virtual void WriteNodes(MessageSerializer* s) = 0;
  virtual void WriteEdges(MessageSerializer* s) {}

  virtual void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {}
  virtual void WriteNodesApi(ApiMessageSerializer* s) {}
  virtual void WriteEdgesApi(ApiMessageSerializer* s) {}

  const char* name() const { return name_; }
  MessagePhase phase() const { return phase_; }
  intptr_t cid() const { return cid_; }
  bool is_canonical() const { return is_canonical_; }

 protected:
  const char* const name_;
  const MessagePhase phase_;
  const intptr_t cid_;
  const bool is_canonical_;

  DISALLOW_COPY_AND_ASSIGN(MessageSerializationCluster);
};

class MessageDeserializationCluster : public ZoneAllocated {
 public:
  explicit MessageDeserializationCluster(const char* name,
                                         bool is_canonical = false)
      : name_(name),
        is_canonical_(is_canonical),
        start_index_(0),
        stop_index_(0) {}
  virtual ~MessageDeserializationCluster() {}

  virtual void ReadNodes(MessageDeserializer* d) = 0;
  virtual void ReadEdges(MessageDeserializer* d) {}
  virtual ObjectPtr PostLoad(MessageDeserializer* d) { return nullptr; }
  virtual void ReadNodesApi(ApiMessageDeserializer* d) {}
  virtual void ReadEdgesApi(ApiMessageDeserializer* d) {}
  virtual void PostLoadApi(ApiMessageDeserializer* d) {}

  void ReadNodesWrapped(MessageDeserializer* d);
  void ReadNodesWrappedApi(ApiMessageDeserializer* d);

  const char* name() const { return name_; }
  bool is_canonical() const { return is_canonical_; }

 protected:
  ObjectPtr PostLoadAbstractType(MessageDeserializer* d);
  ObjectPtr PostLoadLinkedHash(MessageDeserializer* d);

  const char* const name_;
  const bool is_canonical_;
  // The range of the ref array that belongs to this cluster.
  intptr_t start_index_;
  intptr_t stop_index_;

  DISALLOW_COPY_AND_ASSIGN(MessageDeserializationCluster);
};

class BaseSerializer : public StackResource {
 public:
  BaseSerializer(Thread* thread, Zone* zone);
  ~BaseSerializer();

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    BaseWriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }
  void WriteUnsigned(intptr_t value) { stream_.WriteUnsigned(value); }
  void WriteWordWith32BitWrites(uword value) {
    stream_.WriteWordWith32BitWrites(value);
  }
  void WriteBytes(const void* addr, intptr_t len) {
    stream_.WriteBytes(addr, len);
  }
  void WriteAscii(const String& str) {
    intptr_t len = str.Length();
    WriteUnsigned(len);
    for (intptr_t i = 0; i < len; i++) {
      int64_t c = str.CharAt(i);
      ASSERT(c < 128);
      Write<uint8_t>(c);
    }
    Write<uint8_t>(0);
  }

  MessageSerializationCluster* NewClusterForClass(intptr_t cid,
                                                  bool is_canonical);
  void WriteCluster(MessageSerializationCluster* cluster);

  std::unique_ptr<Message> Finish(Dart_Port dest_port,
                                  Message::Priority priority) {
    MessageFinalizableData* finalizable_data = finalizable_data_;
    finalizable_data_ = nullptr;
    finalizable_data->SerializationSucceeded();
    intptr_t size;
    uint8_t* buffer = stream_.Steal(&size);
    return Message::New(dest_port, buffer, size, finalizable_data, priority);
  }

  Zone* zone() const { return zone_; }
  MessageFinalizableData* finalizable_data() const { return finalizable_data_; }
  intptr_t next_ref_index() const { return next_ref_index_; }

 protected:
  Zone* const zone_;
  MallocWriteStream stream_;
  MessageFinalizableData* finalizable_data_;
  GrowableArray<MessageSerializationCluster*> clusters_;
  intptr_t num_base_objects_;
  intptr_t num_written_objects_;
  intptr_t next_ref_index_;
};

class MessageSerializer : public BaseSerializer {
 public:
  explicit MessageSerializer(Thread* thread);
  ~MessageSerializer();

  bool MarkObjectId(ObjectPtr object, intptr_t id) {
    ASSERT(id != WeakTable::kNoValue);
    WeakTable* table;
    if (object->IsImmediateOrOldObject()) {
      table = isolate()->forward_table_old();
    } else {
      table = isolate()->forward_table_new();
    }
    return table->MarkValueExclusive(object, id);
  }

  void SetObjectId(ObjectPtr object, intptr_t id) {
    ASSERT(id != WeakTable::kNoValue);
    WeakTable* table;
    if (object->IsImmediateOrOldObject()) {
      table = isolate()->forward_table_old();
    } else {
      table = isolate()->forward_table_new();
    }
    table->SetValueExclusive(object, id);
  }

  intptr_t GetObjectId(ObjectPtr object) const {
    const WeakTable* table;
    if (object->IsImmediateOrOldObject()) {
      table = isolate()->forward_table_old();
    } else {
      table = isolate()->forward_table_new();
    }
    return table->GetValueExclusive(object);
  }

  DART_NOINLINE void AddBaseObject(ObjectPtr base_object) {
    AssignRef(base_object);
    num_base_objects_++;
  }
  DART_NOINLINE void AssignRef(ObjectPtr object) {
    SetObjectId(object, next_ref_index_);
    next_ref_index_++;
  }
  void AssignRef(Object* object) { AssignRef(object->ptr()); }

  void Push(ObjectPtr object);

  void Trace(const Object& root, Object* object);

  void IllegalObject(const Object& object, const char* message);

  void AddBaseObjects();
  void Serialize(const Object& root);

  DART_NOINLINE void WriteRef(ObjectPtr object) {
    intptr_t index = GetObjectId(object);
    ASSERT(index != WeakTable::kNoValue);
    WriteUnsigned(index);
  }

  Thread* thread() const {
    return static_cast<Thread*>(StackResource::thread());
  }
  Isolate* isolate() const { return thread()->isolate(); }
  IsolateGroup* isolate_group() const { return thread()->isolate_group(); }

  bool HasRef(ObjectPtr object) const {
    return GetObjectId(object) != WeakTable::kNoValue;
  }

 private:
  WeakTable* forward_table_new_;
  WeakTable* forward_table_old_;
  GrowableArray<Object*> stack_;
};

class ApiMessageSerializer : public BaseSerializer {
 public:
  explicit ApiMessageSerializer(Zone* zone);
  ~ApiMessageSerializer();

  bool MarkObjectId(Dart_CObject* object, intptr_t id) {
    ASSERT(id != WeakTable::kNoValue);
    return forward_table_.MarkValueExclusive(
        static_cast<ObjectPtr>(reinterpret_cast<uword>(object)), id);
  }

  void SetObjectId(Dart_CObject* object, intptr_t id) {
    ASSERT(id != WeakTable::kNoValue);
    forward_table_.SetValueExclusive(
        static_cast<ObjectPtr>(reinterpret_cast<uword>(object)), id);
  }

  intptr_t GetObjectId(Dart_CObject* object) const {
    return forward_table_.GetValueExclusive(
        static_cast<ObjectPtr>(reinterpret_cast<uword>(object)));
  }

  DART_NOINLINE void AddBaseObject(Dart_CObject* base_object) {
    AssignRef(base_object);
    num_base_objects_++;
  }
  DART_NOINLINE intptr_t AssignRef(Dart_CObject* object) {
    SetObjectId(object, next_ref_index_);
    return next_ref_index_++;
  }
  void ForwardRef(Dart_CObject* old, Dart_CObject* nue) {
    intptr_t id = GetObjectId(nue);
    ASSERT(id != WeakTable::kNoValue);
    SetObjectId(old, id);
    num_written_objects_--;
  }

  void Push(Dart_CObject* object);

  bool Trace(Dart_CObject* object);

  void AddBaseObjects();
  bool Serialize(Dart_CObject* root);

  void WriteRef(Dart_CObject* object) {
    intptr_t index = GetObjectId(object);
    ASSERT(index != WeakTable::kNoValue);
    WriteUnsigned(index);
  }

  bool Fail(const char* message) {
    exception_message_ = message;
    return false;
  }

 private:
  WeakTable forward_table_;
  GrowableArray<Dart_CObject*> stack_;
  const char* exception_message_;
};

class BaseDeserializer : public ValueObject {
 public:
  BaseDeserializer(Zone* zone, Message* message);
  ~BaseDeserializer();

  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }
  intptr_t ReadUnsigned() { return stream_.ReadUnsigned(); }
  uword ReadWordWith32BitReads() { return stream_.ReadWordWith32BitReads(); }
  void ReadBytes(void* addr, intptr_t len) { stream_.ReadBytes(addr, len); }
  const char* ReadAscii() {
    intptr_t len = ReadUnsigned();
    const char* result = reinterpret_cast<const char*>(CurrentBufferAddress());
    Advance(len + 1);
    return result;
  }

  const uint8_t* CurrentBufferAddress() const {
    return stream_.AddressOfCurrentPosition();
  }

  void Advance(intptr_t value) { stream_.Advance(value); }

  MessageDeserializationCluster* ReadCluster();

  Zone* zone() const { return zone_; }
  intptr_t next_index() const { return next_ref_index_; }
  MessageFinalizableData* finalizable_data() const { return finalizable_data_; }

 protected:
  Zone* zone_;
  ReadStream stream_;
  MessageFinalizableData* finalizable_data_;
  intptr_t next_ref_index_;
};

class MessageDeserializer : public BaseDeserializer {
 public:
  MessageDeserializer(Thread* thread, Message* message)
      : BaseDeserializer(thread->zone(), message),
        thread_(thread),
        refs_(Array::Handle(thread->zone())) {}
  ~MessageDeserializer() {}

  DART_NOINLINE void AddBaseObject(ObjectPtr base_object) {
    AssignRef(base_object);
  }
  void AssignRef(ObjectPtr object) {
    refs_.untag()->set_element(next_ref_index_, object);
    next_ref_index_++;
  }

  ObjectPtr Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= next_ref_index_);
    return refs_.At(index);
  }
  void UpdateRef(intptr_t index, const Object& new_object) {
    ASSERT(index > 0);
    ASSERT(index <= next_ref_index_);
    refs_.SetAt(index, new_object);
  }

  ObjectPtr ReadRef() { return Ref(ReadUnsigned()); }

  void AddBaseObjects();
  ObjectPtr Deserialize();

  Thread* thread() const { return thread_; }
  IsolateGroup* isolate_group() const { return thread_->isolate_group(); }
  ArrayPtr refs() const { return refs_.ptr(); }

 private:
  Thread* const thread_;
  Array& refs_;
};

class ApiMessageDeserializer : public BaseDeserializer {
 public:
  ApiMessageDeserializer(Zone* zone, Message* message)
      : BaseDeserializer(zone, message), refs_(nullptr) {}
  ~ApiMessageDeserializer() {}

  void AddBaseObject(Dart_CObject* base_object) { AssignRef(base_object); }
  void AssignRef(Dart_CObject* object) {
    refs_[next_ref_index_] = object;
    next_ref_index_++;
  }

  Dart_CObject* Allocate(Dart_CObject_Type type) {
    Dart_CObject* result = zone()->Alloc<Dart_CObject>(1);
    result->type = type;
    return result;
  }

  Dart_CObject* Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= next_ref_index_);
    return refs_[index];
  }

  Dart_CObject* ReadRef() { return Ref(ReadUnsigned()); }

  void AddBaseObjects();
  Dart_CObject* Deserialize();

 private:
  Dart_CObject** refs_;
};

void MessageDeserializationCluster::ReadNodesWrapped(MessageDeserializer* d) {
  start_index_ = d->next_index();
  this->ReadNodes(d);
  stop_index_ = d->next_index();
}

void MessageDeserializationCluster::ReadNodesWrappedApi(
    ApiMessageDeserializer* d) {
  start_index_ = d->next_index();
  this->ReadNodesApi(d);
  stop_index_ = d->next_index();
}

ObjectPtr MessageDeserializationCluster::PostLoadAbstractType(
    MessageDeserializer* d) {
  ClassFinalizer::FinalizationKind finalization =
      is_canonical() ? ClassFinalizer::kCanonicalize
                     : ClassFinalizer::kFinalize;
  AbstractType& type = AbstractType::Handle(d->zone());
  Code& code = Code::Handle(d->zone());
  for (intptr_t id = start_index_; id < stop_index_; id++) {
    type ^= d->Ref(id);

    code = TypeTestingStubGenerator::DefaultCodeForType(type);
    type.InitializeTypeTestingStubNonAtomic(code);

    type ^= ClassFinalizer::FinalizeType(type, finalization);
    d->UpdateRef(id, type);
  }
  return nullptr;
}

ObjectPtr MessageDeserializationCluster::PostLoadLinkedHash(
    MessageDeserializer* d) {
  ASSERT(!is_canonical());
  Array& maps = Array::Handle(d->zone(), d->refs());
  maps = maps.Slice(start_index_, stop_index_ - start_index_,
                    /*with_type_argument=*/false);
  return DartLibraryCalls::RehashObjectsInDartCollection(d->thread(), maps);
}

class ClassMessageSerializationCluster : public MessageSerializationCluster {
 public:
  ClassMessageSerializationCluster()
      : MessageSerializationCluster("Class",
                                    MessagePhase::kBeforeTypes,
                                    kClassCid),
        objects_() {}
  ~ClassMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Class* cls = static_cast<Class*>(object);
    objects_.Add(cls);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    Library& lib = Library::Handle(s->zone());
    String& str = String::Handle(s->zone());
    for (intptr_t i = 0; i < count; i++) {
      Class* cls = objects_[i];
      s->AssignRef(cls);
      intptr_t cid = cls->id();
      if (cid < kNumPredefinedCids) {
        ASSERT(cid != 0);
        s->WriteUnsigned(cid);
      } else {
        s->WriteUnsigned(0);
        lib = cls->library();
        str = lib.url();
        s->WriteAscii(str);
        str = cls->Name();
        s->WriteAscii(str);
      }
    }
  }

 private:
  GrowableArray<Class*> objects_;
};

class ClassMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  ClassMessageDeserializationCluster()
      : MessageDeserializationCluster("Class") {}
  ~ClassMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    auto* class_table = d->isolate_group()->class_table();
    String& uri = String::Handle(d->zone());
    Library& lib = Library::Handle(d->zone());
    String& name = String::Handle(d->zone());
    Class& cls = Class::Handle(d->zone());
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t cid = d->ReadUnsigned();
      if (cid != 0) {
        cls = class_table->At(cid);
      } else {
        uri = String::New(d->ReadAscii());   // Library URI.
        name = String::New(d->ReadAscii());  // Class name.
        lib = Library::LookupLibrary(d->thread(), uri);
        if (UNLIKELY(lib.IsNull())) {
          FATAL("Not found: %s %s\n", uri.ToCString(), name.ToCString());
        }
        if (name.Equals(Symbols::TopLevel())) {
          cls = lib.toplevel_class();
        } else {
          cls = lib.LookupClass(name);
        }
        if (UNLIKELY(cls.IsNull())) {
          FATAL("Not found: %s %s\n", uri.ToCString(), name.ToCString());
        }
        cls.EnsureIsFinalized(d->thread());
      }
      d->AssignRef(cls.ptr());
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t cid = d->ReadUnsigned();
      if (cid == 0) {
        d->ReadAscii();  // Library URI.
        d->ReadAscii();  // Class name.
      }
      d->AssignRef(nullptr);
    }
  }
};

class TypeArgumentsMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit TypeArgumentsMessageSerializationCluster(bool is_canonical)
      : MessageSerializationCluster("TypeArguments",
                                    MessagePhase::kTypes,
                                    kTypeArgumentsCid,
                                    is_canonical) {}
  ~TypeArgumentsMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    TypeArguments* type_args = static_cast<TypeArguments*>(object);
    objects_.Add(type_args);

    s->Push(type_args->untag()->instantiations());
    intptr_t length = Smi::Value(type_args->untag()->length());
    for (intptr_t i = 0; i < length; i++) {
      s->Push(type_args->untag()->element(i));
    }
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypeArguments* type_args = objects_[i];
      s->AssignRef(type_args);
      intptr_t length = Smi::Value(type_args->untag()->length());
      s->WriteUnsigned(length);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypeArguments* type_args = objects_[i];
      intptr_t hash = Smi::Value(type_args->untag()->hash());
      s->Write<int32_t>(hash);
      const intptr_t nullability =
          Smi::Value(type_args->untag()->nullability());
      s->WriteUnsigned(nullability);

      intptr_t length = Smi::Value(type_args->untag()->length());
      s->WriteUnsigned(length);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(type_args->untag()->element(j));
      }
    }
  }

 private:
  GrowableArray<TypeArguments*> objects_;
};

class TypeArgumentsMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit TypeArgumentsMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("TypeArguments", is_canonical) {}
  ~TypeArgumentsMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(TypeArguments::New(length));
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypeArgumentsPtr type_args = static_cast<TypeArgumentsPtr>(d->Ref(id));

      type_args->untag()->hash_ = Smi::New(d->Read<int32_t>());
      type_args->untag()->nullability_ = Smi::New(d->ReadUnsigned());

      intptr_t length = d->ReadUnsigned();
      for (intptr_t j = 0; j < length; j++) {
        type_args->untag()->types()[j] =
            static_cast<AbstractTypePtr>(d->ReadRef());
      }
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    if (is_canonical()) {
      TypeArguments& type_args = TypeArguments::Handle(d->zone());
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_args ^= d->Ref(id);
        type_args ^= type_args.Canonicalize(d->thread());
        d->UpdateRef(id, type_args);
      }
    }
    return nullptr;
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->ReadUnsigned();  // Length.
      d->AssignRef(nullptr);
    }
  }

  void ReadEdgesApi(ApiMessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      d->Read<int32_t>();  // Hash.
      d->ReadUnsigned();   // Nullability.
      intptr_t length = d->ReadUnsigned();
      for (intptr_t j = 0; j < length; j++) {
        d->ReadRef();  // Element.
      }
    }
  }
};

class TypeMessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit TypeMessageSerializationCluster(bool is_canonical)
      : MessageSerializationCluster("Type",
                                    MessagePhase::kTypes,
                                    kTypeCid,
                                    is_canonical) {}
  ~TypeMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Type* type = static_cast<Type*>(object);

    if (!type->IsTypeClassAllowedBySpawnUri()) {
      s->IllegalObject(*object, "is a Type");
    }

    objects_.Add(type);

    s->Push(type->type_class());
    s->Push(type->arguments());
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Type* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      Type* type = objects_[i];
      s->WriteRef(type->type_class());
      s->WriteRef(type->arguments());
      s->Write<uint8_t>(static_cast<uint8_t>(type->nullability()));
    }
  }

 private:
  GrowableArray<Type*> objects_;
};

class TypeMessageDeserializationCluster : public MessageDeserializationCluster {
 public:
  explicit TypeMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("Type", is_canonical) {}
  ~TypeMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(Type::New());
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    Class& cls = Class::Handle(d->zone());
    Type& type = Type::Handle(d->zone());
    TypeArguments& type_args = TypeArguments::Handle(d->zone());
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      type ^= d->Ref(id);
      cls ^= d->ReadRef();
      type.set_type_class(cls);
      type_args ^= d->ReadRef();
      type.set_arguments(type_args);
      type.untag()->set_hash(Smi::New(0));
      type.set_nullability(static_cast<Nullability>(d->Read<uint8_t>()));
      type.SetIsFinalized();
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) { return PostLoadAbstractType(d); }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(nullptr);
    }
  }

  void ReadEdgesApi(ApiMessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      d->ReadRef();        // Class.
      d->ReadRef();        // Type arguments.
      d->Read<uint8_t>();  // Nullability.
    }
  }
};

class SmiMessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit SmiMessageSerializationCluster(Zone* zone)
      : MessageSerializationCluster("Smi",
                                    MessagePhase::kBeforeTypes,
                                    kSmiCid,
                                    true),
        objects_(zone, 0) {}
  ~SmiMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Smi* smi = static_cast<Smi*>(object);
    objects_.Add(smi);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Smi* smi = static_cast<Smi*>(objects_[i]);
      s->AssignRef(smi);
      s->Write<intptr_t>(smi->Value());
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<Smi*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* smi = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(smi);
      intptr_t value = smi->type == Dart_CObject_kInt32 ? smi->value.as_int32
                                                        : smi->value.as_int64;
      s->Write<intptr_t>(value);
    }
  }

 private:
  GrowableArray<Smi*> objects_;
};

class SmiMessageDeserializationCluster : public MessageDeserializationCluster {
 public:
  SmiMessageDeserializationCluster()
      : MessageDeserializationCluster("Smi", true) {}
  ~SmiMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(Smi::New(d->Read<intptr_t>()));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t value = d->Read<intptr_t>();
      Dart_CObject* smi;
      if ((kMinInt32 <= value) && (value <= kMaxInt32)) {
        smi = d->Allocate(Dart_CObject_kInt32);
        smi->value.as_int32 = value;
      } else {
        smi = d->Allocate(Dart_CObject_kInt64);
        smi->value.as_int64 = value;
      }
      d->AssignRef(smi);
    }
  }
};

class MintMessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit MintMessageSerializationCluster(Zone* zone, bool is_canonical)
      : MessageSerializationCluster("Mint",
                                    MessagePhase::kBeforeTypes,
                                    kMintCid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~MintMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Mint* mint = static_cast<Mint*>(object);
    objects_.Add(mint);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Mint* mint = static_cast<Mint*>(objects_[i]);
      s->AssignRef(mint);
      s->Write<int64_t>(mint->value());
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<Mint*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* mint = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(mint);
      int64_t value = mint->type == Dart_CObject_kInt32 ? mint->value.as_int32
                                                        : mint->value.as_int64;
      s->Write<int64_t>(value);
    }
  }

 private:
  GrowableArray<Mint*> objects_;
};

class MintMessageDeserializationCluster : public MessageDeserializationCluster {
 public:
  explicit MintMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("int", is_canonical) {}
  ~MintMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      int64_t value = d->Read<int64_t>();
      d->AssignRef(is_canonical() ? Mint::NewCanonical(value)
                                  : Mint::New(value));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      int64_t value = d->Read<int64_t>();
      Dart_CObject* mint;
      if ((kMinInt32 <= value) && (value <= kMaxInt32)) {
        mint = d->Allocate(Dart_CObject_kInt32);
        mint->value.as_int32 = value;
      } else {
        mint = d->Allocate(Dart_CObject_kInt64);
        mint->value.as_int64 = value;
      }
      d->AssignRef(mint);
    }
  }
};

class DoubleMessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit DoubleMessageSerializationCluster(Zone* zone, bool is_canonical)
      : MessageSerializationCluster("double",
                                    MessagePhase::kBeforeTypes,
                                    kDoubleCid,
                                    is_canonical),
        objects_(zone, 0) {}

  ~DoubleMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Double* dbl = static_cast<Double*>(object);
    objects_.Add(dbl);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Double* dbl = objects_[i];
      s->AssignRef(dbl);
      s->Write<double>(dbl->untag()->value_);
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<Double*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* dbl = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(dbl);
      s->Write<double>(dbl->value.as_double);
    }
  }

 private:
  GrowableArray<Double*> objects_;
};

class DoubleMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit DoubleMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("double", is_canonical) {}
  ~DoubleMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      double value = d->Read<double>();
      d->AssignRef(is_canonical() ? Double::NewCanonical(value)
                                  : Double::New(value));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* dbl = d->Allocate(Dart_CObject_kDouble);
      dbl->value.as_double = d->Read<double>();
      d->AssignRef(dbl);
    }
  }
};

class GrowableObjectArrayMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  GrowableObjectArrayMessageSerializationCluster()
      : MessageSerializationCluster("GrowableObjectArray",
                                    MessagePhase::kNonCanonicalInstances,
                                    kGrowableObjectArrayCid) {}
  ~GrowableObjectArrayMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    GrowableObjectArray* array = static_cast<GrowableObjectArray*>(object);
    objects_.Add(array);

    // Compensation for bogus type prefix optimization.
    TypeArguments& args =
        TypeArguments::Handle(s->zone(), array->untag()->type_arguments());
    if (!args.IsNull() && (args.Length() != 1)) {
      args = args.TruncatedTo(1);
      array->untag()->set_type_arguments(args.ptr());
    }

    s->Push(array->untag()->type_arguments());
    for (intptr_t i = 0, n = array->Length(); i < n; i++) {
      s->Push(array->At(i));
    }
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      GrowableObjectArray* array = objects_[i];
      s->WriteUnsigned(array->Length());
      s->AssignRef(array);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      GrowableObjectArray* array = objects_[i];
      s->WriteRef(array->untag()->type_arguments());
      for (intptr_t i = 0, n = array->Length(); i < n; i++) {
        s->WriteRef(array->At(i));
      }
    }
  }

 private:
  GrowableArray<GrowableObjectArray*> objects_;
};

class GrowableObjectArrayMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  GrowableObjectArrayMessageDeserializationCluster()
      : MessageDeserializationCluster("GrowableObjectArray") {}
  ~GrowableObjectArrayMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    GrowableObjectArray& array = GrowableObjectArray::Handle(d->zone());
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      array = GrowableObjectArray::New(length);  // Here length is capacity.
      array.SetLength(length);
      d->AssignRef(array.ptr());
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    GrowableObjectArray& array = GrowableObjectArray::Handle(d->zone());
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      array ^= d->Ref(id);
      array.untag()->set_type_arguments(
          static_cast<TypeArgumentsPtr>(d->ReadRef()));
      for (intptr_t i = 0, n = array.Length(); i < n; i++) {
        array.untag()->data()->untag()->set_element(i, d->ReadRef());
      }
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    ASSERT(!is_canonical());
    return nullptr;
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* array = d->Allocate(Dart_CObject_kArray);
      intptr_t length = d->ReadUnsigned();
      array->value.as_array.length = length;
      if (length > 0) {
        array->value.as_array.values = d->zone()->Alloc<Dart_CObject*>(length);
      } else {
        ASSERT(length == 0);
        array->value.as_array.values = nullptr;
      }
      d->AssignRef(array);
    }
  }

  void ReadEdgesApi(ApiMessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      Dart_CObject* array = d->Ref(id);
      intptr_t length = array->value.as_array.length;
      d->ReadRef();  // type_arguments
      for (intptr_t i = 0; i < length; i++) {
        array->value.as_array.values[i] = d->ReadRef();
      }
    }
  }
};

class TypedDataMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit TypedDataMessageSerializationCluster(Zone* zone, intptr_t cid)
      : MessageSerializationCluster("TypedData",
                                    MessagePhase::kNonCanonicalInstances,
                                    cid),
        objects_(zone, 0) {}
  ~TypedDataMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    TypedData* data = static_cast<TypedData*>(object);
    objects_.Add(data);
  }

  void WriteNodes(MessageSerializer* s) {
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypedData* data = objects_[i];
      s->AssignRef(data);
      intptr_t length = data->Length();
      s->WriteUnsigned(length);
      NoSafepointScope no_safepoint;
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->untag()->data());
      s->WriteBytes(cdata, length * element_size);
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<TypedData*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(data);
      intptr_t length = data->value.as_external_typed_data.length;
      s->WriteUnsigned(length);
      const uint8_t* cdata = data->value.as_typed_data.values;
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  GrowableArray<TypedData*> objects_;
};

class TypedDataMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit TypedDataMessageDeserializationCluster(intptr_t cid)
      : MessageDeserializationCluster("TypedData"), cid_(cid) {}
  ~TypedDataMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    intptr_t count = d->ReadUnsigned();
    TypedData& data = TypedData::Handle(d->zone());
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      data = TypedData::New(cid_, length);
      d->AssignRef(data.ptr());
      const intptr_t length_in_bytes = length * element_size;
      NoSafepointScope no_safepoint;
      d->ReadBytes(data.untag()->data(), length_in_bytes);
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    Dart_TypedData_Type type;
    switch (cid_) {
      case kTypedDataInt8ArrayCid:
        type = Dart_TypedData_kInt8;
        break;
      case kTypedDataUint8ArrayCid:
        type = Dart_TypedData_kUint8;
        break;
      case kTypedDataUint8ClampedArrayCid:
        type = Dart_TypedData_kUint8Clamped;
        break;
      case kTypedDataInt16ArrayCid:
        type = Dart_TypedData_kInt16;
        break;
      case kTypedDataUint16ArrayCid:
        type = Dart_TypedData_kUint16;
        break;
      case kTypedDataInt32ArrayCid:
        type = Dart_TypedData_kInt32;
        break;
      case kTypedDataUint32ArrayCid:
        type = Dart_TypedData_kUint32;
        break;
      case kTypedDataInt64ArrayCid:
        type = Dart_TypedData_kInt64;
        break;
      case kTypedDataUint64ArrayCid:
        type = Dart_TypedData_kUint64;
        break;
      case kTypedDataFloat32ArrayCid:
        type = Dart_TypedData_kFloat32;
        break;
      case kTypedDataFloat64ArrayCid:
        type = Dart_TypedData_kFloat64;
        break;
      case kTypedDataInt32x4ArrayCid:
        type = Dart_TypedData_kInt32x4;
        break;
      case kTypedDataFloat32x4ArrayCid:
        type = Dart_TypedData_kFloat32x4;
        break;
      case kTypedDataFloat64x2ArrayCid:
        type = Dart_TypedData_kFloat64x2;
        break;
      default:
        UNREACHABLE();
    }

    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = d->Allocate(Dart_CObject_kTypedData);
      intptr_t length = d->ReadUnsigned();
      data->value.as_typed_data.type = type;
      data->value.as_typed_data.length = length;
      if (length == 0) {
        data->value.as_typed_data.values = nullptr;
      } else {
        data->value.as_typed_data.values = d->CurrentBufferAddress();
        d->Advance(length * element_size);
      }
      d->AssignRef(data);
    }
  }

 private:
  const intptr_t cid_;
};

// This function's name can appear in Observatory.
static void IsolateMessageTypedDataFinalizer(void* isolate_callback_data,
                                             void* buffer) {
  free(buffer);
}

class ExternalTypedDataMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit ExternalTypedDataMessageSerializationCluster(Zone* zone,
                                                        intptr_t cid)
      : MessageSerializationCluster("ExternalTypedData",
                                    MessagePhase::kNonCanonicalInstances,
                                    cid),
        objects_(zone, 0) {}
  ~ExternalTypedDataMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    ExternalTypedData* data = static_cast<ExternalTypedData*>(object);
    objects_.Add(data);
  }

  void WriteNodes(MessageSerializer* s) {
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);

    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ExternalTypedData* data = objects_[i];
      s->AssignRef(data);
      intptr_t length = Smi::Value(data->untag()->length_);
      s->WriteUnsigned(length);

      intptr_t length_in_bytes = length * element_size;
      void* passed_data = malloc(length_in_bytes);
      memmove(passed_data, data->untag()->data_, length_in_bytes);
      s->finalizable_data()->Put(length_in_bytes,
                                 passed_data,  // data
                                 passed_data,  // peer,
                                 IsolateMessageTypedDataFinalizer);
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<ExternalTypedData*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);

    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(data);

      intptr_t length = data->value.as_external_typed_data.length;
      s->WriteUnsigned(length);

      s->finalizable_data()->Put(length * element_size,
                                 data->value.as_external_typed_data.data,
                                 data->value.as_external_typed_data.peer,
                                 data->value.as_external_typed_data.callback);
    }
  }

 private:
  GrowableArray<ExternalTypedData*> objects_;
};

class ExternalTypedDataMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit ExternalTypedDataMessageDeserializationCluster(intptr_t cid)
      : MessageDeserializationCluster("ExternalTypedData"), cid_(cid) {}
  ~ExternalTypedDataMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);
    intptr_t count = d->ReadUnsigned();
    ExternalTypedData& data = ExternalTypedData::Handle(d->zone());
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      FinalizableData finalizable_data = d->finalizable_data()->Take();
      data = ExternalTypedData::New(
          cid_, reinterpret_cast<uint8_t*>(finalizable_data.data), length);
      intptr_t external_size = length * element_size;
      data.AddFinalizer(finalizable_data.peer, finalizable_data.callback,
                        external_size);
      d->AssignRef(data.ptr());
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    Dart_TypedData_Type type;
    switch (cid_) {
      case kExternalTypedDataInt8ArrayCid:
        type = Dart_TypedData_kInt8;
        break;
      case kExternalTypedDataUint8ArrayCid:
        type = Dart_TypedData_kUint8;
        break;
      case kExternalTypedDataUint8ClampedArrayCid:
        type = Dart_TypedData_kUint8Clamped;
        break;
      case kExternalTypedDataInt16ArrayCid:
        type = Dart_TypedData_kInt16;
        break;
      case kExternalTypedDataUint16ArrayCid:
        type = Dart_TypedData_kUint16;
        break;
      case kExternalTypedDataInt32ArrayCid:
        type = Dart_TypedData_kInt32;
        break;
      case kExternalTypedDataUint32ArrayCid:
        type = Dart_TypedData_kUint32;
        break;
      case kExternalTypedDataInt64ArrayCid:
        type = Dart_TypedData_kInt64;
        break;
      case kExternalTypedDataUint64ArrayCid:
        type = Dart_TypedData_kUint64;
        break;
      case kExternalTypedDataFloat32ArrayCid:
        type = Dart_TypedData_kFloat32;
        break;
      case kExternalTypedDataFloat64ArrayCid:
        type = Dart_TypedData_kFloat64;
        break;
      case kExternalTypedDataInt32x4ArrayCid:
        type = Dart_TypedData_kInt32x4;
        break;
      case kExternalTypedDataFloat32x4ArrayCid:
        type = Dart_TypedData_kFloat32x4;
        break;
      case kExternalTypedDataFloat64x2ArrayCid:
        type = Dart_TypedData_kFloat64x2;
        break;
      default:
        UNREACHABLE();
    }

    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = d->Allocate(Dart_CObject_kTypedData);
      intptr_t length = d->ReadUnsigned();
      FinalizableData finalizable_data = d->finalizable_data()->Get();
      data->value.as_typed_data.type = type;
      data->value.as_typed_data.length = length;
      data->value.as_typed_data.values =
          reinterpret_cast<uint8_t*>(finalizable_data.data);
      d->AssignRef(data);
    }
  }

 private:
  const intptr_t cid_;
};

class NativePointerMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit NativePointerMessageSerializationCluster(Zone* zone)
      : MessageSerializationCluster("NativePointer",
                                    MessagePhase::kNonCanonicalInstances,
                                    kNativePointer),
        objects_(zone, 0) {}
  ~NativePointerMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) { UNREACHABLE(); }

  void WriteNodes(MessageSerializer* s) { UNREACHABLE(); }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(object);
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = objects_[i];
      s->AssignRef(data);

      s->finalizable_data()->Put(
          data->value.as_native_pointer.size,
          reinterpret_cast<void*>(data->value.as_native_pointer.ptr),
          reinterpret_cast<void*>(data->value.as_native_pointer.ptr),
          data->value.as_native_pointer.callback);
    }
  }

 private:
  GrowableArray<Dart_CObject*> objects_;
};

class NativePointerMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  NativePointerMessageDeserializationCluster()
      : MessageDeserializationCluster("NativePointer"), cid_(kNativePointer) {}
  ~NativePointerMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      FinalizableData finalizable_data = d->finalizable_data()->Take();
      intptr_t ptr = reinterpret_cast<intptr_t>(finalizable_data.data);
      d->AssignRef(Integer::New(ptr));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) { UNREACHABLE(); }

 private:
  const intptr_t cid_;
};

enum TypedDataViewFormat {
  kTypedDataViewFromC,
  kTypedDataViewFromDart,
};

class TypedDataViewMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit TypedDataViewMessageSerializationCluster(Zone* zone, intptr_t cid)
      : MessageSerializationCluster("TypedDataView",
                                    MessagePhase::kNonCanonicalInstances,
                                    cid),
        objects_(zone, 0) {}
  ~TypedDataViewMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    TypedDataView* view = static_cast<TypedDataView*>(object);
    objects_.Add(view);

    s->Push(view->untag()->length());
    s->Push(view->untag()->typed_data());
    s->Push(view->untag()->offset_in_bytes());
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    s->Write<TypedDataViewFormat>(kTypedDataViewFromDart);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataView* view = objects_[i];
      s->AssignRef(view);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypedDataView* view = objects_[i];
      s->WriteRef(view->untag()->length());
      s->WriteRef(view->untag()->typed_data());
      s->WriteRef(view->untag()->offset_in_bytes());
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    ASSERT(object->type == Dart_CObject_kUnmodifiableExternalTypedData);
    objects_.Add(reinterpret_cast<TypedDataView*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t element_size = TypedDataView::ElementSizeInBytes(cid_);

    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    s->Write<TypedDataViewFormat>(kTypedDataViewFromC);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(data);

      intptr_t length = data->value.as_external_typed_data.length;
      s->WriteUnsigned(length);

      s->finalizable_data()->Put(length * element_size,
                                 data->value.as_external_typed_data.data,
                                 data->value.as_external_typed_data.peer,
                                 data->value.as_external_typed_data.callback);
    }
  }

 private:
  GrowableArray<TypedDataView*> objects_;
};

class TypedDataViewMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit TypedDataViewMessageDeserializationCluster(intptr_t cid)
      : MessageDeserializationCluster("TypedDataView"), cid_(cid) {}
  ~TypedDataViewMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    format_ = d->Read<TypedDataViewFormat>();
    if (format_ == kTypedDataViewFromC) {
      intptr_t view_cid = cid_;
      ASSERT(IsUnmodifiableTypedDataViewClassId(view_cid));
      intptr_t backing_cid = cid_ - kTypedDataCidRemainderUnmodifiable +
                             kTypedDataCidRemainderExternal;
      ASSERT(IsExternalTypedDataClassId(backing_cid));
      intptr_t element_size =
          ExternalTypedData::ElementSizeInBytes(backing_cid);
      ExternalTypedData& data = ExternalTypedData::Handle(d->zone());
      TypedDataView& view = TypedDataView::Handle(d->zone());
      for (intptr_t i = 0; i < count; i++) {
        intptr_t length = d->ReadUnsigned();
        FinalizableData finalizable_data = d->finalizable_data()->Take();
        data = ExternalTypedData::New(
            backing_cid, reinterpret_cast<uint8_t*>(finalizable_data.data),
            length);
        data.SetImmutable();  // Can pass by reference.
        intptr_t external_size = length * element_size;
        data.AddFinalizer(finalizable_data.peer, finalizable_data.callback,
                          external_size);
        view = TypedDataView::New(view_cid, data, 0, length);
        d->AssignRef(data.ptr());
      }
    } else {
      for (intptr_t i = 0; i < count; i++) {
        d->AssignRef(TypedDataView::New(cid_));
      }
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    if (format_ == kTypedDataViewFromC) return;
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypedDataViewPtr view = static_cast<TypedDataViewPtr>(d->Ref(id));
      view->untag()->set_length(static_cast<SmiPtr>(d->ReadRef()));
      view->untag()->set_typed_data(
          static_cast<TypedDataBasePtr>(d->ReadRef()));
      view->untag()->set_offset_in_bytes(static_cast<SmiPtr>(d->ReadRef()));
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    if (format_ == kTypedDataViewFromC) return nullptr;
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypedDataViewPtr view = static_cast<TypedDataViewPtr>(d->Ref(id));
      view->untag()->RecomputeDataField();
    }
    return nullptr;
  }

  struct Dart_CTypedDataView : public Dart_CObject {
    Dart_CObject* length;
    Dart_CObject* typed_data;
    Dart_CObject* offset_in_bytes;
  };

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    format_ = d->Read<TypedDataViewFormat>();
    if (format_ == kTypedDataViewFromC) {
      Dart_TypedData_Type type;
      switch (cid_) {
        case kUnmodifiableTypedDataInt8ArrayViewCid:
          type = Dart_TypedData_kInt8;
          break;
        case kUnmodifiableTypedDataUint8ArrayViewCid:
          type = Dart_TypedData_kUint8;
          break;
        case kUnmodifiableTypedDataUint8ClampedArrayViewCid:
          type = Dart_TypedData_kUint8Clamped;
          break;
        case kUnmodifiableTypedDataInt16ArrayViewCid:
          type = Dart_TypedData_kInt16;
          break;
        case kUnmodifiableTypedDataUint16ArrayViewCid:
          type = Dart_TypedData_kUint16;
          break;
        case kUnmodifiableTypedDataInt32ArrayViewCid:
          type = Dart_TypedData_kInt32;
          break;
        case kUnmodifiableTypedDataUint32ArrayViewCid:
          type = Dart_TypedData_kUint32;
          break;
        case kUnmodifiableTypedDataInt64ArrayViewCid:
          type = Dart_TypedData_kInt64;
          break;
        case kUnmodifiableTypedDataUint64ArrayViewCid:
          type = Dart_TypedData_kUint64;
          break;
        case kUnmodifiableTypedDataFloat32ArrayViewCid:
          type = Dart_TypedData_kFloat32;
          break;
        case kUnmodifiableTypedDataFloat64ArrayViewCid:
          type = Dart_TypedData_kFloat64;
          break;
        case kUnmodifiableTypedDataInt32x4ArrayViewCid:
          type = Dart_TypedData_kInt32x4;
          break;
        case kUnmodifiableTypedDataFloat32x4ArrayViewCid:
          type = Dart_TypedData_kFloat32x4;
          break;
        case kUnmodifiableTypedDataFloat64x2ArrayViewCid:
          type = Dart_TypedData_kFloat64x2;
          break;
        default:
          UNREACHABLE();
      }

      Dart_CObject* data =
          d->Allocate(Dart_CObject_kUnmodifiableExternalTypedData);
      intptr_t length = d->ReadUnsigned();
      FinalizableData finalizable_data = d->finalizable_data()->Get();
      data->value.as_typed_data.type = type;
      data->value.as_typed_data.length = length;
      data->value.as_typed_data.values =
          reinterpret_cast<uint8_t*>(finalizable_data.data);
      d->AssignRef(data);
    } else {
      for (intptr_t i = 0; i < count; i++) {
        Dart_CTypedDataView* view = d->zone()->Alloc<Dart_CTypedDataView>(1);
        d->AssignRef(view);
      }
    }
  }

  void ReadEdgesApi(ApiMessageDeserializer* d) {
    if (format_ == kTypedDataViewFromC) return;
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      Dart_CTypedDataView* view = static_cast<Dart_CTypedDataView*>(d->Ref(id));
      view->length = d->ReadRef();
      view->typed_data = d->ReadRef();
      view->offset_in_bytes = d->ReadRef();
    }
  }

  void PostLoadApi(ApiMessageDeserializer* d) {
    if (format_ == kTypedDataViewFromC) return;
    Dart_TypedData_Type type;
    switch (cid_) {
      case kTypedDataInt8ArrayViewCid:
      case kUnmodifiableTypedDataInt8ArrayViewCid:
        type = Dart_TypedData_kInt8;
        break;
      case kTypedDataUint8ArrayViewCid:
      case kUnmodifiableTypedDataUint8ArrayViewCid:
        type = Dart_TypedData_kUint8;
        break;
      case kTypedDataUint8ClampedArrayViewCid:
      case kUnmodifiableTypedDataUint8ClampedArrayViewCid:
        type = Dart_TypedData_kUint8Clamped;
        break;
      case kTypedDataInt16ArrayViewCid:
      case kUnmodifiableTypedDataInt16ArrayViewCid:
        type = Dart_TypedData_kInt16;
        break;
      case kTypedDataUint16ArrayViewCid:
      case kUnmodifiableTypedDataUint16ArrayViewCid:
        type = Dart_TypedData_kUint16;
        break;
      case kTypedDataInt32ArrayViewCid:
      case kUnmodifiableTypedDataInt32ArrayViewCid:
        type = Dart_TypedData_kInt32;
        break;
      case kTypedDataUint32ArrayViewCid:
      case kUnmodifiableTypedDataUint32ArrayViewCid:
        type = Dart_TypedData_kUint32;
        break;
      case kTypedDataInt64ArrayViewCid:
      case kUnmodifiableTypedDataInt64ArrayViewCid:
        type = Dart_TypedData_kInt64;
        break;
      case kTypedDataUint64ArrayViewCid:
      case kUnmodifiableTypedDataUint64ArrayViewCid:
        type = Dart_TypedData_kUint64;
        break;
      case kTypedDataFloat32ArrayViewCid:
      case kUnmodifiableTypedDataFloat32ArrayViewCid:
        type = Dart_TypedData_kFloat32;
        break;
      case kTypedDataFloat64ArrayViewCid:
      case kUnmodifiableTypedDataFloat64ArrayViewCid:
        type = Dart_TypedData_kFloat64;
        break;
      case kTypedDataInt32x4ArrayViewCid:
      case kUnmodifiableTypedDataInt32x4ArrayViewCid:
        type = Dart_TypedData_kInt32x4;
        break;
      case kTypedDataFloat32x4ArrayViewCid:
      case kUnmodifiableTypedDataFloat32x4ArrayViewCid:
        type = Dart_TypedData_kFloat32x4;
        break;
      case kTypedDataFloat64x2ArrayViewCid:
      case kUnmodifiableTypedDataFloat64x2ArrayViewCid:
        type = Dart_TypedData_kFloat64x2;
        break;
      default:
        UNREACHABLE();
    }

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      Dart_CTypedDataView* view = static_cast<Dart_CTypedDataView*>(d->Ref(id));
      if (view->typed_data->type == Dart_CObject_kTypedData) {
        view->type = Dart_CObject_kTypedData;
        view->value.as_typed_data.type = type;
        view->value.as_typed_data.length = view->length->value.as_int32;
        view->value.as_typed_data.values =
            view->typed_data->value.as_typed_data.values +
            view->offset_in_bytes->value.as_int32;
      } else {
        UNREACHABLE();
      }
    }
  }

 private:
  const intptr_t cid_;
  TypedDataViewFormat format_;
};

class TransferableTypedDataMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  TransferableTypedDataMessageSerializationCluster()
      : MessageSerializationCluster("TransferableTypedData",
                                    MessagePhase::kNonCanonicalInstances,
                                    kTransferableTypedDataCid) {}
  ~TransferableTypedDataMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    TransferableTypedData* transferable =
        static_cast<TransferableTypedData*>(object);
    objects_.Add(transferable);

    void* peer = s->thread()->heap()->GetPeer(transferable->ptr());
    // Assume that object's Peer is only used to track transferability state.
    ASSERT(peer != nullptr);
    TransferableTypedDataPeer* tpeer =
        reinterpret_cast<TransferableTypedDataPeer*>(peer);
    if (tpeer->data() == nullptr) {
      s->IllegalObject(*object,
                       "TransferableTypedData has been transferred already");
    }
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TransferableTypedData* transferable = objects_[i];
      s->AssignRef(transferable);

      void* peer = s->thread()->heap()->GetPeer(transferable->ptr());
      // Assume that object's Peer is only used to track transferability state.
      ASSERT(peer != nullptr);
      TransferableTypedDataPeer* tpeer =
          reinterpret_cast<TransferableTypedDataPeer*>(peer);
      intptr_t length = tpeer->length();  // In bytes.
      void* data = tpeer->data();
      ASSERT(data != nullptr);
      s->WriteUnsigned(length);
      s->finalizable_data()->Put(
          length, data, tpeer,
          // Finalizer does nothing - in case of failure to serialize,
          // [data] remains wrapped in sender's [TransferableTypedData].
          [](void* data, void* peer) {},
          // This is invoked on successful serialization of the message
          [](void* data, void* peer) {
            TransferableTypedDataPeer* ttpeer =
                reinterpret_cast<TransferableTypedDataPeer*>(peer);
            ttpeer->handle()->EnsureFreedExternal(IsolateGroup::Current());
            ttpeer->ClearData();
          });
    }
  }

 private:
  GrowableArray<TransferableTypedData*> objects_;
};

class TransferableTypedDataMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  TransferableTypedDataMessageDeserializationCluster()
      : MessageDeserializationCluster("TransferableTypedData") {}
  ~TransferableTypedDataMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      const FinalizableData finalizable_data = d->finalizable_data()->Take();
      d->AssignRef(TransferableTypedData::New(
          reinterpret_cast<uint8_t*>(finalizable_data.data), length));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* data = d->Allocate(Dart_CObject_kTypedData);
      data->value.as_typed_data.length = d->ReadUnsigned();
      data->value.as_typed_data.type = Dart_TypedData_kUint8;
      FinalizableData finalizable_data = d->finalizable_data()->Get();
      data->value.as_typed_data.values =
          reinterpret_cast<const uint8_t*>(finalizable_data.data);
      d->AssignRef(data);
    }
  }
};

class Simd128MessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit Simd128MessageSerializationCluster(intptr_t cid)
      : MessageSerializationCluster("Simd128",
                                    MessagePhase::kBeforeTypes,
                                    cid) {}
  ~Simd128MessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) { objects_.Add(object); }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Object* vector = objects_[i];
      s->AssignRef(vector);
      ASSERT_EQUAL(Int32x4::value_offset(), Float32x4::value_offset());
      ASSERT_EQUAL(Int32x4::value_offset(), Float64x2::value_offset());
      s->WriteBytes(&(static_cast<Int32x4Ptr>(vector->ptr())->untag()->value_),
                    sizeof(simd128_value_t));
    }
  }

 private:
  GrowableArray<Object*> objects_;
};

class Simd128MessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit Simd128MessageDeserializationCluster(intptr_t cid)
      : MessageDeserializationCluster("Simd128"), cid_(cid) {
    ASSERT(cid_ == kInt32x4Cid || cid_ == kFloat32x4Cid ||
           cid_ == kFloat64x2Cid);
#if defined(DEBUG)
    // If not for Int32x4, check that all the Int32x4-specific arguments used in
    // ReadNodes match those for the actual class.
    if (cid_ == kFloat32x4Cid) {
      AssertSameStructure<Int32x4, Float32x4>();
    } else if (cid_ == kFloat64x2Cid) {
      AssertSameStructure<Int32x4, Float64x2>();
    }
#endif
  }
  ~Simd128MessageDeserializationCluster() {}

#if defined(DEBUG)
  template <typename Expected, typename Got>
  static void AssertSameStructure() {
    ASSERT_EQUAL(Got::InstanceSize(), Expected::InstanceSize());
    ASSERT_EQUAL(Got::ContainsCompressedPointers(),
                 Expected::ContainsCompressedPointers());
    ASSERT_EQUAL(Object::from_offset<Got>(), Object::from_offset<Expected>());
    ASSERT_EQUAL(Object::to_offset<Got>(), Object::to_offset<Expected>());
    ASSERT_EQUAL(Got::value_offset(), Expected::value_offset());
  }
#endif

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      ObjectPtr vector = Object::Allocate(
          cid_, Int32x4::InstanceSize(), Heap::kNew,
          Int32x4::ContainsCompressedPointers(), Object::from_offset<Int32x4>(),
          Object::to_offset<Int32x4>());
      d->AssignRef(vector);
      d->ReadBytes(&(static_cast<Int32x4Ptr>(vector)->untag()->value_),
                   sizeof(simd128_value_t));
    }
  }

 private:
  const intptr_t cid_;
};

class SendPortMessageSerializationCluster : public MessageSerializationCluster {
 public:
  explicit SendPortMessageSerializationCluster(Zone* zone)
      : MessageSerializationCluster("SendPort",
                                    MessagePhase::kNonCanonicalInstances,
                                    kSendPortCid),
        objects_(zone, 0) {}
  ~SendPortMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    SendPort* port = static_cast<SendPort*>(object);
    objects_.Add(port);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      SendPort* port = objects_[i];
      s->AssignRef(port);
      s->Write<Dart_Port>(port->untag()->id_);
      s->Write<Dart_Port>(port->untag()->origin_id_);
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<SendPort*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* port = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(port);
      s->Write<Dart_Port>(port->value.as_send_port.id);
      s->Write<Dart_Port>(port->value.as_send_port.origin_id);
    }
  }

 private:
  GrowableArray<SendPort*> objects_;
};

class SendPortMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  SendPortMessageDeserializationCluster()
      : MessageDeserializationCluster("SendPort") {}
  ~SendPortMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_Port id = d->Read<Dart_Port>();
      Dart_Port origin_id = d->Read<Dart_Port>();
      d->AssignRef(SendPort::New(id, origin_id));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* port = d->Allocate(Dart_CObject_kSendPort);
      port->value.as_send_port.id = d->Read<Dart_Port>();
      port->value.as_send_port.origin_id = d->Read<Dart_Port>();
      d->AssignRef(port);
    }
  }
};

class CapabilityMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit CapabilityMessageSerializationCluster(Zone* zone)
      : MessageSerializationCluster("Capability",
                                    MessagePhase::kNonCanonicalInstances,
                                    kCapabilityCid),
        objects_(zone, 0) {}
  ~CapabilityMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Capability* cap = static_cast<Capability*>(object);
    objects_.Add(cap);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Capability* cap = objects_[i];
      s->AssignRef(cap);
      s->Write<uint64_t>(cap->untag()->id_);
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<Capability*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* cap = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(cap);
      s->Write<Dart_Port>(cap->value.as_capability.id);
    }
  }

 private:
  GrowableArray<Capability*> objects_;
};

class CapabilityMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  CapabilityMessageDeserializationCluster()
      : MessageDeserializationCluster("Capability") {}
  ~CapabilityMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      uint64_t id = d->Read<uint64_t>();
      d->AssignRef(Capability::New(id));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* cap = d->Allocate(Dart_CObject_kCapability);
      cap->value.as_capability.id = d->Read<uint64_t>();
      d->AssignRef(cap);
    }
  }
};

class MapMessageSerializationCluster : public MessageSerializationCluster {
 public:
  MapMessageSerializationCluster(Zone* zone, bool is_canonical, intptr_t cid)
      : MessageSerializationCluster("Map",
                                    is_canonical
                                        ? MessagePhase::kCanonicalInstances
                                        : MessagePhase::kNonCanonicalInstances,
                                    cid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~MapMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Map* map = static_cast<Map*>(object);
    objects_.Add(map);

    // Compensation for bogus type prefix optimization.
    TypeArguments& args =
        TypeArguments::Handle(s->zone(), map->untag()->type_arguments());
    if (!args.IsNull() && (args.Length() != 2)) {
      args = args.TruncatedTo(2);
      map->untag()->set_type_arguments(args.ptr());
    }

    s->Push(map->untag()->type_arguments());
    s->Push(map->untag()->data());
    s->Push(map->untag()->used_data());
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Map* map = objects_[i];
      s->AssignRef(map);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      Map* map = objects_[i];
      s->WriteRef(map->untag()->type_arguments());
      s->WriteRef(map->untag()->data());
      s->WriteRef(map->untag()->used_data());
    }
  }

 private:
  GrowableArray<Map*> objects_;
};

class MapMessageDeserializationCluster : public MessageDeserializationCluster {
 public:
  MapMessageDeserializationCluster(bool is_canonical, intptr_t cid)
      : MessageDeserializationCluster("Map", is_canonical), cid_(cid) {}
  ~MapMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(Map::NewUninitialized(cid_));
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      MapPtr map = static_cast<MapPtr>(d->Ref(id));
      map->untag()->set_hash_mask(Smi::New(0));
      map->untag()->set_type_arguments(
          static_cast<TypeArgumentsPtr>(d->ReadRef()));
      map->untag()->set_data(static_cast<ArrayPtr>(d->ReadRef()));
      map->untag()->set_used_data(static_cast<SmiPtr>(d->ReadRef()));
      map->untag()->set_deleted_keys(Smi::New(0));
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    if (!is_canonical()) {
      ASSERT(cid_ == kMapCid);
      return PostLoadLinkedHash(d);
    }

    ASSERT(cid_ == kConstMapCid);
    SafepointMutexLocker ml(
        d->isolate_group()->constant_canonicalization_mutex());
    Map& instance = Map::Handle(d->zone());
    for (intptr_t i = start_index_; i < stop_index_; i++) {
      instance ^= d->Ref(i);
      instance ^= instance.CanonicalizeLocked(d->thread());
      d->UpdateRef(i, instance);
    }
    return nullptr;
  }

 private:
  const intptr_t cid_;
};

class SetMessageSerializationCluster : public MessageSerializationCluster {
 public:
  SetMessageSerializationCluster(Zone* zone, bool is_canonical, intptr_t cid)
      : MessageSerializationCluster("Set",
                                    is_canonical
                                        ? MessagePhase::kCanonicalInstances
                                        : MessagePhase::kNonCanonicalInstances,
                                    cid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~SetMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Set* set = static_cast<Set*>(object);
    objects_.Add(set);

    // Compensation for bogus type prefix optimization.
    TypeArguments& args =
        TypeArguments::Handle(s->zone(), set->untag()->type_arguments());
    if (!args.IsNull() && (args.Length() != 1)) {
      args = args.TruncatedTo(1);
      set->untag()->set_type_arguments(args.ptr());
    }

    s->Push(set->untag()->type_arguments());
    s->Push(set->untag()->data());
    s->Push(set->untag()->used_data());
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Set* set = objects_[i];
      s->AssignRef(set);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      Set* set = objects_[i];
      s->WriteRef(set->untag()->type_arguments());
      s->WriteRef(set->untag()->data());
      s->WriteRef(set->untag()->used_data());
    }
  }

 private:
  GrowableArray<Set*> objects_;
};

class SetMessageDeserializationCluster : public MessageDeserializationCluster {
 public:
  SetMessageDeserializationCluster(bool is_canonical, intptr_t cid)
      : MessageDeserializationCluster("Set", is_canonical), cid_(cid) {}
  ~SetMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(Set::NewUninitialized(cid_));
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      SetPtr map = static_cast<SetPtr>(d->Ref(id));
      map->untag()->set_hash_mask(Smi::New(0));
      map->untag()->set_type_arguments(
          static_cast<TypeArgumentsPtr>(d->ReadRef()));
      map->untag()->set_data(static_cast<ArrayPtr>(d->ReadRef()));
      map->untag()->set_used_data(static_cast<SmiPtr>(d->ReadRef()));
      map->untag()->set_deleted_keys(Smi::New(0));
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    if (!is_canonical()) {
      ASSERT(cid_ == kSetCid);
      return PostLoadLinkedHash(d);
    }

    ASSERT(cid_ == kConstSetCid);
    SafepointMutexLocker ml(
        d->isolate_group()->constant_canonicalization_mutex());
    Set& instance = Set::Handle(d->zone());
    for (intptr_t i = start_index_; i < stop_index_; i++) {
      instance ^= d->Ref(i);
      instance ^= instance.CanonicalizeLocked(d->thread());
      d->UpdateRef(i, instance);
    }
    return nullptr;
  }

 private:
  const intptr_t cid_;
};

class ArrayMessageSerializationCluster : public MessageSerializationCluster {
 public:
  ArrayMessageSerializationCluster(Zone* zone, bool is_canonical, intptr_t cid)
      : MessageSerializationCluster("Array",
                                    is_canonical
                                        ? MessagePhase::kCanonicalInstances
                                        : MessagePhase::kNonCanonicalInstances,
                                    cid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~ArrayMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    Array* array = static_cast<Array*>(object);
    objects_.Add(array);

    // Compensation for bogus type prefix optimization.
    TypeArguments& args =
        TypeArguments::Handle(s->zone(), array->untag()->type_arguments());
    if (!args.IsNull() && (args.Length() != 1)) {
      args = args.TruncatedTo(1);
      array->untag()->set_type_arguments(args.ptr());
    }

    s->Push(array->untag()->type_arguments());
    intptr_t length = Smi::Value(array->untag()->length());
    for (intptr_t i = 0; i < length; i++) {
      s->Push(array->untag()->element(i));
    }
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Array* array = objects_[i];
      s->AssignRef(array);
      intptr_t length = Smi::Value(array->untag()->length());
      s->WriteUnsigned(length);
    }
  }

  void WriteEdges(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      Array* array = objects_[i];
      intptr_t length = array->Length();
      s->WriteRef(array->untag()->type_arguments());
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(array->untag()->element(j));
      }
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<Array*>(object));

    for (intptr_t i = 0, n = object->value.as_array.length; i < n; i++) {
      s->Push(object->value.as_array.values[i]);
    }
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* array = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(array);
      s->WriteUnsigned(array->value.as_array.length);
    }
  }

  void WriteEdgesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* array = reinterpret_cast<Dart_CObject*>(objects_[i]);
      intptr_t length = array->value.as_array.length;
      s->WriteRef(PredefinedCObjects::cobj_null());  // TypeArguments
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(array->value.as_array.values[j]);
      }
    }
  }

 private:
  GrowableArray<Array*> objects_;
};

class ArrayMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit ArrayMessageDeserializationCluster(bool is_canonical, intptr_t cid)
      : MessageDeserializationCluster("Array", is_canonical), cid_(cid) {}
  ~ArrayMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(Array::NewUninitialized(cid_, length));
    }
  }

  void ReadEdges(MessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ArrayPtr array = static_cast<ArrayPtr>(d->Ref(id));
      intptr_t length = Smi::Value(array->untag()->length());
      array->untag()->set_type_arguments(
          static_cast<TypeArgumentsPtr>(d->ReadRef()));
      for (intptr_t j = 0; j < length; j++) {
        array->untag()->set_element(j, d->ReadRef());
      }
    }
  }

  ObjectPtr PostLoad(MessageDeserializer* d) {
    if (is_canonical()) {
      SafepointMutexLocker ml(
          d->isolate_group()->constant_canonicalization_mutex());
      Instance& instance = Instance::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        instance ^= d->Ref(i);
        instance = instance.CanonicalizeLocked(d->thread());
        d->UpdateRef(i, instance);
      }
    }
    return nullptr;
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* array = d->Allocate(Dart_CObject_kArray);
      intptr_t length = d->ReadUnsigned();
      array->value.as_array.length = length;
      if (length == 0) {
        array->value.as_array.values = nullptr;
      } else {
        array->value.as_array.values = d->zone()->Alloc<Dart_CObject*>(length);
      }
      d->AssignRef(array);
    }
  }

  void ReadEdgesApi(ApiMessageDeserializer* d) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      Dart_CObject* array = d->Ref(id);
      intptr_t length = array->value.as_array.length;
      d->ReadRef();  // type_arguments
      for (intptr_t i = 0; i < length; i++) {
        array->value.as_array.values[i] = d->ReadRef();
      }
    }
  }

 private:
  const intptr_t cid_;
};

class OneByteStringMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit OneByteStringMessageSerializationCluster(Zone* zone,
                                                    bool is_canonical)
      : MessageSerializationCluster("OneByteString",
                                    MessagePhase::kBeforeTypes,
                                    kOneByteStringCid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~OneByteStringMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    String* str = static_cast<String*>(object);
    objects_.Add(str);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      String* str = objects_[i];
      s->AssignRef(str);
      intptr_t length = str->Length();
      s->WriteUnsigned(length);
      NoSafepointScope no_safepoint;
      s->WriteBytes(OneByteString::DataStart(*str), length * sizeof(uint8_t));
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<String*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* str = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(str);

      const uint8_t* utf8_str =
          reinterpret_cast<const uint8_t*>(str->value.as_string);
      intptr_t utf8_len = strlen(str->value.as_string);
      Utf8::Type type = Utf8::kLatin1;
      intptr_t latin1_len = Utf8::CodeUnitCount(utf8_str, utf8_len, &type);

      uint8_t* latin1_str = reinterpret_cast<uint8_t*>(
          dart::malloc(latin1_len * sizeof(uint8_t)));
      bool success =
          Utf8::DecodeToLatin1(utf8_str, utf8_len, latin1_str, latin1_len);
      ASSERT(success);
      s->WriteUnsigned(latin1_len);
      s->WriteBytes(latin1_str, latin1_len);
      ::free(latin1_str);
    }
  }

 private:
  GrowableArray<String*> objects_;
};

class OneByteStringMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit OneByteStringMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("OneByteString", is_canonical) {}
  ~OneByteStringMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      const uint8_t* data = d->CurrentBufferAddress();
      d->Advance(length * sizeof(uint8_t));
      d->AssignRef(is_canonical()
                       ? Symbols::FromLatin1(d->thread(), data, length)
                       : String::FromLatin1(data, length));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* str = d->Allocate(Dart_CObject_kString);
      intptr_t latin1_length = d->ReadUnsigned();
      const uint8_t* data = d->CurrentBufferAddress();

      d->Advance(latin1_length * sizeof(uint8_t));

      intptr_t utf8_len = 0;
      for (intptr_t i = 0; i < latin1_length; i++) {
        utf8_len += Utf8::Length(data[i]);
      }
      char* utf8_data = d->zone()->Alloc<char>(utf8_len + 1);
      str->value.as_string = utf8_data;
      for (intptr_t i = 0; i < latin1_length; i++) {
        utf8_data += Utf8::Encode(data[i], utf8_data);
      }
      *utf8_data = '\0';

      d->AssignRef(str);
    }
  }
};

class TwoByteStringMessageSerializationCluster
    : public MessageSerializationCluster {
 public:
  explicit TwoByteStringMessageSerializationCluster(Zone* zone,
                                                    bool is_canonical)
      : MessageSerializationCluster("TwoByteString",
                                    MessagePhase::kBeforeTypes,
                                    kTwoByteStringCid,
                                    is_canonical),
        objects_(zone, 0) {}
  ~TwoByteStringMessageSerializationCluster() {}

  void Trace(MessageSerializer* s, Object* object) {
    String* str = static_cast<String*>(object);
    objects_.Add(str);
  }

  void WriteNodes(MessageSerializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      String* str = objects_[i];
      s->AssignRef(str);
      intptr_t length = str->Length();
      s->WriteUnsigned(length);
      NoSafepointScope no_safepoint;
      uint16_t* utf16 = TwoByteString::DataStart(*str);
      s->WriteBytes(reinterpret_cast<const uint8_t*>(utf16),
                    length * sizeof(uint16_t));
    }
  }

  void TraceApi(ApiMessageSerializer* s, Dart_CObject* object) {
    objects_.Add(reinterpret_cast<String*>(object));
  }

  void WriteNodesApi(ApiMessageSerializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      Dart_CObject* str = reinterpret_cast<Dart_CObject*>(objects_[i]);
      s->AssignRef(str);

      const uint8_t* utf8_str =
          reinterpret_cast<const uint8_t*>(str->value.as_string);
      intptr_t utf8_len = strlen(str->value.as_string);
      Utf8::Type type = Utf8::kLatin1;
      intptr_t utf16_len = Utf8::CodeUnitCount(utf8_str, utf8_len, &type);

      uint16_t* utf16_str = reinterpret_cast<uint16_t*>(
          dart::malloc(utf16_len * sizeof(uint16_t)));
      bool success =
          Utf8::DecodeToUTF16(utf8_str, utf8_len, utf16_str, utf16_len);
      ASSERT(success);
      s->WriteUnsigned(utf16_len);
      s->WriteBytes(reinterpret_cast<const uint8_t*>(utf16_str),
                    utf16_len * sizeof(uint16_t));
      ::free(utf16_str);
    }
  }

 private:
  GrowableArray<String*> objects_;
};

class TwoByteStringMessageDeserializationCluster
    : public MessageDeserializationCluster {
 public:
  explicit TwoByteStringMessageDeserializationCluster(bool is_canonical)
      : MessageDeserializationCluster("TwoByteString", is_canonical) {}
  ~TwoByteStringMessageDeserializationCluster() {}

  void ReadNodes(MessageDeserializer* d) {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      const uint16_t* data =
          reinterpret_cast<const uint16_t*>(d->CurrentBufferAddress());
      d->Advance(length * sizeof(uint16_t));
      d->AssignRef(is_canonical()
                       ? Symbols::FromUTF16(d->thread(), data, length)
                       : String::FromUTF16(data, length));
    }
  }

  void ReadNodesApi(ApiMessageDeserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t j = 0; j < count; j++) {
      // Read all the UTF-16 code units.
      intptr_t utf16_length = d->ReadUnsigned();
      const uint16_t* utf16 =
          reinterpret_cast<const uint16_t*>(d->CurrentBufferAddress());
      d->Advance(utf16_length * sizeof(uint16_t));

      // Calculate the UTF-8 length and check if the string can be
      // UTF-8 encoded.
      intptr_t utf8_len = 0;
      bool valid = true;
      intptr_t i = 0;
      while (i < utf16_length && valid) {
        int32_t ch = Utf16::Next(utf16, &i, utf16_length);
        utf8_len += Utf8::Length(ch);
        valid = !Utf16::IsSurrogate(ch);
      }
      if (!valid) {
        d->AssignRef(d->Allocate(Dart_CObject_kUnsupported));
      } else {
        Dart_CObject* str = d->Allocate(Dart_CObject_kString);
        char* utf8 = d->zone()->Alloc<char>(utf8_len + 1);
        str->value.as_string = utf8;
        i = 0;
        while (i < utf16_length) {
          utf8 += Utf8::Encode(Utf16::Next(utf16, &i, utf16_length), utf8);
        }
        *utf8 = '\0';
        d->AssignRef(str);
      }
    }
  }
};

static constexpr intptr_t kFirstReference = 1;
static constexpr intptr_t kUnallocatedReference = -1;

BaseSerializer::BaseSerializer(Thread* thread, Zone* zone)
    : StackResource(thread),
      zone_(zone),
      stream_(100),
      finalizable_data_(new MessageFinalizableData()),
      clusters_(zone, 0),
      num_base_objects_(0),
      num_written_objects_(0),
      next_ref_index_(kFirstReference) {}

BaseSerializer::~BaseSerializer() {
  delete finalizable_data_;
}

MessageSerializer::MessageSerializer(Thread* thread)
    : BaseSerializer(thread, thread->zone()),
      forward_table_new_(),
      forward_table_old_(),
      stack_(thread->zone(), 0) {
  isolate()->set_forward_table_new(new WeakTable());
  isolate()->set_forward_table_old(new WeakTable());
}

MessageSerializer::~MessageSerializer() {
  isolate()->set_forward_table_new(nullptr);
  isolate()->set_forward_table_old(nullptr);
}

ApiMessageSerializer::ApiMessageSerializer(Zone* zone)
    : BaseSerializer(nullptr, zone), forward_table_(), stack_(zone, 0) {}

ApiMessageSerializer::~ApiMessageSerializer() {}

void MessageSerializer::Push(ObjectPtr object) {
  if (MarkObjectId(object, kUnallocatedReference)) {
    stack_.Add(&Object::ZoneHandle(zone_, object));
    num_written_objects_++;
  }
}

void ApiMessageSerializer::Push(Dart_CObject* object) {
  if (MarkObjectId(object, kUnallocatedReference)) {
    stack_.Add(object);
    num_written_objects_++;
  }
}

void MessageSerializer::Trace(const Object& root, Object* object) {
  intptr_t cid;
  bool is_canonical;
  if (!object->ptr()->IsHeapObject()) {
    cid = kSmiCid;
    is_canonical = true;
  } else {
    cid = object->GetClassId();
    is_canonical = object->ptr()->untag()->IsCanonical();
  }

  MessageSerializationCluster* cluster = nullptr;
  for (MessageSerializationCluster* c : clusters_) {
    if ((c->cid() == cid) && (c->is_canonical() == is_canonical)) {
      cluster = c;
      break;
    }
  }
  if (cluster == nullptr) {
    if (cid >= kNumPredefinedCids || cid == kInstanceCid) {
      // Will stomp over forward_table_new/old WeakTables, which should be ok,
      // as they are not going to be used again here.
      const char* message = OS::SCreate(
          zone_, "is a regular instance reachable via %s",
          FindRetainingPath(zone_, isolate(), root, *object,
                            TraversalRules::kExternalBetweenIsolateGroups));
      IllegalObject(*object, message);
    }

    const char* illegal_cid_string = nullptr;
    // Keep the list in sync with the one in lib/isolate.cc,
    // vm/object_graph_copy.cc
#define ILLEGAL(type)                                                          \
  case k##type##Cid:                                                           \
    illegal_cid_string = #type;                                                \
    break;

    switch (cid) {
      ILLEGAL(Closure)
      ILLEGAL(Finalizer)
      ILLEGAL(FinalizerEntry)
      ILLEGAL(FunctionType)
      ILLEGAL(MirrorReference)
      ILLEGAL(NativeFinalizer)
      ILLEGAL(ReceivePort)
      ILLEGAL(Record)
      ILLEGAL(RecordType)
      ILLEGAL(RegExp)
      ILLEGAL(StackTrace)
      ILLEGAL(SuspendState)
      ILLEGAL(UserTag)
      ILLEGAL(WeakProperty)
      ILLEGAL(WeakReference)
      ILLEGAL(WeakArray)

      // From "dart:ffi" we handle only Pointer/DynamicLibrary specially, since
      // those are the only non-abstract classes (so we avoid checking more cids
      // here that cannot happen in reality)
      ILLEGAL(DynamicLibrary)
      ILLEGAL(Pointer)

#undef ILLEGAL
    }

    if (illegal_cid_string != nullptr) {
      // Will stomp over forward_table_new/old WeakTables, which should be ok,
      // as they are not going to be used again here.
      const char* message = OS::SCreate(
          zone_, "is a %s reachable via %s", illegal_cid_string,
          FindRetainingPath(zone_, isolate(), root, *object,
                            TraversalRules::kExternalBetweenIsolateGroups));
      IllegalObject(*object, message);
    }

    cluster = NewClusterForClass(cid, is_canonical);
    clusters_.Add(cluster);
  }

  cluster->Trace(this, object);
}

bool ApiMessageSerializer::Trace(Dart_CObject* object) {
  const bool is_canonical = false;
  intptr_t cid;
  switch (object->type) {
    case Dart_CObject_kNull:
      ForwardRef(object, PredefinedCObjects::cobj_null());
      return true;
    case Dart_CObject_kBool:
      ForwardRef(object, object->value.as_bool ? &cobj_true : &cobj_false);
      return true;
    case Dart_CObject_kInt32:
      cid = Smi::IsValid(object->value.as_int32) ? kSmiCid : kMintCid;
      break;
    case Dart_CObject_kInt64:
      cid = Smi::IsValid(object->value.as_int64) ? kSmiCid : kMintCid;
      break;
    case Dart_CObject_kDouble:
      cid = kDoubleCid;
      break;
    case Dart_CObject_kString: {
      RELEASE_ASSERT(object->value.as_string != nullptr);
      const uint8_t* utf8_str =
          reinterpret_cast<const uint8_t*>(object->value.as_string);
      intptr_t utf8_len = strlen(object->value.as_string);
      if (!Utf8::IsValid(utf8_str, utf8_len)) {
        return Fail("invalid utf8");
      }
      Utf8::Type type = Utf8::kLatin1;
      intptr_t len = Utf8::CodeUnitCount(utf8_str, utf8_len, &type);
      if (len > String::kMaxElements) {
        return Fail("invalid string length");
      }
      cid = type == Utf8::kLatin1 ? kOneByteStringCid : kTwoByteStringCid;
      break;
    }
    case Dart_CObject_kArray:
      cid = kArrayCid;
      if (!Array::IsValidLength(object->value.as_array.length)) {
        return Fail("invalid array length");
      }
      break;
    case Dart_CObject_kTypedData:
      switch (object->value.as_typed_data.type) {
        case Dart_TypedData_kInt8:
          cid = kTypedDataInt8ArrayCid;
          break;
        case Dart_TypedData_kUint8:
          cid = kTypedDataUint8ArrayCid;
          break;
        case Dart_TypedData_kUint8Clamped:
          cid = kTypedDataUint8ClampedArrayCid;
          break;
        case Dart_TypedData_kInt16:
          cid = kTypedDataInt16ArrayCid;
          break;
        case Dart_TypedData_kUint16:
          cid = kTypedDataUint16ArrayCid;
          break;
        case Dart_TypedData_kInt32:
          cid = kTypedDataInt32ArrayCid;
          break;
        case Dart_TypedData_kUint32:
          cid = kTypedDataUint32ArrayCid;
          break;
        case Dart_TypedData_kInt64:
          cid = kTypedDataInt64ArrayCid;
          break;
        case Dart_TypedData_kUint64:
          cid = kTypedDataUint64ArrayCid;
          break;
        case Dart_TypedData_kFloat32:
          cid = kTypedDataFloat32ArrayCid;
          break;
        case Dart_TypedData_kFloat64:
          cid = kTypedDataFloat64ArrayCid;
          break;
        case Dart_TypedData_kInt32x4:
          cid = kTypedDataInt32x4ArrayCid;
          break;
        case Dart_TypedData_kFloat32x4:
          cid = kTypedDataFloat32x4ArrayCid;
          break;
        case Dart_TypedData_kFloat64x2:
          cid = kTypedDataFloat64x2ArrayCid;
          break;
        default:
          return Fail("invalid TypedData type");
      }
      {
        intptr_t len = object->value.as_typed_data.length;
        if (len < 0 || len > TypedData::MaxElements(cid)) {
          return Fail("invalid typeddata length");
        }
      }
      break;
    case Dart_CObject_kExternalTypedData:
      switch (object->value.as_external_typed_data.type) {
        case Dart_TypedData_kInt8:
          cid = kExternalTypedDataInt8ArrayCid;
          break;
        case Dart_TypedData_kUint8:
          cid = kExternalTypedDataUint8ArrayCid;
          break;
        case Dart_TypedData_kUint8Clamped:
          cid = kExternalTypedDataUint8ClampedArrayCid;
          break;
        case Dart_TypedData_kInt16:
          cid = kExternalTypedDataInt16ArrayCid;
          break;
        case Dart_TypedData_kUint16:
          cid = kExternalTypedDataUint16ArrayCid;
          break;
        case Dart_TypedData_kInt32:
          cid = kExternalTypedDataInt32ArrayCid;
          break;
        case Dart_TypedData_kUint32:
          cid = kExternalTypedDataUint32ArrayCid;
          break;
        case Dart_TypedData_kInt64:
          cid = kExternalTypedDataInt64ArrayCid;
          break;
        case Dart_TypedData_kUint64:
          cid = kExternalTypedDataUint64ArrayCid;
          break;
        case Dart_TypedData_kFloat32:
          cid = kExternalTypedDataFloat32ArrayCid;
          break;
        case Dart_TypedData_kFloat64:
          cid = kExternalTypedDataFloat64ArrayCid;
          break;
        case Dart_TypedData_kInt32x4:
          cid = kExternalTypedDataInt32x4ArrayCid;
          break;
        case Dart_TypedData_kFloat32x4:
          cid = kExternalTypedDataFloat32x4ArrayCid;
          break;
        case Dart_TypedData_kFloat64x2:
          cid = kExternalTypedDataFloat64x2ArrayCid;
          break;
        default:
          return Fail("invalid TypedData type");
      }
      {
        intptr_t len = object->value.as_typed_data.length;
        if (len < 0 || len > ExternalTypedData::MaxElements(cid)) {
          return Fail("invalid typeddata length");
        }
      }
      break;
    case Dart_CObject_kUnmodifiableExternalTypedData:
      switch (object->value.as_external_typed_data.type) {
        case Dart_TypedData_kInt8:
          cid = kUnmodifiableTypedDataInt8ArrayViewCid;
          break;
        case Dart_TypedData_kUint8:
          cid = kUnmodifiableTypedDataUint8ArrayViewCid;
          break;
        case Dart_TypedData_kUint8Clamped:
          cid = kUnmodifiableTypedDataUint8ClampedArrayViewCid;
          break;
        case Dart_TypedData_kInt16:
          cid = kUnmodifiableTypedDataInt16ArrayViewCid;
          break;
        case Dart_TypedData_kUint16:
          cid = kUnmodifiableTypedDataUint16ArrayViewCid;
          break;
        case Dart_TypedData_kInt32:
          cid = kUnmodifiableTypedDataInt32ArrayViewCid;
          break;
        case Dart_TypedData_kUint32:
          cid = kUnmodifiableTypedDataUint32ArrayViewCid;
          break;
        case Dart_TypedData_kInt64:
          cid = kUnmodifiableTypedDataInt64ArrayViewCid;
          break;
        case Dart_TypedData_kUint64:
          cid = kUnmodifiableTypedDataUint64ArrayViewCid;
          break;
        case Dart_TypedData_kFloat32:
          cid = kUnmodifiableTypedDataFloat32ArrayViewCid;
          break;
        case Dart_TypedData_kFloat64:
          cid = kUnmodifiableTypedDataFloat64ArrayViewCid;
          break;
        case Dart_TypedData_kInt32x4:
          cid = kUnmodifiableTypedDataInt32x4ArrayViewCid;
          break;
        case Dart_TypedData_kFloat32x4:
          cid = kUnmodifiableTypedDataFloat32x4ArrayViewCid;
          break;
        case Dart_TypedData_kFloat64x2:
          cid = kUnmodifiableTypedDataFloat64x2ArrayViewCid;
          break;
        default:
          return Fail("invalid TypedData type");
      }
      {
        intptr_t len = object->value.as_typed_data.length;
        if (len < 0 || len > TypedData::MaxElements(
                                 cid - kTypedDataCidRemainderUnmodifiable +
                                 kTypedDataCidRemainderInternal)) {
          return Fail("invalid typeddata length");
        }
      }
      break;
    case Dart_CObject_kSendPort:
      cid = kSendPortCid;
      break;
    case Dart_CObject_kCapability:
      cid = kCapabilityCid;
      break;
    case Dart_CObject_kNativePointer:
      cid = kNativePointer;
      break;
    default:
      return Fail("invalid Dart_CObject type");
  }

  MessageSerializationCluster* cluster = nullptr;
  for (MessageSerializationCluster* c : clusters_) {
    if (c->cid() == cid) {
      cluster = c;
      break;
    }
  }
  if (cluster == nullptr) {
    cluster = NewClusterForClass(cid, is_canonical);
    clusters_.Add(cluster);
  }

  cluster->TraceApi(this, object);
  return true;
}

void MessageSerializer::IllegalObject(const Object& object,
                                      const char* message) {
  const Array& args = Array::Handle(zone(), Array::New(3));
  args.SetAt(0, object);
  args.SetAt(2, String::Handle(zone(), String::New(message)));
  Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
}

BaseDeserializer::BaseDeserializer(Zone* zone, Message* message)
    : zone_(zone),
      stream_(message->snapshot(), message->snapshot_length()),
      finalizable_data_(message->finalizable_data()),
      next_ref_index_(kFirstReference) {}

BaseDeserializer::~BaseDeserializer() {}

MessageSerializationCluster* BaseSerializer::NewClusterForClass(
    intptr_t cid,
    bool is_canonical) {
  Zone* Z = zone_;
  if (IsTypedDataViewClassId(cid) || cid == kByteDataViewCid ||
      IsUnmodifiableTypedDataViewClassId(cid) ||
      cid == kUnmodifiableByteDataViewCid) {
    return new (Z) TypedDataViewMessageSerializationCluster(Z, cid);
  }
  if (IsExternalTypedDataClassId(cid)) {
    return new (Z) ExternalTypedDataMessageSerializationCluster(Z, cid);
  }
  if (IsTypedDataClassId(cid)) {
    return new (Z) TypedDataMessageSerializationCluster(Z, cid);
  }

  switch (cid) {
    case kNativePointer:
      return new (Z) NativePointerMessageSerializationCluster(Z);
    case kClassCid:
      return new (Z) ClassMessageSerializationCluster();
    case kTypeArgumentsCid:
      return new (Z) TypeArgumentsMessageSerializationCluster(is_canonical);
    case kTypeCid:
      return new (Z) TypeMessageSerializationCluster(is_canonical);
    case kSmiCid:
      return new (Z) SmiMessageSerializationCluster(Z);
    case kMintCid:
      return new (Z) MintMessageSerializationCluster(Z, is_canonical);
    case kDoubleCid:
      return new (Z) DoubleMessageSerializationCluster(Z, is_canonical);
    case kGrowableObjectArrayCid:
      return new (Z) GrowableObjectArrayMessageSerializationCluster();
    case kSendPortCid:
      return new (Z) SendPortMessageSerializationCluster(Z);
    case kCapabilityCid:
      return new (Z) CapabilityMessageSerializationCluster(Z);
    case kTransferableTypedDataCid:
      return new (Z) TransferableTypedDataMessageSerializationCluster();
    case kMapCid:
    case kConstMapCid:
      return new (Z) MapMessageSerializationCluster(Z, is_canonical, cid);
    case kSetCid:
    case kConstSetCid:
      return new (Z) SetMessageSerializationCluster(Z, is_canonical, cid);
    case kArrayCid:
    case kImmutableArrayCid:
      return new (Z) ArrayMessageSerializationCluster(Z, is_canonical, cid);
    case kOneByteStringCid:
      return new (Z) OneByteStringMessageSerializationCluster(Z, is_canonical);
    case kTwoByteStringCid:
      return new (Z) TwoByteStringMessageSerializationCluster(Z, is_canonical);
    case kInt32x4Cid:
    case kFloat32x4Cid:
    case kFloat64x2Cid:
      return new (Z) Simd128MessageSerializationCluster(cid);
    default:
      break;
  }

  FATAL("No cluster defined for cid %" Pd, cid);
  return nullptr;
}

void BaseSerializer::WriteCluster(MessageSerializationCluster* cluster) {
  uint64_t cid_and_canonical = (static_cast<uint64_t>(cluster->cid()) << 1) |
                               (cluster->is_canonical() ? 0x1 : 0x0);
  WriteUnsigned(cid_and_canonical);
}

MessageDeserializationCluster* BaseDeserializer::ReadCluster() {
  const uint64_t cid_and_canonical = ReadUnsigned();
  const intptr_t cid = (cid_and_canonical >> 1) & kMaxUint32;
  const bool is_canonical = (cid_and_canonical & 0x1) == 0x1;

  Zone* Z = zone_;
  if (IsTypedDataViewClassId(cid) || cid == kByteDataViewCid ||
      IsUnmodifiableTypedDataViewClassId(cid) ||
      cid == kUnmodifiableByteDataViewCid) {
    ASSERT(!is_canonical);
    return new (Z) TypedDataViewMessageDeserializationCluster(cid);
  }
  if (IsExternalTypedDataClassId(cid)) {
    ASSERT(!is_canonical);
    return new (Z) ExternalTypedDataMessageDeserializationCluster(cid);
  }
  if (IsTypedDataClassId(cid)) {
    ASSERT(!is_canonical);
    return new (Z) TypedDataMessageDeserializationCluster(cid);
  }

  switch (cid) {
    case kNativePointer:
      ASSERT(!is_canonical);
      return new (Z) NativePointerMessageDeserializationCluster();
    case kClassCid:
      ASSERT(!is_canonical);
      return new (Z) ClassMessageDeserializationCluster();
    case kTypeArgumentsCid:
      return new (Z) TypeArgumentsMessageDeserializationCluster(is_canonical);
    case kTypeCid:
      return new (Z) TypeMessageDeserializationCluster(is_canonical);
    case kSmiCid:
      ASSERT(is_canonical);
      return new (Z) SmiMessageDeserializationCluster();
    case kMintCid:
      return new (Z) MintMessageDeserializationCluster(is_canonical);
    case kDoubleCid:
      return new (Z) DoubleMessageDeserializationCluster(is_canonical);
    case kGrowableObjectArrayCid:
      ASSERT(!is_canonical);
      return new (Z) GrowableObjectArrayMessageDeserializationCluster();
    case kSendPortCid:
      ASSERT(!is_canonical);
      return new (Z) SendPortMessageDeserializationCluster();
    case kCapabilityCid:
      ASSERT(!is_canonical);
      return new (Z) CapabilityMessageDeserializationCluster();
    case kTransferableTypedDataCid:
      ASSERT(!is_canonical);
      return new (Z) TransferableTypedDataMessageDeserializationCluster();
    case kMapCid:
    case kConstMapCid:
      return new (Z) MapMessageDeserializationCluster(is_canonical, cid);
    case kSetCid:
    case kConstSetCid:
      return new (Z) SetMessageDeserializationCluster(is_canonical, cid);
    case kArrayCid:
    case kImmutableArrayCid:
      return new (Z) ArrayMessageDeserializationCluster(is_canonical, cid);
    case kOneByteStringCid:
      return new (Z) OneByteStringMessageDeserializationCluster(is_canonical);
    case kTwoByteStringCid:
      return new (Z) TwoByteStringMessageDeserializationCluster(is_canonical);
    case kInt32x4Cid:
    case kFloat32x4Cid:
    case kFloat64x2Cid:
      ASSERT(!is_canonical);
      return new (Z) Simd128MessageDeserializationCluster(cid);
    default:
      break;
  }

  FATAL("No cluster defined for cid %" Pd, cid);
  return nullptr;
}

void MessageSerializer::AddBaseObjects() {
  AddBaseObject(Object::null());
  AddBaseObject(Object::sentinel().ptr());
  AddBaseObject(Object::transition_sentinel().ptr());
  AddBaseObject(Object::empty_array().ptr());
  AddBaseObject(Object::dynamic_type().ptr());
  AddBaseObject(Object::void_type().ptr());
  AddBaseObject(Object::empty_type_arguments().ptr());
  AddBaseObject(Bool::True().ptr());
  AddBaseObject(Bool::False().ptr());
}

void MessageDeserializer::AddBaseObjects() {
  AddBaseObject(Object::null());
  AddBaseObject(Object::sentinel().ptr());
  AddBaseObject(Object::transition_sentinel().ptr());
  AddBaseObject(Object::empty_array().ptr());
  AddBaseObject(Object::dynamic_type().ptr());
  AddBaseObject(Object::void_type().ptr());
  AddBaseObject(Object::empty_type_arguments().ptr());
  AddBaseObject(Bool::True().ptr());
  AddBaseObject(Bool::False().ptr());
}

void ApiMessageSerializer::AddBaseObjects() {
  AddBaseObject(PredefinedCObjects::cobj_null());
  AddBaseObject(&cobj_sentinel);
  AddBaseObject(&cobj_transition_sentinel);
  AddBaseObject(PredefinedCObjects::cobj_empty_array());
  AddBaseObject(&cobj_dynamic_type);
  AddBaseObject(&cobj_void_type);
  AddBaseObject(&cobj_empty_type_arguments);
  AddBaseObject(&cobj_true);
  AddBaseObject(&cobj_false);
}

void ApiMessageDeserializer::AddBaseObjects() {
  AddBaseObject(PredefinedCObjects::cobj_null());
  AddBaseObject(&cobj_sentinel);
  AddBaseObject(&cobj_transition_sentinel);
  AddBaseObject(PredefinedCObjects::cobj_empty_array());
  AddBaseObject(&cobj_dynamic_type);
  AddBaseObject(&cobj_void_type);
  AddBaseObject(&cobj_empty_type_arguments);
  AddBaseObject(&cobj_true);
  AddBaseObject(&cobj_false);
}

void MessageSerializer::Serialize(const Object& root) {
  AddBaseObjects();

  Push(root.ptr());

  while (stack_.length() > 0) {
    Trace(root, stack_.RemoveLast());
  }

  intptr_t num_objects = num_base_objects_ + num_written_objects_;
  WriteUnsigned(num_base_objects_);
  WriteUnsigned(num_objects);

  for (intptr_t i = 0; i < static_cast<intptr_t>(MessagePhase::kNumPhases);
       i++) {
    intptr_t num_clusters = 0;
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      num_clusters++;
    }
    WriteUnsigned(num_clusters);
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      WriteCluster(cluster);
      cluster->WriteNodes(this);
    }
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      cluster->WriteEdges(this);
    }
  }

  // We should have assigned a ref to every object we pushed.
  ASSERT((next_ref_index_ - 1) == num_objects);

  WriteRef(root.ptr());
}

bool ApiMessageSerializer::Serialize(Dart_CObject* root) {
  AddBaseObjects();

  Push(root);

  // Strong references only.
  while (stack_.length() > 0) {
    if (!Trace(stack_.RemoveLast())) {
      return false;
    }
  }

  intptr_t num_objects = num_base_objects_ + num_written_objects_;
  WriteUnsigned(num_base_objects_);
  WriteUnsigned(num_objects);

  for (intptr_t i = 0; i < static_cast<intptr_t>(MessagePhase::kNumPhases);
       i++) {
    intptr_t num_clusters = 0;
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      num_clusters++;
    }
    WriteUnsigned(num_clusters);
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      WriteCluster(cluster);
      cluster->WriteNodesApi(this);
    }
    for (MessageSerializationCluster* cluster : clusters_) {
      if (static_cast<intptr_t>(cluster->phase()) != i) continue;
      cluster->WriteEdgesApi(this);
    }
  }

  // We should have assigned a ref to every object we pushed.
  ASSERT((next_ref_index_ - 1) == num_objects);

  WriteRef(root);
  return true;
}

ObjectPtr MessageDeserializer::Deserialize() {
  intptr_t num_base_objects = ReadUnsigned();
  intptr_t num_objects = ReadUnsigned();

  refs_ = Array::New(num_objects + kFirstReference);

  AddBaseObjects();

  // Writer and reader must agree on number of base objects.
  ASSERT_EQUAL(num_base_objects, (next_ref_index_ - kFirstReference));

  Object& error = Object::Handle(zone());
  for (intptr_t i = 0; i < static_cast<intptr_t>(MessagePhase::kNumPhases);
       i++) {
    intptr_t num_clusters = ReadUnsigned();
    MessageDeserializationCluster** clusters =
        zone()->Alloc<MessageDeserializationCluster*>(num_clusters);
    for (intptr_t i = 0; i < num_clusters; i++) {
      clusters[i] = ReadCluster();
      clusters[i]->ReadNodesWrapped(this);
    }
    for (intptr_t i = 0; i < num_clusters; i++) {
      clusters[i]->ReadEdges(this);
    }
    for (intptr_t i = 0; i < num_clusters; i++) {
      error = clusters[i]->PostLoad(this);
      if (error.IsError()) {
        return error.ptr();  // E.g., an UnwindError during rehashing.
      }
    }
  }

  // We should have completely filled the ref array.
  ASSERT_EQUAL(next_ref_index_ - kFirstReference, num_objects);

  return ReadRef();
}

Dart_CObject* ApiMessageDeserializer::Deserialize() {
  intptr_t num_base_objects = ReadUnsigned();
  intptr_t num_objects = ReadUnsigned();

  refs_ = zone()->Alloc<Dart_CObject*>(num_objects + kFirstReference);

  AddBaseObjects();

  // Writer and reader must agree on number of base objects.
  ASSERT_EQUAL(num_base_objects, (next_ref_index_ - kFirstReference));

  for (intptr_t i = 0; i < static_cast<intptr_t>(MessagePhase::kNumPhases);
       i++) {
    intptr_t num_clusters = ReadUnsigned();
    MessageDeserializationCluster** clusters =
        zone()->Alloc<MessageDeserializationCluster*>(num_clusters);
    for (intptr_t i = 0; i < num_clusters; i++) {
      clusters[i] = ReadCluster();
      clusters[i]->ReadNodesWrappedApi(this);
    }
    for (intptr_t i = 0; i < num_clusters; i++) {
      clusters[i]->ReadEdgesApi(this);
    }
    for (intptr_t i = 0; i < num_clusters; i++) {
      clusters[i]->PostLoadApi(this);
    }
  }

  // We should have completely filled the ref array.
  ASSERT_EQUAL(next_ref_index_ - kFirstReference, num_objects);

  return ReadRef();
}

std::unique_ptr<Message> WriteMessage(bool same_group,
                                      const Object& obj,
                                      Dart_Port dest_port,
                                      Message::Priority priority) {
  if (ApiObjectConverter::CanConvert(obj.ptr())) {
    return Message::New(dest_port, obj.ptr(), priority);
  } else if (same_group) {
    const Object& copy = Object::Handle(CopyMutableObjectGraph(obj));
    auto handle =
        IsolateGroup::Current()->api_state()->AllocatePersistentHandle();
    handle->set_ptr(copy.ptr());
    return std::make_unique<Message>(dest_port, handle, priority);
  }

  Thread* thread = Thread::Current();
  MessageSerializer serializer(thread);
  serializer.Serialize(obj);
  return serializer.Finish(dest_port, priority);
}

std::unique_ptr<Message> WriteApiMessage(Zone* zone,
                                         Dart_CObject* obj,
                                         Dart_Port dest_port,
                                         Message::Priority priority) {
  ApiMessageSerializer serializer(zone);
  if (!serializer.Serialize(obj)) {
    return nullptr;
  }
  return serializer.Finish(dest_port, priority);
}

ObjectPtr ReadObjectGraphCopyMessage(Thread* thread, PersistentHandle* handle) {
  // msg_array = [
  //     <message>,
  //     <collection-lib-objects-to-rehash>,
  //     <core-lib-objects-to-rehash>,
  // ]
  Zone* zone = thread->zone();
  Object& msg_obj = Object::Handle(zone);
  const auto& msg_array = Array::Handle(zone, Array::RawCast(handle->ptr()));
  ASSERT(msg_array.Length() == 3);
  msg_obj = msg_array.At(0);
  if (msg_array.At(1) != Object::null()) {
    const auto& objects_to_rehash = Object::Handle(zone, msg_array.At(1));
    auto& result = Object::Handle(zone);
    result = DartLibraryCalls::RehashObjectsInDartCollection(thread,
                                                             objects_to_rehash);
    if (result.ptr() != Object::null()) {
      msg_obj = result.ptr();
    }
  }
  if (msg_array.At(2) != Object::null()) {
    const auto& objects_to_rehash = Object::Handle(zone, msg_array.At(2));
    auto& result = Object::Handle(zone);
    result =
        DartLibraryCalls::RehashObjectsInDartCore(thread, objects_to_rehash);
    if (result.ptr() != Object::null()) {
      msg_obj = result.ptr();
    }
  }
  return msg_obj.ptr();
}

ObjectPtr ReadMessage(Thread* thread, Message* message) {
  if (message->IsRaw()) {
    return message->raw_obj();
  } else if (message->IsFinalizerInvocationRequest()) {
    PersistentHandle* handle = message->persistent_handle();
    Object& msg_obj = Object::Handle(thread->zone(), handle->ptr());
    ASSERT(msg_obj.IsFinalizer() || msg_obj.IsNativeFinalizer());
    return msg_obj.ptr();
  } else if (message->IsPersistentHandle()) {
    return ReadObjectGraphCopyMessage(thread, message->persistent_handle());
  } else {
    RELEASE_ASSERT(message->IsSnapshot());
    LongJumpScope jump(thread);
    if (setjmp(*jump.Set()) == 0) {
      MessageDeserializer deserializer(thread, message);
      return deserializer.Deserialize();
    } else {
      return thread->StealStickyError();
    }
  }
}

Dart_CObject* ReadApiMessage(Zone* zone, Message* message) {
  if (message->IsRaw()) {
    Dart_CObject* result = zone->Alloc<Dart_CObject>(1);
    ApiObjectConverter::Convert(message->raw_obj(), result);
    return result;
  } else {
    RELEASE_ASSERT(message->IsSnapshot());
    ApiMessageDeserializer deserializer(zone, message);
    return deserializer.Deserialize();
  }
}

}  // namespace dart
