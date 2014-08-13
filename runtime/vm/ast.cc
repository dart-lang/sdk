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

DECLARE_FLAG(bool, enable_type_checks);

#define DEFINE_VISIT_FUNCTION(BaseName)                                        \
void BaseName##Node::Visit(AstNodeVisitor* visitor) {                          \
  visitor->Visit##BaseName##Node(this);                                        \
}

FOR_EACH_NODE(DEFINE_VISIT_FUNCTION)
#undef DEFINE_VISIT_FUNCTION


#define DEFINE_NAME_FUNCTION(BaseName)                                         \
const char* BaseName##Node::PrettyName() const {                               \
  return #BaseName;                                                            \
}

FOR_EACH_NODE(DEFINE_NAME_FUNCTION)
#undef DEFINE_NAME_FUNCTION


// A visitor class to collect all the nodes (including children) into an
// array.
class AstNodeCollector : public AstNodeVisitor {
 public:
  explicit AstNodeCollector(GrowableArray<AstNode*>* nodes)
    : nodes_(nodes) { }

#define DEFINE_VISITOR_FUNCTION(BaseName)                                      \
  virtual void Visit##BaseName##Node(BaseName##Node* node) {                   \
    nodes_->Add(node);                                                         \
    node->VisitChildren(this);                                                 \
  }

FOR_EACH_NODE(DEFINE_VISITOR_FUNCTION)
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


void SequenceNode::Add(AstNode* node) {
  if (node->IsReturnNode()) {
    node->AsReturnNode()->set_scope(scope());
  }
  nodes_.Add(node);
}


void PrimaryNode::VisitChildren(AstNodeVisitor* visitor) const {
}


void ArgumentListNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    NodeAt(i)->Visit(visitor);
  }
}


LetNode::LetNode(intptr_t token_pos)
  : AstNode(token_pos),
    vars_(1),
    initializers_(1),
    nodes_(1) { }


LocalVariable* LetNode::AddInitializer(AstNode* node) {
  initializers_.Add(node);
  char name[64];
  OS::SNPrint(name, sizeof(name), ":lt%" Pd "_%" Pd "",
      token_pos(), vars_.length());
  LocalVariable* temp_var =
      new LocalVariable(token_pos(),
                        String::ZoneHandle(Symbols::New(name)),
                        Type::ZoneHandle(Type::DynamicType()));
  vars_.Add(temp_var);
  return temp_var;
}


void LetNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < num_temps(); ++i) {
    initializers_[i]->Visit(visitor);
  }
  for (intptr_t i = 0; i < nodes_.length(); ++i) {
    nodes_[i]->Visit(visitor);
  }
}


void ArrayNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    ElementAt(i)->Visit(visitor);
  }
}


bool LiteralNode::IsPotentiallyConst() const {
  return true;
}


AstNode* LiteralNode::ApplyUnaryOp(Token::Kind unary_op_kind) {
  if (unary_op_kind == Token::kNEGATE) {
    if (literal().IsSmi()) {
      const Smi& smi = Smi::Cast(literal());
      const Instance& literal =
          Instance::ZoneHandle(Integer::New(-smi.Value(), Heap::kOld));
      return new LiteralNode(this->token_pos(), literal);
    }
    if (literal().IsMint()) {
      const Mint& mint = Mint::Cast(literal());
      const Instance& literal =
          Instance::ZoneHandle(Integer::New(-mint.value(), Heap::kOld));
      return new LiteralNode(this->token_pos(), literal);
    }
    if (literal().IsDouble()) {
      const Double& dbl = Double::Cast(literal());
      // Preserve negative zero.
      double new_value = (dbl.value() == 0.0) ? -0.0 : (0.0 - dbl.value());
      const Double& double_instance =
          Double::ZoneHandle(Double::NewCanonical(new_value));
      return new LiteralNode(this->token_pos(), double_instance);
    }
  } else if (unary_op_kind == Token::kBIT_NOT) {
    if (literal().IsSmi()) {
      const Smi& smi = Smi::Cast(literal());
      const Instance& literal =
          Instance::ZoneHandle(Integer::New(~smi.Value(), Heap::kOld));
      return new LiteralNode(this->token_pos(), literal);
    }
    if (literal().IsMint()) {
      const Mint& mint = Mint::Cast(literal());
      const Instance& literal =
          Instance::ZoneHandle(Integer::New(~mint.value(), Heap::kOld));
      return new LiteralNode(this->token_pos(), literal);
    }
  } else if (unary_op_kind == Token::kNOT) {
    if (literal().IsBool()) {
      const Bool& boolean = Bool::Cast(literal());
      return new LiteralNode(this->token_pos(), Bool::Get(!boolean.value()));
    }
  }
  return NULL;
}


const char* TypeNode::TypeName() const {
  return String::Handle(type().UserVisibleName()).ToCString();
}


bool ComparisonNode::IsKindValid() const {
  return Token::IsRelationalOperator(kind_)
      || Token::IsEqualityOperator(kind_)
      || Token::IsTypeTestOperator(kind_)
      || Token::IsTypeCastOperator(kind_);
}


const char* ComparisonNode::TokenName() const {
  return (kind_ == Token::kAS) ? "as" : Token::Str(kind_);
}


bool ComparisonNode::IsPotentiallyConst() const {
  switch (kind_) {
    case Token::kLT:
    case Token::kGT:
    case Token::kLTE:
    case Token::kGTE:
    case Token::kEQ:
    case Token::kNE:
    case Token::kEQ_STRICT:
    case Token::kNE_STRICT:
      return this->left()->IsPotentiallyConst() &&
          this->right()->IsPotentiallyConst();
    default:
      return false;
  }
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
        return &Bool::False();
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
        return &Bool::False();
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


const char* BinaryOpNode::TokenName() const {
  return Token::Str(kind_);
}


const char* BinaryOpWithMask32Node::TokenName() const {
  return Token::Str(kind());
}


bool BinaryOpNode::IsPotentiallyConst() const {
  switch (kind_) {
    case Token::kOR:
    case Token::kAND:
      if (this->left()->IsLiteralNode() &&
          this->left()->AsLiteralNode()->literal().IsNull()) {
        return false;
      }
      if (this->right()->IsLiteralNode() &&
          this->right()->AsLiteralNode()->literal().IsNull()) {
        return false;
      }
      // Fall-through intentional.
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kDIV:
    case Token::kMOD:
    case Token::kTRUNCDIV:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      return this->left()->IsPotentiallyConst() &&
          this->right()->IsPotentiallyConst();
    default:
      UNREACHABLE();
      return false;
  }
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
    case Token::kNEGATE:
    case Token::kNOT:
    case Token::kBIT_NOT:
      return true;
    default:
      return false;
  }
}


bool UnaryOpNode::IsPotentiallyConst() const {
  if (this->operand()->IsLiteralNode() &&
      this->operand()->AsLiteralNode()->literal().IsNull()) {
    return false;
  }
  return this->operand()->IsPotentiallyConst();
}


const Instance* UnaryOpNode::EvalConstExpr() const {
  const Instance* val = this->operand()->EvalConstExpr();
  if (val == NULL) {
    return NULL;
  }
  switch (kind_) {
    case Token::kNEGATE:
      return val->IsNumber() ? val : NULL;
    case Token::kNOT:
      return val->IsBool() ? val : NULL;
    case Token::kBIT_NOT:
      return val->IsInteger() ? val : NULL;
    default:
      return NULL;
  }
}


bool ConditionalExprNode::IsPotentiallyConst() const {
  return this->condition()->IsPotentiallyConst() &&
    this->true_expr()->IsPotentiallyConst() &&
    this->false_expr()->IsPotentiallyConst();
}


const Instance* ConditionalExprNode::EvalConstExpr() const {
  const Instance* cond = this->condition()->EvalConstExpr();
  if ((cond != NULL) &&
      cond->IsBool() &&
      (this->true_expr()->EvalConstExpr() != NULL) &&
      (this->false_expr()->EvalConstExpr() != NULL)) {
    return cond;
  }
  return NULL;
}


bool ClosureNode::IsPotentiallyConst() const {
  if (function().IsImplicitStaticClosureFunction()) {
    return true;
  }
  return false;
}


const Instance* ClosureNode::EvalConstExpr() const {
  if (!is_deferred_reference_ &&
      function().IsImplicitStaticClosureFunction()) {
    // Return a value that represents an instance. Only the type is relevant.
    return &Instance::Handle();
  }
  return NULL;
}


AstNode* ClosureNode::MakeAssignmentNode(AstNode* rhs) {
  if (scope() == NULL) {
    // This is an implicit closure node created because a static getter was not
    // found. Change the getter into a setter. If it does not exist,
    // noSuchMethod will be called.
    return new StaticSetterNode(token_pos(),
                                receiver(),
                                Class::ZoneHandle(function().Owner()),
                                String::ZoneHandle(function().name()),
                                rhs);
  }
  return NULL;
}


const char* UnaryOpNode::TokenName() const {
  return Token::Str(kind_);
}


const char* JumpNode::TokenName() const {
  return Token::Str(kind_);
}


bool LoadLocalNode::IsPotentiallyConst() const {
  // Parameters of const constructors are implicitly final and can be
  // used in initializer expressions.
  // We can't check here whether the local variable is indeed a parameter,
  // but this code is executed before any other local variables are
  // added to the scope.
  return local().is_final();
}


const Instance* LoadLocalNode::EvalConstExpr() const {
  if (local().IsConst()) {
    return local().ConstValue();
  }
  return NULL;
}


AstNode* LoadLocalNode::MakeAssignmentNode(AstNode* rhs) {
  if (local().is_final()) {
    return NULL;
  }
  return new StoreLocalNode(token_pos(), &local(), rhs);
}


AstNode* LoadStaticFieldNode::MakeAssignmentNode(AstNode* rhs) {
  if (field().is_final()) {
    return NULL;
  }
  if (FLAG_enable_type_checks) {
    rhs = new AssignableNode(
        field().token_pos(),
        rhs,
        AbstractType::ZoneHandle(field().type()),
        String::ZoneHandle(field().name()));
  }
  return new StoreStaticFieldNode(token_pos(), field(), rhs);
}


AstNode* InstanceGetterNode::MakeAssignmentNode(AstNode* rhs) {
  return new InstanceSetterNode(token_pos(), receiver(), field_name(), rhs);
}


AstNode* LoadIndexedNode::MakeAssignmentNode(AstNode* rhs) {
  return new StoreIndexedNode(token_pos(), array(), index_expr(),
                              rhs, super_class());
}


AstNode* StaticGetterNode::MakeAssignmentNode(AstNode* rhs) {
  const String& setter_name = String::Handle(Field::SetterName(field_name()));

  if (is_super_getter_) {
    ASSERT(receiver() != NULL);
    // If the static setter is not found in the superclass, noSuchMethod will be
    // called at runtime.
    return new StaticSetterNode(token_pos(),
                                receiver(),
                                cls(),
                                field_name(),
                                rhs);
  }
  const Function& setter =
      Function::ZoneHandle(cls().LookupStaticFunction(setter_name));
  if (!setter.IsNull()) {
    return new StaticSetterNode(token_pos(), NULL, cls(), field_name(), rhs);
  }
  // Could not find a static setter. Look for a field.
  // Access to a lazily initialized static field that has not yet been
  // initialized is compiled to a static implicit getter.
  // A setter may not exist for such a field.
  const Field& field = Field::ZoneHandle(cls().LookupStaticField(field_name()));
  if (!field.IsNull()) {
    if (field.is_final()) {
      // Attempting to assign to a final variable will cause a NoSuchMethodError
      // to be thrown. Change static getter to non-existent static setter in
      // order to trigger the throw at runtime.
      return new StaticSetterNode(token_pos(), NULL, cls(), field_name(), rhs);
    }
#if defined(DEBUG)
    const String& getter_name = String::Handle(Field::GetterName(field_name()));
    const Function& getter =
        Function::Handle(cls().LookupStaticFunction(getter_name));
    ASSERT(!getter.IsNull() &&
           (getter.kind() == RawFunction::kImplicitStaticFinalGetter));
#endif
    if (FLAG_enable_type_checks) {
      rhs = new AssignableNode(
          field.token_pos(),
          rhs,
          AbstractType::ZoneHandle(field.type()),
          String::ZoneHandle(field.name()));
    }
    return new StoreStaticFieldNode(token_pos(), field, rhs);
  }
  // Didn't find a static setter or a static field.
  // If this static getter is in an instance function where
  // a receiver is available, we turn this static getter
  // into an instance setter (and will get an error at runtime if an
  // instance setter cannot be found either).
  if (receiver() != NULL) {
    return new InstanceSetterNode(token_pos(), receiver(), field_name(), rhs);
  }
  return new StaticSetterNode(token_pos(), NULL, cls(), field_name(), rhs);
}


AstNode* StaticCallNode::MakeAssignmentNode(AstNode* rhs) {
  // Return this node if it represents a 'throw NoSuchMethodError' indicating
  // that a getter was not found, otherwise return null.
  const Class& cls = Class::Handle(function().Owner());
  const String& cls_name = String::Handle(cls.Name());
  const String& func_name = String::Handle(function().name());
  if (cls_name.Equals(Symbols::NoSuchMethodError()) &&
      func_name.StartsWith(Symbols::ThrowNew())) {
    return this;
  }
  return NULL;
}


bool StaticGetterNode::IsPotentiallyConst() const {
  if (is_deferred_reference_) {
    return false;
  }
  const String& getter_name =
      String::Handle(Field::GetterName(this->field_name()));
  const Function& getter_func =
      Function::Handle(this->cls().LookupStaticFunction(getter_name));
  if (getter_func.IsNull() || !getter_func.is_const()) {
    return false;
  }
  return true;
}


const Instance* StaticGetterNode::EvalConstExpr() const {
  if (is_deferred_reference_) {
    return NULL;
  }
  const String& getter_name =
      String::Handle(Field::GetterName(this->field_name()));
  const Function& getter_func =
      Function::Handle(this->cls().LookupStaticFunction(getter_name));
  if (getter_func.IsNull() || !getter_func.is_const()) {
    return NULL;
  }
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(getter_func, Object::empty_array()));
  if (result.IsError() || result.IsNull()) {
    // TODO(turnidge): We could get better error messages by returning
    // the Error object directly to the parser.  This will involve
    // replumbing all of the EvalConstExpr methods.
    return NULL;
  }
  return &Instance::ZoneHandle(Instance::Cast(result).raw());
}

}  // namespace dart
