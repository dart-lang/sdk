// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/lint/linter.dart';
/// @docImport 'package:analyzer/src/lint/linter_visitor.dart';
library;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

export 'package:analyzer/src/dart/ast/constant_evaluator.dart';

/// An object used to locate the [AstNode] associated with a source range.
/// More specifically, they will return the deepest [AstNode] which completely
/// encompasses the specified range with some exceptions:
///
/// - Offsets that fall between the name and type/formal parameter list of a
///   declaration will return the declaration node and not the parameter list
///   node.
class NodeLocator2 extends UnifyingAstVisitor<void> {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// The found node or `null` if there is no such node.
  AstNode? _foundNode;

  /// Initialize a newly created locator to locate the deepest [AstNode] for
  /// which `node.offset <= [startOffset]` and `[endOffset] < node.end`.
  ///
  /// If [endOffset] is not provided, then it is considered the same as the
  /// given [startOffset].
  NodeLocator2(int startOffset, [int? endOffset])
    : _startOffset = startOffset,
      _endOffset = endOffset ?? startOffset;

  /// Search within the given AST [node] and return the node that was found,
  /// or `null` if no node was found.
  AstNode? searchWithin(AstNode? node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
        SilentException(
          'Unable to locate element at offset '
          '($_startOffset - $_endOffset)',
          exception,
          stackTrace,
        ),
      );
      return null;
    }
    return _foundNode;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset &&
        _startOffset == (node.name ?? node.returnType).end) {
      _foundNode = node;
      return;
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Names do not have AstNodes but offsets at the end should be treated as
    // part of the declaration (not parameter list).
    if (_startOffset == _endOffset && _startOffset == node.name.end) {
      _foundNode = node;
      return;
    }

    super.visitMethodDeclaration(node);
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit a new tree if the result has been already found.
    if (_foundNode != null) {
      return;
    }
    // Check whether the current node covers the selection.
    Token beginToken = node.beginToken;
    Token endToken = node.endToken;
    // Don't include synthetic tokens.
    while (endToken != beginToken) {
      // Fasta scanner reports unterminated string literal errors
      // and generates a synthetic string token with non-zero length.
      // Because of this, check for length > 0 rather than !isSynthetic.
      if (endToken.isEof || endToken.length > 0) {
        break;
      }
      endToken = endToken.previous!;
    }
    int end = endToken.end;
    int start = node.offset;
    if (end <= _startOffset || start > _endOffset) {
      return;
    }
    // Check children.
    try {
      node.visitChildren(this);
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
        SilentException(
          "Exception caught while traversing an AST structure.",
          exception,
          stackTrace,
        ),
      );
    }
    // Found a child.
    if (_foundNode != null) {
      return;
    }
    // Check this node.
    if (start <= _startOffset && _endOffset < end) {
      _foundNode = node;
    }
  }
}

/// An object that will replace one child node in an AST node with another node.
class NodeReplacer extends ThrowingAstVisitor<bool> {
  /// The node being replaced.
  final AstNode _oldNode;

  /// The node that is replacing the old node.
  final AstNode _newNode;

  /// Initialize a newly created node locator to replace the [_oldNode] with the
  /// [_newNode].
  NodeReplacer._(this._oldNode, this._newNode);

  @override
  bool visitAdjacentStrings(covariant AdjacentStringsImpl node) {
    if (_replaceInList(node.strings)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitAnnotatedNode(covariant AnnotatedNodeImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as CommentImpl;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAnnotation(covariant AnnotationImpl node) {
    if (identical(node.arguments, _oldNode)) {
      node.arguments = _newNode as ArgumentListImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl?;
      return true;
    } else if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as IdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitArgumentList(covariant ArgumentListImpl node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAsExpression(covariant AsExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertInitializer(covariant AssertInitializerImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertStatement(covariant AssertStatementImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    }
    if (identical(node.message, _oldNode)) {
      node.message = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssignmentExpression(covariant AssignmentExpressionImpl node) {
    if (identical(node.leftHandSide, _oldNode)) {
      node.leftHandSide = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.rightHandSide, _oldNode)) {
      node.rightHandSide = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAwaitExpression(covariant AwaitExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBinaryExpression(covariant BinaryExpressionImpl node) {
    if (identical(node.leftOperand, _oldNode)) {
      node.leftOperand = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.rightOperand, _oldNode)) {
      node.rightOperand = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlock(covariant BlockImpl node) {
    if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlockFunctionBody(covariant BlockFunctionBodyImpl node) {
    if (identical(node.block, _oldNode)) {
      node.block = _newNode as BlockImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  bool visitBreakStatement(covariant BreakStatementImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCascadeExpression(covariant CascadeExpressionImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as ExpressionImpl;
      return true;
    } else if (_replaceInList(node.cascadeSections)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCatchClause(covariant CatchClauseImpl node) {
    if (identical(node.exceptionType, _oldNode)) {
      node.exceptionType = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.exceptionParameter, _oldNode)) {
      node.exceptionParameter = _newNode as CatchClauseParameterImpl;
      return true;
    } else if (identical(node.stackTraceParameter, _oldNode)) {
      node.stackTraceParameter = _newNode as CatchClauseParameterImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as BlockImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitCatchClauseParameter(CatchClauseParameter node) {
    return visitNode(node);
  }

  @override
  bool visitClassDeclaration(covariant ClassDeclarationImpl node) {
    if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.extendsClause, _oldNode)) {
      node.extendsClause = _newNode as ExtendsClauseImpl;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClauseImpl;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClauseImpl;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as NamedTypeImpl;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClauseImpl;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClauseImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitComment(covariant CommentImpl node) {
    if (_replaceInList(node.references)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCommentReference(covariant CommentReferenceImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as IdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCompilationUnit(covariant CompilationUnitImpl node) {
    if (identical(node.scriptTag, _oldNode)) {
      node.scriptTag = _newNode as ScriptTagImpl;
      return true;
    } else if (_replaceInList(node.directives)) {
      return true;
    } else if (_replaceInList(node.declarations)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConditionalExpression(covariant ConditionalExpressionImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.thenExpression, _oldNode)) {
      node.thenExpression = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.elseExpression, _oldNode)) {
      node.elseExpression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConfiguration(covariant ConfigurationImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as DottedNameImpl;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as StringLiteralImpl;
      return true;
    } else if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteralImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstantPattern(covariant ConstantPatternImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as IdentifierImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    } else if (identical(node.redirectedConstructor, _oldNode)) {
      node.redirectedConstructor = _newNode as ConstructorNameImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBodyImpl;
      return true;
    } else if (_replaceInList(node.initializers)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitConstructorFieldInitializer(
    covariant ConstructorFieldInitializerImpl node,
  ) {
    if (identical(node.fieldName, _oldNode)) {
      node.fieldName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorName(covariant ConstructorNameImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as NamedTypeImpl;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorReference(covariant ConstructorReferenceImpl node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorNameImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorSelector(ConstructorSelector node) {
    throw UnimplementedError();
  }

  @override
  bool visitContinueStatement(covariant ContinueStatementImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDeclaredIdentifier(covariant DeclaredIdentifierImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    if (identical(node.parameter, _oldNode)) {
      node.parameter = _newNode as NormalFormalParameterImpl;
      return true;
    } else if (identical(node.defaultValue, _oldNode)) {
      node.defaultValue = _newNode as ExpressionImpl;
      var parameterElement = node.declaredFragment;
      parameterElement?.constantInitializer = _newNode;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoStatement(covariant DoStatementImpl node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as StatementImpl;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitDotShorthandInvocation(covariant DotShorthandInvocationImpl node) {
    if (identical(node.memberName, _oldNode)) {
      node.memberName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitDotShorthandPropertyAccess(
    covariant DotShorthandPropertyAccessImpl node,
  ) {
    if (identical(node.propertyName, _oldNode)) {
      node.propertyName = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDottedName(covariant DottedNameImpl node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  bool visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  bool visitEnumConstantArguments(EnumConstantArguments node) {
    throw UnimplementedError();
  }

  @override
  bool visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    return visitAnnotatedNode(node);
  }

  @override
  bool visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClauseImpl;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClauseImpl;
      return true;
    } else if (_replaceInList(node.constants)) {
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitExportDirective(covariant ExportDirectiveImpl node) =>
      visitNamespaceDirective(node);

  @override
  bool visitExpressionFunctionBody(covariant ExpressionFunctionBodyImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExpressionStatement(covariant ExpressionStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtendsClause(covariant ExtendsClauseImpl node) {
    if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as NamedTypeImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as CommentImpl;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    if (identical(node.fields, _oldNode)) {
      node.fields = _newNode as VariableDeclarationListImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (identical(node.loopVariable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).loopVariable =
          _newNode as DeclaredIdentifierImpl;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithDeclarationImpl).iterable =
          _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (identical(node.identifier, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).identifier =
          _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithIdentifierImpl).iterable =
          _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    if (identical(node.iterable, _oldNode)) {
      (node as ForEachPartsWithPatternImpl).iterable =
          _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForElement(ForElement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForElementImpl).forLoopParts = _newNode as ForLoopPartsImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForElementImpl).body = _newNode as CollectionElementImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFormalParameterList(covariant FormalParameterListImpl node) {
    if (_replaceInList(node.parameters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithDeclarations(
    covariant ForPartsWithDeclarationsImpl node,
  ) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationListImpl;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForPartsWithExpression(covariant ForPartsWithExpressionImpl node) {
    if (identical(node.initialization, _oldNode)) {
      node.initialization = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForStatement(ForStatement node) {
    if (identical(node.forLoopParts, _oldNode)) {
      (node as ForStatementImpl).forLoopParts = _newNode as ForLoopPartsImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      (node as ForStatementImpl).body = _newNode as StatementImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.functionExpression, _oldNode)) {
      node.functionExpression = _newNode as FunctionExpressionImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionDeclarationStatement(
    covariant FunctionDeclarationStatementImpl node,
  ) {
    if (identical(node.functionDeclaration, _oldNode)) {
      node.functionDeclaration = _newNode as FunctionDeclarationImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpression(covariant FunctionExpressionImpl node) {
    if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBodyImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpressionInvocation(
    covariant FunctionExpressionInvocationImpl node,
  ) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionReference(covariant FunctionReferenceImpl node) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool? visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    }
    return null;
  }

  @override
  bool visitGenericTypeAlias(GenericTypeAlias node) {
    var nodeImpl = node as GenericTypeAliasImpl;
    if (identical(node.typeParameters, _oldNode)) {
      nodeImpl.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.type, _oldNode)) {
      nodeImpl.type = _newNode as TypeAnnotationImpl;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitHideCombinator(covariant HideCombinatorImpl node) {
    if (_replaceInList(node.hiddenNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfElement(IfElement node) {
    if (identical(node.expression, _oldNode)) {
      (node as IfElementImpl).condition = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.thenElement, _oldNode)) {
      (node as IfElementImpl).thenElement = _newNode as CollectionElementImpl;
      return true;
    } else if (identical(node.elseElement, _oldNode)) {
      (node as IfElementImpl).elseElement = _newNode as CollectionElementImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfStatement(covariant IfStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.thenStatement, _oldNode)) {
      node.thenStatement = _newNode as StatementImpl;
      return true;
    } else if (identical(node.elseStatement, _oldNode)) {
      node.elseStatement = _newNode as StatementImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplementsClause(covariant ImplementsClauseImpl node) {
    if (_replaceInList(node.interfaces)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplicitCallReference(covariant ImplicitCallReferenceImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImportDirective(covariant ImportDirectiveImpl node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNamespaceDirective(node);
  }

  @override
  bool visitIndexExpression(covariant IndexExpressionImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.index, _oldNode)) {
      node.index = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorNameImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  bool visitInterpolationExpression(
    covariant InterpolationExpressionImpl node,
  ) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  bool visitIsExpression(covariant IsExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabel(covariant LabelImpl node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabeledStatement(covariant LabeledStatementImpl node) {
    if (identical(node.statement, _oldNode)) {
      node.statement = _newNode as StatementImpl;
      return true;
    } else if (_replaceInList(node.labels)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as LibraryIdentifierImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitLibraryIdentifier(covariant LibraryIdentifierImpl node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitListLiteral(covariant ListLiteralImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitMapLiteralEntry(covariant MapLiteralEntryImpl node) {
    if (identical(node.key, _oldNode)) {
      node.key = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitMapPatternEntry(covariant MapPatternEntryImpl node) {
    if (identical(node.key, _oldNode)) {
      node.key = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMethodInvocation(covariant MethodInvocationImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.methodName, _oldNode)) {
      node.methodName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMixinOnClause(covariant MixinOnClauseImpl node) {
    if (_replaceInList(node.superclassConstraints)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNamedExpression(covariant NamedExpressionImpl node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as LabelImpl;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  bool visitNamespaceDirective(covariant NamespaceDirectiveImpl node) {
    if (_replaceInList(node.combinators)) {
      return true;
    }
    return visitUriBasedDirective(node);
  }

  @override
  bool visitNativeFunctionBody(covariant NativeFunctionBodyImpl node) {
    if (identical(node.stringLiteral, _oldNode)) {
      node.stringLiteral = _newNode as StringLiteralImpl;
      return true;
    }
    return visitNode(node);
  }

  bool visitNode(AstNode node) {
    throw ArgumentError("The old node is not a child of it's parent");
  }

  bool visitNormalFormalParameter(covariant NormalFormalParameterImpl node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as CommentImpl;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNullAwareElement(NullAwareElement node) {
    if (identical(node.value, _oldNode)) {
      (node as NullAwareElementImpl).value = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  bool visitParenthesizedExpression(
    covariant ParenthesizedExpressionImpl node,
  ) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPartDirective(covariant PartDirectiveImpl node) =>
      visitUriBasedDirective(node);

  @override
  bool visitPartOfDirective(covariant PartOfDirectiveImpl node) {
    if (identical(node.libraryName, _oldNode)) {
      node.libraryName = _newNode as LibraryIdentifierImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitPatternAssignment(covariant PatternAssignmentImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPostfixExpression(covariant PostfixExpressionImpl node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixExpression(covariant PrefixExpressionImpl node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPropertyAccess(covariant PropertyAccessImpl node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.propertyName, _oldNode)) {
      node.propertyName = _newNode as SimpleIdentifierImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRecordLiteral(covariant RecordLiteralImpl node) {
    if (_replaceInList(node.fields)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    if (_replaceInList(node.positionalFields)) {
      return true;
    } else if (identical(node.namedFields, _oldNode)) {
      // node.namedFields = _newNode as RecordTypeAnnotationNamedFieldsImpl;
      throw UnimplementedError();
    }
    return visitNode(node);
  }

  @override
  bool visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.type, _oldNode)) {
      // node.type = _newNode as TypeAnnotationImpl;
      throw UnimplementedError();
    }
    return visitNode(node);
  }

  @override
  bool visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    if (_replaceInList(node.fields)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    if (_replaceInList(node.metadata)) {
      return true;
    } else if (identical(node.type, _oldNode)) {
      // node.type = _newNode as TypeAnnotationImpl;
      throw UnimplementedError();
    }
    return visitNode(node);
  }

  @override
  bool visitRedirectingConstructorInvocation(
    covariant RedirectingConstructorInvocationImpl node,
  ) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitRelationalPattern(covariant RelationalPatternImpl node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  bool visitReturnStatement(covariant ReturnStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  bool visitSetOrMapLiteral(covariant SetOrMapLiteralImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitShowCombinator(covariant ShowCombinatorImpl node) {
    if (_replaceInList(node.shownNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSimpleFormalParameter(covariant SimpleFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  bool visitSpreadElement(SpreadElement node) {
    if (identical(node.expression, _oldNode)) {
      (node as SpreadElementImpl).expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitStringInterpolation(covariant StringInterpolationImpl node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperConstructorInvocation(
    covariant SuperConstructorInvocationImpl node,
  ) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifierImpl;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperExpression(covariant SuperExpressionImpl node) =>
      visitNode(node);

  @override
  bool visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterListImpl;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterListImpl;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSwitchCase(covariant SwitchCaseImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitSwitchMember(node);
  }

  @override
  bool visitSwitchDefault(covariant SwitchDefaultImpl node) =>
      visitSwitchMember(node);

  @override
  bool? visitSwitchExpression(covariant SwitchExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitSwitchExpressionCase(covariant SwitchExpressionCaseImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  bool visitSwitchMember(covariant SwitchMemberImpl node) {
    if (_replaceInList(node.labels)) {
      return true;
    } else if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSwitchStatement(covariant SwitchStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  bool visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  bool visitThrowExpression(covariant ThrowExpressionImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationListImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitTryStatement(covariant TryStatementImpl node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as BlockImpl;
      return true;
    } else if (identical(node.finallyBlock, _oldNode)) {
      node.finallyBlock = _newNode as BlockImpl;
      return true;
    } else if (_replaceInList(node.catchClauses)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeArgumentList(covariant TypeArgumentListImpl node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitTypedLiteral(covariant TypedLiteralImpl node) {
    if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeLiteral(covariant TypeLiteralImpl node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as NamedTypeImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameter(covariant TypeParameterImpl node) {
    if (identical(node.bound, _oldNode)) {
      node.bound = _newNode as TypeAnnotationImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameterList(covariant TypeParameterListImpl node) {
    if (_replaceInList(node.typeParameters)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitUriBasedDirective(covariant UriBasedDirectiveImpl node) {
    if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteralImpl;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    if (identical(node.initializer, _oldNode)) {
      node.initializer = _newNode as ExpressionImpl;
      return true;
      // TODO(srawlins): also replace node's declared element's
      // `constantInitializer`, if the element is [ConstFieldElementImpl],
      // [ConstLocalVariableElementImpl], or [ConstTopLevelVariableElementImpl].
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeAnnotationImpl;
      return true;
    } else if (_replaceInList(node.variables)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationStatement(
    covariant VariableDeclarationStatementImpl node,
  ) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationListImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool? visitWhenClause(covariant WhenClauseImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWhileStatement(covariant WhileStatementImpl node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as ExpressionImpl;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as StatementImpl;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWithClause(covariant WithClauseImpl node) {
    if (_replaceInList(node.mixinTypes)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitYieldStatement(covariant YieldStatementImpl node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as ExpressionImpl;
      return true;
    }
    return visitNode(node);
  }

  bool _replaceInList(NodeList list) {
    int count = list.length;
    for (int i = 0; i < count; i++) {
      if (identical(_oldNode, list[i])) {
        list[i] = _newNode;
        return true;
      }
    }
    return false;
  }

  /// Replace the [oldNode] with the [newNode] in the AST structure containing
  /// the old node. Return `true` if the replacement was successful.
  ///
  /// Throws an [ArgumentError] if either node is `null`, if the old node does
  /// not have a parent node, or if the AST structure has been corrupted.
  ///
  /// If [newNode] is the parent of [oldNode] already (because [newNode] became
  /// the parent of [oldNode] in its constructor), this action will loop
  /// infinitely; pass [oldNode]'s previous parent as [parent] to avoid this.
  static bool replace(AstNode oldNode, AstNode newNode, {AstNode? parent}) {
    if (identical(oldNode, newNode)) {
      return true;
    }
    parent ??= oldNode.parent;
    if (parent == null) {
      throw ArgumentError("The old node is not a child of another node");
    }
    NodeReplacer replacer = NodeReplacer._(oldNode, newNode);
    return parent.accept(replacer)!;
  }
}

/// Traverse the AST from initial child node to successive parents, building a
/// collection of local variable and parameter names visible to the initial
/// child node. In case of name shadowing, the first name seen is the most
/// specific one so names are not redefined.
///
/// Completion test code coverage is 95%. The two basic blocks that are not
/// executed cannot be executed. They are included for future reference.
class ScopedNameFinder extends GeneralizingAstVisitor<void> {
  Declaration? _declarationNode;

  AstNode? _immediateChild;

  final Set<String> _locals = {};

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration? get declaration => _declarationNode;

  Set<String> get locals => _locals;

  @override
  void visitBlock(Block node) {
    _checkStatements(node.statements);
    super.visitBlock(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter?.name);
    _addToScope(node.stackTraceParameter?.name);
    super.visitCatchClause(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _addToScope(node.loopVariable.name);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _addVariables(node.variables.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
    } else {
      super.visitFunctionDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    var parameters = node.parameters;
    if (parameters != null && !identical(_immediateChild, parameters)) {
      _addParameters(parameters.parameters);
    }
  }

  @override
  void visitNode(AstNode node) {
    _immediateChild = node;
    node.parent?.accept(this);
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    super.visitSwitchMember(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
  }

  void _addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      _addToScope(var2.name);
    }
  }

  void _addToScope(Token? identifier) {
    if (identifier != null && _isInRange(identifier)) {
      _locals.add(identifier.lexeme);
    }
  }

  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      _addToScope(variable.name);
    }
  }

  /// Check the given list of [statements] for any that come before the
  /// immediate child and that define a name that would be visible to the
  /// immediate child.
  void _checkStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      if (identical(statement, _immediateChild)) {
        return;
      }
      if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables.variables);
      } else if (statement is FunctionDeclarationStatement &&
          !_referenceIsWithinLocalFunction) {
        _addToScope(statement.functionDeclaration.name);
      }
    }
  }

  bool _isInRange(Token token) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
      // not reached
    }
    return token.end < _position;
  }
}
