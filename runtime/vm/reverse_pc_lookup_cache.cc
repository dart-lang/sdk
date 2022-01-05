// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/reverse_pc_lookup_cache.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

namespace dart {

CodePtr ReversePc::FindCodeInGroup(IsolateGroup* group,
                                   uword pc,
                                   bool is_return_address) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // This can run in the middle of GC and must not allocate handles.
  NoSafepointScope no_safepoint;

  if (is_return_address) {
    pc--;
  }

  // This expected number of tables is low (one per loading unit), so we go
  // through them linearly. If this changes, would could sort the table list
  // during deserialization and binary search for the table.
  GrowableObjectArrayPtr tables = group->object_store()->instructions_tables();
  intptr_t tables_length = Smi::Value(tables->untag()->length());
  for (intptr_t i = 0; i < tables_length; i++) {
    InstructionsTablePtr table = static_cast<InstructionsTablePtr>(
        tables->untag()->data()->untag()->element(i));
    CodePtr code = InstructionsTable::FindCode(table, pc);
    if (code != Code::null()) {
      return code;
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  return Code::null();
}

const UntaggedCompressedStackMaps::Payload* ReversePc::FindStackMapInGroup(
    IsolateGroup* group,
    uword pc,
    bool is_return_address,
    uword* code_start,
    const UntaggedCompressedStackMaps::Payload** global_table) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // This can run in the middle of GC and must not allocate handles.
  NoSafepointScope no_safepoint;

  if (is_return_address) {
    pc--;
  }

  // This expected number of tables is low (one per loading unit), so we go
  // through them linearly. If this changes, would could sort the table list
  // during deserialization and binary search for the table.
  GrowableObjectArrayPtr tables = group->object_store()->instructions_tables();
  intptr_t tables_length = Smi::Value(tables->untag()->length());
  for (intptr_t i = 0; i < tables_length; i++) {
    InstructionsTablePtr table = static_cast<InstructionsTablePtr>(
        tables->untag()->data()->untag()->element(i));
    auto map = InstructionsTable::FindStackMap(table, pc, code_start);
    if (map != nullptr) {
      // Take global table from the first table.
      table = static_cast<InstructionsTablePtr>(
          tables->untag()->data()->untag()->element(0));
      *global_table = InstructionsTable::GetCanonicalStackMap(table);
      return map;
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  *code_start = 0;
  return nullptr;
}

const UntaggedCompressedStackMaps::Payload* ReversePc::FindStackMap(
    IsolateGroup* group,
    uword pc,
    bool is_return_address,
    uword* code_start,
    const UntaggedCompressedStackMaps::Payload** global_table) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  auto map = FindStackMapInGroup(group, pc, is_return_address, code_start,
                                 global_table);
  if (map == nullptr) {
    map = FindStackMapInGroup(Dart::vm_isolate_group(), pc, is_return_address,
                              code_start, global_table);
  }
  return map;
}

CodePtr ReversePc::FindCode(IsolateGroup* group,
                            uword pc,
                            bool is_return_address) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  auto code_descriptor = FindCodeInGroup(group, pc, is_return_address);
  if (code_descriptor == Code::null()) {
    code_descriptor =
        FindCodeInGroup(Dart::vm_isolate_group(), pc, is_return_address);
  }
  return code_descriptor;
}

CodePtr ReversePc::Lookup(IsolateGroup* group,
                          uword pc,
                          bool is_return_address) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  return FindCode(group, pc, is_return_address);
}

}  // namespace dart
