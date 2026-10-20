// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

@V1Ast('The V2 counterpart is FindNode2.')
class FindNode extends _FindNodeBase {
  new(super.content, super.unit);

  BinaryExpression get firstBinaryExpression => _first();

  List<MethodInvocation> get methodInvocations {
    return _nodes<MethodInvocation>();
  }

  AssignmentExpression get singleAssignmentExpression => _single();

  BinaryExpression get singleBinaryExpression => _single();

  ClassTypeAlias get singleClassTypeAlias => _single();

  ConstructorDeclaration get singleConstructorDeclaration => _single();

  ConstructorName get singleConstructorName => _single();

  DotShorthandInvocation get singleDotShorthandInvocation => _single();

  DotShorthandPropertyAccess get singleDotShorthandPropertyAccess => _single();

  EnumConstantDeclaration get singleEnumConstantDeclaration => _single();

  EnumDeclaration get singleEnumDeclaration => _single();

  ExtensionDeclaration get singleExtensionDeclaration => _single();

  FieldDeclaration get singleFieldDeclaration => _single();

  FunctionExpressionInvocation get singleFunctionExpressionInvocation =>
      _single();

  FunctionReference get singleFunctionReference => _single();

  FunctionTypeAlias get singleFunctionTypeAlias => _single();

  GenericTypeAlias get singleGenericTypeAlias => _single();

  ImplicitCallReference get singleImplicitCallReference => _single();

  IndexExpression get singleIndexExpression => _single();

  InstanceCreationExpression get singleInstanceCreationExpression => _single();

  MethodDeclaration get singleMethodDeclaration => _single();

  MethodInvocation get singleMethodInvocation => _single();

  MixinDeclaration get singleMixinDeclaration => _single();

  PrefixedIdentifier get singlePrefixedIdentifier => _single();

  PrimaryConstructorBody get singlePrimaryConstructorBody => _single();

  PropertyAccess get singlePropertyAccess => _single();

  SimpleIdentifier get singleSimpleIdentifier => _single();

  SuperExpression get singleSuperExpression => _single();

  TopLevelVariableDeclaration get singleTopLevelVariableDeclaration =>
      _single();

  VariableDeclaration get singleVariableDeclaration => _single();

  VariableDeclarationList get singleVariableDeclarationList => _single();

  VariableDeclarationStatement get singleVariableDeclarationStatement =>
      _single();

  AssignmentExpression assignment(String search) {
    return _node(search, (n) => n is AssignmentExpression);
  }

  BinaryExpression binary(String search) {
    return _node(search, (node) => node is BinaryExpression);
  }

  ClassTypeAlias classTypeAlias(String search) {
    return _node(search, (n) => n is ClassTypeAlias);
  }

  ConstructorDeclaration constructor(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorDeclaration constructorDeclaration(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorName constructorName(String search) {
    return _node(search, (n) => n is ConstructorName);
  }

  ConstructorReference constructorReference(String search) {
    return _node(search, (n) => n is ConstructorReference);
  }

  DotShorthandInvocation dotShorthandInvocation(String search) {
    return _node(search, (n) => n is DotShorthandInvocation);
  }

  DotShorthandPropertyAccess dotShorthandPropertyAccess(String search) {
    return _node(search, (n) => n is DotShorthandPropertyAccess);
  }

  EnumConstantDeclaration enumConstantDeclaration(String search) {
    return _node(search, (n) => n is EnumConstantDeclaration);
  }

  EnumDeclaration enumDeclaration(String search) {
    return _node(search, (n) => n is EnumDeclaration);
  }

  ExtensionDeclaration extensionDeclaration(String search) {
    return _node(search, (n) => n is ExtensionDeclaration);
  }

  ExtensionOverride extensionOverride(String search) {
    return _node(search, (n) => n is ExtensionOverride);
  }

  FieldDeclaration fieldDeclaration(String search) {
    return _node(search, (n) => n is FieldDeclaration);
  }

  FunctionExpressionInvocation functionExpressionInvocation(String search) {
    return _node(search, (n) => n is FunctionExpressionInvocation);
  }

  FunctionReference functionReference(String search) {
    return _node(search, (n) => n is FunctionReference);
  }

  FunctionTypeAlias functionTypeAlias(String search) {
    return _node(search, (n) => n is FunctionTypeAlias);
  }

  GenericTypeAlias genericTypeAlias(String search) {
    return _node(search, (n) => n is GenericTypeAlias);
  }

  ImplicitCallReference implicitCallReference(String search) {
    return _node(search, (n) => n is ImplicitCallReference);
  }

  IndexExpression index(String search) {
    return _node(search, (n) => n is IndexExpression);
  }

  InstanceCreationExpression instanceCreation(String search) {
    return _node(search, (node) => node is InstanceCreationExpression);
  }

  MethodDeclaration methodDeclaration(String search) {
    return _node(search, (n) => n is MethodDeclaration);
  }

  MethodInvocation methodInvocation(String search) {
    return _node(search, (n) => n is MethodInvocation);
  }

  MixinDeclaration mixin(String search) {
    return _node(search, (n) => n is MixinDeclaration);
  }

  MixinDeclaration mixinDeclaration(String search) {
    return _node(search, (n) => n is MixinDeclaration);
  }

  PostfixExpression postfixExpression(String search) {
    return _node(search, (node) => node is PostfixExpression);
  }

  PrefixExpression prefix(String search) {
    return _node(search, (n) => n is PrefixExpression);
  }

  PrefixedIdentifier prefixed(String search) {
    return _node(search, (n) => n is PrefixedIdentifier);
  }

  PropertyAccess propertyAccess(String search) {
    return _node(search, (n) => n is PropertyAccess);
  }

  SimpleIdentifier simple(String search) {
    return _node(search, (_) => true);
  }

  SuperExpression super_(String search) {
    return _node(search, (n) => n is SuperExpression);
  }

  TopLevelVariableDeclaration topLevelVariableDeclaration(String search) {
    return _node(search, (n) => n is TopLevelVariableDeclaration);
  }

  VariableDeclaration topVariableDeclarationByName(String name) {
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          if (variable.name.lexeme == name) {
            return variable;
          }
        }
      }
    }
    throw StateError(name);
  }

  VariableDeclaration variableDeclaration(String search) {
    return _node(search, (n) => n is VariableDeclaration);
  }

  VariableDeclarationList variableDeclarationList(String search) {
    return _node(search, (n) => n is VariableDeclarationList);
  }

  VariableDeclarationStatement variableDeclarationStatement(String search) {
    return _node(search, (n) => n is VariableDeclarationStatement);
  }

  @override
  AstNode? _locateNode(int offset) {
    return NodeLocator(offset).searchWithin(unit);
  }

  @override
  List<T> _nodes<T extends AstNode>() {
    var visitor = _TypedNodeVisitor<T>();
    unit.accept(visitor);
    return visitor.nodes;
  }

  @override
  AstNode? _thisOrAncestorMatching(
    AstNode node,
    bool Function(AstNode) predicate,
  ) {
    return node.thisOrAncestorMatching(predicate);
  }
}

/// Finds nodes in the canonical V2 AST, including nodes shared with V1.
///
/// Searches match the requested node type without falling back to a V1
/// projection. For example, a [CompoundAssignment] must be found with
/// [compoundAssignment], not [FindNode.assignment]. Use [FindNode] to search
/// the V1 view.
class FindNode2 extends _FindNodeBase {
  new(super.content, super.unit);

  BinaryOperatorInvocation get firstBinaryOperatorInvocation => _first();

  BinaryOperatorInvocation get singleBinaryOperatorInvocation => _single();

  CallInvocation get singleCallInvocation => _single();

  /// The only member of a class-like or enum body.
  AnnotatedNode get singleClassMember {
    return [
      for (var body in _nodes<ClassBody>()) ...body.members2,
      for (var body in _nodes<InstanceDeclarationBody>()) ...body.members,
    ].single;
  }

  ClassTypeAlias2 get singleClassTypeAlias => _single();

  CompoundAssignment get singleCompoundAssignment => _single();

  ConstructorDeclaration2 get singleConstructorDeclaration => _single();

  ConstructorInvocation get singleConstructorInvocation => _single();

  ConstructorTearOff get singleConstructorTearOff => _single();

  ConstructorTypeReference get singleConstructorTypeReference => _single();

  DirectAssignment get singleDirectAssignment => _single();

  DotShorthandMethodInvocation get singleDotShorthandMethodInvocation =>
      _single();

  DotShorthandNameExpression get singleDotShorthandNameExpression => _single();

  EnumConstantDeclaration2 get singleEnumConstantDeclaration => _single();

  EnumDeclaration2 get singleEnumDeclaration => _single();

  ExtensionDeclaration2 get singleExtensionDeclaration => _single();

  Field2 get singleField => _single();

  FieldsDeclaration get singleFieldsDeclaration => _single();

  FunctionTypeAlias2 get singleFunctionTypeAlias => _single();

  GenericTypeAlias2 get singleGenericTypeAlias => _single();

  GetterDeclaration get singleGetterDeclaration => _single();

  IfNull get singleIfNull => _single();

  IfNullAssignment get singleIfNullAssignment => _single();

  ImportPrefixedFunctionInvocation get singleImportPrefixedFunctionInvocation =>
      _single();

  ImportPrefixedNameExpression get singleImportPrefixedNameExpression =>
      _single();

  InvalidExtensionOverrideExpression
  get singleInvalidExtensionOverrideExpression => _single();

  InvalidSuperExpression get singleInvalidSuperExpression => _single();

  LocalFunctionDeclaration get singleLocalFunctionDeclaration => _single();

  LocalVariable get singleLocalVariable => _single();

  LocalVariablesDeclaration get singleLocalVariablesDeclaration => _single();

  LocalVariablesDeclarationStatement
  get singleLocalVariablesDeclarationStatement => _single();

  LogicalAnd get singleLogicalAnd => _single();

  LogicalNot get singleLogicalNot => _single();

  LogicalOr get singleLogicalOr => _single();

  MethodDeclaration2 get singleMethodDeclaration => _single();

  MixinDeclaration2 get singleMixinDeclaration => _single();

  NullAssertionExpression get singleNullAssertionExpression => _single();

  OperatorDeclaration get singleOperatorDeclaration => _single();

  PrimaryConstructorBody2 get singlePrimaryConstructorBody => _single();

  ReceiverMethodInvocation get singleReceiverMethodInvocation => _single();

  SetterDeclaration get singleSetterDeclaration => _single();

  SuperReference get singleSuperReference => _single();

  TopLevelFunctionDeclaration get singleTopLevelFunctionDeclaration =>
      _single();

  TopLevelGetterDeclaration get singleTopLevelGetterDeclaration => _single();

  TopLevelSetterDeclaration get singleTopLevelSetterDeclaration => _single();

  TopLevelVariable2 get singleTopLevelVariable => _single();

  TopLevelVariablesDeclaration get singleTopLevelVariablesDeclaration =>
      _single();

  UnaryOperatorInvocation get singleUnaryOperatorInvocation => _single();

  UnqualifiedFunctionInvocation get singleUnqualifiedFunctionInvocation =>
      _single();

  UnqualifiedNameExpression get singleUnqualifiedNameExpression => _single();

  BinaryOperatorInvocation binaryOperatorInvocation(String search) {
    return _node(search, (node) => node is BinaryOperatorInvocation);
  }

  CallInvocation callInvocation(String search) {
    return _node(search, (node) => node is CallInvocation);
  }

  ClassTypeAlias2 classTypeAlias(String search) {
    return _node(search, (n) => n is ClassTypeAlias2);
  }

  CompoundAssignment compoundAssignment(String search) {
    return _node(search, (node) => node is CompoundAssignment);
  }

  ConstructorDeclaration2 constructor(String search) {
    return _node(search, (n) => n is ConstructorDeclaration2);
  }

  ConstructorDeclaration2 constructorDeclaration(String search) {
    return _node(search, (n) => n is ConstructorDeclaration2);
  }

  ConstructorInvocation constructorInvocation(String search) {
    return _node(search, (node) => node is ConstructorInvocation);
  }

  ConstructorTearOff constructorTearOff(String search) {
    return _node(search, (node) => node is ConstructorTearOff);
  }

  DirectAssignment directAssignment(String search) {
    return _node(search, (node) => node is DirectAssignment);
  }

  DotShorthandMethodInvocation dotShorthandMethodInvocation(String search) {
    return _node(search, (node) => node is DotShorthandMethodInvocation);
  }

  DotShorthandNameExpression dotShorthandNameExpression(String search) {
    return _node(search, (node) => node is DotShorthandNameExpression);
  }

  EnumConstantDeclaration2 enumConstantDeclaration(String search) {
    return _node(search, (n) => n is EnumConstantDeclaration2);
  }

  EnumDeclaration2 enumDeclaration(String search) {
    return _node(search, (n) => n is EnumDeclaration2);
  }

  ExtensionDeclaration2 extensionDeclaration(String search) {
    return _node(search, (n) => n is ExtensionDeclaration2);
  }

  ExtensionOverride2 extensionOverride2(String search) {
    return _node(search, (n) => n is ExtensionOverride2);
  }

  Field2 field(String search) {
    return _node(search, (n) => n is Field2);
  }

  FieldsDeclaration fieldsDeclaration(String search) {
    return _node(search, (n) => n is FieldsDeclaration);
  }

  FunctionTypeAlias2 functionTypeAlias(String search) {
    return _node(search, (n) => n is FunctionTypeAlias2);
  }

  GenericTypeAlias2 genericTypeAlias(String search) {
    return _node(search, (n) => n is GenericTypeAlias2);
  }

  GetterDeclaration getterDeclaration(String search) {
    return _node(search, (n) => n is GetterDeclaration);
  }

  IfNull ifNull(String search) {
    return _node(search, (node) => node is IfNull);
  }

  IfNullAssignment ifNullAssignment(String search) {
    return _node(search, (node) => node is IfNullAssignment);
  }

  ImportPrefixedAssignmentTarget importPrefixedAssignmentTarget(String search) {
    return _node(search, (node) => node is ImportPrefixedAssignmentTarget);
  }

  ImportPrefixedFunctionInvocation importPrefixedFunctionInvocation(
    String search,
  ) {
    return _node(search, (node) => node is ImportPrefixedFunctionInvocation);
  }

  ImportPrefixedNameExpression importPrefixedNameExpression(String search) {
    return _node(search, (node) => node is ImportPrefixedNameExpression);
  }

  IncrementOrDecrementExpression incrementOrDecrement(String search) {
    return _node(search, (node) => node is IncrementOrDecrementExpression);
  }

  InvalidSuperExpression invalidSuperExpression(String search) {
    return _node(search, (node) => node is InvalidSuperExpression);
  }

  LocalFunctionDeclaration localFunctionDeclaration(String search) {
    return _node(search, (node) => node is LocalFunctionDeclaration);
  }

  LocalVariable localVariable(String search) {
    return _node(search, (n) => n is LocalVariable);
  }

  LocalVariablesDeclaration localVariablesDeclaration(String search) {
    return _node(search, (n) => n is LocalVariablesDeclaration);
  }

  LocalVariablesDeclarationStatement localVariablesDeclarationStatement(
    String search,
  ) {
    return _node(search, (n) => n is LocalVariablesDeclarationStatement);
  }

  LogicalAnd logicalAnd(String search) {
    return _node(search, (node) => node is LogicalAnd);
  }

  LogicalNot logicalNot(String search) {
    return _node(search, (node) => node is LogicalNot);
  }

  LogicalOr logicalOr(String search) {
    return _node(search, (node) => node is LogicalOr);
  }

  MethodDeclaration2 methodDeclaration(String search) {
    return _node(search, (n) => n is MethodDeclaration2);
  }

  MixinDeclaration2 mixin(String search) {
    return _node(search, (n) => n is MixinDeclaration2);
  }

  MixinDeclaration2 mixinDeclaration(String search) {
    return _node(search, (n) => n is MixinDeclaration2);
  }

  NullAssertionExpression nullAssertion(String search) {
    return _node(search, (node) => node is NullAssertionExpression);
  }

  OperatorDeclaration operatorDeclaration(String search) {
    return _node(search, (n) => n is OperatorDeclaration);
  }

  ReceiverMethodInvocation receiverMethodInvocation(String search) {
    return _node(search, (node) => node is ReceiverMethodInvocation);
  }

  SetterDeclaration setterDeclaration(String search) {
    return _node(search, (n) => n is SetterDeclaration);
  }

  SuperReference superReference(String search) {
    return _node(search, (node) => node is SuperReference);
  }

  TopLevelFunctionDeclaration topLevelFunctionDeclaration(String search) {
    return _node(search, (node) => node is TopLevelFunctionDeclaration);
  }

  TopLevelGetterDeclaration topLevelGetterDeclaration(String search) {
    return _node(search, (node) => node is TopLevelGetterDeclaration);
  }

  TopLevelSetterDeclaration topLevelSetterDeclaration(String search) {
    return _node(search, (node) => node is TopLevelSetterDeclaration);
  }

  TopLevelVariable2 topLevelVariable(String search) {
    return _node(search, (node) => node is TopLevelVariable2);
  }

  TopLevelVariable2 topLevelVariableByName(String name) {
    for (var declaration in unit.declarations2) {
      if (declaration is TopLevelVariablesDeclaration) {
        for (var variable in declaration.variables) {
          if (variable.name.lexeme == name) {
            return variable;
          }
        }
      }
    }
    throw StateError(name);
  }

  TopLevelVariablesDeclaration topLevelVariablesDeclaration(String search) {
    return _node(search, (node) => node is TopLevelVariablesDeclaration);
  }

  UnaryOperatorInvocation unaryOperatorInvocation(String search) {
    return _node(search, (node) => node is UnaryOperatorInvocation);
  }

  UnqualifiedFunctionInvocation unqualifiedFunctionInvocation(String search) {
    return _node(search, (node) => node is UnqualifiedFunctionInvocation);
  }

  UnqualifiedNameAssignmentTarget unqualifiedNameAssignmentTarget(
    String search,
  ) {
    return _node(search, (node) => node is UnqualifiedNameAssignmentTarget);
  }

  UnqualifiedNameExpression unqualifiedNameExpression(String search) {
    return _node(search, (node) => node is UnqualifiedNameExpression);
  }

  /// Rejects V1 projections so tests cannot silently keep asserting the legacy
  /// AST after a V2 migration. Nodes shared between both views are allowed.
  /// Use [FindNode] explicitly when testing V1 compatibility.
  @override
  void _checkNode(AstNode node) {
    if ((node as AstNodeImpl).astNodeApi == AstNodeApi.v1) {
      throw StateError(
        'FindNode2 cannot return the V1 projection ${node.runtimeType}. '
        'Use a V2 node finder, or findNodeV1 for a compatibility assertion.',
      );
    }
  }

  @override
  AstNode? _locateNode(int offset) {
    return NodeLocator2(offset).searchWithin(unit);
  }

  @override
  List<T> _nodes<T extends AstNode>() {
    var visitor = _TypedNodeVisitor2<T>();
    unit.accept2(visitor);
    visitor.nodes.forEach(_checkNode);
    return visitor.nodes;
  }

  @override
  AstNode? _thisOrAncestorMatching(
    AstNode node,
    bool Function(AstNode) predicate,
  ) {
    return node.thisOrAncestorMatching2(predicate);
  }
}

abstract class _FindNodeBase {
  final String content;
  final CompilationUnit unit;

  new(this.content, this.unit);

  Block get firstBlock => _first();

  FormalParameter get firstFormalParameter => _first();

  FormalParameterList get firstFormalParameterList => _first();

  AdjacentStrings get singleAdjacentStrings => _single();

  Annotation get singleAnnotation => _single();

  ArgumentList get singleArgumentList => _single();

  AsExpression get singleAsExpression => _single();

  AssertInitializer get singleAssertInitializer => _single();

  AssertStatement get singleAssertStatement => _single();

  AssignedVariablePattern get singleAssignedVariablePattern => _single();

  AwaitExpression get singleAwaitExpression => _single();

  Block get singleBlock => _single();

  BlockClassBody get singleBlockClassBody => _single();

  BlockFunctionBody get singleBlockFunctionBody => _single();

  BooleanLiteral get singleBooleanLiteral => _single();

  BreakStatement get singleBreakStatement => _single();

  CascadeExpression get singleCascadeExpression => _single();

  CascadeIndexAssignmentTarget get singleCascadeIndexAssignmentTarget =>
      _single();

  CascadeIndexExpression get singleCascadeIndexExpression => _single();

  CascadePropertyAssignmentTarget get singleCascadePropertyAssignmentTarget =>
      _single();

  CascadePropertyExtraction get singleCascadePropertyExtraction => _single();

  CascadeSection get singleCascadeSection => _single();

  CastPattern get singleCastPattern => _single();

  CatchClause get singleCatchClause => _single();

  ClassDeclaration get singleClassDeclaration => _single();

  Comment get singleComment => _single();

  CommentReference get singleCommentReference => _single();

  ConditionalExpression get singleConditionalExpression => _single();

  Configuration get singleConfiguration => _single();

  ConstantPattern get singleConstantPattern => _single();

  ConstructorFieldInitializer get singleConstructorFieldInitializer =>
      _single();

  ContinueStatement get singleContinueStatement => _single();

  DeclaredVariablePattern get singleDeclaredVariablePattern => _single();

  DoStatement get singleDoStatement => _single();

  DotShorthandConstructorInvocation2
  get singleDotShorthandConstructorInvocation => _single();

  DottedName get singleDottedName => _single();

  DoubleLiteral get singleDoubleLiteral => _single();

  EmptyFunctionBody get singleEmptyFunctionBody => _single();

  EmptyStatement get singleEmptyStatement => _single();

  ExportDirective get singleExportDirective => _single();

  ExpressionFunctionBody get singleExpressionFunctionBody => _single();

  ExpressionStatement get singleExpressionStatement => _single();

  ExtendsClause get singleExtendsClause => _single();

  ExtensionTypeDeclaration get singleExtensionTypeDeclaration => _single();

  FieldFormalParameter get singleFieldFormalParameter => _single();

  ForEachPartsWithIdentifier get singleForEachPartsWithIdentifier => _single();

  ForEachPartsWithPattern get singleForEachPartsWithPattern => _single();

  ForElement get singleForElement => _single();

  FormalParameter get singleFormalParameter => _single();

  FormalParameterList get singleFormalParameterList => _single();

  ForPartsWithDeclarations get singleForPartsWithDeclarations => _single();

  ForPartsWithExpression get singleForPartsWithExpression => _single();

  ForPartsWithPattern get singleForPartsWithPattern => _single();

  ForStatement get singleForStatement => _single();

  FunctionBody get singleFunctionBody => _single();

  FunctionDeclaration get singleFunctionDeclaration => _single();

  FunctionDeclarationStatement get singleFunctionDeclarationStatement =>
      _single();

  FunctionExpression get singleFunctionExpression => _single();

  FunctionInstantiation get singleFunctionInstantiation => _single();

  GenericFunctionType get singleGenericFunctionType => _single();

  GuardedPattern get singleGuardedPattern => _single();

  HideCombinator get singleHideCombinator => _single();

  IfElement get singleIfElement => _single();

  IfStatement get singleIfStatement => _single();

  ImplementsClause get singleImplementsClause => _single();

  ImplicitCallTearOff get singleImplicitCallTearOff => _single();

  ImplicitFunctionInstantiation get singleImplicitFunctionInstantiation =>
      _single();

  ImportDirective get singleImportDirective => _single();

  IncrementOrDecrementExpression get singleIncrementOrDecrement => _single();

  IntegerLiteral get singleIntegerLiteral => _single();

  InterpolationExpression get singleInterpolationExpression => _single();

  IsExpression get singleIsExpression => _single();

  Label get singleLabel => _single();

  LabeledStatement get singleLabeledStatement => _single();

  LibraryDirective get singleLibraryDirective => _single();

  ListLiteral get singleListLiteral => _single();

  ListPattern get singleListPattern => _single();

  MapLiteralEntry get singleMapLiteralEntry => _single();

  MapPattern get singleMapPattern => _single();

  MapPatternEntry get singleMapPatternEntry => _single();

  MixinOnClause get singleMixinOnClause => _single();

  NamedArgument get singleNamedArgument => _single();

  NamedType get singleNamedType => _single();

  NativeClause get singleNativeClause => _single();

  NativeFunctionBody get singleNativeFunctionBody => _single();

  NullAssertPattern get singleNullAssertPattern => _single();

  NullAwareElement get singleNullAwareElement => _single();

  NullCheckPattern get singleNullCheckPattern => _single();

  NullLiteral get singleNullLiteral => _single();

  ObjectPattern get singleObjectPattern => _single();

  ParenthesizedExpression get singleParenthesizedExpression => _single();

  ParenthesizedPattern get singleParenthesizedPattern => _single();

  PartDirective get singlePartDirective => _single();

  PartOfDirective get singlePartOfDirective => _single();

  PatternAssignment get singlePatternAssignment => _single();

  PatternField get singlePatternField => _single();

  PatternFieldName get singlePatternFieldName => _single();

  PatternVariableDeclaration get singlePatternVariableDeclaration => _single();

  PatternVariableDeclarationStatement
  get singlePatternVariableDeclarationStatement => _single();

  PrimaryConstructorDeclaration get singlePrimaryConstructorDeclaration =>
      _single();

  ReceiverIndexExpression get singleReceiverIndexExpression => _single();

  ReceiverPropertyExtraction get singleReceiverPropertyExtraction => _single();

  RecordLiteral get singleRecordLiteral => _single();

  RecordPattern get singleRecordPattern => _single();

  RecordTypeAnnotation get singleRecordTypeAnnotation => _single();

  RedirectingConstructorInvocation get singleRedirectingConstructorInvocation =>
      _single();

  RegularFormalParameter get singleRegularFormalParameter => _single();

  RelationalPattern get singleRelationalPattern => _single();

  RestPatternElement get singleRestPatternElement => _single();

  RethrowExpression get singleRethrowExpression => _single();

  ReturnStatement get singleReturnStatement => _single();

  SetOrMapLiteral get singleSetOrMapLiteral => _single();

  ShowCombinator get singleShowCombinator => _single();

  SimpleStringLiteral get singleSimpleStringLiteral => _single();

  SpreadElement get singleSpreadElement => _single();

  StringInterpolation get singleStringInterpolation => _single();

  SuperConstructorInvocation get singleSuperConstructorInvocation => _single();

  SuperFormalParameter get singleSuperFormalParameter => _single();

  SwitchCase get singleSwitchCase => _single();

  SwitchDefault get singleSwitchDefault => _single();

  SwitchExpression get singleSwitchExpression => _single();

  SwitchPatternCase get singleSwitchPatternCase => _single();

  SwitchStatement get singleSwitchStatement => _single();

  SymbolLiteral get singleSymbolLiteral => _single();

  ThisExpression get singleThisExpression => _single();

  ThrowExpression get singleThrowExpression => _single();

  TryStatement get singleTryStatement => _single();

  TypeArgumentList get singleTypeArgumentList => _single();

  TypeParameter get singleTypeParameter => _single();

  TypeParameterList get singleTypeParameterList => _single();

  WhenClause get singleWhenClause => _single();

  WhileStatement get singleWhileStatement => _single();

  WildcardPattern get singleWildcardPattern => _single();

  WithClause get singleWithClause => _single();

  YieldStatement get singleYieldStatement => _single();

  AdjacentStrings adjacentStrings(String search) {
    return _node(search, (n) => n is AdjacentStrings);
  }

  Annotation annotation(String search) {
    return _node(search, (n) => n is Annotation);
  }

  AstNode any(String search) {
    return _node(search, (n) => true);
  }

  ArgumentList argumentList(String search) {
    return _node(search, (n) => n is ArgumentList);
  }

  AsExpression as_(String search) {
    return _node(search, (n) => n is AsExpression);
  }

  AsExpression asExpression(String search) {
    return _node(search, (n) => n is AsExpression);
  }

  AssertStatement assertStatement(String search) {
    return _node(search, (n) => n is AssertStatement);
  }

  AssignedVariablePattern assignedVariablePattern(String search) {
    return _node(search, (n) => n is AssignedVariablePattern);
  }

  AwaitExpression awaitExpression(String search) {
    return _node(search, (n) => n is AwaitExpression);
  }

  Block block(String search) {
    return _node(search, (n) => n is Block);
  }

  BlockFunctionBody blockFunctionBody(String search) {
    return _node(search, (n) => n is BlockFunctionBody);
  }

  BooleanLiteral booleanLiteral(String search) {
    return _node(search, (n) => n is BooleanLiteral);
  }

  BreakStatement breakStatement(String search) {
    return _node(search, (n) => n is BreakStatement);
  }

  CascadeExpression cascade(String search) {
    return _node(search, (n) => n is CascadeExpression);
  }

  CascadeIndexAssignmentTarget cascadeIndexAssignmentTarget(String search) {
    return _node(search, (n) => n is CascadeIndexAssignmentTarget);
  }

  CascadeIndexExpression cascadeIndexExpression(String search) {
    return _node(search, (n) => n is CascadeIndexExpression);
  }

  CascadeMethodInvocation cascadeMethodInvocation(String search) {
    return _node(search, (n) => n is CascadeMethodInvocation);
  }

  CascadePropertyAssignmentTarget cascadePropertyAssignmentTarget(
    String search,
  ) {
    return _node(search, (n) => n is CascadePropertyAssignmentTarget);
  }

  CascadePropertyExtraction cascadePropertyExtraction(String search) {
    return _node(search, (n) => n is CascadePropertyExtraction);
  }

  CascadeSection cascadeSection(String search) {
    return _node(search, (n) => n is CascadeSection);
  }

  CaseClause caseClause(String search) {
    return _node(search, (n) => n is CaseClause);
  }

  CastPattern castPattern(String search) {
    return _node(search, (n) => n is CastPattern);
  }

  CatchClause catchClause(String search) {
    return _node(search, (n) => n is CatchClause);
  }

  CatchClauseParameter catchClauseParameter(String search) {
    return _node(search, (n) => n is CatchClauseParameter);
  }

  ClassDeclaration classDeclaration(String search) {
    return _node(search, (n) => n is ClassDeclaration);
  }

  CollectionElement collectionElement(String search) {
    return _node(search, (n) => n is CollectionElement);
  }

  Comment comment(String search) {
    return _node(search, (n) => n is Comment);
  }

  CommentReference commentReference(String search) {
    return _node(search, (n) => n is CommentReference);
  }

  ConditionalExpression conditionalExpression(String search) {
    return _node(search, (n) => n is ConditionalExpression);
  }

  Configuration configuration(String search) {
    return _node(search, (n) => n is Configuration);
  }

  ConstantPattern constantPattern(String search) {
    return _node(search, (n) => n is ConstantPattern);
  }

  ConstructorFieldInitializer constructorFieldInitializer(String search) {
    return _node(search, (n) => n is ConstructorFieldInitializer);
  }

  ConstructorSelector constructorSelector(String search) {
    return _node(search, (n) => n is ConstructorSelector);
  }

  ContinueStatement continueStatement(String search) {
    return _node(search, (n) => n is ContinueStatement);
  }

  DeclaredIdentifier declaredIdentifier(String search) {
    return _node(search, (n) => n is DeclaredIdentifier);
  }

  DeclaredVariablePattern declaredVariablePattern(String search) {
    return _node(search, (n) => n is DeclaredVariablePattern);
  }

  DoStatement doStatement(String search) {
    return _node(search, (n) => n is DoStatement);
  }

  DotShorthandConstructorInvocation2 dotShorthandConstructorInvocation(
    String search,
  ) {
    return _node(search, (n) => n is DotShorthandConstructorInvocation2);
  }

  DottedName dottedName(String search) {
    return _node(search, (n) => n is DottedName);
  }

  DoubleLiteral doubleLiteral(String search) {
    return _node(search, (n) => n is DoubleLiteral);
  }

  EmptyFunctionBody emptyFunctionBody(String search) {
    return _node(search, (n) => n is EmptyFunctionBody);
  }

  EmptyStatement emptyStatement(String search) {
    return _node(search, (n) => n is EmptyStatement);
  }

  ExportDirective export(String search) {
    return _node(search, (n) => n is ExportDirective);
  }

  Expression expression(String search) {
    return _node(search, (n) => n is Expression);
  }

  ExpressionFunctionBody expressionFunctionBody(String search) {
    return _node(search, (n) => n is ExpressionFunctionBody);
  }

  ExpressionStatement expressionStatement(String search) {
    return _node(search, (n) => n is ExpressionStatement);
  }

  ExtendsClause extendsClause(String search) {
    return _node(search, (n) => n is ExtendsClause);
  }

  ExtensionTypeDeclaration extensionTypeDeclaration(String search) {
    return _node(search, (n) => n is ExtensionTypeDeclaration);
  }

  FieldFormalParameter fieldFormalParameter(String search) {
    return _node(search, (n) => n is FieldFormalParameter);
  }

  ForEachPartsWithDeclaration forEachPartsWithDeclaration(String search) {
    return _node(search, (n) => n is ForEachPartsWithDeclaration);
  }

  ForEachPartsWithIdentifier forEachPartsWithIdentifier(String search) {
    return _node(search, (n) => n is ForEachPartsWithIdentifier);
  }

  ForEachPartsWithPattern forEachPartsWithPattern(String search) {
    return _node(search, (n) => n is ForEachPartsWithPattern);
  }

  ForElement forElement(String search) {
    return _node(search, (n) => n is ForElement);
  }

  FormalParameter formalParameter(String search) {
    return _node(search, (n) => n is FormalParameter);
  }

  FormalParameterList formalParameterList(String search) {
    // If the search starts with `(` then the locator will find the definition
    // before it, so offset the search to within the parameter list.
    var locateOffset = search.startsWith('(') ? 1 : 0;
    return _node(
      search,
      (n) => n is FormalParameterList,
      locateOffset: locateOffset,
    );
  }

  ForPartsWithDeclarations forPartsWithDeclarations(String search) {
    return _node(search, (n) => n is ForPartsWithDeclarations);
  }

  ForPartsWithExpression forPartsWithExpression(String search) {
    return _node(search, (n) => n is ForPartsWithExpression);
  }

  ForPartsWithPattern forPartsWithPattern(String search) {
    return _node(search, (n) => n is ForPartsWithPattern);
  }

  ForStatement forStatement(String search) {
    return _node(search, (n) => n is ForStatement);
  }

  FunctionBody functionBody(String search) {
    return _node(search, (n) => n is FunctionBody);
  }

  FunctionDeclaration functionDeclaration(String search) {
    return _node(search, (n) => n is FunctionDeclaration);
  }

  FunctionDeclarationStatement functionDeclarationStatement(String search) {
    return _node(search, (n) => n is FunctionDeclarationStatement);
  }

  FunctionExpression functionExpression(String search) {
    return _node(search, (n) => n is FunctionExpression);
  }

  FunctionInstantiation functionInstantiation(String search) {
    return _node(search, (n) => n is FunctionInstantiation);
  }

  FunctionTypedFormalParameterSuffix functionTypedFormalParameterSuffix(
    String search,
  ) {
    return _node(search, (n) => n is FunctionTypedFormalParameterSuffix);
  }

  GenericFunctionType genericFunctionType(String search) {
    return _node(search, (n) => n is GenericFunctionType);
  }

  HideCombinator hideCombinator(String search) {
    return _node(search, (n) => n is HideCombinator);
  }

  IfElement ifElement(String search) {
    return _node(search, (n) => n is IfElement);
  }

  IfStatement ifStatement(String search) {
    return _node(search, (n) => n is IfStatement);
  }

  ImplementsClause implementsClause(String search) {
    return _node(search, (n) => n is ImplementsClause);
  }

  ImplicitCallTearOff implicitCallTearOff(String search) {
    return _node(search, (n) => n is ImplicitCallTearOff);
  }

  ImplicitFunctionInstantiation implicitFunctionInstantiation(String search) {
    return _node(search, (n) => n is ImplicitFunctionInstantiation);
  }

  ImportDirective import(String search) {
    return _node(search, (n) => n is ImportDirective);
  }

  ImportPrefixReference importPrefixReference(String search) {
    return _node(search, (n) => n is ImportPrefixReference);
  }

  IntegerLiteral integerLiteral(String search) {
    return _node(search, (n) => n is IntegerLiteral);
  }

  InterpolationExpression interpolationExpression(String search) {
    return _node(search, (n) => n is InterpolationExpression);
  }

  InterpolationString interpolationString(String search) {
    return _node(search, (n) => n is InterpolationString);
  }

  IsExpression isExpression(String search) {
    return _node(search, (n) => n is IsExpression);
  }

  Label label(String search) {
    return _node(search, (n) => n is Label);
  }

  LabeledStatement labeledStatement(String search) {
    return _node(search, (n) => n is LabeledStatement);
  }

  LibraryDirective library(String search) {
    return _node(search, (n) => n is LibraryDirective);
  }

  ListLiteral listLiteral(String search) {
    return _node(search, (n) => n is ListLiteral);
  }

  ListPattern listPattern(String search) {
    return _node(search, (n) => n is ListPattern);
  }

  LogicalAndPattern logicalAndPattern(String search) {
    return _node(search, (n) => n is LogicalAndPattern);
  }

  LogicalOrPattern logicalOrPattern(String search) {
    return _node(search, (n) => n is LogicalOrPattern);
  }

  MapLiteralEntry mapLiteralEntry(String search) {
    return _node(search, (n) => n is MapLiteralEntry);
  }

  MapPattern mapPattern(String search) {
    return _node(search, (n) => n is MapPattern);
  }

  MapPatternEntry mapPatternEntry(String search) {
    return _node(search, (n) => n is MapPatternEntry);
  }

  NamedArgument namedArgument(String search) {
    return _node(search, (n) => n is NamedArgument);
  }

  NamedType namedType(String search) {
    return _node(search, (n) => n is NamedType);
  }

  NameWithTypeParameters nameWithTypeParameters(String search) {
    return _node(search, (n) => n is NameWithTypeParameters);
  }

  NativeClause nativeClause(String search) {
    return _node(search, (n) => n is NativeClause);
  }

  NativeFunctionBody nativeFunctionBody(String search) {
    return _node(search, (n) => n is NativeFunctionBody);
  }

  NullAssertPattern nullAssertPattern(String search) {
    return _node(search, (n) => n is NullAssertPattern);
  }

  NullCheckPattern nullCheckPattern(String search) {
    return _node(search, (n) => n is NullCheckPattern);
  }

  NullLiteral nullLiteral(String search) {
    return _node(search, (n) => n is NullLiteral);
  }

  ObjectPattern objectPattern(String search) {
    return _node(search, (n) => n is ObjectPattern);
  }

  /// Return the unique offset where the [search] string occurs in [content].
  /// Throws if not found, or if not unique.
  int offset(String search) {
    var offset = content.indexOf(search);
    if (content.contains(search, offset + 1)) {
      throw StateError('The pattern |$search| is not unique in:\n$content');
    }
    if (offset < 0) {
      throw StateError('The pattern |$search| is not found in:\n$content');
    }
    return offset;
  }

  ParenthesizedExpression parenthesized(String search) {
    return _node(search, (n) => n is ParenthesizedExpression);
  }

  ParenthesizedPattern parenthesizedPattern(String search) {
    return _node(search, (n) => n is ParenthesizedPattern);
  }

  ParsedExpression parsedExpression(String search) {
    return _node(
      search,
      (n) => n is ParsedExpression && n.parent2 is! ParsedExpression,
    );
  }

  PartDirective part(String search) {
    return _node(search, (n) => n is PartDirective);
  }

  PartOfDirective partOf(String search) {
    return _node(search, (n) => n is PartOfDirective);
  }

  PatternAssignment patternAssignment(String search) {
    return _node(search, (n) => n is PatternAssignment);
  }

  PatternField patternField(String search) {
    return _node(search, (n) => n is PatternField);
  }

  PatternFieldName patternFieldName(String search) {
    return _node(search, (n) => n is PatternFieldName);
  }

  PatternVariableDeclaration patternVariableDeclaration(String search) {
    return _node(search, (n) => n is PatternVariableDeclaration);
  }

  PatternVariableDeclarationStatement patternVariableDeclarationStatement(
    String search,
  ) {
    return _node(search, (n) => n is PatternVariableDeclarationStatement);
  }

  PrimaryConstructorDeclaration primaryConstructorDeclaration(String search) {
    return _node(search, (n) => n is PrimaryConstructorDeclaration);
  }

  ReceiverIndexExpression receiverIndexExpression(String search) {
    return _node(search, (n) => n is ReceiverIndexExpression);
  }

  ReceiverPropertyExtraction receiverPropertyExtraction(String search) {
    return _node(search, (n) => n is ReceiverPropertyExtraction);
  }

  RecordLiteral recordLiteral(String search) {
    return _node(search, (n) => n is RecordLiteral);
  }

  RecordPattern recordPattern(String search) {
    return _node(search, (n) => n is RecordPattern);
  }

  RecordTypeAnnotation recordTypeAnnotation(String search) {
    return _node(search, (n) => n is RecordTypeAnnotation);
  }

  RedirectingConstructorInvocation redirectingConstructorInvocation(
    String search,
  ) {
    return _node(search, (n) => n is RedirectingConstructorInvocation);
  }

  RegularFormalParameter regularFormalParameter(String search) {
    return _node(search, (n) => n is RegularFormalParameter);
  }

  RelationalPattern relationalPattern(String search) {
    return _node(search, (n) => n is RelationalPattern);
  }

  RestPatternElement restPatternElement(String search) {
    return _node(search, (n) => n is RestPatternElement);
  }

  RethrowExpression rethrow_(String search) {
    return _node(search, (n) => n is RethrowExpression);
  }

  ReturnStatement returnStatement(String search) {
    return _node(search, (n) => n is ReturnStatement);
  }

  SetOrMapLiteral setOrMapLiteral(String search) {
    return _node(search, (n) => n is SetOrMapLiteral);
  }

  ShowCombinator showCombinator(String search) {
    return _node(search, (n) => n is ShowCombinator);
  }

  SimpleStringLiteral simpleStringLiteral(String search) {
    return _node(search, (n) => n is SimpleStringLiteral);
  }

  SpreadElement spreadElement(String search) {
    return _node(search, (n) => n is SpreadElement);
  }

  Statement statement(String search) {
    return _node(search, (n) => n is Statement);
  }

  StringInterpolation stringInterpolation(String search) {
    return _node(search, (n) => n is StringInterpolation);
  }

  StringLiteral stringLiteral(String search) {
    return _node(search, (n) => n is StringLiteral);
  }

  SuperConstructorInvocation superConstructorInvocation(String search) {
    return _node(search, (n) => n is SuperConstructorInvocation);
  }

  SuperFormalParameter superFormalParameter(String search) {
    return _node(search, (n) => n is SuperFormalParameter);
  }

  SwitchCase switchCase(String search) {
    return _node(search, (n) => n is SwitchCase);
  }

  SwitchDefault switchDefault(String search) {
    return _node(search, (n) => n is SwitchDefault);
  }

  SwitchExpression switchExpression(String search) {
    return _node(search, (n) => n is SwitchExpression);
  }

  SwitchExpressionCase switchExpressionCase(String search) {
    return _node(search, (n) => n is SwitchExpressionCase);
  }

  SwitchPatternCase switchPatternCase(String search) {
    return _node(search, (n) => n is SwitchPatternCase);
  }

  SwitchStatement switchStatement(String search) {
    return _node(search, (n) => n is SwitchStatement);
  }

  SymbolLiteral symbolLiteral(String search) {
    return _node(search, (n) => n is SymbolLiteral);
  }

  ThisExpression this_(String search) {
    return _node(search, (n) => n is ThisExpression);
  }

  ThrowExpression throw_(String search) {
    return _node(search, (n) => n is ThrowExpression);
  }

  TryStatement tryStatement(String search) {
    return _node(search, (n) => n is TryStatement);
  }

  TypeAnnotation typeAnnotation(String search) {
    return _node(search, (n) => n is TypeAnnotation);
  }

  TypeArgumentList typeArgumentList(String search) {
    return _node(search, (n) => n is TypeArgumentList);
  }

  TypedLiteral typedLiteral(String search) {
    return _node(search, (n) => n is TypedLiteral);
  }

  TypeLiteral typeLiteral(String search) {
    return _node(search, (n) => n is TypeLiteral);
  }

  TypeParameter typeParameter(String search) {
    return _node(search, (n) => n is TypeParameter);
  }

  TypeParameterList typeParameterList(String search) {
    return _node(search, (n) => n is TypeParameterList);
  }

  WhenClause whenClause(String search) {
    return _node(search, (n) => n is WhenClause);
  }

  WhileStatement whileStatement(String search) {
    return _node(search, (n) => n is WhileStatement);
  }

  WildcardPattern wildcardPattern(String search) {
    return _node(search, (n) => n is WildcardPattern);
  }

  WithClause withClause(String search) {
    return _node(search, (n) => n is WithClause);
  }

  YieldStatement yieldStatement(String search) {
    return _node(search, (n) => n is YieldStatement);
  }

  /// Validates that a search result belongs to this finder's AST view.
  ///
  /// The default accepts all nodes; [FindNode2] overrides this to reject V1
  /// projections. Called for both individual search results and collected nodes.
  void _checkNode(AstNode node) {}

  /// If [unit] has at least one node of type [T], returns the first one.
  /// Otherwise, throws.
  T _first<T extends AstNode>() {
    return _nodes<T>().first;
  }

  AstNode? _locateNode(int offset);

  /// Locates a node at the offset of [search] and returns the first ancestor
  /// matching [predicate].
  ///
  /// If [locateOffset] is provided, its value is added to the offset of
  /// [search] before locating the node.
  T _node<T>(
    String search,
    bool Function(AstNode) predicate, {
    int? locateOffset,
  }) {
    int offset = this.offset(search) + (locateOffset ?? 0);

    var node = _locateNode(offset);
    if (node == null) {
      throw StateError(
        'The pattern |$search| had no corresponding node in:\n$content',
      );
    }

    var ancestors = <Type>[];
    var result = _thisOrAncestorMatching(node, (node) {
      ancestors.add(node.runtimeType);
      return predicate(node);
    });
    if (result == null) {
      throw StateError(
        'The node for |$search| had no matching $T ancestor in $runtimeType.\n'
        'Found: ${ancestors.join(', ')}\n$content',
      );
    }
    _checkNode(result);
    return result as T;
  }

  List<T> _nodes<T extends AstNode>();

  /// If [unit] has exactly one node of type [T], returns it.
  /// Otherwise, throws.
  T _single<T extends AstNode>() {
    return _nodes<T>().single;
  }

  AstNode? _thisOrAncestorMatching(
    AstNode node,
    bool Function(AstNode) predicate,
  );
}

@V1Ast('The V2 counterpart is _TypedNodeVisitor2.')
class _TypedNodeVisitor<T extends AstNode>
    extends GeneralizingAstVisitor<void> {
  final List<T> nodes = [];

  @override
  void visitNode(AstNode node) {
    if (node is T) {
      nodes.add(node);
    }
    super.visitNode(node);
  }
}

class _TypedNodeVisitor2<T extends AstNode> extends UnifyingAstVisitor2<void> {
  final List<T> nodes = [];

  @override
  void visitNode(AstNode node) {
    if (node is T) {
      nodes.add(node);
    }
    super.visitNode(node);
  }
}
