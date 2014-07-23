// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TAGS_H_
#define VM_TAGS_H_

#include "vm/allocation.h"

namespace dart {

class Isolate;
class JSONObject;
class RuntimeEntry;

#define VM_TAG_LIST(V)                                                         \
  V(Idle)                                                                      \
  V(VM) /* Catch all */                                                        \
  V(CompileOptimized)                                                          \
  V(CompileUnoptimized)                                                        \
  V(CompileTopLevel)                                                           \
  V(CompileScanner)                                                            \
  V(Dart)                                                                      \
  V(GCNewSpace)                                                                \
  V(GCOldSpace)                                                                \
  V(Runtime)                                                                   \
  V(Native)                                                                    \

class VMTag : public AllStatic {
 public:
  enum VMTagId {
    kInvalidTagId = 0,
#define DEFINE_VM_TAG_ID(tag)                                                  \
    k##tag##TagId,
    VM_TAG_LIST(DEFINE_VM_TAG_ID)
#undef DEFINE_VM_TAG_KIND
    kNumVMTags,
  };

  static bool IsVMTag(uword id) {
    return (id != kInvalidTagId) && (id < kNumVMTags);
  }
  static const char* TagName(uword id);
  static bool IsNativeEntryTag(uword id);

  static bool IsRuntimeEntryTag(uword id);
  static const char* RuntimeEntryTagName(uword id);

  static void RegisterRuntimeEntry(RuntimeEntry* runtime_entry);

 private:
  struct TagEntry {
    const char* name;
    uword id;
  };
  static TagEntry entries_[];
};


class VMTagScope : StackResource {
 public:
  VMTagScope(Isolate* isolate, uword tag);
  ~VMTagScope();
 private:
  uword previous_tag_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(VMTagScope);
};


class VMTagCounters {
 public:
  VMTagCounters();

  void Increment(uword tag);

  int64_t count(uword tag);

  void PrintToJSONObject(JSONObject* obj);

 private:
  int64_t counters_[VMTag::kNumVMTags];
};


class UserTags : public AllStatic {
 public:
  // UserTag id space: [kUserTagIdOffset, kUserTagIdOffset + kMaxUserTags).
  static const intptr_t kMaxUserTags = 64;
  static const uword kUserTagIdOffset = 0x4096;
  static const uword kDefaultUserTag = kUserTagIdOffset;
  static const char* TagName(uword tag_id);
  static bool IsUserTag(uword tag_id) {
    return (tag_id >= kUserTagIdOffset) &&
           (tag_id < kUserTagIdOffset + kMaxUserTags);
  }
};


}  // namespace dart

#endif  // VM_TAGS_H_
