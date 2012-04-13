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

class FlowGraphVisitor;
class LocalVariable;

// M is a two argument macro.  It is applied to each concrete value's
// typename and classname.
#define FOR_EACH_VALUE(M)                                                      \
  M(Temp, TempVal)                                                             \
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
  M(NativeLoadField, NativeLoadFieldComp)                                      \
  M(ExtractFactoryTypeArguments, ExtractFactoryTypeArgumentsComp)              \
  M(ExtractConstructorTypeArguments, ExtractConstructorTypeArgumentsComp)      \
  M(ExtractConstructorInstantiator, ExtractConstructorInstantiatorComp)        \
  M(AllocateContext, AllocateContextComp)                                      \
  M(ChainContext, ChainContextComp)                                            \
  M(CloneContext, CloneContextComp)                                            \
  M(CatchEntry, CatchEntryComp)                                                \


#define FORWARD_DECLARATION(ShortName, ClassName) class ClassName;
FOR_EACH_COMPUTATION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

class Computation : public ZoneAllocated {
 public:
  Computation() { }

  // Visiting support.
  virtual void Accept(FlowGraphVisitor* visitor) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(Computation);
};


class Value : public Computation {
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
  virtual void Accept(FlowGraphVisitor* visitor);

// Functions defined in all concrete value classes.
#define DECLARE_VALUE(ShortName)                                               \
  DECLARE_COMPUTATION(ShortName)                                               \
  virtual ShortName##Val* As##ShortName() { return this; }


class TempVal : public Value {
 public:
  explicit TempVal(intptr_t index) : index_(index) { }

  DECLARE_VALUE(Temp)

  intptr_t index() const { return index_; }

 private:
  const intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(TempVal);
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
  AssertAssignableComp(intptr_t node_id,
                       intptr_t token_index,
                       intptr_t try_index,
                       Value* value,
                       Value* type_arguments,  // Can be NULL.
                       const AbstractType& dst_type,
                       const String& dst_name)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        value_(value),
        type_arguments_(type_arguments),
        dst_type_(dst_type),
        dst_name_(dst_name) {
    ASSERT(value_ != NULL);
    ASSERT(!dst_type.IsNull());
    ASSERT(!dst_name.IsNull());
  }

  DECLARE_COMPUTATION(AssertAssignable)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* value() const { return value_; }
  Value* type_arguments() const { return type_arguments_; }
  const AbstractType& dst_type() const { return dst_type_; }
  const String& dst_name() const { return dst_name_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* value_;
  Value* type_arguments_;
  const AbstractType& dst_type_;
  const String& dst_name_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableComp);
};


class AssertBooleanComp : public Computation {
 public:
  AssertBooleanComp(intptr_t node_id,
                    intptr_t token_index,
                    intptr_t try_index,
                    Value* value)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        value_(value) {
    ASSERT(value_ != NULL);
  }

  DECLARE_COMPUTATION(AssertBoolean)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* value() const { return value_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(AssertBooleanComp);
};


// Denotes the current context, normally held in a register.  This is
// a computation, not a value, because it's mutable.
class CurrentContextComp : public Computation {
 public:
  CurrentContextComp() { }

  DECLARE_COMPUTATION(CurrentContext)

 private:
  DISALLOW_COPY_AND_ASSIGN(CurrentContextComp);
};


class StoreContextComp : public Computation {
 public:
  explicit StoreContextComp(Value* value) : value_(value) {
    ASSERT(value_ != NULL);
  }

  DECLARE_COMPUTATION(StoreContext);

  Value* value() const { return value_; }

 private:
  Value* value_;

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
    ASSERT(context->IsTemp());
  }

  DECLARE_COMPUTATION(ClosureCall)

  const Array& argument_names() const { return ast_node_.arguments()->names(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }

  Value* context() const { return context_; }
  intptr_t ArgumentCount() const { return arguments_->length(); }
  Value* ArgumentAt(intptr_t index) const { return (*arguments_)[index]; }

 private:
  const ClosureCallNode& ast_node_;
  const intptr_t try_index_;
  Value* context_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(ClosureCallComp);
};


class InstanceCallComp : public Computation {
 public:
  InstanceCallComp(intptr_t node_id,
                   intptr_t token_index,
                   intptr_t try_index,
                   const String& function_name,
                   ZoneGrowableArray<Value*>* arguments,
                   const Array& argument_names,
                   intptr_t checked_argument_count)
      : node_id_(node_id),
        token_index_(token_index),
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

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const String& function_name() const { return function_name_; }
  intptr_t ArgumentCount() const { return arguments_->length(); }
  Value* ArgumentAt(intptr_t index) const { return (*arguments_)[index]; }
  const Array& argument_names() const { return argument_names_; }
  intptr_t checked_argument_count() const { return checked_argument_count_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  const String& function_name_;
  ZoneGrowableArray<Value*>* const arguments_;
  const Array& argument_names_;
  const intptr_t checked_argument_count_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallComp);
};


class StrictCompareComp : public Computation {
 public:
  StrictCompareComp(Token::Kind kind, Value* left, Value* right)
      : kind_(kind), left_(left), right_(right) {
    ASSERT((kind_ == Token::kEQ_STRICT) || (kind_ == Token::kNE_STRICT));
  }

  DECLARE_COMPUTATION(StrictCompare)

  Token::Kind kind() const { return kind_; }
  Value* left() const { return left_; }
  Value* right() const { return right_; }

 private:
  const Token::Kind kind_;
  Value* left_;
  Value* right_;

  DISALLOW_COPY_AND_ASSIGN(StrictCompareComp);
};


class EqualityCompareComp : public Computation {
 public:
  EqualityCompareComp(intptr_t node_id,
                      intptr_t token_index,
                      intptr_t try_index,
                      Value* left,
                      Value* right)
    : node_id_(node_id),
      token_index_(token_index),
      try_index_(try_index),
      left_(left),
      right_(right) {
    ASSERT(left_ != NULL);
    ASSERT(right_ != NULL);
  }

  DECLARE_COMPUTATION(EqualityCompareComp)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* left() const { return left_; }
  Value* right() const { return right_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* left_;
  Value* right_;

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

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const Function& function_;
  const Array& argument_names_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallComp);
};


class LoadLocalComp : public Computation {
 public:
  LoadLocalComp(const LocalVariable& local, intptr_t context_level)
      : local_(local), context_level_(context_level) { }

  DECLARE_COMPUTATION(LoadLocal)

  const LocalVariable& local() const { return local_; }
  intptr_t context_level() const { return context_level_; }

 private:
  const LocalVariable& local_;
  const intptr_t context_level_;

  DISALLOW_COPY_AND_ASSIGN(LoadLocalComp);
};


class StoreLocalComp : public Computation {
 public:
  StoreLocalComp(const LocalVariable& local,
                 Value* value,
                 intptr_t context_level)
      : local_(local), value_(value), context_level_(context_level) { }

  DECLARE_COMPUTATION(StoreLocal)

  const LocalVariable& local() const { return local_; }
  Value* value() const { return value_; }
  intptr_t context_level() const { return context_level_; }

 private:
  const LocalVariable& local_;
  Value* value_;
  const intptr_t context_level_;

  DISALLOW_COPY_AND_ASSIGN(StoreLocalComp);
};


class NativeCallComp : public Computation {
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

 private:
  const NativeBodyNode& ast_node_;
  const intptr_t try_index_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallComp);
};


class LoadInstanceFieldComp : public Computation {
 public:
  LoadInstanceFieldComp(LoadInstanceFieldNode* ast_node, Value* instance)
      : ast_node_(*ast_node), instance_(instance) {
    ASSERT(instance_ != NULL);
  }

  DECLARE_COMPUTATION(LoadInstanceField)

  const Field& field() const { return ast_node_.field(); }

  Value* instance() const { return instance_; }

 private:
  const LoadInstanceFieldNode& ast_node_;
  Value* instance_;

  DISALLOW_COPY_AND_ASSIGN(LoadInstanceFieldComp);
};


class StoreInstanceFieldComp : public Computation {
 public:
  StoreInstanceFieldComp(StoreInstanceFieldNode* ast_node,
                         Value* instance,
                         Value* value)
      : ast_node_(*ast_node), instance_(instance), value_(value) {
    ASSERT(instance_ != NULL);
    ASSERT(value_ != NULL);
  }

  DECLARE_COMPUTATION(StoreInstanceField)

  intptr_t node_id() const { return ast_node_.id(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  const Field& field() const { return ast_node_.field(); }

  Value* instance() const { return instance_; }
  Value* value() const { return value_; }

 private:
  const StoreInstanceFieldNode& ast_node_;
  Value* instance_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(StoreInstanceFieldComp);
};


class LoadStaticFieldComp : public Computation {
 public:
  explicit LoadStaticFieldComp(const Field& field) : field_(field) {}

  DECLARE_COMPUTATION(LoadStaticField);

  const Field& field() const { return field_; }

 private:
  const Field& field_;

  DISALLOW_COPY_AND_ASSIGN(LoadStaticFieldComp);
};


class StoreStaticFieldComp : public Computation {
 public:
  StoreStaticFieldComp(const Field& field, Value* value)
      : field_(field),
        value_(value) {
    ASSERT(field.IsZoneHandle());
    ASSERT(value != NULL);
  }

  DECLARE_COMPUTATION(StoreStaticField);

  const Field& field() const { return field_; }
  Value* value() const { return value_; }

 private:
  const Field& field_;
  Value* const value_;

  DISALLOW_COPY_AND_ASSIGN(StoreStaticFieldComp);
};


// Not simply an InstanceCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class StoreIndexedComp : public Computation {
 public:
  StoreIndexedComp(intptr_t node_id,
                   intptr_t token_index,
                   intptr_t try_index,
                   Value* array,
                   Value* index,
                   Value* value)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        array_(array),
        index_(index),
        value_(value) { }

  DECLARE_COMPUTATION(StoreIndexed)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* array() const { return array_; }
  Value* index() const { return index_; }
  Value* value() const { return value_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* array_;
  Value* index_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(StoreIndexedComp);
};


// Not simply an InstanceCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class InstanceSetterComp : public Computation {
 public:
  InstanceSetterComp(intptr_t node_id,
                     intptr_t token_index,
                     intptr_t try_index,
                     const String& field_name,
                     Value* receiver,
                     Value* value)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        field_name_(field_name),
        receiver_(receiver),
        value_(value) { }

  DECLARE_COMPUTATION(InstanceSetter)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const String& field_name() const { return field_name_; }
  Value* receiver() const { return receiver_; }
  Value* value() const { return value_; }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  const String& field_name_;
  Value* const receiver_;
  Value* const value_;

  DISALLOW_COPY_AND_ASSIGN(InstanceSetterComp);
};


// Not simply a StaticCall because it has somewhat more complicated
// semantics: the value operand is preserved before the call.
class StaticSetterComp : public Computation {
 public:
  StaticSetterComp(intptr_t token_index,
                   intptr_t try_index,
                   const Function& setter_function,
                   Value* value)
      : token_index_(token_index),
        try_index_(try_index),
        setter_function_(setter_function),
        value_(value) { }

  DECLARE_COMPUTATION(StaticSetter)

  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  const Function& setter_function() const { return setter_function_; }
  Value* value() const { return value_; }

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const Function& setter_function_;
  Value* const value_;

  DISALLOW_COPY_AND_ASSIGN(StaticSetterComp);
};


// Note overrideable, built-in: value? false : true.
class BooleanNegateComp : public Computation {
 public:
  explicit BooleanNegateComp(Value* value) : value_(value) {}

  DECLARE_COMPUTATION(BooleanNegate)

  Value* value() const { return value_; }

 private:
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(BooleanNegateComp);
};


class InstanceOfComp : public Computation {
 public:
  InstanceOfComp(intptr_t node_id,
                 intptr_t token_index,
                 intptr_t try_index,
                 Value* value,
                 Value* type_arguments,  // Can be NULL.
                 const AbstractType& type,
                 bool negate_result)
      : node_id_(node_id),
        token_index_(token_index),
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
  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }

 private:
  const intptr_t node_id_;
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

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<Value*>* const arguments_;
  DISALLOW_COPY_AND_ASSIGN(AllocateObjectComp);
};


class CreateArrayComp : public Computation {
 public:
  CreateArrayComp(ArrayNode* node,
                  intptr_t try_index,
                  ZoneGrowableArray<Value*>* elements)
      : ast_node_(*node), try_index_(try_index), elements_(elements) { }

  DECLARE_COMPUTATION(CreateArray)

  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  intptr_t ElementCount() const { return elements_->length(); }
  Value* ElementAt(intptr_t i) const { return (*elements_)[i]; }

 private:
  const ArrayNode& ast_node_;
  const intptr_t try_index_;
  ZoneGrowableArray<Value*>* const elements_;

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

 private:
  const ClosureNode& ast_node_;
  const intptr_t try_index_;
  Value* type_arguments_;

  DISALLOW_COPY_AND_ASSIGN(CreateClosureComp);
};


class NativeLoadFieldComp : public Computation {
 public:
  NativeLoadFieldComp(Value* value, intptr_t offset_in_bytes)
      : value_(value), offset_in_bytes_(offset_in_bytes) {
    ASSERT(value != NULL);
  }

  DECLARE_COMPUTATION(NativeLoadField)

  Value* value() const { return value_; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

 private:
  Value* value_;
  intptr_t offset_in_bytes_;

  DISALLOW_COPY_AND_ASSIGN(NativeLoadFieldComp);
};


class ExtractFactoryTypeArgumentsComp : public Computation {
 public:
  ExtractFactoryTypeArgumentsComp(ConstructorCallNode* ast_node,
                                  intptr_t try_index,
                                  Value* instantiator)
      : ast_node_(*ast_node),
        try_index_(try_index),
        instantiator_(instantiator) {
    ASSERT(instantiator_ != NULL);
  }

  DECLARE_COMPUTATION(ExtractFactoryTypeArguments)

  Value* instantiator() const { return instantiator_; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  const Function& factory() const { return ast_node_.constructor(); }
  intptr_t node_id() const { return ast_node_.id(); }
  intptr_t token_index() const { return ast_node_.token_index(); }
  intptr_t try_index() const { return try_index_; }

 private:
  const ConstructorCallNode& ast_node_;
  const intptr_t try_index_;
  Value* instantiator_;

  DISALLOW_COPY_AND_ASSIGN(ExtractFactoryTypeArgumentsComp);
};


class ExtractConstructorTypeArgumentsComp : public Computation {
 public:
  ExtractConstructorTypeArgumentsComp(ConstructorCallNode* ast_node,
                                      Value* instantiator)
      : ast_node_(*ast_node), instantiator_(instantiator) {
    ASSERT(instantiator_ != NULL);
  }

  DECLARE_COMPUTATION(ExtractConstructorTypeArguments)

  Value* instantiator() const { return instantiator_; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t node_id() const { return ast_node_.id(); }
  intptr_t token_index() const { return ast_node_.token_index(); }

 private:
  const ConstructorCallNode& ast_node_;
  Value* instantiator_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorTypeArgumentsComp);
};


class ExtractConstructorInstantiatorComp : public Computation {
 public:
  ExtractConstructorInstantiatorComp(ConstructorCallNode* ast_node,
                                     Value* instantiator,
                                     Value* discard_value)
      : ast_node_(*ast_node),
        instantiator_(instantiator),
        discard_value_(discard_value) {
    ASSERT(instantiator_ != NULL);
  }

  DECLARE_COMPUTATION(ExtractConstructorInstantiator)

  Value* instantiator() const { return instantiator_; }
  Value* discard_value() const { return discard_value_; }
  const AbstractTypeArguments& type_arguments() const {
    return ast_node_.type_arguments();
  }
  const Function& constructor() const { return ast_node_.constructor(); }
  intptr_t node_id() const { return ast_node_.id(); }
  intptr_t token_index() const { return ast_node_.token_index(); }

 private:
  const ConstructorCallNode& ast_node_;
  Value* instantiator_;
  Value* discard_value_;

  DISALLOW_COPY_AND_ASSIGN(ExtractConstructorInstantiatorComp);
};


class AllocateContextComp : public Computation {
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

 private:
  const intptr_t token_index_;
  const intptr_t try_index_;
  const intptr_t num_context_variables_;

  DISALLOW_COPY_AND_ASSIGN(AllocateContextComp);
};


class ChainContextComp : public Computation {
 public:
  explicit ChainContextComp(Value* context_value)
      : context_value_(context_value) {
    ASSERT(context_value_ != NULL);
  }

  DECLARE_COMPUTATION(ChainContext)

  Value* context_value() const { return context_value_; }

 private:
  Value* context_value_;

  DISALLOW_COPY_AND_ASSIGN(ChainContextComp);
};


class CloneContextComp : public Computation {
 public:
  CloneContextComp(intptr_t node_id,
                   intptr_t token_index,
                   intptr_t try_index,
                   Value* context_value)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        context_value_(context_value) {
    ASSERT(context_value_ != NULL);
  }

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* context_value() const { return context_value_; }

  DECLARE_COMPUTATION(CloneContext)

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* context_value_;

  DISALLOW_COPY_AND_ASSIGN(CloneContextComp);
};


class CatchEntryComp : public Computation {
 public:
  CatchEntryComp(const LocalVariable& exception_var,
                 const LocalVariable& stacktrace_var)
      : exception_var_(exception_var), stacktrace_var_(stacktrace_var) {}

  const LocalVariable& exception_var() const { return exception_var_; }
  const LocalVariable& stacktrace_var() const { return stacktrace_var_; }

  DECLARE_COMPUTATION(CatchEntry)

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
//                 | PickTemp <int> <int> <Instruction>
//                 | TuckTemp <int> <int> <Instruction>
//                 | Do <Computation> <Instruction>
//                 | Bind <int> <Computation> <Instruction>
//                 | Return <Value>
//                 | Branch <Value> <Instruction> <Instruction>

// M is a single argument macro.  It is applied to each concrete instruction
// type name.  The concrete instruction classes are the name with Instr
// concatenated.
#define FOR_EACH_INSTRUCTION(M)                                                \
  M(JoinEntry)                                                                 \
  M(TargetEntry)                                                               \
  M(PickTemp)                                                                  \
  M(TuckTemp)                                                                  \
  M(Do)                                                                        \
  M(Bind)                                                                      \
  M(Return)                                                                    \
  M(Throw)                                                                     \
  M(ReThrow)                                                                   \
  M(Branch)                                                                    \


// Forward declarations for Instruction classes.
class BlockEntryInstr;
#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION


// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                                              \
  virtual Instruction* Accept(FlowGraphVisitor* visitor);                      \
  virtual bool Is##type() const { return true; }                               \
  virtual type##Instr* As##type() { return this; }                             \


class Instruction : public ZoneAllocated {
 public:
  Instruction() { }

  virtual bool IsBlockEntry() const { return false; }
  BlockEntryInstr* AsBlockEntry() {
    return IsBlockEntry() ? reinterpret_cast<BlockEntryInstr*>(this) : NULL;
  }

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
  // numbers to the preorder number of the block's spanning-tree parent.  As
  // a side effect of this function, the set of basic block predecessors
  // (e.g., block entry instructions of predecessor blocks) and also the
  // last instruction in the block is recorded in each entry instruction.
  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent) {
    // Never called for instructions except block entries and branches.
    UNREACHABLE();
  }

#define INSTRUCTION_TYPE_CHECK(type)                                           \
  virtual bool Is##type() const { return false; }                              \
  virtual type##Instr* As##type() { return NULL; }
FOR_EACH_INSTRUCTION(INSTRUCTION_TYPE_CHECK)
#undef INSTRUCTION_TYPE_CHECK

 private:
  DISALLOW_COPY_AND_ASSIGN(Instruction);
};


// Basic block entries are administrative nodes.  Joins are the only nodes
// with multiple predecessors.  Targets are the other basic block entries.
// The types enforce edge-split form---joins are forbidden as the successors
// of branches.
class BlockEntryInstr : public Instruction {
 public:
  virtual bool IsBlockEntry() const { return true; }

  virtual intptr_t PredecessorCount() const = 0;
  virtual BlockEntryInstr* PredecessorAt(intptr_t index) const = 0;

  intptr_t preorder_number() const { return preorder_number_; }
  void set_preorder_number(intptr_t number) { preorder_number_ = number; }

  intptr_t postorder_number() const { return postorder_number_; }
  void set_postorder_number(intptr_t number) { postorder_number_ = number; }

  BlockEntryInstr* dominator() const { return dominator_; }
  void set_dominator(BlockEntryInstr* instr) { dominator_ = instr; }

  Instruction* last_instruction() const { return last_instruction_; }
  void set_last_instruction(Instruction* instr) { last_instruction_ = instr; }

 protected:
  BlockEntryInstr()
      : preorder_number_(-1),
        postorder_number_(-1),
        dominator_(NULL),
        last_instruction_(NULL) { }

 private:
  intptr_t preorder_number_;
  intptr_t postorder_number_;
  BlockEntryInstr* dominator_;  // Immediate dominator, NULL for graph entry.
  Instruction* last_instruction_;

  DISALLOW_COPY_AND_ASSIGN(BlockEntryInstr);
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

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent);

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

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void DiscoverBlocks(
      BlockEntryInstr* current_block,
      GrowableArray<BlockEntryInstr*>* preorder,
      GrowableArray<BlockEntryInstr*>* postorder,
      GrowableArray<intptr_t>* parent);

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


// The non-optimizing compiler assumes that there is exactly one use of
// every temporary so they can be deallocated at their use.  Some AST nodes,
// e.g., expr0[expr1]++, violate this assumption (there are two uses of each
// of the values expr0 and expr1).
//
// PickTemp is used to name (with 'destination') a copy of a live temporary
// (named 'source') without counting as the use of the source.
class PickTempInstr : public Instruction {
 public:
  PickTempInstr(intptr_t dst, intptr_t src)
      : destination_(dst), source_(src), successor_(NULL) { }

  DECLARE_INSTRUCTION(PickTemp)

  intptr_t destination() const { return destination_; }
  intptr_t source() const { return source_; }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL && instr != NULL);
    successor_ = instr;
  }

 private:
  const intptr_t destination_;
  const intptr_t source_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(PickTempInstr);
};


// The non-optimizing compiler assumes that temporary definitions and uses
// obey a stack discipline, so they can be allocated and deallocated with
// push and pop.  Some Some AST nodes, e.g., expr++, violate this assumption
// (the value expr+1 is produced after the value of expr, and also consumed
// after it).
//
// We 'preallocate' temporaries (named with 'destination') such as the one
// for expr+1 and use TuckTemp to mutate them by overwriting them with a
// copy of a temporary (named with 'source').
class TuckTempInstr : public Instruction {
 public:
  TuckTempInstr(intptr_t dst, intptr_t src)
      : destination_(dst), source_(src), successor_(NULL) { }

  DECLARE_INSTRUCTION(TuckTemp)

  intptr_t destination() const { return destination_; }
  intptr_t source() const { return source_; }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL && instr != NULL);
    successor_ = instr;
  }

 private:
  const intptr_t destination_;
  const intptr_t source_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(TuckTempInstr);
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

 private:
  Computation* computation_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(DoInstr);
};


class BindInstr : public Instruction {
 public:
  BindInstr(intptr_t temp_index, Computation* computation)
      : temp_index_(temp_index), computation_(computation), successor_(NULL) { }

  DECLARE_INSTRUCTION(Bind)

  intptr_t temp_index() const { return temp_index_; }
  Computation* computation() const { return computation_; }

  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

 private:
  const intptr_t temp_index_;
  Computation* computation_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(BindInstr);
};


class ReturnInstr : public Instruction {
 public:
  ReturnInstr(intptr_t node_id, intptr_t token_index, Value* value)
      : node_id_(node_id), token_index_(token_index), value_(value) {
    ASSERT(value_ != NULL);
  }

  DECLARE_INSTRUCTION(Return)

  Value* value() const { return value_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t node_id() const { return node_id_; }

  virtual Instruction* StraightLineSuccessor() const { return NULL; }
  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(ReturnInstr);
};


class ThrowInstr : public Instruction {
 public:
  ThrowInstr(intptr_t node_id,
             intptr_t token_index,
             intptr_t try_index,
             Value* exception)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        exception_(exception),
        successor_(NULL) {
    ASSERT(exception_ != NULL);
  }

  DECLARE_INSTRUCTION(Throw)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* exception() const { return exception_; }

  // Parser can generate a throw within an expression tree.
  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

 private:
  const intptr_t node_id_;
  const intptr_t token_index_;
  const intptr_t try_index_;
  Value* exception_;
  Instruction* successor_;

  DISALLOW_COPY_AND_ASSIGN(ThrowInstr);
};


class ReThrowInstr : public Instruction {
 public:
  ReThrowInstr(intptr_t node_id,
              intptr_t token_index,
              intptr_t try_index,
              Value* exception,
              Value* stack_trace)
      : node_id_(node_id),
        token_index_(token_index),
        try_index_(try_index),
        exception_(exception),
        stack_trace_(stack_trace),
        successor_(NULL) {
    ASSERT(exception_ != NULL);
    ASSERT(stack_trace_ != NULL);
  }

  DECLARE_INSTRUCTION(ReThrow)

  intptr_t node_id() const { return node_id_; }
  intptr_t token_index() const { return token_index_; }
  intptr_t try_index() const { return try_index_; }
  Value* exception() const { return exception_; }
  Value* stack_trace() const { return stack_trace_; }

  // Parser can generate a rethrow within an expression tree.
  virtual Instruction* StraightLineSuccessor() const {
    return successor_;
  }
  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

 private:
  const intptr_t node_id_;
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
      GrowableArray<intptr_t>* parent);

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
