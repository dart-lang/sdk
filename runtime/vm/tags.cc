// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/tags.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"

namespace dart {

const char* VMTag::TagName(uword tag) {
  if (IsNativeEntryTag(tag)) {
    const uint8_t* native_reverse_lookup = NativeEntry::ResolveSymbol(tag);
    if (native_reverse_lookup != NULL) {
      return reinterpret_cast<const char*>(native_reverse_lookup);
    }
    return "Unknown native entry";
  } else if (IsRuntimeEntryTag(tag)) {
    const char* runtime_entry_name = RuntimeEntryTagName(tag);
    ASSERT(runtime_entry_name != NULL);
    return runtime_entry_name;
  }
  ASSERT(tag != kInvalidTagId);
  ASSERT(tag < kNumVMTags);
  const TagEntry& entry = entries_[tag];
  ASSERT(entry.id == tag);
  return entry.name;
}

bool VMTag::IsNativeEntryTag(uword tag) {
  return (tag > kLastTagId) && !IsRuntimeEntryTag(tag);
}

bool VMTag::IsDartTag(uword id) {
  return (id == kDartTagId);
}

bool VMTag::IsExitFrameTag(uword id) {
  return (id != 0) && !IsDartTag(id) && (id != kIdleTagId) &&
         (id != kVMTagId) && (id != kEmbedderTagId);
}

bool VMTag::IsRuntimeEntryTag(uword id) {
  return RuntimeEntryTagName(id) != nullptr;
}

const char* VMTag::RuntimeEntryTagName(uword id) {
  void* address = reinterpret_cast<void*>(id);

#define CHECK_RUNTIME_ADDRESS(n)                                               \
  if (address == k##n##RuntimeEntry.function())                                \
    return k##n##RuntimeEntry.name();
  RUNTIME_ENTRY_LIST(CHECK_RUNTIME_ADDRESS)
#undef CHECK_RUNTIME_ADDRESS

#define CHECK_LEAF_RUNTIME_ADDRESS(type, n, ...)                               \
  if (address == k##n##RuntimeEntry.function())                                \
    return k##n##RuntimeEntry.name();
  LEAF_RUNTIME_ENTRY_LIST(CHECK_LEAF_RUNTIME_ADDRESS)
#undef CHECK_LEAF_RUNTIME_ADDRESS

  return nullptr;
}

VMTag::TagEntry VMTag::entries_[] = {
    {
        "InvalidTag", kInvalidTagId,
    },
#define DEFINE_VM_TAG_ENTRY(tag) {"" #tag, k##tag##TagId},
    VM_TAG_LIST(DEFINE_VM_TAG_ENTRY)
#undef DEFINE_VM_TAG_ENTRY
        {"kNumVMTags", kNumVMTags},
};

VMTagScope::VMTagScope(Thread* thread, uword tag, bool conditional_set)
    : ThreadStackResource(thread) {
  if (thread != NULL) {
    ASSERT(isolate_group() != NULL);
    previous_tag_ = thread->vm_tag();
    if (conditional_set) {
      thread->set_vm_tag(tag);
    }
  }
}

VMTagScope::~VMTagScope() {
  if (thread() != NULL) {
    ASSERT(isolate_group() != NULL);
    thread()->set_vm_tag(previous_tag_);
  }
}

VMTagCounters::VMTagCounters() {
  for (intptr_t i = 0; i < VMTag::kNumVMTags; i++) {
    counters_[i] = 0;
  }
}

void VMTagCounters::Increment(uword tag) {
  if (VMTag::IsRuntimeEntryTag(tag)) {
    counters_[VMTag::kRuntimeTagId]++;
    return;
  } else if (tag > VMTag::kNumVMTags) {
    // Assume native entry.
    counters_[VMTag::kNativeTagId]++;
    return;
  }
  ASSERT(tag != VMTag::kInvalidTagId);
  ASSERT(tag < VMTag::kNumVMTags);
  counters_[tag]++;
}

int64_t VMTagCounters::count(uword tag) {
  ASSERT(tag != VMTag::kInvalidTagId);
  ASSERT(tag < VMTag::kNumVMTags);
  return counters_[tag];
}

#ifndef PRODUCT
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
#endif  // !PRODUCT

const char* UserTags::TagName(uword tag_id) {
  ASSERT(tag_id >= kUserTagIdOffset);
  ASSERT(tag_id < kUserTagIdOffset + kMaxUserTags);
  Zone* zone = Thread::Current()->zone();
  const UserTag& tag = UserTag::Handle(zone, UserTag::FindTagById(tag_id));
  ASSERT(!tag.IsNull());
  const String& label = String::Handle(zone, tag.label());
  return label.ToCString();
}

}  // namespace dart
