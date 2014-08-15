// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_RANGE_ANALYSIS_H_
#define VM_FLOW_GRAPH_RANGE_ANALYSIS_H_

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

class RangeBoundary : public ValueObject {
 public:
  enum Kind {
    kUnknown,
    kNegativeInfinity,
    kPositiveInfinity,
    kSymbol,
    kConstant,
  };

  enum RangeSize {
    kRangeBoundarySmi,
    kRangeBoundaryInt64,
  };

  RangeBoundary() : kind_(kUnknown), value_(0), offset_(0) { }

  RangeBoundary(const RangeBoundary& other)
      : ValueObject(),
        kind_(other.kind_),
        value_(other.value_),
        offset_(other.offset_) { }

  explicit RangeBoundary(int64_t val)
      : kind_(kConstant), value_(val), offset_(0) { }

  RangeBoundary& operator=(const RangeBoundary& other) {
    kind_ = other.kind_;
    value_ = other.value_;
    offset_ = other.offset_;
    return *this;
  }

  static const int64_t kMin = kMinInt64;
  static const int64_t kMax = kMaxInt64;

  // Construct a RangeBoundary for a constant value.
  static RangeBoundary FromConstant(int64_t val) {
    return RangeBoundary(val);
  }

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

  // Construct a RangeBoundary for the constant MinSmi value.
  static RangeBoundary MinSmi() {
    return FromConstant(Smi::kMinValue);
  }

  // Construct a RangeBoundary for the constant MaxSmi value.
  static RangeBoundary MaxSmi() {
    return FromConstant(Smi::kMaxValue);
  }

    // Construct a RangeBoundary for the constant kMin value.
  static RangeBoundary MinConstant() {
    return FromConstant(kMin);
  }

  // Construct a RangeBoundary for the constant kMax value.
  static RangeBoundary MaxConstant() {
    return FromConstant(kMax);
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
  static RangeBoundary JoinMin(RangeBoundary a, RangeBoundary b);

  // Given two boundaries a and b compute boundary c such that
  //
  //   sup {(..., a] U (..., b]} <= sup {c}
  //
  // Try to select c such that it is as close to sup {(..., a] U (..., b]}
  // as possible.
  static RangeBoundary JoinMax(RangeBoundary a, RangeBoundary b);

  // Returns true when this is a constant that is outside of Smi range.
  bool OverflowedSmi() const {
    return (IsConstant() && !Smi::IsValid(ConstantValue())) || IsInfinity();
  }

  // Returns true if this outside mint range.
  bool OverflowedMint() const {
    return IsInfinity();
  }

  // -/+ infinity are clamped to MinConstant/MaxConstant of the given type.
  RangeBoundary Clamp(RangeSize size) const {
    if (IsNegativeInfinity()) {
      return (size == kRangeBoundaryInt64) ? MinConstant() : MinSmi();
    }
    if (IsPositiveInfinity()) {
      return (size == kRangeBoundaryInt64) ? MaxConstant() : MaxSmi();
    }
    if ((size == kRangeBoundarySmi) && IsConstant()) {
      if (ConstantValue() <= Smi::kMinValue) {
        return MinSmi();
      }
      if (ConstantValue() >= Smi::kMaxValue) {
        return MaxSmi();
      }
    }
    // If this range is a symbolic range, we do not clamp it.
    // This could lead to some imprecision later on.
    return *this;
  }

  bool IsSmiMinimumOrBelow() const {
    return IsNegativeInfinity() ||
           (IsConstant() && (ConstantValue() <= Smi::kMinValue));
  }

  bool IsSmiMaximumOrAbove() const {
    return IsPositiveInfinity() ||
           (IsConstant() && (ConstantValue() >= Smi::kMaxValue));
  }

  bool IsMinimumOrBelow() const {
    return IsNegativeInfinity() || (IsConstant() && (ConstantValue() == kMin));
  }

  bool IsMaximumOrAbove() const {
    return IsPositiveInfinity() || (IsConstant() && (ConstantValue() == kMax));
  }

  intptr_t kind() const {
    return kind_;
  }

  // Kind tests.
  bool IsUnknown() const { return kind_ == kUnknown; }
  bool IsConstant() const { return kind_ == kConstant; }
  bool IsSymbol() const { return kind_ == kSymbol; }
  bool IsNegativeInfinity() const { return kind_ == kNegativeInfinity; }
  bool IsPositiveInfinity() const { return kind_ == kPositiveInfinity; }
  bool IsInfinity() const {
    return IsNegativeInfinity() || IsPositiveInfinity();
  }
  bool IsConstantOrInfinity() const {
    return IsConstant() || IsInfinity();
  }

  // Returns the value of a kConstant RangeBoundary.
  int64_t ConstantValue() const;

  // Returns the Definition associated with a kSymbol RangeBoundary.
  Definition* symbol() const {
    ASSERT(IsSymbol());
    return reinterpret_cast<Definition*>(value_);
  }

  // Offset from symbol.
  int64_t offset() const {
    return offset_;
  }

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

  void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

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
    int64_t value = static_cast<int64_t>(value_boundary.ConstantValue());
    int64_t result = value >> shift_count;
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

  int64_t SmiUpperBound() const {
    return UpperBound().Clamp(kRangeBoundarySmi).ConstantValue();
  }

  int64_t SmiLowerBound() const {
    return LowerBound().Clamp(kRangeBoundarySmi).ConstantValue();
  }

 private:
  RangeBoundary(Kind kind, int64_t value, int64_t offset)
      : kind_(kind), value_(value), offset_(offset) { }

  Kind kind_;
  int64_t value_;
  int64_t offset_;
};


class Range : public ZoneAllocated {
 public:
  Range() : min_(), max_() { }
  Range(RangeBoundary min, RangeBoundary max) : min_(min), max_(max) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());
  }

  Range(const Range& other)
      : ZoneAllocated(),
        min_(other.min_),
        max_(other.max_) {
  }

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
    if (size == RangeBoundary::kRangeBoundarySmi) {
      return Range(RangeBoundary::MinSmi(), RangeBoundary::MaxSmi());
    } else {
      ASSERT(size == RangeBoundary::kRangeBoundaryInt64);
      return Range(RangeBoundary::MinConstant(), RangeBoundary::MaxConstant());
    }
  }

  void PrintTo(BufferFormatter* f) const;
  static const char* ToCString(const Range* range);

  bool Equals(const Range* other) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());
    if (other == NULL) {
      return min_.IsUnknown();
    }
    return min_.Equals(other->min_) &&
        max_.Equals(other->max_);
  }

  const RangeBoundary& min() const { return min_; }
  const RangeBoundary& max() const { return max_; }
  void set_min(const RangeBoundary& value) {
    min_ = value;
  }
  void set_max(const RangeBoundary& value) {
    max_ = value;
  }

  static RangeBoundary ConstantMinSmi(const Range* range) {
    if (range == NULL) {
      return RangeBoundary::MinSmi();
    }
    return range->min().LowerBound().Clamp(RangeBoundary::kRangeBoundarySmi);
  }

  static RangeBoundary ConstantMaxSmi(const Range* range) {
    if (range == NULL) {
      return RangeBoundary::MaxSmi();
    }
    return range->max().UpperBound().Clamp(RangeBoundary::kRangeBoundarySmi);
  }

  static RangeBoundary ConstantMin(const Range* range) {
    if (range == NULL) {
      return RangeBoundary::MinConstant();
    }
    return range->min().LowerBound().Clamp(RangeBoundary::kRangeBoundaryInt64);
  }

  static RangeBoundary ConstantMax(const Range* range) {
    if (range == NULL) {
      return RangeBoundary::MaxConstant();
    }
    return range->max().UpperBound().Clamp(RangeBoundary::kRangeBoundaryInt64);
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

  bool IsFinite() const {
    return !min_.IsInfinity() && !max_.IsInfinity();
  }

  Range Intersect(const Range* other) const {
    return Range(RangeBoundary::IntersectionMin(min(), other->min()),
                 RangeBoundary::IntersectionMax(max(), other->max()));
  }

  // Clamp this to be within size.
  void Clamp(RangeBoundary::RangeSize size);

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

  static bool Mul(const Range* left_range,
                  const Range* right_range,
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

  static bool And(const Range* left_range,
                  const Range* right_range,
                  RangeBoundary* min,
                  RangeBoundary* max);


  // Both the a and b ranges are >= 0.
  static bool OnlyPositiveOrZero(const Range& a, const Range& b);

  // Both the a and b ranges are <= 0.
  static bool OnlyNegativeOrZero(const Range& a, const Range& b);

  // Return the maximum absolute value included in range.
  static int64_t ConstantAbsMax(const Range* range);

  static void BinaryOp(const Token::Kind op,
                       const Range* left_range,
                       const Range* right_range,
                       Definition* left_defn,
                       Range* result);

 private:
  RangeBoundary min_;
  RangeBoundary max_;
};


// Range analysis for integer values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph) { }

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

 private:
  enum JoinOperator {
    NONE,
    WIDEN,
    NARROW
  };
  static char OpPrefix(JoinOperator op);

  // Collect all values that were proven to be smi in smi_values_ array and all
  // CheckSmi instructions in smi_check_ array.
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
  ConstraintInstr* InsertConstraintFor(Definition* defn,
                                       Range* constraint,
                                       Instruction* after);

  void ConstrainValueAfterBranch(Definition* defn, Value* use);
  void ConstrainValueAfterCheckArrayBound(Definition* defn,
                                          CheckArrayBoundInstr* check,
                                          intptr_t use_index);

  // Replace uses of the definition def that are dominated by instruction dom
  // with uses of other definition.
  void RenameDominatedUses(Definition* def,
                           Instruction* dom,
                           Definition* other);


  // Infer ranges for integer (smi or mint) definitions.
  void InferRanges();

  // Collect integer definition in the reverse postorder.
  void CollectDefinitions(BlockEntryInstr* block, BitVector* set);

  // Recompute ranges of all definitions until they stop changing.
  // Apply the given JoinOperator when computing Phi ranges.
  void Iterate(JoinOperator op, intptr_t max_iterations);
  bool InferRange(JoinOperator op, Definition* defn, intptr_t iteration);

  // Based on computed ranges find and eliminate redundant CheckArrayBound
  // instructions.
  void EliminateRedundantBoundsChecks();

  // Find unsatisfiable constraints and mark corresponding blocks unreachable.
  void MarkUnreachableBlocks();

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  Range* ConstraintSmiRange(Token::Kind op, Definition* boundary);

  Isolate* isolate() const { return flow_graph_->isolate(); }

  FlowGraph* flow_graph_;

  // Value that are known to be smi or mint.
  GrowableArray<Definition*> values_;

  // All CheckSmi instructions.
  GrowableArray<CheckSmiInstr*> smi_checks_;

  // All CheckArrayBound instructions.
  GrowableArray<CheckArrayBoundInstr*> bounds_checks_;

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

  Isolate* isolate() const { return isolate_; }

  GrowableArray<Definition*> potential_uint32_defs_;
  BitVector* selected_uint32_defs_;

  FlowGraph* flow_graph_;
  Isolate* isolate_;
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_RANGE_ANALYSIS_H_
