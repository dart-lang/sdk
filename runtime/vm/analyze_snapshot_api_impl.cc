// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include <set>
#include <sstream>
#include "include/analyze_snapshot_api.h"
#include "vm/dart_api_impl.h"
#include "vm/json_writer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/thread.h"

namespace dart {
namespace snapshot_analyzer {

void DumpFunctionJSON(Dart_SnapshotAnalyzerInformation* info,
                      dart::JSONWriter* js,
                      const Function& function) {
  String& signature = String::Handle(function.InternalSignature());
  Code& code = Code::Handle(function.CurrentCode());
  // On different architectures the type of the underlying
  // dart::uword can result in an unsigned long long vs unsigned long
  // mismatch.
  const auto code_addr = static_cast<uint64_t>(code.PayloadStart());

  const auto isolate_instructions_base =
      reinterpret_cast<uint64_t>(info->vm_isolate_instructions);
  uint64_t relative_offset;
  uint64_t size;
  const char* section;

  js->OpenObject();
  js->PrintProperty("name", function.ToCString());
  js->PrintProperty("signature", signature.ToCString());
  // Invoking code.PayloadStart() for _kDartVmSnapshotInstructions
  // when the tree has been shaken always returns 0
  if (code_addr == 0) {
    relative_offset = 0;
    size = 0;
    section = "_kDartVmSnapshotInstructions";
  } else {
    relative_offset = code_addr - isolate_instructions_base;
    size = static_cast<uint64_t>(code.Size());
    section = "_kDartIsolateSnapshotInstructions";
  }
  js->PrintProperty("section", section);
  js->PrintProperty64("offset", relative_offset);
  js->PrintProperty64("size", size);
  js->CloseObject();
}
void DumpClassTableJSON(Thread* thread,
                        Dart_SnapshotAnalyzerInformation* info,
                        dart::JSONWriter* js) {
  auto class_table = thread->isolate_group()->class_table();

  Class& cls = Class::Handle();
  js->OpenObject("class_table");

  // Note: Parse all top-level library functions first
  // separately, then on second pass just include name of
  // the library the class belongs to
  // TODO(#47924): Can clean this up to require single pass
  js->OpenArray("libs");
  std::set<uintptr_t> lib_hashes;

  // Note: We start counting at index = 1 mirroring other
  // locations that iterate through class_table().
  // HasValidClassAt(0) will crash on DEBUG ASSERT.
  for (intptr_t i = 1; i < class_table->NumCids(); i++) {
    if (!class_table->HasValidClassAt(i)) {
      continue;
    }
    cls = class_table->At(i);
    if (cls.IsNull()) {
      continue;
    }
    const Library& lib = Library::Handle(cls.library());
    if (lib.IsNull()) {
      continue;
    }
    String& lib_name = String::Handle(lib.url());
    uintptr_t lib_hash = lib_name.Hash();
    if (lib_hashes.count(lib_hash) != 0u) {
      continue;
    }
    lib_hashes.insert(lib_hash);
    Class& toplevel_cls = Class::Handle(lib.toplevel_class());
    Array& toplevel_funcs = Array::Handle(toplevel_cls.functions());

    js->OpenObject();
    js->PrintProperty("name", lib_name.ToCString());
    if (toplevel_funcs.Length() > 0) {
      js->OpenArray("functions");
      for (intptr_t j = 0; j < toplevel_funcs.Length(); j++) {
        Function& function =
            Function::Handle(toplevel_cls.FunctionFromIndex(j));
        DumpFunctionJSON(info, js, function);
      }
      js->CloseArray();
    }
    js->CloseObject();
  }
  js->CloseArray();

  js->OpenArray("classes");
  for (intptr_t i = 1; i < class_table->NumCids(); i++) {
    if (!class_table->HasValidClassAt(i)) {
      continue;
    }
    cls = class_table->At(i);
    if (cls.IsNull()) {
      continue;
    }

    js->OpenObject();
    String& name = String::Handle();
    name = cls.Name();
    js->PrintProperty("id", i);
    js->PrintProperty("name", name.ToCString());

    // Note: Some meta info is stripped from the snapshot, it's important
    // to check for nullptr periodically to avoid segfaults.
    const AbstractType& super_type = AbstractType::Handle(cls.super_type());
    if (!super_type.IsNull()) {
      const String& super_name = String::Handle(super_type.Name());
      js->PrintProperty("super_class", super_name.ToCString());
    }

    const Array& interfaces_array = Array::Handle(cls.interfaces());
    if (!interfaces_array.IsNull() && interfaces_array.Length() > 0) {
      js->OpenArray("interfaces");
      AbstractType& interface = AbstractType::Handle();
      intptr_t len = interfaces_array.Length();
      for (intptr_t i = 0; i < len; i++) {
        interface ^= interfaces_array.At(i);
        js->PrintValue(interface.ToCString());
      }
      js->CloseArray();
    }

    const Array& fields_array = Array::Handle(cls.fields());
    if (!fields_array.IsNull() && fields_array.Length() > 0) {
      js->OpenArray("fields");
      Field& field = Field::Handle();
      AbstractType& field_type = AbstractType::Handle();
      for (intptr_t i = 0; i < fields_array.Length(); i++) {
        field ^= fields_array.At(i);
        if (!field.IsNull()) {
          field_type = field.type();
          js->OpenObject();
          js->PrintProperty("name", String::Handle(field.name()).ToCString());
          js->PrintProperty("type",
                            String::Handle(field_type.Name()).ToCString());
          if (field.is_static()) {
            Object& field_instance = Object::Handle();
            field_instance = field.StaticValue();
            js->PrintProperty("value", field_instance.ToCString());
          } else {
            js->PrintProperty("value", "non-static");
          }
          js->CloseObject();
        }
      }
      js->CloseArray();
    }

    const Array& functions_array = Array::Handle(cls.functions());
    if (!functions_array.IsNull() && functions_array.Length() > 0) {
      js->OpenArray("functions");
      Function& function = Function::Handle();

      intptr_t len = functions_array.Length();
      for (intptr_t i = 0; i < len; i++) {
        function ^= functions_array.At(i);
        if (function.IsNull() || !function.HasCode()) {
          continue;
        }
        if (function.IsLocalFunction()) {
          function = function.parent_function();
        }
        DumpFunctionJSON(info, js, function);
      }
      js->CloseArray();
    }

    Library& library = Library::Handle(cls.library());
    if (!library.IsNull()) {
      js->PrintProperty("lib", String::Handle(library.url()).ToCString());
    }
    js->CloseObject();
  }
  js->CloseArray();

  js->CloseObject();
}
void DumpObjectPoolJSON(Thread* thread, dart::JSONWriter* js) {
  js->OpenArray("object_pool");
  auto pool_ptr = thread->isolate_group()->object_store()->global_object_pool();
  const auto& pool = ObjectPool::Handle(ObjectPool::RawCast(pool_ptr));
  for (intptr_t i = 0; i < pool.Length(); i++) {
    auto type = pool.TypeAt(i);
    // Only interested in tagged objects.
    // All these checks are required otherwise ToCString() will segfault.
    if (type != ObjectPool::EntryType::kTaggedObject) {
      continue;
    }

    auto entry = pool.ObjectAt(i);
    if (!entry.IsHeapObject()) {
      continue;
    }

    intptr_t cid = entry.GetClassId();
    switch (cid) {
      case kOneByteStringCid: {
        js->OpenObject();
        js->PrintProperty("type", "kOneByteString");
        js->PrintProperty("id", i);
        js->PrintProperty("offset", pool.element_offset(i));
        js->PrintProperty("value", Object::Handle(entry).ToCString());
        js->CloseObject();
        break;
      }
      case kTwoByteStringCid: {
        // TODO(#47924): Add support.
        break;
      }

      default:
        // TODO(#47924): Investigate other types of objects to parse.
        break;
    }
  }
  js->CloseArray();
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

void DumpFunctionPP(Dart_SnapshotAnalyzerInformation* info,
                    std::stringstream& ss,
                    const Function& function) {
  String& signature = String::Handle(function.InternalSignature());
  Code& code = Code::Handle(function.CurrentCode());
  // On different architectures the type of the underlying
  // dart::uword can result in an unsigned long long vs unsigned long
  // mismatch.
  const auto code_addr = static_cast<uint64_t>(code.PayloadStart());

  const auto isolate_instructions_base =
      reinterpret_cast<uint64_t>(info->vm_isolate_instructions);
  uint64_t relative_offset;
  const char* section;

  ss << "\t" << function.ToCString() << " " << signature.ToCString()
     << " {\n\n";
  char offset_buff[100] = "";
  // Invoking code.PayloadStart() for _kDartVmSnapshotInstructions
  // when the tree has been shaken always returns 0
  if (code_addr == 0) {
    section = "_kDartVmSnapshotInstructions";
    snprintf(offset_buff, sizeof(offset_buff), "Offset: <Could not read>");
  } else {
    relative_offset = code_addr - isolate_instructions_base;
    section = "_kDartIsolateSnapshotInstructions";
    snprintf(offset_buff, sizeof(offset_buff), "Offset: %s + 0x%" PRIx64 "",
             section, relative_offset);
  }

  ss << "\t\t" << offset_buff << "\n\n\t}\n";
}
// TODO(#47924): Refactor and reduce code duplication.
void DumpClassTablePP(Thread* thread, Dart_SnapshotAnalyzerInformation* info) {
  std::stringstream ss;
  auto class_table = thread->isolate_group()->class_table();
  Class& cls = Class::Handle();
  std::set<uintptr_t> lib_hashes;
  for (intptr_t i = 1; i < class_table->NumCids(); i++) {
    if (!class_table->HasValidClassAt(i)) {
      continue;
    }
    cls = class_table->At(i);
    if (cls.IsNull()) {
      continue;
    }
    const Library& lib = Library::Handle(cls.library());
    if (lib.IsNull()) {
      continue;
    }
    String& lib_name = String::Handle(lib.url());
    uintptr_t lib_hash = lib_name.Hash();
    if (lib_hashes.count(lib_hash) != 0u) {
      continue;
    }
    lib_hashes.insert(lib_hash);
    Class& toplevel_cls = Class::Handle(lib.toplevel_class());
    Array& toplevel_funcs = Array::Handle(toplevel_cls.functions());
    if (toplevel_funcs.Length() > 0) {
      ss << "\nLibrary: " << lib_name.ToCString() << " {\n\n";
      for (intptr_t i = 0; i < toplevel_funcs.Length(); i++) {
        Function& function =
            Function::Handle(toplevel_cls.FunctionFromIndex(i));
        DumpFunctionPP(info, ss, function);
      }
      ss << "}\n";
    }
  }

  for (intptr_t i = 1; i < class_table->NumCids(); i++) {
    if (!class_table->HasValidClassAt(i)) {
      continue;
    }
    cls = class_table->At(i);
    if (cls.IsNull()) {
      continue;
    }

    ss << "\n";
    ss << cls.ToCString();
    const AbstractType& super_type = AbstractType::Handle(cls.super_type());
    if (!super_type.IsNull()) {
      const String& super_name = String::Handle(super_type.Name());
      ss << " extends " << super_name.ToCString();
    }

    const Array& interfaces_array = Array::Handle(cls.interfaces());
    if (!interfaces_array.IsNull() && interfaces_array.Length() > 0) {
      AbstractType& interface = AbstractType::Handle();
      intptr_t len = interfaces_array.Length();
      bool implements_flag = true;
      for (intptr_t i = 0; i < len; i++) {
        interface ^= interfaces_array.At(i);
        if (implements_flag) {
          ss << " implements ";
          implements_flag = false;
        } else {
          ss << ", ";
        }
        ss << interface.ToCString();
      }
    }
    ss << " {\n\n";
    const Array& fields_array = Array::Handle(cls.fields());
    if (!fields_array.IsNull() && fields_array.Length() > 0) {
      Field& field = Field::Handle();
      AbstractType& field_type = AbstractType::Handle();
      for (intptr_t i = 0; i < fields_array.Length(); i++) {
        field ^= fields_array.At(i);
        if (!field.IsNull()) {
          field_type = field.type();
          ss << " " << String::Handle(field_type.Name()).ToCString();
          ss << " " << String::Handle(field.name()).ToCString();
          ss << " = ";
          if (field.is_static()) {
            Object& field_instance = Object::Handle();
            field_instance = field.StaticValue();
            ss << field_instance.ToCString() << "\n";
          } else {
            ss << "non-static;\n";
          }
        }
      }
    }
    const Array& functions_array = Array::Handle(cls.functions());
    if (!functions_array.IsNull() && functions_array.Length() > 0) {
      Function& function = Function::Handle();
      intptr_t len = functions_array.Length();
      for (intptr_t i = 0; i < len; i++) {
        function ^= functions_array.At(i);
        if (function.IsNull() || !function.HasCode()) {
          continue;
        }
        if (function.IsLocalFunction()) {
          function = function.parent_function();
        }
        DumpFunctionPP(info, ss, function);
      }
    }
    ss << "\n}\n";
  }
  OS::Print("%s", ss.str().c_str());
}

void Dart_DumpSnapshotInformationAsJson(
    char** buffer,
    intptr_t* buffer_length,
    Dart_SnapshotAnalyzerInformation* info) {
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  JSONWriter js;
  // Open empty object so output is valid/parsable JSON.
  js.OpenObject();
  js.OpenObject("snapshot_data");
  // Base addresses of the snapshot data, useful to calculate relative offsets.
  js.PrintfProperty("vm_data", "%p", info->vm_snapshot_data);
  js.PrintfProperty("vm_instructions", "%p", info->vm_snapshot_instructions);
  js.PrintfProperty("isolate_data", "%p", info->vm_isolate_data);
  js.PrintfProperty("isolate_instructions", "%p",
                    info->vm_isolate_instructions);
  js.CloseObject();

  {
    // Debug builds assert that our thread has a lock before accessing
    // vm internal fields.
    SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
    DumpClassTableJSON(thread, info, &js);
    DumpObjectPoolJSON(thread, &js);
  }

  // Close our empty object.
  js.CloseObject();

  // Give ownership to caller.
  js.Steal(buffer, buffer_length);
}

void Dart_DumpSnapshotInformationPP(Dart_SnapshotAnalyzerInformation* info) {
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  OS::Print("File information:\n\n");
  OS::Print("vm_data: %p\n", info->vm_snapshot_data);
  OS::Print("vm_instructions: %p\n", info->vm_snapshot_instructions);
  OS::Print("isolate_data: %p\n", info->vm_isolate_data);
  OS::Print("isolate_instructions: %p\n", info->vm_isolate_instructions);
  {
    SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
    DumpClassTablePP(thread, info);
  }
}
}  // namespace snapshot_analyzer
}  // namespace dart
