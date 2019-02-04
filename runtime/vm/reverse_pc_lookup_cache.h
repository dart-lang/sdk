// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
#define RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

class Isolate;

#if defined(DART_PRECOMPILED_RUNTIME)

// A cache for looking up a Code object based on pc (currently the cache is
// implemented as a binary-searchable uint32 array)
//
// If an AOT snapshot was created with --use_bare_instructions the isolate's
// object store will contain a `code_order_table` - which is a sorted array
// of [Code] objects.  The order is based on addresses of the code's
// instructions in memory.
//
// For a binary search we would need to touch O(log(array-size)) array entries,
// code objects and instruction objects.
//
// To avoid this we make another uint32 array which is initialized from the end
// PCs of the instructions (relative to the start pc of the first instruction
// object).
//
// We have the following invariants:
//
//   BeginPcFromCode(code_array[0]) <= pc_array[0]
//   pc_array[i] == EndPcFromCode(code_array[i])
//   pc_array[i] <= pc_array[i+1]
//
// The lookup will then do a binary search in pc_array. The index can then be
// used in the `code_order_table` of the object store.
//
// WARNING: This class cannot do memory allocation or handle allocation!
class ReversePcLookupCache {
 public:
  ReversePcLookupCache(Isolate* isolate,
                       uint32_t* pc_array,
                       intptr_t length,
                       uword first_absolute_pc,
                       uword last_absolute_pc)
      : isolate_(isolate),
        pc_array_(pc_array),
        length_(length),
        first_absolute_pc_(first_absolute_pc),
        last_absolute_pc_(last_absolute_pc) {}
  ~ReversePcLookupCache() { delete[] pc_array_; }

  // Builds a [ReversePcLookupCache] and attaches it to the isolate (if
  // `code_order_table` is non-`null`).
  static void BuildAndAttachToIsolate(Isolate* isolate);

  // Returns `true` if the given [pc] contains can be mapped to a [Code] object
  // using this cache.
  inline bool Contains(uword pc) {
    return first_absolute_pc_ <= pc && pc <= last_absolute_pc_;
  }

  // Looks up the [Code] object from a given [pc].
  inline RawCode* Lookup(uword pc) {
    NoSafepointScope no_safepoint_scope;

    intptr_t left = 0;
    intptr_t right = length_ - 1;

    ASSERT(first_absolute_pc_ <= pc && pc < last_absolute_pc_);
    uint32_t pc_offset = static_cast<uint32_t>(pc - first_absolute_pc_);

    while (left < right) {
      intptr_t middle = left + (right - left) / 2;

      uword middle_pc = pc_array_[middle];
      if (middle_pc < pc_offset) {
        left = middle + 1;
      } else {
        right = middle;
      }
    }

    auto code_array = isolate_->object_store()->code_order_table();
    auto raw_code = reinterpret_cast<RawCode*>(Array::DataOf(code_array)[left]);

#if defined(DEBUG)
    ASSERT(raw_code->GetClassIdMayBeSmi() == kCodeCid);
    ASSERT(Code::ContainsInstructionAt(raw_code, pc));
#endif

    return raw_code;
  }

 private:
  Isolate* isolate_;
  uint32_t* pc_array_;
  intptr_t length_;
  uword first_absolute_pc_;
  uword last_absolute_pc_;
};

#else  // defined(DART_PRECOMPILED_RUNTIME

class ReversePcLookupCache {
 public:
  ReversePcLookupCache() {}
  ~ReversePcLookupCache() {}

  static void BuildAndAttachToIsolate(Isolate* isolate) {}

  inline bool Contains(uword pc) { return false; }

  inline RawCode* Lookup(uword pc) { UNREACHABLE(); }
};

#endif  // defined(DART_PRECOMPILED_RUNTIME

}  // namespace dart

#endif  // RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
