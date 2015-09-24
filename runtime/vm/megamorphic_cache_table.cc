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
  ASSERT(name.IsSymbol());
  // TODO(rmacnak): ASSERT(descriptor.IsCanonical());

  // TODO(rmacnak): Make a proper hashtable a la symbol table.
  GrowableObjectArray& table = GrowableObjectArray::Handle(
      isolate->object_store()->megamorphic_cache_table());
  if (table.IsNull()) {
    table = GrowableObjectArray::New(Heap::kOld);
    ASSERT((table.Length() % kEntrySize) == 0);
    isolate->object_store()->set_megamorphic_cache_table(table);
  } else {
    for (intptr_t i = 0; i < table.Length(); i += kEntrySize) {
      if ((table.At(i + kEntryNameOffset) == name.raw()) &&
          (table.At(i + kEntryDescriptorOffset) == descriptor.raw())) {
        return MegamorphicCache::RawCast(table.At(i + kEntryCacheOffset));
      }
    }
  }

  const MegamorphicCache& cache =
      MegamorphicCache::Handle(MegamorphicCache::New());
  table.Add(name, Heap::kOld);
  table.Add(descriptor, Heap::kOld);
  table.Add(cache, Heap::kOld);
  ASSERT((table.Length() % kEntrySize) == 0);
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
  const Code& code =
      Code::Handle(StubCode::Generate("_stub_MegamorphicMiss",
                                      StubCode::GenerateMegamorphicMissStub));
  // When FLAG_lazy_dispatchers=false, this stub can be on the stack during
  // exceptions, but it has a corresponding function so IsStubCode is false and
  // it is considered in the search for an exception handler.
  code.set_exception_handlers(Object::empty_exception_handlers());
  const Class& cls =
      Class::Handle(Type::Handle(Type::Function()).type_class());
  const Function& function =
      Function::Handle(Function::New(Symbols::MegamorphicMiss(),
                                     RawFunction::kRegularFunction,
                                     false,  // Not static.
                                     false,  // Not const.
                                     false,  // Not abstract.
                                     false,  // Not external.
                                     false,  // Not native.
                                     cls,
                                     0));  // No token position.
  function.set_is_debuggable(false);
  function.set_is_visible(false);
  function.AttachCode(code);

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
  for (intptr_t i = 0; i < table.Length(); i += kEntrySize) {
    cache ^= table.At(i + kEntryCacheOffset);
    buckets = cache.buckets();
    size += MegamorphicCache::InstanceSize();
    size += Array::InstanceSize(buckets.Length());
  }
  OS::Print("%" Pd " megamorphic caches using %" Pd "KB.\n",
            table.Length() / kEntrySize, size / 1024);
}

}  // namespace dart
