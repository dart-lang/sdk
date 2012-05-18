// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_INTERMEDIATE_LANGUAGE_H_
#define VM_INTERMEDIATE_LANGUAGE_H_

#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/growable_array.h"
#include "vm/handles_impl.h"
#include "vm/object.h"

namespace dart {

class BitVector;
class FlowGraphVisitor;
class LocalVariable;

// M is a two argument macro.  It is applied to each concrete value's
// typename and classname.
#define FOR_EACH_VALUE(M)                                                      \
  M(Use, UseVal)                                                               \
  M(Constant, ConstantVal)                                                     \


// M is a two argument macro.  It is applied to each concrete instruction's
// (including the values) typename and classname.
#define FOR_EACH_COMPUTATION(M)                                                \
  FOR_EACH_VALUE(M)                                                            \
  M(AssertAssignable, AssertAssignableComp)                                    \
  M(AssertBoolean, AssertBooleanComp)                                          \
  M(CurrentContext, CurrentContextComp)                                        \
  M(StoreContext, StoreContextComp)                                            \
  M(ClosureCall, ClosureCallComp)                                              \
  M(InstanceCall, InstanceCallComp)                                            \
  M(StaticCall, StaticCallComp)                                                \
  M(LoadLocal, LoadLocalComp)                                                  \
  M(StoreLocal, StoreLocalComp)                                                \
  M(StrictCompare, StrictCompareComp)                                          \
  M(EqualityCompare, EqualityCompareComp)                                      \
  M(NativeCall, NativeCallComp)                                                \
  M(StoreIndexed, StoreIndexedComp)                                            \
  M(InstanceSetter, InstanceSetterComp)                                        \
  M(StaticSetter, StaticSetterComp)                                            \
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
  M(NativeLoadField, NativeLoadFieldComp)                                      \
  M(NativeStoreField, NativeStoreFieldComp)                                    \
  M(InstantiateTypeArguments, InstantiateTypeArgumentsComp)                    \
  M(ExtractConstructorTypeArguments, ExtractConstructorTypeArgumentsComp)      \
  M(ExtractConstructorInstantiator, ExtractConstructorInstantiatorComp)        \
  M(AllocateContext, AllocateContextComp)                                      \
  M(ChainContext, ChainContextComp)                                            \
  M(CloneContext, CloneContextComp)                                            \
  M(CatchEntry, CatchEntryComp)                                                \


#define FORWARD_DECLARATION(ShortName, ClassName) class ClassName;
FOR_EACH_COMPUTATION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

// Forward declarations.
class BufferFormatter;
class Value;


class Computation : public ZoneAllocated {
 public:
  static const int kNoCid = -1;

  Computation() : cid_(-1), ic_data_(NULL) {
    Isolate* isolate = Isolate::Current();
    cid_ = GetNextCid(isolate);
    ic_data_ = GetICDataForCid(cid_, isolate);
  }

  // Unique computation/instruction id, used for deoptimization.
  intptr_t cid() const { return cid_; }

  const ICData* ic_data() const { return ic_data_; }

  // Visiting support.
  virtual void Accept(FlowGraphVisitor* visitor) = 0;

  virtual intptr_t InputCount() const = 0;
  virtual Value* InputAt(intptr_t i) const = 0;

  // Static type of the computation.
  virtual RawAbstractType* StaticType() const = 0;

  // Mutate assigned_vars to add the local variable index for all
  // frame-allocated locals assigned to by the computation.
  virtual void RecordAssignedVars(BitVector* assigned_vars);

  virtual const char* DebugName() const = 0;

  // Printing support. These functions are sometimes overridden for custom
  // formatting. Otherwise, it prints in the format "opcode(op1, op2, op3)".
  virtual void PrintTo(BufferFormatter* f) const;
  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  friend class Instruction;
  static intptr_t GetNextCid(Isolate* isolate) {
    intptr_t tmp = isolate->computation_id();
    isolate->set_computation_id(tmp + 1);
    return tmp;
  }
  static ICData* GetICDataForCid(intptr_t cid, Isolate* isolate) {
    if (isolate->ic_data_array() == Array::null()) {
      return NULL;
    } else {
      const Array& array_handle = Array::Handle(isolate->ic_data_array());
      ICData& ic_data_handle = ICData::ZoneHandle();
      if (cid < array_handle.Length()) {
        ic_data_handle ^= array_handle.At(cid);
      }
      return &ic_data_handle;
    }
  }

  intptr_t cid_;
  ICData* ic_data_;

  DISALLOW_COPY_AND_ASSIGN(Computation);
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

 protected:
  EmbeddedArray<Value*, N> inputs_;
};


class Value : public TemplateComputation<0> {
 public:
  Value() { }

#define DEFINE_TESTERS(ShortName, ClassName)                                   \
  virtual ClassName* As##ShortName() { return NULL; }                          \
  bool Is##ShortName() { return As##ShortName() != NULL; }

  FOR_EACH_VALUE(DEFINE_TESTERS)
#undef DEFINE_TESTERS

 private:
  DISALLOW_COPY_AND_ASSIGN(Value);
};


// Functions defined in all concrete computation classes.
#define DECLARE_COMPUTATION(ShortName)                                         \
  virtual void Accept(FlowGraphVisitor* visitor);                              \
  virtual const char* DebugName() const { return #ShortName; }                 \
  virtual RawAbstractType* StaticType() const;

// Functions defined in all concrete value classes.
#define DECLARE_VALUE(ShortName)                                               \
  DECLARE_COMPUTATION(ShortName)                                               \
  virtual ShortName##Val* As##ShortName() { return this; }                     \
  virtual void PrintTo(BufferFormatter* f) const;


// Definitions and uses are mutually recursive.
class Definition;

class UseVal : public Value {
 public:
  explicit UseVal(Definition* definition) : definition_(definition) { }

  DECLARE_VALUE(Use)

  Definition* definition() const { return definition_; }

 private:
  Definition* const definition_;

  DISALLOW_COPY_AND_ASSIGN(UseVal);
};


class ConstantVal: public Value {
 public:
  explicit ConstantVal(const Object& value) : value_(value) {
    ASSERT(value.IsZoneHandle());
  }

  DECLARE_VALUE(Constant)

  const Object& value() const { return value_; }

 private:
  const Object& value_;

  DISALLOW_COPY_AND_ASSIGN(ConstantVal);
};

#undef DECLARE_VALUE


class AssertAssignableComp : public Computation {
 public:
  AssertAssignableComp(intptr_t token_index,
                       intptr_t try_index,
                       Value* value,
                       Value* instantiator_type_arguments,  // Can be NULL.
                       const AbstractType& dst_type,
                       const String& dst_name)
      : token_index_(token_index),
        try_index_(try_index),
        value_(value),
        instantiator_type_arguments_(instantiator_type_arguments),
        dst_type_(dst_type),
        dst_name_(dst_name) {
    ASSERT(value_ != NULL);
    ASSERT(!dst_type.IsNull());
    ASSERT(!dst_name.IsNull());
  }

  DECLARE_COMPUTATION(AssertAssignable)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* value() const { return value_; }
  Value* instantiator_type_arguments() const {
    return instantiator_type_arguments_;
  }
  const AbstractType& dst_type() const { return dst_type_; }
  const String& dst_name() const { return dst_name_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const {
    if (i == 0) return value();
    if (i == 1) return instantiator_type_arguments();
    return NULL;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* value_;
  Value* instantiator_type_arguments_;
  const AbstractType& dst_type_;
  const String& dst_name_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableComp);
};


class AssertBooleanComp : public TemplateComputation<1> {
 public:
  AssertBooleanComp(intptr_t token_index,
                    intptr_t try_index,
                    Value* value)
      : token_index_(token_index),
        try_index_(try_index) {
    ASSERT(value != NULL);
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(AssertBoolean)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* value() const { return inputs_[0]; }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(AssertBooleanComp);
};


// Denotes the current context, normally held in a register.  This is
// a computation, not a value, because it's mutable.
class CurrentContextComp : public TemplateComputation<0> {
 public:
  CurrentContextComp() { }

  DECLARE_COMPUTATION(CurrentContext)

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

 private:
  DISALLOW_COPY_AND_ASSIGN(StoreContextComp);
};


class ClosureCallComp : public Computation {
 public:
  ClosureCallComp(ClosureCallNode* node,
                  intptr_t try_index,
                  Value* context,
                  ZoneGrowableArray<Value*>* arguments)
      : ast_node_(*node),
        try_index_(try_index),
        context_(context),
        arguments_(arguments) {
    ASSERT(context->IsUse());
  }

  DECLARE_COMPUTATION(ClosureCall)

  const Array& argument_names() const { return ast_node_.arguments()->names(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }

  Value* context() const { return context_; }
  intptr_t ArgumentCount() const { return arguments_->length(); }
  Value* ArgumentAt(intptr_t index) const { return (*arguments_)[index]; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const {
    return i == 0 ? context() : ArgumentAt(i - 1);
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const ClosureCallNode& ast_node_;
  const intptr_t try_index_;
  Value* context_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(ClosureCallComp);
};


class InstanceCallComp : public Computation {
 public:
  InstanceCallComp(intptr_t token_index,
                   intptr_t try_index,
                   const String& function_name,
                   ZoneGrowableArray<Value*>* arguments,
                   const Array& argument_names,
                   intptr_t checked_argument_count)
      : token_index_(token_index),
        try_index_(try_index),
        function_name_(function_name),
        arguments_(arguments),
        argument_names_(argument_names),
        checked_argument_count_(checked_argument_count) {
    ASSERT(function_name.IsZoneHandle());
    ASSERT(!arguments->is_empty());
    ASSERT(argument_names.IsZoneHandle());
  }

  DECLARE_COMPUTATION(InstanceCall)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const String& function_name() const { return function_name_; }
  intptr_t ArgumentCount() const { return arguments_->length(); }
  Value* ArgumentAt(intptr_t index) const { return (*arguments_)[index]; }
  const Array& argument_names() const { return argument_names_; }
  intptr_t checked_argument_count() const { return checked_argument_count_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const { return ArgumentAt(i); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const String& function_name_;
  ZoneGrowableArray<Value*>* const arguments_;
  const Array& argument_names_;
  const intptr_t checked_argument_count_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallComp);
};


class StrictCompareComp : public TemplateComputation<2> {
 public:
  StrictCompareComp(Token::Kind kind, Value* left, Value* right)
      : kind_(kind) {
    ASSERT((kind_ == Token::kEQ_STRICT) || (kind_ == Token::kNE_STRICT));
    inputs_[0] = left;
    inputs_[1] = right;
  }

  DECLARE_COMPUTATION(StrictCompare)

  Token::Kind kind() const { return kind_; }
  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const Token::Kind kind_;

  DISALLOW_COPY_AND_ASSIGN(StrictCompareComp);
};


class EqualityCompareComp : public TemplateComputation<2> {
 public:
  EqualityCompareComp(intptr_t token_index,
                      intptr_t try_index,
                      Value* left,
                      Value* right)
    : token_index_(token_index),
      try_index_(try_index) {
    ASSERT(left != NULL);
    ASSERT(right != NULL);
    inputs_[0] = left;
    inputs_[1] = right;
  }

  DECLARE_COMPUTATION(EqualityCompareComp)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* left() const { return inputs_[0]; }
  Value* right() const { return inputs_[1]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(EqualityCompareComp);
};


class StaticCallComp : public Computation {
 public:
  StaticCallComp(intptr_t token_index,
                 intptr_t try_index,
                 const Function& function,
                 const Array& argument_names,
                 ZoneGrowableArray<Value*>* arguments)
      : token_index_(token_index),
        try_index_(try_index),
        function_(function),
        argument_names_(argument_names),
        arguments_(arguments) {
    ASSERT(function.IsZoneHandle());
    ASSERT(argument_names.IsZoneHandle());
  }

  DECLARE_COMPUTATION(StaticCall)

  // Accessors forwarded to the AST node.
  const Function& function() const { return function_; }
  const Array& argument_names() const { return argument_names_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }

  intptr_t ArgumentCount() const { return arguments_->length(); }
  Value* ArgumentAt(intptr_t index) const { return (*arguments_)[index]; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const { return ArgumentAt(i); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const Function& function_;
  const Array& argument_names_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallComp);
};


class LoadLocalComp : public TemplateComputation<0> {
 public:
  LoadLocalComp(const LocalVariable& local, intptr_t context_level)
      : local_(local), context_level_(context_level) { }

  DECLARE_COMPUTATION(LoadLocal)

  const LocalVariable& local() const { return local_; }
  intptr_t context_level() const { return context_level_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

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
      : local_(local), context_level_(context_level) {
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(StoreLocal)

  const LocalVariable& local() const { return local_; }
  Value* value() const { return inputs_[0]; }
  intptr_t context_level() const { return context_level_; }

  virtual void RecordAssignedVars(BitVector* assigned_vars);

  virtual void PrintOperandsTo(BufferFormatter* f) const;

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

  intptr_t token_index() const { return ast_node_.token_index(); }
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

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const NativeBodyNode& ast_node_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallComp);
};


class LoadInstanceFieldComp : public TemplateComputation<1> {
 public:
  LoadInstanceFieldComp(LoadInstanceFieldNode* ast_node, Value* instance)
      : ast_node_(*ast_node) {
    ASSERT(instance != NULL);
    inputs_[0] = instance;
  }

  DECLARE_COMPUTATION(LoadInstanceField)

  const Field& field() const { return ast_node_.field(); }

  Value* instance() const { return inputs_[0]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const LoadInstanceFieldNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(LoadInstanceFieldComp);
};


class StoreInstanceFieldComp : public TemplateComputation<2> {
 public:
  StoreInstanceFieldComp(StoreInstanceFieldNode* ast_node,
                         Value* instance,
                         Value* value)
      : ast_node_(*ast_node) {
    ASSERT(instance != NULL);
    ASSERT(value != NULL);
    inputs_[0] = instance;
    inputs_[1] = value;
  }

  DECLARE_COMPUTATION(StoreInstanceField)

  intptr_t token_index() const { return ast_node_.token_index(); }
  const Field& field() const { return ast_node_.field(); }

  Value* instance() const { return inputs_[0]; }
  Value* value() const { return inputs_[1]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const StoreInstanceFieldNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(StoreInstanceFieldComp);
};


class LoadStaticFieldComp : public TemplateComputation<0> {
 public:
  explicit LoadStaticFieldComp(const Field& field) : field_(field) {}

  DECLARE_COMPUTATION(LoadStaticField);

  const Field& field() const { return field_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

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

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(StoreStaticFieldComp);
};


// Not simply an InstanceCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class StoreIndexedComp : public TemplateComputation<3> {
 public:
  StoreIndexedComp(intptr_t token_index,
                   intptr_t try_index,
                   Value* array,
                   Value* index,
                   Value* value)
      : token_index_(token_index),
        try_index_(try_index) {
    inputs_[0] = array;
    inputs_[1] = index;
    inputs_[2] = value;
  }

  DECLARE_COMPUTATION(StoreIndexed)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* array() const { return inputs_[0]; }
  Value* index() const { return inputs_[1]; }
  Value* value() const { return inputs_[2]; }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(StoreIndexedComp);
};


// Not simply an InstanceCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class InstanceSetterComp : public TemplateComputation<2> {
 public:
  InstanceSetterComp(intptr_t token_index,
                     intptr_t try_index,
                     const String& field_name,
                     Value* receiver,
                     Value* value)
      : token_index_(token_index),
        try_index_(try_index),
        field_name_(field_name) {
    inputs_[0] = receiver;
    inputs_[1] = value;
  }

  DECLARE_COMPUTATION(InstanceSetter)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const String& field_name() const { return field_name_; }
  Value* receiver() const { return inputs_[0]; }
  Value* value() const { return inputs_[1]; }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const String& field_name_;

  DISALLOW_COPY_AND_ASSIGN(InstanceSetterComp);
};


// Not simply a StaticCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class StaticSetterComp : public TemplateComputation<1> {
 public:
  StaticSetterComp(intptr_t token_index,
                   intptr_t try_index,
                   const Function& setter_function,
                   Value* value)
      : token_index_(token_index),
        try_index_(try_index),
        setter_function_(setter_function) {
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(StaticSetter)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const Function& setter_function() const { return setter_function_; }
  Value* value() const { return inputs_[0]; }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const Function& setter_function_;

  DISALLOW_COPY_AND_ASSIGN(StaticSetterComp);
};


// Note overrideable, built-in: value? false : true.
class BooleanNegateComp : public TemplateComputation<1> {
 public:
  explicit BooleanNegateComp(Value* value) {
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(BooleanNegate)

  Value* value() const { return inputs_[0]; }

 private:
  DISALLOW_COPY_AND_ASSIGN(BooleanNegateComp);
};


class InstanceOfComp : public Computation {
 public:
  InstanceOfComp(intptr_t token_index,
                 intptr_t try_index,
                 Value* value,
                 Value* type_arguments,  // Can be NULL.
                 const AbstractType& type,
                 bool negate_result)
      : token_index_(token_index),
        try_index_(try_index),
        value_(value),
        type_arguments_(type_arguments),
        type_(type),
        negate_result_(negate_result) {
    ASSERT(value_ != NULL);
    ASSERT(!type.IsNull());
  }

  DECLARE_COMPUTATION(InstanceOf)

  Value* value() const { return value_; }
  Value* type_arguments() const { return type_arguments_; }
  bool negate_result() const { return negate_result_; }
  const AbstractType& type() const { return type_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const {
    if (i == 0) return value();
    if (i == 1) return type_arguments();
    return NULL;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* value_;
  Value* type_arguments_;
  const AbstractType& type_;
  const bool negate_result_;

  DISALLOW_COPY_AND_ASSIGN(InstanceOfComp);
};


class AllocateObjectComp : public Computation {
 public:
  AllocateObjectComp(ConstructorCallNode* node,
                     intptr_t try_index,
                     ZoneGrowableArray<Value*>* arguments)
      : ast_node_(*node), try_index_(try_index), arguments_(arguments) {
    // Either no arguments or one type-argument and one instantiator.
    ASSERT(arguments->is_empty() || (arguments->length() == 2));
  }

  DECLARE_COMPUTATION(AllocateObject)

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }
  const ZoneGrowableArray<Value*>& arguments() const { return *arguments_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const { return arguments()[i]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<Value*>* const arguments_;
  DISALLOW_COPY_AND_ASSIGN(AllocateObjectComp);
};


class AllocateObjectWithBoundsCheckComp : public Computation {
 public:
  AllocateObjectWithBoundsCheckComp(ConstructorCallNode* node,
                                    intptr_t try_index,
                                    ZoneGrowableArray<Value*>* arguments)
      : ast_node_(*node), try_index_(try_index), arguments_(arguments) {
    // One type-argument and one instantiator.
    ASSERT(arguments->length() == 2);
  }

  DECLARE_COMPUTATION(AllocateObjectWithBoundsCheck)

  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }
  const ZoneGrowableArray<Value*>& arguments() const { return *arguments_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const { return arguments()[i]; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<Value*>* const arguments_;
  DISALLOW_COPY_AND_ASSIGN(AllocateObjectWithBoundsCheckComp);
};


class CreateArrayComp : public Computation {
 public:
  CreateArrayComp(intptr_t token_index,
                  intptr_t try_index,
                  ZoneGrowableArray<Value*>* elements,
                  Value* element_type)
      : token_index_(token_index),
        try_index_(try_index),
        elements_(elements),
        element_type_(element_type) {
#if defined(DEBUG)
    for (int i = 0; i < ElementCount(); ++i) {
      ASSERT(ElementAt(i) != NULL);
    }
    ASSERT(element_type_ != NULL);
#endif
  }

  DECLARE_COMPUTATION(CreateArray)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  intptr_t ElementCount() const { return elements_->length(); }
  Value* ElementAt(intptr_t i) const { return (*elements_)[i]; }
  Value* element_type() const { return element_type_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const { return ElementAt(i); }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  ZoneGrowableArray<Value*>* const elements_;
  Value* element_type_;

  DISALLOW_COPY_AND_ASSIGN(CreateArrayComp);
};


class CreateClosureComp : public Computation {
 public:
  // 'type_arguments' is null if function() does not require type arguments.
  CreateClosureComp(ClosureNode* node,
                    intptr_t try_index,
                    Value* type_arguments)
      : ast_node_(*node),
        try_index_(try_index),
        type_arguments_(type_arguments) {}

  DECLARE_COMPUTATION(CreateClosure)

  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }
  const Function& function() const { return ast_node_.function(); }
  Value* type_arguments() const { return type_arguments_; }

  virtual intptr_t InputCount() const;
  virtual Value* InputAt(intptr_t i) const {
    return i == 0 ? type_arguments() : NULL;
  }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const ClosureNode& ast_node_;
  const intptr_t try_index_;
  Value* type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(CreateClosureComp);
};


class NativeLoadFieldComp : public TemplateComputation<1> {
 public:
  NativeLoadFieldComp(Value* value,
                      intptr_t offset_in_bytes,
                      const AbstractType& type)
      : offset_in_bytes_(offset_in_bytes), type_(type) {
    ASSERT(value != NULL);
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    inputs_[0] = value;
  }

  DECLARE_COMPUTATION(NativeLoadField)

  Value* value() const { return inputs_[0]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(NativeLoadFieldComp);
};


class NativeStoreFieldComp : public TemplateComputation<2> {
 public:
  NativeStoreFieldComp(Value* dest,
                       intptr_t offset_in_bytes,
                       Value* value,
                       const AbstractType& type)
      : offset_in_bytes_(offset_in_bytes), type_(type) {
    ASSERT(value != NULL);
    ASSERT(type.IsZoneHandle());  // May be null if field is not an instance.
    inputs_[0] = dest;
    inputs_[1] = value;
  }

  DECLARE_COMPUTATION(NativeStoreField)

  Value* dest() const { return inputs_[0]; }
  Value* value() const { return inputs_[1]; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }
  const AbstractType& type() const { return type_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t offset_in_bytes_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(NativeStoreFieldComp);
};


class InstantiateTypeArgumentsComp : public TemplateComputation<1> {
 public:
  InstantiateTypeArgumentsComp(intptr_t token_index,
                               intptr_t try_index,
                               const AbstractTypeArguments& type_arguments,
                               Value* instantiator)
      : token_index_(token_index),
        try_index_(try_index),
        type_arguments_(type_arguments) {
    ASSERT(instantiator != NULL);
    inputs_[0] = instantiator;
  }

  DECLARE_COMPUTATION(InstantiateTypeArguments)

  Value* instantiator() const { return inputs_[0]; }
  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const AbstractTypeArguments& type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(InstantiateTypeArgumentsComp);
};


class ExtractConstructorTypeArgumentsComp : public TemplateComputation<1> {
 public:
  ExtractConstructorTypeArgumentsComp(
      intptr_t token_index,
      intptr_t try_index,
      const AbstractTypeArguments& type_arguments,
      Value* instantiator)
      : token_index_(token_index),
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
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
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
  intptr_t token_index() const { return ast_node_.token_index(); }

 private:
  const ConstructorCallNode& ast_node_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorInstantiatorComp);
};


class AllocateContextComp : public TemplateComputation<0> {
 public:
  AllocateContextComp(intptr_t token_index,
                      intptr_t try_index,
                      intptr_t num_context_variables)
      : token_index_(token_index),
        try_index_(try_index),
        num_context_variables_(num_context_variables) {}

  DECLARE_COMPUTATION(AllocateContext);

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  intptr_t num_context_variables() const { return num_context_variables_; }

  virtual void PrintOperandsTo(BufferFormatter* f) const;

 private:
  const intptr_t token_index_;
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

 private:
  DISALLOW_COPY_AND_ASSIGN(ChainContextComp);
};


class CloneContextComp : public TemplateComputation<1> {
 public:
  CloneContextComp(intptr_t token_index,
                   intptr_t try_index,
                   Value* context_value)
      : token_index_(token_index),
        try_index_(try_index) {
    ASSERT(context_value != NULL);
    inputs_[0] = context_value;
  }

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* context_value() const { return inputs_[0]; }

  DECLARE_COMPUTATION(CloneContext)

 private:
  const intptr_t token_index_;
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

 private:
  const LocalVariable& exception_var_;
  const LocalVariable& stacktrace_var_;

  DISALLOW_COPY_AND_ASSIGN(CatchEntryComp);
};


#undef DECLARE_COMPUTATION


// Instructions.
//
// <Instruction> ::= JoinEntry <Instruction>
//                 | TargetEntry <Instruction>
//                 | Do <Computation> <Instruction>
//                 | Return <Value>
//                 | Branch <Value> <Instruction> <Instruction>
// <Definition>  ::= Bind <int> <Computation> <Instruction>

// M is a single argument macro.  It is applied to each concrete instruction
// type name.  The concrete instruction classes are the name with Instr
// concatenated.
#define FOR_EACH_INSTRUCTION(M)                                                \
  M(GraphEntry)                                                                \
  M(JoinEntry)                                                                 \
  M(TargetEntry)                                                               \
  M(Do)                                                                        \
  M(Bind)                                                                      \
  M(Return)                                                                    \
  M(Throw)                                                                     \
  M(ReThrow)                                                                   \
  M(Branch)                                                                    \


// Forward declarations for Instruction classes.
class BlockEntryInstr;
class FlowGraphBuilder;

#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION


// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                                              \
  virtual Instruction* Accept(FlowGraphVisitor* visitor);                      \
  virtual bool Is##type() const { return true; }                               \
  virtual type##Instr* As##type() { return this; }                             \
  virtual intptr_t InputCount() const;                                         \
  virtual const char* DebugName() const { return #type; }                      \
  virtual void PrintTo(BufferFormatter* f) const;


class Instruction : public ZoneAllocated {
 public:
  Instruction() : cid_(-1), ic_data_(NULL) {
    Isolate* isolate = Isolate::Current();
    cid_ = Computation::GetNextCid(isolate);
    ic_data_ = Computation::GetICDataForCid(cid_, isolate);
  }

  // Unique computation/instruction id, used for deoptimization, e.g. for
  // ReturnInstr, ThrowInstr and ReThrowInstr.
  intptr_t cid() const { return cid_; }

  const ICData* ic_data() const { return ic_data_; }

  virtual bool IsBlockEntry() const { return false; }
  BlockEntryInstr* AsBlockEntry() {
    return IsBlockEntry() ? reinterpret_cast<BlockEntryInstr*>(this) : NULL;
  }
  virtual bool IsDefinition() const { return false; }
  Definition* AsDefinition() {
    return IsDefinition() ? reinterpret_cast<Definition*>(this) : NULL;
  }

  virtual intptr_t InputCount() const = 0;

  // Visiting support.
  virtual Instruction* Accept(FlowGraphVisitor* visitor) = 0;

  virtual Instruction* StraightLineSuccessor() const = 0;
  virtual void SetSuccessor(Instruction* instr) = 0;

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
      intptr_t variable_count) {
    // Never called for instructions except block entries and branches.
    UNREACHABLE();
  }

  // Mutate assigned_vars to add the local variable index for all
  // frame-allocated locals assigned to by the instruction.
  virtual void RecordAssignedVars(BitVector* assigned_vars);

  // Printing support.
  virtual void PrintTo(BufferFormatter* f) const = 0;

#define INSTRUCTION_TYPE_CHECK(type)                                           \
  virtual bool Is##type() const { return false; }                              \
  virtual type##Instr* As##type() { return NULL; }
FOR_EACH_INSTRUCTION(INSTRUCTION_TYPE_CHECK)
#undef INSTRUCTION_TYPE_CHECK

  // Static type of the instruction.
  virtual RawAbstractType* StaticType() const {
    UNREACHABLE();
    return AbstractType::null();
  }

 private:
  intptr_t cid_;
  ICData* ic_data_;
  DISALLOW_COPY_AND_ASSIGN(Instruction);
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

  intptr_t preorder_number() const { return preorder_number_; }
  void set_preorder_number(intptr_t number) { preorder_number_ = number; }

  intptr_t postorder_number() const { return postorder_number_; }
  void set_postorder_number(intptr_t number) { postorder_number_ = number; }

  intptr_t block_id() const { return block_id_; }
  void set_block_id(intptr_t value) { block_id_ = value; }

  BlockEntryInstr* dominator() const { return dominator_; }
  void set_dominator(BlockEntryInstr* instr) { dominator_ = instr; }

  Instruction* last_instruction() const { return last_instruction_; }
  void set_last_instruction(Instruction* instr) { last_instruction_ = instr; }

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count);

 protected:
  BlockEntryInstr()
      : preorder_number_(-1),
        postorder_number_(-1),
        block_id_(-1),
        dominator_(NULL),
        last_instruction_(NULL) { }

 private:
  intptr_t preorder_number_;
  intptr_t postorder_number_;
  intptr_t block_id_;
  BlockEntryInstr* dominator_;  // Immediate dominator, NULL for graph entry.
  Instruction* last_instruction_;

  DISALLOW_COPY_AND_ASSIGN(BlockEntryInstr);
};


class GraphEntryInstr : public BlockEntryInstr {
 public:
  explicit GraphEntryInstr(TargetEntryInstr* normal_entry)
      : BlockEntryInstr(), normal_entry_(normal_entry), catch_entries_() { }

  DECLARE_INSTRUCTION(GraphEntry)

  virtual intptr_t PredecessorCount() const { return 0; }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    UNREACHABLE();
    return NULL;
  }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) { UNREACHABLE(); }

  virtual Instruction* StraightLineSuccessor() const { return NULL; }
  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count);

  void AddCatchEntry(TargetEntryInstr* entry) { catch_entries_.Add(entry); }

 private:
  TargetEntryInstr* normal_entry_;
  GrowableArray<TargetEntryInstr*> catch_entries_;

  DISALLOW_COPY_AND_ASSIGN(GraphEntryInstr);
};


class JoinEntryInstr : public BlockEntryInstr {
 public:
  JoinEntryInstr()
      : BlockEntryInstr(),
        predecessors_(2),  // Two is the assumed to be the common case.
        successor_(NULL) { }

  DECLARE_INSTRUCTION(JoinEntry)

  virtual intptr_t PredecessorCount() const { return predecessors_.length(); }
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const {
    return predecessors_[index];
  }
  virtual void AddPredecessor(BlockEntryInstr* predecessor) {
    predecessors_.Add(predecessor);
  }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

 private:
  ZoneGrowableArray<BlockEntryInstr*> predecessors_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(JoinEntryInstr);
};


class TargetEntryInstr : public BlockEntryInstr {
 public:
  TargetEntryInstr()
      : BlockEntryInstr(),
        predecessor_(NULL),
        successor_(NULL),
        try_index_(CatchClauseNode::kInvalidTryIndex) { }

  // Used for exception catch entries.
  explicit TargetEntryInstr(intptr_t try_index)
      : BlockEntryInstr(),
        predecessor_(NULL),
        successor_(NULL),
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

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  bool HasTryIndex() const {
    return try_index_ != CatchClauseNode::kInvalidTryIndex;
  }

  intptr_t try_index() const {
    ASSERT(HasTryIndex());
    return try_index_;
  }

 private:
  BlockEntryInstr* predecessor_;
  Instruction* successor_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(TargetEntryInstr);
};


class DoInstr : public Instruction {
 public:
  explicit DoInstr(Computation* comp)
      : computation_(comp), successor_(NULL) { }

  DECLARE_INSTRUCTION(Do)

  Computation* computation() const { return computation_; }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void RecordAssignedVars(BitVector* assigned_vars);

 private:
  Computation* computation_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(DoInstr);
};


class Definition : public Instruction {
 public:
  Definition() : temp_index_(-1) { }

  virtual bool IsDefinition() const { return true; }

  intptr_t temp_index() const { return temp_index_; }
  void set_temp_index(intptr_t index) { temp_index_ = index; }

 private:
  intptr_t temp_index_;

  DISALLOW_COPY_AND_ASSIGN(Definition);
};


class BindInstr : public Definition {
 public:
  explicit BindInstr(Computation* computation)
      : Definition(), computation_(computation), successor_(NULL) { }

  DECLARE_INSTRUCTION(Bind)

  Computation* computation() const { return computation_; }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  // Static type of the underlying computation.
  virtual RawAbstractType* StaticType() const {
    return computation()->StaticType();
  }

  virtual void RecordAssignedVars(BitVector* assigned_vars);

 private:
  Computation* computation_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(BindInstr);
};


class ReturnInstr : public Instruction {
 public:
  ReturnInstr(intptr_t token_index, Value* value)
      : token_index_(token_index), value_(value) {
    ASSERT(value_ != NULL);
  }

  DECLARE_INSTRUCTION(Return)

  Value* value() const { return value_; }
  intptr_t token_index() const { return token_index_; }

  virtual Instruction* StraightLineSuccessor() const { return NULL; }
  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

 private:
  const intptr_t token_index_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(ReturnInstr);
};


class ThrowInstr : public Instruction {
 public:
  ThrowInstr(intptr_t token_index,
             intptr_t try_index,
             Value* exception)
      : token_index_(token_index),
        try_index_(try_index),
        exception_(exception),
        successor_(NULL) {
    ASSERT(exception_ != NULL);
  }

  DECLARE_INSTRUCTION(Throw)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* exception() const { return exception_; }

  // Parser can generate a throw within an expression tree.  We never
  // add successor instructions to the graph.
  virtual Instruction* StraightLineSuccessor() const { return NULL; }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
  }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* exception_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(ThrowInstr);
};


class ReThrowInstr : public Instruction {
 public:
  ReThrowInstr(intptr_t token_index,
               intptr_t try_index,
               Value* exception,
               Value* stack_trace)
      : token_index_(token_index),
        try_index_(try_index),
        exception_(exception),
        stack_trace_(stack_trace),
        successor_(NULL) {
    ASSERT(exception_ != NULL);
    ASSERT(stack_trace_ != NULL);
  }

  DECLARE_INSTRUCTION(ReThrow)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* exception() const { return exception_; }
  Value* stack_trace() const { return stack_trace_; }

  // Parser can generate a rethrow within an expression tree.  We
  // never add successor instructions to the graph.
  virtual Instruction* StraightLineSuccessor() const {
    return NULL;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
  }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* exception_;
  Value* stack_trace_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(ReThrowInstr);
};


class BranchInstr : public Instruction {
 public:
  explicit BranchInstr(Value* value)
      : value_(value),
        true_successor_(NULL),
        false_successor_(NULL) { }

  DECLARE_INSTRUCTION(Branch)

  Value* value() const { return value_; }
  TargetEntryInstr* true_successor() const { return true_successor_; }
  TargetEntryInstr* false_successor() const { return false_successor_; }

  TargetEntryInstr** true_successor_address() { return &true_successor_; }
  TargetEntryInstr** false_successor_address() { return &false_successor_; }

  virtual Instruction* StraightLineSuccessor() const { return NULL; }
  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent,
      GrowableArray<BitVector*>* assigned_vars,
      intptr_t variable_count);

 private:
  Value* value_;
  TargetEntryInstr* true_successor_;
  TargetEntryInstr* false_successor_;

  DISALLOW_COPY_AND_ASSIGN(BranchInstr);
};

#undef DECLARE_INSTRUCTION


// Visitor base class to visit each instruction and computation in a flow
// graph as defined by a reversed list of basic blocks.
class FlowGraphVisitor : public ValueObject {
 public:
  explicit FlowGraphVisitor(const GrowableArray<BlockEntryInstr*>& block_order)
      : block_order_(block_order) { }
  virtual ~FlowGraphVisitor() { }

  // Visit each block in the block order, and for each block its
  // instructions in order from the block entry to exit.
  virtual void VisitBlocks();

  // Visit functions for instruction and computation classes, with empty
  // default implementations.
#define DECLARE_VISIT_COMPUTATION(ShortName, ClassName)                        \
  virtual void Visit##ShortName(ClassName* comp) { }

#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr) { }

  FOR_EACH_COMPUTATION(DECLARE_VISIT_COMPUTATION)
  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_COMPUTATION
#undef DECLARE_VISIT_INSTRUCTION

 protected:
  // Map a block number in a forward iteration into the block number in the
  // corresponding reverse iteration.  Used to obtain an index into
  // block_order for reverse iterations.
  intptr_t reverse_index(intptr_t index) {
    return block_order_.length() - index - 1;
  }

  const GrowableArray<BlockEntryInstr*>& block_order_;

 private:
  DISALLOW_COPY_AND_ASSIGN(FlowGraphVisitor);
};


}  // namespace dart

#endif  // VM_INTERMEDIATE_LANGUAGE_H_
