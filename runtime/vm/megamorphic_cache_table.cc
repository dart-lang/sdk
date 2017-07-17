// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/megamorphic_cache_table.h"

#include <stdlib.h>
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

RawMegamorphicCache* MegamorphicCacheTable::Lookup(Isolate* isolate,
                                                   const String& name,
                                                   const Array& descriptor) {
  // Multiple compilation threads could access this lookup.
  SafepointMutexLocker ml(isolate->megamorphic_lookup_mutex());
  ASSERT(name.IsSymbol());
  // TODO(rmacnak): ASSERT(descriptor.IsCanonical());

  // TODO(rmacnak): Make a proper hashtable a la symbol table.
  GrowableObjectArray& table = GrowableObjectArray::Handle(
      isolate->object_store()->megamorphic_cache_table());
  MegamorphicCache& cache = MegamorphicCache::Handle();
  if (table.IsNull()) {
    table = GrowableObjectArray::New(Heap::kOld);
    isolate->object_store()->set_megamorphic_cache_table(table);
  } else {
    for (intptr_t i = 0; i < table.Length(); i++) {
      cache ^= table.At(i);
      if ((cache.target_name() == name.raw()) &&
          (cache.arguments_descriptor() == descriptor.raw())) {
        return cache.raw();
      }
    }
  }

  cache = MegamorphicCache::New(name, descriptor);
  table.Add(cache, Heap::kOld);
  return cache.raw();
}

RawFunction* MegamorphicCacheTable::miss_handler(Isolate* isolate) {
  ASSERT(isolate->object_store()->megamorphic_miss_function() !=
         Function::null());
  return isolate->object_store()->megamorphic_miss_function();
}

void MegamorphicCacheTable::InitMissHandler(Isolate* isolate) {
  // The miss handler for a class ID not found in the table is invoked as a
  // normal Dart function.
  const Code& code = Code::Handle(StubCode::Generate(
      "_stub_MegamorphicMiss", StubCode::GenerateMegamorphicMissStub));
  // When FLAG_lazy_dispatchers=false, this stub can be on the stack during
  // exceptions, but it has a corresponding function so IsStubCode is false and
  // it is considered in the search for an exception handler.
  code.set_exception_handlers(Object::empty_exception_handlers());
  const Class& cls =
      Class::Handle(Type::Handle(Type::DartFunctionType()).type_class());
  const Function& function = Function::Handle(
      Function::New(Symbols::MegamorphicMiss(), RawFunction::kRegularFunction,
                    true,   // Static, but called as a method.
                    false,  // Not const.
                    false,  // Not abstract.
                    false,  // Not external.
                    false,  // Not native.
                    cls, TokenPosition::kNoSource));
  function.set_result_type(Type::Handle(Type::DynamicType()));
  function.set_is_debuggable(false);
  function.set_is_visible(false);
  function.AttachCode(code);  // Has a single entry point, as a static function.
  // For inclusion in Snapshot::kFullJIT.
  function.set_unoptimized_code(code);

  ASSERT(isolate->object_store()->megamorphic_miss_function() ==
         Function::null());
  isolate->object_store()->SetMegamorphicMissHandler(code, function);
}

void MegamorphicCacheTable::PrintSizes(Isolate* isolate) {
  StackZone zone(Thread::Current());
  intptr_t size = 0;
  MegamorphicCache& cache = MegamorphicCache::Handle();
  Array& buckets = Array::Handle();
  const GrowableObjectArray& table = GrowableObjectArray::Handle(
      isolate->object_store()->megamorphic_cache_table());
  if (table.IsNull()) return;
  intptr_t max_size = 0;
  for (intptr_t i = 0; i < table.Length(); i++) {
    cache ^= table.At(i);
    buckets = cache.buckets();
    size += MegamorphicCache::InstanceSize();
    size += Array::InstanceSize(buckets.Length());
    if (buckets.Length() > max_size) {
      max_size = buckets.Length();
    }
  }
  OS::Print("%" Pd " megamorphic caches using %" Pd "KB.\n", table.Length(),
            size / 1024);

  intptr_t* probe_counts = new intptr_t[max_size];
  intptr_t entry_count = 0;
  intptr_t max_probe_count = 0;
  for (intptr_t i = 0; i < max_size; i++) {
    probe_counts[i] = 0;
  }
  for (intptr_t i = 0; i < table.Length(); i++) {
    cache ^= table.At(i);
    buckets = cache.buckets();
    intptr_t mask = cache.mask();
    intptr_t capacity = mask + 1;
    for (intptr_t j = 0; j < capacity; j++) {
      intptr_t class_id =
          Smi::Value(Smi::RawCast(cache.GetClassId(buckets, j)));
      if (class_id != kIllegalCid) {
        intptr_t probe_count = 0;
        intptr_t probe_index =
            (class_id * MegamorphicCache::kSpreadFactor) & mask;
        intptr_t probe_cid;
        while (true) {
          probe_count++;
          probe_cid =
              Smi::Value(Smi::RawCast(cache.GetClassId(buckets, probe_index)));
          if (probe_cid == class_id) {
            break;
          }
          probe_index = (probe_index + 1) & mask;
        }
        probe_counts[probe_count]++;
        if (probe_count > max_probe_count) {
          max_probe_count = probe_count;
        }
        entry_count++;
      }
    }
  }
  intptr_t cumulative_entries = 0;
  for (intptr_t i = 0; i <= max_probe_count; i++) {
    cumulative_entries += probe_counts[i];
    OS::Print("Megamorphic probe %" Pd ": %" Pd " (%lf)\n", i, probe_counts[i],
              static_cast<double>(cumulative_entries) /
                  static_cast<double>(entry_count));
  }
  delete[] probe_counts;
}

}  // namespace dart
