// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/reverse_pc_lookup_cache.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

namespace dart {

ObjectPtr ReversePc::FindCodeDescriptorInGroup(IsolateGroup* group,
                                               uword pc,
                                               bool is_return_address,
                                               uword* code_start) {
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
    intptr_t index = InstructionsTable::FindEntry(table, pc);
    if (index >= 0) {
      *code_start = InstructionsTable::PayloadStartAt(table, index);
      return InstructionsTable::DescriptorAt(table, index);
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  *code_start = 0;
  return Object::null();
}

ObjectPtr ReversePc::FindCodeDescriptor(IsolateGroup* group,
                                        uword pc,
                                        bool is_return_address,
                                        uword* code_start) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  ObjectPtr code_descriptor =
      FindCodeDescriptorInGroup(group, pc, is_return_address, code_start);
  if (code_descriptor == Object::null()) {
    code_descriptor = FindCodeDescriptorInGroup(Dart::vm_isolate_group(), pc,
                                                is_return_address, code_start);
  }
  return code_descriptor;
}

CodePtr ReversePc::Lookup(IsolateGroup* group,
                          uword pc,
                          bool is_return_address) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  uword code_start;
  ObjectPtr code_descriptor =
      FindCodeDescriptor(group, pc, is_return_address, &code_start);
  if (code_descriptor != Object::null()) {
    if (!code_descriptor->IsCode()) {
      ASSERT(StubCode::UnknownDartCode().PayloadStart() == 0);
      ASSERT(StubCode::UnknownDartCode().Size() == kUwordMax);
      ASSERT(StubCode::UnknownDartCode().IsFunctionCode());
      ASSERT(StubCode::UnknownDartCode().IsUnknownDartCode());
      code_descriptor = StubCode::UnknownDartCode().ptr();
    }
  }
  return static_cast<CodePtr>(code_descriptor);
}

CompressedStackMapsPtr ReversePc::FindCompressedStackMaps(
    IsolateGroup* group,
    uword pc,
    bool is_return_address,
    uword* code_start) {
  ASSERT(FLAG_precompiled_mode);
  NoSafepointScope no_safepoint;

  ObjectPtr code_descriptor =
      FindCodeDescriptor(group, pc, is_return_address, code_start);
  if (code_descriptor != Object::null()) {
    if (code_descriptor->IsCode()) {
      CodePtr code = static_cast<CodePtr>(code_descriptor);
      ASSERT(*code_start == Code::PayloadStartOf(code));
      return code->untag()->compressed_stackmaps();
    } else {
      ASSERT(code_descriptor->IsCompressedStackMaps());
      return static_cast<CompressedStackMapsPtr>(code_descriptor);
    }
  }

  *code_start = 0;
  return CompressedStackMaps::null();
}

}  // namespace dart
