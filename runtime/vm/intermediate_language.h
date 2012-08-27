// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

// TODO(srdjan): Add _ByteArrayBase, get:length.

#define RECOGNIZED_LIST(V)                                                     \
  V(ObjectArray, get:length, ObjectArrayLength)                                \
  V(ImmutableArray, get:length, ImmutableArrayLength)                          \
  V(GrowableObjectArray, get:length, GrowableArrayLength)                      \
  V(StringBase, get:length, StringBaseLength)                                  \
  V(IntegerImplementation, toDouble, IntegerToDouble)                          \
  V(Double, toDouble, DoubleToDouble)                                          \
  V(::, sqrt, MathSqrt)                                                        \

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name) k##enum_name,
RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
  };

  static Kind RecognizeKind(const Function& function);
  static const char* KindToCString(Kind kind);
};


class BitVector;
class FlowGraphAllocator;
class FlowGraphCompiler;
class FlowGraphVisitor;
class Function;
class LocalVariable;

// M is a two argument macro.  It is applied to each concrete value's
// typename and classname.
#define FOR_EACH_VALUE(M)                                                      \
  M(Use, UseVal)                                                               \
  M(Constant, ConstantVal)                                                     \


// M is a two argument macro.  It is applied to each concrete instruction's
// (including the values) typename and classname.
#define FOR_EACH_COMPUTATION(M)                                                \
  M(AssertAssignable, AssertAssignableComp)                                    \
  M(AssertBoolean, AssertBooleanComp)                                          \
  M(CurrentContext, CurrentContextComp)                                        \
  M(StoreContext, StoreContextComp)                                            \
  M(ClosureCall, ClosureCallComp)                                              \
  M(InstanceCall, InstanceCallComp)                                            \
  M(PolymorphicInstanceCall, PolymorphicInstanceCallComp)                      \
  M(StaticCall, StaticCallComp)                                                \
  M(LoadLocal, LoadLocalComp)                                                  \
  M(StoreLocal, StoreLocalComp)                                                \
  M(StrictCompare, StrictCompareComp)                                          \
  M(EqualityCompare, EqualityCompareComp)                                      \
  M(RelationalOp, RelationalOpComp)                                            \
  M(NativeCall, NativeCallComp)                                                \
  M(LoadIndexed, LoadIndexedComp)                                              \
  M(StoreIndexed, StoreIndexedComp)                                            \
  M(LoadInstanceField, LoadInstanceFieldComp)                                  \
  M(StoreInstanceField, StoreInstanceFieldComp)                                \
  M(LoadStaticField, LoadStaticFieldComp)                                      \
  M(StoreStaticField, StoreStaticFieldComp)                                    \
  M(BooleanNegate, BooleanNegateComp)                                          \
  M(InstanceOf, InstanceOfComp)                                                \
  M(CreateArray, CreateArrayComp)                                              \
  M(CreateClosure, CreateClosureComp)                                          \
  M(AllocateObject, AllocateObjectComp)                                        \
  M(AllocateObjectWithBoundsCheck, AllocateObjectWithBoundsCheckComp)          \
  M(LoadVMField, LoadVMFieldComp)                                              \
  M(StoreVMField, StoreVMFieldComp)                                            \
  M(InstantiateTypeArguments, InstantiateTypeArgumentsComp)                    \
  M(ExtractConstructorTypeArguments, ExtractConstructorTypeArgumentsComp)      \
  M(ExtractConstructorInstantiator, ExtractConstructorInstantiatorComp)        \
  M(AllocateContext, AllocateContextComp)                                      \
  M(ChainContext, ChainContextComp)                                            \
  M(CloneContext, CloneContextComp)                                            \
  M(CatchEntry, CatchEntryComp)                                                \
  M(BinarySmiOp, BinarySmiOpComp)                                              \
  M(BinaryMintOp, BinaryMintOpComp)                                            \
  M(BinaryDoubleOp, BinaryDoubleOpComp)                                        \
  M(UnarySmiOp, UnarySmiOpComp)                                                \
  M(NumberNegate, NumberNegateComp)                                            \
  M(CheckStackOverflow, CheckStackOverflowComp)                                \
  M(DoubleToDouble, DoubleToDoubleComp)                                        \
  M(SmiToDouble, SmiToDoubleComp)                                              \
  M(CheckClass, CheckClassComp)                                                \
  M(CheckSmi, CheckSmiComp)                                                    \
  M(Materialize, MaterializeComp)                                              \
  M(CheckEitherNonSmi, CheckEitherNonSmiComp)                                  \
  M(UnboxedDoubleBinaryOp, UnboxedDoubleBinaryOpComp)                          \
  M(UnboxDouble, UnboxDoubleComp)                                              \
  M(BoxDouble, BoxDoubleComp)


#define FORWARD_DECLARATION(ShortName, ClassName) class ClassName;
FOR_EACH_COMPUTATION(FORWARD_DECLARATION)
FOR_EACH_VALUE(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

// Forward declarations.
class BindInstr;
class BranchInstr;
class BufferFormatter;
class ComparisonComp;
class Definition;
class Instruction;
class PushArgumentInstr;
class Value;


enum Representation {
  kTagged, kUnboxedDouble
};


class Computation : public ZoneAllocated {
 public:
  Computation() : deopt_id_(Isolate::kNoDeoptId), ic_data_(NULL), locs_(NULL) {
    Isolate* isolate = Isolate::Current();
    deopt_id_ = isolate->GetNextDeoptId();
    ic_data_ = isolate->GetICDataForDeoptId(deopt_id_);
  }

  // Unique id used for deoptimization.
  intptr_t deopt_id() const { return deopt_id_; }

  const ICData* ic_data() const { return ic_data_; }
  void set_ic_data(const ICData* value) { ic_data_ = value; }
  bool HasICData() const {
    return (ic_data() != NULL) && !ic_data()->IsNull();
  }

  // Visiting support.
  virtual void Accept(FlowGraphVisitor* visitor, BindInstr* instr) = 0;

  virtual intptr_t InputCount() const = 0;
  virtual Value* InputAt(intptr_t i) const = 0;
  virtual void SetInputAt(intptr_t i, Value* value) = 0;

  // Call computations override this function and return the
  // number of pushed arguments.
  virtual intptr_t ArgumentCount() const = 0;

  // Returns true, if this computation can deoptimize.
  virtual bool CanDeoptimize() const  = 0;

  // Returns a replacement for the instruction that wraps this computation.
  // Returns NULL if instr can be eliminated.
  // By default returns instr (input parameter) which means no change.
  virtual Definition* TryReplace(BindInstr* instr) const;

  // Compares two computations. Returns true, if:
  // 1. They are of the same kind.
  // 2. All input operands match.
  // 3. All other attributes match.
  bool Equals(Computation* other) const;

  // Returns a hash code for use with hash maps.
  virtual intptr_t Hashcode() const;

  // Compare attributes of an computation (except input operands and kind).
  // TODO(fschneider): Make this abstract and implement for all computations.
  virtual bool AttributesEqual(Computation* other) const { return true; }

  // Returns true if the instruction may have side effects.
  // TODO(fschneider): Make this abstract and implement for all computations
  // instead of returning the safe default (true).
  virtual bool HasSideEffect() const { return true; }

  // Compile time type of the computation, which typically depends on the
  // compile time types (and possibly propagated types) of its inputs.
  virtual RawAbstractType* CompileType() const = 0;
  virtual intptr_t ResultCid() const = 0;

  // Mutate assigned_vars to add the local variable index for all
  // frame-allocated locals assigned to by the computation.
  virtual void RecordAssignedVars(BitVector* assigned_vars,
                                  intptr_t fixed_parameter_count);

  virtual const char* DebugName() const = 0;

  // Printing support. These functions are sometimes overridden for custom
  // formatting. Otherwise, it prints in the format "opcode(op1, op2, op3)".
  virtual void PrintTo(BufferFormatter* f) const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;

  // Returns structure describing location constraints required
  // to emit native code for this computation.
  LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  virtual ComparisonComp* AsComparison() { return NULL; }

  // Create a location summary for this computation.
  // TODO(fschneider): Temporarily returns NULL for instructions
  // that are not yet converted to the location based code generation.
  virtual LocationSummary* MakeLocationSummary() const = 0;

  // TODO(fschneider): Make EmitNativeCode and locs const.
  virtual void EmitNativeCode(FlowGraphCompiler* compiler) = 0;

  static LocationSummary* MakeCallSummary();

  // Declare an enum value used to define kind-test predicates.
  enum ComputationKind {
#define DECLARE_COMPUTATION_KIND(ShortName, ClassName) k##ShortName,

  FOR_EACH_COMPUTATION(DECLARE_COMPUTATION_KIND)

#undef DECLARE_COMPUTATION_KIND
  };

  virtual ComputationKind computation_kind() const = 0;

  virtual Representation representation() const {
    return kTagged;
  }

  // Declare predicate for each computation.
#define DECLARE_PREDICATE(ShortName, ClassName)                                \
  inline bool Is##ShortName() const;                                           \
  inline const ClassName* As##ShortName() const;                               \
  inline ClassName* As##ShortName();
FOR_EACH_COMPUTATION(DECLARE_PREDICATE)
#undef DECLARE_PREDICATE

 private:
  intptr_t deopt_id_;
  const ICData* ic_data_;
  LocationSummary* locs_;

  DISALLOW_COPY_AND_ASSIGN(Computation);
};


// An embedded container with N elements of type T.  Used (with partial
// specialization for N=0) because embedded arrays cannot have size 0.
template<typename T, intptr_t N>
class EmbeddedArray {
 public:
  EmbeddedArray() {
    for (intptr_t i = 0; i < N; i++) elements_[i] = NULL;
  }

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


template<intptr_t N>
class TemplateComputation : public Computation {
 public:
  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }
  virtual void SetInputAt(intptr_t i, Value* value) {
    ASSERT(value != NULL);
    inputs_[i] = value;
  }

 protected:
  EmbeddedArray<Value*, N> inputs_;
};


class Value : public ZoneAllocated {
 public:
  Value() { }

  // Declare an enum value used to define kind-test predicates.
  enum ValueKind {
#define DECLARE_VALUE_KIND(ShortName, ClassName) k##ShortName,
  FOR_EACH_VALUE(DECLARE_VALUE_KIND)
#undef DECLARE_VALUE_KIND
  };

  // Declare predicate for each value.
#define DECLARE_PREDICATE(ShortName, ClassName)                                \
  inline bool Is##ShortName() const;                                           \
  inline const ClassName* As##ShortName() const;                               \
  inline ClassName* As##ShortName();
FOR_EACH_VALUE(DECLARE_PREDICATE)
#undef DECLARE_PREDICATE

  virtual ValueKind value_kind() const = 0;

  virtual RawAbstractType* CompileType() const = 0;
  virtual intptr_t ResultCid() const = 0;

  virtual void PrintTo(BufferFormatter* f) const = 0;

  // Returns true if the value represents a constant.
  virtual bool BindsToConstant() const = 0;

  // Returns true if the value represents constant null.
  virtual bool BindsToConstantNull() const = 0;

  // Assert if BindsToConstant() is false, otherwise returns constant.
  virtual const Object& BoundConstant() const = 0;

  // Reminder: The type of the constant null is the bottom type, which is more
  // specific than any type.
  bool CompileTypeIsMoreSpecificThan(const AbstractType& dst_type) const;

  // Compile time constants, Bool, Smi and Nulls do not need to update
  // the store buffer.
  bool NeedsStoreBuffer() const;

  virtual bool Equals(Value* other) const = 0;

  virtual Value* CopyValue() = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(Value);
};


// Functions defined in all concrete computation classes.
#define DECLARE_COMPUTATION(ShortName)                                         \
  virtual void Accept(FlowGraphVisitor* visitor, BindInstr* instr);            \
  virtual ComputationKind computation_kind() const {                           \
    return Computation::k##ShortName;                                          \
  }                                                                            \
  virtual intptr_t ArgumentCount() const { return 0; }                         \
  virtual const char* DebugName() const { return #ShortName; }                 \
  virtual RawAbstractType* CompileType() const;                                \
  virtual LocationSummary* MakeLocationSummary() const;                        \
  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

// Functions defined in all concrete value classes.
#define DECLARE_VALUE(ShortName)                                               \
  virtual ValueKind value_kind() const {                                       \
    return Value::k##ShortName;                                                \
  }                                                                            \
  virtual const char* DebugName() const { return #ShortName; }                 \
  virtual RawAbstractType* CompileType() const;                                \
  virtual bool Equals(Value* other) const;                                     \
  virtual void PrintTo(BufferFormatter* f) const;


// Function defined in all call computation classes.
#define DECLARE_CALL_COMPUTATION(ShortName)                                    \
  virtual void Accept(FlowGraphVisitor* visitor, BindInstr* instr);            \
  virtual ComputationKind computation_kind() const {                           \
    return Computation::k##ShortName;                                          \
  }                                                                            \
  virtual const char* DebugName() const { return #ShortName; }                 \
  virtual RawAbstractType* CompileType() const;                                \
  virtual LocationSummary* MakeLocationSummary() const;                        \
  virtual void EmitNativeCode(FlowGraphCompiler* compiler);


class Definition;
class PhiInstr;

class UseVal : public Value {
 public:
  explicit UseVal(Definition* definition)
      : definition_(definition),
        next_use_(NULL),
        instruction_(NULL),
        use_index_(-1) { }

  DECLARE_VALUE(Use)

  inline Definition* definition() const { return definition_; }
  void set_definition(Definition* definition) { definition_ = definition; }

  // Returns true if the value represents a constant.
  virtual bool BindsToConstant() const;
  virtual const Object& BoundConstant() const;

  // Returns true if the value represents constant null.
  virtual bool BindsToConstantNull() const;

  virtual bool CanDeoptimize() const { return false; }

  UseVal* next_use() const { return next_use_; }
  void set_next_use(UseVal* next) { next_use_ = next; }

  Instruction* instruction() const { return instruction_; }
  void set_instruction(Instruction* instruction) { instruction_ = instruction; }

  intptr_t use_index() const { return use_index_; }
  void set_use_index(intptr_t index) { use_index_ = index; }

  void AddToInputUseList();
  void AddToEnvUseList();

  virtual intptr_t ResultCid() const;

  virtual Value* CopyValue() { return new UseVal(definition_); }

 private:
  Definition* definition_;
  UseVal* next_use_;
  Instruction* instruction_;
  intptr_t use_index_;

  DISALLOW_COPY_AND_ASSIGN(UseVal);
};


class ConstantVal : public Value {
 public:
  explicit ConstantVal(const Object& value)
      : value_(value) {
    ASSERT(value.IsZoneHandle());
    ASSERT(value.IsSmi() || value.IsOld());
  }

  DECLARE_VALUE(Constant)

  const Object& value() const { return value_; }

  // Returns true if the value represents a constant.
  virtual bool BindsToConstant() const { return true; }
  virtual const Object& BoundConstant() const { return value(); }

  // Returns true if the value represents constant null.
  virtual bool BindsToConstantNull() const { return value().IsNull(); }

  virtual bool CanDeoptimize() const { return false; }

  virtual intptr_t ResultCid() const;

  virtual Value* CopyValue() { return this; }

 private:
  const Object& value_;

  DISALLOW_COPY_AND_ASSIGN(ConstantVal);
};

#undef DECLARE_VALUE


class MaterializeComp : public TemplateComputation<0> {
 public:
  explicit MaterializeComp(ConstantVal* constant_val)
      : constant_val_(constant_val) { }

  DECLARE_COMPUTATION(Materialize)

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  ConstantVal* constant_val() const { return constant_val_; }

  virtual intptr_t ResultCid() const;

 private:
  ConstantVal* constant_val_;
};


class AssertAssignableComp : public TemplateComputation<3> {
 public:
  AssertAssignableComp(intptr_t token_pos,
                       intptr_t try_index,
                       Value* value,
                       Value* instantiator,
                       Value* instantiator_type_arguments,
                       const AbstractType& dst_type,
                       const String& dst_name)
      : token_pos_(token_pos),
        try_index_(try_index),
        dst_type_(dst_type),
        dst_name_(dst_name),
        is_eliminated_(false) {
    ASSERT(value != NULL);
    ASSERT(instantiator != NULL);
    ASSERT(instantiator_type_arguments != NULL);
    ASSERT(!dst_type.IsNull());
    ASSERT(!dst_name.IsNull());
    inputs_[0] = value;
    inputs_[1] = instantiator;
    inputs_[2] = instantiator_type_arguments;
  }

  DECLARE_COMPUTATION(AssertAssignable)

  Value* value() const { return inputs_[0]; }
  Value* instantiator() const { return inputs_[1]; }
  Value* instantiator_type_arguments() const { return inputs_[2]; }

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  const AbstractType& dst_type() const { return dst_type_; }
  const String& dst_name() const { return dst_name_; }

  bool is_eliminated() const {
    return is_eliminated_;
  }
  void eliminate() {
    ASSERT(!is_eliminated_);
    is_eliminated_ = true;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const AbstractType& dst_type_;
  const String& dst_name_;
  bool is_eliminated_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableComp);
};


class AssertBooleanComp : public TemplateComputation<1> {
 public:
  AssertBooleanComp(intptr_t token_pos,
                    intptr_t try_index,
                    Value* value)
      : token_pos_(token_pos),
        try_index_(try_index),
        is_eliminated_(false) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(AssertBoolean)

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  Value* value() const { return inputs_[0]; }

  bool is_eliminated() const {
    return is_eliminated_;
  }
  void eliminate() {
    ASSERT(!is_eliminated_);
    is_eliminated_ = true;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kBoolCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  bool is_eliminated_;

  DISALLOW_COPY_AND_ASSIGN(AssertBooleanComp);
};


// Denotes the current context, normally held in a register.  This is
// a computation, not a value, because it's mutable.
class CurrentContextComp : public TemplateComputation<0> {
 public:
  CurrentContextComp() { }

  DECLARE_COMPUTATION(CurrentContext)

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  DISALLOW_COPY_AND_ASSIGN(CurrentContextComp);
};


class StoreContextComp : public TemplateComputation<1> {
 public:
  explicit StoreContextComp(Value* value) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(StoreContext);

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

 private:
  DISALLOW_COPY_AND_ASSIGN(StoreContextComp);
};


class ClosureCallComp : public TemplateComputation<0> {
 public:
  ClosureCallComp(ClosureCallNode* node,
                  intptr_t try_index,
                  ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : ast_node_(*node),
        try_index_(try_index),
        arguments_(arguments) { }

  DECLARE_CALL_COMPUTATION(ClosureCall)

  const Array& argument_names() const { return ast_node_.arguments()->names(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t try_index() const { return try_index_; }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  PushArgumentInstr* ArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const ClosureCallNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(ClosureCallComp);
};


class InstanceCallComp : public TemplateComputation<0> {
 public:
  InstanceCallComp(intptr_t token_pos,
                   intptr_t try_index,
                   const String& function_name,
                   Token::Kind token_kind,
                   ZoneGrowableArray<PushArgumentInstr*>* arguments,
                   const Array& argument_names,
                   intptr_t checked_argument_count)
      : token_pos_(token_pos),
        try_index_(try_index),
        function_name_(function_name),
        token_kind_(token_kind),
        arguments_(arguments),
        argument_names_(argument_names),
        checked_argument_count_(checked_argument_count) {
    ASSERT(function_name.IsZoneHandle());
    ASSERT(!arguments->is_empty());
    ASSERT(argument_names.IsZoneHandle());
    ASSERT(Token::IsBinaryToken(token_kind) ||
           Token::IsUnaryToken(token_kind) ||
           Token::IsIndexOperator(token_kind) ||
           token_kind == Token::kGET ||
           token_kind == Token::kSET ||
           token_kind == Token::kILLEGAL);
  }

  DECLARE_CALL_COMPUTATION(InstanceCall)

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  const String& function_name() const { return function_name_; }
  Token::Kind token_kind() const { return token_kind_; }
  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  PushArgumentInstr* ArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }
  const Array& argument_names() const { return argument_names_; }
  intptr_t checked_argument_count() const { return checked_argument_count_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const String& function_name_;
  const Token::Kind token_kind_;  // Binary op, unary op, kGET or kILLEGAL.
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;
  const Array& argument_names_;
  const intptr_t checked_argument_count_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallComp);
};


class PolymorphicInstanceCallComp : public TemplateComputation<0> {
 public:
  explicit PolymorphicInstanceCallComp(InstanceCallComp* comp, bool with_checks)
      : instance_call_(comp), with_checks_(with_checks) {
    ASSERT(instance_call_ != NULL);
  }

  InstanceCallComp* instance_call() const { return instance_call_; }
  bool with_checks() const { return with_checks_; }

  void PrintTo(BufferFormatter* f) const;

  virtual intptr_t ArgumentCount() const {
    return instance_call()->ArgumentCount();
  }

  DECLARE_CALL_COMPUTATION(PolymorphicInstanceCall)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  InstanceCallComp* instance_call_;
  const bool with_checks_;

  DISALLOW_COPY_AND_ASSIGN(PolymorphicInstanceCallComp);
};


class ComparisonComp : public TemplateComputation<2> {
 public:
  ComparisonComp(Token::Kind kind, Value* left, Value* right) : kind_(kind) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual ComparisonComp* AsComparison() { return this; }

  Token::Kind kind() const { return kind_; }

 private:
  Token::Kind kind_;
};


class StrictCompareComp : public ComparisonComp {
 public:
  StrictCompareComp(Token::Kind kind, Value* left, Value* right)
      : ComparisonComp(kind, left, right) {
    ASSERT((kind == Token::kEQ_STRICT) || (kind == Token::kNE_STRICT));
  }

  DECLARE_COMPUTATION(StrictCompare)

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }

  virtual Definition* TryReplace(BindInstr* instr) const;

  virtual intptr_t ResultCid() const { return kBoolCid; }

 private:
  DISALLOW_COPY_AND_ASSIGN(StrictCompareComp);
};


class EqualityCompareComp : public ComparisonComp {
 public:
  EqualityCompareComp(intptr_t token_pos,
                      intptr_t try_index,
                      Token::Kind kind,
                      Value* left,
                      Value* right)
      : ComparisonComp(kind, left, right),
        token_pos_(token_pos),
        try_index_(try_index),
        receiver_class_id_(kIllegalCid) {
    ASSERT((kind == Token::kEQ) || (kind == Token::kNE));
  }

  DECLARE_COMPUTATION(EqualityCompare)

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  // Receiver class id is computed from collected ICData.
  void set_receiver_class_id(intptr_t value) { receiver_class_id_ = value; }
  intptr_t receiver_class_id() const { return receiver_class_id_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const;

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  intptr_t receiver_class_id_;  // Set by optimizer.

  DISALLOW_COPY_AND_ASSIGN(EqualityCompareComp);
};


class RelationalOpComp : public ComparisonComp {
 public:
  RelationalOpComp(intptr_t token_pos,
                   intptr_t try_index,
                   Token::Kind kind,
                   Value* left,
                   Value* right)
      : ComparisonComp(kind, left, right),
        token_pos_(token_pos),
        try_index_(try_index),
        operands_class_id_(kIllegalCid) {
    ASSERT(Token::IsRelationalOperator(kind));
  }

  DECLARE_COMPUTATION(RelationalOp)

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  // TODO(srdjan): instead of class-id pass an enum that can differentiate
  // between boxed and unboxed doubles and integers.
  void set_operands_class_id(intptr_t value) {
    operands_class_id_ = value;
  }

  intptr_t operands_class_id() const { return operands_class_id_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const;

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  intptr_t operands_class_id_;  // class id of both operands.

  DISALLOW_COPY_AND_ASSIGN(RelationalOpComp);
};


class StaticCallComp : public TemplateComputation<0> {
 public:
  StaticCallComp(intptr_t token_pos,
                 intptr_t try_index,
                 const Function& function,
                 const Array& argument_names,
                 ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : token_pos_(token_pos),
        try_index_(try_index),
        function_(function),
        argument_names_(argument_names),
        arguments_(arguments),
        recognized_(MethodRecognizer::kUnknown) {
    ASSERT(function.IsZoneHandle());
    ASSERT(argument_names.IsZoneHandle());
  }

  DECLARE_CALL_COMPUTATION(StaticCall)

  // Accessors forwarded to the AST node.
  const Function& function() const { return function_; }
  const Array& argument_names() const { return argument_names_; }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  PushArgumentInstr* ArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  MethodRecognizer::Kind recognized() const { return recognized_; }
  void set_recognized(MethodRecognizer::Kind kind) { recognized_ = kind; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const Function& function_;
  const Array& argument_names_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;
  MethodRecognizer::Kind recognized_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallComp);
};


class LoadLocalComp : public TemplateComputation<0> {
 public:
  LoadLocalComp(const LocalVariable& local, intptr_t context_level)
      : local_(local),
        context_level_(context_level) { }

  DECLARE_COMPUTATION(LoadLocal)

  const LocalVariable& local() const { return local_; }
  intptr_t context_level() const { return context_level_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const LocalVariable& local_;
  const intptr_t context_level_;

  DISALLOW_COPY_AND_ASSIGN(LoadLocalComp);
};


class StoreLocalComp : public TemplateComputation<1> {
 public:
  StoreLocalComp(const LocalVariable& local,
                 Value* value,
                 intptr_t context_level)
      : local_(local),
        context_level_(context_level) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(StoreLocal)

  const LocalVariable& local() const { return local_; }
  Value* value() const { return inputs_[0]; }
  intptr_t context_level() const { return context_level_; }

  virtual void RecordAssignedVars(BitVector* assigned_vars,
                                  intptr_t fixed_parameter_count);

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const LocalVariable& local_;
  const intptr_t context_level_;

  DISALLOW_COPY_AND_ASSIGN(StoreLocalComp);
};


class NativeCallComp : public TemplateComputation<0> {
 public:
  NativeCallComp(NativeBodyNode* node, intptr_t try_index)
      : ast_node_(*node), try_index_(try_index) {}

  DECLARE_COMPUTATION(NativeCall)

  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t try_index() const { return try_index_; }

  const String& native_name() const {
    return ast_node_.native_c_function_name();
  }

  NativeFunction native_c_function() const {
    return ast_node_.native_c_function();
  }

  intptr_t argument_count() const { return ast_node_.argument_count(); }

  bool has_optional_parameters() const {
    return ast_node_.has_optional_parameters();
  }

  bool is_native_instance_closure() const {
    return ast_node_.is_native_instance_closure();
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const NativeBodyNode& ast_node_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallComp);
};


class LoadInstanceFieldComp : public TemplateComputation<1> {
 public:
  LoadInstanceFieldComp(const Field& field, Value* instance) : field_(field) {
    ASSERT(instance != NULL);
    inputs_[0] = instance;
  }

  DECLARE_COMPUTATION(LoadInstanceField)

  const Field& field() const { return field_; }
  Value* instance() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(LoadInstanceFieldComp);
};


class StoreInstanceFieldComp : public TemplateComputation<2> {
 public:
  StoreInstanceFieldComp(const Field& field,
                         Value* instance,
                         Value* value)
      : field_(field) {
    ASSERT(instance != NULL);
    ASSERT(value != NULL);
    inputs_[0] = instance;
    inputs_[1] = value;
  }

  DECLARE_COMPUTATION(StoreInstanceField)

  const Field& field() const { return field_; }

  Value* instance() const { return inputs_[0]; }
  Value* value() const { return inputs_[1]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(StoreInstanceFieldComp);
};


class LoadStaticFieldComp : public TemplateComputation<0> {
 public:
  explicit LoadStaticFieldComp(const Field& field) : field_(field) {}

  DECLARE_COMPUTATION(LoadStaticField);

  const Field& field() const { return field_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(LoadStaticFieldComp);
};


class StoreStaticFieldComp : public TemplateComputation<1> {
 public:
  StoreStaticFieldComp(const Field& field, Value* value)
      : field_(field) {
    ASSERT(field.IsZoneHandle());
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(StoreStaticField);

  const Field& field() const { return field_; }
  Value* value() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(StoreStaticFieldComp);
};


class LoadIndexedComp : public TemplateComputation<2> {
 public:
  LoadIndexedComp(Value* array,
                  Value* index,
                  intptr_t receiver_type,
                  InstanceCallComp* original)
      : receiver_type_(receiver_type),
        original_(original) {
    ASSERT(array != NULL);
    ASSERT(index != NULL);
    inputs_[0] = array;
    inputs_[1] = index;
  }

  DECLARE_COMPUTATION(LoadIndexed)

  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }

  intptr_t receiver_type() const { return receiver_type_; }

  InstanceCallComp* original() const { return original_; }

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  intptr_t receiver_type_;
  InstanceCallComp* original_;

  DISALLOW_COPY_AND_ASSIGN(LoadIndexedComp);
};


class StoreIndexedComp : public TemplateComputation<3> {
 public:
  StoreIndexedComp(Value* array,
                   Value* index,
                   Value* value,
                   intptr_t receiver_type,
                   InstanceCallComp* original)
        : receiver_type_(receiver_type),
          original_(original) {
    ASSERT(array != NULL);
    ASSERT(index != NULL);
    ASSERT(value != NULL);
    inputs_[0] = array;
    inputs_[1] = index;
    inputs_[2] = value;
  }

  DECLARE_COMPUTATION(StoreIndexed)

  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }
  Value* value() const { return inputs_[2]; }

  InstanceCallComp* original() const { return original_; }

  intptr_t receiver_type() const { return receiver_type_; }

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  intptr_t receiver_type_;
  InstanceCallComp* original_;

  DISALLOW_COPY_AND_ASSIGN(StoreIndexedComp);
};


// Note overrideable, built-in: value? false : true.
class BooleanNegateComp : public TemplateComputation<1> {
 public:
  explicit BooleanNegateComp(Value* value) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(BooleanNegate)

  Value* value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kBoolCid; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BooleanNegateComp);
};


class InstanceOfComp : public TemplateComputation<3> {
 public:
  InstanceOfComp(intptr_t token_pos,
                 intptr_t try_index,
                 Value* value,
                 Value* instantiator,
                 Value* instantiator_type_arguments,
                 const AbstractType& type,
                 bool negate_result)
      : token_pos_(token_pos),
        try_index_(try_index),
        type_(type),
        negate_result_(negate_result) {
    ASSERT(value != NULL);
    ASSERT(instantiator != NULL);
    ASSERT(instantiator_type_arguments != NULL);
    ASSERT(!type.IsNull());
    inputs_[0] = value;
    inputs_[1] = instantiator;
    inputs_[2] = instantiator_type_arguments;
  }

  DECLARE_COMPUTATION(InstanceOf)

  Value* value() const { return inputs_[0]; }
  Value* instantiator() const { return inputs_[1]; }
  Value* instantiator_type_arguments() const { return inputs_[2]; }

  bool negate_result() const { return negate_result_; }
  const AbstractType& type() const { return type_; }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kBoolCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  Value* value_;
  Value* instantiator_;
  Value* type_arguments_;
  const AbstractType& type_;
  const bool negate_result_;

  DISALLOW_COPY_AND_ASSIGN(InstanceOfComp);
};


class AllocateObjectComp : public TemplateComputation<0> {
 public:
  AllocateObjectComp(ConstructorCallNode* node,
                     intptr_t try_index,
                     ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : ast_node_(*node), try_index_(try_index), arguments_(arguments) {
    // Either no arguments or one type-argument and one instantiator.
    ASSERT(arguments->is_empty() || (arguments->length() == 2));
  }

  DECLARE_CALL_COMPUTATION(AllocateObject)

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  PushArgumentInstr* ArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;

  DISALLOW_COPY_AND_ASSIGN(AllocateObjectComp);
};


class AllocateObjectWithBoundsCheckComp : public TemplateComputation<2> {
 public:
  AllocateObjectWithBoundsCheckComp(ConstructorCallNode* node,
                                    intptr_t try_index,
                                    Value* type_arguments,
                                    Value* instantiator)
      : ast_node_(*node), try_index_(try_index) {
    ASSERT(type_arguments != NULL);
    ASSERT(instantiator != NULL);
    inputs_[0] = type_arguments;
    inputs_[1] = instantiator;
  }

  DECLARE_COMPUTATION(AllocateObjectWithBoundsCheck)

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(AllocateObjectWithBoundsCheckComp);
};


class CreateArrayComp : public TemplateComputation<1> {
 public:
  CreateArrayComp(intptr_t token_pos,
                  intptr_t try_index,
                  ZoneGrowableArray<PushArgumentInstr*>* arguments,
                  const AbstractType& type,
                  Value* element_type)
      : token_pos_(token_pos),
        try_index_(try_index),
        arguments_(arguments),
        type_(type) {
#if defined(DEBUG)
    for (int i = 0; i < ArgumentCount(); ++i) {
      ASSERT(ArgumentAt(i) != NULL);
    }
    ASSERT(element_type != NULL);
    ASSERT(type_.IsZoneHandle());
    ASSERT(!type_.IsNull());
    ASSERT(type_.IsFinalized());
#endif
    inputs_[0] = element_type;
  }

  DECLARE_CALL_COMPUTATION(CreateArray)

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  PushArgumentInstr* ArgumentAt(intptr_t i) const { return (*arguments_)[i]; }
  const AbstractType& type() const { return type_; }
  Value* element_type() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  ZoneGrowableArray<PushArgumentInstr*>* const arguments_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(CreateArrayComp);
};


class CreateClosureComp : public TemplateComputation<0> {
 public:
  CreateClosureComp(ClosureNode* node,
                    intptr_t try_index,
                    ZoneGrowableArray<PushArgumentInstr*>* arguments)
      : ast_node_(*node),
        try_index_(try_index),
        arguments_(arguments) { }

  DECLARE_CALL_COMPUTATION(CreateClosure)

  intptr_t token_pos() const { return ast_node_.token_pos(); }
  intptr_t try_index() const { return try_index_; }
  const Function& function() const { return ast_node_.function(); }

  virtual intptr_t ArgumentCount() const { return arguments_->length(); }
  PushArgumentInstr* ArgumentAt(intptr_t index) const {
    return (*arguments_)[index];
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const ClosureNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<PushArgumentInstr*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(CreateClosureComp);
};


class LoadVMFieldComp : public TemplateComputation<1> {
 public:
  LoadVMFieldComp(Value* value,
                  intptr_t offset_in_bytes,
                  const AbstractType& type)
      : offset_in_bytes_(offset_in_bytes),
        type_(type),
        result_cid_(kDynamicCid),
        original_(NULL) {
    ASSERT(value != NULL);
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(LoadVMField)

  Value* value() const { return inputs_[0]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }
  const InstanceCallComp* original() const { return original_; }
  void set_original(InstanceCallComp* value) { original_ = value; }
  void set_result_cid(intptr_t value) { result_cid_ = value; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return result_cid_; }

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;
  intptr_t result_cid_;
  const InstanceCallComp* original_;  // For optimizations.
  // If non-NULL, the instruction is valid only for the class ids listed.

  DISALLOW_COPY_AND_ASSIGN(LoadVMFieldComp);
};


class StoreVMFieldComp : public TemplateComputation<2> {
 public:
  StoreVMFieldComp(Value* dest,
                   intptr_t offset_in_bytes,
                   Value* value,
                   const AbstractType& type)
      : offset_in_bytes_(offset_in_bytes), type_(type) {
    ASSERT(value != NULL);
    ASSERT(dest != NULL);
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    inputs_[0] = value;
    inputs_[1] = dest;
  }

  DECLARE_COMPUTATION(StoreVMField)

  Value* value() const { return inputs_[0]; }
  Value* dest() const { return inputs_[1]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(StoreVMFieldComp);
};


class InstantiateTypeArgumentsComp : public TemplateComputation<1> {
 public:
  InstantiateTypeArgumentsComp(intptr_t token_pos,
                               intptr_t try_index,
                               const AbstractTypeArguments& type_arguments,
                               Value* instantiator)
      : token_pos_(token_pos),
        try_index_(try_index),
        type_arguments_(type_arguments) {
    ASSERT(type_arguments.IsZoneHandle());
    ASSERT(instantiator != NULL);
    inputs_[0] = instantiator;
  }

  DECLARE_COMPUTATION(InstantiateTypeArguments)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const AbstractTypeArguments& type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(InstantiateTypeArgumentsComp);
};


class ExtractConstructorTypeArgumentsComp : public TemplateComputation<1> {
 public:
  ExtractConstructorTypeArgumentsComp(
      intptr_t token_pos,
      intptr_t try_index,
      const AbstractTypeArguments& type_arguments,
      Value* instantiator)
      : token_pos_(token_pos),
        try_index_(try_index),
        type_arguments_(type_arguments) {
    ASSERT(instantiator != NULL);
    inputs_[0] = instantiator;
  }

  DECLARE_COMPUTATION(ExtractConstructorTypeArguments)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const AbstractTypeArguments& type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorTypeArgumentsComp);
};


class ExtractConstructorInstantiatorComp : public TemplateComputation<1> {
 public:
  ExtractConstructorInstantiatorComp(ConstructorCallNode* ast_node,
                                     Value* instantiator)
      : ast_node_(*ast_node) {
    ASSERT(instantiator != NULL);
    inputs_[0] = instantiator;
  }

  DECLARE_COMPUTATION(ExtractConstructorInstantiator)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_pos() const { return ast_node_.token_pos(); }

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const ConstructorCallNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorInstantiatorComp);
};


class AllocateContextComp : public TemplateComputation<0> {
 public:
  AllocateContextComp(intptr_t token_pos,
                      intptr_t try_index,
                      intptr_t num_context_variables)
      : token_pos_(token_pos),
        try_index_(try_index),
        num_context_variables_(num_context_variables) {}

  DECLARE_COMPUTATION(AllocateContext);

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kDynamicCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const intptr_t num_context_variables_;

  DISALLOW_COPY_AND_ASSIGN(AllocateContextComp);
};


class ChainContextComp : public TemplateComputation<1> {
 public:
  explicit ChainContextComp(Value* context_value) {
    ASSERT(context_value != NULL);
    inputs_[0] = context_value;
  }

  DECLARE_COMPUTATION(ChainContext)

  Value* context_value() const { return inputs_[0]; }

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

 private:
  DISALLOW_COPY_AND_ASSIGN(ChainContextComp);
};


class CloneContextComp : public TemplateComputation<1> {
 public:
  CloneContextComp(intptr_t token_pos,
                   intptr_t try_index,
                   Value* context_value)
      : token_pos_(token_pos),
        try_index_(try_index) {
    ASSERT(context_value != NULL);
    inputs_[0] = context_value;
  }

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }
  Value* context_value() const { return inputs_[0]; }

  DECLARE_COMPUTATION(CloneContext)

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(CloneContextComp);
};


class CatchEntryComp : public TemplateComputation<0> {
 public:
  CatchEntryComp(const LocalVariable& exception_var,
                 const LocalVariable& stacktrace_var)
      : exception_var_(exception_var), stacktrace_var_(stacktrace_var) {}

  const LocalVariable& exception_var() const { return exception_var_; }
  const LocalVariable& stacktrace_var() const { return stacktrace_var_; }

  DECLARE_COMPUTATION(CatchEntry)

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

 private:
  const LocalVariable& exception_var_;
  const LocalVariable& stacktrace_var_;

  DISALLOW_COPY_AND_ASSIGN(CatchEntryComp);
};


class CheckEitherNonSmiComp : public TemplateComputation<2> {
 public:
  CheckEitherNonSmiComp(Value* left,
                        Value* right,
                        InstanceCallComp* instance_call)
      : instance_call_(instance_call) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  DECLARE_COMPUTATION(CheckEitherNonSmi)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

  virtual bool HasSideEffect() const { return false; }

  Value* left() const { return inputs_[0]; }

  Value* right() const { return inputs_[1]; }

  virtual Definition* TryReplace(BindInstr* instr) const;

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(CheckEitherNonSmiComp);
};


class BoxDoubleComp : public TemplateComputation<1> {
 public:
  BoxDoubleComp(Value* value, InstanceCallComp* instance_call)
      : instance_call_(instance_call) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  Value* value() const { return inputs_[0]; }
  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual bool CanDeoptimize() const { return false; }

  virtual intptr_t ResultCid() const;

  DECLARE_COMPUTATION(BoxDouble)

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(BoxDoubleComp);
};


class UnboxDoubleComp : public TemplateComputation<1> {
 public:
  UnboxDoubleComp(Value* value, InstanceCallComp* instance_call)
      : instance_call_(instance_call) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  Value* value() const { return inputs_[0]; }
  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual bool CanDeoptimize() const {
    return value()->ResultCid() != kDoubleCid;
  }
  // The output is not an instance.
  virtual intptr_t ResultCid() const { return kDynamicCid; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  DECLARE_COMPUTATION(UnboxDouble)

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(UnboxDoubleComp);
};


class UnboxedDoubleBinaryOpComp : public TemplateComputation<2> {
 public:
  UnboxedDoubleBinaryOpComp(Token::Kind op_kind,
                            Value* left,
                            Value* right)
      : op_kind_(op_kind) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  virtual bool CanDeoptimize() const { return false; }
  // The output is not an instance.
  virtual intptr_t ResultCid() const { return kDynamicCid; }

  virtual Representation representation() const {
    return kUnboxedDouble;
  }

  DECLARE_COMPUTATION(UnboxedDoubleBinaryOp)

 private:
  const Token::Kind op_kind_;

  DISALLOW_COPY_AND_ASSIGN(UnboxedDoubleBinaryOpComp);
};


class BinarySmiOpComp : public TemplateComputation<2> {
 public:
  BinarySmiOpComp(Token::Kind op_kind,
                  InstanceCallComp* instance_call,
                  Value* left,
                  Value* right)
      : op_kind_(op_kind),
        instance_call_(instance_call) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_COMPUTATION(BinarySmiOp)

  virtual bool CanDeoptimize() const;

  virtual intptr_t ResultCid() const;

 private:
  const Token::Kind op_kind_;
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(BinarySmiOpComp);
};


class BinaryMintOpComp : public TemplateComputation<2> {
 public:
  BinaryMintOpComp(Token::Kind op_kind,
                   InstanceCallComp* instance_call,
                   Value* left,
                   Value* right)
      : op_kind_(op_kind),
        instance_call_(instance_call) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_COMPUTATION(BinaryMintOp)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const;

 private:
  const Token::Kind op_kind_;
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(BinaryMintOpComp);
};


class BinaryDoubleOpComp : public TemplateComputation<0> {
 public:
  BinaryDoubleOpComp(Token::Kind op_kind, InstanceCallComp* instance_call)
      : op_kind_(op_kind), instance_call_(instance_call) { }

  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_CALL_COMPUTATION(BinaryDoubleOp)

  virtual intptr_t ArgumentCount() const { return 2; }

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const;

 private:
  const Token::Kind op_kind_;
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(BinaryDoubleOpComp);
};


// Handles both Smi operations: BIT_OR and NEGATE.
class UnarySmiOpComp : public TemplateComputation<1> {
 public:
  UnarySmiOpComp(Token::Kind op_kind,
                 InstanceCallComp* instance_call,
                 Value* value)
      : op_kind_(op_kind), instance_call_(instance_call) {
    ASSERT((op_kind == Token::kNEGATE) || (op_kind == Token::kBIT_NOT));
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  Value* value() const { return inputs_[0]; }
  Token::Kind op_kind() const { return op_kind_; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

  DECLARE_COMPUTATION(UnarySmiOp)

  virtual bool CanDeoptimize() const { return op_kind() == Token::kNEGATE; }
  virtual intptr_t ResultCid() const { return kSmiCid; }

 private:
  const Token::Kind op_kind_;
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(UnarySmiOpComp);
};


// Handles non-Smi NEGATE operations
class NumberNegateComp : public TemplateComputation<1> {
 public:
  NumberNegateComp(InstanceCallComp* instance_call,
                   Value* value) : instance_call_(instance_call) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  Value* value() const { return inputs_[0]; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  DECLARE_COMPUTATION(NumberNegate)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDoubleCid; }

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(NumberNegateComp);
};


class CheckStackOverflowComp : public TemplateComputation<0> {
 public:
  CheckStackOverflowComp(intptr_t token_pos, intptr_t try_index)
      : token_pos_(token_pos),
        try_index_(try_index) {}

  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  DECLARE_COMPUTATION(CheckStackOverflow)

  virtual bool CanDeoptimize() const { return false; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

 private:
  const intptr_t token_pos_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(CheckStackOverflowComp);
};


class DoubleToDoubleComp : public TemplateComputation<1> {
 public:
  DoubleToDoubleComp(Value* value, InstanceCallComp* instance_call)
      : instance_call_(instance_call) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  Value* value() const { return inputs_[0]; }

  InstanceCallComp* instance_call() const { return instance_call_; }

  DECLARE_COMPUTATION(DoubleToDouble)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDoubleCid; }

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(DoubleToDoubleComp);
};


class SmiToDoubleComp : public TemplateComputation<0> {
 public:
  explicit SmiToDoubleComp(InstanceCallComp* instance_call)
      : instance_call_(instance_call) { }

  InstanceCallComp* instance_call() const { return instance_call_; }

  DECLARE_CALL_COMPUTATION(SmiToDouble)

  virtual intptr_t ArgumentCount() const { return 1; }

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kDoubleCid; }

 private:
  InstanceCallComp* instance_call_;

  DISALLOW_COPY_AND_ASSIGN(SmiToDoubleComp);
};


class CheckClassComp : public TemplateComputation<1> {
 public:
  CheckClassComp(Value* value, InstanceCallComp* original)
      : original_(original) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(CheckClass)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

  virtual bool AttributesEqual(Computation* other) const;

  virtual bool HasSideEffect() const { return false; }

  Value* value() const { return inputs_[0]; }

  intptr_t deopt_id() const { return original_->deopt_id(); }
  intptr_t try_index() const { return original_->try_index(); }

  virtual Definition* TryReplace(BindInstr* instr) const;

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  InstanceCallComp* original_;

  DISALLOW_COPY_AND_ASSIGN(CheckClassComp);
};


class CheckSmiComp : public TemplateComputation<1> {
 public:
  CheckSmiComp(Value* value, InstanceCallComp* original)
      : original_(original) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(CheckSmi)

  virtual bool CanDeoptimize() const { return true; }
  virtual intptr_t ResultCid() const { return kIllegalCid; }

  virtual bool AttributesEqual(Computation* other) const { return true; }

  virtual bool HasSideEffect() const { return false; }

  virtual Definition* TryReplace(BindInstr* instr) const;

  Value* value() const { return inputs_[0]; }

  intptr_t deopt_id() const { return original_->deopt_id(); }
  intptr_t try_index() const { return original_->try_index(); }

 private:
  InstanceCallComp* original_;

  DISALLOW_COPY_AND_ASSIGN(CheckSmiComp);
};


#undef DECLARE_COMPUTATION


// Implementation of type testers and cast functins.
#define DEFINE_COMPUTATION_PREDICATE(ShortName, ClassName)                     \
bool Computation::Is##ShortName() const {                                      \
  return computation_kind() == k##ShortName;                                   \
}                                                                              \
const ClassName* Computation::As##ShortName() const {                          \
  if (!Is##ShortName()) return NULL;                                           \
  return static_cast<const ClassName*>(this);                                  \
}                                                                              \
ClassName* Computation::As##ShortName() {                                      \
  if (!Is##ShortName()) return NULL;                                           \
  return static_cast<ClassName*>(this);                                        \
}
FOR_EACH_COMPUTATION(DEFINE_COMPUTATION_PREDICATE)
#undef DEFINE_COMPUTATION_PREDICATE

#define DEFINE_VALUE_PREDICATE(ShortName, ClassName)                           \
bool Value::Is##ShortName() const {                                            \
  return value_kind() == k##ShortName;                                         \
}                                                                              \
const ClassName* Value::As##ShortName() const {                                \
  if (!Is##ShortName()) return NULL;                                           \
  return static_cast<const ClassName*>(this);                                  \
}                                                                              \
ClassName* Value::As##ShortName() {                                            \
  if (!Is##ShortName()) return NULL;                                           \
  return static_cast<ClassName*>(this);                                        \
}
FOR_EACH_VALUE(DEFINE_VALUE_PREDICATE)
#undef DEFINE_VALUE_PREDICATE

// Instructions.

// M is a single argument macro.  It is applied to each concrete instruction
// type name.  The concrete instruction classes are the name with Instr
// concatenated.
#define FOR_EACH_INSTRUCTION(M)                                                \
  M(GraphEntry)                                                                \
  M(JoinEntry)                                                                 \
  M(TargetEntry)                                                               \
  M(Phi)                                                                       \
  M(Bind)                                                                      \
  M(Parameter)                                                                 \
  M(ParallelMove)                                                              \
  M(PushArgument)                                                              \
  M(Return)                                                                    \
  M(Throw)                                                                     \
  M(ReThrow)                                                                   \
  M(Goto)                                                                      \
  M(Branch)                                                                    \
  M(StrictCompareAndBranch)


// Forward declarations for Instruction classes.
class BlockEntryInstr;
class FlowGraphBuilder;
class Environment;

#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION


// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                                              \
  virtual void Accept(FlowGraphVisitor* visitor);                              \
  virtual bool Is##type() const { return true; }                               \
  virtual type##Instr* As##type() { return this; }                             \
  virtual const char* DebugName() const { return #type; }                      \
  virtual void PrintTo(BufferFormatter* f) const;                              \
  virtual void PrintToVisualizer(BufferFormatter* f) const;


class Instruction : public ZoneAllocated {
 public:
  Instruction()
      : lifetime_position_(-1), previous_(NULL), next_(NULL), env_(NULL) { }

  virtual bool IsBlockEntry() const { return false; }
  BlockEntryInstr* AsBlockEntry() {
    return IsBlockEntry() ? reinterpret_cast<BlockEntryInstr*>(this) : NULL;
  }
  virtual bool IsDefinition() const { return false; }
  virtual Definition* AsDefinition() { return NULL; }
  virtual bool IsControl() const { return false; }

  virtual intptr_t InputCount() const = 0;
  virtual Value* InputAt(intptr_t i) const = 0;
  virtual void SetInputAt(intptr_t i, Value* value) = 0;

  // Call instructions override this function and return the
  // number of pushed arguments.
  virtual intptr_t ArgumentCount() const = 0;

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
    ASSERT(!IsControl());
    ASSERT(!IsPhi());
    ASSERT(instr == NULL || !instr->IsBlockEntry());
    // TODO(fschneider): Also add Throw and ReThrow to the list of instructions
    // that do not have a successor. Currently, the graph builder will continue
    // to append instruction in case of a Throw inside an expression. This
    // condition should be handled in the graph builder
    next_ = instr;
  }

  // Removed this instruction from the graph.
  Instruction* RemoveFromGraph(bool return_previous = true);

  // Normal instructions can have 0 (inside a block) or 1 (last instruction in
  // a block) successors. Branch instruction with >1 successors override this
  // function.
  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  void Goto(JoinEntryInstr* entry);

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
  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count,
      intptr_t fixed_parameter_count) {
    // Never called for instructions except block entries and branches.
    UNREACHABLE();
  }

  // Mutate assigned_vars to add the local variable index for all
  // frame-allocated locals assigned to by the instruction.
  virtual void RecordAssignedVars(BitVector* assigned_vars,
                                  intptr_t fixed_parameter_count);

  // Printing support.
  virtual void PrintTo(BufferFormatter* f) const = 0;
  virtual void PrintToVisualizer(BufferFormatter* f) const = 0;

#define INSTRUCTION_TYPE_CHECK(type)                                           \
  virtual bool Is##type() const { return false; }                              \
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

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    UNIMPLEMENTED();
  }

  Environment* env() const { return env_; }
  void set_env(Environment* env) { env_ = env; }

  intptr_t lifetime_position() const { return lifetime_position_; }
  void set_lifetime_position(intptr_t pos) {
    lifetime_position_ = pos;
  }

  virtual Representation representation() const {
    return kTagged;
  }

 private:
  friend class BindInstr;  // Needed for BindInstr::InsertBefore.

  intptr_t lifetime_position_;  // Position used by register allocator.
  Instruction* previous_;
  Instruction* next_;
  Environment* env_;
  DISALLOW_COPY_AND_ASSIGN(Instruction);
};


template<intptr_t N>
class TemplateInstruction: public Instruction {
 public:
  TemplateInstruction<N>() : locs_(NULL) { }

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }
  virtual void SetInputAt(intptr_t i, Value* value) {
    ASSERT(value != NULL);
    inputs_[i] = value;
  }

  virtual LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  virtual LocationSummary* MakeLocationSummary() const = 0;

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
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

  MoveOperands* AddMove(Location dest, Location src) {
    MoveOperands* move = new MoveOperands(dest, src);
    moves_.Add(move);
    return move;
  }

  MoveOperands* MoveOperandsAt(intptr_t index) const { return moves_[index]; }

  void SetSrcSlotAt(intptr_t index, const Location& loc);
  void SetDestSlotAt(intptr_t index, const Location& loc);

  intptr_t NumMoves() const { return moves_.length(); }

  LocationSummary* MakeLocationSummary() const { return NULL; }

  void EmitNativeCode(FlowGraphCompiler* compiler) { UNREACHABLE(); }

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
  virtual bool IsBlockEntry() const { return true; }

  virtual intptr_t PredecessorCount() const = 0;
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const = 0;
  virtual void AddPredecessor(BlockEntryInstr* predecessor) = 0;
  virtual void PrepareEntry(FlowGraphCompiler* compiler) = 0;

  intptr_t preorder_number() const { return preorder_number_; }
  void set_preorder_number(intptr_t number) { preorder_number_ = number; }

  intptr_t postorder_number() const { return postorder_number_; }
  void set_postorder_number(intptr_t number) { postorder_number_ = number; }

  intptr_t block_id() const { return block_id_; }
  void set_block_id(intptr_t value) { block_id_ = value; }

  void set_start_pos(intptr_t pos) { start_pos_ = pos; }
  intptr_t start_pos() const { return start_pos_; }
  void  set_end_pos(intptr_t pos) { end_pos_ = pos; }
  intptr_t end_pos() const { return end_pos_; }

  BlockEntryInstr* dominator() const { return dominator_; }
  void set_dominator(BlockEntryInstr* instr) { dominator_ = instr; }

  const GrowableArray<BlockEntryInstr*>& dominated_blocks() {
    return dominated_blocks_;
  }

  void AddDominatedBlock(BlockEntryInstr* block) {
    dominated_blocks_.Add(block);
  }

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

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count,
      intptr_t fixed_parameter_count);

  virtual intptr_t InputCount() const { return 0; }
  virtual Value* InputAt(intptr_t i) const {
    UNREACHABLE();
    return NULL;
  }
  virtual void SetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual bool CanDeoptimize() const { return false; }

 protected:
  BlockEntryInstr()
      : preorder_number_(-1),
        postorder_number_(-1),
        block_id_(-1),
        dominator_(NULL),
        dominated_blocks_(1),
        last_instruction_(NULL),
        parallel_move_(NULL) { }

 private:
  intptr_t preorder_number_;
  intptr_t postorder_number_;
  // Starting and ending lifetime positions for this block.  Used by
  // the linear scan register allocator.
  intptr_t block_id_;
  intptr_t start_pos_;
  intptr_t end_pos_;
  BlockEntryInstr* dominator_;  // Immediate dominator, NULL for graph entry.
  // TODO(fschneider): Optimize the case of one child to save space.
  GrowableArray<BlockEntryInstr*> dominated_blocks_;
  Instruction* last_instruction_;

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the start of the block.
  ParallelMoveInstr* parallel_move_;

  DISALLOW_COPY_AND_ASSIGN(BlockEntryInstr);
};


class ForwardInstructionIterator : public ValueObject {
 public:
  explicit ForwardInstructionIterator(BlockEntryInstr* block_entry)
      : block_entry_(block_entry), current_(block_entry) {
    ASSERT(block_entry_->last_instruction()->next() == NULL);
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
  BlockEntryInstr* block_entry_;
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
  explicit GraphEntryInstr(TargetEntryInstr* normal_entry)
      : BlockEntryInstr(),
        normal_entry_(normal_entry),
        catch_entries_(),
        start_env_(NULL),
        spill_slot_count_(0) { }

  DECLARE_INSTRUCTION(GraphEntry)

  virtual intptr_t PredecessorCount() const { return 0; }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    UNREACHABLE();
    return NULL;
  }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) { UNREACHABLE(); }

  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count,
      intptr_t fixed_parameter_count);

  void AddCatchEntry(TargetEntryInstr* entry) { catch_entries_.Add(entry); }

  virtual void PrepareEntry(FlowGraphCompiler* compiler);

  Environment* start_env() const { return start_env_; }
  void set_start_env(Environment* env) { start_env_ = env; }

  intptr_t spill_slot_count() const { return spill_slot_count_; }
  void set_spill_slot_count(intptr_t count) {
    ASSERT(count >= 0);
    spill_slot_count_ = count;
  }

 private:
  TargetEntryInstr* normal_entry_;
  GrowableArray<TargetEntryInstr*> catch_entries_;
  Environment* start_env_;
  intptr_t spill_slot_count_;

  DISALLOW_COPY_AND_ASSIGN(GraphEntryInstr);
};


class JoinEntryInstr : public BlockEntryInstr {
 public:
  JoinEntryInstr()
      : BlockEntryInstr(),
        predecessors_(2),  // Two is the assumed to be the common case.
        phis_(NULL),
        phi_count_(0) { }

  DECLARE_INSTRUCTION(JoinEntry)

  virtual intptr_t PredecessorCount() const { return predecessors_.length(); }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    return predecessors_[index];
  }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    predecessors_.Add(predecessor);
  }

  // Returns -1 if pred is not in the list.
  intptr_t IndexOfPredecessor(BlockEntryInstr* pred) const;

  ZoneGrowableArray<PhiInstr*>* phis() const { return phis_; }

  virtual void PrepareEntry(FlowGraphCompiler* compiler);

  void InsertPhi(intptr_t var_index, intptr_t var_count);
  void RemoveDeadPhis();

  intptr_t phi_count() const { return phi_count_; }

 private:
  GrowableArray<BlockEntryInstr*> predecessors_;
  ZoneGrowableArray<PhiInstr*>* phis_;
  intptr_t phi_count_;

  DISALLOW_COPY_AND_ASSIGN(JoinEntryInstr);
};


class TargetEntryInstr : public BlockEntryInstr {
 public:
  TargetEntryInstr()
      : BlockEntryInstr(),
        predecessor_(NULL),
        try_index_(CatchClauseNode::kInvalidTryIndex) { }

  // Used for exception catch entries.
  explicit TargetEntryInstr(intptr_t try_index)
      : BlockEntryInstr(),
        predecessor_(NULL),
        try_index_(try_index) { }

  DECLARE_INSTRUCTION(TargetEntry)

  virtual intptr_t PredecessorCount() const {
    return (predecessor_ == NULL) ? 0 : 1;
  }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    ASSERT((index == 0) && (predecessor_ != NULL));
    return predecessor_;
  }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    ASSERT(predecessor_ == NULL);
    predecessor_ = predecessor;
  }

  bool HasTryIndex() const {
    return try_index_ != CatchClauseNode::kInvalidTryIndex;
  }

  intptr_t try_index() const {
    ASSERT(HasTryIndex());
    return try_index_;
  }

  virtual void PrepareEntry(FlowGraphCompiler* compiler);

 private:
  BlockEntryInstr* predecessor_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(TargetEntryInstr);
};


// Abstract super-class of all instructions that define a value (Bind, Phi).
class Definition : public Instruction {
 public:
  Definition()
      : temp_index_(-1),
        ssa_temp_index_(-1),
        propagated_type_(AbstractType::Handle()),
        propagated_cid_(kIllegalCid),
        input_use_list_(NULL),
        env_use_list_(NULL) { }

  virtual bool IsDefinition() const { return true; }
  virtual Definition* AsDefinition() { return this; }

  intptr_t temp_index() const { return temp_index_; }
  void set_temp_index(intptr_t index) { temp_index_ = index; }

  intptr_t ssa_temp_index() const { return ssa_temp_index_; }
  void set_ssa_temp_index(intptr_t index) {
    ASSERT(index >= 0);
    ssa_temp_index_ = index;
  }
  bool HasSSATemp() const { return ssa_temp_index_ >= 0; }

  // Compile time type of the definition, which may be requested before type
  // propagation during graph building.
  virtual RawAbstractType* CompileType() const = 0;

  bool HasPropagatedType() const {
    return !propagated_type_.IsNull();
  }
  RawAbstractType* PropagatedType() const {
    ASSERT(HasPropagatedType());
    return propagated_type_.raw();
  }
  // Returns true if the propagated type has changed.
  bool SetPropagatedType(const AbstractType& propagated_type) {
    if (propagated_type.IsNull()) {
      // Not a typed definition, e.g. access to a VM field.
      return false;
    }
    const bool changed =
        propagated_type_.IsNull() || !propagated_type.Equals(propagated_type_);
    propagated_type_ = propagated_type.raw();
    return changed;
  }

  bool has_propagated_cid() const { return propagated_cid_ != kIllegalCid; }
  intptr_t propagated_cid() const { return propagated_cid_; }
  // May compute and set propagated cid.
  virtual intptr_t GetPropagatedCid() = 0;

  // Returns true if the propagated cid has changed.
  bool SetPropagatedCid(intptr_t cid);

  UseVal* input_use_list() { return input_use_list_; }
  void set_input_use_list(UseVal* head) { input_use_list_ = head; }

  UseVal* env_use_list() { return env_use_list_; }
  void set_env_use_list(UseVal* head) { env_use_list_ = head; }

  // Replace uses of this definition with uses of other definition or value.
  // Precondition: use lists must be properly calculated.
  // Postcondition: use lists and use values are still valid.
  void ReplaceUsesWith(Definition* other);
  void ReplaceUsesWith(Value* value);

 private:
  intptr_t temp_index_;
  intptr_t ssa_temp_index_;
  // TODO(regis): GrowableArray<const AbstractType*> propagated_types_;
  // For now:
  AbstractType& propagated_type_;
  intptr_t propagated_cid_;
  UseVal* input_use_list_;
  UseVal* env_use_list_;

  DISALLOW_COPY_AND_ASSIGN(Definition);
};


class BindInstr : public Definition {
 public:
  enum UseKind { kUnused, kUsed };

  BindInstr(UseKind used, Computation* computation)
      : computation_(computation), is_used_(used != kUnused) {
    ASSERT(computation != NULL);
  }

  DECLARE_INSTRUCTION(Bind)

  virtual intptr_t ArgumentCount() const {
    return computation()->ArgumentCount();
  }
  intptr_t InputCount() const { return computation()->InputCount(); }

  Value* InputAt(intptr_t i) const { return computation()->InputAt(i); }

  void SetInputAt(intptr_t i, Value* value) {
    computation()->SetInputAt(i, value);
  }

  virtual bool CanDeoptimize() const { return computation()->CanDeoptimize(); }

  Computation* computation() const { return computation_; }
  void set_computation(Computation* value) { computation_ = value; }
  bool is_used() const { return is_used_; }

  virtual RawAbstractType* CompileType() const;
  virtual intptr_t GetPropagatedCid();

  virtual void RecordAssignedVars(BitVector* assigned_vars,
                                  intptr_t fixed_parameter_count);

  intptr_t Hashcode() const { return computation()->Hashcode(); }

  bool Equals(BindInstr* other) const {
    return computation()->Equals(other->computation());
  }

  virtual LocationSummary* locs() {
    return computation()->locs();
  }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  // Insert this instruction before 'next'.
  void InsertBefore(Instruction* next);

  // Insert this instruction after 'prev'.
  void InsertAfter(Instruction* prev);

  virtual Representation representation() const {
    return computation()->representation();
  }

 private:
  Computation* computation_;
  const bool is_used_;

  DISALLOW_COPY_AND_ASSIGN(BindInstr);
};


class PhiInstr : public Definition {
 public:
  explicit PhiInstr(intptr_t num_inputs)
    : inputs_(num_inputs), is_alive_(false) {
    for (intptr_t i = 0; i < num_inputs; ++i) {
      inputs_.Add(NULL);
    }
  }

  virtual RawAbstractType* CompileType() const;
  virtual intptr_t GetPropagatedCid() { return propagated_cid(); }

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t InputCount() const { return inputs_.length(); }

  Value* InputAt(intptr_t i) const { return inputs_[i]; }

  void SetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }

  virtual bool CanDeoptimize() const { return false; }

  // TODO(regis): This helper will be removed once we support type sets.
  RawAbstractType* LeastSpecificInputType() const;

  // Phi is alive if it reaches a non-environment use.
  bool is_alive() const { return is_alive_; }
  void mark_alive() { is_alive_ = true; }

  DECLARE_INSTRUCTION(Phi)

 private:
  GrowableArray<Value*> inputs_;
  bool is_alive_;

  DISALLOW_COPY_AND_ASSIGN(PhiInstr);
};


class ParameterInstr : public Definition {
 public:
  explicit ParameterInstr(intptr_t index) : index_(index) { }

  DECLARE_INSTRUCTION(Parameter)

  intptr_t index() const { return index_; }

  // Compile type of the passed-in parameter.
  virtual RawAbstractType* CompileType() const;
  // No known propagated cid for parameters.
  virtual intptr_t GetPropagatedCid() { return propagated_cid(); }

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t InputCount() const { return 0; }
  Value* InputAt(intptr_t i) const {
    UNREACHABLE();
    return NULL;
  }
  void SetInputAt(intptr_t i, Value* value) { UNREACHABLE(); }

  virtual bool CanDeoptimize() const { return false; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(ParameterInstr);
};


class PushArgumentInstr : public Definition {
 public:
  explicit PushArgumentInstr(Value* value) : value_(value), locs_(NULL) {
    ASSERT(value != NULL);
  }

  DECLARE_INSTRUCTION(PushArgument)

  intptr_t InputCount() const { return 1; }
  Value* InputAt(intptr_t i) const {
    ASSERT(i == 0);
    return value_;
  }
  void SetInputAt(intptr_t i, Value* value) {
    ASSERT(i == 0);
    value_ = value;
  }

  virtual intptr_t ArgumentCount() const { return 0; }

  virtual RawAbstractType* CompileType() const;
  virtual intptr_t GetPropagatedCid() { return propagated_cid(); }

  Value* value() const { return value_; }

  virtual LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

  bool WasEliminated() const {
    return next() == NULL;
  }

 private:
  Value* value_;
  LocationSummary* locs_;

  DISALLOW_COPY_AND_ASSIGN(PushArgumentInstr);
};


class ReturnInstr : public TemplateInstruction<1> {
 public:
  ReturnInstr(intptr_t token_pos, Value* value)
      : deopt_id_(Isolate::Current()->GetNextDeoptId()),
        token_pos_(token_pos) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_INSTRUCTION(Return)

  virtual intptr_t ArgumentCount() const { return 0; }

  intptr_t deopt_id() const { return deopt_id_; }
  intptr_t token_pos() const { return token_pos_; }
  Value* value() const { return inputs_[0]; }

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

 private:
  const intptr_t deopt_id_;
  const intptr_t token_pos_;

  DISALLOW_COPY_AND_ASSIGN(ReturnInstr);
};


class ThrowInstr : public TemplateInstruction<0> {
 public:
  ThrowInstr(intptr_t token_pos, intptr_t try_index)
      : deopt_id_(Isolate::Current()->GetNextDeoptId()),
        token_pos_(token_pos),
        try_index_(try_index) { }

  DECLARE_INSTRUCTION(Throw)

  virtual intptr_t ArgumentCount() const { return 1; }

  intptr_t deopt_id() const { return deopt_id_; }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

 private:
  const intptr_t deopt_id_;
  const intptr_t token_pos_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(ThrowInstr);
};


class ReThrowInstr : public TemplateInstruction<0> {
 public:
  ReThrowInstr(intptr_t token_pos,
               intptr_t try_index)
      : deopt_id_(Isolate::Current()->GetNextDeoptId()),
        token_pos_(token_pos),
        try_index_(try_index) { }

  DECLARE_INSTRUCTION(ReThrow)

  virtual intptr_t ArgumentCount() const { return 2; }

  intptr_t deopt_id() const { return deopt_id_; }
  intptr_t token_pos() const { return token_pos_; }
  intptr_t try_index() const { return try_index_; }

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

 private:
  const intptr_t deopt_id_;
  const intptr_t token_pos_;
  const intptr_t try_index_;

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

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

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

 private:
  JoinEntryInstr* successor_;

  // Parallel move that will be used by linear scan register allocator to
  // connect live ranges at the end of the block and resolve phis.
  ParallelMoveInstr* parallel_move_;
};


class ControlInstruction : public Instruction {
 public:
  ControlInstruction() : true_successor_(NULL), false_successor_(NULL) { }

  virtual bool IsControl() const { return true; }

  TargetEntryInstr* true_successor() const { return true_successor_; }
  TargetEntryInstr* false_successor() const { return false_successor_; }

  TargetEntryInstr** true_successor_address() { return &true_successor_; }
  TargetEntryInstr** false_successor_address() { return &false_successor_; }

  virtual intptr_t SuccessorCount() const;
  virtual BlockEntryInstr* SuccessorAt(intptr_t index) const;

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count,
      intptr_t fixed_parameter_count);


  void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                             Condition true_condition);

 private:
  TargetEntryInstr* true_successor_;
  TargetEntryInstr* false_successor_;

  DISALLOW_COPY_AND_ASSIGN(ControlInstruction);
};


template<intptr_t N>
class TemplateControlInstruction: public ControlInstruction {
 public:
  TemplateControlInstruction<N>() : locs_(NULL) { }

  virtual intptr_t InputCount() const { return N; }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }
  virtual void SetInputAt(intptr_t i, Value* value) {
    ASSERT(value != NULL);
    inputs_[i] = value;
  }

  virtual LocationSummary* locs() {
    if (locs_ == NULL) {
      locs_ = MakeLocationSummary();
    }
    return locs_;
  }

  virtual LocationSummary* MakeLocationSummary() const = 0;

 protected:
  EmbeddedArray<Value*, N> inputs_;

 private:
  LocationSummary* locs_;
};


class BranchInstr : public TemplateControlInstruction<2> {
 public:
  BranchInstr(intptr_t token_pos,
              intptr_t try_index,
              Value* left,
              Value* right,
              Token::Kind kind)
      : deopt_id_(Isolate::kNoDeoptId),
        ic_data_(NULL),
        token_pos_(token_pos),
        try_index_(try_index),
        kind_(kind) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
    ASSERT(!Token::IsStrictEqualityOperator(kind));
    ASSERT(Token::IsEqualityOperator(kind) ||
           Token::IsRelationalOperator(kind) ||
           Token::IsTypeTestOperator(kind));
    Isolate* isolate = Isolate::Current();
    deopt_id_ = isolate->GetNextDeoptId();
    ic_data_ = isolate->GetICDataForDeoptId(deopt_id_);
  }

  DECLARE_INSTRUCTION(Branch)

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual intptr_t ArgumentCount() const { return 0; }

  Token::Kind kind() const { return kind_; }

  intptr_t deopt_id() const { return deopt_id_; }

  const ICData* ic_data() const { return ic_data_; }
  bool HasICData() const {
    return (ic_data() != NULL) && !ic_data()->IsNull();
  }

  intptr_t token_pos() const { return token_pos_;}
  intptr_t try_index() const { return try_index_; }

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return true; }

 private:
  intptr_t deopt_id_;
  const ICData* ic_data_;
  const intptr_t token_pos_;
  const intptr_t try_index_;
  const Token::Kind kind_;

  DISALLOW_COPY_AND_ASSIGN(BranchInstr);
};


class StrictCompareAndBranchInstr : public TemplateControlInstruction<2> {
 public:
  StrictCompareAndBranchInstr(Value* left, Value* right, Token::Kind kind)
        : kind_(kind) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
    ASSERT(Token::IsStrictEqualityOperator(kind));
  }

  DECLARE_INSTRUCTION(StrictCompareAndBranch)

  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual intptr_t ArgumentCount() const { return 0; }

  Token::Kind kind() const { return kind_; }

  virtual LocationSummary* MakeLocationSummary() const;

  virtual void EmitNativeCode(FlowGraphCompiler* compiler);

  virtual bool CanDeoptimize() const { return false; }

 private:
  const Token::Kind kind_;

  DISALLOW_COPY_AND_ASSIGN(StrictCompareAndBranchInstr);
};


#undef DECLARE_INSTRUCTION


class Environment : public ZoneAllocated {
 public:
  // Construct an environment by constructing uses from an array of definitions.
  Environment(const GrowableArray<Definition*>& definitions,
              intptr_t fixed_parameter_count);

  void set_locations(Location* locations) {
    ASSERT(locations_ == NULL);
    locations_ = locations;
  }

  const GrowableArray<Value*>& values() const {
    return values_;
  }

  GrowableArray<Value*>* values_ptr() {
    return &values_;
  }

  Location LocationAt(intptr_t ix) const {
    ASSERT((ix >= 0) && (ix < values_.length()));
    return locations_[ix];
  }

  Location* LocationSlotAt(intptr_t ix) const {
    ASSERT((ix >= 0) && (ix < values_.length()));
    return &locations_[ix];
  }

  intptr_t fixed_parameter_count() const {
    return fixed_parameter_count_;
  }

  void CopyTo(Instruction* instr) const;

  void PrintTo(BufferFormatter* f) const;

 private:
  Environment(intptr_t length, intptr_t fixed_parameter_count)
      : values_(length),
        locations_(NULL),
        fixed_parameter_count_(fixed_parameter_count) { }

  GrowableArray<Value*> values_;
  Location* locations_;
  const intptr_t fixed_parameter_count_;

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

  // Visit functions for instruction and computation classes, with empty
  // default implementations.
#define DECLARE_VISIT_COMPUTATION(ShortName, ClassName)                        \
  virtual void Visit##ShortName(ClassName* comp, BindInstr* instr) { }

#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr) { }

  FOR_EACH_COMPUTATION(DECLARE_VISIT_COMPUTATION)
  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_COMPUTATION
#undef DECLARE_VISIT_INSTRUCTION

 protected:
  const GrowableArray<BlockEntryInstr*>& block_order_;
  ForwardInstructionIterator* current_iterator_;

 private:
  DISALLOW_COPY_AND_ASSIGN(FlowGraphVisitor);
};


}  // namespace dart

#endif  // VM_INTERMEDIATE_LANGUAGE_H_
