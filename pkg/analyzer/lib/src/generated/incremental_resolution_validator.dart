// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.incremental_resolution_validator;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';

/**
 * Validates that the [actual] and the [expected] units have the same structure
 * and resolution. Throws [IncrementalResolutionMismatch] otherwise.
 */
void assertSameResolution(CompilationUnit actual, CompilationUnit expected,
    {bool validateTypes: false}) {
  _SameResolutionValidator validator =
      new _SameResolutionValidator(validateTypes, expected);
  actual.accept(validator);
}

/**
 * This exception is thrown when a mismatch between actual and expected AST
 * or resolution is found.
 */
class IncrementalResolutionMismatch {
  final String message;
  IncrementalResolutionMismatch(this.message);

  @override
  String toString() => "IncrementalResolutionMismatch: $message";
}

class _SameResolutionValidator implements AstVisitor {
  final bool validateTypes;

  /// The expected node to compare with the visited node.
  AstNode other;

  _SameResolutionValidator(this.validateTypes, this.other);

  @override
  visitAdjacentStrings(AdjacentStrings node) {}

  @override
  visitAnnotation(Annotation node) {
    Annotation other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.arguments, other.arguments);
    _verifyElement(node.element, other.element);
  }

  @override
  visitArgumentList(ArgumentList node) {
    ArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitAsExpression(AsExpression node) {
    AsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitAssertStatement(AssertStatement node) {
    AssertStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.message, other.message);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftHandSide, other.leftHandSide);
    _visitNode(node.rightHandSide, other.rightHandSide);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftOperand, other.leftOperand);
    _visitNode(node.rightOperand, other.rightOperand);
  }

  @override
  visitBlock(Block node) {
    Block other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = this.other;
    _visitNode(node.block, other.block);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    BreakStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitList(node.cascadeSections, other.cascadeSections);
  }

  @override
  visitCatchClause(CatchClause node) {
    CatchClause other = this.other;
    _visitNode(node.exceptionType, other.exceptionType);
    _visitNode(node.exceptionParameter, other.exceptionParameter);
    _visitNode(node.stackTraceParameter, other.stackTraceParameter);
    _visitNode(node.body, other.body);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.extendsClause, other.extendsClause);
    _visitNode(node.implementsClause, other.implementsClause);
    _visitNode(node.withClause, other.withClause);
    _visitList(node.members, other.members);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.superclass, other.superclass);
    _visitNode(node.withClause, other.withClause);
  }

  @override
  visitComment(Comment node) {
    Comment other = this.other;
    _visitList(node.references, other.references);
  }

  @override
  visitCommentReference(CommentReference node) {
    CommentReference other = this.other;
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = this.other;
    _verifyElement(node.element, other.element);
    _visitList(node.directives, other.directives);
    _visitList(node.declarations, other.declarations);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenExpression, other.thenExpression);
    _visitNode(node.elseExpression, other.elseExpression);
  }

  @override
  visitConfiguration(Configuration node) {
    Configuration other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.value, other.value);
    _visitNode(node.libraryUri, other.libraryUri);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.redirectedConstructor, other.redirectedConstructor);
    _visitList(node.initializers, other.initializers);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = this.other;
    _visitNode(node.fieldName, other.fieldName);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitConstructorName(ConstructorName node) {
    ConstructorName other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.type, other.type);
    _visitNode(node.name, other.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = this.other;
    _visitNode(node.type, other.type);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = this.other;
    _visitNode(node.parameter, other.parameter);
    _visitNode(node.defaultValue, other.defaultValue);
  }

  @override
  visitDoStatement(DoStatement node) {
    DoStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitDottedName(DottedName node) {
    DottedName other = this.other;
    _visitList(node.components, other.components);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitEmptyFunctionBody(EmptyFunctionBody node) {}

  @override
  visitEmptyStatement(EmptyStatement node) {}

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitList(node.constants, other.constants);
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = this.other;
    _visitNode(node.superclass, other.superclass);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.fields, other.fields);
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = this.other;
    _visitNode(node.identifier, other.identifier);
    _visitNode(node.loopVariable, other.loopVariable);
    _visitNode(node.iterable, other.iterable);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = this.other;
    _visitList(node.parameters, other.parameters);
  }

  @override
  visitForStatement(ForStatement node) {
    ForStatement other = this.other;
    _visitNode(node.variables, other.variables);
    _visitNode(node.initialization, other.initialization);
    _visitNode(node.condition, other.condition);
    _visitList(node.updaters, other.updaters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.functionExpression, other.functionExpression);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = this.other;
    _visitNode(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.element, other.element);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.function, other.function);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitHideCombinator(HideCombinator node) {
    HideCombinator other = this.other;
    _visitList(node.hiddenNames, other.hiddenNames);
  }

  @override
  visitIfStatement(IfStatement node) {
    IfStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenStatement, other.thenStatement);
    _visitNode(node.elseStatement, other.elseStatement);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = this.other;
    _visitList(node.interfaces, other.interfaces);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.prefix, other.prefix);
    _verifyElement(node.uriElement, other.uriElement);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    IndexExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.target, other.target);
    _visitNode(node.index, other.index);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitInterpolationString(InterpolationString node) {}

  @override
  visitIsExpression(IsExpression node) {
    IsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitLabel(Label node) {
    Label other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.statement, other.statement);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = this.other;
    _visitList(node.components, other.components);
  }

  @override
  visitListLiteral(ListLiteral node) {
    ListLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.elements, other.elements);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    MapLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.entries, other.entries);
  }

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = this.other;
    _visitNode(node.key, other.key);
    _visitNode(node.value, other.value);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = this.other;
    _visitNode(node.target, other.target);
    _visitNode(node.methodName, other.methodName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitNamedExpression(NamedExpression node) {
    NamedExpression other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitNativeClause(NativeClause node) {}

  @override
  visitNativeFunctionBody(NativeFunctionBody node) {}

  @override
  visitNullLiteral(NullLiteral node) {
    NullLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitPartDirective(PartDirective node) {
    PartDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.libraryName, other.libraryName);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = this.other;
    _visitExpression(node, other);
    _visitNode(node.prefix, other.prefix);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitNode(node.propertyName, other.propertyName);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitScriptTag(ScriptTag node) {}

  @override
  visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = this.other;
    _visitList(node.shownNames, other.shownNames);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitExpression(node, other);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {}

  @override
  visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = this.other;
    _visitList(node.elements, other.elements);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    SuperExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    SwitchCase other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.expression, other.expression);
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = this.other;
    _visitNode(node.expression, other.expression);
    _visitList(node.members, other.members);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {}

  @override
  visitThisExpression(ThisExpression node) {
    ThisExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitTryStatement(TryStatement node) {
    TryStatement other = this.other;
    _visitNode(node.body, other.body);
    _visitList(node.catchClauses, other.catchClauses);
    _visitNode(node.finallyBlock, other.finallyBlock);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitTypeName(TypeName node) {
    TypeName other = this.other;
    _verifyType(node.type, other.type);
    _visitNode(node.name, node.name);
    _visitNode(node.typeArguments, other.typeArguments);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    TypeParameter other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.bound, other.bound);
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = this.other;
    _visitList(node.typeParameters, other.typeParameters);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.initializer, other.initializer);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = this.other;
    _visitNode(node.type, other.type);
    _visitList(node.variables, other.variables);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    WhileStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitWithClause(WithClause node) {
    WithClause other = this.other;
    _visitList(node.mixinTypes, other.mixinTypes);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    YieldStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  void _assertNode(AstNode a, AstNode b) {
    _expectEquals(a.offset, b.offset);
    _expectEquals(a.length, b.length);
  }

  void _expectEquals(actual, expected) {
    if (actual != expected) {
      String message = '';
      message += 'Expected: $expected\n';
      message += '  Actual: $actual\n';
      _fail(message);
    }
  }

  void _expectIsNull(obj) {
    if (obj != null) {
      String message = '';
      message += 'Expected: null\n';
      message += '  Actual: $obj\n';
      _fail(message);
    }
  }

  void _expectLength(List actualList, int expected) {
    String message = '';
    message += 'Expected length: $expected\n';
    if (actualList == null) {
      message += 'but null found.';
      _fail(message);
    }
    int actual = actualList.length;
    if (actual != expected) {
      message += 'but $actual found\n';
      message += 'in $actualList';
      _fail(message);
    }
  }

  void _fail(String message) {
    throw new IncrementalResolutionMismatch(message);
  }

  void _verifyElement(Element a, Element b) {
    if (a is Member && b is Member) {
      a = (a as Member).baseElement;
      b = (b as Member).baseElement;
    }
    String locationA = _getElementLocationWithoutUri(a);
    String locationB = _getElementLocationWithoutUri(b);
    if (locationA != locationB) {
      int offset = other.offset;
      _fail('[$offset]\nExpected: $b ($locationB)\n  Actual: $a ($locationA)');
    }
    if (a == null && b == null) {
      return;
    }
    _verifyEqual('nameOffset', a.nameOffset, b.nameOffset);
    if (a is ElementImpl && b is ElementImpl) {
      _verifyEqual('codeOffset', a.codeOffset, b.codeOffset);
      _verifyEqual('codeLength', a.codeLength, b.codeLength);
    }
    if (a is LocalElement && b is LocalElement) {
      _verifyEqual('visibleRange', a.visibleRange, b.visibleRange);
    }
  }

  void _verifyEqual(String name, actual, expected) {
    if (actual != expected) {
      _fail('$name\nExpected: $expected\n  Actual: $actual');
    }
  }

  void _verifyType(DartType a, DartType b) {
    if (!validateTypes) {
      return;
    }
    if (a != b) {
      int offset = other.offset;
      _fail('[$offset]\nExpected: $b\n  Actual: $a');
    }
  }

  void _visitAnnotatedNode(AnnotatedNode node, AnnotatedNode other) {
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
  }

  _visitDeclaration(Declaration node, Declaration other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  _visitDirective(Directive node, Directive other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  void _visitExpression(Expression a, Expression b) {
//    print('[${a.offset}] |$a| vs. [${b.offset}] |$b|');
    _verifyType(a.staticType, b.staticType);
    _verifyType(a.propagatedType, b.propagatedType);
    _verifyElement(a.staticParameterElement, b.staticParameterElement);
    _verifyElement(a.propagatedParameterElement, b.propagatedParameterElement);
    _assertNode(a, b);
  }

  void _visitList(NodeList nodeList, NodeList expected) {
    int length = nodeList.length;
    _expectLength(nodeList, expected.length);
    for (int i = 0; i < length; i++) {
      _visitNode(nodeList[i], expected[i]);
    }
  }

  void _visitNode(AstNode node, AstNode other) {
    if (node == null) {
      _expectIsNull(other);
    } else {
      this.other = other;
      _assertNode(node, other);
      node.accept(this);
    }
  }

  void _visitNormalFormalParameter(
      NormalFormalParameter node, NormalFormalParameter other) {
    _verifyElement(node.element, other.element);
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
    _visitNode(node.identifier, other.identifier);
  }

  /**
   * Returns an URI scheme independent version of the [element] location.
   */
  static String _getElementLocationWithoutUri(Element element) {
    if (element == null) {
      return '<null>';
    }
    if (element is UriReferencedElementImpl) {
      return '<ignored>';
    }
    ElementLocation location = element.location;
    List<String> components = location.components;
    String uriPrefix = '';
    Element unit = element is CompilationUnitElement
        ? element
        : element.getAncestor((e) => e is CompilationUnitElement);
    if (unit != null) {
      String libComponent = components[0];
      String unitComponent = components[1];
      components = components.sublist(2);
      uriPrefix = _getShortElementLocationUri(libComponent) +
          ':' +
          _getShortElementLocationUri(unitComponent);
    } else {
      String libComponent = components[0];
      components = components.sublist(1);
      uriPrefix = _getShortElementLocationUri(libComponent);
    }
    return uriPrefix + ':' + components.join(':');
  }

  /**
   * Returns a "short" version of the given [uri].
   *
   * For example:
   *     /User/me/project/lib/my_lib.dart -> my_lib.dart
   *     package:project/my_lib.dart      -> my_lib.dart
   */
  static String _getShortElementLocationUri(String uri) {
    int index = uri.lastIndexOf('/');
    if (index == -1) {
      return uri;
    }
    return uri.substring(index + 1);
  }
}
