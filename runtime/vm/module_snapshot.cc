// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <memory>
#include <utility>

#include "vm/module_snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/canonical_tables.h"
#include "vm/class_id.h"
#include "vm/code_observers.h"
#include "vm/compiler/api/print_filter.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/dart.h"
#include "vm/dart_entry.h"
#include "vm/dispatch_table.h"
#include "vm/flag_list.h"
#include "vm/growable_array.h"
#include "vm/heap/heap.h"
#include "vm/image_snapshot.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/version.h"
#include "vm/zone_text_buffer.h"

namespace dart {
namespace module_snapshot {

class ModuleSnapshot : public AllStatic {
 public:
  // Version of module snapshot format.
  // Should match Snapshot.moduleSnapshotFormatVersion
  // constant declared in pkg/native_compiler/lib/snapshot/snapshot.dart.
  static constexpr intptr_t kFormatVersion = 1;

  // Predefined clusters in the module snapshot.
  // Should match PredefinedClusters enum
  // declared in pkg/native_compiler/lib/snapshot/snapshot.dart.
  enum PredefinedClusters {
    kOneByteStrings,
    kTwoByteStrings,
    kLibraryRefs,
    kPrivateNames,
    kClassRefs,
    kFieldRefs,
    kFunctionRefs,
    kClosureFunctionRefs,
    kClosureRefs,
    kArgumentsDescriptorRefs,
    kInts,
    kDoubles,
    kLists,
    kMaps,
    kSets,
    kRecords,
    kInstantiatedClosures,
    kTypeParameters,
    kInterfaceTypes,
    kFunctionTypes,
    kRecordTypes,
    kTypeParameterTypes,
    kTypeArguments,
    kCodes,
    kICDatas,
    kObjectPools,
    kInstances,
  };

  // Function kinds in the module snapshot.
  // Should match FunctionKind enum
  // declared in pkg/native_compiler/lib/snapshot/snapshot.dart.
  enum FunctionKind {
    kRegular,
    kGetter,
    kSetter,
    kGenerativeConstructor,
    kFactoryConstructor,
    kImplicitGetter,
    kImplicitSetter,
    kFieldInitializer,
  };

  // Object pool entry kinds in the module snapshots.
  // Should match ObjectPoolEntryKind enum
  // declared in pkg/native_compiler/lib/snapshot/snapshot.dart.
  enum ObjectPoolEntryKind {
    kObjectRef,
    kNewObjectTags,
    kInterfaceCall,
  };
};

class Deserializer;

class DeserializationCluster : public ZoneObject {
 public:
  explicit DeserializationCluster(const char* name,
                                  bool is_deeply_immutable = false)
      : name_(name),
        is_deeply_immutable_(is_deeply_immutable),
        start_index_(-1),
        stop_index_(-1) {}
  virtual ~DeserializationCluster() {}

  // Read references to base objects.
  virtual void PreLoad(Deserializer* deserializer) {}

  // Allocate memory for all objects in the cluster and write their addresses
  // into the ref array. Do not touch this memory.
  virtual void ReadAlloc(Deserializer* deserializer) {}

  // Initialize the cluster's objects. Do not touch the memory of other objects.
  virtual void ReadFill(Deserializer* deserializer) {}

  // Complete any action that requires the full graph to be deserialized, such
  // as rehashing.
  virtual void PostLoad(Deserializer* deserializer, const Array& refs) {}

  const char* name() const { return name_; }
  bool is_deeply_immutable() const { return is_deeply_immutable_; }

 protected:
  void ReadAllocFixedSize(Deserializer* deserializer, intptr_t instance_size);

  const char* const name_;
  const bool is_deeply_immutable_;
  // The range of the ref array that belongs to this cluster.
  intptr_t start_index_;
  intptr_t stop_index_;
};

static constexpr intptr_t kFirstReference = 1;

class Deserializer : public ThreadStackResource {
 public:
  Deserializer(Thread* thread,
               const uint8_t* buffer,
               intptr_t size,
               const uint8_t* instructions_buffer);
  ~Deserializer();

  ApiErrorPtr VerifyVersionAndFeatures();

  ObjectPtr Allocate(intptr_t size);
  static void InitializeHeader(ObjectPtr raw,
                               intptr_t cid,
                               intptr_t size,
                               bool is_deeply_immutable = false);

  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }
  intptr_t ReadRefId() { return stream_.ReadRefId(); }
  intptr_t ReadUnsigned() { return stream_.ReadUnsigned(); }
  uint64_t ReadUnsigned64() { return stream_.ReadUnsigned<uint64_t>(); }
  void ReadBytes(uint8_t* addr, intptr_t len) { stream_.ReadBytes(addr, len); }

  intptr_t position() const { return stream_.Position(); }
  void set_position(intptr_t p) { stream_.SetPosition(p); }
  const uint8_t* AddressOfCurrentPosition() const {
    return stream_.AddressOfCurrentPosition();
  }
  void Advance(intptr_t value) { stream_.Advance(value); }

  void AddBaseObject(const Object& object) { AssignRefPreLoad(object); }

  void AssignRefPreLoad(const Object& object) {
    refs_array_.SetAt(next_ref_index_, object);
    next_ref_index_++;
  }

  void AssignRef(ObjectPtr object) {
    ASSERT(next_ref_index_ <= num_objects_);
    refs_->untag()->data()[next_ref_index_] = object;
    next_ref_index_++;
  }

  ObjectPtr Ref(intptr_t index) const {
    ASSERT(index > 0);
    ASSERT(index <= num_objects_);
    return refs_array_.At(index);
  }

  ObjectPtr ReadRef() { return Ref(ReadRefId()); }

  void Deserialize();

  DeserializationCluster* ReadCluster();

  uword instructions() const {
    return reinterpret_cast<uword>(instructions_buffer_);
  }
  intptr_t next_index() const { return next_ref_index_; }
  Heap* heap() const { return heap_; }
  Zone* zone() const { return zone_; }

  // This serves to make the snapshot cursor, ref table and null be locals
  // during ReadFill, which allows the C compiler to see they are not aliased
  // and can be kept in registers.
  class Local : public ReadStream {
   public:
    explicit Local(Deserializer* d)
        : ReadStream(d->stream_.buffer_, d->stream_.current_, d->stream_.end_),
          d_(d),
          refs_(d->refs_),
          null_(Object::null()) {
#if defined(DEBUG)
      // Can't mix use of Deserializer::Read*.
      d->stream_.current_ = nullptr;
#endif
    }
    ~Local() { d_->stream_.current_ = current_; }

    ObjectPtr Ref(intptr_t index) const {
      ASSERT(index > 0);
      ASSERT(index <= d_->num_objects_);
      return refs_->untag()->element(index);
    }

    template <typename T>
    T Read() {
      return ReadStream::Raw<sizeof(T), T>::Read(this);
    }
    uint64_t ReadUnsigned64() { return ReadUnsigned<uint64_t>(); }

    ObjectPtr ReadRef() { return Ref(ReadRefId()); }

    ObjectPtr null() const { return null_; }

   private:
    Deserializer* const d_;
    const ArrayPtr refs_;
    const ObjectPtr null_;
  };

 private:
  Heap* heap_;
  PageSpace* old_space_;
  FreeList* freelist_;
  Zone* zone_;
  ReadStream stream_;
  const uint8_t* instructions_buffer_;
  intptr_t num_base_objects_ = 0;
  intptr_t num_objects_ = 0;
  intptr_t num_clusters_ = 0;
  Array& refs_array_;
  ArrayPtr refs_;
  intptr_t next_ref_index_ = kFirstReference;
  DeserializationCluster** clusters_ = nullptr;
};

DART_FORCE_INLINE
ObjectPtr Deserializer::Allocate(intptr_t size) {
  return UntaggedObject::FromAddr(
      old_space_->AllocateSnapshotLocked(freelist_, size));
}

void Deserializer::InitializeHeader(ObjectPtr raw,
                                    intptr_t class_id,
                                    intptr_t size,
                                    bool is_deeply_immutable) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword tags = 0;
  tags = UntaggedObject::ClassIdTag::update(class_id, tags);
  tags = UntaggedObject::SizeTag::update(size, tags);
  tags = UntaggedObject::CanonicalBit::update(false, tags);
  tags = UntaggedObject::AlwaysSetBit::update(true, tags);
  tags = UntaggedObject::NotMarkedBit::update(true, tags);
  tags = UntaggedObject::OldAndNotRememberedBit::update(true, tags);
  tags = UntaggedObject::NewOrEvacuationCandidateBit::update(false, tags);
  tags = UntaggedObject::ShallowImmutableBit::update(
      Object::ShouldHaveShallowImmutabilityBitSet(class_id), tags);
  tags = UntaggedObject::DeeplyImmutableBit::update(is_deeply_immutable, tags);
  raw->untag()->tags_ = tags;
}

DART_NOINLINE
void DeserializationCluster::ReadAllocFixedSize(Deserializer* d,
                                                intptr_t instance_size) {
  start_index_ = d->next_index();
  intptr_t count = d->ReadUnsigned();
  for (intptr_t i = 0; i < count; i++) {
    d->AssignRef(d->Allocate(instance_size));
  }
  stop_index_ = d->next_index();
}

class OneByteStringDeserializationCluster : public DeserializationCluster {
 public:
  explicit OneByteStringDeserializationCluster(Zone* zone)
      : DeserializationCluster("OneByteString"),
        string_(String::Handle(zone)) {}
  ~OneByteStringDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t len = d->ReadUnsigned();
      string_ =
          Symbols::FromLatin1(d->thread(), d->AddressOfCurrentPosition(), len);
      d->Advance(len);
      d->AssignRefPreLoad(string_);
    }
  }

 private:
  String& string_;
};

class TwoByteStringDeserializationCluster : public DeserializationCluster {
 public:
  explicit TwoByteStringDeserializationCluster(Zone* zone)
      : DeserializationCluster("TwoByteString"),
        string_(String::Handle(zone)) {}
  ~TwoByteStringDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t len = d->ReadUnsigned();
      string_ = Symbols::FromUTF16(
          d->thread(),
          reinterpret_cast<const uint16_t*>(d->AddressOfCurrentPosition()),
          len);
      d->Advance(len << 1);
      d->AssignRefPreLoad(string_);
    }
  }

 private:
  String& string_;
};

class LibraryRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit LibraryRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("LibraryRef"),
        uri_(String::Handle(zone)),
        library_(Library::Handle(zone)) {}
  ~LibraryRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      uri_ = static_cast<StringPtr>(d->ReadRef());
      library_ = Library::LookupLibrary(d->thread(), uri_);
      if (library_.IsNull()) {
        FATAL("Unable to find library %s", uri_.ToCString());
      }
      d->AssignRefPreLoad(library_);
    }
  }

 private:
  String& uri_;
  Library& library_;
};

class ClassRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit ClassRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("ClassRef"),
        library_(Library::Handle(zone)),
        class_name_(String::Handle(zone)),
        class_(Class::Handle(zone)) {}
  ~ClassRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      library_ = static_cast<LibraryPtr>(d->ReadRef());
      class_name_ = static_cast<StringPtr>(d->ReadRef());
      class_ = library_.LookupClass(class_name_);
      if (class_.IsNull()) {
        FATAL("Unable to find class %s in %s", class_name_.ToCString(),
              library_.ToCString());
      }
      d->AssignRefPreLoad(class_);
    }
  }

 private:
  Library& library_;
  String& class_name_;
  Class& class_;
};

class PrivateNameDeserializationCluster : public DeserializationCluster {
 public:
  explicit PrivateNameDeserializationCluster(Zone* zone)
      : DeserializationCluster("PrivateName"),
        library_(Library::Handle(zone)),
        name_(String::Handle(zone)) {}
  ~PrivateNameDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      library_ = static_cast<LibraryPtr>(d->ReadRef());
      name_ = static_cast<StringPtr>(d->ReadRef());
      name_ = library_.PrivateName(name_);
      d->AssignRefPreLoad(name_);
    }
  }

 private:
  Library& library_;
  String& name_;
};

class FieldRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit FieldRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("FieldRef"),
        owner_(Object::Handle(zone)),
        field_name_(String::Handle(zone)),
        field_(Field::Handle(zone)) {}
  ~FieldRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      owner_ = d->ReadRef();
      field_name_ = static_cast<StringPtr>(d->ReadRef());
      if (owner_.IsLibrary()) {
        owner_ = Library::Cast(owner_).toplevel_class();
      }
      field_ = Class::Cast(owner_).LookupField(field_name_);
      if (field_.IsNull()) {
        FATAL("Unable to find field %s in %s", field_name_.ToCString(),
              owner_.ToCString());
      }
      d->AssignRefPreLoad(field_);
    }
  }

 private:
  Object& owner_;
  String& field_name_;
  Field& field_;
};

class FunctionRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit FunctionRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("FunctionRef"),
        zone_(zone),
        owner_(Object::Handle(zone)),
        class_name_(String::Handle(zone)),
        function_name_(String::Handle(zone)),
        function_(Function::Handle(zone)),
        field_(Field::Handle(zone)) {}
  ~FunctionRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const auto kind =
          static_cast<ModuleSnapshot::FunctionKind>(d->ReadUnsigned());
      owner_ = d->ReadRef();
      if (owner_.IsLibrary()) {
        owner_ = Library::Cast(owner_).toplevel_class();
      }
      function_name_ = static_cast<StringPtr>(d->ReadRef());
      switch (kind) {
        case ModuleSnapshot::kRegular:
          break;
        case ModuleSnapshot::kGetter:
        case ModuleSnapshot::kImplicitGetter:
          function_name_ = Field::GetterName(function_name_);
          break;
        case ModuleSnapshot::kSetter:
        case ModuleSnapshot::kImplicitSetter:
          function_name_ = Field::SetterName(function_name_);
          break;
        case ModuleSnapshot::kFieldInitializer:
          field_ = Class::Cast(owner_).LookupField(function_name_);
          if (field_.IsNull()) {
            FATAL("Unable to find field %s in %s", function_name_.ToCString(),
                  owner_.ToCString());
          }
          function_ = field_.EnsureInitializerFunction();
          ASSERT(!function_.IsNull());
          break;
        case ModuleSnapshot::kGenerativeConstructor:
        case ModuleSnapshot::kFactoryConstructor: {
          class_name_ = Class::Cast(owner_).Name();
          GrowableHandlePtrArray<const String> pieces(zone_, 3);
          pieces.Add(class_name_);
          pieces.Add(Symbols::Dot());
          pieces.Add(function_name_);
          function_name_ = Symbols::FromConcatAll(d->thread(), pieces);
        } break;
      }
      if (kind != ModuleSnapshot::kFieldInitializer) {
        function_ = Resolver::ResolveFunction(zone_, Class::Cast(owner_),
                                              function_name_);
        if (function_.IsNull()) {
          FATAL("Unable to find function %s in %s", function_name_.ToCString(),
                owner_.ToCString());
        }
      }
      d->AssignRefPreLoad(function_);
    }
  }

 private:
  Zone* zone_;
  Object& owner_;
  String& class_name_;
  String& function_name_;
  Function& function_;
  Field& field_;
};

class ClosureFunctionRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit ClosureFunctionRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("ClosureFunctionRef"),
        function_(Function::Handle(zone)) {}
  ~ClosureFunctionRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const bool is_tear_off = d->ReadUnsigned() != 0;
      function_ = static_cast<FunctionPtr>(d->ReadRef());
      if (is_tear_off) {
        function_ = function_.ImplicitClosureFunction();
      } else {
        // TODO(alexmarkov): support local functions
        UNIMPLEMENTED();
      }
      d->AssignRefPreLoad(function_);
    }
  }

 private:
  Function& function_;
};

class ClosureRefDeserializationCluster : public DeserializationCluster {
 public:
  explicit ClosureRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("ClosureRef"),
        function_(Function::Handle(zone)),
        closure_(Closure::Handle(zone)) {}
  ~ClosureRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      function_ = static_cast<FunctionPtr>(d->ReadRef());
      closure_ = function_.ImplicitStaticClosure();
      d->AssignRefPreLoad(closure_);
    }
  }

 private:
  Function& function_;
  Closure& closure_;
};

class ArgumentsDescriptorRefDeserializationCluster
    : public DeserializationCluster {
 public:
  explicit ArgumentsDescriptorRefDeserializationCluster(Zone* zone)
      : DeserializationCluster("ArgumentsDescriptorRef"),
        name_(String::Handle(zone)),
        named_(Array::Handle(zone)),
        args_descriptor_(Array::Handle(zone)) {}
  ~ArgumentsDescriptorRefDeserializationCluster() {}

  void PreLoad(Deserializer* d) override {
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t num_type_args = d->ReadUnsigned();
      const intptr_t num_positional = d->ReadUnsigned();
      const intptr_t num_named = d->ReadUnsigned();
      const intptr_t total_args = num_positional + num_named;
      // TODO(alexmarkov): support unboxed parameters.
      if (num_named > 0) {
        named_ = Array::New(num_named, Heap::kOld);
        for (intptr_t i = 0; i < num_named; ++i) {
          name_ ^= d->ReadRef();
          named_.SetAt(i, name_);
        }
        args_descriptor_ = ArgumentsDescriptor::New(num_type_args, total_args,
                                                    total_args, named_);
      } else {
        args_descriptor_ =
            ArgumentsDescriptor::New(num_type_args, total_args, total_args);
      }
      d->AssignRefPreLoad(args_descriptor_);
    }
  }

 private:
  String& name_;
  Array& named_;
  Array& args_descriptor_;
};

class IntDeserializationCluster : public DeserializationCluster {
 public:
  IntDeserializationCluster()
      : DeserializationCluster("Int", /*is_deeply_immutable=*/true) {
    ASSERT(Object::ShouldHaveDeeplyImmutabilityBitSet(kMintCid));
  }
  ~IntDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    const intptr_t smi_count = d->ReadUnsigned();
    for (intptr_t i = 0; i < smi_count; i++) {
      int64_t value = d->Read<int64_t>();
      ASSERT(Smi::IsValid(value));
      d->AssignRef(Smi::New(value));
    }
    for (intptr_t i = smi_count; i < count; i++) {
      int64_t value = d->Read<int64_t>();
      ASSERT(!Smi::IsValid(value));
      MintPtr mint = static_cast<MintPtr>(d->Allocate(Mint::InstanceSize()));
      Deserializer::InitializeHeader(mint, kMintCid, Mint::InstanceSize(),
                                     /*is_deeply_immutable=*/true);
      mint->untag()->value_ = value;
      d->AssignRef(mint);
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer*) override {}
};

class DoubleDeserializationCluster : public DeserializationCluster {
 public:
  DoubleDeserializationCluster()
      : DeserializationCluster("Double", /*is_deeply_immutable=*/true) {
    ASSERT(Object::ShouldHaveDeeplyImmutabilityBitSet(kDoubleCid));
  }
  ~DoubleDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, Double::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      DoublePtr dbl = static_cast<DoublePtr>(d.Ref(id));
      Deserializer::InitializeHeader(dbl, kDoubleCid, Double::InstanceSize(),
                                     /*is_deeply_immutable=*/true);
      dbl->untag()->value_ = d.Read<double>();
    }
  }
};

class ListDeserializationCluster : public DeserializationCluster {
 public:
  ListDeserializationCluster()
      : DeserializationCluster(
            "List",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kImmutableArrayCid)) {}
  ~ListDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(Array::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ArrayPtr array = static_cast<ArrayPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(array, kImmutableArrayCid,
                                     Array::InstanceSize(length),
                                     is_deeply_immutable());
      if (Array::UseCardMarkingForAllocation(length)) [[unlikely]] {
        array->untag()->SetCardRememberedBitUnsynchronized();
        Page::Of(array)->AllocateCardTable();
      }
      array->untag()->type_arguments_ =
          static_cast<TypeArgumentsPtr>(d.ReadRef());
      array->untag()->length_ = Smi::New(length);
      for (intptr_t j = 0; j < length; j++) {
        array->untag()->data()[j] = d.ReadRef();
      }
    }
  }
};

class MapDeserializationCluster : public DeserializationCluster {
 public:
  MapDeserializationCluster()
      : DeserializationCluster(
            "Map",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kConstMapCid)) {}
  ~MapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, Map::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      MapPtr map = static_cast<MapPtr>(d.Ref(id));
      Deserializer::InitializeHeader(map, kConstMapCid, Map::InstanceSize(),
                                     is_deeply_immutable());
      map->untag()->type_arguments_ =
          static_cast<TypeArgumentsPtr>(d.ReadRef());
      map->untag()->hash_mask_ = Smi::New(0);
      map->untag()->data_ = static_cast<ArrayPtr>(d.ReadRef());
      map->untag()->used_data_ = Smi::New(d.ReadUnsigned());
      map->untag()->deleted_keys_ = Smi::New(0);
      map->untag()->index_ = static_cast<TypedDataPtr>(d.null());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    Map& map = Map::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      map ^= refs.At(id);
      map.ComputeAndSetHashMask();
    }
  }
};

class SetDeserializationCluster : public DeserializationCluster {
 public:
  SetDeserializationCluster()
      : DeserializationCluster(
            "Set",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kConstSetCid)) {}
  ~SetDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, Set::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      SetPtr set = static_cast<SetPtr>(d.Ref(id));
      Deserializer::InitializeHeader(set, kConstSetCid, Set::InstanceSize(),
                                     is_deeply_immutable());
      set->untag()->type_arguments_ =
          static_cast<TypeArgumentsPtr>(d.ReadRef());
      set->untag()->hash_mask_ = Smi::New(0);
      set->untag()->data_ = static_cast<ArrayPtr>(d.ReadRef());
      set->untag()->used_data_ = Smi::New(d.ReadUnsigned());
      set->untag()->deleted_keys_ = Smi::New(0);
      set->untag()->index_ = static_cast<TypedDataPtr>(d.null());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    Set& set = Set::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      set ^= refs.At(id);
      set.ComputeAndSetHashMask();
    }
  }
};

class InstanceDeserializationCluster : public DeserializationCluster {
 public:
  explicit InstanceDeserializationCluster(const Class& cls)
      : DeserializationCluster(
            "List",
            Object::ShouldHaveDeeplyImmutabilityBitSet(cls.id())),
        class_(cls) {}
  ~InstanceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    next_field_offset_ = d->ReadUnsigned();
    const intptr_t instance_size = instance_size_ = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(d->Allocate(instance_size));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    const intptr_t cid = class_.id();
    intptr_t next_field_offset = next_field_offset_;
    intptr_t instance_size = instance_size_;

    // TODO(alexmarkov): support unboxed fields
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      InstancePtr instance = static_cast<InstancePtr>(d.Ref(id));
      Deserializer::InitializeHeader(instance, cid, instance_size,
                                     is_deeply_immutable());

      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        CompressedObjectPtr* p = reinterpret_cast<CompressedObjectPtr*>(
            reinterpret_cast<uword>(instance->untag()) + offset);
        *p = d.ReadRef();
        offset += kCompressedWordSize;
      }
      while (offset < instance_size) {
        CompressedObjectPtr* p = reinterpret_cast<CompressedObjectPtr*>(
            reinterpret_cast<uword>(instance->untag()) + offset);
        *p = d.null();
        offset += kCompressedWordSize;
      }
      ASSERT(offset == instance_size);
    }
  }

 private:
  const Class& class_;
  intptr_t next_field_offset_ = 0;
  intptr_t instance_size_ = 0;
};

class TypeArgumentsDeserializationCluster : public DeserializationCluster {
 public:
  TypeArgumentsDeserializationCluster()
      : DeserializationCluster(
            "TypeArguments",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kTypeArgumentsCid)) {}
  ~TypeArgumentsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(TypeArguments::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypeArgumentsPtr type_args = static_cast<TypeArgumentsPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(type_args, kTypeArgumentsCid,
                                     TypeArguments::InstanceSize(length),
                                     is_deeply_immutable());
      type_args->untag()->length_ = Smi::New(length);
      type_args->untag()->hash_ = Smi::New(0);
      type_args->untag()->nullability_ = Smi::New(0);
      type_args->untag()->instantiations_ =
          Object::empty_instantiations_cache_array().ptr();
      for (intptr_t j = 0; j < length; j++) {
        type_args->untag()->types()[j] =
            static_cast<AbstractTypePtr>(d.ReadRef());
      }
    }
  }
};

class FunctionTypeDeserializationCluster : public DeserializationCluster {
 public:
  FunctionTypeDeserializationCluster()
      : DeserializationCluster(
            "FunctionType",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kFunctionTypeCid)) {}
  ~FunctionTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, FunctionType::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      FunctionTypePtr type = static_cast<FunctionTypePtr>(d.Ref(id));
      Deserializer::InitializeHeader(type, kFunctionTypeCid,
                                     FunctionType::InstanceSize(),
                                     is_deeply_immutable());
      type->untag()->type_test_stub_entry_point_.store(
          0, std::memory_order_relaxed);
      const intptr_t is_nullable = d.ReadUnsigned();
      const intptr_t flags = UntaggedAbstractType::NullabilityBit::update(
          is_nullable, UntaggedAbstractType::TypeStateBits::encode(
                           UntaggedAbstractType::kAllocated));
      type->untag()->set_flags(flags);
      type->untag()->type_test_stub_ = static_cast<CodePtr>(d.null());
      type->untag()->hash_ = Smi::New(0);
      type->untag()->type_parameters_ =
          static_cast<TypeParametersPtr>(d.ReadRef());
      type->untag()->result_type_ = static_cast<AbstractTypePtr>(d.ReadRef());
      type->untag()->parameter_types_ = static_cast<ArrayPtr>(d.ReadRef());
      type->untag()->named_parameter_names_ =
          static_cast<ArrayPtr>(d.ReadRef());
      const intptr_t num_fixed_params = d.ReadUnsigned();
      type->untag()->packed_parameter_counts_ =
          UntaggedFunctionType::PackedNumImplicitParameters::update(
              1 /* implicit closure parameter */,
              UntaggedFunctionType::PackedNumFixedParameters::encode(
                  num_fixed_params));
      type->untag()->packed_type_parameter_counts_ =
          0;  // TODO(alexmarkov): set type parameter counts.
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    FunctionType& type = FunctionType::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      type ^= refs.At(id);
      stub = TypeTestingStubGenerator::DefaultCodeForType(type);
      type.InitializeTypeTestingStubNonAtomic(stub);
      const intptr_t num_params = Array::LengthOf(type.parameter_types());
      const intptr_t num_named_params =
          Array::LengthOf(type.named_parameter_names());
      const intptr_t num_fixed_params = type.num_fixed_parameters();
      type.set_num_implicit_parameters(1);  // Implicit closure parameter.
      if (num_named_params != 0) {
        type.SetNumOptionalParameters(num_params - num_named_params,
                                      /* are_optional_positional=*/false);
      } else if (num_fixed_params != num_params) {
        type.SetNumOptionalParameters(num_params - num_fixed_params,
                                      /* are_optional_positional=*/true);
      }
      type.SetIsFinalized();
    }
  }
};

class InterfaceTypeDeserializationCluster : public DeserializationCluster {
 public:
  InterfaceTypeDeserializationCluster()
      : DeserializationCluster(
            "InterfaceType",
            Object::ShouldHaveDeeplyImmutabilityBitSet(kTypeCid)) {}
  ~InterfaceTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, Type::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypePtr type = static_cast<TypePtr>(d.Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_deeply_immutable());
      type->untag()->type_test_stub_entry_point_.store(
          0, std::memory_order_relaxed);
      ClassPtr type_class = static_cast<ClassPtr>(d.ReadRef());
      const intptr_t is_nullable = d.ReadUnsigned();
      const intptr_t flags = UntaggedType::TypeClassIdBits::update(
          type_class->untag()->id(),
          UntaggedAbstractType::NullabilityBit::update(
              is_nullable, UntaggedAbstractType::TypeStateBits::encode(
                               UntaggedAbstractType::kAllocated)));
      type->untag()->set_flags(flags);
      type->untag()->type_test_stub_ = static_cast<CodePtr>(d.null());
      type->untag()->hash_ = Smi::New(0);
      type->untag()->arguments_ = static_cast<TypeArgumentsPtr>(d.ReadRef());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    Type& type = Type::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      type ^= refs.At(id);
      stub = TypeTestingStubGenerator::DefaultCodeForType(type);
      type.InitializeTypeTestingStubNonAtomic(stub);
      type.SetIsFinalized();
    }
  }
};

class CodeDeserializationCluster : public DeserializationCluster {
 public:
  explicit CodeDeserializationCluster(Zone* zone)
      : DeserializationCluster("Code"),
        code_source_map_(CodeSourceMap::Handle(zone, CodeSourceMap::New(0))) {}
  ~CodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, Code::InstanceSize(0));
  }

  void ReadFill(Deserializer* d) override {
    uword instructions = d->instructions();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      auto const code = static_cast<CodePtr>(d->Ref(id));

      Deserializer::InitializeHeader(code, kCodeCid, Code::InstanceSize(0));

      const uword entry_point = instructions;
      code->untag()->entry_point_ = entry_point;
      code->untag()->monomorphic_entry_point_ = entry_point;
      code->untag()->unchecked_entry_point_ = entry_point;
      code->untag()->monomorphic_unchecked_entry_point_ = entry_point;
      code->untag()->object_pool_ = static_cast<ObjectPoolPtr>(d->ReadRef());
      code->untag()->instructions_ = Instructions::null();
      code->untag()->owner_ = d->ReadRef();
      code->untag()->exception_handlers_ =
          Object::empty_exception_handlers().ptr();
      code->untag()->pc_descriptors_ = Object::empty_descriptors().ptr();
      code->untag()->catch_entry_ = Object::null();
      code->untag()->compressed_stackmaps_ = CompressedStackMaps::null();
      code->untag()->inlined_id_to_function_ = Array::null();
      code->untag()->code_source_map_ = code_source_map_.ptr();
      code->untag()->active_instructions_ = Instructions::null();
      code->untag()->deopt_info_array_ = Array::null();
      code->untag()->static_calls_target_table_ = Array::null();

#if !defined(PRODUCT)
      code->untag()->return_address_metadata_ = Object::null();
      code->untag()->var_descriptors_ = LocalVarDescriptors::null();
      code->untag()->comments_ = Array::null();
      code->untag()->compile_timestamp_ = 0;
#endif

      code->untag()->state_bits_ = Code::OptimizedBit::update(true, 0);
      code->untag()->unchecked_offset_ = 0;

      const uword instr_size = d->ReadUnsigned();
      instructions += instr_size;
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    Code& code = Code::Handle(d->zone());
    Object& owner = Object::Handle(d->zone());

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      code ^= refs.At(id);
      owner = code.owner();

      if (owner.IsFunction()) {
        Function::Cast(owner).SetInstructionsSafe(code);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
        if ((FLAG_disassemble ||
             (code.is_optimized() && FLAG_disassemble_optimized)) &&
            compiler::PrintFilter::ShouldPrint(Function::Cast(owner))) {
          Disassembler::DisassembleCode(Function::Cast(owner), code,
                                        code.is_optimized());
        }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
      } else {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
        if (FLAG_disassemble_stubs) {
          Disassembler::DisassembleStub("", code);
        }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
      }

#if !defined(PRODUCT)
      if (CodeObservers::AreActive()) {
        Code::NotifyCodeObservers(code, code.is_optimized());
      }
#endif
    }
  }

 private:
  const CodeSourceMap& code_source_map_;
};

class ICDataDeserializationCluster : public DeserializationCluster {
 public:
  ICDataDeserializationCluster() : DeserializationCluster("ICData") {}
  ~ICDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    ReadAllocFixedSize(d, ICData::InstanceSize());
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ICDataPtr ic = static_cast<ICDataPtr>(d.Ref(id));
      Deserializer::InitializeHeader(ic, kICDataCid, ICData::InstanceSize());
      ic->untag()->target_name_ = static_cast<StringPtr>(d.ReadRef());
      ic->untag()->args_descriptor_ = static_cast<ArrayPtr>(d.ReadRef());
      ic->untag()->entries_ = ICData::CachedEmptyICDataArray(
          /*num_args_tested=*/1, /*tracking_exactness=*/false);
      ic->untag()->receivers_static_type_ =
          static_cast<AbstractTypePtr>(d.null());
      ic->untag()->owner_ = static_cast<FunctionPtr>(d.ReadRef());
      ic->untag()->deopt_id_ = DeoptId::kNone;
      ic->untag()->state_bits_ = ICData::NumArgsTestedBits::encode(1);
    }
  }
};

class ObjectPoolDeserializationCluster : public DeserializationCluster {
 public:
  ObjectPoolDeserializationCluster() : DeserializationCluster("ObjectPool") {}
  ~ObjectPoolDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) override {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(ObjectPool::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_) override {
    Deserializer::Local d(d_);

    const uint8_t tagged_entry_bits =
        ObjectPool::EncodeBits(ObjectPool::EntryType::kTaggedObject,
                               ObjectPool::Patchability::kNotPatchable,
                               ObjectPool::SnapshotBehavior::kNotSnapshotable);
    const uint8_t immediate_entry_bits =
        ObjectPool::EncodeBits(ObjectPool::EntryType::kImmediate,
                               ObjectPool::Patchability::kNotPatchable,
                               ObjectPool::SnapshotBehavior::kNotSnapshotable);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      const intptr_t length = d.ReadUnsigned();
      ObjectPoolPtr pool = static_cast<ObjectPoolPtr>(d.Ref(id));
      Deserializer::InitializeHeader(pool, kObjectPoolCid,
                                     ObjectPool::InstanceSize(length));
      pool->untag()->length_ = length;
      for (intptr_t j = 0; j < length; j++) {
        const auto kind =
            static_cast<ModuleSnapshot::ObjectPoolEntryKind>(d.ReadUnsigned());
        switch (kind) {
          case ModuleSnapshot::kObjectRef: {
            pool->untag()->entry_bits()[j] = tagged_entry_bits;
            UntaggedObjectPool::Entry& entry = pool->untag()->data()[j];
            entry.raw_obj_ = d.ReadRef();
            break;
          }
          case ModuleSnapshot::kNewObjectTags: {
            ClassPtr cls = static_cast<ClassPtr>(d.ReadRef());
            pool->untag()->entry_bits()[j] = immediate_entry_bits;
            UntaggedObjectPool::Entry& entry = pool->untag()->data()[j];
            entry.raw_value_ = compiler::target::MakeTagWordForNewSpaceObject(
                cls->untag()->id_,
                Object::RoundedAllocationSize(Class::host_instance_size(cls) *
                                              kCompressedWordSize));
            break;
          }
          case ModuleSnapshot::kInterfaceCall: {
            pool->untag()->entry_bits()[j] = tagged_entry_bits;
            UntaggedObjectPool::Entry& entry = pool->untag()->data()[j];
            entry.raw_obj_ = d.ReadRef();
            ASSERT(j < length);
            ++j;
            pool->untag()->entry_bits()[j] = tagged_entry_bits;
            UntaggedObjectPool::Entry& entry2 = pool->untag()->data()[j];
            entry2.raw_obj_ = StubCode::OneArgOptimizedCheckInlineCache().ptr();
            break;
          }
        }
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) override {
    ObjectPool& pool = ObjectPool::Handle(d->zone());
    Object& obj = Object::Handle(d->zone());

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      pool ^= refs.At(id);

      for (intptr_t i = 0, length = pool.Length(); i < length; ++i) {
        if (pool.TypeAt(i) != ObjectPool::EntryType::kTaggedObject) {
          continue;
        }
        obj = pool.ObjectAt(i);
        if (obj.IsInstance() && !obj.InVMIsolateHeap()) {
          obj = Instance::Cast(obj).Canonicalize(d->thread());
          pool.SetObjectAt(i, obj);
        }
      }
    }
  }
};

Deserializer::Deserializer(Thread* thread,
                           const uint8_t* buffer,
                           intptr_t size,
                           const uint8_t* instructions_buffer)
    : ThreadStackResource(thread),
      heap_(thread->isolate_group()->heap()),
      old_space_(heap_->old_space()),
      freelist_(old_space_->DataFreeList()),
      zone_(thread->zone()),
      stream_(buffer, size),
      instructions_buffer_(instructions_buffer),
      refs_array_(Array::Handle(zone_)),
      refs_(Array::null()) {}

Deserializer::~Deserializer() {
  delete[] clusters_;
}

ApiErrorPtr Deserializer::VerifyVersionAndFeatures() {
  stream_.SetPosition(Snapshot::kHeaderSize);

  const intptr_t format_version = stream_.ReadUnsigned();
  if (format_version != ModuleSnapshot::kFormatVersion) {
    return ApiError::New(String::Handle(String::NewFormatted(
        "Invalid module snapshot format version %" Pd " (expected %" Pd ")",
        format_version, ModuleSnapshot::kFormatVersion)));
  }

  const char* features =
      reinterpret_cast<const char*>(stream_.AddressOfCurrentPosition());
  const intptr_t features_length =
      Utils::StrNLen(features, stream_.PendingBytes());
  if (features_length == stream_.PendingBytes()) {
    return ApiError::New(
        String::Handle(String::New("The features string in the module snapshot "
                                   "was not zero-terminated.")));
  }
  stream_.Advance(features_length + 1);

  const char* expected_features = kHostArchitectureName;
  if (strcmp(expected_features, features) != 0) {
    return ApiError::New(String::Handle(String::NewFormatted(
        "Invalid module snapshot configuration '%s' (expected '%s')", features,
        expected_features)));
  }
  return ApiError::null();
}

DeserializationCluster* Deserializer::ReadCluster() {
  const intptr_t cluster_id = ReadUnsigned();
  Zone* Z = zone_;
  switch (cluster_id) {
    case ModuleSnapshot::kOneByteStrings:
      return new (Z) OneByteStringDeserializationCluster(Z);
    case ModuleSnapshot::kTwoByteStrings:
      return new (Z) TwoByteStringDeserializationCluster(Z);
    case ModuleSnapshot::kLibraryRefs:
      return new (Z) LibraryRefDeserializationCluster(Z);
    case ModuleSnapshot::kPrivateNames:
      return new (Z) PrivateNameDeserializationCluster(Z);
    case ModuleSnapshot::kClassRefs:
      return new (Z) ClassRefDeserializationCluster(Z);
    case ModuleSnapshot::kFieldRefs:
      return new (Z) FieldRefDeserializationCluster(Z);
    case ModuleSnapshot::kFunctionRefs:
      return new (Z) FunctionRefDeserializationCluster(Z);
    case ModuleSnapshot::kClosureFunctionRefs:
      return new (Z) ClosureFunctionRefDeserializationCluster(Z);
    case ModuleSnapshot::kClosureRefs:
      return new (Z) ClosureRefDeserializationCluster(Z);
    case ModuleSnapshot::kArgumentsDescriptorRefs:
      return new (Z) ArgumentsDescriptorRefDeserializationCluster(Z);
    case ModuleSnapshot::kInts:
      return new (Z) IntDeserializationCluster();
    case ModuleSnapshot::kDoubles:
      return new (Z) DoubleDeserializationCluster();
    case ModuleSnapshot::kLists:
      return new (Z) ListDeserializationCluster();
    case ModuleSnapshot::kMaps:
      return new (Z) MapDeserializationCluster();
    case ModuleSnapshot::kSets:
      return new (Z) SetDeserializationCluster();
    case ModuleSnapshot::kRecords:
      // return new (Z) RecordDeserializationCluster();
      UNIMPLEMENTED();
      return nullptr;
    case ModuleSnapshot::kInstantiatedClosures:
      // return new (Z) InstantiatedClosureDeserializationCluster();
      UNIMPLEMENTED();
      return nullptr;
    case ModuleSnapshot::kTypeParameters:
      // return new (Z) TypeParametersDeserializationCluster();
      UNIMPLEMENTED();
      return nullptr;
    case ModuleSnapshot::kInterfaceTypes:
      return new (Z) InterfaceTypeDeserializationCluster();
    case ModuleSnapshot::kFunctionTypes:
      return new (Z) FunctionTypeDeserializationCluster();
    case ModuleSnapshot::kRecordTypes:
      // return new (Z) RecordTypeDeserializationCluster();
      UNIMPLEMENTED();
      return nullptr;
    case ModuleSnapshot::kTypeParameterTypes:
      // return new (Z) TypeParameterTypeDeserializationCluster();
      UNIMPLEMENTED();
      return nullptr;
    case ModuleSnapshot::kTypeArguments:
      return new (Z) TypeArgumentsDeserializationCluster();
    case ModuleSnapshot::kCodes:
      return new (Z) CodeDeserializationCluster(Z);
    case ModuleSnapshot::kICDatas:
      return new (Z) ICDataDeserializationCluster();
    case ModuleSnapshot::kObjectPools:
      return new (Z) ObjectPoolDeserializationCluster();
    case ModuleSnapshot::kInstances: {
      const auto& cls = Class::Handle(Z, static_cast<ClassPtr>(ReadRef()));
      return new (Z) InstanceDeserializationCluster(cls);
    }
    default:
      break;
  }
  FATAL("No cluster defined for cluster id %" Pd, cluster_id);
  return nullptr;
}

class HeapLocker : public StackResource {
 public:
  HeapLocker(Thread* thread, PageSpace* page_space)
      : StackResource(thread),
        page_space_(page_space),
        freelist_(page_space->DataFreeList()) {
    page_space_->AcquireLock(freelist_);
  }
  ~HeapLocker() { page_space_->ReleaseLock(freelist_); }

 private:
  PageSpace* page_space_;
  FreeList* freelist_;
};

void Deserializer::Deserialize() {
  const void* clustered_start = AddressOfCurrentPosition();

  num_base_objects_ = ReadUnsigned();
  num_objects_ = ReadUnsigned();
  const uword instructions_size = ReadUnsigned();
  num_clusters_ = ReadUnsigned();

  // TODO(alexmarkov): register image pages
  //
  // heap_->SetupImagePage(const_cast<uint8_t*>(instructions_buffer_),
  //                       instructions_size,
  //                       /* is_executable */ true);
  USE(instructions_size);

  clusters_ = new DeserializationCluster*[num_clusters_];
  refs_array_ = Array::New(num_objects_ + kFirstReference, Heap::kOld);
  ObjectStore* object_store = thread()->isolate_group()->object_store();

  AddBaseObject(Object::null_object());
  AddBaseObject(Bool::True());
  AddBaseObject(Bool::False());
  AddBaseObject(Object::dynamic_type());
  AddBaseObject(Object::void_type());
  AddBaseObject(Type::Handle(zone(), object_store->null_type()));
  AddBaseObject(Type::Handle(zone(), object_store->never_type()));
  AddBaseObject(Object::empty_array());

  if (num_base_objects_ != (next_ref_index_ - kFirstReference)) {
    FATAL("Snapshot expects %" Pd
          " base objects, but deserializer provided %" Pd,
          num_base_objects_, next_ref_index_ - kFirstReference);
  }

  {
    TIMELINE_DURATION(thread(), Isolate, "PreLoad");
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i] = ReadCluster();
      clusters_[i]->PreLoad(this);
    }
  }

  {
    // The deserializer initializes objects without using the write barrier,
    // partly for speed since we know all the deserialized objects will be
    // long-lived and partly because the target objects can be not yet
    // initialized at the time of the write. To make this safe, we must ensure
    // there are no other threads mutating this heap, and that incremental
    // marking is not in progress. This is normally the case anyway for the
    // module snapshots being deserialized at isolate load.
    HeapIterationScope iter(thread());
    // For bump-pointer allocation in old-space.
    HeapLocker hl(thread(), heap_->old_space());
    // Must not perform any other type of allocation, which might trigger GC
    // while there are still uninitialized objects.
    NoSafepointScope no_safepoint(thread());
    refs_ = refs_array_.ptr();

    {
      TIMELINE_DURATION(thread(), Isolate, "ReadAlloc");
      for (intptr_t i = 0; i < num_clusters_; i++) {
        clusters_[i]->ReadAlloc(this);
      }
    }

    // We should have completely filled the ref array.
    ASSERT_EQUAL(next_ref_index_ - kFirstReference, num_objects_);

    {
      TIMELINE_DURATION(thread(), Isolate, "ReadFill");
      for (intptr_t i = 0; i < num_clusters_; i++) {
        clusters_[i]->ReadFill(this);
      }
    }

    refs_ = nullptr;
  }

  auto isolate_group = thread()->isolate_group();
#if defined(DEBUG)
  isolate_group->heap()->Verify("Deserializer::Deserialize");
#endif

  {
    TIMELINE_DURATION(thread(), Isolate, "PostLoad");
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i]->PostLoad(this, refs_array_);
    }
  }

  if (isolate_group->snapshot_is_dontneed_safe()) {
    size_t clustered_length =
        reinterpret_cast<uword>(AddressOfCurrentPosition()) -
        reinterpret_cast<uword>(clustered_start);
    VirtualMemory::DontNeed(const_cast<void*>(clustered_start),
                            clustered_length);
  }
}

ApiErrorPtr ReadModuleSnapshot(Thread* thread,
                               const Snapshot* snapshot,
                               const uint8_t* instructions_buffer) {
  ASSERT(snapshot->kind() == Snapshot::kModule);

  Deserializer deserializer(thread, snapshot->Addr(), snapshot->length(),
                            instructions_buffer);

  ApiErrorPtr api_error = deserializer.VerifyVersionAndFeatures();
  if (api_error != ApiError::null()) {
    return api_error;
  }

  deserializer.Deserialize();

  return ApiError::null();
}

}  // namespace module_snapshot
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
