// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/reverse_pc_lookup_cache.h"

#include "vm/isolate.h"

namespace dart {

#if defined(DART_PRECOMPILED_RUNTIME)

static uword BeginPcFromCode(const CodePtr code) {
  return Code::PayloadStartOf(code);
}

static uword EndPcFromCode(const CodePtr code) {
  return Code::PayloadStartOf(code) + Code::PayloadSizeOf(code);
}

void ReversePcLookupCache::BuildAndAttachToIsolateGroup(
    IsolateGroup* isolate_group) {
  // This should be called once when the isolate group is created.
  ASSERT(isolate_group->reverse_pc_lookup_cache() == nullptr);

  auto object_store = isolate_group->object_store();
  auto& array = Array::Handle(object_store->code_order_table());
  if (!array.IsNull()) {
    const intptr_t length = array.Length();
    {
      NoSafepointScope no_safepoint_scope;

      const uword begin = BeginPcFromCode(static_cast<CodePtr>(array.At(0)));
      const uword end =
          EndPcFromCode(static_cast<CodePtr>(array.At(length - 1)));

      auto pc_array = new uint32_t[length];
      for (intptr_t i = 0; i < length; i++) {
        const auto end_pc = EndPcFromCode(static_cast<CodePtr>(array.At(i)));
        pc_array[i] = end_pc - begin;
      }
#if defined(DEBUG)
      for (intptr_t i = 1; i < length; i++) {
        ASSERT(pc_array[i - 1] <= pc_array[i]);
      }
#endif  // defined(DEBUG)
      auto cache =
          new ReversePcLookupCache(isolate_group, pc_array, length, begin, end);
      isolate_group->set_reverse_pc_lookup_cache(cache);
    }
  }
}

#endif  // defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
