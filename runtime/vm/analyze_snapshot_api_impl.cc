// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <set>
#include <sstream>

#include "include/analyze_snapshot_api.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dart_api_impl.h"
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
      : info_(info) {}

  // Saves JSON format snapshot information in the output character buffer.
  void DumpSnapshotInformation(char** buffer, intptr_t* buffer_length);

 private:
  void DumpLibrary(const Library& library);
  void DumpArray(const Array& array, const char* name);
  void DumpClass(const Class& klass);
  void DumpFunction(const Function& function);
  void DumpCode(const Code& code);
  void DumpField(const Field& field);
  void DumpString(const String& string);
  void DumpInstance(const Object& object);
  void DumpType(const Type& type);
  void DumpObjectPool(const ObjectPool& pool);

  void DumpInterestingObjects();
  void DumpMetadata();

  intptr_t GetObjectId(ObjectPtr obj) { return heap_->GetObjectId(obj); }

  const Dart_SnapshotAnalyzerInformation& info_;
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

  js_.PrintProperty("class_id", klass.id());
  js_.PrintProperty("name", String::Handle(klass.Name()).ToCString());
  js_.PrintProperty("super_class", GetObjectId(klass.SuperClass()));

  Zone* zone = thread_->zone();
  Array& array = Array::Handle(zone);

  // To avoid depending on layout of VM internal classes we don't use
  //   js_.PrintProperty("fields", GetObjectId(heap, klass.fields());
  // here and instead iterate and refer to them manually.
  array = klass.fields();
  if (!array.IsNull()) {
    DumpArray(array, "fields");
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

void SnapshotAnalyzer::DumpFunction(const Function& function) {
  js_.PrintProperty("type", "Function");
  js_.PrintProperty("name", function.ToCString());

  js_.PrintProperty("signature",
                    String::Handle(function.InternalSignature()).ToCString());

  js_.PrintProperty("code", GetObjectId(function.CurrentCode()));
  if (function.IsClosureFunction()) {
    js_.PrintProperty("parent_function",
                      GetObjectId(function.parent_function()));
  }
}

void SnapshotAnalyzer::DumpCode(const Code& code) {
  js_.PrintProperty("type", "Code");
  const auto instruction_base =
      reinterpret_cast<uint64_t>(info_.vm_isolate_instructions);

  // On different architectures the type of the underlying
  // dart::uword can result in an unsigned long long vs unsigned long
  // mismatch.
  const auto code_addr = static_cast<uint64_t>(code.PayloadStart());
  // Invoking code.PayloadStart() for _kDartVmSnapshotInstructions
  // when the tree has been shaken always returns 0
  if (code_addr == 0) {
    js_.PrintProperty64("offset", 0);
    js_.PrintProperty64("size", 0);
    js_.PrintProperty("section", "_kDartVmSnapshotInstructions");
  } else {
    js_.PrintProperty64("offset", code_addr - instruction_base);
    js_.PrintProperty64("size", static_cast<uint64_t>(code.Size()));
    js_.PrintProperty("section", "_kDartIsolateSnapshotInstructions");
  }
}

void SnapshotAnalyzer::DumpField(const Field& field) {
  js_.PrintProperty("type", "Field");
  js_.PrintProperty("name", String::Handle(field.name()).ToCString());
  js_.PrintProperty64("type_class", GetObjectId(field.type()));
  if (field.is_static()) {
    js_.PrintProperty("instance", GetObjectId(field.StaticValue()));
  }
  if (field.HasInitializerFunction()) {
    js_.PrintProperty("initializer_function",
                      GetObjectId(field.InitializerFunction()));
  }
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
  Zone* zone = thread_->zone();

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

// TODO(#47924): Add processing of the entires in the dispatch table.
// Below is an example skeleton
// void DumpDispatchTable(dart::Thread* thread) {
//   auto dispatch = thread->isolate_group()->dispatch_table();
//   auto length = dispatch->length();
// We must unbias the array entries so we don't crash on null access.
//   auto entries = dispatch->ArrayOrigin() - DispatchTable::kOriginElement;
//   for (intptr_t i = 0; i < length; i++) {
//     OS::Print("0x%lx at %ld\n", entries[i], i);
//   }
// }

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
