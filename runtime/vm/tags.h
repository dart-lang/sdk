// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TAGS_H_
#define VM_TAGS_H_

#include "vm/allocation.h"

namespace dart {

class Isolate;
class JSONObject;

#define VM_TAG_LIST(V)                                                         \
  V(Idle)                                                                      \
  V(VM) /* Catch all */                                                        \
  V(Compile)                                                                   \
  V(Script)                                                                    \
  V(GCNewSpace)                                                                \
  V(GCOldSpace)                                                                \
  V(RuntimeNative)                                                             \


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

  static const char* TagName(uword id);

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

}  // namespace dart

#endif  // VM_TAGS_H_
