// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/front_end/tool/generate_ast_equivalence.dart' to update.

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';
import 'union_find.dart';

part 'equivalence_helpers.dart';

/// Visitor that uses a EquivalenceStrategy to compute AST node equivalence.
///
/// The visitor hold a current state that collects found inequivalences and
/// current assumptions. The current state has two modes. In the asserting mode,
/// the default, inequivalences are registered when found. In the non-asserting
/// mode, inequivalences are _not_ registered. The latter is used to compute
/// equivalences in sandboxed state, for instance to determine which elements
/// to pair when checking equivalence of two sets.
class EquivalenceVisitor implements Visitor1<bool, Node> {
  final EquivalenceStrategy strategy;

  EquivalenceVisitor({this.strategy = const EquivalenceStrategy()});

  @override
  bool visitLibrary(Library node, Node other) {
    return strategy.checkLibrary(this, node, other);
  }

  @override
  bool visitTypedef(Typedef node, Node other) {
    return strategy.checkTypedef(this, node, other);
  }

  @override
  bool visitClass(Class node, Node other) {
    return strategy.checkClass(this, node, other);
  }

  @override
  bool visitExtension(Extension node, Node other) {
    return strategy.checkExtension(this, node, other);
  }

  @override
  bool visitExtensionTypeDeclaration(
      ExtensionTypeDeclaration node, Node other) {
    return strategy.checkExtensionTypeDeclaration(this, node, other);
  }

  @override
  bool visitField(Field node, Node other) {
    return strategy.checkField(this, node, other);
  }

  @override
  bool visitConstructor(Constructor node, Node other) {
    return strategy.checkConstructor(this, node, other);
  }

  @override
  bool visitProcedure(Procedure node, Node other) {
    return strategy.checkProcedure(this, node, other);
  }

  @override
  bool visitLibraryDependency(LibraryDependency node, Node other) {
    return strategy.checkLibraryDependency(this, node, other);
  }

  @override
  bool visitLibraryPart(LibraryPart node, Node other) {
    return strategy.checkLibraryPart(this, node, other);
  }

  @override
  bool visitCombinator(Combinator node, Node other) {
    return strategy.checkCombinator(this, node, other);
  }

  @override
  bool visitAuxiliaryInitializer(AuxiliaryInitializer node, Node other) {
    return strategy.checkAuxiliaryInitializer(this, node, other);
  }

  @override
  bool visitInvalidInitializer(InvalidInitializer node, Node other) {
    return strategy.checkInvalidInitializer(this, node, other);
  }

  @override
  bool visitFieldInitializer(FieldInitializer node, Node other) {
    return strategy.checkFieldInitializer(this, node, other);
  }

  @override
  bool visitSuperInitializer(SuperInitializer node, Node other) {
    return strategy.checkSuperInitializer(this, node, other);
  }

  @override
  bool visitRedirectingInitializer(RedirectingInitializer node, Node other) {
    return strategy.checkRedirectingInitializer(this, node, other);
  }

  @override
  bool visitLocalInitializer(LocalInitializer node, Node other) {
    return strategy.checkLocalInitializer(this, node, other);
  }

  @override
  bool visitAssertInitializer(AssertInitializer node, Node other) {
    return strategy.checkAssertInitializer(this, node, other);
  }

  @override
  bool visitFunctionNode(FunctionNode node, Node other) {
    return strategy.checkFunctionNode(this, node, other);
  }

  @override
  bool visitAuxiliaryExpression(AuxiliaryExpression node, Node other) {
    return strategy.checkAuxiliaryExpression(this, node, other);
  }

  @override
  bool visitInvalidExpression(InvalidExpression node, Node other) {
    return strategy.checkInvalidExpression(this, node, other);
  }

  @override
  bool visitVariableGet(VariableGet node, Node other) {
    return strategy.checkVariableGet(this, node, other);
  }

  @override
  bool visitVariableSet(VariableSet node, Node other) {
    return strategy.checkVariableSet(this, node, other);
  }

  @override
  bool visitRecordIndexGet(RecordIndexGet node, Node other) {
    return strategy.checkRecordIndexGet(this, node, other);
  }

  @override
  bool visitRecordNameGet(RecordNameGet node, Node other) {
    return strategy.checkRecordNameGet(this, node, other);
  }

  @override
  bool visitDynamicGet(DynamicGet node, Node other) {
    return strategy.checkDynamicGet(this, node, other);
  }

  @override
  bool visitInstanceGet(InstanceGet node, Node other) {
    return strategy.checkInstanceGet(this, node, other);
  }

  @override
  bool visitFunctionTearOff(FunctionTearOff node, Node other) {
    return strategy.checkFunctionTearOff(this, node, other);
  }

  @override
  bool visitInstanceTearOff(InstanceTearOff node, Node other) {
    return strategy.checkInstanceTearOff(this, node, other);
  }

  @override
  bool visitDynamicSet(DynamicSet node, Node other) {
    return strategy.checkDynamicSet(this, node, other);
  }

  @override
  bool visitInstanceSet(InstanceSet node, Node other) {
    return strategy.checkInstanceSet(this, node, other);
  }

  @override
  bool visitAbstractSuperPropertyGet(
      AbstractSuperPropertyGet node, Node other) {
    return strategy.checkAbstractSuperPropertyGet(this, node, other);
  }

  @override
  bool visitSuperPropertyGet(SuperPropertyGet node, Node other) {
    return strategy.checkSuperPropertyGet(this, node, other);
  }

  @override
  bool visitAbstractSuperPropertySet(
      AbstractSuperPropertySet node, Node other) {
    return strategy.checkAbstractSuperPropertySet(this, node, other);
  }

  @override
  bool visitSuperPropertySet(SuperPropertySet node, Node other) {
    return strategy.checkSuperPropertySet(this, node, other);
  }

  @override
  bool visitStaticGet(StaticGet node, Node other) {
    return strategy.checkStaticGet(this, node, other);
  }

  @override
  bool visitStaticTearOff(StaticTearOff node, Node other) {
    return strategy.checkStaticTearOff(this, node, other);
  }

  @override
  bool visitStaticSet(StaticSet node, Node other) {
    return strategy.checkStaticSet(this, node, other);
  }

  @override
  bool visitDynamicInvocation(DynamicInvocation node, Node other) {
    return strategy.checkDynamicInvocation(this, node, other);
  }

  @override
  bool visitInstanceInvocation(InstanceInvocation node, Node other) {
    return strategy.checkInstanceInvocation(this, node, other);
  }

  @override
  bool visitInstanceGetterInvocation(
      InstanceGetterInvocation node, Node other) {
    return strategy.checkInstanceGetterInvocation(this, node, other);
  }

  @override
  bool visitFunctionInvocation(FunctionInvocation node, Node other) {
    return strategy.checkFunctionInvocation(this, node, other);
  }

  @override
  bool visitLocalFunctionInvocation(LocalFunctionInvocation node, Node other) {
    return strategy.checkLocalFunctionInvocation(this, node, other);
  }

  @override
  bool visitAbstractSuperMethodInvocation(
      AbstractSuperMethodInvocation node, Node other) {
    return strategy.checkAbstractSuperMethodInvocation(this, node, other);
  }

  @override
  bool visitSuperMethodInvocation(SuperMethodInvocation node, Node other) {
    return strategy.checkSuperMethodInvocation(this, node, other);
  }

  @override
  bool visitStaticInvocation(StaticInvocation node, Node other) {
    return strategy.checkStaticInvocation(this, node, other);
  }

  @override
  bool visitConstructorInvocation(ConstructorInvocation node, Node other) {
    return strategy.checkConstructorInvocation(this, node, other);
  }

  @override
  bool visitEqualsNull(EqualsNull node, Node other) {
    return strategy.checkEqualsNull(this, node, other);
  }

  @override
  bool visitEqualsCall(EqualsCall node, Node other) {
    return strategy.checkEqualsCall(this, node, other);
  }

  @override
  bool visitInstantiation(Instantiation node, Node other) {
    return strategy.checkInstantiation(this, node, other);
  }

  @override
  bool visitNot(Not node, Node other) {
    return strategy.checkNot(this, node, other);
  }

  @override
  bool visitLogicalExpression(LogicalExpression node, Node other) {
    return strategy.checkLogicalExpression(this, node, other);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node, Node other) {
    return strategy.checkConditionalExpression(this, node, other);
  }

  @override
  bool visitStringConcatenation(StringConcatenation node, Node other) {
    return strategy.checkStringConcatenation(this, node, other);
  }

  @override
  bool visitListConcatenation(ListConcatenation node, Node other) {
    return strategy.checkListConcatenation(this, node, other);
  }

  @override
  bool visitSetConcatenation(SetConcatenation node, Node other) {
    return strategy.checkSetConcatenation(this, node, other);
  }

  @override
  bool visitMapConcatenation(MapConcatenation node, Node other) {
    return strategy.checkMapConcatenation(this, node, other);
  }

  @override
  bool visitInstanceCreation(InstanceCreation node, Node other) {
    return strategy.checkInstanceCreation(this, node, other);
  }

  @override
  bool visitFileUriExpression(FileUriExpression node, Node other) {
    return strategy.checkFileUriExpression(this, node, other);
  }

  @override
  bool visitIsExpression(IsExpression node, Node other) {
    return strategy.checkIsExpression(this, node, other);
  }

  @override
  bool visitAsExpression(AsExpression node, Node other) {
    return strategy.checkAsExpression(this, node, other);
  }

  @override
  bool visitNullCheck(NullCheck node, Node other) {
    return strategy.checkNullCheck(this, node, other);
  }

  @override
  bool visitStringLiteral(StringLiteral node, Node other) {
    return strategy.checkStringLiteral(this, node, other);
  }

  @override
  bool visitIntLiteral(IntLiteral node, Node other) {
    return strategy.checkIntLiteral(this, node, other);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node, Node other) {
    return strategy.checkDoubleLiteral(this, node, other);
  }

  @override
  bool visitBoolLiteral(BoolLiteral node, Node other) {
    return strategy.checkBoolLiteral(this, node, other);
  }

  @override
  bool visitNullLiteral(NullLiteral node, Node other) {
    return strategy.checkNullLiteral(this, node, other);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node, Node other) {
    return strategy.checkSymbolLiteral(this, node, other);
  }

  @override
  bool visitTypeLiteral(TypeLiteral node, Node other) {
    return strategy.checkTypeLiteral(this, node, other);
  }

  @override
  bool visitThisExpression(ThisExpression node, Node other) {
    return strategy.checkThisExpression(this, node, other);
  }

  @override
  bool visitRethrow(Rethrow node, Node other) {
    return strategy.checkRethrow(this, node, other);
  }

  @override
  bool visitThrow(Throw node, Node other) {
    return strategy.checkThrow(this, node, other);
  }

  @override
  bool visitListLiteral(ListLiteral node, Node other) {
    return strategy.checkListLiteral(this, node, other);
  }

  @override
  bool visitSetLiteral(SetLiteral node, Node other) {
    return strategy.checkSetLiteral(this, node, other);
  }

  @override
  bool visitMapLiteral(MapLiteral node, Node other) {
    return strategy.checkMapLiteral(this, node, other);
  }

  @override
  bool visitRecordLiteral(RecordLiteral node, Node other) {
    return strategy.checkRecordLiteral(this, node, other);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node, Node other) {
    return strategy.checkAwaitExpression(this, node, other);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node, Node other) {
    return strategy.checkFunctionExpression(this, node, other);
  }

  @override
  bool visitConstantExpression(ConstantExpression node, Node other) {
    return strategy.checkConstantExpression(this, node, other);
  }

  @override
  bool visitLet(Let node, Node other) {
    return strategy.checkLet(this, node, other);
  }

  @override
  bool visitBlockExpression(BlockExpression node, Node other) {
    return strategy.checkBlockExpression(this, node, other);
  }

  @override
  bool visitLoadLibrary(LoadLibrary node, Node other) {
    return strategy.checkLoadLibrary(this, node, other);
  }

  @override
  bool visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, Node other) {
    return strategy.checkCheckLibraryIsLoaded(this, node, other);
  }

  @override
  bool visitConstructorTearOff(ConstructorTearOff node, Node other) {
    return strategy.checkConstructorTearOff(this, node, other);
  }

  @override
  bool visitRedirectingFactoryTearOff(
      RedirectingFactoryTearOff node, Node other) {
    return strategy.checkRedirectingFactoryTearOff(this, node, other);
  }

  @override
  bool visitTypedefTearOff(TypedefTearOff node, Node other) {
    return strategy.checkTypedefTearOff(this, node, other);
  }

  @override
  bool visitSwitchExpression(SwitchExpression node, Node other) {
    return strategy.checkSwitchExpression(this, node, other);
  }

  @override
  bool visitPatternAssignment(PatternAssignment node, Node other) {
    return strategy.checkPatternAssignment(this, node, other);
  }

  @override
  bool visitArguments(Arguments node, Node other) {
    return strategy.checkArguments(this, node, other);
  }

  @override
  bool visitNamedExpression(NamedExpression node, Node other) {
    return strategy.checkNamedExpression(this, node, other);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node, Node other) {
    return strategy.checkMapLiteralEntry(this, node, other);
  }

  @override
  bool visitAuxiliaryStatement(AuxiliaryStatement node, Node other) {
    return strategy.checkAuxiliaryStatement(this, node, other);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node, Node other) {
    return strategy.checkExpressionStatement(this, node, other);
  }

  @override
  bool visitBlock(Block node, Node other) {
    return strategy.checkBlock(this, node, other);
  }

  @override
  bool visitAssertBlock(AssertBlock node, Node other) {
    return strategy.checkAssertBlock(this, node, other);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node, Node other) {
    return strategy.checkEmptyStatement(this, node, other);
  }

  @override
  bool visitAssertStatement(AssertStatement node, Node other) {
    return strategy.checkAssertStatement(this, node, other);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node, Node other) {
    return strategy.checkLabeledStatement(this, node, other);
  }

  @override
  bool visitBreakStatement(BreakStatement node, Node other) {
    return strategy.checkBreakStatement(this, node, other);
  }

  @override
  bool visitWhileStatement(WhileStatement node, Node other) {
    return strategy.checkWhileStatement(this, node, other);
  }

  @override
  bool visitDoStatement(DoStatement node, Node other) {
    return strategy.checkDoStatement(this, node, other);
  }

  @override
  bool visitForStatement(ForStatement node, Node other) {
    return strategy.checkForStatement(this, node, other);
  }

  @override
  bool visitForInStatement(ForInStatement node, Node other) {
    return strategy.checkForInStatement(this, node, other);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node, Node other) {
    return strategy.checkSwitchStatement(this, node, other);
  }

  @override
  bool visitContinueSwitchStatement(ContinueSwitchStatement node, Node other) {
    return strategy.checkContinueSwitchStatement(this, node, other);
  }

  @override
  bool visitIfStatement(IfStatement node, Node other) {
    return strategy.checkIfStatement(this, node, other);
  }

  @override
  bool visitReturnStatement(ReturnStatement node, Node other) {
    return strategy.checkReturnStatement(this, node, other);
  }

  @override
  bool visitTryCatch(TryCatch node, Node other) {
    return strategy.checkTryCatch(this, node, other);
  }

  @override
  bool visitTryFinally(TryFinally node, Node other) {
    return strategy.checkTryFinally(this, node, other);
  }

  @override
  bool visitYieldStatement(YieldStatement node, Node other) {
    return strategy.checkYieldStatement(this, node, other);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node, Node other) {
    return strategy.checkVariableDeclaration(this, node, other);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node, Node other) {
    return strategy.checkFunctionDeclaration(this, node, other);
  }

  @override
  bool visitPatternSwitchStatement(PatternSwitchStatement node, Node other) {
    return strategy.checkPatternSwitchStatement(this, node, other);
  }

  @override
  bool visitPatternVariableDeclaration(
      PatternVariableDeclaration node, Node other) {
    return strategy.checkPatternVariableDeclaration(this, node, other);
  }

  @override
  bool visitIfCaseStatement(IfCaseStatement node, Node other) {
    return strategy.checkIfCaseStatement(this, node, other);
  }

  @override
  bool visitSwitchCase(SwitchCase node, Node other) {
    return strategy.checkSwitchCase(this, node, other);
  }

  @override
  bool visitCatch(Catch node, Node other) {
    return strategy.checkCatch(this, node, other);
  }

  @override
  bool visitTypeParameter(TypeParameter node, Node other) {
    return strategy.checkTypeParameter(this, node, other);
  }

  @override
  bool visitComponent(Component node, Node other) {
    return strategy.checkComponent(this, node, other);
  }

  @override
  bool visitConstantPattern(ConstantPattern node, Node other) {
    return strategy.checkConstantPattern(this, node, other);
  }

  @override
  bool visitAndPattern(AndPattern node, Node other) {
    return strategy.checkAndPattern(this, node, other);
  }

  @override
  bool visitOrPattern(OrPattern node, Node other) {
    return strategy.checkOrPattern(this, node, other);
  }

  @override
  bool visitCastPattern(CastPattern node, Node other) {
    return strategy.checkCastPattern(this, node, other);
  }

  @override
  bool visitNullAssertPattern(NullAssertPattern node, Node other) {
    return strategy.checkNullAssertPattern(this, node, other);
  }

  @override
  bool visitNullCheckPattern(NullCheckPattern node, Node other) {
    return strategy.checkNullCheckPattern(this, node, other);
  }

  @override
  bool visitListPattern(ListPattern node, Node other) {
    return strategy.checkListPattern(this, node, other);
  }

  @override
  bool visitObjectPattern(ObjectPattern node, Node other) {
    return strategy.checkObjectPattern(this, node, other);
  }

  @override
  bool visitRelationalPattern(RelationalPattern node, Node other) {
    return strategy.checkRelationalPattern(this, node, other);
  }

  @override
  bool visitWildcardPattern(WildcardPattern node, Node other) {
    return strategy.checkWildcardPattern(this, node, other);
  }

  @override
  bool visitAssignedVariablePattern(AssignedVariablePattern node, Node other) {
    return strategy.checkAssignedVariablePattern(this, node, other);
  }

  @override
  bool visitMapPattern(MapPattern node, Node other) {
    return strategy.checkMapPattern(this, node, other);
  }

  @override
  bool visitNamedPattern(NamedPattern node, Node other) {
    return strategy.checkNamedPattern(this, node, other);
  }

  @override
  bool visitRecordPattern(RecordPattern node, Node other) {
    return strategy.checkRecordPattern(this, node, other);
  }

  @override
  bool visitVariablePattern(VariablePattern node, Node other) {
    return strategy.checkVariablePattern(this, node, other);
  }

  @override
  bool visitRestPattern(RestPattern node, Node other) {
    return strategy.checkRestPattern(this, node, other);
  }

  @override
  bool visitInvalidPattern(InvalidPattern node, Node other) {
    return strategy.checkInvalidPattern(this, node, other);
  }

  @override
  bool visitMapPatternEntry(MapPatternEntry node, Node other) {
    return strategy.checkMapPatternEntry(this, node, other);
  }

  @override
  bool visitMapPatternRestEntry(MapPatternRestEntry node, Node other) {
    return strategy.checkMapPatternRestEntry(this, node, other);
  }

  @override
  bool visitPatternGuard(PatternGuard node, Node other) {
    return strategy.checkPatternGuard(this, node, other);
  }

  @override
  bool visitPatternSwitchCase(PatternSwitchCase node, Node other) {
    return strategy.checkPatternSwitchCase(this, node, other);
  }

  @override
  bool visitSwitchExpressionCase(SwitchExpressionCase node, Node other) {
    return strategy.checkSwitchExpressionCase(this, node, other);
  }

  @override
  bool visitName(Name node, Node other) {
    return strategy.checkName(this, node, other);
  }

  @override
  bool visitInterfaceType(InterfaceType node, Node other) {
    return strategy.checkInterfaceType(this, node, other);
  }

  @override
  bool visitExtensionType(ExtensionType node, Node other) {
    return strategy.checkExtensionType(this, node, other);
  }

  @override
  bool visitAuxiliaryType(AuxiliaryType node, Node other) {
    return strategy.checkAuxiliaryType(this, node, other);
  }

  @override
  bool visitInvalidType(InvalidType node, Node other) {
    return strategy.checkInvalidType(this, node, other);
  }

  @override
  bool visitDynamicType(DynamicType node, Node other) {
    return strategy.checkDynamicType(this, node, other);
  }

  @override
  bool visitVoidType(VoidType node, Node other) {
    return strategy.checkVoidType(this, node, other);
  }

  @override
  bool visitNeverType(NeverType node, Node other) {
    return strategy.checkNeverType(this, node, other);
  }

  @override
  bool visitNullType(NullType node, Node other) {
    return strategy.checkNullType(this, node, other);
  }

  @override
  bool visitFunctionType(FunctionType node, Node other) {
    return strategy.checkFunctionType(this, node, other);
  }

  @override
  bool visitTypedefType(TypedefType node, Node other) {
    return strategy.checkTypedefType(this, node, other);
  }

  @override
  bool visitFutureOrType(FutureOrType node, Node other) {
    return strategy.checkFutureOrType(this, node, other);
  }

  @override
  bool visitIntersectionType(IntersectionType node, Node other) {
    return strategy.checkIntersectionType(this, node, other);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node, Node other) {
    return strategy.checkTypeParameterType(this, node, other);
  }

  @override
  bool visitStructuralParameterType(StructuralParameterType node, Node other) {
    return strategy.checkStructuralParameterType(this, node, other);
  }

  @override
  bool visitRecordType(RecordType node, Node other) {
    return strategy.checkRecordType(this, node, other);
  }

  @override
  bool visitNamedType(NamedType node, Node other) {
    return strategy.checkNamedType(this, node, other);
  }

  @override
  bool visitStructuralParameter(StructuralParameter node, Node other) {
    return strategy.checkStructuralParameter(this, node, other);
  }

  @override
  bool visitSupertype(Supertype node, Node other) {
    return strategy.checkSupertype(this, node, other);
  }

  @override
  bool visitAuxiliaryConstant(AuxiliaryConstant node, Node other) {
    return strategy.checkAuxiliaryConstant(this, node, other);
  }

  @override
  bool visitNullConstant(NullConstant node, Node other) {
    return strategy.checkNullConstant(this, node, other);
  }

  @override
  bool visitBoolConstant(BoolConstant node, Node other) {
    return strategy.checkBoolConstant(this, node, other);
  }

  @override
  bool visitIntConstant(IntConstant node, Node other) {
    return strategy.checkIntConstant(this, node, other);
  }

  @override
  bool visitDoubleConstant(DoubleConstant node, Node other) {
    return strategy.checkDoubleConstant(this, node, other);
  }

  @override
  bool visitStringConstant(StringConstant node, Node other) {
    return strategy.checkStringConstant(this, node, other);
  }

  @override
  bool visitSymbolConstant(SymbolConstant node, Node other) {
    return strategy.checkSymbolConstant(this, node, other);
  }

  @override
  bool visitMapConstant(MapConstant node, Node other) {
    return strategy.checkMapConstant(this, node, other);
  }

  @override
  bool visitListConstant(ListConstant node, Node other) {
    return strategy.checkListConstant(this, node, other);
  }

  @override
  bool visitSetConstant(SetConstant node, Node other) {
    return strategy.checkSetConstant(this, node, other);
  }

  @override
  bool visitRecordConstant(RecordConstant node, Node other) {
    return strategy.checkRecordConstant(this, node, other);
  }

  @override
  bool visitInstanceConstant(InstanceConstant node, Node other) {
    return strategy.checkInstanceConstant(this, node, other);
  }

  @override
  bool visitInstantiationConstant(InstantiationConstant node, Node other) {
    return strategy.checkInstantiationConstant(this, node, other);
  }

  @override
  bool visitStaticTearOffConstant(StaticTearOffConstant node, Node other) {
    return strategy.checkStaticTearOffConstant(this, node, other);
  }

  @override
  bool visitConstructorTearOffConstant(
      ConstructorTearOffConstant node, Node other) {
    return strategy.checkConstructorTearOffConstant(this, node, other);
  }

  @override
  bool visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node, Node other) {
    return strategy.checkRedirectingFactoryTearOffConstant(this, node, other);
  }

  @override
  bool visitTypedefTearOffConstant(TypedefTearOffConstant node, Node other) {
    return strategy.checkTypedefTearOffConstant(this, node, other);
  }

  @override
  bool visitTypeLiteralConstant(TypeLiteralConstant node, Node other) {
    return strategy.checkTypeLiteralConstant(this, node, other);
  }

  @override
  bool visitUnevaluatedConstant(UnevaluatedConstant node, Node other) {
    return strategy.checkUnevaluatedConstant(this, node, other);
  }

  @override
  bool visitTypedefReference(Typedef node, Node other) {
    return false;
  }

  @override
  bool visitClassReference(Class node, Node other) {
    return false;
  }

  @override
  bool visitExtensionReference(Extension node, Node other) {
    return false;
  }

  @override
  bool visitExtensionTypeDeclarationReference(
      ExtensionTypeDeclaration node, Node other) {
    return false;
  }

  @override
  bool visitFieldReference(Field node, Node other) {
    return false;
  }

  @override
  bool visitConstructorReference(Constructor node, Node other) {
    return false;
  }

  @override
  bool visitProcedureReference(Procedure node, Node other) {
    return false;
  }

  @override
  bool visitAuxiliaryConstantReference(AuxiliaryConstant node, Node other) {
    return false;
  }

  @override
  bool visitNullConstantReference(NullConstant node, Node other) {
    return false;
  }

  @override
  bool visitBoolConstantReference(BoolConstant node, Node other) {
    return false;
  }

  @override
  bool visitIntConstantReference(IntConstant node, Node other) {
    return false;
  }

  @override
  bool visitDoubleConstantReference(DoubleConstant node, Node other) {
    return false;
  }

  @override
  bool visitStringConstantReference(StringConstant node, Node other) {
    return false;
  }

  @override
  bool visitSymbolConstantReference(SymbolConstant node, Node other) {
    return false;
  }

  @override
  bool visitMapConstantReference(MapConstant node, Node other) {
    return false;
  }

  @override
  bool visitListConstantReference(ListConstant node, Node other) {
    return false;
  }

  @override
  bool visitSetConstantReference(SetConstant node, Node other) {
    return false;
  }

  @override
  bool visitRecordConstantReference(RecordConstant node, Node other) {
    return false;
  }

  @override
  bool visitInstanceConstantReference(InstanceConstant node, Node other) {
    return false;
  }

  @override
  bool visitInstantiationConstantReference(
      InstantiationConstant node, Node other) {
    return false;
  }

  @override
  bool visitStaticTearOffConstantReference(
      StaticTearOffConstant node, Node other) {
    return false;
  }

  @override
  bool visitConstructorTearOffConstantReference(
      ConstructorTearOffConstant node, Node other) {
    return false;
  }

  @override
  bool visitRedirectingFactoryTearOffConstantReference(
      RedirectingFactoryTearOffConstant node, Node other) {
    return false;
  }

  @override
  bool visitTypedefTearOffConstantReference(
      TypedefTearOffConstant node, Node other) {
    return false;
  }

  @override
  bool visitTypeLiteralConstantReference(TypeLiteralConstant node, Node other) {
    return false;
  }

  @override
  bool visitUnevaluatedConstantReference(UnevaluatedConstant node, Node other) {
    return false;
  }

  /// Returns `true` if [a] and [b] are identical or equal.
  bool _checkValues<T>(T? a, T? b) {
    return identical(a, b) || a == b;
  }

  /// Returns `true` if [a] and [b] are identical or equal and registers the
  /// inequivalence otherwise.
  bool checkValues<T>(T? a, T? b, String propertyName) {
    bool result = _checkValues(a, b);
    if (!result) {
      registerInequivalence(
          propertyName, 'Values ${a} and ${b} are not equivalent');
    }
    return result;
  }

  /// Returns `true` if [a] and [b] are identical or equal. Inequivalence is
  /// _not_ registered.
  bool matchValues<T>(T? a, T? b) {
    return _checkValues(a, b);
  }

  /// Cache of Constants compares and the results.
  /// This avoids potential exponential blowup when comparing ASTs
  /// that contain Constants.
  Map<Constant, Map<dynamic, bool>>? _constantCache;

  /// Returns `true` if [a] and [b] are equivalent.
  bool _checkNodes<T extends Node>(T? a, T? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) {
      return false;
    } else {
      if (a is Constant) {
        Map<Constant, Map<dynamic, bool>> cacheFrom = _constantCache ??= {};
        Map<dynamic, bool> cacheTo = cacheFrom[a] ??= {};
        bool? previousResult = cacheTo[b];
        if (previousResult != null) return previousResult;
        bool result = a.accept1(this, b);
        cacheTo[b] = result;
        return result;
      }
      return a.accept1(this, b);
    }
  }

  /// Returns `true` if [a] and [b] are equivalent, as defined by the current
  /// strategy, and registers the inequivalence otherwise.
  bool checkNodes<T extends Node>(T? a, T? b, [String propertyName = '']) {
    _checkingState.pushPropertyState(propertyName);
    bool result = _checkNodes(a, b);
    _checkingState.popState();
    if (!result) {
      registerInequivalence(
          propertyName, 'Inequivalent nodes\n1: ${a}\n2: ${b}');
    }
    return result;
  }

  /// Returns `true` if [a] and [b] are equivalent, either by existing
  /// assumption or as defined by their corresponding canonical names.
  /// Inequivalence is _not_ registered.
  bool matchNamedNodes(NamedNode? a, NamedNode? b) {
    return identical(a, b) ||
        a == null ||
        b == null ||
        checkAssumedReferences(a.reference, b.reference) ||
        new ReferenceName.fromNamedNode(a) ==
            new ReferenceName.fromNamedNode(b);
  }

  /// Returns `true` if [a] and [b] are currently assumed to be equivalent.
  bool checkAssumedReferences(Reference? a, Reference? b) {
    return _checkingState.checkAssumedReferences(a, b);
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// would not be the case if [a] xor [b] is `null`.
  bool assumeReferences(Reference? a, Reference? b) {
    return _checkingState.assumeReferences(a, b);
  }

  /// Returns `true` if [a] and [b] are equivalent, either by existing
  /// assumption or as defined by their corresponding canonical names.
  /// Inequivalence is _not_ registered.
  bool matchReferences(Reference? a, Reference? b) {
    return identical(a, b) ||
        checkAssumedReferences(a, b) ||
        ReferenceName.fromReference(a) == ReferenceName.fromReference(b);
  }

  /// Returns `true` if [a] and [b] are equivalent, either by their
  /// corresponding canonical names or by assumption. Inequivalence is _not_
  /// registered.
  bool _checkReferences(Reference? a, Reference? b) {
    if (identical(a, b)) {
      return true;
    } else if (a == null || b == null) {
      return false;
    } else if (matchReferences(a, b)) {
      return true;
    } else if (checkAssumedReferences(a, b)) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns `true` if [a] and [b] are equivalent, either by their
  /// corresponding canonical names or by assumption, and registers the
  /// inequivalence otherwise.
  bool checkReferences(Reference? a, Reference? b, [String propertyName = '']) {
    bool result = _checkReferences(a, b);
    if (!result) {
      registerInequivalence(
          propertyName, 'Inequivalent references:\n1: ${a}\n2: ${b}');
    }
    return result;
  }

  /// Returns `true` if declarations [a] and [b] are currently assumed to be
  /// equivalent.
  bool checkAssumedDeclarations(dynamic a, dynamic b) {
    return _checkingState.checkAssumedDeclarations(a, b);
  }

  /// Assume that [a] and [b] are equivalent, if possible.
  ///
  /// Returns `true` if [a] and [b] could be assumed to be equivalent. This
  /// would not be the case if [a] is already assumed to be equivalent to
  /// another declaration.
  bool assumeDeclarations(dynamic a, dynamic b) {
    return _checkingState.assumeDeclarations(a, b);
  }

  bool matchDeclarations(dynamic a, dynamic b) {
    if (a is LabeledStatement) {
      return b is LabeledStatement;
    }
    if (a is VariableDeclaration) {
      return b is VariableDeclaration && a.name == b.name;
    }
    if (a is SwitchCase) {
      return b is SwitchCase;
    }
    if (a is TypeParameter) {
      return b is TypeParameter && a.name == b.name;
    }
    if (a is StructuralParameter) {
      return b is StructuralParameter && a.name == b.name;
    }
    return false;
  }

  bool _checkDeclarations(dynamic a, dynamic b) {
    if (identical(a, b)) {
      return true;
    } else if (a == null || b == null) {
      return false;
    } else if (checkAssumedDeclarations(a, b)) {
      return true;
    } else if (matchDeclarations(a, b)) {
      return assumeDeclarations(a, b);
    } else {
      return false;
    }
  }

  bool checkDeclarations(dynamic a, dynamic b, [String propertyName = '']) {
    bool result = _checkDeclarations(a, b);
    if (!result) {
      result = assumeDeclarations(a, b);
    }
    if (!result) {
      registerInequivalence(
          propertyName, 'Declarations ${a} and ${b} are not equivalent');
    }
    return result;
  }

  /// Returns `true` if lists [a] and [b] are equivalent, using
  /// [equivalentValues] to determine element-wise equivalence.
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool checkLists<E>(
      List<E>? a, List<E>? b, bool Function(E?, E?, String) equivalentValues,
      [String propertyName = '']) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) {
      registerInequivalence(
          '${propertyName}.length', 'Lists ${a} and ${b} are not equivalent');
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!equivalentValues(a[i], b[i], '${propertyName}[${i}]')) {
        return false;
      }
    }
    return true;
  }

  /// Returns `true` if sets [a] and [b] are equivalent, using
  /// [matchingValues] to determine which elements that should be checked for
  /// element-wise equivalence using [equivalentValues].
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool checkSets<E>(Set<E>? a, Set<E>? b, bool Function(E?, E?) matchingValues,
      bool Function(E?, E?, String) equivalentValues,
      [String propertyName = '']) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) {
      registerInequivalence(
          '${propertyName}.length', 'Sets ${a} and ${b} are not equivalent');
      return false;
    }
    b = b.toSet();
    for (E aValue in a) {
      bool hasFoundValue = false;
      E? foundValue;
      for (E bValue in b) {
        if (matchingValues(aValue, bValue)) {
          foundValue = bValue;
          hasFoundValue = true;
          if (!equivalentValues(aValue, bValue, '${propertyName}[${aValue}]')) {
            registerInequivalence('${propertyName}[${aValue}]',
                'Elements ${aValue} and ${bValue} are not equivalent');
            return false;
          }
          break;
        }
      }
      if (hasFoundValue) {
        b.remove(foundValue);
      } else {
        registerInequivalence(
            '${propertyName}[${aValue}]',
            'Sets ${a} and ${b} are not equivalent, no equivalent value '
                'found for $aValue');
        return false;
      }
    }
    return true;
  }

  /// Returns `true` if maps [a] and [b] are equivalent, using
  /// [matchingKeys] to determine which entries that should be checked for
  /// entry-wise equivalence using [equivalentKeys] and [equivalentValues] to
  /// determine key and value equivalences, respectively.
  ///
  /// If run in a checking state, the [propertyName] is used for registering
  /// inequivalences.
  bool checkMaps<K, V>(
      Map<K, V>? a,
      Map<K, V>? b,
      bool Function(K?, K?) matchingKeys,
      bool Function(K?, K?, String) equivalentKeys,
      bool Function(V?, V?, String) equivalentValues,
      [String propertyName = '']) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) {
      registerInequivalence(
          '${propertyName}.length', 'Maps ${a} and ${b} are not equivalent');
      return false;
    }
    Set<K> bKeys = b.keys.toSet();
    for (K aKey in a.keys) {
      bool hasFoundKey = false;
      K? foundKey;
      for (K bKey in bKeys) {
        if (matchingKeys(aKey, bKey)) {
          foundKey = bKey;
          hasFoundKey = true;
          if (!equivalentKeys(aKey, bKey, '${propertyName}[${aKey}]')) {
            registerInequivalence('${propertyName}[${aKey}]',
                'Keys ${aKey} and ${bKey} are not equivalent');
            return false;
          }
          break;
        }
      }
      if (hasFoundKey) {
        bKeys.remove(foundKey);
        if (!equivalentValues(
            a[aKey], b[foundKey], '${propertyName}[${aKey}]')) {
          return false;
        }
      } else {
        registerInequivalence(
            '${propertyName}[${aKey}]',
            'Maps ${a} and ${b} are not equivalent, no equivalent key '
                'found for $aKey');
        return false;
      }
    }
    return true;
  }

  /// The current state of the visitor.
  ///
  /// This holds the current assumptions, found inequivalences, and whether
  /// inequivalences are currently registered.
  CheckingState _checkingState = new CheckingState();

  /// Registers that the visitor enters nodes [a] and [b].
  void pushNodeState(Node a, Node b) {
    _checkingState.pushNodeState(a, b);
  }

  /// Register that the visitor leave the current node or property.
  void popState() {
    _checkingState.popState();
  }

  /// Returns the value used as the result for property inequivalences.
  ///
  /// When inequivalences are currently registered, this is `true`, so that the
  /// visitor will continue find inequivalences that are not directly related.
  ///
  /// An example is finding several child inequivalences on otherwise equivalent
  /// nodes, like finding inequivalences deeply in the members of the second
  /// library of a component even when inequivalences deeply in the members of
  /// the first library. Had the return value been `false`, signaling that the
  /// first libraries were inequivalent, which they technically are, given that
  /// the contain inequivalent subnodes, the visitor would have stopped short in
  /// checking the list of libraries, and the inequivalences in the second
  /// library would not have been found.
  ///
  /// When inequivalences are _not_ currently registered, i.e. we are only
  /// interested in the true/false value of the equivalence test, `false` is
  /// used as the result value to stop the equivalence checking short.
  bool get resultOnInequivalence => _checkingState.resultOnInequivalence;

  /// Registers an equivalence on the [propertyName] with a detailed description
  /// in [message].
  void registerInequivalence(String propertyName, String message) {
    _checkingState.registerInequivalence(propertyName, message);
  }

  /// Returns the inequivalences found by the visitor.
  EquivalenceResult toResult() => _checkingState.toResult();
}

/// Checks [a] and [b] be for equivalence using [strategy].
///
/// Returns an [EquivalenceResult] containing the found inequivalences.
EquivalenceResult checkEquivalence(Node a, Node b,
    {EquivalenceStrategy strategy = const EquivalenceStrategy()}) {
  EquivalenceVisitor visitor = new EquivalenceVisitor(strategy: strategy);
  visitor.checkNodes(a, b, 'root');
  return visitor.toResult();
}

/// Strategy used for determining equivalence of AST nodes.
///
/// The strategy has a method for determining the equivalence of each AST node
/// class, and a method for determining the equivalence of each property on each
/// AST node class.
///
/// The base implementation enforces a full structural equivalence.
///
/// Custom strategies can be made by extending this strategy and override
/// methods where exceptions to the structural equivalence are needed.
class EquivalenceStrategy {
  const EquivalenceStrategy();

  bool checkLibrary(EquivalenceVisitor visitor, Library? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Library) return false;
    if (other is! Library) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLibrary_importUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_languageVersion(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_problemsAsJson(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_dependencies(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_additionalExports(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_parts(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_typedefs(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_classes(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_extensions(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_extensionTypeDeclarations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_procedures(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_fields(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibrary_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypedef(EquivalenceVisitor visitor, Typedef? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Typedef) return false;
    if (other is! Typedef) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypedef_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedef_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkClass(EquivalenceVisitor visitor, Class? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Class) return false;
    if (other is! Class) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkClass_startFileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_supertype(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_mixedInType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_implementedTypes(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_fields(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_constructors(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_procedures(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkClass_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkExtensionMemberDescriptor(EquivalenceVisitor visitor,
      ExtensionMemberDescriptor? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ExtensionMemberDescriptor) return false;
    if (other is! ExtensionMemberDescriptor) return false;
    bool result = true;
    if (!checkExtensionMemberDescriptor_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionMemberDescriptor_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionMemberDescriptor_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionMemberDescriptor_memberReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionMemberDescriptor_tearOffReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    return result;
  }

  bool checkExtension(
      EquivalenceVisitor visitor, Extension? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Extension) return false;
    if (other is! Extension) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkExtension_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_onType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_memberDescriptors(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtension_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkExtensionTypeMemberDescriptor(EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ExtensionTypeMemberDescriptor) return false;
    if (other is! ExtensionTypeMemberDescriptor) return false;
    bool result = true;
    if (!checkExtensionTypeMemberDescriptor_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeMemberDescriptor_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeMemberDescriptor_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeMemberDescriptor_memberReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeMemberDescriptor_tearOffReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    return result;
  }

  bool checkExtensionTypeDeclaration(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ExtensionTypeDeclaration) return false;
    if (other is! ExtensionTypeDeclaration) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkExtensionTypeDeclaration_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_declaredRepresentationType(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_representationName(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_procedures(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_memberDescriptors(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_implements(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionTypeDeclaration_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkField(EquivalenceVisitor visitor, Field? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Field) return false;
    if (other is! Field) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkField_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_initializer(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_getterReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_setterReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_transformerFlags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_fieldReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkField_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstructor(
      EquivalenceVisitor visitor, Constructor? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Constructor) return false;
    if (other is! Constructor) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstructor_startFileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_function(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_initializers(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_transformerFlags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructor_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkProcedure(
      EquivalenceVisitor visitor, Procedure? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Procedure) return false;
    if (other is! Procedure) return false;
    if (!visitor.matchNamedNodes(node, other)) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkProcedure_fileStartOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_function(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_stubKind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_stubTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_signatureType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_transformerFlags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_reference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkProcedure_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLibraryDependency(
      EquivalenceVisitor visitor, LibraryDependency? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LibraryDependency) return false;
    if (other is! LibraryDependency) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLibraryDependency_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryDependency_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryDependency_importedLibraryReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryDependency_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryDependency_combinators(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryDependency_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLibraryPart(
      EquivalenceVisitor visitor, LibraryPart? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LibraryPart) return false;
    if (other is! LibraryPart) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLibraryPart_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryPart_partUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLibraryPart_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkCombinator(
      EquivalenceVisitor visitor, Combinator? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Combinator) return false;
    if (other is! Combinator) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkCombinator_isShow(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCombinator_names(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCombinator_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAuxiliaryInitializer(
      EquivalenceVisitor visitor, AuxiliaryInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AuxiliaryInitializer) return false;
    if (other is! AuxiliaryInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAuxiliaryInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAuxiliaryInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInvalidInitializer(
      EquivalenceVisitor visitor, InvalidInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InvalidInitializer) return false;
    if (other is! InvalidInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInvalidInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInvalidInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFieldInitializer(
      EquivalenceVisitor visitor, FieldInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FieldInitializer) return false;
    if (other is! FieldInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFieldInitializer_fieldReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFieldInitializer_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFieldInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFieldInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSuperInitializer(
      EquivalenceVisitor visitor, SuperInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SuperInitializer) return false;
    if (other is! SuperInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSuperInitializer_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperInitializer_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRedirectingInitializer(
      EquivalenceVisitor visitor, RedirectingInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RedirectingInitializer) return false;
    if (other is! RedirectingInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRedirectingInitializer_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingInitializer_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLocalInitializer(
      EquivalenceVisitor visitor, LocalInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LocalInitializer) return false;
    if (other is! LocalInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLocalInitializer_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLocalInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLocalInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAssertInitializer(
      EquivalenceVisitor visitor, AssertInitializer? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AssertInitializer) return false;
    if (other is! AssertInitializer) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAssertInitializer_statement(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertInitializer_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertInitializer_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRedirectingFactoryTarget(EquivalenceVisitor visitor,
      RedirectingFactoryTarget? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RedirectingFactoryTarget) return false;
    if (other is! RedirectingFactoryTarget) return false;
    bool result = true;
    if (!checkRedirectingFactoryTarget_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingFactoryTarget_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingFactoryTarget_errorMessage(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    return result;
  }

  bool checkFunctionNode(
      EquivalenceVisitor visitor, FunctionNode? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionNode) return false;
    if (other is! FunctionNode) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionNode_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_asyncMarker(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_dartAsyncMarker(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_requiredParameterCount(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_positionalParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_namedParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_returnType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_emittedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_redirectingFactoryTarget(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_lazyBuilder(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionNode_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAuxiliaryExpression(
      EquivalenceVisitor visitor, AuxiliaryExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AuxiliaryExpression) return false;
    if (other is! AuxiliaryExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAuxiliaryExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInvalidExpression(
      EquivalenceVisitor visitor, InvalidExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InvalidExpression) return false;
    if (other is! InvalidExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInvalidExpression_message(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInvalidExpression_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInvalidExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkVariableGet(
      EquivalenceVisitor visitor, VariableGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! VariableGet) return false;
    if (other is! VariableGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkVariableGet_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableGet_promotedType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkVariableSet(
      EquivalenceVisitor visitor, VariableSet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! VariableSet) return false;
    if (other is! VariableSet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkVariableSet_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableSet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableSet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordIndexGet(
      EquivalenceVisitor visitor, RecordIndexGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordIndexGet) return false;
    if (other is! RecordIndexGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordIndexGet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordIndexGet_receiverType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordIndexGet_index(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordIndexGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordNameGet(
      EquivalenceVisitor visitor, RecordNameGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordNameGet) return false;
    if (other is! RecordNameGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordNameGet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordNameGet_receiverType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordNameGet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordNameGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDynamicGet(
      EquivalenceVisitor visitor, DynamicGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DynamicGet) return false;
    if (other is! DynamicGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDynamicGet_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicGet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicGet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceGet(
      EquivalenceVisitor visitor, InstanceGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceGet) return false;
    if (other is! InstanceGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceGet_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGet_resultType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGet_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFunctionTearOff(
      EquivalenceVisitor visitor, FunctionTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionTearOff) return false;
    if (other is! FunctionTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionTearOff_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceTearOff(
      EquivalenceVisitor visitor, InstanceTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceTearOff) return false;
    if (other is! InstanceTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceTearOff_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceTearOff_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceTearOff_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceTearOff_resultType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceTearOff_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDynamicSet(
      EquivalenceVisitor visitor, DynamicSet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DynamicSet) return false;
    if (other is! DynamicSet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDynamicSet_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicSet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicSet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicSet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicSet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceSet(
      EquivalenceVisitor visitor, InstanceSet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceSet) return false;
    if (other is! InstanceSet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceSet_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceSet_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceSet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceSet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceSet_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceSet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAbstractSuperPropertyGet(EquivalenceVisitor visitor,
      AbstractSuperPropertyGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AbstractSuperPropertyGet) return false;
    if (other is! AbstractSuperPropertyGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAbstractSuperPropertyGet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperPropertyGet_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperPropertyGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSuperPropertyGet(
      EquivalenceVisitor visitor, SuperPropertyGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SuperPropertyGet) return false;
    if (other is! SuperPropertyGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSuperPropertyGet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperPropertyGet_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperPropertyGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAbstractSuperPropertySet(EquivalenceVisitor visitor,
      AbstractSuperPropertySet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AbstractSuperPropertySet) return false;
    if (other is! AbstractSuperPropertySet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAbstractSuperPropertySet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperPropertySet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperPropertySet_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperPropertySet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSuperPropertySet(
      EquivalenceVisitor visitor, SuperPropertySet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SuperPropertySet) return false;
    if (other is! SuperPropertySet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSuperPropertySet_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperPropertySet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperPropertySet_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperPropertySet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStaticGet(
      EquivalenceVisitor visitor, StaticGet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StaticGet) return false;
    if (other is! StaticGet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStaticGet_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticGet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStaticTearOff(
      EquivalenceVisitor visitor, StaticTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StaticTearOff) return false;
    if (other is! StaticTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStaticTearOff_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStaticSet(
      EquivalenceVisitor visitor, StaticSet? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StaticSet) return false;
    if (other is! StaticSet) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStaticSet_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticSet_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticSet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDynamicInvocation(
      EquivalenceVisitor visitor, DynamicInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DynamicInvocation) return false;
    if (other is! DynamicInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDynamicInvocation_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicInvocation_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicInvocation_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicInvocation_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDynamicInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceInvocation(
      EquivalenceVisitor visitor, InstanceInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceInvocation) return false;
    if (other is! InstanceInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceInvocation_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceGetterInvocation(EquivalenceVisitor visitor,
      InstanceGetterInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceGetterInvocation) return false;
    if (other is! InstanceGetterInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceGetterInvocation_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceGetterInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFunctionInvocation(
      EquivalenceVisitor visitor, FunctionInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionInvocation) return false;
    if (other is! FunctionInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionInvocation_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionInvocation_receiver(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionInvocation_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLocalFunctionInvocation(EquivalenceVisitor visitor,
      LocalFunctionInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LocalFunctionInvocation) return false;
    if (other is! LocalFunctionInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLocalFunctionInvocation_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLocalFunctionInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLocalFunctionInvocation_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLocalFunctionInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAbstractSuperMethodInvocation(EquivalenceVisitor visitor,
      AbstractSuperMethodInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AbstractSuperMethodInvocation) return false;
    if (other is! AbstractSuperMethodInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAbstractSuperMethodInvocation_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperMethodInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperMethodInvocation_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAbstractSuperMethodInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSuperMethodInvocation(
      EquivalenceVisitor visitor, SuperMethodInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SuperMethodInvocation) return false;
    if (other is! SuperMethodInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSuperMethodInvocation_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperMethodInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperMethodInvocation_interfaceTargetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSuperMethodInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStaticInvocation(
      EquivalenceVisitor visitor, StaticInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StaticInvocation) return false;
    if (other is! StaticInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStaticInvocation_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticInvocation_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStaticInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstructorInvocation(
      EquivalenceVisitor visitor, ConstructorInvocation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstructorInvocation) return false;
    if (other is! ConstructorInvocation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstructorInvocation_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructorInvocation_arguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructorInvocation_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructorInvocation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkEqualsNull(
      EquivalenceVisitor visitor, EqualsNull? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! EqualsNull) return false;
    if (other is! EqualsNull) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkEqualsNull_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkEqualsNull_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkEqualsCall(
      EquivalenceVisitor visitor, EqualsCall? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! EqualsCall) return false;
    if (other is! EqualsCall) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkEqualsCall_left(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkEqualsCall_right(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkEqualsCall_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkEqualsCall_interfaceTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkEqualsCall_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstantiation(
      EquivalenceVisitor visitor, Instantiation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Instantiation) return false;
    if (other is! Instantiation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstantiation_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstantiation_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstantiation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNot(EquivalenceVisitor visitor, Not? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Not) return false;
    if (other is! Not) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNot_operand(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNot_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLogicalExpression(
      EquivalenceVisitor visitor, LogicalExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LogicalExpression) return false;
    if (other is! LogicalExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLogicalExpression_left(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLogicalExpression_operatorEnum(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLogicalExpression_right(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLogicalExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConditionalExpression(
      EquivalenceVisitor visitor, ConditionalExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConditionalExpression) return false;
    if (other is! ConditionalExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConditionalExpression_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConditionalExpression_then(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConditionalExpression_otherwise(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConditionalExpression_staticType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConditionalExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStringConcatenation(
      EquivalenceVisitor visitor, StringConcatenation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StringConcatenation) return false;
    if (other is! StringConcatenation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStringConcatenation_expressions(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStringConcatenation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkListConcatenation(
      EquivalenceVisitor visitor, ListConcatenation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ListConcatenation) return false;
    if (other is! ListConcatenation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkListConcatenation_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListConcatenation_lists(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListConcatenation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSetConcatenation(
      EquivalenceVisitor visitor, SetConcatenation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SetConcatenation) return false;
    if (other is! SetConcatenation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSetConcatenation_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetConcatenation_sets(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetConcatenation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapConcatenation(
      EquivalenceVisitor visitor, MapConcatenation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapConcatenation) return false;
    if (other is! MapConcatenation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapConcatenation_keyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapConcatenation_valueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapConcatenation_maps(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapConcatenation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceCreation(
      EquivalenceVisitor visitor, InstanceCreation? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceCreation) return false;
    if (other is! InstanceCreation) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceCreation_classReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceCreation_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceCreation_fieldValues(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceCreation_asserts(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceCreation_unusedArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceCreation_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFileUriExpression(
      EquivalenceVisitor visitor, FileUriExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FileUriExpression) return false;
    if (other is! FileUriExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFileUriExpression_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFileUriExpression_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFileUriExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIsExpression(
      EquivalenceVisitor visitor, IsExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IsExpression) return false;
    if (other is! IsExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIsExpression_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIsExpression_operand(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIsExpression_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIsExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAsExpression(
      EquivalenceVisitor visitor, AsExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AsExpression) return false;
    if (other is! AsExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAsExpression_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAsExpression_operand(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAsExpression_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAsExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNullCheck(
      EquivalenceVisitor visitor, NullCheck? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullCheck) return false;
    if (other is! NullCheck) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNullCheck_operand(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNullCheck_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStringLiteral(
      EquivalenceVisitor visitor, StringLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StringLiteral) return false;
    if (other is! StringLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStringLiteral_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStringLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIntLiteral(
      EquivalenceVisitor visitor, IntLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IntLiteral) return false;
    if (other is! IntLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIntLiteral_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIntLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDoubleLiteral(
      EquivalenceVisitor visitor, DoubleLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DoubleLiteral) return false;
    if (other is! DoubleLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDoubleLiteral_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDoubleLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkBoolLiteral(
      EquivalenceVisitor visitor, BoolLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! BoolLiteral) return false;
    if (other is! BoolLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkBoolLiteral_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBoolLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNullLiteral(
      EquivalenceVisitor visitor, NullLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullLiteral) return false;
    if (other is! NullLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNullLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSymbolLiteral(
      EquivalenceVisitor visitor, SymbolLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SymbolLiteral) return false;
    if (other is! SymbolLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSymbolLiteral_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSymbolLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypeLiteral(
      EquivalenceVisitor visitor, TypeLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypeLiteral) return false;
    if (other is! TypeLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypeLiteral_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkThisExpression(
      EquivalenceVisitor visitor, ThisExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ThisExpression) return false;
    if (other is! ThisExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkThisExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRethrow(EquivalenceVisitor visitor, Rethrow? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Rethrow) return false;
    if (other is! Rethrow) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRethrow_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkThrow(EquivalenceVisitor visitor, Throw? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Throw) return false;
    if (other is! Throw) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkThrow_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkThrow_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkThrow_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkListLiteral(
      EquivalenceVisitor visitor, ListLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ListLiteral) return false;
    if (other is! ListLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkListLiteral_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListLiteral_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListLiteral_expressions(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSetLiteral(
      EquivalenceVisitor visitor, SetLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SetLiteral) return false;
    if (other is! SetLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSetLiteral_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetLiteral_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetLiteral_expressions(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapLiteral(
      EquivalenceVisitor visitor, MapLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapLiteral) return false;
    if (other is! MapLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapLiteral_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteral_keyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteral_valueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteral_entries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordLiteral(
      EquivalenceVisitor visitor, RecordLiteral? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordLiteral) return false;
    if (other is! RecordLiteral) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordLiteral_isConst(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordLiteral_positional(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordLiteral_named(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordLiteral_recordType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordLiteral_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAwaitExpression(
      EquivalenceVisitor visitor, AwaitExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AwaitExpression) return false;
    if (other is! AwaitExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAwaitExpression_operand(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAwaitExpression_runtimeCheckType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAwaitExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFunctionExpression(
      EquivalenceVisitor visitor, FunctionExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionExpression) return false;
    if (other is! FunctionExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionExpression_function(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstantExpression(
      EquivalenceVisitor visitor, ConstantExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstantExpression) return false;
    if (other is! ConstantExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstantExpression_constant(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantExpression_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLet(EquivalenceVisitor visitor, Let? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Let) return false;
    if (other is! Let) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLet_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLet_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLet_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkBlockExpression(
      EquivalenceVisitor visitor, BlockExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! BlockExpression) return false;
    if (other is! BlockExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkBlockExpression_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBlockExpression_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBlockExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLoadLibrary(
      EquivalenceVisitor visitor, LoadLibrary? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LoadLibrary) return false;
    if (other is! LoadLibrary) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLoadLibrary_import(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLoadLibrary_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkCheckLibraryIsLoaded(
      EquivalenceVisitor visitor, CheckLibraryIsLoaded? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! CheckLibraryIsLoaded) return false;
    if (other is! CheckLibraryIsLoaded) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkCheckLibraryIsLoaded_import(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCheckLibraryIsLoaded_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstructorTearOff(
      EquivalenceVisitor visitor, ConstructorTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstructorTearOff) return false;
    if (other is! ConstructorTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstructorTearOff_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstructorTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRedirectingFactoryTearOff(EquivalenceVisitor visitor,
      RedirectingFactoryTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RedirectingFactoryTearOff) return false;
    if (other is! RedirectingFactoryTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRedirectingFactoryTearOff_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRedirectingFactoryTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypedefTearOff(
      EquivalenceVisitor visitor, TypedefTearOff? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypedefTearOff) return false;
    if (other is! TypedefTearOff) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypedefTearOff_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefTearOff_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefTearOff_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefTearOff_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSwitchExpression(
      EquivalenceVisitor visitor, SwitchExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SwitchExpression) return false;
    if (other is! SwitchExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSwitchExpression_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpression_cases(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpression_expressionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpression_staticType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkPatternAssignment(
      EquivalenceVisitor visitor, PatternAssignment? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! PatternAssignment) return false;
    if (other is! PatternAssignment) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkPatternAssignment_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternAssignment_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternAssignment_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternAssignment_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkArguments(
      EquivalenceVisitor visitor, Arguments? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Arguments) return false;
    if (other is! Arguments) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkArguments_types(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkArguments_positional(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkArguments_named(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkArguments_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNamedExpression(
      EquivalenceVisitor visitor, NamedExpression? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NamedExpression) return false;
    if (other is! NamedExpression) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNamedExpression_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedExpression_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedExpression_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapLiteralEntry(
      EquivalenceVisitor visitor, MapLiteralEntry? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapLiteralEntry) return false;
    if (other is! MapLiteralEntry) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapLiteralEntry_key(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteralEntry_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapLiteralEntry_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAuxiliaryStatement(
      EquivalenceVisitor visitor, AuxiliaryStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AuxiliaryStatement) return false;
    if (other is! AuxiliaryStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAuxiliaryStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkExpressionStatement(
      EquivalenceVisitor visitor, ExpressionStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ExpressionStatement) return false;
    if (other is! ExpressionStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkExpressionStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExpressionStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkBlock(EquivalenceVisitor visitor, Block? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Block) return false;
    if (other is! Block) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkBlock_statements(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBlock_fileEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBlock_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAssertBlock(
      EquivalenceVisitor visitor, AssertBlock? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AssertBlock) return false;
    if (other is! AssertBlock) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAssertBlock_statements(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertBlock_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkEmptyStatement(
      EquivalenceVisitor visitor, EmptyStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! EmptyStatement) return false;
    if (other is! EmptyStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkEmptyStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAssertStatement(
      EquivalenceVisitor visitor, AssertStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AssertStatement) return false;
    if (other is! AssertStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAssertStatement_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertStatement_message(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertStatement_conditionStartOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertStatement_conditionEndOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssertStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLabeledStatement(
      EquivalenceVisitor visitor, LabeledStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! LabeledStatement) return false;
    if (other is! LabeledStatement) return false;
    if (!visitor.checkDeclarations(node, other, '')) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkLabeledStatement_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkLabeledStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkBreakStatement(
      EquivalenceVisitor visitor, BreakStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! BreakStatement) return false;
    if (other is! BreakStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkBreakStatement_target(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkBreakStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkWhileStatement(
      EquivalenceVisitor visitor, WhileStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! WhileStatement) return false;
    if (other is! WhileStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkWhileStatement_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkWhileStatement_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkWhileStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDoStatement(
      EquivalenceVisitor visitor, DoStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DoStatement) return false;
    if (other is! DoStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDoStatement_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDoStatement_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkDoStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkForStatement(
      EquivalenceVisitor visitor, ForStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ForStatement) return false;
    if (other is! ForStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkForStatement_variables(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForStatement_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForStatement_updates(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForStatement_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkForInStatement(
      EquivalenceVisitor visitor, ForInStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ForInStatement) return false;
    if (other is! ForInStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkForInStatement_bodyOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForInStatement_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForInStatement_iterable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForInStatement_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForInStatement_isAsync(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkForInStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSwitchStatement(
      EquivalenceVisitor visitor, SwitchStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SwitchStatement) return false;
    if (other is! SwitchStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSwitchStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchStatement_cases(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchStatement_isExplicitlyExhaustive(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchStatement_expressionTypeInternal(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkContinueSwitchStatement(EquivalenceVisitor visitor,
      ContinueSwitchStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ContinueSwitchStatement) return false;
    if (other is! ContinueSwitchStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkContinueSwitchStatement_target(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkContinueSwitchStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIfStatement(
      EquivalenceVisitor visitor, IfStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IfStatement) return false;
    if (other is! IfStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIfStatement_condition(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfStatement_then(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfStatement_otherwise(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkReturnStatement(
      EquivalenceVisitor visitor, ReturnStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ReturnStatement) return false;
    if (other is! ReturnStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkReturnStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkReturnStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTryCatch(
      EquivalenceVisitor visitor, TryCatch? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TryCatch) return false;
    if (other is! TryCatch) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTryCatch_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTryCatch_catches(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTryCatch_isSynthetic(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTryCatch_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTryFinally(
      EquivalenceVisitor visitor, TryFinally? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TryFinally) return false;
    if (other is! TryFinally) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTryFinally_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTryFinally_finalizer(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTryFinally_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkYieldStatement(
      EquivalenceVisitor visitor, YieldStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! YieldStatement) return false;
    if (other is! YieldStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkYieldStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkYieldStatement_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkYieldStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkVariableDeclaration(
      EquivalenceVisitor visitor, VariableDeclaration? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! VariableDeclaration) return false;
    if (other is! VariableDeclaration) return false;
    if (!visitor.checkDeclarations(node, other, '')) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkVariableDeclaration_fileEqualsOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_binaryOffsetNoTag(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_initializer(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariableDeclaration_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFunctionDeclaration(
      EquivalenceVisitor visitor, FunctionDeclaration? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionDeclaration) return false;
    if (other is! FunctionDeclaration) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionDeclaration_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionDeclaration_function(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionDeclaration_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkPatternSwitchStatement(
      EquivalenceVisitor visitor, PatternSwitchStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! PatternSwitchStatement) return false;
    if (other is! PatternSwitchStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkPatternSwitchStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchStatement_cases(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchStatement_expressionTypeInternal(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchStatement_lastCaseTerminates(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchStatement_isExplicitlyExhaustive(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkPatternVariableDeclaration(EquivalenceVisitor visitor,
      PatternVariableDeclaration? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! PatternVariableDeclaration) return false;
    if (other is! PatternVariableDeclaration) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkPatternVariableDeclaration_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternVariableDeclaration_initializer(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternVariableDeclaration_isFinal(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternVariableDeclaration_matchedValueType(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternVariableDeclaration_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIfCaseStatement(
      EquivalenceVisitor visitor, IfCaseStatement? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IfCaseStatement) return false;
    if (other is! IfCaseStatement) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIfCaseStatement_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfCaseStatement_patternGuard(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfCaseStatement_then(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfCaseStatement_otherwise(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfCaseStatement_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIfCaseStatement_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSwitchCase(
      EquivalenceVisitor visitor, SwitchCase? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SwitchCase) return false;
    if (other is! SwitchCase) return false;
    if (!visitor.checkDeclarations(node, other, '')) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSwitchCase_expressions(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchCase_expressionOffsets(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchCase_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchCase_isDefault(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchCase_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkCatch(EquivalenceVisitor visitor, Catch? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Catch) return false;
    if (other is! Catch) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkCatch_guard(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCatch_exception(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCatch_stackTrace(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCatch_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCatch_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypeParameter(
      EquivalenceVisitor visitor, TypeParameter? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypeParameter) return false;
    if (other is! TypeParameter) return false;
    if (!visitor.checkDeclarations(node, other, '')) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypeParameter_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_annotations(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_bound(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_defaultType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_variance(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameter_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSource(EquivalenceVisitor visitor, Source? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Source) return false;
    if (other is! Source) return false;
    bool result = true;
    if (!checkSource_lineStarts(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSource_source(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSource_importUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSource_fileUri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSource_constantCoverageConstructors(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSource_cachedText(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    return result;
  }

  bool checkMetadataRepository(
      EquivalenceVisitor visitor, MetadataRepository? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MetadataRepository) return false;
    if (other is! MetadataRepository) return false;
    bool result = true;
    return result;
  }

  bool checkComponent(
      EquivalenceVisitor visitor, Component? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Component) return false;
    if (other is! Component) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkComponent_problemsAsJson(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_libraries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_uriToSource(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_metadata(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_mainMethodName(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_mode(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkComponent_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstantPattern(
      EquivalenceVisitor visitor, ConstantPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstantPattern) return false;
    if (other is! ConstantPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstantPattern_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantPattern_expressionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantPattern_equalsTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantPattern_equalsType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantPattern_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAndPattern(
      EquivalenceVisitor visitor, AndPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AndPattern) return false;
    if (other is! AndPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAndPattern_left(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAndPattern_right(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAndPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkOrPattern(
      EquivalenceVisitor visitor, OrPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! OrPattern) return false;
    if (other is! OrPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkOrPattern_left(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkOrPattern_right(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkOrPattern_orPatternJointVariables(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkOrPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkCastPattern(
      EquivalenceVisitor visitor, CastPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! CastPattern) return false;
    if (other is! CastPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkCastPattern_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCastPattern_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkCastPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNullAssertPattern(
      EquivalenceVisitor visitor, NullAssertPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullAssertPattern) return false;
    if (other is! NullAssertPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNullAssertPattern_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNullAssertPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNullCheckPattern(
      EquivalenceVisitor visitor, NullCheckPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullCheckPattern) return false;
    if (other is! NullCheckPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNullCheckPattern_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNullCheckPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkListPattern(
      EquivalenceVisitor visitor, ListPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ListPattern) return false;
    if (other is! ListPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkListPattern_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_patterns(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_requiredType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_needsCheck(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_lookupType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_hasRestPattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_lengthTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_lengthType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_lengthCheckTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_lengthCheckType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_sublistTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_sublistType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_minusTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_minusType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_indexGetTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_indexGetType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkObjectPattern(
      EquivalenceVisitor visitor, ObjectPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ObjectPattern) return false;
    if (other is! ObjectPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkObjectPattern_requiredType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkObjectPattern_fields(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkObjectPattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkObjectPattern_needsCheck(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkObjectPattern_lookupType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkObjectPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRelationalPattern(
      EquivalenceVisitor visitor, RelationalPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RelationalPattern) return false;
    if (other is! RelationalPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRelationalPattern_kind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_expressionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_accessKind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_expressionValue(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRelationalPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkWildcardPattern(
      EquivalenceVisitor visitor, WildcardPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! WildcardPattern) return false;
    if (other is! WildcardPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkWildcardPattern_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkWildcardPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAssignedVariablePattern(EquivalenceVisitor visitor,
      AssignedVariablePattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AssignedVariablePattern) return false;
    if (other is! AssignedVariablePattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkAssignedVariablePattern_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssignedVariablePattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssignedVariablePattern_needsCast(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssignedVariablePattern_hasObservableEffect(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkAssignedVariablePattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapPattern(
      EquivalenceVisitor visitor, MapPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapPattern) return false;
    if (other is! MapPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapPattern_keyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_valueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_entries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_requiredType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_needsCheck(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_lookupType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_containsKeyTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_containsKeyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_indexGetTargetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_indexGetType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNamedPattern(
      EquivalenceVisitor visitor, NamedPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NamedPattern) return false;
    if (other is! NamedPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNamedPattern_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_fieldName(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_accessKind(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_resultType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_checkReturn(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_recordType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_recordFieldIndex(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_functionType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordPattern(
      EquivalenceVisitor visitor, RecordPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordPattern) return false;
    if (other is! RecordPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordPattern_patterns(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordPattern_requiredType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordPattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordPattern_needsCheck(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordPattern_lookupType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkVariablePattern(
      EquivalenceVisitor visitor, VariablePattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! VariablePattern) return false;
    if (other is! VariablePattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkVariablePattern_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariablePattern_variable(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariablePattern_matchedValueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkVariablePattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRestPattern(
      EquivalenceVisitor visitor, RestPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RestPattern) return false;
    if (other is! RestPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRestPattern_subPattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRestPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInvalidPattern(
      EquivalenceVisitor visitor, InvalidPattern? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InvalidPattern) return false;
    if (other is! InvalidPattern) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInvalidPattern_invalidExpression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInvalidPattern_declaredVariables(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInvalidPattern_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapPatternEntry(
      EquivalenceVisitor visitor, MapPatternEntry? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapPatternEntry) return false;
    if (other is! MapPatternEntry) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapPatternEntry_key(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPatternEntry_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPatternEntry_keyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPatternEntry_keyValue(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapPatternEntry_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkMapPatternRestEntry(
      EquivalenceVisitor visitor, MapPatternRestEntry? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapPatternRestEntry) return false;
    if (other is! MapPatternRestEntry) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapPatternRestEntry_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkPatternGuard(
      EquivalenceVisitor visitor, PatternGuard? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! PatternGuard) return false;
    if (other is! PatternGuard) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkPatternGuard_pattern(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternGuard_guard(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternGuard_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkPatternSwitchCase(
      EquivalenceVisitor visitor, PatternSwitchCase? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! PatternSwitchCase) return false;
    if (other is! PatternSwitchCase) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkPatternSwitchCase_caseOffsets(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_patternGuards(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_labelUsers(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_body(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_isDefault(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_hasLabel(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_jointVariables(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_jointVariableFirstUseOffsets(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkPatternSwitchCase_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSwitchExpressionCase(
      EquivalenceVisitor visitor, SwitchExpressionCase? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SwitchExpressionCase) return false;
    if (other is! SwitchExpressionCase) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSwitchExpressionCase_patternGuard(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpressionCase_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSwitchExpressionCase_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkName(EquivalenceVisitor visitor, Name? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Name) return false;
    if (other is! Name) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkName_text(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInterfaceType(
      EquivalenceVisitor visitor, InterfaceType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InterfaceType) return false;
    if (other is! InterfaceType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInterfaceType_classReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInterfaceType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInterfaceType_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkExtensionType(
      EquivalenceVisitor visitor, ExtensionType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ExtensionType) return false;
    if (other is! ExtensionType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkExtensionType_extensionTypeDeclarationReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkExtensionType_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAuxiliaryType(
      EquivalenceVisitor visitor, AuxiliaryType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AuxiliaryType) return false;
    if (other is! AuxiliaryType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkInvalidType(
      EquivalenceVisitor visitor, InvalidType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InvalidType) return false;
    if (other is! InvalidType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkDynamicType(
      EquivalenceVisitor visitor, DynamicType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DynamicType) return false;
    if (other is! DynamicType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkVoidType(
      EquivalenceVisitor visitor, VoidType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! VoidType) return false;
    if (other is! VoidType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkNeverType(
      EquivalenceVisitor visitor, NeverType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NeverType) return false;
    if (other is! NeverType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNeverType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNullType(
      EquivalenceVisitor visitor, NullType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullType) return false;
    if (other is! NullType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkFunctionType(
      EquivalenceVisitor visitor, FunctionType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FunctionType) return false;
    if (other is! FunctionType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFunctionType_typeParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionType_requiredParameterCount(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionType_positionalParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionType_namedParameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFunctionType_returnType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypedefType(
      EquivalenceVisitor visitor, TypedefType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypedefType) return false;
    if (other is! TypedefType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypedefType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefType_typedefReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefType_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkFutureOrType(
      EquivalenceVisitor visitor, FutureOrType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! FutureOrType) return false;
    if (other is! FutureOrType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkFutureOrType_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkFutureOrType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIntersectionType(
      EquivalenceVisitor visitor, IntersectionType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IntersectionType) return false;
    if (other is! IntersectionType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIntersectionType_left(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkIntersectionType_right(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypeParameterType(
      EquivalenceVisitor visitor, TypeParameterType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypeParameterType) return false;
    if (other is! TypeParameterType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypeParameterType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypeParameterType_parameter(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStructuralParameterType(EquivalenceVisitor visitor,
      StructuralParameterType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StructuralParameterType) return false;
    if (other is! StructuralParameterType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStructuralParameterType_declaredNullability(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameterType_parameter(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordType(
      EquivalenceVisitor visitor, RecordType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordType) return false;
    if (other is! RecordType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordType_positional(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordType_named(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordType_declaredNullability(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkNamedType(
      EquivalenceVisitor visitor, NamedType? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NamedType) return false;
    if (other is! NamedType) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNamedType_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedType_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkNamedType_isRequired(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStructuralParameter(
      EquivalenceVisitor visitor, StructuralParameter? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StructuralParameter) return false;
    if (other is! StructuralParameter) return false;
    if (!visitor.checkDeclarations(node, other, '')) {
      return false;
    }
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStructuralParameter_flags(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_fileOffset(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_uri(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_bound(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_defaultType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkStructuralParameter_variance(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSupertype(
      EquivalenceVisitor visitor, Supertype? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! Supertype) return false;
    if (other is! Supertype) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSupertype_className(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSupertype_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkAuxiliaryConstant(
      EquivalenceVisitor visitor, AuxiliaryConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! AuxiliaryConstant) return false;
    if (other is! AuxiliaryConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    visitor.popState();
    return result;
  }

  bool checkNullConstant(
      EquivalenceVisitor visitor, NullConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! NullConstant) return false;
    if (other is! NullConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkNullConstant_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkBoolConstant(
      EquivalenceVisitor visitor, BoolConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! BoolConstant) return false;
    if (other is! BoolConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkBoolConstant_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkIntConstant(
      EquivalenceVisitor visitor, IntConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! IntConstant) return false;
    if (other is! IntConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkIntConstant_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkDoubleConstant(
      EquivalenceVisitor visitor, DoubleConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! DoubleConstant) return false;
    if (other is! DoubleConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkDoubleConstant_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStringConstant(
      EquivalenceVisitor visitor, StringConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StringConstant) return false;
    if (other is! StringConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStringConstant_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSymbolConstant(
      EquivalenceVisitor visitor, SymbolConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SymbolConstant) return false;
    if (other is! SymbolConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSymbolConstant_name(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSymbolConstant_libraryReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstantMapEntry(
      EquivalenceVisitor visitor, ConstantMapEntry? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstantMapEntry) return false;
    if (other is! ConstantMapEntry) return false;
    bool result = true;
    if (!checkConstantMapEntry_key(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkConstantMapEntry_value(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    return result;
  }

  bool checkMapConstant(
      EquivalenceVisitor visitor, MapConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! MapConstant) return false;
    if (other is! MapConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkMapConstant_keyType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapConstant_valueType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkMapConstant_entries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkListConstant(
      EquivalenceVisitor visitor, ListConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ListConstant) return false;
    if (other is! ListConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkListConstant_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkListConstant_entries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkSetConstant(
      EquivalenceVisitor visitor, SetConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! SetConstant) return false;
    if (other is! SetConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkSetConstant_typeArgument(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkSetConstant_entries(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRecordConstant(
      EquivalenceVisitor visitor, RecordConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RecordConstant) return false;
    if (other is! RecordConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRecordConstant_positional(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordConstant_named(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkRecordConstant_recordType(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstanceConstant(
      EquivalenceVisitor visitor, InstanceConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstanceConstant) return false;
    if (other is! InstanceConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstanceConstant_classReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceConstant_typeArguments(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstanceConstant_fieldValues(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkInstantiationConstant(
      EquivalenceVisitor visitor, InstantiationConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! InstantiationConstant) return false;
    if (other is! InstantiationConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkInstantiationConstant_tearOffConstant(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkInstantiationConstant_types(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkStaticTearOffConstant(
      EquivalenceVisitor visitor, StaticTearOffConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! StaticTearOffConstant) return false;
    if (other is! StaticTearOffConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkStaticTearOffConstant_targetReference(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkConstructorTearOffConstant(EquivalenceVisitor visitor,
      ConstructorTearOffConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! ConstructorTearOffConstant) return false;
    if (other is! ConstructorTearOffConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkConstructorTearOffConstant_targetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkRedirectingFactoryTearOffConstant(EquivalenceVisitor visitor,
      RedirectingFactoryTearOffConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! RedirectingFactoryTearOffConstant) return false;
    if (other is! RedirectingFactoryTearOffConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkRedirectingFactoryTearOffConstant_targetReference(
        visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypedefTearOffConstant(
      EquivalenceVisitor visitor, TypedefTearOffConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypedefTearOffConstant) return false;
    if (other is! TypedefTearOffConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypedefTearOffConstant_parameters(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefTearOffConstant_tearOffConstant(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    if (!checkTypedefTearOffConstant_types(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkTypeLiteralConstant(
      EquivalenceVisitor visitor, TypeLiteralConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! TypeLiteralConstant) return false;
    if (other is! TypeLiteralConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkTypeLiteralConstant_type(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkUnevaluatedConstant(
      EquivalenceVisitor visitor, UnevaluatedConstant? node, Object? other) {
    if (identical(node, other)) return true;
    if (node is! UnevaluatedConstant) return false;
    if (other is! UnevaluatedConstant) return false;
    visitor.pushNodeState(node, other);
    bool result = true;
    if (!checkUnevaluatedConstant_expression(visitor, node, other)) {
      result = visitor.resultOnInequivalence;
    }
    visitor.popState();
    return result;
  }

  bool checkLibrary_importUri(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkValues(node.importUri, other.importUri, 'importUri');
  }

  bool checkLibrary_fileUri(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkLibrary_languageVersion(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkValues(
        node.languageVersion, other.languageVersion, 'languageVersion');
  }

  bool checkLibrary_flags(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkLibrary_name(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkLibrary_problemsAsJson(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(node.problemsAsJson, other.problemsAsJson,
        visitor.checkValues, 'problemsAsJson');
  }

  bool checkLibrary_annotations(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkLibrary_dependencies(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(node.dependencies, other.dependencies,
        visitor.checkNodes, 'dependencies');
  }

  bool checkLibrary_additionalExports(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(node.additionalExports, other.additionalExports,
        visitor.checkReferences, 'additionalExports');
  }

  bool checkLibrary_parts(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.parts, other.parts, visitor.checkNodes, 'parts');
  }

  bool checkLibrary_typedefs(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.typedefs, other.typedefs, visitor.checkNodes, 'typedefs');
  }

  bool checkLibrary_classes(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.classes, other.classes, visitor.checkNodes, 'classes');
  }

  bool checkLibrary_extensions(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.extensions, other.extensions, visitor.checkNodes, 'extensions');
  }

  bool checkLibrary_extensionTypeDeclarations(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.extensionTypeDeclarations,
        other.extensionTypeDeclarations,
        visitor.checkNodes,
        'extensionTypeDeclarations');
  }

  bool checkLibrary_procedures(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.procedures, other.procedures, visitor.checkNodes, 'procedures');
  }

  bool checkLibrary_fields(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkLists(
        node.fields, other.fields, visitor.checkNodes, 'fields');
  }

  bool checkNamedNode_reference(
      EquivalenceVisitor visitor, NamedNode node, NamedNode other) {
    return visitor.checkReferences(
        node.reference, other.reference, 'reference');
  }

  bool checkLibrary_reference(
      EquivalenceVisitor visitor, Library node, Library other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkTreeNode_fileOffset(
      EquivalenceVisitor visitor, TreeNode node, TreeNode other) {
    return visitor.checkValues(node.fileOffset, other.fileOffset, 'fileOffset');
  }

  bool checkNamedNode_fileOffset(
      EquivalenceVisitor visitor, NamedNode node, NamedNode other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkLibrary_fileOffset(
      EquivalenceVisitor visitor, Library node, Library other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkTypedef_fileUri(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkTypedef_annotations(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkTypedef_name(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkTypedef_typeParameters(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkTypedef_type(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkTypedef_reference(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkTypedef_fileOffset(
      EquivalenceVisitor visitor, Typedef node, Typedef other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkClass_startFileOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkValues(
        node.startFileOffset, other.startFileOffset, 'startFileOffset');
  }

  bool checkClass_fileEndOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkValues(
        node.fileEndOffset, other.fileEndOffset, 'fileEndOffset');
  }

  bool checkClass_annotations(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkClass_name(EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkClass_flags(EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkClass_fileUri(EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkClass_typeParameters(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkClass_supertype(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkNodes(node.supertype, other.supertype, 'supertype');
  }

  bool checkClass_mixedInType(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkNodes(
        node.mixedInType, other.mixedInType, 'mixedInType');
  }

  bool checkClass_implementedTypes(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(node.implementedTypes, other.implementedTypes,
        visitor.checkNodes, 'implementedTypes');
  }

  bool checkClass_fields(EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(
        node.fields, other.fields, visitor.checkNodes, 'fields');
  }

  bool checkClass_constructors(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(node.constructors, other.constructors,
        visitor.checkNodes, 'constructors');
  }

  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    return visitor.checkLists(
        node.procedures, other.procedures, visitor.checkNodes, 'procedures');
  }

  bool checkClass_reference(
      EquivalenceVisitor visitor, Class node, Class other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkClass_fileOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkExtension_name(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkExtension_fileUri(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkExtension_typeParameters(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkExtension_onType(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkNodes(node.onType, other.onType, 'onType');
  }

  bool checkExtensionMemberDescriptor_name(EquivalenceVisitor visitor,
      ExtensionMemberDescriptor node, ExtensionMemberDescriptor other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkExtensionMemberDescriptor_kind(EquivalenceVisitor visitor,
      ExtensionMemberDescriptor node, ExtensionMemberDescriptor other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkExtensionMemberDescriptor_flags(EquivalenceVisitor visitor,
      ExtensionMemberDescriptor node, ExtensionMemberDescriptor other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkExtensionMemberDescriptor_memberReference(
      EquivalenceVisitor visitor,
      ExtensionMemberDescriptor node,
      ExtensionMemberDescriptor other) {
    return visitor.checkReferences(
        node.memberReference, other.memberReference, 'memberReference');
  }

  bool checkExtensionMemberDescriptor_tearOffReference(
      EquivalenceVisitor visitor,
      ExtensionMemberDescriptor node,
      ExtensionMemberDescriptor other) {
    return visitor.checkReferences(
        node.tearOffReference, other.tearOffReference, 'tearOffReference');
  }

  bool checkExtension_memberDescriptors(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkLists(node.memberDescriptors, other.memberDescriptors,
        (a, b, _) {
      if (identical(a, b)) return true;
      if (a is! ExtensionMemberDescriptor) return false;
      if (b is! ExtensionMemberDescriptor) return false;
      return checkExtensionMemberDescriptor(visitor, a, b);
    }, 'memberDescriptors');
  }

  bool checkExtension_annotations(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkExtension_flags(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkExtension_reference(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkExtension_fileOffset(
      EquivalenceVisitor visitor, Extension node, Extension other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkExtensionTypeDeclaration_name(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkExtensionTypeDeclaration_fileUri(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkExtensionTypeDeclaration_typeParameters(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkExtensionTypeDeclaration_declaredRepresentationType(
      EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node,
      ExtensionTypeDeclaration other) {
    return visitor.checkNodes(node.declaredRepresentationType,
        other.declaredRepresentationType, 'declaredRepresentationType');
  }

  bool checkExtensionTypeDeclaration_representationName(
      EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node,
      ExtensionTypeDeclaration other) {
    return visitor.checkValues(node.representationName,
        other.representationName, 'representationName');
  }

  bool checkExtensionTypeDeclaration_procedures(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkLists(
        node.procedures, other.procedures, visitor.checkNodes, 'procedures');
  }

  bool checkExtensionTypeMemberDescriptor_name(EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor node, ExtensionTypeMemberDescriptor other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkExtensionTypeMemberDescriptor_kind(EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor node, ExtensionTypeMemberDescriptor other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkExtensionTypeMemberDescriptor_flags(EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor node, ExtensionTypeMemberDescriptor other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkExtensionTypeMemberDescriptor_memberReference(
      EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor node,
      ExtensionTypeMemberDescriptor other) {
    return visitor.checkReferences(
        node.memberReference, other.memberReference, 'memberReference');
  }

  bool checkExtensionTypeMemberDescriptor_tearOffReference(
      EquivalenceVisitor visitor,
      ExtensionTypeMemberDescriptor node,
      ExtensionTypeMemberDescriptor other) {
    return visitor.checkReferences(
        node.tearOffReference, other.tearOffReference, 'tearOffReference');
  }

  bool checkExtensionTypeDeclaration_memberDescriptors(
      EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node,
      ExtensionTypeDeclaration other) {
    return visitor.checkLists(node.memberDescriptors, other.memberDescriptors,
        (a, b, _) {
      if (identical(a, b)) return true;
      if (a is! ExtensionTypeMemberDescriptor) return false;
      if (b is! ExtensionTypeMemberDescriptor) return false;
      return checkExtensionTypeMemberDescriptor(visitor, a, b);
    }, 'memberDescriptors');
  }

  bool checkExtensionTypeDeclaration_annotations(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkExtensionTypeDeclaration_implements(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkLists(
        node.implements, other.implements, visitor.checkNodes, 'implements');
  }

  bool checkExtensionTypeDeclaration_flags(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkExtensionTypeDeclaration_reference(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkExtensionTypeDeclaration_fileOffset(EquivalenceVisitor visitor,
      ExtensionTypeDeclaration node, ExtensionTypeDeclaration other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkField_type(EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkField_flags(EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkField_initializer(
      EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkNodes(
        node.initializer, other.initializer, 'initializer');
  }

  bool checkField_getterReference(
      EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkReferences(
        node.getterReference, other.getterReference, 'getterReference');
  }

  bool checkField_setterReference(
      EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkReferences(
        node.setterReference, other.setterReference, 'setterReference');
  }

  bool checkMember_fileEndOffset(
      EquivalenceVisitor visitor, Member node, Member other) {
    return visitor.checkValues(
        node.fileEndOffset, other.fileEndOffset, 'fileEndOffset');
  }

  bool checkField_fileEndOffset(
      EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_fileEndOffset(visitor, node, other);
  }

  bool checkMember_annotations(
      EquivalenceVisitor visitor, Member node, Member other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkField_annotations(
      EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_annotations(visitor, node, other);
  }

  bool checkMember_name(EquivalenceVisitor visitor, Member node, Member other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkField_name(EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_name(visitor, node, other);
  }

  bool checkMember_fileUri(
      EquivalenceVisitor visitor, Member node, Member other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkField_fileUri(EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_fileUri(visitor, node, other);
  }

  bool checkMember_transformerFlags(
      EquivalenceVisitor visitor, Member node, Member other) {
    return visitor.checkValues(
        node.transformerFlags, other.transformerFlags, 'transformerFlags');
  }

  bool checkField_transformerFlags(
      EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_transformerFlags(visitor, node, other);
  }

  bool checkField_fieldReference(
      EquivalenceVisitor visitor, Field node, Field other) {
    return visitor.checkReferences(
        node.fieldReference, other.fieldReference, 'fieldReference');
  }

  bool checkMember_fileOffset(
      EquivalenceVisitor visitor, Member node, Member other) {
    return checkNamedNode_fileOffset(visitor, node, other);
  }

  bool checkField_fileOffset(
      EquivalenceVisitor visitor, Field node, Field other) {
    return checkMember_fileOffset(visitor, node, other);
  }

  bool checkConstructor_startFileOffset(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return visitor.checkValues(
        node.startFileOffset, other.startFileOffset, 'startFileOffset');
  }

  bool checkConstructor_flags(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkConstructor_function(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return visitor.checkNodes(node.function, other.function, 'function');
  }

  bool checkConstructor_initializers(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return visitor.checkLists(node.initializers, other.initializers,
        visitor.checkNodes, 'initializers');
  }

  bool checkConstructor_fileEndOffset(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_fileEndOffset(visitor, node, other);
  }

  bool checkConstructor_annotations(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_annotations(visitor, node, other);
  }

  bool checkConstructor_name(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_name(visitor, node, other);
  }

  bool checkConstructor_fileUri(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_fileUri(visitor, node, other);
  }

  bool checkConstructor_transformerFlags(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_transformerFlags(visitor, node, other);
  }

  bool checkMember_reference(
      EquivalenceVisitor visitor, Member node, Member other) {
    return checkNamedNode_reference(visitor, node, other);
  }

  bool checkConstructor_reference(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_reference(visitor, node, other);
  }

  bool checkConstructor_fileOffset(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return checkMember_fileOffset(visitor, node, other);
  }

  bool checkProcedure_fileStartOffset(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkValues(
        node.fileStartOffset, other.fileStartOffset, 'fileStartOffset');
  }

  bool checkProcedure_kind(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkProcedure_flags(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkProcedure_function(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkNodes(node.function, other.function, 'function');
  }

  bool checkProcedure_stubKind(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkValues(node.stubKind, other.stubKind, 'stubKind');
  }

  bool checkProcedure_stubTargetReference(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkReferences(node.stubTargetReference,
        other.stubTargetReference, 'stubTargetReference');
  }

  bool checkProcedure_signatureType(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return visitor.checkNodes(
        node.signatureType, other.signatureType, 'signatureType');
  }

  bool checkProcedure_fileEndOffset(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_fileEndOffset(visitor, node, other);
  }

  bool checkProcedure_annotations(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_annotations(visitor, node, other);
  }

  bool checkProcedure_name(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_name(visitor, node, other);
  }

  bool checkProcedure_fileUri(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_fileUri(visitor, node, other);
  }

  bool checkProcedure_transformerFlags(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_transformerFlags(visitor, node, other);
  }

  bool checkProcedure_reference(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_reference(visitor, node, other);
  }

  bool checkProcedure_fileOffset(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return checkMember_fileOffset(visitor, node, other);
  }

  bool checkLibraryDependency_flags(EquivalenceVisitor visitor,
      LibraryDependency node, LibraryDependency other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkLibraryDependency_annotations(EquivalenceVisitor visitor,
      LibraryDependency node, LibraryDependency other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkLibraryDependency_importedLibraryReference(
      EquivalenceVisitor visitor,
      LibraryDependency node,
      LibraryDependency other) {
    return visitor.checkReferences(node.importedLibraryReference,
        other.importedLibraryReference, 'importedLibraryReference');
  }

  bool checkLibraryDependency_name(EquivalenceVisitor visitor,
      LibraryDependency node, LibraryDependency other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkLibraryDependency_combinators(EquivalenceVisitor visitor,
      LibraryDependency node, LibraryDependency other) {
    return visitor.checkLists(
        node.combinators, other.combinators, visitor.checkNodes, 'combinators');
  }

  bool checkLibraryDependency_fileOffset(EquivalenceVisitor visitor,
      LibraryDependency node, LibraryDependency other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkLibraryPart_annotations(
      EquivalenceVisitor visitor, LibraryPart node, LibraryPart other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkLibraryPart_partUri(
      EquivalenceVisitor visitor, LibraryPart node, LibraryPart other) {
    return visitor.checkValues(node.partUri, other.partUri, 'partUri');
  }

  bool checkLibraryPart_fileOffset(
      EquivalenceVisitor visitor, LibraryPart node, LibraryPart other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkCombinator_isShow(
      EquivalenceVisitor visitor, Combinator node, Combinator other) {
    return visitor.checkValues(node.isShow, other.isShow, 'isShow');
  }

  bool checkCombinator_names(
      EquivalenceVisitor visitor, Combinator node, Combinator other) {
    return visitor.checkLists(
        node.names, other.names, visitor.checkValues, 'names');
  }

  bool checkCombinator_fileOffset(
      EquivalenceVisitor visitor, Combinator node, Combinator other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkInitializer_isSynthetic(
      EquivalenceVisitor visitor, Initializer node, Initializer other) {
    return visitor.checkValues(
        node.isSynthetic, other.isSynthetic, 'isSynthetic');
  }

  bool checkAuxiliaryInitializer_isSynthetic(EquivalenceVisitor visitor,
      AuxiliaryInitializer node, AuxiliaryInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkInitializer_fileOffset(
      EquivalenceVisitor visitor, Initializer node, Initializer other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkAuxiliaryInitializer_fileOffset(EquivalenceVisitor visitor,
      AuxiliaryInitializer node, AuxiliaryInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkInvalidInitializer_isSynthetic(EquivalenceVisitor visitor,
      InvalidInitializer node, InvalidInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkInvalidInitializer_fileOffset(EquivalenceVisitor visitor,
      InvalidInitializer node, InvalidInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkFieldInitializer_fieldReference(EquivalenceVisitor visitor,
      FieldInitializer node, FieldInitializer other) {
    return visitor.checkReferences(
        node.fieldReference, other.fieldReference, 'fieldReference');
  }

  bool checkFieldInitializer_value(EquivalenceVisitor visitor,
      FieldInitializer node, FieldInitializer other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkFieldInitializer_isSynthetic(EquivalenceVisitor visitor,
      FieldInitializer node, FieldInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkFieldInitializer_fileOffset(EquivalenceVisitor visitor,
      FieldInitializer node, FieldInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkSuperInitializer_targetReference(EquivalenceVisitor visitor,
      SuperInitializer node, SuperInitializer other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkSuperInitializer_arguments(EquivalenceVisitor visitor,
      SuperInitializer node, SuperInitializer other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkSuperInitializer_isSynthetic(EquivalenceVisitor visitor,
      SuperInitializer node, SuperInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkSuperInitializer_fileOffset(EquivalenceVisitor visitor,
      SuperInitializer node, SuperInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkRedirectingInitializer_targetReference(EquivalenceVisitor visitor,
      RedirectingInitializer node, RedirectingInitializer other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkRedirectingInitializer_arguments(EquivalenceVisitor visitor,
      RedirectingInitializer node, RedirectingInitializer other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkRedirectingInitializer_isSynthetic(EquivalenceVisitor visitor,
      RedirectingInitializer node, RedirectingInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkRedirectingInitializer_fileOffset(EquivalenceVisitor visitor,
      RedirectingInitializer node, RedirectingInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkLocalInitializer_variable(EquivalenceVisitor visitor,
      LocalInitializer node, LocalInitializer other) {
    return visitor.checkNodes(node.variable, other.variable, 'variable');
  }

  bool checkLocalInitializer_isSynthetic(EquivalenceVisitor visitor,
      LocalInitializer node, LocalInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkLocalInitializer_fileOffset(EquivalenceVisitor visitor,
      LocalInitializer node, LocalInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkAssertInitializer_statement(EquivalenceVisitor visitor,
      AssertInitializer node, AssertInitializer other) {
    return visitor.checkNodes(node.statement, other.statement, 'statement');
  }

  bool checkAssertInitializer_isSynthetic(EquivalenceVisitor visitor,
      AssertInitializer node, AssertInitializer other) {
    return checkInitializer_isSynthetic(visitor, node, other);
  }

  bool checkAssertInitializer_fileOffset(EquivalenceVisitor visitor,
      AssertInitializer node, AssertInitializer other) {
    return checkInitializer_fileOffset(visitor, node, other);
  }

  bool checkFunctionNode_fileEndOffset(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkValues(
        node.fileEndOffset, other.fileEndOffset, 'fileEndOffset');
  }

  bool checkFunctionNode_asyncMarker(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkValues(
        node.asyncMarker, other.asyncMarker, 'asyncMarker');
  }

  bool checkFunctionNode_dartAsyncMarker(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkValues(
        node.dartAsyncMarker, other.dartAsyncMarker, 'dartAsyncMarker');
  }

  bool checkFunctionNode_typeParameters(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkFunctionNode_requiredParameterCount(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkValues(node.requiredParameterCount,
        other.requiredParameterCount, 'requiredParameterCount');
  }

  bool checkFunctionNode_positionalParameters(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkLists(node.positionalParameters,
        other.positionalParameters, visitor.checkNodes, 'positionalParameters');
  }

  bool checkFunctionNode_namedParameters(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkLists(node.namedParameters, other.namedParameters,
        visitor.checkNodes, 'namedParameters');
  }

  bool checkFunctionNode_returnType(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkNodes(node.returnType, other.returnType, 'returnType');
  }

  bool checkFunctionNode_body(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkFunctionNode_emittedValueType(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkNodes(
        node.emittedValueType, other.emittedValueType, 'emittedValueType');
  }

  bool checkRedirectingFactoryTarget_targetReference(EquivalenceVisitor visitor,
      RedirectingFactoryTarget node, RedirectingFactoryTarget other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkRedirectingFactoryTarget_typeArguments(EquivalenceVisitor visitor,
      RedirectingFactoryTarget node, RedirectingFactoryTarget other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkRedirectingFactoryTarget_errorMessage(EquivalenceVisitor visitor,
      RedirectingFactoryTarget node, RedirectingFactoryTarget other) {
    return visitor.checkValues(
        node.errorMessage, other.errorMessage, 'errorMessage');
  }

  bool checkFunctionNode_redirectingFactoryTarget(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    'redirectingFactoryTarget';
    return checkRedirectingFactoryTarget(
        visitor, node.redirectingFactoryTarget, other.redirectingFactoryTarget);
  }

  bool checkFunctionNode_lazyBuilder(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return visitor.checkValues(
        node.lazyBuilder, other.lazyBuilder, 'lazyBuilder');
  }

  bool checkFunctionNode_fileOffset(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkExpression_fileOffset(
      EquivalenceVisitor visitor, Expression node, Expression other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkAuxiliaryExpression_fileOffset(EquivalenceVisitor visitor,
      AuxiliaryExpression node, AuxiliaryExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInvalidExpression_message(EquivalenceVisitor visitor,
      InvalidExpression node, InvalidExpression other) {
    return visitor.checkValues(node.message, other.message, 'message');
  }

  bool checkInvalidExpression_expression(EquivalenceVisitor visitor,
      InvalidExpression node, InvalidExpression other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkInvalidExpression_fileOffset(EquivalenceVisitor visitor,
      InvalidExpression node, InvalidExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkVariableGet_variable(
      EquivalenceVisitor visitor, VariableGet node, VariableGet other) {
    return visitor.checkDeclarations(node.variable, other.variable, 'variable');
  }

  bool checkVariableGet_promotedType(
      EquivalenceVisitor visitor, VariableGet node, VariableGet other) {
    return visitor.checkNodes(
        node.promotedType, other.promotedType, 'promotedType');
  }

  bool checkVariableGet_fileOffset(
      EquivalenceVisitor visitor, VariableGet node, VariableGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkVariableSet_variable(
      EquivalenceVisitor visitor, VariableSet node, VariableSet other) {
    return visitor.checkDeclarations(node.variable, other.variable, 'variable');
  }

  bool checkVariableSet_value(
      EquivalenceVisitor visitor, VariableSet node, VariableSet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkVariableSet_fileOffset(
      EquivalenceVisitor visitor, VariableSet node, VariableSet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkRecordIndexGet_receiver(
      EquivalenceVisitor visitor, RecordIndexGet node, RecordIndexGet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkRecordIndexGet_receiverType(
      EquivalenceVisitor visitor, RecordIndexGet node, RecordIndexGet other) {
    return visitor.checkNodes(
        node.receiverType, other.receiverType, 'receiverType');
  }

  bool checkRecordIndexGet_index(
      EquivalenceVisitor visitor, RecordIndexGet node, RecordIndexGet other) {
    return visitor.checkValues(node.index, other.index, 'index');
  }

  bool checkRecordIndexGet_fileOffset(
      EquivalenceVisitor visitor, RecordIndexGet node, RecordIndexGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkRecordNameGet_receiver(
      EquivalenceVisitor visitor, RecordNameGet node, RecordNameGet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkRecordNameGet_receiverType(
      EquivalenceVisitor visitor, RecordNameGet node, RecordNameGet other) {
    return visitor.checkNodes(
        node.receiverType, other.receiverType, 'receiverType');
  }

  bool checkRecordNameGet_name(
      EquivalenceVisitor visitor, RecordNameGet node, RecordNameGet other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkRecordNameGet_fileOffset(
      EquivalenceVisitor visitor, RecordNameGet node, RecordNameGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkDynamicGet_kind(
      EquivalenceVisitor visitor, DynamicGet node, DynamicGet other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkDynamicGet_receiver(
      EquivalenceVisitor visitor, DynamicGet node, DynamicGet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkDynamicGet_name(
      EquivalenceVisitor visitor, DynamicGet node, DynamicGet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkDynamicGet_fileOffset(
      EquivalenceVisitor visitor, DynamicGet node, DynamicGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceGet_kind(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkInstanceGet_receiver(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkInstanceGet_name(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkInstanceGet_resultType(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return visitor.checkNodes(node.resultType, other.resultType, 'resultType');
  }

  bool checkInstanceGet_interfaceTargetReference(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkInstanceGet_fileOffset(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkFunctionTearOff_receiver(
      EquivalenceVisitor visitor, FunctionTearOff node, FunctionTearOff other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkFunctionTearOff_fileOffset(
      EquivalenceVisitor visitor, FunctionTearOff node, FunctionTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceTearOff_kind(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkInstanceTearOff_receiver(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkInstanceTearOff_name(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkInstanceTearOff_resultType(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return visitor.checkNodes(node.resultType, other.resultType, 'resultType');
  }

  bool checkInstanceTearOff_interfaceTargetReference(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkInstanceTearOff_fileOffset(
      EquivalenceVisitor visitor, InstanceTearOff node, InstanceTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkDynamicSet_kind(
      EquivalenceVisitor visitor, DynamicSet node, DynamicSet other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkDynamicSet_receiver(
      EquivalenceVisitor visitor, DynamicSet node, DynamicSet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkDynamicSet_name(
      EquivalenceVisitor visitor, DynamicSet node, DynamicSet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkDynamicSet_value(
      EquivalenceVisitor visitor, DynamicSet node, DynamicSet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkDynamicSet_fileOffset(
      EquivalenceVisitor visitor, DynamicSet node, DynamicSet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceSet_kind(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkInstanceSet_receiver(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkInstanceSet_name(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkInstanceSet_value(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkInstanceSet_interfaceTargetReference(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkInstanceSet_fileOffset(
      EquivalenceVisitor visitor, InstanceSet node, InstanceSet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkAbstractSuperPropertyGet_name(EquivalenceVisitor visitor,
      AbstractSuperPropertyGet node, AbstractSuperPropertyGet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkAbstractSuperPropertyGet_interfaceTargetReference(
      EquivalenceVisitor visitor,
      AbstractSuperPropertyGet node,
      AbstractSuperPropertyGet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkAbstractSuperPropertyGet_fileOffset(EquivalenceVisitor visitor,
      AbstractSuperPropertyGet node, AbstractSuperPropertyGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkSuperPropertyGet_name(EquivalenceVisitor visitor,
      SuperPropertyGet node, SuperPropertyGet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkSuperPropertyGet_interfaceTargetReference(
      EquivalenceVisitor visitor,
      SuperPropertyGet node,
      SuperPropertyGet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkSuperPropertyGet_fileOffset(EquivalenceVisitor visitor,
      SuperPropertyGet node, SuperPropertyGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkAbstractSuperPropertySet_name(EquivalenceVisitor visitor,
      AbstractSuperPropertySet node, AbstractSuperPropertySet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkAbstractSuperPropertySet_value(EquivalenceVisitor visitor,
      AbstractSuperPropertySet node, AbstractSuperPropertySet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkAbstractSuperPropertySet_interfaceTargetReference(
      EquivalenceVisitor visitor,
      AbstractSuperPropertySet node,
      AbstractSuperPropertySet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkAbstractSuperPropertySet_fileOffset(EquivalenceVisitor visitor,
      AbstractSuperPropertySet node, AbstractSuperPropertySet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkSuperPropertySet_name(EquivalenceVisitor visitor,
      SuperPropertySet node, SuperPropertySet other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkSuperPropertySet_value(EquivalenceVisitor visitor,
      SuperPropertySet node, SuperPropertySet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkSuperPropertySet_interfaceTargetReference(
      EquivalenceVisitor visitor,
      SuperPropertySet node,
      SuperPropertySet other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkSuperPropertySet_fileOffset(EquivalenceVisitor visitor,
      SuperPropertySet node, SuperPropertySet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStaticGet_targetReference(
      EquivalenceVisitor visitor, StaticGet node, StaticGet other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkStaticGet_fileOffset(
      EquivalenceVisitor visitor, StaticGet node, StaticGet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStaticTearOff_targetReference(
      EquivalenceVisitor visitor, StaticTearOff node, StaticTearOff other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkStaticTearOff_fileOffset(
      EquivalenceVisitor visitor, StaticTearOff node, StaticTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStaticSet_targetReference(
      EquivalenceVisitor visitor, StaticSet node, StaticSet other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkStaticSet_value(
      EquivalenceVisitor visitor, StaticSet node, StaticSet other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkStaticSet_fileOffset(
      EquivalenceVisitor visitor, StaticSet node, StaticSet other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkDynamicInvocation_kind(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkDynamicInvocation_receiver(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkDynamicInvocation_name(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkDynamicInvocation_arguments(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkDynamicInvocation_flags(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkInvocationExpression_fileOffset(EquivalenceVisitor visitor,
      InvocationExpression node, InvocationExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceInvocationExpression_fileOffset(EquivalenceVisitor visitor,
      InstanceInvocationExpression node, InstanceInvocationExpression other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkDynamicInvocation_fileOffset(EquivalenceVisitor visitor,
      DynamicInvocation node, DynamicInvocation other) {
    return checkInstanceInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceInvocation_kind(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkInstanceInvocation_receiver(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkInstanceInvocation_name(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkInstanceInvocation_arguments(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkInstanceInvocation_flags(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkInstanceInvocation_functionType(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkInstanceInvocation_interfaceTargetReference(
      EquivalenceVisitor visitor,
      InstanceInvocation node,
      InstanceInvocation other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkInstanceInvocation_fileOffset(EquivalenceVisitor visitor,
      InstanceInvocation node, InstanceInvocation other) {
    return checkInstanceInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceGetterInvocation_kind(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkInstanceGetterInvocation_receiver(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkInstanceGetterInvocation_name(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkInstanceGetterInvocation_arguments(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkInstanceGetterInvocation_flags(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkInstanceGetterInvocation_functionType(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkInstanceGetterInvocation_interfaceTargetReference(
      EquivalenceVisitor visitor,
      InstanceGetterInvocation node,
      InstanceGetterInvocation other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkInstanceGetterInvocation_fileOffset(EquivalenceVisitor visitor,
      InstanceGetterInvocation node, InstanceGetterInvocation other) {
    return checkInstanceInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkFunctionInvocation_kind(EquivalenceVisitor visitor,
      FunctionInvocation node, FunctionInvocation other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkFunctionInvocation_receiver(EquivalenceVisitor visitor,
      FunctionInvocation node, FunctionInvocation other) {
    return visitor.checkNodes(node.receiver, other.receiver, 'receiver');
  }

  bool checkFunctionInvocation_arguments(EquivalenceVisitor visitor,
      FunctionInvocation node, FunctionInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkFunctionInvocation_functionType(EquivalenceVisitor visitor,
      FunctionInvocation node, FunctionInvocation other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkFunctionInvocation_fileOffset(EquivalenceVisitor visitor,
      FunctionInvocation node, FunctionInvocation other) {
    return checkInstanceInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkLocalFunctionInvocation_variable(EquivalenceVisitor visitor,
      LocalFunctionInvocation node, LocalFunctionInvocation other) {
    return visitor.checkDeclarations(node.variable, other.variable, 'variable');
  }

  bool checkLocalFunctionInvocation_arguments(EquivalenceVisitor visitor,
      LocalFunctionInvocation node, LocalFunctionInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkLocalFunctionInvocation_functionType(EquivalenceVisitor visitor,
      LocalFunctionInvocation node, LocalFunctionInvocation other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkLocalFunctionInvocation_fileOffset(EquivalenceVisitor visitor,
      LocalFunctionInvocation node, LocalFunctionInvocation other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkAbstractSuperMethodInvocation_name(EquivalenceVisitor visitor,
      AbstractSuperMethodInvocation node, AbstractSuperMethodInvocation other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkAbstractSuperMethodInvocation_arguments(EquivalenceVisitor visitor,
      AbstractSuperMethodInvocation node, AbstractSuperMethodInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkAbstractSuperMethodInvocation_interfaceTargetReference(
      EquivalenceVisitor visitor,
      AbstractSuperMethodInvocation node,
      AbstractSuperMethodInvocation other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkAbstractSuperMethodInvocation_fileOffset(EquivalenceVisitor visitor,
      AbstractSuperMethodInvocation node, AbstractSuperMethodInvocation other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkSuperMethodInvocation_name(EquivalenceVisitor visitor,
      SuperMethodInvocation node, SuperMethodInvocation other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkSuperMethodInvocation_arguments(EquivalenceVisitor visitor,
      SuperMethodInvocation node, SuperMethodInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkSuperMethodInvocation_interfaceTargetReference(
      EquivalenceVisitor visitor,
      SuperMethodInvocation node,
      SuperMethodInvocation other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkSuperMethodInvocation_fileOffset(EquivalenceVisitor visitor,
      SuperMethodInvocation node, SuperMethodInvocation other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkStaticInvocation_targetReference(EquivalenceVisitor visitor,
      StaticInvocation node, StaticInvocation other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkStaticInvocation_arguments(EquivalenceVisitor visitor,
      StaticInvocation node, StaticInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkStaticInvocation_isConst(EquivalenceVisitor visitor,
      StaticInvocation node, StaticInvocation other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkStaticInvocation_fileOffset(EquivalenceVisitor visitor,
      StaticInvocation node, StaticInvocation other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkConstructorInvocation_targetReference(EquivalenceVisitor visitor,
      ConstructorInvocation node, ConstructorInvocation other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkConstructorInvocation_arguments(EquivalenceVisitor visitor,
      ConstructorInvocation node, ConstructorInvocation other) {
    return visitor.checkNodes(node.arguments, other.arguments, 'arguments');
  }

  bool checkConstructorInvocation_isConst(EquivalenceVisitor visitor,
      ConstructorInvocation node, ConstructorInvocation other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkConstructorInvocation_fileOffset(EquivalenceVisitor visitor,
      ConstructorInvocation node, ConstructorInvocation other) {
    return checkInvocationExpression_fileOffset(visitor, node, other);
  }

  bool checkEqualsNull_expression(
      EquivalenceVisitor visitor, EqualsNull node, EqualsNull other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkEqualsNull_fileOffset(
      EquivalenceVisitor visitor, EqualsNull node, EqualsNull other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkEqualsCall_left(
      EquivalenceVisitor visitor, EqualsCall node, EqualsCall other) {
    return visitor.checkNodes(node.left, other.left, 'left');
  }

  bool checkEqualsCall_right(
      EquivalenceVisitor visitor, EqualsCall node, EqualsCall other) {
    return visitor.checkNodes(node.right, other.right, 'right');
  }

  bool checkEqualsCall_functionType(
      EquivalenceVisitor visitor, EqualsCall node, EqualsCall other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkEqualsCall_interfaceTargetReference(
      EquivalenceVisitor visitor, EqualsCall node, EqualsCall other) {
    return visitor.checkReferences(node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }

  bool checkEqualsCall_fileOffset(
      EquivalenceVisitor visitor, EqualsCall node, EqualsCall other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstantiation_expression(
      EquivalenceVisitor visitor, Instantiation node, Instantiation other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkInstantiation_typeArguments(
      EquivalenceVisitor visitor, Instantiation node, Instantiation other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkInstantiation_fileOffset(
      EquivalenceVisitor visitor, Instantiation node, Instantiation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkNot_operand(EquivalenceVisitor visitor, Not node, Not other) {
    return visitor.checkNodes(node.operand, other.operand, 'operand');
  }

  bool checkNot_fileOffset(EquivalenceVisitor visitor, Not node, Not other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkLogicalExpression_left(EquivalenceVisitor visitor,
      LogicalExpression node, LogicalExpression other) {
    return visitor.checkNodes(node.left, other.left, 'left');
  }

  bool checkLogicalExpression_operatorEnum(EquivalenceVisitor visitor,
      LogicalExpression node, LogicalExpression other) {
    return visitor.checkValues(
        node.operatorEnum, other.operatorEnum, 'operatorEnum');
  }

  bool checkLogicalExpression_right(EquivalenceVisitor visitor,
      LogicalExpression node, LogicalExpression other) {
    return visitor.checkNodes(node.right, other.right, 'right');
  }

  bool checkLogicalExpression_fileOffset(EquivalenceVisitor visitor,
      LogicalExpression node, LogicalExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkConditionalExpression_condition(EquivalenceVisitor visitor,
      ConditionalExpression node, ConditionalExpression other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkConditionalExpression_then(EquivalenceVisitor visitor,
      ConditionalExpression node, ConditionalExpression other) {
    return visitor.checkNodes(node.then, other.then, 'then');
  }

  bool checkConditionalExpression_otherwise(EquivalenceVisitor visitor,
      ConditionalExpression node, ConditionalExpression other) {
    return visitor.checkNodes(node.otherwise, other.otherwise, 'otherwise');
  }

  bool checkConditionalExpression_staticType(EquivalenceVisitor visitor,
      ConditionalExpression node, ConditionalExpression other) {
    return visitor.checkNodes(node.staticType, other.staticType, 'staticType');
  }

  bool checkConditionalExpression_fileOffset(EquivalenceVisitor visitor,
      ConditionalExpression node, ConditionalExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStringConcatenation_expressions(EquivalenceVisitor visitor,
      StringConcatenation node, StringConcatenation other) {
    return visitor.checkLists(
        node.expressions, other.expressions, visitor.checkNodes, 'expressions');
  }

  bool checkStringConcatenation_fileOffset(EquivalenceVisitor visitor,
      StringConcatenation node, StringConcatenation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkListConcatenation_typeArgument(EquivalenceVisitor visitor,
      ListConcatenation node, ListConcatenation other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkListConcatenation_lists(EquivalenceVisitor visitor,
      ListConcatenation node, ListConcatenation other) {
    return visitor.checkLists(
        node.lists, other.lists, visitor.checkNodes, 'lists');
  }

  bool checkListConcatenation_fileOffset(EquivalenceVisitor visitor,
      ListConcatenation node, ListConcatenation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkSetConcatenation_typeArgument(EquivalenceVisitor visitor,
      SetConcatenation node, SetConcatenation other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkSetConcatenation_sets(EquivalenceVisitor visitor,
      SetConcatenation node, SetConcatenation other) {
    return visitor.checkLists(
        node.sets, other.sets, visitor.checkNodes, 'sets');
  }

  bool checkSetConcatenation_fileOffset(EquivalenceVisitor visitor,
      SetConcatenation node, SetConcatenation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkMapConcatenation_keyType(EquivalenceVisitor visitor,
      MapConcatenation node, MapConcatenation other) {
    return visitor.checkNodes(node.keyType, other.keyType, 'keyType');
  }

  bool checkMapConcatenation_valueType(EquivalenceVisitor visitor,
      MapConcatenation node, MapConcatenation other) {
    return visitor.checkNodes(node.valueType, other.valueType, 'valueType');
  }

  bool checkMapConcatenation_maps(EquivalenceVisitor visitor,
      MapConcatenation node, MapConcatenation other) {
    return visitor.checkLists(
        node.maps, other.maps, visitor.checkNodes, 'maps');
  }

  bool checkMapConcatenation_fileOffset(EquivalenceVisitor visitor,
      MapConcatenation node, MapConcatenation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkInstanceCreation_classReference(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return visitor.checkReferences(
        node.classReference, other.classReference, 'classReference');
  }

  bool checkInstanceCreation_typeArguments(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkInstanceCreation_fieldValues(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return visitor.checkMaps(
        node.fieldValues,
        other.fieldValues,
        visitor.matchReferences,
        visitor.checkReferences,
        visitor.checkNodes,
        'fieldValues');
  }

  bool checkInstanceCreation_asserts(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return visitor.checkLists(
        node.asserts, other.asserts, visitor.checkNodes, 'asserts');
  }

  bool checkInstanceCreation_unusedArguments(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return visitor.checkLists(node.unusedArguments, other.unusedArguments,
        visitor.checkNodes, 'unusedArguments');
  }

  bool checkInstanceCreation_fileOffset(EquivalenceVisitor visitor,
      InstanceCreation node, InstanceCreation other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkFileUriExpression_fileUri(EquivalenceVisitor visitor,
      FileUriExpression node, FileUriExpression other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkFileUriExpression_expression(EquivalenceVisitor visitor,
      FileUriExpression node, FileUriExpression other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkFileUriExpression_fileOffset(EquivalenceVisitor visitor,
      FileUriExpression node, FileUriExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkIsExpression_flags(
      EquivalenceVisitor visitor, IsExpression node, IsExpression other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkIsExpression_operand(
      EquivalenceVisitor visitor, IsExpression node, IsExpression other) {
    return visitor.checkNodes(node.operand, other.operand, 'operand');
  }

  bool checkIsExpression_type(
      EquivalenceVisitor visitor, IsExpression node, IsExpression other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkIsExpression_fileOffset(
      EquivalenceVisitor visitor, IsExpression node, IsExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkAsExpression_flags(
      EquivalenceVisitor visitor, AsExpression node, AsExpression other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkAsExpression_operand(
      EquivalenceVisitor visitor, AsExpression node, AsExpression other) {
    return visitor.checkNodes(node.operand, other.operand, 'operand');
  }

  bool checkAsExpression_type(
      EquivalenceVisitor visitor, AsExpression node, AsExpression other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkAsExpression_fileOffset(
      EquivalenceVisitor visitor, AsExpression node, AsExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkNullCheck_operand(
      EquivalenceVisitor visitor, NullCheck node, NullCheck other) {
    return visitor.checkNodes(node.operand, other.operand, 'operand');
  }

  bool checkNullCheck_fileOffset(
      EquivalenceVisitor visitor, NullCheck node, NullCheck other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStringLiteral_value(
      EquivalenceVisitor visitor, StringLiteral node, StringLiteral other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkBasicLiteral_fileOffset(
      EquivalenceVisitor visitor, BasicLiteral node, BasicLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkStringLiteral_fileOffset(
      EquivalenceVisitor visitor, StringLiteral node, StringLiteral other) {
    return checkBasicLiteral_fileOffset(visitor, node, other);
  }

  bool checkIntLiteral_value(
      EquivalenceVisitor visitor, IntLiteral node, IntLiteral other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkIntLiteral_fileOffset(
      EquivalenceVisitor visitor, IntLiteral node, IntLiteral other) {
    return checkBasicLiteral_fileOffset(visitor, node, other);
  }

  bool checkDoubleLiteral_value(
      EquivalenceVisitor visitor, DoubleLiteral node, DoubleLiteral other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkDoubleLiteral_fileOffset(
      EquivalenceVisitor visitor, DoubleLiteral node, DoubleLiteral other) {
    return checkBasicLiteral_fileOffset(visitor, node, other);
  }

  bool checkBoolLiteral_value(
      EquivalenceVisitor visitor, BoolLiteral node, BoolLiteral other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkBoolLiteral_fileOffset(
      EquivalenceVisitor visitor, BoolLiteral node, BoolLiteral other) {
    return checkBasicLiteral_fileOffset(visitor, node, other);
  }

  bool checkNullLiteral_fileOffset(
      EquivalenceVisitor visitor, NullLiteral node, NullLiteral other) {
    return checkBasicLiteral_fileOffset(visitor, node, other);
  }

  bool checkSymbolLiteral_value(
      EquivalenceVisitor visitor, SymbolLiteral node, SymbolLiteral other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkSymbolLiteral_fileOffset(
      EquivalenceVisitor visitor, SymbolLiteral node, SymbolLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkTypeLiteral_type(
      EquivalenceVisitor visitor, TypeLiteral node, TypeLiteral other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkTypeLiteral_fileOffset(
      EquivalenceVisitor visitor, TypeLiteral node, TypeLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkThisExpression_fileOffset(
      EquivalenceVisitor visitor, ThisExpression node, ThisExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkRethrow_fileOffset(
      EquivalenceVisitor visitor, Rethrow node, Rethrow other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkThrow_expression(
      EquivalenceVisitor visitor, Throw node, Throw other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkThrow_flags(EquivalenceVisitor visitor, Throw node, Throw other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkThrow_fileOffset(
      EquivalenceVisitor visitor, Throw node, Throw other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkListLiteral_isConst(
      EquivalenceVisitor visitor, ListLiteral node, ListLiteral other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkListLiteral_typeArgument(
      EquivalenceVisitor visitor, ListLiteral node, ListLiteral other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkListLiteral_expressions(
      EquivalenceVisitor visitor, ListLiteral node, ListLiteral other) {
    return visitor.checkLists(
        node.expressions, other.expressions, visitor.checkNodes, 'expressions');
  }

  bool checkListLiteral_fileOffset(
      EquivalenceVisitor visitor, ListLiteral node, ListLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkSetLiteral_isConst(
      EquivalenceVisitor visitor, SetLiteral node, SetLiteral other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkSetLiteral_typeArgument(
      EquivalenceVisitor visitor, SetLiteral node, SetLiteral other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkSetLiteral_expressions(
      EquivalenceVisitor visitor, SetLiteral node, SetLiteral other) {
    return visitor.checkLists(
        node.expressions, other.expressions, visitor.checkNodes, 'expressions');
  }

  bool checkSetLiteral_fileOffset(
      EquivalenceVisitor visitor, SetLiteral node, SetLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkMapLiteral_isConst(
      EquivalenceVisitor visitor, MapLiteral node, MapLiteral other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkMapLiteral_keyType(
      EquivalenceVisitor visitor, MapLiteral node, MapLiteral other) {
    return visitor.checkNodes(node.keyType, other.keyType, 'keyType');
  }

  bool checkMapLiteral_valueType(
      EquivalenceVisitor visitor, MapLiteral node, MapLiteral other) {
    return visitor.checkNodes(node.valueType, other.valueType, 'valueType');
  }

  bool checkMapLiteral_entries(
      EquivalenceVisitor visitor, MapLiteral node, MapLiteral other) {
    return visitor.checkLists(
        node.entries, other.entries, visitor.checkNodes, 'entries');
  }

  bool checkMapLiteral_fileOffset(
      EquivalenceVisitor visitor, MapLiteral node, MapLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkRecordLiteral_isConst(
      EquivalenceVisitor visitor, RecordLiteral node, RecordLiteral other) {
    return visitor.checkValues(node.isConst, other.isConst, 'isConst');
  }

  bool checkRecordLiteral_positional(
      EquivalenceVisitor visitor, RecordLiteral node, RecordLiteral other) {
    return visitor.checkLists(
        node.positional, other.positional, visitor.checkNodes, 'positional');
  }

  bool checkRecordLiteral_named(
      EquivalenceVisitor visitor, RecordLiteral node, RecordLiteral other) {
    return visitor.checkLists(
        node.named, other.named, visitor.checkNodes, 'named');
  }

  bool checkRecordLiteral_recordType(
      EquivalenceVisitor visitor, RecordLiteral node, RecordLiteral other) {
    return visitor.checkNodes(node.recordType, other.recordType, 'recordType');
  }

  bool checkRecordLiteral_fileOffset(
      EquivalenceVisitor visitor, RecordLiteral node, RecordLiteral other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkAwaitExpression_operand(
      EquivalenceVisitor visitor, AwaitExpression node, AwaitExpression other) {
    return visitor.checkNodes(node.operand, other.operand, 'operand');
  }

  bool checkAwaitExpression_runtimeCheckType(
      EquivalenceVisitor visitor, AwaitExpression node, AwaitExpression other) {
    return visitor.checkNodes(
        node.runtimeCheckType, other.runtimeCheckType, 'runtimeCheckType');
  }

  bool checkAwaitExpression_fileOffset(
      EquivalenceVisitor visitor, AwaitExpression node, AwaitExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkFunctionExpression_function(EquivalenceVisitor visitor,
      FunctionExpression node, FunctionExpression other) {
    return visitor.checkNodes(node.function, other.function, 'function');
  }

  bool checkFunctionExpression_fileOffset(EquivalenceVisitor visitor,
      FunctionExpression node, FunctionExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkConstantExpression_constant(EquivalenceVisitor visitor,
      ConstantExpression node, ConstantExpression other) {
    return visitor.checkNodes(node.constant, other.constant, 'constant');
  }

  bool checkConstantExpression_type(EquivalenceVisitor visitor,
      ConstantExpression node, ConstantExpression other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkConstantExpression_fileOffset(EquivalenceVisitor visitor,
      ConstantExpression node, ConstantExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkLet_variable(EquivalenceVisitor visitor, Let node, Let other) {
    return visitor.checkNodes(node.variable, other.variable, 'variable');
  }

  bool checkLet_body(EquivalenceVisitor visitor, Let node, Let other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkLet_fileOffset(EquivalenceVisitor visitor, Let node, Let other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkBlockExpression_body(
      EquivalenceVisitor visitor, BlockExpression node, BlockExpression other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkBlockExpression_value(
      EquivalenceVisitor visitor, BlockExpression node, BlockExpression other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkBlockExpression_fileOffset(
      EquivalenceVisitor visitor, BlockExpression node, BlockExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkLoadLibrary_import(
      EquivalenceVisitor visitor, LoadLibrary node, LoadLibrary other) {
    return visitor.checkNodes(node.import, other.import, 'import');
  }

  bool checkLoadLibrary_fileOffset(
      EquivalenceVisitor visitor, LoadLibrary node, LoadLibrary other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkCheckLibraryIsLoaded_import(EquivalenceVisitor visitor,
      CheckLibraryIsLoaded node, CheckLibraryIsLoaded other) {
    return visitor.checkNodes(node.import, other.import, 'import');
  }

  bool checkCheckLibraryIsLoaded_fileOffset(EquivalenceVisitor visitor,
      CheckLibraryIsLoaded node, CheckLibraryIsLoaded other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkConstructorTearOff_targetReference(EquivalenceVisitor visitor,
      ConstructorTearOff node, ConstructorTearOff other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkConstructorTearOff_fileOffset(EquivalenceVisitor visitor,
      ConstructorTearOff node, ConstructorTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkRedirectingFactoryTearOff_targetReference(
      EquivalenceVisitor visitor,
      RedirectingFactoryTearOff node,
      RedirectingFactoryTearOff other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkRedirectingFactoryTearOff_fileOffset(EquivalenceVisitor visitor,
      RedirectingFactoryTearOff node, RedirectingFactoryTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkTypedefTearOff_typeParameters(
      EquivalenceVisitor visitor, TypedefTearOff node, TypedefTearOff other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkTypedefTearOff_expression(
      EquivalenceVisitor visitor, TypedefTearOff node, TypedefTearOff other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkTypedefTearOff_typeArguments(
      EquivalenceVisitor visitor, TypedefTearOff node, TypedefTearOff other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkTypedefTearOff_fileOffset(
      EquivalenceVisitor visitor, TypedefTearOff node, TypedefTearOff other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkSwitchExpression_expression(EquivalenceVisitor visitor,
      SwitchExpression node, SwitchExpression other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkSwitchExpression_cases(EquivalenceVisitor visitor,
      SwitchExpression node, SwitchExpression other) {
    return visitor.checkLists(
        node.cases, other.cases, visitor.checkNodes, 'cases');
  }

  bool checkSwitchExpression_expressionType(EquivalenceVisitor visitor,
      SwitchExpression node, SwitchExpression other) {
    return visitor.checkNodes(
        node.expressionType, other.expressionType, 'expressionType');
  }

  bool checkSwitchExpression_staticType(EquivalenceVisitor visitor,
      SwitchExpression node, SwitchExpression other) {
    return visitor.checkNodes(node.staticType, other.staticType, 'staticType');
  }

  bool checkSwitchExpression_fileOffset(EquivalenceVisitor visitor,
      SwitchExpression node, SwitchExpression other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkPatternAssignment_pattern(EquivalenceVisitor visitor,
      PatternAssignment node, PatternAssignment other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkPatternAssignment_expression(EquivalenceVisitor visitor,
      PatternAssignment node, PatternAssignment other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkPatternAssignment_matchedValueType(EquivalenceVisitor visitor,
      PatternAssignment node, PatternAssignment other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkPatternAssignment_fileOffset(EquivalenceVisitor visitor,
      PatternAssignment node, PatternAssignment other) {
    return checkExpression_fileOffset(visitor, node, other);
  }

  bool checkArguments_types(
      EquivalenceVisitor visitor, Arguments node, Arguments other) {
    return visitor.checkLists(
        node.types, other.types, visitor.checkNodes, 'types');
  }

  bool checkArguments_positional(
      EquivalenceVisitor visitor, Arguments node, Arguments other) {
    return visitor.checkLists(
        node.positional, other.positional, visitor.checkNodes, 'positional');
  }

  bool checkArguments_named(
      EquivalenceVisitor visitor, Arguments node, Arguments other) {
    return visitor.checkLists(
        node.named, other.named, visitor.checkNodes, 'named');
  }

  bool checkArguments_fileOffset(
      EquivalenceVisitor visitor, Arguments node, Arguments other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkNamedExpression_name(
      EquivalenceVisitor visitor, NamedExpression node, NamedExpression other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkNamedExpression_value(
      EquivalenceVisitor visitor, NamedExpression node, NamedExpression other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkNamedExpression_fileOffset(
      EquivalenceVisitor visitor, NamedExpression node, NamedExpression other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkMapLiteralEntry_key(
      EquivalenceVisitor visitor, MapLiteralEntry node, MapLiteralEntry other) {
    return visitor.checkNodes(node.key, other.key, 'key');
  }

  bool checkMapLiteralEntry_value(
      EquivalenceVisitor visitor, MapLiteralEntry node, MapLiteralEntry other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkMapLiteralEntry_fileOffset(
      EquivalenceVisitor visitor, MapLiteralEntry node, MapLiteralEntry other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkStatement_fileOffset(
      EquivalenceVisitor visitor, Statement node, Statement other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkAuxiliaryStatement_fileOffset(EquivalenceVisitor visitor,
      AuxiliaryStatement node, AuxiliaryStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkExpressionStatement_expression(EquivalenceVisitor visitor,
      ExpressionStatement node, ExpressionStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkExpressionStatement_fileOffset(EquivalenceVisitor visitor,
      ExpressionStatement node, ExpressionStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkBlock_statements(
      EquivalenceVisitor visitor, Block node, Block other) {
    return visitor.checkLists(
        node.statements, other.statements, visitor.checkNodes, 'statements');
  }

  bool checkBlock_fileEndOffset(
      EquivalenceVisitor visitor, Block node, Block other) {
    return visitor.checkValues(
        node.fileEndOffset, other.fileEndOffset, 'fileEndOffset');
  }

  bool checkBlock_fileOffset(
      EquivalenceVisitor visitor, Block node, Block other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkAssertBlock_statements(
      EquivalenceVisitor visitor, AssertBlock node, AssertBlock other) {
    return visitor.checkLists(
        node.statements, other.statements, visitor.checkNodes, 'statements');
  }

  bool checkAssertBlock_fileOffset(
      EquivalenceVisitor visitor, AssertBlock node, AssertBlock other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkEmptyStatement_fileOffset(
      EquivalenceVisitor visitor, EmptyStatement node, EmptyStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkAssertStatement_condition(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkAssertStatement_message(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return visitor.checkNodes(node.message, other.message, 'message');
  }

  bool checkAssertStatement_conditionStartOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return visitor.checkValues(node.conditionStartOffset,
        other.conditionStartOffset, 'conditionStartOffset');
  }

  bool checkAssertStatement_conditionEndOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return visitor.checkValues(node.conditionEndOffset,
        other.conditionEndOffset, 'conditionEndOffset');
  }

  bool checkAssertStatement_fileOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkLabeledStatement_body(EquivalenceVisitor visitor,
      LabeledStatement node, LabeledStatement other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkLabeledStatement_fileOffset(EquivalenceVisitor visitor,
      LabeledStatement node, LabeledStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkBreakStatement_target(
      EquivalenceVisitor visitor, BreakStatement node, BreakStatement other) {
    return visitor.checkDeclarations(node.target, other.target, 'target');
  }

  bool checkBreakStatement_fileOffset(
      EquivalenceVisitor visitor, BreakStatement node, BreakStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkWhileStatement_condition(
      EquivalenceVisitor visitor, WhileStatement node, WhileStatement other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkWhileStatement_body(
      EquivalenceVisitor visitor, WhileStatement node, WhileStatement other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkWhileStatement_fileOffset(
      EquivalenceVisitor visitor, WhileStatement node, WhileStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkDoStatement_body(
      EquivalenceVisitor visitor, DoStatement node, DoStatement other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkDoStatement_condition(
      EquivalenceVisitor visitor, DoStatement node, DoStatement other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkDoStatement_fileOffset(
      EquivalenceVisitor visitor, DoStatement node, DoStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkForStatement_variables(
      EquivalenceVisitor visitor, ForStatement node, ForStatement other) {
    return visitor.checkLists(
        node.variables, other.variables, visitor.checkNodes, 'variables');
  }

  bool checkForStatement_condition(
      EquivalenceVisitor visitor, ForStatement node, ForStatement other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkForStatement_updates(
      EquivalenceVisitor visitor, ForStatement node, ForStatement other) {
    return visitor.checkLists(
        node.updates, other.updates, visitor.checkNodes, 'updates');
  }

  bool checkForStatement_body(
      EquivalenceVisitor visitor, ForStatement node, ForStatement other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkForStatement_fileOffset(
      EquivalenceVisitor visitor, ForStatement node, ForStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkForInStatement_bodyOffset(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return visitor.checkValues(node.bodyOffset, other.bodyOffset, 'bodyOffset');
  }

  bool checkForInStatement_variable(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return visitor.checkNodes(node.variable, other.variable, 'variable');
  }

  bool checkForInStatement_iterable(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return visitor.checkNodes(node.iterable, other.iterable, 'iterable');
  }

  bool checkForInStatement_body(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkForInStatement_isAsync(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return visitor.checkValues(node.isAsync, other.isAsync, 'isAsync');
  }

  bool checkForInStatement_fileOffset(
      EquivalenceVisitor visitor, ForInStatement node, ForInStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkSwitchStatement_expression(
      EquivalenceVisitor visitor, SwitchStatement node, SwitchStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkSwitchStatement_cases(
      EquivalenceVisitor visitor, SwitchStatement node, SwitchStatement other) {
    return visitor.checkLists(
        node.cases, other.cases, visitor.checkNodes, 'cases');
  }

  bool checkSwitchStatement_isExplicitlyExhaustive(
      EquivalenceVisitor visitor, SwitchStatement node, SwitchStatement other) {
    return visitor.checkValues(node.isExplicitlyExhaustive,
        other.isExplicitlyExhaustive, 'isExplicitlyExhaustive');
  }

  bool checkSwitchStatement_expressionTypeInternal(
      EquivalenceVisitor visitor, SwitchStatement node, SwitchStatement other) {
    return visitor.checkNodes(node.expressionTypeInternal,
        other.expressionTypeInternal, 'expressionTypeInternal');
  }

  bool checkSwitchStatement_fileOffset(
      EquivalenceVisitor visitor, SwitchStatement node, SwitchStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkContinueSwitchStatement_target(EquivalenceVisitor visitor,
      ContinueSwitchStatement node, ContinueSwitchStatement other) {
    return visitor.checkDeclarations(node.target, other.target, 'target');
  }

  bool checkContinueSwitchStatement_fileOffset(EquivalenceVisitor visitor,
      ContinueSwitchStatement node, ContinueSwitchStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkIfStatement_condition(
      EquivalenceVisitor visitor, IfStatement node, IfStatement other) {
    return visitor.checkNodes(node.condition, other.condition, 'condition');
  }

  bool checkIfStatement_then(
      EquivalenceVisitor visitor, IfStatement node, IfStatement other) {
    return visitor.checkNodes(node.then, other.then, 'then');
  }

  bool checkIfStatement_otherwise(
      EquivalenceVisitor visitor, IfStatement node, IfStatement other) {
    return visitor.checkNodes(node.otherwise, other.otherwise, 'otherwise');
  }

  bool checkIfStatement_fileOffset(
      EquivalenceVisitor visitor, IfStatement node, IfStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkReturnStatement_expression(
      EquivalenceVisitor visitor, ReturnStatement node, ReturnStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkReturnStatement_fileOffset(
      EquivalenceVisitor visitor, ReturnStatement node, ReturnStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkTryCatch_body(
      EquivalenceVisitor visitor, TryCatch node, TryCatch other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkTryCatch_catches(
      EquivalenceVisitor visitor, TryCatch node, TryCatch other) {
    return visitor.checkLists(
        node.catches, other.catches, visitor.checkNodes, 'catches');
  }

  bool checkTryCatch_isSynthetic(
      EquivalenceVisitor visitor, TryCatch node, TryCatch other) {
    return visitor.checkValues(
        node.isSynthetic, other.isSynthetic, 'isSynthetic');
  }

  bool checkTryCatch_fileOffset(
      EquivalenceVisitor visitor, TryCatch node, TryCatch other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkTryFinally_body(
      EquivalenceVisitor visitor, TryFinally node, TryFinally other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkTryFinally_finalizer(
      EquivalenceVisitor visitor, TryFinally node, TryFinally other) {
    return visitor.checkNodes(node.finalizer, other.finalizer, 'finalizer');
  }

  bool checkTryFinally_fileOffset(
      EquivalenceVisitor visitor, TryFinally node, TryFinally other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkYieldStatement_expression(
      EquivalenceVisitor visitor, YieldStatement node, YieldStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkYieldStatement_flags(
      EquivalenceVisitor visitor, YieldStatement node, YieldStatement other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkYieldStatement_fileOffset(
      EquivalenceVisitor visitor, YieldStatement node, YieldStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkVariableDeclaration_fileEqualsOffset(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkValues(
        node.fileEqualsOffset, other.fileEqualsOffset, 'fileEqualsOffset');
  }

  bool checkVariableDeclaration_annotations(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkVariableDeclaration_name(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkVariableDeclaration_flags(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkVariableDeclaration_type(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkVariableDeclaration_binaryOffsetNoTag(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkValues(
        node.binaryOffsetNoTag, other.binaryOffsetNoTag, 'binaryOffsetNoTag');
  }

  bool checkVariableDeclaration_initializer(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return visitor.checkNodes(
        node.initializer, other.initializer, 'initializer');
  }

  bool checkVariableDeclaration_fileOffset(EquivalenceVisitor visitor,
      VariableDeclaration node, VariableDeclaration other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkFunctionDeclaration_variable(EquivalenceVisitor visitor,
      FunctionDeclaration node, FunctionDeclaration other) {
    return visitor.checkNodes(node.variable, other.variable, 'variable');
  }

  bool checkFunctionDeclaration_function(EquivalenceVisitor visitor,
      FunctionDeclaration node, FunctionDeclaration other) {
    return visitor.checkNodes(node.function, other.function, 'function');
  }

  bool checkFunctionDeclaration_fileOffset(EquivalenceVisitor visitor,
      FunctionDeclaration node, FunctionDeclaration other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkPatternSwitchStatement_expression(EquivalenceVisitor visitor,
      PatternSwitchStatement node, PatternSwitchStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkPatternSwitchStatement_cases(EquivalenceVisitor visitor,
      PatternSwitchStatement node, PatternSwitchStatement other) {
    return visitor.checkLists(
        node.cases, other.cases, visitor.checkNodes, 'cases');
  }

  bool checkPatternSwitchStatement_expressionTypeInternal(
      EquivalenceVisitor visitor,
      PatternSwitchStatement node,
      PatternSwitchStatement other) {
    return visitor.checkNodes(node.expressionTypeInternal,
        other.expressionTypeInternal, 'expressionTypeInternal');
  }

  bool checkPatternSwitchStatement_lastCaseTerminates(
      EquivalenceVisitor visitor,
      PatternSwitchStatement node,
      PatternSwitchStatement other) {
    return visitor.checkValues(node.lastCaseTerminates,
        other.lastCaseTerminates, 'lastCaseTerminates');
  }

  bool checkPatternSwitchStatement_isExplicitlyExhaustive(
      EquivalenceVisitor visitor,
      PatternSwitchStatement node,
      PatternSwitchStatement other) {
    return visitor.checkValues(node.isExplicitlyExhaustive,
        other.isExplicitlyExhaustive, 'isExplicitlyExhaustive');
  }

  bool checkPatternSwitchStatement_fileOffset(EquivalenceVisitor visitor,
      PatternSwitchStatement node, PatternSwitchStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkPatternVariableDeclaration_pattern(EquivalenceVisitor visitor,
      PatternVariableDeclaration node, PatternVariableDeclaration other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkPatternVariableDeclaration_initializer(EquivalenceVisitor visitor,
      PatternVariableDeclaration node, PatternVariableDeclaration other) {
    return visitor.checkNodes(
        node.initializer, other.initializer, 'initializer');
  }

  bool checkPatternVariableDeclaration_isFinal(EquivalenceVisitor visitor,
      PatternVariableDeclaration node, PatternVariableDeclaration other) {
    return visitor.checkValues(node.isFinal, other.isFinal, 'isFinal');
  }

  bool checkPatternVariableDeclaration_matchedValueType(
      EquivalenceVisitor visitor,
      PatternVariableDeclaration node,
      PatternVariableDeclaration other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkPatternVariableDeclaration_fileOffset(EquivalenceVisitor visitor,
      PatternVariableDeclaration node, PatternVariableDeclaration other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkIfCaseStatement_expression(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkIfCaseStatement_patternGuard(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return visitor.checkNodes(
        node.patternGuard, other.patternGuard, 'patternGuard');
  }

  bool checkIfCaseStatement_then(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return visitor.checkNodes(node.then, other.then, 'then');
  }

  bool checkIfCaseStatement_otherwise(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return visitor.checkNodes(node.otherwise, other.otherwise, 'otherwise');
  }

  bool checkIfCaseStatement_matchedValueType(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkIfCaseStatement_fileOffset(
      EquivalenceVisitor visitor, IfCaseStatement node, IfCaseStatement other) {
    return checkStatement_fileOffset(visitor, node, other);
  }

  bool checkSwitchCase_expressions(
      EquivalenceVisitor visitor, SwitchCase node, SwitchCase other) {
    return visitor.checkLists(
        node.expressions, other.expressions, visitor.checkNodes, 'expressions');
  }

  bool checkSwitchCase_expressionOffsets(
      EquivalenceVisitor visitor, SwitchCase node, SwitchCase other) {
    return visitor.checkLists(node.expressionOffsets, other.expressionOffsets,
        visitor.checkValues, 'expressionOffsets');
  }

  bool checkSwitchCase_body(
      EquivalenceVisitor visitor, SwitchCase node, SwitchCase other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkSwitchCase_isDefault(
      EquivalenceVisitor visitor, SwitchCase node, SwitchCase other) {
    return visitor.checkValues(node.isDefault, other.isDefault, 'isDefault');
  }

  bool checkSwitchCase_fileOffset(
      EquivalenceVisitor visitor, SwitchCase node, SwitchCase other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkCatch_guard(EquivalenceVisitor visitor, Catch node, Catch other) {
    return visitor.checkNodes(node.guard, other.guard, 'guard');
  }

  bool checkCatch_exception(
      EquivalenceVisitor visitor, Catch node, Catch other) {
    return visitor.checkNodes(node.exception, other.exception, 'exception');
  }

  bool checkCatch_stackTrace(
      EquivalenceVisitor visitor, Catch node, Catch other) {
    return visitor.checkNodes(node.stackTrace, other.stackTrace, 'stackTrace');
  }

  bool checkCatch_body(EquivalenceVisitor visitor, Catch node, Catch other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkCatch_fileOffset(
      EquivalenceVisitor visitor, Catch node, Catch other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkTypeParameter_flags(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkTypeParameter_annotations(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkLists(
        node.annotations, other.annotations, visitor.checkNodes, 'annotations');
  }

  bool checkTypeParameter_name(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkTypeParameter_bound(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkNodes(node.bound, other.bound, 'bound');
  }

  bool checkTypeParameter_defaultType(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkNodes(
        node.defaultType, other.defaultType, 'defaultType');
  }

  bool checkTypeParameter_variance(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return visitor.checkValues(node.variance, other.variance, 'variance');
  }

  bool checkTypeParameter_fileOffset(
      EquivalenceVisitor visitor, TypeParameter node, TypeParameter other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkComponent_problemsAsJson(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkLists(node.problemsAsJson, other.problemsAsJson,
        visitor.checkValues, 'problemsAsJson');
  }

  bool checkComponent_libraries(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkLists(
        node.libraries, other.libraries, visitor.checkNodes, 'libraries');
  }

  bool checkSource_lineStarts(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkLists(
        node.lineStarts, other.lineStarts, visitor.checkValues, 'lineStarts');
  }

  bool checkSource_source(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkLists(
        node.source, other.source, visitor.checkValues, 'source');
  }

  bool checkSource_importUri(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkValues(node.importUri, other.importUri, 'importUri');
  }

  bool checkSource_fileUri(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkValues(node.fileUri, other.fileUri, 'fileUri');
  }

  bool checkSource_constantCoverageConstructors(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkSets(
        node.constantCoverageConstructors,
        other.constantCoverageConstructors,
        visitor.matchReferences,
        visitor.checkReferences,
        'constantCoverageConstructors');
  }

  bool checkSource_cachedText(
      EquivalenceVisitor visitor, Source node, Source other) {
    return visitor.checkValues(node.cachedText, other.cachedText, 'cachedText');
  }

  bool checkComponent_uriToSource(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkMaps(node.uriToSource, other.uriToSource,
        visitor.matchValues, visitor.checkValues, (a, b, _) {
      if (identical(a, b)) return true;
      if (a is! Source) return false;
      if (b is! Source) return false;
      return checkSource(visitor, a, b);
    }, 'uriToSource');
  }

  bool checkComponent_metadata(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkMaps(
        node.metadata, other.metadata, visitor.matchValues, visitor.checkValues,
        (a, b, _) {
      if (identical(a, b)) return true;
      if (a is! MetadataRepository) return false;
      if (b is! MetadataRepository) return false;
      return checkMetadataRepository(visitor, a, b);
    }, 'metadata');
  }

  bool checkComponent_mainMethodName(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkReferences(
        node.mainMethodName, other.mainMethodName, 'mainMethodName');
  }

  bool checkComponent_mode(
      EquivalenceVisitor visitor, Component node, Component other) {
    return visitor.checkValues(node.mode, other.mode, 'mode');
  }

  bool checkComponent_fileOffset(
      EquivalenceVisitor visitor, Component node, Component other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkConstantPattern_expression(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkConstantPattern_expressionType(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return visitor.checkNodes(
        node.expressionType, other.expressionType, 'expressionType');
  }

  bool checkConstantPattern_equalsTargetReference(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return visitor.checkReferences(node.equalsTargetReference,
        other.equalsTargetReference, 'equalsTargetReference');
  }

  bool checkConstantPattern_equalsType(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return visitor.checkNodes(node.equalsType, other.equalsType, 'equalsType');
  }

  bool checkConstantPattern_value(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkPattern_fileOffset(
      EquivalenceVisitor visitor, Pattern node, Pattern other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkConstantPattern_fileOffset(
      EquivalenceVisitor visitor, ConstantPattern node, ConstantPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkAndPattern_left(
      EquivalenceVisitor visitor, AndPattern node, AndPattern other) {
    return visitor.checkNodes(node.left, other.left, 'left');
  }

  bool checkAndPattern_right(
      EquivalenceVisitor visitor, AndPattern node, AndPattern other) {
    return visitor.checkNodes(node.right, other.right, 'right');
  }

  bool checkAndPattern_fileOffset(
      EquivalenceVisitor visitor, AndPattern node, AndPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkOrPattern_left(
      EquivalenceVisitor visitor, OrPattern node, OrPattern other) {
    return visitor.checkNodes(node.left, other.left, 'left');
  }

  bool checkOrPattern_right(
      EquivalenceVisitor visitor, OrPattern node, OrPattern other) {
    return visitor.checkNodes(node.right, other.right, 'right');
  }

  bool checkOrPattern_orPatternJointVariables(
      EquivalenceVisitor visitor, OrPattern node, OrPattern other) {
    return visitor.checkLists(
        node.orPatternJointVariables,
        other.orPatternJointVariables,
        visitor.checkDeclarations,
        'orPatternJointVariables');
  }

  bool checkOrPattern_fileOffset(
      EquivalenceVisitor visitor, OrPattern node, OrPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkCastPattern_pattern(
      EquivalenceVisitor visitor, CastPattern node, CastPattern other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkCastPattern_type(
      EquivalenceVisitor visitor, CastPattern node, CastPattern other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkCastPattern_fileOffset(
      EquivalenceVisitor visitor, CastPattern node, CastPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkNullAssertPattern_pattern(EquivalenceVisitor visitor,
      NullAssertPattern node, NullAssertPattern other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkNullAssertPattern_fileOffset(EquivalenceVisitor visitor,
      NullAssertPattern node, NullAssertPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkNullCheckPattern_pattern(EquivalenceVisitor visitor,
      NullCheckPattern node, NullCheckPattern other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkNullCheckPattern_fileOffset(EquivalenceVisitor visitor,
      NullCheckPattern node, NullCheckPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkListPattern_typeArgument(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkListPattern_patterns(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkLists(
        node.patterns, other.patterns, visitor.checkNodes, 'patterns');
  }

  bool checkListPattern_requiredType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.requiredType, other.requiredType, 'requiredType');
  }

  bool checkListPattern_matchedValueType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkListPattern_needsCheck(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkValues(node.needsCheck, other.needsCheck, 'needsCheck');
  }

  bool checkListPattern_lookupType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(node.lookupType, other.lookupType, 'lookupType');
  }

  bool checkListPattern_hasRestPattern(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkValues(
        node.hasRestPattern, other.hasRestPattern, 'hasRestPattern');
  }

  bool checkListPattern_lengthTargetReference(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkReferences(node.lengthTargetReference,
        other.lengthTargetReference, 'lengthTargetReference');
  }

  bool checkListPattern_lengthType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(node.lengthType, other.lengthType, 'lengthType');
  }

  bool checkListPattern_lengthCheckTargetReference(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkReferences(node.lengthCheckTargetReference,
        other.lengthCheckTargetReference, 'lengthCheckTargetReference');
  }

  bool checkListPattern_lengthCheckType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.lengthCheckType, other.lengthCheckType, 'lengthCheckType');
  }

  bool checkListPattern_sublistTargetReference(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkReferences(node.sublistTargetReference,
        other.sublistTargetReference, 'sublistTargetReference');
  }

  bool checkListPattern_sublistType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.sublistType, other.sublistType, 'sublistType');
  }

  bool checkListPattern_minusTargetReference(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkReferences(node.minusTargetReference,
        other.minusTargetReference, 'minusTargetReference');
  }

  bool checkListPattern_minusType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(node.minusType, other.minusType, 'minusType');
  }

  bool checkListPattern_indexGetTargetReference(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkReferences(node.indexGetTargetReference,
        other.indexGetTargetReference, 'indexGetTargetReference');
  }

  bool checkListPattern_indexGetType(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return visitor.checkNodes(
        node.indexGetType, other.indexGetType, 'indexGetType');
  }

  bool checkListPattern_fileOffset(
      EquivalenceVisitor visitor, ListPattern node, ListPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkObjectPattern_requiredType(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return visitor.checkNodes(
        node.requiredType, other.requiredType, 'requiredType');
  }

  bool checkObjectPattern_fields(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return visitor.checkLists(
        node.fields, other.fields, visitor.checkNodes, 'fields');
  }

  bool checkObjectPattern_matchedValueType(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkObjectPattern_needsCheck(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return visitor.checkValues(node.needsCheck, other.needsCheck, 'needsCheck');
  }

  bool checkObjectPattern_lookupType(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return visitor.checkNodes(node.lookupType, other.lookupType, 'lookupType');
  }

  bool checkObjectPattern_fileOffset(
      EquivalenceVisitor visitor, ObjectPattern node, ObjectPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkRelationalPattern_kind(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkValues(node.kind, other.kind, 'kind');
  }

  bool checkRelationalPattern_expression(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkRelationalPattern_expressionType(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(
        node.expressionType, other.expressionType, 'expressionType');
  }

  bool checkRelationalPattern_matchedValueType(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkRelationalPattern_accessKind(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkValues(node.accessKind, other.accessKind, 'accessKind');
  }

  bool checkRelationalPattern_name(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(node.name, other.name, 'name');
  }

  bool checkRelationalPattern_targetReference(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkRelationalPattern_typeArguments(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkRelationalPattern_functionType(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkRelationalPattern_expressionValue(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return visitor.checkNodes(
        node.expressionValue, other.expressionValue, 'expressionValue');
  }

  bool checkRelationalPattern_fileOffset(EquivalenceVisitor visitor,
      RelationalPattern node, RelationalPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkWildcardPattern_type(
      EquivalenceVisitor visitor, WildcardPattern node, WildcardPattern other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkWildcardPattern_fileOffset(
      EquivalenceVisitor visitor, WildcardPattern node, WildcardPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkAssignedVariablePattern_variable(EquivalenceVisitor visitor,
      AssignedVariablePattern node, AssignedVariablePattern other) {
    return visitor.checkDeclarations(node.variable, other.variable, 'variable');
  }

  bool checkAssignedVariablePattern_matchedValueType(EquivalenceVisitor visitor,
      AssignedVariablePattern node, AssignedVariablePattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkAssignedVariablePattern_needsCast(EquivalenceVisitor visitor,
      AssignedVariablePattern node, AssignedVariablePattern other) {
    return visitor.checkValues(node.needsCast, other.needsCast, 'needsCast');
  }

  bool checkAssignedVariablePattern_hasObservableEffect(
      EquivalenceVisitor visitor,
      AssignedVariablePattern node,
      AssignedVariablePattern other) {
    return visitor.checkValues(node.hasObservableEffect,
        other.hasObservableEffect, 'hasObservableEffect');
  }

  bool checkAssignedVariablePattern_fileOffset(EquivalenceVisitor visitor,
      AssignedVariablePattern node, AssignedVariablePattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkMapPattern_keyType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(node.keyType, other.keyType, 'keyType');
  }

  bool checkMapPattern_valueType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(node.valueType, other.valueType, 'valueType');
  }

  bool checkMapPattern_entries(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkLists(
        node.entries, other.entries, visitor.checkNodes, 'entries');
  }

  bool checkMapPattern_requiredType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(
        node.requiredType, other.requiredType, 'requiredType');
  }

  bool checkMapPattern_matchedValueType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkMapPattern_needsCheck(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkValues(node.needsCheck, other.needsCheck, 'needsCheck');
  }

  bool checkMapPattern_lookupType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(node.lookupType, other.lookupType, 'lookupType');
  }

  bool checkMapPattern_containsKeyTargetReference(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkReferences(node.containsKeyTargetReference,
        other.containsKeyTargetReference, 'containsKeyTargetReference');
  }

  bool checkMapPattern_containsKeyType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(
        node.containsKeyType, other.containsKeyType, 'containsKeyType');
  }

  bool checkMapPattern_indexGetTargetReference(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkReferences(node.indexGetTargetReference,
        other.indexGetTargetReference, 'indexGetTargetReference');
  }

  bool checkMapPattern_indexGetType(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return visitor.checkNodes(
        node.indexGetType, other.indexGetType, 'indexGetType');
  }

  bool checkMapPattern_fileOffset(
      EquivalenceVisitor visitor, MapPattern node, MapPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkNamedPattern_name(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkNamedPattern_pattern(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkNamedPattern_fieldName(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkNodes(node.fieldName, other.fieldName, 'fieldName');
  }

  bool checkNamedPattern_accessKind(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkValues(node.accessKind, other.accessKind, 'accessKind');
  }

  bool checkNamedPattern_targetReference(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkNamedPattern_resultType(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkNodes(node.resultType, other.resultType, 'resultType');
  }

  bool checkNamedPattern_checkReturn(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkValues(
        node.checkReturn, other.checkReturn, 'checkReturn');
  }

  bool checkNamedPattern_recordType(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkNodes(node.recordType, other.recordType, 'recordType');
  }

  bool checkNamedPattern_recordFieldIndex(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkValues(
        node.recordFieldIndex, other.recordFieldIndex, 'recordFieldIndex');
  }

  bool checkNamedPattern_functionType(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkNodes(
        node.functionType, other.functionType, 'functionType');
  }

  bool checkNamedPattern_typeArguments(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkNamedPattern_fileOffset(
      EquivalenceVisitor visitor, NamedPattern node, NamedPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkRecordPattern_patterns(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return visitor.checkLists(
        node.patterns, other.patterns, visitor.checkNodes, 'patterns');
  }

  bool checkRecordPattern_requiredType(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return visitor.checkNodes(
        node.requiredType, other.requiredType, 'requiredType');
  }

  bool checkRecordPattern_matchedValueType(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkRecordPattern_needsCheck(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return visitor.checkValues(node.needsCheck, other.needsCheck, 'needsCheck');
  }

  bool checkRecordPattern_lookupType(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return visitor.checkNodes(node.lookupType, other.lookupType, 'lookupType');
  }

  bool checkRecordPattern_fileOffset(
      EquivalenceVisitor visitor, RecordPattern node, RecordPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkVariablePattern_type(
      EquivalenceVisitor visitor, VariablePattern node, VariablePattern other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkVariablePattern_variable(
      EquivalenceVisitor visitor, VariablePattern node, VariablePattern other) {
    return visitor.checkNodes(node.variable, other.variable, 'variable');
  }

  bool checkVariablePattern_matchedValueType(
      EquivalenceVisitor visitor, VariablePattern node, VariablePattern other) {
    return visitor.checkNodes(
        node.matchedValueType, other.matchedValueType, 'matchedValueType');
  }

  bool checkVariablePattern_fileOffset(
      EquivalenceVisitor visitor, VariablePattern node, VariablePattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkRestPattern_subPattern(
      EquivalenceVisitor visitor, RestPattern node, RestPattern other) {
    return visitor.checkNodes(node.subPattern, other.subPattern, 'subPattern');
  }

  bool checkRestPattern_fileOffset(
      EquivalenceVisitor visitor, RestPattern node, RestPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkInvalidPattern_invalidExpression(
      EquivalenceVisitor visitor, InvalidPattern node, InvalidPattern other) {
    return visitor.checkNodes(
        node.invalidExpression, other.invalidExpression, 'invalidExpression');
  }

  bool checkInvalidPattern_declaredVariables(
      EquivalenceVisitor visitor, InvalidPattern node, InvalidPattern other) {
    return visitor.checkLists(node.declaredVariables, other.declaredVariables,
        visitor.checkNodes, 'declaredVariables');
  }

  bool checkInvalidPattern_fileOffset(
      EquivalenceVisitor visitor, InvalidPattern node, InvalidPattern other) {
    return checkPattern_fileOffset(visitor, node, other);
  }

  bool checkMapPatternEntry_key(
      EquivalenceVisitor visitor, MapPatternEntry node, MapPatternEntry other) {
    return visitor.checkNodes(node.key, other.key, 'key');
  }

  bool checkMapPatternEntry_value(
      EquivalenceVisitor visitor, MapPatternEntry node, MapPatternEntry other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkMapPatternEntry_keyType(
      EquivalenceVisitor visitor, MapPatternEntry node, MapPatternEntry other) {
    return visitor.checkNodes(node.keyType, other.keyType, 'keyType');
  }

  bool checkMapPatternEntry_keyValue(
      EquivalenceVisitor visitor, MapPatternEntry node, MapPatternEntry other) {
    return visitor.checkNodes(node.keyValue, other.keyValue, 'keyValue');
  }

  bool checkMapPatternEntry_fileOffset(
      EquivalenceVisitor visitor, MapPatternEntry node, MapPatternEntry other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkMapPatternRestEntry_fileOffset(EquivalenceVisitor visitor,
      MapPatternRestEntry node, MapPatternRestEntry other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkPatternGuard_pattern(
      EquivalenceVisitor visitor, PatternGuard node, PatternGuard other) {
    return visitor.checkNodes(node.pattern, other.pattern, 'pattern');
  }

  bool checkPatternGuard_guard(
      EquivalenceVisitor visitor, PatternGuard node, PatternGuard other) {
    return visitor.checkNodes(node.guard, other.guard, 'guard');
  }

  bool checkPatternGuard_fileOffset(
      EquivalenceVisitor visitor, PatternGuard node, PatternGuard other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkPatternSwitchCase_caseOffsets(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkLists(node.caseOffsets, other.caseOffsets,
        visitor.checkValues, 'caseOffsets');
  }

  bool checkPatternSwitchCase_patternGuards(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkLists(node.patternGuards, other.patternGuards,
        visitor.checkNodes, 'patternGuards');
  }

  bool checkPatternSwitchCase_labelUsers(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkLists(
        node.labelUsers, other.labelUsers, visitor.checkNodes, 'labelUsers');
  }

  bool checkPatternSwitchCase_body(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkNodes(node.body, other.body, 'body');
  }

  bool checkPatternSwitchCase_isDefault(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkValues(node.isDefault, other.isDefault, 'isDefault');
  }

  bool checkPatternSwitchCase_hasLabel(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkValues(node.hasLabel, other.hasLabel, 'hasLabel');
  }

  bool checkPatternSwitchCase_jointVariables(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return visitor.checkLists(node.jointVariables, other.jointVariables,
        visitor.checkNodes, 'jointVariables');
  }

  bool checkPatternSwitchCase_jointVariableFirstUseOffsets(
      EquivalenceVisitor visitor,
      PatternSwitchCase node,
      PatternSwitchCase other) {
    return visitor.checkLists(
        node.jointVariableFirstUseOffsets,
        other.jointVariableFirstUseOffsets,
        visitor.checkValues,
        'jointVariableFirstUseOffsets');
  }

  bool checkPatternSwitchCase_fileOffset(EquivalenceVisitor visitor,
      PatternSwitchCase node, PatternSwitchCase other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkSwitchExpressionCase_patternGuard(EquivalenceVisitor visitor,
      SwitchExpressionCase node, SwitchExpressionCase other) {
    return visitor.checkNodes(
        node.patternGuard, other.patternGuard, 'patternGuard');
  }

  bool checkSwitchExpressionCase_expression(EquivalenceVisitor visitor,
      SwitchExpressionCase node, SwitchExpressionCase other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }

  bool checkSwitchExpressionCase_fileOffset(EquivalenceVisitor visitor,
      SwitchExpressionCase node, SwitchExpressionCase other) {
    return checkTreeNode_fileOffset(visitor, node, other);
  }

  bool checkName_text(EquivalenceVisitor visitor, Name node, Name other) {
    return visitor.checkValues(node.text, other.text, 'text');
  }

  bool checkInterfaceType_classReference(
      EquivalenceVisitor visitor, InterfaceType node, InterfaceType other) {
    return visitor.checkReferences(
        node.classReference, other.classReference, 'classReference');
  }

  bool checkInterfaceType_declaredNullability(
      EquivalenceVisitor visitor, InterfaceType node, InterfaceType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkInterfaceType_typeArguments(
      EquivalenceVisitor visitor, InterfaceType node, InterfaceType other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkExtensionType_extensionTypeDeclarationReference(
      EquivalenceVisitor visitor, ExtensionType node, ExtensionType other) {
    return visitor.checkReferences(
        node.extensionTypeDeclarationReference,
        other.extensionTypeDeclarationReference,
        'extensionTypeDeclarationReference');
  }

  bool checkExtensionType_declaredNullability(
      EquivalenceVisitor visitor, ExtensionType node, ExtensionType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkExtensionType_typeArguments(
      EquivalenceVisitor visitor, ExtensionType node, ExtensionType other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkNeverType_declaredNullability(
      EquivalenceVisitor visitor, NeverType node, NeverType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkFunctionType_typeParameters(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkLists(node.typeParameters, other.typeParameters,
        visitor.checkNodes, 'typeParameters');
  }

  bool checkFunctionType_requiredParameterCount(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkValues(node.requiredParameterCount,
        other.requiredParameterCount, 'requiredParameterCount');
  }

  bool checkFunctionType_positionalParameters(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkLists(node.positionalParameters,
        other.positionalParameters, visitor.checkNodes, 'positionalParameters');
  }

  bool checkFunctionType_namedParameters(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkLists(node.namedParameters, other.namedParameters,
        visitor.checkNodes, 'namedParameters');
  }

  bool checkFunctionType_declaredNullability(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkFunctionType_returnType(
      EquivalenceVisitor visitor, FunctionType node, FunctionType other) {
    return visitor.checkNodes(node.returnType, other.returnType, 'returnType');
  }

  bool checkTypedefType_declaredNullability(
      EquivalenceVisitor visitor, TypedefType node, TypedefType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkTypedefType_typedefReference(
      EquivalenceVisitor visitor, TypedefType node, TypedefType other) {
    return visitor.checkReferences(
        node.typedefReference, other.typedefReference, 'typedefReference');
  }

  bool checkTypedefType_typeArguments(
      EquivalenceVisitor visitor, TypedefType node, TypedefType other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkFutureOrType_typeArgument(
      EquivalenceVisitor visitor, FutureOrType node, FutureOrType other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkFutureOrType_declaredNullability(
      EquivalenceVisitor visitor, FutureOrType node, FutureOrType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkIntersectionType_left(EquivalenceVisitor visitor,
      IntersectionType node, IntersectionType other) {
    return visitor.checkNodes(node.left, other.left, 'left');
  }

  bool checkIntersectionType_right(EquivalenceVisitor visitor,
      IntersectionType node, IntersectionType other) {
    return visitor.checkNodes(node.right, other.right, 'right');
  }

  bool checkTypeParameterType_declaredNullability(EquivalenceVisitor visitor,
      TypeParameterType node, TypeParameterType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkTypeParameterType_parameter(EquivalenceVisitor visitor,
      TypeParameterType node, TypeParameterType other) {
    return visitor.checkDeclarations(
        node.parameter, other.parameter, 'parameter');
  }

  bool checkStructuralParameterType_declaredNullability(
      EquivalenceVisitor visitor,
      StructuralParameterType node,
      StructuralParameterType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkStructuralParameterType_parameter(EquivalenceVisitor visitor,
      StructuralParameterType node, StructuralParameterType other) {
    return visitor.checkDeclarations(
        node.parameter, other.parameter, 'parameter');
  }

  bool checkRecordType_positional(
      EquivalenceVisitor visitor, RecordType node, RecordType other) {
    return visitor.checkLists(
        node.positional, other.positional, visitor.checkNodes, 'positional');
  }

  bool checkRecordType_named(
      EquivalenceVisitor visitor, RecordType node, RecordType other) {
    return visitor.checkLists(
        node.named, other.named, visitor.checkNodes, 'named');
  }

  bool checkRecordType_declaredNullability(
      EquivalenceVisitor visitor, RecordType node, RecordType other) {
    return visitor.checkValues(node.declaredNullability,
        other.declaredNullability, 'declaredNullability');
  }

  bool checkNamedType_name(
      EquivalenceVisitor visitor, NamedType node, NamedType other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkNamedType_type(
      EquivalenceVisitor visitor, NamedType node, NamedType other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkNamedType_isRequired(
      EquivalenceVisitor visitor, NamedType node, NamedType other) {
    return visitor.checkValues(node.isRequired, other.isRequired, 'isRequired');
  }

  bool checkStructuralParameter_flags(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkValues(node.flags, other.flags, 'flags');
  }

  bool checkStructuralParameter_name(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkStructuralParameter_fileOffset(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkValues(node.fileOffset, other.fileOffset, 'fileOffset');
  }

  bool checkStructuralParameter_uri(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkValues(node.uri, other.uri, 'uri');
  }

  bool checkStructuralParameter_bound(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkNodes(node.bound, other.bound, 'bound');
  }

  bool checkStructuralParameter_defaultType(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkNodes(
        node.defaultType, other.defaultType, 'defaultType');
  }

  bool checkStructuralParameter_variance(EquivalenceVisitor visitor,
      StructuralParameter node, StructuralParameter other) {
    return visitor.checkValues(node.variance, other.variance, 'variance');
  }

  bool checkSupertype_className(
      EquivalenceVisitor visitor, Supertype node, Supertype other) {
    return visitor.checkReferences(
        node.className, other.className, 'className');
  }

  bool checkSupertype_typeArguments(
      EquivalenceVisitor visitor, Supertype node, Supertype other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkPrimitiveConstant_value(EquivalenceVisitor visitor,
      PrimitiveConstant node, PrimitiveConstant other) {
    return visitor.checkValues(node.value, other.value, 'value');
  }

  bool checkNullConstant_value(
      EquivalenceVisitor visitor, NullConstant node, NullConstant other) {
    return checkPrimitiveConstant_value(visitor, node, other);
  }

  bool checkBoolConstant_value(
      EquivalenceVisitor visitor, BoolConstant node, BoolConstant other) {
    return checkPrimitiveConstant_value(visitor, node, other);
  }

  bool checkIntConstant_value(
      EquivalenceVisitor visitor, IntConstant node, IntConstant other) {
    return checkPrimitiveConstant_value(visitor, node, other);
  }

  bool checkDoubleConstant_value(
      EquivalenceVisitor visitor, DoubleConstant node, DoubleConstant other) {
    return checkPrimitiveConstant_value(visitor, node, other);
  }

  bool checkStringConstant_value(
      EquivalenceVisitor visitor, StringConstant node, StringConstant other) {
    return checkPrimitiveConstant_value(visitor, node, other);
  }

  bool checkSymbolConstant_name(
      EquivalenceVisitor visitor, SymbolConstant node, SymbolConstant other) {
    return visitor.checkValues(node.name, other.name, 'name');
  }

  bool checkSymbolConstant_libraryReference(
      EquivalenceVisitor visitor, SymbolConstant node, SymbolConstant other) {
    return visitor.checkReferences(
        node.libraryReference, other.libraryReference, 'libraryReference');
  }

  bool checkMapConstant_keyType(
      EquivalenceVisitor visitor, MapConstant node, MapConstant other) {
    return visitor.checkNodes(node.keyType, other.keyType, 'keyType');
  }

  bool checkMapConstant_valueType(
      EquivalenceVisitor visitor, MapConstant node, MapConstant other) {
    return visitor.checkNodes(node.valueType, other.valueType, 'valueType');
  }

  bool checkConstantMapEntry_key(EquivalenceVisitor visitor,
      ConstantMapEntry node, ConstantMapEntry other) {
    return visitor.checkNodes(node.key, other.key, 'key');
  }

  bool checkConstantMapEntry_value(EquivalenceVisitor visitor,
      ConstantMapEntry node, ConstantMapEntry other) {
    return visitor.checkNodes(node.value, other.value, 'value');
  }

  bool checkMapConstant_entries(
      EquivalenceVisitor visitor, MapConstant node, MapConstant other) {
    return visitor.checkLists(node.entries, other.entries, (a, b, _) {
      if (identical(a, b)) return true;
      if (a is! ConstantMapEntry) return false;
      if (b is! ConstantMapEntry) return false;
      return checkConstantMapEntry(visitor, a, b);
    }, 'entries');
  }

  bool checkListConstant_typeArgument(
      EquivalenceVisitor visitor, ListConstant node, ListConstant other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkListConstant_entries(
      EquivalenceVisitor visitor, ListConstant node, ListConstant other) {
    return visitor.checkLists(
        node.entries, other.entries, visitor.checkNodes, 'entries');
  }

  bool checkSetConstant_typeArgument(
      EquivalenceVisitor visitor, SetConstant node, SetConstant other) {
    return visitor.checkNodes(
        node.typeArgument, other.typeArgument, 'typeArgument');
  }

  bool checkSetConstant_entries(
      EquivalenceVisitor visitor, SetConstant node, SetConstant other) {
    return visitor.checkLists(
        node.entries, other.entries, visitor.checkNodes, 'entries');
  }

  bool checkRecordConstant_positional(
      EquivalenceVisitor visitor, RecordConstant node, RecordConstant other) {
    return visitor.checkLists(
        node.positional, other.positional, visitor.checkNodes, 'positional');
  }

  bool checkRecordConstant_named(
      EquivalenceVisitor visitor, RecordConstant node, RecordConstant other) {
    return visitor.checkMaps(node.named, other.named, visitor.matchValues,
        visitor.checkValues, visitor.checkNodes, 'named');
  }

  bool checkRecordConstant_recordType(
      EquivalenceVisitor visitor, RecordConstant node, RecordConstant other) {
    return visitor.checkNodes(node.recordType, other.recordType, 'recordType');
  }

  bool checkInstanceConstant_classReference(EquivalenceVisitor visitor,
      InstanceConstant node, InstanceConstant other) {
    return visitor.checkReferences(
        node.classReference, other.classReference, 'classReference');
  }

  bool checkInstanceConstant_typeArguments(EquivalenceVisitor visitor,
      InstanceConstant node, InstanceConstant other) {
    return visitor.checkLists(node.typeArguments, other.typeArguments,
        visitor.checkNodes, 'typeArguments');
  }

  bool checkInstanceConstant_fieldValues(EquivalenceVisitor visitor,
      InstanceConstant node, InstanceConstant other) {
    return visitor.checkMaps(
        node.fieldValues,
        other.fieldValues,
        visitor.matchReferences,
        visitor.checkReferences,
        visitor.checkNodes,
        'fieldValues');
  }

  bool checkInstantiationConstant_tearOffConstant(EquivalenceVisitor visitor,
      InstantiationConstant node, InstantiationConstant other) {
    return visitor.checkNodes(
        node.tearOffConstant, other.tearOffConstant, 'tearOffConstant');
  }

  bool checkInstantiationConstant_types(EquivalenceVisitor visitor,
      InstantiationConstant node, InstantiationConstant other) {
    return visitor.checkLists(
        node.types, other.types, visitor.checkNodes, 'types');
  }

  bool checkStaticTearOffConstant_targetReference(EquivalenceVisitor visitor,
      StaticTearOffConstant node, StaticTearOffConstant other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkConstructorTearOffConstant_targetReference(
      EquivalenceVisitor visitor,
      ConstructorTearOffConstant node,
      ConstructorTearOffConstant other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkRedirectingFactoryTearOffConstant_targetReference(
      EquivalenceVisitor visitor,
      RedirectingFactoryTearOffConstant node,
      RedirectingFactoryTearOffConstant other) {
    return visitor.checkReferences(
        node.targetReference, other.targetReference, 'targetReference');
  }

  bool checkTypedefTearOffConstant_parameters(EquivalenceVisitor visitor,
      TypedefTearOffConstant node, TypedefTearOffConstant other) {
    return visitor.checkLists(
        node.parameters, other.parameters, visitor.checkNodes, 'parameters');
  }

  bool checkTypedefTearOffConstant_tearOffConstant(EquivalenceVisitor visitor,
      TypedefTearOffConstant node, TypedefTearOffConstant other) {
    return visitor.checkNodes(
        node.tearOffConstant, other.tearOffConstant, 'tearOffConstant');
  }

  bool checkTypedefTearOffConstant_types(EquivalenceVisitor visitor,
      TypedefTearOffConstant node, TypedefTearOffConstant other) {
    return visitor.checkLists(
        node.types, other.types, visitor.checkNodes, 'types');
  }

  bool checkTypeLiteralConstant_type(EquivalenceVisitor visitor,
      TypeLiteralConstant node, TypeLiteralConstant other) {
    return visitor.checkNodes(node.type, other.type, 'type');
  }

  bool checkUnevaluatedConstant_expression(EquivalenceVisitor visitor,
      UnevaluatedConstant node, UnevaluatedConstant other) {
    return visitor.checkNodes(node.expression, other.expression, 'expression');
  }
}
