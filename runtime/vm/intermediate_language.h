// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_INTERMEDIATE_LANGUAGE_H_
#define VM_INTERMEDIATE_LANGUAGE_H_

#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/growable_array.h"
#include "vm/handles_impl.h"
#include "vm/locations.h"
#include "vm/object.h"

namespace dart {

class BitVector;
class BlockEntryInstr;
class BufferFormatter;
class CatchBlockEntryInstr;
class ComparisonInstr;
class ControlInstruction;
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


// TODO(srdjan): Unify with INTRINSIC_LIST.
// (class-name, function-name, recognized enum, fingerprint).
// See intrinsifier for fingerprint computation.
#define RECOGNIZED_LIST(V)                                                     \
  V(Object, get:_cid, ObjectCid, 732498573)                                    \
  V(_ObjectArray, get:length, ObjectArrayLength, 405297088)                    \
  V(_ImmutableArray, get:length, ImmutableArrayLength, 433698233)              \
  V(_TypedList, get:length, TypedDataLength, 1004567191)                       \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 728842615)                     \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 728842615)                   \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 728842615)                   \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 728842615)                 \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 728842615)                   \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 728842615)                 \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 1067360925)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 1067360925)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 279982060)           \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 427754869)                     \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 427754869)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 427754869)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 427754869)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 427754869)                   \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 427754869)                 \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 637235443)               \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 637235443)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 780994886)           \
  V(_GrowableObjectArray, get:length, GrowableArrayLength, 725548050)          \
  V(_GrowableObjectArray, get:_capacity, GrowableArrayCapacity, 725548050)     \
  V(_StringBase, get:length, StringBaseLength, 320803993)                      \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 110631520)                    \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 984449525)                  \
  V(_StringBase, [], StringBaseCharAt, 1062366987)                             \
  V(_OneByteString, _setAt, OneByteStringSetAt, 342452817)                     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 1331752138)             \
  V(_Double, toInt, DoubleToInteger, 362666636)                                \
  V(_Double, truncateToDouble, DoubleTruncate, 620870996)                      \
  V(_Double, roundToDouble, DoubleRound, 620870996)                            \
  V(_Double, floorToDouble, DoubleFloor, 620870996)                            \
  V(_Double, ceilToDouble, DoubleCeil, 620870996)                              \
  V(_Double, pow, DoublePow, 102305574)                                        \
  V(_Double, _modulo, DoubleMod, 437099337)                                    \
  V(::, sqrt, MathSqrt, 1662640002)                                            \
  V(Float32x4, Float32x4., Float32x4Constructor, 1492157358)                   \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 444339161)                       \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 1843231403)                    \
  V(_Float32x4, get:xxxx, Float32x4ShuffleXXXX, 42621627)                      \
  V(_Float32x4, get:yyyy, Float32x4ShuffleYYYY, 42621627)                      \
  V(_Float32x4, get:zzzz, Float32x4ShuffleZZZZ, 42621627)                      \
  V(_Float32x4, get:wwww, Float32x4ShuffleWWWW, 42621627)                      \
  V(_Float32x4, get:x, Float32x4ShuffleX, 211144022)                           \
  V(_Float32x4, get:y, Float32x4ShuffleY, 211144022)                           \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 211144022)                           \
  V(_Float32x4, get:w, Float32x4ShuffleW, 211144022)                           \
  V(_Float32x4, _cmpequal, Float32x4Equal, 548944488)                          \
  V(_Float32x4, _cmpgt, Float32x4GreaterThan, 548944488)                       \
  V(_Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, 548944488)               \
  V(_Float32x4, _cmplt, Float32x4LessThan, 548944488)                          \
  V(_Float32x4, _cmplte, Float32x4LessThanOrEqual, 548944488)                  \
  V(_Float32x4, _cmpnequal, Float32x4NotEqual, 548944488)                      \
  V(_Float32x4, _min, Float32x4Min, 342800599)                                 \
  V(_Float32x4, _max, Float32x4Max, 342800599)                                 \
  V(_Float32x4, _scale, Float32x4Scale, 219466242)                             \
  V(_Float32x4, _sqrt, Float32x4Sqrt, 42621627)                                \
  V(_Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, 42621627)            \
  V(_Float32x4, _reciprocal, Float32x4Reciprocal, 42621627)                    \
  V(_Float32x4, _negate, Float32x4Negate, 42621627)                            \
  V(_Float32x4, _abs, Float32x4Absolute, 42621627)                             \
  V(_Float32x4, _clamp, Float32x4Clamp, 615895313)                             \
  V(_Float32x4, withX, Float32x4WithX, 219466242)                              \
  V(_Float32x4, withY, Float32x4WithY, 219466242)                              \
  V(_Float32x4, withZ, Float32x4WithZ, 219466242)                              \
  V(_Float32x4, withW, Float32x4WithW, 219466242)                              \
  V(_Float32x4, _toUint32x4, Float32x4ToUint32x4, 1044409108)                  \
  V(Uint32x4, Uint32x4.bool, Uint32x4BoolConstructor, 487876159)               \
  V(_Uint32x4, get:flagX, Uint32x4GetFlagX, 782547529)                         \
  V(_Uint32x4, get:flagY, Uint32x4GetFlagY, 782547529)                         \
  V(_Uint32x4, get:flagZ, Uint32x4GetFlagZ, 782547529)                         \
  V(_Uint32x4, get:flagW, Uint32x4GetFlagW, 782547529)                         \
  V(_Uint32x4, select, Uint32x4Select, 810336099)                              \
  V(_Uint32x4, withFlagX, Uint32x4WithFlagX, 980864994)                        \
  V(_Uint32x4, withFlagY, Uint32x4WithFlagY, 980864994)                        \
  V(_Uint32x4, withFlagZ, Uint32x4WithFlagZ, 980864994)                        \
  V(_Uint32x4, withFlagW, Uint32x4WithFlagW, 980864994)                        \
  V(_Uint32x4, _toFloat32x4, Uint32x4ToUint32x4, 311564070)                    \


// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, fp) k##enum_name,
RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
  };

  static Kind RecognizeKind(const Function& function);
  static const char* KindToCString(Kind kind);
};


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
class CompileType : public ValueObject {
 public:
  static const bool kNullable = true;
  static const bool kNonNullable = false;

  CompileType(bool is_nullable, intptr_t cid, const AbstractType* type)
      : is_nullable_(is_nullable), cid_(cid), type_(type) { }

  CompileType(const CompileType& other)
      : ValueObject(),
        is_nullable_(other.is_nullable_),
        cid_(other.cid_),
        type_(other.type_) { }

  CompileType& operator=(const CompileType& other) {
    is_nullable_ = other.is_nullable_;
    cid_ = other.cid_;
    type_ =  other.type_;
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
    return CanComputeIsInstanceOf(type, kNullable, &is_instance) &&
           is_instance;
  }

  // Create a new CompileType representing given combination of class id and
  // abstract type. The pair is assumed to be coherent.
  static CompileType Create(intptr_t cid, const AbstractType& type);

  CompileType CopyNonNullable() const {
    return CompileType(kNonNullable, cid_, type_);
  }

  static CompileType CreateNullable(bool is_nullable, intptr_t cid) {
    return CompileType(is_nullable, cid, NULL);
  }

  // Create a new CompileType representing given abstract type. By default
  // values as assumed to be nullable.
  static CompileType FromAbstractType(const AbstractType& type,
                                       bool is_nullable = kNullable);

  // Create a new CompileType representing an value with the given class id.
  // Resulting CompileType is nullable only if cid is kDynamicCid or kNullCid.
  static CompileType FromCid(intptr_t cid);

  // Create None CompileType. It is the bottom of the lattice and is used to
  // represent type of the phi that was not yet inferred.
  static CompileType None() {
    return CompileType(true, kIllegalCid, NULL);
  }

  // Create Dynamic CompileType. It is the top of the lattice and is used to
  // represent unknown type.
  static CompileType Dynamic();

  static CompileType Null();

  // Create non-nullable Bool type.
  static CompileType Bool();

  // Create non-nullable Int type.
  static CompileType Int();

  // Perform a join operation over the type lattice.
  void Union(CompileType* other);

  // Returns true if this and other types are the same.
  bool IsEqualTo(CompileType* other) {
    return (is_nullable_ == other->is_nullable_) &&
        (ToNullableCid() == other->ToNullableCid()) &&
        (ToAbstractType()->Equals(*other->ToAbstractType()));
  }

  bool IsNone() const {
    return (cid_ == kIllegalCid) && (type_ == NULL);
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


// Zone allocated wrapper for the CompileType value.
class ZoneCompileType : public ZoneAllocated {
 public:
  static CompileType* Wrap(const CompileType& type) {
    ZoneCompileType* zone_type = new ZoneCompileType(type);
    return zone_type->ToCompileType();
  }

  CompileType* ToCompileType() {
    return &type_;
  }

 protected:
  explicit ZoneCompileType(const CompileType& type) : type_(type) { }

  CompileType type_;
};


// ConstrainedCompileType represents a compile type that is computed from
// another compile type.
class ConstrainedCompileType : public ZoneCompileType {
 public:
  // Recompute compile type.
  virtual void Update() = 0;

 protected:
  explicit ConstrainedCompileType(const CompileType& type)
      : ZoneCompileType(type) { }
};


// NotNullConstrainedCompileType represents not-null constraint applied to
// the source compile type. Result is non-nullable version of the incomming
// compile type. It is used to represent compile type propagated downwards
// from strict comparison with the null constant.
class NotNullConstrainedCompileType : public ConstrainedCompileType {
 public:
  explicit NotNullConstrainedCompileType(CompileType* source)
      : ConstrainedCompileType(source->CopyNonNullable()), source_(source) { }

  virtual void Update() {
    type_ = source_->CopyNonNullable();
  }

 private:
  CompileType* source_;
};


class EffectSet : public ValueObject {
 public:
  enum Effects {
    kNoEffects = 0,
    kExternalization = 1,
    kLastEffect = kExternalization
  };

  EffectSet(const EffectSet& other)
      : ValueObject(), effects_(other.effects_) {
  }

  bool IsNone() const { return effects_ == kNoEffects; }

  static EffectSet None() { return EffectSet(kNoEffects); }
  static EffectSet All() {
    ASSERT(EffectSet::kLastEffect == 1);
    return EffectSet(kExternalization);
  }

  static EffectSet Externalization() {
    return EffectSet(kExternalization);
  }

  bool ToInt() { return effects_; }

 private:
  explicit EffectSet(intptr_t effects) : effects_(effects) { }

  intptr_t effects_;
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
        reaching_type_(NULL) { }

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

  Value* Copy() { return new Value(definition_); }

  // This function must only be used when the new Value is dominated by
  // the original Value.
  Value* CopyWithType() {
    Value* copy = new Value(definition_);
    copy->reaching_type_ = reaching_type_;
    return copy;
  }

  CompileType* Type();

  void SetReachingType(CompileType* type) {
    reaching_type_ = type;
  }

  void PrintTo(BufferFormatter* f) const;

  const char* DebugName() const { return "Value"; }

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
template<typename T, intptr_t N>
class EmbeddedArray {
 public:
  EmbeddedArray() : elements_() { }

  intptr_t length() const { return N; }

  const T& operator[](intptr_t i) const {
    ASSERT(i < length());
    return elements_[i];
  }

  T& operator[](intptr_t i) {
    ASSERT(i < length());
    return elements_[i];
  }

  const T& At(intptr_t i) const {
    return (*this)[i];
  }

  void SetAt(intptr_t i, const T& val) {
    (*this)[i] = val;
  }

 private:
  T elements_[N];
};


template<typename T>
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
  M(CatchBlockEntry)                                                           \
  M(Phi)                                                                       \
  M(Redefinition)                                                              \
  M(Parameter)                                                                 \
  M(ParallelMove)                                                              \
  M(PushArgument)                                                              \
  M(Return)                                                                    \
  M(Throw)                                                                     \
  M(ReThrow)                                                                   \
  M(Goto)                                                                      \
  M(Branch)                                                                    \
  M(AssertAssignable)                                                          \
  M(AssertBoolean)                                                             \
  M(ArgumentDefinitionTest)                                                    \
  M(CurrentContext)                                                            \
  M(StoreContext)                                                              \
  M(ClosureCall)                                                               \
  M(InstanceCall)                                                              \
  M(PolymorphicInstanceCall)                                                   \
  M(StaticCall)                                                                \
  M(LoadLocal)                                                                 \
  M(PushTemp)                                                                  \
  M(DropTemps)                                                                 \
  M(StoreLocal)                                                                \
  M(StrictCompare)                                                             \
  M(EqualityCompare)                                                           \
  M(RelationalOp)                                                              \
  M(NativeCall)                                                                \
  M(LoadIndexed)                                                               \
  M(StoreIndexed)                                                              \
  M(StoreInstanceField)                                                        \
  M(LoadStaticField)                                                           \
  M(StoreStaticField)                                                          \
  M(BooleanNegate)                                                             \
  M(InstanceOf)                                                                \
  M(CreateArray)                                                               \
  M(CreateClosure)                                                             \
  M(AllocateObject)                                                            \
  M(AllocateObjectWithBoundsCheck)                                             \
  M(LoadField)                                                                 \
  M(StoreVMField)                                                              \
  M(LoadUntagged)                                                              \
  M(LoadClassId)                                                               \
  M(InstantiateTypeArguments)                                                  \
  M(ExtractConstructorTypeArguments)                                           \
  M(ExtractConstructorInstantiator)                                            \
  M(AllocateContext)                                                           \
  M(ChainContext)                                                              \
  M(CloneContext)                                                              \
  M(CatchEntry)                                                                \
  M(BinarySmiOp)                                                               \
  M(UnarySmiOp)                                                                \
  M(CheckStackOverflow)                                                        \
  M(SmiToDouble)                                                               \
  M(DoubleToInteger)                                                           \
  M(DoubleToSmi)                                                               \
  M(DoubleToDouble)                                                            \
  M(CheckClass)                                                                \
  M(CheckSmi)                                                                  \
  M(Constant)                                                                  \
  M(CheckEitherNonSmi)                                                         \
  M(BinaryDoubleOp)                                                            \
  M(MathSqrt)                                                                  \
  M(UnboxDouble)                                                               \
  M(BoxDouble)                                                                 \
  M(BoxFloat32x4)                                                              \
  M(UnboxFloat32x4)                                                            \
  M(BoxUint32x4)                                                               \
  M(UnboxUint32x4)                                                             \
  M(UnboxInteger)                                                              \
  M(BoxInteger)                                                                \
  M(BinaryMintOp)                                                              \
  M(ShiftMintOp)                                                               \
  M(UnaryMintOp)                                                               \
  M(CheckArrayBound)                                                           \
  M(Constraint)                                                                \
  M(StringFromCharCode)                                                        \
  M(InvokeMathCFunction)                                                       \
  M(GuardField)                                                                \
  M(IfThenElse)                                                                \
  M(BinaryFloat32x4Op)                                                         \
  M(Float32x4Shuffle)                                                          \
  M(Float32x4Constructor)                                                      \
  M(Float32x4Zero)                                                             \
  M(Float32x4Splat)                                                            \
  M(Float32x4Comparison)                                                       \
  M(Float32x4MinMax)                                                           \
  M(Float32x4Scale)                                                            \
  M(Float32x4Sqrt)                                                             \
  M(Float32x4ZeroArg)                                                          \
  M(Float32x4Clamp)                                                            \
  M(Float32x4With)                                                             \
  M(Float32x4ToUint32x4)                                                       \
  M(MaterializeObject)                                                         \
  M(Uint32x4BoolConstructor)                                                   \
  M(Uint32x4GetFlag)                                                           \
  M(Uint32x4Select)                                                            \
  M(Uint32x4SetFlag)                                                           \
  M(Uint32x4ToFloat32x4)                                                       \
  M(BinaryUint32x4Op)                                                          \


#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION


// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                                              \
  virtual Tag tag() const { return k##type; }                                  \
  virtual void Accept(FlowGraphVisitor* visitor);                              \
  virtual type##Instr* As##type() { return this; }                             \
  virtual const char* DebugName() const { return #type; }                      \
  virtual LocationSummary* MakeLocationSummary() const;                        \
  virtual void EmitNativeCode(FlowGraphCompiler* compiler);                    \


class Instruction : public ZoneAllocated {
 public:
#define DECLARE_TAG(type) k##type,
  enum Tag {
    FOR_EACH_INSTRUCTION(DECLARE_TAG)
  };
#undef DECLARE_TAG

  Instruction()
      : deopt_id_(Isolate::Current()->GetNextDeoptId()),
        lifetime_position_(-1),
        previous_(NULL),
        next_(NULL),
        env_(NULL),
        expr_id_(kNoExprId) { }

  virtual Tag tag() const = 0;

  intptr_t deopt_id() const {
    ASSERT(CanDeoptimize() || CanBecomeDeoptimizationTarget());
    return deopt_id_;
  }

  ICData* GetICData(const Array& ic_data_array) const;

  bool IsBlockEntry() { return (AsBlockEntry() != NULL); }
  virtual BlockEntryInstr* AsBlockEntry() { return NULL; }

  bool IsDefinition() { return (AsDefinition() != NULL); }
  virtual Definition* AsDefinition() { return NULL; }

  bool IsControl() { return (AsControl() != NULL); }
  virtual ControlInstruction* AsControl() { return NULL; }

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
  virtual intptr_t ArgumentCount() const = 0;
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    UNREACHABLE();
    return NULL;
  }
  inline Definition* ArgumentAt(intptr_t index) const;

  // Returns true, if this instruction can deoptimize.
  virtual bool CanDeoptimize() const = 0;

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
    ASSERT(!IsControl() || (instr == NULL));
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

  // Printing support.
  virtual void PrintTo(BufferFormatter* f) const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;

#define INSTRUCTION_TYPE_CHECK(type)                                           \
  bool Is##type() { return (As##type() != NULL); }                             \
  virtual type##Instr* As##type() { return NULL; }
FOR_EACH_INSTRUCTION(INSTRUCTION_TYPE_CHECK)
#undef INSTRUCTION_TYPE_CHECK

  // Returns structure describing location constraints required
  // to emit native code for this instruction.
  virtual LocationSummary* locs() {
    // TODO(vegorov): This should be pure virtual method.
    // However we are temporary using NULL for instructions that
    // were not converted to the location based code generation yet.
    return NULL;
  }

  virtual LocationSummary* MakeLocationSummary() const = 0;

  static LocationSummary* MakeCallSummary();

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    UNIMPLEMENTED();
  }

  Environment* env() const { return env_; }
  void SetEnvironment(Environment* deopt_env);
  void RemoveEnvironment();

  intptr_t lifetime_position() const { return lifetime_position_; }
  void set_lifetime_position(intptr_t pos) {
    lifetime_position_ = pos;
  }

  // Returns representation expected for the input operand at the given index.
  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    return kTagged;
  }

  // Representation of the value produced by this computation.
  virtual Representation representation() const {
    return kTagged;
  }

  bool WasEliminated() const {
    return next() == NULL;
  }

  // Returns deoptimization id that corresponds to the deoptimization target
  // that input operands conversions inserted for this instruction can jump
  // to.
  virtual intptr_t DeoptimizationTarget() const {
    UNREACHABLE();
    return Isolate::kNoDeoptId;
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
  virtual bool AllowsCSE() const {
    return false;
  }

  // Returns set of effects created by this instruction.
  virtual EffectSet Effects() const = 0;

  // Returns set of effects that affect this instruction.
  virtual EffectSet Dependencies() const {
    UNREACHABLE();
    return EffectSet::All();
  }

  // Get the block entry for this instruction.
  virtual BlockEntryInstr* GetBlock() const;

  // Id for load instructions used during load forwarding pass and later in
  // LICM.
  intptr_t expr_id() const { return expr_id_; }
  void set_expr_id(intptr_t expr_id) { expr_id_ = expr_id; }
  bool HasExprId() const { return expr_id_ != kNoExprId; }

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

  virtual void InheritDeoptTarget(Instruction* other);

  bool NeedsEnvironment() const {
    return CanDeoptimize() || CanBecomeDeoptimizationTarget();
  }

  virtual bool CanBecomeDeoptimizationTarget() const {
    return false;
  }

  void InheritDeoptTargetAfter(Instruction* other);

  virtual bool MayThrow() const = 0;

 protected:
  // Fetch deopt id without checking if this computation can deoptimize.
  intptr_t GetDeoptId() const {
    return deopt_id_;
  }

 private:
  friend class Definition;  // Needed for InsertBefore, InsertAfter.

  // Classes that set or read deopt_id_.
  friend class UnboxIntegerInstr;
  friend class UnboxDoubleInstr;
  friend class UnboxFloat32x4Instr;
  friend class UnboxUint32x4Instr;
  friend class BinaryDoubleOpInstr;
  friend class BinaryFloat32x4OpInstr;
  friend class Float32x4ZeroInstr;
  friend class Float32x4SplatInstr;
  friend class Float32x4ShuffleInstr;
  friend class Float32x4ConstructorInstr;
  friend class Float32x4ComparisonInstr;
  friend class Float32x4MinMaxInstr;
  friend class Float32x4ScaleInstr;
  friend class Float32x4SqrtInstr;
  friend class Float32x4ZeroArgInstr;
  friend class Float32x4ClampInstr;
  friend class Float32x4WithInstr;
  friend class Float32x4ToUint32x4Instr;
  friend class Uint32x4BoolConstructorInstr;
  friend class Uint32x4GetFlagInstr;
  friend class Uint32x4SetFlagInstr;
  friend class Uint32x4SelectInstr;
  friend class Uint32x4ToFloat32x4Instr;
  friend class BinaryUint32x4OpInstr;
  friend class BinaryMintOpInstr;
  friend class BinarySmiOpInstr;
  friend class UnarySmiOpInstr;
  friend class ShiftMintOpInstr;
  friend class UnaryMintOpInstr;
  friend class MathSqrtInstr;
  friend class CheckClassInstr;
  friend class GuardFieldInstr;
  friend class CheckSmiInstr;
  friend class CheckArrayBoundInstr;
  friend class CheckEitherNonSmiInstr;
  friend class LICM;
  friend class DoubleToSmiInstr;
  friend class DoubleToDoubleInstr;
  friend class InvokeMathCFunctionInstr;
  friend class FlowGraphOptimizer;
  friend class LoadIndexedInstr;
  friend class StoreIndexedInstr;
  friend class StoreInstanceFieldInstr;
  friend class ControlInstruction;
  friend class ComparisonInstr;
  friend class TargetEntryInstr;
  friend class JoinEntryInstr;
  friend class InstanceOfInstr;
  friend class PolymorphicInstanceCallInstr;
  friend class SmiToDoubleInstr;
  friend class DoubleToIntegerInstr;
  friend class BranchSimplifier;
  friend class BlockEntryInstr;

  virtual void RawSetInputAt(intptr_t i, Value* value) = 0;

  enum {
    kNoExprId = -1
  };

  intptr_t deopt_id_;
  intptr_t lifetime_position_;  // Position used by register allocator.
  Instruction* previous_;
  Instruction* next_;
  Environment* env_;
  intptr_t expr_id_;

  DISALLOW_COPY_AND_ASSIGN(Instruction);
};


template<intptr_t N>
class TemplateInstruction: public Instruction {
 public:
  TemplateInstruction<N>() : locs_(NULL) { }

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    inputs_[i] = value;
  }

  LocationSummary* locs_;
};


class MoveOperands : public ZoneAllocated {
 public:
  MoveOperands(Location dest, Location src) : dest_(dest), src_(src) { }

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


class ParallelMoveInstr : public TemplateInstruction<0> {
 public:
  ParallelMoveInstr() : moves_(4) { }

  DECLARE_INSTRUCTION(ParallelMove)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const {
    UNREACHABLE();  // This instruction never visited by optimization passes.
    return EffectSet::None();
  }

  virtual EffectSet Dependencies() const {
    UNREACHABLE();  // This instruction never visited by optimization passes.
    return EffectSet::None();
  }

  MoveOperands* AddMove(Location dest, Location src) {
    MoveOperands* move = new MoveOperands(dest, src);
    moves_.Add(move);
    return move;
  }

  MoveOperands* MoveOperandsAt(intptr_t index) const { return moves_[index]; }

  intptr_t NumMoves() const { return moves_.length(); }

  virtual void PrintTo(BufferFormatter* f) const;

  virtual bool MayThrow() const { return false; }

 private:
  GrowableArray<MoveOperands*> moves_;   // Elements cannot be null.

  DISALLOW_COPY_AND_ASSIGN(ParallelMoveInstr);
};


// Basic block entries are administrative nodes.  There is a distinguished
// graph entry with no predecessor.  Joins are the only nodes with multiple
// predecessors.  Targets are all other basic block entries.  The types
// enforce edge-split form---joins are forbidden as the successors of
// branches.
class BlockEntryInstr : public Instruction {
 public:
  virtual BlockEntryInstr* AsBlockEntry() { return this; }

  virtual intptr_t PredecessorCount() const = 0;
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const = 0;

  intptr_t preorder_number() const { return preorder_number_; }
  void set_preorder_number(intptr_t number) { preorder_number_ = number; }

  intptr_t postorder_number() const { return postorder_number_; }
  void set_postorder_number(intptr_t number) { postorder_number_ = number; }

  intptr_t block_id() const { return block_id_; }

  void set_start_pos(intptr_t pos) { start_pos_ = pos; }
  intptr_t start_pos() const { return start_pos_; }
  void  set_end_pos(intptr_t pos) { end_pos_ = pos; }
  intptr_t end_pos() const { return end_pos_; }

  BlockEntryInstr* dominator() const { return dominator_; }

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

  ParallelMoveInstr* parallel_move() const {
    return parallel_move_;
  }

  bool HasParallelMove() const {
    return parallel_move_ != NULL;
  }

  ParallelMoveInstr* GetParallelMove() {
    if (parallel_move_ == NULL) {
      parallel_move_ = new ParallelMoveInstr();
    }
    return parallel_move_;
  }

  // Discover basic-block structure by performing a recursive depth first
  // traversal of the instruction graph reachable from this instruction.  As
  // a side effect, the block entry instructions in the graph are assigned
  // numbers in both preorder and postorder.  The array 'preorder' maps
  // preorder block numbers to the block entry instruction with that number
  // and analogously for the array 'postorder'.  The depth first spanning
  // tree is recorded in the array 'parent', which maps preorder block
  // numbers to the preorder number of the block's spanning-tree parent.
  // The array 'assigned_vars' maps preorder block numbers to the set of
  // assigned frame-allocated local variables in the block.  As a side
  // effect of this function, the set of basic block predecessors (e.g.,
  // block entry instructions of predecessor blocks) and also the last
  // instruction in the block is recorded in each entry instruction.
  void DiscoverBlocks(
      BlockEntryInstr* predecessor,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      intptr_t variable_count,
      intptr_t fixed_parameter_count);

  // Perform a depth first search to prune code not reachable from an OSR
  // entry point.
  bool PruneUnreachable(FlowGraphBuilder* builder,
                        GraphEntryInstr* graph_entry,
                        intptr_t osr_id,
                        BitVector* block_marks);

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

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

  intptr_t try_index() const { return try_index_; }

  // True for blocks inside a try { } region.
  bool InsideTryBlock() const {
    return try_index_ != CatchClauseNode::kInvalidTryIndex;
  }

  BitVector* loop_info() const { return loop_info_; }
  void set_loop_info(BitVector* loop_info) {
    loop_info_ = loop_info;
  }

  virtual BlockEntryInstr* GetBlock() const {
    return const_cast<BlockEntryInstr*>(this);
  }

  // Helper to mutate the graph during inlining. This block should be
  // replaced with new_block as a predecessor of all of this block's
  // successors.
  void ReplaceAsPredecessorWith(BlockEntryInstr* new_block);

  void set_block_id(intptr_t block_id) { block_id_ = block_id; }

 protected:
  BlockEntryInstr(intptr_t block_id, intptr_t try_index)
      : block_id_(block_id),
        try_index_(try_index),
        preorder_number_(-1),
        postorder_number_(-1),
        dominator_(NULL),
        dominated_blocks_(1),
        last_instruction_(NULL),
        parallel_move_(NULL),
        loop_info_(NULL) { }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  virtual void ClearPredecessors() = 0;
  virtual void AddPredecessor(BlockEntryInstr* predecessor) = 0;

  void set_dominator(BlockEntryInstr* instr) { dominator_ = instr; }

  intptr_t block_id_;
  const intptr_t try_index_;
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

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the start of the block.
  ParallelMoveInstr* parallel_move_;

  // Bit vector containg loop blocks for a loop header indexed by block
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

  GrowableArray<Definition*>* initial_definitions() {
    return &initial_definitions_;
  }
  ConstantInstr* constant_null();

  bool IsCompiledForOsr() const { return osr_id_ != Isolate::kNoDeoptId; }

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

  const ParsedFunction& parsed_function() const {
    return parsed_function_;
  }

  const GrowableArray<CatchBlockEntryInstr*>& catch_entries() const {
    return catch_entries_;
  }

  virtual void PrintTo(BufferFormatter* f) const;

 private:
  virtual void ClearPredecessors() {}
  virtual void AddPredecessor(BlockEntryInstr* predecessor) { UNREACHABLE(); }

  const ParsedFunction& parsed_function_;
  TargetEntryInstr* normal_entry_;
  GrowableArray<CatchBlockEntryInstr*> catch_entries_;
  GrowableArray<Definition*> initial_definitions_;
  const intptr_t osr_id_;
  intptr_t spill_slot_count_;
  intptr_t fixed_slot_count_;  // For try-catch in optimized code.

  DISALLOW_COPY_AND_ASSIGN(GraphEntryInstr);
};


class JoinEntryInstr : public BlockEntryInstr {
 public:
  JoinEntryInstr(intptr_t block_id, intptr_t try_index)
      : BlockEntryInstr(block_id, try_index),
        predecessors_(2),  // Two is the assumed to be the common case.
        phis_(NULL) { }

  DECLARE_INSTRUCTION(JoinEntry)

  virtual intptr_t PredecessorCount() const { return predecessors_.length(); }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    return predecessors_[index];
  }

  // Returns -1 if pred is not in the list.
  intptr_t IndexOfPredecessor(BlockEntryInstr* pred) const;

  ZoneGrowableArray<PhiInstr*>* phis() const { return phis_; }

  void InsertPhi(intptr_t var_index, intptr_t var_count);
  void RemoveDeadPhis(Definition* replacement);

  void InsertPhi(PhiInstr* phi);

  virtual void PrintTo(BufferFormatter* f) const;

  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }

 private:
  // Classes that have access to predecessors_ when inlining.
  friend class BlockEntryInstr;
  friend class InlineExitCollector;
  friend class PolymorphicInliner;

  // Direct access to phis_ in order to resize it due to phi elimination.
  friend class ConstantPropagator;

  virtual void ClearPredecessors() { predecessors_.Clear(); }
  virtual void AddPredecessor(BlockEntryInstr* predecessor);

  GrowableArray<BlockEntryInstr*> predecessors_;
  ZoneGrowableArray<PhiInstr*>* phis_;

  DISALLOW_COPY_AND_ASSIGN(JoinEntryInstr);
};


class PhiIterator : public ValueObject {
 public:
  explicit PhiIterator(JoinEntryInstr* join)
      : phis_(join->phis()), index_(0) { }

  void Advance() {
    ASSERT(!Done());
    index_++;
  }

  bool Done() const {
    return (phis_ == NULL) || (index_ >= phis_->length());
  }

  PhiInstr* Current() const {
    return (*phis_)[index_];
  }

 private:
  ZoneGrowableArray<PhiInstr*>* phis_;
  intptr_t index_;
};


class TargetEntryInstr : public BlockEntryInstr {
 public:
  TargetEntryInstr(intptr_t block_id, intptr_t try_index)
      : BlockEntryInstr(block_id, try_index), predecessor_(NULL) { }

  DECLARE_INSTRUCTION(TargetEntry)

  virtual intptr_t PredecessorCount() const {
    return (predecessor_ == NULL) ? 0 : 1;
  }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    ASSERT((index == 0) && (predecessor_ != NULL));
    return predecessor_;
  }

  virtual void PrintTo(BufferFormatter* f) const;

 private:
  friend class BlockEntryInstr;  // Access to predecessor_ when inlining.

  virtual void ClearPredecessors() { predecessor_ = NULL; }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    ASSERT(predecessor_ == NULL);
    predecessor_ = predecessor;
  }

  BlockEntryInstr* predecessor_;

  DISALLOW_COPY_AND_ASSIGN(TargetEntryInstr);
};


class CatchBlockEntryInstr : public BlockEntryInstr {
 public:
  CatchBlockEntryInstr(intptr_t block_id,
                       intptr_t try_index,
                       const Array& handler_types,
                       intptr_t catch_try_index)
      : BlockEntryInstr(block_id, try_index),
        predecessor_(NULL),
        catch_handler_types_(Array::ZoneHandle(handler_types.raw())),
        catch_try_index_(catch_try_index) { }

  DECLARE_INSTRUCTION(CatchBlockEntry)

  virtual intptr_t PredecessorCount() const {
    return (predecessor_ == NULL) ? 0 : 1;
  }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    ASSERT((index == 0) && (predecessor_ != NULL));
    return predecessor_;
  }

  // Returns try index for the try block to which this catch handler
  // corresponds.
  intptr_t catch_try_index() const {
    return catch_try_index_;
  }
  GrowableArray<Definition*>* initial_definitions() {
    return &initial_definitions_;
  }

  virtual void PrintTo(BufferFormatter* f) const;

 private:
  friend class BlockEntryInstr;  // Access to predecessor_ when inlining.

  virtual void ClearPredecessors() { predecessor_ = NULL; }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    ASSERT(predecessor_ == NULL);
    predecessor_ = predecessor;
  }

  BlockEntryInstr* predecessor_;
  const Array& catch_handler_types_;
  const intptr_t catch_try_index_;
  GrowableArray<Definition*> initial_definitions_;

  DISALLOW_COPY_AND_ASSIGN(CatchBlockEntryInstr);
};


// Abstract super-class of all instructions that define a value (Bind, Phi).
class Definition : public Instruction {
 public:
  enum UseKind { kEffect, kValue };

  Definition();

  virtual Definition* AsDefinition() { return this; }

  bool IsComparison() { return (AsComparison() != NULL); }
  virtual ComparisonInstr* AsComparison() { return NULL; }

  // Overridden by definitions that push arguments.
  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t temp_index() const { return temp_index_; }
  void set_temp_index(intptr_t index) { temp_index_ = index; }
  void ClearTempIndex() { temp_index_ = -1; }

  intptr_t ssa_temp_index() const { return ssa_temp_index_; }
  void set_ssa_temp_index(intptr_t index) {
    ASSERT(index >= 0);
    ASSERT(is_used());
    ssa_temp_index_ = index;
  }
  bool HasSSATemp() const { return ssa_temp_index_ >= 0; }
  void ClearSSATempIndex() { ssa_temp_index_ = -1; }

  bool is_used() const { return (use_kind_ != kEffect); }
  void set_use_kind(UseKind kind) { use_kind_ = kind; }

  // Compile time type of the definition, which may be requested before type
  // propagation during graph building.
  CompileType* Type() {
    if (type_ == NULL) {
      type_ = ComputeInitialType();
    }
    return type_;
  }

  virtual CompileType* ComputeInitialType() const {
    return ZoneCompileType::Wrap(ComputeType());
  }

  // Compute compile type for this definition. It is safe to use this
  // approximation even before type propagator was run (e.g. during graph
  // building).
  virtual CompileType ComputeType() const {
    return CompileType::Dynamic();
  }

  // Update CompileType of the definition. Returns true if the type has changed.
  virtual bool RecomputeType() {
    return false;
  }

  bool UpdateType(CompileType new_type) {
    if (type_ == NULL) {
      type_ = ZoneCompileType::Wrap(new_type);
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

  // Printing support. These functions are sometimes overridden for custom
  // formatting. Otherwise, it prints in the format "opcode(op1, op2, op3)".
  virtual void PrintTo(BufferFormatter* f) const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;

  // A value in the constant propagation lattice.
  //    - non-constant sentinel
  //    - a constant (any non-sentinel value)
  //    - unknown sentinel
  Object& constant_value() const { return constant_value_; }

  virtual void InferRange();

  Range* range() const { return range_; }

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

 protected:
  friend class RangeAnalysis;

  Range* range_;
  CompileType* type_;

 private:
  intptr_t temp_index_;
  intptr_t ssa_temp_index_;
  Value* input_use_list_;
  Value* env_use_list_;
  UseKind use_kind_;

  Object& constant_value_;

  DISALLOW_COPY_AND_ASSIGN(Definition);
};


// Change a value's definition after use lists have been computed.
inline void Value::BindTo(Definition* def) {
  RemoveFromUseList();
  set_definition(def);
  def->AddInputUse(this);
}


class PhiInstr : public Definition {
 public:
  PhiInstr(JoinEntryInstr* block, intptr_t num_inputs)
    : block_(block),
      inputs_(num_inputs),
      is_alive_(false),
      representation_(kTagged),
      reaching_defs_(NULL) {
    for (intptr_t i = 0; i < num_inputs; ++i) {
      inputs_.Add(NULL);
    }
  }

  // Get the block entry for that instruction.
  virtual BlockEntryInstr* GetBlock() const { return block(); }
  JoinEntryInstr* block() const { return block_; }

  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t InputCount() const { return inputs_.length(); }

  Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  // Phi is alive if it reaches a non-environment use.
  bool is_alive() const { return is_alive_; }
  void mark_alive() { is_alive_ = true; }

  virtual Representation RequiredInputRepresentation(intptr_t i) const {
    return representation_;
  }

  virtual Representation representation() const {
    return representation_;
  }

  virtual void set_representation(Representation r) {
    representation_ = r;
  }

  virtual intptr_t Hashcode() const {
    UNREACHABLE();
    return 0;
  }

  DECLARE_INSTRUCTION(Phi)

  virtual void PrintTo(BufferFormatter* f) const;

  virtual void InferRange();

  BitVector* reaching_defs() const {
    return reaching_defs_;
  }

  void set_reaching_defs(BitVector* reaching_defs) {
    reaching_defs_ = reaching_defs;
  }

  virtual bool MayThrow() const { return false; }

 private:
  // Direct access to inputs_ in order to resize it due to unreachable
  // predecessors.
  friend class ConstantPropagator;

  void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }

  JoinEntryInstr* block_;
  GrowableArray<Value*> inputs_;
  bool is_alive_;
  Representation representation_;

  BitVector* reaching_defs_;

  DISALLOW_COPY_AND_ASSIGN(PhiInstr);
};


class ParameterInstr : public Definition {
 public:
  ParameterInstr(intptr_t index, BlockEntryInstr* block)
      : index_(index), block_(block) { }

  DECLARE_INSTRUCTION(Parameter)

  intptr_t index() const { return index_; }

  // Get the block entry for that instruction.
  virtual BlockEntryInstr* GetBlock() const { return block_; }

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t InputCount() const { return 0; }
  Value* InputAt(intptr_t i) const {
    UNREACHABLE();
    return NULL;
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }

  virtual intptr_t Hashcode() const {
    UNREACHABLE();
    return 0;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual CompileType ComputeType() const;

  virtual bool MayThrow() const { return false; }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  const intptr_t index_;
  BlockEntryInstr* block_;

  DISALLOW_COPY_AND_ASSIGN(ParameterInstr);
};


class PushArgumentInstr : public Definition {
 public:
  explicit PushArgumentInstr(Value* value) : locs_(NULL) {
    SetInputAt(0, value);
    set_use_kind(kEffect);  // Override the default.
  }

  DECLARE_INSTRUCTION(PushArgument)

  intptr_t InputCount() const { return 1; }
  Value* InputAt(intptr_t i) const {
    ASSERT(i == 0);
    return value_;
  }

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual CompileType ComputeType() const;

  Value* value() const { return value_; }

  virtual LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  virtual intptr_t Hashcode() const {
    UNREACHABLE();
    return 0;
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool MayThrow() const { return false; }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    ASSERT(i == 0);
    value_ = value;
  }

  Value* value_;
  LocationSummary* locs_;

  DISALLOW_COPY_AND_ASSIGN(PushArgumentInstr);
};


inline Definition* Instruction::ArgumentAt(intptr_t index) const {
  return PushArgumentAt(index)->value()->definition();
}


class ReturnInstr : public TemplateInstruction<1> {
 public:
  ReturnInstr(intptr_t token_pos, Value* value)
      : token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Return)

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t token_pos() const { return token_pos_; }
  Value* value() const { return inputs_[0]; }

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Return instruction might turn into a Goto instruction after inlining.
    // Every Goto must have an environment.
    return true;
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ReturnInstr);
};


class ThrowInstr : public TemplateInstruction<0> {
 public:
  explicit ThrowInstr(intptr_t token_pos) : token_pos_(token_pos) { }

  DECLARE_INSTRUCTION(Throw)

  virtual intptr_t ArgumentCount() const { return 1; }

  intptr_t token_pos() const { return token_pos_; }

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ThrowInstr);
};


class ReThrowInstr : public TemplateInstruction<0> {
 public:
  explicit ReThrowInstr(intptr_t token_pos) : token_pos_(token_pos) { }

  DECLARE_INSTRUCTION(ReThrow)

  virtual intptr_t ArgumentCount() const { return 2; }

  intptr_t token_pos() const { return token_pos_; }

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ReThrowInstr);
};


class GotoInstr : public TemplateInstruction<0> {
 public:
  explicit GotoInstr(JoinEntryInstr* entry)
    : successor_(entry),
      parallel_move_(NULL) { }

  DECLARE_INSTRUCTION(Goto)

  virtual intptr_t ArgumentCount() const { return 0; }

  JoinEntryInstr* successor() const { return successor_; }
  void set_successor(JoinEntryInstr* successor) { successor_ = successor; }
  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  virtual bool CanBecomeDeoptimizationTarget() const {
    // Goto instruction can be used as a deoptimization target when LICM
    // hoists instructions out of the loop.
    return true;
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  ParallelMoveInstr* parallel_move() const {
    return parallel_move_;
  }

  bool HasParallelMove() const {
    return parallel_move_ != NULL;
  }

  ParallelMoveInstr* GetParallelMove() {
    if (parallel_move_ == NULL) {
      parallel_move_ = new ParallelMoveInstr();
    }
    return parallel_move_;
  }

  virtual void PrintTo(BufferFormatter* f) const;

  virtual bool MayThrow() const { return false; }

 private:
  JoinEntryInstr* successor_;

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the end of the block and resolve phis.
  ParallelMoveInstr* parallel_move_;
};


class ControlInstruction : public Instruction {
 public:
  ControlInstruction() : true_successor_(NULL), false_successor_(NULL) { }

  virtual ControlInstruction* AsControl() { return this; }

  TargetEntryInstr* true_successor() const { return true_successor_; }
  TargetEntryInstr* false_successor() const { return false_successor_; }

  TargetEntryInstr** true_successor_address() { return &true_successor_; }
  TargetEntryInstr** false_successor_address() { return &false_successor_; }

  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                             Condition true_condition);

  void EmitBranchOnValue(FlowGraphCompiler* compiler, bool result);

 private:
  TargetEntryInstr* true_successor_;
  TargetEntryInstr* false_successor_;

  DISALLOW_COPY_AND_ASSIGN(ControlInstruction);
};


class BranchInstr : public ControlInstruction {
 public:
  explicit BranchInstr(ComparisonInstr* comparison, bool is_checked = false);

  DECLARE_INSTRUCTION(Branch)

  virtual intptr_t ArgumentCount() const;
  intptr_t InputCount() const;
  Value* InputAt(intptr_t i) const;
  virtual bool CanDeoptimize() const;
  virtual bool CanBecomeDeoptimizationTarget() const;

  virtual EffectSet Effects() const;

  ComparisonInstr* comparison() const { return comparison_; }
  void SetComparison(ComparisonInstr* comp);

  bool is_checked() const { return is_checked_; }

  virtual LocationSummary* locs();
  virtual intptr_t DeoptimizationTarget() const;
  virtual Representation RequiredInputRepresentation(intptr_t i) const;

  // A misleadingly named function for use in template functions that also
  // replace definitions.  In this case, leave the branch intact and replace
  // its comparison with another comparison that has been removed from the
  // graph but still has uses properly linked into their definition's use
  // list.
  void ReplaceWith(ComparisonInstr* other,
                   ForwardInstructionIterator* ignored);

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual void PrintTo(BufferFormatter* f) const;

  // Set compile type constrained by the comparison of this branch.
  // FlowGraphPropagator propagates it downwards into either true or false
  // successor.
  void set_constrained_type(ConstrainedCompileType* type) {
    constrained_type_ = type;
  }

  // Return compile type constrained by the comparison of this branch.
  ConstrainedCompileType* constrained_type() const {
    return constrained_type_;
  }

  void set_constant_target(TargetEntryInstr* target) {
    ASSERT(target == true_successor() || target == false_successor());
    constant_target_ = target;
  }
  TargetEntryInstr* constant_target() const {
    return constant_target_;
  }

  virtual void InheritDeoptTarget(Instruction* other);

  virtual bool MayThrow() const;

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value);

  ComparisonInstr* comparison_;
  const bool is_checked_;

  ConstrainedCompileType* constrained_type_;

  TargetEntryInstr* constant_target_;

  DISALLOW_COPY_AND_ASSIGN(BranchInstr);
};


class StoreContextInstr : public TemplateInstruction<1> {
 public:
  explicit StoreContextInstr(Value* value) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(StoreContext)

  virtual intptr_t ArgumentCount() const { return 0; }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(StoreContextInstr);
};


template<intptr_t N>
class TemplateDefinition : public Definition {
 public:
  TemplateDefinition<N>() : locs_(NULL) { }

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  // Returns a structure describing the location constraints required
  // to emit native code for this definition.
  LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  friend class BranchInstr;

  virtual void RawSetInputAt(intptr_t i, Value* value) {
    inputs_[i] = value;
  }

  LocationSummary* locs_;
};


class RedefinitionInstr : public TemplateDefinition<1> {
 public:
  explicit RedefinitionInstr(Value* value) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Redefinition)

  Value* value() const { return inputs_[0]; }

  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  virtual bool CanDeoptimize() const { return false; }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(RedefinitionInstr);
};


class RangeBoundary : public ValueObject {
 public:
  enum Kind { kUnknown, kSymbol, kConstant };

  RangeBoundary() : kind_(kUnknown), value_(0), offset_(0) { }

  RangeBoundary(const RangeBoundary& other)
      : ValueObject(),
        kind_(other.kind_),
        value_(other.value_),
        offset_(other.offset_) { }

  RangeBoundary& operator=(const RangeBoundary& other) {
    kind_ = other.kind_;
    value_ = other.value_;
    offset_ = other.offset_;
    return *this;
  }

  static RangeBoundary FromConstant(intptr_t val) {
    return RangeBoundary(kConstant, val, 0);
  }

  static RangeBoundary FromDefinition(Definition* defn, intptr_t offs = 0);

  static RangeBoundary MinSmi() {
    return FromConstant(Smi::kMinValue);
  }

  static RangeBoundary MaxSmi() {
    return FromConstant(Smi::kMaxValue);
  }

  static const intptr_t kMinusInfinity = Smi::kMinValue - 1;
  static const intptr_t kPlusInfinity = Smi::kMaxValue + 1;

  static RangeBoundary OverflowedMinSmi() {
    return FromConstant(Smi::kMinValue - 1);
  }

  static RangeBoundary OverflowedMaxSmi() {
    return FromConstant(Smi::kMaxValue + 1);
  }

  static RangeBoundary Min(RangeBoundary a, RangeBoundary b);

  static RangeBoundary Max(RangeBoundary a, RangeBoundary b);

  bool Overflowed() const {
    return IsConstant() && !Smi::IsValid(value());
  }

  RangeBoundary Clamp() const {
    if (IsConstant()) {
      if (value() < Smi::kMinValue) return MinSmi();
      if (value() > Smi::kMaxValue) return MaxSmi();
    }
    return *this;
  }

  bool Equals(const RangeBoundary& other) const {
    return (kind_ == other.kind_) && (value_ == other.value_);
  }

  bool IsUnknown() const { return kind_ == kUnknown; }
  bool IsConstant() const { return kind_ == kConstant; }
  bool IsSymbol() const { return kind_ == kSymbol; }

  intptr_t value() const {
    ASSERT(IsConstant());
    return value_;
  }

  Definition* symbol() const {
    ASSERT(IsSymbol());
    return reinterpret_cast<Definition*>(value_);
  }

  intptr_t offset() const {
    return offset_;
  }

  RangeBoundary LowerBound() const;
  RangeBoundary UpperBound() const;

  void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

  static RangeBoundary Add(const RangeBoundary& a,
                           const RangeBoundary& b,
                           const RangeBoundary& overflow) {
    ASSERT(a.IsConstant() && b.IsConstant());

    intptr_t result = a.value() + b.value();
    if (!Smi::IsValid(result)) {
      return overflow;
    }
    return RangeBoundary::FromConstant(result);
  }

  static RangeBoundary Sub(const RangeBoundary& a,
                           const RangeBoundary& b,
                           const RangeBoundary& overflow) {
    ASSERT(a.IsConstant() && b.IsConstant());

    intptr_t result = a.value() - b.value();
    if (!Smi::IsValid(result)) {
      return overflow;
    }
    return RangeBoundary::FromConstant(result);
  }

 private:
  RangeBoundary(Kind kind, intptr_t value, intptr_t offset)
      : kind_(kind), value_(value), offset_(offset) { }

  Kind kind_;
  intptr_t value_;
  intptr_t offset_;
};


class Range : public ZoneAllocated {
 public:
  Range(RangeBoundary min, RangeBoundary max) : min_(min), max_(max) { }

  static Range* Unknown() {
    return new Range(RangeBoundary::MinSmi(), RangeBoundary::MaxSmi());
  }

  void PrintTo(BufferFormatter* f) const;
  static const char* ToCString(Range* range);

  const RangeBoundary& min() const { return min_; }
  const RangeBoundary& max() const { return max_; }

  bool Equals(Range* other) {
    return min_.Equals(other->min_) && max_.Equals(other->max_);
  }

  static RangeBoundary ConstantMin(const Range* range) {
    if (range == NULL) return RangeBoundary::MinSmi();
    return range->min().LowerBound().Clamp();
  }

  static RangeBoundary ConstantMax(const Range* range) {
    if (range == NULL) return RangeBoundary::MaxSmi();
    return range->max().UpperBound().Clamp();
  }

  // Inclusive.
  bool IsWithin(intptr_t min_int, intptr_t max_int) const;

  bool IsUnsatisfiable() const;

 private:
  RangeBoundary min_;
  RangeBoundary max_;
};


class ConstraintInstr : public TemplateDefinition<2> {
 public:
  ConstraintInstr(Value* value, Range* constraint)
      : constraint_(constraint),
        target_(NULL) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(Constraint)

  virtual intptr_t InputCount() const {
    return (inputs_[1] == NULL) ? 1 : 2;
  }

  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool AttributesEqual(Instruction* other) const {
    UNREACHABLE();
    return false;
  }

  virtual bool MayThrow() const { return false; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  Value* value() const { return inputs_[0]; }
  Range* constraint() const { return constraint_; }

  virtual void InferRange();

  void AddDependency(Definition* defn) {
    Value* val = new Value(defn);
    defn->AddInputUse(val);
    SetInputAt(1, val);
  }

  // Constraints for branches have their target block stored in order
  // to find the the comparsion that generated the constraint:
  // target->predecessor->last_instruction->comparison.
  void set_target(TargetEntryInstr* target) {
    target_ = target;
  }
  TargetEntryInstr* target() const {
    return target_;
  }

 private:
  Value* dependency() {
    return inputs_[1];
  }

  Range* constraint_;
  TargetEntryInstr* target_;

  DISALLOW_COPY_AND_ASSIGN(ConstraintInstr);
};


class ConstantInstr : public TemplateDefinition<0> {
 public:
  explicit ConstantInstr(const Object& value);

  DECLARE_INSTRUCTION(Constant)
  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  const Object& value() const { return value_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual void InferRange();

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  const Object& value_;

  DISALLOW_COPY_AND_ASSIGN(ConstantInstr);
};


class AssertAssignableInstr : public TemplateDefinition<3> {
 public:
  AssertAssignableInstr(intptr_t token_pos,
                        Value* value,
                        Value* instantiator,
                        Value* instantiator_type_arguments,
                        const AbstractType& dst_type,
                        const String& dst_name)
      : token_pos_(token_pos),
        dst_type_(AbstractType::ZoneHandle(dst_type.raw())),
        dst_name_(dst_name) {
    ASSERT(!dst_type.IsNull());
    ASSERT(!dst_name.IsNull());
    SetInputAt(0, value);
    SetInputAt(1, instantiator);
    SetInputAt(2, instantiator_type_arguments);
  }

  DECLARE_INSTRUCTION(AssertAssignable)
  virtual CompileType* ComputeInitialType() const;
  virtual bool RecomputeType();

  Value* value() const { return inputs_[0]; }
  Value* instantiator() const { return inputs_[1]; }
  Value* instantiator_type_arguments() const { return inputs_[2]; }

  intptr_t token_pos() const { return token_pos_; }
  const AbstractType& dst_type() const { return dst_type_; }
  void set_dst_type(const AbstractType& dst_type) {
    dst_type_ = dst_type.raw();
  }
  const String& dst_name() const { return dst_name_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;
  AbstractType& dst_type_;
  const String& dst_name_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableInstr);
};


class AssertBooleanInstr : public TemplateDefinition<1> {
 public:
  AssertBooleanInstr(intptr_t token_pos, Value* value)
      : token_pos_(token_pos) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(AssertBoolean)
  virtual CompileType ComputeType() const;

  intptr_t token_pos() const { return token_pos_; }
  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(AssertBooleanInstr);
};


class ArgumentDefinitionTestInstr : public TemplateDefinition<1> {
 public:
  ArgumentDefinitionTestInstr(ArgumentDefinitionTestNode* node,
                              Value* saved_arguments_descriptor)
      : ast_node_(*node) {
    SetInputAt(0, saved_arguments_descriptor);
  }

  DECLARE_INSTRUCTION(ArgumentDefinitionTest)
  virtual CompileType ComputeType() const;

  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t formal_parameter_index() const {
    return ast_node_.formal_parameter_index();
  }
  const String& formal_parameter_name() const {
    return ast_node_.formal_parameter_name();
  }

  Value* saved_arguments_descriptor() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  const ArgumentDefinitionTestNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(ArgumentDefinitionTestInstr);
};


// Denotes the current context, normally held in a register.  This is
// a computation, not a value, because it's mutable.
class CurrentContextInstr : public TemplateDefinition<0> {
 public:
  CurrentContextInstr() { }

  DECLARE_INSTRUCTION(CurrentContext)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(CurrentContextInstr);
};


class ClosureCallInstr : public TemplateDefinition<0> {
 public:
  ClosureCallInstr(ClosureCallNode* node,
                   ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : ast_node_(*node),
        arguments_(arguments) { }

  DECLARE_INSTRUCTION(ClosureCall)

  const Array& argument_names() const { return ast_node_.arguments()->names(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  virtual bool MayThrow() const { return true; }

 private:
  const ClosureCallNode& ast_node_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(ClosureCallInstr);
};


class InstanceCallInstr : public TemplateDefinition<0> {
 public:
  InstanceCallInstr(intptr_t token_pos,
                    const String& function_name,
                    Token::Kind token_kind,
                    ZoneGrowableArray<PushArgumentInstr*>* arguments,
                    const Array& argument_names,
                    intptr_t checked_argument_count,
                    const Array& ic_data_array)
      : ic_data_(GetICData(ic_data_array)),
        token_pos_(token_pos),
        function_name_(function_name),
        token_kind_(token_kind),
        arguments_(arguments),
        argument_names_(argument_names),
        checked_argument_count_(checked_argument_count) {
    ASSERT(function_name.IsNotTemporaryScopedHandle());
    ASSERT(!arguments->is_empty());
    ASSERT(argument_names.IsZoneHandle());
    ASSERT(Token::IsBinaryOperator(token_kind) ||
           Token::IsPrefixOperator(token_kind) ||
           Token::IsIndexOperator(token_kind) ||
           Token::IsTypeTestOperator(token_kind) ||
           Token::IsTypeCastOperator(token_kind) ||
           token_kind == Token::kGET ||
           token_kind == Token::kSET ||
           token_kind == Token::kILLEGAL);
  }

  DECLARE_INSTRUCTION(InstanceCall)

  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const {
    return (ic_data() != NULL) && !ic_data()->IsNull();
  }

  // ICData can be replaced by optimizer.
  void set_ic_data(const ICData* value) { ic_data_ = value; }

  intptr_t token_pos() const { return token_pos_; }
  const String& function_name() const { return function_name_; }
  Token::Kind token_kind() const { return token_kind_; }
  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }
  const Array& argument_names() const { return argument_names_; }
  intptr_t checked_argument_count() const { return checked_argument_count_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  virtual bool MayThrow() const { return true; }

 protected:
  friend class FlowGraphOptimizer;
  void set_ic_data(ICData* value) { ic_data_ = value; }

 private:
  const ICData* ic_data_;
  const intptr_t token_pos_;
  const String& function_name_;
  const Token::Kind token_kind_;  // Binary op, unary op, kGET or kILLEGAL.
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;
  const Array& argument_names_;
  const intptr_t checked_argument_count_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallInstr);
};


class PolymorphicInstanceCallInstr : public TemplateDefinition<0> {
 public:
  PolymorphicInstanceCallInstr(InstanceCallInstr* instance_call,
                               const ICData& ic_data,
                               bool with_checks)
      : instance_call_(instance_call),
        ic_data_(ic_data),
        with_checks_(with_checks) {
    ASSERT(instance_call_ != NULL);
    deopt_id_ = instance_call->deopt_id();
  }

  InstanceCallInstr* instance_call() const { return instance_call_; }
  bool with_checks() const { return with_checks_; }

  virtual intptr_t ArgumentCount() const {
    return instance_call()->ArgumentCount();
  }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return instance_call()->PushArgumentAt(index);
  }

  DECLARE_INSTRUCTION(PolymorphicInstanceCall)

  const ICData& ic_data() const { return ic_data_; }

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool MayThrow() const { return true; }

 private:
  InstanceCallInstr* instance_call_;
  const ICData& ic_data_;
  const bool with_checks_;

  DISALLOW_COPY_AND_ASSIGN(PolymorphicInstanceCallInstr);
};


class ComparisonInstr : public TemplateDefinition<2> {
 public:
  ComparisonInstr(intptr_t token_pos,
                  Token::Kind kind,
                  Value* left,
                  Value* right)
      : token_pos_(token_pos), kind_(kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual ComparisonInstr* AsComparison() { return this; }

  intptr_t token_pos() const { return token_pos_; }
  Token::Kind kind() const { return kind_; }

  virtual void EmitBranchCode(FlowGraphCompiler* compiler,
                              BranchInstr* branch) = 0;

  void SetDeoptId(intptr_t deopt_id) {
    deopt_id_ = deopt_id;
  }

 protected:
  intptr_t token_pos_;
  Token::Kind kind_;
};


// Inlined functions from class BranchInstr that forward to their comparison.
inline intptr_t BranchInstr::ArgumentCount() const {
  return comparison()->ArgumentCount();
}


inline intptr_t BranchInstr::InputCount() const {
  return comparison()->InputCount();
}


inline Value* BranchInstr::InputAt(intptr_t i) const {
  return comparison()->InputAt(i);
}


inline bool BranchInstr::CanDeoptimize() const {
  // Branches need a deoptimization info in checked mode if they
  // can throw a type check error.
  return comparison()->CanDeoptimize() || is_checked();
}


inline bool BranchInstr::CanBecomeDeoptimizationTarget() const {
  return comparison()->CanBecomeDeoptimizationTarget();
}


inline EffectSet BranchInstr::Effects() const {
  return comparison()->Effects();
}


inline LocationSummary* BranchInstr::locs() {
  if (comparison()->locs_ == NULL) {
    LocationSummary* summary = comparison()->MakeLocationSummary();
    // Branches don't produce a result.
    summary->set_out(Location::NoLocation());
    comparison()->locs_ = summary;
  }
  return comparison()->locs_;
}


inline intptr_t BranchInstr::DeoptimizationTarget() const {
  return comparison()->DeoptimizationTarget();
}


inline Representation BranchInstr::RequiredInputRepresentation(
    intptr_t i) const {
  return comparison()->RequiredInputRepresentation(i);
}


inline bool BranchInstr::MayThrow() const {
  return comparison()->MayThrow();
}


class StrictCompareInstr : public ComparisonInstr {
 public:
  StrictCompareInstr(intptr_t token_pos,
                     Token::Kind kind,
                     Value* left,
                     Value* right);

  DECLARE_INSTRUCTION(StrictCompare)
  virtual CompileType ComputeType() const;

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanBecomeDeoptimizationTarget() const {
    // StrictCompare can be merged into Branch and thus needs an environment.
    return true;
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual void EmitBranchCode(FlowGraphCompiler* compiler,
                              BranchInstr* branch);

  bool needs_number_check() const { return needs_number_check_; }
  void set_needs_number_check(bool value) { needs_number_check_ = value; }
  void set_kind(Token::Kind value) { kind_ = value; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  // True if the comparison must check for double, Mint or Bigint and
  // use value comparison instead.
  bool needs_number_check_;

  DISALLOW_COPY_AND_ASSIGN(StrictCompareInstr);
};


class EqualityCompareInstr : public ComparisonInstr {
 public:
  EqualityCompareInstr(intptr_t token_pos,
                       Token::Kind kind,
                       Value* left,
                       Value* right,
                       const Array& ic_data_array)
      : ComparisonInstr(token_pos, kind, left, right),
        ic_data_(GetICData(ic_data_array)),
        receiver_class_id_(kIllegalCid) {
    ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  }

  DECLARE_INSTRUCTION(EqualityCompare)
  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const {
    return (ic_data() != NULL) && !ic_data()->IsNull();
  }
  void set_ic_data(const ICData* value) { ic_data_ = value; }

  // Receiver class id is computed from collected ICData.
  void set_receiver_class_id(intptr_t value) { receiver_class_id_ = value; }
  intptr_t receiver_class_id() const { return receiver_class_id_; }

  bool IsInlinedNumericComparison() const {
    return (receiver_class_id() == kDoubleCid)
        || (receiver_class_id() == kMintCid)
        || (receiver_class_id() == kSmiCid);
  }

  bool is_checked_strict_equal() const {
    return HasICData() && ic_data()->AllTargetsHaveSameOwner(kInstanceCid);
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const {
    return !IsInlinedNumericComparison();
  }

  virtual void EmitBranchCode(FlowGraphCompiler* compiler,
                              BranchInstr* branch);

  virtual intptr_t DeoptimizationTarget() const {
    return GetDeoptId();
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (receiver_class_id() == kDoubleCid) return kUnboxedDouble;
    if (receiver_class_id() == kMintCid) return kUnboxedMint;
    return kTagged;
  }

  bool IsPolymorphic() const;

  virtual EffectSet Effects() const {
    return IsInlinedNumericComparison() ? EffectSet::None() : EffectSet::All();
  }

  virtual bool MayThrow() const {
    return !IsInlinedNumericComparison() && !is_checked_strict_equal();
  }

 private:
  const ICData* ic_data_;
  intptr_t receiver_class_id_;  // Set by optimizer.

  DISALLOW_COPY_AND_ASSIGN(EqualityCompareInstr);
};


class RelationalOpInstr : public ComparisonInstr {
 public:
  RelationalOpInstr(intptr_t token_pos,
                    Token::Kind kind,
                    Value* left,
                    Value* right,
                    const Array& ic_data_array)
      : ComparisonInstr(token_pos, kind, left, right),
        ic_data_(GetICData(ic_data_array)),
        operands_class_id_(kIllegalCid) {
    ASSERT(Token::IsRelationalOperator(kind));
  }

  DECLARE_INSTRUCTION(RelationalOp)
  virtual CompileType ComputeType() const;
  virtual bool RecomputeType();

  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const {
    return (ic_data() != NULL) && !ic_data()->IsNull();
  }
  void set_ic_data(const ICData* value) { ic_data_ = value; }

  // TODO(srdjan): instead of class-id pass an enum that can differentiate
  // between boxed and unboxed doubles and integers.
  void set_operands_class_id(intptr_t value) {
    operands_class_id_ = value;
  }

  intptr_t operands_class_id() const { return operands_class_id_; }

  bool IsInlinedNumericComparison() const {
    return (operands_class_id() == kDoubleCid)
        || (operands_class_id() == kMintCid)
        || (operands_class_id() == kSmiCid);
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const {
    return !IsInlinedNumericComparison();
  }

  virtual void EmitBranchCode(FlowGraphCompiler* compiler,
                              BranchInstr* branch);


  virtual intptr_t DeoptimizationTarget() const {
    return GetDeoptId();
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (operands_class_id() == kDoubleCid) return kUnboxedDouble;
    if (operands_class_id() == kMintCid) return kUnboxedMint;
    return kTagged;
  }

  virtual EffectSet Effects() const {
    return IsInlinedNumericComparison() ? EffectSet::None() : EffectSet::All();
  }

  virtual bool MayThrow() const { return !IsInlinedNumericComparison(); }

 private:
  const ICData* ic_data_;
  intptr_t operands_class_id_;  // class id of both operands.

  DISALLOW_COPY_AND_ASSIGN(RelationalOpInstr);
};


// TODO(vegorov): ComparisonInstr should be switched to use IfTheElseInstr for
// materialization of true and false constants.
class IfThenElseInstr : public TemplateDefinition<2> {
 public:
  IfThenElseInstr(Token::Kind kind,
                  Value* left,
                  Value* right,
                  Value* if_true,
                  Value* if_false)
      : kind_(kind),
        if_true_(Smi::Cast(if_true->BoundConstant()).Value()),
        if_false_(Smi::Cast(if_false->BoundConstant()).Value()) {
    ASSERT(Token::IsEqualityOperator(kind));
    SetInputAt(0, left);
    SetInputAt(1, right);
  }

  // Returns true if this instruction is supported on the current platform.
  static bool IsSupported();

  // Returns true if this combination of comparison and values flowing on
  // the true and false paths is supported on the current platform.
  static bool Supports(ComparisonInstr* comparison, Value* v1, Value* v2);

  DECLARE_INSTRUCTION(IfThenElse)

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual CompileType ComputeType() const;

  virtual void InferRange();

  virtual bool CanDeoptimize() const { return false; }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }
  intptr_t if_true() const { return if_true_; }
  intptr_t if_false() const { return if_false_; }

  Token::Kind kind() const { return kind_; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    IfThenElseInstr* other_if_then_else = other->AsIfThenElse();
    return (kind_ == other_if_then_else->kind_) &&
           (if_true_ == other_if_then_else->if_true_) &&
           (if_false_ == other_if_then_else->if_false_);
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind kind_;
  const intptr_t if_true_;
  const intptr_t if_false_;

  DISALLOW_COPY_AND_ASSIGN(IfThenElseInstr);
};


class StaticCallInstr : public TemplateDefinition<0> {
 public:
  StaticCallInstr(intptr_t token_pos,
                  const Function& function,
                  const Array& argument_names,
                  ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : token_pos_(token_pos),
        function_(function),
        argument_names_(argument_names),
        arguments_(arguments),
        result_cid_(kDynamicCid),
        is_known_list_constructor_(false) {
    ASSERT(function.IsZoneHandle());
    ASSERT(argument_names.IsZoneHandle());
  }

  DECLARE_INSTRUCTION(StaticCall)
  virtual CompileType ComputeType() const;

  // Accessors forwarded to the AST node.
  const Function& function() const { return function_; }
  const Array& argument_names() const { return argument_names_; }
  intptr_t token_pos() const { return token_pos_; }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  void set_result_cid(intptr_t value) { result_cid_ = value; }

  bool is_known_list_constructor() const { return is_known_list_constructor_; }
  void set_is_known_list_constructor(bool value) {
    is_known_list_constructor_ = value;
  }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;
  const Function& function_;
  const Array& argument_names_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;
  intptr_t result_cid_;  // For some library functions we know the result.

  // 'True' for recognized list constructors.
  bool is_known_list_constructor_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallInstr);
};


class LoadLocalInstr : public TemplateDefinition<0> {
 public:
  explicit LoadLocalInstr(const LocalVariable& local)
      : local_(local), is_last_(false) { }

  DECLARE_INSTRUCTION(LoadLocal)
  virtual CompileType ComputeType() const;

  const LocalVariable& local() const { return local_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return EffectSet::None();
  }

  void mark_last() { is_last_ = true; }
  bool is_last() const { return is_last_; }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return false;
  }

 private:
  const LocalVariable& local_;
  bool is_last_;

  DISALLOW_COPY_AND_ASSIGN(LoadLocalInstr);
};


class PushTempInstr : public TemplateDefinition<1> {
 public:
  explicit PushTempInstr(Value* value) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(PushTemp)

  Value* value() const { return inputs_[0]; }

  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return EffectSet::None();
  }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return false;
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(PushTempInstr);
};


class DropTempsInstr : public TemplateDefinition<1> {
 public:
  explicit DropTempsInstr(intptr_t num_temps, Value* value)
      : num_temps_(num_temps) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(DropTemps)

  Value* value() const { return inputs_[0]; }

  intptr_t num_temps() const { return num_temps_; }

  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return EffectSet::None();
  }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return false;
  }

 private:
  intptr_t num_temps_;

  DISALLOW_COPY_AND_ASSIGN(DropTempsInstr);
};


class StoreLocalInstr : public TemplateDefinition<1> {
 public:
  StoreLocalInstr(const LocalVariable& local, Value* value)
      : local_(local), is_dead_(false), is_last_(false) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(StoreLocal)
  virtual CompileType* ComputeInitialType() const;

  const LocalVariable& local() const { return local_; }
  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  void mark_dead() { is_dead_ = true; }
  bool is_dead() const { return is_dead_; }

  void mark_last() { is_last_ = true; }
  bool is_last() const { return is_last_; }

  virtual EffectSet Effects() const {
    UNREACHABLE();  // Eliminated by SSA construction.
    return EffectSet::None();
  }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return false;
  }

 private:
  const LocalVariable& local_;
  bool is_dead_;
  bool is_last_;

  DISALLOW_COPY_AND_ASSIGN(StoreLocalInstr);
};


class NativeCallInstr : public TemplateDefinition<0> {
 public:
  explicit NativeCallInstr(NativeBodyNode* node)
      : ast_node_(*node) {}

  DECLARE_INSTRUCTION(NativeCall)

  intptr_t token_pos() const { return ast_node_.token_pos(); }

  const Function& function() const { return ast_node_.function(); }

  const String& native_name() const {
    return ast_node_.native_c_function_name();
  }

  NativeFunction native_c_function() const {
    return ast_node_.native_c_function();
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  virtual bool MayThrow() const {
    UNREACHABLE();
    return true;
  }

 private:
  const NativeBodyNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallInstr);
};


enum StoreBarrierType {
  kNoStoreBarrier,
  kEmitStoreBarrier
};


class StoreInstanceFieldInstr : public TemplateDefinition<2> {
 public:
  StoreInstanceFieldInstr(const Field& field,
                          Value* instance,
                          Value* value,
                          StoreBarrierType emit_store_barrier)
      : field_(field),
        emit_store_barrier_(emit_store_barrier) {
    SetInputAt(0, instance);
    SetInputAt(1, value);
  }

  DECLARE_INSTRUCTION(StoreInstanceField)
  virtual CompileType* ComputeInitialType() const;

  const Field& field() const { return field_; }

  Value* instance() const { return inputs_[0]; }
  Value* value() const { return inputs_[1]; }
  bool ShouldEmitStoreBarrier() const {
    return value()->NeedsStoreBuffer()
        && (emit_store_barrier_ == kEmitStoreBarrier);
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  // Currently CSE/LICM don't operate on any instructions that can be affected
  // by stores/loads. LoadOptimizer handles loads separately. Hence stores
  // are marked as having no side-effects.
  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  bool CanValueBeSmi() const {
    const intptr_t cid = value()->Type()->ToNullableCid();
    // Write barrier is skipped for nullable and non-nullable smis.
    ASSERT(cid != kSmiCid);
    return (cid == kDynamicCid);
  }

  const Field& field_;
  const StoreBarrierType emit_store_barrier_;

  DISALLOW_COPY_AND_ASSIGN(StoreInstanceFieldInstr);
};


class GuardFieldInstr : public TemplateInstruction<1> {
 public:
  GuardFieldInstr(Value* value,
                  const Field& field,
                  intptr_t deopt_id)
    : field_(field) {
    deopt_id_ = deopt_id;
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  const Field& field() const { return field_; }

  DECLARE_INSTRUCTION(GuardField)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(GuardFieldInstr);
};


class LoadStaticFieldInstr : public TemplateDefinition<1> {
 public:
  explicit LoadStaticFieldInstr(Value* field_value) {
    ASSERT(field_value->BindsToConstant());
    SetInputAt(0, field_value);
  }

  DECLARE_INSTRUCTION(LoadStaticField)
  virtual CompileType ComputeType() const;

  const Field& StaticField() const;

  Value* field_value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual bool AllowsCSE() const { return StaticField().is_final(); }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const;
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(LoadStaticFieldInstr);
};


class StoreStaticFieldInstr : public TemplateDefinition<1> {
 public:
  StoreStaticFieldInstr(const Field& field, Value* value)
      : field_(field) {
    ASSERT(field.IsZoneHandle());
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(StoreStaticField)
  virtual CompileType* ComputeInitialType() const;

  const Field& field() const { return field_; }
  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  // Currently CSE/LICM don't operate on any instructions that can be affected
  // by stores/loads. LoadOptimizer handles loads separately. Hence stores
  // are marked as having no side-effects.
  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  bool CanValueBeSmi() const {
    const intptr_t cid = value()->Type()->ToNullableCid();
    // Write barrier is skipped for nullable and non-nullable smis.
    ASSERT(cid != kSmiCid);
    return (cid == kDynamicCid);
  }

  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(StoreStaticFieldInstr);
};


class LoadIndexedInstr : public TemplateDefinition<2> {
 public:
  LoadIndexedInstr(Value* array,
                   Value* index,
                   intptr_t index_scale,
                   intptr_t class_id,
                   intptr_t deopt_id)
      : index_scale_(index_scale), class_id_(class_id) {
    SetInputAt(0, array);
    SetInputAt(1, index);
    deopt_id_ = deopt_id;
  }

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

  virtual bool CanDeoptimize() const {
    return deopt_id_ != Isolate::kNoDeoptId;
  }


  virtual Representation representation() const;
  virtual void InferRange();

  virtual bool AllowsCSE() const { return false; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const;
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t index_scale_;
  const intptr_t class_id_;

  DISALLOW_COPY_AND_ASSIGN(LoadIndexedInstr);
};


class StringFromCharCodeInstr : public TemplateDefinition<1> {
 public:
  StringFromCharCodeInstr(Value* char_code, intptr_t cid) : cid_(cid) {
    ASSERT(char_code != NULL);
    ASSERT(char_code->definition()->IsLoadIndexed() &&
           (char_code->definition()->AsLoadIndexed()->class_id() ==
            kOneByteStringCid));
    SetInputAt(0, char_code);
  }

  DECLARE_INSTRUCTION(StringFromCharCode)
  virtual CompileType ComputeType() const;

  Value* char_code() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsStringFromCharCode()->cid_ == cid_;
  }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t cid_;

  DISALLOW_COPY_AND_ASSIGN(StringFromCharCodeInstr);
};


class StoreIndexedInstr : public TemplateDefinition<3> {
 public:
  StoreIndexedInstr(Value* array,
                    Value* index,
                    Value* value,
                    StoreBarrierType emit_store_barrier,
                    intptr_t index_scale,
                    intptr_t class_id,
                    intptr_t deopt_id)
      : emit_store_barrier_(emit_store_barrier),
        index_scale_(index_scale),
        class_id_(class_id) {
    SetInputAt(0, array);
    SetInputAt(1, index);
    SetInputAt(2, value);
    deopt_id_ = deopt_id;
  }

  DECLARE_INSTRUCTION(StoreIndexed)

  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }
  Value* value() const { return inputs_[2]; }
  intptr_t index_scale() const { return index_scale_; }
  intptr_t class_id() const { return class_id_; }

  bool ShouldEmitStoreBarrier() const {
    return value()->NeedsStoreBuffer()
        && (emit_store_barrier_ == kEmitStoreBarrier);
  }

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const;

  bool IsExternal() const {
    return array()->definition()->representation() == kUntagged;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const StoreBarrierType emit_store_barrier_;
  const intptr_t index_scale_;
  const intptr_t class_id_;

  DISALLOW_COPY_AND_ASSIGN(StoreIndexedInstr);
};


// Note overrideable, built-in: value? false : true.
class BooleanNegateInstr : public TemplateDefinition<1> {
 public:
  explicit BooleanNegateInstr(Value* value) {
    SetInputAt(0, value);
  }

  DECLARE_INSTRUCTION(BooleanNegate)
  virtual CompileType ComputeType() const;

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BooleanNegateInstr);
};


class InstanceOfInstr : public TemplateDefinition<3> {
 public:
  InstanceOfInstr(intptr_t token_pos,
                  Value* value,
                  Value* instantiator,
                  Value* instantiator_type_arguments,
                  const AbstractType& type,
                  bool negate_result,
                  intptr_t deopt_id)
      : token_pos_(token_pos),
        type_(type),
        negate_result_(negate_result) {
    ASSERT(!type.IsNull());
    SetInputAt(0, value);
    SetInputAt(1, instantiator);
    SetInputAt(2, instantiator_type_arguments);
    deopt_id_ = deopt_id;
  }

  DECLARE_INSTRUCTION(InstanceOf)
  virtual CompileType ComputeType() const;

  Value* value() const { return inputs_[0]; }
  Value* instantiator() const { return inputs_[1]; }
  Value* instantiator_type_arguments() const { return inputs_[2]; }

  bool negate_result() const { return negate_result_; }
  const AbstractType& type() const { return type_; }
  intptr_t token_pos() const { return token_pos_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;
  Value* value_;
  Value* instantiator_;
  Value* type_arguments_;
  const AbstractType& type_;
  const bool negate_result_;

  DISALLOW_COPY_AND_ASSIGN(InstanceOfInstr);
};


class AllocateObjectInstr : public TemplateDefinition<0> {
 public:
  AllocateObjectInstr(ConstructorCallNode* node,
                      ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : ast_node_(*node),
        arguments_(arguments),
        cid_(Class::Handle(node->constructor().Owner()).id()),
        identity_(kUnknown) {
    // Either no arguments or one type-argument and one instantiator.
    ASSERT(arguments->is_empty() || (arguments->length() == 2));
  }

  DECLARE_INSTRUCTION(AllocateObject)
  virtual CompileType ComputeType() const;

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

  // If the result of the allocation is not stored into any field, passed
  // as an argument or used in a phi then it can't alias with any other
  // SSA value.
  enum Identity {
    kUnknown,
    kAliased,
    kNotAliased
  };

  Identity identity() const { return identity_; }
  void set_identity(Identity identity) { identity_ = identity; }

 private:
  const ConstructorCallNode& ast_node_;
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;
  const intptr_t cid_;
  Identity identity_;

  DISALLOW_COPY_AND_ASSIGN(AllocateObjectInstr);
};


// This instruction captures the state of the object which had its allocation
// removed during the AllocationSinking pass.
// It does not produce any real code only deoptimization information.
class MaterializeObjectInstr : public Definition {
 public:
  MaterializeObjectInstr(const Class& cls,
                         const ZoneGrowableArray<const Field*>& fields,
                         ZoneGrowableArray<Value*>* values)
      : cls_(cls), fields_(fields), values_(values), locations_(NULL) {
    ASSERT(fields_.length() == values_->length());
    for (intptr_t i = 0; i < InputCount(); i++) {
      InputAt(i)->set_instruction(this);
      InputAt(i)->set_use_index(i);
    }
  }

  const Class& cls() const { return cls_; }
  const Field& FieldAt(intptr_t i) const {
    return *fields_[i];
  }
  const Location& LocationAt(intptr_t i) {
    return locations_[i];
  }

  DECLARE_INSTRUCTION(MaterializeObject)
  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual intptr_t InputCount() const {
    return values_->length();
  }

  virtual Value* InputAt(intptr_t i) const {
    return (*values_)[i];
  }

  virtual bool CanDeoptimize() const { return false; }
  virtual EffectSet Effects() const { return EffectSet::None(); }

  LocationSummary* locs() {
    UNREACHABLE();
    return NULL;
  }

  Location* locations() { return locations_; }
  void set_locations(Location* locations) { locations_ = locations; }

  virtual bool MayThrow() const { return false; }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    (*values_)[i] = value;
  }

  const Class& cls_;
  const ZoneGrowableArray<const Field*>& fields_;
  ZoneGrowableArray<Value*>* values_;
  Location* locations_;

  DISALLOW_COPY_AND_ASSIGN(MaterializeObjectInstr);
};


class AllocateObjectWithBoundsCheckInstr : public TemplateDefinition<0> {
 public:
  explicit AllocateObjectWithBoundsCheckInstr(ConstructorCallNode* node)
      : ast_node_(*node) {
  }

  DECLARE_INSTRUCTION(AllocateObjectWithBoundsCheck)

  virtual intptr_t ArgumentCount() const { return 4; }

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const ConstructorCallNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(AllocateObjectWithBoundsCheckInstr);
};


class CreateArrayInstr : public TemplateDefinition<1> {
 public:
  CreateArrayInstr(intptr_t token_pos,
                   intptr_t num_elements,
                   const AbstractType& type,
                   Value* element_type)
      : token_pos_(token_pos),
        num_elements_(num_elements),
        type_(type) {
    ASSERT(type_.IsZoneHandle());
    ASSERT(!type_.IsNull());
    ASSERT(type_.IsFinalized());
    SetInputAt(0, element_type);
  }

  DECLARE_INSTRUCTION(CreateArray)
  virtual CompileType ComputeType() const;

  intptr_t num_elements() const { return num_elements_; }

  intptr_t token_pos() const { return token_pos_; }
  const AbstractType& type() const { return type_; }
  Value* element_type() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t token_pos_;
  const intptr_t num_elements_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(CreateArrayInstr);
};


class CreateClosureInstr : public TemplateDefinition<0> {
 public:
  CreateClosureInstr(const Function& function,
                     ZoneGrowableArray<PushArgumentInstr*>* arguments,
                     intptr_t token_pos)
      : function_(function),
        arguments_(arguments),
        token_pos_(token_pos) { }

  DECLARE_INSTRUCTION(CreateClosure)
  virtual CompileType ComputeType() const;

  intptr_t token_pos() const { return token_pos_; }
  const Function& function() const { return function_; }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  virtual PushArgumentInstr* PushArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const Function& function_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;
  intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(CreateClosureInstr);
};


class LoadUntaggedInstr : public TemplateDefinition<1> {
 public:
  LoadUntaggedInstr(Value* object, intptr_t offset) : offset_(offset) {
    SetInputAt(0, object);
  }

  virtual Representation representation() const {
    return kUntagged;
  }
  DECLARE_INSTRUCTION(LoadUntagged)
  virtual CompileType ComputeType() const;

  Value* object() const { return inputs_[0]; }
  intptr_t offset() const { return offset_; }

  virtual bool CanDeoptimize() const { return false; }

  // This instruction must not be moved without the indexed access that
  // depends on it (e.g. out of loops). GC may cause collect
  // the array while the external data-array is still accessed.
  virtual bool AllowsCSE() const { return false; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  intptr_t offset_;

  DISALLOW_COPY_AND_ASSIGN(LoadUntaggedInstr);
};


class LoadClassIdInstr : public TemplateDefinition<1> {
 public:
  explicit LoadClassIdInstr(Value* object) {
    SetInputAt(0, object);
  }

  virtual Representation representation() const {
    return kTagged;
  }
  DECLARE_INSTRUCTION(LoadClassId)
  virtual CompileType ComputeType() const;

  Value* object() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const {
    return EffectSet::Externalization();
  }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(LoadClassIdInstr);
};


class LoadFieldInstr : public TemplateDefinition<1> {
 public:
  LoadFieldInstr(Value* instance,
                 intptr_t offset_in_bytes,
                 const AbstractType& type,
                 bool immutable = false)
      : offset_in_bytes_(offset_in_bytes),
        type_(type),
        result_cid_(kDynamicCid),
        immutable_(immutable),
        recognized_kind_(MethodRecognizer::kUnknown),
        field_name_(NULL),
        field_(NULL) {
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    SetInputAt(0, instance);
  }

  Value* instance() const { return inputs_[0]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }
  void set_result_cid(intptr_t value) { result_cid_ = value; }
  intptr_t result_cid() const { return result_cid_; }

  void set_field_name(const char* name) { field_name_ = name; }
  const char* field_name() const { return field_name_; }

  const Field* field() const { return field_; }
  void set_field(const Field* field) { field_ = field; }

  void set_recognized_kind(MethodRecognizer::Kind kind) {
    recognized_kind_ = kind;
  }

  MethodRecognizer::Kind recognized_kind() const {
    return recognized_kind_;
  }

  DECLARE_INSTRUCTION(LoadField)
  virtual CompileType ComputeType() const;

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual void InferRange();

  bool IsImmutableLengthLoad() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  static MethodRecognizer::Kind RecognizedKindFromArrayCid(intptr_t cid);

  static bool IsFixedLengthArrayCid(intptr_t cid);

  virtual bool AllowsCSE() const { return immutable_; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const;
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;
  intptr_t result_cid_;
  const bool immutable_;

  MethodRecognizer::Kind recognized_kind_;

  const char* field_name_;
  const Field* field_;

  DISALLOW_COPY_AND_ASSIGN(LoadFieldInstr);
};


class StoreVMFieldInstr : public TemplateDefinition<2> {
 public:
  StoreVMFieldInstr(Value* dest,
                    intptr_t offset_in_bytes,
                    Value* value,
                    const AbstractType& type)
      : offset_in_bytes_(offset_in_bytes), type_(type) {
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    SetInputAt(0, value);
    SetInputAt(1, dest);
  }

  DECLARE_INSTRUCTION(StoreVMField)
  virtual CompileType* ComputeInitialType() const;

  Value* value() const { return inputs_[0]; }
  Value* dest() const { return inputs_[1]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(StoreVMFieldInstr);
};


class InstantiateTypeArgumentsInstr : public TemplateDefinition<1> {
 public:
  InstantiateTypeArgumentsInstr(intptr_t token_pos,
                                const AbstractTypeArguments& type_arguments,
                                const Class& instantiator_class,
                                Value* instantiator)
      : token_pos_(token_pos),
        type_arguments_(type_arguments),
        instantiator_class_(instantiator_class) {
    ASSERT(type_arguments.IsZoneHandle());
    SetInputAt(0, instantiator);
  }

  DECLARE_INSTRUCTION(InstantiateTypeArguments)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  const Class& instantiator_class() const { return instantiator_class_; }
  intptr_t token_pos() const { return token_pos_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  const intptr_t token_pos_;
  const AbstractTypeArguments& type_arguments_;
  const Class& instantiator_class_;

  DISALLOW_COPY_AND_ASSIGN(InstantiateTypeArgumentsInstr);
};


class ExtractConstructorTypeArgumentsInstr : public TemplateDefinition<1> {
 public:
  ExtractConstructorTypeArgumentsInstr(
      intptr_t token_pos,
      const AbstractTypeArguments& type_arguments,
      const Class& instantiator_class,
      Value* instantiator)
      : token_pos_(token_pos),
        type_arguments_(type_arguments),
        instantiator_class_(instantiator_class) {
    SetInputAt(0, instantiator);
  }

  DECLARE_INSTRUCTION(ExtractConstructorTypeArguments)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  const Class& instantiator_class() const { return instantiator_class_; }
  intptr_t token_pos() const { return token_pos_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t token_pos_;
  const AbstractTypeArguments& type_arguments_;
  const Class& instantiator_class_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorTypeArgumentsInstr);
};


class ExtractConstructorInstantiatorInstr : public TemplateDefinition<1> {
 public:
  ExtractConstructorInstantiatorInstr(ConstructorCallNode* ast_node,
                                      const Class& instantiator_class,
                                      Value* instantiator)
      : ast_node_(*ast_node), instantiator_class_(instantiator_class) {
    SetInputAt(0, instantiator);
  }

  DECLARE_INSTRUCTION(ExtractConstructorInstantiator)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  const Function& constructor() const { return ast_node_.constructor(); }
  const Class& instantiator_class() const { return instantiator_class_; }
  intptr_t token_pos() const { return ast_node_.token_pos(); }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const ConstructorCallNode& ast_node_;
  const Class& instantiator_class_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorInstantiatorInstr);
};


class AllocateContextInstr : public TemplateDefinition<0> {
 public:
  AllocateContextInstr(intptr_t token_pos,
                       intptr_t num_context_variables)
      : token_pos_(token_pos),
        num_context_variables_(num_context_variables) {}

  DECLARE_INSTRUCTION(AllocateContext)
  virtual CompileType ComputeType() const;

  intptr_t token_pos() const { return token_pos_; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t token_pos_;
  const intptr_t num_context_variables_;

  DISALLOW_COPY_AND_ASSIGN(AllocateContextInstr);
};


class ChainContextInstr : public TemplateInstruction<1> {
 public:
  explicit ChainContextInstr(Value* context_value) {
    SetInputAt(0, context_value);
  }

  DECLARE_INSTRUCTION(ChainContext)

  virtual intptr_t ArgumentCount() const { return 0; }

  Value* context_value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(ChainContextInstr);
};


class CloneContextInstr : public TemplateDefinition<1> {
 public:
  CloneContextInstr(intptr_t token_pos, Value* context_value)
      : token_pos_(token_pos) {
    SetInputAt(0, context_value);
  }

  intptr_t token_pos() const { return token_pos_; }
  Value* context_value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(CloneContext)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(CloneContextInstr);
};


class CatchEntryInstr : public TemplateInstruction<0> {
 public:
  CatchEntryInstr(const LocalVariable& exception_var,
                  const LocalVariable& stacktrace_var)
      : exception_var_(exception_var), stacktrace_var_(stacktrace_var) {}

  const LocalVariable& exception_var() const { return exception_var_; }
  const LocalVariable& stacktrace_var() const { return stacktrace_var_; }

  DECLARE_INSTRUCTION(CatchEntry)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual EffectSet Effects() const { return EffectSet::All(); }

  virtual bool MayThrow() const { return false; }

 private:
  const LocalVariable& exception_var_;
  const LocalVariable& stacktrace_var_;

  DISALLOW_COPY_AND_ASSIGN(CatchEntryInstr);
};


class CheckEitherNonSmiInstr : public TemplateInstruction<2> {
 public:
  CheckEitherNonSmiInstr(Value* left,
                         Value* right,
                         InstanceCallInstr* instance_call) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  DECLARE_INSTRUCTION(CheckEitherNonSmi)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(CheckEitherNonSmiInstr);
};


class BoxDoubleInstr : public TemplateDefinition<1> {
 public:
  explicit BoxDoubleInstr(Value* value) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(BoxDouble)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

  Definition* Canonicalize(FlowGraph* flow_graph);

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxDoubleInstr);
};


class BoxFloat32x4Instr : public TemplateDefinition<1> {
 public:
  explicit BoxFloat32x4Instr(Value* value) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedFloat32x4;
  }

  DECLARE_INSTRUCTION(BoxFloat32x4)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxFloat32x4Instr);
};


class BoxUint32x4Instr : public TemplateDefinition<1> {
 public:
  explicit BoxUint32x4Instr(Value* value) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedUint32x4;
  }

  DECLARE_INSTRUCTION(BoxUint32x4)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxUint32x4Instr);
};


class BoxIntegerInstr : public TemplateDefinition<1> {
 public:
  explicit BoxIntegerInstr(Value* value) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedMint;
  }

  DECLARE_INSTRUCTION(BoxInteger)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BoxIntegerInstr);
};


class UnboxDoubleInstr : public TemplateDefinition<1> {
 public:
  UnboxDoubleInstr(Value* value, intptr_t deopt_id) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const {
    return (value()->Type()->ToCid() != kDoubleCid)
        && (value()->Type()->ToCid() != kSmiCid);
  }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  DECLARE_INSTRUCTION(UnboxDouble)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

  Definition* Canonicalize(FlowGraph* flow_graph);

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxDoubleInstr);
};


class UnboxFloat32x4Instr : public TemplateDefinition<1> {
 public:
  UnboxFloat32x4Instr(Value* value, intptr_t deopt_id) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const {
    return (value()->Type()->ToCid() != kFloat32x4Cid);
  }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  DECLARE_INSTRUCTION(UnboxFloat32x4)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxFloat32x4Instr);
};


class UnboxUint32x4Instr : public TemplateDefinition<1> {
 public:
  UnboxUint32x4Instr(Value* value, intptr_t deopt_id) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const {
    return (value()->Type()->ToCid() != kUint32x4Cid);
  }

  virtual Representation representation() const {
    return kUnboxedUint32x4;
  }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  DECLARE_INSTRUCTION(UnboxUint32x4)
  virtual CompileType ComputeType() const;

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxUint32x4Instr);
};


class UnboxIntegerInstr : public TemplateDefinition<1> {
 public:
  UnboxIntegerInstr(Value* value, intptr_t deopt_id) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const {
    return (value()->Type()->ToCid() != kSmiCid)
        && (value()->Type()->ToCid() != kMintCid);
  }

  virtual Representation representation() const {
    return kUnboxedMint;
  }


  DECLARE_INSTRUCTION(UnboxInteger)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(UnboxIntegerInstr);
};


class MathSqrtInstr : public TemplateDefinition<1> {
 public:
  MathSqrtInstr(Value* value, StaticCallInstr* instance_call) {
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(MathSqrt)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(MathSqrtInstr);
};


class BinaryDoubleOpInstr : public TemplateDefinition<2> {
 public:
  BinaryDoubleOpInstr(Token::Kind op_kind,
                      Value* left,
                      Value* right,
                      InstanceCallInstr* instance_call)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(BinaryDoubleOp)
  virtual CompileType ComputeType() const;

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsBinaryDoubleOp()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(BinaryDoubleOpInstr);
};


class BinaryFloat32x4OpInstr : public TemplateDefinition<2> {
 public:
  BinaryFloat32x4OpInstr(Token::Kind op_kind,
                         Value* left,
                         Value* right,
                         intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(BinaryFloat32x4Op)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsBinaryFloat32x4Op()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(BinaryFloat32x4OpInstr);
};


class Float32x4ShuffleInstr : public TemplateDefinition<1> {
 public:
  Float32x4ShuffleInstr(MethodRecognizer::Kind op_kind, Value* value,
                        intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    if ((op_kind_ == MethodRecognizer::kFloat32x4ShuffleX) ||
        (op_kind_ == MethodRecognizer::kFloat32x4ShuffleY) ||
        (op_kind_ == MethodRecognizer::kFloat32x4ShuffleZ) ||
        (op_kind_ == MethodRecognizer::kFloat32x4ShuffleW)) {
      return kUnboxedDouble;
    }
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Shuffle)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4Shuffle()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4ShuffleInstr);
};


class Float32x4ConstructorInstr : public TemplateDefinition<4> {
 public:
  Float32x4ConstructorInstr(Value* value0, Value* value1, Value* value2,
                            Value* value3, intptr_t deopt_id) {
    SetInputAt(0, value0);
    SetInputAt(1, value1);
    SetInputAt(2, value2);
    SetInputAt(3, value3);
    deopt_id_ = deopt_id;
  }

  Value* value0() const { return inputs_[0]; }
  Value* value1() const { return inputs_[1]; }
  Value* value2() const { return inputs_[2]; }
  Value* value3() const { return inputs_[3]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx >= 0 && idx < 4);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Constructor)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Float32x4ConstructorInstr);
};


class Float32x4SplatInstr : public TemplateDefinition<1> {
 public:
  Float32x4SplatInstr(Value* value, intptr_t deopt_id) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Splat)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Float32x4SplatInstr);
};


class Float32x4ZeroInstr : public TemplateDefinition<0> {
 public:
  explicit Float32x4ZeroInstr(intptr_t deopt_id) {
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    UNIMPLEMENTED();
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Zero)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Float32x4ZeroInstr);
};


class Float32x4ComparisonInstr : public TemplateDefinition<2> {
 public:
  Float32x4ComparisonInstr(MethodRecognizer::Kind op_kind, Value* left,
                           Value* right, intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedUint32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Comparison)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4Comparison()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4ComparisonInstr);
};


class Float32x4MinMaxInstr : public TemplateDefinition<2> {
 public:
  Float32x4MinMaxInstr(MethodRecognizer::Kind op_kind, Value* left,
                       Value* right, intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4MinMax)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4MinMax()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4MinMaxInstr);
};


class Float32x4ScaleInstr : public TemplateDefinition<2> {
 public:
  Float32x4ScaleInstr(MethodRecognizer::Kind op_kind, Value* left,
                      Value* right, intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (idx == 0) {
      return kUnboxedDouble;
    }
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Scale)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4Scale()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4ScaleInstr);
};


class Float32x4SqrtInstr : public TemplateDefinition<1> {
 public:
  Float32x4SqrtInstr(MethodRecognizer::Kind op_kind, Value* left,
                     intptr_t deopt_id) : op_kind_(op_kind) {
    SetInputAt(0, left);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Sqrt)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4Sqrt()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4SqrtInstr);
};


class Float32x4ZeroArgInstr : public TemplateDefinition<1> {
 public:
  Float32x4ZeroArgInstr(MethodRecognizer::Kind op_kind, Value* left,
                        intptr_t deopt_id) : op_kind_(op_kind) {
    SetInputAt(0, left);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4ZeroArg)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4ZeroArg()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4ZeroArgInstr);
};


class Float32x4ClampInstr : public TemplateDefinition<3> {
 public:
  Float32x4ClampInstr(Value* left, Value* lower, Value* upper,
                      intptr_t deopt_id) {
    SetInputAt(0, left);
    SetInputAt(1, lower);
    SetInputAt(2, upper);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* lower() const { return inputs_[1]; }
  Value* upper() const { return inputs_[2]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1) || (idx == 2));
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4Clamp)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Float32x4ClampInstr);
};


class Float32x4WithInstr : public TemplateDefinition<2> {
 public:
  Float32x4WithInstr(MethodRecognizer::Kind op_kind, Value* left,
                     Value* replacement, intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, replacement);
    SetInputAt(1, left);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[1]; }
  Value* replacement() const { return inputs_[0]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (idx == 0) {
      return kUnboxedDouble;
    }
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4With)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsFloat32x4With()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Float32x4WithInstr);
};


class Float32x4ToUint32x4Instr : public TemplateDefinition<1> {
 public:
  Float32x4ToUint32x4Instr(Value* left, intptr_t deopt_id) {
    SetInputAt(0, left);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedUint32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Float32x4ToUint32x4)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Float32x4ToUint32x4Instr);
};


class Uint32x4BoolConstructorInstr : public TemplateDefinition<4> {
 public:
  Uint32x4BoolConstructorInstr(Value* value0, Value* value1, Value* value2,
                               Value* value3, intptr_t deopt_id) {
    SetInputAt(0, value0);
    SetInputAt(1, value1);
    SetInputAt(2, value2);
    SetInputAt(3, value3);
    deopt_id_ = deopt_id;
  }

  Value* value0() const { return inputs_[0]; }
  Value* value1() const { return inputs_[1]; }
  Value* value2() const { return inputs_[2]; }
  Value* value3() const { return inputs_[3]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedUint32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx >= 0 && idx < 4);
    return kTagged;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Uint32x4BoolConstructor)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Uint32x4BoolConstructorInstr);
};


class Uint32x4GetFlagInstr : public TemplateDefinition<1> {
 public:
  Uint32x4GetFlagInstr(MethodRecognizer::Kind op_kind, Value* value,
                       intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, value);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
      return kTagged;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedUint32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Uint32x4GetFlag)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsUint32x4GetFlag()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Uint32x4GetFlagInstr);
};


class Uint32x4SelectInstr : public TemplateDefinition<3> {
 public:
  Uint32x4SelectInstr(Value* mask, Value* trueValue, Value* falseValue,
                      intptr_t deopt_id) {
    SetInputAt(0, mask);
    SetInputAt(1, trueValue);
    SetInputAt(2, falseValue);
    deopt_id_ = deopt_id;
  }

  Value* mask() const { return inputs_[0]; }
  Value* trueValue() const { return inputs_[1]; }
  Value* falseValue() const { return inputs_[2]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
      return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1) || (idx == 2));
    if (idx == 0) {
      return kUnboxedUint32x4;
    }
    return kUnboxedFloat32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Uint32x4Select)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Uint32x4SelectInstr);
};


class Uint32x4SetFlagInstr : public TemplateDefinition<2> {
 public:
  Uint32x4SetFlagInstr(MethodRecognizer::Kind op_kind, Value* value,
                       Value* flagValue, intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, value);
    SetInputAt(1, flagValue);
    deopt_id_ = deopt_id;
  }

  Value* value() const { return inputs_[0]; }
  Value* flagValue() const { return inputs_[1]; }

  MethodRecognizer::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
      return kUnboxedUint32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    if (idx == 1) {
      return kTagged;
    }
    return kUnboxedUint32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Uint32x4SetFlag)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsUint32x4SetFlag()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(Uint32x4SetFlagInstr);
};


class Uint32x4ToFloat32x4Instr : public TemplateDefinition<1> {
 public:
  Uint32x4ToFloat32x4Instr(Value* left, intptr_t deopt_id) {
    SetInputAt(0, left);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedFloat32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedUint32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(Uint32x4ToFloat32x4)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(Uint32x4ToFloat32x4Instr);
};


class BinaryUint32x4OpInstr : public TemplateDefinition<2> {
 public:
  BinaryUint32x4OpInstr(Token::Kind op_kind,
                        Value* left,
                        Value* right,
                        intptr_t deopt_id)
      : op_kind_(op_kind) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = deopt_id;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedUint32x4;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedUint32x4;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(BinaryUint32x4Op)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsBinaryUint32x4Op()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(BinaryUint32x4OpInstr);
};

class BinaryMintOpInstr : public TemplateDefinition<2> {
 public:
  BinaryMintOpInstr(Token::Kind op_kind,
                           Value* left,
                           Value* right,
                           InstanceCallInstr* instance_call)
      : op_kind_(op_kind),
        instance_call_(instance_call) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallInstr* instance_call() const { return instance_call_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const {
    return (op_kind() == Token::kADD) || (op_kind() == Token::kSUB);
  }

  virtual Representation representation() const {
    return kUnboxedMint;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return kUnboxedMint;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  DECLARE_INSTRUCTION(BinaryMintOp)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    ASSERT(other->IsBinaryMintOp());
    return op_kind() == other->AsBinaryMintOp()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;
  InstanceCallInstr* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(BinaryMintOpInstr);
};


class ShiftMintOpInstr : public TemplateDefinition<2> {
 public:
  ShiftMintOpInstr(Token::Kind op_kind,
                   Value* left,
                   Value* right,
                   InstanceCallInstr* instance_call)
      : op_kind_(op_kind) {
    ASSERT(op_kind == Token::kSHR || op_kind == Token::kSHL);
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }

  virtual CompileType ComputeType() const;

  virtual Representation representation() const {
    return kUnboxedMint;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((idx == 0) || (idx == 1));
    return (idx == 0) ? kUnboxedMint : kTagged;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(ShiftMintOp)

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsShiftMintOp()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(ShiftMintOpInstr);
};


class UnaryMintOpInstr : public TemplateDefinition<1> {
 public:
  UnaryMintOpInstr(Token::Kind op_kind,
                          Value* value,
                          InstanceCallInstr* instance_call)
      : op_kind_(op_kind) {
    ASSERT(op_kind == Token::kBIT_NOT);
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedMint;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedMint;
  }

  virtual intptr_t DeoptimizationTarget() const {
    // Direct access since this instruction cannot deoptimize, and the deopt-id
    // was inherited from another instruction that could deoptimize.
    return deopt_id_;
  }

  DECLARE_INSTRUCTION(UnaryMintOp)
  virtual CompileType ComputeType() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return op_kind() == other->AsUnaryMintOp()->op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(UnaryMintOpInstr);
};


class BinarySmiOpInstr : public TemplateDefinition<2> {
 public:
  BinarySmiOpInstr(Token::Kind op_kind,
                   InstanceCallInstr* instance_call,
                   Value* left,
                   Value* right)
      : op_kind_(op_kind),
        instance_call_(instance_call),
        overflow_(true),
        is_truncating_(false) {
    SetInputAt(0, left);
    SetInputAt(1, right);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallInstr* instance_call() const { return instance_call_; }

  const ICData* ic_data() const { return instance_call()->ic_data(); }

  void set_overflow(bool overflow) { overflow_ = overflow; }

  void set_is_truncating(bool value) { is_truncating_ = value; }
  bool is_truncating() const { return is_truncating_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_INSTRUCTION(BinarySmiOp)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const;

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const;

  void PrintTo(BufferFormatter* f) const;

  virtual void InferRange();

  virtual Definition* Canonicalize(FlowGraph* flow_graph);

  // Returns true if right is a non-zero Smi constant which absolute value is
  // a power of two.
  bool RightIsPowerOfTwoConstant() const;

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;
  InstanceCallInstr* instance_call_;
  bool overflow_;
  bool is_truncating_;

  DISALLOW_COPY_AND_ASSIGN(BinarySmiOpInstr);
};


// Handles both Smi operations: BIT_OR and NEGATE.
class UnarySmiOpInstr : public TemplateDefinition<1> {
 public:
  UnarySmiOpInstr(Token::Kind op_kind,
                  InstanceCallInstr* instance_call,
                  Value* value)
      : op_kind_(op_kind) {
    ASSERT((op_kind == Token::kNEGATE) || (op_kind == Token::kBIT_NOT));
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }
  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_INSTRUCTION(UnarySmiOp)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return op_kind() == Token::kNEGATE; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsUnarySmiOp()->op_kind() == op_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(UnarySmiOpInstr);
};


class CheckStackOverflowInstr : public TemplateInstruction<0> {
 public:
  CheckStackOverflowInstr(intptr_t token_pos, bool in_loop)
      : token_pos_(token_pos), in_loop_(in_loop) {}

  intptr_t token_pos() const { return token_pos_; }
  bool in_loop() const { return in_loop_; }

  DECLARE_INSTRUCTION(CheckStackOverflow)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_pos_;
  const bool in_loop_;

  DISALLOW_COPY_AND_ASSIGN(CheckStackOverflowInstr);
};


class SmiToDoubleInstr : public TemplateDefinition<1> {
 public:
  explicit SmiToDoubleInstr(Value* value) {
    SetInputAt(0, value);
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(SmiToDouble)
  virtual CompileType ComputeType() const;

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  virtual intptr_t ArgumentCount() const { return 1; }

  virtual bool CanDeoptimize() const { return false; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(SmiToDoubleInstr);
};


class DoubleToIntegerInstr : public TemplateDefinition<1> {
 public:
  DoubleToIntegerInstr(Value* value, InstanceCallInstr* instance_call)
      : instance_call_(instance_call) {
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }
  InstanceCallInstr* instance_call() const { return instance_call_; }

  DECLARE_INSTRUCTION(DoubleToInteger)
  virtual CompileType ComputeType() const;

  virtual intptr_t ArgumentCount() const { return 1; }

  virtual bool CanDeoptimize() const { return true; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return true; }

 private:
  InstanceCallInstr* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(DoubleToIntegerInstr);
};


// Similar to 'DoubleToIntegerInstr' but expects unboxed double as input
// and creates a Smi.
class DoubleToSmiInstr : public TemplateDefinition<1> {
 public:
  DoubleToSmiInstr(Value* value, InstanceCallInstr* instance_call) {
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(DoubleToSmi)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return true; }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return deopt_id_; }

  virtual EffectSet Effects() const { return EffectSet::None(); }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(DoubleToSmiInstr);
};


class DoubleToDoubleInstr : public TemplateDefinition<1> {
 public:
  DoubleToDoubleInstr(Value* value,
                      InstanceCallInstr* instance_call,
                      MethodRecognizer::Kind recognized_kind)
    : recognized_kind_(recognized_kind) {
    SetInputAt(0, value);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* value() const { return inputs_[0]; }

  MethodRecognizer::Kind recognized_kind() const { return recognized_kind_; }

  DECLARE_INSTRUCTION(DoubleToDouble)
  virtual CompileType ComputeType() const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT(idx == 0);
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return deopt_id_; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    return other->AsDoubleToDouble()->recognized_kind() == recognized_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  const MethodRecognizer::Kind recognized_kind_;

  DISALLOW_COPY_AND_ASSIGN(DoubleToDoubleInstr);
};


class InvokeMathCFunctionInstr : public Definition {
 public:
  InvokeMathCFunctionInstr(ZoneGrowableArray<Value*>* inputs,
                           InstanceCallInstr* instance_call,
                           MethodRecognizer::Kind recognized_kind);

  static intptr_t ArgumentCountFor(MethodRecognizer::Kind recognized_kind_);

  const RuntimeEntry& TargetFunction() const;

  MethodRecognizer::Kind recognized_kind() const { return recognized_kind_; }

  DECLARE_INSTRUCTION(InvokeMathCFunction)
  virtual CompileType ComputeType() const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  virtual Representation RequiredInputRepresentation(intptr_t idx) const {
    ASSERT((0 <= idx) && (idx < InputCount()));
    return kUnboxedDouble;
  }

  virtual intptr_t DeoptimizationTarget() const { return deopt_id_; }

  virtual intptr_t InputCount() const {
    return inputs_->length();
  }

  virtual Value* InputAt(intptr_t i) const {
    return (*inputs_)[i];
  }

  // Returns a structure describing the location constraints required
  // to emit native code for this definition.
  LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const {
    InvokeMathCFunctionInstr* other_invoke = other->AsInvokeMathCFunction();
    return other_invoke->recognized_kind() == recognized_kind();
  }

  virtual bool MayThrow() const { return false; }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) {
    (*inputs_)[i] = value;
  }

  ZoneGrowableArray<Value*>* inputs_;

  LocationSummary* locs_;

  const MethodRecognizer::Kind recognized_kind_;

  DISALLOW_COPY_AND_ASSIGN(InvokeMathCFunctionInstr);
};


class CheckClassInstr : public TemplateInstruction<1> {
 public:
  CheckClassInstr(Value* value,
                  intptr_t deopt_id,
                  const ICData& unary_checks);

  DECLARE_INSTRUCTION(CheckClass)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  Value* value() const { return inputs_[0]; }

  const ICData& unary_checks() const { return unary_checks_; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  void set_null_check(bool flag) { null_check_ = flag; }

  bool null_check() const { return null_check_; }

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const;
  virtual bool AttributesEqual(Instruction* other) const;

  virtual bool MayThrow() const { return false; }

 private:
  const ICData& unary_checks_;

  bool null_check_;

  DISALLOW_COPY_AND_ASSIGN(CheckClassInstr);
};


class CheckSmiInstr : public TemplateInstruction<1> {
 public:
  CheckSmiInstr(Value* value, intptr_t original_deopt_id) {
    ASSERT(original_deopt_id != Isolate::kNoDeoptId);
    SetInputAt(0, value);
    deopt_id_ = original_deopt_id;
  }

  Value* value() const { return inputs_[0]; }

  DECLARE_INSTRUCTION(CheckSmi)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  DISALLOW_COPY_AND_ASSIGN(CheckSmiInstr);
};


class CheckArrayBoundInstr : public TemplateInstruction<2> {
 public:
  CheckArrayBoundInstr(Value* length,
                       Value* index,
                       InstanceCallInstr* instance_call) {
    SetInputAt(kLengthPos, length);
    SetInputAt(kIndexPos, index);
    deopt_id_ = instance_call->deopt_id();
  }

  Value* length() const { return inputs_[kLengthPos]; }
  Value* index() const { return inputs_[kIndexPos]; }

  DECLARE_INSTRUCTION(CheckArrayBound)

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return true; }

  bool IsRedundant(RangeBoundary length);

  virtual Instruction* Canonicalize(FlowGraph* flow_graph);

  // Returns the length offset for array and string types.
  static intptr_t LengthOffsetFor(intptr_t class_id);

  static bool IsFixedLengthArrayType(intptr_t class_id);

  virtual bool AllowsCSE() const { return true; }
  virtual EffectSet Effects() const { return EffectSet::None(); }
  virtual EffectSet Dependencies() const { return EffectSet::None(); }
  virtual bool AttributesEqual(Instruction* other) const { return true; }

  virtual bool MayThrow() const { return false; }

 private:
  // Give a name to the location/input indices.
  enum {
    kLengthPos = 0,
    kIndexPos = 1
  };

  DISALLOW_COPY_AND_ASSIGN(CheckArrayBoundInstr);
};


#undef DECLARE_INSTRUCTION

class Environment : public ZoneAllocated {
 public:
  // Iterate the non-NULL values in the innermost level of an environment.
  class ShallowIterator : public ValueObject {
   public:
    explicit ShallowIterator(Environment* environment)
        : environment_(environment), index_(0) { }

    ShallowIterator(const ShallowIterator& other)
        : ValueObject(),
          environment_(other.environment_),
          index_(other.index_) { }

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
  static Environment* From(const GrowableArray<Definition*>& definitions,
                           intptr_t fixed_parameter_count,
                           const Function& function);

  void set_locations(Location* locations) {
    ASSERT(locations_ == NULL);
    locations_ = locations;
  }

  void set_deopt_id(intptr_t deopt_id) { deopt_id_ = deopt_id; }
  intptr_t deopt_id() const { return deopt_id_; }

  Environment* outer() const { return outer_; }

  Value* ValueAt(intptr_t ix) const {
    return values_[ix];
  }

  intptr_t Length() const {
    return values_.length();
  }

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

  intptr_t fixed_parameter_count() const {
    return fixed_parameter_count_;
  }

  const Function& function() const { return function_; }

  void DeepCopyTo(Instruction* instr) const;
  void DeepCopyToOuter(Instruction* instr) const;

  void PrintTo(BufferFormatter* f) const;

 private:
  friend class ShallowIterator;

  Environment(intptr_t length,
              intptr_t fixed_parameter_count,
              intptr_t deopt_id,
              const Function& function,
              Environment* outer)
      : values_(length),
        locations_(NULL),
        fixed_parameter_count_(fixed_parameter_count),
        deopt_id_(deopt_id),
        function_(function),
        outer_(outer) { }

  // Deep copy the environment.  A 'length' parameter can be given, which
  // may be less than the environment's length in order to drop values
  // (e.g., passed arguments) from the copy.
  Environment* DeepCopy() const;
  Environment* DeepCopy(intptr_t length) const;

  GrowableArray<Value*> values_;
  Location* locations_;
  const intptr_t fixed_parameter_count_;
  intptr_t deopt_id_;
  const Function& function_;
  Environment* outer_;

  DISALLOW_COPY_AND_ASSIGN(Environment);
};


// Visitor base class to visit each instruction and computation in a flow
// graph as defined by a reversed list of basic blocks.
class FlowGraphVisitor : public ValueObject {
 public:
  explicit FlowGraphVisitor(const GrowableArray<BlockEntryInstr*>& block_order)
      : block_order_(block_order), current_iterator_(NULL) { }
  virtual ~FlowGraphVisitor() { }

  ForwardInstructionIterator* current_iterator() const {
    return current_iterator_;
  }

  // Visit each block in the block order, and for each block its
  // instructions in order from the block entry to exit.
  virtual void VisitBlocks();

  // Visit functions for instruction classes, with an empty default
  // implementation.
#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr) { }

  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_INSTRUCTION

 protected:
  const GrowableArray<BlockEntryInstr*>& block_order_;
  ForwardInstructionIterator* current_iterator_;

 private:
  DISALLOW_COPY_AND_ASSIGN(FlowGraphVisitor);
};


}  // namespace dart

#endif  // VM_INTERMEDIATE_LANGUAGE_H_
