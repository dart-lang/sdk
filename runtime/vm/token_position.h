// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TOKEN_POSITION_H_
#define RUNTIME_VM_TOKEN_POSITION_H_

#include "platform/utils.h"
#include "vm/allocation.h"

namespace dart {

// The token space is organized as follows:
//
// Sentinel values start at -1 and move towards negative infinity:
// kNoSourcePos                -> -1
// ClassifyingTokenPositions 1 -> -1 - 1
// ClassifyingTokenPositions N -> -1 - N
//
// Real token positions represent source offsets in some script, and are encoded
// as non-negative values which are equal to that offset.
//
// Synthetically created functions that correspond to user code are given
// starting token positions unique from other synthetic functions. The value for
// these token positions encode a unique non-negative value as a negative number
// within [kSmiMin32, -1 - N).
//
// For example:
// A synthetic token with value 0 is encoded as ((-1 - N) - (0 + 1)) = -2 - N.
// A synthetic token with value 1 is encoded as ((-1 - N) - (1 + 1)) = -3 - N.
//
// Note that the encoded value is _not_ related to any possible real token
// position, as two real token positions for different scripts can have the same
// value and thus cannot serve as a unique nonce for a synthetic node.
//
// All other nodes read from user code, such as non-synthetic functions, fields,
// etc., are given real starting token positions. All nodes coming from user
// code, both real or synthetic, with ending token positions have real ending
// token positions.
//
// This organization allows for ~1 billion token positions.

#define SENTINEL_TOKEN_DESCRIPTORS(V)                                          \
  V(NoSource, -1)                                                              \
  V(Box, -2)                                                                   \
  V(ParallelMove, -3)                                                          \
  V(TempMove, -4)                                                              \
  V(Constant, -5)                                                              \
  V(PushArgument, -6)                                                          \
  V(ControlFlow, -7)                                                           \
  V(Context, -8)                                                               \
  V(MethodExtractor, -9)                                                       \
  V(DeferredSlowPath, -10)                                                     \
  V(DeferredDeoptInfo, -11)                                                    \
  V(DartCodePrologue, -12)                                                     \
  V(DartCodeEpilogue, -13)                                                     \
  V(Last, -14)  // Always keep this at the end.

// A token position represents either a debug safe source (real) position,
// non-debug safe unique (synthetic) position, or a classifying value used
// by the profiler.
class TokenPosition {
 public:
  intptr_t Hash() const;

  // Returns whether the token positions are equal.  Defined for all token
  // positions.
  bool operator==(const TokenPosition& b) const { return value() == b.value(); }

  // Returns whether the token positions are not equal. Defined for all token
  // positions.
  bool operator!=(const TokenPosition& b) const { return !(*this == b); }

  // Returns whether the token position is less than [b]. Only defined for
  // real token positions.
  inline bool operator<(const TokenPosition& b) const {
    return Pos() < b.Pos();
  }

  // Returns whether the token position is greater than [b]. Only defined for
  // real token positions.
  inline bool operator>(const TokenPosition& b) const { return b < *this; }

  // Returns whether the token position is less than or equal to [b]. Only
  // defined for real token positions.
  inline bool operator<=(const TokenPosition& b) const { return !(*this > b); }

  // Returns whether the token position is greater than or equal to [b].  Only
  // defined for real token positions.
  inline bool operator>=(const TokenPosition& b) const { return !(*this < b); }

  // For real token positions, returns whether this is between [a] and [b],
  // inclusive. If [a] or [b] is non-real, they are treated as less than
  // any real token position.
  //
  // For synthetic token positions, returns whether [a] or [b] equals this.
  //
  // For other token positions, always returns false.
  bool IsWithin(const TokenPosition& a, const TokenPosition& b) const {
    if (IsReal()) return (a.value() <= value()) && (value() <= b.value());
    if (IsSynthetic()) return (a == *this) || (b == *this);
    return false;
  }

  // Returns [a] if both positions are not real, the real position if only one
  // of [a] and [b] is real, or the minimum position of [a] and [b].
  static const TokenPosition& Min(const TokenPosition& a,
                                  const TokenPosition& b) {
    if (!b.IsReal()) return a;
    if (!a.IsReal()) return b;
    return b.value() < a.value() ? b : a;
  }
  // Returns [a] if both positions are not real, the real position if only one
  // of [a] and [b] is real, or the maximum position of [a] and [b].
  static const TokenPosition& Max(const TokenPosition& a,
                                  const TokenPosition& b) {
    if (!b.IsReal()) return a;
    if (!a.IsReal()) return b;
    return b.value() > a.value() ? b : a;
  }

  // Compares two arbitrary source positions for use in sorting, where a
  // negative return means [a] sorts before [b], a return of 0 means [a] is the
  // same as [b], and a positive return means [a] sorts after [b].
  //
  // Does _not_ correspond to the relational operators on token positions, as
  // this also allows comparison of kNoSource, classifying, and synthetic token
  // positions to each other.
  static intptr_t CompareForSorting(const TokenPosition& a,
                                    const TokenPosition& b) {
    return a.value() - b.value();
  }

  static constexpr int32_t kMaxSentinelDescriptors = 64;

#define DECLARE_VALUES(name, value)                                            \
  static constexpr int32_t k##name##Pos = value;                               \
  static const TokenPosition k##name;
  SENTINEL_TOKEN_DESCRIPTORS(DECLARE_VALUES);
#undef DECLARE_VALUES
  // Check assumptions used in Is<X> methods below.
#define CHECK_VALUES(name, value)                                              \
  static_assert(k##name##Pos < 0, "Non-negative sentinel descriptor");         \
  static_assert(                                                               \
      k##name##Pos == kNoSourcePos || k##name##Pos <= kBoxPos,                 \
      "Box sentinel descriptor is not greatest classifying sentinel value");   \
  static_assert(kLastPos <= k##name##Pos,                                      \
                "Last sentinel descriptor is not least sentinel valu");        \
  SENTINEL_TOKEN_DESCRIPTORS(CHECK_VALUES);
#undef CHECK_VALUES
  static_assert(kLastPos > -kMaxSentinelDescriptors,
                "More sentinel descriptors than expected");

  static constexpr int32_t kMinSourcePos = 0;
  static const TokenPosition kMinSource;
  static constexpr int32_t kMaxSourcePos =
      kSmiMax32 - kMaxSentinelDescriptors - 2;
  static const TokenPosition kMaxSource;

  // Decode from a serialized form.
  static TokenPosition Deserialize(int32_t value);

  // Encode into a serialized form.
  int32_t Serialize() const;

  // Given a real token position, returns the next real token position.
  TokenPosition Next() {
    ASSERT(IsReal());
    return TokenPosition(value_ + 1);
  }

  // Return the source position for real token positions.
  inline intptr_t Pos() const {
    ASSERT(IsReal());
    return value_;
  }

  // Is |this| a classifying sentinel source position?
  // Classifying positions are used by the profiler to group instructions whose
  // cost isn't naturally attributable to a source location.
  inline bool IsClassifying() const {
    return (value_ >= kBox.value()) && (value_ <= kLast.value());
  }

  // Is |this| the no source position sentinel?
  inline bool IsNoSource() const { return value_ == kNoSourcePos; }

  // Is |this| a synthetic source position?
  // Synthetic source positions are used by the profiler to attribute ticks to a
  // pieces of source, but ignored by the debugger as potential breakpoints.
  inline bool IsSynthetic() const { return value_ < kLastPos; }

  // Is |this| a real source position?
  inline bool IsReal() const { return value_ >= kMinSourcePos; }

  // Is |this| a debug pause source position?
  inline bool IsDebugPause() const { return IsReal(); }

  // Creates a synthetic source position from a non-negative value.
  static TokenPosition Synthetic(intptr_t value) {
    ASSERT(value >= 0 && value <= kMaxSourcePos);
    return TokenPosition((kLastPos - 1) - value);
  }

  const char* ToCString() const;

 private:
  explicit TokenPosition(intptr_t value) : value_(value) {}

  // The raw value of this TokenPosition.
  intptr_t value() const { return value_; }

  int32_t value_;

  DISALLOW_ALLOCATION();
};

}  // namespace dart

#endif  // RUNTIME_VM_TOKEN_POSITION_H_
