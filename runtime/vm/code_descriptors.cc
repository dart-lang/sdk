// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_descriptors.h"

namespace dart {

void DescriptorList::AddDescriptor(PcDescriptors::Kind kind,
                                   intptr_t pc_offset,
                                   intptr_t deopt_id,
                                   intptr_t token_index,
                                   intptr_t try_index) {
  struct PcDesc data;
  data.pc_offset = pc_offset;
  data.kind = kind;
  data.deopt_id = deopt_id;
  data.token_index = token_index;
  data.try_index = try_index;
  list_.Add(data);
}


void DescriptorList::AddDeoptInfo(intptr_t pc_offset,
                                  intptr_t deopt_id,
                                  intptr_t token_index,
                                  intptr_t deopt_array_index) {
  struct PcDesc data;
  data.pc_offset = pc_offset;
  data.kind = PcDescriptors::kDeoptIndex;
  data.deopt_id = deopt_id;
  data.token_index = token_index;
  // Try_index is reused for deopt_array_index.
  data.try_index = deopt_array_index;
  list_.Add(data);
}


RawPcDescriptors* DescriptorList::FinalizePcDescriptors(uword entry_point) {
  intptr_t num_descriptors = Length();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(PcDescriptors::New(num_descriptors));
  for (intptr_t i = 0; i < num_descriptors; i++) {
    descriptors.AddDescriptor(i,
                              (entry_point + PcOffset(i)),
                              Kind(i),
                              DeoptId(i),
                              TokenPos(i),
                              TryIndex(i));
  }
  return descriptors.raw();
}


void StackmapTableBuilder::AddEntry(intptr_t pc_offset,
                                    BitmapBuilder* bitmap) {
  stack_map_ = Stackmap::New(pc_offset, bitmap);
  list_.Add(stack_map_);
}


bool StackmapTableBuilder::Verify() {
  intptr_t num_entries = Length();
  Stackmap& map1 = Stackmap::Handle();
  Stackmap& map2 = Stackmap::Handle();
  for (intptr_t i = 1; i < num_entries; i++) {
    map1 = Map(i - 1);
    map2 = Map(i);
    // Ensure there are no duplicates and the entries are sorted.
    if (map1.PC() >= map2.PC()) {
      return false;
    }
  }
  return true;
}


RawArray* StackmapTableBuilder::FinalizeStackmaps(const Code& code) {
  ASSERT(Verify());
  intptr_t num_entries = Length();
  uword entry_point = code.EntryPoint();
  if (num_entries == 0) {
    return Object::empty_array();
  }
  for (intptr_t i = 0; i < num_entries; i++) {
    stack_map_ = Map(i);
    stack_map_.SetPC(entry_point + stack_map_.PC());
    stack_map_.SetCode(code);
  }
  return Array::MakeArray(list_);
}


RawStackmap* StackmapTableBuilder::Map(int index) const {
  Stackmap& map = Stackmap::Handle();
  map ^= list_.At(index);
  return map.raw();
}

}  // namespace dart
