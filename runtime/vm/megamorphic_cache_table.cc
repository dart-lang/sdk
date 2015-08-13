// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/megamorphic_cache_table.h"

#include <stdlib.h>
#include "vm/object.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

MegamorphicCacheTable::MegamorphicCacheTable()
    : miss_handler_function_(NULL),
      miss_handler_code_(NULL),
      capacity_(0),
      length_(0),
      table_(NULL) {
}


MegamorphicCacheTable::~MegamorphicCacheTable() {
  free(table_);
}


RawMegamorphicCache* MegamorphicCacheTable::Lookup(const String& name,
                                                   const Array& descriptor) {
  for (intptr_t i = 0; i < length_; ++i) {
    if ((table_[i].name == name.raw()) &&
        (table_[i].descriptor == descriptor.raw())) {
      return table_[i].cache;
    }
  }

  if (length_ == capacity_) {
    capacity_ += kCapacityIncrement;
    table_ =
        reinterpret_cast<Entry*>(realloc(table_, capacity_ * sizeof(*table_)));
  }

  ASSERT(length_ < capacity_);
  const MegamorphicCache& cache =
      MegamorphicCache::Handle(MegamorphicCache::New());
  Entry entry = { name.raw(), descriptor.raw(), cache.raw() };
  table_[length_++] = entry;
  return cache.raw();
}


void MegamorphicCacheTable::InitMissHandler() {
  // The miss handler for a class ID not found in the table is invoked as a
  // normal Dart function.
  const Code& code =
      Code::Handle(StubCode::Generate("_stub_MegamorphicMiss",
                                      StubCode::GenerateMegamorphicMissStub));
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
  miss_handler_code_ = code.raw();
  miss_handler_function_ = function.raw();
  function.AttachCode(code);
}


void MegamorphicCacheTable::VisitObjectPointers(ObjectPointerVisitor* v) {
  ASSERT(v != NULL);
  v->VisitPointer(reinterpret_cast<RawObject**>(&miss_handler_code_));
  v->VisitPointer(reinterpret_cast<RawObject**>(&miss_handler_function_));
  for (intptr_t i = 0; i < length_; ++i) {
    v->VisitPointer(reinterpret_cast<RawObject**>(&table_[i].name));
    v->VisitPointer(reinterpret_cast<RawObject**>(&table_[i].descriptor));
    v->VisitPointer(reinterpret_cast<RawObject**>(&table_[i].cache));
  }
}


void MegamorphicCacheTable::PrintSizes() {
  StackZone zone(Thread::Current());
  intptr_t size = 0;
  MegamorphicCache& cache = MegamorphicCache::Handle();
  Array& buckets = Array::Handle();
  for (intptr_t i = 0; i < length_; ++i) {
    cache = table_[i].cache;
    buckets = cache.buckets();
    size += MegamorphicCache::InstanceSize();
    size += Array::InstanceSize(buckets.Length());
  }
  OS::Print("%" Pd " megamorphic caches using %" Pd "KB.\n",
            length_, size / 1024);
}

}  // namespace dart
