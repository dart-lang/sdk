// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/tags.h"

#include "vm/isolate.h"

namespace dart {

const char* VMTag::TagName(uword id) {
  ASSERT(id != kInvalidTagId);
  ASSERT(id < kNumVMTags);
  const TagEntry& entry = entries_[id];
  ASSERT(entry.id == id);
  return entry.name;
}


VMTag::TagEntry VMTag::entries_[] = {
  { "InvalidTag", kInvalidTagId, },
#define DEFINE_VM_TAG_ENTRY(tag)                                               \
  { ""#tag, k##tag##TagId },
  VM_TAG_LIST(DEFINE_VM_TAG_ENTRY)
#undef DEFINE_VM_TAG_ENTRY
  { "kNumVMTags", kNumVMTags },
};


VMTagScope::VMTagScope(Isolate* base_isolate, uword tag)
    : StackResource(base_isolate) {
  ASSERT(isolate() != NULL);
  previous_tag_ = isolate()->vm_tag();
  isolate()->set_vm_tag(tag);
}


VMTagScope::~VMTagScope() {
  ASSERT(isolate() != NULL);
  isolate()->set_vm_tag(previous_tag_);
}


}  // namespace dart
