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

// How to interpret values with kTagged representation.
enum class TaggedMode {
  kTaggedNotAllowed,
  kTaggedIsSmi,
};

class RangeBoundary : public ValueObject {
 public:
#define FOR_EACH_RANGE_BOUNDARY_KIND(V)                                        \
  V(Unknown)                                                                   \
  V(Symbol)                                                                    \
  V(Constant)

#define KIND_DEFN(name) k##name,
  enum Kind { FOR_EACH_RANGE_BOUNDARY_KIND(KIND_DEFN) };
#undef KIND_DEFN

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

  // Construct a RangeBoundary for a constant value.
  static RangeBoundary FromConstant(int64_t val) { return RangeBoundary(val); }

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

  static RangeBoundary MinInt64() { return FromConstant(kMinInt64); }

  static RangeBoundary MaxInt64() { return FromConstant(kMaxInt64); }

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
                               const Range& full_range);

  // Given two boundaries a and b compute boundary c such that
  //
  //   sup {(..., a] U (..., b]} <= sup {c}
  //
  // Try to select c such that it is as close to sup {(..., a] U (..., b]}
  // as possible.
  static RangeBoundary JoinMax(RangeBoundary a,
                               RangeBoundary b,
                               const Range& full_range);

  // Returns true when this is a constant that is outside of Smi range.
  bool OverflowedSmi() const {
    return IsConstant() && !compiler::target::IsSmi(ConstantValue());
  }

  bool Overflowed(const Range& full_range) const {
    ASSERT(IsConstant());
    return !Equals(Clamp(full_range));
  }

  // Clamp constant boundary to the given [full_range].
  RangeBoundary Clamp(const Range& full_range) const;

  bool IsLessOrEqual(const RangeBoundary& other) const {
    ASSERT(other.IsConstant());
    return IsConstant() && (ConstantValue() <= other.ConstantValue());
  }

  bool IsGreaterOrEqual(const RangeBoundary& other) const {
    ASSERT(other.IsConstant());
    return IsConstant() && (ConstantValue() >= other.ConstantValue());
  }

  intptr_t kind() const { return kind_; }

  // Kind tests.
  bool IsUnknown() const { return kind_ == kUnknown; }
  bool IsConstant() const { return kind_ == kConstant; }
  bool IsSymbol() const { return kind_ == kSymbol; }

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
  // IsConstant() -> value().
  // IsSymbol() -> lower bound computed from definition + offset.
  RangeBoundary LowerBound() const;

  // Computes the UpperBound of this. Three cases:
  // IsConstant() -> value().
  // IsSymbol() -> upper bound computed from definition + offset.
  RangeBoundary UpperBound() const;

  void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString() const;

  static bool WillAddOverflow(const RangeBoundary& a, const RangeBoundary& b);

  static RangeBoundary Add(const RangeBoundary& a, const RangeBoundary& b);

  static bool WillSubOverflow(const RangeBoundary& a, const RangeBoundary& b);

  static RangeBoundary Sub(const RangeBoundary& a, const RangeBoundary& b);

  static bool WillShlOverflow(const RangeBoundary& a, int64_t shift_count);

  static RangeBoundary Shl(const RangeBoundary& value_boundary,
                           int64_t shift_count);

  static RangeBoundary Shr(const RangeBoundary& value_boundary,
                           int64_t shift_count);

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

  int64_t UpperBound(const Range& full_range) const {
    return UpperBound().Clamp(full_range).ConstantValue();
  }

  int64_t LowerBound(const Range& full_range) const {
    return LowerBound().Clamp(full_range).ConstantValue();
  }

  void Write(FlowGraphSerializer* s) const;
  explicit RangeBoundary(FlowGraphDeserializer* d);

 private:
  RangeBoundary(Kind kind, int64_t value, int64_t offset)
      : kind_(kind), value_(value), offset_(offset) {}

  Kind kind_;
  int64_t value_;
  int64_t offset_;
};

class Range : public ZoneObject {
 public:
  Range() : min_(), max_() {}

  Range(RangeBoundary min, RangeBoundary max) : min_(min), max_(max) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());
  }

  Range(const Range& other)
      : ZoneObject(), min_(other.min_), max_(other.max_) {}

  Range& operator=(const Range& other) {
    min_ = other.min_;
    max_ = other.max_;
    return *this;
  }

  static bool IsUnknown(const Range* other) {
    if (other == nullptr) {
      return true;
    }
    return other->min().IsUnknown();
  }

  static Range Smi() {
    return Range(RangeBoundary::MinSmi(), RangeBoundary::MaxSmi());
  }

  static Range Int64() {
    return Range(RangeBoundary::MinInt64(), RangeBoundary::MaxInt64());
  }

  static Range Full(Representation rep,
                    TaggedMode tagged_mode = TaggedMode::kTaggedNotAllowed);

  void PrintTo(BaseTextBuffer* f) const;
  static const char* ToCString(const Range* range);

  bool Equals(const Range* other) {
    ASSERT(min_.IsUnknown() == max_.IsUnknown());
    if (other == nullptr) {
      return min_.IsUnknown();
    }
    return min_.Equals(other->min_) && max_.Equals(other->max_);
  }

  const RangeBoundary& min() const { return min_; }
  const RangeBoundary& max() const { return max_; }

  void set_min(const RangeBoundary& value) { min_ = value; }

  void set_max(const RangeBoundary& value) { max_ = value; }

  static RangeBoundary ConstantMinSmi(const Range* range) {
    return ConstantMin(range, Range::Smi());
  }

  static RangeBoundary ConstantMaxSmi(const Range* range) {
    return ConstantMax(range, Range::Smi());
  }

  static RangeBoundary ConstantMin(const Range* range) {
    return ConstantMin(range, Range::Int64());
  }

  static RangeBoundary ConstantMax(const Range* range) {
    return ConstantMax(range, Range::Int64());
  }

  static RangeBoundary ConstantMin(const Range* range,
                                   const Range& full_range) {
    if (range == nullptr) {
      return full_range.min();
    }
    return range->min().LowerBound().Clamp(full_range);
  }

  static RangeBoundary ConstantMax(const Range* range,
                                   const Range& full_range) {
    if (range == nullptr) {
      return full_range.max();
    }
    return range->max().UpperBound().Clamp(full_range);
  }

  // [0, +inf]
  bool IsPositive() const;

  // [-inf, -1]
  bool IsNegative() const;

  // [-inf, val].
  bool OnlyLessThanOrEqualTo(int64_t val) const;

  // [val, +inf].
  bool OnlyGreaterThanOrEqualTo(int64_t val) const;

  // Inclusive.
  bool IsWithin(int64_t min_int, int64_t max_int) const;

  // Inclusive.
  bool IsWithin(const Range* other) const;

  // Inclusive.
  bool Overlaps(int64_t min_int, int64_t max_int) const;

  bool IsUnsatisfiable() const;

  bool IsSingleton() const {
    return min_.IsConstant() && max_.IsConstant() &&
           min_.ConstantValue() == max_.ConstantValue();
  }

  int64_t Singleton() const {
    ASSERT(IsSingleton());
    return min_.ConstantValue();
  }

  Range Intersect(const Range* other) const {
    return Range(RangeBoundary::IntersectionMin(min(), other->min()),
                 RangeBoundary::IntersectionMax(max(), other->max()));
  }

  // Returns true if this range fits without truncation into
  // the given representation.
  static bool Fits(Range* range,
                   Representation rep,
                   TaggedMode tagged_mode = TaggedMode::kTaggedNotAllowed) {
    if (range == nullptr) return false;
    const Range& other = Range::Full(rep, tagged_mode);
    return range->IsWithin(&other);
  }

  // Clamp this to be within size.
  void Clamp(const Range& full_range);

  // Clamp this to be within size and eliminate symbols.
  void ClampToConstant(const Range& full_range);

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

  static void Ushr(const Range* left_range,
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

  void Write(FlowGraphSerializer* s) const;
  explicit Range(FlowGraphDeserializer* d);

 private:
  RangeBoundary min_;
  RangeBoundary max_;
};

class RangeUtils : public AllStatic {
 public:
  static bool IsWithin(const Range* range, int64_t min, int64_t max) {
    return !Range::IsUnknown(range) && range->IsWithin(min, max);
  }

  static bool IsWithin(const Range* range, const Range* other) {
    return !Range::IsUnknown(range) && range->IsWithin(other);
  }

  static bool IsPositive(Range* range) {
    return !Range::IsUnknown(range) && range->IsPositive();
  }
  static bool IsNegative(Range* range) {
    return !Range::IsUnknown(range) && range->IsNegative();
  }

  static bool Overlaps(Range* range, intptr_t min, intptr_t max) {
    return Range::IsUnknown(range) || range->Overlaps(min, max);
  }

  static bool CanBeZero(Range* range) { return Overlaps(range, 0, 0); }

  static bool OnlyLessThanOrEqualTo(Range* range, intptr_t value) {
    return !Range::IsUnknown(range) && range->OnlyLessThanOrEqualTo(value);
  }

  static bool IsSingleton(Range* range) {
    return !Range::IsUnknown(range) && range->IsSingleton();
  }
};

// Range analysis for integer values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph), smi_range_(Range::Smi()) {}

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

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
                                     CheckBoundBaseInstr* check,
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

  // Convert Int64 operations that stay within Int32 range into Int32
  // operations.
  void NarrowInt64OperationsToInt32();

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  Range* ConstraintRange(Token::Kind op,
                         Definition* boundary,
                         const Range& full_range);

  Zone* zone() const { return flow_graph_->zone(); }

  const Range& smi_range() const { return smi_range_; }

  FlowGraph* flow_graph_;

  Range smi_range_;

  // All values that are known to be smi or mint.
  GrowableArray<Definition*> values_;

  // All 64-bit binary operations.
  GrowableArray<BinaryInt64OpInstr*> binary_int64_ops_;
  GrowableArray<ComparisonInstr*> int64_comparisons_;

  // All CheckArrayBound/GenericCheckBound instructions.
  GrowableArray<CheckBoundBaseInstr*> bounds_checks_;

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
  bool IsUint32Use(Value* use);
  void NarrowUint32Uses();
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
