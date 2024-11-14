// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BITFIELD_H_
#define RUNTIME_VM_BITFIELD_H_

#include <type_traits>

#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/globals.h"
#include "platform/no_tsan.h"
#include "platform/thread_sanitizer.h"
#include "platform/utils.h"

namespace dart {

template <typename T>
class AtomicBitFieldContainer {
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
  NO_SANITIZE_THREAD T load_ignore_race() const {
    return *reinterpret_cast<const T*>(&field_);
  }
  void store(T value, std::memory_order order) { field_.store(value, order); }

  bool compare_exchange_weak(T old_tags, T new_tags, std::memory_order order) {
    return field_.compare_exchange_weak(old_tags, new_tags, order);
  }

  template <class TargetBitField,
            std::memory_order order = std::memory_order_relaxed>
  typename TargetBitField::Type Read() const {
    return TargetBitField::decode(field_.load(order));
  }

  template <class TargetBitField,
            std::memory_order order = std::memory_order_relaxed>
  void UpdateBool(bool value) {
    if (value) {
      field_.fetch_or(TargetBitField::encode(true), order);
    } else {
      field_.fetch_and(static_cast<T>(~TargetBitField::encode(true)), order);
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

  template <class TargetBitField>
  bool TryClearIgnoreRace() {
    T mask = ~TargetBitField::encode(true);
    T old_field = FetchAndRelaxedIgnoreRace(&field_, mask);
    return TargetBitField::decode(old_field);
  }

 private:
  std::atomic<T> field_;
};

static constexpr uword kUwordOne = 1U;

#define BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position)               \
  ((sizeof(S) * kBitsPerByte - position > sizeof(T) * kBitsPerByte)            \
       ? sizeof(T) * kBitsPerByte                                              \
       : sizeof(S) * kBitsPerByte - (position))

// BitField is a template for encoding and decoding a value of type T
// inside a storage of type S. If a requested size is not provided, then:
// * If T is bool, the requested size is 1.
// * If the remaining bits is larger than the number of bits needed to store a
//   value of type T, then the requested size is sizeof(T) * kBitsPerByte.
// * Otherwise, the requsted size is the number of remaining bits.
//
// Note that the size of the bitfield may be smaller than the requested size,
// if T is a signed type and the requested size includes the sign bit of T.
//
// Note: S and T must be static_cast-able to and from an integral type. If S is
// decltype(field_) and field_ is defined as
//   std::atomic<U> field_;
// then change the definition to be
//   AtomicBitFieldContainer<U> field_;
// which is supported by partial specializations to work like a BitField on U.
template <typename S,
          typename T,
          int position = 0,
          int requested_size =
              std::is_same_v<T, bool>
                  ? 1
                  : BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position),
          bool sign_extend = false,
          typename Enable = void>
class BitField {
 public:
  using Type = T;

  static_assert(sizeof(S) * kBitsPerByte <= kBitsPerInt64,
                "The container type cannot be larger than 64 bits.");
  static_assert(sizeof(T) * kBitsPerByte <= kBitsPerInt64,
                "The value type cannot be larger than 64 bits.");
  static_assert(requested_size > 0, "A non-positive size was requested.");
  static_assert(requested_size <= sizeof(T) * kBitsPerByte,
                "The value type cannot hold all values of the requested size.");
  static_assert(!sign_extend || std::is_signed_v<T>,
                "Only signed bitfield types should be sign extended.");

 private:
  static constexpr int size =
      !sign_extend && std::is_signed_v<T> &&
              (sizeof(T) * kBitsPerByte <= requested_size)
          ? (sizeof(T) * kBitsPerByte - 1)
          : requested_size;

 public:
  static_assert((sizeof(S) * kBitsPerByte) >= (position + size),
                "BitField does not fit into the container type.");

  static constexpr intptr_t kNextBit = position + size;

  // Tells whether the provided value fits into the bit field.
  static constexpr bool is_valid(T value) {
    return decode(encode_unchecked(value)) == value;
  }

  // Returns a S mask of the bit field.
  static constexpr S mask() {
    return static_cast<S>(Utils::NBitMask<uint64_t>(size));
  }

  // Returns a S mask of the bit field which can be applied directly to
  // to the raw unshifted bits.
  static constexpr S mask_in_place() {
    return static_cast<S>(static_cast<uint64_t>(mask()) << position);
  }

  // Returns the shift count needed to right-shift the bit field to
  // the least-significant bits.
  static constexpr int shift() { return position; }

  // Returns the size of the bit field.
  static constexpr int bitsize() { return size; }

  // Returns whether the sign bit of the value is sign extended.
  static constexpr bool sign_extended() { return sign_extend; }

  // Returns the maximum value encodable in the bitfield.
  static constexpr T max() {
    constexpr size_t magnitude_bits = bitsize() - (sign_extended() ? 1 : 0);
    return static_cast<T>(Utils::NBitMask<uint64_t>(magnitude_bits));
  }

  // Returns the minimum value encodable in the bitfield.
  static constexpr T min() {
    return static_cast<T>(sign_extended() ? ~static_cast<uint64_t>(max()) : 0);
  }

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
    auto const u = static_cast<uint64_t>(value);
    if constexpr (sign_extend) {
      return static_cast<T>((static_cast<int64_t>(u << (64 - kNextBit))) >>
                            (64 - size));
    } else {
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
    auto const u = static_cast<uint64_t>(value);
    return static_cast<S>(u & mask()) << position;
  }
};

// Partial instantiations to avoid having to change BitField declarations if
// S is decltype(field_) and the type of field_ is changed to be wrapped in an
// AtomicBitFieldContainer, which includes not having to provide any values for
// parameters that would otherwise be appropriately deduced when not provided
// for a BitField on an integral type S.
//
// Note that some specializations are duplicated for T != bool and T = bool,
// since partial specializations cannot specialize the requested size with a
// value that checks the type of T (to use a default requested size of 1
// if T == bool and otherwise sizeof(T) * kBitsPerByte).

template <typename S, typename T, int position, int size, bool sign_extend>
class BitField<S,
               T,
               position,
               size,
               sign_extend,
               std::void_t<typename S::ContainedType>>
    : public BitField<typename S::ContainedType,
                      T,
                      position,
                      size,
                      sign_extend> {};

template <typename S, typename T, int position, int size>
class BitField<
    S,
    T,
    position,
    size,
    false,
    std::void_t<std::enable_if_t<
        size != BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position) &&
            !std::is_same_v<T, bool>,
        typename S::ContainedType>>>
    : public BitField<typename S::ContainedType, T, position, size, false> {};

template <typename S, typename T, int position>
class BitField<
    S,
    T,
    position,
    BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position),
    false,
    std::void_t<std::enable_if_t<position != 0 && !std::is_same_v<T, bool>,
                                 typename S::ContainedType>>>
    : public BitField<typename S::ContainedType,
                      T,
                      position,
                      BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position),
                      false> {};

template <typename S, typename T>
class BitField<S,
               T,
               0,
               BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, 0),
               false,
               std::void_t<std::enable_if_t<!std::is_same_v<T, bool>,
                                            typename S::ContainedType>>>
    : public BitField<typename S::ContainedType,
                      T,
                      0,
                      BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, 0),
                      false> {};

template <typename S, int position, int size>
class BitField<
    S,
    bool,
    position,
    size,
    false,
    std::void_t<std::enable_if_t<size != 1, typename S::ContainedType>>>
    : public BitField<typename S::ContainedType, bool, position, size, false> {
};

template <typename S, int position>
class BitField<
    S,
    bool,
    position,
    1,
    false,
    std::void_t<std::enable_if_t<position != 0, typename S::ContainedType>>>
    : public BitField<typename S::ContainedType, bool, position, 1, false> {};

template <typename S>
class BitField<S, bool, 0, 1, false, std::void_t<typename S::ContainedType>>
    : public BitField<typename S::ContainedType, bool, 0, 1, false> {};

// Alias for sign-extended BitFields to avoid being forced to provide a size
// and/or position when the default values are appropriate.
template <typename S,
          typename T,
          int position = 0,
          int size = BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION(S, T, position)>
using SignedBitField = BitField<S,
                                T,
                                position,
                                size,
                                /*sign_extend=*/true,
                                std::enable_if_t<std::is_signed_v<T>, void>>;

#undef BITFIELD_NON_BOOL_MIN_SIZE_WITH_POSITION

}  // namespace dart

#endif  // RUNTIME_VM_BITFIELD_H_
