// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_SET_H_
#define RUNTIME_VM_OBJECT_SET_H_

#include "platform/utils.h"
#include "vm/bit_vector.h"
#include "vm/globals.h"
#include "vm/raw_object.h"
#include "vm/zone.h"

namespace dart {

class ObjectSetRegion : public ZoneAllocated {
 public:
  ObjectSetRegion(Zone* zone, uword start, uword end)
      : start_(start),
        end_(end),
        bit_vector_(zone, (end - start) >> kWordSizeLog2) {}

  bool ContainsAddress(uword address) const {
    return address >= start_ && address < end_;
  }

  intptr_t IndexForAddress(uword address) const {
    ASSERT(Utils::IsAligned(address, kWordSize));
    return (address - start_) >> kWordSizeLog2;
  }

  void AddObject(uword address) { bit_vector_.Add(IndexForAddress(address)); }

  bool ContainsObject(uword address) const {
    return bit_vector_.Contains(IndexForAddress(address));
  }

  uword start() const { return start_; }
  uword end() const { return end_; }

 private:
  uword start_;
  uword end_;
  BitVector bit_vector_;
};

class ObjectSet : public ZoneAllocated {
 public:
  explicit ObjectSet(Zone* zone) : zone_(zone), sorted_(true), regions_() {}

  void AddRegion(uword start, uword end) {
    if (start == end) {
      return;  // Ignore empty regions, such as semispaces in the vm-isolate.
    }
    ASSERT(start < end);
    ObjectSetRegion* region = new (zone_) ObjectSetRegion(zone_, start, end);
    regions_.Add(region);
    sorted_ = false;
  }

  void SortRegions() {
    regions_.Sort(CompareRegions);
    sorted_ = true;
  }

  bool Contains(ObjectPtr raw_obj) const {
    uword raw_addr = ObjectLayout::ToAddr(raw_obj);
    ObjectSetRegion* region;
    if (FindRegion(raw_addr, &region)) {
      return region->ContainsObject(raw_addr);
    }
    return false;
  }

  void Add(ObjectPtr raw_obj) {
    uword raw_addr = ObjectLayout::ToAddr(raw_obj);
    ObjectSetRegion* region;
    if (FindRegion(raw_addr, &region)) {
      return region->AddObject(raw_addr);
    }
    FATAL("Address not in any heap region");
  }

 private:
  static int CompareRegions(ObjectSetRegion* const* a,
                            ObjectSetRegion* const* b) {
    const uword a_start = (*a)->start();
    const uword b_start = (*b)->start();
    if (a_start < b_start) {
      return -1;
    } else if (a_start == b_start) {
      return 0;
    } else {
      return 1;
    }
  }

  bool FindRegion(uword addr, ObjectSetRegion** region) const {
    ASSERT(sorted_);
    intptr_t lo = 0;
    intptr_t hi = regions_.length() - 1;
    while (lo <= hi) {
      const intptr_t mid = (hi - lo + 1) / 2 + lo;
      ASSERT(mid >= lo);
      ASSERT(mid <= hi);
      *region = regions_[mid];
      if (addr < (*region)->start()) {
        hi = mid - 1;
      } else if (addr >= (*region)->end()) {
        lo = mid + 1;
      } else {
        return true;
      }
    }
    return false;
  }

  Zone* zone_;
  bool sorted_;
  GrowableArray<ObjectSetRegion*> regions_;
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_SET_H_
