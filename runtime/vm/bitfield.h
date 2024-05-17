// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITFIELD_H_
#define RUNTIME_VM_BITFIELD_H_

#include <type_traits>

#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/globals.h"
#include "platform/thread_sanitizer.h"

namespace dart {

class AtomicBitFieldContainerBase {
 private:
  AtomicBitFieldContainerBase() = delete;  // Only used for std::is_base_of.
};

template <typename T>
class AtomicBitFieldContainer : AtomicBitFieldContainerBase {
  static_assert(sizeof(std::atomic<T>) == sizeof(T),
                "Size of type changes when made atomic");

 public:
  using ContainedType = T;

  AtomicBitFieldContainer() : field_(0) {}

  operator T() const { return field_.load(std::memory_order_relaxed); }
  T operator=(T tags) {
    field_.store(tags, std::memory_order_relaxed);
    return tags;
  }

  T load(std::memory_order order) const { return field_.load(order); }
  void store(T value, std::memory_order order) { field_.store(value, order); }

  bool compare_exchange_weak(T old_tags, T new_tags, std::memory_order order) {
    return field_.compare_exchange_weak(old_tags, new_tags, order);
  }

  template <class TargetBitField,
            std::memory_order order = std::memory_order_relaxed>
  typename TargetBitField::Type Read() const {
    return TargetBitField::decode(field_.load(order));
  }

  template <class TargetBitField>
  NO_SANITIZE_THREAD typename TargetBitField::Type ReadIgnoreRace() const {
    return TargetBitField::decode(*reinterpret_cast<const T*>(&field_));
  }

  template <class TargetBitField,
            std::memory_order order = std::memory_order_relaxed>
  void UpdateBool(bool value) {
    if (value) {
      field_.fetch_or(TargetBitField::encode(true), order);
    } else {
      field_.fetch_and(~TargetBitField::encode(true), order);
    }
  }

  template <class TargetBitField>
  void FetchOr(typename TargetBitField::Type value) {
    field_.fetch_or(TargetBitField::encode(value), std::memory_order_relaxed);
  }

  template <class TargetBitField>
  void Update(typename TargetBitField::Type value) {
    T old_field = field_.load(std::memory_order_relaxed);
    T new_field;
    do {
      new_field = TargetBitField::update(value, old_field);
    } while (!field_.compare_exchange_weak(old_field, new_field,
                                           std::memory_order_relaxed));
  }

  template <class TargetBitField>
  void UpdateUnsynchronized(typename TargetBitField::Type value) {
    field_.store(
        TargetBitField::update(value, field_.load(std::memory_order_relaxed)),
        std::memory_order_relaxed);
  }

  template <class TargetBitField>
  typename TargetBitField::Type UpdateConditional(
      typename TargetBitField::Type value_to_be_set,
      typename TargetBitField::Type conditional_old_value) {
    T old_field = field_.load(std::memory_order_relaxed);
    while (true) {
      // This operation is only performed if the condition is met.
      auto old_value = TargetBitField::decode(old_field);
      if (old_value != conditional_old_value) {
        return old_value;
      }
      T new_tags = TargetBitField::update(value_to_be_set, old_field);
      if (field_.compare_exchange_weak(old_field, new_tags,
                                       std::memory_order_relaxed)) {
        return value_to_be_set;
      }
      // [old_tags] was updated to it's current value.
    }
  }

  template <class TargetBitField>
  bool TryAcquire() {
    T mask = TargetBitField::encode(true);
    T old_field = field_.fetch_or(mask, std::memory_order_relaxed);
    return !TargetBitField::decode(old_field);
  }

  template <class TargetBitField>
  bool TryClear() {
    T mask = ~TargetBitField::encode(true);
    T old_field = field_.fetch_and(mask, std::memory_order_relaxed);
    return TargetBitField::decode(old_field);
  }

 private:
  std::atomic<T> field_;
};

static constexpr uword kUwordOne = 1U;

// BitField is a template for encoding and decoding a value of type T
// inside a storage of type S.
template <typename S,
          typename T,
          int position,
          int size = (sizeof(S) * kBitsPerByte) - position,
          bool sign_extend = false,
          typename Enable = void>
class BitField {
 public:
  typedef T Type;

  static_assert((sizeof(S) * kBitsPerByte) >= (position + size),
                "BitField does not fit into the type.");
  static_assert(!sign_extend || std::is_signed<T>::value,
                "Should only sign extend signed bitfield types");

  static constexpr intptr_t kNextBit = position + size;

  // Tells whether the provided value fits into the bit field.
  static constexpr bool is_valid(T value) {
    return decode(encode_unchecked(value)) == value;
  }

  // Returns a S mask of the bit field.
  static constexpr S mask() { return (kUwordOne << size) - 1; }

  // Returns a S mask of the bit field which can be applied directly to
  // to the raw unshifted bits.
  static constexpr S mask_in_place() { return mask() << position; }

  // Returns the shift count needed to right-shift the bit field to
  // the least-significant bits.
  static constexpr int shift() { return position; }

  // Returns the size of the bit field.
  static constexpr int bitsize() { return size; }

  // Returns an S with the bit field value encoded.
  static constexpr S encode(T value) {
    ASSERT(is_valid(value));
    return encode_unchecked(value);
  }

  // Extracts the bit field from the value.
  static constexpr T decode(S value) {
    // Ensure we slide down the sign bit if the value in the bit field is signed
    // and negative. We use 64-bit ints inside the expression since we can have
    // both cases: sizeof(S) > sizeof(T) or sizeof(S) < sizeof(T).
    if constexpr (sign_extend) {
      auto const u = static_cast<uint64_t>(value);
      return static_cast<T>((static_cast<int64_t>(u << (64 - kNextBit))) >>
                            (64 - size));
    } else {
      auto const u = static_cast<typename std::make_unsigned<S>::type>(value);
      return static_cast<T>((u >> position) & mask());
    }
  }

  // Returns an S with the bit field value encoded based on the
  // original value. Only the bits corresponding to this bit field
  // will be changed.
  static constexpr S update(T value, S original) {
    return encode(value) | (~mask_in_place() & original);
  }

 private:
  // Returns an S with the bit field value encoded.
  static constexpr S encode_unchecked(T value) {
    auto const u = static_cast<typename std::make_unsigned<S>::type>(value);
    return (u & mask()) << position;
  }
};

// Partial instantiations to avoid having to change BitField declarations if
// S is decltype(field_) and the type of field_ is changed to be wrapped in an
// AtomicBitFieldContainer.
template <typename S, typename T, int position, int size, bool sign_extend>
class BitField<S,
               T,
               position,
               size,
               sign_extend,
               typename std::enable_if<
                   std::is_base_of<AtomicBitFieldContainerBase, S>::value,
                   void>::type> : public BitField<typename S::ContainedType,
                                                  T,
                                                  position,
                                                  size,
                                                  sign_extend> {};

template <typename S, typename T, int position, int size>
class BitField<S,
               T,
               position,
               size,
               false,
               typename std::enable_if<
                   std::is_base_of<AtomicBitFieldContainerBase, S>::value,
                   void>::type>
    : public BitField<typename S::ContainedType, T, position, size, false> {};

}  // namespace dart

#endif  // RUNTIME_VM_BITFIELD_H_
