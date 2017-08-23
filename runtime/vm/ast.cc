// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/resolver.h"

namespace dart {

#define DEFINE_VISIT_FUNCTION(BaseName)                                        \
  void BaseName##Node::Visit(AstNodeVisitor* visitor) {                        \
    visitor->Visit##BaseName##Node(this);                                      \
  }

FOR_EACH_NODE(DEFINE_VISIT_FUNCTION)
#undef DEFINE_VISIT_FUNCTION

#define DEFINE_NAME_FUNCTION(BaseName)                                         \
  const char* BaseName##Node::Name() const { return #BaseName; }

FOR_EACH_NODE(DEFINE_NAME_FUNCTION)
#undef DEFINE_NAME_FUNCTION

const Field* AstNode::MayCloneField(const Field& value) {
  if (Compiler::IsBackgroundCompilation() ||
      FLAG_force_clone_compiler_objects) {
    return &Field::ZoneHandle(value.CloneFromOriginal());
  } else {
    ASSERT(value.IsZoneHandle());
    return &value;
  }
}

// A visitor class to collect all the nodes (including children) into an
// array.
class AstNodeCollector : public AstNodeVisitor {
 public:
  explicit AstNodeCollector(GrowableArray<AstNode*>* nodes) : nodes_(nodes) {}

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

void PrimaryNode::VisitChildren(AstNodeVisitor* visitor) const {}

void ArgumentListNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    NodeAt(i)->Visit(visitor);
  }
}

LetNode::LetNode(TokenPosition token_pos)
    : AstNode(token_pos), vars_(1), initializers_(1), nodes_(1) {}

LocalVariable* LetNode::AddInitializer(AstNode* node) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  initializers_.Add(node);
  char name[64];
  OS::SNPrint(name, sizeof(name), ":lt%s_%" Pd "", token_pos().ToCString(),
              vars_.length());
  LocalVariable* temp_var =
      new LocalVariable(TokenPosition::kNoSource, token_pos(),
                        String::ZoneHandle(zone, Symbols::New(thread, name)),
                        Object::dynamic_type());
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

bool LetNode::IsPotentiallyConst() const {
  for (intptr_t i = 0; i < num_temps(); i++) {
    if (!initializers_[i]->IsPotentiallyConst()) {
      return false;
    }
  }
  for (intptr_t i = 0; i < nodes_.length(); i++) {
    if (!nodes_[i]->IsPotentiallyConst()) {
      return false;
    }
  }
  return true;
}

const Instance* LetNode::EvalConstExpr() const {
  for (intptr_t i = 0; i < num_temps(); i++) {
    if (initializers_[i]->EvalConstExpr() == NULL) {
      return NULL;
    }
  }
  const Instance* last = NULL;
  for (intptr_t i = 0; i < nodes_.length(); i++) {
    last = nodes_[i]->EvalConstExpr();
    if (last == NULL) {
      return NULL;
    }
  }
  return last;
}

void ArrayNode::VisitChildren(AstNodeVisitor* visitor) const {
  for (intptr_t i = 0; i < this->length(); i++) {
    ElementAt(i)->Visit(visitor);
  }
}

bool StringInterpolateNode::IsPotentiallyConst() const {
  for (int i = 0; i < value_->length(); i++) {
    if (!value_->ElementAt(i)->IsPotentiallyConst()) {
      return false;
    }
  }
  return true;
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
  return Token::IsRelationalOperator(kind_) ||
         Token::IsEqualityOperator(kind_) || Token::IsTypeTestOperator(kind_) ||
         Token::IsTypeCastOperator(kind_);
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
      // The comparison is a compile time const if both operands are either a
      // number, string, or boolean value (but not necessarily the same type).
      if ((left_val->IsNumber() || left_val->IsString() || left_val->IsBool() ||
           left_val->IsNull()) &&
          (right_val->IsNumber() || right_val->IsString() ||
           right_val->IsBool() || right_val->IsNull())) {
        return &Bool::False();
      }
      return NULL;
    case Token::kEQ_STRICT:
    case Token::kNE_STRICT:
      // identical(a, b) is a compile time const if both operands are
      // compile time constants, regardless of their type.
      return &Bool::True();
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
    case Token::kIFNULL:
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
    case Token::kIFNULL:
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
  if (!left_val->IsNumber() && !left_val->IsBool() && !left_val->IsString() &&
      kind_ != Token::kIFNULL) {
    return NULL;
  }
  const Instance* right_val = this->right()->EvalConstExpr();
  if (right_val == NULL) {
    return NULL;
  }
  switch (kind_) {
    case Token::kADD:
      if (left_val->IsString()) {
        return right_val->IsString() ? left_val : NULL;
      }
    // Fall-through intentional.
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
      } else if (left_val->IsNumber() && right_val->IsNumber()) {
        return left_val;
      }
      return NULL;
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      if (left_val->IsInteger() && right_val->IsInteger()) {
        return right_val;
      }
      return NULL;
    case Token::kOR:
    case Token::kAND:
      if (left_val->IsBool() && right_val->IsBool()) {
        return left_val;
      }
      return NULL;
    case Token::kIFNULL:
      if (left_val->IsNull()) {
        return right_val;
      }
      return left_val;
    default:
      UNREACHABLE();
      return NULL;
  }
  return NULL;
}

AstNode* UnaryOpNode::UnaryOpOrLiteral(TokenPosition token_pos,
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
  if ((cond != NULL) && cond->IsBool() &&
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
  if (!is_deferred_reference_ && function().IsImplicitStaticClosureFunction()) {
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
    return new StaticSetterNode(token_pos(), receiver(),
                                Class::ZoneHandle(function().Owner()),
                                String::ZoneHandle(function().name()), rhs);
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
  if (Isolate::Current()->type_checks()) {
    rhs = new AssignableNode(field().token_pos(), rhs,
                             AbstractType::ZoneHandle(field().type()),
                             String::ZoneHandle(field().name()));
  }
  return new StoreStaticFieldNode(token_pos(),
                                  Field::ZoneHandle(field().Original()), rhs);
}

AstNode* InstanceGetterNode::MakeAssignmentNode(AstNode* rhs) {
  return new InstanceSetterNode(token_pos(), receiver(), field_name(), rhs,
                                is_conditional());
}

bool InstanceGetterNode::IsPotentiallyConst() const {
  return field_name().Equals(Symbols::Length()) && !is_conditional() &&
         receiver()->IsPotentiallyConst();
}

const Instance* InstanceGetterNode::EvalConstExpr() const {
  if (field_name().Equals(Symbols::Length()) && !is_conditional()) {
    const Instance* receiver_val = receiver()->EvalConstExpr();
    if ((receiver_val != NULL) && receiver_val->IsString()) {
      return &Instance::ZoneHandle(Smi::New(1));
    }
  }
  return NULL;
}

AstNode* LoadIndexedNode::MakeAssignmentNode(AstNode* rhs) {
  return new StoreIndexedNode(token_pos(), array(), index_expr(), rhs,
                              super_class());
}

AstNode* StaticGetterNode::MakeAssignmentNode(AstNode* rhs) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  if (is_super_getter()) {
    ASSERT(receiver() != NULL);
    const String& setter_name =
        String::ZoneHandle(zone, Field::LookupSetterSymbol(field_name_));
    Function& setter = Function::ZoneHandle(zone);
    if (!setter_name.IsNull()) {
      setter = Resolver::ResolveDynamicAnyArgs(zone, cls(), setter_name);
    }
    if (setter.IsNull() || setter.is_abstract()) {
      // No instance setter found in super class chain,
      // noSuchMethod will be called at runtime.
      return new StaticSetterNode(token_pos(), receiver(), cls(), field_name_,
                                  rhs);
    }
    return new StaticSetterNode(token_pos(), receiver(), field_name_, setter,
                                rhs);
  }

  if (owner().IsLibraryPrefix()) {
    const LibraryPrefix& prefix = LibraryPrefix::Cast(owner_);
    // The parser has already dealt with the pathological case where a
    // library imports itself. See Parser::ResolveIdentInPrefixScope()
    ASSERT(field_name_.CharAt(0) != Library::kPrivateIdentifierStart);

    // If the prefix is not yet loaded, the getter doesn't exist. Return a
    // setter that will throw a NSME at runtime.
    if (!prefix.is_loaded()) {
      return new StaticSetterNode(token_pos(), NULL, cls(), field_name_, rhs);
    }

    Object& obj = Object::Handle(zone, prefix.LookupObject(field_name_));
    if (obj.IsField()) {
      const Field& field = Field::ZoneHandle(zone, Field::Cast(obj).raw());
      if (!field.is_final()) {
        if (isolate->type_checks()) {
          rhs = new AssignableNode(field.token_pos(), rhs,
                                   AbstractType::ZoneHandle(zone, field.type()),
                                   field_name_);
        }
        return new StoreStaticFieldNode(token_pos(), field, rhs);
      }
    }

    // No field found in prefix. Look for a setter function.
    const String& setter_name =
        String::Handle(zone, Field::LookupSetterSymbol(field_name_));
    if (!setter_name.IsNull()) {
      obj = prefix.LookupObject(setter_name);
      if (obj.IsFunction()) {
        const Function& setter =
            Function::ZoneHandle(zone, Function::Cast(obj).raw());
        ASSERT(setter.is_static() && setter.IsSetterFunction());
        return new StaticSetterNode(token_pos(), NULL, field_name_, setter,
                                    rhs);
      }
    }

    // No writeable field and no setter found in the prefix. Return a
    // non-existing setter that will throw an NSM error.
    return new StaticSetterNode(token_pos(), NULL, cls(), field_name_, rhs);
  }

  if (owner().IsLibrary()) {
    const Library& library = Library::Cast(owner());
    Object& obj = Object::Handle(zone, library.ResolveName(field_name_));
    if (obj.IsField()) {
      const Field& field = Field::ZoneHandle(zone, Field::Cast(obj).raw());
      if (!field.is_final()) {
        if (isolate->type_checks()) {
          rhs = new AssignableNode(field.token_pos(), rhs,
                                   AbstractType::ZoneHandle(zone, field.type()),
                                   field_name_);
        }
        return new StoreStaticFieldNode(token_pos(), field, rhs);
      }
    }

    // No field found in library. Look for a setter function.
    const String& setter_name =
        String::Handle(zone, Field::LookupSetterSymbol(field_name_));
    if (!setter_name.IsNull()) {
      obj = library.ResolveName(setter_name);
      if (obj.IsFunction()) {
        const Function& setter =
            Function::ZoneHandle(zone, Function::Cast(obj).raw());
        ASSERT(setter.is_static() && setter.IsSetterFunction());
        return new StaticSetterNode(token_pos(), NULL, field_name_, setter,
                                    rhs);
      }
    }

    // No writeable field and no setter found in the library. Return a
    // non-existing setter that will throw an NSM error.
    return new StaticSetterNode(token_pos(), NULL, cls(), field_name_, rhs);
  }

  const Function& setter =
      Function::ZoneHandle(zone, cls().LookupSetterFunction(field_name_));
  if (!setter.IsNull() && setter.IsStaticFunction()) {
    return new StaticSetterNode(token_pos(), NULL, field_name_, setter, rhs);
  }
  // Could not find a static setter. Look for a field.
  // Access to a lazily initialized static field that has not yet been
  // initialized is compiled to a static implicit getter.
  // A setter may not exist for such a field.
  const Field& field =
      Field::ZoneHandle(zone, cls().LookupStaticField(field_name_));
  if (!field.IsNull()) {
    if (field.is_final()) {
      // Attempting to assign to a final variable will cause a NoSuchMethodError
      // to be thrown. Change static getter to non-existent static setter in
      // order to trigger the throw at runtime.
      return new StaticSetterNode(token_pos(), NULL, cls(), field_name_, rhs);
    }
#if defined(DEBUG)
    const String& getter_name =
        String::Handle(zone, Field::LookupGetterSymbol(field_name_));
    ASSERT(!getter_name.IsNull());
    const Function& getter =
        Function::Handle(zone, cls().LookupStaticFunction(getter_name));
    ASSERT(!getter.IsNull() &&
           (getter.kind() == RawFunction::kImplicitStaticFinalGetter));
#endif
    if (isolate->type_checks()) {
      rhs = new AssignableNode(field.token_pos(), rhs,
                               AbstractType::ZoneHandle(zone, field.type()),
                               String::ZoneHandle(zone, field.name()));
    }
    return new StoreStaticFieldNode(token_pos(), field, rhs);
  }
  // Didn't find a static setter or a static field. Make a call to
  // the non-existent setter to trigger a NoSuchMethodError at runtime.
  return new StaticSetterNode(token_pos(), NULL, cls(), field_name_, rhs);
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
      String::Handle(Field::LookupGetterSymbol(this->field_name()));
  if (getter_name.IsNull()) {
    return NULL;
  }
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
