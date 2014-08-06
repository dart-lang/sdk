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

  // Calculate the minimum of a and b within the given range.
  static RangeBoundary Min(RangeBoundary a, RangeBoundary b, RangeSize size);
  static RangeBoundary Max(RangeBoundary a, RangeBoundary b, RangeSize size);

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

 private:
  RangeBoundary(Kind kind, int64_t value, int64_t offset)
      : kind_(kind), value_(value), offset_(offset) { }

  Kind kind_;
  int64_t value_;
  int64_t offset_;
};


class Range : public ZoneAllocated {
 public:
  Range(RangeBoundary min, RangeBoundary max) : min_(min), max_(max) { }

  static Range* Unknown() {
    return new Range(RangeBoundary::MinConstant(),
                     RangeBoundary::MaxConstant());
  }

  static Range* UnknownSmi() {
    return new Range(RangeBoundary::MinSmi(),
                     RangeBoundary::MaxSmi());
  }

  void PrintTo(BufferFormatter* f) const;
  static const char* ToCString(const Range* range);

  const RangeBoundary& min() const { return min_; }
  const RangeBoundary& max() const { return max_; }

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

  static Range* BinaryOp(const Token::Kind op,
                         const Range* left_range,
                         const Range* right_range,
                         Definition* left_defn);

 private:
  RangeBoundary min_;
  RangeBoundary max_;
};


// Range analysis for integer values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        marked_defns_(NULL) { }

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

 private:
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


  // Walk the dominator tree and infer ranges for smi values.
  void InferRanges();
  void InferRangesRecursive(BlockEntryInstr* block);

  enum Direction {
    kUnknown,
    kPositive,
    kNegative,
    kBoth
  };

  Range* InferInductionVariableRange(JoinEntryInstr* loop_header,
                                     PhiInstr* var);

  void ResetWorklist();
  void MarkDefinition(Definition* defn);

  static Direction ToDirection(Value* val);

  static Direction Invert(Direction direction) {
    return (direction == kPositive) ? kNegative : kPositive;
  }

  static void UpdateDirection(Direction* direction,
                              Direction new_direction) {
    if (*direction != new_direction) {
      if (*direction != kUnknown) new_direction = kBoth;
      *direction = new_direction;
    }
  }

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  Range* ConstraintRange(Token::Kind op, Definition* boundary);

  Isolate* isolate() const { return flow_graph_->isolate(); }

  FlowGraph* flow_graph_;

  // Value that are known to be smi or mint.
  GrowableArray<Definition*> values_;
  // All CheckSmi instructions.
  GrowableArray<CheckSmiInstr*> smi_checks_;

  // All Constraints inserted during InsertConstraints phase. They are treated
  // as smi values.
  GrowableArray<ConstraintInstr*> constraints_;

  // Bitvector for a quick filtering of known smi or mint values.
  BitVector* definitions_;

  // Worklist for induction variables analysis.
  GrowableArray<Definition*> worklist_;
  BitVector* marked_defns_;

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
