// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/object_store.h"
#include "vm/resolver.h"


namespace dart {

#define DEFINE_VISIT_FUNCTION(type, name)                                      \
  void type::Visit(AstNodeVisitor* visitor) {                                  \
    visitor->Visit##type(this);                                                \
  }
NODE_LIST(DEFINE_VISIT_FUNCTION)
#undef DEFINE_VISIT_FUNCTION


#define DEFINE_NAME_FUNCTION(type, name)                                       \
  const char* type::ShortName() const {                                        \
    return name;                                                               \
  }
NODE_LIST(DEFINE_NAME_FUNCTION)
#undef DEFINE_NAME_FUNCTION


// A visitor class to collect all the nodes (including children) into an
// array.
class AstNodeCollector : public AstNodeVisitor {
 public:
  explicit AstNodeCollector(GrowableArray<AstNode*>* nodes)
    : nodes_(nodes) { }

#define DEFINE_VISITOR_FUNCTION(type, name)                                    \
  virtual void Visit##type(type* node) {                                       \
    nodes_->Add(node);                                                         \
    node->VisitChildren(this);                                                 \
  }
NODE_LIST(DEFINE_VISITOR_FUNCTION)
#undef DEFINE_VISITOR_FUNCTION

 private:
  GrowableArray<AstNode*>* nodes_;
  DISALLOW_COPY_AND_ASSIGN(AstNodeCollector);
};


void SequenceNode::CollectAllNodes(GrowableArray<AstNode*>* nodes) {
  AstNodeCollector node_collector(nodes);
  this->Visit(&node_collector);
}


void SequenceNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    NodeAt(i)->Visit(visitor);
  }
}


void PrimaryNode::VisitChildren(AstNodeVisitor* visitor) const {
}


void ArgumentListNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    NodeAt(i)->Visit(visitor);
  }
}


void ArrayNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    ElementAt(i)->Visit(visitor);
  }
}


// TODO(srdjan): Add code for logical negation.
AstNode* LiteralNode::ApplyUnaryOp(Token::Kind unary_op_kind) {
  if (unary_op_kind == Token::kSUB) {
    if (literal().IsSmi()) {
      const Smi& smi = Smi::Cast(literal());
      const Instance& literal =
          Instance::ZoneHandle(Integer::New(-smi.Value()));
      return new LiteralNode(this->token_pos(), literal);
    }
    if (literal().IsDouble()) {
      const Double& dbl = Double::Cast(literal());
      // Preserve negative zero.
      double new_value = (dbl.value() == 0.0) ? -0.0 : (0.0 - dbl.value());
      Double& double_instance =
          Double::ZoneHandle(Double::New(new_value, Heap::kOld));
      double_instance ^= double_instance.Canonicalize();
      return new LiteralNode(this->token_pos(), double_instance);
    }
  }
  return NULL;
}


bool ComparisonNode::IsKindValid() const {
  return Token::IsRelationalOperator(kind_)
      || Token::IsEqualityOperator(kind_)
      || Token::IsTypeTestOperator(kind_)
      || Token::IsTypeCastOperator(kind_);
}


const char* ComparisonNode::Name() const {
  return Token::Str(kind_);
}


const Instance* ComparisonNode::EvalConstExpr() const {
  const Instance* left_val = this->left()->EvalConstExpr();
  if (left_val == NULL) {
    return NULL;
  }
  const Instance* right_val = this->right()->EvalConstExpr();
  if (right_val == NULL) {
    return NULL;
  }
  switch (kind_) {
    case Token::kLT:
    case Token::kGT:
    case Token::kLTE:
    case Token::kGTE:
      if ((left_val->IsNumber() || left_val->IsNull()) &&
          (right_val->IsNumber() || right_val->IsNull())) {
        return &Bool::ZoneHandle(Bool::False());
      }
      return NULL;
    case Token::kEQ:
    case Token::kNE:
    case Token::kEQ_STRICT:
    case Token::kNE_STRICT:
      // The comparison is a compile time const if both operands are either a
      // number, string, or boolean value (but not necessarily the same type).
      if ((left_val->IsNumber() ||
          left_val->IsString() ||
          left_val->IsBool() ||
          left_val->IsNull()) &&
          (right_val->IsNumber() ||
          right_val->IsString() ||
          right_val->IsBool() ||
          right_val->IsNull())) {
        return &Bool::ZoneHandle(Bool::False());
      }
      return NULL;
    default:
      return NULL;
  }
  return NULL;
}



bool BinaryOpNode::IsKindValid() const {
  switch (kind_) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kDIV:
    case Token::kTRUNCDIV:
    case Token::kMOD:
    case Token::kOR:
    case Token::kAND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      return true;
    default:
      return false;
  }
}


const char* BinaryOpNode::Name() const {
  return Token::Str(kind_);
}


const Instance* BinaryOpNode::EvalConstExpr() const {
  const Instance* left_val = this->left()->EvalConstExpr();
  if (left_val == NULL) {
    return NULL;
  }
  if (!left_val->IsNumber() && !left_val->IsBool()) {
    return NULL;
  }
  const Instance* right_val = this->right()->EvalConstExpr();
  if (right_val == NULL) {
    return NULL;
  }
  switch (kind_) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kDIV:
    case Token::kMOD:
    case Token::kTRUNCDIV:
      if (left_val->IsInteger()) {
        if (right_val->IsInteger()) {
          return left_val;
        } else if (right_val->IsNumber()) {
          return right_val;
        }
      } else if (left_val->IsNumber() &&
                 right_val->IsNumber()) {
        return left_val;
      }
      return NULL;
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      if (left_val->IsInteger() &&
          right_val->IsInteger()) {
        return right_val;
      }
      return NULL;
    case Token::kOR:
    case Token::kAND:
      if (left_val->IsBool() && right_val->IsBool()) {
        return left_val;
      }
      return NULL;
    default:
      UNREACHABLE();
      return NULL;
  }
  return NULL;
}


AstNode* UnaryOpNode::UnaryOpOrLiteral(intptr_t token_pos,
                                       Token::Kind kind,
                                       AstNode* operand) {
  AstNode* new_operand = operand->ApplyUnaryOp(kind);
  if (new_operand != NULL) {
    return new_operand;
  }
  return new UnaryOpNode(token_pos, kind, operand);
}


bool UnaryOpNode::IsKindValid() const {
  switch (kind_) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kNOT:
    case Token::kBIT_NOT:
      return true;
    default:
      return false;
  }
}


const Instance* UnaryOpNode::EvalConstExpr() const {
  const Instance* val = this->operand()->EvalConstExpr();
  if (val == NULL) {
    return NULL;
  }
  switch (kind_) {
    case Token::kADD:
    case Token::kSUB:
      return val->IsNumber() ? val : NULL;
    case Token::kNOT:
      return val->IsBool() ? val : NULL;
    case Token::kBIT_NOT:
      return val->IsInteger() ? val : NULL;
    default:
      return NULL;
  }
}


const Instance* ClosureNode::EvalConstExpr() const {
  if (function().IsImplicitStaticClosureFunction()) {
    // Return a value that represents a closure. Only the type is relevant.
    return &Closure::Handle();
  }
  return NULL;
}


const char* UnaryOpNode::Name() const {
  return Token::Str(kind_);
}


const char* JumpNode::Name() const {
  return Token::Str(kind_);
}


AstNode* LoadLocalNode::MakeAssignmentNode(AstNode* rhs) {
  if (local().is_final()) {
    return NULL;
  }
  if (HasPseudo()) {
    return NULL;
  }
  return new StoreLocalNode(token_pos(), &local(), rhs);
}


AstNode* LoadStaticFieldNode::MakeAssignmentNode(AstNode* rhs) {
  return new StoreStaticFieldNode(token_pos(), field(), rhs);
}


AstNode* InstanceGetterNode::MakeAssignmentNode(AstNode* rhs) {
  return new InstanceSetterNode(token_pos(), receiver(), field_name(), rhs);
}


AstNode* LoadIndexedNode::MakeAssignmentNode(AstNode* rhs) {
  return new StoreIndexedNode(token_pos(), array(), index_expr(), rhs);
}


AstNode* StaticGetterNode::MakeAssignmentNode(AstNode* rhs) {
  const String& setter_name = String::Handle(Field::SetterName(field_name()));

  if (is_super_getter_) {
    // Resolve the (dynamic) setter method.
    ASSERT(receiver() != NULL);
    const Function& super_setter = Function::ZoneHandle(
        Resolver::ResolveDynamicAnyArgs(cls(), setter_name));
    if (!super_setter.IsNull()) {
      return new StaticSetterNode(token_pos(),
                                  receiver(),
                                  cls(),
                                  field_name(),
                                  rhs);
    }
    // If setter is found in the superclass, do not turn this into an
    // instance setter resolved at runtime, since a super getter/setter
    // explicitly refers to the static superclass of the enclosing function.
    return NULL;
  } else {
    const Function& setter =
        Function::ZoneHandle(cls().LookupStaticFunction(setter_name));
    if (!setter.IsNull()) {
      return new StaticSetterNode(token_pos(), NULL, cls(), field_name(), rhs);
    }
    // Could not find a static setter. Look for a field.
    // Access to a lazily initialized static field that has not yet been
    // initialized is compiled to a static implicit getter.
    // A setter may not exist for such a field.
    const Field& field =
        Field::ZoneHandle(cls().LookupStaticField(field_name()));
    if (!field.IsNull()) {
#if defined(DEBUG)
      const String& getter_name =
          String::Handle(Field::GetterName(field_name()));
      const Function& getter =
          Function::ZoneHandle(cls().LookupStaticFunction(getter_name));
      ASSERT(!getter.IsNull() &&
             (getter.kind() == RawFunction::kConstImplicitGetter));
#endif
      return new StoreStaticFieldNode(token_pos(), field, rhs);
    }
    // Didn't find a static setter or a static field.
    // If this static getter is in an instance function where
    // a receiver is available, we turn this static getter
    // into an instance setter (and will get an error at runtime if an
    // instance setter cannot be found either).
    if (receiver() != NULL) {
      return new InstanceSetterNode(token_pos(),
                                    receiver(),
                                    field_name(),
                                    rhs);
    }
    return NULL;
  }
}


AstNode* StaticCallNode::MakeAssignmentNode(AstNode* rhs) {
  // Return this node if it represents a 'throw NoSuchMethodError' indicating
  // that a getter was not found, otherwise return null.
  const Class& cls = Class::Handle(function().Owner());
  const String& cls_name = String::Handle(cls.Name());
  const String& func_name = String::Handle(function().name());
  const String& error_cls_name = String::Handle(Symbols::NoSuchMethodError());
  const String& error_func_name = String::Handle(Symbols::ThrowNew());
  if (cls_name.Equals(error_cls_name) &&
      func_name.StartsWith(error_func_name)) {
    return this;
  }
  return NULL;
}


const Instance* StaticGetterNode::EvalConstExpr() const {
  const String& getter_name =
      String::Handle(Field::GetterName(this->field_name()));
  const Function& getter_func =
      Function::Handle(this->cls().LookupStaticFunction(getter_name));
  if (getter_func.IsNull() || !getter_func.is_const()) {
    return NULL;
  }
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle();
  const Object& result =
      Object::Handle(DartEntry::InvokeStatic(getter_func,
                                             arguments,
                                             kNoArgumentNames));
  if (result.IsError() || result.IsNull()) {
    // TODO(turnidge): We could get better error messages by returning
    // the Error object directly to the parser.  This will involve
    // replumbing all of the EvalConstExpr methods.
    return NULL;
  }
  return &Instance::ZoneHandle(Instance::Cast(result).raw());
}

}  // namespace dart
