// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_H_

#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/token_position.h"

namespace dart {

class BitVector;
class BlockEntryInstr;
class BoxIntegerInstr;
class BufferFormatter;
class CallTargets;
class CatchBlockEntryInstr;
class ComparisonInstr;
class Definition;
class Environment;
class FlowGraph;
class FlowGraphBuilder;
class FlowGraphCompiler;
class FlowGraphVisitor;
class Instruction;
class LocalVariable;
class ParsedFunction;
class Range;
class RangeAnalysis;
class RangeBoundary;
class UnboxIntegerInstr;

// CompileType describes type of the value produced by the definition.
//
// It captures the following properties:
//    - whether value can potentially be null or it is definitely not null;
//    - concrete class id of the value or kDynamicCid if unknown statically;
//    - abstract super type of the value, concrete type of the value in runtime
//      is guaranteed to be sub type of this type.
//
// Values of CompileType form a lattice with a None type as a bottom and a
// nullable Dynamic type as a top element. Method Union provides a join
// operation for the lattice.
class CompileType : public ZoneAllocated {
 public:
  static const bool kNullable = true;
  static const bool kNonNullable = false;

  CompileType(bool is_nullable, intptr_t cid, const AbstractType* type)
      : is_nullable_(is_nullable), cid_(cid), type_(type) {}

  CompileType(const CompileType& other)
      : ZoneAllocated(),
        is_nullable_(other.is_nullable_),
        cid_(other.cid_),
        type_(other.type_) {}

  CompileType& operator=(const CompileType& other) {
    is_nullable_ = other.is_nullable_;
    cid_ = other.cid_;
    type_ = other.type_;
    return *this;
  }

  bool is_nullable() const { return is_nullable_; }

  // Return type such that concrete value's type in runtime is guaranteed to
  // be subtype of it.
  const AbstractType* ToAbstractType();

  // Return class id such that it is either kDynamicCid or in runtime
  // value is guaranteed to have an equal class id.
  intptr_t ToCid();

  // Return class id such that it is either kDynamicCid or in runtime
  // value is guaranteed to be either null or have an equal class id.
  intptr_t ToNullableCid();

  // Returns true if the value is guaranteed to be not-null or is known to be
  // always null.
  bool HasDecidableNullability();

  // Returns true if the value is known to be always null.
  bool IsNull();

  // Returns true if this type is more specific than given type.
  bool IsMoreSpecificThan(const AbstractType& other);

  // Returns true if value of this type is assignable to a location of the
  // given type.
  bool IsAssignableTo(const AbstractType& type) {
    bool is_instance;
    return CanComputeIsInstanceOf(type, kNullable, &is_instance) && is_instance;
  }

  // Create a new CompileType representing given combination of class id and
  // abstract type. The pair is assumed to be coherent.
  static CompileType Create(intptr_t cid, const AbstractType& type);

  CompileType CopyNonNullable() const {
    return CompileType(kNonNullable, kIllegalCid, type_);
  }

  static CompileType CreateNullable(bool is_nullable, intptr_t cid) {
    return CompileType(is_nullable, cid, NULL);
  }

  // Create a new CompileType representing given abstract type. By default
  // values as assumed to be nullable.
  static CompileType FromAbstractType(const AbstractType& type,
                                      bool is_nullable = kNullable);

  // Create a new CompileType representing a value with the given class id.
  // Resulting CompileType is nullable only if cid is kDynamicCid or kNullCid.
  static CompileType FromCid(intptr_t cid);

  // Create None CompileType. It is the bottom of the lattice and is used to
  // represent type of the phi that was not yet inferred.
  static CompileType None() {
    return CompileType(kNullable, kIllegalCid, NULL);
  }

  // Create Dynamic CompileType. It is the top of the lattice and is used to
  // represent unknown type.
  static CompileType Dynamic();

  static CompileType Null();

  // Create non-nullable Bool type.
  static CompileType Bool();

  // Create non-nullable Int type.
  static CompileType Int();

  // Create non-nullable Smi type.
  static CompileType Smi();

  // Create non-nullable Double type.
  static CompileType Double();

  // Create non-nullable String type.
  static CompileType String();

  // Perform a join operation over the type lattice.
  void Union(CompileType* other);

  // Refine old type with newly inferred type (it could be more or less
  // specific, or even unrelated to an old type in case of unreachable code).
  // May return 'old_type', 'new_type' or create a new CompileType instance.
  static CompileType* ComputeRefinedType(CompileType* old_type,
                                         CompileType* new_type);

  // Returns true if this and other types are the same.
  bool IsEqualTo(CompileType* other) {
    return (is_nullable_ == other->is_nullable_) &&
           (ToNullableCid() == other->ToNullableCid()) &&
           (ToAbstractType()->Equals(*other->ToAbstractType()));
  }

  bool IsNone() const { return (cid_ == kIllegalCid) && (type_ == NULL); }

  bool IsInt() {
    return !is_nullable() &&
           ((ToCid() == kSmiCid) || (ToCid() == kMintCid) ||
            ((type_ != NULL) &&
             (type_->Equals(Type::Handle(Type::Int64Type())))));
  }

  // Returns true if value of this type is either int or null.
  bool IsNullableInt() {
    if ((cid_ == kSmiCid) || (cid_ == kMintCid) || (cid_ == kBigintCid)) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return (type_ != NULL) && ((type_->IsIntType() || type_->IsInt64Type() ||
                                  type_->IsSmiType()));
    }
    return false;
  }

  // Returns true if value of this type is either double or null.
  bool IsNullableDouble() {
    if (cid_ == kDoubleCid) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return (type_ != NULL) && type_->IsDoubleType();
    }
    return false;
  }

  void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

 private:
  bool CanComputeIsInstanceOf(const AbstractType& type,
                              bool is_nullable,
                              bool* is_instance);

  bool is_nullable_;
  intptr_t cid_;
  const AbstractType* type_;
};

class Value : public ZoneAllocated {
 public:
  // A forward iterator that allows removing the current value from the
  // underlying use list during iteration.
  class Iterator {
   public:
    explicit Iterator(Value* head) : next_(head) { Advance(); }
    Value* Current() const { return current_; }
    bool Done() const { return current_ == NULL; }
    void Advance() {
      // Pre-fetch next on advance and cache it.
      current_ = next_;
      if (next_ != NULL) next_ = next_->next_use();
    }

   private:
    Value* current_;
    Value* next_;
  };

  explicit Value(Definition* definition)
      : definition_(definition),
        previous_use_(NULL),
        next_use_(NULL),
        instruction_(NULL),
        use_index_(-1),
        reaching_type_(NULL) {}

  Definition* definition() const { return definition_; }
  void set_definition(Definition* definition) { definition_ = definition; }

  Value* previous_use() const { return previous_use_; }
  void set_previous_use(Value* previous) { previous_use_ = previous; }

  Value* next_use() const { return next_use_; }
  void set_next_use(Value* next) { next_use_ = next; }

  bool IsSingleUse() const {
    return (next_use_ == NULL) && (previous_use_ == NULL);
  }

  Instruction* instruction() const { return instruction_; }
  void set_instruction(Instruction* instruction) { instruction_ = instruction; }

  intptr_t use_index() const { return use_index_; }
  void set_use_index(intptr_t index) { use_index_ = index; }

  static void AddToList(Value* value, Value** list);
  void RemoveFromUseList();

  // Change the definition after use lists have been computed.
  inline void BindTo(Definition* definition);
  inline void BindToEnvironment(Definition* definition);

  Value* Copy(Zone* zone) { return new (zone) Value(definition_); }

  // CopyWithType() must only be used when the new Value is dominated by
  // the original Value.
  Value* CopyWithType(Zone* zone) {
    Value* copy = new (zone) Value(definition_);
    copy->reaching_type_ = reaching_type_;
    return copy;
  }
  Value* CopyWithType() { return CopyWithType(Thread::Current()->zone()); }

  CompileType* Type();

  void SetReachingType(CompileType* type) { reaching_type_ = type; }
  void RefineReachingType(CompileType* type);

  void PrintTo(BufferFormatter* f) const;

  const char* ToCString() const;

  bool IsSmiValue() { return Type()->ToCid() == kSmiCid; }

  // Return true if the value represents a constant.
  bool BindsToConstant() const;

  // Return true if the value represents the constant null.
  bool BindsToConstantNull() const;

  // Assert if BindsToConstant() is false, otherwise returns the constant value.
  const Object& BoundConstant() const;

  // Compile time constants, Bool, Smi and Nulls do not need to update
  // the store buffer.
  bool NeedsStoreBuffer();

  bool Equals(Value* other) const;

 private:
  friend class FlowGraphPrinter;

  Definition* definition_;
  Value* previous_use_;
  Value* next_use_;
  Instruction* instruction_;
  intptr_t use_index_;

  CompileType* reaching_type_;

  DISALLOW_COPY_AND_ASSIGN(Value);
};

// An embedded container with N elements of type T.  Used (with partial
// specialization for N=0) because embedded arrays cannot have size 0.
template <typename T, intptr_t N>
class EmbeddedArray {
 public:
  EmbeddedArray() : elements_() {}

  intptr_t length() const { return N; }

  const T& operator[](intptr_t i) const {
    ASSERT(i < length());
    return elements_[i];
  }

  T& operator[](intptr_t i) {
    ASSERT(i < length());
    return elements_[i];
  }

  const T& At(intptr_t i) const { return (*this)[i]; }

  void SetAt(intptr_t i, const T& val) { (*this)[i] = val; }

 private:
  T elements_[N];
};

template <typename T>
class EmbeddedArray<T, 0> {
 public:
  intptr_t length() const { return 0; }
  const T& operator[](intptr_t i) const {
    UNREACHABLE();
    static T sentinel = 0;
    return sentinel;
  }
  T& operator[](intptr_t i) {
    UNREACHABLE();
    static T sentinel = 0;
    return sentinel;
  }
};

// Instructions.

// M is a single argument macro.  It is applied to each concrete instruction
// type name.  The concrete instruction classes are the name with Instr
// concatenated.
#define FOR_EACH_INSTRUCTION(M)                                                \
  M(GraphEntry)                                                                \
  M(JoinEntry)                                                                 \
  M(TargetEntry)                                                               \
  M(IndirectEntry)                                                             \
  M(CatchBlockEntry)                                                           \
  M(Phi)                                                                       \
  M(Redefinition)                                                              \
  M(Parameter)                                                                 \
  M(ParallelMove)                                                              \
  M(PushArgument)                                                              \
  M(Return)                                                                    \
  M(Throw)                                                                     \
  M(ReThrow)                                                                   \
  M(Stop)                                                                      \
  M(Goto)                                                                      \
  M(IndirectGoto)                                                              \
  M(Branch)                                                                    \
  M(AssertAssignable)                                                          \
  M(AssertBoolean)                                                             \
  M(SpecialParameter)                                                          \
  M(ClosureCall)                                                               \
  M(InstanceCall)                                                              \
  M(PolymorphicInstanceCall)                                                   \
  M(StaticCall)                                                                \
  M(LoadLocal)                                                                 \
  M(DropTemps)                                                                 \
  M(StoreLocal)                                                                \
  M(StrictCompare)                                                             \
  M(EqualityCompare)                                                           \
  M(RelationalOp)                                                              \
  M(NativeCall)                                                                \
  M(DebugStepCheck)                                                            \
  M(LoadIndexed)                                                               \
  M(LoadCodeUnits)                                                             \
  M(StoreIndexed)                                                              \
  M(StoreInstanceField)                                                        \
  M(InitStaticField)                                                           \
  M(LoadStaticField)                                                           \
  M(StoreStaticField)                                                          \
  M(BooleanNegate)                                                             \
  M(InstanceOf)                                                                \
  M(CreateArray)                                                               \
  M(AllocateObject)                                                            \
  M(LoadField)                                                                 \
  M(LoadUntagged)                                                              \
  M(LoadClassId)                                                               \
  M(InstantiateType)                                                           \
  M(InstantiateTypeArguments)                                                  \
  M(AllocateContext)                                                           \
  M(AllocateUninitializedContext)                                              \
  M(CloneContext)                                                              \
  M(BinarySmiOp)                                                               \
  M(CheckedSmiComparison)                                                      \
  M(CheckedSmiOp)                                                              \
  M(BinaryInt32Op)                                                             \
  M(UnarySmiOp)                                                                \
  M(UnaryDoubleOp)                                                             \
  M(CheckStackOverflow)                                                        \
  M(SmiToDouble)                                                               \
  M(Int32ToDouble)                                                             \
  M(MintToDouble)                                                              \
  M(DoubleToInteger)                                                           \
  M(DoubleToSmi)                                                               \
  M(DoubleToDouble)                                                            \
  M(DoubleToFloat)                                                             \
  M(FloatToDouble)                                                             \
  M(CheckClass)                                                                \
  M(CheckClassId)                                                              \
  M(CheckSmi)                                                                  \
  M(CheckNull)                                                                 \
  M(Constant)                                                                  \
  M(UnboxedConstant)                                                           \
  M(CheckEitherNonSmi)                                                         \
  M(BinaryDoubleOp)                                                            \
  M(DoubleTestOp)                                                              \
  M(MathUnary)                                                                 \
  M(MathMinMax)                                                                \
  M(Box)                                                                       \
  M(Unbox)                                                                     \
  M(BoxInt64)                                                                  \
  M(UnboxInt64)                                                                \
  M(CaseInsensitiveCompareUC16)                                                \
  M(BinaryInt64Op)                                                             \
  M(ShiftInt64Op)                                                              \
  M(UnaryInt64Op)                                                              \
  M(CheckArrayBound)                                                           \
  M(GenericCheckBound)                                                         \
  M(Constraint)                                                                \
  M(StringToCharCode)                                                          \
  M(OneByteStringFromCharCode)                                                 \
  M(StringInterpolate)                                                         \
  M(InvokeMathCFunction)                                                       \
  M(TruncDivMod)                                                               \
  M(GuardFieldClass)                                                           \
  M(GuardFieldLength)                                                          \
  M(IfThenElse)                                                                \
  M(MaterializeObject)                                                         \
  M(TestSmi)                                                                   \
  M(TestCids)                                                                  \
  M(ExtractNthOutput)                                                          \
  M(BinaryUint32Op)                                                            \
  M(ShiftUint32Op)                                                             \
  M(UnaryUint32Op)                                                             \
  M(BoxUint32)                                                                 \
  M(UnboxUint32)                                                               \
  M(BoxInt32)                                                                  \
  M(UnboxInt32)                                                                \
  M(UnboxedIntConverter)                                                       \
  M(Deoptimize)                                                                \
  M(SimdOp)

#define FOR_EACH_ABSTRACT_INSTRUCTION(M)                                       \
  M(BlockEntry)                                                                \
  M(BoxInteger)                                                                \
  M(UnboxInteger)                                                              \
  M(Comparison)                                                                \
  M(UnaryIntegerOp)                                                            \
  M(BinaryIntegerOp)

#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
FOR_EACH_ABSTRACT_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

#define DEFINE_INSTRUCTION_TYPE_CHECK(type)                                    \
  virtual type##Instr* As##type() { return this; }                             \
  virtual const char* DebugName() const { return #type; }

// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION_NO_BACKEND(type)                                   \
  virtual Tag tag() const { return k##type; }                                  \
  virtual void Accept(FlowGraphVisitor* visitor);                              \
  DEFINE_INSTRUCTION_TYPE_CHECK(type)

#define DECLARE_INSTRUCTION_BACKEND()                                          \
  virtual LocationSummary* MakeLocationSummary(Zone* zone, bool optimizing)    \
      const;                                                                   \
  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                                              \
  DECLARE_INSTRUCTION_NO_BACKEND(type)                                         \
  DECLARE_INSTRUCTION_BACKEND()

#if defined(TARGET_ARCH_DBC)
#define DECLARE_COMPARISON_METHODS                                             \
  virtual LocationSummary* MakeLocationSummary(Zone* zone, bool optimizing)    \
      const;                                                                   \
  virtual Condition EmitComparisonCode(FlowGraphCompiler* compiler,            \
                                       BranchLabels labels);                   \
  virtual Condition GetNextInstructionCondition(FlowGraphCompiler* compiler,   \
                                                BranchLabels labels);
#else
#define DECLARE_COMPARISON_METHODS                                             \
  virtual LocationSummary* MakeLocationSummary(Zone* zone, bool optimizing)    \
      const;                                                                   \
  virtual Condition EmitComparisonCode(FlowGraphCompiler* compiler,            \
                                       BranchLabels labels);
#endif

#define DECLARE_COMPARISON_INSTRUCTION(type)                                   \
  DECLARE_INSTRUCTION_NO_BACKEND(type)                                         \
  DECLARE_COMPARISON_METHODS

#ifndef PRODUCT
#define PRINT_TO_SUPPORT virtual void PrintTo(BufferFormatter* f) const;
#else
#define PRINT_TO_SUPPORT
#endif  // !PRODUCT

#ifndef PRODUCT
#define PRINT_OPERANDS_TO_SUPPORT                                              \
  virtual void PrintOperandsTo(BufferFormatter* f) const;
#else
#define PRINT_OPERANDS_TO_SUPPORT
#endif  // !PRODUCT

// Represents a range of class-ids for use in class checks and polymorphic
// dispatches.
struct CidRange : public ZoneAllocated {
  CidRange(const CidRange& o)
      : ZoneAllocated(), cid_start(o.cid_start), cid_end(o.cid_end) {}
  CidRange(intptr_t cid_start_arg, intptr_t cid_end_arg)
      : cid_start(cid_start_arg), cid_end(cid_end_arg) {}

  bool IsSingleCid() const { return cid_start == cid_end; }
  bool Contains(intptr_t cid) { return cid_start <= cid && cid <= cid_end; }
  int32_t Extent() const { return cid_end - cid_start; }

  intptr_t cid_start;
  intptr_t cid_end;
};

// Together with CidRange, this represents a mapping from a range of class-ids
// to a method for a given selector (method name).  Also can contain an
// indication of how frequently a given method has been called at a call site.
// This information can be harvested from the inline caches (ICs).
struct TargetInfo : public CidRange {
  TargetInfo(intptr_t cid_start_arg,
             intptr_t cid_end_arg,
             const Function* target_arg,
             intptr_t count_arg)
      : CidRange(cid_start_arg, cid_end_arg),
        target(target_arg),
        count(count_arg) {
    ASSERT(target->IsZoneHandle());
  }
  const Function* target;
  intptr_t count;
};

// A set of class-ids, arranged in ranges. Used for the CheckClass
// and PolymorphicInstanceCall instructions.
class Cids : public ZoneAllocated {
 public:
  explicit Cids(Zone* zone) : zone_(zone) {}
  // Creates the off-heap Cids object that reflects the contents
  // of the on-VM-heap IC data.
  static Cids* Create(Zone* zone, const ICData& ic_data, int argument_number);
  static Cids* CreateMonomorphic(Zone* zone, intptr_t cid);

  bool Equals(const Cids& other) const;

  bool HasClassId(intptr_t cid) const;

  void Add(CidRange* target) { cid_ranges_.Add(target); }

  CidRange& operator[](intptr_t index) const { return *cid_ranges_[index]; }

  CidRange* At(int index) const { return cid_ranges_[index]; }

  intptr_t length() const { return cid_ranges_.length(); }

  void SetLength(intptr_t len) { cid_ranges_.SetLength(len); }

  bool is_empty() const { return cid_ranges_.is_empty(); }

  void Sort(int compare(CidRange* const* a, CidRange* const* b)) {
    cid_ranges_.Sort(compare);
  }

  bool IsMonomorphic() const;
  intptr_t MonomorphicReceiverCid() const;
  intptr_t ComputeLowestCid() const;
  intptr_t ComputeHighestCid() const;

 protected:
  void CreateHelper(Zone* zone,
                    const ICData& ic_data,
                    int argument_number,
                    bool include_targets);
  GrowableArray<CidRange*> cid_ranges_;
  Zone* zone_;

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(Cids);
};

class CallTargets : public Cids {
 public:
  explicit CallTargets(Zone* zone) : Cids(zone) {}
  // Creates the off-heap CallTargets object that reflects the contents
  // of the on-VM-heap IC data.
  static CallTargets* Create(Zone* zone, const ICData& ic_data);

  // This variant also expands the class-ids to neighbouring classes that
  // inherit the same method.
  static CallTargets* CreateAndExpand(Zone* zone, const ICData& ic_data);

  TargetInfo* TargetAt(int i) const { return static_cast<TargetInfo*>(At(i)); }

  intptr_t AggregateCallCount() const;

  bool HasSingleTarget() const;
  bool HasSingleRecognizedTarget() const;
  const Function& FirstTarget() const;
  const Function& MostPopularTarget() const;

 private:
  void MergeIntoRanges();
};

class Instruction : public ZoneAllocated {
 public:
#define DECLARE_TAG(type) k##type,
  enum Tag { FOR_EACH_INSTRUCTION(DECLARE_TAG) };
#undef DECLARE_TAG

  explicit Instruction(intptr_t deopt_id = Thread::kNoDeoptId)
      : deopt_id_(deopt_id),
        lifetime_position_(kNoPlaceId),
        previous_(NULL),
        next_(NULL),
        env_(NULL),
        locs_(NULL),
        inlining_id_(-1) {}

  virtual ~Instruction() {}

  virtual Tag tag() const = 0;

  intptr_t deopt_id() const {
    ASSERT(ComputeCanDeoptimize() || CanBecomeDeoptimizationTarget());
    return GetDeoptId();
  }

  const ICData* GetICData(
      const ZoneGrowableArray<const ICData*>& ic_data_array) const;

  virtual TokenPosition token_pos() const { return TokenPosition::kNoSource; }

  virtual intptr_t InputCount() const = 0;
  virtual Value* InputAt(intptr_t i) const = 0;
  void SetInputAt(intptr_t i, Value* value) {
    ASSERT(value != NULL);
    value->set_instruction(this);
    value->set_use_index(i);
    RawSetInputAt(i, value);
  }

  // Remove all inputs (including in the environment) from their
  // definition's use lists.
  void UnuseAllInputs();

  // Call instructions override this function and return the number of
  // pushed arguments.
  virtual intptr_t ArgumentCount() const { return 0; }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    UNREACHABLE();
    return NULL;
  }
  inline Definition* ArgumentAt(intptr_t index) const;

  // Returns true, if this instruction can deoptimize with its current inputs.
  // This property can change if we add or remove redefinitions that constrain
  // the type or the range of input operands during compilation.
  virtual bool ComputeCanDeoptimize() const = 0;

  // Once we removed the deopt environment, we assume that this
  // instruction can't deoptimize.
  bool CanDeoptimize() const { return env() != NULL && ComputeCanDeoptimize(); }

  // Visiting support.
  virtual void Accept(FlowGraphVisitor* visitor) = 0;

  Instruction* previous() const { return previous_; }
  void set_previous(Instruction* instr) {
    ASSERT(!IsBlockEntry());
    previous_ = instr;
  }

  Instruction* next() const { return next_; }
  void set_next(Instruction* instr) {
    ASSERT(!IsGraphEntry());
    ASSERT(!IsReturn());
    ASSERT(!IsBranch() || (instr == NULL));
    ASSERT(!IsPhi());
    ASSERT(instr == NULL || !instr->IsBlockEntry());
    // TODO(fschneider): Also add Throw and ReThrow to the list of instructions
    // that do not have a successor. Currently, the graph builder will continue
    // to append instruction in case of a Throw inside an expression. This
    // condition should be handled in the graph builder
    next_ = instr;
  }

  // Link together two instruction.
  void LinkTo(Instruction* next) {
    ASSERT(this != next);
    this->set_next(next);
    next->set_previous(this);
  }

  // Removed this instruction from the graph, after use lists have been
  // computed.  If the instruction is a definition with uses, those uses are
  // unaffected (so the instruction can be reinserted, e.g., hoisting).
  Instruction* RemoveFromGraph(bool return_previous = true);

  // Normal instructions can have 0 (inside a block) or 1 (last instruction in
  // a block) successors. Branch instruction with >1 successors override this
  // function.
  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  void Goto(JoinEntryInstr* entry);

  virtual const char* DebugName() const = 0;

#if defined(DEBUG)
  // Checks that the field stored in an instruction has proper form:
  // - must be a zone-handle
  // - In background compilation, must be cloned.
  // Aborts if field is not OK.
  void CheckField(const Field& field) const;
#else
  void CheckField(const Field& field) const {}
#endif  // DEBUG

  // Printing support.
  const char* ToCString() const;
#ifndef PRODUCT
  virtual void PrintTo(BufferFormatter* f) const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;
#endif

#define DECLARE_INSTRUCTION_TYPE_CHECK(Name, Type)                             \
  bool Is##Name() { return (As##Name() != NULL); }                             \
  virtual Type* As##Name() { return NULL; }
#define INSTRUCTION_TYPE_CHECK(Name)                                           \
  DECLARE_INSTRUCTION_TYPE_CHECK(Name, Name##Instr)

  DECLARE_INSTRUCTION_TYPE_CHECK(Definition, Definition)
  FOR_EACH_INSTRUCTION(INSTRUCTION_TYPE_CHECK)
  FOR_EACH_ABSTRACT_INSTRUCTION(INSTRUCTION_TYPE_CHECK)

#undef INSTRUCTION_TYPE_CHECK
#undef DECLARE_INSTRUCTION_TYPE_CHECK

  // Returns structure describing location constraints required
  // to emit native code for this instruction.
  LocationSummary* locs() {
    ASSERT(locs_ != NULL);
    return locs_;
  }

  bool HasLocs() const { return locs_ != NULL; }

  virtual LocationSummary* MakeLocationSummary(Zone* zone,
                                               bool is_optimizing) const = 0;

  void InitializeLocationSummary(Zone* zone, bool optimizing) {
    ASSERT(locs_ == NULL);
    locs_ = MakeLocationSummary(zone, optimizing);
  }

  static LocationSummary* MakeCallSummary(Zone* zone);

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) { UNIMPLEMENTED(); }

  Environment* env() const { return env_; }
  void SetEnvironment(Environment* deopt_env);
  void RemoveEnvironment();

  intptr_t lifetime_position() const { return lifetime_position_; }
  void set_lifetime_position(intptr_t pos) { lifetime_position_ = pos; }

  bool HasUnmatchedInputRepresentations() const;

  // Returns representation expected for the input operand at the given index.
  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    return kTagged;
  }

  // Representation of the value produced by this computation.
  virtual Representation representation() const { return kTagged; }

  bool WasEliminated() const { return next() == NULL; }

  // Returns deoptimization id that corresponds to the deoptimization target
  // that input operands conversions inserted for this instruction can jump
  // to.
  virtual intptr_t DeoptimizationTarget() const {
    UNREACHABLE();
    return Thread::kNoDeoptId;
  }

  // Returns a replacement for the instruction or NULL if the instruction can
  // be eliminated.  By default returns the this instruction which means no
  // change.
  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  // Insert this instruction before 'next' after use lists are computed.
  // Instructions cannot be inserted before a block entry or any other
  // instruction without a previous instruction.
  void InsertBefore(Instruction* next) { InsertAfter(next->previous()); }

  // Insert this instruction after 'prev' after use lists are computed.
  void InsertAfter(Instruction* prev);

  // Append an instruction to the current one and return the tail.
  // This function updated def-use chains of the newly appended
  // instruction.
  Instruction* AppendInstruction(Instruction* tail);

  // Returns true if CSE and LICM are allowed for this instruction.
  virtual bool AllowsCSE() const { return false; }

  // Returns true if this instruction has any side-effects besides storing.
  // See StoreInstanceFieldInstr::HasUnknownSideEffects() for rationale.
  virtual bool HasUnknownSideEffects() const = 0;

  // Get the block entry for this instruction.
  virtual BlockEntryInstr* GetBlock();

  // Place identifiers used by the load optimization pass.
  intptr_t place_id() const { return place_id_; }
  void set_place_id(intptr_t place_id) { place_id_ = place_id; }
  bool HasPlaceId() const { return place_id_ != kNoPlaceId; }

  intptr_t inlining_id() const { return inlining_id_; }
  void set_inlining_id(intptr_t value) {
    ASSERT(value >= 0);
    inlining_id_ = value;
  }
  bool has_inlining_id() const { return inlining_id_ >= 0; }

  // Returns a hash code for use with hash maps.
  virtual intptr_t Hashcode() const;

  // Compares two instructions.  Returns true, iff:
  // 1. They have the same tag.
  // 2. All input operands are Equals.
  // 3. They satisfy AttributesEqual.
  bool Equals(Instruction* other) const;

  // Compare attributes of a instructions (except input operands and tag).
  // All instructions that participate in CSE have to override this function.
  // This function can assume that the argument has the same type as this.
  virtual bool AttributesEqual(Instruction* other) const {
    UNREACHABLE();
    return false;
  }

  virtual void InheritDeoptTarget(Zone* zone, Instruction* other);

  bool NeedsEnvironment() const {
    return ComputeCanDeoptimize() || CanBecomeDeoptimizationTarget();
  }

  virtual bool CanBecomeDeoptimizationTarget() const { return false; }

  void InheritDeoptTargetAfter(FlowGraph* flow_graph,
                               Definition* call,
                               Definition* result);

  virtual bool MayThrow() const = 0;

  bool IsDominatedBy(Instruction* dom);

  void ClearEnv() { env_ = NULL; }

  void Unsupported(FlowGraphCompiler* compiler);

 protected:
  // GetDeoptId and/or CopyDeoptIdFrom.
  friend class CallSiteInliner;
  friend class LICM;
  friend class ComparisonInstr;
  friend class Scheduler;
  friend class BlockEntryInstr;
  friend class CatchBlockEntryInstr;  // deopt_id_
  friend class DebugStepCheckInstr;   // deopt_id_
  friend class StrictCompareInstr;    // deopt_id_

  // Fetch deopt id without checking if this computation can deoptimize.
  intptr_t GetDeoptId() const { return deopt_id_; }

  void CopyDeoptIdFrom(const Instruction& instr) {
    deopt_id_ = instr.deopt_id_;
  }

 private:
  friend class BranchInstr;      // For RawSetInputAt.
  friend class IfThenElseInstr;  // For RawSetInputAt.

  virtual void RawSetInputAt(intptr_t i, Value* value) = 0;

  enum { kNoPlaceId = -1 };

  intptr_t deopt_id_;
  union {
    intptr_t lifetime_position_;  // Position used by register allocator.
    intptr_t place_id_;
  };
  Instruction* previous_;
  Instruction* next_;
  Environment* env_;
  LocationSummary* locs_;
  intptr_t inlining_id_;

  DISALLOW_COPY_AND_ASSIGN(Instruction);
};

struct BranchLabels {
  Label* true_label;
  Label* false_label;
  Label* fall_through;
};

class PureInstruction : public Instruction {
 public:
  explicit PureInstruction(intptr_t deopt_id) : Instruction(deopt_id) {}

  virtual bool AllowsCSE() const { return true; }
  virtual bool HasUnknownSideEffects() const { return false; }
};

// Types to be used as ThrowsTrait for TemplateInstruction/TemplateDefinition.
struct Throws {
  static const bool kCanThrow = true;
};

struct NoThrow {
  static const bool kCanThrow = false;
};

// Types to be used as CSETrait for TemplateInstruction/TemplateDefinition.
// Pure instructions are those that allow CSE and have no effects and
// no dependencies.
template <typename DefaultBase, typename PureBase>
struct Pure {
  typedef PureBase Base;
};

template <typename DefaultBase, typename PureBase>
struct NoCSE {
  typedef DefaultBase Base;
};

template <intptr_t N,
          typename ThrowsTrait,
          template <typename Default, typename Pure> class CSETrait = NoCSE>
class TemplateInstruction
    : public CSETrait<Instruction, PureInstruction>::Base {
 public:
  explicit TemplateInstruction(intptr_t deopt_id = Thread::kNoDeoptId)
      : CSETrait<Instruction, PureInstruction>::Base(deopt_id), inputs_() {}

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool MayThrow() const { return ThrowsTrait::kCanThrow; }

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }
};

class MoveOperands : public ZoneAllocated {
 public:
  MoveOperands(Location dest, Location src) : dest_(dest), src_(src) {}

  Location src() const { return src_; }
  Location dest() const { return dest_; }

  Location* src_slot() { return &src_; }
  Location* dest_slot() { return &dest_; }

  void set_src(const Location& value) { src_ = value; }
  void set_dest(const Location& value) { dest_ = value; }

  // The parallel move resolver marks moves as "in-progress" by clearing the
  // destination (but not the source).
  Location MarkPending() {
    ASSERT(!IsPending());
    Location dest = dest_;
    dest_ = Location::NoLocation();
    return dest;
  }

  void ClearPending(Location dest) {
    ASSERT(IsPending());
    dest_ = dest;
  }

  bool IsPending() const {
    ASSERT(!src_.IsInvalid() || dest_.IsInvalid());
    return dest_.IsInvalid() && !src_.IsInvalid();
  }

  // True if this move a move from the given location.
  bool Blocks(Location loc) const {
    return !IsEliminated() && src_.Equals(loc);
  }

  // A move is redundant if it's been eliminated, if its source and
  // destination are the same, or if its destination is unneeded.
  bool IsRedundant() const {
    return IsEliminated() || dest_.IsInvalid() || src_.Equals(dest_);
  }

  // We clear both operands to indicate move that's been eliminated.
  void Eliminate() { src_ = dest_ = Location::NoLocation(); }
  bool IsEliminated() const {
    ASSERT(!src_.IsInvalid() || dest_.IsInvalid());
    return src_.IsInvalid();
  }

 private:
  Location dest_;
  Location src_;

  DISALLOW_COPY_AND_ASSIGN(MoveOperands);
};

class ParallelMoveInstr : public TemplateInstruction<0, NoThrow> {
 public:
  ParallelMoveInstr() : moves_(4) {}

  DECLARE_INSTRUCTION(ParallelMove)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const {
    UNREACHABLE();  // This instruction never visited by optimization passes.
    return false;
  }

  MoveOperands* AddMove(Location dest, Location src) {
    MoveOperands* move = new MoveOperands(dest, src);
    moves_.Add(move);
    return move;
  }

  MoveOperands* MoveOperandsAt(intptr_t index) const { return moves_[index]; }

  intptr_t NumMoves() const { return moves_.length(); }

  bool IsRedundant() const;

  virtual TokenPosition token_pos() const {
    return TokenPosition::kParallelMove;
  }

  PRINT_TO_SUPPORT

 private:
  GrowableArray<MoveOperands*> moves_;  // Elements cannot be null.

  DISALLOW_COPY_AND_ASSIGN(ParallelMoveInstr);
};

// Basic block entries are administrative nodes.  There is a distinguished
// graph entry with no predecessor.  Joins are the only nodes with multiple
// predecessors.  Targets are all other basic block entries.  The types
// enforce edge-split form---joins are forbidden as the successors of
// branches.
class BlockEntryInstr : public Instruction {
 public:
  virtual intptr_t PredecessorCount() const = 0;
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const = 0;

  intptr_t preorder_number() const { return preorder_number_; }
  void set_preorder_number(intptr_t number) { preorder_number_ = number; }

  intptr_t postorder_number() const { return postorder_number_; }
  void set_postorder_number(intptr_t number) { postorder_number_ = number; }

  intptr_t block_id() const { return block_id_; }

  // NOTE: These are SSA positions and not token positions. These are used by
  // the register allocator.
  void set_start_pos(intptr_t pos) { start_pos_ = pos; }
  intptr_t start_pos() const { return start_pos_; }
  void set_end_pos(intptr_t pos) { end_pos_ = pos; }
  intptr_t end_pos() const { return end_pos_; }

  BlockEntryInstr* dominator() const { return dominator_; }
  BlockEntryInstr* ImmediateDominator() const;

  const GrowableArray<BlockEntryInstr*>& dominated_blocks() {
    return dominated_blocks_;
  }

  void AddDominatedBlock(BlockEntryInstr* block) {
    block->set_dominator(this);
    dominated_blocks_.Add(block);
  }
  void ClearDominatedBlocks() { dominated_blocks_.Clear(); }

  bool Dominates(BlockEntryInstr* other) const;

  Instruction* last_instruction() const { return last_instruction_; }
  void set_last_instruction(Instruction* instr) { last_instruction_ = instr; }

  ParallelMoveInstr* parallel_move() const { return parallel_move_; }

  bool HasParallelMove() const { return parallel_move_ != NULL; }

  bool HasNonRedundantParallelMove() const {
    return HasParallelMove() && !parallel_move()->IsRedundant();
  }

  ParallelMoveInstr* GetParallelMove() {
    if (parallel_move_ == NULL) {
      parallel_move_ = new ParallelMoveInstr();
    }
    return parallel_move_;
  }

  // Discover basic-block structure of the current block.  Must be called
  // on all graph blocks in preorder to yield valid results.  As a side effect,
  // the block entry instructions in the graph are assigned preorder numbers.
  // The array 'preorder' maps preorder block numbers to the block entry
  // instruction with that number.  The depth first spanning tree is recorded
  // in the array 'parent', which maps preorder block numbers to the preorder
  // number of the block's spanning-tree parent.  As a side effect of this
  // function, the set of basic block predecessors (e.g., block entry
  // instructions of predecessor blocks) and also the last instruction in the
  // block is recorded in each entry instruction.  Returns true when called the
  // first time on this particular block within one graph traversal, and false
  // on all successive calls.
  bool DiscoverBlock(BlockEntryInstr* predecessor,
                     GrowableArray<BlockEntryInstr*>* preorder,
                     GrowableArray<intptr_t>* parent);

  virtual intptr_t InputCount() const { return 0; }
  virtual Value* InputAt(intptr_t i) const {
    UNREACHABLE();
    return NULL;
  }

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // BlockEntry environment is copied to Goto and Branch instructions
    // when we insert new blocks targeting this block.
    return true;
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool MayThrow() const { return false; }

  intptr_t try_index() const { return try_index_; }
  void set_try_index(intptr_t index) { try_index_ = index; }

  // True for blocks inside a try { } region.
  bool InsideTryBlock() const {
    return try_index_ != CatchClauseNode::kInvalidTryIndex;
  }

  BitVector* loop_info() const { return loop_info_; }
  void set_loop_info(BitVector* loop_info) { loop_info_ = loop_info; }

  virtual BlockEntryInstr* GetBlock() { return this; }

  virtual TokenPosition token_pos() const {
    return TokenPosition::kControlFlow;
  }

  // Helper to mutate the graph during inlining. This block should be
  // replaced with new_block as a predecessor of all of this block's
  // successors.
  void ReplaceAsPredecessorWith(BlockEntryInstr* new_block);

  void set_block_id(intptr_t block_id) { block_id_ = block_id; }

  intptr_t offset() const { return offset_; }
  void set_offset(intptr_t offset) { offset_ = offset; }

  // For all instruction in this block: Remove all inputs (including in the
  // environment) from their definition's use lists for all instructions.
  void ClearAllInstructions();

  DEFINE_INSTRUCTION_TYPE_CHECK(BlockEntry)

 protected:
  BlockEntryInstr(intptr_t block_id, intptr_t try_index, intptr_t deopt_id)
      : Instruction(deopt_id),
        block_id_(block_id),
        try_index_(try_index),
        preorder_number_(-1),
        postorder_number_(-1),
        dominator_(NULL),
        dominated_blocks_(1),
        last_instruction_(NULL),
        offset_(-1),
        parallel_move_(NULL),
        loop_info_(NULL) {}

  // Perform a depth first search to find OSR entry and
  // link it to the given graph entry.
  bool FindOsrEntryAndRelink(GraphEntryInstr* graph_entry,
                             Instruction* parent,
                             BitVector* block_marks);

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  virtual void ClearPredecessors() = 0;
  virtual void AddPredecessor(BlockEntryInstr* predecessor) = 0;

  void set_dominator(BlockEntryInstr* instr) { dominator_ = instr; }

  intptr_t block_id_;
  intptr_t try_index_;
  intptr_t preorder_number_;
  intptr_t postorder_number_;
  // Starting and ending lifetime positions for this block.  Used by
  // the linear scan register allocator.
  intptr_t start_pos_;
  intptr_t end_pos_;
  BlockEntryInstr* dominator_;  // Immediate dominator, NULL for graph entry.
  // TODO(fschneider): Optimize the case of one child to save space.
  GrowableArray<BlockEntryInstr*> dominated_blocks_;
  Instruction* last_instruction_;

  // Offset of this block from the start of the emitted code.
  intptr_t offset_;

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the start of the block.
  ParallelMoveInstr* parallel_move_;

  // Bit vector containing loop blocks for a loop header indexed by block
  // preorder number.
  BitVector* loop_info_;

  DISALLOW_COPY_AND_ASSIGN(BlockEntryInstr);
};

class ForwardInstructionIterator : public ValueObject {
 public:
  explicit ForwardInstructionIterator(BlockEntryInstr* block_entry)
      : current_(block_entry) {
    Advance();
  }

  void Advance() {
    ASSERT(!Done());
    current_ = current_->next();
  }

  bool Done() const { return current_ == NULL; }

  // Removes 'current_' from graph and sets 'current_' to previous instruction.
  void RemoveCurrentFromGraph();

  Instruction* Current() const { return current_; }

 private:
  Instruction* current_;
};

class BackwardInstructionIterator : public ValueObject {
 public:
  explicit BackwardInstructionIterator(BlockEntryInstr* block_entry)
      : block_entry_(block_entry), current_(block_entry->last_instruction()) {
    ASSERT(block_entry_->previous() == NULL);
  }

  void Advance() {
    ASSERT(!Done());
    current_ = current_->previous();
  }

  bool Done() const { return current_ == block_entry_; }

  void RemoveCurrentFromGraph();

  Instruction* Current() const { return current_; }

 private:
  BlockEntryInstr* block_entry_;
  Instruction* current_;
};

class GraphEntryInstr : public BlockEntryInstr {
 public:
  GraphEntryInstr(const ParsedFunction& parsed_function,
                  TargetEntryInstr* normal_entry,
                  intptr_t osr_id);

  DECLARE_INSTRUCTION(GraphEntry)

  virtual intptr_t PredecessorCount() const { return 0; }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    UNREACHABLE();
    return NULL;
  }
  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  void AddCatchEntry(CatchBlockEntryInstr* entry) { catch_entries_.Add(entry); }

  CatchBlockEntryInstr* GetCatchEntry(intptr_t index);

  void AddIndirectEntry(IndirectEntryInstr* entry) {
    indirect_entries_.Add(entry);
  }

  GrowableArray<Definition*>* initial_definitions() {
    return &initial_definitions_;
  }
  ConstantInstr* constant_null();

  void RelinkToOsrEntry(Zone* zone, intptr_t max_block_id);
  bool IsCompiledForOsr() const;
  intptr_t osr_id() const { return osr_id_; }

  intptr_t entry_count() const { return entry_count_; }
  void set_entry_count(intptr_t count) { entry_count_ = count; }

  intptr_t spill_slot_count() const { return spill_slot_count_; }
  void set_spill_slot_count(intptr_t count) {
    ASSERT(count >= 0);
    spill_slot_count_ = count;
  }

  // Number of stack slots reserved for compiling try-catch. For functions
  // without try-catch, this is 0. Otherwise, it is the number of local
  // variables.
  intptr_t fixed_slot_count() const { return fixed_slot_count_; }
  void set_fixed_slot_count(intptr_t count) {
    ASSERT(count >= 0);
    fixed_slot_count_ = count;
  }
  TargetEntryInstr* normal_entry() const { return normal_entry_; }

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  const GrowableArray<CatchBlockEntryInstr*>& catch_entries() const {
    return catch_entries_;
  }

  const GrowableArray<IndirectEntryInstr*>& indirect_entries() const {
    return indirect_entries_;
  }

  PRINT_TO_SUPPORT

 private:
  virtual void ClearPredecessors() {}
  virtual void AddPredecessor(BlockEntryInstr* predecessor) { UNREACHABLE(); }

  const ParsedFunction& parsed_function_;
  TargetEntryInstr* normal_entry_;
  GrowableArray<CatchBlockEntryInstr*> catch_entries_;
  // Indirect targets are blocks reachable only through indirect gotos.
  GrowableArray<IndirectEntryInstr*> indirect_entries_;
  GrowableArray<Definition*> initial_definitions_;
  const intptr_t osr_id_;
  intptr_t entry_count_;
  intptr_t spill_slot_count_;
  intptr_t fixed_slot_count_;  // For try-catch in optimized code.

  DISALLOW_COPY_AND_ASSIGN(GraphEntryInstr);
};

class JoinEntryInstr : public BlockEntryInstr {
 public:
  JoinEntryInstr(intptr_t block_id, intptr_t try_index, intptr_t deopt_id)
      : BlockEntryInstr(block_id, try_index, deopt_id),
        predecessors_(2),  // Two is the assumed to be the common case.
        phis_(NULL) {}

  DECLARE_INSTRUCTION(JoinEntry)

  virtual intptr_t PredecessorCount() const { return predecessors_.length(); }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    return predecessors_[index];
  }

  // Returns -1 if pred is not in the list.
  intptr_t IndexOfPredecessor(BlockEntryInstr* pred) const;

  ZoneGrowableArray<PhiInstr*>* phis() const { return phis_; }

  PhiInstr* InsertPhi(intptr_t var_index, intptr_t var_count);
  void RemoveDeadPhis(Definition* replacement);

  void InsertPhi(PhiInstr* phi);
  void RemovePhi(PhiInstr* phi);

  virtual bool HasUnknownSideEffects() const { return false; }

  PRINT_TO_SUPPORT

 private:
  // Classes that have access to predecessors_ when inlining.
  friend class BlockEntryInstr;
  friend class InlineExitCollector;
  friend class PolymorphicInliner;
  friend class IndirectEntryInstr;  // Access in il_printer.cc.

  // Direct access to phis_ in order to resize it due to phi elimination.
  friend class ConstantPropagator;
  friend class DeadCodeElimination;

  virtual void ClearPredecessors() { predecessors_.Clear(); }
  virtual void AddPredecessor(BlockEntryInstr* predecessor);

  GrowableArray<BlockEntryInstr*> predecessors_;
  ZoneGrowableArray<PhiInstr*>* phis_;

  DISALLOW_COPY_AND_ASSIGN(JoinEntryInstr);
};

class PhiIterator : public ValueObject {
 public:
  explicit PhiIterator(JoinEntryInstr* join) : phis_(join->phis()), index_(0) {}

  void Advance() {
    ASSERT(!Done());
    index_++;
  }

  bool Done() const { return (phis_ == NULL) || (index_ >= phis_->length()); }

  PhiInstr* Current() const { return (*phis_)[index_]; }

 private:
  ZoneGrowableArray<PhiInstr*>* phis_;
  intptr_t index_;
};

class TargetEntryInstr : public BlockEntryInstr {
 public:
  TargetEntryInstr(intptr_t block_id, intptr_t try_index, intptr_t deopt_id)
      : BlockEntryInstr(block_id, try_index, deopt_id),
        predecessor_(NULL),
        edge_weight_(0.0) {}

  DECLARE_INSTRUCTION(TargetEntry)

  double edge_weight() const { return edge_weight_; }
  void set_edge_weight(double weight) { edge_weight_ = weight; }
  void adjust_edge_weight(double scale_factor) { edge_weight_ *= scale_factor; }

  virtual intptr_t PredecessorCount() const {
    return (predecessor_ == NULL) ? 0 : 1;
  }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    ASSERT((index == 0) && (predecessor_ != NULL));
    return predecessor_;
  }

  PRINT_TO_SUPPORT

 private:
  friend class BlockEntryInstr;  // Access to predecessor_ when inlining.

  virtual void ClearPredecessors() { predecessor_ = NULL; }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    ASSERT(predecessor_ == NULL);
    predecessor_ = predecessor;
  }

  BlockEntryInstr* predecessor_;
  double edge_weight_;

  DISALLOW_COPY_AND_ASSIGN(TargetEntryInstr);
};

class IndirectEntryInstr : public JoinEntryInstr {
 public:
  IndirectEntryInstr(intptr_t block_id,
                     intptr_t indirect_id,
                     intptr_t try_index,
                     intptr_t deopt_id)
      : JoinEntryInstr(block_id, try_index, deopt_id),
        indirect_id_(indirect_id) {}

  DECLARE_INSTRUCTION(IndirectEntry)

  intptr_t indirect_id() const { return indirect_id_; }

  PRINT_TO_SUPPORT

 private:
  const intptr_t indirect_id_;
};

class CatchBlockEntryInstr : public BlockEntryInstr {
 public:
  CatchBlockEntryInstr(TokenPosition handler_token_pos,
                       bool is_generated,
                       intptr_t block_id,
                       intptr_t try_index,
                       GraphEntryInstr* graph_entry,
                       const Array& handler_types,
                       intptr_t catch_try_index,
                       const LocalVariable& exception_var,
                       const LocalVariable& stacktrace_var,
                       bool needs_stacktrace,
                       intptr_t deopt_id,
                       bool should_restore_closure_context = false)
      : BlockEntryInstr(block_id, try_index, deopt_id),
        graph_entry_(graph_entry),
        predecessor_(NULL),
        catch_handler_types_(Array::ZoneHandle(handler_types.raw())),
        catch_try_index_(catch_try_index),
        exception_var_(exception_var),
        stacktrace_var_(stacktrace_var),
        needs_stacktrace_(needs_stacktrace),
        should_restore_closure_context_(should_restore_closure_context),
        handler_token_pos_(handler_token_pos),
        is_generated_(is_generated) {}

  DECLARE_INSTRUCTION(CatchBlockEntry)

  virtual intptr_t PredecessorCount() const {
    return (predecessor_ == NULL) ? 0 : 1;
  }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    ASSERT((index == 0) && (predecessor_ != NULL));
    return predecessor_;
  }

  GraphEntryInstr* graph_entry() const { return graph_entry_; }

  const LocalVariable& exception_var() const { return exception_var_; }
  const LocalVariable& stacktrace_var() const { return stacktrace_var_; }

  bool needs_stacktrace() const { return needs_stacktrace_; }

  bool is_generated() const { return is_generated_; }
  TokenPosition handler_token_pos() const { return handler_token_pos_; }

  // Returns try index for the try block to which this catch handler
  // corresponds.
  intptr_t catch_try_index() const { return catch_try_index_; }
  GrowableArray<Definition*>* initial_definitions() {
    return &initial_definitions_;
  }

  PRINT_TO_SUPPORT

 private:
  friend class BlockEntryInstr;  // Access to predecessor_ when inlining.

  virtual void ClearPredecessors() { predecessor_ = NULL; }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    ASSERT(predecessor_ == NULL);
    predecessor_ = predecessor;
  }

  bool should_restore_closure_context() const {
    ASSERT(exception_var_.is_captured() == stacktrace_var_.is_captured());
    ASSERT(!exception_var_.is_captured() || should_restore_closure_context_);
    return should_restore_closure_context_;
  }

  GraphEntryInstr* graph_entry_;
  BlockEntryInstr* predecessor_;
  const Array& catch_handler_types_;
  const intptr_t catch_try_index_;
  GrowableArray<Definition*> initial_definitions_;
  const LocalVariable& exception_var_;
  const LocalVariable& stacktrace_var_;
  const bool needs_stacktrace_;
  const bool should_restore_closure_context_;
  TokenPosition handler_token_pos_;
  bool is_generated_;

  DISALLOW_COPY_AND_ASSIGN(CatchBlockEntryInstr);
};

// If the result of the allocation is not stored into any field, passed
// as an argument or used in a phi then it can't alias with any other
// SSA value.
class AliasIdentity : public ValueObject {
 public:
  // It is unknown if value has aliases.
  static AliasIdentity Unknown() { return AliasIdentity(kUnknown); }

  // It is known that value can have aliases.
  static AliasIdentity Aliased() { return AliasIdentity(kAliased); }

  // It is known that value has no aliases.
  static AliasIdentity NotAliased() { return AliasIdentity(kNotAliased); }

  // It is known that value has no aliases and it was selected by
  // allocation sinking pass as a candidate.
  static AliasIdentity AllocationSinkingCandidate() {
    return AliasIdentity(kAllocationSinkingCandidate);
  }

  bool IsUnknown() const { return value_ == kUnknown; }
  bool IsAliased() const { return value_ == kAliased; }
  bool IsNotAliased() const { return (value_ & kNotAliased) != 0; }
  bool IsAllocationSinkingCandidate() const {
    return value_ == kAllocationSinkingCandidate;
  }

  AliasIdentity(const AliasIdentity& other)
      : ValueObject(), value_(other.value_) {}

  AliasIdentity& operator=(const AliasIdentity& other) {
    value_ = other.value_;
    return *this;
  }

 private:
  explicit AliasIdentity(intptr_t value) : value_(value) {}

  enum {
    kUnknown = 0,
    kNotAliased = 1,
    kAliased = 2,
    kAllocationSinkingCandidate = 3,
  };

  COMPILE_ASSERT((kUnknown & kNotAliased) == 0);
  COMPILE_ASSERT((kAliased & kNotAliased) == 0);
  COMPILE_ASSERT((kAllocationSinkingCandidate & kNotAliased) != 0);

  intptr_t value_;
};

// Abstract super-class of all instructions that define a value (Bind, Phi).
class Definition : public Instruction {
 public:
  explicit Definition(intptr_t deopt_id = Thread::kNoDeoptId);

  // Overridden by definitions that have call counts.
  virtual intptr_t CallCount() const {
    UNREACHABLE();
    return -1;
  }

  intptr_t temp_index() const { return temp_index_; }
  void set_temp_index(intptr_t index) { temp_index_ = index; }
  void ClearTempIndex() { temp_index_ = -1; }
  bool HasTemp() const { return temp_index_ >= 0; }

  intptr_t ssa_temp_index() const { return ssa_temp_index_; }
  void set_ssa_temp_index(intptr_t index) {
    ASSERT(index >= 0);
    ssa_temp_index_ = index;
  }
  bool HasSSATemp() const { return ssa_temp_index_ >= 0; }
  void ClearSSATempIndex() { ssa_temp_index_ = -1; }
  bool HasPairRepresentation() const {
#if defined(TARGET_ARCH_X64)
    return representation() == kPairOfTagged;
#else
    return (representation() == kPairOfTagged) ||
           (representation() == kUnboxedInt64);
#endif
  }

  // Compile time type of the definition, which may be requested before type
  // propagation during graph building.
  CompileType* Type() {
    if (type_ == NULL) {
      type_ = new CompileType(ComputeType());
    }
    return type_;
  }

  // Does this define a mint?
  inline bool IsMintDefinition();

  bool IsInt32Definition() {
    return IsBinaryInt32Op() || IsBoxInt32() || IsUnboxInt32() ||
           IsUnboxedIntConverter();
  }

  // Compute compile type for this definition. It is safe to use this
  // approximation even before type propagator was run (e.g. during graph
  // building).
  virtual CompileType ComputeType() const { return CompileType::Dynamic(); }

  // Update CompileType of the definition. Returns true if the type has changed.
  virtual bool RecomputeType() { return false; }

  PRINT_OPERANDS_TO_SUPPORT
  PRINT_TO_SUPPORT

  bool UpdateType(CompileType new_type) {
    if (type_ == NULL) {
      type_ = new CompileType(new_type);
      return true;
    }

    if (type_->IsNone() || !type_->IsEqualTo(&new_type)) {
      *type_ = new_type;
      return true;
    }

    return false;
  }

  bool HasUses() const {
    return (input_use_list_ != NULL) || (env_use_list_ != NULL);
  }
  bool HasOnlyUse(Value* use) const;
  bool HasOnlyInputUse(Value* use) const;

  Value* input_use_list() const { return input_use_list_; }
  void set_input_use_list(Value* head) { input_use_list_ = head; }

  Value* env_use_list() const { return env_use_list_; }
  void set_env_use_list(Value* head) { env_use_list_ = head; }

  void AddInputUse(Value* value) { Value::AddToList(value, &input_use_list_); }
  void AddEnvUse(Value* value) { Value::AddToList(value, &env_use_list_); }

  // Replace uses of this definition with uses of other definition or value.
  // Precondition: use lists must be properly calculated.
  // Postcondition: use lists and use values are still valid.
  void ReplaceUsesWith(Definition* other);

  // Replace this definition and all uses with another definition.  If
  // replacing during iteration, pass the iterator so that the instruction
  // can be replaced without affecting iteration order, otherwise pass a
  // NULL iterator.
  void ReplaceWith(Definition* other, ForwardInstructionIterator* iterator);

  // A value in the constant propagation lattice.
  //    - non-constant sentinel
  //    - a constant (any non-sentinel value)
  //    - unknown sentinel
  Object& constant_value();

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  Range* range() const { return range_; }
  void set_range(const Range&);

  // Definitions can be canonicalized only into definitions to ensure
  // this check statically we override base Canonicalize with a Canonicalize
  // returning Definition (return type is covariant).
  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  static const intptr_t kReplacementMarker = -2;

  Definition* Replacement() {
    if (ssa_temp_index_ == kReplacementMarker) {
      return reinterpret_cast<Definition*>(temp_index_);
    }
    return this;
  }

  void SetReplacement(Definition* other) {
    ASSERT(ssa_temp_index_ >= 0);
    ASSERT(WasEliminated());
    ssa_temp_index_ = kReplacementMarker;
    temp_index_ = reinterpret_cast<intptr_t>(other);
  }

  virtual AliasIdentity Identity() const { return AliasIdentity::Unknown(); }

  virtual void SetIdentity(AliasIdentity identity) { UNREACHABLE(); }

  Definition* OriginalDefinition();

  virtual Definition* AsDefinition() { return this; }

 protected:
  friend class RangeAnalysis;
  friend class Value;

  Range* range_;
  CompileType* type_;

 private:
  intptr_t temp_index_;
  intptr_t ssa_temp_index_;
  Value* input_use_list_;
  Value* env_use_list_;

  Object* constant_value_;

  DISALLOW_COPY_AND_ASSIGN(Definition);
};

// Change a value's definition after use lists have been computed.
inline void Value::BindTo(Definition* def) {
  RemoveFromUseList();
  set_definition(def);
  def->AddInputUse(this);
}

inline void Value::BindToEnvironment(Definition* def) {
  RemoveFromUseList();
  set_definition(def);
  def->AddEnvUse(this);
}

class PureDefinition : public Definition {
 public:
  explicit PureDefinition(intptr_t deopt_id) : Definition(deopt_id) {}

  virtual bool AllowsCSE() const { return true; }
  virtual bool HasUnknownSideEffects() const { return false; }
};

template <intptr_t N,
          typename ThrowsTrait,
          template <typename Impure, typename Pure> class CSETrait = NoCSE>
class TemplateDefinition : public CSETrait<Definition, PureDefinition>::Base {
 public:
  explicit TemplateDefinition(intptr_t deopt_id = Thread::kNoDeoptId)
      : CSETrait<Definition, PureDefinition>::Base(deopt_id), inputs_() {}

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool MayThrow() const { return ThrowsTrait::kCanThrow; }

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  friend class BranchInstr;
  friend class IfThenElseInstr;

  virtual void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }
};

class InductionVariableInfo;

class PhiInstr : public Definition {
 public:
  PhiInstr(JoinEntryInstr* block, intptr_t num_inputs)
      : block_(block),
        inputs_(num_inputs),
        representation_(kTagged),
        reaching_defs_(NULL),
        loop_variable_info_(NULL),
        is_alive_(false),
        is_receiver_(kUnknownReceiver) {
    for (intptr_t i = 0; i < num_inputs; ++i) {
      inputs_.Add(NULL);
    }
  }

  // Get the block entry for that instruction.
  virtual BlockEntryInstr* GetBlock() { return block(); }
  JoinEntryInstr* block() const { return block_; }

  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  intptr_t InputCount() const { return inputs_.length(); }

  Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  // Phi is alive if it reaches a non-environment use.
  bool is_alive() const { return is_alive_; }
  void mark_alive() { is_alive_ = true; }
  void mark_dead() { is_alive_ = false; }

  virtual Representation RequiredInputRepresentation(intptr_t i) const {
    return representation_;
  }

  virtual Representation representation() const { return representation_; }

  virtual void set_representation(Representation r) { representation_ = r; }

  virtual intptr_t Hashcode() const {
    UNREACHABLE();
    return 0;
  }

  DECLARE_INSTRUCTION(Phi)

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  BitVector* reaching_defs() const { return reaching_defs_; }

  void set_reaching_defs(BitVector* reaching_defs) {
    reaching_defs_ = reaching_defs;
  }

  virtual bool MayThrow() const { return false; }

  // A phi is redundant if all input operands are the same.
  bool IsRedundant() const;

  void set_induction_variable_info(InductionVariableInfo* info) {
    loop_variable_info_ = info;
  }

  InductionVariableInfo* induction_variable_info() {
    return loop_variable_info_;
  }

  PRINT_TO_SUPPORT

  enum ReceiverType { kUnknownReceiver = -1, kNotReceiver = 0, kReceiver = 1 };

  ReceiverType is_receiver() const {
    return static_cast<ReceiverType>(is_receiver_);
  }

  void set_is_receiver(ReceiverType is_receiver) { is_receiver_ = is_receiver; }

 private:
  // Direct access to inputs_ in order to resize it due to unreachable
  // predecessors.
  friend class ConstantPropagator;

  void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }

  JoinEntryInstr* block_;
  GrowableArray<Value*> inputs_;
  Representation representation_;
  BitVector* reaching_defs_;
  InductionVariableInfo* loop_variable_info_;
  bool is_alive_;
  int8_t is_receiver_;

  DISALLOW_COPY_AND_ASSIGN(PhiInstr);
};

class ParameterInstr : public Definition {
 public:
  ParameterInstr(intptr_t index,
                 BlockEntryInstr* block,
                 Register base_reg = FPREG)
      : index_(index), base_reg_(base_reg), block_(block) {}

  DECLARE_INSTRUCTION(Parameter)

  intptr_t index() const { return index_; }
  Register base_reg() const { return base_reg_; }

  // Get the block entry for that instruction.
  virtual BlockEntryInstr* GetBlock() { return block_; }

  intptr_t InputCount() const { return 0; }
  Value* InputAt(intptr_t i) const {
    UNREACHABLE();
    return NULL;
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual intptr_t Hashcode() const {
    UNREACHABLE();
    return 0;
  }

  virtual CompileType ComputeType() const;

  virtual bool MayThrow() const { return false; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  const intptr_t index_;
  const Register base_reg_;
  BlockEntryInstr* block_;

  DISALLOW_COPY_AND_ASSIGN(ParameterInstr);
};

class PushArgumentInstr : public TemplateDefinition<1, NoThrow> {
 public:
  explicit PushArgumentInstr(Value* value) { SetInputAt(0, value); }

  DECLARE_INSTRUCTION(PushArgument)

  virtual CompileType ComputeType() const;

  Value* value() const { return InputAt(0); }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual TokenPosition token_pos() const {
    return TokenPosition::kPushArgument;
  }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  DISALLOW_COPY_AND_ASSIGN(PushArgumentInstr);
};

inline Definition* Instruction::ArgumentAt(intptr_t index) const {
  return PushArgumentAt(index)->value()->definition();
}

class ReturnInstr : public TemplateInstruction<1, NoThrow> {
 public:
  ReturnInstr(TokenPosition token_pos, Value* value, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Return)

  virtual TokenPosition token_pos() const { return token_pos_; }
  Value* value() const { return inputs_[0]; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Return instruction might turn into a Goto instruction after inlining.
    // Every Goto must have an environment.
    return true;
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ReturnInstr);
};

class ThrowInstr : public TemplateInstruction<0, Throws> {
 public:
  explicit ThrowInstr(TokenPosition token_pos, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), token_pos_(token_pos) {}

  DECLARE_INSTRUCTION(Throw)

  virtual intptr_t ArgumentCount() const { return 1; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ThrowInstr);
};

class ReThrowInstr : public TemplateInstruction<0, Throws> {
 public:
  // 'catch_try_index' can be CatchClauseNode::kInvalidTryIndex if the
  // rethrow has been artificially generated by the parser.
  ReThrowInstr(TokenPosition token_pos,
               intptr_t catch_try_index,
               intptr_t deopt_id)
      : TemplateInstruction(deopt_id),
        token_pos_(token_pos),
        catch_try_index_(catch_try_index) {}

  DECLARE_INSTRUCTION(ReThrow)

  virtual intptr_t ArgumentCount() const { return 2; }

  virtual TokenPosition token_pos() const { return token_pos_; }
  intptr_t catch_try_index() const { return catch_try_index_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const TokenPosition token_pos_;
  const intptr_t catch_try_index_;

  DISALLOW_COPY_AND_ASSIGN(ReThrowInstr);
};

class StopInstr : public TemplateInstruction<0, NoThrow> {
 public:
  explicit StopInstr(const char* message) : message_(message) {
    ASSERT(message != NULL);
  }

  const char* message() const { return message_; }

  DECLARE_INSTRUCTION(Stop);

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const char* message_;

  DISALLOW_COPY_AND_ASSIGN(StopInstr);
};

class GotoInstr : public TemplateInstruction<0, NoThrow> {
 public:
  explicit GotoInstr(JoinEntryInstr* entry, intptr_t deopt_id)
      : TemplateInstruction(deopt_id),
        block_(NULL),
        successor_(entry),
        edge_weight_(0.0),
        parallel_move_(NULL) {}

  DECLARE_INSTRUCTION(Goto)

  BlockEntryInstr* block() const { return block_; }
  void set_block(BlockEntryInstr* block) { block_ = block; }

  JoinEntryInstr* successor() const { return successor_; }
  void set_successor(JoinEntryInstr* successor) { successor_ = successor; }
  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  double edge_weight() const { return edge_weight_; }
  void set_edge_weight(double weight) { edge_weight_ = weight; }
  void adjust_edge_weight(double scale_factor) { edge_weight_ *= scale_factor; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Goto instruction can be used as a deoptimization target when LICM
    // hoists instructions out of the loop.
    return true;
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  ParallelMoveInstr* parallel_move() const { return parallel_move_; }

  bool HasParallelMove() const { return parallel_move_ != NULL; }

  bool HasNonRedundantParallelMove() const {
    return HasParallelMove() && !parallel_move()->IsRedundant();
  }

  ParallelMoveInstr* GetParallelMove() {
    if (parallel_move_ == NULL) {
      parallel_move_ = new ParallelMoveInstr();
    }
    return parallel_move_;
  }

  virtual TokenPosition token_pos() const {
    return TokenPosition::kControlFlow;
  }

  PRINT_TO_SUPPORT

 private:
  BlockEntryInstr* block_;
  JoinEntryInstr* successor_;
  double edge_weight_;

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the end of the block and resolve phis.
  ParallelMoveInstr* parallel_move_;
};

// IndirectGotoInstr represents a dynamically computed jump. Only
// IndirectEntryInstr targets are valid targets of an indirect goto. The
// concrete target to jump to is given as a parameter to the indirect goto.
//
// In order to preserve split-edge form, an indirect goto does not itself point
// to its targets. Instead, for each possible target, the successors_ field
// will contain an ordinary goto instruction that jumps to the target.
// TODO(zerny): Implement direct support instead of embedding gotos.
//
// Byte offsets of all possible targets are stored in the offsets_ array. The
// desired offset is looked up while the generated code is executing, and passed
// to IndirectGoto as an input.
class IndirectGotoInstr : public TemplateInstruction<1, NoThrow> {
 public:
  IndirectGotoInstr(TypedData* offsets, Value* offset_from_start)
      : offsets_(*offsets) {
    SetInputAt(0, offset_from_start);
  }

  DECLARE_INSTRUCTION(IndirectGoto)

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kNoRepresentation;
  }

  virtual intptr_t ArgumentCount() const { return 0; }

  void AddSuccessor(TargetEntryInstr* successor) {
    ASSERT(successor->next()->IsGoto());
    ASSERT(successor->next()->AsGoto()->successor()->IsIndirectEntry());
    successors_.Add(successor);
  }

  virtual intptr_t SuccessorCount() const { return successors_.length(); }
  virtual TargetEntryInstr* SuccessorAt(intptr_t index) const {
    ASSERT(index < SuccessorCount());
    return successors_[index];
  }

  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool CanBecomeDeoptimizationTarget() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  Value* offset() const { return inputs_[0]; }
  void ComputeOffsetTable();

  PRINT_TO_SUPPORT

 private:
  GrowableArray<TargetEntryInstr*> successors_;
  TypedData& offsets_;
};

class ComparisonInstr : public Definition {
 public:
  Value* left() const { return InputAt(0); }
  Value* right() const { return InputAt(1); }

  virtual TokenPosition token_pos() const { return token_pos_; }
  Token::Kind kind() const { return kind_; }

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right) = 0;

  // Emits instructions to do the comparison and branch to the true or false
  // label depending on the result.  This implementation will call
  // EmitComparisonCode and then generate the branch instructions afterwards.
  virtual void EmitBranchCode(FlowGraphCompiler* compiler, BranchInstr* branch);

  // Used by EmitBranchCode and EmitNativeCode depending on whether the boolean
  // is to be turned into branches or instantiated.  May return a valid
  // condition in which case the caller is expected to emit a branch to the
  // true label based on that condition (or a branch to the false label on the
  // opposite condition).  May also branch directly to the labels.
  virtual Condition EmitComparisonCode(FlowGraphCompiler* compiler,
                                       BranchLabels labels) = 0;

#if defined(TARGET_ARCH_DBC)
  // On the DBC platform EmitNativeCode needs to know ahead of time what
  // 'Condition' will be returned by EmitComparisonCode. This call must return
  // the same result as EmitComparisonCode, but should not emit any
  // instructions.
  virtual Condition GetNextInstructionCondition(FlowGraphCompiler* compiler,
                                                BranchLabels labels) = 0;
#endif

  // Emits code that generates 'true' or 'false', depending on the comparison.
  // This implementation will call EmitComparisonCode.  If EmitComparisonCode
  // does not use the labels (merely returning a condition) then EmitNativeCode
  // may be able to use the condition to avoid a branch.
  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  void SetDeoptId(const Instruction& instr) { CopyDeoptIdFrom(instr); }

  // Operation class id is computed from collected ICData.
  void set_operation_cid(intptr_t value) { operation_cid_ = value; }
  intptr_t operation_cid() const { return operation_cid_; }

  virtual void NegateComparison() { kind_ = Token::NegateComparison(kind_); }

  virtual bool CanBecomeDeoptimizationTarget() const { return true; }
  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual bool AttributesEqual(Instruction* other) const {
    ComparisonInstr* other_comparison = other->AsComparison();
    return kind() == other_comparison->kind() &&
           (operation_cid() == other_comparison->operation_cid());
  }

  DEFINE_INSTRUCTION_TYPE_CHECK(Comparison)

 protected:
  ComparisonInstr(TokenPosition token_pos,
                  Token::Kind kind,
                  intptr_t deopt_id = Thread::kNoDeoptId)
      : Definition(deopt_id),
        token_pos_(token_pos),
        kind_(kind),
        operation_cid_(kIllegalCid) {}

 private:
  const TokenPosition token_pos_;
  Token::Kind kind_;
  intptr_t operation_cid_;  // Set by optimizer.

  DISALLOW_COPY_AND_ASSIGN(ComparisonInstr);
};

class PureComparison : public ComparisonInstr {
 public:
  virtual bool AllowsCSE() const { return true; }
  virtual bool HasUnknownSideEffects() const { return false; }

 protected:
  PureComparison(TokenPosition token_pos, Token::Kind kind, intptr_t deopt_id)
      : ComparisonInstr(token_pos, kind, deopt_id) {}
};

template <intptr_t N,
          typename ThrowsTrait,
          template <typename Impure, typename Pure> class CSETrait = NoCSE>
class TemplateComparison
    : public CSETrait<ComparisonInstr, PureComparison>::Base {
 public:
  TemplateComparison(TokenPosition token_pos,
                     Token::Kind kind,
                     intptr_t deopt_id = Thread::kNoDeoptId)
      : CSETrait<ComparisonInstr, PureComparison>::Base(token_pos,
                                                        kind,
                                                        deopt_id),
        inputs_() {}

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool MayThrow() const { return ThrowsTrait::kCanThrow; }

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }
};

class BranchInstr : public Instruction {
 public:
  explicit BranchInstr(ComparisonInstr* comparison, intptr_t deopt_id)
      : Instruction(deopt_id), comparison_(comparison), constant_target_(NULL) {
    ASSERT(comparison->env() == NULL);
    for (intptr_t i = comparison->InputCount() - 1; i >= 0; --i) {
      comparison->InputAt(i)->set_instruction(this);
    }
  }

  DECLARE_INSTRUCTION(Branch)

  virtual intptr_t ArgumentCount() const {
    return comparison()->ArgumentCount();
  }

  intptr_t InputCount() const { return comparison()->InputCount(); }

  Value* InputAt(intptr_t i) const { return comparison()->InputAt(i); }

  virtual TokenPosition token_pos() const { return comparison_->token_pos(); }

  virtual bool ComputeCanDeoptimize() const {
    return comparison()->ComputeCanDeoptimize();
  }

  virtual bool CanBecomeDeoptimizationTarget() const {
    return comparison()->CanBecomeDeoptimizationTarget();
  }

  virtual bool HasUnknownSideEffects() const {
    return comparison()->HasUnknownSideEffects();
  }

  ComparisonInstr* comparison() const { return comparison_; }
  void SetComparison(ComparisonInstr* comp);

  virtual intptr_t DeoptimizationTarget() const {
    return comparison()->DeoptimizationTarget();
  }

  virtual Representation RequiredInputRepresentation(intptr_t i) const {
    return comparison()->RequiredInputRepresentation(i);
  }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  void set_constant_target(TargetEntryInstr* target) {
    ASSERT(target == true_successor() || target == false_successor());
    constant_target_ = target;
  }
  TargetEntryInstr* constant_target() const { return constant_target_; }

  virtual void InheritDeoptTarget(Zone* zone, Instruction* other);

  virtual bool MayThrow() const { return comparison()->MayThrow(); }

  TargetEntryInstr* true_successor() const { return true_successor_; }
  TargetEntryInstr* false_successor() const { return false_successor_; }

  TargetEntryInstr** true_successor_address() { return &true_successor_; }
  TargetEntryInstr** false_successor_address() { return &false_successor_; }

  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  PRINT_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    comparison()->RawSetInputAt(i, value);
  }

  TargetEntryInstr* true_successor_;
  TargetEntryInstr* false_successor_;
  ComparisonInstr* comparison_;
  TargetEntryInstr* constant_target_;

  DISALLOW_COPY_AND_ASSIGN(BranchInstr);
};

class DeoptimizeInstr : public TemplateInstruction<0, NoThrow, Pure> {
 public:
  DeoptimizeInstr(ICData::DeoptReasonId deopt_reason, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), deopt_reason_(deopt_reason) {}

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  DECLARE_INSTRUCTION(Deoptimize)

 private:
  const ICData::DeoptReasonId deopt_reason_;

  DISALLOW_COPY_AND_ASSIGN(DeoptimizeInstr);
};

class RedefinitionInstr : public TemplateDefinition<1, NoThrow> {
 public:
  explicit RedefinitionInstr(Value* value) : constrained_type_(NULL) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Redefinition)

  Value* value() const { return inputs_[0]; }

  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  void set_constrained_type(CompileType* type) { constrained_type_ = type; }
  CompileType* constrained_type() const { return constrained_type_; }

  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  CompileType* constrained_type_;
  DISALLOW_COPY_AND_ASSIGN(RedefinitionInstr);
};

class ConstraintInstr : public TemplateDefinition<1, NoThrow> {
 public:
  ConstraintInstr(Value* value, Range* constraint)
      : constraint_(constraint), target_(NULL) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Constraint)

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const {
    UNREACHABLE();
    return false;
  }

  Value* value() const { return inputs_[0]; }
  Range* constraint() const { return constraint_; }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  // Constraints for branches have their target block stored in order
  // to find the comparison that generated the constraint:
  // target->predecessor->last_instruction->comparison.
  void set_target(TargetEntryInstr* target) { target_ = target; }
  TargetEntryInstr* target() const { return target_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  Range* constraint_;
  TargetEntryInstr* target_;

  DISALLOW_COPY_AND_ASSIGN(ConstraintInstr);
};

class ConstantInstr : public TemplateDefinition<0, NoThrow, Pure> {
 public:
  ConstantInstr(const Object& value,
                TokenPosition token_pos = TokenPosition::kConstant);

  DECLARE_INSTRUCTION(Constant)
  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  const Object& value() const { return value_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual bool AttributesEqual(Instruction* other) const;

  virtual TokenPosition token_pos() const { return token_pos_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const Object& value_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ConstantInstr);
};

// Merged ConstantInstr -> UnboxedXXX into UnboxedConstantInstr.
// TODO(srdjan): Implemented currently for doubles only, should implement
// for other unboxing instructions.
class UnboxedConstantInstr : public ConstantInstr {
 public:
  explicit UnboxedConstantInstr(const Object& value,
                                Representation representation);

  virtual Representation representation() const { return representation_; }

  // Either NULL or the address of the unboxed constant.
  uword constant_address() const { return constant_address_; }

  DECLARE_INSTRUCTION(UnboxedConstant)

 private:
  const Representation representation_;
  uword constant_address_;  // Either NULL or points to the untagged constant.

  DISALLOW_COPY_AND_ASSIGN(UnboxedConstantInstr);
};

class AssertAssignableInstr : public TemplateDefinition<3, Throws, Pure> {
 public:
  AssertAssignableInstr(TokenPosition token_pos,
                        Value* value,
                        Value* instantiator_type_arguments,
                        Value* function_type_arguments,
                        const AbstractType& dst_type,
                        const String& dst_name,
                        intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        token_pos_(token_pos),
        dst_type_(AbstractType::ZoneHandle(dst_type.raw())),
        dst_name_(dst_name) {
    ASSERT(!dst_type.IsNull());
    ASSERT(!dst_type.IsTypeRef());
    ASSERT(!dst_name.IsNull());
    SetInputAt(0, value);
    SetInputAt(1, instantiator_type_arguments);
    SetInputAt(2, function_type_arguments);
  }

  DECLARE_INSTRUCTION(AssertAssignable)
  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  Value* value() const { return inputs_[0]; }
  Value* instantiator_type_arguments() const { return inputs_[1]; }
  Value* function_type_arguments() const { return inputs_[2]; }

  virtual TokenPosition token_pos() const { return token_pos_; }
  const AbstractType& dst_type() const { return dst_type_; }
  void set_dst_type(const AbstractType& dst_type) {
    ASSERT(!dst_type.IsTypeRef());
    dst_type_ = dst_type.raw();
  }
  const String& dst_name() const { return dst_name_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // AssertAssignable instructions that are specialized by the optimizer
    // (e.g. replaced with CheckClass) need a deoptimization descriptor before.
    return true;
  }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const;

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  AbstractType& dst_type_;
  const String& dst_name_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableInstr);
};

class AssertBooleanInstr : public TemplateDefinition<1, Throws, Pure> {
 public:
  AssertBooleanInstr(TokenPosition token_pos, Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(AssertBoolean)
  virtual CompileType ComputeType() const;

  virtual TokenPosition token_pos() const { return token_pos_; }
  Value* value() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(AssertBooleanInstr);
};

// Denotes a special parameter, currently either the context of a closure
// or the type arguments of a generic function.
class SpecialParameterInstr : public TemplateDefinition<0, NoThrow> {
 public:
  enum SpecialParameterKind { kContext, kTypeArgs };
  SpecialParameterInstr(SpecialParameterKind kind, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), kind_(kind) {}

  DECLARE_INSTRUCTION(SpecialParameter)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const {
    return kind() == other->AsSpecialParameter()->kind();
  }
  SpecialParameterKind kind() const { return kind_; }

 private:
  const SpecialParameterKind kind_;
  DISALLOW_COPY_AND_ASSIGN(SpecialParameterInstr);
};

struct ArgumentsInfo {
  ArgumentsInfo(intptr_t type_args_len,
                intptr_t count_with_type_args,
                const Array& argument_names)
      : type_args_len(type_args_len),
        count_with_type_args(count_with_type_args),
        count_without_type_args(count_with_type_args -
                                (type_args_len > 0 ? 1 : 0)),
        argument_names(argument_names) {}

  RawArray* ToArgumentsDescriptor() const {
    return ArgumentsDescriptor::New(type_args_len, count_without_type_args,
                                    argument_names);
  }

  const intptr_t type_args_len;
  const intptr_t count_with_type_args;
  const intptr_t count_without_type_args;
  const Array& argument_names;
};

template <intptr_t kInputCount>
class TemplateDartCall : public TemplateDefinition<kInputCount, Throws> {
 public:
  TemplateDartCall(intptr_t deopt_id,
                   intptr_t type_args_len,
                   const Array& argument_names,
                   ZoneGrowableArray<PushArgumentInstr*>* arguments,
                   TokenPosition token_pos)
      : TemplateDefinition<kInputCount, Throws>(deopt_id),
        type_args_len_(type_args_len),
        argument_names_(argument_names),
        arguments_(arguments),
        token_pos_(token_pos) {
    ASSERT(argument_names.IsZoneHandle() || argument_names.InVMHeap());
  }

  intptr_t FirstArgIndex() const { return type_args_len_ > 0 ? 1 : 0; }
  intptr_t ArgumentCountWithoutTypeArgs() const {
    return arguments_->length() - FirstArgIndex();
  }
  // ArgumentCount() includes the type argument vector if any.
  // Caution: Must override Instruction::ArgumentCount().
  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }
  intptr_t type_args_len() const { return type_args_len_; }
  const Array& argument_names() const { return argument_names_; }
  virtual TokenPosition token_pos() const { return token_pos_; }
  RawArray* GetArgumentsDescriptor() const {
    return ArgumentsDescriptor::New(
        type_args_len(), ArgumentCountWithoutTypeArgs(), argument_names());
  }

 private:
  intptr_t type_args_len_;
  const Array& argument_names_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;
  TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(TemplateDartCall);
};

class ClosureCallInstr : public TemplateDartCall<1> {
 public:
  ClosureCallInstr(Value* function,
                   ClosureCallNode* node,
                   ZoneGrowableArray<PushArgumentInstr*>* arguments,
                   intptr_t deopt_id)
      : TemplateDartCall(deopt_id,
                         node->arguments()->type_args_len(),
                         node->arguments()->names(),
                         arguments,
                         node->token_pos()) {
    ASSERT(!arguments->is_empty());
    SetInputAt(0, function);
  }

  ClosureCallInstr(Value* function,
                   ZoneGrowableArray<PushArgumentInstr*>* arguments,
                   intptr_t type_args_len,
                   const Array& argument_names,
                   TokenPosition token_pos,
                   intptr_t deopt_id)
      : TemplateDartCall(deopt_id,
                         type_args_len,
                         argument_names,
                         arguments,
                         token_pos) {
    ASSERT(!arguments->is_empty());
    SetInputAt(0, function);
  }

  DECLARE_INSTRUCTION(ClosureCall)

  // TODO(kmillikin): implement exact call counts for closure calls.
  virtual intptr_t CallCount() const { return 1; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  DISALLOW_COPY_AND_ASSIGN(ClosureCallInstr);
};

class InstanceCallInstr : public TemplateDartCall<0> {
 public:
  InstanceCallInstr(
      TokenPosition token_pos,
      const String& function_name,
      Token::Kind token_kind,
      ZoneGrowableArray<PushArgumentInstr*>* arguments,
      intptr_t type_args_len,
      const Array& argument_names,
      intptr_t checked_argument_count,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t deopt_id,
      const Function& interface_target = Function::null_function())
      : TemplateDartCall(deopt_id,
                         type_args_len,
                         argument_names,
                         arguments,
                         token_pos),
        ic_data_(NULL),
        function_name_(function_name),
        token_kind_(token_kind),
        checked_argument_count_(checked_argument_count),
        interface_target_(interface_target),
        has_unique_selector_(false) {
    ic_data_ = GetICData(ic_data_array);
    ASSERT(function_name.IsNotTemporaryScopedHandle());
    ASSERT(interface_target_.IsNotTemporaryScopedHandle());
    ASSERT(!arguments->is_empty());
    ASSERT(Token::IsBinaryOperator(token_kind) ||
           Token::IsEqualityOperator(token_kind) ||
           Token::IsRelationalOperator(token_kind) ||
           Token::IsUnaryOperator(token_kind) ||
           Token::IsIndexOperator(token_kind) ||
           Token::IsTypeTestOperator(token_kind) ||
           Token::IsTypeCastOperator(token_kind) || token_kind == Token::kGET ||
           token_kind == Token::kSET || token_kind == Token::kILLEGAL);
  }

  DECLARE_INSTRUCTION(InstanceCall)

  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const { return (ic_data() != NULL) && !ic_data()->IsNull(); }

  // ICData can be replaced by optimizer.
  void set_ic_data(const ICData* value) { ic_data_ = value; }

  const String& function_name() const { return function_name_; }
  Token::Kind token_kind() const { return token_kind_; }
  intptr_t checked_argument_count() const { return checked_argument_count_; }
  const Function& interface_target() const { return interface_target_; }

  bool has_unique_selector() const { return has_unique_selector_; }
  void set_has_unique_selector(bool b) { has_unique_selector_ = b; }

  virtual intptr_t CallCount() const {
    return ic_data() == NULL ? 0 : ic_data()->AggregateCount();
  }

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Instance calls that are specialized by the optimizer need a
    // deoptimization descriptor before the call.
    return true;
  }

  virtual bool HasUnknownSideEffects() const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

  bool MatchesCoreName(const String& name);

  RawFunction* ResolveForReceiverClass(const Class& cls, bool allow_add = true);

 protected:
  friend class CallSpecializer;
  void set_ic_data(ICData* value) { ic_data_ = value; }

 private:
  const ICData* ic_data_;
  const String& function_name_;
  const Token::Kind token_kind_;  // Binary op, unary op, kGET or kILLEGAL.
  const intptr_t checked_argument_count_;
  const Function& interface_target_;
  bool has_unique_selector_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallInstr);
};

class PolymorphicInstanceCallInstr : public TemplateDefinition<0, Throws> {
 public:
  PolymorphicInstanceCallInstr(InstanceCallInstr* instance_call,
                               const CallTargets& targets,
                               bool complete)
      : TemplateDefinition(instance_call->deopt_id()),
        instance_call_(instance_call),
        targets_(targets),
        complete_(complete) {
    ASSERT(instance_call_ != NULL);
    ASSERT(targets.length() != 0);
    total_call_count_ = CallCount();
  }

  InstanceCallInstr* instance_call() const { return instance_call_; }
  bool complete() const { return complete_; }
  virtual TokenPosition token_pos() const {
    return instance_call_->token_pos();
  }

  virtual CompileType ComputeType() const;

  virtual intptr_t ArgumentCount() const {
    return instance_call()->ArgumentCount();
  }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return instance_call()->PushArgumentAt(index);
  }
  const Array& argument_names() const {
    return instance_call()->argument_names();
  }
  intptr_t type_args_len() const { return instance_call()->type_args_len(); }

  bool HasOnlyDispatcherOrImplicitAccessorTargets() const;

  const CallTargets& targets() const { return targets_; }
  intptr_t NumberOfChecks() const { return targets_.length(); }

  bool IsSureToCallSingleRecognizedTarget() const;

  virtual intptr_t CallCount() const;

  // If this polymophic call site was created to cover the remaining cids after
  // inlining then we need to keep track of the total number of calls including
  // the ones that we inlined. This is different from the CallCount above:  Eg
  // if there were 100 calls originally, distributed across three class-ids in
  // the ratio 50, 40, 7, 3.  The first two were inlined, so now we have only
  // 10 calls in the CallCount above, but the heuristics need to know that the
  // last two cids cover 7% and 3% of the calls, not 70% and 30%.
  intptr_t total_call_count() { return total_call_count_; }

  void set_total_call_count(intptr_t count) { total_call_count_ = count; }

  DECLARE_INSTRUCTION(PolymorphicInstanceCall)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* graph);

  static RawType* ComputeRuntimeType(const CallTargets& targets);

  PRINT_OPERANDS_TO_SUPPORT

 private:
  InstanceCallInstr* instance_call_;
  const CallTargets& targets_;
  const bool complete_;
  intptr_t total_call_count_;

  friend class PolymorphicInliner;

  DISALLOW_COPY_AND_ASSIGN(PolymorphicInstanceCallInstr);
};

class StrictCompareInstr : public TemplateComparison<2, NoThrow, Pure> {
 public:
  StrictCompareInstr(TokenPosition token_pos,
                     Token::Kind kind,
                     Value* left,
                     Value* right,
                     bool needs_number_check,
                     intptr_t deopt_id);

  DECLARE_COMPARISON_INSTRUCTION(StrictCompare)

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  bool needs_number_check() const { return needs_number_check_; }
  void set_needs_number_check(bool value) { needs_number_check_ = value; }

  bool AttributesEqual(Instruction* other) const;

  PRINT_OPERANDS_TO_SUPPORT

 private:
  // True if the comparison must check for double, Mint or Bigint and
  // use value comparison instead.
  bool needs_number_check_;

  DISALLOW_COPY_AND_ASSIGN(StrictCompareInstr);
};

// Comparison instruction that is equivalent to the (left & right) == 0
// comparison pattern.
class TestSmiInstr : public TemplateComparison<2, NoThrow, Pure> {
 public:
  TestSmiInstr(TokenPosition token_pos,
               Token::Kind kind,
               Value* left,
               Value* right)
      : TemplateComparison(token_pos, kind) {
    ASSERT(kind == Token::kEQ || kind == Token::kNE);
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  DECLARE_COMPARISON_INSTRUCTION(TestSmi);

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    return kTagged;
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TestSmiInstr);
};

// Checks the input value cid against cids stored in a table and returns either
// a result or deoptimizes.  If the cid is not in the list and there is a deopt
// id, then the instruction deoptimizes.  If there is no deopt id, all the
// results must be the same (all true or all false) and the instruction returns
// the opposite for cids not on the list.  The first element in the table must
// always be the result for the Smi class-id and is allowed to differ from the
// other results even in the no-deopt case.
class TestCidsInstr : public TemplateComparison<1, NoThrow, Pure> {
 public:
  TestCidsInstr(TokenPosition token_pos,
                Token::Kind kind,
                Value* value,
                const ZoneGrowableArray<intptr_t>& cid_results,
                intptr_t deopt_id);

  const ZoneGrowableArray<intptr_t>& cid_results() const {
    return cid_results_;
  }

  DECLARE_COMPARISON_INSTRUCTION(TestCids);

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool ComputeCanDeoptimize() const {
    return GetDeoptId() != Thread::kNoDeoptId;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    return kTagged;
  }

  virtual bool AttributesEqual(Instruction* other) const;

  void set_licm_hoisted(bool value) { licm_hoisted_ = value; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const ZoneGrowableArray<intptr_t>& cid_results_;
  bool licm_hoisted_;
  DISALLOW_COPY_AND_ASSIGN(TestCidsInstr);
};

class EqualityCompareInstr : public TemplateComparison<2, NoThrow, Pure> {
 public:
  EqualityCompareInstr(TokenPosition token_pos,
                       Token::Kind kind,
                       Value* left,
                       Value* right,
                       intptr_t cid,
                       intptr_t deopt_id)
      : TemplateComparison(token_pos, kind, deopt_id) {
    ASSERT(Token::IsEqualityOperator(kind));
    SetInputAt(0, left);
    SetInputAt(1, right);
    set_operation_cid(cid);
  }

  DECLARE_COMPARISON_INSTRUCTION(EqualityCompare)

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (operation_cid() == kDoubleCid) return kUnboxedDouble;
    if (operation_cid() == kMintCid) return kUnboxedInt64;
    return kTagged;
  }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  DISALLOW_COPY_AND_ASSIGN(EqualityCompareInstr);
};

class RelationalOpInstr : public TemplateComparison<2, NoThrow, Pure> {
 public:
  RelationalOpInstr(TokenPosition token_pos,
                    Token::Kind kind,
                    Value* left,
                    Value* right,
                    intptr_t cid,
                    intptr_t deopt_id)
      : TemplateComparison(token_pos, kind, deopt_id) {
    ASSERT(Token::IsRelationalOperator(kind));
    SetInputAt(0, left);
    SetInputAt(1, right);
    set_operation_cid(cid);
  }

  DECLARE_COMPARISON_INSTRUCTION(RelationalOp)

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (operation_cid() == kDoubleCid) return kUnboxedDouble;
    if (operation_cid() == kMintCid) return kUnboxedInt64;
    return kTagged;
  }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  DISALLOW_COPY_AND_ASSIGN(RelationalOpInstr);
};

// TODO(vegorov): ComparisonInstr should be switched to use IfTheElseInstr for
// materialization of true and false constants.
class IfThenElseInstr : public Definition {
 public:
  IfThenElseInstr(ComparisonInstr* comparison,
                  Value* if_true,
                  Value* if_false,
                  intptr_t deopt_id)
      : Definition(deopt_id),
        comparison_(comparison),
        if_true_(Smi::Cast(if_true->BoundConstant()).Value()),
        if_false_(Smi::Cast(if_false->BoundConstant()).Value()) {
    // Adjust uses at the comparison.
    ASSERT(comparison->env() == NULL);
    for (intptr_t i = comparison->InputCount() - 1; i >= 0; --i) {
      comparison->InputAt(i)->set_instruction(this);
    }
  }

  // Returns true if this combination of comparison and values flowing on
  // the true and false paths is supported on the current platform.
  static bool Supports(ComparisonInstr* comparison, Value* v1, Value* v2);

  DECLARE_INSTRUCTION(IfThenElse)

  intptr_t InputCount() const { return comparison()->InputCount(); }

  Value* InputAt(intptr_t i) const { return comparison()->InputAt(i); }

  virtual bool ComputeCanDeoptimize() const {
    return comparison()->ComputeCanDeoptimize();
  }

  virtual bool CanBecomeDeoptimizationTarget() const {
    return comparison()->CanBecomeDeoptimizationTarget();
  }

  virtual intptr_t DeoptimizationTarget() const {
    return comparison()->DeoptimizationTarget();
  }

  virtual Representation RequiredInputRepresentation(intptr_t i) const {
    return comparison()->RequiredInputRepresentation(i);
  }

  virtual CompileType ComputeType() const;

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  ComparisonInstr* comparison() const { return comparison_; }
  intptr_t if_true() const { return if_true_; }
  intptr_t if_false() const { return if_false_; }

  virtual bool AllowsCSE() const { return comparison()->AllowsCSE(); }
  virtual bool HasUnknownSideEffects() const {
    return comparison()->HasUnknownSideEffects();
  }

  virtual bool AttributesEqual(Instruction* other) const {
    IfThenElseInstr* other_if_then_else = other->AsIfThenElse();
    return (comparison()->tag() == other_if_then_else->comparison()->tag()) &&
           comparison()->AttributesEqual(other_if_then_else->comparison()) &&
           (if_true_ == other_if_then_else->if_true_) &&
           (if_false_ == other_if_then_else->if_false_);
  }

  virtual bool MayThrow() const { return comparison()->MayThrow(); }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    comparison()->RawSetInputAt(i, value);
  }

  ComparisonInstr* comparison_;
  const intptr_t if_true_;
  const intptr_t if_false_;

  DISALLOW_COPY_AND_ASSIGN(IfThenElseInstr);
};

class StaticCallInstr : public TemplateDartCall<0> {
 public:
  StaticCallInstr(TokenPosition token_pos,
                  const Function& function,
                  intptr_t type_args_len,
                  const Array& argument_names,
                  ZoneGrowableArray<PushArgumentInstr*>* arguments,
                  const ZoneGrowableArray<const ICData*>& ic_data_array,
                  intptr_t deopt_id,
                  ICData::RebindRule rebind_rule)
      : TemplateDartCall(deopt_id,
                         type_args_len,
                         argument_names,
                         arguments,
                         token_pos),
        ic_data_(NULL),
        call_count_(0),
        function_(function),
        rebind_rule_(rebind_rule),
        result_cid_(kDynamicCid),
        is_known_list_constructor_(false),
        identity_(AliasIdentity::Unknown()) {
    ic_data_ = GetICData(ic_data_array);
    ASSERT(function.IsZoneHandle());
    ASSERT(!function.IsNull());
  }

  StaticCallInstr(TokenPosition token_pos,
                  const Function& function,
                  intptr_t type_args_len,
                  const Array& argument_names,
                  ZoneGrowableArray<PushArgumentInstr*>* arguments,
                  intptr_t deopt_id,
                  intptr_t call_count,
                  ICData::RebindRule rebind_rule)
      : TemplateDartCall(deopt_id,
                         type_args_len,
                         argument_names,
                         arguments,
                         token_pos),
        ic_data_(NULL),
        call_count_(call_count),
        function_(function),
        rebind_rule_(rebind_rule),
        result_cid_(kDynamicCid),
        is_known_list_constructor_(false),
        identity_(AliasIdentity::Unknown()) {
    ASSERT(function.IsZoneHandle());
    ASSERT(!function.IsNull());
  }

  // Generate a replacement call instruction for an instance call which
  // has been found to have only one target.
  template <class C>
  static StaticCallInstr* FromCall(Zone* zone,
                                   const C* call,
                                   const Function& target) {
    ZoneGrowableArray<PushArgumentInstr*>* args =
        new (zone) ZoneGrowableArray<PushArgumentInstr*>(call->ArgumentCount());
    for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
      args->Add(call->PushArgumentAt(i));
    }
    return new (zone)
        StaticCallInstr(call->token_pos(), target, call->type_args_len(),
                        call->argument_names(), args, call->deopt_id(),
                        call->CallCount(), ICData::kNoRebind);
  }

  // ICData for static calls carries call count.
  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const { return (ic_data() != NULL) && !ic_data()->IsNull(); }

  void set_ic_data(const ICData* value) { ic_data_ = value; }

  DECLARE_INSTRUCTION(StaticCall)
  virtual CompileType ComputeType() const;
  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  // Accessors forwarded to the AST node.
  const Function& function() const { return function_; }

  virtual intptr_t CallCount() const {
    return ic_data() == NULL ? call_count_ : ic_data()->AggregateCount();
  }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Static calls that are specialized by the optimizer (e.g. sqrt) need a
    // deoptimization descriptor before the call.
    return true;
  }

  virtual bool HasUnknownSideEffects() const { return true; }

  void set_result_cid(intptr_t value) { result_cid_ = value; }

  bool is_known_list_constructor() const { return is_known_list_constructor_; }
  void set_is_known_list_constructor(bool value) {
    is_known_list_constructor_ = value;
  }

  bool IsRecognizedFactory() const { return is_known_list_constructor(); }

  virtual AliasIdentity Identity() const { return identity_; }
  virtual void SetIdentity(AliasIdentity identity) { identity_ = identity; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const ICData* ic_data_;
  const intptr_t call_count_;
  const Function& function_;
  const ICData::RebindRule rebind_rule_;
  intptr_t result_cid_;  // For some library functions we know the result.

  // 'True' for recognized list constructors.
  bool is_known_list_constructor_;

  AliasIdentity identity_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallInstr);
};

class LoadLocalInstr : public TemplateDefinition<0, NoThrow> {
 public:
  LoadLocalInstr(const LocalVariable& local, TokenPosition token_pos)
      : local_(local), is_last_(false), token_pos_(token_pos) {}

  DECLARE_INSTRUCTION(LoadLocal)
  virtual CompileType ComputeType() const;

  const LocalVariable& local() const { return local_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return false;
  }

  void mark_last() { is_last_ = true; }
  bool is_last() const { return is_last_; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const LocalVariable& local_;
  bool is_last_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(LoadLocalInstr);
};

class DropTempsInstr : public Definition {
 public:
  DropTempsInstr(intptr_t num_temps, Value* value)
      : num_temps_(num_temps), value_(NULL) {
    if (value != NULL) {
      SetInputAt(0, value);
    }
  }

  DECLARE_INSTRUCTION(DropTemps)

  virtual intptr_t InputCount() const { return value_ != NULL ? 1 : 0; }
  virtual Value* InputAt(intptr_t i) const {
    ASSERT((value_ != NULL) && (i == 0));
    return value_;
  }

  Value* value() const { return value_; }

  intptr_t num_temps() const { return num_temps_; }

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return false;
  }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return false;
  }

  virtual TokenPosition token_pos() const { return TokenPosition::kTempMove; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { value_ = value; }

  const intptr_t num_temps_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(DropTempsInstr);
};

class StoreLocalInstr : public TemplateDefinition<1, NoThrow> {
 public:
  StoreLocalInstr(const LocalVariable& local,
                  Value* value,
                  TokenPosition token_pos)
      : local_(local), is_dead_(false), is_last_(false), token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(StoreLocal)
  virtual CompileType ComputeType() const;

  const LocalVariable& local() const { return local_; }
  Value* value() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  void mark_dead() { is_dead_ = true; }
  bool is_dead() const { return is_dead_; }

  void mark_last() { is_last_ = true; }
  bool is_last() const { return is_last_; }

  virtual bool HasUnknownSideEffects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return false;
  }

  virtual TokenPosition token_pos() const { return token_pos_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const LocalVariable& local_;
  bool is_dead_;
  bool is_last_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(StoreLocalInstr);
};

class NativeCallInstr : public TemplateDefinition<0, Throws> {
 public:
  explicit NativeCallInstr(NativeBodyNode* node)
      : native_name_(&node->native_c_function_name()),
        function_(&node->function()),
        native_c_function_(NULL),
        is_bootstrap_native_(false),
        link_lazily_(node->link_lazily()),
        token_pos_(node->token_pos()) {}

  NativeCallInstr(const String* name,
                  const Function* function,
                  bool link_lazily,
                  TokenPosition position)
      : native_name_(name),
        function_(function),
        native_c_function_(NULL),
        is_bootstrap_native_(false),
        is_auto_scope_(true),
        link_lazily_(link_lazily),
        token_pos_(position) {}

  DECLARE_INSTRUCTION(NativeCall)

  const String& native_name() const { return *native_name_; }
  const Function& function() const { return *function_; }
  NativeFunction native_c_function() const { return native_c_function_; }
  bool is_bootstrap_native() const { return is_bootstrap_native_; }
  bool is_auto_scope() const { return is_auto_scope_; }
  bool link_lazily() const { return link_lazily_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return true; }

  void SetupNative();

  PRINT_OPERANDS_TO_SUPPORT

 private:
  void set_native_c_function(NativeFunction value) {
    native_c_function_ = value;
  }

  void set_is_bootstrap_native(bool value) { is_bootstrap_native_ = value; }
  void set_is_auto_scope(bool value) { is_auto_scope_ = value; }

  const String* native_name_;
  const Function* function_;
  NativeFunction native_c_function_;
  bool is_bootstrap_native_;
  bool is_auto_scope_;
  bool link_lazily_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallInstr);
};

class DebugStepCheckInstr : public TemplateInstruction<0, NoThrow> {
 public:
  DebugStepCheckInstr(TokenPosition token_pos,
                      RawPcDescriptors::Kind stub_kind,
                      intptr_t deopt_id)
      : TemplateInstruction<0, NoThrow>(deopt_id),
        token_pos_(token_pos),
        stub_kind_(stub_kind) {}

  DECLARE_INSTRUCTION(DebugStepCheck)

  virtual TokenPosition token_pos() const { return token_pos_; }
  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool HasUnknownSideEffects() const { return true; }
  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

 private:
  const TokenPosition token_pos_;
  const RawPcDescriptors::Kind stub_kind_;

  DISALLOW_COPY_AND_ASSIGN(DebugStepCheckInstr);
};

enum StoreBarrierType { kNoStoreBarrier, kEmitStoreBarrier };

class StoreInstanceFieldInstr : public TemplateDefinition<2, NoThrow> {
 public:
  StoreInstanceFieldInstr(const Field& field,
                          Value* instance,
                          Value* value,
                          StoreBarrierType emit_store_barrier,
                          TokenPosition token_pos)
      : field_(field),
        offset_in_bytes_(field.Offset()),
        emit_store_barrier_(emit_store_barrier),
        token_pos_(token_pos),
        is_initialization_(false) {
    SetInputAt(kInstancePos, instance);
    SetInputAt(kValuePos, value);
    CheckField(field);
  }

  StoreInstanceFieldInstr(intptr_t offset_in_bytes,
                          Value* instance,
                          Value* value,
                          StoreBarrierType emit_store_barrier,
                          TokenPosition token_pos)
      : field_(Field::ZoneHandle()),
        offset_in_bytes_(offset_in_bytes),
        emit_store_barrier_(emit_store_barrier),
        token_pos_(token_pos),
        is_initialization_(false) {
    SetInputAt(kInstancePos, instance);
    SetInputAt(kValuePos, value);
  }

  DECLARE_INSTRUCTION(StoreInstanceField)

  void set_is_initialization(bool value) { is_initialization_ = value; }

  enum { kInstancePos = 0, kValuePos = 1 };

  Value* instance() const { return inputs_[kInstancePos]; }
  Value* value() const { return inputs_[kValuePos]; }
  bool is_initialization() const { return is_initialization_; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  const Field& field() const { return field_; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

  bool ShouldEmitStoreBarrier() const {
    return value()->NeedsStoreBuffer() &&
           (emit_store_barrier_ == kEmitStoreBarrier);
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  // May require a deoptimization target for input conversions.
  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  // Currently CSE/LICM don't operate on any instructions that can be affected
  // by stores/loads. LoadOptimizer handles loads separately. Hence stores
  // are marked as having no side-effects.
  virtual bool HasUnknownSideEffects() const { return false; }

  bool IsUnboxedStore() const;

  bool IsPotentialUnboxedStore() const;

  virtual Representation RequiredInputRepresentation(intptr_t index) const;

  PRINT_OPERANDS_TO_SUPPORT

 private:
  friend class JitCallSpecializer;  // For ASSERT(initialization_).

  bool CanValueBeSmi() const {
    const intptr_t cid = value()->Type()->ToNullableCid();
    // Write barrier is skipped for nullable and non-nullable smis.
    ASSERT(cid != kSmiCid);
    return (cid == kDynamicCid);
  }

  const Field& field_;
  intptr_t offset_in_bytes_;
  const StoreBarrierType emit_store_barrier_;
  const TokenPosition token_pos_;
  // Marks initializing stores. E.g. in the constructor.
  bool is_initialization_;

  DISALLOW_COPY_AND_ASSIGN(StoreInstanceFieldInstr);
};

class GuardFieldInstr : public TemplateInstruction<1, NoThrow, Pure> {
 public:
  GuardFieldInstr(Value* value, const Field& field, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), field_(field) {
    SetInputAt(0, value);
    CheckField(field);
  }

  Value* value() const { return inputs_[0]; }

  const Field& field() const { return field_; }

  virtual bool ComputeCanDeoptimize() const { return true; }
  virtual bool CanBecomeDeoptimizationTarget() const {
    // Ensure that we record kDeopt PC descriptor in unoptimized code.
    return true;
  }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(GuardFieldInstr);
};

class GuardFieldClassInstr : public GuardFieldInstr {
 public:
  GuardFieldClassInstr(Value* value, const Field& field, intptr_t deopt_id)
      : GuardFieldInstr(value, field, deopt_id) {
    CheckField(field);
  }

  DECLARE_INSTRUCTION(GuardFieldClass)

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(GuardFieldClassInstr);
};

class GuardFieldLengthInstr : public GuardFieldInstr {
 public:
  GuardFieldLengthInstr(Value* value, const Field& field, intptr_t deopt_id)
      : GuardFieldInstr(value, field, deopt_id) {
    CheckField(field);
  }

  DECLARE_INSTRUCTION(GuardFieldLength)

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(GuardFieldLengthInstr);
};

class LoadStaticFieldInstr : public TemplateDefinition<1, NoThrow> {
 public:
  LoadStaticFieldInstr(Value* field_value, TokenPosition token_pos)
      : token_pos_(token_pos) {
    ASSERT(field_value->BindsToConstant());
    SetInputAt(0, field_value);
  }

  DECLARE_INSTRUCTION(LoadStaticField)
  virtual CompileType ComputeType() const;

  const Field& StaticField() const;

  Value* field_value() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AllowsCSE() const {
    return StaticField().is_final() && !FLAG_fields_may_be_reset;
  }
  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const;

  virtual TokenPosition token_pos() const { return token_pos_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(LoadStaticFieldInstr);
};

class StoreStaticFieldInstr : public TemplateDefinition<1, NoThrow> {
 public:
  StoreStaticFieldInstr(const Field& field,
                        Value* value,
                        TokenPosition token_pos)
      : field_(field), token_pos_(token_pos) {
    ASSERT(field.IsZoneHandle());
    SetInputAt(kValuePos, value);
    CheckField(field);
  }

  enum { kValuePos = 0 };

  DECLARE_INSTRUCTION(StoreStaticField)

  const Field& field() const { return field_; }
  Value* value() const { return inputs_[kValuePos]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  // Currently CSE/LICM don't operate on any instructions that can be affected
  // by stores/loads. LoadOptimizer handles loads separately. Hence stores
  // are marked as having no side-effects.
  virtual bool HasUnknownSideEffects() const { return false; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  bool CanValueBeSmi() const {
    const intptr_t cid = value()->Type()->ToNullableCid();
    // Write barrier is skipped for nullable and non-nullable smis.
    ASSERT(cid != kSmiCid);
    return (cid == kDynamicCid);
  }

  const Field& field_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(StoreStaticFieldInstr);
};

enum AlignmentType {
  kUnalignedAccess,
  kAlignedAccess,
};

class LoadIndexedInstr : public TemplateDefinition<2, NoThrow> {
 public:
  LoadIndexedInstr(Value* array,
                   Value* index,
                   intptr_t index_scale,
                   intptr_t class_id,
                   AlignmentType alignment,
                   intptr_t deopt_id,
                   TokenPosition token_pos);

  TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(LoadIndexed)
  virtual CompileType ComputeType() const;

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0 || idx == 1);
    // The array may be tagged or untagged (for external arrays).
    if (idx == 0) return kNoRepresentation;
    return kTagged;
  }

  bool IsExternal() const {
    return array()->definition()->representation() == kUntagged;
  }

  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }
  intptr_t index_scale() const { return index_scale_; }
  intptr_t class_id() const { return class_id_; }
  bool aligned() const { return alignment_ == kAlignedAccess; }

  virtual bool ComputeCanDeoptimize() const {
    return GetDeoptId() != Thread::kNoDeoptId;
  }

  virtual Representation representation() const;
  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const intptr_t index_scale_;
  const intptr_t class_id_;
  const AlignmentType alignment_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(LoadIndexedInstr);
};

// Loads the specified number of code units from the given string, packing
// multiple code units into a single datatype. In essence, this is a specialized
// version of LoadIndexedInstr which accepts only string targets and can load
// multiple elements at once. The result datatype differs depending on the
// string type, element count, and architecture; if possible, the result is
// packed into a Smi, falling back to a Mint otherwise.
// TODO(zerny): Add support for loading into UnboxedInt32x4.
class LoadCodeUnitsInstr : public TemplateDefinition<2, NoThrow> {
 public:
  LoadCodeUnitsInstr(Value* str,
                     Value* index,
                     intptr_t element_count,
                     intptr_t class_id,
                     TokenPosition token_pos)
      : class_id_(class_id),
        token_pos_(token_pos),
        element_count_(element_count),
        representation_(kTagged) {
    ASSERT(element_count == 1 || element_count == 2 || element_count == 4);
    ASSERT(RawObject::IsStringClassId(class_id));
    SetInputAt(0, str);
    SetInputAt(1, index);
  }

  TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(LoadCodeUnits)
  virtual CompileType ComputeType() const;

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    if (idx == 0) {
      // The string may be tagged or untagged (for external strings).
      return kNoRepresentation;
    }
    ASSERT(idx == 1);
    return kTagged;
  }

  bool IsExternal() const {
    return array()->definition()->representation() == kUntagged;
  }

  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }
  intptr_t index_scale() const { return Instance::ElementSizeFor(class_id_); }
  intptr_t class_id() const { return class_id_; }
  intptr_t element_count() const { return element_count_; }

  bool can_pack_into_smi() const {
    return element_count() <= kSmiBits / (index_scale() * kBitsPerByte);
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return representation_; }
  void set_representation(Representation repr) { representation_ = repr; }
  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const intptr_t class_id_;
  const TokenPosition token_pos_;
  const intptr_t element_count_;
  Representation representation_;

  DISALLOW_COPY_AND_ASSIGN(LoadCodeUnitsInstr);
};

class OneByteStringFromCharCodeInstr
    : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  explicit OneByteStringFromCharCodeInstr(Value* char_code) {
    SetInputAt(0, char_code);
  }

  DECLARE_INSTRUCTION(OneByteStringFromCharCode)
  virtual CompileType ComputeType() const;

  Value* char_code() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  DISALLOW_COPY_AND_ASSIGN(OneByteStringFromCharCodeInstr);
};

class StringToCharCodeInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  StringToCharCodeInstr(Value* str, intptr_t cid) : cid_(cid) {
    ASSERT(str != NULL);
    SetInputAt(0, str);
  }

  DECLARE_INSTRUCTION(StringToCharCode)
  virtual CompileType ComputeType() const;

  Value* str() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsStringToCharCode()->cid_ == cid_;
  }

 private:
  const intptr_t cid_;

  DISALLOW_COPY_AND_ASSIGN(StringToCharCodeInstr);
};

class StringInterpolateInstr : public TemplateDefinition<1, Throws> {
 public:
  StringInterpolateInstr(Value* value,
                         TokenPosition token_pos,
                         intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        token_pos_(token_pos),
        function_(Function::ZoneHandle()) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual CompileType ComputeType() const;
  // Issues a static call to Dart code which calls toString on objects.
  virtual bool HasUnknownSideEffects() const { return true; }
  virtual bool ComputeCanDeoptimize() const { return true; }

  const Function& CallFunction() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DECLARE_INSTRUCTION(StringInterpolate)

 private:
  const TokenPosition token_pos_;
  Function& function_;

  DISALLOW_COPY_AND_ASSIGN(StringInterpolateInstr);
};

class StoreIndexedInstr : public TemplateDefinition<3, NoThrow> {
 public:
  StoreIndexedInstr(Value* array,
                    Value* index,
                    Value* value,
                    StoreBarrierType emit_store_barrier,
                    intptr_t index_scale,
                    intptr_t class_id,
                    AlignmentType alignment,
                    intptr_t deopt_id,
                    TokenPosition token_pos);
  DECLARE_INSTRUCTION(StoreIndexed)

  enum { kArrayPos = 0, kIndexPos = 1, kValuePos = 2 };

  Value* array() const { return inputs_[kArrayPos]; }
  Value* index() const { return inputs_[kIndexPos]; }
  Value* value() const { return inputs_[kValuePos]; }

  intptr_t index_scale() const { return index_scale_; }
  intptr_t class_id() const { return class_id_; }
  bool aligned() const { return alignment_ == kAlignedAccess; }

  bool ShouldEmitStoreBarrier() const {
    return value()->NeedsStoreBuffer() &&
           (emit_store_barrier_ == kEmitStoreBarrier);
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const;

  bool IsExternal() const {
    return array()->definition()->representation() == kUntagged;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const StoreBarrierType emit_store_barrier_;
  const intptr_t index_scale_;
  const intptr_t class_id_;
  const AlignmentType alignment_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(StoreIndexedInstr);
};

// Note overrideable, built-in: value ? false : true.
class BooleanNegateInstr : public TemplateDefinition<1, NoThrow> {
 public:
  explicit BooleanNegateInstr(Value* value) { SetInputAt(0, value); }

  DECLARE_INSTRUCTION(BooleanNegate)
  virtual CompileType ComputeType() const;

  Value* value() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

 private:
  DISALLOW_COPY_AND_ASSIGN(BooleanNegateInstr);
};

class InstanceOfInstr : public TemplateDefinition<3, Throws> {
 public:
  InstanceOfInstr(TokenPosition token_pos,
                  Value* value,
                  Value* instantiator_type_arguments,
                  Value* function_type_arguments,
                  const AbstractType& type,
                  intptr_t deopt_id)
      : TemplateDefinition(deopt_id), token_pos_(token_pos), type_(type) {
    ASSERT(!type.IsNull());
    SetInputAt(0, value);
    SetInputAt(1, instantiator_type_arguments);
    SetInputAt(2, function_type_arguments);
  }

  DECLARE_INSTRUCTION(InstanceOf)
  virtual CompileType ComputeType() const;

  Value* value() const { return inputs_[0]; }
  Value* instantiator_type_arguments() const { return inputs_[1]; }
  Value* function_type_arguments() const { return inputs_[2]; }

  const AbstractType& type() const { return type_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  Value* value_;
  Value* type_arguments_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(InstanceOfInstr);
};

class AllocateObjectInstr : public TemplateDefinition<0, NoThrow> {
 public:
  AllocateObjectInstr(TokenPosition token_pos,
                      const Class& cls,
                      ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : token_pos_(token_pos),
        cls_(cls),
        arguments_(arguments),
        identity_(AliasIdentity::Unknown()),
        closure_function_(Function::ZoneHandle()) {
    // Either no arguments or one type-argument and one instantiator.
    ASSERT(arguments->is_empty() || (arguments->length() == 1));
  }

  DECLARE_INSTRUCTION(AllocateObject)
  virtual CompileType ComputeType() const;

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  const Class& cls() const { return cls_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  const Function& closure_function() const { return closure_function_; }
  void set_closure_function(const Function& function) {
    closure_function_ ^= function.raw();
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual AliasIdentity Identity() const { return identity_; }
  virtual void SetIdentity(AliasIdentity identity) { identity_ = identity; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const Class& cls_;
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;
  AliasIdentity identity_;
  Function& closure_function_;

  DISALLOW_COPY_AND_ASSIGN(AllocateObjectInstr);
};

class AllocateUninitializedContextInstr
    : public TemplateDefinition<0, NoThrow> {
 public:
  AllocateUninitializedContextInstr(TokenPosition token_pos,
                                    intptr_t num_context_variables)
      : token_pos_(token_pos),
        num_context_variables_(num_context_variables),
        identity_(AliasIdentity::Unknown()) {}

  DECLARE_INSTRUCTION(AllocateUninitializedContext)
  virtual CompileType ComputeType() const;

  virtual TokenPosition token_pos() const { return token_pos_; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual AliasIdentity Identity() const { return identity_; }
  virtual void SetIdentity(AliasIdentity identity) { identity_ = identity; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const intptr_t num_context_variables_;
  AliasIdentity identity_;

  DISALLOW_COPY_AND_ASSIGN(AllocateUninitializedContextInstr);
};

// This instruction captures the state of the object which had its allocation
// removed during the AllocationSinking pass.
// It does not produce any real code only deoptimization information.
class MaterializeObjectInstr : public Definition {
 public:
  MaterializeObjectInstr(AllocateObjectInstr* allocation,
                         const ZoneGrowableArray<const Object*>& slots,
                         ZoneGrowableArray<Value*>* values)
      : allocation_(allocation),
        cls_(allocation->cls()),
        num_variables_(-1),
        slots_(slots),
        values_(values),
        locations_(NULL),
        visited_for_liveness_(false),
        registers_remapped_(false) {
    ASSERT(slots_.length() == values_->length());
    for (intptr_t i = 0; i < InputCount(); i++) {
      InputAt(i)->set_instruction(this);
      InputAt(i)->set_use_index(i);
    }
  }

  MaterializeObjectInstr(AllocateUninitializedContextInstr* allocation,
                         const ZoneGrowableArray<const Object*>& slots,
                         ZoneGrowableArray<Value*>* values)
      : allocation_(allocation),
        cls_(Class::ZoneHandle(Object::context_class())),
        num_variables_(allocation->num_context_variables()),
        slots_(slots),
        values_(values),
        locations_(NULL),
        visited_for_liveness_(false),
        registers_remapped_(false) {
    ASSERT(slots_.length() == values_->length());
    for (intptr_t i = 0; i < InputCount(); i++) {
      InputAt(i)->set_instruction(this);
      InputAt(i)->set_use_index(i);
    }
  }

  Definition* allocation() const { return allocation_; }
  const Class& cls() const { return cls_; }

  intptr_t num_variables() const { return num_variables_; }

  intptr_t FieldOffsetAt(intptr_t i) const {
    return slots_[i]->IsField() ? Field::Cast(*slots_[i]).Offset()
                                : Smi::Cast(*slots_[i]).Value();
  }

  const Location& LocationAt(intptr_t i) { return locations_[i]; }

  DECLARE_INSTRUCTION(MaterializeObject)

  virtual intptr_t InputCount() const { return values_->length(); }

  virtual Value* InputAt(intptr_t i) const { return (*values_)[i]; }

  // SelectRepresentations pass is run once more while MaterializeObject
  // instructions are still in the graph. To avoid any redundant boxing
  // operations inserted by that pass we should indicate that this
  // instruction can cope with any representation as it is essentially
  // an environment use.
  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(0 <= idx && idx < InputCount());
    return kNoRepresentation;
  }

  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool HasUnknownSideEffects() const { return false; }

  Location* locations() { return locations_; }
  void set_locations(Location* locations) { locations_ = locations; }

  virtual bool MayThrow() const { return false; }

  void RemapRegisters(intptr_t* cpu_reg_slots, intptr_t* fpu_reg_slots);

  bool was_visited_for_liveness() const { return visited_for_liveness_; }
  void mark_visited_for_liveness() { visited_for_liveness_ = true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    (*values_)[i] = value;
  }

  Definition* allocation_;
  const Class& cls_;
  intptr_t num_variables_;
  const ZoneGrowableArray<const Object*>& slots_;
  ZoneGrowableArray<Value*>* values_;
  Location* locations_;

  bool visited_for_liveness_;
  bool registers_remapped_;

  DISALLOW_COPY_AND_ASSIGN(MaterializeObjectInstr);
};

class CreateArrayInstr : public TemplateDefinition<2, Throws> {
 public:
  CreateArrayInstr(TokenPosition token_pos,
                   Value* element_type,
                   Value* num_elements,
                   intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        token_pos_(token_pos),
        identity_(AliasIdentity::Unknown()) {
    SetInputAt(kElementTypePos, element_type);
    SetInputAt(kLengthPos, num_elements);
  }

  enum { kElementTypePos = 0, kLengthPos = 1 };

  DECLARE_INSTRUCTION(CreateArray)
  virtual CompileType ComputeType() const;

  virtual TokenPosition token_pos() const { return token_pos_; }
  Value* element_type() const { return inputs_[kElementTypePos]; }
  Value* num_elements() const { return inputs_[kLengthPos]; }

  // Throw needs environment, which is created only if instruction can
  // deoptimize.
  virtual bool ComputeCanDeoptimize() const { return MayThrow(); }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual AliasIdentity Identity() const { return identity_; }
  virtual void SetIdentity(AliasIdentity identity) { identity_ = identity; }

 private:
  const TokenPosition token_pos_;
  AliasIdentity identity_;

  DISALLOW_COPY_AND_ASSIGN(CreateArrayInstr);
};

// Note: this instruction must not be moved without the indexed access that
// depends on it (e.g. out of loops). GC may cause collect
// the array while the external data-array is still accessed.
// TODO(vegorov) enable LICMing this instruction by ensuring that array itself
// is kept alive.
class LoadUntaggedInstr : public TemplateDefinition<1, NoThrow> {
 public:
  LoadUntaggedInstr(Value* object, intptr_t offset) : offset_(offset) {
    SetInputAt(0, object);
  }

  virtual Representation representation() const { return kUntagged; }
  DECLARE_INSTRUCTION(LoadUntagged)
  virtual CompileType ComputeType() const;

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    // The object may be tagged or untagged (for external objects).
    return kNoRepresentation;
  }

  Value* object() const { return inputs_[0]; }
  intptr_t offset() const { return offset_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  intptr_t offset_;

  DISALLOW_COPY_AND_ASSIGN(LoadUntaggedInstr);
};

class LoadClassIdInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  explicit LoadClassIdInstr(Value* object) { SetInputAt(0, object); }

  virtual Representation representation() const { return kTagged; }
  DECLARE_INSTRUCTION(LoadClassId)
  virtual CompileType ComputeType() const;

  Value* object() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  DISALLOW_COPY_AND_ASSIGN(LoadClassIdInstr);
};

class LoadFieldInstr : public TemplateDefinition<1, NoThrow> {
 public:
  LoadFieldInstr(Value* instance,
                 intptr_t offset_in_bytes,
                 const AbstractType& type,
                 TokenPosition token_pos)
      : offset_in_bytes_(offset_in_bytes),
        type_(type),
        result_cid_(kDynamicCid),
        immutable_(false),
        recognized_kind_(MethodRecognizer::kUnknown),
        field_(NULL),
        token_pos_(token_pos) {
    ASSERT(offset_in_bytes >= 0);
    // May be null if field is not an instance.
    ASSERT(type.IsZoneHandle() || type.IsReadOnlyHandle());
    SetInputAt(0, instance);
  }

  LoadFieldInstr(Value* instance,
                 const Field* field,
                 const AbstractType& type,
                 TokenPosition token_pos,
                 const ParsedFunction* parsed_function)
      : offset_in_bytes_(field->Offset()),
        type_(type),
        result_cid_(kDynamicCid),
        immutable_(false),
        recognized_kind_(MethodRecognizer::kUnknown),
        field_(field),
        token_pos_(token_pos) {
    ASSERT(field->IsZoneHandle());
    // May be null if field is not an instance.
    ASSERT(type.IsZoneHandle() || type.IsReadOnlyHandle());
    SetInputAt(0, instance);

    if (parsed_function != NULL && field->guarded_cid() != kIllegalCid) {
      if (!field->is_nullable() || (field->guarded_cid() == kNullCid)) {
        set_result_cid(field->guarded_cid());
      }
      parsed_function->AddToGuardedFields(field);
    }
  }

  void set_is_immutable(bool value) { immutable_ = value; }

  Value* instance() const { return inputs_[0]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }
  void set_result_cid(intptr_t value) { result_cid_ = value; }
  intptr_t result_cid() const { return result_cid_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  const Field* field() const { return field_; }

  virtual Representation representation() const;

  bool IsUnboxedLoad() const;

  bool IsPotentialUnboxedLoad() const;

  void set_recognized_kind(MethodRecognizer::Kind kind) {
    recognized_kind_ = kind;
  }

  MethodRecognizer::Kind recognized_kind() const { return recognized_kind_; }

  DECLARE_INSTRUCTION(LoadField)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  bool IsImmutableLengthLoad() const;

  // Try evaluating this load against the given constant value of
  // the instance. Returns true if evaluation succeeded and
  // puts result into result.
  // Note: we only evaluate loads when we can ensure that
  // instance has the field.
  bool Evaluate(const Object& instance_value, Object* result);

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  static MethodRecognizer::Kind RecognizedKindFromArrayCid(intptr_t cid);

  static bool IsFixedLengthArrayCid(intptr_t cid);

  virtual bool AllowsCSE() const { return immutable_; }
  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const;

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;
  intptr_t result_cid_;
  bool immutable_;

  MethodRecognizer::Kind recognized_kind_;
  const Field* field_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(LoadFieldInstr);
};

class InstantiateTypeInstr : public TemplateDefinition<2, Throws> {
 public:
  InstantiateTypeInstr(TokenPosition token_pos,
                       const AbstractType& type,
                       Value* instantiator_type_arguments,
                       Value* function_type_arguments,
                       intptr_t deopt_id)
      : TemplateDefinition(deopt_id), token_pos_(token_pos), type_(type) {
    ASSERT(type.IsZoneHandle() || type.IsReadOnlyHandle());
    SetInputAt(0, instantiator_type_arguments);
    SetInputAt(1, function_type_arguments);
  }

  DECLARE_INSTRUCTION(InstantiateType)

  Value* instantiator_type_arguments() const { return inputs_[0]; }
  Value* function_type_arguments() const { return inputs_[1]; }
  const AbstractType& type() const { return type_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(InstantiateTypeInstr);
};

class InstantiateTypeArgumentsInstr : public TemplateDefinition<2, Throws> {
 public:
  InstantiateTypeArgumentsInstr(TokenPosition token_pos,
                                const TypeArguments& type_arguments,
                                const Class& instantiator_class,
                                Value* instantiator_type_arguments,
                                Value* function_type_arguments,
                                intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        token_pos_(token_pos),
        type_arguments_(type_arguments),
        instantiator_class_(instantiator_class) {
    ASSERT(type_arguments.IsZoneHandle());
    SetInputAt(0, instantiator_type_arguments);
    SetInputAt(1, function_type_arguments);
  }

  DECLARE_INSTRUCTION(InstantiateTypeArguments)

  Value* instantiator_type_arguments() const { return inputs_[0]; }
  Value* function_type_arguments() const { return inputs_[1]; }
  const TypeArguments& type_arguments() const { return type_arguments_; }
  const Class& instantiator_class() const { return instantiator_class_; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const TypeArguments& type_arguments_;
  const Class& instantiator_class_;

  DISALLOW_COPY_AND_ASSIGN(InstantiateTypeArgumentsInstr);
};

class AllocateContextInstr : public TemplateDefinition<0, NoThrow> {
 public:
  AllocateContextInstr(TokenPosition token_pos, intptr_t num_context_variables)
      : token_pos_(token_pos), num_context_variables_(num_context_variables) {}

  DECLARE_INSTRUCTION(AllocateContext)
  virtual CompileType ComputeType() const;

  virtual TokenPosition token_pos() const { return token_pos_; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool HasUnknownSideEffects() const { return false; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const intptr_t num_context_variables_;

  DISALLOW_COPY_AND_ASSIGN(AllocateContextInstr);
};

class InitStaticFieldInstr : public TemplateInstruction<1, Throws> {
 public:
  InitStaticFieldInstr(Value* input, const Field& field, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), field_(field) {
    SetInputAt(0, input);
    CheckField(field);
  }

  virtual TokenPosition token_pos() const { return field_.token_pos(); }
  const Field& field() const { return field_; }

  DECLARE_INSTRUCTION(InitStaticField)

  virtual bool ComputeCanDeoptimize() const { return true; }
  virtual bool HasUnknownSideEffects() const { return true; }
  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(InitStaticFieldInstr);
};

class CloneContextInstr : public TemplateDefinition<1, NoThrow> {
 public:
  CloneContextInstr(TokenPosition token_pos,
                    Value* context_value,
                    intptr_t num_context_variables,
                    intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        token_pos_(token_pos),
        num_context_variables_(num_context_variables) {
    SetInputAt(0, context_value);
  }

  static const intptr_t kUnknownContextSize = -1;

  virtual TokenPosition token_pos() const { return token_pos_; }
  Value* context_value() const { return inputs_[0]; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  DECLARE_INSTRUCTION(CloneContext)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  const TokenPosition token_pos_;
  const intptr_t num_context_variables_;

  DISALLOW_COPY_AND_ASSIGN(CloneContextInstr);
};

class CheckEitherNonSmiInstr : public TemplateInstruction<2, NoThrow, Pure> {
 public:
  CheckEitherNonSmiInstr(Value* left, Value* right, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), licm_hoisted_(false) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  DECLARE_INSTRUCTION(CheckEitherNonSmi)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  void set_licm_hoisted(bool value) { licm_hoisted_ = value; }

 private:
  bool licm_hoisted_;

  DISALLOW_COPY_AND_ASSIGN(CheckEitherNonSmiInstr);
};

class Boxing : public AllStatic {
 public:
  static bool Supports(Representation rep) {
    switch (rep) {
      case kUnboxedDouble:
      case kUnboxedFloat32x4:
      case kUnboxedFloat64x2:
      case kUnboxedInt32x4:
      case kUnboxedInt64:
      case kUnboxedInt32:
      case kUnboxedUint32:
        return true;
      default:
        return false;
    }
  }

  static intptr_t ValueOffset(Representation rep) {
    switch (rep) {
      case kUnboxedDouble:
        return Double::value_offset();

      case kUnboxedFloat32x4:
        return Float32x4::value_offset();

      case kUnboxedFloat64x2:
        return Float64x2::value_offset();

      case kUnboxedInt32x4:
        return Int32x4::value_offset();

      case kUnboxedInt64:
        return Mint::value_offset();

      default:
        UNREACHABLE();
        return 0;
    }
  }

  static intptr_t BoxCid(Representation rep) {
    switch (rep) {
      case kUnboxedInt64:
        return kMintCid;
      case kUnboxedDouble:
        return kDoubleCid;
      case kUnboxedFloat32x4:
        return kFloat32x4Cid;
      case kUnboxedFloat64x2:
        return kFloat64x2Cid;
      case kUnboxedInt32x4:
        return kInt32x4Cid;
      default:
        UNREACHABLE();
        return kIllegalCid;
    }
  }
};

class BoxInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  static BoxInstr* Create(Representation from, Value* value);

  Value* value() const { return inputs_[0]; }
  Representation from_representation() const { return from_representation_; }

  DECLARE_INSTRUCTION(Box)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual intptr_t DeoptimizationTarget() const { return Thread::kNoDeoptId; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return from_representation();
  }

  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsBox()->from_representation() == from_representation();
  }

  Definition* Canonicalize(FlowGraph* flow_graph);

  virtual TokenPosition token_pos() const { return TokenPosition::kBox; }

 protected:
  BoxInstr(Representation from_representation, Value* value)
      : from_representation_(from_representation) {
    SetInputAt(0, value);
  }

 private:
  intptr_t ValueOffset() const {
    return Boxing::ValueOffset(from_representation());
  }

  const Representation from_representation_;

  DISALLOW_COPY_AND_ASSIGN(BoxInstr);
};

class BoxIntegerInstr : public BoxInstr {
 public:
  BoxIntegerInstr(Representation representation, Value* value)
      : BoxInstr(representation, value) {}

  virtual bool ValueFitsSmi() const;

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DEFINE_INSTRUCTION_TYPE_CHECK(BoxInteger)

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxIntegerInstr);
};

class BoxInteger32Instr : public BoxIntegerInstr {
 public:
  BoxInteger32Instr(Representation representation, Value* value)
      : BoxIntegerInstr(representation, value) {}

  DECLARE_INSTRUCTION_BACKEND()

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxInteger32Instr);
};

class BoxInt32Instr : public BoxInteger32Instr {
 public:
  explicit BoxInt32Instr(Value* value)
      : BoxInteger32Instr(kUnboxedInt32, value) {}

  DECLARE_INSTRUCTION_NO_BACKEND(BoxInt32)

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxInt32Instr);
};

class BoxUint32Instr : public BoxInteger32Instr {
 public:
  explicit BoxUint32Instr(Value* value)
      : BoxInteger32Instr(kUnboxedUint32, value) {}

  DECLARE_INSTRUCTION_NO_BACKEND(BoxUint32)

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxUint32Instr);
};

class BoxInt64Instr : public BoxIntegerInstr {
 public:
  explicit BoxInt64Instr(Value* value)
      : BoxIntegerInstr(kUnboxedInt64, value) {}

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DECLARE_INSTRUCTION(BoxInt64)

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxInt64Instr);
};

class UnboxInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  static UnboxInstr* Create(Representation to, Value* value, intptr_t deopt_id);

  Value* value() const { return inputs_[0]; }

  virtual bool ComputeCanDeoptimize() const {
    const intptr_t value_cid = value()->Type()->ToCid();
    const intptr_t box_cid = BoxCid();

    if (value_cid == box_cid) {
      return false;
    }

    if (CanConvertSmi() && (value_cid == kSmiCid)) {
      return false;
    }

    if (FLAG_experimental_strong_mode) {
      if ((representation() == kUnboxedDouble) &&
          value()->Type()->IsNullableDouble()) {
        return false;
      }

      if (FLAG_limit_ints_to_64_bits && (representation() == kUnboxedInt64) &&
          value()->Type()->IsNullableInt()) {
        return false;
      }
    }

    return true;
  }

  virtual Representation representation() const { return representation_; }

  DECLARE_INSTRUCTION(Unbox)
  virtual CompileType ComputeType() const;

  virtual bool AttributesEqual(Instruction* other) const {
    return representation() == other->AsUnbox()->representation();
  }

  Definition* Canonicalize(FlowGraph* flow_graph);

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual TokenPosition token_pos() const { return TokenPosition::kBox; }

 protected:
  UnboxInstr(Representation representation, Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), representation_(representation) {
    SetInputAt(0, value);
  }

 private:
  bool CanConvertSmi() const;
  void EmitLoadFromBox(FlowGraphCompiler* compiler);
  void EmitSmiConversion(FlowGraphCompiler* compiler);
  void EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler);
  void EmitLoadFromBoxWithDeopt(FlowGraphCompiler* compiler);

  intptr_t BoxCid() const { return Boxing::BoxCid(representation_); }

  intptr_t ValueOffset() const { return Boxing::ValueOffset(representation_); }

  const Representation representation_;

  DISALLOW_COPY_AND_ASSIGN(UnboxInstr);
};

class UnboxIntegerInstr : public UnboxInstr {
 public:
  enum TruncationMode { kTruncate, kNoTruncation };

  UnboxIntegerInstr(Representation representation,
                    TruncationMode truncation_mode,
                    Value* value,
                    intptr_t deopt_id)
      : UnboxInstr(representation, value, deopt_id),
        is_truncating_(truncation_mode == kTruncate) {}

  bool is_truncating() const { return is_truncating_; }

  virtual CompileType ComputeType() const;

  virtual bool AttributesEqual(Instruction* other) const {
    UnboxIntegerInstr* other_unbox = other->AsUnboxInteger();
    return UnboxInstr::AttributesEqual(other) &&
           (other_unbox->is_truncating_ == is_truncating_);
  }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DEFINE_INSTRUCTION_TYPE_CHECK(UnboxInteger)

  PRINT_OPERANDS_TO_SUPPORT

 private:
  bool is_truncating_;

  DISALLOW_COPY_AND_ASSIGN(UnboxIntegerInstr);
};

class UnboxInteger32Instr : public UnboxIntegerInstr {
 public:
  UnboxInteger32Instr(Representation representation,
                      TruncationMode truncation_mode,
                      Value* value,
                      intptr_t deopt_id)
      : UnboxIntegerInstr(representation, truncation_mode, value, deopt_id) {}

  DECLARE_INSTRUCTION_BACKEND()

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxInteger32Instr);
};

class UnboxUint32Instr : public UnboxInteger32Instr {
 public:
  UnboxUint32Instr(Value* value, intptr_t deopt_id)
      : UnboxInteger32Instr(kUnboxedUint32, kTruncate, value, deopt_id) {
    ASSERT(is_truncating());
  }

  virtual bool ComputeCanDeoptimize() const;

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  DECLARE_INSTRUCTION_NO_BACKEND(UnboxUint32)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxUint32Instr);
};

class UnboxInt32Instr : public UnboxInteger32Instr {
 public:
  UnboxInt32Instr(TruncationMode truncation_mode,
                  Value* value,
                  intptr_t deopt_id)
      : UnboxInteger32Instr(kUnboxedInt32, truncation_mode, value, deopt_id) {}

  virtual bool ComputeCanDeoptimize() const;

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DECLARE_INSTRUCTION_NO_BACKEND(UnboxInt32)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxInt32Instr);
};

class UnboxInt64Instr : public UnboxIntegerInstr {
 public:
  UnboxInt64Instr(Value* value, intptr_t deopt_id)
      : UnboxIntegerInstr(kUnboxedInt64, kNoTruncation, value, deopt_id) {}

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  DECLARE_INSTRUCTION_NO_BACKEND(UnboxInt64)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxInt64Instr);
};

bool Definition::IsMintDefinition() {
  return (Type()->ToCid() == kMintCid) || IsBinaryInt64Op() ||
         IsUnaryInt64Op() || IsShiftInt64Op() || IsBoxInt64() || IsUnboxInt64();
}

class MathUnaryInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  enum MathUnaryKind {
    kIllegal,
    kSqrt,
    kDoubleSquare,
  };
  MathUnaryInstr(MathUnaryKind kind, Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), kind_(kind) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  MathUnaryKind kind() const { return kind_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  DECLARE_INSTRUCTION(MathUnary)
  virtual CompileType ComputeType() const;

  virtual bool AttributesEqual(Instruction* other) const {
    return kind() == other->AsMathUnary()->kind();
  }

  Definition* Canonicalize(FlowGraph* flow_graph);

  static const char* KindToCString(MathUnaryKind kind);

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const MathUnaryKind kind_;

  DISALLOW_COPY_AND_ASSIGN(MathUnaryInstr);
};

// Calls into the runtime and performs a case-insensitive comparison of the
// UTF16 strings (i.e. TwoByteString or ExternalTwoByteString) located at
// str[lhs_index:lhs_index + length] and str[rhs_index:rhs_index + length].
//
// TODO(zerny): Remove this once (if) functions inherited from unibrow
// are moved to dart code.
class CaseInsensitiveCompareUC16Instr
    : public TemplateDefinition<4, NoThrow, Pure> {
 public:
  CaseInsensitiveCompareUC16Instr(Value* str,
                                  Value* lhs_index,
                                  Value* rhs_index,
                                  Value* length,
                                  intptr_t cid)
      : cid_(cid) {
    ASSERT(cid == kTwoByteStringCid || cid == kExternalTwoByteStringCid);
    ASSERT(index_scale() == 2);
    SetInputAt(0, str);
    SetInputAt(1, lhs_index);
    SetInputAt(2, rhs_index);
    SetInputAt(3, length);
  }

  Value* str() const { return inputs_[0]; }
  Value* lhs_index() const { return inputs_[1]; }
  Value* rhs_index() const { return inputs_[2]; }
  Value* length() const { return inputs_[3]; }

  const RuntimeEntry& TargetFunction() const;
  bool IsExternal() const { return cid_ == kExternalTwoByteStringCid; }
  intptr_t class_id() const { return cid_; }
  intptr_t index_scale() const { return Instance::ElementSizeFor(cid_); }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kTagged; }

  DECLARE_INSTRUCTION(CaseInsensitiveCompareUC16)
  virtual CompileType ComputeType() const;

  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsCaseInsensitiveCompareUC16()->cid_ == cid_;
  }

 private:
  const intptr_t cid_;

  DISALLOW_COPY_AND_ASSIGN(CaseInsensitiveCompareUC16Instr);
};

// Represents Math's static min and max functions.
class MathMinMaxInstr : public TemplateDefinition<2, NoThrow, Pure> {
 public:
  MathMinMaxInstr(MethodRecognizer::Kind op_kind,
                  Value* left_value,
                  Value* right_value,
                  intptr_t deopt_id,
                  intptr_t result_cid)
      : TemplateDefinition(deopt_id),
        op_kind_(op_kind),
        result_cid_(result_cid) {
    ASSERT((result_cid == kSmiCid) || (result_cid == kDoubleCid));
    SetInputAt(0, left_value);
    SetInputAt(1, right_value);
  }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  intptr_t result_cid() const { return result_cid_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const {
    if (result_cid() == kSmiCid) {
      return kTagged;
    }
    ASSERT(result_cid() == kDoubleCid);
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    if (result_cid() == kSmiCid) {
      return kTagged;
    }
    ASSERT(result_cid() == kDoubleCid);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  DECLARE_INSTRUCTION(MathMinMax)
  virtual CompileType ComputeType() const;
  virtual bool AttributesEqual(Instruction* other) const;

 private:
  const MethodRecognizer::Kind op_kind_;
  const intptr_t result_cid_;

  DISALLOW_COPY_AND_ASSIGN(MathMinMaxInstr);
};

class BinaryDoubleOpInstr : public TemplateDefinition<2, NoThrow, Pure> {
 public:
  BinaryDoubleOpInstr(Token::Kind op_kind,
                      Value* left,
                      Value* right,
                      intptr_t deopt_id,
                      TokenPosition token_pos)
      : TemplateDefinition(deopt_id), op_kind_(op_kind), token_pos_(token_pos) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  PRINT_OPERANDS_TO_SUPPORT

  DECLARE_INSTRUCTION(BinaryDoubleOp)
  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsBinaryDoubleOp()->op_kind();
  }

 private:
  const Token::Kind op_kind_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(BinaryDoubleOpInstr);
};

class DoubleTestOpInstr : public TemplateComparison<1, NoThrow, Pure> {
 public:
  DoubleTestOpInstr(MethodRecognizer::Kind op_kind,
                    Value* value,
                    intptr_t deopt_id,
                    TokenPosition token_pos)
      : TemplateComparison(token_pos, Token::kEQ, deopt_id), op_kind_(op_kind) {
    SetInputAt(0, value);
  }

  Value* value() const { return InputAt(0); }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  PRINT_OPERANDS_TO_SUPPORT

  DECLARE_COMPARISON_INSTRUCTION(DoubleTestOp)

  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind_ == other->AsDoubleTestOp()->op_kind() &&
           ComparisonInstr::AttributesEqual(other);
  }

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(DoubleTestOpInstr);
};

class UnaryIntegerOpInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  UnaryIntegerOpInstr(Token::Kind op_kind, Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), op_kind_(op_kind) {
    ASSERT((op_kind == Token::kNEGATE) || (op_kind == Token::kBIT_NOT));
    SetInputAt(0, value);
  }

  static UnaryIntegerOpInstr* Make(Representation representation,
                                   Token::Kind op_kind,
                                   Value* value,
                                   intptr_t deopt_id,
                                   Range* range);

  Value* value() const { return inputs_[0]; }
  Token::Kind op_kind() const { return op_kind_; }

  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsUnaryIntegerOp()->op_kind() == op_kind();
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  PRINT_OPERANDS_TO_SUPPORT

  RawInteger* Evaluate(const Integer& value) const;

  DEFINE_INSTRUCTION_TYPE_CHECK(UnaryIntegerOp)

 private:
  const Token::Kind op_kind_;
};

// Handles both Smi operations: BIT_OR and NEGATE.
class UnarySmiOpInstr : public UnaryIntegerOpInstr {
 public:
  UnarySmiOpInstr(Token::Kind op_kind, Value* value, intptr_t deopt_id)
      : UnaryIntegerOpInstr(op_kind, value, deopt_id) {}

  virtual bool ComputeCanDeoptimize() const {
    return op_kind() == Token::kNEGATE;
  }

  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(UnarySmiOp)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnarySmiOpInstr);
};

class UnaryUint32OpInstr : public UnaryIntegerOpInstr {
 public:
  UnaryUint32OpInstr(Token::Kind op_kind, Value* value, intptr_t deopt_id)
      : UnaryIntegerOpInstr(op_kind, value, deopt_id) {
    ASSERT(op_kind == Token::kBIT_NOT);
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual CompileType ComputeType() const;

  virtual Representation representation() const { return kUnboxedUint32; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedUint32;
  }

  DECLARE_INSTRUCTION(UnaryUint32Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnaryUint32OpInstr);
};

class UnaryInt64OpInstr : public UnaryIntegerOpInstr {
 public:
  UnaryInt64OpInstr(Token::Kind op_kind, Value* value, intptr_t deopt_id)
      : UnaryIntegerOpInstr(op_kind, value, deopt_id) {
    ASSERT(op_kind == Token::kBIT_NOT);
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual CompileType ComputeType() const;

  virtual Representation representation() const { return kUnboxedInt64; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedInt64;
  }

  DECLARE_INSTRUCTION(UnaryInt64Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(UnaryInt64OpInstr);
};

class CheckedSmiOpInstr : public TemplateDefinition<2, Throws> {
 public:
  CheckedSmiOpInstr(Token::Kind op_kind,
                    Value* left,
                    Value* right,
                    InstanceCallInstr* call)
      : TemplateDefinition(call->deopt_id()), call_(call), op_kind_(op_kind) {
    ASSERT(call->type_args_len() == 0);
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  InstanceCallInstr* call() const { return call_; }
  Token::Kind op_kind() const { return op_kind_; }
  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual CompileType ComputeType() const;

  virtual bool HasUnknownSideEffects() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  PRINT_OPERANDS_TO_SUPPORT

  DECLARE_INSTRUCTION(CheckedSmiOp)

 private:
  InstanceCallInstr* call_;
  const Token::Kind op_kind_;
  DISALLOW_COPY_AND_ASSIGN(CheckedSmiOpInstr);
};

class CheckedSmiComparisonInstr : public TemplateComparison<2, Throws> {
 public:
  CheckedSmiComparisonInstr(Token::Kind op_kind,
                            Value* left,
                            Value* right,
                            InstanceCallInstr* call)
      : TemplateComparison(call->token_pos(), op_kind, call->deopt_id()),
        call_(call),
        is_negated_(false) {
    ASSERT(call->type_args_len() == 0);
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  InstanceCallInstr* call() const { return call_; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual void NegateComparison() {
    ComparisonInstr::NegateComparison();
    is_negated_ = !is_negated_;
  }

  bool is_negated() const { return is_negated_; }

  virtual bool HasUnknownSideEffects() const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

  DECLARE_INSTRUCTION(CheckedSmiComparison)

  virtual void EmitBranchCode(FlowGraphCompiler* compiler, BranchInstr* branch);

  virtual Condition EmitComparisonCode(FlowGraphCompiler* compiler,
                                       BranchLabels labels);

#if defined(TARGET_ARCH_DBC)
  virtual Condition GetNextInstructionCondition(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
    UNREACHABLE();
    return INVALID_CONDITION;
  }
#endif

  virtual ComparisonInstr* CopyWithNewOperands(Value* left, Value* right);

 private:
  InstanceCallInstr* call_;
  bool is_negated_;
  DISALLOW_COPY_AND_ASSIGN(CheckedSmiComparisonInstr);
};

class BinaryIntegerOpInstr : public TemplateDefinition<2, NoThrow, Pure> {
 public:
  BinaryIntegerOpInstr(Token::Kind op_kind,
                       Value* left,
                       Value* right,
                       intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        op_kind_(op_kind),
        can_overflow_(true),
        is_truncating_(false) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  static BinaryIntegerOpInstr* Make(Representation representation,
                                    Token::Kind op_kind,
                                    Value* left,
                                    Value* right,
                                    intptr_t deopt_id,
                                    bool can_overflow,
                                    bool is_truncating,
                                    Range* range);

  Token::Kind op_kind() const { return op_kind_; }
  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  bool can_overflow() const { return can_overflow_; }
  void set_can_overflow(bool overflow) {
    ASSERT(!is_truncating_ || !overflow);
    can_overflow_ = overflow;
  }

  bool is_truncating() const { return is_truncating_; }
  void mark_truncating() {
    is_truncating_ = true;
    set_can_overflow(false);
  }

  // Returns true if right is a non-zero Smi constant which absolute value is
  // a power of two.
  bool RightIsPowerOfTwoConstant() const;

  RawInteger* Evaluate(const Integer& left, const Integer& right) const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const;

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  PRINT_OPERANDS_TO_SUPPORT

  DEFINE_INSTRUCTION_TYPE_CHECK(BinaryIntegerOp)

 protected:
  void InferRangeHelper(const Range* left_range,
                        const Range* right_range,
                        Range* range);

 private:
  Definition* CreateConstantResult(FlowGraph* graph, const Integer& result);

  const Token::Kind op_kind_;

  bool can_overflow_;
  bool is_truncating_;
};

class BinarySmiOpInstr : public BinaryIntegerOpInstr {
 public:
  BinarySmiOpInstr(Token::Kind op_kind,
                   Value* left,
                   Value* right,
                   intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id),
        right_range_(NULL) {}

  virtual bool ComputeCanDeoptimize() const;

  virtual void InferRange(RangeAnalysis* analysis, Range* range);
  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(BinarySmiOp)

  Range* right_range() const { return right_range_; }

 private:
  Range* right_range_;

  DISALLOW_COPY_AND_ASSIGN(BinarySmiOpInstr);
};

class BinaryInt32OpInstr : public BinaryIntegerOpInstr {
 public:
  BinaryInt32OpInstr(Token::Kind op_kind,
                     Value* left,
                     Value* right,
                     intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  static bool IsSupported(Token::Kind op, Value* left, Value* right) {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
    switch (op) {
      case Token::kADD:
      case Token::kSUB:
      case Token::kMUL:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        return true;

      case Token::kSHL:
      case Token::kSHR:
        if (right->BindsToConstant() && right->BoundConstant().IsSmi()) {
          const intptr_t value = Smi::Cast(right->BoundConstant()).Value();
          return 0 <= value && value < kBitsPerWord;
        }
        return false;

      default:
        return false;
    }
#else
    return false;
#endif
  }

  virtual bool ComputeCanDeoptimize() const;

  virtual Representation representation() const { return kUnboxedInt32; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedInt32;
  }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);
  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(BinaryInt32Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(BinaryInt32OpInstr);
};

class BinaryUint32OpInstr : public BinaryIntegerOpInstr {
 public:
  BinaryUint32OpInstr(Token::Kind op_kind,
                      Value* left,
                      Value* right,
                      intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id) {
    mark_truncating();
  }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedUint32; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedUint32;
  }

  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(BinaryUint32Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(BinaryUint32OpInstr);
};

class ShiftUint32OpInstr : public BinaryIntegerOpInstr {
 public:
  ShiftUint32OpInstr(Token::Kind op_kind,
                     Value* left,
                     Value* right,
                     intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id) {
    ASSERT((op_kind == Token::kSHR) || (op_kind == Token::kSHL));
  }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Representation representation() const { return kUnboxedUint32; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return (idx == 0) ? kUnboxedUint32 : kTagged;
  }

  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(ShiftUint32Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(ShiftUint32OpInstr);
};

class BinaryInt64OpInstr : public BinaryIntegerOpInstr {
 public:
  BinaryInt64OpInstr(Token::Kind op_kind,
                     Value* left,
                     Value* right,
                     intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id) {
    if (FLAG_limit_ints_to_64_bits) {
      mark_truncating();
    }
  }

  virtual bool ComputeCanDeoptimize() const {
    switch (op_kind()) {
      case Token::kADD:
      case Token::kSUB:
        return can_overflow();
      case Token::kMUL:
// Note that ARM64 does not support operations with unboxed mints,
// so it is not handled here.
#if defined(TARGET_ARCH_X64)
        return can_overflow();  // Deopt if overflow.
#else
        // IA32, ARM
        return true;  // Deopt if inputs are not int32.
#endif
      default:
        return false;
    }
  }

  virtual Representation representation() const { return kUnboxedInt64; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedInt64;
  }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);
  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(BinaryInt64Op)

 private:
  DISALLOW_COPY_AND_ASSIGN(BinaryInt64OpInstr);
};

class ShiftInt64OpInstr : public BinaryIntegerOpInstr {
 public:
  ShiftInt64OpInstr(Token::Kind op_kind,
                    Value* left,
                    Value* right,
                    intptr_t deopt_id)
      : BinaryIntegerOpInstr(op_kind, left, right, deopt_id),
        shift_range_(NULL) {
    ASSERT((op_kind == Token::kSHR) || (op_kind == Token::kSHL));
    if (FLAG_limit_ints_to_64_bits) {
      mark_truncating();
    }
  }

  Range* shift_range() const { return shift_range_; }

  virtual bool ComputeCanDeoptimize() const {
    return (!IsShiftCountInRange()) ||
           (can_overflow() && (op_kind() == Token::kSHL));
  }

  virtual Representation representation() const { return kUnboxedInt64; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return (idx == 0) ? kUnboxedInt64 : kTagged;
  }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);
  virtual CompileType ComputeType() const;

  DECLARE_INSTRUCTION(ShiftInt64Op)

 private:
  static const intptr_t kMintShiftCountLimit = 63;

  // Returns true if the shift amount is guranteed to be in
  // [0..kMintShiftCountLimit] range.
  bool IsShiftCountInRange() const;

  Range* shift_range_;

  DISALLOW_COPY_AND_ASSIGN(ShiftInt64OpInstr);
};

// Handles only NEGATE.
class UnaryDoubleOpInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  UnaryDoubleOpInstr(Token::Kind op_kind, Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id), op_kind_(op_kind) {
    ASSERT(op_kind == Token::kNEGATE);
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  Token::Kind op_kind() const { return op_kind_; }

  DECLARE_INSTRUCTION(UnaryDoubleOp)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(UnaryDoubleOpInstr);
};

class CheckStackOverflowInstr : public TemplateInstruction<0, NoThrow> {
 public:
  enum Kind {
    // kOsrAndPreemption stack overflow checks are emitted in both unoptimized
    // and optimized versions of the code and they serve as both preemption and
    // OSR entry points.
    kOsrAndPreemption,

    // kOsrOnly stack overflow checks are only needed in the unoptimized code
    // because we can't OSR optimized code.
    kOsrOnly,
  };

  CheckStackOverflowInstr(TokenPosition token_pos,
                          intptr_t loop_depth,
                          intptr_t deopt_id,
                          Kind kind = kOsrAndPreemption)
      : TemplateInstruction(deopt_id),
        token_pos_(token_pos),
        loop_depth_(loop_depth),
        kind_(kind) {
    ASSERT(kind != kOsrOnly || loop_depth > 0);
  }

  virtual TokenPosition token_pos() const { return token_pos_; }
  bool in_loop() const { return loop_depth_ > 0; }
  intptr_t loop_depth() const { return loop_depth_; }

  DECLARE_INSTRUCTION(CheckStackOverflow)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool HasUnknownSideEffects() const { return false; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const TokenPosition token_pos_;
  const intptr_t loop_depth_;
  const Kind kind_;

  DISALLOW_COPY_AND_ASSIGN(CheckStackOverflowInstr);
};

// TODO(vegorov): remove this instruction in favor of Int32ToDouble.
class SmiToDoubleInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  SmiToDoubleInstr(Value* value, TokenPosition token_pos)
      : token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(SmiToDouble)
  virtual CompileType ComputeType() const;

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(SmiToDoubleInstr);
};

class Int32ToDoubleInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  explicit Int32ToDoubleInstr(Value* value) { SetInputAt(0, value); }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(Int32ToDouble)
  virtual CompileType ComputeType() const;

  virtual Representation RequiredInputRepresentation(intptr_t index) const {
    ASSERT(index == 0);
    return kUnboxedInt32;
  }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Int32ToDoubleInstr);
};

class MintToDoubleInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  MintToDoubleInstr(Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(MintToDouble)
  virtual CompileType ComputeType() const;

  virtual Representation RequiredInputRepresentation(intptr_t index) const {
    ASSERT(index == 0);
    return kUnboxedInt64;
  }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  DISALLOW_COPY_AND_ASSIGN(MintToDoubleInstr);
};

class DoubleToIntegerInstr : public TemplateDefinition<1, Throws> {
 public:
  DoubleToIntegerInstr(Value* value, InstanceCallInstr* instance_call)
      : TemplateDefinition(instance_call->deopt_id()),
        instance_call_(instance_call) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  InstanceCallInstr* instance_call() const { return instance_call_; }

  DECLARE_INSTRUCTION(DoubleToInteger)
  virtual CompileType ComputeType() const;

  virtual intptr_t ArgumentCount() const { return 1; }

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  InstanceCallInstr* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(DoubleToIntegerInstr);
};

// Similar to 'DoubleToIntegerInstr' but expects unboxed double as input
// and creates a Smi.
class DoubleToSmiInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  DoubleToSmiInstr(Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(DoubleToSmi)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  DISALLOW_COPY_AND_ASSIGN(DoubleToSmiInstr);
};

class DoubleToDoubleInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  DoubleToDoubleInstr(Value* value,
                      MethodRecognizer::Kind recognized_kind,
                      intptr_t deopt_id)
      : TemplateDefinition(deopt_id), recognized_kind_(recognized_kind) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  MethodRecognizer::Kind recognized_kind() const { return recognized_kind_; }

  DECLARE_INSTRUCTION(DoubleToDouble)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsDoubleToDouble()->recognized_kind() == recognized_kind();
  }

 private:
  const MethodRecognizer::Kind recognized_kind_;

  DISALLOW_COPY_AND_ASSIGN(DoubleToDoubleInstr);
};

class DoubleToFloatInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  DoubleToFloatInstr(Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(DoubleToFloat)

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const {
    // This works since double is the representation that the typed array
    // store expects.
    // TODO(fschneider): Change this to a genuine float representation once it
    // is supported.
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

 private:
  DISALLOW_COPY_AND_ASSIGN(DoubleToFloatInstr);
};

class FloatToDoubleInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  FloatToDoubleInstr(Value* value, intptr_t deopt_id)
      : TemplateDefinition(deopt_id) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(FloatToDouble)

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

 private:
  DISALLOW_COPY_AND_ASSIGN(FloatToDoubleInstr);
};

class InvokeMathCFunctionInstr : public PureDefinition {
 public:
  InvokeMathCFunctionInstr(ZoneGrowableArray<Value*>* inputs,
                           intptr_t deopt_id,
                           MethodRecognizer::Kind recognized_kind,
                           TokenPosition token_pos);

  static intptr_t ArgumentCountFor(MethodRecognizer::Kind recognized_kind_);

  const RuntimeEntry& TargetFunction() const;

  MethodRecognizer::Kind recognized_kind() const { return recognized_kind_; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(InvokeMathCFunction)
  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual Representation representation() const { return kUnboxedDouble; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((0 <= idx) && (idx < InputCount()));
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  virtual intptr_t InputCount() const { return inputs_->length(); }

  virtual Value* InputAt(intptr_t i) const { return (*inputs_)[i]; }

  virtual bool AttributesEqual(Instruction* other) const {
    InvokeMathCFunctionInstr* other_invoke = other->AsInvokeMathCFunction();
    return other_invoke->recognized_kind() == recognized_kind();
  }

  virtual bool MayThrow() const { return false; }

  static const intptr_t kSavedSpTempIndex = 0;
  static const intptr_t kObjectTempIndex = 1;
  static const intptr_t kDoubleTempIndex = 2;

  PRINT_OPERANDS_TO_SUPPORT

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    (*inputs_)[i] = value;
  }

  ZoneGrowableArray<Value*>* inputs_;
  const MethodRecognizer::Kind recognized_kind_;
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(InvokeMathCFunctionInstr);
};

class ExtractNthOutputInstr : public TemplateDefinition<1, NoThrow, Pure> {
 public:
  // Extract the Nth output register from value.
  ExtractNthOutputInstr(Value* value,
                        intptr_t n,
                        Representation definition_rep,
                        intptr_t definition_cid)
      : index_(n),
        definition_rep_(definition_rep),
        definition_cid_(definition_cid) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(ExtractNthOutput)

  virtual CompileType ComputeType() const;
  virtual bool ComputeCanDeoptimize() const { return false; }

  intptr_t index() const { return index_; }

  virtual Representation representation() const { return definition_rep_; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    if (representation() == kTagged) {
      return kPairOfTagged;
    }
    UNREACHABLE();
    return definition_rep_;
  }

  virtual bool AttributesEqual(Instruction* other) const {
    ExtractNthOutputInstr* other_extract = other->AsExtractNthOutput();
    return (other_extract->representation() == representation()) &&
           (other_extract->index() == index());
  }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const intptr_t index_;
  const Representation definition_rep_;
  const intptr_t definition_cid_;
  DISALLOW_COPY_AND_ASSIGN(ExtractNthOutputInstr);
};

class TruncDivModInstr : public TemplateDefinition<2, NoThrow, Pure> {
 public:
  TruncDivModInstr(Value* lhs, Value* rhs, intptr_t deopt_id);

  static intptr_t OutputIndexOf(Token::Kind token);

  virtual CompileType ComputeType() const;

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Representation representation() const { return kPairOfTagged; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((0 <= idx) && (idx < InputCount()));
    return kTagged;
  }

  virtual intptr_t DeoptimizationTarget() const { return GetDeoptId(); }

  DECLARE_INSTRUCTION(TruncDivMod)

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  Range* divisor_range() const {
    // Note: this range is only used to remove check for zero divisor from
    // the emitted pattern. It is not used for deciding whether instruction
    // will deoptimize or not - that is why it is ok to access range of
    // the definition directly. Otherwise range analysis or another pass
    // needs to cache range of the divisor in the operation to prevent
    // bugs when range information gets out of sync with the final decision
    // whether some instruction can deoptimize or not made in
    // EliminateEnvironments().
    return InputAt(1)->definition()->range();
  }

  DISALLOW_COPY_AND_ASSIGN(TruncDivModInstr);
};

class CheckClassInstr : public TemplateInstruction<1, NoThrow> {
 public:
  CheckClassInstr(Value* value,
                  intptr_t deopt_id,
                  const Cids& cids,
                  TokenPosition token_pos);

  DECLARE_INSTRUCTION(CheckClass)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual TokenPosition token_pos() const { return token_pos_; }

  Value* value() const { return inputs_[0]; }

  const Cids& cids() const { return cids_; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  bool IsNullCheck() const { return IsDeoptIfNull() || IsDeoptIfNotNull(); }

  bool IsDeoptIfNull() const;
  bool IsDeoptIfNotNull() const;

  bool IsBitTest() const;
  static bool IsCompactCidRange(const Cids& cids);
  intptr_t ComputeCidMask() const;

  virtual bool AllowsCSE() const { return true; }
  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const;

  bool licm_hoisted() const { return licm_hoisted_; }
  void set_licm_hoisted(bool value) { licm_hoisted_ = value; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const Cids& cids_;
  bool licm_hoisted_;
  bool is_bit_test_;
  const TokenPosition token_pos_;

  int EmitCheckCid(FlowGraphCompiler* compiler,
                   int bias,
                   intptr_t cid_start,
                   intptr_t cid_end,
                   bool is_last,
                   Label* is_ok,
                   Label* deopt,
                   bool use_near_jump);
  void EmitBitTest(FlowGraphCompiler* compiler,
                   intptr_t min,
                   intptr_t max,
                   intptr_t mask,
                   Label* deopt);
  void EmitNullCheck(FlowGraphCompiler* compiler, Label* deopt);

  DISALLOW_COPY_AND_ASSIGN(CheckClassInstr);
};

class CheckSmiInstr : public TemplateInstruction<1, NoThrow, Pure> {
 public:
  CheckSmiInstr(Value* value, intptr_t deopt_id, TokenPosition token_pos)
      : TemplateInstruction(deopt_id),
        token_pos_(token_pos),
        licm_hoisted_(false) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(CheckSmi)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  bool licm_hoisted() const { return licm_hoisted_; }
  void set_licm_hoisted(bool value) { licm_hoisted_ = value; }

 private:
  const TokenPosition token_pos_;
  bool licm_hoisted_;

  DISALLOW_COPY_AND_ASSIGN(CheckSmiInstr);
};

// CheckNull instruction takes one input (`value`) and tests it for `null`.
// If `value` is `null`, then `NoSuchMethodError` is thrown. Otherwise,
// execution proceeds to the next instruction.
class CheckNullInstr : public TemplateInstruction<1, Throws, NoCSE> {
 public:
  CheckNullInstr(Value* value, intptr_t deopt_id, TokenPosition token_pos)
      : TemplateInstruction(deopt_id), token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  virtual TokenPosition token_pos() const { return token_pos_; }

  DECLARE_INSTRUCTION(CheckNull)

  // CheckNull can implicitly call Dart code (NoSuchMethodError constructor),
  // so it can lazily deopt.
  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

 private:
  const TokenPosition token_pos_;

  DISALLOW_COPY_AND_ASSIGN(CheckNullInstr);
};

class CheckClassIdInstr : public TemplateInstruction<1, NoThrow> {
 public:
  CheckClassIdInstr(Value* value, CidRange cids, intptr_t deopt_id)
      : TemplateInstruction(deopt_id), cids_(cids) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }
  const CidRange& cids() const { return cids_; }

  DECLARE_INSTRUCTION(CheckClassId)

  virtual bool ComputeCanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  PRINT_OPERANDS_TO_SUPPORT

 private:
  bool Contains(intptr_t cid) const;

  CidRange cids_;

  DISALLOW_COPY_AND_ASSIGN(CheckClassIdInstr);
};

class CheckArrayBoundInstr : public TemplateInstruction<2, NoThrow, Pure> {
 public:
  CheckArrayBoundInstr(Value* length, Value* index, intptr_t deopt_id)
      : TemplateInstruction(deopt_id),
        generalized_(false),
        licm_hoisted_(false) {
    SetInputAt(kLengthPos, length);
    SetInputAt(kIndexPos, index);
  }

  Value* length() const { return inputs_[kLengthPos]; }
  Value* index() const { return inputs_[kIndexPos]; }

  DECLARE_INSTRUCTION(CheckArrayBound)

  virtual bool ComputeCanDeoptimize() const { return true; }

  bool IsRedundant(const RangeBoundary& length);

  void mark_generalized() { generalized_ = true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  // Returns the length offset for array and string types.
  static intptr_t LengthOffsetFor(intptr_t class_id);

  static bool IsFixedLengthArrayType(intptr_t class_id);

  virtual bool AttributesEqual(Instruction* other) const { return true; }

  void set_licm_hoisted(bool value) { licm_hoisted_ = value; }

  // Give a name to the location/input indices.
  enum { kLengthPos = 0, kIndexPos = 1 };

 private:
  bool generalized_;
  bool licm_hoisted_;

  DISALLOW_COPY_AND_ASSIGN(CheckArrayBoundInstr);
};

class GenericCheckBoundInstr : public TemplateInstruction<2, Throws, NoCSE> {
 public:
  GenericCheckBoundInstr(Value* length, Value* index, intptr_t deopt_id)
      : TemplateInstruction(deopt_id) {
    SetInputAt(kLengthPos, length);
    SetInputAt(kIndexPos, index);
  }

  Value* length() const { return inputs_[kLengthPos]; }
  Value* index() const { return inputs_[kIndexPos]; }

  virtual bool HasUnknownSideEffects() const { return false; }

  DECLARE_INSTRUCTION(GenericCheckBound)

  // GenericCheckBound can implicitly call Dart code (RangeError or
  // ArgumentError constructor), so it can lazily deopt.
  virtual bool ComputeCanDeoptimize() const { return true; }

  // Give a name to the location/input indices.
  enum { kLengthPos = 0, kIndexPos = 1 };

 private:
  DISALLOW_COPY_AND_ASSIGN(GenericCheckBoundInstr);
};

class UnboxedIntConverterInstr : public TemplateDefinition<1, NoThrow> {
 public:
  UnboxedIntConverterInstr(Representation from,
                           Representation to,
                           Value* value,
                           intptr_t deopt_id)
      : TemplateDefinition(deopt_id),
        from_representation_(from),
        to_representation_(to),
        is_truncating_(to == kUnboxedUint32) {
    ASSERT(from != to);
    ASSERT((from == kUnboxedInt64) || (from == kUnboxedUint32) ||
           (from == kUnboxedInt32));
    ASSERT((to == kUnboxedInt64) || (to == kUnboxedUint32) ||
           (to == kUnboxedInt32));
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  Representation from() const { return from_representation_; }
  Representation to() const { return to_representation_; }
  bool is_truncating() const { return is_truncating_; }

  void mark_truncating() { is_truncating_ = true; }

  Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool ComputeCanDeoptimize() const;

  virtual Representation representation() const { return to(); }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return from();
  }

  virtual bool HasUnknownSideEffects() const { return false; }

  virtual bool AttributesEqual(Instruction* other) const {
    ASSERT(other->IsUnboxedIntConverter());
    UnboxedIntConverterInstr* converter = other->AsUnboxedIntConverter();
    return (converter->from() == from()) && (converter->to() == to()) &&
           (converter->is_truncating() == is_truncating());
  }

  virtual void InferRange(RangeAnalysis* analysis, Range* range);

  virtual CompileType ComputeType() const {
    // TODO(vegorov) use range information to improve type.
    return CompileType::Int();
  }

  DECLARE_INSTRUCTION(UnboxedIntConverter);

  PRINT_OPERANDS_TO_SUPPORT

 private:
  const Representation from_representation_;
  const Representation to_representation_;
  bool is_truncating_;

  DISALLOW_COPY_AND_ASSIGN(UnboxedIntConverterInstr);
};

//
// SimdOpInstr
//
// All SIMD intrinsics and recognized methods are represented via instances
// of SimdOpInstr, a particular type of SimdOp is selected by SimdOpInstr::Kind.
//
// Defines below are used to contruct SIMD_OP_LIST - a list of all SIMD
// operations. SIMD_OP_LIST contains information such as arity, input types and
// output type for each SIMD op and is used to derive things like input
// and output representations, type of return value, etc.
//
// Lists of SIMD ops are defined using macro M, OP and BINARY_OP which are
// expected to have the following signature:
//
//          (Arity, HasMask, Name, (In_0, ..., In_Arity), Out)
//
// where:
//
//          HasMask is either _ or MASK and determines if operation has an
//          constant mask attribute
//          In_0, ..., In_Arity are input types
//          Out is output type
//

// A binary SIMD op with the given name that has signature T x T -> T.
#define SIMD_BINARY_OP(M, T, Name) M(2, _, T##Name, (T, T), T)

// List of SIMD_BINARY_OPs common for Float32x4 or Float64x2.
// Note: M for recognized methods and OP for operators.
#define SIMD_BINARY_FLOAT_OP_LIST(M, OP, T)                                    \
  SIMD_BINARY_OP(OP, T, Add)                                                   \
  SIMD_BINARY_OP(OP, T, Sub)                                                   \
  SIMD_BINARY_OP(OP, T, Mul)                                                   \
  SIMD_BINARY_OP(OP, T, Div)                                                   \
  SIMD_BINARY_OP(M, T, Min)                                                    \
  SIMD_BINARY_OP(M, T, Max)

// List of SIMD_BINARY_OP for Int32x4.
// Note: M for recognized methods and OP for operators.
#define SIMD_BINARY_INTEGER_OP_LIST(M, OP, T)                                  \
  SIMD_BINARY_OP(OP, T, Add)                                                   \
  SIMD_BINARY_OP(OP, T, Sub)                                                   \
  SIMD_BINARY_OP(OP, T, BitAnd)                                                \
  SIMD_BINARY_OP(OP, T, BitOr)                                                 \
  SIMD_BINARY_OP(OP, T, BitXor)

// Given a signature of a given SIMD op construct its per component variations.
#define SIMD_PER_COMPONENT_XYZW(M, Arity, Name, Inputs, Output)                \
  M(Arity, _, Name##X, Inputs, Output)                                         \
  M(Arity, _, Name##Y, Inputs, Output)                                         \
  M(Arity, _, Name##Z, Inputs, Output)                                         \
  M(Arity, _, Name##W, Inputs, Output)

// Define convertion between two SIMD types.
#define SIMD_CONVERSION(M, FromType, ToType)                                   \
  M(1, _, FromType##To##ToType, (FromType), ToType)

// List of all recognized SIMD operations.
// Note: except for operations that map to operators (Add, Mul, Sub, Div,
// BitXor, BitOr) all other operations must match names used by
// MethodRecognizer. This allows to autogenerate convertion from
// MethodRecognizer::Kind into SimdOpInstr::Kind (see KindForMethod helper).
// Note: M is for those SimdOp that are recognized methods and BINARY_OP
// is for operators.
#define SIMD_OP_LIST(M, BINARY_OP)                                             \
  SIMD_BINARY_FLOAT_OP_LIST(M, BINARY_OP, Float32x4)                           \
  SIMD_BINARY_FLOAT_OP_LIST(M, BINARY_OP, Float64x2)                           \
  SIMD_BINARY_INTEGER_OP_LIST(M, BINARY_OP, Int32x4)                           \
  SIMD_PER_COMPONENT_XYZW(M, 1, Float32x4Shuffle, (Float32x4), Double)         \
  SIMD_PER_COMPONENT_XYZW(M, 2, Float32x4With, (Double, Float32x4), Float32x4) \
  SIMD_PER_COMPONENT_XYZW(M, 1, Int32x4GetFlag, (Int32x4), Bool)               \
  SIMD_PER_COMPONENT_XYZW(M, 2, Int32x4WithFlag, (Int32x4, Bool), Int32x4)     \
  M(1, MASK, Float32x4Shuffle, (Float32x4), Float32x4)                         \
  M(1, MASK, Int32x4Shuffle, (Int32x4), Int32x4)                               \
  M(2, MASK, Float32x4ShuffleMix, (Float32x4, Float32x4), Float32x4)           \
  M(2, MASK, Int32x4ShuffleMix, (Int32x4, Int32x4), Int32x4)                   \
  M(2, _, Float32x4Equal, (Float32x4, Float32x4), Int32x4)                     \
  M(2, _, Float32x4GreaterThan, (Float32x4, Float32x4), Int32x4)               \
  M(2, _, Float32x4GreaterThanOrEqual, (Float32x4, Float32x4), Int32x4)        \
  M(2, _, Float32x4LessThan, (Float32x4, Float32x4), Int32x4)                  \
  M(2, _, Float32x4LessThanOrEqual, (Float32x4, Float32x4), Int32x4)           \
  M(2, _, Float32x4NotEqual, (Float32x4, Float32x4), Int32x4)                  \
  M(4, _, Int32x4Constructor, (Int32, Int32, Int32, Int32), Int32x4)           \
  M(4, _, Int32x4BoolConstructor, (Bool, Bool, Bool, Bool), Int32x4)           \
  M(4, _, Float32x4Constructor, (Double, Double, Double, Double), Float32x4)   \
  M(2, _, Float64x2Constructor, (Double, Double), Float64x2)                   \
  M(0, _, Float32x4Zero, (), Float32x4)                                        \
  M(0, _, Float64x2Zero, (), Float64x2)                                        \
  M(1, _, Float32x4Splat, (Double), Float32x4)                                 \
  M(1, _, Float64x2Splat, (Double), Float64x2)                                 \
  M(1, _, Int32x4GetSignMask, (Int32x4), Int8)                                 \
  M(1, _, Float32x4GetSignMask, (Float32x4), Int8)                             \
  M(1, _, Float64x2GetSignMask, (Float64x2), Int8)                             \
  M(2, _, Float32x4Scale, (Double, Float32x4), Float32x4)                      \
  M(2, _, Float64x2Scale, (Float64x2, Double), Float64x2)                      \
  M(1, _, Float32x4Sqrt, (Float32x4), Float32x4)                               \
  M(1, _, Float64x2Sqrt, (Float64x2), Float64x2)                               \
  M(1, _, Float32x4Reciprocal, (Float32x4), Float32x4)                         \
  M(1, _, Float32x4ReciprocalSqrt, (Float32x4), Float32x4)                     \
  M(1, _, Float32x4Negate, (Float32x4), Float32x4)                             \
  M(1, _, Float64x2Negate, (Float64x2), Float64x2)                             \
  M(1, _, Float32x4Abs, (Float32x4), Float32x4)                                \
  M(1, _, Float64x2Abs, (Float64x2), Float64x2)                                \
  M(3, _, Float32x4Clamp, (Float32x4, Float32x4, Float32x4), Float32x4)        \
  M(1, _, Float64x2GetX, (Float64x2), Double)                                  \
  M(1, _, Float64x2GetY, (Float64x2), Double)                                  \
  M(2, _, Float64x2WithX, (Float64x2, Double), Float64x2)                      \
  M(2, _, Float64x2WithY, (Float64x2, Double), Float64x2)                      \
  M(3, _, Int32x4Select, (Int32x4, Float32x4, Float32x4), Float32x4)           \
  SIMD_CONVERSION(M, Float32x4, Int32x4)                                       \
  SIMD_CONVERSION(M, Int32x4, Float32x4)                                       \
  SIMD_CONVERSION(M, Float32x4, Float64x2)                                     \
  SIMD_CONVERSION(M, Float64x2, Float32x4)

class SimdOpInstr : public Definition {
 public:
  enum Kind {
#define DECLARE_ENUM(Arity, Mask, Name, ...) k##Name,
    SIMD_OP_LIST(DECLARE_ENUM, DECLARE_ENUM)
#undef DECLARE_ENUM
        kIllegalSimdOp,
  };

  // Create SimdOp from the arguments of the given call and the given receiver.
  static SimdOpInstr* CreateFromCall(Zone* zone,
                                     MethodRecognizer::Kind kind,
                                     Definition* receiver,
                                     Instruction* call,
                                     intptr_t mask = 0);

  // Create SimdOp from the arguments of the given factory call.
  static SimdOpInstr* CreateFromFactoryCall(Zone* zone,
                                            MethodRecognizer::Kind kind,
                                            Instruction* call);

  // Create a binary SimdOp instr.
  static SimdOpInstr* Create(Kind kind,
                             Value* left,
                             Value* right,
                             intptr_t deopt_id) {
    return new SimdOpInstr(kind, left, right, deopt_id);
  }

  // Create a binary SimdOp instr.
  static SimdOpInstr* Create(MethodRecognizer::Kind kind,
                             Value* left,
                             Value* right,
                             intptr_t deopt_id) {
    return new SimdOpInstr(KindForMethod(kind), left, right, deopt_id);
  }

  // Create a unary SimdOp.
  static SimdOpInstr* Create(MethodRecognizer::Kind kind,
                             Value* left,
                             intptr_t deopt_id) {
    return new SimdOpInstr(KindForMethod(kind), left, deopt_id);
  }

  static Kind KindForMethod(MethodRecognizer::Kind method_kind);

  // Convert a combination of SIMD cid and an arithmetic token into Kind, e.g.
  // Float32x4 and Token::kADD becomes Float32x4Add.
  static Kind KindForOperator(intptr_t cid, Token::Kind op);

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const {
    ASSERT(0 <= i && i < InputCount());
    return inputs_[i];
  }

  Kind kind() const { return kind_; }
  intptr_t mask() const {
    ASSERT(HasMask());
    return mask_;
  }

  virtual Representation representation() const;
  virtual Representation RequiredInputRepresentation(intptr_t idx) const;

  virtual CompileType ComputeType() const;

  virtual bool MayThrow() const { return false; }
  virtual bool ComputeCanDeoptimize() const { return false; }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return GetDeoptId();
  }

  virtual bool HasUnknownSideEffects() const { return false; }
  virtual bool AllowsCSE() const { return true; }

  virtual bool AttributesEqual(Instruction* other) const {
    SimdOpInstr* other_op = other->AsSimdOp();
    return kind() == other_op->kind() &&
           (!HasMask() || mask() == other_op->mask());
  }

  DECLARE_INSTRUCTION(SimdOp)
  PRINT_OPERANDS_TO_SUPPORT

 private:
  SimdOpInstr(Kind kind, intptr_t deopt_id)
      : Definition(deopt_id), kind_(kind) {}

  SimdOpInstr(Kind kind, Value* left, intptr_t deopt_id)
      : Definition(deopt_id), kind_(kind) {
    SetInputAt(0, left);
  }

  SimdOpInstr(Kind kind, Value* left, Value* right, intptr_t deopt_id)
      : Definition(deopt_id), kind_(kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  bool HasMask() const;
  void set_mask(intptr_t mask) { mask_ = mask; }

  virtual void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }

  // We consider SimdOpInstr to be very uncommon so we don't optimize them for
  // size. Any instance of SimdOpInstr has enough space to fit any variation.
  // TODO(dartbug.com/30949) optimize this for size.
  const Kind kind_;
  Value* inputs_[4];
  intptr_t mask_;

  DISALLOW_COPY_AND_ASSIGN(SimdOpInstr);
};

#undef DECLARE_INSTRUCTION

class Environment : public ZoneAllocated {
 public:
  // Iterate the non-NULL values in the innermost level of an environment.
  class ShallowIterator : public ValueObject {
   public:
    explicit ShallowIterator(Environment* environment)
        : environment_(environment), index_(0) {}

    ShallowIterator(const ShallowIterator& other)
        : ValueObject(),
          environment_(other.environment_),
          index_(other.index_) {}

    ShallowIterator& operator=(const ShallowIterator& other) {
      environment_ = other.environment_;
      index_ = other.index_;
      return *this;
    }

    Environment* environment() const { return environment_; }

    void Advance() {
      ASSERT(!Done());
      ++index_;
    }

    bool Done() const {
      return (environment_ == NULL) || (index_ >= environment_->Length());
    }

    Value* CurrentValue() const {
      ASSERT(!Done());
      ASSERT(environment_->values_[index_] != NULL);
      return environment_->values_[index_];
    }

    void SetCurrentValue(Value* value) {
      ASSERT(!Done());
      ASSERT(value != NULL);
      environment_->values_[index_] = value;
    }

    Location CurrentLocation() const {
      ASSERT(!Done());
      return environment_->locations_[index_];
    }

    void SetCurrentLocation(Location loc) {
      ASSERT(!Done());
      environment_->locations_[index_] = loc;
    }

   private:
    Environment* environment_;
    intptr_t index_;
  };

  // Iterate all non-NULL values in an environment, including outer
  // environments.  Note that the iterator skips empty environments.
  class DeepIterator : public ValueObject {
   public:
    explicit DeepIterator(Environment* environment) : iterator_(environment) {
      SkipDone();
    }

    void Advance() {
      ASSERT(!Done());
      iterator_.Advance();
      SkipDone();
    }

    bool Done() const { return iterator_.environment() == NULL; }

    Value* CurrentValue() const {
      ASSERT(!Done());
      return iterator_.CurrentValue();
    }

    void SetCurrentValue(Value* value) {
      ASSERT(!Done());
      iterator_.SetCurrentValue(value);
    }

    Location CurrentLocation() const {
      ASSERT(!Done());
      return iterator_.CurrentLocation();
    }

    void SetCurrentLocation(Location loc) {
      ASSERT(!Done());
      iterator_.SetCurrentLocation(loc);
    }

   private:
    void SkipDone() {
      while (!Done() && iterator_.Done()) {
        iterator_ = ShallowIterator(iterator_.environment()->outer());
      }
    }

    ShallowIterator iterator_;
  };

  // Construct an environment by constructing uses from an array of definitions.
  static Environment* From(Zone* zone,
                           const GrowableArray<Definition*>& definitions,
                           intptr_t fixed_parameter_count,
                           const ParsedFunction& parsed_function);

  void set_locations(Location* locations) {
    ASSERT(locations_ == NULL);
    locations_ = locations;
  }

  void set_deopt_id(intptr_t deopt_id) { deopt_id_ = deopt_id; }
  intptr_t deopt_id() const { return deopt_id_; }

  Environment* outer() const { return outer_; }

  Environment* Outermost() {
    Environment* result = this;
    while (result->outer() != NULL)
      result = result->outer();
    return result;
  }

  Value* ValueAt(intptr_t ix) const { return values_[ix]; }

  void PushValue(Value* value);

  intptr_t Length() const { return values_.length(); }

  Location LocationAt(intptr_t index) const {
    ASSERT((index >= 0) && (index < values_.length()));
    return locations_[index];
  }

  // The use index is the index in the flattened environment.
  Value* ValueAtUseIndex(intptr_t index) const {
    const Environment* env = this;
    while (index >= env->Length()) {
      ASSERT(env->outer_ != NULL);
      index -= env->Length();
      env = env->outer_;
    }
    return env->ValueAt(index);
  }

  intptr_t fixed_parameter_count() const { return fixed_parameter_count_; }

  intptr_t CountArgsPushed() {
    intptr_t count = 0;
    for (Environment::DeepIterator it(this); !it.Done(); it.Advance()) {
      if (it.CurrentValue()->definition()->IsPushArgument()) {
        count++;
      }
    }
    return count;
  }

  const Function& function() const { return parsed_function_.function(); }

  Environment* DeepCopy(Zone* zone) const { return DeepCopy(zone, Length()); }

  void DeepCopyTo(Zone* zone, Instruction* instr) const;
  void DeepCopyToOuter(Zone* zone, Instruction* instr) const;

  void DeepCopyAfterTo(Zone* zone,
                       Instruction* instr,
                       intptr_t argc,
                       Definition* dead,
                       Definition* result) const;

  void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

  // Deep copy an environment.  The 'length' parameter may be less than the
  // environment's length in order to drop values (e.g., passed arguments)
  // from the copy.
  Environment* DeepCopy(Zone* zone, intptr_t length) const;

#if defined(TARGET_ARCH_DBC)
  // Return/ReturnTOS instruction drops incoming arguments so
  // we have to drop outgoing arguments from the innermost environment.
  // On all other architectures caller drops outgoing arguments itself
  // hence the difference.
  // Note: this method can only be used at the code generation stage because
  // it mutates environment in unsafe way (e.g. does not update def-use
  // chains).
  void DropArguments(intptr_t argc);
#endif

 private:
  friend class ShallowIterator;
  friend class BlockBuilder;  // For Environment constructor.

  Environment(intptr_t length,
              intptr_t fixed_parameter_count,
              intptr_t deopt_id,
              const ParsedFunction& parsed_function,
              Environment* outer)
      : values_(length),
        locations_(NULL),
        fixed_parameter_count_(fixed_parameter_count),
        deopt_id_(deopt_id),
        parsed_function_(parsed_function),
        outer_(outer) {}

  GrowableArray<Value*> values_;
  Location* locations_;
  const intptr_t fixed_parameter_count_;
  intptr_t deopt_id_;
  const ParsedFunction& parsed_function_;
  Environment* outer_;

  DISALLOW_COPY_AND_ASSIGN(Environment);
};

// Visitor base class to visit each instruction and computation in a flow
// graph as defined by a reversed list of basic blocks.
class FlowGraphVisitor : public ValueObject {
 public:
  explicit FlowGraphVisitor(const GrowableArray<BlockEntryInstr*>& block_order)
      : current_iterator_(NULL), block_order_(block_order) {}
  virtual ~FlowGraphVisitor() {}

  ForwardInstructionIterator* current_iterator() const {
    return current_iterator_;
  }

  // Visit each block in the block order, and for each block its
  // instructions in order from the block entry to exit.
  virtual void VisitBlocks();

// Visit functions for instruction classes, with an empty default
// implementation.
#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr) {}

  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_INSTRUCTION

 protected:
  ForwardInstructionIterator* current_iterator_;

 private:
  const GrowableArray<BlockEntryInstr*>& block_order_;
  DISALLOW_COPY_AND_ASSIGN(FlowGraphVisitor);
};

// Helper macros for platform ports.
#define DEFINE_UNIMPLEMENTED_INSTRUCTION(Name)                                 \
  LocationSummary* Name::MakeLocationSummary(Zone* zone, bool opt) const {     \
    UNIMPLEMENTED();                                                           \
    return NULL;                                                               \
  }                                                                            \
  void Name::EmitNativeCode(FlowGraphCompiler* compiler) { UNIMPLEMENTED(); }

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_H_
