// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {

namespace kernel {


template <typename T>
void VisitList(List<T>* list, Visitor* visitor) {
  for (int i = 0; i < list->length(); ++i) {
    (*list)[i]->AcceptVisitor(visitor);
  }
}


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


void TreeNode::AcceptVisitor(Visitor* visitor) {
  AcceptTreeVisitor(visitor);
}


LinkedNode::~LinkedNode() {}


Library::~Library() {}


void Library::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitLibrary(this);
}


void Library::VisitChildren(Visitor* visitor) {
  VisitList(&typedefs(), visitor);
  VisitList(&classes(), visitor);
  VisitList(&procedures(), visitor);
  VisitList(&fields(), visitor);
}


LibraryDependency::~LibraryDependency() {}


Combinator::~Combinator() {}


Typedef::~Typedef() {}


void Typedef::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitTypedef(this);
}


void Typedef::VisitChildren(Visitor* visitor) {
  VisitList(&type_parameters(), visitor);
  type()->AcceptDartTypeVisitor(visitor);
}


Class::~Class() {}


void Class::AcceptTreeVisitor(TreeVisitor* visitor) {
  AcceptClassVisitor(visitor);
}


NormalClass::~NormalClass() {}


void NormalClass::AcceptClassVisitor(ClassVisitor* visitor) {
  visitor->VisitNormalClass(this);
}


void NormalClass::VisitChildren(Visitor* visitor) {
  VisitList(&type_parameters(), visitor);
  if (super_class() != NULL) visitor->VisitInterfaceType(super_class());
  VisitList(&implemented_classes(), visitor);
  VisitList(&constructors(), visitor);
  VisitList(&procedures(), visitor);
  VisitList(&fields(), visitor);
}


MixinClass::~MixinClass() {}


void MixinClass::AcceptClassVisitor(ClassVisitor* visitor) {
  visitor->VisitMixinClass(this);
}


void MixinClass::VisitChildren(Visitor* visitor) {
  VisitList(&type_parameters(), visitor);
  visitor->VisitInterfaceType(first());
  visitor->VisitInterfaceType(second());
  VisitList(&implemented_classes(), visitor);
  VisitList(&constructors(), visitor);
}


Member::~Member() {}


void Member::AcceptTreeVisitor(TreeVisitor* visitor) {
  AcceptMemberVisitor(visitor);
}


Field::~Field() {}


void Field::AcceptMemberVisitor(MemberVisitor* visitor) {
  visitor->VisitField(this);
}


void Field::VisitChildren(Visitor* visitor) {
  type()->AcceptDartTypeVisitor(visitor);
  visitor->VisitName(name());
  if (initializer() != NULL) initializer()->AcceptExpressionVisitor(visitor);
}


Constructor::~Constructor() {}


void Constructor::AcceptMemberVisitor(MemberVisitor* visitor) {
  visitor->VisitConstructor(this);
}


void Constructor::VisitChildren(Visitor* visitor) {
  visitor->VisitName(name());
  visitor->VisitFunctionNode(function());
  VisitList(&initializers(), visitor);
}


Procedure::~Procedure() {}


void Procedure::AcceptMemberVisitor(MemberVisitor* visitor) {
  visitor->VisitProcedure(this);
}


void Procedure::VisitChildren(Visitor* visitor) {
  visitor->VisitName(name());
  if (function() != NULL) visitor->VisitFunctionNode(function());
}


Initializer::~Initializer() {}


void Initializer::AcceptTreeVisitor(TreeVisitor* visitor) {
  AcceptInitializerVisitor(visitor);
}


InvalidInitializer::~InvalidInitializer() {}


void InvalidInitializer::AcceptInitializerVisitor(InitializerVisitor* visitor) {
  visitor->VisitInvalidInitializer(this);
}


void InvalidInitializer::VisitChildren(Visitor* visitor) {}


FieldInitializer::~FieldInitializer() {}


void FieldInitializer::AcceptInitializerVisitor(InitializerVisitor* visitor) {
  visitor->VisitFieldInitializer(this);
}


void FieldInitializer::VisitChildren(Visitor* visitor) {
  value()->AcceptExpressionVisitor(visitor);
}


SuperInitializer::~SuperInitializer() {}


void SuperInitializer::AcceptInitializerVisitor(InitializerVisitor* visitor) {
  visitor->VisitSuperInitializer(this);
}


void SuperInitializer::VisitChildren(Visitor* visitor) {
  visitor->VisitArguments(arguments());
}


RedirectingInitializer::~RedirectingInitializer() {}


void RedirectingInitializer::AcceptInitializerVisitor(
    InitializerVisitor* visitor) {
  visitor->VisitRedirectingInitializer(this);
}


void RedirectingInitializer::VisitChildren(Visitor* visitor) {
  visitor->VisitArguments(arguments());
}


LocalInitializer::~LocalInitializer() {}


void LocalInitializer::AcceptInitializerVisitor(InitializerVisitor* visitor) {
  visitor->VisitLocalInitializer(this);
}


void LocalInitializer::VisitChildren(Visitor* visitor) {
  visitor->VisitVariableDeclaration(variable());
}


FunctionNode::~FunctionNode() {}


void FunctionNode::ReplaceBody(Statement* body) {
  delete body_;
  // Use static_cast to invoke the conversion function and so avoid triggering
  // ASSERT(pointer_ == NULL) in operator= when overwriting a non-NULL body.
  static_cast<Statement*&>(body_) = body;
}


void FunctionNode::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitFunctionNode(this);
}


void FunctionNode::VisitChildren(Visitor* visitor) {
  VisitList(&type_parameters(), visitor);
  VisitList(&positional_parameters(), visitor);
  VisitList(&named_parameters(), visitor);
  if (return_type() != NULL) return_type()->AcceptDartTypeVisitor(visitor);
  if (body() != NULL) body()->AcceptStatementVisitor(visitor);
}


Expression::~Expression() {}


void Expression::AcceptTreeVisitor(TreeVisitor* visitor) {
  AcceptExpressionVisitor(visitor);
}


InvalidExpression::~InvalidExpression() {}


void InvalidExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitInvalidExpression(this);
}


void InvalidExpression::VisitChildren(Visitor* visitor) {}


VariableGet::~VariableGet() {}


void VariableGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVariableGet(this);
}


void VariableGet::VisitChildren(Visitor* visitor) {}


VariableSet::~VariableSet() {}


void VariableSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVariableSet(this);
}


void VariableSet::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


PropertyGet::~PropertyGet() {}


void PropertyGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitPropertyGet(this);
}


void PropertyGet::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
  visitor->VisitName(name());
}


PropertySet::~PropertySet() {}


void PropertySet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitPropertySet(this);
}


void PropertySet::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
  visitor->VisitName(name());
  value()->AcceptExpressionVisitor(visitor);
}


DirectPropertyGet::~DirectPropertyGet() {}


void DirectPropertyGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitDirectPropertyGet(this);
}


void DirectPropertyGet::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
}


DirectPropertySet::~DirectPropertySet() {}


void DirectPropertySet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitDirectPropertySet(this);
}


void DirectPropertySet::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
  value()->AcceptExpressionVisitor(visitor);
}


StaticGet::~StaticGet() {}


void StaticGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticGet(this);
}


void StaticGet::VisitChildren(Visitor* visitor) {}


StaticSet::~StaticSet() {}


void StaticSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticSet(this);
}


void StaticSet::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


Arguments::~Arguments() {}


void Arguments::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitArguments(this);
}


void Arguments::VisitChildren(Visitor* visitor) {
  VisitList(&types(), visitor);
  VisitList(&positional(), visitor);
  VisitList(&named(), visitor);
}


NamedExpression::~NamedExpression() {}


void NamedExpression::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitNamedExpression(this);
}


void NamedExpression::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


MethodInvocation::~MethodInvocation() {}


void MethodInvocation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitMethodInvocation(this);
}


void MethodInvocation::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
  visitor->VisitName(name());
  visitor->VisitArguments(arguments());
}


DirectMethodInvocation::~DirectMethodInvocation() {}


void DirectMethodInvocation::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitDirectMethodInvocation(this);
}


void DirectMethodInvocation::VisitChildren(Visitor* visitor) {
  receiver()->AcceptExpressionVisitor(visitor);
  visitor->VisitArguments(arguments());
}


StaticInvocation::~StaticInvocation() {}


void StaticInvocation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStaticInvocation(this);
}


void StaticInvocation::VisitChildren(Visitor* visitor) {
  visitor->VisitArguments(arguments());
}


ConstructorInvocation::~ConstructorInvocation() {}


void ConstructorInvocation::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitConstructorInvocation(this);
}


void ConstructorInvocation::VisitChildren(Visitor* visitor) {
  visitor->VisitArguments(arguments());
}


Not::~Not() {}


void Not::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitNot(this);
}


void Not::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


LogicalExpression::~LogicalExpression() {}


void LogicalExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitLogicalExpression(this);
}


void LogicalExpression::VisitChildren(Visitor* visitor) {
  left()->AcceptExpressionVisitor(visitor);
  right()->AcceptExpressionVisitor(visitor);
}


ConditionalExpression::~ConditionalExpression() {}


void ConditionalExpression::AcceptExpressionVisitor(
    ExpressionVisitor* visitor) {
  visitor->VisitConditionalExpression(this);
}


void ConditionalExpression::VisitChildren(Visitor* visitor) {
  condition()->AcceptExpressionVisitor(visitor);
  then()->AcceptExpressionVisitor(visitor);
  otherwise()->AcceptExpressionVisitor(visitor);
}


StringConcatenation::~StringConcatenation() {}


void StringConcatenation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitStringConcatenation(this);
}


void StringConcatenation::VisitChildren(Visitor* visitor) {
  VisitList(&expressions(), visitor);
}


IsExpression::~IsExpression() {}


void IsExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitIsExpression(this);
}


void IsExpression::VisitChildren(Visitor* visitor) {
  operand()->AcceptExpressionVisitor(visitor);
  type()->AcceptDartTypeVisitor(visitor);
}


AsExpression::~AsExpression() {}


void AsExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitAsExpression(this);
}


void AsExpression::VisitChildren(Visitor* visitor) {
  operand()->AcceptExpressionVisitor(visitor);
  type()->AcceptDartTypeVisitor(visitor);
}


BasicLiteral::~BasicLiteral() {}


void BasicLiteral::VisitChildren(Visitor* visitor) {}


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


void SymbolLiteral::VisitChildren(Visitor* visitor) {}


TypeLiteral::~TypeLiteral() {}


void TypeLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitTypeLiteral(this);
}


void TypeLiteral::VisitChildren(Visitor* visitor) {
  type()->AcceptDartTypeVisitor(visitor);
}


ThisExpression::~ThisExpression() {}


void ThisExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitThisExpression(this);
}


void ThisExpression::VisitChildren(Visitor* visitor) {}


Rethrow::~Rethrow() {}


void Rethrow::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitRethrow(this);
}


void Rethrow::VisitChildren(Visitor* visitor) {}


Throw::~Throw() {}


void Throw::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitThrow(this);
}


void Throw::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


ListLiteral::~ListLiteral() {}


void ListLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitListLiteral(this);
}


void ListLiteral::VisitChildren(Visitor* visitor) {
  type()->AcceptDartTypeVisitor(visitor);
  VisitList(&expressions(), visitor);
}


MapLiteral::~MapLiteral() {}


void MapLiteral::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitMapLiteral(this);
}


void MapLiteral::VisitChildren(Visitor* visitor) {
  key_type()->AcceptDartTypeVisitor(visitor);
  value_type()->AcceptDartTypeVisitor(visitor);
  VisitList(&entries(), visitor);
}


MapEntry::~MapEntry() {}


void MapEntry::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitMapEntry(this);
}


void MapEntry::VisitChildren(Visitor* visitor) {
  key()->AcceptExpressionVisitor(visitor);
  value()->AcceptExpressionVisitor(visitor);
}


AwaitExpression::~AwaitExpression() {}


void AwaitExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitAwaitExpression(this);
}


void AwaitExpression::VisitChildren(Visitor* visitor) {
  operand()->AcceptExpressionVisitor(visitor);
}


FunctionExpression::~FunctionExpression() {}


void FunctionExpression::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitFunctionExpression(this);
}


void FunctionExpression::VisitChildren(Visitor* visitor) {
  visitor->VisitFunctionNode(function());
}


Let::~Let() {}


void Let::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitLet(this);
}


void Let::VisitChildren(Visitor* visitor) {
  visitor->VisitVariableDeclaration(variable());
  body()->AcceptExpressionVisitor(visitor);
}


VectorCreation::~VectorCreation() {}


void VectorCreation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorCreation(this);
}


void VectorCreation::VisitChildren(Visitor* visitor) {}


VectorGet::~VectorGet() {}


void VectorGet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorGet(this);
}


void VectorGet::VisitChildren(Visitor* visitor) {
  vector_expression()->AcceptExpressionVisitor(visitor);
}


VectorSet::~VectorSet() {}


void VectorSet::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorSet(this);
}


void VectorSet::VisitChildren(Visitor* visitor) {
  vector_expression()->AcceptExpressionVisitor(visitor);
  value()->AcceptExpressionVisitor(visitor);
}


VectorCopy::~VectorCopy() {}


void VectorCopy::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitVectorCopy(this);
}


void VectorCopy::VisitChildren(Visitor* visitor) {
  vector_expression()->AcceptExpressionVisitor(visitor);
}


ClosureCreation::~ClosureCreation() {}


void ClosureCreation::AcceptExpressionVisitor(ExpressionVisitor* visitor) {
  visitor->VisitClosureCreation(this);
}


void ClosureCreation::VisitChildren(Visitor* visitor) {
  context_vector()->AcceptExpressionVisitor(visitor);
  function_type()->AcceptDartTypeVisitor(visitor);
}


Statement::~Statement() {}


void Statement::AcceptTreeVisitor(TreeVisitor* visitor) {
  AcceptStatementVisitor(visitor);
}


InvalidStatement::~InvalidStatement() {}


void InvalidStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitInvalidStatement(this);
}


void InvalidStatement::VisitChildren(Visitor* visitor) {}


ExpressionStatement::~ExpressionStatement() {}


void ExpressionStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitExpressionStatement(this);
}


void ExpressionStatement::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


Block::~Block() {}


void Block::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitBlock(this);
}


void Block::VisitChildren(Visitor* visitor) {
  VisitList(&statements(), visitor);
}


EmptyStatement::~EmptyStatement() {}


void EmptyStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitEmptyStatement(this);
}


void EmptyStatement::VisitChildren(Visitor* visitor) {}


AssertStatement::~AssertStatement() {}


void AssertStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitAssertStatement(this);
}


void AssertStatement::VisitChildren(Visitor* visitor) {
  condition()->AcceptExpressionVisitor(visitor);
  if (message() != NULL) message()->AcceptExpressionVisitor(visitor);
}


LabeledStatement::~LabeledStatement() {}


void LabeledStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitLabeledStatement(this);
}


void LabeledStatement::VisitChildren(Visitor* visitor) {
  body()->AcceptStatementVisitor(visitor);
}


BreakStatement::~BreakStatement() {}


void BreakStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitBreakStatement(this);
}


void BreakStatement::VisitChildren(Visitor* visitor) {}


WhileStatement::~WhileStatement() {}


void WhileStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitWhileStatement(this);
}


void WhileStatement::VisitChildren(Visitor* visitor) {
  condition()->AcceptExpressionVisitor(visitor);
  body()->AcceptStatementVisitor(visitor);
}


DoStatement::~DoStatement() {}


void DoStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitDoStatement(this);
}


void DoStatement::VisitChildren(Visitor* visitor) {
  body()->AcceptStatementVisitor(visitor);
  condition()->AcceptExpressionVisitor(visitor);
}


ForStatement::~ForStatement() {}


void ForStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitForStatement(this);
}


void ForStatement::VisitChildren(Visitor* visitor) {
  VisitList(&variables(), visitor);
  if (condition() != NULL) condition()->AcceptExpressionVisitor(visitor);
  VisitList(&updates(), visitor);
  body()->AcceptStatementVisitor(visitor);
}


ForInStatement::~ForInStatement() {}


void ForInStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitForInStatement(this);
}


void ForInStatement::VisitChildren(Visitor* visitor) {
  visitor->VisitVariableDeclaration(variable());
  iterable()->AcceptExpressionVisitor(visitor);
  body()->AcceptStatementVisitor(visitor);
}


SwitchStatement::~SwitchStatement() {}


void SwitchStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitSwitchStatement(this);
}


void SwitchStatement::VisitChildren(Visitor* visitor) {
  condition()->AcceptExpressionVisitor(visitor);
  VisitList(&cases(), visitor);
}


SwitchCase::~SwitchCase() {}


void SwitchCase::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitSwitchCase(this);
}


void SwitchCase::VisitChildren(Visitor* visitor) {
  VisitList(&expressions(), visitor);
  body()->AcceptStatementVisitor(visitor);
}


ContinueSwitchStatement::~ContinueSwitchStatement() {}


void ContinueSwitchStatement::AcceptStatementVisitor(
    StatementVisitor* visitor) {
  visitor->VisitContinueSwitchStatement(this);
}


void ContinueSwitchStatement::VisitChildren(Visitor* visitor) {}


IfStatement::~IfStatement() {}


void IfStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitIfStatement(this);
}


void IfStatement::VisitChildren(Visitor* visitor) {
  condition()->AcceptExpressionVisitor(visitor);
  then()->AcceptStatementVisitor(visitor);
  otherwise()->AcceptStatementVisitor(visitor);
}


ReturnStatement::~ReturnStatement() {}


void ReturnStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitReturnStatement(this);
}


void ReturnStatement::VisitChildren(Visitor* visitor) {
  if (expression() != NULL) expression()->AcceptExpressionVisitor(visitor);
}


TryCatch::~TryCatch() {}


void TryCatch::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitTryCatch(this);
}


void TryCatch::VisitChildren(Visitor* visitor) {
  body()->AcceptStatementVisitor(visitor);
  VisitList(&catches(), visitor);
}


Catch::~Catch() {}


void Catch::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitCatch(this);
}


void Catch::VisitChildren(Visitor* visitor) {
  if (guard() != NULL) guard()->AcceptDartTypeVisitor(visitor);
  if (exception() != NULL) visitor->VisitVariableDeclaration(exception());
  if (stack_trace() != NULL) visitor->VisitVariableDeclaration(stack_trace());
  body()->AcceptStatementVisitor(visitor);
}


TryFinally::~TryFinally() {}


void TryFinally::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitTryFinally(this);
}


void TryFinally::VisitChildren(Visitor* visitor) {
  body()->AcceptStatementVisitor(visitor);
  finalizer()->AcceptStatementVisitor(visitor);
}


YieldStatement::~YieldStatement() {}


void YieldStatement::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitYieldStatement(this);
}


void YieldStatement::VisitChildren(Visitor* visitor) {
  expression()->AcceptExpressionVisitor(visitor);
}


VariableDeclaration::~VariableDeclaration() {}


void VariableDeclaration::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitVariableDeclaration(this);
}


void VariableDeclaration::VisitChildren(Visitor* visitor) {
  if (type() != NULL) type()->AcceptDartTypeVisitor(visitor);
  if (initializer() != NULL) initializer()->AcceptExpressionVisitor(visitor);
}


FunctionDeclaration::~FunctionDeclaration() {}


void FunctionDeclaration::AcceptStatementVisitor(StatementVisitor* visitor) {
  visitor->VisitFunctionDeclaration(this);
}


void FunctionDeclaration::VisitChildren(Visitor* visitor) {
  visitor->VisitVariableDeclaration(variable());
  visitor->VisitFunctionNode(function());
}


Name::~Name() {}


void Name::AcceptVisitor(Visitor* visitor) {
  visitor->VisitName(this);
}


void Name::VisitChildren(Visitor* visitor) {}


DartType::~DartType() {}


void DartType::AcceptVisitor(Visitor* visitor) {
  AcceptDartTypeVisitor(visitor);
}


InvalidType::~InvalidType() {}


void InvalidType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitInvalidType(this);
}


void InvalidType::VisitChildren(Visitor* visitor) {}


DynamicType::~DynamicType() {}


void DynamicType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitDynamicType(this);
}


void DynamicType::VisitChildren(Visitor* visitor) {}


VoidType::~VoidType() {}


void VoidType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitVoidType(this);
}


void VoidType::VisitChildren(Visitor* visitor) {}


BottomType::~BottomType() {}


void BottomType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitBottomType(this);
}


void BottomType::VisitChildren(Visitor* visitor) {}


InterfaceType::~InterfaceType() {}


void InterfaceType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitInterfaceType(this);
}


void InterfaceType::VisitChildren(Visitor* visitor) {
  VisitList(&type_arguments(), visitor);
}


TypedefType::~TypedefType() {}


void TypedefType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitTypedefType(this);
}


void TypedefType::VisitChildren(Visitor* visitor) {
  VisitList(&type_arguments(), visitor);
}


FunctionType::~FunctionType() {}


void FunctionType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitFunctionType(this);
}


void FunctionType::VisitChildren(Visitor* visitor) {
  VisitList(&type_parameters(), visitor);
  VisitList(&positional_parameters(), visitor);
  for (int i = 0; i < named_parameters().length(); ++i) {
    named_parameters()[i]->type()->AcceptDartTypeVisitor(visitor);
  }
  return_type()->AcceptDartTypeVisitor(visitor);
}


TypeParameterType::~TypeParameterType() {}


void TypeParameterType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitTypeParameterType(this);
}


void TypeParameterType::VisitChildren(Visitor* visitor) {}


VectorType::~VectorType() {}


void VectorType::AcceptDartTypeVisitor(DartTypeVisitor* visitor) {
  visitor->VisitVectorType(this);
}


void VectorType::VisitChildren(Visitor* visitor) {}


TypeParameter::~TypeParameter() {}


void TypeParameter::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitTypeParameter(this);
}


void TypeParameter::VisitChildren(Visitor* visitor) {
  bound()->AcceptDartTypeVisitor(visitor);
}


Program::~Program() {
  while (valid_token_positions.length() > 0) {
    delete valid_token_positions.RemoveLast();
  }
  while (yield_token_positions.length() > 0) {
    delete yield_token_positions.RemoveLast();
  }
}


void Program::AcceptTreeVisitor(TreeVisitor* visitor) {
  visitor->VisitProgram(this);
}


void Program::VisitChildren(Visitor* visitor) {
  VisitList(&libraries(), visitor);
}


}  // namespace kernel

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
