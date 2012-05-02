// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_AST_H_
#define VM_AST_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/scopes.h"
#include "vm/object.h"
#include "vm/native_entry.h"
#include "vm/token.h"

namespace dart {

#define NODE_LIST(V)                                                           \
  V(ReturnNode, "return")                                                      \
  V(LiteralNode, "literal")                                                    \
  V(TypeNode, "type")                                                          \
  V(AssignableNode, "assignable")                                              \
  V(BinaryOpNode, "binop")                                                     \
  V(StringConcatNode, "concat")                                                \
  V(ComparisonNode, "compare")                                                 \
  V(UnaryOpNode, "unaryop")                                                    \
  V(IncrOpLocalNode, "incr local")                                             \
  V(IncrOpInstanceFieldNode, "incr instance field")                            \
  V(IncrOpIndexedNode, "incr indexed")                                         \
  V(ConditionalExprNode, "?:")                                                 \
  V(IfNode, "if")                                                              \
  V(SwitchNode, "switch")                                                      \
  V(CaseNode, "case")                                                          \
  V(WhileNode, "while")                                                        \
  V(DoWhileNode, "dowhile")                                                    \
  V(ForNode, "for")                                                            \
  V(JumpNode, "jump")                                                          \
  V(ArgumentListNode, "args")                                                  \
  V(ArrayNode, "array")                                                        \
  V(ClosureNode, "closure")                                                    \
  V(InstanceCallNode, "instance call")                                         \
  V(StaticCallNode, "static call")                                             \
  V(ClosureCallNode, "closure call")                                           \
  V(CloneContextNode, "clone context")                                         \
  V(ConstructorCallNode, "constructor call")                                   \
  V(InstanceGetterNode, "instance getter call")                                \
  V(InstanceSetterNode, "instance setter call")                                \
  V(StaticGetterNode, "static getter")                                         \
  V(StaticSetterNode, "static setter")                                         \
  V(NativeBodyNode, "native body")                                             \
  V(PrimaryNode, "primary")                                                    \
  V(LoadLocalNode, "load local")                                               \
  V(StoreLocalNode, "store local")                                             \
  V(LoadInstanceFieldNode, "load field")                                       \
  V(StoreInstanceFieldNode, "store field")                                     \
  V(LoadStaticFieldNode, "load static field")                                  \
  V(StoreStaticFieldNode, "store static field")                                \
  V(LoadIndexedNode, "load indexed")                                           \
  V(StoreIndexedNode, "store indexed")                                         \
  V(SequenceNode, "seq")                                                       \
  V(CatchClauseNode, "catch clause block")                                     \
  V(TryCatchNode, "try catch block")                                           \
  V(ThrowNode, "throw")                                                        \
  V(InlinedFinallyNode, "inlined finally")                                     \


#define DEFINE_FORWARD_DECLARATION(type, name) class type;
NODE_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION

// Forward declarations.
class CodeGenInfo;

// Abstract class to implement an AST node visitor. An example is AstPrinter.
class AstNodeVisitor : public ValueObject {
 public:
  AstNodeVisitor() {}
  virtual ~AstNodeVisitor() {}

#define DEFINE_VISITOR_FUNCTION(type, name)                                    \
  virtual void Visit##type(type* node) { }
NODE_LIST(DEFINE_VISITOR_FUNCTION)
#undef DEFINE_VISITOR_FUNCTION

 private:
  DISALLOW_COPY_AND_ASSIGN(AstNodeVisitor);
};


#define DECLARE_COMMON_NODE_FUNCTIONS(type)                                    \
  virtual void Visit(AstNodeVisitor* visitor);                                 \
  virtual const char* ShortName() const;                                       \
  virtual bool Is##type() const { return true; }                               \
  virtual type* As##type() { return this; }


class AstNode : public ZoneAllocated {
 public:
  static const int kNoId = -1;

  explicit AstNode(intptr_t token_index)
      : token_index_(token_index),
        id_(GetNextId()),
        ic_data_(ICData::ZoneHandle()),
        info_(NULL) {
    ASSERT(token_index >= 0);
  }

  intptr_t token_index() const { return token_index_; }

  virtual void SetIcDataAtId(intptr_t node_id, const ICData& value) {
    ASSERT(id() == node_id);
    set_ic_data(value);
  }

  virtual const ICData& ICDataAtId(intptr_t node_id) const {
    ASSERT(id() == node_id);
    return ic_data_;
  }

  virtual bool HasId(intptr_t value) const { return id_ == value; }

  intptr_t id() const { return id_; }

  void set_info(CodeGenInfo* info) { info_ = info; }
  CodeGenInfo* info() const { return info_; }

#define AST_TYPE_CHECK(type, name)                                             \
  virtual bool Is##type() const { return false; }                              \
  virtual type* As##type() { return NULL; }
NODE_LIST(AST_TYPE_CHECK)
#undef AST_TYPE_CHECK

  virtual void Visit(AstNodeVisitor* visitor) = 0;
  virtual void VisitChildren(AstNodeVisitor* visitor) const = 0;
  virtual const char* ShortName() const = 0;

  // 'ShortName' is predefined for each AstNode and is the default
  // implementation of "Name()". Each AST node can override the function
  // "Name" to do more complex name composition.
  virtual const char* Name() const {
    return ShortName();
  }

  // Convert the node into an assignment node using the rhs which is passed in,
  // this is typically used for converting nodes like LoadLocalNode,
  // LoadStaticFieldNode, InstanceGetterNode etc. which were created during
  // parsing as the assignment context was not known yet at that time.
  virtual AstNode* MakeAssignmentNode(AstNode* rhs) {
    return NULL;  // By default all nodes are not assignable.
  }

  // Return NULL if 'unary_op_kind' can't be applied.
  virtual AstNode* ApplyUnaryOp(Token::Kind unary_op_kind) {
    return NULL;
  }

  // Creates a an IncrOpXXXNode that corresponds to this node type, e.g.,
  // LoadLocalNode creates the appropriate IncrOpLocalNode
  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix) {
    return NULL;
  }

  // Analyzes an expression to determine whether it is a compile time
  // constant or not. Returns NULL if the expression is not a compile time
  // constant. Otherwise, the return value is an approximation of the
  // actual value of the const expression. The type of the returned value
  // corresponds to the type of the const expression and is either
  // Number, Integer, String, Bool, or anything else (not a subtype of
  // the former).
  virtual const Instance* EvalConstExpr() const { return NULL; }

 protected:
  friend class ParsedFunction;

  const ICData& ic_data() const { return ic_data_; }
  void set_ic_data(const ICData& value) {
    ic_data_ = value.raw();
  }

  static intptr_t GetNextId() {
    Isolate* isolate = Isolate::Current();
    intptr_t tmp = isolate->ast_node_id();
    isolate->set_ast_node_id(tmp + 1);
    return tmp;
  }

 private:
  const intptr_t token_index_;
  // Unique id per function compiled, used to match AST node to a PC.
  const intptr_t id_;
  // IC data collected for this node.
  ICData& ic_data_;
  // Used by optimizing compiler.
  CodeGenInfo* info_;
  DISALLOW_COPY_AND_ASSIGN(AstNode);
};


class SequenceNode : public AstNode {
 public:
  SequenceNode(intptr_t token_index, LocalScope* scope)
    : AstNode(token_index),
      scope_(scope),
      nodes_(4),
      label_(NULL),
      first_parameter_id_(AstNode::kNoId),
      last_parameter_id_(AstNode::kNoId) {
  }

  LocalScope* scope() const { return scope_; }

  SourceLabel* label() const { return label_; }
  void set_label(SourceLabel* value) { label_ = value; }

  void VisitChildren(AstNodeVisitor* visitor) const;

  void Add(AstNode* node) { nodes_.Add(node); }
  intptr_t length() const { return nodes_.length(); }
  AstNode* NodeAt(intptr_t index) const { return nodes_[index]; }

  void set_first_parameter_id(intptr_t value) { first_parameter_id_ = value; }
  void set_last_parameter_id(intptr_t value) { last_parameter_id_ = value; }
  intptr_t ParameterIdAt(intptr_t param_pos) const {
    ASSERT(first_parameter_id_ != AstNode::kNoId);
    ASSERT(last_parameter_id_ != AstNode::kNoId);
    ASSERT(param_pos <= (last_parameter_id_ - first_parameter_id_));
    return first_parameter_id_ + param_pos;
  }

  DECLARE_COMMON_NODE_FUNCTIONS(SequenceNode);

  // Collects all nodes accessible from this sequence node into array 'nodes'.
  void CollectAllNodes(GrowableArray<AstNode*>* nodes);

 private:
  LocalScope* scope_;
  GrowableArray<AstNode*> nodes_;
  SourceLabel* label_;
  intptr_t first_parameter_id_;
  intptr_t last_parameter_id_;

  DISALLOW_COPY_AND_ASSIGN(SequenceNode);
};


class CloneContextNode : public AstNode {
 public:
  explicit CloneContextNode(intptr_t token_index)
    : AstNode(token_index) {
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  DECLARE_COMMON_NODE_FUNCTIONS(CloneContextNode);

 private:
  DISALLOW_COPY_AND_ASSIGN(CloneContextNode);
};


class ArgumentListNode : public AstNode {
 public:
  explicit ArgumentListNode(intptr_t token_index)
     : AstNode(token_index),
       nodes_(4),
       names_(Array::ZoneHandle()) {
  }

  void VisitChildren(AstNodeVisitor* visitor) const;

  void Add(AstNode* node) {
    nodes_.Add(node);
  }
  intptr_t length() const { return nodes_.length(); }
  AstNode* NodeAt(intptr_t index) const { return nodes_[index]; }
  void SetNodeAt(intptr_t index, AstNode* node) { nodes_[index] = node; }
  const Array& names() const {
    return names_;
  }
  void set_names(const Array& names) {
    names_ = names.raw();
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ArgumentListNode);

 private:
  GrowableArray<AstNode*> nodes_;
  Array& names_;

  DISALLOW_COPY_AND_ASSIGN(ArgumentListNode);
};


class ArrayNode : public AstNode {
 public:
  ArrayNode(intptr_t token_index, const AbstractTypeArguments& type_arguments)
      : AstNode(token_index),
        type_arguments_(type_arguments),
        elements_(4) {
    ASSERT(type_arguments_.IsZoneHandle());
    ASSERT(type_arguments.IsNull() || type_arguments_.IsInstantiated());
  }

  void VisitChildren(AstNodeVisitor* visitor) const;

  intptr_t length() const { return elements_.length(); }

  AstNode* ElementAt(intptr_t index) const { return elements_[index]; }
  void SetElementAt(intptr_t index, AstNode* value) {
    elements_[index] = value;
  }
  void AddElement(AstNode* expr) { elements_.Add(expr); }

  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ArrayNode);

 private:
  const AbstractTypeArguments& type_arguments_;
  GrowableArray<AstNode*> elements_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ArrayNode);
};


class LiteralNode : public AstNode {
 public:
  LiteralNode(intptr_t token_index, const Instance& literal)
      : AstNode(token_index), literal_(literal) {
    ASSERT(literal.IsZoneHandle());
#if defined(DEBUG)
    if (literal.IsString()) {
      String& str = String::Handle();
      str ^= literal.raw();
      ASSERT(str.IsSymbol());
    }
#endif  // defined(DEBUG)
    ASSERT(literal.IsNull() ||
           Class::Handle(literal.clazz()).is_finalized() ||
           Class::Handle(literal.clazz()).is_prefinalized());
  }

  const Instance& literal() const { return literal_; }

  virtual const Instance* EvalConstExpr() const {
    return &literal();
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  virtual AstNode* ApplyUnaryOp(Token::Kind unary_op_kind);

  DECLARE_COMMON_NODE_FUNCTIONS(LiteralNode);

 private:
  const Instance& literal_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(LiteralNode);
};


class TypeNode : public AstNode {
 public:
  TypeNode(intptr_t token_index, const AbstractType& type)
      : AstNode(token_index), type_(type) {
    ASSERT(type.IsZoneHandle());
    ASSERT(!type.IsNull());
    ASSERT(type.IsFinalized());
  }

  const AbstractType& type() const { return type_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  DECLARE_COMMON_NODE_FUNCTIONS(TypeNode);

 private:
  const AbstractType& type_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(TypeNode);
};


class AssignableNode : public AstNode {
 public:
  AssignableNode(intptr_t token_index,
                 AstNode* expr,
                 const AbstractType& type,
                 const String& dst_name)
      : AstNode(token_index), expr_(expr), type_(type), dst_name_(dst_name) {
    ASSERT(expr_ != NULL);
    ASSERT(type_.IsZoneHandle());
    ASSERT(!type_.IsNull());
    ASSERT(type_.IsFinalized());
    ASSERT(dst_name_.IsZoneHandle());
  }

  AstNode* expr() const { return expr_; }
  const AbstractType& type() const { return type_; }
  const String& dst_name() const { return dst_name_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    expr()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(AssignableNode);

 private:
  AstNode* expr_;
  const AbstractType& type_;
  const String& dst_name_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(AssignableNode);
};


class ClosureNode : public AstNode {
 public:
  ClosureNode(intptr_t token_index,
              const Function& function,
              AstNode* receiver,  // Non-null for implicit instance closures.
              LocalScope* scope)  // Null for implicit closures.
      : AstNode(token_index),
        function_(function),
        receiver_(receiver),
        scope_(scope) {
    ASSERT(function.IsZoneHandle());
    ASSERT((function.IsNonImplicitClosureFunction() &&
            (receiver_ == NULL) && (scope_ != NULL)) ||
           (function.IsImplicitInstanceClosureFunction() &&
            (receiver_ != NULL) && (scope_ == NULL)) ||
           (function.IsImplicitStaticClosureFunction() &&
            (receiver_ == NULL) && (scope_ == NULL)));
  }

  const Function& function() const { return function_; }
  AstNode* receiver() const { return receiver_; }
  LocalScope* scope() const { return scope_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    if (receiver() != NULL) {
      receiver()->Visit(visitor);
    }
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ClosureNode);

 private:
  const Function& function_;
  AstNode* receiver_;
  LocalScope* scope_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ClosureNode);
};


// Primary nodes hold identifiers or values (library, class or function)
// resolved from an identifier. Primary nodes should not ever make it to the
// code generation phase as they will be transformed into the correct call or
// field access nodes.
class PrimaryNode : public AstNode {
 public:
  PrimaryNode(intptr_t token_index, const Object& primary)
      : AstNode(token_index), primary_(primary) {
    ASSERT(primary.IsZoneHandle());
  }

  const Object& primary() const { return primary_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const;

  DECLARE_COMMON_NODE_FUNCTIONS(PrimaryNode);

 private:
  const Object& primary_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PrimaryNode);
};


class ReturnNode : public AstNode {
 public:
  // Return from a void function returns the null object.
  explicit ReturnNode(intptr_t token_index)
      : AstNode(token_index),
        value_(new LiteralNode(token_index, Instance::ZoneHandle())),
        inlined_finally_list_() { }
  // Return from a non-void function.
  ReturnNode(intptr_t token_index,
             AstNode* value)
      : AstNode(token_index), value_(value), inlined_finally_list_() {
    ASSERT(value != NULL);
  }

  AstNode* value() const { return value_; }

  intptr_t inlined_finally_list_length() const {
    return inlined_finally_list_.length();
  }
  InlinedFinallyNode* InlinedFinallyNodeAt(intptr_t index) const {
    return inlined_finally_list_[index];
  }
  void AddInlinedFinallyNode(InlinedFinallyNode* finally_node) {
    inlined_finally_list_.Add(finally_node);
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    if (value() != NULL) {
      value()->Visit(visitor);
    }
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ReturnNode);

 private:
  AstNode* value_;
  GrowableArray<InlinedFinallyNode*> inlined_finally_list_;

  DISALLOW_COPY_AND_ASSIGN(ReturnNode);
};


class ComparisonNode : public AstNode {
 public:
  ComparisonNode(intptr_t token_index,
                 Token::Kind kind,
                 AstNode* left,
                 AstNode* right)
  : AstNode(token_index), kind_(kind), left_(left), right_(right) {
    ASSERT(left_ != NULL);
    ASSERT(right_ != NULL);
    ASSERT(IsKindValid());
  }

  Token::Kind kind() const { return kind_; }
  AstNode* left() const { return left_; }
  AstNode* right() const { return right_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    left()->Visit(visitor);
    right()->Visit(visitor);
  }

  virtual const char* Name() const;
  virtual const Instance* EvalConstExpr() const;

  DECLARE_COMMON_NODE_FUNCTIONS(ComparisonNode);

 private:
  const Token::Kind kind_;
  AstNode* left_;
  AstNode* right_;

  bool IsKindValid() const;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ComparisonNode);
};


class BinaryOpNode : public AstNode {
 public:
  BinaryOpNode(intptr_t token_index,
               Token::Kind kind,
               AstNode* left,
               AstNode* right)
      : AstNode(token_index), kind_(kind), left_(left), right_(right) {
    ASSERT(left_ != NULL);
    ASSERT(right_ != NULL);
    ASSERT(IsKindValid());
  }

  Token::Kind kind() const { return kind_; }
  AstNode* left() const { return left_; }
  AstNode* right() const { return right_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    left()->Visit(visitor);
    right()->Visit(visitor);
  }

  virtual const char* Name() const;
  virtual const Instance* EvalConstExpr() const;

  DECLARE_COMMON_NODE_FUNCTIONS(BinaryOpNode);

 private:
  const Token::Kind kind_;
  AstNode* left_;
  AstNode* right_;

  bool IsKindValid() const;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BinaryOpNode);
};


class StringConcatNode : public AstNode {
 public:
  explicit StringConcatNode(intptr_t token_index)
      : AstNode(token_index),
        values_(new ArrayNode(token_index, TypeArguments::ZoneHandle())) {
  }

  ArrayNode* values() const { return values_; }

  virtual const Instance* EvalConstExpr() const;

  void AddExpr(AstNode* expr) const {
    values_->AddElement(expr);
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    values_->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StringConcatNode);

 private:
  ArrayNode* values_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(StringConcatNode);
};


class UnaryOpNode : public AstNode {
 public:
  // Returns optimized version, e.g., for ('-' '1') ('-1') literal is returned.
  static AstNode* UnaryOpOrLiteral(intptr_t token_index,
                                   Token::Kind kind,
                                   AstNode* operand);
  UnaryOpNode(intptr_t token_index,
              Token::Kind kind,
              AstNode* operand)
      : AstNode(token_index), kind_(kind), operand_(operand) {
    ASSERT(operand_ != NULL);
    ASSERT(IsKindValid());
  }

  Token::Kind kind() const { return kind_; }
  AstNode* operand() const { return operand_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    operand()->Visit(visitor);
  }

  virtual const char* Name() const;
  virtual const Instance* EvalConstExpr() const;

  DECLARE_COMMON_NODE_FUNCTIONS(UnaryOpNode);

 private:
  const Token::Kind kind_;
  AstNode* operand_;

  bool IsKindValid() const;

  DISALLOW_IMPLICIT_CONSTRUCTORS(UnaryOpNode);
};


class IncrOpLocalNode : public AstNode {
 public:
  IncrOpLocalNode(intptr_t token_index,
                  Token::Kind kind,
                  bool prefix,
                  const LocalVariable& local)
      : AstNode(token_index), kind_(kind), prefix_(prefix), local_(local) {
    ASSERT(kind_ == Token::kINCR || kind_ == Token::kDECR);
  }

  Token::Kind kind() const { return kind_; }
  bool prefix() const { return prefix_; }
  const LocalVariable& local() const { return local_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {}

  virtual const char* Name() const;

  DECLARE_COMMON_NODE_FUNCTIONS(IncrOpLocalNode);

 private:
  const Token::Kind kind_;
  const bool prefix_;
  const LocalVariable& local_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(IncrOpLocalNode);
};


class IncrOpInstanceFieldNode : public AstNode {
 public:
  IncrOpInstanceFieldNode(intptr_t token_index,
                          Token::Kind kind,
                          bool prefix,
                          AstNode* receiver,
                          const String& field_name)
      : AstNode(token_index),
        kind_(kind),
        prefix_(prefix),
        receiver_(receiver),
        field_name_(field_name),
        operator_id_(AstNode::GetNextId()),
        setter_id_(AstNode::GetNextId()),
        operator_ic_data_(ICData::ZoneHandle()),
        setter_ic_data_(ICData::ZoneHandle()) {
    ASSERT(receiver_ != NULL);
    ASSERT(field_name_.IsZoneHandle());
    ASSERT(kind_ == Token::kINCR || kind_ == Token::kDECR);
  }

  Token::Kind kind() const { return kind_; }
  bool prefix() const { return prefix_; }
  AstNode* receiver() const { return receiver_; }
  const String& field_name() const { return field_name_; }

  intptr_t getter_id() const { return id(); }
  intptr_t operator_id() const { return operator_id_; }
  intptr_t setter_id() const { return setter_id_; }

  virtual bool HasId(intptr_t value) const {
    return (getter_id() == value) ||
           (operator_id() == value) ||
           (setter_id() == value);
  }

  virtual void SetIcDataAtId(intptr_t node_id, const ICData& value) {
    ASSERT(HasId(node_id));
    if (node_id == getter_id()) {
      set_ic_data(value);
    } else if (node_id == operator_id()) {
      operator_ic_data_ = value.raw();
    } else {
      ASSERT(node_id == setter_id());
      setter_ic_data_ = value.raw();
    }
  }

  virtual const ICData& ICDataAtId(intptr_t node_id) const {
    ASSERT(HasId(node_id));
    if (node_id == getter_id()) {
      return ic_data();
    } else if (node_id == operator_id()) {
      return operator_ic_data_;
    } else {
      ASSERT(node_id == setter_id());
      return setter_ic_data_;
    }
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    receiver()->Visit(visitor);
  }

  virtual const char* Name() const;

  DECLARE_COMMON_NODE_FUNCTIONS(IncrOpInstanceFieldNode);

 private:
  const Token::Kind kind_;
  const bool prefix_;
  AstNode* receiver_;
  const String& field_name_;
  const intptr_t operator_id_;
  const intptr_t setter_id_;
  ICData& operator_ic_data_;
  ICData& setter_ic_data_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(IncrOpInstanceFieldNode);
};


class IncrOpIndexedNode : public AstNode {
 public:
  IncrOpIndexedNode(intptr_t token_index,
                    Token::Kind kind,
                    bool prefix,
                    AstNode* array,
                    AstNode* index)
      : AstNode(token_index),
        kind_(kind),
        prefix_(prefix),
        array_(array),
        index_(index),
        operator_id_(AstNode::GetNextId()),
        store_id_(AstNode::GetNextId()),
        operator_ic_data_(ICData::ZoneHandle()),
        store_ic_data_(ICData::ZoneHandle()) {
    ASSERT(kind_ == Token::kINCR || kind_ == Token::kDECR);
    ASSERT(array_ != NULL);
    ASSERT(index_ != NULL);
  }

  Token::Kind kind() const { return kind_; }
  bool prefix() const { return prefix_; }
  AstNode* array() const { return array_; }
  AstNode* index() const { return index_; }

  intptr_t load_id() const { return id(); }
  intptr_t operator_id() const { return operator_id_; }
  intptr_t store_id() const { return store_id_; }

  virtual bool HasId(intptr_t value) const {
    return (load_id() == value) ||
           (operator_id() == value) ||
           (store_id() == value);
  }

  virtual const ICData& ICDataAtId(intptr_t node_id) const {
    ASSERT(HasId(node_id));
    if (node_id == load_id()) {
      return ic_data();
    } else if (node_id == operator_id()) {
      return operator_ic_data_;
    } else {
      ASSERT(node_id == store_id());
      return store_ic_data_;
    }
  }

  virtual void SetIcDataAtId(intptr_t node_id, const ICData& value) {
    ASSERT(HasId(node_id));
    if (node_id == load_id()) {
      set_ic_data(value);
    } else if (node_id == operator_id()) {
      operator_ic_data_ = value.raw();
    } else {
      ASSERT(node_id == store_id());
      store_ic_data_ = value.raw();
    }
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    array()->Visit(visitor);
    index()->Visit(visitor);
  }

  virtual const char* Name() const;

  DECLARE_COMMON_NODE_FUNCTIONS(IncrOpIndexedNode);

 private:
  const Token::Kind kind_;
  const bool prefix_;
  AstNode* array_;
  AstNode* index_;
  const intptr_t operator_id_;
  const intptr_t store_id_;
  ICData& operator_ic_data_;
  ICData& store_ic_data_;
};


class ConditionalExprNode : public AstNode {
 public:
  ConditionalExprNode(intptr_t token_index,
                      AstNode* condition,
                      AstNode* true_expr,
                      AstNode* false_expr)
      : AstNode(token_index),
        condition_(condition),
        true_expr_(true_expr),
        false_expr_(false_expr) {
      ASSERT(condition_ != NULL);
      ASSERT(true_expr_ != NULL);
      ASSERT(false_expr_ != NULL);
  }

  AstNode* condition() const { return condition_; }
  AstNode* true_expr() const { return true_expr_; }
  AstNode* false_expr() const { return false_expr_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    condition()->Visit(visitor);
    true_expr()->Visit(visitor);
    false_expr()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ConditionalExprNode);

 private:
  AstNode* condition_;
  AstNode* true_expr_;
  AstNode* false_expr_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ConditionalExprNode);
};


class IfNode : public AstNode {
 public:
  IfNode(intptr_t token_index,
         AstNode* condition,
         SequenceNode* true_branch,
         SequenceNode* false_branch)
      : AstNode(token_index),
        condition_(condition),
        true_branch_(true_branch),
        false_branch_(false_branch) {
      ASSERT(condition_ != NULL);
  }

  AstNode* condition() const { return condition_; }
  SequenceNode* true_branch() const { return true_branch_; }
  SequenceNode* false_branch() const { return false_branch_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    condition()->Visit(visitor);
    true_branch()->Visit(visitor);
    if (false_branch() != NULL) {
      false_branch()->Visit(visitor);
    }
  }

  DECLARE_COMMON_NODE_FUNCTIONS(IfNode);

 private:
  AstNode* condition_;
  SequenceNode* true_branch_;
  SequenceNode* false_branch_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(IfNode);
};


class CaseNode : public AstNode {
 public:
  CaseNode(intptr_t token_index,
           SourceLabel* label,
           SequenceNode* case_expressions,
           bool contains_default,
           LocalVariable* switch_expr_value,
           SequenceNode* statements)
    : AstNode(token_index),
      label_(label),
      case_expressions_(case_expressions),
      contains_default_(contains_default),
      switch_expr_value_(switch_expr_value),
      statements_(statements) {
    // label may be NULL.
    ASSERT(case_expressions_ != NULL);
    ASSERT(switch_expr_value_ != NULL);
    ASSERT(statements_ != NULL);
  }

  SourceLabel* label() const { return label_; }
  SequenceNode* case_expressions() const { return case_expressions_; }
  bool contains_default() const { return contains_default_; }
  LocalVariable* switch_expr_value() const { return switch_expr_value_; }
  SequenceNode* statements() const { return statements_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    case_expressions()->Visit(visitor);
    statements()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(CaseNode);

 private:
  SourceLabel* label_;
  SequenceNode* case_expressions_;
  bool contains_default_;
  LocalVariable* switch_expr_value_;
  SequenceNode* statements_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(CaseNode);
};


class SwitchNode : public AstNode {
 public:
  SwitchNode(intptr_t token_index,
             SourceLabel* label,
             SequenceNode* body)
    : AstNode(token_index),
      label_(label),
      body_(body) {
    ASSERT(label_ != NULL);
    ASSERT(body_ != NULL);
  }

  SourceLabel* label() const { return label_; }
  AstNode* body() const { return body_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    body()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(SwitchNode);

 private:
  SourceLabel* label_;
  AstNode* body_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(SwitchNode);
};


class WhileNode : public AstNode {
 public:
  WhileNode(intptr_t token_index,
            SourceLabel* label,
            AstNode* condition,
            SequenceNode* body)
    : AstNode(token_index),
      label_(label),
      condition_(condition),
      body_(body) {
    ASSERT(label_ != NULL);
    ASSERT(condition_ != NULL);
    ASSERT(body_ != NULL);
  }

  SourceLabel* label() const { return label_; }
  AstNode* condition() const { return condition_; }
  SequenceNode* body() const { return body_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    condition()->Visit(visitor);
    body()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(WhileNode);

 private:
  SourceLabel* label_;
  AstNode* condition_;
  SequenceNode* body_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(WhileNode);
};


class DoWhileNode : public AstNode {
 public:
  DoWhileNode(intptr_t token_index,
              SourceLabel* label,
              AstNode* condition,
              SequenceNode* body)
    : AstNode(token_index),
      label_(label),
      condition_(condition),
      body_(body) {
    ASSERT(label_ != NULL);
    ASSERT(condition_ != NULL);
    ASSERT(body_ != NULL);
  }

  SourceLabel* label() const { return label_; }
  AstNode* condition() const { return condition_; }
  SequenceNode* body() const { return body_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    body()->Visit(visitor);
    condition()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(DoWhileNode);

 private:
  SourceLabel* label_;
  AstNode* condition_;
  SequenceNode* body_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(DoWhileNode);
};


// initializer, condition, increment expressions can be NULL.
class ForNode : public AstNode {
 public:
  ForNode(intptr_t token_index,
          SourceLabel* label,
          SequenceNode* initializer,
          AstNode* condition,
          SequenceNode* increment,
          SequenceNode* body)
    : AstNode(token_index),
      label_(label),
      initializer_(initializer),
      condition_(condition),
      increment_(increment),
      body_(body) {
    ASSERT(label_ != NULL);
    ASSERT(initializer_ != NULL);
    ASSERT(increment_ != NULL);
    ASSERT(body_ != NULL);
  }

  SourceLabel* label() const { return label_; }
  SequenceNode* initializer() const { return initializer_; }
  AstNode* condition() const { return condition_; }
  SequenceNode* increment() const { return increment_; }
  SequenceNode* body() const { return body_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    initializer()->Visit(visitor);
    if (condition() != NULL) {
      condition()->Visit(visitor);
    }
    increment()->Visit(visitor);
    body()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ForNode);

 private:
  SourceLabel* label_;
  SequenceNode* initializer_;
  AstNode* condition_;
  SequenceNode* increment_;
  SequenceNode* body_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ForNode);
};


class JumpNode : public AstNode {
 public:
  JumpNode(intptr_t token_index,
           Token::Kind kind,
           SourceLabel* label)
    : AstNode(token_index),
      kind_(kind),
      label_(label),
      inlined_finally_list_(NULL) {
    ASSERT(label_ != NULL);
    ASSERT(kind_ == Token::kBREAK || kind_ == Token::kCONTINUE);
    if (kind_ == Token::kCONTINUE) {
      label_->set_is_continue_target(true);
    }
  }

  SourceLabel* label() const { return label_; }
  Token::Kind kind() const { return kind_; }

  intptr_t inlined_finally_list_length() const {
    return inlined_finally_list_.length();
  }
  InlinedFinallyNode* InlinedFinallyNodeAt(intptr_t index) const {
    return inlined_finally_list_[index];
  }
  void AddInlinedFinallyNode(InlinedFinallyNode* finally_node) {
    inlined_finally_list_.Add(finally_node);
  }

  virtual const char* Name() const;

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  DECLARE_COMMON_NODE_FUNCTIONS(JumpNode);

 private:
  Token::Kind kind_;
  SourceLabel* label_;
  GrowableArray<InlinedFinallyNode*> inlined_finally_list_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(JumpNode);
};


class LoadLocalNode : public AstNode {
 public:
  LoadLocalNode(intptr_t token_index, const LocalVariable& local)
      : AstNode(token_index), local_(local), pseudo_(NULL) { }
  // The pseudo node does not produce input but must be visited before
  // completing local load.
  LoadLocalNode(intptr_t token_index,
                const LocalVariable& local,
                AstNode* pseudo)
      : AstNode(token_index), local_(local), pseudo_(pseudo) {}

  const LocalVariable& local() const { return local_; }
  AstNode* pseudo() const { return pseudo_; }  // Can be NULL.
  bool HasPseudo() const { return pseudo_ != NULL; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    if (HasPseudo()) {
      pseudo()->Visit(visitor);
    }
  }

  virtual AstNode* MakeAssignmentNode(AstNode* rhs);

  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix);

  DECLARE_COMMON_NODE_FUNCTIONS(LoadLocalNode);

 private:
  const LocalVariable& local_;
  AstNode* pseudo_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(LoadLocalNode);
};


class StoreLocalNode : public AstNode {
 public:
  StoreLocalNode(intptr_t token_index,
                 const LocalVariable& local,
                 AstNode* value)
      : AstNode(token_index), local_(local), value_(value) {
    ASSERT(value_ != NULL);
  }

  const LocalVariable& local() const { return local_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StoreLocalNode);

 private:
  const LocalVariable& local_;
  AstNode* value_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StoreLocalNode);
};



class LoadInstanceFieldNode : public AstNode {
 public:
  LoadInstanceFieldNode(intptr_t token_index,
                        AstNode* instance,
                        const Field& field)
      : AstNode(token_index), instance_(instance), field_(field) {
    ASSERT(instance_ != NULL);
    ASSERT(field.IsZoneHandle());
  }

  AstNode* instance() const { return instance_; }
  const Field& field() const { return field_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    instance()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(LoadInstanceFieldNode);

 private:
  AstNode* instance_;
  const Field& field_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(LoadInstanceFieldNode);
};


class StoreInstanceFieldNode : public AstNode {
 public:
  StoreInstanceFieldNode(intptr_t token_index,
                         AstNode* instance,
                         const Field& field,
                         AstNode* value)
      : AstNode(token_index),
        instance_(instance),
        field_(field),
        value_(value) {
    ASSERT(instance_ != NULL);
    ASSERT(field.IsZoneHandle());
    ASSERT(value_ != NULL);
  }

  AstNode* instance() const { return instance_; }
  const Field& field() const { return field_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    instance()->Visit(visitor);
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StoreInstanceFieldNode);

 private:
  AstNode* instance_;
  const Field& field_;
  AstNode* value_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StoreInstanceFieldNode);
};


class LoadStaticFieldNode : public AstNode {
 public:
  LoadStaticFieldNode(intptr_t token_index, const Field& field)
      : AstNode(token_index), field_(field) {
    ASSERT(field.IsZoneHandle());
  }

  const Field& field() const { return field_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  virtual AstNode* MakeAssignmentNode(AstNode* rhs);

  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix);

  virtual const Instance* EvalConstExpr() const {
    ASSERT(field_.is_static());
    return field_.is_final() ? &Instance::ZoneHandle(field_.value()) : NULL;
  }

  DECLARE_COMMON_NODE_FUNCTIONS(LoadStaticFieldNode);

 private:
  const Field& field_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(LoadStaticFieldNode);
};


class StoreStaticFieldNode : public AstNode {
 public:
  StoreStaticFieldNode(intptr_t token_index, const Field& field, AstNode* value)
      : AstNode(token_index), field_(field), value_(value) {
    ASSERT(field.IsZoneHandle());
    ASSERT(value_ != NULL);
  }

  const Field& field() const { return field_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StoreStaticFieldNode);

 private:
  const Field& field_;
  AstNode* value_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StoreStaticFieldNode);
};


class LoadIndexedNode : public AstNode {
 public:
  LoadIndexedNode(intptr_t token_index, AstNode* array, AstNode* index)
      : AstNode(token_index), array_(array), index_expr_(index) {
    ASSERT(array != NULL);
    ASSERT(index != NULL);
  }

  AstNode* array() const { return array_; }
  AstNode* index_expr() const { return index_expr_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    array()->Visit(visitor);
    index_expr()->Visit(visitor);
  }

  virtual AstNode* MakeAssignmentNode(AstNode* rhs);

  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix);

  DECLARE_COMMON_NODE_FUNCTIONS(LoadIndexedNode);

 private:
  AstNode* array_;
  AstNode* index_expr_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(LoadIndexedNode);
};


class StoreIndexedNode : public AstNode {
 public:
  StoreIndexedNode(intptr_t token_index,
                   AstNode* array, AstNode* index, AstNode* value)
    : AstNode(token_index), array_(array), index_expr_(index), value_(value) {
    ASSERT(array != NULL);
    ASSERT(index != NULL);
    ASSERT(value != NULL);
  }

  AstNode* array() const { return array_; }
  AstNode* index_expr() const { return index_expr_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    array()->Visit(visitor);
    index_expr()->Visit(visitor);
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StoreIndexedNode);

 private:
  AstNode* array_;
  AstNode* index_expr_;
  AstNode* value_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(StoreIndexedNode);
};


class InstanceCallNode : public AstNode {
 public:
  InstanceCallNode(intptr_t token_index,
                   AstNode* receiver,
                   const String& function_name,
                   ArgumentListNode* arguments)
      : AstNode(token_index),
        receiver_(receiver),
        function_name_(function_name),
        arguments_(arguments) {
    ASSERT(receiver_ != NULL);
    ASSERT(function_name_.IsZoneHandle());
    ASSERT(function_name_.IsSymbol());
    ASSERT(arguments_ != NULL);
  }

  AstNode* receiver() const { return receiver_; }
  const String& function_name() const { return function_name_; }
  ArgumentListNode* arguments() const { return arguments_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    receiver()->Visit(visitor);
    arguments()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(InstanceCallNode);

 private:
  AstNode* receiver_;
  const String& function_name_;
  ArgumentListNode* arguments_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCallNode);
};


class InstanceGetterNode : public AstNode {
 public:
  InstanceGetterNode(intptr_t token_index,
                     AstNode* receiver,
                     const String& field_name)
      : AstNode(token_index),
        receiver_(receiver),
        field_name_(field_name) {
    ASSERT(receiver_ != NULL);
    ASSERT(field_name_.IsZoneHandle());
    ASSERT(field_name_.IsSymbol());
  }

  AstNode* receiver() const { return receiver_; }
  const String& field_name() const { return field_name_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    receiver()->Visit(visitor);
  }

  virtual AstNode* MakeAssignmentNode(AstNode* rhs);

  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix);

  DECLARE_COMMON_NODE_FUNCTIONS(InstanceGetterNode);

 private:
  AstNode* receiver_;
  const String& field_name_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceGetterNode);
};


class InstanceSetterNode : public AstNode {
 public:
  InstanceSetterNode(intptr_t token_index,
                     AstNode* receiver,
                     const String& field_name,
                     AstNode* value)
      : AstNode(token_index),
        receiver_(receiver),
        field_name_(field_name),
        value_(value) {
    ASSERT(receiver_ != NULL);
    ASSERT(value_ != NULL);
    ASSERT(field_name_.IsZoneHandle());
    ASSERT(field_name_.IsSymbol());
  }

  AstNode* receiver() const { return receiver_; }
  const String& field_name() const { return field_name_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    receiver()->Visit(visitor);
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(InstanceSetterNode);

 private:
  AstNode* receiver_;
  const String& field_name_;
  AstNode* value_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceSetterNode);
};


class StaticGetterNode : public AstNode {
 public:
  StaticGetterNode(intptr_t token_index,
                   const Class& cls,
                   const String& field_name)
      : AstNode(token_index),
        cls_(cls),
        field_name_(field_name) {
    ASSERT(cls_.IsZoneHandle());
    ASSERT(field_name_.IsZoneHandle());
    ASSERT(field_name_.IsSymbol());
  }

  const Class& cls() const { return cls_; }
  const String& field_name() const { return field_name_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  virtual AstNode* MakeAssignmentNode(AstNode* rhs);

  virtual AstNode* MakeIncrOpNode(intptr_t token_index,
                                  Token::Kind kind,
                                  bool is_prefix);

  virtual const Instance* EvalConstExpr() const;

  DECLARE_COMMON_NODE_FUNCTIONS(StaticGetterNode);

 private:
  const Class& cls_;
  const String& field_name_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticGetterNode);
};


class StaticSetterNode : public AstNode {
 public:
  StaticSetterNode(intptr_t token_index,
                   const Class& cls,
                   const String& field_name,
                   AstNode* value)
      : AstNode(token_index),
        cls_(cls),
        field_name_(field_name),
        value_(value) {
    ASSERT(cls_.IsZoneHandle());
    ASSERT(field_name_.IsZoneHandle());
    ASSERT(value != NULL);
  }

  const Class& cls() const { return cls_; }
  const String& field_name() const { return field_name_; }
  AstNode* value() const { return value_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    value()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StaticSetterNode);

 private:
  const Class& cls_;
  const String& field_name_;
  AstNode* value_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticSetterNode);
};


class StaticCallNode : public AstNode {
 public:
  StaticCallNode(intptr_t token_index,
                 const Function& function,
                 ArgumentListNode* arguments)
      : AstNode(token_index),
        function_(function),
        arguments_(arguments) {
    ASSERT(function.IsZoneHandle());
    ASSERT(arguments_ != NULL);
  }

  const Function& function() const { return function_; }
  ArgumentListNode* arguments() const { return arguments_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    arguments()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(StaticCallNode);

 private:
  const Function& function_;
  ArgumentListNode* arguments_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCallNode);
};


class ClosureCallNode : public AstNode {
 public:
  ClosureCallNode(intptr_t token_index,
                  AstNode* closure,
                  ArgumentListNode* arguments)
      : AstNode(token_index),
        closure_(closure),
        arguments_(arguments) {
    ASSERT(closure_ != NULL);
    ASSERT(arguments_ != NULL);
  }

  AstNode* closure() const { return closure_; }
  ArgumentListNode* arguments() const { return arguments_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    closure()->Visit(visitor);
    arguments()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ClosureCallNode);

 private:
  AstNode* closure_;
  ArgumentListNode* arguments_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ClosureCallNode);
};


// There are two kinds of constructor calls: factory calls and constructor
// calls, distinguishable by constructor.IsFactory().
//
// Constructor calls implicitly allocate an object of class constructor.owner(),
// possibly parameterized by type_arguments, which may still be uninstantiated.
// For example, if the type argument T in 'new A<T>()' is not known at compile
// time, it needs to be instantiated at run time. The instantiator and its
// instantiator_class are used to instantiate uninstantiated type arguments
// at run time, as explained below.
//
// Factory calls do not implicitly allocate an object, but receive an implicit
// type argument vector as first parameter, which may still be uninstantiated.
// As in constructor calls, the instantiator and its instantiator_class are used
// to instantiate uninstantiated type arguments at run time.
//
// If the caller to the constructor or to the factory is an instance function,
// the instantiator is the receiver of this function. In order to instantiate T
// in the example above (which could for example be the first type parameter of
// the class of the caller), the code at run time extracts the type arguments of
// the receiver at an offset in the receiver specified by the provided
// instantiator_class.
//
// If the caller to the constructor or to the factory is a factory, then the
// instantiator is the first parameter of this factory, which is already a
// type argument vector. This case is identified by a null and unneeded
// instantiator_class.
class ConstructorCallNode : public AstNode {
 public:
  ConstructorCallNode(intptr_t token_index,
                      const AbstractTypeArguments& type_arguments,
                      const Function& constructor,
                      ArgumentListNode* arguments)
      : AstNode(token_index),
        type_arguments_(type_arguments),
        constructor_(constructor),
        arguments_(arguments) {
    ASSERT(type_arguments_.IsZoneHandle());
    ASSERT(constructor_.IsZoneHandle());
    ASSERT(arguments_ != NULL);
  }

  const AbstractTypeArguments& type_arguments() const {
    return type_arguments_;
  }
  const Function& constructor() const { return constructor_; }
  ArgumentListNode* arguments() const { return arguments_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    arguments()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ConstructorCallNode);

 private:
  const AbstractTypeArguments& type_arguments_;
  const Function& constructor_;
  ArgumentListNode* arguments_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ConstructorCallNode);
};


// The body of a Dart function marked as 'native' consists of this node.
class NativeBodyNode : public AstNode {
 public:
  NativeBodyNode(intptr_t token_index,
                 const String& native_c_function_name,
                 NativeFunction native_c_function,
                 int argument_count,
                 bool has_optional_parameters)
      : AstNode(token_index),
        native_c_function_name_(native_c_function_name),
        native_c_function_(native_c_function),
        argument_count_(argument_count),
        has_optional_parameters_(has_optional_parameters) {
    ASSERT(native_c_function_ != NULL);
    ASSERT(native_c_function_name_.IsZoneHandle());
    ASSERT(native_c_function_name_.IsSymbol());
  }

  const String& native_c_function_name() const {
    return native_c_function_name_;
  }
  NativeFunction native_c_function() const { return native_c_function_; }
  int argument_count() const { return argument_count_; }
  bool has_optional_parameters() const {
    return has_optional_parameters_;
  }

  virtual void VisitChildren(AstNodeVisitor* visitor) const { }

  DECLARE_COMMON_NODE_FUNCTIONS(NativeBodyNode);

 private:
  const String& native_c_function_name_;
  NativeFunction native_c_function_;  // Actual non-Dart implementation.
  const int argument_count_;  // Native Dart function argument count.
  const bool has_optional_parameters_;  // Native Dart function kind.

  DISALLOW_IMPLICIT_CONSTRUCTORS(NativeBodyNode);
};


class CatchClauseNode : public AstNode {
 public:
  static const int kInvalidTryIndex = -1;

  CatchClauseNode(intptr_t token_index,
                  SequenceNode* catch_block,
                  const LocalVariable& context_var,
                  const LocalVariable& exception_var,
                  const LocalVariable& stacktrace_var)
      : AstNode(token_index),
        try_index_(kInvalidTryIndex),
        catch_block_(catch_block),
        context_var_(context_var),
        exception_var_(exception_var),
        stacktrace_var_(stacktrace_var) {
    ASSERT(catch_block != NULL);
  }

  int try_index() const {
    ASSERT(try_index_ >= 0);
    return try_index_;
  }
  void set_try_index(int value) { try_index_ = value; }

  const LocalVariable& context_var() const { return context_var_; }
  const LocalVariable& exception_var() const { return exception_var_; }
  const LocalVariable& stacktrace_var() const { return stacktrace_var_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    catch_block_->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(CatchClauseNode);

 private:
  int try_index_;  // Running index of the try blocks seen in a function.
  SequenceNode* catch_block_;
  const LocalVariable& context_var_;
  const LocalVariable& exception_var_;
  const LocalVariable& stacktrace_var_;

  DISALLOW_COPY_AND_ASSIGN(CatchClauseNode);
};


class TryCatchNode : public AstNode {
 public:
  TryCatchNode(intptr_t token_index,
               SequenceNode* try_block,
               SourceLabel* end_catch_label,
               const LocalVariable& context_var,
               CatchClauseNode* catch_block,
               SequenceNode* finally_block)
      : AstNode(token_index),
        try_block_(try_block),
        end_catch_label_(end_catch_label),
        context_var_(context_var),
        catch_block_(catch_block),
        finally_block_(finally_block) {
    ASSERT(try_block != NULL);
    ASSERT(catch_block != NULL || finally_block != NULL);
    ASSERT(end_catch_label != NULL);
  }

  SequenceNode* try_block() const { return try_block_; }
  SourceLabel* end_catch_label() const { return end_catch_label_; }
  CatchClauseNode* catch_block() const { return catch_block_; }
  SequenceNode* finally_block() const { return finally_block_; }
  const LocalVariable& context_var() const { return context_var_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    try_block_->Visit(visitor);
    if (catch_block_ != NULL) {
      catch_block_->Visit(visitor);
    }
    if (finally_block_ != NULL) {
      finally_block_->Visit(visitor);
    }
  }

  DECLARE_COMMON_NODE_FUNCTIONS(TryCatchNode);

 private:
  SequenceNode* try_block_;
  SourceLabel* end_catch_label_;
  const LocalVariable& context_var_;
  CatchClauseNode* catch_block_;
  SequenceNode* finally_block_;

  DISALLOW_COPY_AND_ASSIGN(TryCatchNode);
};


class ThrowNode : public AstNode {
 public:
  ThrowNode(intptr_t token_index, AstNode* exception, AstNode* stacktrace)
      : AstNode(token_index), exception_(exception), stacktrace_(stacktrace) {
    ASSERT(exception != NULL);
  }

  AstNode* exception() const { return exception_; }
  AstNode* stacktrace() const { return stacktrace_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    exception()->Visit(visitor);
    if (stacktrace() != NULL) {
      stacktrace()->Visit(visitor);
    }
  }

  DECLARE_COMMON_NODE_FUNCTIONS(ThrowNode);
 private:
  AstNode* exception_;
  AstNode* stacktrace_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ThrowNode);
};


class InlinedFinallyNode : public AstNode {
 public:
  InlinedFinallyNode(intptr_t token_index,
                     AstNode* finally_block,
                     const LocalVariable& context_var)
      : AstNode(token_index),
        finally_block_(finally_block),
        context_var_(context_var) {
    ASSERT(finally_block != NULL);
  }

  AstNode* finally_block() const { return finally_block_; }
  const LocalVariable& context_var() const { return context_var_; }

  virtual void VisitChildren(AstNodeVisitor* visitor) const {
    finally_block()->Visit(visitor);
  }

  DECLARE_COMMON_NODE_FUNCTIONS(InlinedFinallyNode);
 private:
  AstNode* finally_block_;
  const LocalVariable& context_var_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(InlinedFinallyNode);
};

}  // namespace dart

#undef DECLARE_COMMON_NODE_FUNCTIONS

#endif  // VM_AST_H_
