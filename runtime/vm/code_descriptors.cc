// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_descriptors.h"

namespace dart {

void DescriptorList::AddDescriptor(PcDescriptors::Kind kind,
                                   intptr_t pc_offset,
                                   intptr_t node_id,
                                   intptr_t token_index,
                                   intptr_t try_index) {
  struct PcDesc data;
  data.pc_offset = pc_offset;
  data.kind = kind;
  data.node_id = node_id;
  data.token_index = token_index;
  data.try_index = try_index;
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
                              NodeId(i),
                              TokenIndex(i),
                              TryIndex(i));
  }
  return descriptors.raw();
}


void StackmapBuilder::AddEntry(intptr_t pc_offset) {
  stack_map_ = Stackmap::New(pc_offset, builder_);
  list_.Add(stack_map_);
}


bool StackmapBuilder::Verify() {
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


RawArray* StackmapBuilder::FinalizeStackmaps(const Code& code) {
  ASSERT(Verify());
  intptr_t num_entries = Length();
  uword entry_point = code.EntryPoint();
  if (num_entries == 0) {
    return Array::Empty();
  }
  for (intptr_t i = 0; i < num_entries; i++) {
    stack_map_ = Map(i);
    stack_map_.SetPC(entry_point + stack_map_.PC());
    stack_map_.SetCode(code);
  }
  return Array::MakeArray(list_);
}


RawStackmap* StackmapBuilder::Map(int index) const {
  Stackmap& map = Stackmap::Handle();
  map ^= list_.At(index);
  return map.raw();
}

}  // namespace dart
