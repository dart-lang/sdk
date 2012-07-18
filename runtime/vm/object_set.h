// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_SET_H_
#define VM_OBJECT_SET_H_

#include "vm/globals.h"

namespace dart {

class ObjectSet {
 public:
  ObjectSet(uword start, uword end) : start_(start), end_(end) {
    ASSERT(start_ <= end_);
    size_ = SizeFor((end_ - start_) >> kWordSizeLog2);
    allocation_ = new uword[size_];
    data_ = &allocation_[-((start >> kWordSizeLog2) / kBitsPerWord)];
    ASSERT(allocation_ == &data_[(start >> kWordSizeLog2) / kBitsPerWord]);
    Clear();
  }

  ~ObjectSet() {
    delete[] allocation_;
  }

  bool Contains(RawObject* raw_obj) const {
    uword raw_addr = RawObject::ToAddr(raw_obj);
    ASSERT(raw_addr >= start_);
    ASSERT(raw_addr < end_);
    uword i = raw_addr >> kWordSizeLog2;
    uword mask = (static_cast<uword>(1) << (i % kBitsPerWord));
    return (data_[i / kBitsPerWord] & mask) != 0;
  }

  void Add(RawObject* raw_obj) {
    uword raw_addr = RawObject::ToAddr(raw_obj);
    ASSERT(raw_addr >= start_);
    ASSERT(raw_addr < end_);
    uword i = raw_addr >> kWordSizeLog2;
    data_[i / kBitsPerWord] |= (static_cast<uword>(1) << (i % kBitsPerWord));
  }

  void Clear() {
    memset(allocation_, 0, (size_ * sizeof(allocation_[0])));
  }

 private:
  static intptr_t SizeFor(intptr_t length) {
    return 1 + ((length - 1) / kBitsPerWord);
  }

  // Biased data pointer aliased to allocation_.  This value can be
  // indexed without adjusting for the starting address of the heap.
  uword* data_;

  // Allocated data pointer.
  uword* allocation_;

  // Allocation size in uwords.
  intptr_t size_;

  // Lowest possible heap address, inclusive.
  uword start_;

  // Highest possible heap address, exclusive.
  uword end_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectSet);
};

}  // namespace dart

#endif  // VM_OBJECT_SET_H_
