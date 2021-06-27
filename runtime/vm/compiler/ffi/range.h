// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_RANGE_H_
#define RUNTIME_VM_COMPILER_FFI_RANGE_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/allocation.h"

namespace dart {

namespace compiler {

namespace ffi {

// A non-empty range.
//
// Ranges are positive and non-empty.
//
// The end is exclusive.
class Range {
 public:
  // Constructs a Range from start (inclusive) and length.
  //
  // The resulting range is `[start_inclusive, start_inclusive + length)`.
  static Range StartAndLength(intptr_t start_inclusive, intptr_t length) {
    return Range(start_inclusive, start_inclusive + length);
  }

  // Constructs a Range from start (inclusive) and end (exclusive).
  //
  // The resulting range is `[start_inclusive, end_exclusive)`.
  static Range StartAndEnd(intptr_t start_inclusive, intptr_t end_exclusive) {
    return Range(start_inclusive, end_exclusive);
  }

  intptr_t start() const { return start_; }
  intptr_t end_exclusive() const { return end_exclusive_; }
  intptr_t end_inclusive() const { return end_exclusive_ - 1; }

  intptr_t Length() const { return end_exclusive_ - start_; }

  // Returs true iff number is in this range.
  bool Contains(intptr_t number) const {
    return start_ <= number && number < end_exclusive_;
  }

  // Returns true iff [this] contains [other] completely.
  bool Contains(const Range& other) const {
    return Contains(other.start_) && Contains(other.end_inclusive());
  }

  // Returns true iff [this] is completey after [other].
  bool After(const Range& other) const {
    return other.end_exclusive_ <= start_;
  }

  // Returns true iff [this] contains some numbers of [other].
  bool Overlaps(const Range& other) const {
    return !this->After(other) && !other.After(*this);
  }

  // Returns the intersection of [this] with [other].
  //
  // Requires [this] and [other] to overlap.
  const Range Intersect(const Range& other) const {
    ASSERT(Overlaps(other));
    return Range(Utils::Maximum(start_, other.start_),
                 Utils::Minimum(end_exclusive_, other.end_exclusive_));
  }

  // Returns a range moved by [delta].
  //
  // `this.start() - delta` must be positive.
  const Range Translate(intptr_t delta) const {
    return Range(start_ + delta, end_exclusive_ + delta);
  }

 private:
  Range(intptr_t start_inclusive, intptr_t end_exclusive)
      : start_(start_inclusive), end_exclusive_(end_exclusive) {
    ASSERT(start_ < end_exclusive_);
  }

  const intptr_t start_;
  const intptr_t end_exclusive_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_RANGE_H_
