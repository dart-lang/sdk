// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show convertElementToElementKind, ElementKind;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, Element, LibraryElement, LocalElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: a single absolute file path to analyze.');
    io.exit(1);
  }

  var rootPath = args[0];
  print('Analyzing root: \"$rootPath\"');
  if (!io.Directory(rootPath).existsSync()) {
    print('\tError: No such directory exists on this machine.\n');
    return;
  }

  var computer = RelevanceMetricsComputer(rootPath);
  await computer.compute();
  computer.printMetrics();
  io.exit(0);
}

/// An object that records the data used to compute the metrics.
class RelevanceData {
  /// A table mapping element kinds to counts by context.
  Map<String, Map<ElementKind, int>> byElementKind = {};

  /// A table mapping token types to counts by context.
  Map<String, Map<TokenType, int>> byTokenType = {};

  /// A table mapping match types to counts.
  Map<String, Map<bool, int>> byTypeMatch = {};

  /// A table mapping match distances to counts.
  Map<String, Map<int, int>> byDistance = {};

  /// Initialize a newly created set of relevance data to be empty.
  RelevanceData();

  /// Record that a reference to an element was found and that the distance
  /// between that reference and the declaration site is the given [distance].
  /// The [descriptor] is used to describe the kind of distance being measured.
  void recordDistance(String descriptor, int distance) {
    var contextMap = byDistance.putIfAbsent(descriptor, () => {});
    contextMap[distance] = (contextMap[distance] ?? 0) + 1;
  }

  /// Record that an element of the given [kind] was found in the given
  /// [context].
  void recordElementKind(String context, ElementKind kind) {
    var contextMap = byElementKind.putIfAbsent(context, () => {});
    contextMap[kind] = (contextMap[kind] ?? 0) + 1;
  }

  /// Record that a token of the given [type] was found in the given [context].
  void recordTokenType(String context, TokenType type) {
    var contextMap = byTokenType.putIfAbsent(context, () => {});
    contextMap[type] = (contextMap[type] ?? 0) + 1;
  }

  /// Record whether the given [kind] or type match applied to a given argument
  /// (that is, whether [matches] is `true`).
  void recordTypeMatch(String kind, bool matches) {
    var contextMap = byTypeMatch.putIfAbsent(kind, () => {});
    contextMap[matches] = (contextMap[matches] ?? 0) + 1;
  }
}

/// An object that visits a compilation unit in order to record the data used to
/// compute the metrics.
class RelevanceDataCollector extends RecursiveAstVisitor<void> {
  /// The relevance data being collected.
  final RelevanceData data;

  /// The library containing the compilation unit being visited.
  LibraryElement enclosingLibrary;

  /// The type system associated with the current compilation unit.
  TypeSystem typeSystem;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  RelevanceDataCollector(this.data);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // There are no completions.
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    // After the `@`.
    _recordElementKind('Annotation', node.name);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      // At the start of each argument.
      if (argument is NamedExpression) {
        _recordElementKind('ArgumentList (named)', argument.expression);
        // The invocation.
        _recordTypeMatch(argument.expression);
      } else {
        _recordElementKind('ArgumentList (unnamed)', argument);
        // The invocation.
        _recordTypeMatch(argument);
      }
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    // After the `as`.
    _recordElementKind('AsExpression', node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    // At the start of the condition.
    _recordElementKind('AssertInitializer (condition)', node.condition);
    // At the start of the message.
    _recordElementKind('AssertInitializer (message)', node.message);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    // At the start of the condition.
    _recordElementKind('AssertStatement (condition)', node.condition);
    // At the start of the message.
    _recordElementKind('AssertStatement (message)', node.message);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // At the start of the right-hand side.
    _recordElementKind('AssignmentExpression', node.rightHandSide);
    // The invocation.
    var operatorType = node.operator.type;
    if (operatorType != TokenType.EQ &&
        operatorType != TokenType.QUESTION_QUESTION_EQ) {
      _recordTypeMatch(node.rightHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    // After the `await`.
    _recordElementKind('AwaitExpression', node.expression);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // After the operator.
    var operator = node.operator.lexeme;
    _recordElementKind('BinaryExpression ($operator)', node.rightOperand);
    // The invocation.
    if (node.operator.isUserDefinableOperator) {
      _recordTypeMatch(node.rightOperand);
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    // At the start of each statement.
    for (var statement in node.statements) {
      _recordElementKind('Block', statement);
      _recordTokenType('Block', statement);
    }
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _recordTokenType('BlockFunctionBody', node);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _recordTokenType('BooleanLiteral', node);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    // The token following the `break` (if there is one) is always a label.
    super.visitBreakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    // After each `..`.
    for (var cascade in node.cascadeSections) {
      _recordElementKind('CascadeExpression', cascade);
      _recordTokenType('CascadeExpression', cascade);
    }
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    // After the `on`.
    _recordElementKind('CatchClause', node.exceptionType);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // After the name and optional type parameters.
    if (node.extendsClause != null) {
      _recordTokenType('ClassDeclaration (name)', node.extendsClause);
      if (node.withClause != null) {
        _recordTokenType('ClassDeclaration (extends)', node.withClause);
        _recordTokenType('ClassDeclaration (with)', node.implementsClause);
      } else {
        _recordTokenType('ClassDeclaration (extends)', node.implementsClause);
      }
    } else if (node.withClause != null) {
      _recordTokenType('ClassDeclaration (name)', node.withClause);
      _recordTokenType('ClassDeclaration (with)', node.implementsClause);
    } else {
      _recordTokenType('ClassDeclaration (name)', node.implementsClause);
    }
    // At the start of each member.
    for (var member in node.members) {
      _recordElementKind('ClassDeclaration (member)', member);
      _recordTokenType('ClassDeclaration (member)', member);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    // After the `=`.
    _recordElementKind('ClassTypeAlias (=)', node.superclass);
    if (node.withClause != null) {
      _recordTokenType('ClassDeclaration (superclass)', node.withClause);
      _recordTokenType('ClassDeclaration (with)', node.implementsClause);
    } else {
      _recordTokenType('ClassDeclaration (superclass)', node.implementsClause);
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    // There are no completions.
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    // After the `[`.
    _recordElementKind('CommentReference', node.identifier);
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    enclosingLibrary = node.declaredElement.library;
    typeSystem = enclosingLibrary.typeSystem;

    // At the start of each directive.
    for (var member in node.directives) {
      _recordTokenType('CompilationUnit (directives)', member);
    }
    for (var member in node.declarations) {
      _recordElementKind('CompilationUnit (declarations)', member);
      _recordTokenType('CompilationUnit (declarations)', member);
    }
    super.visitCompilationUnit(node);

    typeSystem = null;
    enclosingLibrary = null;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    // After the `?`.
    _recordElementKind('ConditionalExpression (?)', node.thenExpression);
    // After the `:`.
    _recordElementKind('ConditionalExpression (:)', node.elseExpression);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    // There are no completions.
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // At the beginning of each initializer.
    for (var initializer in node.initializers) {
      _recordTokenType('ConstructorDeclaration (initializer)', initializer);
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    // After the `=`.
    _recordElementKind('ConstructorFieldInitializer', node.expression);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // The token following the `.` is always an identifier.
    super.visitConstructorName(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    // The token following the `continue` (if there is one) is always a label.
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    // There are no completions.
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // After the `=`.
    _recordElementKind('DefaultFormalParameter', node.defaultValue);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    // At the start of the body, unless it's a block.
    if (node.body is! Block) {
      _recordElementKind('DoStatement (body)', node.body);
    }
    // At the start of the condition.
    _recordElementKind('DoStatement (condition)', node.condition);
    super.visitDoStatement(node);
  }

  @override
  void visitDottedName(DottedName node) {
    // The components are always identifiers.
    super.visitDottedName(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // There are no completions.
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    // There are no completions.
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    // There are no completions.
    super.visitEmptyStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // There are no completions.
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // There are no completions.
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    // After the URI.
    if (node.configurations.isNotEmpty) {
      _recordTokenType('ImportDirective', node.configurations[0]);
    } else if (node.combinators.isNotEmpty) {
      _recordTokenType('ImportDirective', node.combinators[0]);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // At the start of the expression.
    _recordElementKind('ExpressionFunctionBody', node.expression);
    _recordTokenType('ExpressionFunctionBody', node.expression);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    // At the start of the expression.
    _recordElementKind('ExpressionStatement', node.expression);
    _recordTokenType('ExpressionStatement', node.expression);
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    // After the `extends`.
    _recordElementKind('ExtendsClause', node.superclass);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // After the `on`.
    _recordElementKind('ExtensionDeclaration', node.extendedType);
    // At the start of each member.
    for (var member in node.members) {
      _recordElementKind('ExtensionDeclaration (member)', member);
      _recordTokenType('ExtensionDeclaration (member)', member);
    }
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    // There are no completions.
    super.visitExtensionOverride(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // There are no completions.
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    // The completions after `this.` are always existing fields.
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    // After the `in`.
    _recordElementKind('ForEachPartsWithIdentifier', node.iterable);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    // After the `in`.
    _recordElementKind('ForEachPartsWithIdentifier', node.iterable);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    // After the `(`.
    _recordTokenType('ForElement (parts)', node.forLoopParts);
    // After the `)`.
    _recordElementKind('ForElement (body)', node.body);
    _recordTokenType('ForElement (body)', node.body);
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    // At the start of each parameter.
    for (var parameter in node.parameters) {
      _recordElementKind('FormalParameterList', parameter);
      _recordTokenType('FormalParameterList', parameter);
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    // After the first `;`.
    _recordElementKind('ForPartsWithDeclarations (condition)', node.condition);
    // After the second `;`.
    for (var updater in node.updaters) {
      _recordElementKind('ForPartsWithDeclarations (updater)', updater);
    }
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    // After the first `;`.
    _recordElementKind('ForPartsWithDeclarations (condition)', node.condition);
    // After the second `;`.
    for (var updater in node.updaters) {
      _recordElementKind('ForPartsWithDeclarations (updater)', updater);
    }
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    // After the `(`.
    _recordTokenType('ForElement (parts)', node.forLoopParts);
    // After the `)`.
    _recordElementKind('ForElement (body)', node.body);
    _recordTokenType('ForElement (body)', node.body);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // There are no completions.
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // There are no completions.
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // There are no completions.
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // There are no completions.
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // There are no completions.
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    // There are no completions.
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // There are no completions.
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    // After the `=`.
    _recordElementKind('GenericTypeAlias', node.functionType);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    // At the start of each name.
    for (var name in node.hiddenNames) {
      _recordElementKind('HideCombinator', name);
    }
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    // At the start of the condition.
    _recordElementKind('IfElement (condition)', node.condition);
    // At the start of the then element.
    _recordElementKind('IfElement (then)', node.thenElement);
    _recordTokenType('IfElement (then)', node.thenElement);
    // At the start of the else element.
    _recordElementKind('IfElement (else)', node.elseElement);
    _recordTokenType('IfElement (else)', node.elseElement);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    // At the start of the condition.
    _recordElementKind('IfStatement (condition)', node.condition);
    // At the start of the then statement, unless it's a block.
    if (node.thenStatement is! Block) {
      _recordElementKind('IfStatement (then)', node.thenStatement);
    }
    // At the start of the else statement, unless it's a block.
    if (node.elseStatement is! Block) {
      _recordElementKind('IfStatement (else)', node.elseStatement);
    }
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    // At the start of each type name.
    for (var typeName in node.interfaces) {
      _recordElementKind('ImplementsClause', typeName);
    }
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    // After the URI.
    if (node.deferredKeyword != null) {
      data.recordTokenType('ImportDirective', node.deferredKeyword.type);
    } else if (node.asKeyword != null) {
      data.recordTokenType('ImportDirective', node.asKeyword.type);
    } else if (node.configurations.isNotEmpty) {
      _recordTokenType('ImportDirective', node.configurations[0]);
    } else if (node.combinators.isNotEmpty) {
      _recordTokenType('ImportDirective', node.combinators[0]);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    // After the `[`.
    _recordElementKind('IndexExpression', node.index);
    _recordTokenType('IndexExpression', node.index);
    // The invocation.
    _recordTypeMatch(node.index);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // There are no completions.
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    // At the start of the expression.
    _recordElementKind('InterpolationExpression', node.expression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    // There are no completions.
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    // After the `is`.
    _recordElementKind('IsExpression', node.type);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    // There are no completions.
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _recordElementKind('LabeledStatement', node.statement);
    _recordTokenType('LabeledStatement', node.statement);
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    // There are no completions.
    super.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    // There are no completions.
    super.visitLibraryIdentifier(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    // At the start of each element.
    for (var element in node.elements) {
      _recordElementKind('ListLiteral', element);
      _recordTokenType('ListLiteral', element);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    // After the `:`.
    _recordElementKind('MapLiteralEntry', node.value);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // There are no completions.
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // There are no completions.
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // After the name and optional type parameters.
    if (node.onClause != null) {
      _recordTokenType('MixinDeclaration (name)', node.onClause);
      _recordTokenType('MixinDeclaration (on)', node.implementsClause);
    } else {
      _recordTokenType('MixinDeclaration (name)', node.implementsClause);
    }
    // At the start of each member.
    for (var member in node.members) {
      _recordElementKind('MixinDeclaration (member)', member);
      _recordTokenType('MixinDeclaration (member)', member);
    }
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    // Named expressions only occur in parameter lists and are handled there.
    super.visitNamedExpression(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    // There are no completions.
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    // There are no completions.
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // There are no completions.
    super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    // At the start of each type name.
    for (var constraint in node.superclassConstraints) {
      _recordElementKind('OnClause', constraint);
    }
    super.visitOnClause(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    // After the `(`.
    _recordElementKind('ParenthesizedExpression', node.expression);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    // There are no completions.
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    // There are no completions.
    super.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    // The invocation.
    _recordTypeMatch(node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // There are no completions.
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    // After the operator.
    _recordElementKind('PrefixExpression', node.operand);
    // The invocation.
    _recordTypeMatch(node.operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // There are no completions.
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    // There are no completions.
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // There are no completions.
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    // After the `return`.
    _recordElementKind('ReturnStatement', node.expression);
    if (node.expression == null) {
      data.recordTokenType('ReturnStatement', node.semicolon.type);
    } else {
      _recordTokenType('ReturnStatement', node.expression);
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    // There are no completions.
    super.visitScriptTag(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    // At the start of each element.
    for (var element in node.elements) {
      _recordElementKind('SetOrMapLiteral', element);
      _recordTokenType('SetOrMapLiteral', element);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    // At the start of each name.
    for (var name in node.shownNames) {
      _recordElementKind('ShowCombinator', name);
    }
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    // There are no completions.
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      var element = node.staticElement;
      if (element != null) {
        // TODO(brianwilkerson) We might want to cross reference the depth of
        //  the declaration with the depth of the reference to see whether there
        //  is a pattern.
        _recordDistance('depth', _depth(element));
      }
      if (element is LocalElement) {
        // TODO(brianwilkerson) Record the distance between the reference site
        //  and the declaration site to determine whether local variables that
        //  are declared nearer are more likely to be referenced.
      }
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // There are no completions.
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    // After the `...` or `...?`.
    _recordElementKind('SpreadElement', node.expression);
    super.visitSpreadElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // There are no completions.
    super.visitStringInterpolation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // There are no completions.
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    // There are no completions.
    super.visitSuperExpression(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // At the start of the value.
    _recordElementKind('SwitchCase', node.expression);
    // At the start of each statement.
    for (var statement in node.statements) {
      _recordElementKind('SwitchCase', statement);
      _recordTokenType('SwitchCase', statement);
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    // At the start of each statement.
    for (var statement in node.statements) {
      _recordElementKind('SwitchDefault', statement);
      _recordTokenType('SwitchDefault', statement);
    }
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // At the start of the condition.
    _recordElementKind('SwitchStatement', node.expression);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    // There are no completions.
    super.visitSymbolLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    // There are no completions.
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    // After the `throw`.
    _recordElementKind('ThrowExpression', node.expression);
    _recordTokenType('ThrowExpression', node.expression);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // There are no completions.
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    // At the beginning of each clause.
    for (var clause in node.catchClauses) {
      _recordTokenType('TryStatement', clause);
    }
    if (node.finallyKeyword != null) {
      data.recordTokenType('TryStatement', node.finallyKeyword.type);
    }
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    for (var typeArgument in node.arguments) {
      _recordElementKind('TypeArgumentList', typeArgument);
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeName(TypeName node) {
    // There are no completions.
    super.visitTypeName(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    // After the `extends`.
    if (node.bound != null) {
      _recordElementKind('TypeParameter', node.bound);
    }
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    // There are no completions.
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // After the `=`.
    _recordElementKind('VariableDeclaration', node.initializer);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    // There are no completions.
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    // There are no completions.
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    // At the start of the condition.
    _recordElementKind('WhileStatement', node.condition);
    // At the start of the body, unless it's a block.
    if (node.body is! Block) {
      _recordElementKind('WhileStatement', node.body);
    }
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    // At the start of each type name.
    for (var typeName in node.mixinTypes) {
      _recordElementKind('WithClause', typeName);
    }
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    // After the `yield` and optional `*`.
    _recordElementKind('YieldStatement', node.expression);
    super.visitYieldStatement(node);
  }

  /// Return the depth of the given [element]. For example:
  /// 0: imported
  /// 1: prefix
  /// 2: top-level decl
  /// 3: class member
  /// 4: local variable, function, parameter
  /// 5: local to a local function
  int _depth(Element element) {
    if (element.library != enclosingLibrary) {
      return 0;
    }
    var depth = 0;
    var currentElement = element;
    while (currentElement != enclosingLibrary) {
      depth++;
      currentElement = currentElement.enclosingElement;
    }
    return depth;
  }

  /// Return the first child of the [node] that is neither a comment nor an
  /// annotation.
  SyntacticEntity _firstChild(AstNode node) {
    var children = node.childEntities.toList();
    for (int i = 0; i < children.length; i++) {
      var child = children[i];
      if (child is! Comment && child is! Annotation) {
        return child;
      }
    }
    return null;
  }

  /// Return the left-most child of the [node] if it is a simple identifier, or
  /// `null` if the left-most child is not a simple identifier. Comments and
  /// annotations are ignored for this purpose.
  SimpleIdentifier _leftMostIdentifier(AstNode node) {
    var currentNode = node;
    while (currentNode != null && currentNode is! SimpleIdentifier) {
      var firstChild = _firstChild(currentNode);
      if (firstChild is AstNode) {
        currentNode = firstChild;
      } else {
        currentNode = null;
      }
    }
    if (currentNode is SimpleIdentifier && currentNode.inDeclarationContext()) {
      return null;
    }
    return currentNode;
  }

  /// Return the element kind of the element associated with the left-most
  /// identifier that is a child of the [node].
  ElementKind _leftMostKind(AstNode node) {
    var identifier = _leftMostIdentifier(node);
    var element = identifier?.staticElement;
    if (element == null) {
      return null;
    }
    return convertElementToElementKind(element);
  }

  /// Return the left-most token that is a child of the [node].
  Token _leftMostToken(AstNode node) {
    SyntacticEntity entity = node;
    while (entity is AstNode) {
      entity = _firstChild(entity as AstNode);
    }
    if (entity is Token) {
      return entity;
    }
    return null;
  }

  /// Record the [distance] from a reference to the declaration. The kind of
  /// distance is described by the [descriptor].
  void _recordDistance(String descriptor, int distance) {
    data.recordDistance(descriptor, distance);
  }

  /// Record the element kind of the element associated with the left-most
  /// identifier that is a child of the [node].
  void _recordElementKind(String context, AstNode node) {
    if (node != null) {
      var kind = _leftMostKind(node);
      if (kind != null) {
        data.recordElementKind(context, kind);
      }
    }
  }

  /// Record the token type of the left-most token that is a child of the
  /// [node].
  void _recordTokenType(String context, AstNode node) {
    if (node != null) {
      var token = _leftMostToken(node);
      if (token != null) {
        data.recordTokenType(context, token.type);
      }
    }
  }

  /// Record information about how the argument as a whole and the first token
  /// in the expression match the type of the associated parameter.
  void _recordTypeMatch(Expression argument) {
    var parameterType = argument.staticParameterElement?.type;
    if (parameterType == null || parameterType.isDynamic) {
      return;
    }
    var argumentType = argument.staticType;
    if (argumentType != null) {
      _recordTypeRelationships('whole argument', parameterType, argumentType);
    }
    var identifier = _leftMostIdentifier(argument);
    if (identifier != null) {
      var firstTokenType = identifier.staticType;
      if (firstTokenType == null) {
        var element = identifier.staticElement;
        if (element is ClassElement) {
          // This is effectively treating a reference to a class name as having
          // the same type as an instance of the class, which isn't valid, but
          // on the other hand, the spec doesn't define the static type of a
          // class name in this context so anything we do will be wrong in some
          // sense.
          firstTokenType = element.thisType;
        }
      }
      if (firstTokenType != null) {
        _recordTypeRelationships('first token', parameterType, firstTokenType);
      }
    }
  }

  /// Record information about how the [parameterType] and [argumentType] are
  /// related, using the [descriptor] to differentiate between the counts.
  void _recordTypeRelationships(
      String descriptor, DartType parameterType, DartType argumentType) {
    var matches = argumentType == parameterType;
    data.recordTypeMatch('$descriptor (exact)', matches);

    var subtype = typeSystem.isSubtypeOf(argumentType, parameterType);
    data.recordTypeMatch('$descriptor (subtype)', subtype);
  }
}

/// An object used to compute metrics for a single file or directory.
class RelevanceMetricsComputer {
  /// The absolute and normalized path to the analysis context root.
  final String rootPath;

  /// The metrics data that was computed.
  final RelevanceData data = RelevanceData();

  /// Initialize a newly created metrics computer to compute the metrics in the
  /// [rootPath].
  RelevanceMetricsComputer(this.rootPath);

  /// Compute the metrics for the file(s) in the [rootPath].
  void compute() async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = RelevanceDataCollector(data);

    for (var context in collection.contexts) {
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath)) {
          try {
            ResolvedUnitResult resolvedUnitResult =
                await context.currentSession.getResolvedUnit(filePath);
            //
            // Check for errors that cause the file to be skipped.
            //
            if (resolvedUnitResult.state != ResultState.VALID) {
              print('File $filePath skipped because it could not be analyzed.');
              print('');
              continue;
            } else if (hasError(resolvedUnitResult)) {
              print('File $filePath skipped due to errors:');
              for (var error in resolvedUnitResult.errors) {
                print('  ${error.toString()}');
              }
              print('');
              continue;
            }

            resolvedUnitResult.unit.accept(collector);
          } catch (exception) {
            print('Exception caught analyzing: "$filePath"');
            print(exception.toString());
          }
        }
      }
    }
  }

  /// Print a report of the metrics that were computed.
  void printMetrics() {
    print('');
    print('Element kinds by context');
    _printContextMap(data.byElementKind, (kind) => kind.name);
    print('');
    print('Token types by context');
    _printContextMap(data.byTokenType, (type) => type.name);
    print('');
    print('Argument types match');
    _printContextMap(data.byTypeMatch, (match) => match.toString());
    print('');
    print('Distance from reference to declaration');
    _printContextMap(data.byDistance, (distance) => distance.toString());
  }

  /// Print a [contextMap] containing one kind of metric data, using the
  /// [getName] function to print the second-level keys.
  void _printContextMap<T>(
      Map<String, Map<T, int>> contextMap, String Function(T) getName) {
    var contexts = contextMap.keys.toList()..sort();
    for (var context in contexts) {
      var kindMap = contextMap[context];
      var entries = kindMap.entries.toList()
        ..sort((first, second) {
          return second.value.compareTo(first.value);
        });
      var total = 0;
      for (var entry in entries) {
        total += entry.value;
      }
      print('  $context ($total)');
      for (var entry in entries) {
        var value = entry.value;
        var percent = ((value / total) * 100).toStringAsFixed(1);
        if (percent.length < 4) {
          percent = ' $percent';
        }
        print('    $percent%: ${getName(entry.key)} ($value)');
      }
    }
  }

  /// Return `true` if the [result] contains an error.
  static bool hasError(ResolvedUnitResult result) {
    for (var error in result.errors) {
      if (error.severity == Severity.error) {
        return true;
      }
    }
    return false;
  }
}
