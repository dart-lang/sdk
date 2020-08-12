// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/reverse_pc_lookup_cache.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

CodePtr ReversePc::Lookup(IsolateGroup* group,
                          uword pc,
                          bool is_return_address) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // This can run in the middle of GC and must not allocate handles.
  NoSafepointScope no_safepoint;

  if (is_return_address) {
    pc--;
  }

  // This expected number of tables is low, so we go through them linearly. If
  // this changes, would could sort the table list during deserialization and
  // binary search for the table.
  GrowableObjectArrayPtr tables = group->object_store()->code_order_tables();
  intptr_t tables_length = Smi::Value(tables->ptr()->length_);
  for (intptr_t i = 0; i < tables_length; i++) {
    ArrayPtr table =
        static_cast<ArrayPtr>(tables->ptr()->data_->ptr()->data()[i]);
    intptr_t lo = 0;
    intptr_t hi = Smi::Value(table->ptr()->length_) - 1;

    // Fast check if pc belongs to this table.
    if (lo > hi) {
      continue;
    }
    CodePtr first = static_cast<CodePtr>(table->ptr()->data()[lo]);
    if (pc < Code::PayloadStartOf(first)) {
      continue;
    }
    CodePtr last = static_cast<CodePtr>(table->ptr()->data()[hi]);
    if (pc >= (Code::PayloadStartOf(last) + Code::PayloadSizeOf(last))) {
      continue;
    }

    // Binary search within the table for the matching Code.
    while (lo <= hi) {
      intptr_t mid = (hi - lo + 1) / 2 + lo;
      ASSERT(mid >= lo);
      ASSERT(mid <= hi);
      CodePtr code = static_cast<CodePtr>(table->ptr()->data()[mid]);
      uword code_start = Code::PayloadStartOf(code);
      uword code_end = code_start + Code::PayloadSizeOf(code);
      if (pc < code_start) {
        hi = mid - 1;
      } else if (pc >= code_end) {
        lo = mid + 1;
      } else {
        return code;
      }
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  return Code::null();
}

}  // namespace dart
