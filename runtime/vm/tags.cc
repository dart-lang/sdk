// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/tags.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"

namespace dart {

const char* VMTag::TagName(uword tag) {
  ASSERT(tag != kInvalidTagId);
  ASSERT(tag < kNumVMTags);
  const TagEntry& entry = entries_[tag];
  ASSERT(entry.id == tag);
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


VMTagCounters::VMTagCounters() {
  for (intptr_t i = 0; i < VMTag::kNumVMTags; i++) {
    counters_[i] = 0;
  }
}


void VMTagCounters::Increment(uword tag) {
  ASSERT(tag != VMTag::kInvalidTagId);
  ASSERT(tag < VMTag::kNumVMTags);
  counters_[tag]++;
}


int64_t VMTagCounters::count(uword tag) {
  ASSERT(tag != VMTag::kInvalidTagId);
  ASSERT(tag < VMTag::kNumVMTags);
  return counters_[tag];
}


void VMTagCounters::PrintToJSONObject(JSONObject* obj) {
  {
    JSONArray arr(obj, "names");
    for (intptr_t i = 1; i < VMTag::kNumVMTags; i++) {
      arr.AddValue(VMTag::TagName(i));
    }
  }
  {
    JSONArray arr(obj, "counters");
    for (intptr_t i = 1; i < VMTag::kNumVMTags; i++) {
      arr.AddValue64(counters_[i]);
    }
  }
}

}  // namespace dart
