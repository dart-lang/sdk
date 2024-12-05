// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';

class FindNode {
  final String content;
  final CompilationUnit unit;

  FindNode(this.content, this.unit);

  List<MethodInvocation> get methodInvocations {
    var result = <MethodInvocation>[];
    unit.accept(
      FunctionAstVisitor(
        methodInvocation: result.add,
      ),
    );
    return result;
  }

  AdjacentStrings get singleAdjacentStrings => _single();

  Annotation get singleAnnotation => _single();

  AsExpression get singleAsExpression => _single();

  AssertInitializer get singleAssertInitializer => _single();

  AssertStatement get singleAssertStatement => _single();

  AssignmentExpression get singleAssignmentExpression => _single();

  AugmentedExpression get singleAugmentedExpression => _single();

  AugmentedInvocation get singleAugmentedInvocation => _single();

  AwaitExpression get singleAwaitExpression => _single();

  BinaryExpression get singleBinaryExpression => _single();

  Block get singleBlock => _single();

  CascadeExpression get singleCascadeExpression => _single();

  ClassDeclaration get singleClassDeclaration => _single();

  ConditionalExpression get singleConditionalExpression => _single();

  Configuration get singleConfiguration => _single();

  ConstructorDeclaration get singleConstructorDeclaration => _single();

  ConstructorFieldInitializer get singleConstructorFieldInitializer =>
      _single();

  EnumDeclaration get singleEnumDeclaration => _single();

  ExportDirective get singleExportDirective => _single();

  ExpressionStatement get singleExpressionStatement => _single();

  ExtendsClause get singleExtendsClause => _single();

  ExtensionDeclaration get singleExtensionDeclaration => _single();

  ExtensionTypeDeclaration get singleExtensionTypeDeclaration => _single();

  FieldDeclaration get singleFieldDeclaration => _single();

  FieldFormalParameter get singleFieldFormalParameter => _single();

  ForElement get singleForElement => _single();

  FormalParameterList get singleFormalParameterList => _single();

  ForStatement get singleForStatement => _single();

  FunctionBody get singleFunctionBody => _single();

  FunctionDeclaration get singleFunctionDeclaration => _single();

  FunctionDeclarationStatement get singleFunctionDeclarationStatement =>
      _single();

  FunctionExpressionInvocation get singleFunctionExpressionInvocation =>
      _single();

  FunctionReference get singleFunctionReference => _single();

  FunctionTypeAlias get singleFunctionTypeAlias => _single();

  FunctionTypedFormalParameter get singleFunctionTypedFormalParameter =>
      _single();

  GenericTypeAlias get singleGenericTypeAlias => _single();

  GuardedPattern get singleGuardedPattern => _single();

  IfElement get singleIfElement => _single();

  IfStatement get singleIfStatement => _single();

  ImplementsClause get singleImplementsClause => _single();

  ImplicitCallReference get singleImplicitCallReference => _single();

  ImportDirective get singleImportDirective => _single();

  IndexExpression get singleIndexExpression => _single();

  InstanceCreationExpression get singleInstanceCreationExpression => _single();

  IsExpression get singleIsExpression => _single();

  LabeledStatement get singleLabeledStatement => _single();

  LibraryDirective get singleLibraryDirective => _single();

  ListLiteral get singleListLiteral => _single();

  MethodDeclaration get singleMethodDeclaration => _single();

  MethodInvocation get singleMethodInvocation => _single();

  MixinDeclaration get singleMixinDeclaration => _single();

  MixinOnClause get singleMixinOnClause => _single();

  NamedType get singleNamedType => _single();

  NullAwareElement get singleNullAwareElement => _single();

  ParenthesizedExpression get singleParenthesizedExpression => _single();

  PartDirective get singlePartDirective => _single();

  PartOfDirective get singlePartOfDirective => _single();

  PatternAssignment get singlePatternAssignment => _single();

  PatternVariableDeclaration get singlePatternVariableDeclaration => _single();

  PatternVariableDeclarationStatement
      get singlePatternVariableDeclarationStatement => _single();

  PostfixExpression get singlePostfixExpression => _single();

  PrefixedIdentifier get singlePrefixedIdentifier => _single();

  PrefixExpression get singlePrefixExpression => _single();

  PropertyAccess get singlePropertyAccess => _single();

  RecordLiteral get singleRecordLiteral => _single();

  RedirectingConstructorInvocation get singleRedirectingConstructorInvocation =>
      _single();

  RepresentationConstructorName get singleRepresentationConstructorName =>
      _single();

  RepresentationDeclaration get singleRepresentationDeclaration => _single();

  RethrowExpression get singleRethrowExpression => _single();

  ReturnStatement get singleReturnStatement => _single();

  SetOrMapLiteral get singleSetOrMapLiteral => _single();

  SuperConstructorInvocation get singleSuperConstructorInvocation => _single();

  SuperFormalParameter get singleSuperFormalParameter => _single();

  SwitchCase get singleSwitchCase => _single();

  SwitchExpression get singleSwitchExpression => _single();

  SwitchPatternCase get singleSwitchPatternCase => _single();

  ThisExpression get singleThisExpression => _single();

  TopLevelVariableDeclaration get singleTopLevelVariableDeclaration =>
      _single();

  TryStatement get singleTryStatement => _single();

  VariableDeclaration get singleVariableDeclaration => _single();

  VariableDeclarationStatement get singleVariableDeclarationStatement =>
      _single();

  WhileStatement get singleWhileStatement => _single();

  WithClause get singleWithClause => _single();

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

  AssignmentExpression assignment(String search) {
    return _node(search, (n) => n is AssignmentExpression);
  }

  AwaitExpression awaitExpression(String search) {
    return _node(search, (n) => n is AwaitExpression);
  }

  BinaryExpression binary(String search) {
    return _node(search, (n) => n is BinaryExpression);
  }

  BindPatternVariableElement bindPatternVariableElement(String search) {
    var node = declaredVariablePattern(search);
    return node.declaredElement!;
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

  ClassTypeAlias classTypeAlias(String search) {
    return _node(search, (n) => n is ClassTypeAlias);
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

  ConstructorDeclaration constructor(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorDeclaration constructorDeclaration(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorFieldInitializer constructorFieldInitializer(String search) {
    return _node(search, (n) => n is ConstructorFieldInitializer);
  }

  ConstructorName constructorName(String search) {
    return _node(search, (n) => n is ConstructorName);
  }

  ConstructorReference constructorReference(String search) {
    return _node(search, (n) => n is ConstructorReference);
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

  DefaultFormalParameter defaultParameter(String search) {
    return _node(search, (n) => n is DefaultFormalParameter);
  }

  DoStatement doStatement(String search) {
    return _node(search, (n) => n is DoStatement);
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

  EnumConstantDeclaration enumConstantDeclaration(String search) {
    return _node(search, (n) => n is EnumConstantDeclaration);
  }

  EnumDeclaration enumDeclaration(String search) {
    return _node(search, (n) => n is EnumDeclaration);
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

  ExtensionDeclaration extensionDeclaration(String search) {
    return _node(search, (n) => n is ExtensionDeclaration);
  }

  ExtensionOverride extensionOverride(String search) {
    return _node(search, (n) => n is ExtensionOverride);
  }

  ExtensionTypeDeclaration extensionTypeDeclaration(String search) {
    return _node(search, (n) => n is ExtensionTypeDeclaration);
  }

  FieldDeclaration fieldDeclaration(String search) {
    return _node(search, (n) => n is FieldDeclaration);
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

  FormalParameterList formalParameterList(String search) {
    // If the search starts with `(` then NodeLocator will locate the definition
    // before it, so offset the search to within the parameter list.
    var locateOffset = search.startsWith('(') ? 1 : 0;
    return _node(search, (n) => n is FormalParameterList,
        locateOffset: locateOffset);
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

  FunctionExpressionInvocation functionExpressionInvocation(String search) {
    return _node(search, (n) => n is FunctionExpressionInvocation);
  }

  FunctionReference functionReference(String search) {
    return _node(search, (n) => n is FunctionReference);
  }

  FunctionTypeAlias functionTypeAlias(String search) {
    return _node(search, (n) => n is FunctionTypeAlias);
  }

  FunctionTypedFormalParameter functionTypedFormalParameter(String search) {
    return _node(search, (n) => n is FunctionTypedFormalParameter);
  }

  GenericFunctionType genericFunctionType(String search) {
    return _node(search, (n) => n is GenericFunctionType);
  }

  GenericTypeAlias genericTypeAlias(String search) {
    return _node(search, (n) => n is GenericTypeAlias);
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

  ImplicitCallReference implicitCallReference(String search) {
    return _node(search, (n) => n is ImplicitCallReference);
  }

  ImportDirective import(String search) {
    return _node(search, (n) => n is ImportDirective);
  }

  ImportPrefixReference importPrefixReference(String search) {
    return _node(search, (n) => n is ImportPrefixReference);
  }

  IndexExpression index(String search) {
    return _node(search, (n) => n is IndexExpression);
  }

  InstanceCreationExpression instanceCreation(String search) {
    return _node(search, (n) => n is InstanceCreationExpression);
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

  LibraryIdentifier libraryIdentifier(String search) {
    return _node(search, (n) => n is LibraryIdentifier);
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

  NamedExpression namedExpression(String search) {
    return _node(search, (n) => n is NamedExpression);
  }

  NamedType namedType(String search) {
    return _node(search, (n) => n is NamedType);
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
      String search) {
    return _node(search, (n) => n is PatternVariableDeclarationStatement);
  }

  PostfixExpression postfix(String search) {
    return _node(search, (n) => n is PostfixExpression);
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
      String search) {
    return _node(search, (n) => n is RedirectingConstructorInvocation);
  }

  RelationalPattern relationalPattern(String search) {
    return _node(search, (n) => n is RelationalPattern);
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

  SimpleIdentifier simple(String search) {
    return _node(search, (_) => true);
  }

  SimpleFormalParameter simpleFormalParameter(String search) {
    return _node(search, (n) => n is SimpleFormalParameter);
  }

  SimpleFormalParameter simpleParameter(String search) {
    return _node(search, (n) => n is SimpleFormalParameter);
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

  SuperExpression super_(String search) {
    return _node(search, (n) => n is SuperExpression);
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

  VariableDeclaration variableDeclaration(String search) {
    return _node(search, (n) => n is VariableDeclaration);
  }

  VariableDeclarationList variableDeclarationList(String search) {
    return _node(search, (n) => n is VariableDeclarationList);
  }

  VariableDeclarationStatement variableDeclarationStatement(String search) {
    return _node(search, (n) => n is VariableDeclarationStatement);
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

  /// Locates a node at the offset of [search] and returns the first ancestor
  /// matching [predicate].
  ///
  /// If [locateOffset] is provided, its value is added to the offset of
  /// [search] before locating the node.
  T _node<T>(String search, bool Function(AstNode) predicate,
      {int? locateOffset}) {
    int offset = this.offset(search) + (locateOffset ?? 0);

    var node = NodeLocator2(offset).searchWithin(unit);
    if (node == null) {
      throw StateError(
          'The pattern |$search| had no corresponding node in:\n$content');
    }

    var result = node.thisOrAncestorMatching(predicate);
    if (result == null) {
      throw StateError(
          'The node for |$search| had no matching ancestor in:\n$content\n$unit');
    }
    return result as T;
  }

  /// If [unit] has exactly one node of type [T], returns it.
  /// Otherwise, throws.
  T _single<T extends AstNode>() {
    var visitor = _TypedNodeVisitor<T>();
    unit.accept(visitor);
    return visitor.nodes.single;
  }
}

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
