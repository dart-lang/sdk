// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// A visitor used to write a source representation of a visited AST node (and
/// all of it's children) to a sink.
class ToSourceVisitor implements AstVisitor<void> {
  /// The sink to which the source is to be written.
  @protected
  final StringSink sink;

  /// Initialize a newly created visitor to write source code representing the
  /// visited nodes to the given [sink].
  ToSourceVisitor(this.sink);

  /// Visit the given function [body], printing the [prefix] before if the body
  /// is not empty.
  @protected
  void safelyVisitFunctionWithPrefix(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      sink.write(prefix);
    }
    safelyVisitNode(body);
  }

  /// Safely visit the given [node].
  @protected
  void safelyVisitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /// Print a list of [nodes] without any separation.
  @protected
  void safelyVisitNodeList(NodeList<AstNode> nodes) {
    safelyVisitNodeListWithSeparator(nodes, "");
  }

  /// Print a list of [nodes], separated by the given [separator].
  @protected
  void safelyVisitNodeListWithSeparator(
      NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        if (i > 0) {
          sink.write(separator);
        }
        var node = nodes[i];
        if (node != null) {
          node.accept(this);
        } else {
          sink.write('<null>');
        }
      }
    }
  }

  /// Print a list of [nodes], prefixed by the given [prefix] if the list is not
  /// empty, and separated by the given [separator].
  @protected
  void safelyVisitNodeListWithSeparatorAndPrefix(
      String prefix, NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        sink.write(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            sink.write(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

  /// Print a list of [nodes], separated by the given [separator], followed by
  /// the given [suffix] if the list is not empty.
  @protected
  void safelyVisitNodeListWithSeparatorAndSuffix(
      NodeList<AstNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            sink.write(separator);
          }
          nodes[i].accept(this);
        }
        sink.write(suffix);
      }
    }
  }

  /// Safely visit the given [node], printing the [prefix] before the node if it
  /// is non-`null`.
  @protected
  void safelyVisitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      sink.write(prefix);
      node.accept(this);
    }
  }

  /// Safely visit the given [node], printing the [suffix] after the node if it
  /// is non-`null`.
  @protected
  void safelyVisitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      sink.write(suffix);
    }
  }

  /// Safely visit the given [token].
  @protected
  void safelyVisitToken(Token token) {
    if (token != null) {
      sink.write(token.lexeme);
    }
  }

  /// Safely visit the given [token], printing the [suffix] after the token if
  /// it is non-`null`.
  @protected
  void safelyVisitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      sink.write(token.lexeme);
      sink.write(suffix);
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    safelyVisitNodeListWithSeparator(node.strings, " ");
  }

  @override
  void visitAnnotation(Annotation node) {
    sink.write('@');
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.arguments);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    sink.write('(');
    safelyVisitNodeListWithSeparator(node.arguments, ", ");
    sink.write(')');
  }

  @override
  void visitAsExpression(AsExpression node) {
    safelyVisitNode(node.expression);
    sink.write(" as ");
    safelyVisitNode(node.type);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    sink.write("assert (");
    safelyVisitNode(node.condition);
    if (node.message != null) {
      sink.write(', ');
      safelyVisitNode(node.message);
    }
    sink.write(");");
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    sink.write("assert (");
    safelyVisitNode(node.condition);
    if (node.message != null) {
      sink.write(', ');
      safelyVisitNode(node.message);
    }
    sink.write(");");
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    safelyVisitNode(node.leftHandSide);
    sink.write(' ');
    sink.write(node.operator.lexeme);
    sink.write(' ');
    safelyVisitNode(node.rightHandSide);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    sink.write("await ");
    safelyVisitNode(node.expression);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeOperand(node, node.leftOperand);
    sink.write(' ');
    sink.write(node.operator.lexeme);
    sink.write(' ');
    _writeOperand(node, node.rightOperand);
  }

  @override
  void visitBlock(Block node) {
    sink.write('{');
    safelyVisitNodeListWithSeparator(node.statements, " ");
    sink.write('}');
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      sink.write(keyword.lexeme);
      if (node.star != null) {
        sink.write('*');
      }
      sink.write(' ');
    }
    safelyVisitNode(node.block);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    sink.write(node.literal.lexeme);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    sink.write("break");
    safelyVisitNodeWithPrefix(" ", node.label);
    sink.write(";");
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    safelyVisitNode(node.target);
    safelyVisitNodeList(node.cascadeSections);
  }

  @override
  void visitCatchClause(CatchClause node) {
    safelyVisitNodeWithPrefix("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        sink.write(' ');
      }
      sink.write("catch (");
      safelyVisitNode(node.exceptionParameter);
      safelyVisitNodeWithPrefix(", ", node.stackTraceParameter);
      sink.write(") ");
    } else {
      sink.write(" ");
    }
    safelyVisitNode(node.body);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.abstractKeyword, " ");
    sink.write("class ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    safelyVisitNodeWithPrefix(" ", node.extendsClause);
    safelyVisitNodeWithPrefix(" ", node.withClause);
    safelyVisitNodeWithPrefix(" ", node.implementsClause);
    sink.write(" {");
    safelyVisitNodeListWithSeparator(node.members, " ");
    sink.write("}");
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    if (node.abstractKeyword != null) {
      sink.write("abstract ");
    }
    sink.write("class ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    sink.write(" = ");
    safelyVisitNode(node.superclass);
    safelyVisitNodeWithPrefix(" ", node.withClause);
    safelyVisitNodeWithPrefix(" ", node.implementsClause);
    sink.write(";");
  }

  @override
  void visitComment(Comment node) {}

  @override
  void visitCommentReference(CommentReference node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    safelyVisitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    safelyVisitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    safelyVisitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    safelyVisitNode(node.condition);
    sink.write(" ? ");
    safelyVisitNode(node.thenExpression);
    sink.write(" : ");
    safelyVisitNode(node.elseExpression);
  }

  @override
  void visitConfiguration(Configuration node) {
    sink.write('if (');
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" == ", node.value);
    sink.write(') ');
    safelyVisitNode(node.uri);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitTokenWithSuffix(node.constKeyword, " ");
    safelyVisitTokenWithSuffix(node.factoryKeyword, " ");
    safelyVisitNode(node.returnType);
    safelyVisitNodeWithPrefix(".", node.name);
    safelyVisitNode(node.parameters);
    safelyVisitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    safelyVisitNodeWithPrefix(" = ", node.redirectedConstructor);
    safelyVisitFunctionWithPrefix(" ", node.body);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    safelyVisitTokenWithSuffix(node.thisKeyword, ".");
    safelyVisitNode(node.fieldName);
    sink.write(" = ");
    safelyVisitNode(node.expression);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    safelyVisitNode(node.type);
    safelyVisitNodeWithPrefix(".", node.name);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    sink.write("continue");
    safelyVisitNodeWithPrefix(" ", node.label);
    sink.write(";");
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    safelyVisitNode(node.identifier);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (node.isRequiredNamed) {
      sink.write('required ');
    }
    safelyVisitNode(node.parameter);
    if (node.separator != null) {
      if (node.separator.lexeme != ":") {
        sink.write(" ");
      }
      sink.write(node.separator.lexeme);
      safelyVisitNodeWithPrefix(" ", node.defaultValue);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    sink.write("do ");
    safelyVisitNode(node.body);
    sink.write(" while (");
    safelyVisitNode(node.condition);
    sink.write(");");
  }

  @override
  void visitDottedName(DottedName node) {
    safelyVisitNodeListWithSeparator(node.components, ".");
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    sink.write(node.literal.lexeme);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    sink.write(';');
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    sink.write(';');
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitNode(node.name);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("enum ");
    safelyVisitNode(node.name);
    sink.write(" {");
    safelyVisitNodeListWithSeparator(node.constants, ", ");
    sink.write("}");
  }

  @override
  void visitExportDirective(ExportDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("export ");
    safelyVisitNode(node.uri);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    sink.write(';');
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      sink.write(keyword.lexeme);
      sink.write(' ');
    }
    sink.write('${node.functionDefinition?.lexeme} ');
    safelyVisitNode(node.expression);
    if (node.semicolon != null) {
      sink.write(';');
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    safelyVisitNode(node.expression);
    sink.write(';');
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    sink.write("extends ");
    safelyVisitNode(node.superclass);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.extensionKeyword, ' ');
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    sink.write(' ');
    safelyVisitToken(node.onKeyword);
    sink.write(' ');
    safelyVisitNodeWithSuffix(node.extendedType, ' ');
    safelyVisitToken(node.leftBracket);
    safelyVisitNodeListWithSeparator(node.members, ' ');
    safelyVisitToken(node.rightBracket);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    safelyVisitNode(node.extensionName);
    safelyVisitNode(node.typeArguments);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.abstractKeyword, " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitTokenWithSuffix(node.staticKeyword, " ");
    safelyVisitNode(node.fields);
    sink.write(";");
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    sink.write("this.");
    safelyVisitNode(node.identifier);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    safelyVisitNode(node.loopVariable);
    sink.write(' in ');
    safelyVisitNode(node.iterable);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    safelyVisitNode(node.identifier);
    sink.write(' in ');
    safelyVisitNode(node.iterable);
  }

  @override
  void visitForElement(ForElement node) {
    safelyVisitTokenWithSuffix(node.awaitKeyword, ' ');
    sink.write('for (');
    safelyVisitNode(node.forLoopParts);
    sink.write(') ');
    safelyVisitNode(node.body);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    String groupEnd;
    sink.write('(');
    NodeList<FormalParameter> parameters = node.parameters;
    int size = parameters.length;
    for (int i = 0; i < size; i++) {
      FormalParameter parameter = parameters[i];
      if (i > 0) {
        sink.write(", ");
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (parameter.isNamed) {
          groupEnd = "}";
          sink.write('{');
        } else {
          groupEnd = "]";
          sink.write('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      sink.write(groupEnd);
    }
    sink.write(')');
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    safelyVisitNode(node.variables);
    sink.write(';');
    safelyVisitNodeWithPrefix(' ', node.condition);
    sink.write(';');
    safelyVisitNodeListWithSeparatorAndPrefix(' ', node.updaters, ', ');
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    safelyVisitNode(node.initialization);
    sink.write(';');
    safelyVisitNodeWithPrefix(' ', node.condition);
    sink.write(';');
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.updaters, ', ');
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) {
      sink.write('await ');
    }
    sink.write('for (');
    safelyVisitNode(node.forLoopParts);
    sink.write(') ');
    safelyVisitNode(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitTokenWithSuffix(node.propertyKeyword, " ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.functionExpression);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    safelyVisitNode(node.functionDeclaration);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    if (node.body is! EmptyFunctionBody) {
      sink.write(' ');
    }
    safelyVisitNode(node.body);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    safelyVisitNode(node.function);
    safelyVisitNode(node.typeArguments);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("typedef ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    sink.write(";");
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitNode(node.identifier);
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    if (node.question != null) {
      sink.write('?');
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    safelyVisitNode(node.returnType);
    sink.write(' Function');
    safelyVisitNode(node.typeParameters);
    safelyVisitNode(node.parameters);
    if (node.question != null) {
      sink.write('?');
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("typedef ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    sink.write(" = ");
    safelyVisitNode(node.type);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    sink.write("hide ");
    safelyVisitNodeListWithSeparator(node.hiddenNames, ", ");
  }

  @override
  void visitIfElement(IfElement node) {
    sink.write('if (');
    safelyVisitNode(node.condition);
    sink.write(') ');
    safelyVisitNode(node.thenElement);
    safelyVisitNodeWithPrefix(' else ', node.elseElement);
  }

  @override
  void visitIfStatement(IfStatement node) {
    sink.write("if (");
    safelyVisitNode(node.condition);
    sink.write(") ");
    safelyVisitNode(node.thenStatement);
    safelyVisitNodeWithPrefix(" else ", node.elseStatement);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    sink.write("implements ");
    safelyVisitNodeListWithSeparator(node.interfaces, ", ");
  }

  @override
  void visitImportDirective(ImportDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("import ");
    safelyVisitNode(node.uri);
    if (node.deferredKeyword != null) {
      sink.write(" deferred");
    }
    safelyVisitNodeWithPrefix(" as ", node.prefix);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    sink.write(';');
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      safelyVisitToken(node.period);
    } else {
      safelyVisitNode(node.target);
    }
    safelyVisitToken(node.question);
    safelyVisitToken(node.leftBracket);
    safelyVisitNode(node.index);
    safelyVisitToken(node.rightBracket);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNode(node.constructorName);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    sink.write(node.literal.lexeme);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      sink.write("\${");
      safelyVisitNode(node.expression);
      sink.write("}");
    } else {
      sink.write("\$");
      safelyVisitNode(node.expression);
    }
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    sink.write(node.contents.lexeme);
  }

  @override
  void visitIsExpression(IsExpression node) {
    safelyVisitNode(node.expression);
    if (node.notOperator == null) {
      sink.write(" is ");
    } else {
      sink.write(" is! ");
    }
    safelyVisitNode(node.type);
  }

  @override
  void visitLabel(Label node) {
    safelyVisitNode(node.label);
    sink.write(":");
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    safelyVisitNode(node.statement);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("library ");
    safelyVisitNode(node.name);
    sink.write(';');
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    sink.write(node.name);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    safelyVisitTokenWithSuffix(node.constKeyword, ' ');
    safelyVisitNode(node.typeArguments);
    sink.write('[');
    safelyVisitNodeListWithSeparator(node.elements, ', ');
    sink.write(']');
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    safelyVisitNode(node.key);
    sink.write(" : ");
    safelyVisitNode(node.value);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitTokenWithSuffix(node.modifierKeyword, " ");
    safelyVisitNodeWithSuffix(node.returnType, " ");
    safelyVisitTokenWithSuffix(node.propertyKeyword, " ");
    safelyVisitTokenWithSuffix(node.operatorKeyword, " ");
    safelyVisitNode(node.name);
    if (!node.isGetter) {
      safelyVisitNode(node.typeParameters);
      safelyVisitNode(node.parameters);
    }
    safelyVisitFunctionWithPrefix(" ", node.body);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      sink.write(node.operator.lexeme);
    } else {
      if (node.target != null) {
        node.target.accept(this);
        sink.write(node.operator.lexeme);
      }
    }
    safelyVisitNode(node.methodName);
    safelyVisitNode(node.typeArguments);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("mixin ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeParameters);
    safelyVisitNodeWithPrefix(" ", node.onClause);
    safelyVisitNodeWithPrefix(" ", node.implementsClause);
    sink.write(" {");
    safelyVisitNodeListWithSeparator(node.members, " ");
    sink.write("}");
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" ", node.expression);
  }

  @override
  void visitNativeClause(NativeClause node) {
    sink.write("native ");
    safelyVisitNode(node.name);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    sink.write("native ");
    safelyVisitNode(node.stringLiteral);
    sink.write(';');
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    sink.write("null");
  }

  @override
  void visitOnClause(OnClause node) {
    sink.write('on ');
    safelyVisitNodeListWithSeparator(node.superclassConstraints, ", ");
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    sink.write('(');
    safelyVisitNode(node.expression);
    sink.write(')');
  }

  @override
  void visitPartDirective(PartDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("part ");
    safelyVisitNode(node.uri);
    sink.write(';');
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    sink.write("part of ");
    safelyVisitNode(node.libraryName);
    sink.write(';');
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeOperand(node, node.operand);
    sink.write(node.operator.lexeme);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    safelyVisitNode(node.prefix);
    sink.write('.');
    safelyVisitNode(node.identifier);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    sink.write(node.operator.lexeme);
    _writeOperand(node, node.operand);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      sink.write(node.operator.lexeme);
    } else {
      safelyVisitNode(node.target);
      sink.write(node.operator.lexeme);
    }
    safelyVisitNode(node.propertyName);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    sink.write("this");
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    sink.write("rethrow");
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Expression expression = node.expression;
    if (expression == null) {
      sink.write("return;");
    } else {
      sink.write("return ");
      expression.accept(this);
      sink.write(";");
    }
  }

  @override
  void visitScriptTag(ScriptTag node) {
    sink.write(node.scriptTag.lexeme);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    safelyVisitTokenWithSuffix(node.constKeyword, ' ');
    safelyVisitNode(node.typeArguments);
    sink.write('{');
    safelyVisitNodeListWithSeparator(node.elements, ', ');
    sink.write('}');
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    sink.write("show ");
    safelyVisitNodeListWithSeparator(node.shownNames, ", ");
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, ' ', ' ');
    safelyVisitTokenWithSuffix(node.covariantKeyword, ' ');
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNode(node.type);
    if (node.type != null && node.identifier != null) {
      sink.write(' ');
    }
    safelyVisitNode(node.identifier);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    sink.write(node.token.lexeme);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    sink.write(node.literal.lexeme);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    sink.write(node.spreadOperator.lexeme);
    safelyVisitNode(node.expression);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    safelyVisitNodeList(node.elements);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    sink.write("super");
    safelyVisitNodeWithPrefix(".", node.constructorName);
    safelyVisitNode(node.argumentList);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    sink.write("super");
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    sink.write("case ");
    safelyVisitNode(node.expression);
    sink.write(": ");
    safelyVisitNodeListWithSeparator(node.statements, " ");
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    sink.write("default: ");
    safelyVisitNodeListWithSeparator(node.statements, " ");
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    sink.write("switch (");
    safelyVisitNode(node.expression);
    sink.write(") {");
    safelyVisitNodeListWithSeparator(node.members, " ");
    sink.write("}");
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    sink.write("#");
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        sink.write(".");
      }
      sink.write(components[i].lexeme);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    sink.write("this");
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    sink.write("throw ");
    safelyVisitNode(node.expression);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    safelyVisitTokenWithSuffix(node.externalKeyword, " ");
    safelyVisitNodeWithSuffix(node.variables, ";");
  }

  @override
  void visitTryStatement(TryStatement node) {
    sink.write("try ");
    safelyVisitNode(node.body);
    safelyVisitNodeListWithSeparatorAndPrefix(" ", node.catchClauses, " ");
    safelyVisitNodeWithPrefix(" finally ", node.finallyBlock);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    sink.write('<');
    safelyVisitNodeListWithSeparator(node.arguments, ", ");
    sink.write('>');
  }

  @override
  void visitTypeName(TypeName node) {
    safelyVisitNode(node.name);
    safelyVisitNode(node.typeArguments);
    if (node.question != null) {
      sink.write('?');
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    if ((node as TypeParameterImpl).varianceKeyword != null) {
      sink.write((node as TypeParameterImpl).varianceKeyword.lexeme + ' ');
    }
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" extends ", node.bound);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    sink.write('<');
    safelyVisitNodeListWithSeparator(node.typeParameters, ", ");
    sink.write('>');
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitNode(node.name);
    safelyVisitNodeWithPrefix(" = ", node.initializer);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    safelyVisitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    safelyVisitTokenWithSuffix(node.lateKeyword, " ");
    safelyVisitTokenWithSuffix(node.keyword, " ");
    safelyVisitNodeWithSuffix(node.type, " ");
    safelyVisitNodeListWithSeparator(node.variables, ", ");
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    safelyVisitNode(node.variables);
    sink.write(";");
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    sink.write("while (");
    safelyVisitNode(node.condition);
    sink.write(") ");
    safelyVisitNode(node.body);
  }

  @override
  void visitWithClause(WithClause node) {
    sink.write("with ");
    safelyVisitNodeListWithSeparator(node.mixinTypes, ", ");
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    if (node.star != null) {
      sink.write("yield* ");
    } else {
      sink.write("yield ");
    }
    safelyVisitNode(node.expression);
    sink.write(";");
  }

  void _writeOperand(Expression node, Expression operand) {
    if (operand != null) {
      bool needsParenthesis = operand.precedence < node.precedence;
      if (needsParenthesis) {
        sink.write('(');
      }
      operand.accept(this);
      if (needsParenthesis) {
        sink.write(')');
      }
    }
  }
}
