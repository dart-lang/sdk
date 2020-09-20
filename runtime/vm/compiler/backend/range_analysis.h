// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_RANGE_ANALYSIS_H_
#define RUNTIME_VM_COMPILER_BACKEND_RANGE_ANALYSIS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class SExpression;
class FlowGraphSerializer;

class RangeBoundary : public ValueObject {
 public:
#define FOR_EACH_RANGE_BOUNDARY_KIND(V)                                        \
  V(Unknown)                                                                   \
  V(NegativeInfinity)                                                          \
  V(PositiveInfinity)                                                          \
  V(Symbol)                                                                    \
  V(Constant)

#define KIND_DEFN(name) k##name,
  enum Kind { FOR_EACH_RANGE_BOUNDARY_KIND(KIND_DEFN) };
#undef KIND_DEFN

  static const char* KindToCString(Kind kind);
  static bool ParseKind(const char* str, Kind* out);

  enum RangeSize {
    kRangeBoundarySmi,
    kRangeBoundaryInt32,
    kRangeBoundaryInt64,
  };

  RangeBoundary() : kind_(kUnknown), value_(0), offset_(0) {}

  RangeBoundary(const RangeBoundary& other)
      : ValueObject(),
        kind_(other.kind_),
        value_(other.value_),
        offset_(other.offset_) {}

  explicit RangeBoundary(int64_t val)
      : kind_(kConstant), value_(val), offset_(0) {}

  RangeBoundary& operator=(const RangeBoundary& other) {
    kind_ = other.kind_;
    value_ = other.value_;
    offset_ = other.offset_;
    return *this;
  }

  static const int64_t kMin = kMinInt64;
  static const int64_t kMax = kMaxInt64;

  // Construct a RangeBoundary for a constant value.
  static RangeBoundary FromConstant(int64_t val) { return RangeBoundary(val); }

  // Construct a RangeBoundary for -inf.
  static RangeBoundary NegativeInfinity() {
    return RangeBoundary(kNegativeInfinity, 0, 0);
  }

  // Construct a RangeBoundary for +inf.
  static RangeBoundary PositiveInfinity() {
    return RangeBoundary(kPositiveInfinity, 0, 0);
  }

  // Construct a RangeBoundary from a definition and offset.
  static RangeBoundary FromDefinition(Definition* defn, int64_t offs = 0);

  static bool IsValidOffsetForSymbolicRangeBoundary(int64_t offset) {
    if ((offset > (kMaxInt64 - compiler::target::kSmiMax)) ||
        (offset < (kMinInt64 - compiler::target::kSmiMin))) {
      // Avoid creating symbolic range boundaries which can wrap around.
      return false;
    }
    return true;
  }

  // Construct a RangeBoundary for the constant MinSmi value.
  static RangeBoundary MinSmi() {
    return FromConstant(compiler::target::kSmiMin);
  }

  // Construct a RangeBoundary for the constant MaxSmi value.
  static RangeBoundary MaxSmi() {
    return FromConstant(compiler::target::kSmiMax);
  }

  // Construct a RangeBoundary for the constant kMin value.
  static RangeBoundary MinConstant(RangeSize size) {
    switch (size) {
      case kRangeBoundarySmi:
        return FromConstant(compiler::target::kSmiMin);
      case kRangeBoundaryInt32:
        return FromConstant(kMinInt32);
      case kRangeBoundaryInt64:
        return FromConstant(kMinInt64);
    }
    UNREACHABLE();
    return FromConstant(kMinInt64);
  }

  static RangeBoundary MaxConstant(RangeSize size) {
    switch (size) {
      case kRangeBoundarySmi:
        return FromConstant(compiler::target::kSmiMax);
      case kRangeBoundaryInt32:
        return FromConstant(kMaxInt32);
      case kRangeBoundaryInt64:
        return FromConstant(kMaxInt64);
    }
    UNREACHABLE();
    return FromConstant(kMaxInt64);
  }

  // Given two boundaries a and b, select one of them as c so that
  //
  //   inf {[a, ...) ^ [b, ...)} >= inf {c}
  //
  static RangeBoundary IntersectionMin(RangeBoundary a, RangeBoundary b);

  // Given two boundaries a and b, select one of them as c so that
  //
  //   sup {(..., a] ^ (..., b]} <= sup {c}
  //
  static RangeBoundary IntersectionMax(RangeBoundary a, RangeBoundary b);

  // Given two boundaries a and b compute boundary c such that
  //
  //   inf {[a, ...) U  [b, ...)} >= inf {c}
  //
  // Try to select c such that it is as close to inf {[a, ...) U [b, ...)}
  // as possible.
  static RangeBoundary JoinMin(RangeBoundary a,
                               RangeBoundary b,
                               RangeBoundary::RangeSize size);

  // Given two boundaries a and b compute boundary c such that
  //
  //   sup {(..., a] U (..., b]} <= sup {c}
  //
  // Try to select c such that it is as close to sup {(..., a] U (..., b]}
  // as possible.
  static RangeBoundary JoinMax(RangeBoundary a,
                               RangeBoundary b,
                               RangeBoundary::RangeSize size);

  // Returns true when this is a constant that is outside of Smi range.
  bool OverflowedSmi() const {
    return (IsConstant() && !compiler::target::IsSmi(ConstantValue())) ||
           IsInfinity();
  }

  bool Overflowed(RangeBoundary::RangeSize size) const {
    ASSERT(IsConstantOrInfinity());
    return !Equals(Clamp(size));
  }

  // Returns true if this outside mint range.
  bool OverflowedMint() const { return IsInfinity(); }

  // -/+ infinity are clamped to MinConstant/MaxConstant of the given type.
  RangeBoundary Clamp(RangeSize size) const {
    if (IsNegativeInfinity()) {
      return RangeBoundary::MinConstant(size);
    }

    if (IsPositiveInfinity()) {
      return RangeBoundary::MaxConstant(size);
    }

    if (IsConstant()) {
      const RangeBoundary range_min = RangeBoundary::MinConstant(size);
      const RangeBoundary range_max = RangeBoundary::MaxConstant(size);

      if (ConstantValue() <= range_min.ConstantValue()) {
        return range_min;
      }
      if (ConstantValue() >= range_max.ConstantValue()) {
        return range_max;
      }
    }

    // If this range is a symbolic range, we do not clamp it.
    // This could lead to some imprecision later on.
    return *this;
  }

  bool IsMinimumOrBelow(RangeSize size) const {
    return IsNegativeInfinity() ||
           (IsConstant() && (ConstantValue() <=
                             RangeBoundary::MinConstant(size).ConstantValue()));
  }

  bool IsMaximumOrAbove(RangeSize size) const {
    return IsPositiveInfinity() ||
           (IsConstant() && (ConstantValue() >=
                             RangeBoundary::MaxConstant(size).ConstantValue()));
  }

  intptr_t kind() const { return kind_; }

  // Kind tests.
  bool IsUnknown() const { return kind_ == kUnknown; }
  bool IsConstant() const { return kind_ == kConstant; }
  bool IsSymbol() const { return kind_ == kSymbol; }
  bool IsNegativeInfinity() const { return kind_ == kNegativeInfinity; }
  bool IsPositiveInfinity() const { return kind_ == kPositiveInfinity; }
  bool IsInfinity() const {
    return IsNegativeInfinity() || IsPositiveInfinity();
  }
  bool IsConstantOrInfinity() const { return IsConstant() || IsInfinity(); }

  // Returns the value of a kConstant RangeBoundary.
  int64_t ConstantValue() const;

  // Returns the Definition associated with a kSymbol RangeBoundary.
  Definition* symbol() const {
    ASSERT(IsSymbol());
    return reinterpret_cast<Definition*>(value_);
  }

  // Offset from symbol.
  int64_t offset() const { return offset_; }

  // Computes the LowerBound of this. Three cases:
  // IsInfinity() -> NegativeInfinity().
  // IsConstant() -> value().
  // IsSymbol() -> lower bound computed from definition + offset.
  RangeBoundary LowerBound() const;

  // Computes the UpperBound of this. Three cases:
  // IsInfinity() -> PositiveInfinity().
  // IsConstant() -> value().
  // IsSymbol() -> upper bound computed from definition + offset.
  RangeBoundary UpperBound() const;

  void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString() const;
  SExpression* ToSExpression(FlowGraphSerializer* s);

  static RangeBoundary Add(const RangeBoundary& a,
                           const RangeBoundary& b,
                           const RangeBoundary& overflow);

  static RangeBoundary Sub(const RangeBoundary& a,
                           const RangeBoundary& b,
                           const RangeBoundary& overflow);

  static RangeBoundary Shl(const RangeBoundary& value_boundary,
                           int64_t shift_count,
                           const RangeBoundary& overflow);

  static RangeBoundary Shr(const RangeBoundary& value_boundary,
                           int64_t shift_count) {
    ASSERT(value_boundary.IsConstant());
    ASSERT(shift_count >= 0);
    const int64_t value = static_cast<int64_t>(value_boundary.ConstantValue());
    const int64_t result = (shift_count <= 63)
                               ? (value >> shift_count)
                               : (value >= 0 ? 0 : -1);  // Dart semantics
    return RangeBoundary(result);
  }

  // Attempts to calculate a + b when:
  // a is a symbol and b is a constant OR
  // a is a constant and b is a symbol
  // returns true if it succeeds, output is in result.
  static bool SymbolicAdd(const RangeBoundary& a,
                          const RangeBoundary& b,
                          RangeBoundary* result);

  // Attempts to calculate a - b when:
  // a is a symbol and b is a constant
  // returns true if it succeeds, output is in result.
  static bool SymbolicSub(const RangeBoundary& a,
                          const RangeBoundary& b,
                          RangeBoundary* result);

  bool Equals(const RangeBoundary& other) const;

  int64_t UpperBound(RangeSize size) const {
    return UpperBound().Clamp(size).ConstantValue();
  }

  int64_t LowerBound(RangeSize size) const {
    return LowerBound().Clamp(size).ConstantValue();
  }

  int64_t SmiUpperBound() const { return UpperBound(kRangeBoundarySmi); }

  int64_t SmiLowerBound() const { return LowerBound(kRangeBoundarySmi); }

 private:
  friend class FlowGraphDeserializer;  // For setting fields directly.

  RangeBoundary(Kind kind, int64_t value, int64_t offset)
      : kind_(kind), value_(value), offset_(offset) {}

  Kind kind_;
  int64_t value_;
  int64_t offset_;
};

class Range : public ZoneAllocated {
 public:
  Range() : min_(), max_() {}

  Range(RangeBoundary min, RangeBoundary max) : min_(min), max_(max) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());

    if (min_.IsInfinity() || max_.IsInfinity()) {
      // Value can wrap around, so fall back to the full 64-bit range.
      SetInt64Range();
    }
  }

  Range(const Range& other)
      : ZoneAllocated(), min_(other.min_), max_(other.max_) {}

  Range& operator=(const Range& other) {
    min_ = other.min_;
    max_ = other.max_;
    return *this;
  }

  static bool IsUnknown(const Range* other) {
    if (other == NULL) {
      return true;
    }
    return other->min().IsUnknown();
  }

  static Range Full(RangeBoundary::RangeSize size) {
    return Range(RangeBoundary::MinConstant(size),
                 RangeBoundary::MaxConstant(size));
  }

  void PrintTo(BaseTextBuffer* f) const;
  static const char* ToCString(const Range* range);
  SExpression* ToSExpression(FlowGraphSerializer* s);

  bool Equals(const Range* other) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());
    if (other == NULL) {
      return min_.IsUnknown();
    }
    return min_.Equals(other->min_) && max_.Equals(other->max_);
  }

  const RangeBoundary& min() const { return min_; }
  const RangeBoundary& max() const { return max_; }

  void set_min(const RangeBoundary& value) {
    min_ = value;

    if (min_.IsInfinity()) {
      // Value can wrap around, so fall back to the full 64-bit range.
      SetInt64Range();
    }
  }

  void set_max(const RangeBoundary& value) {
    max_ = value;

    if (max_.IsInfinity()) {
      // Value can wrap around, so fall back to the full 64-bit range.
      SetInt64Range();
    }
  }

  static RangeBoundary ConstantMinSmi(const Range* range) {
    return ConstantMin(range, RangeBoundary::kRangeBoundarySmi);
  }

  static RangeBoundary ConstantMaxSmi(const Range* range) {
    return ConstantMax(range, RangeBoundary::kRangeBoundarySmi);
  }

  static RangeBoundary ConstantMin(const Range* range) {
    return ConstantMin(range, RangeBoundary::kRangeBoundaryInt64);
  }

  static RangeBoundary ConstantMax(const Range* range) {
    return ConstantMax(range, RangeBoundary::kRangeBoundaryInt64);
  }

  static RangeBoundary ConstantMin(const Range* range,
                                   RangeBoundary::RangeSize size) {
    if (range == NULL) {
      return RangeBoundary::MinConstant(size);
    }
    return range->min().LowerBound().Clamp(size);
  }

  static RangeBoundary ConstantMax(const Range* range,
                                   RangeBoundary::RangeSize size) {
    if (range == NULL) {
      return RangeBoundary::MaxConstant(size);
    }
    return range->max().UpperBound().Clamp(size);
  }

  // [0, +inf]
  bool IsPositive() const;

  // [-inf, val].
  bool OnlyLessThanOrEqualTo(int64_t val) const;

  // [val, +inf].
  bool OnlyGreaterThanOrEqualTo(int64_t val) const;

  // Inclusive.
  bool IsWithin(int64_t min_int, int64_t max_int) const;

  // Inclusive.
  bool Overlaps(int64_t min_int, int64_t max_int) const;

  bool IsUnsatisfiable() const;

  bool IsFinite() const { return !min_.IsInfinity() && !max_.IsInfinity(); }

  Range Intersect(const Range* other) const {
    return Range(RangeBoundary::IntersectionMin(min(), other->min()),
                 RangeBoundary::IntersectionMax(max(), other->max()));
  }

  bool Fits(RangeBoundary::RangeSize size) const {
    return !min().LowerBound().Overflowed(size) &&
           !max().UpperBound().Overflowed(size);
  }

  // Clamp this to be within size.
  void Clamp(RangeBoundary::RangeSize size);

  // Clamp this to be within size and eliminate symbols.
  void ClampToConstant(RangeBoundary::RangeSize size);

  static void Add(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max,
                  Definition* left_defn);

  static void Sub(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max,
                  Definition* left_defn);

  static void Mul(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);

  static void TruncDiv(const Range* left_range,
                       const Range* right_range,
                       RangeBoundary* min,
                       RangeBoundary* max);

  static void Mod(const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);

  static void Shr(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);

  static void Shl(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);

  static void And(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);

  static void BitwiseOp(const Range* left_range,
                        const Range* right_range,
                        RangeBoundary* min,
                        RangeBoundary* max);

  // Both the a and b ranges are >= 0.
  static bool OnlyPositiveOrZero(const Range& a, const Range& b);

  // Both the a and b ranges are <= 0.
  static bool OnlyNegativeOrZero(const Range& a, const Range& b);

  // Return the maximum absolute value included in range.
  static int64_t ConstantAbsMax(const Range* range);

  // Return the minimum absolute value included in range.
  static int64_t ConstantAbsMin(const Range* range);

  static void BinaryOp(const Token::Kind op,
                       const Range* left_range,
                       const Range* right_range,
                       Definition* left_defn,
                       Range* result);

 private:
  friend class FlowGraphDeserializer;  // For setting min_/max_ directly.

  RangeBoundary min_;
  RangeBoundary max_;

  void SetInt64Range() {
    min_ = RangeBoundary::MinConstant(RangeBoundary::kRangeBoundaryInt64);
    max_ = RangeBoundary::MaxConstant(RangeBoundary::kRangeBoundaryInt64);
  }
};

class RangeUtils : public AllStatic {
 public:
  static bool Fits(Range* range, RangeBoundary::RangeSize size) {
    return !Range::IsUnknown(range) && range->Fits(size);
  }

  static bool IsWithin(Range* range, int64_t min, int64_t max) {
    return !Range::IsUnknown(range) && range->IsWithin(min, max);
  }

  static bool IsPositive(Range* range) {
    return !Range::IsUnknown(range) && range->IsPositive();
  }

  static bool Overlaps(Range* range, intptr_t min, intptr_t max) {
    return Range::IsUnknown(range) || range->Overlaps(min, max);
  }

  static bool CanBeZero(Range* range) { return Overlaps(range, 0, 0); }

  static bool OnlyLessThanOrEqualTo(Range* range, intptr_t value) {
    return !Range::IsUnknown(range) && range->OnlyLessThanOrEqualTo(value);
  }
};

// Range analysis for integer values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        smi_range_(Range::Full(RangeBoundary::kRangeBoundarySmi)),
        int64_range_(Range::Full(RangeBoundary::kRangeBoundaryInt64)) {}

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

  // Helper that should be used to access ranges of inputs during range
  // inference.
  // Returns meaningful results for uses of non-smi/non-int definitions that
  // have smi/int as a reaching type.
  const Range* GetSmiRange(Value* value) const;
  const Range* GetIntRange(Value* value) const;

  static bool IsIntegerDefinition(Definition* defn) {
    return defn->Type()->IsInt();
  }

  void AssignRangesRecursively(Definition* defn);

 private:
  enum JoinOperator { NONE, WIDEN, NARROW };
  static char OpPrefix(JoinOperator op);

  // Collect all integer values (smi or int), all 64-bit binary
  // and shift operations, and all check bounds.
  void CollectValues();

  // Iterate over smi values and constrain them at branch successors.
  // Additionally constraint values after CheckSmi instructions.
  void InsertConstraints();

  // Iterate over uses of the given definition and discover branches that
  // constrain it. Insert appropriate Constraint instructions at true
  // and false successor and rename all dominated uses to refer to a
  // Constraint instead of this definition.
  void InsertConstraintsFor(Definition* defn);

  // Create a constraint for defn, insert it after given instruction and
  // rename all uses that are dominated by it.
  ConstraintInstr* InsertConstraintFor(Value* use,
                                       Definition* defn,
                                       Range* constraint,
                                       Instruction* after);

  bool ConstrainValueAfterBranch(Value* use, Definition* defn);
  void ConstrainValueAfterCheckBound(Value* use,
                                     CheckBoundBase* check,
                                     Definition* defn);

  // Infer ranges for integer (smi or mint) definitions.
  void InferRanges();

  // Collect integer definition in the reverse postorder.
  void CollectDefinitions(BitVector* set);

  // Recompute ranges of all definitions until they stop changing.
  // Apply the given JoinOperator when computing Phi ranges.
  void Iterate(JoinOperator op, intptr_t max_iterations);
  bool InferRange(JoinOperator op, Definition* defn, intptr_t iteration);

  // Based on computed ranges find and eliminate redundant CheckArrayBound
  // instructions.
  void EliminateRedundantBoundsChecks();

  // Find unsatisfiable constraints and mark corresponding blocks unreachable.
  void MarkUnreachableBlocks();

  // Convert mint operations that stay within int32 range into Int32 operations.
  void NarrowMintToInt32();

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  Range* ConstraintSmiRange(Token::Kind op, Definition* boundary);

  Zone* zone() const { return flow_graph_->zone(); }

  FlowGraph* flow_graph_;

  // Range object representing full Smi range.
  Range smi_range_;

  Range int64_range_;

  // All values that are known to be smi or mint.
  GrowableArray<Definition*> values_;

  // All 64-bit binary and shift operations.
  GrowableArray<BinaryInt64OpInstr*> binary_int64_ops_;
  GrowableArray<ShiftIntegerOpInstr*> shift_int64_ops_;

  // All CheckArrayBound/GenericCheckBound instructions.
  GrowableArray<CheckBoundBase*> bounds_checks_;

  // All Constraints inserted during InsertConstraints phase. They are treated
  // as smi values.
  GrowableArray<ConstraintInstr*> constraints_;

  // List of integer (smi or mint) definitions including constraints sorted
  // in the reverse postorder.
  GrowableArray<Definition*> definitions_;

  DISALLOW_COPY_AND_ASSIGN(RangeAnalysis);
};

// Replaces Mint IL instructions with Uint32 IL instructions
// when possible. Uses output of RangeAnalysis.
class IntegerInstructionSelector : public ValueObject {
 public:
  explicit IntegerInstructionSelector(FlowGraph* flow_graph);

  void Select();

 private:
  bool IsPotentialUint32Definition(Definition* def);
  void FindPotentialUint32Definitions();
  bool IsUint32NarrowingDefinition(Definition* def);
  void FindUint32NarrowingDefinitions();
  bool AllUsesAreUint32Narrowing(Value* list_head);
  bool CanBecomeUint32(Definition* def);
  void Propagate();
  Definition* ConstructReplacementFor(Definition* def);
  void ReplaceInstructions();

  Zone* zone() const { return zone_; }

  GrowableArray<Definition*> potential_uint32_defs_;
  BitVector* selected_uint32_defs_;

  FlowGraph* flow_graph_;
  Zone* zone_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_RANGE_ANALYSIS_H_
