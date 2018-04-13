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
// Synthetically created AstNodes are given real source positions but encoded
// as negative numbers from [kSmiMin32, -1 - N]. For example:
//
// A source position of 0 in a synthetic AstNode would be encoded as -2 - N.
// A source position of 1 in a synthetic AstNode would be encoded as -3 - N.
//
// All other AstNodes are given real source positions encoded as positive
// integers.
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

// A token position representing a debug safe source (real) position,
// non-debug safe source (synthetic) positions, or a classifying value used
// by the profiler.
class TokenPosition {
 public:
  TokenPosition() : value_(kNoSource.value()) {}

  explicit TokenPosition(intptr_t value) : value_(value) {}

  bool operator==(const TokenPosition& b) const { return value() == b.value(); }

  bool operator!=(const TokenPosition& b) const { return !(*this == b); }

  bool operator<(const TokenPosition& b) const {
    // TODO(johnmccutchan): Assert that this is a source position.
    return value() < b.value();
  }

  bool operator>(const TokenPosition& b) const {
    // TODO(johnmccutchan): Assert that this is a source position.
    return b < *this;
  }

  bool operator<=(const TokenPosition& b) {
    // TODO(johnmccutchan): Assert that this is a source position.
    return !(*this > b);
  }

  bool operator>=(const TokenPosition& b) {
    // TODO(johnmccutchan): Assert that this is a source position.
    return !(*this < b);
  }

  static const intptr_t kMaxSentinelDescriptors = 64;

#define DECLARE_VALUES(name, value)                                            \
  static const intptr_t k##name##Pos = value;                                  \
  static const TokenPosition k##name;
  SENTINEL_TOKEN_DESCRIPTORS(DECLARE_VALUES);
#undef DECLARE_VALUES
  static const intptr_t kMinSourcePos = 0;
  static const TokenPosition kMinSource;
  static const intptr_t kMaxSourcePos = kSmiMax32 - kMaxSentinelDescriptors - 2;
  static const TokenPosition kMaxSource;

  // Decode from a snapshot.
  static TokenPosition SnapshotDecode(int32_t value);

  // Encode for writing into a snapshot.
  int32_t SnapshotEncode();

  // Increment the token position.
  TokenPosition Next() {
    ASSERT(IsReal());
    value_++;
    return *this;
  }

  // The raw value.
  // TODO(johnmccutchan): Make this private.
  intptr_t value() const { return value_; }

  // Return the source position.
  intptr_t Pos() const {
    if (IsSynthetic()) {
      return FromSynthetic().Pos();
    }
    return value_;
  }

  // Is |this| a classifying sentinel source position?
  // Classifying positions are used by the profiler to group instructions whose
  // cost isn't naturally attributable to a source location.
  bool IsClassifying() const {
    return (value_ >= kBox.value()) && (value_ <= kLast.value());
  }

  // Is |this| the no source position sentinel?
  bool IsNoSource() const { return *this == kNoSource; }

  // Is |this| a synthetic source position?
  // Synthetic source positions are used by the profiler to attribute ticks to a
  // pieces of source, but ignored by the debugger as potential breakpoints.
  bool IsSynthetic() const;

  // Is |this| a real source position?
  bool IsReal() const { return value_ >= kMinSourcePos; }

  // Is |this| a source position?
  bool IsSourcePosition() const { return IsReal() || IsSynthetic(); }

  // Convert |this| into a real source position. Sentinel values remain
  // unchanged.
  TokenPosition SourcePosition() const { return FromSynthetic(); }

  // Is |this| a debug pause source position?
  bool IsDebugPause() const {
    // Sanity check some values here.
    ASSERT(kNoSource.value() == kNoSourcePos);
    ASSERT(kLast.value() < kNoSource.value());
    ASSERT(kLast.value() > -kMaxSentinelDescriptors);
    return IsReal();
  }

  // Convert |this| into a synthetic source position. Sentinel values remain
  // unchanged.
  TokenPosition ToSynthetic() const {
    const intptr_t value = value_;
    if (IsClassifying() || IsNoSource()) {
      return *this;
    }
    if (IsSynthetic()) {
      return *this;
    }
    const TokenPosition synthetic_value =
        TokenPosition((kLast.value() - 1) - value);
    ASSERT(synthetic_value.IsSynthetic());
    ASSERT(synthetic_value.value() < kLast.value());
    return synthetic_value;
  }

  // Convert |this| from a synthetic source position. Sentinel values remain
  // unchanged.
  TokenPosition FromSynthetic() const {
    const intptr_t synthetic_value = value_;
    if (IsClassifying() || IsNoSource()) {
      return *this;
    }
    if (!IsSynthetic()) {
      return *this;
    }
    const TokenPosition value =
        TokenPosition(-synthetic_value + (kLast.value() - 1));
    ASSERT(!value.IsSynthetic());
    return value;
  }

  const char* ToCString() const;

 private:
  int32_t value_;

  DISALLOW_ALLOCATION();
};

}  // namespace dart

#endif  // RUNTIME_VM_TOKEN_POSITION_H_
