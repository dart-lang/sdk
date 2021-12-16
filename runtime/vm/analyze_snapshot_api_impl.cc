// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/analyze_snapshot_api.h"
#include "vm/dart_api_impl.h"
#include "vm/json_writer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/thread.h"

namespace dart {
namespace snapshot_analyzer {
void DumpClassTable(Thread* thread, dart::JSONWriter* js) {
  auto class_table = thread->isolate_group()->class_table();

  Class& cls = Class::Handle();
  String& name = String::Handle();
  js->OpenArray("class_table");

  for (intptr_t i = 1; i < class_table->NumCids(); i++) {
    if (!class_table->HasValidClassAt(i)) {
      continue;
    }
    cls = class_table->At(i);
    if (!cls.IsNull()) {
      name = cls.Name();
      js->OpenObject();
      js->PrintProperty("id", i);
      js->PrintProperty("name", name.ToCString());

      // Note: Some meta info is stripped from the snapshot, it's important
      // to check every field for NULL to avoid segfaults.
      const Library& library = Library::Handle(cls.library());
      if (!library.IsNull()) {
        String& lib_name = String::Handle();
        lib_name = String::NewFormatted(
            Heap::kOld, "%s%s", String::Handle(library.url()).ToCString(),
            String::Handle(library.private_key()).ToCString());
        js->PrintProperty("library", lib_name.ToCString());
      }

      const AbstractType& super_type = AbstractType::Handle(cls.super_type());
      if (super_type.IsNull()) {
      } else {
        const String& super_name = String::Handle(super_type.Name());
        js->PrintProperty("super_class", super_name.ToCString());
      }

      const Array& interfaces_array = Array::Handle(cls.interfaces());
      if (!interfaces_array.IsNull()) {
        if (interfaces_array.Length() > 0) {
          js->OpenArray("interfaces");
          AbstractType& interface = AbstractType::Handle();
          intptr_t len = interfaces_array.Length();
          for (intptr_t i = 0; i < len; i++) {
            interface ^= interfaces_array.At(i);
            js->PrintValue(interface.ToCString());
          }
          js->CloseArray();
        }
      }
      const Array& functions_array = Array::Handle(cls.functions());
      if (!functions_array.IsNull()) {
        if (functions_array.Length() > 0) {
          js->OpenArray("functions");
          Function& function = Function::Handle();
          intptr_t len = functions_array.Length();
          for (intptr_t i = 0; i < len; i++) {
            function ^= functions_array.At(i);
            if (function.IsNull() || !function.HasCode()) {
              continue;
            }
            const Code& code = Code::Handle(function.CurrentCode());
            intptr_t size = code.Size();

            // Note: Some entry points here will be pointing to the VM
            // instructions buffer.

            // Note: code_entry will contain the address in the memory
            // In order to resolve it to a relative offset in the instructions
            // buffer we need to pick the base address and substract it from
            // the entry point address.
            auto code_entry = code.EntryPoint();
            // On different architectures the type of the underlying
            // dart::uword can result in an unsigned long long vs unsigned long
            // mismatch.
            uint64_t code_addr = static_cast<uint64_t>(code_entry);
            js->OpenObject();
            js->PrintProperty("name", function.ToCString());
            js->PrintfProperty("code_entry", "0x%" PRIx64 "", code_addr);
            js->PrintProperty("size", size);
            js->CloseObject();
          }
          js->CloseArray();
        }
      }
      const Array& fields_array = Array::Handle(cls.fields());
      if (fields_array.IsNull()) {
      } else {
        if (fields_array.Length() > 0) {
          js->OpenArray("fields");
          Field& field = Field::Handle();
          for (intptr_t i = 0; i < fields_array.Length(); i++) {
            field ^= fields_array.At(i);
            js->PrintValue(field.ToCString());
          }
          js->CloseArray();
        }
      }
    }
    js->CloseObject();
  }
  js->CloseArray();
}
void DumpObjectPool(Thread* thread, dart::JSONWriter* js) {
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
//   auto entries = dispatch->ArrayOrigin() - DispatchTable::OriginElement();
//   for (intptr_t i = 0; i < length; i++) {
//     OS::Print("0x%lx at %ld\n", entries[i], i);
//   }
// }

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
  // Base addreses of the snapshot data, useful to calculate relative offsets.
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
    DumpClassTable(thread, &js);
    DumpObjectPool(thread, &js);
  }

  // Close our empty object.
  js.CloseObject();

  // Give ownership to caller.
  js.Steal(buffer, buffer_length);
}
}  // namespace snapshot_analyzer
}  // namespace dart
