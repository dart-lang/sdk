// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_SET_H_
#define VM_OBJECT_SET_H_

#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/raw_object.h"

namespace dart {

class ObjectSet {
 public:
  ObjectSet() {
    Init(0, 0);
  }

  ObjectSet(uword start, uword end) {
    Init(start, end);
  }

  ~ObjectSet() {
    delete[] allocation_;
  }

  void Init(uword start, uword end) {
    start_ = start;
    end_ = end;
    ASSERT(start_ <= end_);
    size_ = SizeFor((end_ - start_) >> kWordSizeLog2);
    allocation_ = new uword[size_];
    const intptr_t skipped_bitfield_words =
        (start >> kWordSizeLog2) / kBitsPerWord;
    data_ = &allocation_[-skipped_bitfield_words];
    ASSERT(allocation_ == &data_[skipped_bitfield_words]);
    Clear();
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
    min_ = Utils::Minimum(raw_addr, min_);
    max_ = Utils::Maximum(raw_addr, max_);
  }

  void Resize(uword start, uword end) {
    if (start_ != start || end_ != end) {
      delete[] allocation_;
      Init(start, end);
    }
  }

  void Clear() {
    memset(allocation_, 0, (size_ * sizeof(allocation_[0])));
    min_ = end_;
    max_ = start_;
  }

  void FastClear() {
    uword i = min_ >> kWordSizeLog2;
    memset(&data_[i / kBitsPerWord],
           0,
           sizeof(uword) * SizeFor((max_ + 1  - min_) >> kWordSizeLog2));
    min_ = end_;
    max_ = start_;
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

  // The inclusive minimum address set in this ObjectMap.
  // Used by FastClear
  uword min_;

  // The inclusive maximum address in this ObjectMap.
  // Used by FastClear
  uword max_;

  DISALLOW_COPY_AND_ASSIGN(ObjectSet);
};

}  // namespace dart

#endif  // VM_OBJECT_SET_H_
