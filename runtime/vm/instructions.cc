// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/instructions.h"

#include "vm/object.h"
#if defined(DART_PRECOMPILER)
#include "vm/compiler/aot/precompiler.h"
#endif

namespace dart {

bool ObjectAtPoolIndex(const Code& code, intptr_t index, Object* obj) {
#if defined(DART_PRECOMPILER)
  if (FLAG_precompiled_mode) {
    Precompiler* precompiler = Precompiler::Instance();
    if (precompiler != nullptr) {
      compiler::ObjectPoolBuilder* pool =
          precompiler->global_object_pool_builder();
      if (index < pool->CurrentLength()) {
        compiler::ObjectPoolBuilderEntry& entry = pool->EntryAt(index);
        if (entry.type() == compiler::ObjectPoolBuilderEntry::kTaggedObject) {
          *obj = entry.obj_->ptr();
          return true;
        }
      }
    }
    return false;
  }
#endif
  const ObjectPool& pool = ObjectPool::Handle(code.GetObjectPool());
  if (!pool.IsNull() && (index < pool.Length()) &&
      (pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject)) {
    *obj = pool.ObjectAt(index);
    return true;
  }
  return false;
}

}  // namespace dart
