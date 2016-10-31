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
        bit_vector_(zone, (end - start) >> kWordSizeLog2),
        next_(NULL) {
  }

  bool ContainsAddress(uword address) {
    return address >= start_ && address < end_;
  }

  intptr_t IndexForAddress(uword address) {
    ASSERT(Utils::IsAligned(address, kWordSize));
    return (address - start_) >> kWordSizeLog2;
  }

  void AddObject(uword address) {
    bit_vector_.Add(IndexForAddress(address));
  }

  bool ContainsObject(uword address) {
    return bit_vector_.Contains(IndexForAddress(address));
  }

  ObjectSetRegion* next() { return next_; }
  void set_next(ObjectSetRegion* region) { next_ = region; }

 private:
  uword start_;
  uword end_;
  BitVector bit_vector_;
  ObjectSetRegion* next_;
};

class ObjectSet : public ZoneAllocated {
 public:
  explicit ObjectSet(Zone* zone) : zone_(zone), head_(NULL) { }

  void AddRegion(uword start, uword end) {
    ObjectSetRegion* region = new(zone_) ObjectSetRegion(zone_, start, end);
    region->set_next(head_);
    head_ = region;
  }

  bool Contains(RawObject* raw_obj) const {
    uword raw_addr = RawObject::ToAddr(raw_obj);
    for (ObjectSetRegion* region = head_;
         region != NULL;
         region = region->next()) {
      if (region->ContainsAddress(raw_addr)) {
        return region->ContainsObject(raw_addr);
      }
    }
    return false;
  }

  void Add(RawObject* raw_obj) {
    uword raw_addr = RawObject::ToAddr(raw_obj);
    for (ObjectSetRegion* region = head_;
         region != NULL;
         region = region->next()) {
      if (region->ContainsAddress(raw_addr)) {
        return region->AddObject(raw_addr);
      }
    }
    FATAL("Address not in any heap region");
  }

 private:
  Zone* zone_;
  ObjectSetRegion* head_;
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_SET_H_
