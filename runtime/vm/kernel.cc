// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {

namespace kernel {


Source::~Source() {
  delete[] uri_;
  delete[] source_code_;
  delete[] line_starts_;
}


SourceTable::~SourceTable() {
  delete[] sources_;
}


Node::~Node() {}


TreeNode::~TreeNode() {}


LinkedNode::~LinkedNode() {}


Library::~Library() {}


LibraryDependency::~LibraryDependency() {}


Combinator::~Combinator() {}


Typedef::~Typedef() {}


Class::~Class() {}


NormalClass::~NormalClass() {}


Member::~Member() {}


Field::~Field() {}


Constructor::~Constructor() {}


Procedure::~Procedure() {}


Initializer::~Initializer() {}


InvalidInitializer::~InvalidInitializer() {}


FieldInitializer::~FieldInitializer() {}


SuperInitializer::~SuperInitializer() {}


RedirectingInitializer::~RedirectingInitializer() {}


LocalInitializer::~LocalInitializer() {}


FunctionNode::~FunctionNode() {}


void FunctionNode::ReplaceBody(Statement* body) {
  delete body_;
  // Use static_cast to invoke the conversion function and so avoid triggering
  // ASSERT(pointer_ == NULL) in operator= when overwriting a non-NULL body.
  static_cast<Statement*&>(body_) = body;
}


Expression::~Expression() {}


InvalidExpression::~InvalidExpression() {}


void InvalidExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitInvalidExpression(this);
}



VariableGet::~VariableGet() {}


void VariableGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVariableGet(this);
}


VariableSet::~VariableSet() {}


void VariableSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVariableSet(this);
}


PropertyGet::~PropertyGet() {}


void PropertyGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitPropertyGet(this);
}


PropertySet::~PropertySet() {}


void PropertySet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitPropertySet(this);
}


DirectPropertyGet::~DirectPropertyGet() {}


void DirectPropertyGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitDirectPropertyGet(this);
}


DirectPropertySet::~DirectPropertySet() {}


void DirectPropertySet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitDirectPropertySet(this);
}


StaticGet::~StaticGet() {}


void StaticGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticGet(this);
}


StaticSet::~StaticSet() {}


void StaticSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticSet(this);
}


Arguments::~Arguments() {}


NamedExpression::~NamedExpression() {}


MethodInvocation::~MethodInvocation() {}


void MethodInvocation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitMethodInvocation(this);
}


DirectMethodInvocation::~DirectMethodInvocation() {}


void DirectMethodInvocation::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitDirectMethodInvocation(this);
}


StaticInvocation::~StaticInvocation() {}


void StaticInvocation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticInvocation(this);
}


ConstructorInvocation::~ConstructorInvocation() {}


void ConstructorInvocation::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitConstructorInvocation(this);
}


Not::~Not() {}


void Not::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitNot(this);
}


LogicalExpression::~LogicalExpression() {}


void LogicalExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitLogicalExpression(this);
}


ConditionalExpression::~ConditionalExpression() {}


void ConditionalExpression::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitConditionalExpression(this);
}


StringConcatenation::~StringConcatenation() {}


void StringConcatenation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStringConcatenation(this);
}


IsExpression::~IsExpression() {}


void IsExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitIsExpression(this);
}


AsExpression::~AsExpression() {}


void AsExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitAsExpression(this);
}


BasicLiteral::~BasicLiteral() {}


StringLiteral::~StringLiteral() {}


void StringLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStringLiteral(this);
}


BigintLiteral::~BigintLiteral() {}


void BigintLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitBigintLiteral(this);
}


IntLiteral::~IntLiteral() {}


void IntLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitIntLiteral(this);
}


DoubleLiteral::~DoubleLiteral() {}


void DoubleLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitDoubleLiteral(this);
}


BoolLiteral::~BoolLiteral() {}


void BoolLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitBoolLiteral(this);
}


NullLiteral::~NullLiteral() {}


void NullLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitNullLiteral(this);
}


SymbolLiteral::~SymbolLiteral() {}


void SymbolLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitSymbolLiteral(this);
}


TypeLiteral::~TypeLiteral() {}


void TypeLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitTypeLiteral(this);
}


ThisExpression::~ThisExpression() {}


void ThisExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitThisExpression(this);
}


Rethrow::~Rethrow() {}


void Rethrow::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitRethrow(this);
}


Throw::~Throw() {}


void Throw::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitThrow(this);
}


ListLiteral::~ListLiteral() {}


void ListLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitListLiteral(this);
}


MapLiteral::~MapLiteral() {}


void MapLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitMapLiteral(this);
}


MapEntry::~MapEntry() {}


AwaitExpression::~AwaitExpression() {}


void AwaitExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitAwaitExpression(this);
}


FunctionExpression::~FunctionExpression() {}


void FunctionExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitFunctionExpression(this);
}


Let::~Let() {}


void Let::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitLet(this);
}


VectorCreation::~VectorCreation() {}


void VectorCreation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorCreation(this);
}


VectorGet::~VectorGet() {}


void VectorGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorGet(this);
}


VectorSet::~VectorSet() {}


void VectorSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorSet(this);
}


VectorCopy::~VectorCopy() {}


void VectorCopy::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorCopy(this);
}


ClosureCreation::~ClosureCreation() {}


void ClosureCreation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitClosureCreation(this);
}


Statement::~Statement() {}


InvalidStatement::~InvalidStatement() {}


ExpressionStatement::~ExpressionStatement() {}


Block::~Block() {}


EmptyStatement::~EmptyStatement() {}


AssertStatement::~AssertStatement() {}


LabeledStatement::~LabeledStatement() {}


BreakStatement::~BreakStatement() {}


WhileStatement::~WhileStatement() {}


DoStatement::~DoStatement() {}


ForStatement::~ForStatement() {}


ForInStatement::~ForInStatement() {}


SwitchStatement::~SwitchStatement() {}


SwitchCase::~SwitchCase() {}


ContinueSwitchStatement::~ContinueSwitchStatement() {}


IfStatement::~IfStatement() {}


ReturnStatement::~ReturnStatement() {}


TryCatch::~TryCatch() {}


Catch::~Catch() {}


TryFinally::~TryFinally() {}


YieldStatement::~YieldStatement() {}


VariableDeclaration::~VariableDeclaration() {}


FunctionDeclaration::~FunctionDeclaration() {}


Name::~Name() {}


DartType::~DartType() {}


InvalidType::~InvalidType() {}


void InvalidType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitInvalidType(this);
}


DynamicType::~DynamicType() {}


void DynamicType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitDynamicType(this);
}


VoidType::~VoidType() {}


void VoidType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitVoidType(this);
}


BottomType::~BottomType() {}


void BottomType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitBottomType(this);
}


InterfaceType::~InterfaceType() {}


void InterfaceType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitInterfaceType(this);
}


TypedefType::~TypedefType() {}


void TypedefType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitTypedefType(this);
}


FunctionType::~FunctionType() {}


void FunctionType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitFunctionType(this);
}


TypeParameterType::~TypeParameterType() {}


void TypeParameterType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitTypeParameterType(this);
}


VectorType::~VectorType() {}


void VectorType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitVectorType(this);
}


TypeParameter::~TypeParameter() {}


Program::~Program() {
  while (valid_token_positions.length() > 0) {
    delete valid_token_positions.RemoveLast();
  }
  while (yield_token_positions.length() > 0) {
    delete yield_token_positions.RemoveLast();
  }
}


}  // namespace kernel

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
