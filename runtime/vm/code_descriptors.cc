// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_descriptors.h"

namespace dart {

void DescriptorList::AddDescriptor(RawPcDescriptors::Kind kind,
                                   intptr_t pc_offset,
                                   intptr_t deopt_id,
                                   intptr_t token_index,
                                   intptr_t try_index) {
  ASSERT((kind == RawPcDescriptors::kRuntimeCall) ||
         (kind == RawPcDescriptors::kOther) ||
         (deopt_id != Isolate::kNoDeoptId));
  struct PcDesc data;
  data.pc_offset = pc_offset;
  data.kind = kind;
  data.deopt_id = deopt_id;
  data.SetTokenPos(token_index);
  data.try_index = try_index;
  list_.Add(data);
  if (try_index >= 0) {
    has_try_index_ = true;
  }
}


RawPcDescriptors* DescriptorList::FinalizePcDescriptors(uword entry_point) {
  intptr_t num_descriptors = Length();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(PcDescriptors::New(num_descriptors,
                                               has_try_index_));
  for (intptr_t i = 0; i < num_descriptors; i++) {
    descriptors.AddDescriptor(i,
                              PcOffset(i),
                              Kind(i),
                              DeoptId(i),
                              TokenPos(i),
                              TryIndex(i));
  }
  return descriptors.raw();
}


void StackmapTableBuilder::AddEntry(intptr_t pc_offset,
                                    BitmapBuilder* bitmap,
                                    intptr_t register_bit_count) {
  stack_map_ = Stackmap::New(pc_offset, bitmap, register_bit_count);
  list_.Add(stack_map_, Heap::kOld);
}


bool StackmapTableBuilder::Verify() {
  intptr_t num_entries = Length();
  Stackmap& map1 = Stackmap::Handle();
  Stackmap& map2 = Stackmap::Handle();
  for (intptr_t i = 1; i < num_entries; i++) {
    map1 = MapAt(i - 1);
    map2 = MapAt(i);
    // Ensure there are no duplicates and the entries are sorted.
    if (map1.PcOffset() >= map2.PcOffset()) {
      return false;
    }
  }
  return true;
}


RawArray* StackmapTableBuilder::FinalizeStackmaps(const Code& code) {
  ASSERT(Verify());
  intptr_t num_entries = Length();
  if (num_entries == 0) {
    return Object::empty_array().raw();
  }
  return Array::MakeArray(list_);
}


RawStackmap* StackmapTableBuilder::MapAt(intptr_t index) const {
  Stackmap& map = Stackmap::Handle();
  map ^= list_.At(index);
  return map.raw();
}


RawExceptionHandlers* ExceptionHandlerList::FinalizeExceptionHandlers(
    uword entry_point) const {
  intptr_t num_handlers = Length();
  if (num_handlers == 0) {
    return Object::empty_exception_handlers().raw();
  }
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(ExceptionHandlers::New(num_handlers));
  for (intptr_t i = 0; i < num_handlers; i++) {
    // Assert that every element in the array has been initialized.
    if (list_[i].handler_types == NULL) {
      // Unreachable handler, entry not computed.
      // Initialize it to some meaningful value.
      const bool has_catch_all = false;
      // Check it is uninitialized.
      ASSERT((list_[i].outer_try_index == -1) &&
             (list_[i].pc_offset == ExceptionHandlers::kInvalidPcOffset));
      handlers.SetHandlerInfo(i,
                              list_[i].outer_try_index,
                              list_[i].pc_offset,
                              list_[i].needs_stacktrace,
                              has_catch_all);
      handlers.SetHandledTypes(i, Array::null_array());
    } else {
      const bool has_catch_all = ContainsDynamic(*list_[i].handler_types);
      handlers.SetHandlerInfo(i,
                              list_[i].outer_try_index,
                              list_[i].pc_offset,
                              list_[i].needs_stacktrace,
                              has_catch_all);
      handlers.SetHandledTypes(i, *list_[i].handler_types);
    }
  }
  return handlers.raw();
}


}  // namespace dart
