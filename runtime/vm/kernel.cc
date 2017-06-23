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


VariableGet::~VariableGet() {}


VariableSet::~VariableSet() {}


PropertyGet::~PropertyGet() {}


PropertySet::~PropertySet() {}


DirectPropertyGet::~DirectPropertyGet() {}


DirectPropertySet::~DirectPropertySet() {}


StaticGet::~StaticGet() {}


StaticSet::~StaticSet() {}


Arguments::~Arguments() {}


NamedExpression::~NamedExpression() {}


MethodInvocation::~MethodInvocation() {}


DirectMethodInvocation::~DirectMethodInvocation() {}


StaticInvocation::~StaticInvocation() {}


ConstructorInvocation::~ConstructorInvocation() {}


Not::~Not() {}


LogicalExpression::~LogicalExpression() {}


ConditionalExpression::~ConditionalExpression() {}


StringConcatenation::~StringConcatenation() {}


IsExpression::~IsExpression() {}


AsExpression::~AsExpression() {}


BasicLiteral::~BasicLiteral() {}


StringLiteral::~StringLiteral() {}


BigintLiteral::~BigintLiteral() {}


IntLiteral::~IntLiteral() {}


DoubleLiteral::~DoubleLiteral() {}


BoolLiteral::~BoolLiteral() {}


NullLiteral::~NullLiteral() {}


SymbolLiteral::~SymbolLiteral() {}


TypeLiteral::~TypeLiteral() {}


ThisExpression::~ThisExpression() {}


Rethrow::~Rethrow() {}


Throw::~Throw() {}


ListLiteral::~ListLiteral() {}


MapLiteral::~MapLiteral() {}


MapEntry::~MapEntry() {}


AwaitExpression::~AwaitExpression() {}


FunctionExpression::~FunctionExpression() {}


Let::~Let() {}


VectorCreation::~VectorCreation() {}


VectorGet::~VectorGet() {}


VectorSet::~VectorSet() {}


VectorCopy::~VectorCopy() {}


ClosureCreation::~ClosureCreation() {}


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


DynamicType::~DynamicType() {}


VoidType::~VoidType() {}


BottomType::~BottomType() {}


InterfaceType::~InterfaceType() {}


TypedefType::~TypedefType() {}


FunctionType::~FunctionType() {}


TypeParameterType::~TypeParameterType() {}


VectorType::~VectorType() {}


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
