// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstddef>
#include <cstdint>
#include <set>
#include <sstream>
#include <unordered_map>
#include <vector>

#include "include/analyze_snapshot_api.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/globals.h"
#include "vm/json_writer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/thread.h"

namespace dart {
namespace snapshot_analyzer {

constexpr intptr_t kSnapshotAnalyzerVersion = 2;
constexpr intptr_t kStartIndex = 1;

class FieldVisitor : public ObjectPointerVisitor {
 public:
  explicit FieldVisitor(IsolateGroup* isolate_group)
      : ObjectPointerVisitor(isolate_group) {}

  void init(std::function<void(ObjectPtr)>* fun) { callback_ = fun; }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (ObjectPtr* current = first; current <= last; current++) {
      (*callback_)(*current);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    for (CompressedObjectPtr* current = first; current <= last; current++) {
      (*callback_)(current->Decompress(heap_base));
    }
  }
#endif

 private:
  std::function<void(ObjectPtr object)>* callback_ = nullptr;
};

class SnapshotAnalyzer {
 public:
  explicit SnapshotAnalyzer(const Dart_SnapshotAnalyzerInformation& info)
      : info_(info),
        class_fields_(IsolateGroup::Current()->class_table()->NumCids()),
        top_level_class_fields_(
            IsolateGroup::Current()->class_table()->NumTopLevelCids()) {}

  // Saves JSON format snapshot information in the output character buffer.
  void DumpSnapshotInformation(char** buffer, intptr_t* buffer_length);

 private:
  void DumpLibrary(const Library& library);
  void DumpArray(const Array& array, const char* name);
  void DumpClass(const Class& klass);
  void DumpClassInstanceSlots(const Class& klass,
                              const std::vector<const Field*>& fields);
  void DumpFunction(const Function& function);
  void DumpCode(const Code& code);
  void DumpCode(uword start_pc, uword end_pc, const char* name);
  void DumpField(const Field& field);
  void DumpString(const String& string);
  void DumpInstance(const Object& object);
  void DumpType(const Type& type);
  void DumpObjectPool(const ObjectPool& pool);

  void DumpInterestingObjects();
  void DumpMetadata();

  intptr_t GetObjectId(ObjectPtr obj) { return heap_->GetObjectId(obj); }

  const Dart_SnapshotAnalyzerInformation& info_;
  std::vector<std::vector<const Field*>> class_fields_;
  std::vector<std::vector<const Field*>> top_level_class_fields_;
  std::unordered_map<uword, const char*> stub_names_;

  JSONWriter js_;
  Thread* thread_;
  Heap* heap_;
};

void SnapshotAnalyzer::DumpLibrary(const Library& library) {
  js_.PrintProperty("type", "Library");
  js_.PrintProperty("url", String::Handle(library.url()).ToCString());

  js_.PrintProperty("toplevel_class",
                    GetObjectId(Object::RawCast(library.toplevel_class())));
}

void SnapshotAnalyzer::DumpArray(const Array& array, const char* name) {
  js_.OpenArray(name);
  for (intptr_t i = 0; i < array.Length(); ++i) {
    js_.PrintValue64(GetObjectId(array.At(i)));
  }
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpClass(const Class& klass) {
  js_.PrintProperty("type", "Class");

  auto& class_fields =
      klass.IsTopLevel() ? top_level_class_fields_ : class_fields_;
  const auto& fields =
      class_fields[klass.IsTopLevel()
                       ? ClassTable::IndexFromTopLevelCid(klass.id())
                       : klass.id()];

  js_.PrintProperty("class_id", klass.id());
  js_.PrintProperty("name", String::Handle(klass.Name()).ToCString());
  js_.PrintProperty("super_class", GetObjectId(klass.SuperClass()));

  Zone* zone = thread_->zone();
  Array& array = Array::Handle(zone);

  // We use [fields] instead of [Class.fields()] as a [Field] object may not
  // appear in [Class.fields()] but may still be available (e.g. for
  // `LateInitizializationError`) so we can include all fields of the class we
  // found.
  js_.OpenArray("fields");
  for (uintptr_t i = 0; i < fields.size(); ++i) {
    js_.PrintValue64(GetObjectId(fields[i]->ptr()));
  }
  js_.CloseArray();

  // Here we write information about every slot in an instance. Even if there's
  // no corresponding [Field] object, we will write out an entry describing the
  // slot (e.g. whether it's boxed or not, ...)
  //
  // So this information is always available, whereas the "fields" above only
  // writes non-tree shaken [Field] obejcts.
  if (!klass.IsTopLevel()) {
    DumpClassInstanceSlots(klass, fields);
  }

  array = klass.functions();
  if (!array.IsNull()) {
    DumpArray(array, "functions");
  }

  array = klass.interfaces();
  if (!array.IsNull()) {
    DumpArray(array, "interfaces");
  }

  Library& library = Library::Handle(klass.library());
  if (!library.IsNull()) {
    js_.PrintProperty("library", GetObjectId(klass.library()));
  }
}

void SnapshotAnalyzer::DumpClassInstanceSlots(
    const Class& klass,
    const std::vector<const Field*>& fields) {
  const auto& super_class = Class::Handle(klass.SuperClass());
  auto& field = Field::Handle();
  auto& type = AbstractType::Handle();
  auto class_table = thread_->isolate_group()->class_table();

  const auto bitmap = class_table->GetUnboxedFieldsMapAt(klass.id());

  const intptr_t start_offset = super_class.IsNull()
                                    ? Instance::NextFieldOffset()
                                    : super_class.host_next_field_offset();
  const intptr_t end_offset = klass.host_next_field_offset();

  js_.OpenArray("instance_slots");
  intptr_t offset = start_offset;
  while (offset < end_offset) {
    const bool is_reference = !bitmap.Get(offset / kCompressedWordSize);

    js_.OpenObject();
    js_.PrintProperty("offset", offset);
    js_.PrintPropertyBool("is_reference", is_reference);

    if (offset == klass.host_type_arguments_field_offset()) {
      RELEASE_ASSERT(is_reference);
      js_.PrintProperty("slot_type", "type_arguments_field");
      js_.CloseObject();
      offset += kCompressedWordSize;
      continue;
    }

    // Try to see if the corresponding [Field] object was not tree shaken.
    bool found = false;
    for (uintptr_t i = 0; i < fields.size(); ++i) {
      field = fields[i]->ptr();
      if (field.is_static()) continue;
      if (field.HostOffset() == offset) {
        found = true;
        break;
      }
    }
    if (found) {
      type = field.type();

      intptr_t slots = 0;
      if (field.is_unboxed()) {
        if (type.IsDoubleType()) {
          slots = sizeof(double) / kCompressedWordSize;
        } else if (type.IsIntType()) {
          slots = sizeof(int64_t) / kCompressedWordSize;
        } else if (type.IsFloat32x4Type()) {
          slots = sizeof(simd128_value_t) / kCompressedWordSize;
        } else if (type.IsFloat64x2Type()) {
          slots = sizeof(simd128_value_t) / kCompressedWordSize;
        } else {
          // Rare: Could be that the field type isn't telling us the unboxed
          // type but field is still unboxed (e.g. `dynamic` field which TFA
          // inferred to be of certain type).
          //
          // In this case we treat it as unknown field below (as we don't know
          // it's size).
          slots = -1;
        }
      } else {
        slots = 1;
      }
      if (!field.is_unboxed() || slots > 0) {
        js_.PrintProperty("slot_type", "instance_field");
        js_.PrintProperty64("field", GetObjectId(field.ptr()));
        js_.CloseObject();
        offset += slots * kCompressedWordSize;
        continue;
      }
    }

    // This slot is either an unknown reference field or part of an unknown
    // unboxed field (64-bit integer/double or 128-bit float32x4/float64x2).
    // We cannot know the size or type of the unboxed field as the [Field]
    // object was tree shaken.
    js_.PrintProperty("slot_type", "unknown_slot");
    js_.CloseObject();

    offset += kCompressedWordSize;
  }
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpFunction(const Function& function) {
  js_.PrintProperty("type", "Function");
  js_.PrintProperty("name", function.QualifiedScrubbedNameCString());

  js_.PrintProperty("signature",
                    String::Handle(function.InternalSignature()).ToCString());

  js_.PrintProperty("code", GetObjectId(function.CurrentCode()));
  if (function.IsClosureFunction()) {
    js_.PrintProperty("parent_function",
                      GetObjectId(function.parent_function()));
  }
}

namespace {
// Try to identify stubs which were effectively copied into the isolate
// instructions section by comparing payloads.
const char* TryIdentifyIsolateSpecificStubCopy(ObjectStore* object_store,
                                               const Code& code) {
#define MATCH(member, name)                                                    \
  if (object_store->member() != Code::null() &&                                \
      StubCode::name().ptr() == object_store->member() &&                      \
      StubCode::name().Size() == code.Size() &&                                \
      memcmp(reinterpret_cast<void*>(code.PayloadStart()),                     \
             reinterpret_cast<void*>(StubCode::name().PayloadStart()),         \
             code.Size()) == 0) {                                              \
    return "_iso_stub_" #name "Stub";                                          \
  }
  OBJECT_STORE_STUB_CODE_LIST(MATCH)
#undef MATCH

  return nullptr;
}
}  // namespace

void SnapshotAnalyzer::DumpCode(const Code& code) {
  js_.PrintProperty("type", "Code");
  const auto instruction_base =
      reinterpret_cast<uint64_t>(info_.vm_isolate_instructions);

  if (code.IsUnknownDartCode()) {
    js_.PrintProperty64("offset", 0);
    js_.PrintProperty64("size", 0);
    js_.PrintProperty("name", "UnknownDartCode");
    js_.PrintProperty("section", "_kDartVmSnapshotInstructions");
    return;
  }

  // On different architectures the type of the underlying
  // dart::uword can result in an unsigned long long vs unsigned long
  // mismatch.
  const auto code_addr = static_cast<uint64_t>(code.PayloadStart());
  js_.PrintProperty64("offset", code_addr - instruction_base);
  js_.PrintProperty64("size", static_cast<uint64_t>(code.Size()));
  js_.PrintProperty("section", "_kDartIsolateSnapshotInstructions");

  if (code.owner() != Object::null()) {
    const auto& owner = Object::Handle(code.owner());
    js_.PrintProperty("owner", GetObjectId(owner.ptr()));
    if (owner.IsClass()) {
      js_.PrintfProperty("name", "new %s",
                         Class::Cast(owner).ScrubbedNameCString());
      js_.PrintPropertyBool("is_stub", true);
    } else if (owner.IsAbstractType()) {
      js_.PrintfProperty("name", "as %s",
                         AbstractType::Cast(owner).ScrubbedNameCString());
      js_.PrintPropertyBool("is_stub", true);
    } else if (owner.IsFunction()) {
      js_.PrintProperty("name", Function::Cast(owner).UserVisibleNameCString());
    } else if (owner.IsSmi()) {
      // This is a class id of the class which owned the function.
      // See Precompiler::DropFunctions.
      const auto cid = Smi::Cast(owner).Value();
      auto class_table = thread_->isolate_group()->class_table();
      if (class_table->IsValidIndex(cid) &&
          class_table->At(cid) != Class::null()) {
        const auto& cls = Class::Handle(class_table->At(cid));
        js_.PrintProperty("owner", GetObjectId(cls.ptr()));
        js_.PrintfProperty("name", "unknown function of %s",
                           Class::Cast(cls).ScrubbedNameCString());
      } else {
        js_.PrintfProperty("name", "unknown function of class #%" Pd "", cid);
      }
    } else {
      // Expected to handle all possibilities.
      UNREACHABLE();
    }
  } else {
    js_.PrintPropertyBool("is_stub", true);

    const auto it = stub_names_.find(code.EntryPoint());
    if (it != stub_names_.end()) {
      js_.PrintProperty("name", it->second);
    } else if (auto stub_name = TryIdentifyIsolateSpecificStubCopy(
                   thread_->isolate_group()->object_store(), code)) {
      js_.PrintProperty("name", stub_name);
    } else {
      UNREACHABLE();
    }
  }
}

void SnapshotAnalyzer::DumpCode(uword start_pc,
                                uword end_pc,
                                const char* name) {
  js_.PrintProperty("type", "Code");
  const auto instruction_base =
      reinterpret_cast<uint64_t>(info_.vm_isolate_instructions);

  js_.PrintProperty64("offset",
                      static_cast<uint64_t>(start_pc) - instruction_base);
  js_.PrintProperty64("size", static_cast<uint64_t>(end_pc - start_pc));
  js_.PrintProperty("name", name);
  js_.PrintProperty("section", "_kDartIsolateSnapshotInstructions");
}

void SnapshotAnalyzer::DumpField(const Field& field) {
  const auto& name = String::Handle(field.name());
  const auto& type = AbstractType::Handle(field.type());

  js_.PrintProperty("type", "Field");
  js_.PrintProperty("name", name.ToCString());
  js_.PrintProperty64("type_class", GetObjectId(field.type()));
  if (field.is_static()) {
    js_.PrintProperty("instance", GetObjectId(field.StaticValue()));
    js_.PrintProperty64("static_field_offset",
                        FieldTable::FieldOffsetFor(field.field_id()));
  }
  if (field.HasInitializerFunction()) {
    js_.PrintProperty("initializer_function",
                      GetObjectId(field.InitializerFunction()));
  }

  js_.PrintPropertyBool("is_reference", !field.is_unboxed());
  if (field.is_unboxed()) {
    const char* unboxed_type = nullptr;
    if (type.IsDoubleType()) {
      unboxed_type = "double";
    } else if (type.IsIntType()) {
      unboxed_type = "int";
    } else if (type.IsFloat32x4Type()) {
      unboxed_type = "Float32x4";
    } else if (type.IsFloat64x2Type()) {
      unboxed_type = "Float64x2";
    } else {
      unboxed_type = "unknown";
    }
    js_.PrintProperty("unboxed_type", unboxed_type);
  }

  js_.OpenArray("flags");
  if (field.is_final()) js_.PrintValue("final");
  if (field.is_static()) {
    js_.PrintValue("static");
    if (field.is_shared()) js_.PrintValue("shared");
  }
  if (field.is_instance()) {
    if (field.is_late()) js_.PrintValue("late");
  }
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpString(const String& string) {
  js_.PrintProperty("type", "String");
  js_.PrintProperty("value", string.ToCString());
}

void SnapshotAnalyzer::DumpInstance(const Object& object) {
  js_.PrintProperty("type", "Instance");

  js_.PrintProperty("class", GetObjectId(object.clazz()));

  FieldVisitor visitor(thread_->isolate_group());
  // Two phase algorithm, first discover all relevant objects
  // and assign ids, then write them out.
  std::function<void(ObjectPtr)> print_reference = [&](ObjectPtr value) {
    if (!value.IsHeapObject()) return;
    intptr_t index = GetObjectId(value);
    js_.PrintValue64(index);
  };
  visitor.init(&print_reference);

  js_.OpenArray("references");
  object.ptr().untag()->VisitPointers(&visitor);
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpType(const Type& type) {
  js_.PrintProperty("type", "Type");

  js_.PrintProperty("type_class", GetObjectId(type.type_class()));

  const TypeArguments& arguments = TypeArguments::Handle(type.arguments());
  js_.OpenArray("type_arguments");
  for (intptr_t i = 0; i < arguments.Length(); ++i) {
    js_.PrintValue64(GetObjectId(arguments.TypeAt(i)));
  }
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpObjectPool(const ObjectPool& pool) {
  js_.PrintProperty("type", "ObjectPool");
  js_.OpenArray("references");
  for (intptr_t i = 0; i < pool.Length(); ++i) {
    if (pool.TypeAt(i) == ObjectPool::EntryType::kTaggedObject) {
      // We write (index, offset, value) triplets.
      js_.PrintValue64(i);
      js_.PrintValue64(pool.OffsetFromIndex(i));
      js_.PrintValue64(GetObjectId(pool.ObjectAt(i)));
    }
  }
  js_.CloseArray();
}

void SnapshotAnalyzer::DumpInterestingObjects() {
  // Collect stubs into stub_names to enable quick name lookup
  StubCode::ForEachStub([&](const char* name, uword entry_point) {
    stub_names_[entry_point] = name;
    return true;
  });

  Zone* zone = thread_->zone();
  auto class_table = thread_->isolate_group()->class_table();
  class_table->NumCids();

  heap_->ResetObjectIdTable();
  std::vector<const Object*> discovered_objects;
  Object& object = Object::Handle(zone);
  {
    NoSafepointScope ns(thread_);

    FieldVisitor visitor(thread_->isolate_group());
    std::function<void(ObjectPtr)> handle_object = [&](ObjectPtr value) {
      if (!value.IsHeapObject()) return;

      // Ensure we never handle an object more than once.
      if (heap_->GetObjectId(value) != 0) return;

      heap_->SetObjectId(value, kStartIndex + discovered_objects.size());
      discovered_objects.push_back(&Object::Handle(zone, value));

      // Ensure all references of this object are visited first.
      value->untag()->VisitPointers(&visitor);
    };
    visitor.init(&handle_object);

    // BEGIN Visit all things we are interested in.

    // - All constants reachable via object pool
    object = thread_->isolate_group()->object_store()->global_object_pool();
    handle_object(object.ptr());

    // - All libraries
    object = thread_->isolate_group()->object_store()->libraries();
    object = GrowableObjectArray::Cast(object).data();
    object.ptr().untag()->VisitPointers(&visitor);

    // - All classes
    auto class_table = thread_->isolate_group()->class_table();
    for (intptr_t cid = 0; cid < class_table->NumCids(); ++cid) {
      if (!class_table->HasValidClassAt(cid)) continue;
      object = class_table->At(cid);
      handle_object(object.ptr());
    }

    // - All instructions tables
    const auto& instruction_tables = GrowableObjectArray::Handle(
        thread_->isolate_group()->object_store()->instructions_tables());
    for (intptr_t i = 0; i < instruction_tables.Length(); i++) {
      object = instruction_tables.At(i);
      object = InstructionsTable::Cast(object).code_objects();
      handle_object(object.ptr());
    }

    // - All VM stubs
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      if (!StubCode::EntryAt(i).IsNull()) {
        handle_object(StubCode::EntryAt(i).ptr());
      }
    }

    // - Object store.
    //
    // This will include a bunch of stuff we don't care about
    // but it will also capture things like isolate specific stubs and
    // canonicalized types which themselves include references to stubs.
    thread_->isolate_group()->object_store()->VisitObjectPointers(&visitor);
  }

  // Sometimes we have [Field] objects for fields but they are not available
  // from [Class.fields] (e.g. late final fields where the slow path uses
  // [Field] from object pool to throw a nice error).
  //
  // So we manually look for all [Field]s and associate them with classes
  // instead of relying on the [Class.fields] array.
  auto& owner = Class::Handle();
  for (uintptr_t i = 0; i < discovered_objects.size(); ++i) {
    const Object& object = *discovered_objects[i];
    if (object.IsField()) {
      const auto& field = Field::Cast(object);
      owner = field.Owner();
      auto& array =
          owner.IsTopLevel() ? top_level_class_fields_ : class_fields_;
      const intptr_t index = owner.IsTopLevel()
                                 ? ClassTable::IndexFromTopLevelCid(owner.id())
                                 : owner.id();
      array[index].push_back(&field);
    }
  }

  // Print information about objects
  js_.OpenArray("objects");

  // The 0 object id is used in the VM's weak hashmap implementation
  // to indicate no value.
  js_.OpenObject();
  js_.PrintProperty("type", "NoValue");
  js_.CloseObject();

  for (size_t id = 0; id < discovered_objects.size(); ++id) {
    const auto* object = discovered_objects[id];
    js_.OpenObject();
    // TODO(balid): Remove this as it can be inferred from the array position.
    // Used for manual debugging at the moment.
    js_.PrintProperty64("id", id + kStartIndex);
    // Order matters here, Strings are a subtype of Instance, for example.
    if (object->IsNull()) {
      js_.PrintProperty("type", "Null");
    } else if (object->IsLibrary()) {
      DumpLibrary(Library::Cast(*object));
    } else if (object->IsObjectPool()) {
      DumpObjectPool(ObjectPool::Cast(*object));
    } else if (object->IsClass()) {
      DumpClass(Class::Cast(*object));
    } else if (object->IsFunction()) {
      DumpFunction(Function::Cast(*object));
    } else if (object->IsCode()) {
      DumpCode(Code::Cast(*object));
    } else if (object->IsField()) {
      DumpField(Field::Cast(*object));
    } else if (object->IsString()) {
      DumpString(String::Cast(*object));
    } else if (object->IsArray()) {
      js_.PrintProperty("type", "Array");
      const Array& array = Array::Handle(Array::RawCast(object->ptr()));
      DumpArray(array, "elements");
    } else if (object->IsType()) {
      DumpType(Type::Cast(*object));
    } else if (object->IsInstance()) {
      DumpInstance(*object);
    }
    js_.CloseObject();
  }

  // Finally dump pseudo-Code objects for all entries in the instructions
  // tables without code objects.
  uint64_t pseudo_code_id = kStartIndex + discovered_objects.size();
  const auto& instruction_tables = GrowableObjectArray::Handle(
      thread_->isolate_group()->object_store()->instructions_tables());
  auto& instructions_table = InstructionsTable::Handle();
  for (intptr_t i = 0; i < instruction_tables.Length(); i++) {
    instructions_table ^= instruction_tables.At(i);
    for (intptr_t index = 0; index < instructions_table.FirstEntryWithCode();
         index++) {
      js_.OpenObject();
      js_.PrintProperty64("id", pseudo_code_id);
      DumpCode(instructions_table.EntryPointAt(index),
               instructions_table.EntryPointAt(index + 1), "Unknown Code");
      js_.CloseObject();
      pseudo_code_id++;
    }
  }

  js_.CloseArray();
}

void SnapshotAnalyzer::DumpMetadata() {
  js_.OpenObject("metadata");
  js_.OpenObject("offsets");
  js_.OpenObject("thread");
  // TODO(balid): Use `dart::compiler::target::` versions.
  js_.PrintProperty("isolate", Thread::isolate_offset());
  js_.PrintProperty("isolate_group", Thread::isolate_group_offset());
  js_.PrintProperty("dispatch_table_array",
                    Thread::dispatch_table_array_offset());
  js_.CloseObject();
  js_.OpenObject("isolate_group");
  js_.PrintProperty("class_table", IsolateGroup::class_table_offset());
  js_.PrintProperty("cached_class_table",
                    IsolateGroup::cached_class_table_table_offset());
  js_.PrintProperty("object_store_offset", IsolateGroup::object_store_offset());
  js_.CloseObject();
  js_.CloseObject();
  js_.PrintProperty64("word_size", dart::compiler::target::kWordSize);
  js_.PrintProperty64("compressed_word_size",
                      dart::compiler::target::kCompressedWordSize);
  js_.PrintProperty64("analyzer_version", kSnapshotAnalyzerVersion);
  js_.CloseObject();
}

void SnapshotAnalyzer::DumpSnapshotInformation(char** buffer,
                                               intptr_t* buffer_length) {
  thread_ = Thread::Current();
  heap_ = thread_->isolate_group()->heap();
  DARTSCOPE(thread_);

  // Open empty object so output is valid/parsable JSON.
  js_.OpenObject();
  js_.OpenObject("snapshot_data");
  // Base addresses of the snapshot data, useful to calculate relative offsets.
  js_.PrintfProperty("vm_data", "%p", info_.vm_snapshot_data);
  js_.PrintfProperty("vm_instructions", "%p", info_.vm_snapshot_instructions);
  js_.PrintfProperty("isolate_data", "%p", info_.vm_isolate_data);
  js_.PrintfProperty("isolate_instructions", "%p",
                     info_.vm_isolate_instructions);
  js_.CloseObject();

  {
    // Debug builds assert that our thread has a lock before accessing
    // vm internal fields.
    SafepointReadRwLocker ml(thread_, thread_->isolate_group()->program_lock());
    DumpInterestingObjects();
    DumpMetadata();
  }

  // Close our empty object.
  js_.CloseObject();

  // Give ownership to caller.
  js_.Steal(buffer, buffer_length);
}

void Dart_DumpSnapshotInformationAsJson(
    const Dart_SnapshotAnalyzerInformation& info,
    char** out,
    intptr_t* out_len) {
  SnapshotAnalyzer analyzer(info);
  analyzer.DumpSnapshotInformation(out, out_len);
}

}  // namespace snapshot_analyzer
}  // namespace dart
